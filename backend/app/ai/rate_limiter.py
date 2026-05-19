from collections import defaultdict
from datetime import datetime, timedelta
from threading import Lock


class RateLimitStore:
    _instance = None
    _lock = Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    cls._instance._calls = defaultdict(list)
                    cls._instance._tokens = defaultdict(lambda: {"count": 0, "window": None})
        return cls._instance

    def check_rate_limit(self, user_id: str, limit: int, window_seconds: int) -> tuple[bool, int]:
        now = datetime.utcnow()
        key = f"rate:{user_id}"
        self._calls[key] = [t for t in self._calls[key] if (now - t).total_seconds() < window_seconds]
        if len(self._calls[key]) >= limit:
            retry_after = int(window_seconds - (now - self._calls[key][0]).total_seconds())
            return False, max(retry_after, 1)
        self._calls[key].append(now)
        return True, 0

    def check_token_quota(self, user_id: str, daily_limit: int) -> tuple[bool, int]:
        now = datetime.utcnow()
        today = now.date()
        key = f"tokens:{user_id}:{today}"
        entry = self._tokens[key]
        if entry["window"] != today:
            entry["count"] = 0
            entry["window"] = today
        if entry["count"] >= daily_limit:
            return False, 0
        return True, 0

    def consume_tokens(self, user_id: str, count: int) -> None:
        now = datetime.utcnow()
        today = now.date()
        key = f"tokens:{user_id}:{today}"
        entry = self._tokens[key]
        if entry["window"] != today:
            entry["count"] = 0
            entry["window"] = today
        entry["count"] += count


class RateLimitConfig:
    PLATFORM_MANAGED_CALLS_PER_MIN = 10
    PLATFORM_MANAGED_TOKENS_PER_DAY = 100000

    @classmethod
    def get_limit(cls, mode: str) -> tuple[int, int]:
        if mode == "platform_managed":
            return cls.PLATFORM_MANAGED_CALLS_PER_MIN, cls.PLATFORM_MANAGED_TOKENS_PER_DAY
        return 0, 0


_rate_store = RateLimitStore()


def check_rate_limit(user_id: str, mode: str) -> tuple[bool, int]:
    if mode != "platform_managed":
        return True, 0
    calls_limit, _ = RateLimitConfig.get_limit(mode)
    return _rate_store.check_rate_limit(user_id, calls_limit, 60)


def check_token_quota(user_id: str, mode: str) -> tuple[bool, int]:
    if mode != "platform_managed":
        return True, 0
    _, tokens_limit = RateLimitConfig.get_limit(mode)
    return _rate_store.check_token_quota(user_id, tokens_limit)


def consume_tokens(user_id: str, count: int) -> None:
    _rate_store.consume_tokens(user_id, count)