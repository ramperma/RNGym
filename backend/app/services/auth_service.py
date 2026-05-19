from fastapi import HTTPException, status

from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.db import db_connection_context
from app.repositories import (
    create_user,
    email_exists,
    get_user_by_email,
    get_user_by_id,
    update_last_login,
)


def register(email: str, password: str, nombre: str, apellidos: str | None = None) -> dict:
    with db_connection_context() as conn:
        if email_exists(conn, email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={"code": "EMAIL_ALREADY_EXISTS", "message": "Este email ya está registrado"},
            )
        hashed = hash_password(password)
        user = create_user(conn, email, hashed, nombre, apellidos)
        access_token = create_access_token({"sub": user.id, "email": user.email, "rol": user.rol})
        refresh_token = create_refresh_token({"sub": user.id})
        update_last_login(conn, user.id)
        return {
            "user": {
                "id": user.id,
                "email": user.email,
                "nombre": user.nombre,
                "apellidos": user.apellidos,
                "rol": user.rol,
                "idioma": user.idioma,
                "timezone": user.timezone,
                "email_verificado": user.email_verificado,
                "fecha_alta": user.fecha_alta.isoformat(),
                "esta_activo": user.esta_activo,
            },
            "access_token": access_token,
            "refresh_token": refresh_token,
        }


def login(email: str, password: str) -> dict:
    with db_connection_context() as conn:
        user = get_user_by_email(conn, email)
        if not user or not verify_password(password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"code": "INVALID_CREDENTIALS", "message": "Email o contraseña incorrectos"},
            )
        if not user.esta_activo:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={"code": "ACCOUNT_DISABLED", "message": "Cuenta desactivada"},
            )
        update_last_login(conn, user.id)
        access_token = create_access_token({"sub": user.id, "email": user.email, "rol": user.rol})
        refresh_token = create_refresh_token({"sub": user.id})
        return {
            "user": {
                "id": user.id,
                "email": user.email,
                "nombre": user.nombre,
                "apellidos": user.apellidos,
                "rol": user.rol,
            },
            "access_token": access_token,
            "refresh_token": refresh_token,
        }


def refresh(refresh_token: str) -> dict:
    payload = decode_token(refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_REFRESH_TOKEN", "message": "Refresh token inválido o expirado"},
        )
    user_id = payload.get("sub")
    with db_connection_context() as conn:
        user = get_user_by_id(conn, user_id)
        if not user or not user.esta_activo:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"code": "USER_NOT_FOUND_DISABLED", "message": "Usuario no disponible"},
            )
        access_token = create_access_token({"sub": user.id, "email": user.email, "rol": user.rol})
        new_refresh_token = create_refresh_token({"sub": user.id})
        return {
            "access_token": access_token,
            "refresh_token": new_refresh_token,
        }
