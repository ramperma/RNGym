import base64
import json
import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status

from app.ai.client import ai_client, AIError
from app.ai.rate_limiter import check_rate_limit, check_token_quota
from app.api.deps import get_current_user
from app.schemas.ai import (
    AIRecommendRoutineRequest,
    AIAnalyzeSessionRequest,
    AIConsultaRequest,
    AIMachineProposeRequest,
    AIMachineProposeResponse,
    AIExerciseHelpResponse,
)
from app.schemas.plan_semanal import (
    AIWeeklyPlanRequest,
    AIWeeklyPlanResponse,
    AIModifyPlanRequest,
    PlanDia,
    PlanDiaBloque,
    PlanDiaEjercicio,
    PlanSemanalJSON,
    PlanSemanalResponse,
)
from app.schemas.maquina_gym import MaquinaGymResponse

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])

STORAGE_DIR = Path("backend/storage/machines")
STORAGE_DIR.mkdir(parents=True, exist_ok=True)

DIAS_SEMANA = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]


def _build_weekly_plan_prompt(
    req: AIWeeklyPlanRequest,
    perfil: dict | None,
    maquinas_info: list[dict],
) -> list[dict[str, str]]:
    perfil_str = ""
    if perfil:
        perfil_str = (
            f"Perfil del usuario: objetivo={perfil.get('objetivo_principal', 'no definido')}, "
            f"lesiones={perfil.get('lesiones', [])}, "
            f"equipo disponible={req.equipo_disponible}."
        )

    maquinas_str = ""
    if maquinas_info:
        maquinas_str = "\nMáquinas personalizadas del usuario:\n"
        for m in maquinas_info:
            foto = f"[foto: {m['foto_path']}]" if m.get("foto_path") else ""
            maquinas_str += f"  - {m['nombre']} ({m.get('grupo_muscular', 'sin grupo')}) {foto}\n"

    dias_seleccionados = getattr(req, "dias_entreno_seleccionados", [])
    pref_equipamiento = getattr(req, "preferencias_equipamiento", [])

    dias_sel_str = f"- Días específicos de la semana seleccionados para entrenar: {', '.join(dias_seleccionados)}\n" if dias_seleccionados else ""
    pref_eq_str = f"- Preferencias de equipamiento / tipo de ejercicios: {', '.join(pref_equipamiento)}\n" if pref_equipamiento else ""

    ratio_str = ""
    if getattr(req, "porcentaje_maquinas_guiadas", None) is not None or getattr(req, "porcentaje_peso_libre", None) is not None:
        ratio_str = "\nPREFERENCIA DE TIPOS DE EJERCICIO (MANDATORIO):\n"
        if getattr(req, "porcentaje_maquinas_guiadas", None) is not None:
            ratio_str += f"  - Porcentaje aproximado de máquinas guiadas / selectorizadas / Smith / poleas: {req.porcentaje_maquinas_guiadas}%\n"
        if getattr(req, "porcentaje_peso_libre", None) is not None:
            ratio_str += f"  - Porcentaje aproximado de peso libre (mancuernas / barras / discos): {req.porcentaje_peso_libre}%\n"
        ratio_str += "  Debes diseñar la selección de ejercicios de los bloques principales intentando cumplir rigurosamente con esta proporción.\n"

    prompt = f"""Eres un entrenador personal experto con años de experiencia diseñando planes semanales progresivos para gyms.
    
{perfil_str}
{maquinas_str}

Datos de la solicitud:
- Objetivo: {req.objetivo}
- Días de entrenamiento objetivo: {req.dias_por_semana}
{dias_sel_str}{pref_eq_str}- Duración máxima por sesión: {req.duracion_max_minutos} minutos
- Equipo disponible: {', '.join(req.equipo_disponible)}
- Nivel de experiencia: {req.nivel_experiencia}
- Limitaciones: {', '.join(req.lesiones_o_limitaciones) or 'ninguna'}{ratio_str}
- Notas adicionales: {req.notas_adicionales or 'ninguna'}

INSTRUCCIONES ESTRICTAS PARA AHORRO DE TOKENS:
1. Devuelve ÚNICAMENTE los {req.dias_por_semana} días de entrenamiento (tipo "workout"). NO incluyas días de descanso ("rest") en la lista de "dias"; el sistema los rellenará automáticamente para ahorrar tokens.
2. Cada día workout debe tener: bloque de calentamiento (5-10 min), bloque principal de ejercicios, bloque de enfriamiento (5 min).
3. LÍMITE ESTRICTO DE EJERCICIOS: Para evitar que la respuesta se corte por el límite de tokens de la API, limita estrictamente los ejercicios: Máximo 1 ejercicio en calentamiento, Máximo 4 ejercicios en el bloque principal y Máximo 1 ejercicio en enfriamiento. No superes nunca los 6 ejercicios en total por día.
4. Los descansos entre bloques intra-sesión deben ser de 2 minutos aproximadamente.
5. Incluye series, repeticiones y descanso en segundos para cada ejercicio.
6. Si el usuario proporcionó máquinas personalizadas, úsalas referenciándolas por nombre en machine_nombre.
7. El campo machine_id is opcional; si la máquina es una de las personalizadas del usuario, proporciona su id.
8. Distribuye los grupos musculares equilibradamente a lo largo de la semana siguiendo evidencia científica.
9. Para cada ejercicio, las instrucciones ("notas") deben ser ULTRA CONCISAS (máximo una frase de 8 palabras, ej: "Mantén espalda recta y rodillas estables").
10. Calcula el tiempo_total_estimado_minutos para cada día basándote en la suma de bloques.
11. DÍAS DE ENTRENO ESPECÍFICOS: Si se han especificado días de entrenamiento (en "Días específicos..."), los días de tipo "workout" que devuelvas DEBEN ser obligatoriamente esos días indicados. Usa sus respectivos índices: Lunes=0, Martes=1, Miércoles=2, Jueves=3, Viernes=4, Sábado=5, Domingo=6.
 12. ADAPTACIÓN DE LESIONES Y PREFERENCIAS ARTICULARES: Revisa con especial cuidado la sección "Limitaciones" y el "Perfil del usuario". Si se especifican dolores articulares, lesiones (como hombros, rodillas, espalda, etc.) o preferencias de equipamiento (como máquinas guiadas), adapta TODO el plan de forma inteligente. Prioriza de manera absoluta ejercicios seguros que estabilicen y guíen el movimiento (como máquinas selectorizadas guiadas, poleas regulables o Smith) para las zonas afectadas, y reduce o elimina por completo ejercicios pesados de peso libre que puedan agravar sus limitaciones.

FORMATO JSON ESTRICTO (solo JSON, sin texto adicional, sin markdown, sin bloques de código):
{{
  "dias": [
    {{
      "dia_semana": 0,
      "nombre_dia": "Lunes",
      "tipo": "workout",
      "bloques": [
        {{
          "tipo": "calentamiento",
          "nombre": "Calentamiento específico",
          "duracion_minutos": 8,
          "ejercicios": [
            {{
              "nombre_ejercicio": "nombre del ejercicio",
              "grupo_muscular": "pecho",
              "series": 3,
              "repeticiones": "10-12",
              "descanso_segundos": 60,
              "rir_o_rpe": "RPE 7",
              "notas": "instrucciones breves de ejecución",
              "machine_id": null,
              "machine_nombre": "nombre de la máquina o equipo",
              "machine_foto_url": null
            }}
          ]
        }},
        {{
          "tipo": "principal",
          "nombre": "Bloque principal",
          "duracion_minutos": 45,
          "ejercicios": [{{...}}]
        }},
        {{
          "tipo": "enfriamiento",
          "nombre": "Enfriamiento y estiramientos",
          "duracion_minutos": 5,
          "ejercicios": [{{...}}]
        }}
      ],
      "descanso_entre_bloques_minutos": 2,
      "tiempo_total_estimado_minutos": 60,
      "notas": null
    }},
    {{
      "dia_semana": 1,
      "nombre_dia": "Martes",
      "tipo": "rest",
      "bloques": [],
      "descanso_entre_bloques_minutos": 0,
      "tiempo_total_estimado_minutos": 0,
      "notas": "Día de descanso activo: caminata suave 20-30 min"
    }}
  ],
  "nota_general": "Plan diseñado para {req.objetivo} con énfasis en {req.nivel_experiencia}"
}}

Solo devuelve el JSON, sin explicaciones adicionales."""

    return [
        {
            "role": "system",
            "content": "Eres un entrenador personal experto. Responde SOLO con JSON válido, sin texto adicional, sin bloques de código, sin markdown.",
        },
        {"role": "user", "content": prompt},
    ]


