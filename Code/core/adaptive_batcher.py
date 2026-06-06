# core/adaptive_batcher.py
import asyncio
from typing import Any

from core.logger import logger


class AdaptiveBatcher:
    """Grupowanie zadań AI dla optymalnego wykorzystania przepustowości GPU."""

    def __init__(self, process_func, batch_size: int = 8, timeout: float = 0.2):
        self.process_func = process_func # Funkcja inferencyjna modelu (np. _infer_batch)
        self.batch_size = batch_size # Maksymalny rozmiar batcha
        self.timeout = timeout # Maksymalny czas oczekiwania (w sekundach)
        self._queue = asyncio.Queue()
        self._worker_task = asyncio.create_task(self._batch_worker())

    async def add_task(self, item: Any) -> Any:
        """Dodaje zadanie do kolejki i czeka na jego przetworzenie."""
        future = asyncio.get_event_loop().create_future()
        await self._queue.put((item, future))
        return await future

    async def _batch_worker(self):
        """Wątek roboczy grupujący zadania."""
        while True:
            batch = []
            futures = []

            try:
                # Oczekiwanie na pierwszy element
                item, future = await self._queue.get()
                batch.append(item)
                futures.append(future)

                # Zbieranie kolejnych do osiągnięcia batch_size lub timeoutu
                end_time = asyncio.get_event_loop().time() + self.timeout
                while len(batch) < self.batch_size:
                    time_left = end_time - asyncio.get_event_loop().time()
                    if time_left <= 0:
                        break
                    try:
                        item, future = await asyncio.wait_for(self._queue.get(), timeout=time_left)
                        batch.append(item)
                        futures.append(future)
                    except TimeoutError:
                        break

                if batch:
                    logger.debug(f"Wysyłanie batcha {len(batch)} elementów do GPU...")
                    results = await self.process_func(batch)

                    # Rozdanie wyników do oczekujących wątków
                    for fut, res in zip(futures, results):
                        if not fut.done():
                            fut.set_result(res)

            except Exception as e:
                logger.error(f"Błąd przetwarzania batcha: {e}")
                for fut in futures:
                    if not fut.done():
                        fut.set_exception(e)
