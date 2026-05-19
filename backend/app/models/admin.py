from datetime import datetime

from pydantic import BaseModel, Field


class AdminAiSettings(BaseModel):
    id: str
    ai_enabled: bool
    provider: str
    model_name: str
    temperature: float = Field(ge=0.0, le=2.0)
    max_tokens_per_request: int = Field(ge=1, le=100000)
    updated_at: datetime
    created_at: datetime


class AdminAiSettingsUpsert(BaseModel):
    ai_enabled: bool
    provider: str = Field(min_length=1, max_length=120)
    model_name: str = Field(min_length=1, max_length=120)
    temperature: float = Field(ge=0.0, le=2.0)
    max_tokens_per_request: int = Field(ge=1, le=100000)


class AdminUser(BaseModel):
    id: str
    username: str
    email: str
    is_active: bool
    token_limit_daily: int = Field(ge=0)
    tokens_used_today: int = Field(ge=0)
    notes: str
    updated_at: datetime
    created_at: datetime


class AdminUserCreate(BaseModel):
    username: str = Field(min_length=2, max_length=120)
    email: str = Field(min_length=3, max_length=200)
    token_limit_daily: int = Field(default=50000, ge=0, le=10000000)
    notes: str = Field(default="", max_length=1000)


class AdminUserTokenLimitUpdate(BaseModel):
    token_limit_daily: int = Field(ge=0, le=10000000)


class AdminUserStatusUpdate(BaseModel):
    is_active: bool
