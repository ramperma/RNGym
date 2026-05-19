from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class Rutina(Base):
    __tablename__ = "rutinas"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    nombre: Mapped[str] = mapped_column(String(150), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)
    tipo_rutina: Mapped[str] = mapped_column(String(30), nullable=False)
    dificultad: Mapped[str | None] = mapped_column(String(20), nullable=True)
    duracion_estimada_minutos: Mapped[int | None] = mapped_column(Integer, nullable=True)
    frecuencia_semanal: Mapped[int] = mapped_column(Integer, default=3)

    usuario_id: Mapped[str | None] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id"), nullable=True
    )
    creador_id: Mapped[str | None] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id"), nullable=True
    )
    es_publica: Mapped[bool] = mapped_column(Boolean, default=False)

    fuente_creacion: Mapped[str] = mapped_column(String(20), default="entrenador")
    metadata_ia: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
    activa: Mapped[bool] = mapped_column(Boolean, default=True)

    usuario: Mapped["Usuario | None"] = relationship("Usuario", back_populates="rutinas", foreign_keys=[usuario_id])
    creador: Mapped["Usuario | None"] = relationship("Usuario", foreign_keys=[creador_id])
    ejercicios: Mapped[list["RutinaEjercicio"]] = relationship(
        "RutinaEjercicio", back_populates="rutina", cascade="all, delete-orphan", order_by="RutinaEjercicio.orden"
    )


class RutinaEjercicio(Base):
    __tablename__ = "rutina_ejercicios"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    rutina_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("rutinas.id", ondelete="CASCADE"), nullable=False
    )
    ejercicio_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("ejercicios.id"), nullable=False
    )
    orden: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    series: Mapped[int] = mapped_column(Integer, nullable=False, default=3)
    repeticiones: Mapped[str] = mapped_column(String(30), nullable=False, default="10-12")
    descanso_segundos: Mapped[int | None] = mapped_column(Integer, nullable=True, default=90)
    tempo: Mapped[str | None] = mapped_column(String(10), nullable=True)
    notas: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    rutina: Mapped["Rutina"] = relationship("Rutina", back_populates="ejercicios")
    ejercicio: Mapped["Ejercicio"] = relationship("Ejercicio")


import uuid  # noqa: E402, F401
from app.models.usuario import Usuario  # noqa: E402, F401
from app.models.ejercicio import Ejercicio  # noqa: E402, F401
