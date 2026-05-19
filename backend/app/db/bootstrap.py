from sqlalchemy import text
from sqlalchemy.engine import Engine

_USER_PROFILE_BOOTSTRAP_SQL = """
CREATE TABLE IF NOT EXISTS user_profile (
    id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL DEFAULT '',
    age INTEGER,
    weight_kg NUMERIC(5,2),
    height_cm INTEGER,
    sex TEXT,
    goal TEXT,
    injuries TEXT NOT NULL DEFAULT '',
    medical_notes TEXT NOT NULL DEFAULT '',
    ai_personalization_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT user_profile_age_chk CHECK (age IS NULL OR age BETWEEN 13 AND 100),
    CONSTRAINT user_profile_weight_chk CHECK (weight_kg IS NULL OR weight_kg > 0),
    CONSTRAINT user_profile_height_chk CHECK (height_cm IS NULL OR height_cm BETWEEN 100 AND 250)
);

INSERT INTO user_profile (
    id,
    display_name,
    age,
    weight_kg,
    height_cm,
    sex,
    goal,
    injuries,
    medical_notes,
    ai_personalization_enabled
)
VALUES (
    'main',
    'Ramón',
    33,
    78.5,
    178,
    'masculino',
    'ganar_musculo',
    'Molestia leve de hombro derecho en presses por encima de la cabeza.',
    'Priorizar técnica, progresión prudente y alternativas si aparece dolor.',
    TRUE
)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS admin_ai_settings (
    id TEXT PRIMARY KEY,
    ai_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    provider TEXT NOT NULL DEFAULT 'backend-unconfigured',
    model_name TEXT NOT NULL DEFAULT 'gpt-4.1-mini',
    temperature NUMERIC(3,2) NOT NULL DEFAULT 0.70,
    max_tokens_per_request INTEGER NOT NULL DEFAULT 2048,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT admin_ai_settings_temperature_chk CHECK (temperature >= 0 AND temperature <= 2),
    CONSTRAINT admin_ai_settings_max_tokens_chk CHECK (max_tokens_per_request >= 1)
);

CREATE TABLE IF NOT EXISTS admin_users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    token_limit_daily INTEGER NOT NULL DEFAULT 50000,
    tokens_used_today INTEGER NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT admin_users_token_limit_chk CHECK (token_limit_daily >= 0),
    CONSTRAINT admin_users_tokens_used_chk CHECK (tokens_used_today >= 0)
);

INSERT INTO admin_ai_settings (
    id,
    ai_enabled,
    provider,
    model_name,
    temperature,
    max_tokens_per_request
)
VALUES (
    'default',
    FALSE,
    'backend-unconfigured',
    'gpt-4.1-mini',
    0.70,
    2048
)
ON CONFLICT (id) DO NOTHING;
"""


def ensure_schema_compatibility(engine: Engine) -> None:
    with engine.begin() as connection:
        connection.execute(text(_USER_PROFILE_BOOTSTRAP_SQL))
