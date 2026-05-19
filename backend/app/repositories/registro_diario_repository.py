from datetime import date, datetime

from sqlalchemy import select, update

from app.models.registro_diario import RegistroDiario


def upsert_registro_diario(conn, usuario_id: str, fecha: date, data: dict) -> RegistroDiario:
    existing = conn.execute(
        select(RegistroDiario).where(
            RegistroDiario.usuario_id == usuario_id,
            RegistroDiario.fecha == fecha,
        )
    ).scalar_one_or_none()

    update_values = {k: v for k, v in data.items() if v is not None}
    update_values["updated_at"] = datetime.utcnow()

    if existing:
        conn.execute(
            update(RegistroDiario)
            .where(RegistroDiario.id == existing.id)
            .values(**update_values)
        )
        conn.commit()
        conn.refresh(existing)
        return existing
    else:
        update_values["usuario_id"] = usuario_id
        update_values["fecha"] = fecha
        update_values["created_at"] = datetime.utcnow()
        registro = RegistroDiario(**update_values)
        conn.add(registro)
        conn.commit()
        conn.refresh(registro)
        return registro


def get_registro_by_fecha(conn, usuario_id: str, fecha: date) -> RegistroDiario | None:
    return conn.execute(
        select(RegistroDiario).where(
            RegistroDiario.usuario_id == usuario_id,
            RegistroDiario.fecha == fecha,
        )
    ).scalar_one_or_none()


def list_registros(
    conn, usuario_id: str, skip: int = 0, limit: int = 30
) -> list[RegistroDiario]:
    result = conn.execute(
        select(RegistroDiario)
        .where(RegistroDiario.usuario_id == usuario_id)
        .order_by(RegistroDiario.fecha.desc())
        .offset(skip)
        .limit(limit)
    )
    return list(result.scalars().all())