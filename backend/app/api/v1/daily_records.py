from datetime import date

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.api.deps import get_current_user
from app.db import get_db_connection, db_connection_context
from app.repositories import get_registro_by_fecha, list_registros, upsert_registro_diario
from app.schemas.registro_diario import RegistroDiarioResponse, RegistroDiarioUpdate

router = APIRouter(prefix="/api/v1/daily-records", tags=["daily-records"])


@router.get("", response_model=list[RegistroDiarioResponse])
def list_daily_records(
    skip: int = 0,
    limit: int = 30,
    current_user: dict = Depends(get_current_user),
) -> list[dict]:
    with db_connection_context() as conn:
        registros = list_registros(conn, current_user["id"], skip, limit)
        return [_registro_to_dict(r) for r in registros]


@router.get("/{fecha}", response_model=RegistroDiarioResponse)
def get_daily_record(
    fecha: date,
    current_user: dict = Depends(get_current_user),
) -> dict:
    with db_connection_context() as conn:
        registro = get_registro_by_fecha(conn, current_user["id"], fecha)
        if not registro:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "RECORD_NOT_FOUND", "message": "No existe registro para esa fecha"},
            )
        return _registro_to_dict(registro)


@router.put("/{fecha}", response_model=RegistroDiarioResponse)
def upsert_daily_record(
    fecha: date,
    payload: RegistroDiarioUpdate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    data = payload.model_dump(exclude_unset=True)
    with db_connection_context() as conn:
        registro = upsert_registro_diario(conn, current_user["id"], fecha, data)
        return _registro_to_dict(registro)


def _registro_to_dict(r) -> dict:
    return {
        "id": r.id,
        "usuario_id": r.usuario_id,
        "fecha": r.fecha,
        "peso_kg": r.peso_kg,
        "kcal_consumidas": r.kcal_consumidas,
        "agua_litros": r.agua_litros,
        "horas_sueño": r.horas_sueño,
        "calidad_sueno": r.calidad_sueno,
        "nivel_estres": r.nivel_estres,
        "nivel_energia": r.nivel_energia,
        "ejercicios_realizados": r.ejercicios_realizados,
        "minutos_entreno": r.minutos_entreno,
        "notas": r.notas,
        "created_at": r.created_at,
        "updated_at": r.updated_at,
    }