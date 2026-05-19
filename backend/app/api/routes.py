from html import escape
from datetime import datetime, timedelta
from uuid import uuid4
import random

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy import text
from sqlalchemy.engine import Connection

from app.core.config import settings
from app.db import get_db_connection
from app.models.exercise import Exercise
from app.models.admin import (
    AdminAiSettingsUpsert,
    AdminUserCreate,
    AdminUserStatusUpdate,
    AdminUserTokenLimitUpdate,
)
from app.models.user_profile import UserProfileUpsert
from app.models.workout_session import WorkoutSessionCreate
from app.models.training_plan import TrainingPlanRequest, TrainingPlan, TrainingDay
from app.repositories import build_ai_status
from app.repositories import create_admin_user as create_admin_user_in_db
from app.repositories import create_workout_session as create_workout_session_in_db
from app.repositories import get_admin_ai_settings as get_admin_ai_settings_from_db
from app.repositories import get_admin_user as get_admin_user_from_db
from app.repositories import get_exercise as get_exercise_from_db
from app.repositories import get_user_profile as get_user_profile_from_db
from app.repositories import get_workout_session as get_workout_session_from_db
from app.repositories import list_admin_users as list_admin_users_from_db
from app.repositories import list_exercises as list_exercises_from_db
from app.repositories import list_workout_sessions as list_workout_sessions_from_db
from app.repositories import update_admin_user_status as update_admin_user_status_in_db
from app.repositories import update_admin_user_token_limit as update_admin_user_token_limit_in_db
from app.repositories import upsert_admin_ai_settings as upsert_admin_ai_settings_in_db
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
    admin_ai = get_admin_ai_settings_from_db(connection)
    personalization_ready = bool(
        profile
        and profile.ai_personalization_enabled
        and any([profile.goal, profile.age, profile.weight_kg, profile.height_cm, profile.injuries, profile.medical_notes])
    )
    status = build_ai_status(
        enabled=admin_ai.ai_enabled if admin_ai is not None else settings.ai_enabled,
        provider=admin_ai.provider if admin_ai is not None else settings.ai_provider,
        personalization_ready=personalization_ready,
    )
    return {"ok": True, "data": status.model_dump(mode="json")}


@router.get("/admin/ai-settings")
def get_admin_ai_settings(connection: Connection = Depends(get_db_connection)) -> dict:
    config = get_admin_ai_settings_from_db(connection)
    if config is None:
        config = upsert_admin_ai_settings_in_db(
            connection,
            AdminAiSettingsUpsert(
                ai_enabled=settings.ai_enabled,
                provider=settings.ai_provider,
                model_name="gpt-4.1-mini",
                temperature=0.7,
                max_tokens_per_request=2048,
            ),
        )
    return {"ok": True, "data": config.model_dump(mode="json")}


@router.put("/admin/ai-settings")
def update_admin_ai_settings(payload: AdminAiSettingsUpsert, connection: Connection = Depends(get_db_connection)) -> dict:
    config = upsert_admin_ai_settings_in_db(connection, payload)
    return {"ok": True, "data": config.model_dump(mode="json")}


@router.get("/admin/users")
def list_admin_users(connection: Connection = Depends(get_db_connection)) -> dict:
    users = list_admin_users_from_db(connection)
    return {"ok": True, "data": [user.model_dump(mode="json") for user in users]}


@router.post("/admin/users", status_code=201)
def create_admin_user(payload: AdminUserCreate, connection: Connection = Depends(get_db_connection)) -> dict:
    user = create_admin_user_in_db(connection, payload, user_id=str(uuid4()))
    return {"ok": True, "data": user.model_dump(mode="json")}


@router.put("/admin/users/{user_id}/token-limit")
def update_admin_user_token_limit(
    user_id: str,
    payload: AdminUserTokenLimitUpdate,
    connection: Connection = Depends(get_db_connection),
) -> dict:
    user = update_admin_user_token_limit_in_db(connection, user_id, payload.token_limit_daily)
    if user is None:
        raise HTTPException(status_code=404, detail="Admin user not found")
    return {"ok": True, "data": user.model_dump(mode="json")}


@router.put("/admin/users/{user_id}/status")
def update_admin_user_status(
    user_id: str,
    payload: AdminUserStatusUpdate,
    connection: Connection = Depends(get_db_connection),
) -> dict:
    user = update_admin_user_status_in_db(connection, user_id, payload.is_active)
    if user is None:
        raise HTTPException(status_code=404, detail="Admin user not found")
    return {"ok": True, "data": user.model_dump(mode="json")}


