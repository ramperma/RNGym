from pydantic import BaseModel


class AIRecommendRoutineRequest(BaseModel):
    objetivo: str
    dias_por_semana: int = 4
    duracion_max_minutos: int = 75
    equipo_disponible: list[str] = ["barra", "mancuernas", "polea"]
    lesiones_o_limitaciones: list[str] = []
    nivel_experiencia: str = "intermedio"


class AIAnalyzeSessionRequest(BaseModel):
    sesion_id: str
    notas_adicionales: str | None = None


class AIConsultaRequest(BaseModel):
    provider: str | None = None
    model: str | None = None
    modo: str = "platform_managed"
    user_api_key: str | None = None


class AIRecommendRoutineResponse(BaseModel):
    ok: bool = True
    rutina_generada: dict
    proveedor: str
    modelo: str
    modo: str


class AIAnalyzeSessionResponse(BaseModel):
    ok: bool = True
    analisis: str
    proveedor: str
    modelo: str
    modo: str


class AIMachineProposeRequest(BaseModel):
    descripcion_uso: str


class AIEjercicioPropuesto(BaseModel):
    nombre_ejercicio: str
    series: int = 4
    repeticiones: str = "10-12"
    descanso_segundos: int = 90
    notas: str | None = None


class AIMachineProposeResponse(BaseModel):
    ok: bool = True
    nombre: str
    grupo_muscular: str
    descripcion_uso: str
    ejercicios: list[AIEjercicioPropuesto] = []
    proveedor: str
    modelo: str
    modo: str