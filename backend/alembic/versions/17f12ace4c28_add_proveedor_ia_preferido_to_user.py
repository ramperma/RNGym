"""add_proveedor_ia_preferido_to_user

Revision ID: 17f12ace4c28
Revises: cea42f352df4
Create Date: 2026-05-18 00:58:59.390879

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '17f12ace4c28'
down_revision: Union[str, None] = 'cea42f352df4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('usuarios', sa.Column('proveedor_ia_preferido', sa.String(length=50), nullable=True))


def downgrade() -> None:
    op.drop_column('usuarios', 'proveedor_ia_preferido')
