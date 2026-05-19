from datetime import datetime

from pydantic import BaseModel


class RutinaEjercicioBase(BaseModel):
    ejercicio_id: str
    orden: int = 1
    series: int = 3
    repeticiones: str = "10-12"
    descanso_segundos: int | None = 90
    tempo: str | None = None
    notas: str | None = None


class RutinaEjercicioCreate(RutinaEjercicioBase):
    pass


class RutinaEjercicioResponse(RutinaEjercicioBase):
    id: str
    rutina_id: str
    created_at: datetime

    class Config:
        from_attributes = True


class RutinaBase(BaseModel):
    nombre: str
    descripcion: str | None = None
    tipo_rutina: str
    dificultad: str | None = None
    duracion_estimada_minutos: int | None = None
    frecuencia_semanal: int = 3
    es_publica: bool = False
    fuente_creacion: str = "entrenador"
    metadata_ia: dict | None = None


class RutinaCreate(RutinaBase):
    ejercicios: list[RutinaEjercicioCreate] = []


class RutinaUpdate(BaseModel):
    nombre: str | None = None
    descripcion: str | None = None
    tipo_rutina: str | None = None
    dificultad: str | None = None
    duracion_estimada_minutos: int | None = None
    frecuencia_semanal: int | None = None
    es_publica: bool | None = None
    activa: bool | None = None
    ejercicios: list[RutinaEjercicioCreate] | None = None


class RutinaResponse(BaseModel):
    id: str
    nombre: str
    descripcion: str | None
    tipo_rutina: str
    dificultad: str | None
    duracion_estimada_minutos: int | None
    frecuencia_semanal: int
    usuario_id: str | None
    creador_id: str | None
    es_publica: bool
    fuente_creacion: str
    metadata_ia: dict | None
    created_at: datetime
    updated_at: datetime
    activa: bool
    ejercicios: list[RutinaEjercicioResponse] = []

    class Config:
        from_attributes = True


class RutinaListResponse(BaseModel):
    id: str
    nombre: str
    tipo_rutina: str
    dificultad: str | None
    created_at: datetime
    activa: bool

    class Config:
        from_attributes = True