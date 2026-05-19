from uuid import uuid4

from sqlalchemy import text
from sqlalchemy.engine import Connection

from app.models.workout_session import WorkoutSession, WorkoutSessionCreate


_SESSION_COLUMNS = """
    ws.id,
    ws.exercise_id,
    e.name AS exercise_name,
    ws.performed_at,
    ws.sets_completed,
    ws.reps_completed,
    ws.notes,
    ws.created_at
"""

_LIST_SESSIONS_QUERY = text(
    f"""
    SELECT {_SESSION_COLUMNS}
    FROM workout_sessions ws
    JOIN exercises e ON e.id = ws.exercise_id
    ORDER BY ws.performed_at DESC, ws.created_at DESC
    LIMIT :limit
    """
)

_GET_SESSION_QUERY = text(
    f"""
    SELECT {_SESSION_COLUMNS}
    FROM workout_sessions ws
    JOIN exercises e ON e.id = ws.exercise_id
    WHERE ws.id = :session_id
    """
)

_INSERT_SESSION_QUERY = text(
    """
    INSERT INTO workout_sessions (
        id,
        exercise_id,
        performed_at,
        sets_completed,
        reps_completed,
        notes
    ) VALUES (
        :id,
        :exercise_id,
        :performed_at,
        :sets_completed,
        :reps_completed,
        :notes
    )
    """
)


def list_workout_sessions(connection: Connection, *, limit: int = 20) -> list[WorkoutSession]:
    rows = connection.execute(_LIST_SESSIONS_QUERY, {"limit": limit}).mappings().all()
    return [WorkoutSession(**row) for row in rows]


def get_workout_session(connection: Connection, session_id: str) -> WorkoutSession | None:
    row = connection.execute(_GET_SESSION_QUERY, {"session_id": session_id}).mappings().first()
    if row is None:
        return None

    return WorkoutSession(**row)


def create_workout_session(connection: Connection, payload: WorkoutSessionCreate) -> WorkoutSession:
    session_id = f"ws-{uuid4().hex[:12]}"
    connection.execute(
        _INSERT_SESSION_QUERY,
        {
            "id": session_id,
            "exercise_id": payload.exercise_id,
            "performed_at": payload.performed_at,
            "sets_completed": payload.sets_completed,
            "reps_completed": payload.reps_completed,
            "notes": payload.notes,
        },
    )
    connection.commit()
    session = get_workout_session(connection, session_id)
    if session is None:
        raise RuntimeError("Workout session insert failed")
    return session
