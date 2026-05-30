from datetime import datetime, timedelta

from sqlalchemy import delete, func, select, update

from app.models.sesion_entreno import SesionEntreno, SesionEjercicioRegistro
from app.models.ejercicio import Ejercicio


def create_sesion(conn, usuario_id: str, data: dict) -> SesionEntreno:
    data["usuario_id"] = usuario_id
    data["created_at"] = datetime.utcnow()
    sesion = SesionEntreno(**data)
    conn.add(sesion)
    conn.commit()
    conn.refresh(sesion)
    return sesion


def get_sesion_by_id(conn, sesion_id: str, usuario_id: str) -> SesionEntreno | None:
    result = conn.execute(
        select(SesionEntreno).where(
            SesionEntreno.id == sesion_id,
            SesionEntreno.usuario_id == usuario_id,
        )
    )
    return result.scalar_one_or_none()


def list_sesiones(
    conn, usuario_id: str, skip: int = 0, limit: int = 20, estado: str | None = None
) -> list[SesionEntreno]:
    query = select(SesionEntreno).where(SesionEntreno.usuario_id == usuario_id)
    if estado:
        query = query.where(SesionEntreno.estado == estado)
    else:
        query = query.where(SesionEntreno.estado != 'cancelada')
    result = conn.execute(
        query.order_by(SesionEntreno.fecha_inicio.desc()).offset(skip).limit(limit)
    )
    return list(result.scalars().all())


def update_sesion(conn, sesion_id: str, usuario_id: str, data: dict) -> SesionEntreno | None:
    sesion = get_sesion_by_id(conn, sesion_id, usuario_id)
    if not sesion:
        return None
    update_values = {k: v for k, v in data.items() if v is not None}
    if update_values:
        conn.execute(
            update(SesionEntreno)
            .where(SesionEntreno.id == sesion_id)
            .values(**update_values)
        )
        conn.commit()
        conn.refresh(sesion)
    return sesion


def delete_sesion(conn, sesion_id: str, usuario_id: str) -> bool:
    result = conn.execute(
        delete(SesionEntreno)
        .where(SesionEntreno.id == sesion_id, SesionEntreno.usuario_id == usuario_id)
    )
    conn.commit()
    return result.rowcount > 0


def registrar_sets(conn, sesion_id: str, usuario_id: str, ejercicio_id: str, registros: list[dict]) -> list[SesionEjercicioRegistro]:
    sesion = get_sesion_by_id(conn, sesion_id, usuario_id)
    if not sesion:
        return []

    created = []
    for reg in registros:
        record = SesionEjercicioRegistro(
            sesion_id=sesion_id,
            ejercicio_id=ejercicio_id,
            set_numero=reg["set_numero"],
            peso_kg=reg.get("peso_kg"),
            repeticiones=reg.get("repeticiones"),
            rpe=reg.get("rpe"),
            completado=reg.get("completado", True),
            notas=reg.get("notas"),
        )
        conn.add(record)
        created.append(record)

    conn.commit()
    for r in created:
        conn.refresh(r)
    return created


def get_exercise_history_by_weeks(
    conn,
    usuario_id: str,
    num_semanas: int = 3,
) -> list[dict]:
    """Return per-exercise stats grouped by ISO week for the last num_semanas weeks."""
    from sqlalchemy import text as sa_text

    cutoff = datetime.utcnow() - timedelta(weeks=num_semanas)
    result = conn.execute(
        sa_text("""
            SELECT
                date_trunc('week', se.fecha_inicio) AS semana,
                e.nombre AS ejercicio_nombre,
                e.equipo_necesario AS equipo,
                MAX(ser.peso_kg) AS max_peso_kg,
                MAX(ser.repeticiones) AS max_reps,
                COUNT(ser.id) AS total_sets
            FROM sesiones_entreno se
            JOIN sesion_ejercicio_registros ser ON se.id = ser.sesion_id
            JOIN ejercicios e ON ser.ejercicio_id = e.id
            WHERE se.usuario_id = :usuario_id
              AND se.fecha_inicio >= :cutoff
              AND se.estado != 'cancelada'
            GROUP BY date_trunc('week', se.fecha_inicio), e.nombre, e.equipo_necesario
            ORDER BY date_trunc('week', se.fecha_inicio) DESC, e.nombre
        """),
        {"usuario_id": usuario_id, "cutoff": cutoff},
    )
    rows = result.all()
    return [
        {
            "semana": str(r.semana.date()) if r.semana else None,
            "ejercicio_nombre": r.ejercicio_nombre,
            "equipo": r.equipo,
            "max_peso_kg": float(r.max_peso_kg) if r.max_peso_kg is not None else None,
            "max_reps": r.max_reps,
            "total_sets": r.total_sets,
        }
        for r in rows
    ]