def _get_day_focus(dia_idx: int, dias_por_semana: int) -> str:
    if dias_por_semana <= 2:
        return "Cuerpo Completo (Full Body) balanceado, combinando ejercicios de empuje, tirón y piernas de manera uniforme."
    elif dias_por_semana == 3:
        focus_map = {
            0: "Torso Superior (Pecho, Espalda, Hombros).",
            2: "Piernas completo (Cuádriceps, Isquiotibiales, Gemelos, Glúteos).",
            4: "Cuerpo Completo (Full Body) con énfasis en brazos (Bíceps y Tríceps) y Core."
        }
        return focus_map.get(dia_idx, "Cuerpo Completo.")
    elif dias_por_semana == 4:
        focus_map = {
            0: "Torso Superior: Empuje / Push (Pecho, Hombro anterior/lateral y Tríceps).",
            1: "Torso Superior: Tirón / Pull (Espalda, Hombro posterior y Bíceps).",
            3: "Piernas completo (Cuádriceps, Isquiotibiales, Gemelos, Glúteos).",
            4: "Brazos (Bíceps, Tríceps) y Core (Abdominales, Lumbares)."
        }
        return focus_map.get(dia_idx, "Cuerpo Completo.")
    elif dias_por_semana == 5:
        focus_map = {
            0: "Pecho y Tríceps.",
            1: "Espalda y Bíceps.",
            3: "Piernas completo (Énfasis anterior: Cuádriceps y Glúteos).",
            4: "Hombros y Core.",
            5: "Brazos (Bíceps/Tríceps) y Piernas posterior (Isquiotibiales, Gemelos)."
        }
        return focus_map.get(dia_idx, "Cuerpo Completo.")
    else:
        focus_map = {
            0: "Pecho y Core.",
            1: "Espalda.",
            2: "Piernas (Énfasis Cuádriceps).",
            3: "Hombros.",
            4: "Brazos (Bíceps y Tríceps).",
            5: "Piernas (Énfasis Isquiotibiales y Glúteos).",
            6: "Core y Cardio/Movilidad activa."
        }
        return focus_map.get(dia_idx, "Cuerpo Completo.")


def _build_weekly_plan_single_day_prompt(
    req: AIWeeklyPlanRequest,
    perfil: dict | None,
    maquinas_info: list[dict],
    dia_idx: int,
    dia_nombre: str,
    enfoque_muscular: str,
) -> list[dict[str, str]]:
    perfil_str = ""
    if perfil:
        perfil_str = (
            f"Perfil del usuario: objetivo={perfil.get('objetivo_principal', 'no definido')}, "
            f"lesiones={perfil.get('lesiones', [])}, "
            f"equipo disponible={req.equipo_disponible}."
        )

    maquinas_str = ""
    if maquinas_info:
        maquinas_str = "\nMáquinas personalizadas del usuario:\n"
        for m in maquinas_info:
            foto = f"[foto: {m['foto_path']}]" if m.get("foto_path") else ""
            maquinas_str += f"  - {m['nombre']} ({m.get('grupo_muscular', 'sin grupo')}) {foto}\n"

    ratio_str = ""
    if getattr(req, "porcentaje_maquinas_guiadas", None) is not None or getattr(req, "porcentaje_peso_libre", None) is not None:
        ratio_str = "\nPREFERENCIA DE TIPOS DE EJERCICIO (MANDATORIO):\n"
        if getattr(req, "porcentaje_maquinas_guiadas", None) is not None:
            ratio_str += f"  - Porcentaje aproximado de máquinas guiadas / selectorizadas / Smith / poleas: {req.porcentaje_maquinas_guiadas}%\n"
        if getattr(req, "porcentaje_peso_libre", None) is not None:
            ratio_str += f"  - Porcentaje aproximado de peso libre (mancuernas / barras / discos): {req.porcentaje_peso_libre}%\n"
        ratio_str += "  Debes diseñar la selección de ejercicios del bloque principal intentando cumplir rigurosamente con esta proporción.\n"

    prompt = f"""Eres un entrenador personal experto con años de experiencia diseñando planes semanales progresivos para gyms.

{perfil_str}
{maquinas_str}

Datos de la solicitud:
- Objetivo general: {req.objetivo}
- Nivel de experiencia: {req.nivel_experiencia}
- Duración máxima por sesión: {req.duracion_max_minutos} minutos
- Equipo disponible: {', '.join(req.equipo_disponible)}
- Limitaciones/Lesiones: {', '.join(req.lesiones_o_limitaciones) or 'ninguna'}{ratio_str}
- Notas adicionales: {req.notas_adicionales or 'ninguna'}

INSTRUCCIONES PARA ESTE DÍA ESPECÍFICO (MUY IMPORTANTE):
1. Genera el entrenamiento para el día de la semana: {dia_nombre} (índice {dia_idx}).
2. El tipo del día debe ser "workout".
3. ENFOQUE MUSCULAR MANDATORIO: Esta sesión de entrenamiento debe centrarse estrictamente en: {enfoque_muscular}. Solo incluye ejercicios correspondientes a este enfoque muscular para evitar solapamiento con otros días.
4. Debe tener exactamente 3 bloques:
   - Bloque "calentamiento" (5-10 min, máximo 2 ejercicios).
   - Bloque "principal" (35-50 min, MÍNIMO {req.min_ejercicios_por_sesion} ejercicios de alta calidad adaptados a su nivel y al enfoque muscular del día).
   - Bloque "enfriamiento" (5 min, máximo 2 ejercicios/estiramientos).
5. Si el usuario tiene máquinas personalizadas, úsalas referenciándolas por su exacto machine_nombre en el campo correspondiente. El campo machine_id es opcional (pon su ID de la lista si es una máquina personalizada).
6. Las instrucciones de ejecución (campo "notas" dentro de cada ejercicio) deben ser sumamente claras y descriptivas, de unas 2-3 líneas de texto técnico (máximo 25 palabras). Da detalles de ejecución correctos y precisos!
7. Calcula con precisión la "duracion_minutos" para cada bloque y el "tiempo_total_estimado_minutos" del día.

FORMATO JSON DE RESPUESTA (Solo devuelve este objeto JSON sin bloques de código, sin markdown, sin texto aclaratorio):
{{
  "dia_semana": {dia_idx},
  "nombre_dia": "{dia_nombre}",
  "tipo": "workout",
  "bloques": [
    {{
      "tipo": "calentamiento",
      "nombre": "Calentamiento específico",
      "duracion_minutos": 8,
      "ejercicios": [
        {{
          "nombre_ejercicio": "nombre del ejercicio",
          "grupo_muscular": "grupo muscular",
          "series": 3,
          "repeticiones": "10-12",
          "descanso_segundos": 60,
          "rir_o_rpe": "RPE 7",
          "notas": "Instrucciones de ejecución técnica detalladas de 2 a 3 líneas.",
          "machine_id": null,
          "machine_nombre": "nombre de la máquina o equipo",
          "machine_foto_url": null
        }}
      ]
    }},
    {{
      "tipo": "principal",
      "nombre": "Bloque principal",
      "duracion_minutos": 45,
      "ejercicios": [
        {{
          "nombre_ejercicio": "ejercicio principal",
          "grupo_muscular": "grupo muscular",
          "series": 4,
          "repeticiones": "8-10",
          "descanso_segundos": 90,
          "rir_o_rpe": "RPE 8",
          "notas": "Instrucciones de ejecución técnica detalladas.",
          "machine_id": null,
          "machine_nombre": "equipo"
        }}
      ]
    }},
    {{
      "tipo": "enfriamiento",
      "nombre": "Enfriamiento y estiramientos",
      "duracion_minutos": 5,
      "ejercicios": [
        {{
          "nombre_ejercicio": "estiramiento",
          "grupo_muscular": "general",
          "series": 1,
          "repeticiones": "30 seg",
          "descanso_segundos": 0,
          "rir_o_rpe": null,
          "notas": "Instrucciones de ejecución del estiramiento.",
          "machine_id": null,
          "machine_nombre": "ninguna"
        }}
      ]
    }}
  ],
  "descanso_entre_bloques_minutos": 2,
  "tiempo_total_estimado_minutos": 60,
  "notas": "Descripción breve del enfoque muscular o metabólico de esta sesión."
}}"""

    return [
        {
            "role": "system",
            "content": "Eres un entrenador personal experto. Tu salida debe ser estrictamente un objeto JSON válido para el día solicitado, sin explicaciones, sin markdown, sin bloques de código.",
        },
        {"role": "user", "content": prompt},
    ]


