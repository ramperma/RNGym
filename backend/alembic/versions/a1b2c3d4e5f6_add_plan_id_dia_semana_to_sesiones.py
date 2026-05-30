"""add_plan_semanal_id_and_dia_semana_to_sesiones_entreno

Revision ID: a1b2c3d4e5f6
Revises: b3e9f1a2c4d5
Create Date: 2026-05-27

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = 'b3e9f1a2c4d5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('sesiones_entreno', sa.Column('plan_semanal_id', sa.String(36), nullable=True))
    op.add_column('sesiones_entreno', sa.Column('dia_semana', sa.Integer(), nullable=True))
    op.create_index('ix_sesiones_plan_dia', 'sesiones_entreno', ['plan_semanal_id', 'dia_semana'])


def downgrade() -> None:
    op.drop_index('ix_sesiones_plan_dia', 'sesiones_entreno')
    op.drop_column('sesiones_entreno', 'dia_semana')
    op.drop_column('sesiones_entreno', 'plan_semanal_id')
