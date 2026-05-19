from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.security import decode_token
from app.db import db_connection_context
from app.repositories import get_user_by_id

security = HTTPBearer()


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    token = credentials.credentials
    payload = decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_TOKEN", "message": "Token inválido o expirado"},
        )
    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "NOT_ACCESS_TOKEN", "message": "Se requiere access token"},
        )
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "MISSING_USER_ID", "message": "Token sin user id"},
        )
    with db_connection_context() as conn:
        user = get_user_by_id(conn, user_id)
        if not user or not user.esta_activo:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={"code": "USER_NOT_FOUND_DISABLED", "message": "Usuario no disponible"},
            )
    return {
        "id": user.id,
        "email": user.email,
        "rol": user.rol,
        "openai_api_key": getattr(user, "openai_api_key", None),
        "deepseek_api_key": getattr(user, "deepseek_api_key", None),
        "minimax_api_key": getattr(user, "minimax_api_key", None),
        "proveedor_ia_preferido": getattr(user, "proveedor_ia_preferido", None),
        "permitir_ia": getattr(user, "permitir_ia", True),
    }


def require_admin(current_user: dict = Depends(get_current_user)) -> dict:
    if current_user.get("rol") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "ADMIN_REQUIRED", "message": "Se requiere rol admin"},
        )
    return current_user