def _build_routine_prompt(req: AIRecommendRoutineRequest, perfil: dict | None) -> list[dict[str, str]]:
    perfil_str = ""
    if perfil:
        perfil_str = f"Perfil del usuario: objetivo={perfil.get('objetivo_principal', 'no definido')}, "
        perfil_str += f"lesiones={perfil.get('lesiones', [])}, "
        perfil_str += f"equipo disponible={req.equipo_disponible}."

    prompt = f"""Eres un entrenador personal experto. Genera una rutina de entrenamiento personalizada.

{perfil_str}

Datos de la solicitud:
- Objetivo: {req.objetivo}
- Días por semana: {req.dias_por_semana}
- Duración máxima por sesión: {req.duracion_max_minutos} minutos
- Equipo disponible: {', '.join(req.equipo_disponible)}
- Nivel de experiencia: {req.nivel_experiencia}
- Limitaciones: {', '.join(req.lesiones_o_limitaciones) or 'ninguna'}

Devuelve la rutina en formato JSON con esta estructura exacta:
{{
  "nombre": "Nombre de la rutina",
  "descripcion": "Descripción breve",
  "tipo_rutina": "fuerza|hipertrofia|definicion|cardio|funcional|flexibilidad",
  "dificultad": "principiante|intermedio|avanzado",
  "duracion_estimada_minutos": número,
  "frecuencia_semanal": número,
  "ejercicios": [
    {{
      "nombre_ejercicio": "nombre",
      "grupo_muscular": "grupo",
      "series": número,
      "repeticiones": "10-12",
      "descanso_segundos": número,
      "notas": "indicaciones"
    }}
  ]
}}
Solo devuelve el JSON, sin explicaciones adicionales."""

    return [{"role": "system", "content": "Eres un entrenador personal experto. Responde solo con JSON válido."}, {"role": "user", "content": prompt}]


def _build_analyze_prompt(sesion_id: str, sesion_data: dict, notas: str | None) -> list[dict[str, str]]:
    estado = sesion_data.get("estado", "desconocido")
    nombre = sesion_data.get("nombre", "sin nombre")
    duracion = sesion_data.get("duracion_minutos", 0)
    notas_texto = f"\nNotas adicionales del usuario: {notas}" if notas else ""

    prompt = f"""Analiza esta sesión de entrenamiento y proporciona feedback útil para el usuario.

Sesión: {nombre}
Estado: {estado}
Duración: {duracion} minutos{notas_texto}

Proporciona:
1. Breve análisis del rendimiento
2. Puntos fuertes identificados
3. Áreas de mejora
4. Sugerencias para la próxima sesión

Sé conciso y motivador."""

    return [{"role": "system", "content": "Eres un asistente de análisis de entrenamiento."}, {"role": "user", "content": prompt}]


def _resolve_ai_settings(current_user: dict) -> tuple[str, str, str | None, str | None]:
    """
    Resolves mode, provider, model, and user_key based on configured API keys.
    Returns: (mode, provider, model, user_key)
    """
    if not current_user.get("permitir_ia", True):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "AI_DISABLED_BY_ADMIN", "message": "El uso de la IA ha sido desactivado para este usuario por el administrador."},
        )

    deepseek_key = current_user.get("deepseek_api_key")
    minimax_key = current_user.get("minimax_api_key")
    openai_key = current_user.get("openai_api_key")
    preferred = current_user.get("proveedor_ia_preferido")

    # If the user has a specific preference, we strictly respect it!
    if preferred and preferred.strip():
        pref = preferred.strip().lower()
        if pref == "deepseek":
            if deepseek_key and deepseek_key.strip():
                return "byok", "deepseek", "deepseek-chat", deepseek_key
            from app.core.config import settings
            if settings.deepseek_api_key and settings.deepseek_api_key.strip():
                return "platform_managed", "deepseek", "deepseek-chat", None
        elif pref == "minimax":
            if minimax_key and minimax_key.strip():
                return "byok", "minimax", "minimax-text-01", minimax_key
            from app.core.config import settings
            if settings.minimax_api_key and settings.minimax_api_key.strip():
                return "platform_managed", "minimax", "minimax-text-01", None
        elif pref == "openai":
            if openai_key and openai_key.strip():
                return "byok", "openai", "gpt-4o", openai_key
            from app.core.config import settings
            if settings.openai_api_key and settings.openai_api_key.strip():
                return "platform_managed", "openai", "gpt-4o", None
        elif pref == "gemini":
            return "platform_managed", "gemini", None, None

    # Fallback to auto-priority resolution if no preference or preference not configurable
    # 1. Custom keys (BYOK)
    if deepseek_key and deepseek_key.strip():
        return "byok", "deepseek", "deepseek-chat", deepseek_key
    elif minimax_key and minimax_key.strip():
        return "byok", "minimax", "minimax-text-01", minimax_key
    elif openai_key and openai_key.strip():
        return "byok", "openai", "gpt-4o", openai_key

    # 2. Server global keys from .env
    from app.core.config import settings
    if settings.deepseek_api_key and settings.deepseek_api_key.strip():
        return "platform_managed", "deepseek", "deepseek-chat", None
    elif settings.minimax_api_key and settings.minimax_api_key.strip():
        return "platform_managed", "minimax", "minimax-text-01", None
    else:
        return "platform_managed", "gemini", None, None


