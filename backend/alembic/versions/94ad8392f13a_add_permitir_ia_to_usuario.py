"""add_permitir_ia_to_usuario

Revision ID: 94ad8392f13a
Revises: 17f12ace4c28
Create Date: 2026-05-19 18:37:43.493412

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '94ad8392f13a'
down_revision: Union[str, None] = '17f12ace4c28'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('usuarios', sa.Column('permitir_ia', sa.Boolean(), nullable=False, server_default='true'))


def downgrade() -> None:
    op.drop_column('usuarios', 'permitir_ia')
