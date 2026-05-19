from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class RegistroDiario(Base):
    __tablename__ = "registros_diarios"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    usuario_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id"), nullable=False
    )
    fecha: Mapped[date] = mapped_column(Date, nullable=False)

    peso_kg: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)
    kcal_consumidas: Mapped[int | None] = mapped_column(Integer, nullable=True)
    agua_litros: Mapped[float | None] = mapped_column(Numeric(4, 2), nullable=True)

    horas_sueño: Mapped[float | None] = mapped_column(Numeric(3, 1), nullable=True)
    calidad_sueno: Mapped[int | None] = mapped_column(Integer, nullable=True)
    nivel_estres: Mapped[int | None] = mapped_column(Integer, nullable=True)
    nivel_energia: Mapped[int | None] = mapped_column(Integer, nullable=True)

    ejercicios_realizados: Mapped[int | None] = mapped_column(Integer, nullable=True)
    minutos_entreno: Mapped[int | None] = mapped_column(Integer, nullable=True)

    notas: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    usuario: Mapped["Usuario"] = relationship("Usuario", back_populates="registros_diarios")


import uuid  # noqa: E402, F401
from app.models.usuario import Usuario  # noqa: E402, F401