@router.post("/recommend-routine")
async def recommend_routine(
    payload: AIRecommendRoutineRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    mode, provider, model, user_key = _resolve_ai_settings(current_user)

    allowed, retry_after = check_rate_limit(current_user["id"], mode)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "RATE_LIMIT_EXCEEDED",
                "message": f"Límite de llamadas superado. Retry-After: {retry_after}s",
            },
            headers={"Retry-After": str(retry_after)},
        )

    allowed_quota, _ = check_token_quota(current_user["id"], mode)
    if not allowed_quota:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "TOKEN_QUOTA_EXCEEDED",
                "message": "Cuota de tokens diaria agotada para el plan actual.",
            },
        )

    from app.repositories import get_perfil_by_usuario
    from app.db import get_db_connection, db_connection_context

    perfil_data = None
    with db_connection_context() as conn:
        perfil = get_perfil_by_usuario(conn, current_user["id"])
        if perfil:
            perfil_data = {
                "objetivo_principal": perfil.objetivo_principal,
                "lesiones": perfil.lesiones or [],
            }

    messages = _build_routine_prompt(payload, perfil_data)

    try:
        response = await ai_client.chat(
            provider=provider,
            model=model,
            messages=messages,
            mode=mode,
            user_api_key=user_key,
            user_id=current_user["id"],
            tipo_consulta="recommend_routine",
            max_tokens=2048,
            temperature=0.7,
        )

        text = ai_client._extract_text_response(response, provider) or ""
        try:
            rutina_gen = json.loads(text)
        except json.JSONDecodeError:
            rutina_gen = {"raw_response": text}

        return {
            "ok": True,
            "rutina_generada": rutina_gen,
            "proveedor": provider,
            "modelo": ai_client._resolve_model(provider, model),
            "modo": mode,
        }
    except AIError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": e.code, "message": e.message},
        )


@router.post("/analyze-session")
async def analyze_session(
    payload: AIAnalyzeSessionRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    mode, provider, model, user_key = _resolve_ai_settings(current_user)

    allowed, retry_after = check_rate_limit(current_user["id"], mode)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "RATE_LIMIT_EXCEEDED",
                "message": f"Límite de llamadas superado. Retry-After: {retry_after}s",
            },
            headers={"Retry-After": str(retry_after)},
        )

    from app.repositories import get_sesion_by_id
    from app.db import get_db_connection, db_connection_context

    with db_connection_context() as conn:
        sesion = get_sesion_by_id(conn, payload.sesion_id, current_user["id"])
        if not sesion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "SESSION_NOT_FOUND", "message": "Sesión no encontrada"},
            )
        sesion_data = {
            "nombre": sesion.nombre,
            "estado": sesion.estado,
            "duracion_minutos": sesion.duracion_minutos,
        }

    messages = _build_analyze_prompt(payload.sesion_id, sesion_data, payload.notas_adicionales)

    try:
        response = await ai_client.chat(
            provider=provider,
            model=model,
            messages=messages,
            mode=mode,
            user_api_key=user_key,
            user_id=current_user["id"],
            tipo_consulta="analyze_session",
            max_tokens=1024,
            temperature=0.7,
        )

        text = ai_client._extract_text_response(response, provider) or ""

        return {
            "ok": True,
            "analisis": text,
            "proveedor": provider,
            "modelo": ai_client._resolve_model(provider, model),
            "modo": mode,
        }
    except AIError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": e.code, "message": e.message},
        )


def _post_process_weekly_plan(plan_raw: dict, maquinas_map: dict[str, dict]) -> PlanSemanalJSON:
    dias_semana_map = {
        0: "Lunes",
        1: "Martes",
        2: "Miércoles",
        3: "Jueves",
        4: "Viernes",
        5: "Sábado",
        6: "Domingo"
    }
    
    dias_dict = {
        i: PlanDia(
            dia_semana=i,
            nombre_dia=dias_semana_map[i],
            tipo="rest",
            bloques=[],
            descanso_entre_bloques_minutos=0,
            tiempo_total_estimado_minutos=0,
        )
        for i in range(7)
    }

    for d in plan_raw.get("dias", []):
        dia_idx = d.get("dia_semana")
        if dia_idx is None or dia_idx < 0 or dia_idx > 6:
            continue
            
        bloques = []
        for b in d.get("bloques", []):
            ejercicios = []
            for e in b.get("ejercicios", []):
                # Sanitize and coerce fields to prevent Pydantic ValidationErrors
                if "nombre_ejercicio" not in e or e["nombre_ejercicio"] is None:
                    e["nombre_ejercicio"] = "Ejercicio"
                e["nombre_ejercicio"] = str(e["nombre_ejercicio"])

                if "grupo_muscular" in e and e["grupo_muscular"] is not None:
                    e["grupo_muscular"] = str(e["grupo_muscular"])

                if "series" in e:
                    try:
                        e["series"] = int(e["series"])
                    except (ValueError, TypeError):
                        e["series"] = 3

                if "repeticiones" in e:
                    e["repeticiones"] = str(e["repeticiones"])

                if "descanso_segundos" in e:
                    try:
                        e["descanso_segundos"] = int(e["descanso_segundos"])
                    except (ValueError, TypeError):
                        e["descanso_segundos"] = 90

                if "rir_o_rpe" in e and e["rir_o_rpe"] is not None:
                    e["rir_o_rpe"] = str(e["rir_o_rpe"])

                if "notas" in e and e["notas"] is not None:
                    e["notas"] = str(e["notas"])

                if "machine_id" in e:
                    mid = e["machine_id"]
                    if mid is None or str(mid).strip().lower() in ("null", "none", "0", ""):
                        e["machine_id"] = None
                    else:
                        e["machine_id"] = str(mid)

                if "machine_nombre" in e:
                    mnom = e["machine_nombre"]
                    if mnom is None or str(mnom).strip().lower() in ("null", "none", "0", ""):
                        e["machine_nombre"] = None
                    else:
                        e["machine_nombre"] = str(mnom)

                if "machine_foto_url" in e:
                    mfoto = e["machine_foto_url"]
                    if mfoto is None or str(mfoto).strip().lower() in ("null", "none", "0", ""):
                        e["machine_foto_url"] = None
                    else:
                        e["machine_foto_url"] = str(mfoto)

                # Now perform the mapping against user's custom machines
                machine_id = e.get("machine_id") or e.get("machine_nombre")
                if machine_id and machine_id in maquinas_map:
                    machine_ref = maquinas_map[machine_id]
                    e["machine_id"] = machine_ref["id"]
                    e["machine_nombre"] = machine_ref["nombre"]
                    e["machine_foto_url"] = machine_ref.get("foto_path")

                ejercicios.append(PlanDiaEjercicio(**e))
            bloques.append(PlanDiaBloque(
                tipo=b.get("tipo", ""),
                nombre=b.get("nombre", ""),
                duracion_minutos=b.get("duracion_minutos"),
                ejercicios=ejercicios,
            ))
            
        dias_dict[dia_idx] = PlanDia(
            dia_semana=dia_idx,
            nombre_dia=d.get("nombre_dia", dias_semana_map[dia_idx]),
            tipo=d.get("tipo", "workout"),
            bloques=bloques,
            descanso_entre_bloques_minutos=d.get("descanso_entre_bloques_minutos", 2),
            tiempo_total_estimado_minutos=d.get("tiempo_total_estimado_minutos"),
            notas=d.get("notas"),
        )
        
    dias_ordenados = [dias_dict[i] for i in range(7)]
    return PlanSemanalJSON(dias=dias_ordenados, nota_general=plan_raw.get("nota_general"))


