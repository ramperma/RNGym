import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class Usuario(Base):
    __tablename__ = "usuarios"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    apellidos: Mapped[str | None] = mapped_column(String(150), nullable=True)
    rol: Mapped[str] = mapped_column(String(20), nullable=False, default="usuario")
    idioma: Mapped[str] = mapped_column(String(5), default="es")
    timezone: Mapped[str] = mapped_column(String(50), default="Europe/Madrid")
    email_verificado: Mapped[bool] = mapped_column(Boolean, default=False)
    fecha_alta: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    ultimo_acceso: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    esta_activo: Mapped[bool] = mapped_column(Boolean, default=True)
    consentimiento_gdpr: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    fecha_consentimiento: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    consentimiento_marketing: Mapped[bool] = mapped_column(Boolean, default=False)
    version_politica_privacidad: Mapped[str] = mapped_column(String(20), default="1.0")
    openai_api_key: Mapped[str | None] = mapped_column(String(255), nullable=True)
    deepseek_api_key: Mapped[str | None] = mapped_column(String(255), nullable=True)
    minimax_api_key: Mapped[str | None] = mapped_column(String(255), nullable=True)
    proveedor_ia_preferido: Mapped[str | None] = mapped_column(String(50), nullable=True)
    permitir_ia: Mapped[bool] = mapped_column(Boolean, default=True)
    max_rutinas: Mapped[int] = mapped_column(default=5)
    max_sesiones_semana: Mapped[int] = mapped_column(default=7)

    perfil_salud: Mapped["PerfilSalud | None"] = relationship(
        "PerfilSalud", back_populates="usuario", uselist=False, cascade="all, delete-orphan"
    )
    rutinas: Mapped[list["Rutina"]] = relationship(
        "Rutina", back_populates="usuario", foreign_keys="Rutina.usuario_id"
    )
    sesiones: Mapped[list["SesionEntreno"]] = relationship("SesionEntreno", back_populates="usuario")
    registros_diarios: Mapped[list["RegistroDiario"]] = relationship(
        "RegistroDiario", back_populates="usuario"
    )
    logs_ia: Mapped[list["LogIA"]] = relationship("LogIA", back_populates="usuario")


from app.models.perfil_salud import PerfilSalud  # noqa: E402, F401
from app.models.rutina import Rutina  # noqa: E402, F401
from app.models.sesion_entreno import SesionEntreno  # noqa: E402, F401
from app.models.registro_diario import RegistroDiario  # noqa: E402, F401
from app.models.log_ia import LogIA  # noqa: E402, F401
