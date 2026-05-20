from datetime import datetime

from sqlalchemy import func, select, update, text
from sqlalchemy.engine import Connection

from app.models.usuario import Usuario
from app.models.rutina import Rutina
from app.models.sesion_entreno import SesionEntreno
from app.models.log_ia import LogIA
from app.repositories.user_repository import create_user, get_user_by_id

from app.models.admin import (
    AdminAiSettings,
    AdminAiSettingsUpsert,
    AdminUser,
    AdminUserCreate,
)


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


_AI_SETTINGS_COLUMNS = """
    id,
    ai_enabled,
    provider,
    model_name,
    temperature,
    max_tokens_per_request,
    updated_at,
    created_at
"""

_ADMIN_USER_COLUMNS = """
    id,
    username,
    email,
    is_active,
    token_limit_daily,
    tokens_used_today,
    notes,
    updated_at,
    created_at
"""

_GET_AI_SETTINGS_QUERY = text(
    f"""
    SELECT {_AI_SETTINGS_COLUMNS}
    FROM admin_ai_settings
    WHERE id = :id
    """
)

_UPSERT_AI_SETTINGS_QUERY = text(
    """
    INSERT INTO admin_ai_settings (
        id,
        ai_enabled,
        provider,
        model_name,
        temperature,
        max_tokens_per_request
    ) VALUES (
        :id,
        :ai_enabled,
        :provider,
        :model_name,
        :temperature,
        :max_tokens_per_request
    )
    ON CONFLICT (id)
    DO UPDATE SET
        ai_enabled = EXCLUDED.ai_enabled,
        provider = EXCLUDED.provider,
        model_name = EXCLUDED.model_name,
        temperature = EXCLUDED.temperature,
        max_tokens_per_request = EXCLUDED.max_tokens_per_request,
        updated_at = NOW()
    """
)

_LIST_ADMIN_USERS_QUERY = text(
    f"""
    SELECT {_ADMIN_USER_COLUMNS}
    FROM admin_users
    ORDER BY created_at DESC
    """
)

_GET_ADMIN_USER_QUERY = text(
    f"""
    SELECT {_ADMIN_USER_COLUMNS}
    FROM admin_users
    WHERE id = :user_id
    """
)

_CREATE_ADMIN_USER_QUERY = text(
    """
    INSERT INTO admin_users (
        id,
        username,
        email,
        token_limit_daily,
        notes
    ) VALUES (
        :id,
        :username,
        :email,
        :token_limit_daily,
        :notes
    )
    """
)

_UPDATE_ADMIN_USER_TOKEN_LIMIT_QUERY = text(
    """
    UPDATE admin_users
    SET token_limit_daily = :token_limit_daily,
        updated_at = NOW()
    WHERE id = :user_id
    """
)

_UPDATE_ADMIN_USER_STATUS_QUERY = text(
    """
    UPDATE admin_users
    SET is_active = :is_active,
        updated_at = NOW()
    WHERE id = :user_id
    """
)


def get_admin_ai_settings(connection: Connection, settings_id: str = "default") -> AdminAiSettings | None:
    row = connection.execute(_GET_AI_SETTINGS_QUERY, {"id": settings_id}).mappings().first()
    if row is None:
        return None
    return AdminAiSettings(**row)


def upsert_admin_ai_settings(
    connection: Connection,
    payload: AdminAiSettingsUpsert,
    settings_id: str = "default",
) -> AdminAiSettings:
    connection.execute(
        _UPSERT_AI_SETTINGS_QUERY,
        {
            "id": settings_id,
            "ai_enabled": payload.ai_enabled,
            "provider": payload.provider.strip(),
            "model_name": payload.model_name.strip(),
            "temperature": payload.temperature,
            "max_tokens_per_request": payload.max_tokens_per_request,
        },
    )
    connection.commit()
    settings = get_admin_ai_settings(connection, settings_id)
    if settings is None:
        raise RuntimeError("Admin AI settings upsert failed")
    return settings


def list_admin_users(connection: Connection) -> list[AdminUser]:
    rows = connection.execute(_LIST_ADMIN_USERS_QUERY).mappings().all()
    return [AdminUser(**row) for row in rows]


def get_admin_user(connection: Connection, user_id: str) -> AdminUser | None:
    row = connection.execute(_GET_ADMIN_USER_QUERY, {"user_id": user_id}).mappings().first()
    if row is None:
        return None
    return AdminUser(**row)


def create_admin_user_legacy(connection: Connection, payload: AdminUserCreate, user_id: str) -> AdminUser:
    connection.execute(
        _CREATE_ADMIN_USER_QUERY,
        {
            "id": user_id,
            "username": payload.username.strip(),
            "email": payload.email.strip().lower(),
            "token_limit_daily": payload.token_limit_daily,
            "notes": payload.notes.strip(),
        },
    )
    connection.commit()
    user = get_admin_user(connection, user_id)
    if user is None:
        raise RuntimeError("Admin user creation failed")
    return user


def update_admin_user_token_limit(connection: Connection, user_id: str, token_limit_daily: int) -> AdminUser | None:
    result = connection.execute(
        _UPDATE_ADMIN_USER_TOKEN_LIMIT_QUERY,
        {"user_id": user_id, "token_limit_daily": token_limit_daily},
    )
    connection.commit()
    if result.rowcount == 0:
        return None
    return get_admin_user(connection, user_id)


def update_admin_user_status(connection: Connection, user_id: str, is_active: bool) -> AdminUser | None:
    result = connection.execute(
        _UPDATE_ADMIN_USER_STATUS_QUERY,
        {"user_id": user_id, "is_active": is_active},
    )
    connection.commit()
    if result.rowcount == 0:
        return None
    return get_admin_user(connection, user_id)