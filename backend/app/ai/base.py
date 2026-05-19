from abc import ABC, abstractmethod
from typing import Any


class AIProvider(ABC):
    @abstractmethod
    async def chat(
        self,
        messages: list[dict[str, str]],
        model: str,
        api_key: str,
        max_tokens: int | None = None,
        temperature: float = 0.7,
    ) -> dict[str, Any]:
        pass

    @abstractmethod
    def provider_name(self) -> str:
        pass

    @abstractmethod
    def supports_stream(self) -> bool:
        return False