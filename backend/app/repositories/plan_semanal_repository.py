from sqlalchemy import delete, update
from sqlalchemy.engine import Connection

from app.models.plan_semanal import PlanSemanal


def create_plan_semanal(conn: Connection, usuario_id: str, data: dict) -> PlanSemanal:
    plan = PlanSemanal(usuario_id=usuario_id, **data)
    conn.add(plan)
    conn.commit()
    conn.refresh(plan)
    return plan


def get_plan_by_id(conn: Connection, plan_id: str, usuario_id: str) -> PlanSemanal | None:
    result = conn.execute(
        PlanSemanal.__table__.select()
        .where(PlanSemanal.id == plan_id, PlanSemanal.usuario_id == usuario_id)
    )
    row = result.first()
    return PlanSemanal(**row._asdict()) if row else None


def list_planes_semanales(
    conn: Connection, usuario_id: str, skip: int = 0, limit: int = 20, solo_activos: bool = False
) -> list[PlanSemanal]:
    query = PlanSemanal.__table__.select().where(PlanSemanal.usuario_id == usuario_id)
    if solo_activos:
        query = query.where(PlanSemanal.activo == True)
    query = query.order_by(PlanSemanal.created_at.desc()).offset(skip).limit(limit)
    result = conn.execute(query)
    return [PlanSemanal(**row._asdict()) for row in result.all()]


def update_plan_semanal(
    conn: Connection, plan_id: str, usuario_id: str, data: dict
) -> PlanSemanal | None:
    plan_exists = get_plan_by_id(conn, plan_id, usuario_id)
    if not plan_exists:
        return None
    
    valid_data = {}
    for key, value in data.items():
        if value is not None and hasattr(PlanSemanal, key):
            valid_data[key] = value

    if valid_data:
        conn.execute(
            update(PlanSemanal.__table__)
            .where(PlanSemanal.id == plan_id, PlanSemanal.usuario_id == usuario_id)
            .values(**valid_data)
        )
        conn.commit()

    return get_plan_by_id(conn, plan_id, usuario_id)


def deactivate_plan(conn: Connection, plan_id: str, usuario_id: str) -> bool:
    result = conn.execute(
        update(PlanSemanal.__table__)
        .where(PlanSemanal.id == plan_id, PlanSemanal.usuario_id == usuario_id)
        .values(activo=False)
    )
    conn.commit()
    return result.rowcount > 0


def activate_plan(conn: Connection, plan_id: str, usuario_id: str) -> bool:
    # 1. Deactivate all plans of the user
    conn.execute(
        update(PlanSemanal.__table__)
        .where(PlanSemanal.usuario_id == usuario_id)
        .values(activo=False)
    )
    # 2. Activate the selected plan
    result = conn.execute(
        update(PlanSemanal.__table__)
        .where(PlanSemanal.id == plan_id, PlanSemanal.usuario_id == usuario_id)
        .values(activo=True)
    )
    conn.commit()
    return result.rowcount > 0


def delete_plan_semanal(conn: Connection, plan_id: str, usuario_id: str) -> bool:
    result = conn.execute(
        delete(PlanSemanal.__table__).where(
            PlanSemanal.id == plan_id, PlanSemanal.usuario_id == usuario_id
        )
    )
    conn.commit()
    return result.rowcount > 0