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
"""


def ensure_schema_compatibility(engine: Engine) -> None:
    with engine.begin() as connection:
        connection.execute(text(_USER_PROFILE_BOOTSTRAP_SQL))