@router.post("/weekly-plan", response_model=AIWeeklyPlanResponse)
async def generate_weekly_plan(
    payload: AIWeeklyPlanRequest,
    current_user: dict = Depends(get_current_user),
) -> AIWeeklyPlanResponse:
    mode, provider, model, user_key = _resolve_ai_settings(current_user)

    allowed, retry_after = check_rate_limit(current_user["id"], mode)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "RATE_LIMIT_EXCEEDED",
                "message": f"Límite de llamadas superado. Retry-After: {retry_after}s",
            },
            headers={"Retry-After": str(retry_after)},
        )

    allowed_quota, _ = check_token_quota(current_user["id"], mode)
    if not allowed_quota:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "TOKEN_QUOTA_EXCEEDED",
                "message": "Cuota de tokens diaria agotada para el plan actual.",
            },
        )

    from app.repositories import get_perfil_by_usuario, list_maquinas
    from app.db import get_db_connection, db_connection_context

    perfil_data = None
    maquinas_info: list[dict] = []
    maquinas_map: dict[str, dict] = {}
    with db_connection_context() as conn:
        perfil = get_perfil_by_usuario(conn, current_user["id"])
        if perfil:
            perfil_data = {
                "objetivo_principal": perfil.objetivo_principal,
                "lesiones": perfil.lesiones or [],
            }
        if payload.maquinas_usuario_ids:
            maquinas = list_maquinas(conn, current_user["id"])
            for m in maquinas:
                if m.id in payload.maquinas_usuario_ids or m.nombre in payload.maquinas_usuario_ids:
                    mi = {"id": m.id, "nombre": m.nombre, "grupo_muscular": m.grupo_muscular, "foto_path": m.foto_path}
                    maquinas_info.append(mi)
                    maquinas_map[m.id] = mi
                    maquinas_map[m.nombre] = mi

    def _get_active_days(dias_por_semana: int) -> list[int]:
        if dias_por_semana <= 1:
            return [0]
        elif dias_por_semana == 2:
            return [0, 3]
        elif dias_por_semana == 3:
            return [0, 2, 4]
        elif dias_por_semana == 4:
            return [0, 1, 3, 4]
        elif dias_por_semana == 5:
            return [0, 1, 3, 4, 5]
        elif dias_por_semana == 6:
            return [0, 1, 2, 3, 4, 5]
        else:
            return [0, 1, 2, 3, 4, 5, 6]

    active_days_indices = _get_active_days(payload.dias_por_semana)
    dias_generados = []

    import asyncio

    async def _generate_single_day(dia_idx: int) -> dict:
        dia_nombre = DIAS_SEMANA[dia_idx]
        enfoque = _get_day_focus(dia_idx, payload.dias_por_semana)
        
        single_day_messages = _build_weekly_plan_single_day_prompt(
            req=payload,
            perfil=perfil_data,
            maquinas_info=maquinas_info,
            dia_idx=dia_idx,
            dia_nombre=dia_nombre,
            enfoque_muscular=enfoque,
        )

        response = await ai_client.chat(
            provider=provider,
            model=model,
            messages=single_day_messages,
            mode=mode,
            user_api_key=user_key,
            user_id=current_user["id"],
            tipo_consulta="weekly_plan",
            max_tokens=4096,
            temperature=0.7,
        )

        text = ai_client._extract_text_response(response, provider) or ""
        cleaned_text = text.strip()
        if cleaned_text.startswith("```json"):
            cleaned_text = cleaned_text[7:]
        if cleaned_text.endswith("```"):
            cleaned_text = cleaned_text[:-3]
        cleaned_text = cleaned_text.strip()

        try:
            return json.loads(cleaned_text)
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail={"code": "INVALID_JSON", "message": f"La IA no devolvió JSON válido para {dia_nombre}: {text[:200]}"},
            )

    try:
        # Ejecutar todas las llamadas de día en PARALELO
        dias_generados = await asyncio.gather(*[_generate_single_day(idx) for idx in active_days_indices])

        plan_raw = {
            "dias": dias_generados,
            "nota_general": f"Plan semanal personalizado de {payload.dias_por_semana} días enfocado en {payload.objetivo}."
        }

        plan_validado = _post_process_weekly_plan(plan_raw, maquinas_map)

        from app.repositories import create_plan_semanal
        plan_data = {
            "nombre": f"Plan {payload.objetivo} - Semana",
            "objetivo": payload.objetivo,
            "nivel": payload.nivel_experiencia,
            "duracion_max_minutos": payload.duracion_max_minutos,
            "dias_entreno_objetivo": payload.dias_por_semana,
            "equipo_disponible": payload.equipo_disponible,
            "lesiones_o_limitaciones": payload.lesiones_o_limitaciones,
            "plan_json": plan_validado.model_dump(),
            "metadata_ia": {
                "proveedor": provider,
                "modelo": ai_client._resolve_model(provider, model),
                "modo": mode,
            },
        }
        with db_connection_context() as conn:
            plan_guardado = create_plan_semanal(conn, current_user["id"], plan_data)

        return AIWeeklyPlanResponse(
            ok=True,
            plan_guardado=plan_guardado,
            proveedor=provider,
            modelo=ai_client._resolve_model(provider, model),
            modo=mode,
        )
    except AIError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": e.code, "message": e.message},
        )
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "code": "PLAN_PROCESSING_FAILED",
                "message": f"Error procesando, validando o guardando el plan semanal generado: {str(e)}"
            },
        )


def _build_modify_plan_prompt(
    original_plan_json: dict,
    instrucciones: str,
) -> list[dict[str, str]]:
    prompt = f"""Eres un entrenador personal experto con años de experiencia diseñando y modificando planes semanales progresivos para gyms.

Tu objetivo es MODIFICAR la rutina actual de entrenamiento siguiendo estrictamente las siguientes instrucciones de modificación provistas por el usuario:
"{instrucciones}"

A continuación se detalla la rutina semanal actual en formato JSON:
{json.dumps(original_plan_json, indent=2, ensure_ascii=False)}

INSTRUCCIONES PARA LA GENERACIÓN:
1. Identifica qué días específicos deben modificarse en base a las instrucciones del usuario.
2. Para cada día que requiera modificación, rediseña sus bloques de ejercicios (calentamiento, principal, enfriamiento) aplicando el cambio solicitado.
3. Las instrucciones de ejecución (campo "notas" dentro de cada ejercicio) para los ejercicios modificados o nuevos deben ser claras y descriptivas, de unas 2-3 líneas de texto técnico (máximo 25 palabras).
4. El tipo del día debe ser "workout" si hay entrenamiento, o "rest"/"active_recovery" según corresponda.
5. Devuelve ÚNICAMENTE los días que han sufrido alguna modificación en la lista "dias_modificados" de la respuesta JSON. Los días que no cambian NO deben incluirse para ahorrar tokens.

FORMATO JSON DE RESPUESTA (Solo devuelve este objeto JSON sin bloques de código, sin markdown, sin texto aclaratorio):
{{
  "dias_modificados": [
    {{
      "dia_semana": 0,
      "nombre_dia": "Lunes",
      "tipo": "workout",
      "bloques": [
        {{
          "tipo": "calentamiento",
          "nombre": "Calentamiento específico",
          "duracion_minutos": 8,
          "ejercicios": [
            {{
              "nombre_ejercicio": "nombre del ejercicio",
              "grupo_muscular": "grupo muscular",
              "series": 3,
              "repeticiones": "10-12",
              "descanso_segundos": 60,
              "rir_o_rpe": "RPE 7",
              "notas": "Instrucciones de ejecución técnica detalladas de 2 a 3 líneas.",
              "machine_id": null,
              "machine_nombre": "nombre de la máquina o equipo",
              "machine_foto_url": null
            }}
          ]
        }}
      ],
      "descanso_entre_bloques_minutos": 2,
      "tiempo_total_estimado_minutos": 60,
      "notas": "Descripción breve del enfoque muscular o metabólico de esta sesión."
    }}
  ]
}}"""

    return [
        {
            "role": "system",
            "content": "Eres un entrenador personal experto. Tu salida debe ser estrictamente un objeto JSON válido con los días modificados, sin explicaciones, sin markdown, sin bloques de código.",
        },
        {"role": "user", "content": prompt},
    ]


