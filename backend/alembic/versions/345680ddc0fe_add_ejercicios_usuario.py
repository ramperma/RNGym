"""add_ejercicios_usuario

Revision ID: 345680ddc0fe
Revises: 94ad8392f13a
Create Date: 2026-05-22 16:55:46.615995

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '345680ddc0fe'
down_revision: Union[str, None] = '94ad8392f13a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'ejercicios_usuario',
        sa.Column('id', sa.UUID(as_uuid=False), nullable=False),
        sa.Column('usuario_id', sa.UUID(as_uuid=False), nullable=False),
        sa.Column('nombre', sa.String(length=255), nullable=False),
        sa.Column('grupo_muscular', sa.String(length=100), nullable=True),
        sa.Column('machine_nombre', sa.String(length=255), nullable=True),
        sa.Column('machine_foto_path', sa.String(length=500), nullable=True),
        sa.Column('series', sa.Integer(), nullable=False),
        sa.Column('repeticiones', sa.String(length=50), nullable=True),
        sa.Column('descanso_segundos', sa.Integer(), nullable=False),
        sa.Column('rir_o_pe', sa.String(length=20), nullable=True),
        sa.Column('notas', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['usuario_id'], ['usuarios.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_ejercicios_usuario_usuario_id'), 'ejercicios_usuario', ['usuario_id'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_ejercicios_usuario_usuario_id'), table_name='ejercicios_usuario')
    op.drop_table('ejercicios_usuario')
