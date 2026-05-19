from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class LogIA(Base):
    __tablename__ = "logs_ia"

    id: Mapped[str] = mapped_column(
        UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())
    )
    usuario_id: Mapped[str | None] = mapped_column(
        UUID(as_uuid=False), ForeignKey("usuarios.id"), nullable=True
    )
    tipo_consulta: Mapped[str] = mapped_column(String(50), nullable=False)
    prompt: Mapped[str] = mapped_column(Text, nullable=False)
    respuesta: Mapped[str | None] = mapped_column(Text, nullable=True)
    proveedor: Mapped[str] = mapped_column(String(50), nullable=False)
    modelo: Mapped[str] = mapped_column(String(100), nullable=False)
    modo_facturacion: Mapped[str] = mapped_column(String(20), nullable=False)
    tokens_entrada: Mapped[int | None] = mapped_column(Integer, nullable=True)
    tokens_salida: Mapped[int | None] = mapped_column(Integer, nullable=True)
    latencia_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    coste_estimado: Mapped[float | None] = mapped_column(Numeric(10, 6), nullable=True)
    codigo_error: Mapped[str | None] = mapped_column(String(50), nullable=True)
    mensaje_error: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    usuario: Mapped["Usuario | None"] = relationship("Usuario", back_populates="logs_ia")


import uuid  # noqa: E402, F401
from app.models.usuario import Usuario  # noqa: E402, F401
