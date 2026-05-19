from datetime import datetime

from pydantic import BaseModel


class MaquinaGymCreate(BaseModel):
    nombre: str
    grupo_muscular: str | None = None
    descripcion_uso: str | None = None


class MaquinaGymUpdate(BaseModel):
    nombre: str | None = None
    grupo_muscular: str | None = None
    descripcion_uso: str | None = None


class MaquinaGymResponse(BaseModel):
    id: str
    usuario_id: str
    nombre: str
    foto_path: str | None
    descripcion_uso: str | None
    grupo_muscular: str | None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True