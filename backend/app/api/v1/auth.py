from fastapi import APIRouter, Depends, status

from app.api.deps import get_current_user
from app.schemas.auth import (
    RefreshRequest,
    RegisterResponse,
    TokenResponse,
    UserCreate,
    UserLogin,
)
from app.services.auth_service import login, refresh, register

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/register", status_code=status.HTTP_201_CREATED)
def auth_register(payload: UserCreate) -> dict:
    result = register(payload.email, payload.password, payload.nombre, payload.apellidos)
    user_data = result["user"]
    return {
        "ok": True,
        "user": {
            "id": user_data["id"],
            "email": user_data["email"],
            "nombre": user_data["nombre"],
            "apellidos": user_data["apellidos"],
            "rol": user_data["rol"],
            "idioma": user_data.get("idioma", "es"),
            "timezone": user_data.get("timezone", "Europe/Madrid"),
            "email_verificado": user_data.get("email_verificado", False),
            "fecha_alta": user_data.get("fecha_alta"),
            "esta_activo": user_data.get("esta_activo", True),
        },
        "message": "Cuenta creada correctamente",
        "access_token": result["access_token"],
        "refresh_token": result["refresh_token"],
    }


@router.post("/login")
def auth_login(payload: UserLogin) -> dict:
    result = login(payload.email, payload.password)
    return {
        "ok": True,
        "access_token": result["access_token"],
        "refresh_token": result["refresh_token"],
        "token_type": "bearer",
        "user": result["user"],
    }


@router.post("/refresh", response_model=TokenResponse)
def auth_refresh(payload: RefreshRequest) -> dict:
    result = refresh(payload.refresh_token)
    return {
        "access_token": result["access_token"],
        "refresh_token": result["refresh_token"],
        "token_type": "bearer",
    }


@router.get("/me")
def auth_me(current_user: dict = Depends(get_current_user)) -> dict:
    """Returns the current authenticated user (called by Flutter AuthApi.getCurrentUser)"""
    return {"ok": True, "user": current_user}