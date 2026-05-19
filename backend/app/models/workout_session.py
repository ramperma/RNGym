from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class WorkoutSession(BaseModel):
    id: str
    exercise_id: str
    exercise_name: str
    performed_at: datetime
    sets_completed: int
    reps_completed: str
    notes: str
    created_at: datetime


class WorkoutSessionCreate(BaseModel):
    exercise_id: str = Field(min_length=1)
    performed_at: datetime
    sets_completed: int = Field(ge=1, le=20)
    reps_completed: str = Field(min_length=1, max_length=50)
    notes: str = Field(default="", max_length=500)


class WorkoutSessionPayload(BaseModel):
    ok: bool = True
    data: WorkoutSession


class WorkoutSessionListPayload(BaseModel):
    ok: bool = True
    data: list[WorkoutSession]

