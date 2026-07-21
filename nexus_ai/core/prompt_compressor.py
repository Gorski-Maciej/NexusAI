"""Adaptive Prompt Compression — Kompresja promptów dla znanych kontrahentów.

GENIALNY POMYSŁ #14 z Raportu v7.0:
Dla faktur od znanych kontrahentów, prompt jest KOMPRESOWANY:
- Pełny prompt: 2500 tokenów (nowy kontrahent, złożona faktura)
- Skompresowany: 500 tokenów (znany kontrahent, prosta faktura)
Redukcja kosztu inferencji o 60% i czasu o 50%.
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.core.prompt_compressor")


class PromptCompressor:
    """Kompresor promptów — usuwa zbędne przykłady few-shot i redukuje kontekst.

    GENIALNY POMYSŁ #14:
    Kompresja przez usuwanie przykładów few-shot które nie pasują
    do kontekstu (k-NN similarity < 0.3).
    """

    # ── Konfiguracja ────────────────────────────────────────────────
    FULL_PROMPT_MAX_TOKENS = 2500
    COMPRESSED_PROMPT_MAX_TOKENS = 500
    MIN_SIMILARITY_FOR_INCLUSION = 0.3
    MAX_EXAMPLES_FULL = 5
    MAX_EXAMPLES_COMPRESSED = 1

    def __init__(self, max_tokens: int = 500) -> None:
        self._max_tokens = max_tokens
        self._compression_stats: dict[str, int] = {
            "full_prompts": 0,
            "compressed_prompts": 0,
            "tokens_saved": 0,
        }

    # ── Core Logic ──────────────────────────────────────────────────

    def compress(
        self,
        prompt: str,
        vendor_known: bool = False,
        invoice_complexity: str = "medium",
        few_shot_examples: list[dict[str, Any]] | None = None,
        similarity_scores: list[float] | None = None,
    ) -> str:
        """Skompresuj prompt na podstawie kontekstu.

        Args:
            prompt: Pełny prompt (może być rozszerzony o few-shot).
            vendor_known: Czy kontrahent jest znany.
            invoice_complexity: "simple", "medium", "complex".
            few_shot_examples: Lista przykładów few-shot.
            similarity_scores: Wyniki podobieństwa k-NN dla przykładów.

        Returns:
            Skompresowany prompt.
        """
        # Proste faktury od znanych kontrahentów → maksymalna kompresja
        if vendor_known and invoice_complexity == "simple":
            return self._aggressive_compress(
                prompt, few_shot_examples, similarity_scores
            )

        # Średnie → umiarkowana kompresja
        if vendor_known and invoice_complexity == "medium":
            return self._moderate_compress(
                prompt, few_shot_examples, similarity_scores
            )

        # Złożone / nowi kontrahenci → pełny prompt
        self._compression_stats["full_prompts"] += 1
        return prompt

    def _aggressive_compress(
        self,
        prompt: str,
        few_shot_examples: list[dict[str, Any]] | None = None,
        similarity_scores: list[float] | None = None,
    ) -> str:
        """Agresywna kompresja — tylko essential data + 1 przykład."""
        self._compression_stats["compressed_prompts"] += 1

        # Zachowaj tylko dane faktury (usuń rozbudowane instrukcje)
        lines = prompt.split("\n")
        essential_lines: list[str] = []
        in_data_section = False

        for line in lines:
            stripped = line.strip()
            # Zachowaj dane faktury
            if any(keyword in stripped.lower() for keyword in [
                "numer:", "nip:", "kwota:", "data:", "dane faktury"
            ]):
                in_data_section = True
                essential_lines.append(line)
                continue
            if in_data_section and stripped.startswith("-"):
                essential_lines.append(line)
                continue
            if in_data_section and not stripped:
                in_data_section = False

            # Zachowaj tylko kluczowe instrukcje
            if any(keyword in stripped.lower() for keyword in [
                "oceń", "zdecyduj", "format:", "trust:", "status:"
            ]):
                essential_lines.append(line)

        # Dodaj maksymalnie 1 najbardziej podobny przykład few-shot
        if few_shot_examples and similarity_scores:
            best_idx = similarity_scores.index(max(similarity_scores))
            if similarity_scores[best_idx] >= self.MIN_SIMILARITY_FOR_INCLUSION:
                example = few_shot_examples[best_idx]
                essential_lines.append("")
                essential_lines.append(f"UWAGA: Podobna przeszła korekta: {example.get('user_correction', '')}")

        result = "\n".join(essential_lines)
        tokens_saved = self._estimate_tokens(prompt) - self._estimate_tokens(result)
        self._compression_stats["tokens_saved"] += max(0, tokens_saved)

        logger.debug("[COMPRESS] Aggressive: %d → %d tokens (saved %d)",
                     self._estimate_tokens(prompt), self._estimate_tokens(result), max(0, tokens_saved))
        return result

    def _moderate_compress(
        self,
        prompt: str,
        few_shot_examples: list[dict[str, Any]] | None = None,
        similarity_scores: list[float] | None = None,
    ) -> str:
        """Umiarkowana kompresja — zachowaj dane + max 3 przykłady."""
        self._compression_stats["compressed_prompts"] += 1

        lines = prompt.split("\n")
        essential_lines: list[str] = []
        skip_next = False

        for line in lines:
            stripped = line.strip()
            # Pomiń puste instrukcje i rozwlekłe opisy
            if skip_next:
                skip_next = False
                continue
            if "szczegółowy" in stripped.lower() and len(stripped) > 100:
                skip_next = True
                continue
            essential_lines.append(line)

        # Dodaj max 3 podobne przykłady
        if few_shot_examples and similarity_scores:
            scored = sorted(
                zip(few_shot_examples, similarity_scores),
                key=lambda x: x[1], reverse=True
            )
            included = 0
            for example, score in scored[: self.MAX_EXAMPLES_COMPRESSED + 2]:
                if score >= self.MIN_SIMILARITY_FOR_INCLUSION and included < 3:
                    essential_lines.append(
                        f"Przykład: {example.get('user_correction', '')}"
                    )
                    included += 1

        result = "\n".join(essential_lines)
        tokens_saved = self._estimate_tokens(prompt) - self._estimate_tokens(result)
        self._compression_stats["tokens_saved"] += max(0, tokens_saved)

        logger.debug("[COMPRESS] Moderate: %d → %d tokens",
                     self._estimate_tokens(prompt), self._estimate_tokens(result))
        return result

    # ── Helpers ──────────────────────────────────────────────────────

    @staticmethod
    def _estimate_tokens(text: str) -> int:
        """Proste oszacowanie liczby tokenów (≈ 4 znaki na token)."""
        return len(text) // 4

    def should_compress(
        self, vendor_known: bool, amount: float, positions: int = 1
    ) -> bool:
        """Określ czy prompt powinien być skompresowany."""
        if not vendor_known:
            return False
        if amount > 50_000:
            return False  # Wysokie kwoty → pełny prompt
        if positions > 10:
            return False  # Złożone faktury → pełny prompt
        return True

    def get_compression_ratio(self) -> float:
        """Stosunek skompresowanych do pełnych promptów."""
        total = self._compression_stats["full_prompts"] + self._compression_stats["compressed_prompts"]
        if total == 0:
            return 0.0
        return self._compression_stats["compressed_prompts"] / total

    def get_stats(self) -> dict[str, Any]:
        return {
            **self._compression_stats,
            "compression_ratio_pct": round(self.get_compression_ratio() * 100, 1),
            "avg_tokens_saved": self._compression_stats["tokens_saved"] // max(
                self._compression_stats["compressed_prompts"], 1
            ),
        }
