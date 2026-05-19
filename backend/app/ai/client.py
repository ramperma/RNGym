import time
import httpx
from datetime import datetime
from typing import Any

from app.ai.base import AIProvider
from app.ai.providers import get_provider
from app.ai.log_repository import log_ia
from app.core.config import settings

DEFAULT_MODEL_BY_PROVIDER = {
    "openai": "gpt-4o",
    "anthropic": "claude-sonnet-4-20250514",
    "gemini": "gemini-2.0-flash",
    "deepseek": "deepseek-chat",
    "minimax": "minimax-text-01",
}


class AIClient:
    def __init__(self):
        self._provider_cache: dict[str, AIProvider] = {}

    def _get_provider(self, provider: str) -> AIProvider | None:
        if provider not in self._provider_cache:
            self._provider_cache[provider] = get_provider(provider)
        return self._provider_cache[provider]

    def _resolve_api_key(self, provider: str, mode: str, user_api_key: str | None = None) -> str:
        if mode == "platform_managed":
            env_key = self._platform_key_for(provider)
            if not env_key:
                raise ValueError(f"No platform API key configured for provider: {provider}")
            return env_key
        else:
            if not user_api_key:
                raise ValueError("BYOK mode requires user API key")
            return user_api_key

    def _platform_key_for(self, provider: str) -> str | None:
        key_map = {
            "openai": getattr(settings, "openai_api_key", None),
            "anthropic": getattr(settings, "anthropic_api_key", None),
            "gemini": getattr(settings, "gemini_api_key", None),
            "deepseek": getattr(settings, "deepseek_api_key", None),
            "minimax": getattr(settings, "minimax_api_key", None),
        }
        return key_map.get(provider)

    def _resolve_model(self, provider: str, model: str | None) -> str:
        if model:
            return model
        return DEFAULT_MODEL_BY_PROVIDER.get(provider, "unknown")

    async def chat(
        self,
        provider: str,
        model: str | None,
        messages: list[dict[str, str]],
        mode: str,
        user_api_key: str | None = None,
        max_tokens: int | None = None,
        temperature: float = 0.7,
        user_id: str | None = None,
        tipo_consulta: str = "chat",
    ) -> dict[str, Any]:
        provider_obj = self._get_provider(provider)
        if not provider_obj:
            raise ValueError(f"Unknown provider: {provider}")

        resolved_model = self._resolve_model(provider, model)
        api_key = self._resolve_api_key(provider, mode, user_api_key)

        start_ms = int(time.time() * 1000)
        error_code = None
        error_message = None
        response_data = None

        try:
            response_data = await self._call_provider(
                provider_obj,
                resolved_model,
                api_key,
                messages,
                max_tokens,
                temperature,
            )
        except Exception as e:
            error_message = str(e)
            if isinstance(e, httpx.HTTPStatusError):
                error_code = f"HTTP_{e.response.status_code}"
            elif isinstance(e, httpx.TimeoutException):
                error_code = "TIMEOUT"
            elif isinstance(e, httpx.NetworkError):
                error_code = "NETWORK_ERROR"
            else:
                error_code = "UNKNOWN_ERROR"

        latency_ms = int(time.time() * 1000) - start_ms

        tokens_in = response_data.get("usage", {}).get("prompt_tokens") if response_data else None
        tokens_out = response_data.get("usage", {}).get("completion_tokens") if response_data else None
        respuesta = self._extract_text_response(response_data, provider) if response_data else None

        try:
            from app.db import get_db_connection, db_connection_context
            with db_connection_context() as conn:
                log_ia(
                    conn,
                    usuario_id=user_id,
                    tipo_consulta=tipo_consulta,
                    prompt=self._messages_to_prompt(messages),
                    respuesta=respuesta,
                    proveedor=provider,
                    modelo=resolved_model,
                    modo_facturacion=mode,
                    tokens_entrada=tokens_in,
                    tokens_salida=tokens_out,
                    latencia_ms=latency_ms,
                    codigo_error=error_code,
                    mensaje_error=error_message,
                )
        except Exception:
            pass

        if error_code:
            raise AIError(code=error_code, message=error_message or "AI call failed")

        return response_data or {}

    async def _call_provider(
        self,
        provider: AIProvider,
        model: str,
        api_key: str,
        messages: list[dict[str, str]],
        max_tokens: int | None,
        temperature: float,
    ) -> dict[str, Any]:
        attempt = 0
        max_attempts = 3
        while attempt < max_attempts:
            try:
                return await provider.chat(
                    messages=messages,
                    model=model,
                    api_key=api_key,
                    max_tokens=max_tokens,
                    temperature=temperature,
                )
            except Exception as e:
                attempt += 1
                if not self._is_transient(e) or attempt >= max_attempts:
                    raise
                wait = min(2 ** attempt, 10)
                time.sleep(wait)

    def _is_transient(self, error: Exception) -> bool:
        if isinstance(error, httpx.HTTPStatusError):
            return error.response.status_code in (429, 500, 502, 503, 504)
        if isinstance(error, httpx.TimeoutException):
            return True
        if isinstance(error, httpx.NetworkError):
            return True
        return False

    def _extract_text_response(self, data: dict[str, Any], provider: str) -> str | None:
        if provider in ("openai", "deepseek", "minimax"):
            choices = data.get("choices", [])
            if choices:
                return choices[0].get("message", {}).get("content")
        elif provider == "anthropic":
            return data.get("content", [{}])[0].get("text")
        elif provider == "gemini":
            candidates = data.get("candidates", [])
            if candidates:
                return candidates[0].get("message", {}).get("content")
        return None

    def _messages_to_prompt(self, messages: list[dict[str, str]]) -> str:
        parts = []
        for m in messages:
            role = m.get("role", "user")
            content = m.get("content", "")
            parts.append(f"{role}: {content}")
        return "\n".join(parts)


class AIError(Exception):
    def __init__(self, code: str, message: str):
        self.code = code
        self.message = message
        super().__init__(f"[{code}] {message}")


ai_client = AIClient()