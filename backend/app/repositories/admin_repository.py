from datetime import datetime

from sqlalchemy import func, select, update

from app.models.usuario import Usuario
from app.models.rutina import Rutina
from app.models.sesion_entreno import SesionEntreno
from app.models.log_ia import LogIA
from app.repositories.user_repository import create_user, get_user_by_id


def create_admin_user(conn, email: str, nombre: str, apellidos: str | None, rol: str, hashed_password: str) -> Usuario:
    return create_user(conn, email, hashed_password, nombre, apellidos, rol)


def update_admin_user(conn, user_id: str, data: dict) -> Usuario | None:
    existing = get_user_by_id(conn, user_id)
    if not existing:
        return None
    update_values = {k: v for k, v in data.items() if v is not None}
    if update_values:
        conn.execute(
            update(Usuario).where(Usuario.id == user_id).values(**update_values)
        )
        conn.commit()
        conn.refresh(existing)
    return existing


def list_all_users(conn, skip: int = 0, limit: int = 50) -> list[Usuario]:
    result = conn.execute(
        select(Usuario).order_by(Usuario.fecha_alta.desc()).offset(skip).limit(limit)
    )
    return list(result.scalars().all())


def get_stats(conn) -> dict:
    total_users = conn.execute(select(func.count(Usuario.id))).scalar_one()
    activos = conn.execute(
        select(func.count(Usuario.id)).where(Usuario.esta_activo == True)
    ).scalar_one()
    total_rutinas = conn.execute(select(func.count(Rutina.id))).scalar_one()
    total_sesiones = conn.execute(select(func.count(SesionEntreno.id))).scalar_one()
    total_logs = conn.execute(select(func.count(LogIA.id))).scalar_one()
    return {
        "total_usuarios": total_users,
        "usuarios_activos": activos,
        "total_rutinas": total_rutinas,
        "total_sesiones": total_sesiones,
        "total_logs_ia": total_logs,
        "fecha_data": datetime.utcnow().isoformat(),
    }