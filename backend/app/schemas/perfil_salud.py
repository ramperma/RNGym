from datetime import date, datetime

from pydantic import BaseModel


class PerfilSaludBase(BaseModel):
    fecha_nacimiento: date | None = None
    sexo_biologico: str | None = None
    altura_cm: float | None = None
    peso_actual_kg: float | None = None
    peso_deseado_kg: float | None = None
    porcentaje_grasa: float | None = None
    porcentaje_musculo: float | None = None
    tmb_kcal: int | None = None
    factor_actividad: float = 1.2
    lesiones: list[str] | None = None
    condiciones_medicas: list[str] | None = None
    alergias: list[str] | None = None
    medicamentos: list[str] | None = None
    restricciones_nutricionales: list[str] | None = None
    objetivo_principal: str | None = None
    objetivo_detalle: str | None = None
    consentimiento_salud: bool = False
    semanas_rotacion: int = 3
    porcentaje_progresion: float = 5.0


class PerfilSaludCreate(PerfilSaludBase):
    pass


class PerfilSaludUpdate(BaseModel):
    fecha_nacimiento: date | None = None
    sexo_biologico: str | None = None
    altura_cm: float | None = None
    peso_actual_kg: float | None = None
    peso_deseado_kg: float | None = None
    porcentaje_grasa: float | None = None
    porcentaje_musculo: float | None = None
    tmb_kcal: int | None = None
    factor_actividad: float | None = None
    lesiones: list[str] | None = None
    condiciones_medicas: list[str] | None = None
    alergias: list[str] | None = None
    medicamentos: list[str] | None = None
    restricciones_nutricionales: list[str] | None = None
    objetivo_principal: str | None = None
    objetivo_detalle: str | None = None
    consentimiento_salud: bool | None = None
    semanas_rotacion: int | None = None
    porcentaje_progresion: float | None = None


class PerfilSaludResponse(BaseModel):
    id: str
    usuario_id: str
    fecha_nacimiento: date | None
    sexo_biologico: str | None
    altura_cm: float | None
    peso_actual_kg: float | None
    peso_deseado_kg: float | None
    porcentaje_grasa: float | None
    porcentaje_musculo: float | None
    tmb_kcal: int | None
    factor_actividad: float
    lesiones: list[str] | None
    condiciones_medicas: list[str] | None
    alergias: list[str] | None
    medicamentos: list[str] | None
    restricciones_nutricionales: list[str] | None
    objetivo_principal: str | None
    objetivo_detalle: str | None
    consentimiento_salud: bool
    fecha_consentimiento_salud: datetime | None
    fecha_ultima_actualizacion: datetime
    created_at: datetime
    semanas_rotacion: int | None = 3
    porcentaje_progresion: float | None = 5.0

    class Config:
        from_attributes = True