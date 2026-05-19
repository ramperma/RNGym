from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


GoalType = Literal[
    "perder_grasa",
    "ganar_musculo",
    "mantener",
    "rendimiento",
    "salud_general",
]

SexType = Literal["masculino", "femenino", "otro", "prefiero_no_decir"]


class UserProfile(BaseModel):
    id: str
    display_name: str
    age: int | None = Field(default=None, ge=13, le=100)
    weight_kg: float | None = Field(default=None, gt=0, le=400)
    height_cm: int | None = Field(default=None, ge=100, le=250)
    sex: SexType | None = None
    goal: GoalType | None = None
    injuries: str = ""
    medical_notes: str = ""
    ai_personalization_enabled: bool = True
    updated_at: datetime
    created_at: datetime


class UserProfileUpsert(BaseModel):
    display_name: str = Field(default="", max_length=120)
    age: int | None = Field(default=None, ge=13, le=100)
    weight_kg: float | None = Field(default=None, gt=0, le=400)
    height_cm: int | None = Field(default=None, ge=100, le=250)
    sex: SexType | None = None
    goal: GoalType | None = None
    injuries: str = Field(default="", max_length=1000)
    medical_notes: str = Field(default="", max_length=2000)
    ai_personalization_enabled: bool = True


class UserProfilePayload(BaseModel):
    ok: bool = True
    data: UserProfile


class AiStatus(BaseModel):
    enabled: bool
    provider: str
    status: str
    personalization_ready: bool
    uses_backend_credentials: bool = True
    client_can_store_api_key: bool = False


class AiStatusPayload(BaseModel):
    ok: bool = True
    data: AiStatus
