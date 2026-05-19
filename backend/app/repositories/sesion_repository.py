from datetime import datetime

from sqlalchemy import delete, select, update

from app.models.sesion_entreno import SesionEntreno, SesionEjercicioRegistro


def create_sesion(conn, usuario_id: str, data: dict) -> SesionEntreno:
    data["usuario_id"] = usuario_id
    data["created_at"] = datetime.utcnow()
    sesion = SesionEntreno(**data)
    conn.add(sesion)
    conn.commit()
    conn.refresh(sesion)
    return sesion


def get_sesion_by_id(conn, sesion_id: str, usuario_id: str) -> SesionEntreno | None:
    result = conn.execute(
        select(SesionEntreno).where(
            SesionEntreno.id == sesion_id,
            SesionEntreno.usuario_id == usuario_id,
        )
    )
    return result.scalar_one_or_none()


def list_sesiones(
    conn, usuario_id: str, skip: int = 0, limit: int = 20, estado: str | None = None
) -> list[SesionEntreno]:
    query = select(SesionEntreno).where(SesionEntreno.usuario_id == usuario_id)
    if estado:
        query = query.where(SesionEntreno.estado == estado)
    result = conn.execute(
        query.order_by(SesionEntreno.fecha_inicio.desc()).offset(skip).limit(limit)
    )
    return list(result.scalars().all())


def update_sesion(conn, sesion_id: str, usuario_id: str, data: dict) -> SesionEntreno | None:
    sesion = get_sesion_by_id(conn, sesion_id, usuario_id)
    if not sesion:
        return None
    update_values = {k: v for k, v in data.items() if v is not None}
    if update_values:
        conn.execute(
            update(SesionEntreno)
            .where(SesionEntreno.id == sesion_id)
            .values(**update_values)
        )
        conn.commit()
        conn.refresh(sesion)
    return sesion


def delete_sesion(conn, sesion_id: str, usuario_id: str) -> bool:
    result = conn.execute(
        update(SesionEntreno)
        .where(SesionEntreno.id == sesion_id, SesionEntreno.usuario_id == usuario_id)
        .values(estado="cancelada")
    )
    conn.commit()
    return result.rowcount > 0


def registrar_sets(conn, sesion_id: str, usuario_id: str, ejercicio_id: str, registros: list[dict]) -> list[SesionEjercicioRegistro]:
    sesion = get_sesion_by_id(conn, sesion_id, usuario_id)
    if not sesion:
        return []

    created = []
    for reg in registros:
        record = SesionEjercicioRegistro(
            sesion_id=sesion_id,
            ejercicio_id=ejercicio_id,
            set_numero=reg["set_numero"],
            peso_kg=reg.get("peso_kg"),
            repeticiones=reg.get("repeticiones"),
            rpe=reg.get("rpe"),
            completado=reg.get("completado", True),
            notas=reg.get("notas"),
        )
        conn.add(record)
        created.append(record)

    conn.commit()
    for r in created:
        conn.refresh(r)
    return created


def get_registros_by_sesion(conn, sesion_id: str) -> list[SesionEjercicioRegistro]:
    result = conn.execute(
        select(SesionEjercicioRegistro)
        .where(SesionEjercicioRegistro.sesion_id == sesion_id)
        .order_by(SesionEjercicioRegistro.set_numero)
    )
    return list(result.scalars().all())