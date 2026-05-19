from html import escape

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy import text
from sqlalchemy.engine import Connection

from app.core.config import settings
from app.db import get_db_connection
from app.models.exercise import Exercise
from app.models.user_profile import UserProfileUpsert
from app.models.workout_session import WorkoutSessionCreate
from app.repositories import build_ai_status
from app.repositories import create_workout_session as create_workout_session_in_db
from app.repositories import get_exercise as get_exercise_from_db
from app.repositories import get_user_profile as get_user_profile_from_db
from app.repositories import get_workout_session as get_workout_session_from_db
from app.repositories import list_exercises as list_exercises_from_db
from app.repositories import list_workout_sessions as list_workout_sessions_from_db
from app.repositories import upsert_user_profile as upsert_user_profile_in_db

router = APIRouter(prefix="/api/v1")
ui_router = APIRouter()


def _page_shell(*, title: str, body: str) -> str:
    return f"""<!DOCTYPE html>
<html lang=\"es\">
<head>
  <meta charset=\"utf-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
  <title>{escape(title)}</title>
  <style>
    :root {{
      color-scheme: dark;
      --bg: #0f172a;
      --panel: #111827;
      --panel-2: #1f2937;
      --text: #e5e7eb;
      --muted: #94a3b8;
      --accent: #22c55e;
      --accent-2: #38bdf8;
      --border: #243041;
    }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; font-family: Inter, system-ui, sans-serif; background: linear-gradient(180deg, #020617 0%, #0f172a 100%); color: var(--text); }}
    a {{ color: inherit; text-decoration: none; }}
    .wrap {{ max-width: 1100px; margin: 0 auto; padding: 24px; }}
    .hero {{ padding: 32px; border: 1px solid var(--border); border-radius: 24px; background: rgba(15, 23, 42, 0.82); backdrop-filter: blur(8px); box-shadow: 0 20px 60px rgba(0,0,0,.25); }}
    .hero h1 {{ margin: 0 0 12px; font-size: clamp(2rem, 5vw, 3.4rem); }}
    .hero p {{ margin: 0; color: var(--muted); font-size: 1.05rem; line-height: 1.6; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; margin-top: 24px; }}
    .card {{ background: var(--panel); border: 1px solid var(--border); border-radius: 20px; padding: 20px; box-shadow: 0 10px 30px rgba(0,0,0,.18); }}
    .card h2, .card h3 {{ margin-top: 0; }}
    .muted {{ color: var(--muted); }}
    .pill-row {{ display: flex; flex-wrap: wrap; gap: 8px; margin-top: 14px; }}
    .pill {{ display: inline-flex; padding: 8px 12px; border-radius: 999px; background: var(--panel-2); color: var(--text); font-size: .95rem; }}
    .cta {{ display: inline-flex; align-items: center; justify-content: center; padding: 12px 16px; border-radius: 14px; background: var(--accent); color: #052e16; font-weight: 700; }}
    .cta.secondary {{ background: transparent; color: var(--accent-2); border: 1px solid var(--border); }}
    .actions {{ display: flex; flex-wrap: wrap; gap: 12px; margin-top: 20px; }}
    .list {{ display: grid; gap: 14px; margin-top: 24px; }}
    .exercise {{ display: block; }}
    .exercise:hover {{ border-color: #3b82f6; transform: translateY(-1px); transition: .15s ease; }}
    .exercise-title {{ margin: 0 0 10px; font-size: 1.15rem; }}
    .kpi {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 12px; margin-top: 24px; }}
    .kpi .card strong {{ display: block; font-size: 1.5rem; margin-top: 8px; }}
    .back {{ color: var(--accent-2); font-weight: 600; }}
    .section-title {{ margin: 28px 0 10px; font-size: 1.4rem; }}
    pre {{ white-space: pre-wrap; font-family: inherit; margin: 0; line-height: 1.7; }}
  </style>
</head>
<body>
  <main class=\"wrap\">{body}</main>
</body>
</html>"""


def _exercise_card(exercise: Exercise) -> str:
    return f"""
    <a class=\"card exercise\" href=\"/app/exercises/{escape(exercise.id)}\">
      <h3 class=\"exercise-title\">{escape(exercise.name)}</h3>
      <p class=\"muted\">{escape(exercise.description)}</p>
      <div class=\"pill-row\">
        <span class=\"pill\">Grupo: {escape(exercise.muscle_group)}</span>
        <span class=\"pill\">Nivel: {escape(exercise.difficulty)}</span>
        <span class=\"pill\">Equipo: {escape(exercise.equipment)}</span>
        <span class=\"pill\">{exercise.default_sets} series</span>
        <span class=\"pill\">{escape(exercise.default_reps)} reps</span>
      </div>
    </a>
    """


@router.get("/health")
def healthcheck(connection: Connection = Depends(get_db_connection)) -> dict:
    db_ok = connection.execute(text("SELECT 1")).scalar_one() == 1
    return {
        "ok": True,
        "service": "gym-trainer-api",
        "env": settings.app_env,
        "database": "ok" if db_ok else "error",
    }


@router.get("/exercises")
def list_exercises(connection: Connection = Depends(get_db_connection)) -> dict:
    exercises = list_exercises_from_db(connection)
    return {"ok": True, "data": [exercise.model_dump() for exercise in exercises]}


