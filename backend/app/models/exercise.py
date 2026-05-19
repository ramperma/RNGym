from pydantic import BaseModel


class Exercise(BaseModel):
    id: str
    name: str
    muscle_group: str
    difficulty: str
    equipment: str
    description: str
    instructions: str
    default_sets: int
    default_reps: str


class ExerciseListResponse(BaseModel):
    ok: bool = True
    data: list[Exercise]


class ExerciseDetailResponse(BaseModel):
    ok: bool = True
    data: Exercise
