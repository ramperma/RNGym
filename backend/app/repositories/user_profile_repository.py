from sqlalchemy import text
from sqlalchemy.engine import Connection

from app.models.user_profile import AiStatus, UserProfile, UserProfileUpsert

_PROFILE_COLUMNS = """
    id,
    display_name,
    age,
    weight_kg,
    height_cm,
    sex,
    goal,
    injuries,
    medical_notes,
    ai_personalization_enabled,
    updated_at,
    created_at
"""

_GET_PROFILE_QUERY = text(
    f"""
    SELECT {_PROFILE_COLUMNS}
    FROM user_profile
    WHERE id = :profile_id
    """
)

_UPSERT_PROFILE_QUERY = text(
    """
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
    ) VALUES (
        :id,
        :display_name,
        :age,
        :weight_kg,
        :height_cm,
        :sex,
        :goal,
        :injuries,
        :medical_notes,
        :ai_personalization_enabled
    )
    ON CONFLICT (id)
    DO UPDATE SET
        display_name = EXCLUDED.display_name,
        age = EXCLUDED.age,
        weight_kg = EXCLUDED.weight_kg,
        height_cm = EXCLUDED.height_cm,
        sex = EXCLUDED.sex,
        goal = EXCLUDED.goal,
        injuries = EXCLUDED.injuries,
        medical_notes = EXCLUDED.medical_notes,
        ai_personalization_enabled = EXCLUDED.ai_personalization_enabled,
        updated_at = NOW()
    """
)


def get_user_profile(connection: Connection, profile_id: str = "main") -> UserProfile | None:
    row = connection.execute(_GET_PROFILE_QUERY, {"profile_id": profile_id}).mappings().first()
    if row is None:
        return None
    return UserProfile(**row)


def upsert_user_profile(
    connection: Connection,
    payload: UserProfileUpsert,
    *,
    profile_id: str = "main",
) -> UserProfile:
    connection.execute(
        _UPSERT_PROFILE_QUERY,
        {
            "id": profile_id,
            "display_name": payload.display_name.strip(),
            "age": payload.age,
            "weight_kg": payload.weight_kg,
            "height_cm": payload.height_cm,
            "sex": payload.sex,
            "goal": payload.goal,
            "injuries": payload.injuries.strip(),
            "medical_notes": payload.medical_notes.strip(),
            "ai_personalization_enabled": payload.ai_personalization_enabled,
        },
    )
    connection.commit()
    profile = get_user_profile(connection, profile_id)
    if profile is None:
        raise RuntimeError("User profile upsert failed")
    return profile


def build_ai_status(*, enabled: bool, provider: str, personalization_ready: bool) -> AiStatus:
    return AiStatus(
        enabled=enabled,
        provider=provider,
        status="connected" if enabled else "disabled",
        personalization_ready=personalization_ready,
    )
