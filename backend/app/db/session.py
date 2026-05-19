from collections.abc import Generator
from contextlib import contextmanager

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.core.config import settings

engine = create_engine(settings.database_url, future=True, pool_pre_ping=True)


def get_db_connection() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session


@contextmanager
def db_connection_context() -> Generator[Session, None, None]:
    with Session(engine) as session:
        yield session
