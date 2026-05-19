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


def list_exercises(connection: Connection) -> list[Exercise]:
    rows = connection.execute(_EXERCISE_QUERY).mappings().all()
    return [Exercise(**row) for row in rows]
