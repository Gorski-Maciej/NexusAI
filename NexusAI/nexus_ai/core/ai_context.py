# core/ai_context.py
from nexus_ai.core.logger import logger


class AIContextManager:
    """Zarządza oknem kontekstowym dla lokalnych modeli LLM."""

    def __init__(self, max_tokens: int = 4096):
        self.max_tokens = max_tokens
        # Heurystyka: 1 token to średnio 4 znaki w j. polskim
        self.chars_per_token = 4

    def truncate_for_llm(self, text: str, reserve_tokens: int = 500) -> str:
        """Przycina tekst OCR, aby zmieścił się w oknie modelu wraz z promptem."""
        max_chars = (self.max_tokens - reserve_tokens) * self.chars_per_token

        if len(text) > max_chars:
            logger.warning(
                f"Tekst dokumentu zbyt długi ({len(text)} znaków). Przycinanie do {max_chars}."
            )
            # Przycinamy do ostatniej kropki, aby nie rwać zdań
            truncated = text[:max_chars]
            last_dot = truncated.rfind(".")
            return truncated[: last_dot + 1] if last_dot > 0 else truncated

        return text
