from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user
from app.db import get_db_connection, db_connection_context
from app.repositories import (
    create_sesion,
    delete_sesion,
    get_last_week_max_per_exercise,
    get_or_create_ejercicio_by_nombre,
    get_registros_by_sesion,
    get_sesion_by_id,
    list_sesiones,
    registrar_sets,
    update_sesion,
)
from app.schemas.sesion import (
    RegistrarSetsRequest,
    SesionEntrenoCreate,
    SesionEntrenoListResponse,
    SesionEntrenoResponse,
    SesionEntrenoUpdate,
)

router = APIRouter(prefix="/api/v1/sessions", tags=["sessions"])


def _sesion_to_response(sesion, registros: list = None) -> dict:
    return {
        "id": sesion.id,
        "usuario_id": sesion.usuario_id,
        "rutina_id": sesion.rutina_id,
        "nombre": sesion.nombre,
        "fecha_inicio": sesion.fecha_inicio,
        "fecha_fin": sesion.fecha_fin,
        "duracion_minutos": sesion.duracion_minutos,
        "estado": sesion.estado,
        "kcal_estimadas": sesion.kcal_estimadas,
        "kcal_real": sesion.kcal_real,
        "notas": sesion.notas,
        "created_at": sesion.created_at,
        "registros": [
            {
                "id": r["id"],
                "sesion_id": r["sesion_id"],
                "ejercicio_id": r["ejercicio_id"],
                "ejercicio_nombre": r.get("ejercicio_nombre"),
                "ejercicio_grupo_muscular": r.get("ejercicio_grupo_muscular"),
                "ejercicio_equipo": r.get("ejercicio_equipo"),
                "set_numero": r["set_numero"],
                "peso_kg": r["peso_kg"],
                "repeticiones": r["repeticiones"],
                "rpe": r["rpe"],
                "completado": r["completado"],
                "notas": r["notas"],
                "created_at": r["created_at"],
            }
            for r in (registros or [])
        ],
    }


@router.get("", response_model=list[SesionEntrenoListResponse])
def list_user_sessions(
    skip: int = 0,
    limit: int = 20,
    estado: str | None = None,
    current_user: dict = Depends(get_current_user),
) -> list[dict]:
    with db_connection_context() as conn:
        sesiones = list_sesiones(conn, current_user["id"], skip, limit, estado)
        return [
            {
                "id": s.id,
                "nombre": s.nombre,
                "fecha_inicio": s.fecha_inicio,
                "estado": s.estado,
                "duracion_minutos": s.duracion_minutos,
            }
            for s in sesiones
        ]


@router.post("", response_model=SesionEntrenoResponse, status_code=status.HTTP_201_CREATED)
def create_session(
    payload: SesionEntrenoCreate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    data = payload.model_dump()
    with db_connection_context() as conn:
        sesion = create_sesion(conn, current_user["id"], data)
        return _sesion_to_response(sesion, [])


@router.get("/last-week-history")
def last_week_history(
    days: int = 14,
    current_user: dict = Depends(get_current_user),
) -> dict:
    with db_connection_context() as conn:
        data = get_last_week_max_per_exercise(conn, current_user["id"], days=days)
    return {"ok": True, "history": data}


@router.get("/{sesion_id}", response_model=SesionEntrenoResponse)
def get_session(
    sesion_id: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    with db_connection_context() as conn:
        sesion = get_sesion_by_id(conn, sesion_id, current_user["id"])
        if not sesion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "SESSION_NOT_FOUND", "message": "Sesión no encontrada"},
            )
        regs = get_registros_by_sesion(conn, sesion_id)
        return _sesion_to_response(sesion, regs)


@router.patch("/{sesion_id}", response_model=SesionEntrenoResponse)
def update_session(
    sesion_id: str,
    payload: SesionEntrenoUpdate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    data = payload.model_dump(exclude_unset=True)
    with db_connection_context() as conn:
        sesion = update_sesion(conn, sesion_id, current_user["id"], data)
        if not sesion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "SESSION_NOT_FOUND", "message": "Sesión no encontrada"},
            )
        regs = get_registros_by_sesion(conn, sesion_id)
        return _sesion_to_response(sesion, regs)


@router.delete("/{sesion_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_session(
    sesion_id: str,
    current_user: dict = Depends(get_current_user),
) -> None:
    with db_connection_context() as conn:
        deleted = delete_sesion(conn, sesion_id, current_user["id"])
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "SESSION_NOT_FOUND", "message": "Sesión no encontrada"},
            )


@router.post("/{sesion_id}/exercises")
def register_session_exercises(
    sesion_id: str,
    payload: RegistrarSetsRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    registros_data = [r.model_dump() for r in payload.registros]
    with db_connection_context() as conn:
        sesion = get_sesion_by_id(conn, sesion_id, current_user["id"])
        if not sesion:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "SESSION_NOT_FOUND", "message": "Sesión no encontrada"},
            )
        ejercicio_id = payload.ejercicio_id
        if not ejercicio_id:
            if not payload.ejercicio_nombre:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={
                        "code": "EXERCISE_ID_OR_NAME_REQUIRED",
                        "message": "Debes enviar ejercicio_id o ejercicio_nombre",
                    },
                )

            ejercicio = get_or_create_ejercicio_by_nombre(
                conn,
                nombre=payload.ejercicio_nombre,
                grupo_muscular=payload.ejercicio_grupo_muscular,
                equipo=payload.ejercicio_equipo,
            )
            ejercicio_id = ejercicio.id

        created = registrar_sets(conn, sesion_id, current_user["id"], ejercicio_id, registros_data)
        return {
            "ok": True,
            "sesion_id": sesion_id,
            "ejercicio_id": ejercicio_id,
            "created_sets": len(created),
            "registros": [
                {
                    "id": r.id,
                    "sesion_id": r.sesion_id,
                    "ejercicio_id": r.ejercicio_id,
                    "ejercicio_nombre": r.ejercicio.nombre if getattr(r, "ejercicio", None) else None,
                    "ejercicio_grupo_muscular": r.ejercicio.grupo_muscular if getattr(r, "ejercicio", None) else None,
                    "ejercicio_equipo": r.ejercicio.equipo_necesario if getattr(r, "ejercicio", None) else None,
                    "set_numero": r.set_numero,
                    "peso_kg": r.peso_kg,
                    "repeticiones": r.repeticiones,
                    "rpe": r.rpe,
                    "completado": r.completado,
                    "notas": r.notas,
                    "created_at": r.created_at,
                }
                for r in created
            ],
        }
