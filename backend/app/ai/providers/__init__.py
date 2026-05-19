from app.ai.providers.openai import OpenAIProvider
from app.ai.providers.anthropic import AnthropicProvider
from app.ai.providers.gemini import GeminiProvider
from app.ai.providers.deepseek import DeepSeekProvider
from app.ai.providers.minimax import MiniMaxProvider


REGISTRY: dict[str, type] = {
    "openai": OpenAIProvider,
    "anthropic": AnthropicProvider,
    "gemini": GeminiProvider,
    "deepseek": DeepSeekProvider,
    "minimax": MiniMaxProvider,
}


def get_provider(name: str) -> OpenAIProvider | AnthropicProvider | GeminiProvider | DeepSeekProvider | MiniMaxProvider | None:
    cls = REGISTRY.get(name.lower())
    if cls is None:
        return None
    return cls()