"""add_evolucion_config_to_perfiles_salud

Revision ID: b3e9f1a2c4d5
Revises: 345680ddc0fe
Create Date: 2026-05-26

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = 'b3e9f1a2c4d5'
down_revision: Union[str, None] = '345680ddc0fe'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('perfiles_salud', sa.Column('semanas_rotacion', sa.Integer(), nullable=True, server_default='3'))
    op.add_column('perfiles_salud', sa.Column('porcentaje_progresion', sa.Numeric(5, 2), nullable=True, server_default='5.0'))


def downgrade() -> None:
    op.drop_column('perfiles_salud', 'porcentaje_progresion')
    op.drop_column('perfiles_salud', 'semanas_rotacion')
