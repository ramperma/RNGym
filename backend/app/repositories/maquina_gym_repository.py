from sqlalchemy import delete
from sqlalchemy.engine import Connection

from app.models.maquina_gym import MaquinaGym


def create_maquina(
    conn: Connection, usuario_id: str, nombre: str, foto_path: str | None = None, descripcion_uso: str | None = None, grupo_muscular: str | None = None
) -> MaquinaGym:
    maquina = MaquinaGym(
        usuario_id=usuario_id,
        nombre=nombre,
        foto_path=foto_path,
        descripcion_uso=descripcion_uso,
        grupo_muscular=grupo_muscular,
    )
    conn.add(maquina)
    conn.commit()
    conn.refresh(maquina)
    return maquina


def list_maquinas(conn: Connection, usuario_id: str) -> list[MaquinaGym]:
    result = conn.execute(
        MaquinaGym.__table__.select()
        .where(MaquinaGym.usuario_id == usuario_id)
        .order_by(MaquinaGym.created_at.desc())
    )
    return list(result.all())


def get_maquina_by_id(conn: Connection, maquina_id: str, usuario_id: str) -> MaquinaGym | None:
    result = conn.execute(
        MaquinaGym.__table__.select()
        .where(MaquinaGym.id == maquina_id, MaquinaGym.usuario_id == usuario_id)
    )
    row = result.first()
    return MaquinaGym(**row._asdict()) if row else None


def update_maquina(
    conn: Connection, maquina_id: str, usuario_id: str, data: dict
) -> MaquinaGym | None:
    maquina = get_maquina_by_id(conn, maquina_id, usuario_id)
    if not maquina:
        return None
    for key, value in data.items():
        if value is not None and hasattr(maquina, key):
            setattr(maquina, key, value)
    conn.commit()
    conn.refresh(maquina)
    return maquina


def delete_maquina(conn: Connection, maquina_id: str, usuario_id: str) -> bool:
    result = conn.execute(
        delete(MaquinaGym.__table__).where(
            MaquinaGym.id == maquina_id, MaquinaGym.usuario_id == usuario_id
        )
    )
    conn.commit()
    return result.rowcount > 0