@router.post("/modify-plan", response_model=AIWeeklyPlanResponse)
async def modify_weekly_plan(
    payload: AIModifyPlanRequest,
    current_user: dict = Depends(get_current_user),
) -> AIWeeklyPlanResponse:
    mode, provider, model, user_key = _resolve_ai_settings(current_user)

    allowed, retry_after = check_rate_limit(current_user["id"], mode)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "RATE_LIMIT_EXCEEDED",
                "message": f"Límite de llamadas superado. Retry-After: {retry_after}s",
            },
            headers={"Retry-After": str(retry_after)},
        )

    from app.repositories import get_plan_by_id, update_plan_semanal, list_maquinas
    from app.db import db_connection_context

    # 1. Cargar el plan original
    with db_connection_context() as conn:
        original_plan = get_plan_by_id(conn, payload.plan_id, current_user["id"])
        if not original_plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "PLAN_NOT_FOUND", "message": "El plan especificado no existe."},
            )
        
        # Mapear máquinas del usuario para el post-procesamiento
        maquinas_map = {}
        maquinas = list_maquinas(conn, current_user["id"])
        for m in maquinas:
            mi = {"id": m.id, "nombre": m.nombre, "grupo_muscular": m.grupo_muscular, "foto_path": m.foto_path}
            maquinas_map[m.id] = mi
            maquinas_map[m.nombre] = mi

    original_plan_json = original_plan.plan_json

    # 2. Generar prompt de modificación
    messages = _build_modify_plan_prompt(original_plan_json, payload.instrucciones)

    try:
        response = await ai_client.chat(
            provider=provider,
            model=model,
            messages=messages,
            mode=mode,
            user_api_key=user_key,
            user_id=current_user["id"],
            tipo_consulta="weekly_plan",
            max_tokens=4096,
            temperature=0.7,
        )

        text = ai_client._extract_text_response(response, provider) or ""
        cleaned_text = text.strip()
        if cleaned_text.startswith("```json"):
            cleaned_text = cleaned_text[7:]
        if cleaned_text.endswith("```"):
            cleaned_text = cleaned_text[:-3]
        cleaned_text = cleaned_text.strip()

        try:
            mod_raw = json.loads(cleaned_text)
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail={"code": "INVALID_JSON", "message": f"La IA no devolvió JSON válido para la modificación: {text[:200]}"},
            )

        # 3. Fusionar los días modificados en la estructura original
        original_dias = original_plan_json.get("dias", [])
        dias_modificados = mod_raw.get("dias_modificados", [])
        
        # Mapear días originales por dia_semana para facilitar el reemplazo
        dias_map = {d.get("dia_semana"): d for d in original_dias}
        for d_mod in dias_modificados:
            dia_idx = d_mod.get("dia_semana")
            if dia_idx is not None and 0 <= dia_idx <= 6:
                dias_map[dia_idx] = d_mod

        # Reconstruir la lista ordenada de 7 días
        dias_ordenados = [dias_map.get(i) for i in range(7) if dias_map.get(i) is not None]
        # Si por alguna razón faltan días, rellenar
        while len(dias_ordenados) < 7:
            missing_idx = len(dias_ordenados)
            dias_ordenados.append({
                "dia_semana": missing_idx,
                "nombre_dia": DIAS_SEMANA[missing_idx],
                "tipo": "rest",
                "bloques": [],
                "descanso_entre_bloques_minutos": 0,
                "tiempo_total_estimado_minutos": 0,
                "notas": "Día de descanso"
            })

        # Armar el plan completo fusionado
        plan_fusionado_raw = {
            "dias": dias_ordenados,
            "nota_general": original_plan_json.get("nota_general")
        }

        # Validar con el post-procesador
        plan_validado = _post_process_weekly_plan(plan_fusionado_raw, maquinas_map)

        # 4. Actualizar el plan en la base de datos
        plan_data = {
            "plan_json": plan_validado.model_dump(),
            "metadata_ia": {
                "proveedor": provider,
                "modelo": ai_client._resolve_model(provider, model),
                "modo": mode,
                "modificado": True,
                "mod_instrucciones": payload.instrucciones
            },
        }

        with db_connection_context() as conn:
            plan_guardado = update_plan_semanal(conn, original_plan.id, current_user["id"], plan_data)

        return AIWeeklyPlanResponse(
            ok=True,
            plan_guardado=plan_guardado,
            proveedor=provider,
            modelo=ai_client._resolve_model(provider, model),
            modo=mode,
        )
    except AIError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": e.code, "message": e.message},
        )


@router.post("/machines/upload", response_model=MaquinaGymResponse)
async def upload_machine(
    nombre: str = Form(...),
    grupo_muscular: str | None = Form(None),
    descripcion_uso: str | None = Form(None),
    file: UploadFile | None = File(None),
    current_user: dict = Depends(get_current_user),
) -> MaquinaGymResponse:
    foto_path = None
    if file:
        if file.size and file.size > 10 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="Archivo demasiado grande (max 10MB)",
            )
        ext = Path(file.filename or "img").suffix.lower()
        if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail="Solo se permiten imágenes jpg, png, webp",
            )
        user_dir = STORAGE_DIR / current_user["id"]
        user_dir.mkdir(parents=True, exist_ok=True)
        safe_name = "".join(c for c in nombre if c.isalnum() or c in ("_", "-", " ")).strip()[:50]
        filename = f"{uuid.uuid4().hex}_{safe_name}{ext}"
        file_path = user_dir / filename
        with file_path.open("wb") as f:
            content = await file.read()
            f.write(content)
        foto_path = str(file_path)

    from app.repositories import create_maquina
    from app.db import get_db_connection, db_connection_context

    with db_connection_context() as conn:
        maquina = create_maquina(
            conn,
            usuario_id=current_user["id"],
            nombre=nombre,
            foto_path=foto_path,
            descripcion_uso=descripcion_uso,
            grupo_muscular=grupo_muscular,
        )
    return MaquinaGymResponse.model_validate(maquina)


@router.get("/machines", response_model=list[MaquinaGymResponse])
async def list_machines(current_user: dict = Depends(get_current_user)) -> list[MaquinaGymResponse]:
    from app.repositories import list_maquinas
    from app.db import get_db_connection, db_connection_context

    with db_connection_context() as conn:
        maquinas = list_maquinas(conn, current_user["id"])
    return [MaquinaGymResponse.model_validate(m) for m in maquinas]


@router.delete("/machines/{machine_id}")
async def delete_machine(machine_id: str, current_user: dict = Depends(get_current_user)) -> dict:
    from app.repositories import get_maquina_by_id, delete_maquina
    from app.db import get_db_connection, db_connection_context

    with db_connection_context() as conn:
        maquina = get_maquina_by_id(conn, machine_id, current_user["id"])
        if not maquina:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "MACHINE_NOT_FOUND", "message": "Máquina no encontrada"},
            )
        if maquina.foto_path:
            try:
                Path(maquina.foto_path).unlink(missing_ok=True)
            except OSError:
                pass
        delete_maquina(conn, machine_id, current_user["id"])
    return {"ok": True}


@router.get("/plans", response_model=list[PlanSemanalResponse])
async def list_plans(
    skip: int = 0,
    limit: int = 20,
    solo_activos: bool = False,
    current_user: dict = Depends(get_current_user),
) -> list[PlanSemanalResponse]:
    from app.repositories import list_planes_semanales
    from app.db import get_db_connection, db_connection_context

    with db_connection_context() as conn:
        planes = list_planes_semanales(conn, current_user["id"], skip, limit, solo_activos)
    return [PlanSemanalResponse.model_validate(p) for p in planes]


