from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class Ejercicio(Base):
    __tablename__ = "ejercicios"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    nombre: Mapped[str] = mapped_column(String(150), nullable=False)
    nombre_normalizado: Mapped[str | None] = mapped_column(String(150), nullable=True)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)
    grupo_muscular: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    grupos_secundarios: Mapped[list[str] | None] = mapped_column(ARRAY(String(50)), nullable=True)
    tipo_ejercicio: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    dificultad: Mapped[str] = mapped_column(String(20), default="principiante")
    equipo_necesario: Mapped[str | None] = mapped_column(String(100), nullable=True)
    instrucciones: Mapped[list[str] | None] = mapped_column(ARRAY(Text), nullable=True)
    musculos_implicados: Mapped[list[str] | None] = mapped_column(ARRAY(Text), nullable=True)
    es_publico: Mapped[bool] = mapped_column(Boolean, default=True)
    creado_por: Mapped[str | None] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )


import uuid  # noqa: E402, F401
