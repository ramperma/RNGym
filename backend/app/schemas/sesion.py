from datetime import datetime

from pydantic import BaseModel


class SesionEjercicioRegistroBase(BaseModel):
    ejercicio_id: str | None = None
    set_numero: int
    peso_kg: float | None = None
    repeticiones: int | None = None
    rpe: int | None = None
    completado: bool = True
    notas: str | None = None


class SesionEjercicioRegistroCreate(SesionEjercicioRegistroBase):
    pass


class SesionEjercicioRegistroResponse(SesionEjercicioRegistroBase):
    id: str
    sesion_id: str
    created_at: datetime

    class Config:
        from_attributes = True


class SesionEntrenoBase(BaseModel):
    rutina_id: str | None = None
    plan_semanal_id: str | None = None
    dia_semana: int | None = None
    nombre: str | None = None
    fecha_inicio: datetime
    fecha_fin: datetime | None = None
    duracion_minutos: int | None = None
    estado: str = "planificada"
    kcal_estimadas: int | None = None
    kcal_real: int | None = None
    notas: str | None = None


class SesionEntrenoCreate(SesionEntrenoBase):
    pass


class SesionEntrenoUpdate(BaseModel):
    nombre: str | None = None
    fecha_inicio: datetime | None = None
    fecha_fin: datetime | None = None
    duracion_minutos: int | None = None
    estado: str | None = None
    kcal_estimadas: int | None = None
    kcal_real: int | None = None
    notas: str | None = None


class SesionEntrenoResponse(SesionEntrenoBase):
    id: str
    usuario_id: str
    created_at: datetime
    registros: list[SesionEjercicioRegistroResponse] = []

    class Config:
        from_attributes = True


class SesionEntrenoListResponse(BaseModel):
    id: str
    nombre: str | None
    fecha_inicio: datetime
    estado: str
    duracion_minutos: int | None

    class Config:
        from_attributes = True


class RegistrarSetsRequest(BaseModel):
    ejercicio_id: str | None = None
    ejercicio_nombre: str | None = None
    ejercicio_grupo_muscular: str | None = None
    ejercicio_equipo: str | None = None
    registros: list[SesionEjercicioRegistroCreate]
