from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1.auth import router as auth_router
from app.api.v1.health_profile import router as health_profile_router
from app.api.v1.routines import router as routines_router
from app.api.v1.sessions import router as sessions_router
from app.api.v1.daily_records import router as daily_records_router
from app.api.v1.ai import router as ai_router
from app.api.v1.admin import router as admin_router
from app.api.v1.me import router as me_router
from app.api.v1.dashboard import router as dashboard_router
from app.api.v1.exercises import router as exercises_router
from app.api.routes import router as public_router
from app.core.config import settings
from app.db import engine
from app.middleware.rlsmiddleware import RLSContextMiddleware

app = FastAPI(title=settings.app_name, version="0.6.0")


@app.on_event("startup")
def on_startup():
    from app.db.bootstrap import ensure_schema_compatibility
    ensure_schema_compatibility(engine)


app.add_middleware(

    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(RLSContextMiddleware)

app.state.db_engine = engine

app.include_router(public_router)
app.include_router(auth_router)
app.include_router(health_profile_router)
app.include_router(routines_router)
app.include_router(sessions_router)
app.include_router(daily_records_router)
app.include_router(ai_router)
app.include_router(admin_router)
app.include_router(me_router)
app.include_router(dashboard_router)
app.include_router(exercises_router)

# Montar directorio de imágenes de ejercicios para servir estáticamente
_exercises_storage_dir = Path(__file__).resolve().parent.parent / "storage" / "exercises"
_exercises_storage_dir.mkdir(parents=True, exist_ok=True)
app.mount("/storage/exercises", StaticFiles(directory=_exercises_storage_dir), name="exercise-photos")

_flutter_web_dir = (
    Path(__file__).resolve().parents[1] / "../flutter_app/build/web"
).resolve()

@app.get("/")
def root() -> dict:
    return {
        "ok": True,
        "message": "Gym Trainer API running",
        "docs": "/docs",
        "api_base": "/api/v1",
    }