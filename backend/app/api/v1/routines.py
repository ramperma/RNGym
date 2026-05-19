from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.api.deps import get_current_user
from app.db import get_db_connection, db_connection_context
from app.repositories import (
    create_rutina,
    delete_rutina,
    get_rutina_by_id,
    get_rutina_for_execute,
    list_rutinas,
    update_rutina,
)
from app.schemas.rutina import (
    RutinaCreate,
    RutinaListResponse,
    RutinaResponse,
    RutinaUpdate,
)

router = APIRouter(prefix="/api/v1/routines", tags=["routines"])


def _rutina_to_response(rutina) -> dict:
    return {
        "id": rutina.id,
        "nombre": rutina.nombre,
        "descripcion": rutina.descripcion,
        "tipo_rutina": rutina.tipo_rutina,
        "dificultad": rutina.dificultad,
        "duracion_estimada_minutos": rutina.duracion_estimada_minutos,
        "frecuencia_semanal": rutina.frecuencia_semanal,
        "usuario_id": rutina.usuario_id,
        "creador_id": rutina.creador_id,
        "es_publica": rutina.es_publica,
        "fuente_creacion": rutina.fuente_creacion,
        "metadata_ia": rutina.metadata_ia,
        "created_at": rutina.created_at,
        "updated_at": rutina.updated_at,
        "activa": rutina.activa,
        "ejercicios": [
            {
                "id": e.id,
                "rutina_id": e.rutina_id,
                "ejercicio_id": e.ejercicio_id,
                "orden": e.orden,
                "series": e.series,
                "repeticiones": e.repeticiones,
                "descanso_segundos": e.descanso_segundos,
                "tempo": e.tempo,
                "notas": e.notas,
                "created_at": e.created_at,
            }
            for e in rutina.ejercicios
        ],
    }


@router.get("", response_model=list[RutinaListResponse])
def list_user_routines(
    skip: int = 0,
    limit: int = 20,
    current_user: dict = Depends(get_current_user),
) -> list[dict]:
    with db_connection_context() as conn:
        rutinas = list_rutinas(conn, current_user["id"], skip, limit)
        return [
            {
                "id": r.id,
                "nombre": r.nombre,
                "tipo_rutina": r.tipo_rutina,
                "dificultad": r.dificultad,
                "created_at": r.created_at,
                "activa": r.activa,
            }
            for r in rutinas
        ]


@router.post("", response_model=RutinaResponse, status_code=status.HTTP_201_CREATED)
def create_user_routine(
    payload: RutinaCreate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    data = payload.model_dump()
    with db_connection_context() as conn:
        rutina = create_rutina(conn, current_user["id"], data)
        return _rutina_to_response(rutina)


@router.get("/{rutina_id}", response_model=RutinaResponse)
def get_routine(
    rutina_id: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    with db_connection_context() as conn:
        rutina = get_rutina_by_id(conn, rutina_id, current_user["id"])
        if not rutina:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "ROUTINE_NOT_FOUND", "message": "Rutina no encontrada"},
            )
        return _rutina_to_response(rutina)


@router.put("/{rutina_id}", response_model=RutinaResponse)
def update_user_routine(
    rutina_id: str,
    payload: RutinaUpdate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    data = payload.model_dump(exclude_unset=True)
    with db_connection_context() as conn:
        rutina = update_rutina(conn, rutina_id, current_user["id"], data)
        if not rutina:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "ROUTINE_NOT_FOUND", "message": "Rutina no encontrada"},
            )
        return _rutina_to_response(rutina)


@router.delete("/{rutina_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_routine(
    rutina_id: str,
    current_user: dict = Depends(get_current_user),
) -> None:
    with db_connection_context() as conn:
        deleted = delete_rutina(conn, rutina_id, current_user["id"])
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "ROUTINE_NOT_FOUND", "message": "Rutina no encontrada"},
            )


@router.get("/{rutina_id}/execute", response_model=RutinaResponse)
def execute_routine(
    rutina_id: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    with db_connection_context() as conn:
        rutina = get_rutina_for_execute(conn, rutina_id, current_user["id"])
        if not rutina:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "ROUTINE_NOT_FOUND", "message": "Rutina no encontrada"},
            )
        return _rutina_to_response(rutina)