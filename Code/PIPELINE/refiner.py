# pipeline/refiner.py
from core.logger import logger
from core.llm_guard import LLMGuard

class PipelineRefiner:
    """Mechanizm 'Self-Correction' – prosi AI o poprawkę w przypadku błędów."""

    def __init__(self, llm_engine):
        self.llm = llm_engine

    async def refine_extraction(self, raw_text: str, previous_error: str, last_attempt: dict) -> dict:
        """Wysyła błąd walidacji z powrotem do AI, aby model spróbował naprawić dane."""
        logger.warning(f"Uruchamianie autokorekty AI dla błędu: {previous_error}")

        refine_prompt = (
            f"Poprzednia ekstrakcja danych: {last_attempt}\n"
            f"Wystąpił błąd: {previous_error}\n"
            f"Przeanalizuj tekst ponownie i popraw błąd. Zwróć tylko JSON.\n"
            f"Tekst źródłowy: {raw_text[:2000]}"
        )

        new_raw_output = await self.llm.generate(refine_prompt)
        return LLMGuard.parse_and_validate(new_raw_output)
