import httpx
from typing import Any

from app.ai.base import AIProvider


class GeminiProvider(AIProvider):
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta"

    def provider_name(self) -> str:
        return "gemini"

    def supports_stream(self) -> bool:
        return False

    async def chat(
        self,
        messages: list[dict[str, str]],
        model: str,
        api_key: str,
        max_tokens: int | None = None,
        temperature: float = 0.7,
    ) -> dict[str, Any]:
        contents = []
        system_instruction = None
        for m in messages:
            if m.get("role") == "system":
                system_instruction = {"parts": [{"text": m.get("content", "")}]}
                continue
            content = m.get("content", "")
            if isinstance(content, list):
                parts = []
                for part in content:
                    if part.get("type") == "text":
                        parts.append({"text": part["text"]})
                    elif part.get("type") == "image_url":
                        url = part["image_url"]["url"]
                        if url.startswith("data:"):
                            header, b64data = url.split(",", 1)
                            mime_type = header.split(";")[0].split(":")[1]
                            parts.append({"inline_data": {"mime_type": mime_type, "data": b64data}})
            else:
                parts = [{"text": str(content)}]
            contents.append({
                "role": "user" if m.get("role") == "user" else "model",
                "parts": parts,
            })

        body: dict[str, Any] = {
            "contents": contents,
            "generationConfig": {
                "temperature": temperature,
            },
        }
        if system_instruction:
            body["systemInstruction"] = system_instruction
        if max_tokens:
            body["generationConfig"]["maxOutputTokens"] = max_tokens

        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.BASE_URL}/models/{model}:generateContent",
                json=body,
                params={"key": api_key},
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            data = response.json()
            return {
                "candidates": [
                    {
                        "message": {
                            "role": "model",
                            "content": data["candidates"][0]["content"]["parts"][0]["text"]
                            if data.get("candidates")
                            else "",
                        }
                    }
                ],
                "usage": data.get("usage", {}),
            }