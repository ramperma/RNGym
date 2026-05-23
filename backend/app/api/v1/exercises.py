from pathlib import Path
import uuid
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import BaseModel
from app.api.v1.auth import get_current_user
from app.db import db_connection_context

router = APIRouter(prefix="/api/v1", tags=["exercises"])

# Ruta absoluta al directorio de storage (resuelve desde este archivo: backend/app/api/v1/)
STORAGE_DIR = Path(__file__).resolve().parents[3] / "storage" / "exercises"


class EjercicioUsuarioCreate(BaseModel):
    nombre: str
    grupo_muscular: str | None = None
    machine_nombre: str | None = None
    machine_foto_path: str | None = None
    series: int = 3
    repeticiones: str | None = None
    descanso_segundos: int = 90
    rir_o_pe: str | None = None
    notas: str | None = None


class EjercicioUsuarioUpdate(BaseModel):
    nombre: str | None = None
    grupo_muscular: str | None = None
    machine_nombre: str | None = None
    machine_foto_path: str | None = None
    series: int | None = None
    repeticiones: str | None = None
    descanso_segundos: int | None = None
    rir_o_pe: str | None = None
    notas: str | None = None


class EjercicioUsuarioResponse(BaseModel):
    id: str
    nombre: str
    grupo_muscular: str | None
    machine_nombre: str | None
    machine_foto_path: str | None
    series: int
    repeticiones: str | None
    descanso_segundos: int
    rir_o_pe: str | None
    notas: str | None

    class Config:
        from_attributes = True


@router.get("/user-exercises", response_model=list[EjercicioUsuarioResponse])
async def list_user_exercises(current_user: dict = Depends(get_current_user)) -> list[EjercicioUsuarioResponse]:
    from app.repositories import list_ejercicios_usuario
    with db_connection_context() as conn:
        ejercicios = list_ejercicios_usuario(conn, current_user["id"])
    return [EjercicioUsuarioResponse.model_validate(e) for e in ejercicios]


@router.post("/user-exercises", response_model=EjercicioUsuarioResponse)
async def create_user_exercise(
    payload: EjercicioUsuarioCreate,
    current_user: dict = Depends(get_current_user),
) -> EjercicioUsuarioResponse:
    from app.repositories import create_ejercicio_usuario
    with db_connection_context() as conn:
        ejercicio = create_ejercicio_usuario(
            conn,
            usuario_id=current_user["id"],
            nombre=payload.nombre,
            grupo_muscular=payload.grupo_muscular,
            machine_nombre=payload.machine_nombre,
            machine_foto_path=payload.machine_foto_path,
            series=payload.series,
            repeticiones=payload.repeticiones,
            descanso_segundos=payload.descanso_segundos,
            rir_o_pe=payload.rir_o_pe,
            notas=payload.notas,
        )
    return EjercicioUsuarioResponse.model_validate(ejercicio)


@router.put("/user-exercises/{exercise_id}", response_model=EjercicioUsuarioResponse)
async def update_user_exercise(
    exercise_id: str,
    payload: EjercicioUsuarioUpdate,
    current_user: dict = Depends(get_current_user),
) -> EjercicioUsuarioResponse:
    from app.repositories import get_ejercicio_usuario_by_id, update_ejercicio_usuario
    with db_connection_context() as conn:
        ejercicio = get_ejercicio_usuario_by_id(conn, exercise_id, current_user["id"])
        if not ejercicio:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ejercicio no encontrado")
        data = payload.model_dump(exclude_unset=True)
        # Borrar foto anterior si se está actualizando con una nueva
        if "machine_foto_path" in data and data["machine_foto_path"] != ejercicio.machine_foto_path:
            if ejercicio.machine_foto_path:
                try:
                    # Resolve actual file path from stored URL
                    project_root = Path(__file__).resolve().parents[3]
                    old_photo_path = project_root / ejercicio.machine_foto_path.lstrip('/')
                    old_photo_path.unlink(missing_ok=True)
                except OSError:
                    pass
        updated = update_ejercicio_usuario(conn, exercise_id, current_user["id"], data)
        if not updated:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ejercicio no encontrado")
    return EjercicioUsuarioResponse.model_validate(updated)


@router.delete("/user-exercises/{exercise_id}")
async def delete_user_exercise(
    exercise_id: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    from app.repositories import get_ejercicio_usuario_by_id, delete_ejercicio_usuario
    with db_connection_context() as conn:
        ejercicio = get_ejercicio_usuario_by_id(conn, exercise_id, current_user["id"])
        if not ejercicio:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ejercicio no encontrado")
        if ejercicio.machine_foto_path:
            try:
                # Resolve actual file path from stored URL
                project_root = Path(__file__).resolve().parents[3]
                photo_path = project_root / ejercicio.machine_foto_path.lstrip('/')
                photo_path.unlink(missing_ok=True)
            except OSError:
                pass
        delete_ejercicio_usuario(conn, exercise_id, current_user["id"])
    return {"ok": True}


@router.post("/user-exercises/upload-photo")
async def upload_user_exercise_photo(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
) -> dict:
    content = await file.read()
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="Archivo demasiado grande (max 10MB)")
    ext = Path(file.filename or "img").suffix.lower()
    if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail="Solo se permiten imágenes jpg, png, webp")
    user_dir = STORAGE_DIR / current_user["id"]
    user_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{uuid.uuid4().hex}{ext}"
    file_path = user_dir / filename
    with file_path.open("wb") as f:
        f.write(content)
    # Return a web-accessible URL path (served by /api/v1/storage static mount)
    # e.g. /api/v1/storage/exercises/<user_id>/<filename>
    relative_url = f"/api/v1/storage/exercises/{current_user['id']}/{filename}"
    return {"foto_path": relative_url}
