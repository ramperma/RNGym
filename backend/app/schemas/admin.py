from datetime import datetime

from pydantic import BaseModel, EmailStr


class AdminUserCreate(BaseModel):
    email: EmailStr
    password: str
    nombre: str
    apellidos: str | None = None
    rol: str = "usuario"


class AdminUserUpdate(BaseModel):
    nombre: str | None = None
    apellidos: str | None = None
    rol: str | None = None
    esta_activo: bool | None = None


class AdminUserResponse(BaseModel):
    id: str
    email: str
    nombre: str
    apellidos: str | None
    rol: str
    idioma: str
    timezone: str
    email_verificado: bool
    fecha_alta: datetime
    ultimo_acceso: datetime | None
    esta_activo: bool

    class Config:
        from_attributes = True


class AdminStatsResponse(BaseModel):
    total_usuarios: int
    usuarios_activos: int
    total_rutinas: int
    total_sesiones: int
    total_logs_ia: int
    fecha_data: str