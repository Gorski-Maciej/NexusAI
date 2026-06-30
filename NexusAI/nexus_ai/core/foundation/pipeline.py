"""Pipeline pattern — sekwencyjne przetwarzanie danych przez Step'y.

Eliminuje powtarzalne sekwencje wywołań funkcji.
Zastępuje: osobną orkiestrację w OCR, walidacji, decyzjach.

Usage:
    class ValidateStep(Step):
        async def process(self, ctx: PipelineContext) -> None:
            ctx.data["valid"] = True

    pipeline = Pipeline([ValidateStep(), EnrichStep(), SaveStep()])
    result = await pipeline.run({"invoice_id": "123"})
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Generic, TypeVar

T = TypeVar("T")


class PipelineContext(Generic[T]):
    """Kontekst pipeline'u — przenosi dane między krokami.

    Attributes:
        data: Główne dane przetwarzane w pipeline.
        metadata: Słownik na metadane (błędy, logi, checkpointy).
        errors: Lista błędów zebranych podczas przetwarzania.
    """

    __slots__ = ("data", "metadata", "errors")

    def __init__(self, data: T, metadata: dict[str, Any] | None = None) -> None:
        self.data = data
        self.metadata = metadata or {}
        self.errors: list[Exception] = []

    def add_error(self, error: Exception) -> None:
        """Dodaj błąd do kontekstu."""
        self.errors.append(error)


class Step(ABC, Generic[T]):
    """Pojedynczy krok w pipeline przetwarzania.

    Każdy krok implementuje metodę process() która otrzymuje
    kontekst pipeline'u i może go modyfikować.
    """

    __slots__ = ("name",)

    def __init__(self, name: str | None = None) -> None:
        self.name = name or self.__class__.__name__

    @abstractmethod
    async def process(self, ctx: PipelineContext[T]) -> None:
        """Przetwórz dane w kontekście.

        Args:
            ctx: Kontekst pipeline'u z danymi do przetworzenia.
        """

    async def __call__(self, ctx: PipelineContext[T]) -> PipelineContext[T]:
        try:
            await self.process(ctx)
        except Exception as e:
            ctx.add_error(e)
        return ctx


class Pipeline(Generic[T]):
    """Sekwencyjny pipeline kroków przetwarzania.

    Wykonuje kroki po kolei, przekazując kontekst między nimi.
    Jeśli step_on_error=False (domyślnie), kontynuuje mimo błędów.
    Jeśli raise_on_error=True, przerywa przy pierwszym błędzie.

    Usage:
        pipeline = Pipeline([
            OcrStep(),
            ValidateStep(),
            SaveStep(),
        ], raise_on_error=False)

        ctx = await pipeline.run({"invoice_id": "inv-123"})
        if ctx.errors:
            logger.error("Pipeline failed", errors=ctx.errors)
    """

    __slots__ = ("steps", "raise_on_error")

    def __init__(self, steps: list[Step[T]], *, raise_on_error: bool = False) -> None:
        self.steps = steps
        self.raise_on_error = raise_on_error

    async def run(self, data: T, metadata: dict[str, Any] | None = None) -> PipelineContext[T]:
        """Uruchom pipeline z danymi wejściowymi.

        Args:
            data: Dane wejściowe do przetworzenia.
            metadata: Opcjonalne metadane (np. tenant_id, user_id).

        Returns:
            PipelineContext z przetworzonymi danymi i ewentualnymi błędami.
        """
        ctx = PipelineContext(data, metadata)
        for step in self.steps:
            await step(ctx)
            if self.raise_on_error and ctx.errors:
                break
        return ctx

    @property
    def step_count(self) -> int:
        """Liczba kroków w pipeline."""
        return len(self.steps)

    @property
    def step_names(self) -> list[str]:
        """Nazwy kroków."""
        return [s.name for s in self.steps]
