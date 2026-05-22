from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class EjercicioUsuario(Base):
    __tablename__ = "ejercicios_usuario"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(__import__("uuid").uuid4())
    )
    usuario_id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id"), nullable=False, index=True
    )
    nombre: Mapped[str] = mapped_column(String(255), nullable=False)
    grupo_muscular: Mapped[str | None] = mapped_column(String(100), nullable=True)
    machine_nombre: Mapped[str | None] = mapped_column(String(255), nullable=True)
    machine_foto_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    series: Mapped[int] = mapped_column(Integer, nullable=False, default=3)
    repeticiones: Mapped[str | None] = mapped_column(String(50), nullable=True)
    descanso_segundos: Mapped[int] = mapped_column(Integer, nullable=False, default=90)
    rir_o_pe: Mapped[str | None] = mapped_column(String(20), nullable=True)
    notas: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
