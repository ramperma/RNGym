"""add_deepseek_api_key_to_user

Revision ID: cea42f352df4
Revises: 50102dc4b922
Create Date: 2026-05-18 00:47:27.077800

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'cea42f352df4'
down_revision: Union[str, None] = '50102dc4b922'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('usuarios', sa.Column('deepseek_api_key', sa.String(length=255), nullable=True))
    op.add_column('usuarios', sa.Column('minimax_api_key', sa.String(length=255), nullable=True))


def downgrade() -> None:
    op.drop_column('usuarios', 'minimax_api_key')
    op.drop_column('usuarios', 'deepseek_api_key')
