"""add_maquinas_gym_and_planes_semanales

Revision ID: 50102dc4b922
Revises: 725fb0b7ecf6
Create Date: 2026-05-17 22:41:30.643350

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID


revision: str = '50102dc4b922'
down_revision: Union[str, None] = '725fb0b7ecf6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")

    op.create_table(
        'maquinas_gym',
        sa.Column('id', UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())),
        sa.Column('usuario_id', UUID(as_uuid=False), sa.ForeignKey('usuarios.id'), nullable=False),
        sa.Column('nombre', sa.String(150), nullable=False),
        sa.Column('foto_path', sa.String(500), nullable=True),
        sa.Column('descripcion_uso', sa.Text, nullable=True),
        sa.Column('grupo_muscular', sa.String(50), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index('idx_maquinas_gym_usuario', 'maquinas_gym', ['usuario_id'])

    op.create_table(
        'planes_semanales',
        sa.Column('id', UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4())),
        sa.Column('usuario_id', UUID(as_uuid=False), sa.ForeignKey('usuarios.id'), nullable=False),
        sa.Column('nombre', sa.String(200), nullable=False),
        sa.Column('objetivo', sa.String(50), nullable=False),
        sa.Column('nivel', sa.String(30), nullable=False, server_default='intermedio'),
        sa.Column('duracion_max_minutos', sa.Integer(), nullable=False, server_default=sa.text('75')),
        sa.Column('dias_entreno_objetivo', sa.Integer(), nullable=False, server_default=sa.text('4')),
        sa.Column('equipo_disponible', ARRAY(sa.String(100)), nullable=False, server_default=sa.text("'{}'::text[]")),
        sa.Column('lesiones_o_limitaciones', ARRAY(sa.String(200)), nullable=True),
        sa.Column('plan_json', JSONB, nullable=False),
        sa.Column('metadata_ia', JSONB, nullable=True),
        sa.Column('activo', sa.Boolean(), server_default=sa.text('true')),
        sa.Column('created_at', sa.DateTime(), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.func.now(), onupdate=sa.func.now()),
    )
    op.create_index('idx_planes_semanales_usuario', 'planes_semanales', ['usuario_id'])
    op.create_index('idx_planes_semanales_activo', 'planes_semanales', ['usuario_id', 'activo'])


def downgrade() -> None:
    op.drop_table('planes_semanales')
    op.drop_table('maquinas_gym')


import uuid  # noqa: E402, F401
