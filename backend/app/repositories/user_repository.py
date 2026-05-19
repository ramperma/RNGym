from datetime import datetime
from types import SimpleNamespace

from sqlalchemy import text
from sqlalchemy.engine import Connection


def _to_user(row: dict | None):
    if not row:
        return None
    return SimpleNamespace(**row)


def create_user(
    connection: Connection,
    email: str,
    hashed_password: str,
    nombre: str,
    apellidos: str | None,
) -> object:
    row = (
        connection.execute(
            text(
                """
                INSERT INTO usuarios (
                    email, hashed_password, nombre, apellidos, rol,
                    idioma, timezone, email_verificado, fecha_alta, esta_activo,
                    consentimiento_gdpr, version_politica_privacidad
                )
                VALUES (
                    :email, :hashed_password, :nombre, :apellidos, 'usuario',
                    'es', 'Europe/Madrid', FALSE, NOW(), TRUE,
                    FALSE, '1.0'
                )
                RETURNING
                    id::text AS id,
                    email,
                    hashed_password,
                    nombre,
                    apellidos,
                    rol::text AS rol,
                    idioma,
                    timezone,
                    email_verificado,
                    fecha_alta,
                    ultimo_acceso,
                    esta_activo,
                    openai_api_key,
                    deepseek_api_key,
                    minimax_api_key,
                    proveedor_ia_preferido,
                    permitir_ia
                """
            ),
            {
                "email": email,
                "hashed_password": hashed_password,
                "nombre": nombre,
                "apellidos": apellidos,
            },
        )
        .mappings()
        .first()
    )
    connection.commit()
    return _to_user(dict(row) if row else None)


def get_user_by_email(connection: Connection, email: str) -> object | None:
    row = (
        connection.execute(
            text(
                """
                SELECT
                    id::text AS id,
                    email,
                    hashed_password,
                    nombre,
                    apellidos,
                    rol::text AS rol,
                    idioma,
                    timezone,
                    email_verificado,
                    fecha_alta,
                    ultimo_acceso,
                    esta_activo,
                    openai_api_key,
                    deepseek_api_key,
                    minimax_api_key,
                    proveedor_ia_preferido,
                    permitir_ia
                FROM usuarios
                WHERE email = :email
                LIMIT 1
                """
            ),
            {"email": email},
        )
        .mappings()
        .first()
    )
    return _to_user(dict(row) if row else None)


def get_user_by_id(connection: Connection, user_id: str) -> object | None:
    row = (
        connection.execute(
            text(
                """
                SELECT
                    id::text AS id,
                    email,
                    hashed_password,
                    nombre,
                    apellidos,
                    rol::text AS rol,
                    idioma,
                    timezone,
                    email_verificado,
                    fecha_alta,
                    ultimo_acceso,
                    esta_activo,
                    openai_api_key,
                    deepseek_api_key,
                    minimax_api_key,
                    proveedor_ia_preferido,
                    permitir_ia
                FROM usuarios
                WHERE id = CAST(:user_id AS uuid)
                LIMIT 1
                """
            ),
            {"user_id": user_id},
        )
        .mappings()
        .first()
    )
    return _to_user(dict(row) if row else None)


def update_last_login(connection: Connection, user_id: str) -> None:
    connection.execute(
        text("UPDATE usuarios SET ultimo_acceso = :ts WHERE id = CAST(:user_id AS uuid)"),
        {"ts": datetime.utcnow(), "user_id": user_id},
    )
    connection.commit()


def user_is_admin(connection: Connection, user_id: str) -> bool:
    result = connection.execute(
        text("SELECT rol::text FROM usuarios WHERE id = CAST(:user_id AS uuid) LIMIT 1"),
        {"user_id": user_id},
    )
    row = result.scalar_one_or_none()
    return row == "admin" if row else False


def email_exists(connection: Connection, email: str) -> bool:
    result = connection.execute(
        text("SELECT 1 FROM usuarios WHERE email = :email LIMIT 1"),
        {"email": email},
    )
    return result.scalar_one_or_none() is not None


def update_user_profile(connection: Connection, user_id: str, data: dict) -> object | None:
    if not data:
        return get_user_by_id(connection, user_id)

    set_clauses = []
    for key in data.keys():
        set_clauses.append(f"{key} = :{key}")

    query = f"""
        UPDATE usuarios
        SET {', '.join(set_clauses)}
        WHERE id = CAST(:user_id AS uuid)
        RETURNING
            id::text AS id, email, nombre, apellidos, rol::text AS rol,
            idioma, timezone, email_verificado, fecha_alta, esta_activo,
            openai_api_key,
            deepseek_api_key,
            minimax_api_key,
            proveedor_ia_preferido,
            permitir_ia
    """
    params = {**data, "user_id": user_id}
    row = connection.execute(text(query), params).mappings().first()
    connection.commit()
    return _to_user(dict(row) if row else None)
