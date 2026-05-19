from datetime import datetime

from sqlalchemy import select, update

from app.models.perfil_salud import PerfilSalud
from app.models.usuario import Usuario


def create_or_update_perfil(
    conn,
    usuario_id: str,
    data: dict,
) -> PerfilSalud:
    existing = conn.execute(
        select(PerfilSalud).where(PerfilSalud.usuario_id == usuario_id)
    ).scalar_one_or_none()

    if existing:
        update_values = {k: v for k, v in data.items() if v is not None}
        update_values["fecha_ultima_actualizacion"] = datetime.utcnow()
        if data.get("consentimiento_salud") is True:
            update_values["fecha_consentimiento_salud"] = datetime.utcnow()
        conn.execute(
            update(PerfilSalud)
            .where(PerfilSalud.usuario_id == usuario_id)
            .values(**update_values)
        )
        conn.commit()
        conn.refresh(existing)
        return existing
    else:
        data["usuario_id"] = usuario_id
        data["fecha_consentimiento_salud"] = (
            datetime.utcnow() if data.get("consentimiento_salud") else None
        )
        perfil = PerfilSalud(**data)
        conn.add(perfil)
        conn.commit()
        conn.refresh(perfil)
        return perfil


def get_perfil_by_usuario(conn, usuario_id: str) -> PerfilSalud | None:
    return conn.execute(
        select(PerfilSalud).where(PerfilSalud.usuario_id == usuario_id)
    ).scalar_one_or_none()


def delete_perfil(conn, usuario_id: str) -> bool:
    result = conn.execute(
        update(PerfilSalud)
        .where(PerfilSalud.usuario_id == usuario_id)
        .values(lesiones=[], condiciones_medicas=[], alergias=[])
    )
    conn.commit()
    return result.rowcount > 0