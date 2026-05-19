"""initial schema - complete model without nutrition

Revision ID: 001
Revises:
Create Date: 2026-05-03

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import ARRAY, JSONB, UUID

revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"")
    op.execute("CREATE EXTENSION IF NOT EXISTS \"pg_trgm\"")

    op.execute("""
        CREATE TYPE rol_usuario AS ENUM ('admin', 'entrenador', 'usuario')
    """)
    op.execute("""
        CREATE TYPE sexo_biologico AS ENUM ('M', 'F', 'O')
    """)
    op.execute("""
        CREATE TYPE unidad_peso AS ENUM ('kg', 'lb')
    """)
    op.execute("""
        CREATE TYPE unidad_distancia AS ENUM ('km', 'mi')
    """)
    op.execute("""
        CREATE TYPE tipo_ejercicio AS ENUM ('fuerza', 'cardio', 'flexibilidad', 'equilibrio')
    """)
    op.execute("""
        CREATE TYPE grupo_muscular AS ENUM (
            'pecho', 'espalda', 'hombro', 'bicep', 'tricep', 'antebrazo',
            'abdomen', 'oblicuos', 'cuadriceps', 'femoral', 'gluteo',
            'gemelo', 'core', 'full_body'
        )
    """)
    op.execute("""
        CREATE TYPE tipo_rutina AS ENUM ('fuerza', 'hipertrofia', 'definicion', 'cardio', 'funcional', 'flexibilidad')
    """)
    op.execute("""
        CREATE TYPE dificultad_ejercicio AS ENUM ('principiante', 'intermedio', 'avanzado')
    """)
    op.execute("""
        CREATE TYPE estado_sesion AS ENUM ('planificada', 'en_progreso', 'completada', 'cancelada')
    """)
    op.execute("""
        CREATE TYPE fuente_creacion AS ENUM ('entrenador', 'ia', 'usuario')
    """)

    op.execute("""
        CREATE TABLE usuarios (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            email VARCHAR(255) NOT NULL UNIQUE,
            hashed_password VARCHAR(255) NOT NULL,
            nombre VARCHAR(100) NOT NULL,
            apellidos VARCHAR(150),
            rol rol_usuario NOT NULL DEFAULT 'usuario',
            idioma VARCHAR(5) DEFAULT 'es',
            timezone VARCHAR(50) DEFAULT 'Europe/Madrid',
            email_verificado BOOLEAN DEFAULT FALSE,
            fecha_alta TIMESTAMPTZ DEFAULT NOW(),
            ultimo_acceso TIMESTAMPTZ,
            esta_activo BOOLEAN DEFAULT TRUE,
            consentimiento_gdpr BOOLEAN NOT NULL DEFAULT FALSE,
            fecha_consentimiento TIMESTAMPTZ,
            consentimiento_marketing BOOLEAN DEFAULT FALSE,
            version_politica_privacidad VARCHAR(20) DEFAULT '1.0'
        )
    """)
    op.execute("CREATE INDEX idx_usuarios_email ON usuarios(email)")
    op.execute("CREATE INDEX idx_usuarios_rol ON usuarios(rol)")

    op.execute("""
        CREATE TABLE perfiles_salud (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE UNIQUE,
            fecha_nacimiento DATE,
            sexo_biologico sexo_biologico,
            altura_cm DECIMAL(5,2),
            peso_actual_kg DECIMAL(5,2),
            peso_deseado_kg DECIMAL(5,2),
            porcentaje_grasa DECIMAL(4,1),
            porcentaje_musculo DECIMAL(4,1),
            tmb_kcal INTEGER,
            factor_actividad DECIMAL(3,2) DEFAULT 1.2,
            lesiones TEXT[],
            condiciones_medicas TEXT[],
            alergias TEXT[],
            medicamentos TEXT[],
            restricciones_nutricionales TEXT[],
            objetivo_principal VARCHAR(100),
            objetivo_detalle TEXT,
            consentimiento_salud BOOLEAN NOT NULL DEFAULT FALSE,
            fecha_consentimiento_salud TIMESTAMPTZ,
            fecha_ultima_actualizacion TIMESTAMPTZ DEFAULT NOW(),
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("""
        ALTER TABLE perfiles_salud ENABLE ROW LEVEL SECURITY
    """)
    op.execute("""
        CREATE POLICY rl_perfil_salud_usuario ON perfiles_salud
            FOR ALL USING (usuario_id::text = current_setting('app.current_user_id', TRUE))
    """)

    op.execute("""
        CREATE TABLE ejercicios (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            nombre VARCHAR(150) NOT NULL,
            nombre_normalizado VARCHAR(150),
            descripcion TEXT,
            grupo_muscular VARCHAR(50) NOT NULL,
            grupos_secundarios VARCHAR(50)[],
            tipo_ejercicio VARCHAR(30) NOT NULL,
            dificultad VARCHAR(20) DEFAULT 'principiante',
            equipo_necesario VARCHAR(100),
            instrucciones TEXT[],
            musculos_implicados TEXT[],
            es_publico BOOLEAN DEFAULT TRUE,
            creado_por UUID REFERENCES usuarios(id),
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("CREATE INDEX idx_ejercicios_grupo ON ejercicios(grupo_muscular)")
    op.execute("CREATE INDEX idx_ejercicios_tipo ON ejercicios(tipo_ejercicio)")
    op.execute("""
        CREATE INDEX idx_ejercicios_nombre_trgm ON ejercicios
            USING gin(nombre_normalizado gin_trgm_ops)
    """)
    op.execute("""
        CREATE POLICY rl_ejercicios_read ON ejercicios
            FOR SELECT USING (
                es_publico = TRUE
                OR creado_por::text = current_setting('app.current_user_id', TRUE)
            )
    """)

    op.execute("""
        CREATE TABLE rutinas (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            nombre VARCHAR(150) NOT NULL,
            descripcion TEXT,
            tipo_rutina VARCHAR(30) NOT NULL,
            dificultad VARCHAR(20),
            duracion_estimada_minutos INTEGER,
            frecuencia_semanal INTEGER DEFAULT 3,
            usuario_id UUID REFERENCES usuarios(id),
            creador_id UUID REFERENCES usuarios(id),
            es_publica BOOLEAN DEFAULT FALSE,
            fuente_creacion VARCHAR(20) DEFAULT 'entrenador',
            metadata_ia JSONB,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            activa BOOLEAN DEFAULT TRUE
        )
    """)
    op.execute("""
        ALTER TABLE rutinas ENABLE ROW LEVEL SECURITY
    """)
    op.execute("""
        CREATE POLICY rl_rutinas_usuario ON rutinas
            FOR ALL USING (
                usuario_id::text = current_setting('app.current_user_id', TRUE)
                OR es_publica = TRUE
                OR (usuario_id IS NULL AND es_publica = TRUE)
            )
    """)

    op.execute("""
        CREATE TABLE rutina_ejercicios (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            rutina_id UUID NOT NULL REFERENCES rutinas(id) ON DELETE CASCADE,
            ejercicio_id UUID NOT NULL REFERENCES ejercicios(id),
            orden INTEGER NOT NULL DEFAULT 1,
            series INTEGER NOT NULL DEFAULT 3,
            repeticiones VARCHAR(30) NOT NULL DEFAULT '10-12',
            descanso_segundos INTEGER DEFAULT 90,
            tempo VARCHAR(10),
            notas TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE sesiones_entreno (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            usuario_id UUID NOT NULL REFERENCES usuarios(id),
            rutina_id UUID REFERENCES rutinas(id),
            nombre VARCHAR(150),
            fecha_inicio TIMESTAMPTZ NOT NULL,
            fecha_fin TIMESTAMPTZ,
            duracion_minutos INTEGER,
            estado VARCHAR(20) DEFAULT 'planificada',
            kcal_estimadas INTEGER,
            kcal_real INTEGER,
            notas TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("""
        ALTER TABLE sesiones_entreno ENABLE ROW LEVEL SECURITY
    """)
    op.execute("""
        CREATE POLICY rl_sesiones_usuario ON sesiones_entreno
            FOR ALL USING (usuario_id::text = current_setting('app.current_user_id', TRUE))
    """)

    op.execute("""
        CREATE TABLE sesion_ejercicio_registros (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            sesion_id UUID NOT NULL REFERENCES sesiones_entreno(id) ON DELETE CASCADE,
            ejercicio_id UUID NOT NULL REFERENCES ejercicios(id),
            set_numero INTEGER NOT NULL,
            peso_kg DECIMAL(6,2),
            repeticiones INTEGER,
            rpe INTEGER,
            completado BOOLEAN DEFAULT TRUE,
            notas TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)

    op.execute("""
        CREATE TABLE registros_diarios (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            usuario_id UUID NOT NULL REFERENCES usuarios(id),
            fecha DATE NOT NULL,
            peso_kg DECIMAL(5,2),
            kcal_consumidas INTEGER,
            agua_litros DECIMAL(4,2),
            horas_sueño DECIMAL(3,1),
            calidad_sueno INTEGER,
            nivel_estres INTEGER,
            nivel_energia INTEGER,
            ejercicios_realizados INTEGER,
            minutos_entreno INTEGER,
            notas TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(usuario_id, fecha)
        )
    """)
    op.execute("""
        ALTER TABLE registros_diarios ENABLE ROW LEVEL SECURITY
    """)
    op.execute("""
        CREATE POLICY rl_registros_diarios_usuario ON registros_diarios
            FOR ALL USING (usuario_id::text = current_setting('app.current_user_id', TRUE))
    """)
    op.execute("""
        CREATE INDEX idx_registros_diarios_usuario_fecha
            ON registros_diarios(usuario_id, fecha DESC)
    """)

    op.execute("""
        CREATE TABLE logs_ia (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            usuario_id UUID REFERENCES usuarios(id),
            tipo_consulta VARCHAR(50) NOT NULL,
            prompt TEXT NOT NULL,
            respuesta TEXT,
            proveedor VARCHAR(50) NOT NULL,
            modelo VARCHAR(100) NOT NULL,
            modo_facturacion VARCHAR(20) NOT NULL,
            tokens_entrada INTEGER,
            tokens_salida INTEGER,
            latencia_ms INTEGER,
            coste_estimado DECIMAL(10,6),
            codigo_error VARCHAR(50),
            mensaje_error TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )
    """)
    op.execute("""
        CREATE INDEX idx_logs_ia_usuario ON logs_ia(usuario_id)
    """)
    op.execute("""
        CREATE INDEX idx_logs_ia_created_at ON logs_ia(created_at DESC)
    """)

    op.execute("""
        INSERT INTO ejercicios (id, nombre, nombre_normalizado, grupo_muscular, tipo_ejercicio, dificultad, equipo_necesario, instrucciones, musculos_implicados)
        VALUES
            (
                uuid_generate_v4(), 'Sentadilla goblet', 'sentadilla goblet',
                'cuadriceps', 'fuerza', 'principiante', 'mancuerna',
                ARRAY['Paso 1', 'Paso 2', 'Paso 3'],
                ARRAY['cuadriceps', 'gluteo', 'femoral']
            ),
            (
                uuid_generate_v4(), 'Press banca con mancuernas', 'press banca con mancuernas',
                'pecho', 'fuerza', 'intermedio', 'mancuernas',
                ARRAY['Paso 1', 'Paso 2'],
                ARRAY['pectoral mayor', 'deltoides anterior', 'triceps']
            ),
            (
                uuid_generate_v4(), 'Remo con polea baja', 'remo con polea baja',
                'espalda', 'fuerza', 'principiante', 'polea',
                ARRAY['Paso 1', 'Paso 2'],
                ARRAY['dorsal ancho', 'bicep', 'romboides']
            )
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS logs_ia CASCADE")
    op.execute("DROP TABLE IF EXISTS registros_diarios CASCADE")
    op.execute("DROP TABLE IF EXISTS sesion_ejercicio_registros CASCADE")
    op.execute("DROP TABLE IF EXISTS sesiones_entreno CASCADE")
    op.execute("DROP TABLE IF EXISTS rutina_ejercicios CASCADE")
    op.execute("DROP TABLE IF EXISTS rutinas CASCADE")
    op.execute("DROP TABLE IF EXISTS ejercicios CASCADE")
    op.execute("DROP TABLE IF EXISTS perfiles_salud CASCADE")
    op.execute("DROP TABLE IF EXISTS usuarios CASCADE")

    op.execute("DROP TYPE IF EXISTS fuente_creacion")
    op.execute("DROP TYPE IF EXISTS estado_sesion")
    op.execute("DROP TYPE IF EXISTS dificultad_ejercicio")
    op.execute("DROP TYPE IF EXISTS tipo_rutina")
    op.execute("DROP TYPE IF EXISTS grupo_muscular")
    op.execute("DROP TYPE IF EXISTS tipo_ejercicio")
    op.execute("DROP TYPE IF EXISTS unidad_distancia")
    op.execute("DROP TYPE IF EXISTS unidad_peso")
    op.execute("DROP TYPE IF EXISTS sexo_biologico")
    op.execute("DROP TYPE IF EXISTS rol_usuario")
