DROP TABLE IF EXISTS exercises;
DROP TABLE IF EXISTS workout_sessions;
DROP TABLE IF EXISTS user_profile;
DROP TABLE IF EXISTS admin_users;
DROP TABLE IF EXISTS admin_ai_settings;

CREATE TABLE exercises (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    muscle_group TEXT NOT NULL,
    difficulty TEXT NOT NULL,
    equipment TEXT NOT NULL,
    description TEXT NOT NULL,
    instructions TEXT NOT NULL,
    default_sets INTEGER NOT NULL,
    default_reps TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE workout_sessions (
    id TEXT PRIMARY KEY,
    exercise_id TEXT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    performed_at TIMESTAMPTZ NOT NULL,
    sets_completed INTEGER NOT NULL,
    reps_completed TEXT NOT NULL,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_profile (
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

CREATE TABLE admin_ai_settings (
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

CREATE TABLE admin_users (
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

INSERT INTO exercises (
    id,
    name,
    muscle_group,
    difficulty,
    equipment,
    description,
    instructions,
    default_sets,
    default_reps
)
VALUES
    (
        'ex-001',
        'Sentadilla goblet',
        'piernas',
        'principiante',
        'mancuerna',
        'Ejercicio base para piernas y core con una sola carga frontal.',
        'Sujeta una mancuerna al pecho, baja con la espalda neutra hasta romper paralelo y sube empujando el suelo.',
        4,
        '10-12'
    ),
    (
        'ex-002',
        'Press banca con mancuernas',
        'pecho',
        'intermedio',
        'mancuernas',
        'Empuje horizontal para pecho, tríceps y estabilidad escapular.',
        'Apoya escápulas en el banco, baja controlado hasta 90 grados y empuja arriba sin chocar mancuernas.',
        4,
        '8-10'
    ),
    (
        'ex-003',
        'Remo con polea baja',
        'espalda',
        'principiante',
        'polea',
        'Tirón horizontal para espalda media y control postural.',
        'Saca pecho, tira de la empuñadura hacia el ombligo y vuelve lento manteniendo hombros abajo.',
        3,
        '12-15'
    );

INSERT INTO workout_sessions (
    id,
    exercise_id,
    performed_at,
    sets_completed,
    reps_completed,
    notes
)
VALUES
    (
        'ws-seed-001',
        'ex-001',
        NOW() - INTERVAL '1 day',
        4,
        '10-12',
        'Sesión inicial de ejemplo guardada desde seed.'
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
VALUES
    (
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
    );

INSERT INTO admin_ai_settings (
    id,
    ai_enabled,
    provider,
    model_name,
    temperature,
    max_tokens_per_request
)
VALUES
    (
        'default',
        FALSE,
        'backend-unconfigured',
        'gpt-4.1-mini',
        0.70,
        2048
    );
