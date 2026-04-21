# ui/utils.py
import asyncio
from typing import Callable

class Debouncer:
    """Zapobiega spamowaniu API (np. przy pasku wyszukiwania)."""

    def __init__(self, wait_ms: int = 500):
        self.wait_ms = wait_ms / 1000.0
        self._task: asyncio.Task | None = None

    def __call__(self, coroutine_func: Callable):
        """Wywołuje funkcję asynchroniczną dopiero po upływie zadanego czasu."""
        async def debounce_wrapper(*args, **kwargs):
            if self._task is not None:
                self._task.cancel()

            async def delayed_call():
                await asyncio.sleep(self.wait_ms)
                await coroutine_func(*args, **kwargs)

            self._task = asyncio.create_task(delayed_call())

            try:
                await self._task
            except asyncio.CancelledError:
                pass # Anulowano przez kolejne uderzenie klawisza

        return debounce_wrapper
