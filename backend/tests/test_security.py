import time
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)


class TestPasswordHashing:
    def test_hash_password_produces_different_values(self):
        h1 = hash_password("Test1234")
        h2 = hash_password("Test1234")
        assert h1 != h2

    def test_verify_correct_password(self):
        h = hash_password("Test1234")
        assert verify_password("Test1234", h) is True

    def test_verify_wrong_password(self):
        h = hash_password("Test1234")
        assert verify_password("Wrong1234", h) is False


class TestJWT:
    def test_access_token_contains_payload(self):
        token = create_access_token({"sub": "user-123", "rol": "admin"})
        payload = decode_token(token)
        assert payload["sub"] == "user-123"
        assert payload["rol"] == "admin"
        assert payload["type"] == "access"

    def test_access_token_expires(self):
        token = create_access_token({"sub": "user-123"})
        payload = decode_token(token)
        assert payload["exp"] > int(time.time())

    def test_refresh_token_type_is_refresh(self):
        token = create_refresh_token({"sub": "user-123"})
        payload = decode_token(token)
        assert payload["type"] == "refresh"
        assert payload["sub"] == "user-123"

    def test_invalid_token_returns_none(self):
        result = decode_token("not.a.valid.token")
        assert result is None

    def test_tampered_token_returns_none(self):
        token = create_access_token({"sub": "user-123"})
        tampered = token[:-5] + "XXXXX"
        result = decode_token(tampered)
        assert result is None


class TestSecurityIntegration:
    def test_login_flow_hash_and_verify(self):
        password = "SecurePass99"
        hashed = hash_password(password)
        assert verify_password(password, hashed)
        assert not verify_password("wrongpass", hashed)