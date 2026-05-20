from sqlalchemy import text
from sqlalchemy.engine import Connection

from app.models.exercise import Exercise


_EXERCISE_COLUMNS = """
    id::text AS id,
    nombre AS name,
    grupo_muscular AS muscle_group,
    dificultad AS difficulty,
    coalesce(equipo_necesario, '') AS equipment,
    coalesce(descripcion, '') AS description,
    coalesce(array_to_string(instrucciones, E'\n'), '') AS instructions,
    3 AS default_sets,
    '10-12' AS default_reps
"""

_EXERCISE_LIST_QUERY = text(
    f"""
    SELECT {_EXERCISE_COLUMNS}
    FROM ejercicios
    ORDER BY created_at ASC, nombre ASC
    """
)

_EXERCISE_DETAIL_QUERY = text(
    f"""
    SELECT {_EXERCISE_COLUMNS}
    FROM ejercicios
    WHERE id = :exercise_id
    """
)


def list_exercises(connection: Connection) -> list[Exercise]:
    rows = connection.execute(_EXERCISE_LIST_QUERY).mappings().all()
    return [Exercise(**row) for row in rows]


def get_exercise(connection: Connection, exercise_id: str) -> Exercise | None:
    row = connection.execute(
        _EXERCISE_DETAIL_QUERY,
        {"exercise_id": exercise_id},
    ).mappings().first()

    if row is None:
        return None

    return Exercise(**row)