@router.get("/exercises/{exercise_id}")
def get_exercise(exercise_id: str, connection: Connection = Depends(get_db_connection)) -> dict:
    exercise = get_exercise_from_db(connection, exercise_id)
    if exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")

    return {"ok": True, "data": exercise.model_dump()}


@router.get("/workout-sessions")
def list_workout_sessions(connection: Connection = Depends(get_db_connection)) -> dict:
    sessions = list_workout_sessions_from_db(connection)
    return {"ok": True, "data": [session.model_dump(mode="json") for session in sessions]}


@router.get("/workout-sessions/{session_id}")
def get_workout_session(session_id: str, connection: Connection = Depends(get_db_connection)) -> dict:
    session = get_workout_session_from_db(connection, session_id)
    if session is None:
        raise HTTPException(status_code=404, detail="Workout session not found")

    return {"ok": True, "data": session.model_dump(mode="json")}


@router.post("/workout-sessions", status_code=201)
def create_workout_session(payload: WorkoutSessionCreate, connection: Connection = Depends(get_db_connection)) -> dict:
    exercise = get_exercise_from_db(connection, payload.exercise_id)
    if exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")

    session = create_workout_session_in_db(connection, payload)
    return {"ok": True, "data": session.model_dump(mode="json")}


@router.get("/user-profile")
def get_user_profile(connection: Connection = Depends(get_db_connection)) -> dict:
    profile = get_user_profile_from_db(connection)
    if profile is None:
        profile = upsert_user_profile_in_db(connection, UserProfileUpsert(display_name=""))
    return {"ok": True, "data": profile.model_dump(mode="json")}


@router.put("/user-profile")
def upsert_user_profile(payload: UserProfileUpsert, connection: Connection = Depends(get_db_connection)) -> dict:
    profile = upsert_user_profile_in_db(connection, payload)
    return {"ok": True, "data": profile.model_dump(mode="json")}


@router.get("/ai/status")
def get_ai_status(connection: Connection = Depends(get_db_connection)) -> dict:
    profile = get_user_profile_from_db(connection)
    personalization_ready = bool(
        profile
        and profile.ai_personalization_enabled
        and any([profile.goal, profile.age, profile.weight_kg, profile.height_cm, profile.injuries, profile.medical_notes])
    )
    status = build_ai_status(
        enabled=settings.ai_enabled,
        provider=settings.ai_provider,
        personalization_ready=personalization_ready,
    )
    return {"ok": True, "data": status.model_dump(mode="json")}


@ui_router.get("/app", response_class=HTMLResponse)
def frontend_home(connection: Connection = Depends(get_db_connection)) -> str:
    exercises = list_exercises_from_db(connection)
    exercise_cards = "".join(_exercise_card(exercise) for exercise in exercises)

    body = f"""
    <section class=\"hero\">
      <p class=\"muted\">Demo local lista para hoy</p>
      <h1>Gym Trainer</h1>
      <p>Frontend de emergencia servido por FastAPI para enseñar catálogo y detalle de ejercicios desde PostgreSQL real, sin depender de Flutter en esta Raspberry.</p>
      <div class=\"actions\">
        <a class=\"cta\" href=\"#catalogo\">Ver catálogo</a>
        <a class=\"cta secondary\" href=\"/docs\">API docs</a>
      </div>
      <div class=\"kpi\">
        <div class=\"card\"><span class=\"muted\">Backend</span><strong>FastAPI</strong></div>
        <div class=\"card\"><span class=\"muted\">Base de datos</span><strong>PostgreSQL</strong></div>
        <div class=\"card\"><span class=\"muted\">Ejercicios seed</span><strong>{len(exercises)}</strong></div>
      </div>
    </section>

    <h2 id=\"catalogo\" class=\"section-title\">Catálogo de ejercicios</h2>
    <div class=\"list\">{exercise_cards}</div>
    """
    return _page_shell(title="Gym Trainer Demo", body=body)


@ui_router.get("/app/exercises/{exercise_id}", response_class=HTMLResponse)
def frontend_exercise_detail(exercise_id: str, connection: Connection = Depends(get_db_connection)) -> str:
    exercise = get_exercise_from_db(connection, exercise_id)
    if exercise is None:
        raise HTTPException(status_code=404, detail="Exercise not found")

    body = f"""
    <p><a class=\"back\" href=\"/app\">← Volver al catálogo</a></p>
    <section class=\"hero\">
      <p class=\"muted\">Ficha de ejercicio</p>
      <h1>{escape(exercise.name)}</h1>
      <p>{escape(exercise.description)}</p>
      <div class=\"pill-row\">
        <span class=\"pill\">Grupo: {escape(exercise.muscle_group)}</span>
        <span class=\"pill\">Nivel: {escape(exercise.difficulty)}</span>
        <span class=\"pill\">Equipo: {escape(exercise.equipment)}</span>
        <span class=\"pill\">Series: {exercise.default_sets}</span>
        <span class=\"pill\">Reps: {escape(exercise.default_reps)}</span>
      </div>
    </section>

    <div class=\"grid\">
      <section class=\"card\">
        <h2>Descripción</h2>
        <p>{escape(exercise.description)}</p>
      </section>
      <section class=\"card\">
        <h2>Cómo hacerlo</h2>
        <pre>{escape(exercise.instructions)}</pre>
      </section>
    </div>
    """
    return _page_shell(title=exercise.name, body=body)
