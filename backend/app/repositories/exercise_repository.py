from sqlalchemy import text
from sqlalchemy.engine import Connection

from app.models.exercise import Exercise


_EXERCISE_QUERY = text(
    """
    SELECT id::text AS id, nombre AS name, grupo_muscular AS muscle_group,
           dificultad AS difficulty, equipo_necesario AS equipment
    FROM ejercicios
    ORDER BY created_at ASC, nombre ASC
    """
)

_EXERCISE_DETAIL_QUERY = text(
    f"""
    SELECT {_EXERCISE_COLUMNS}
    FROM exercises
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