def _generate_training_plan_logic(
    profile,
    exercises: list[Exercise],
    request: TrainingPlanRequest,
) -> TrainingPlan:
    """Generate a personalized training plan based on user profile and preferences."""
    
    plan_id = str(uuid4())
    now = datetime.now()
    
    # Determine difficulty level based on profile
    difficulty_level = "intermediate"
    if profile.age and profile.age > 50:
        difficulty_level = "beginner"
    elif profile.goal == "rendimiento":
        difficulty_level = "advanced"
    
    # Filter exercises based on limitations
    available_exercises = exercises
    if request.selected_limitations:
        # Simple logic: exclude exercises that match limitations
        excluded_muscle_groups = {
            "lower_body": ["piernas", "glúteos"],
            "upper_body": ["pecho", "espalda", "brazos"],
            "lower_back": ["espalda"],
            "shoulder": ["hombros"],
            "knee": ["piernas"],
            "wrist": ["brazos"],
        }
        excluded_groups = []
        for limitation in request.selected_limitations:
            excluded_groups.extend(excluded_muscle_groups.get(limitation, []))
        
        available_exercises = [
            ex for ex in exercises
            if ex.muscle_group.lower() not in [g.lower() for g in excluded_groups]
        ]
    
    # Calculate training structure
    total_days = 0
    if request.training_type == "daily":
        total_days = 7
    elif request.training_type == "weekly":
        total_days = 7
    else:  # monthly
        total_days = 30
    
    # Create training days
    training_days = []
    active_days = total_days - request.rest_days
    
    focus_areas = []
    muscle_groups = set()
    
    for day_num in range(1, total_days + 1):
        is_rest = day_num % (total_days // request.rest_days) == 0 if request.rest_days > 0 else False
        
        if is_rest:
            training_days.append(
                TrainingDay(
                    day=day_num if request.training_type != "weekly" else f"Día {day_num}",
                    focus_area="Descanso",
                    exercises=[],
                    is_rest_day=True,
                    notes="Día de recuperación. Descansa y rehidratate.",
                )
            )
        else:
            # Select exercises for this day
            if available_exercises:
                num_exercises = 4 if difficulty_level == "intermediate" else 3
                day_exercises = random.sample(
                    available_exercises,
                    min(num_exercises, len(available_exercises))
                )
                
                exercises_data = []
                for exercise in day_exercises:
                    muscle_groups.add(exercise.muscle_group)
                    exercises_data.append({
                        "id": exercise.id,
                        "name": exercise.name,
                        "sets": exercise.default_sets,
                        "reps": exercise.default_reps,
                        "rest_seconds": 60,
                        "notes": f"Nivel: {exercise.difficulty}",
                    })
                
                focus = day_exercises[0].muscle_group if day_exercises else "General"
                training_days.append(
                    TrainingDay(
                        day=day_num if request.training_type != "weekly" else f"Día {day_num}",
                        focus_area=focus,
                        exercises=exercises_data,
                        is_rest_day=False,
                        notes=f"Enfoque en {focus}. Realiza {len(exercises_data)} ejercicios.",
                    )
                )
    
    focus_areas = list(muscle_groups) or ["General"]
    
    # Create personalized notes
    personalized_notes = f"Plan de {request.training_type} personalizado basado en tu perfil: "
    if profile.goal:
        goal_labels = {
            "perder_grasa": "pérdida de grasa",
            "ganar_musculo": "ganancia muscular",
            "mantener": "mantenimiento",
            "rendimiento": "rendimiento atlético",
            "salud_general": "salud general",
        }
        personalized_notes += goal_labels.get(profile.goal, "objetivo personalizado")
    
    if request.additional_notes:
        personalized_notes += f". {request.additional_notes}"
    
    return TrainingPlan(
        id=plan_id,
        training_type=request.training_type,
        rest_days=request.rest_days,
        total_days=total_days,
        focus_areas=focus_areas,
        days=training_days,
        personalized_notes=personalized_notes,
        estimated_duration_weeks=4 if request.training_type in ["daily", "weekly"] else 16,
        difficulty_level=difficulty_level,
        ai_generated=True,
        created_at=now,
        valid_until=now + timedelta(days=90),
    )


@router.post("/ai/training-plan", status_code=201)
def generate_training_plan(
    payload: TrainingPlanRequest,
    connection: Connection = Depends(get_db_connection),
) -> dict:
    """Generate a personalized training plan using AI based on user profile."""
    profile = get_user_profile_from_db(connection)
    if profile is None:
        raise HTTPException(
            status_code=400,
            detail="Por favor completa tu perfil primero",
        )
    
    if not profile.ai_personalization_enabled:
        raise HTTPException(
            status_code=403,
            detail="La personalización con IA no está habilitada en tu perfil",
        )
    
    exercises = list_exercises_from_db(connection)
    if not exercises:
        raise HTTPException(
            status_code=400,
            detail="No hay ejercicios disponibles",
        )
    
    admin_ai = get_admin_ai_settings_from_db(connection)
    if admin_ai is not None and not admin_ai.ai_enabled:
        raise HTTPException(
            status_code=403,
            detail="La IA está deshabilitada por administración",
        )

    training_plan = _generate_training_plan_logic(profile, exercises, payload)
    
    return {"ok": True, "data": training_plan.model_dump(mode="json")}


@ui_router.get("/admin", response_class=HTMLResponse)
def admin_panel() -> str:
        body = """
        <section class=\"hero\">
            <p class=\"muted\">Panel de administración PC</p>
            <h1>Administración IA y Usuarios</h1>
            <p>Configura parámetros globales de IA del backend, crea usuarios y define límites diarios de tokens por usuario.</p>
            <div class=\"actions\">
                <a class=\"cta secondary\" href=\"/docs\">API docs</a>
                <a class=\"cta secondary\" href=\"/app\">Ver frontend demo</a>
            </div>
        </section>

        <div class=\"grid\" style=\"margin-top:16px;\">
            <section class=\"card\">
                <h2>Configuración IA</h2>
                <form id=\"ai-form\" class=\"list\" style=\"margin-top: 10px;\">
                    <label>Proveedor IA<br/><input id=\"provider\" required /></label>
                    <label>Modelo<br/><input id=\"model_name\" required /></label>
                    <label>Temperatura (0-2)<br/><input id=\"temperature\" type=\"number\" step=\"0.1\" min=\"0\" max=\"2\" required /></label>
                    <label>Max tokens por request<br/><input id=\"max_tokens_per_request\" type=\"number\" min=\"1\" required /></label>
                    <label><input id=\"ai_enabled\" type=\"checkbox\" /> IA habilitada</label>
                    <button class=\"cta\" type=\"submit\" style=\"border:0; cursor:pointer;\">Guardar configuración</button>
                </form>
            </section>

            <section class=\"card\">
                <h2>Nuevo usuario</h2>
                <form id=\"user-form\" class=\"list\" style=\"margin-top: 10px;\">
                    <label>Nombre de usuario<br/><input id=\"username\" required /></label>
                    <label>Email<br/><input id=\"email\" type=\"email\" required /></label>
                    <label>Límite tokens diario<br/><input id=\"token_limit_daily\" type=\"number\" min=\"0\" value=\"50000\" required /></label>
                    <label>Notas<br/><textarea id=\"notes\" rows=\"3\"></textarea></label>
                    <button class=\"cta\" type=\"submit\" style=\"border:0; cursor:pointer;\">Crear usuario</button>
                </form>
            </section>
        </div>

        <section class=\"card\" style=\"margin-top: 16px;\">
            <h2>Usuarios administrados</h2>
            <p class=\"muted\">Actualiza límite de tokens o estado activo/inactivo por usuario.</p>
            <table id=\"users-table\" style=\"width:100%; border-collapse: collapse;\">
                <thead>
                    <tr>
                        <th style=\"text-align:left; padding:8px; border-bottom:1px solid var(--border);\">Usuario</th>
                        <th style=\"text-align:left; padding:8px; border-bottom:1px solid var(--border);\">Email</th>
                        <th style=\"text-align:left; padding:8px; border-bottom:1px solid var(--border);\">Límite diario</th>
                        <th style=\"text-align:left; padding:8px; border-bottom:1px solid var(--border);\">Usados hoy</th>
                        <th style=\"text-align:left; padding:8px; border-bottom:1px solid var(--border);\">Estado</th>
                        <th style=\"text-align:left; padding:8px; border-bottom:1px solid var(--border);\">Acciones</th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </section>

        <script>
            const apiBase = '/api/v1/admin';
            const usersTableBody = document.querySelector('#users-table tbody');

            function showError(error) {
                alert('Error: ' + error);
            }

            async function loadAiSettings() {
                const res = await fetch(`${apiBase}/ai-settings`);
                const payload = await res.json();
                if (!payload.ok) throw new Error('No se pudo cargar configuración IA');
                const data = payload.data;
                document.getElementById('provider').value = data.provider;
                document.getElementById('model_name').value = data.model_name;
                document.getElementById('temperature').value = data.temperature;
                document.getElementById('max_tokens_per_request').value = data.max_tokens_per_request;
                document.getElementById('ai_enabled').checked = data.ai_enabled;
            }

            async function saveAiSettings(event) {
                event.preventDefault();
                const body = {
                    provider: document.getElementById('provider').value.trim(),
                    model_name: document.getElementById('model_name').value.trim(),
                    temperature: Number(document.getElementById('temperature').value),
                    max_tokens_per_request: Number(document.getElementById('max_tokens_per_request').value),
                    ai_enabled: document.getElementById('ai_enabled').checked,
                };

                const res = await fetch(`${apiBase}/ai-settings`, {
                    method: 'PUT',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(body),
                });
                if (!res.ok) throw new Error('No se pudo guardar configuración IA');
                alert('Configuración IA guardada');
            }

            function userRowTemplate(user) {
                return `
                    <tr>
                        <td style=\"padding:8px; border-bottom:1px solid var(--border);\">${user.username}</td>
                        <td style=\"padding:8px; border-bottom:1px solid var(--border);\">${user.email}</td>
                        <td style=\"padding:8px; border-bottom:1px solid var(--border);\">
                            <input type=\"number\" min=\"0\" value=\"${user.token_limit_daily}\" id=\"limit-${user.id}\" style=\"width:120px\" />
                        </td>
                        <td style=\"padding:8px; border-bottom:1px solid var(--border);\">${user.tokens_used_today}</td>
                        <td style=\"padding:8px; border-bottom:1px solid var(--border);\">${user.is_active ? 'Activo' : 'Inactivo'}</td>
                        <td style=\"padding:8px; border-bottom:1px solid var(--border); display:flex; gap:8px;\">
                            <button onclick=\"updateLimit('${user.id}')\">Guardar límite</button>
                            <button onclick=\"toggleStatus('${user.id}', ${!user.is_active})\">${user.is_active ? 'Desactivar' : 'Activar'}</button>
                        </td>
                    </tr>
                `;
            }

            async function loadUsers() {
                const res = await fetch(`${apiBase}/users`);
                const payload = await res.json();
                if (!payload.ok) throw new Error('No se pudo cargar usuarios');
                usersTableBody.innerHTML = payload.data.map(userRowTemplate).join('');
            }

            async function createUser(event) {
                event.preventDefault();
                const body = {
                    username: document.getElementById('username').value.trim(),
                    email: document.getElementById('email').value.trim(),
                    token_limit_daily: Number(document.getElementById('token_limit_daily').value),
                    notes: document.getElementById('notes').value.trim(),
                };
                const res = await fetch(`${apiBase}/users`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(body),
                });
                if (!res.ok) throw new Error('No se pudo crear usuario');
                document.getElementById('user-form').reset();
                document.getElementById('token_limit_daily').value = 50000;
                await loadUsers();
            }

            async function updateLimit(userId) {
                try {
                    const value = Number(document.getElementById(`limit-${userId}`).value);
                    const res = await fetch(`${apiBase}/users/${userId}/token-limit`, {
                        method: 'PUT',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ token_limit_daily: value }),
                    });
                    if (!res.ok) throw new Error('No se pudo actualizar límite');
                    await loadUsers();
                } catch (error) {
                    showError(error.message);
                }
            }

            async function toggleStatus(userId, isActive) {
                try {
                    const res = await fetch(`${apiBase}/users/${userId}/status`, {
                        method: 'PUT',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ is_active: isActive }),
                    });
                    if (!res.ok) throw new Error('No se pudo actualizar estado');
                    await loadUsers();
                } catch (error) {
                    showError(error.message);
                }
            }

            document.getElementById('ai-form').addEventListener('submit', async (event) => {
                try {
                    await saveAiSettings(event);
                } catch (error) {
                    showError(error.message);
                }
            });

            document.getElementById('user-form').addEventListener('submit', async (event) => {
                try {
                    await createUser(event);
                } catch (error) {
                    showError(error.message);
                }
            });

            window.updateLimit = updateLimit;
            window.toggleStatus = toggleStatus;

            (async function init() {
                try {
                    await loadAiSettings();
                    await loadUsers();
                } catch (error) {
                    showError(error.message);
                }
            })();
        </script>
        """
        return _page_shell(title="Gym Trainer Admin", body=body)


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