def get_or_create_ejercicio_by_nombre(
    conn,
    *,
    nombre: str,
    grupo_muscular: str | None = None,
    equipo: str | None = None,
) -> Ejercicio:
    normalized = " ".join((nombre or "").strip().lower().split())

    existing = conn.execute(
        select(Ejercicio).where(Ejercicio.nombre_normalizado == normalized)
    ).scalar_one_or_none()
    if existing:
        return existing

    fallback_group = (grupo_muscular or "general").strip() or "general"
    fallback_equipment = (equipo or "sin equipo").strip() or "sin equipo"

    created = Ejercicio(
        nombre=nombre.strip(),
        nombre_normalizado=normalized,
        descripcion="Ejercicio creado automaticamente desde registro de sesion.",
        grupo_muscular=fallback_group,
        tipo_ejercicio="fuerza",
        equipo_necesario=fallback_equipment,
        instrucciones=["Revisar tecnica antes de aumentar carga."],
        musculos_implicados=[fallback_group],
        es_publico=True,
    )
    conn.add(created)
    conn.commit()
    conn.refresh(created)
    return created


def get_last_week_max_per_exercise(
    conn,
    usuario_id: str,
    days: int = 14,
) -> dict[str, dict]:
    """Return {exercise_name: {max_weight_kg, max_reps}} for completed sessions in the last `days` days."""
    from sqlalchemy import text as sa_text

    cutoff = datetime.utcnow() - timedelta(days=days)
    result = conn.execute(
        sa_text("""
            SELECT
                e.nombre AS ejercicio_nombre,
                MAX(ser.peso_kg) AS max_peso_kg,
                MAX(ser.repeticiones) AS max_reps
            FROM sesiones_entreno se
            JOIN sesion_ejercicio_registros ser ON se.id = ser.sesion_id
            JOIN ejercicios e ON ser.ejercicio_id = e.id
            WHERE se.usuario_id = :usuario_id
              AND se.fecha_inicio >= :cutoff
              AND se.estado = 'completada'
              AND ser.completado = true
            GROUP BY e.nombre
        """),
        {"usuario_id": usuario_id, "cutoff": cutoff},
    )
    return {
        r.ejercicio_nombre: {
            "max_peso_kg": float(r.max_peso_kg) if r.max_peso_kg is not None else None,
            "max_reps": r.max_reps,
        }
        for r in result.all()
    }


def get_plan_day_history(
    conn,
    usuario_id: str,
    plan_id: str,
    dia_semana: int,
) -> dict[str, dict]:
    """Return {exercise_name: {max_peso_kg, max_reps}} from all completed sessions of a specific plan+day."""
    from sqlalchemy import text as sa_text

    result = conn.execute(
        sa_text("""
            SELECT
                e.nombre AS ejercicio_nombre,
                MAX(ser.peso_kg) AS max_peso_kg,
                MAX(ser.repeticiones) AS max_reps
            FROM sesiones_entreno se
            JOIN sesion_ejercicio_registros ser ON se.id = ser.sesion_id
            JOIN ejercicios e ON ser.ejercicio_id = e.id
            WHERE se.usuario_id = :usuario_id
              AND se.plan_semanal_id = :plan_id
              AND se.dia_semana = :dia_semana
              AND se.estado = 'completada'
              AND ser.completado = true
            GROUP BY e.nombre
        """),
        {"usuario_id": usuario_id, "plan_id": plan_id, "dia_semana": dia_semana},
    )
    return {
        r.ejercicio_nombre: {
            "max_peso_kg": float(r.max_peso_kg) if r.max_peso_kg is not None else None,
            "max_reps": r.max_reps,
        }
        for r in result.all()
    }


def get_registros_by_sesion(conn, sesion_id: str) -> list[dict]:
    result = conn.execute(
        select(
            SesionEjercicioRegistro.id,
            SesionEjercicioRegistro.sesion_id,
            SesionEjercicioRegistro.ejercicio_id,
            Ejercicio.nombre.label("ejercicio_nombre"),
            Ejercicio.grupo_muscular.label("ejercicio_grupo_muscular"),
            Ejercicio.equipo_necesario.label("ejercicio_equipo"),
            SesionEjercicioRegistro.set_numero,
            SesionEjercicioRegistro.peso_kg,
            SesionEjercicioRegistro.repeticiones,
            SesionEjercicioRegistro.rpe,
            SesionEjercicioRegistro.completado,
            SesionEjercicioRegistro.notas,
            SesionEjercicioRegistro.created_at,
        )
        .join(Ejercicio, SesionEjercicioRegistro.ejercicio_id == Ejercicio.id)
        .where(SesionEjercicioRegistro.sesion_id == sesion_id)
        .order_by(Ejercicio.nombre, SesionEjercicioRegistro.set_numero)
    )
    rows = result.all()
    return [
        {
            "id": r.id,
            "sesion_id": r.sesion_id,
            "ejercicio_id": r.ejercicio_id,
            "ejercicio_nombre": r.ejercicio_nombre,
            "ejercicio_grupo_muscular": r.ejercicio_grupo_muscular,
            "ejercicio_equipo": r.ejercicio_equipo,
            "set_numero": r.set_numero,
            "peso_kg": float(r.peso_kg) if r.peso_kg is not None else None,
            "repeticiones": r.repeticiones,
            "rpe": r.rpe,
            "completado": r.completado,
            "notas": r.notas,
            "created_at": r.created_at,
        }
        for r in rows
    ]
