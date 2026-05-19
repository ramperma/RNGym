from datetime import datetime
from typing import Annotated

from fastapi import Depends
from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    email: EmailStr
    password: Annotated[str, Field(min_length=8, pattern=r".*[A-Z].*")]
    nombre: str = Field(min_length=1, max_length=100)
    apellidos: str | None = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    sub: str
    exp: int
    type: str


class RefreshRequest(BaseModel):
    refresh_token: str


class UserResponse(BaseModel):
    id: str
    email: str
    nombre: str
    apellidos: str | None
    rol: str
    idioma: str = "es"
    timezone: str = "Europe/Madrid"
    email_verificado: bool = False
    fecha_alta: datetime | None = None
    esta_activo: bool = True

    class Config:
        from_attributes = True


class RegisterResponse(BaseModel):
    ok: bool = True
    user: UserResponse
    message: str = "Cuenta creada correctamente"
    access_token: str
    refresh_token: str