# ui/utils.py
from collections.abc import Callable

import anyio


class Debouncer:
    """Zapobiega spamowaniu API (np. przy pasku wyszukiwania)."""

    def __init__(self, wait_ms: int = 500):
        self.wait_ms = wait_ms / 1000.0
        self._task: anyio.abc.TaskGroup | None = None

    def __call__(self, coroutine_func: Callable):
        """Wywołuje funkcję asynchroniczną dopiero po upływie zadanego czasu."""

        async def debounce_wrapper(*args, **kwargs):
            async def delayed_call():
                await anyio.sleep(self.wait_ms)
                await coroutine_func(*args, **kwargs)

            async with anyio.create_task_group() as tg:
                tg.start_soon(delayed_call)
                # Anulowanie nastąpi automatycznie gdy task group wyjdzie z scope

        return debounce_wrapper