@router.get("/plans/{plan_id}", response_model=PlanSemanalResponse)
async def get_plan(plan_id: str, current_user: dict = Depends(get_current_user)) -> PlanSemanalResponse:
    from app.repositories import get_plan_by_id
    from app.db import get_db_connection, db_connection_context

    with db_connection_context() as conn:
        plan = get_plan_by_id(conn, plan_id, current_user["id"])
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "PLAN_NOT_FOUND", "message": "Plan no encontrado"},
            )
    return PlanSemanalResponse.model_validate(plan)


@router.delete("/plans/{plan_id}")
async def delete_plan(plan_id: str, current_user: dict = Depends(get_current_user)) -> dict:
    from app.repositories import delete_plan_semanal, get_plan_by_id
    from app.db import db_connection_context

    with db_connection_context() as conn:
        plan = get_plan_by_id(conn, plan_id, current_user["id"])
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "PLAN_NOT_FOUND", "message": "Plan no encontrado"},
            )
        delete_plan_semanal(conn, plan_id, current_user["id"])
    return {"ok": True}


@router.post("/plans/{plan_id}/activate", response_model=PlanSemanalResponse)
async def activate_plan_endpoint(
    plan_id: str,
    current_user: dict = Depends(get_current_user),
) -> PlanSemanalResponse:
    from app.repositories import activate_plan, get_plan_by_id
    from app.db import db_connection_context

    with db_connection_context() as conn:
        plan = get_plan_by_id(conn, plan_id, current_user["id"])
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "PLAN_NOT_FOUND", "message": "Plan no encontrado"},
            )
        activate_plan(conn, plan_id, current_user["id"])
        # Refetch the plan to get the updated status
        updated_plan = get_plan_by_id(conn, plan_id, current_user["id"])
    return PlanSemanalResponse.model_validate(updated_plan)


@router.post("/plans/{plan_id}/add-exercises", response_model=PlanSemanalResponse)
async def add_exercises_to_plan(
    plan_id: str,
    payload: dict,
    current_user: dict = Depends(get_current_user),
) -> PlanSemanalResponse:
    from app.repositories import get_plan_by_id, update_plan_semanal, get_ejercicio_usuario_by_id
    from app.db import db_connection_context

    dia_semana = payload.get("dia_semana")
    bloque_tipo = payload.get("bloque_tipo")
    ejercicios_ids = payload.get("ejercicios_ids", [])

    if dia_semana is None or not bloque_tipo or not ejercicios_ids:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Se requieren dia_semana, bloque_tipo y ejercicios_ids",
        )

    with db_connection_context() as conn:
        plan = get_plan_by_id(conn, plan_id, current_user["id"])
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "PLAN_NOT_FOUND", "message": "Plan no encontrado"},
            )

        plan_json = plan.plan_json
        dias = plan_json.get("dias", [])
        target_dia = None
        for d in dias:
            if d.get("dia_semana") == dia_semana:
                target_dia = d
                break

        if not target_dia:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Día no encontrado en el plan",
            )

        bloques = target_dia.get("bloques", [])
        target_bloque = None
        for b in bloques:
            if b.get("tipo") == bloque_tipo:
                target_bloque = b
                break

        if not target_bloque:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Bloque no encontrado en el día",
            )

        for eid in ejercicios_ids:
            ej = get_ejercicio_usuario_by_id(conn, eid, current_user["id"])
            if not ej:
                continue
            target_bloque["ejercicios"].append({
                "nombre_ejercicio": ej.nombre,
                "grupo_muscular": ej.grupo_muscular,
                "series": ej.series,
                "repeticiones": ej.repeticiones or "10-12",
                "descanso_segundos": ej.descanso_segundos,
                "rir_o_rpe": ej.rir_o_pe,
                "notas": ej.notas,
                "machine_id": None,
                "machine_nombre": ej.machine_nombre,
                "machine_foto_url": ej.machine_foto_path,
            })

        updated = update_plan_semanal(conn, plan_id, current_user["id"], {"plan_json": plan_json})
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Error actualizando el plan",
            )
        updated_plan = get_plan_by_id(conn, plan_id, current_user["id"])
    return PlanSemanalResponse.model_validate(updated_plan)


def _build_exercise_help_messages(
    nombre_ejercicio: str,
    grupo_muscular: str | None,
    machine_nombre: str | None,
    notas_plan: str | None,
    pregunta: str | None,
    image_b64: str | None,
    image_media_type: str,
    provider: str,
    lesiones: list[str] | None = None,
) -> list[dict]:
    system_msg = (
        "Eres un entrenador personal experto con profundo conocimiento en biomecánica, "
        "técnica deportiva y entrenamiento de fuerza. Responde de forma clara, práctica "
        "y motivadora en español."
    )

    context_lines = [f"Ejercicio: **{nombre_ejercicio}**"]
    if grupo_muscular:
        context_lines.append(f"Grupo muscular: {grupo_muscular}")
    if machine_nombre:
        context_lines.append(f"Máquina/Equipo: {machine_nombre}")
    if notas_plan:
        context_lines.append(f"Notas del plan: {notas_plan}")
    context = "\n".join(context_lines)

    lesiones_block = ""
    if lesiones:
        lesiones_str = ", ".join(lesiones)
        lesiones_block = (
            f"\n\n⚠️ LIMITACIONES FÍSICAS DEL USUARIO (OBLIGATORIO tenerlas en cuenta): {lesiones_str}\n"
            "Adapta TODA la explicación a estas limitaciones. Para cada una que sea relevante indica "
            "explícitamente cómo modificar el ejercicio: ángulos articulares, apertura o cierre de piernas, "
            "altura de los pies, rango de movimiento seguro, músculos estabilizadores a activar, qué evitar "
            "y por qué. Si la limitación no afecta a este ejercicio, indícalo brevemente."
        )

    if image_b64 and pregunta:
        text = (
            f"{context}{lesiones_block}\n\n"
            f"El usuario ha enviado una fotografía y pregunta: \"{pregunta}\"\n\n"
            "Analiza la imagen y evalúa si la posición o técnica mostrada es correcta para "
            "este ejercicio, teniendo en cuenta sus limitaciones físicas. Sé específico sobre "
            "qué está bien y qué debe corregir para proteger sus zonas afectadas."
        )
    elif image_b64:
        text = (
            f"{context}{lesiones_block}\n\n"
            "El usuario ha enviado una fotografía de su posición o de la máquina. "
            "Analiza si la posición o técnica mostrada es correcta para este ejercicio "
            "considerando sus limitaciones físicas. Indica qué está bien y qué debe corregir."
        )
    elif pregunta:
        text = (
            f"{context}{lesiones_block}\n\n"
            f"Pregunta del usuario: \"{pregunta}\"\n\n"
            "Responde de forma clara y técnica, adaptando la respuesta a sus limitaciones físicas."
        )
    else:
        text = (
            f"{context}{lesiones_block}\n\n"
            "Dame una explicación detallada y práctica de cómo realizar este ejercicio correctamente "
            "adaptada a las limitaciones físicas indicadas:\n"
            "1. Posición inicial y configuración del equipo (con ajustes por limitaciones si aplica)\n"
            "2. Técnica de ejecución paso a paso\n"
            "3. Músculos principales y secundarios trabajados\n"
            "4. Adaptaciones específicas por cada limitación física relevante\n"
            "5. Errores comunes a evitar (especialmente los que pueden agravar las lesiones)\n"
            "6. Respiración adecuada durante el movimiento\n"
            "7. Consejos para progresar con seguridad respetando las limitaciones"
        )

    supports_vision = provider in ("openai", "gemini")

    if image_b64 and supports_vision:
        user_content: list | str = [
            {"type": "text", "text": text},
            {"type": "image_url", "image_url": {"url": f"data:{image_media_type};base64,{image_b64}"}},
        ]
    else:
        if image_b64 and not supports_vision:
            text += "\n\n(Nota: el análisis de imágenes no está disponible con tu proveedor de IA actual.)"
        user_content = text

    return [
        {"role": "system", "content": system_msg},
        {"role": "user", "content": user_content},
    ]


