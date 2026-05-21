from datetime import datetime

from sqlalchemy import delete, select, update

from app.models.sesion_entreno import SesionEntreno, SesionEjercicioRegistro
from app.models.ejercicio import Ejercicio


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


def get_registros_by_sesion(conn, sesion_id: str) -> list[dict]:
    result = conn.execute(
        select(
            SesionEjercicioRegistro.id,
            SesionEjercicioRegistro.sesion_id,
            SesionEjercicioRegistro.ejercicio_id,
            Ejercicio.nombre.label("ejercicio_nombre"),
            Ejercicio.grupo_muscular.label("ejercicio_grupo_muscular"),
            Ejercicio.equipo_necesario.label("ejercicio_equipo"),
            SesionEjercicioRegistro.set_numero,
            SesionEjercicioRegistro.peso_kg,
            SesionEjercicioRegistro.repeticiones,
            SesionEjercicioRegistro.rpe,
            SesionEjercicioRegistro.completado,
            SesionEjercicioRegistro.notas,
            SesionEjercicioRegistro.created_at,
        )
        .join(Ejercicio, SesionEjercicioRegistro.ejercicio_id == Ejercicio.id)
        .where(SesionEjercicioRegistro.sesion_id == sesion_id)
        .order_by(Ejercicio.nombre, SesionEjercicioRegistro.set_numero)
    )
    rows = result.all()
    return [
        {
            "id": r.id,
            "sesion_id": r.sesion_id,
            "ejercicio_id": r.ejercicio_id,
            "ejercicio_nombre": r.ejercicio_nombre,
            "ejercicio_grupo_muscular": r.ejercicio_grupo_muscular,
            "ejercicio_equipo": r.ejercicio_equipo,
            "set_numero": r.set_numero,
            "peso_kg": float(r.peso_kg) if r.peso_kg is not None else None,
            "repeticiones": r.repeticiones,
            "rpe": r.rpe,
            "completado": r.completado,
            "notas": r.notas,
            "created_at": r.created_at,
        }
        for r in rows
    ]