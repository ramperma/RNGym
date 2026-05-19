import httpx
from typing import Any

from app.ai.base import AIProvider


class DeepSeekProvider(AIProvider):
    BASE_URL = "https://api.deepseek.com/v1"

    def provider_name(self) -> str:
        return "deepseek"

    def supports_stream(self) -> bool:
        return True

    async def chat(
        self,
        messages: list[dict[str, str]],
        model: str,
        api_key: str,
        max_tokens: int | None = None,
        temperature: float = 0.7,
    ) -> dict[str, Any]:
        # Deepseek chat endpoints are at BASE_URL + /chat/completions
        body: dict[str, Any] = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
        }
        if max_tokens:
            body["max_tokens"] = max_tokens

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.BASE_URL}/chat/completions",
                json=body,
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
            )
            response.raise_for_status()
            return response.json()
