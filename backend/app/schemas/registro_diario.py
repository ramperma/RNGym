from datetime import date, datetime

from pydantic import BaseModel


class RegistroDiarioBase(BaseModel):
    fecha: date
    peso_kg: float | None = None
    kcal_consumidas: int | None = None
    agua_litros: float | None = None
    horas_sueño: float | None = None
    calidad_sueno: int | None = None
    nivel_estres: int | None = None
    nivel_energia: int | None = None
    ejercicios_realizados: int | None = None
    minutos_entreno: int | None = None
    notas: str | None = None


class RegistroDiarioCreate(RegistroDiarioBase):
    pass


class RegistroDiarioUpdate(BaseModel):
    peso_kg: float | None = None
    kcal_consumidas: int | None = None
    agua_litros: float | None = None
    horas_sueño: float | None = None
    calidad_sueno: int | None = None
    nivel_estres: int | None = None
    nivel_energia: int | None = None
    ejercicios_realizados: int | None = None
    minutos_entreno: int | None = None
    notas: str | None = None


class RegistroDiarioResponse(RegistroDiarioBase):
    id: str
    usuario_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True