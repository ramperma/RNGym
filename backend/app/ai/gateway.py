import time
import httpx
from typing import Any, Callable

from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception


def _is_transient(error: Exception) -> bool:
    if isinstance(error, httpx.HTTPStatusError):
        status = error.response.status_code
        return status in (429, 500, 502, 503, 504)
    if isinstance(error, httpx.TimeoutException):
        return True
    if isinstance(error, httpx.NetworkError):
        return True
    return False


async def call_with_retry(coro: Callable, *args, **kwargs) -> Any:
    attempt = 0
    max_attempts = 3
    while attempt < max_attempts:
        try:
            return await coro(*args, **kwargs)
        except Exception as e:
            attempt += 1
            if attempt >= max_attempts or not _is_transient(e):
                raise
            wait = min(2 ** attempt, 10)
            time.sleep(wait)
    raise RuntimeError("unreachable")