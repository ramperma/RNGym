from sqlalchemy import delete
from sqlalchemy.engine import Connection

from app.models.ejercicio_usuario import EjercicioUsuario


def create_ejercicio_usuario(
    conn: Connection,
    usuario_id: str,
    nombre: str,
    grupo_muscular: str | None = None,
    machine_nombre: str | None = None,
    machine_foto_path: str | None = None,
    series: int = 3,
    repeticiones: str | None = None,
    descanso_segundos: int = 90,
    rir_o_pe: str | None = None,
    notas: str | None = None,
) -> EjercicioUsuario:
    ejercicio = EjercicioUsuario(
        usuario_id=usuario_id,
        nombre=nombre,
        grupo_muscular=grupo_muscular,
        machine_nombre=machine_nombre,
        machine_foto_path=machine_foto_path,
        series=series,
        repeticiones=repeticiones,
        descanso_segundos=descanso_segundos,
        rir_o_pe=rir_o_pe,
        notas=notas,
    )
    conn.add(ejercicio)
    conn.commit()
    conn.refresh(ejercicio)
    return ejercicio


def list_ejercicios_usuario(conn: Connection, usuario_id: str) -> list[EjercicioUsuario]:
    result = conn.execute(
        EjercicioUsuario.__table__.select()
        .where(EjercicioUsuario.usuario_id == usuario_id)
        .order_by(EjercicioUsuario.created_at.desc())
    )
    return list(result.all())


def get_ejercicio_usuario_by_id(conn: Connection, ejercicio_id: str, usuario_id: str) -> EjercicioUsuario | None:
    result = conn.execute(
        EjercicioUsuario.__table__.select()
        .where(EjercicioUsuario.id == ejercicio_id, EjercicioUsuario.usuario_id == usuario_id)
    )
    row = result.first()
    return EjercicioUsuario(**row._asdict()) if row else None


def update_ejercicio_usuario(
    conn: Connection, ejercicio_id: str, usuario_id: str, data: dict
) -> EjercicioUsuario | None:
    ejercicio = get_ejercicio_usuario_by_id(conn, ejercicio_id, usuario_id)
    if not ejercicio:
        return None
    for key, value in data.items():
        if value is not None and hasattr(ejercicio, key):
            setattr(ejercicio, key, value)
    conn.commit()
    conn.refresh(ejercicio)
    return ejercicio


def delete_ejercicio_usuario(conn: Connection, ejercicio_id: str, usuario_id: str) -> bool:
    result = conn.execute(
        delete(EjercicioUsuario.__table__).where(
            EjercicioUsuario.id == ejercicio_id, EjercicioUsuario.usuario_id == usuario_id
        )
    )
    conn.commit()
    return result.rowcount > 0
