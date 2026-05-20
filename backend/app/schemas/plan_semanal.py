from datetime import datetime

from pydantic import BaseModel, Field


class PlanDiaEjercicio(BaseModel):
    nombre_ejercicio: str
    grupo_muscular: str | None = None
    series: int = 3
    repeticiones: str = "10-12"
    descanso_segundos: int = 90
    rir_o_rpe: str | None = None
    notas: str | None = None
    machine_id: str | None = None
    machine_nombre: str | None = None
    machine_foto_url: str | None = None


class PlanDiaBloque(BaseModel):
    tipo: str
    nombre: str
    duracion_minutos: int | None = None
    ejercicios: list[PlanDiaEjercicio] = []


class PlanDia(BaseModel):
    dia_semana: int = Field(..., ge=0, le=6)
    nombre_dia: str
    tipo: str = Field(
        ...,
        description="workout | rest | active_recovery",
        pattern="^(workout|rest|active_recovery)$",
    )
    bloques: list[PlanDiaBloque] = []
    descanso_entre_bloques_minutos: int = 2
    tiempo_total_estimado_minutos: int | None = None
    notas: str | None = None


class PlanSemanalJSON(BaseModel):
    dias: list[PlanDia] = Field(..., min_length=7, max_length=7)
    nota_general: str | None = None


class AIWeeklyPlanRequest(BaseModel):
    objetivo: str = Field(
        ...,
        description="fuerza | hipertrofia | definicion | cardio | funcional | flexibilidad",
    )
    dias_por_semana: int = Field(4, ge=1, le=7)
    duracion_max_minutos: int = Field(75, ge=30, le=150)
    nivel_experiencia: str = Field(
        "intermedio", description="principiante | intermedio | avanzado"
    )
    equipo_disponible: list[str] = [
        "barra",
        "mancuernas",
        "polea",
        "leg_press",
        "smith",
    ]
    lesiones_o_limitaciones: list[str] = []
    notas_adicionales: str | None = None
    maquinas_usuario_ids: list[str] = []
    dias_entreno_seleccionados: list[str] = []
    preferencias_equipamiento: list[str] = []
    porcentaje_maquinas_guiadas: int | None = Field(
        None, ge=0, le=100, description="Porcentaje deseado de máquinas guiadas"
    )
    porcentaje_peso_libre: int | None = Field(
        None, ge=0, le=100, description="Porcentaje deseado de peso libre y mancuernas"
    )
    min_ejercicios_por_sesion: int = Field(
        4, ge=2, le=12, description="Mínimo de ejercicios en el bloque principal por sesión"
    )


class PlanSemanalCreate(BaseModel):
    nombre: str
    objetivo: str
    nivel: str = "intermedio"
    duracion_max_minutos: int = 75
    dias_entreno_objetivo: int = 4
    equipo_disponible: list[str] = ["barra", "mancuernas", "polea"]
    lesiones_o_limitaciones: list[str] = []
    plan_json: dict
    metadata_ia: dict | None = None


class PlanSemanalResponse(BaseModel):
    id: str
    usuario_id: str
    nombre: str
    objetivo: str
    nivel: str
    duracion_max_minutos: int
    dias_entreno_objetivo: int
    equipo_disponible: list[str]
    lesiones_o_limitaciones: list[str] | None
    plan_json: dict
    metadata_ia: dict | None
    activo: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PlanSemanalListResponse(BaseModel):
    id: str
    nombre: str
    objetivo: str
    nivel: str
    activo: bool
    created_at: datetime

    class Config:
        from_attributes = True


class AIWeeklyPlanResponse(BaseModel):
    ok: bool = True
    plan_guardado: PlanSemanalResponse
    proveedor: str
    modelo: str
    modo: str


class AIModifyPlanRequest(BaseModel):
    plan_id: str
    instrucciones: str