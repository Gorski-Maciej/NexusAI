# core/adaptive_batcher.py
from typing import Any

import anyio

from nexus_ai.core.logger import logger


class AdaptiveBatcher:
    """Grupowanie zadań AI dla optymalnego wykorzystania przepustowości GPU."""

    def __init__(self, process_func, batch_size: int = 8, timeout: float = 0.2):
        self.process_func = process_func
        self.batch_size = batch_size
        self.timeout = timeout
        self._send, self._receive = anyio.create_memory_object_stream[tuple[Any, anyio.Event]]()
        self._worker_task = None

    async def start(self) -> None:
        self._worker_task = anyio.ensure_backend().create_task(self._batch_worker())

    async def add_task(self, item: Any) -> Any:
        """Dodaje zadanie do kolejki i czeka na jego przetworzenie."""
        event = anyio.Event()
        result_container: list[Any] = []

        async def _resolve() -> Any:
            await event.wait()
            if isinstance(result_container[0], Exception):
                raise result_container[0]
            return result_container[0]

        await self._send.send((item, event, result_container))
        return await _resolve()

    async def _batch_worker(self):
        """Wątek roboczy grupujący zadania."""
        async with self._receive:
            async for item, event, result_container in self._receive:
                batch = [(item, event, result_container)]
                futures_batch = [(event, result_container)]

                # Zbieranie kolejnych do osiągnięcia batch_size lub timeoutu
                deadline = anyio.current_time() + self.timeout
                while len(batch) < self.batch_size:
                    time_left = deadline - anyio.current_time()
                    if time_left <= 0:
                        break
                    try:
                        with anyio.fail_after(time_left):
                            item, event, result_container = await self._receive.receive()
                            batch.append((item, event, result_container))
                            futures_batch.append((event, result_container))
                    except TimeoutError:
                        break

                if batch:
                    logger.debug(f"Wysyłanie batcha {len(batch)} elementów do GPU...")
                    results = await self.process_func([it for it, _, _ in batch])

                    for (_, ev, rc), res in zip(futures_batch, results):
                        rc.append(res)
                        ev.set()
