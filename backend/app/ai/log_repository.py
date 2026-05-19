from datetime import datetime

from sqlalchemy import insert

from app.models.log_ia import LogIA


def log_ia(
    conn,
    usuario_id: str | None,
    tipo_consulta: str,
    prompt: str,
    respuesta: str | None,
    proveedor: str,
    modelo: str,
    modo_facturacion: str,
    tokens_entrada: int | None = None,
    tokens_salida: int | None = None,
    latencia_ms: int | None = None,
    coste_estimado: float | None = None,
    codigo_error: str | None = None,
    mensaje_error: str | None = None,
) -> None:
    conn.execute(
        insert(LogIA).values(
            usuario_id=usuario_id,
            tipo_consulta=tipo_consulta,
            prompt=prompt,
            respuesta=respuesta,
            proveedor=proveedor,
            modelo=modelo,
            modo_facturacion=modo_facturacion,
            tokens_entrada=tokens_entrada,
            tokens_salida=tokens_salida,
            latencia_ms=latencia_ms,
            coste_estimado=coste_estimado,
            codigo_error=codigo_error,
            mensaje_error=mensaje_error,
            created_at=datetime.utcnow(),
        )
    )
    conn.commit()