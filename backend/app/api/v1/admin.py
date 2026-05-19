from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import require_admin
from app.core.security import hash_password
from app.db import get_db_connection, db_connection_context
from app.repositories import email_exists
from app.repositories.admin_repository import (
    create_admin_user,
    get_stats,
    list_all_users,
    update_admin_user,
)
from app.schemas.admin import (
    AdminStatsResponse,
    AdminUserCreate,
    AdminUserResponse,
    AdminUserUpdate,
)

router = APIRouter(prefix="/api/v1/admin", tags=["admin"])


@router.get("/users", response_model=list[AdminUserResponse])
def admin_list_users(
    skip: int = 0,
    limit: int = 50,
    current_user: dict = Depends(require_admin),
) -> list[dict]:
    with db_connection_context() as conn:
        users = list_all_users(conn, skip, limit)
        return [_user_to_dict(u) for u in users]


@router.post("/users", response_model=AdminUserResponse, status_code=status.HTTP_201_CREATED)
def admin_create_user(
    payload: AdminUserCreate,
    current_user: dict = Depends(require_admin),
) -> dict:
    with db_connection_context() as conn:
        if email_exists(conn, payload.email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={"code": "EMAIL_ALREADY_EXISTS", "message": "Este email ya está registrado"},
            )
        hashed = hash_password(payload.password)
        user = create_admin_user(
            conn,
            payload.email,
            payload.nombre,
            payload.apellidos,
            payload.rol,
            hashed,
        )
        return _user_to_dict(user)


@router.patch("/users/{user_id}", response_model=AdminUserResponse)
def admin_update_user(
    user_id: str,
    payload: AdminUserUpdate,
    current_user: dict = Depends(require_admin),
) -> dict:
    data = payload.model_dump(exclude_unset=True)
    with db_connection_context() as conn:
        user = update_admin_user(conn, user_id, data)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "USER_NOT_FOUND", "message": "Usuario no encontrado"},
            )
        return _user_to_dict(user)


@router.get("/stats", response_model=AdminStatsResponse)
def admin_stats(current_user: dict = Depends(require_admin)) -> dict:
    with db_connection_context() as conn:
        return get_stats(conn)


def _user_to_dict(user) -> dict:
    return {
        "id": user.id,
        "email": user.email,
        "nombre": user.nombre,
        "apellidos": user.apellidos,
        "rol": user.rol,
        "idioma": user.idioma,
        "timezone": user.timezone,
        "email_verificado": user.email_verificado,
        "fecha_alta": user.fecha_alta,
        "ultimo_acceso": user.ultimo_acceso,
        "esta_activo": user.esta_activo,
    }