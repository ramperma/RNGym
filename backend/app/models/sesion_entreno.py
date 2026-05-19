from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class SesionEntreno(Base):
    __tablename__ = "sesiones_entreno"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    usuario_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id"), nullable=False
    )
    rutina_id: Mapped[str | None] = mapped_column(
        UUID(as_uuid=False), ForeignKey("rutinas.id"), nullable=True
    )
    nombre: Mapped[str | None] = mapped_column(String(150), nullable=True)

    fecha_inicio: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    fecha_fin: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    duracion_minutos: Mapped[int | None] = mapped_column(Integer, nullable=True)
    estado: Mapped[str] = mapped_column(String(20), default="planificada")

    kcal_estimadas: Mapped[int | None] = mapped_column(Integer, nullable=True)
    kcal_real: Mapped[int | None] = mapped_column(Integer, nullable=True)

    notas: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    usuario: Mapped["Usuario"] = relationship("Usuario", back_populates="sesiones")
    rutina: Mapped["Rutina | None"] = relationship("Rutina")
    registros: Mapped[list["SesionEjercicioRegistro"]] = relationship(
        "SesionEjercicioRegistro",
        back_populates="sesion",
        cascade="all, delete-orphan",
        order_by="SesionEjercicioRegistro.set_numero",
    )


class SesionEjercicioRegistro(Base):
    __tablename__ = "sesion_ejercicio_registros"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    sesion_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("sesiones_entreno.id", ondelete="CASCADE"), nullable=False
    )
    ejercicio_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("ejercicios.id"), nullable=False
    )
    set_numero: Mapped[int] = mapped_column(Integer, nullable=False)
    peso_kg: Mapped[float | None] = mapped_column(Numeric(6, 2), nullable=True)
    repeticiones: Mapped[int | None] = mapped_column(Integer, nullable=True)
    rpe: Mapped[int | None] = mapped_column(Integer, nullable=True)
    completado: Mapped[bool] = mapped_column(default=True)
    notas: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    sesion: Mapped["SesionEntreno"] = relationship("SesionEntreno", back_populates="registros")
    ejercicio: Mapped["Ejercicio"] = relationship("Ejercicio")


import uuid  # noqa: E402, F401
from app.models.usuario import Usuario  # noqa: E402, F401
from app.models.rutina import Rutina  # noqa: E402, F401
from app.models.ejercicio import Ejercicio  # noqa: E402, F401
