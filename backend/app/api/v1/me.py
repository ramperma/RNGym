from fastapi import APIRouter, Depends, HTTPException, status
from app.api.deps import get_current_user
from app.db import get_db_connection, db_connection_context
from app.repositories.user_repository import get_user_by_id, update_user_profile
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/v1/me", tags=["me"])

class UserSettingsUpdate(BaseModel):
    nombre: str | None = None
    apellidos: str | None = None
    openai_api_key: str | None = Field(None, description="OpenAI API Key personalizada")
    deepseek_api_key: str | None = Field(None, description="DeepSeek API Key personalizada")
    minimax_api_key: str | None = Field(None, description="MiniMax API Key personalizada")
    proveedor_ia_preferido: str | None = Field(None, description="Proveedor de IA de preferencia ('deepseek', 'minimax', 'openai', 'gemini' o null)")

@router.get("/")
def get_me(current_user: dict = Depends(get_current_user)):
    return {"ok": True, "user": current_user}

@router.patch("/settings")
def update_settings(
    payload: UserSettingsUpdate,
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user["id"]
    data = payload.model_dump(exclude_unset=True)
    
    with db_connection_context() as conn:
        user = update_user_profile(conn, user_id, data)
        if not user:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")
        return {"ok": True, "message": "Ajustes actualizados", "user": user}
