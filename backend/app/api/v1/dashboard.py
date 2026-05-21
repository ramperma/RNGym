from datetime import datetime, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import text

from app.api.deps import get_current_user
from app.db import db_connection_context

router = APIRouter(prefix="/api/v1/dashboard", tags=["dashboard"])


def _inicio_y_fin_semana(now: datetime) -> tuple[datetime, datetime]:
    """Devuelve lunes 00:00 y domingo 23:59 de la semana de `now`."""
    # weekday(): 0=lunes, 6=domingo
    lunes = now - timedelta(days=now.weekday(), hours=now.hour, minutes=now.minute, seconds=now.second, microseconds=now.microsecond)
    siguiente_lunes = lunes + timedelta(days=7)
    return lunes, siguiente_lunes


@router.get("/stats")
def dashboard_stats(current_user: dict = Depends(get_current_user)) -> dict:
    user_id = current_user["id"]
    now = datetime.utcnow()
    lunes, siguiente_lunes = _inicio_y_fin_semana(now)

    with db_connection_context() as conn:
        # 1) Sesiones completadas esta semana
        sem_result = conn.execute(
            text("""
                SELECT COUNT(*) FROM sesiones_entreno
                WHERE usuario_id = :uid
                  AND estado = 'completada'
                  AND fecha_inicio >= :lunes
                  AND fecha_inicio < :sig
            """),
            {"uid": user_id, "lunes": lunes, "sig": siguiente_lunes},
        )
        sem_completados = sem_result.scalar_one()

        # 2) Plan semanal activo → días objetivo y JSON
        plan_result = conn.execute(
            text("""
                SELECT dias_entreno_objetivo, plan_json
                FROM planes_semanales
                WHERE usuario_id = :uid AND activo = true
                ORDER BY created_at DESC
                LIMIT 1
            """),
            {"uid": user_id},
        )
        plan_row = plan_result.fetchone()
        dias_objetivo = 4
        plan_json = None
        if plan_row:
            dias_objetivo = plan_row.dias_entreno_objetivo or 4
            plan_json = plan_row.plan_json

        # 3) ¿Entrenó hoy?
        hoy_inicio = now.replace(hour=0, minute=0, second=0, microsecond=0)
        hoy_fin = hoy_inicio + timedelta(days=1)
        hoy_result = conn.execute(
            text("""
                SELECT id, nombre
                FROM sesiones_entreno
                WHERE usuario_id = :uid
                  AND estado = 'completada'
                  AND fecha_inicio >= :ini
                  AND fecha_inicio < :fin
                ORDER BY fecha_inicio DESC
                LIMIT 1
            """),
            {"uid": user_id, "ini": hoy_inicio, "fin": hoy_fin},
        )
        hoy_row = hoy_result.fetchone()
        hoy_entrenado = hoy_row is not None
        hoy_resumen = hoy_row.nombre if hoy_row else None

        # 4) Próximo día de entreno (si no entrenó hoy o incluso si sí, para mañana)
        proximo_dia_nombre = None
        proximo_entreno_nombre = None
        if plan_json and "dias" in plan_json:
            dias = plan_json["dias"]
            hoy_idx = now.weekday()  # 0=lunes

            # Buscar siguiente día de tipo 'workout' a partir de mañana
            for offset in range(1, 8):
                idx = (hoy_idx + offset) % 7
                dia = next((d for d in dias if d.get("dia_semana") == idx), None)
                if dia and dia.get("tipo") == "workout":
                    proximo_dia_nombre = dia.get("nombre_dia", "")
                    # Usar notas o primer bloque como nombre descriptivo
                    notas = dia.get("notas", "")
                    bloques = dia.get("bloques", [])
                    if notas:
                        proximo_entreno_nombre = notas
                    elif bloques:
                        # primer ejercicio del bloque principal
                        principal = next((b for b in bloques if b.get("tipo") == "principal"), None)
                        if principal:
                            ejercicios = principal.get("ejercicios", [])
                            if ejercicios:
                                nombres = [e.get("nombre_ejercicio", "") for e in ejercicios[:2]]
                                proximo_entreno_nombre = " · ".join(nombres)
                    break

        # 5) Conteo de ejercicios de hoy (si entrenó)
        hoy_ejercicios = 0
        if hoy_entrenado and hoy_row:
            ej_result = conn.execute(
                text("""
                    SELECT COUNT(DISTINCT ejercicio_id)
                    FROM sesion_ejercicio_registros
                    WHERE sesion_id = :sid
                """),
                {"sid": hoy_row.id},
            )
            hoy_ejercicios = ej_result.scalar_one()

    porcentaje = min(1.0, sem_completados / dias_objetivo) if dias_objetivo > 0 else 0.0

    return {
        "ok": True,
        "semanal_completados": sem_completados,
        "semanal_objetivo": dias_objetivo,
        "semanal_porcentaje": round(porcentaje, 2),
        "hoy_entrenado": hoy_entrenado,
        "hoy_resumen": hoy_resumen,
        "hoy_ejercicios": hoy_ejercicios,
        "proximo_dia": proximo_dia_nombre,
        "proximo_nombre": proximo_entreno_nombre,
    }
