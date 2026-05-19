from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class PerfilSalud(Base):
    __tablename__ = "perfiles_salud"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    usuario_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False, unique=True
    )

    fecha_nacimiento: Mapped[date | None] = mapped_column(Date, nullable=True)
    sexo_biologico: Mapped[str | None] = mapped_column(
        Enum("M", "F", "O", name="sexo_biologico", create_type=False), nullable=True
    )
    altura_cm: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)
    peso_actual_kg: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)
    peso_deseado_kg: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)
    porcentaje_grasa: Mapped[float | None] = mapped_column(Numeric(4, 1), nullable=True)
    porcentaje_musculo: Mapped[float | None] = mapped_column(Numeric(4, 1), nullable=True)

    tmb_kcal: Mapped[int | None] = mapped_column(Numeric, nullable=True)
    factor_actividad: Mapped[float] = mapped_column(Numeric(3, 2), default=1.2)

    lesiones: Mapped[list[str] | None] = mapped_column(ARRAY(Text), nullable=True)
    condiciones_medicas: Mapped[list[str] | None] = mapped_column(ARRAY(Text), nullable=True)
    alergias: Mapped[list[str] | None] = mapped_column(ARRAY(Text), nullable=True)
    medicamentos: Mapped[list[str] | None] = mapped_column(ARRAY(Text), nullable=True)
    restricciones_nutricionales: Mapped[list[str] | None] = mapped_column(ARRAY(Text), nullable=True)

    objetivo_principal: Mapped[str | None] = mapped_column(String(100), nullable=True)
    objetivo_detalle: Mapped[str | None] = mapped_column(Text, nullable=True)

    consentimiento_salud: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    fecha_consentimiento_salud: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    fecha_ultima_actualizacion: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    usuario: Mapped["Usuario"] = relationship("Usuario", back_populates="perfil_salud")


import uuid  # noqa: E402, F401
from app.models.usuario import Usuario  # noqa: E402, F401
