import httpx
from typing import Any

from app.ai.base import AIProvider


class AnthropicProvider(AIProvider):
    BASE_URL = "https://api.anthropic.com/v1"

    def provider_name(self) -> str:
        return "anthropic"

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
        system_msg = ""
        filtered_messages = []
        for m in messages:
            if m.get("role") == "system":
                system_msg = m.get("content", "")
            else:
                filtered_messages.append(m)

        body: dict[str, Any] = {
            "model": model,
            "messages": filtered_messages,
            "temperature": temperature,
        }
        if system_msg:
            body["system"] = system_msg
        if max_tokens:
            body["max_tokens"] = max_tokens

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.BASE_URL}/messages",
                json=body,
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                    "anthropic-version": "2023-06-01",
                    "anthropic-dangerous-direct-browser-access": "true",
                },
            )
            response.raise_for_status()
            return response.json()