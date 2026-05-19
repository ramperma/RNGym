from datetime import datetime

from sqlalchemy import delete, select, update

from app.models.rutina import Rutina, RutinaEjercicio


def create_rutina(conn, usuario_id: str, data: dict) -> Rutina:
    data["usuario_id"] = usuario_id
    data["created_at"] = datetime.utcnow()
    data["updated_at"] = datetime.utcnow()
    ejercicios_data = data.pop("ejercicios", [])

    rutina = Rutina(**data)
    conn.add(rutina)
    conn.flush()

    for ej in ejercicios_data:
        ej["rutina_id"] = rutina.id
        conn.add(RutinaEjercicio(**ej))

    conn.commit()
    conn.refresh(rutina)
    return rutina


def get_rutina_by_id(conn, rutina_id: str, usuario_id: str) -> Rutina | None:
    result = conn.execute(
        select(Rutina).where(
            Rutina.id == rutina_id,
            (Rutina.usuario_id == usuario_id) | (Rutina.es_publica == True),
        )
    )
    return result.scalar_one_or_none()


def list_rutinas(conn, usuario_id: str, skip: int = 0, limit: int = 20) -> list[Rutina]:
    result = conn.execute(
        select(Rutina)
        .where((Rutina.usuario_id == usuario_id) | (Rutina.es_publica == True))
        .where(Rutina.activa == True)
        .order_by(Rutina.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return list(result.scalars().all())


def update_rutina(conn, rutina_id: str, usuario_id: str, data: dict) -> Rutina | None:
    rutina = get_rutina_by_id(conn, rutina_id, usuario_id)
    if not rutina:
        return None

    update_fields = {k: v for k, v in data.items() if k != "ejercicios" and v is not None}
    update_fields["updated_at"] = datetime.utcnow()

    if update_fields:
        conn.execute(
            update(Rutina).where(Rutina.id == rutina_id).values(**update_fields)
        )

    if "ejercicios" in data and data["ejercicios"] is not None:
        conn.execute(delete(RutinaEjercicio).where(RutinaEjercicio.rutina_id == rutina_id))
        conn.flush()
        for ej in data["ejercicios"]:
            conn.add(RutinaEjercicio(rutina_id=rutina_id, **ej))

    conn.commit()
    conn.refresh(rutina)
    return rutina


def delete_rutina(conn, rutina_id: str, usuario_id: str) -> bool:
    result = conn.execute(
        update(Rutina)
        .where(Rutina.id == rutina_id, Rutina.usuario_id == usuario_id)
        .values(activa=False, updated_at=datetime.utcnow())
    )
    conn.commit()
    return result.rowcount > 0


def get_rutina_for_execute(conn, rutina_id: str, usuario_id: str) -> Rutina | None:
    return get_rutina_by_id(conn, rutina_id, usuario_id)