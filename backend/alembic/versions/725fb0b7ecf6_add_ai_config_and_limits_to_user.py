"""add_ai_config_and_limits_to_user

Revision ID: 725fb0b7ecf6
Revises: 001
Create Date: 2026-05-03

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '725fb0b7ecf6'
down_revision: Union[str, None] = '001'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('usuarios', sa.Column('openai_api_key', sa.String(length=255), nullable=True))
    op.add_column('usuarios', sa.Column('max_rutinas', sa.Integer(), nullable=False, server_default='5'))
    op.add_column('usuarios', sa.Column('max_sesiones_semana', sa.Integer(), nullable=False, server_default='7'))


def downgrade() -> None:
    op.drop_column('usuarios', 'max_sesiones_semana')
    op.drop_column('usuarios', 'max_rutinas')
    op.drop_column('usuarios', 'openai_api_key')
