from app.ai.providers import get_provider, REGISTRY
from app.ai.rate_limiter import RateLimitStore, check_rate_limit, RateLimitConfig


class TestAIProviders:
    def test_registry_has_all_providers(self):
        assert "openai" in REGISTRY
        assert "anthropic" in REGISTRY
        assert "gemini" in REGISTRY

    def test_get_provider_openai(self):
        p = get_provider("openai")
        assert p is not None
        assert p.provider_name() == "openai"
        assert p.supports_stream() is True

    def test_get_provider_anthropic(self):
        p = get_provider("anthropic")
        assert p is not None
        assert p.provider_name() == "anthropic"
        assert p.supports_stream() is True

    def test_get_provider_gemini(self):
        p = get_provider("gemini")
        assert p is not None
        assert p.provider_name() == "gemini"
        assert p.supports_stream() is False

    def test_get_unknown_provider_returns_none(self):
        assert get_provider("unknown") is None
        assert get_provider("") is None


class TestRateLimiter:
    def test_rate_limit_store_singleton(self):
        store1 = RateLimitStore()
        store2 = RateLimitStore()
        assert store1 is store2

    def test_first_request_allowed(self):
        store = RateLimitStore()
        ok, retry = store.check_rate_limit("user-test-1", 10, 60)
        assert ok is True
        assert retry == 0

    def test_repeated_requests_up_to_limit(self):
        store = RateLimitStore()
        for i in range(9):
            ok, _ = store.check_rate_limit(f"user-burst-{i}", 10, 60)
            assert ok is True

    def test_rate_limit_config_platform_managed(self):
        calls, tokens = RateLimitConfig.get_limit("platform_managed")
        assert calls == 10
        assert tokens == 100000

    def test_rate_limit_config_user_byok_no_limits(self):
        calls, tokens = RateLimitConfig.get_limit("user_byok")
        assert calls == 0
        assert tokens == 0

    def test_check_rate_limit_function(self):
        ok, retry = check_rate_limit("user-123", "user_byok")
        assert ok is True
        assert retry == 0

    def test_token_quota_first_check_allowed(self):
        store = RateLimitStore()
        ok, remaining = store.check_token_quota("user-456", 100000)
        assert ok is True

    def test_token_consume(self):
        store = RateLimitStore()
        store.consume_tokens("user-789", 500)
        ok, _ = store.check_token_quota("user-789", 100000)
        assert ok is True