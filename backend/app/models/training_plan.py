from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


TrainingFrequency = Literal["daily", "weekly", "monthly"]


class TrainingPlanRequest(BaseModel):
    training_type: TrainingFrequency = Field(..., description="daily, weekly, or monthly")
    rest_days: int = Field(ge=0, le=7, description="Days of rest per week")
    selected_limitations: list[str] = Field(default=[], description="List of selected limitation IDs")
    additional_notes: str = Field(default="", max_length=2000, description="User's additional preferences")
    want_expert_chat: bool = Field(default=False, description="Whether user wants AI expert chat")


class TrainingDay(BaseModel):
    day: int | str
    focus_area: str
    exercises: list[dict] = Field(
        default=[],
        description="List of exercises with sets, reps, rest time",
    )
    is_rest_day: bool = False
    notes: str = ""


class TrainingPlan(BaseModel):
    id: str
    training_type: TrainingFrequency
    rest_days: int
    total_days: int
    focus_areas: list[str]
    days: list[TrainingDay]
    personalized_notes: str
    estimated_duration_weeks: int
    difficulty_level: str
    ai_generated: bool
    created_at: datetime
    valid_until: datetime | None = None


class TrainingPlanResponse(BaseModel):
    ok: bool = True
    data: TrainingPlan


class TrainingPlanListResponse(BaseModel):
    ok: bool = True
    data: list[TrainingPlan]
