from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class PlanSemanal(Base):
    __tablename__ = "planes_semanales"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    usuario_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id"), nullable=False, index=True
    )
    nombre: Mapped[str] = mapped_column(String(200), nullable=False)
    objetivo: Mapped[str] = mapped_column(String(50), nullable=False)
    nivel: Mapped[str] = mapped_column(String(30), nullable=False, default="intermedio")
    duracion_max_minutos: Mapped[int] = mapped_column(Integer, nullable=False, default=75)
    dias_entreno_objetivo: Mapped[int] = mapped_column(Integer, nullable=False, default=4)
    equipo_disponible: Mapped[list[str]] = mapped_column(
        ARRAY(String(100)), nullable=False, default=[]
    )
    lesiones_o_limitaciones: Mapped[list[str] | None] = mapped_column(
        ARRAY(String(200)), nullable=True
    )
    plan_json: Mapped[dict] = mapped_column(JSONB, nullable=False)
    metadata_ia: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    activo: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )


import uuid  # noqa: E402, F401