@router.post("/exercise-help", response_model=AIExerciseHelpResponse)
async def exercise_help(
    nombre_ejercicio: str = Form(...),
    grupo_muscular: str | None = Form(None),
    machine_nombre: str | None = Form(None),
    notas_plan: str | None = Form(None),
    pregunta: str | None = Form(None),
    file: UploadFile | None = File(None),
    current_user: dict = Depends(get_current_user),
) -> AIExerciseHelpResponse:
    mode, provider, model, user_key = _resolve_ai_settings(current_user)

    allowed, retry_after = check_rate_limit(current_user["id"], mode)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"code": "RATE_LIMIT_EXCEEDED", "message": f"Límite de llamadas superado. Retry-After: {retry_after}s"},
            headers={"Retry-After": str(retry_after)},
        )

    image_b64: str | None = None
    image_media_type = "image/jpeg"
    if file:
        if file.size and file.size > 10 * 1024 * 1024:
            raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="Imagen demasiado grande (máx 10MB)")
        content = await file.read()
        image_b64 = base64.b64encode(content).decode()
        image_media_type = file.content_type or "image/jpeg"

    # Gather user's physical limitations from active plan + health profile
    from app.repositories import get_perfil_by_usuario, list_planes_semanales
    from app.db import db_connection_context

    lesiones: list[str] = []
    with db_connection_context() as conn:
        planes = list_planes_semanales(conn, current_user["id"], skip=0, limit=1, solo_activos=True)
        if planes and planes[0].lesiones_o_limitaciones:
            lesiones.extend(planes[0].lesiones_o_limitaciones)
        perfil = get_perfil_by_usuario(conn, current_user["id"])
        if perfil and perfil.lesiones:
            for l in perfil.lesiones:
                if l not in lesiones:
                    lesiones.append(l)

    messages = _build_exercise_help_messages(
        nombre_ejercicio=nombre_ejercicio,
        grupo_muscular=grupo_muscular,
        machine_nombre=machine_nombre,
        notas_plan=notas_plan,
        pregunta=pregunta,
        image_b64=image_b64,
        image_media_type=image_media_type,
        provider=provider,
        lesiones=lesiones if lesiones else None,
    )

    try:
        response = await ai_client.chat(
            provider=provider,
            model=model,
            messages=messages,
            mode=mode,
            user_api_key=user_key,
            user_id=current_user["id"],
            tipo_consulta="exercise_help",
            max_tokens=1024,
            temperature=0.7,
        )
        text = ai_client._extract_text_response(response, provider) or "No se pudo obtener respuesta."
        return AIExerciseHelpResponse(
            ok=True,
            respuesta=text,
            proveedor=provider,
            modelo=ai_client._resolve_model(provider, model),
            modo=mode,
        )
    except AIError as e:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail={"code": e.code, "message": e.message})


def _build_machine_propose_prompt(descripcion_uso: str) -> list[dict[str, str]]:
    prompt = f"""Analiza la siguiente explicación de una máquina de gimnasio para la cual el usuario quiere generar su ficha:
    
Explicación del usuario: "{descripcion_uso}"

Debes proponer:
1. Un nombre corto y profesional para la máquina en español (máximo 5 palabras).
2. El grupo muscular principal que trabaja (debe ser uno de los siguientes en minúsculas: "pecho", "espalda", "hombros", "biceps", "triceps", "cuadriceps", "isquiotibiales", "gluteos", "gemelos", "core", "general").
3. Una lista de 1 a 3 ejercicios específicos que se pueden realizar en esta máquina. Cada ejercicio debe tener:
   - "nombre_ejercicio": Nombre descriptivo en español.
   - "series": Número recomendado de series (entero, ej: 4).
   - "repeticiones": Rango recomendado de repeticiones (ej: "10-12").
   - "descanso_segundos": Tiempo recomendado de descanso (ej: 90).
   - "notas": Instrucción técnica ultra concisa de ejecución (máximo 15 palabras).

FORMATO JSON DE RESPUESTA ESTRICTO (Solo devuelve este objeto JSON sin bloques de código, sin markdown, sin texto aclaratorio):
{{
  "nombre": "nombre propuesto",
  "grupo_muscular": "grupo muscular",
  "descripcion_uso": "Explicación sintetizada y limpia de uso en una frase",
  "ejercicios": [
    {{
      "nombre_ejercicio": "ejercicio 1",
      "series": 4,
      "repeticiones": "10-12",
      "descanso_segundos": 90,
      "notes": "Mantén los codos pegados al cuerpo durante la ejecución."
    }}
  ]
}}
"""
    return [
        {
            "role": "system",
            "content": "Eres un entrenador personal experto. Tu salida debe ser estrictamente un objeto JSON válido, sin explicaciones, sin markdown, sin bloques de código.",
        },
        {"role": "user", "content": prompt},
    ]


@router.post("/machines/propose", response_model=AIMachineProposeResponse)
async def propose_machine(
    payload: AIMachineProposeRequest,
    current_user: dict = Depends(get_current_user),
) -> AIMachineProposeResponse:
    mode, provider, model, user_key = _resolve_ai_settings(current_user)

    allowed, retry_after = check_rate_limit(current_user["id"], mode)
    if not allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "RATE_LIMIT_EXCEEDED",
                "message": f"Límite de llamadas superado. Retry-After: {retry_after}s",
            },
            headers={"Retry-After": str(retry_after)},
        )

    messages = _build_machine_propose_prompt(payload.descripcion_uso)

    try:
        response = await ai_client.chat(
            provider=provider,
            model=model,
            messages=messages,
            mode=mode,
            user_api_key=user_key,
            user_id=current_user["id"],
            tipo_consulta="propose_machine",
            max_tokens=2048,
            temperature=0.7,
        )

        text = ai_client._extract_text_response(response, provider) or ""
        cleaned_text = text.strip()
        if cleaned_text.startswith("```json"):
            cleaned_text = cleaned_text[7:]
        if cleaned_text.endswith("```"):
            cleaned_text = cleaned_text[:-3]
        cleaned_text = cleaned_text.strip()

        try:
            proposal_raw = json.loads(cleaned_text)
        except json.JSONDecodeError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail={"code": "INVALID_JSON", "message": f"La IA no devolvió JSON válido para la máquina: {text[:200]}"},
            )

        # Map 'notes' key to 'notas' if LLM returned 'notes' in the exercises list
        exercises_raw = proposal_raw.get("ejercicios", [])
        exercises_processed = []
        for e in exercises_raw:
            notas_val = e.get("notas") or e.get("notes") or ""
            exercises_processed.append({
                "nombre_ejercicio": e.get("nombre_ejercicio", ""),
                "series": e.get("series", 4),
                "repeticiones": e.get("repeticiones", "10-12"),
                "descanso_segundos": e.get("descanso_segundos", 90),
                "notas": notas_val
            })

        return AIMachineProposeResponse(
            ok=True,
            nombre=proposal_raw.get("nombre", "Nueva Máquina"),
            grupo_muscular=proposal_raw.get("grupo_muscular", "general"),
            descripcion_uso=proposal_raw.get("descripcion_uso", payload.descripcion_uso),
            ejercicios=exercises_processed,
            proveedor=provider,
            modelo=ai_client._resolve_model(provider, model),
            modo=mode,
        )
    except AIError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": e.code, "message": e.message},
        )