from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.core.security import decode_token
from app.db import engine
from sqlalchemy import text


class RLSContextMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        user_id = _extract_user_id_from_request(request)
        with engine.connect() as conn:
            if user_id:
                conn.execute(text(f"SET app.current_user_id = '{user_id}'"))
            else:
                conn.execute(text("RESET app.current_user_id"))
            conn.commit()

        response = await call_next(request)
        return response


def _extract_user_id_from_request(request: Request) -> str | None:
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return None
    token = auth[7:]
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        return None
    return payload.get("sub")