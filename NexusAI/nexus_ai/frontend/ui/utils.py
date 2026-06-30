# ui/utils.py
from __future__ import annotations

from collections.abc import Callable, Coroutine
from typing import Any

import anyio


class Debouncer:
    """Zapobiega spamowaniu API (np. przy pasku wyszukiwania).

    """

    def __init__(self, wait_ms: int = 500):
        self.wait_ms = wait_ms / 1000.0
        self._cancel_event: anyio.Event | None = None

    def __call__(self, coroutine_func: Callable[..., Coroutine[Any, Any, Any]]):
        """Wywołuje funkcję asynchroniczną dopiero po upływie zadanego czasu.

        Poprzednie oczekujące wywołanie jest automatycznie anulowane.
        """

        async def debounce_wrapper(*args: Any, **kwargs: Any) -> None:
            # Anuluj poprzednie oczekujące wywołanie
            if self._cancel_event is not None:
                self._cancel_event.set()

            cancel_event = anyio.Event()
            self._cancel_event = cancel_event

            try:
                # Czekaj, ale przerwij jeśli pojawi się nowe wywołanie
                with anyio.CancelScope() as scope:
                    # Podłącz anulowanie do eventu
                    async def _wait_for_cancel():
                        await cancel_event.wait()
                        scope.cancel()

                    # Uruchom równolegle czekanie na anulowanie i timeout
                    async with anyio.create_task_group() as tg:
                        tg.start_soon(_wait_for_cancel)
                        await anyio.sleep(self.wait_ms)

                    # Jeśli doszliśmy tutaj, timeout minął bez anulowania
                    await coroutine_func(*args, **kwargs)
            except anyio.get_cancelled_exc_class():
                pass  # Anulowane przez nowsze wywołanie

        return debounce_wrapper
