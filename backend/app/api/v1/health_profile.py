from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user
from app.db import get_db_connection, db_connection_context
from app.repositories import create_or_update_perfil, delete_perfil, get_perfil_by_usuario
from app.schemas.perfil_salud import PerfilSaludCreate, PerfilSaludResponse, PerfilSaludUpdate

router = APIRouter(prefix="/api/v1/health-profile", tags=["health-profile"])


@router.get("", response_model=PerfilSaludResponse)
def get_health_profile(current_user: dict = Depends(get_current_user)) -> dict:
    with db_connection_context() as conn:
        perfil = get_perfil_by_usuario(conn, current_user["id"])
        if not perfil:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"code": "PERFIL_NOT_FOUND", "message": "No existe perfil de salud para este usuario"},
            )
        return {
            "id": perfil.id,
            "usuario_id": perfil.usuario_id,
            "fecha_nacimiento": perfil.fecha_nacimiento,
            "sexo_biologico": perfil.sexo_biologico,
            "altura_cm": perfil.altura_cm,
            "peso_actual_kg": perfil.peso_actual_kg,
            "peso_deseado_kg": perfil.peso_deseado_kg,
            "porcentaje_grasa": perfil.porcentaje_grasa,
            "porcentaje_musculo": perfil.porcentaje_musculo,
            "tmb_kcal": perfil.tmb_kcal,
            "factor_actividad": perfil.factor_actividad,
            "lesiones": perfil.lesiones or [],
            "condiciones_medicas": perfil.condiciones_medicas or [],
            "alergias": perfil.alergias or [],
            "medicamentos": perfil.medicamentos or [],
            "restricciones_nutricionales": perfil.restricciones_nutricionales or [],
            "objetivo_principal": perfil.objetivo_principal,
            "objetivo_detalle": perfil.objetivo_detalle,
            "consentimiento_salud": perfil.consentimiento_salud,
            "fecha_consentimiento_salud": perfil.fecha_consentimiento_salud,
            "fecha_ultima_actualizacion": perfil.fecha_ultima_actualizacion,
            "created_at": perfil.created_at,
            "semanas_rotacion": perfil.semanas_rotacion if perfil.semanas_rotacion is not None else 3,
            "porcentaje_progresion": float(perfil.porcentaje_progresion) if perfil.porcentaje_progresion is not None else 5.0,
        }


@router.put("", response_model=PerfilSaludResponse)
def upsert_health_profile(
    payload: PerfilSaludCreate,
    current_user: dict = Depends(get_current_user),
) -> dict:
    data = payload.model_dump()
    with db_connection_context() as conn:
        perfil = create_or_update_perfil(conn, current_user["id"], data)
        return {
            "id": perfil.id,
            "usuario_id": perfil.usuario_id,
            "fecha_nacimiento": perfil.fecha_nacimiento,
            "sexo_biologico": perfil.sexo_biologico,
            "altura_cm": perfil.altura_cm,
            "peso_actual_kg": perfil.peso_actual_kg,
            "peso_deseado_kg": perfil.peso_deseado_kg,
            "porcentaje_grasa": perfil.porcentaje_grasa,
            "porcentaje_musculo": perfil.porcentaje_musculo,
            "tmb_kcal": perfil.tmb_kcal,
            "factor_actividad": perfil.factor_actividad,
            "lesiones": perfil.lesiones or [],
            "condiciones_medicas": perfil.condiciones_medicas or [],
            "alergias": perfil.alergias or [],
            "medicamentos": perfil.medicamentos or [],
            "restricciones_nutricionales": perfil.restricciones_nutricionales or [],
            "objetivo_principal": perfil.objetivo_principal,
            "objetivo_detalle": perfil.objetivo_detalle,
            "consentimiento_salud": perfil.consentimiento_salud,
            "fecha_consentimiento_salud": perfil.fecha_consentimiento_salud,
            "fecha_ultima_actualizacion": perfil.fecha_ultima_actualizacion,
            "created_at": perfil.created_at,
            "semanas_rotacion": perfil.semanas_rotacion if perfil.semanas_rotacion is not None else 3,
            "porcentaje_progresion": float(perfil.porcentaje_progresion) if perfil.porcentaje_progresion is not None else 5.0,
        }


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def delete_health_profile(
    current_user: dict = Depends(get_current_user),
) -> None:
    with db_connection_context() as conn:
        delete_perfil(conn, current_user["id"])