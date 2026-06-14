"""
ProjectionWorker — standalone process that consumes domain events from NATS JetStream
and updates CQRS read-side projections in real time.

Architecture:
    ┌──────────────┐     ┌──────────────────┐     ┌────────────────────┐
    │   JetStream  │────▶│ ProjectionWorker  │────▶│ InvoiceProjection  │
    │ (pull sub)   │     │ (event dispatcher)│     │ (invoice_read_model)│
    └──────────────┘     │                   │     └────────────────────┘
                         │                   │     ┌────────────────────┐
                         │                   │────▶│ DecisionProjection  │
                         │                   │     │ (decision_analytics)│
                         └──────────────────┘     └────────────────────┘

Każda projekcja ma dedykowanego durable pull consumera na swoim strumieniu
JetStream (nexus-invoice, nexus-decision). Eventy są deserializowane przez
``decode_event()`` i przekazywane do ``projection._handle_event()``.

Po przetworzeniu:
  1. JetStream message jest ack'owana
  2. Checkpoint w EventStore jest aktualizowany (dla spójności przy rebuildzie)

Jeśli NATS jest niedostępny, worker może działać w trybie fallback:
polling EventStore co N sekund (graceful degradation).

Usage:
    # Jako CLI:
    python -m nexus_ai.scripts.projection_worker

    # Programowo:
    from nexus_ai.events import ProjectionWorker, InvoiceProjection, DecisionProjection

    worker = ProjectionWorker(nats_servers="nats://localhost:4222")
    worker.add_projection(InvoiceProjection(event_store))
    worker.add_projection(DecisionProjection(event_store))
    await worker.start()
    # ... wait ...
    await worker.stop()
"""

from __future__ import annotations

import signal
import sys
from pathlib import Path
from typing import Any, Callable

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.events.domain_events import DomainEvent, decode_event
from nexus_ai.events.projections import DecisionProjection, InvoiceProjection, Projection
from nexus_ai.events.event_store import EventStore
from nexus_ai.events.jetstream_bus import STREAM_CONFIG, get_event_bus

logger = get_logger("nexus.events.projection_worker")


# ── Projection Worker ─────────────────────────────────────────────────────


class ProjectionWorker:
    """Konsumuje eventy z JetStream i aktualizuje projekcje CQRS.

    Args:
        event_store: Instancja EventStore (dla checkpointów).
        nats_servers: Serwery NATS do połączenia.
        poll_interval_seconds: Interwał pollowania dla pull consumera.
        batch_size: Maksymalna liczba wiadomości w jednym fetchu.
        enable_fallback_poll: Jeśli True, uruchamia fallback polling EventStore
                              gdy JetStream jest niedostępny.
        fallback_poll_seconds: Interwał fallback pollowania EventStore.
    """

    def __init__(
        self,
        event_store: EventStore | None = None,
        nats_servers: list[str] | str | None = None,
        poll_interval_seconds: float = 1.0,
        batch_size: int = 10,
        enable_fallback_poll: bool = True,
        fallback_poll_seconds: float = 30.0,
    ) -> None:
        self._event_store = event_store
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._poll_interval = poll_interval_seconds
        self._batch_size = batch_size
        self._enable_fallback = enable_fallback_poll
        self._fallback_poll_seconds = fallback_poll_seconds

        # Rejestr projekcji: {(projection, stream_name, filter_subject), ...}
        self._projections: list[tuple[Projection, str, str]] = []

        # NATS connection
        self._nc: Any = None
        self._js: Any = None
        self._connected = False

        # Async task management
        self._consumer_tasks: list[Any] = []
        self._fallback_task: Any | None = None
        self._shutdown_event = anyio.Event()

    # ── Projection registration ──────────────────────────────────────────

    def add_projection(
        self,
        projection: Projection,
        stream_name: str | None = None,
        filter_subject: str = "",
    ) -> None:
        """Dodaj projekcję do workera.

        Args:
            projection: Instancja projekcji (InvoiceProjection, DecisionProjection itp.).
            stream_name: Nazwa strumienia JetStream. Jeśli None, wywnioskuje z typu.
            filter_subject: Opcjonalny filtr subject (np. "nexus-invoice.invoice.created").
                            Pusty = wszystkie eventy ze strumienia.
        """
        if stream_name is None:
            stream_name = self._infer_stream(projection)

        self._projections.append((projection, stream_name, filter_subject))
        logger.info(
            "[PROJECTION-WORKER] Registered projection %s → stream=%s filter=%s",
            projection.name,
            stream_name,
            filter_subject or "*",
        )

    @staticmethod
    def _infer_stream(projection: Projection) -> str:
        """Wywnioskuj nazwę strumienia JetStream z typu projekcji."""
        if isinstance(projection, InvoiceProjection):
            return "nexus-invoice"
        if isinstance(projection, DecisionProjection):
            return "nexus-decision"
        # Domyślnie: użyj nazwy projekcji jako nazwy strumienia
        return f"nexus-{projection.name}"

    # ── Lifecycle ────────────────────────────────────────────────────────

    async def start(self) -> None:
        """Uruchom workera: połącz z NATS i rozpocznij konsumpcję."""
        logger.info(
            "[PROJECTION-WORKER] Starting with %d projections",
            len(self._projections),
        )

        # Próba połączenia z NATS JetStream
        try:
            await self._connect_nats()
        except Exception as exc:
            logger.warning(
                "[PROJECTION-WORKER] NATS connection failed: %s",
                exc,
            )

        # Uruchom konsumentów JetStream dla każdej projekcji
        if self._connected:
            for projection, stream_name, filter_subject in self._projections:
                task = anyio.create_task(
                    self._consume_stream(projection, stream_name, filter_subject),
                    name=f"jetstream-{projection.name}",
                )
                self._consumer_tasks.append(task)
                logger.info(
                    "[PROJECTION-WORKER] Consumer started: %s/%s",
                    stream_name,
                    projection.name,
                )

        # Fallback polling (gdy NATS niedostępny lub jako uzupełnienie)
        if self._enable_fallback:
            self._fallback_task = anyio.create_task(
                self._fallback_poll_loop(),
                name="fallback-poll",
            )
            logger.info("[PROJECTION-WORKER] Fallback poll task started")

        # Czekaj na sygnał shutdown
        try:
            await self._shutdown_event.wait()
        except anyio.CancelledError:
            pass

    async def stop(self) -> None:
        """Zatrzymaj workera: zamknij konsumentów i połączenie."""
        logger.info("[PROJECTION-WORKER] Stopping...")

        # Anuluj zadania konsumentów
        for task in self._consumer_tasks:
            task.cancel()
        if self._consumer_tasks:
            await anyio.gather(*self._consumer_tasks, return_exceptions=True)
        self._consumer_tasks.clear()

        # Anuluj fallback polling
        if self._fallback_task is not None:
            self._fallback_task.cancel()
            try:
                await self._fallback_task
            except (anyio.CancelledError, Exception):
                pass
            self._fallback_task = None

        # Zamknij połączenie NATS
        if self._nc is not None:
            try:
                await self._nc.drain()
            except Exception:
                pass
            self._nc = None
            self._js = None
            self._connected = False

        # Zamknij projekcje (zwolnij zasoby baz danych)
        for projection, _, _ in self._projections:
            try:
                if hasattr(projection, "close"):
                    projection.close()
            except Exception as exc:
                logger.warning(
                    "[PROJECTION-WORKER] Error closing projection %s: %s",
                    projection.name,
                    exc,
                )

        logger.info("[PROJECTION-WORKER] Stopped")

    def handle_signal(self, sig: int, _frame: Any = None) -> None:
        """Obsłuż sygnał shutdown (SIGINT, SIGTERM).

        Podłącz przez ``signal.signal(signal.SIGINT, worker.handle_signal)``.

        Args:
            sig: Numer sygnału (signal.SIGINT, signal.SIGTERM).
            _frame: Ramka stosu (ignorowana).
        """
        sig_name = signal.Signals(sig).name
        logger.info("[PROJECTION-WORKER] Received signal %s", sig_name)
        self._shutdown_event.set()

    # ── NATS connection ──────────────────────────────────────────────────

    async def _connect_nats(self) -> None:
        """Połącz z NATS i skonfiguruj JetStream."""
        import nats as nats_module
        from nats.js.api import StorageType

        self._nc = await nats_module.connect(
            servers=self._nats_servers,
            connect_timeout=10.0,
            name="nexus-projection-worker",
        )
        self._js = self._nc.jetstream()
        self._connected = True
        logger.info(
            "[PROJECTION-WORKER] Connected to NATS: %s",
            self._nats_servers,
        )

        # Upewnij się, że strumienie istnieją (utwórz jeśli nie)
        for projection, stream_name, _ in self._projections:
            try:
                try:
                    await self._js.stream_info(stream_name)
                except Exception:
                    # Stream nie istnieje — znajdź konfigurację
                    agg_type = self._infer_aggregate_type(projection)
                    cfg = STREAM_CONFIG.get(agg_type, {})
                    await self._js.add_stream(
                        name=stream_name,
                        subjects=cfg.get("subjects", [f"{stream_name}.>"]),
                        max_age=cfg.get("max_age_days", 90) * 24 * 3600,
                        storage=StorageType.FILE,
                        replicas=cfg.get("replicas", 1),
                    )
                    logger.info(
                        "[PROJECTION-WORKER] Created stream: %s",
                        stream_name,
                    )
            except Exception as exc:
                logger.warning(
                    "[PROJECTION-WORKER] Failed to ensure stream %s: %s",
                    stream_name,
                    exc,
                )

    @staticmethod
    def _infer_aggregate_type(projection: Projection) -> str:
        """Wywnioskuj typ agregatu z projekcji."""
        if isinstance(projection, InvoiceProjection):
            return "invoice"
        if isinstance(projection, DecisionProjection):
            return "decision"
        return projection.name.replace("_projection", "")

    # ── JetStream consumer ───────────────────────────────────────────────

    async def _consume_stream(
        self,
        projection: Projection,
        stream_name: str,
        filter_subject: str,
    ) -> None:
        """Konsumuj eventy ze strumienia JetStream dla jednej projekcji.

        Używa durable pull subscribera, który automatycznie zapamiętuje
        checkpoint na serwerze NATS.

        Args:
            projection: Projekcja do aktualizacji.
            stream_name: Nazwa strumienia JetStream.
            filter_subject: Filtr subject (pusty = wszystkie).
        """
        if not self._connected or self._js is None:
            logger.warning(
                "[PROJECTION-WORKER] JetStream not connected — "
                "falling back to EventStore polling for %s",
                projection.name,
            )
            return

        try:
            sub = await self._js.pull_subscribe(
                subject=filter_subject or ">",
                stream=stream_name,
                durable=f"{projection.name}-worker",
                config={
                    "max_deliver": 3,
                    "ack_wait": 30,
                },
            )
            logger.info(
                "[PROJECTION-WORKER] Pull subscriber ready: %s/%s",
                stream_name,
                projection.name,
            )

            while not self._shutdown_event.is_set():
                try:
                    msgs = await sub.fetch(
                        batch=self._batch_size,
                        timeout=self._poll_interval,
                    )
                    for msg in msgs:
                        await self._process_message(projection, msg)
                except TimeoutError:
                    # Brak wiadomości — kontynuuj pętlę
                    continue
                except Exception as exc:
                    if not self._shutdown_event.is_set():
                        logger.warning(
                            "[PROJECTION-WORKER] Fetch error for %s: %s",
                            projection.name,
                            exc,
                        )
                        await anyio.sleep(1)

        except anyio.CancelledError:
            logger.info(
                "[PROJECTION-WORKER] Consumer cancelled: %s",
                projection.name,
            )
        except Exception as exc:
            logger.error(
                "[PROJECTION-WORKER] Consumer %s failed: %s",
                projection.name,
                exc,
            )

    async def _process_message(
        self,
        projection: Projection,
        msg: Any,
    ) -> None:
        """Przetwórz pojedynczą wiadomość JetStream przez projekcję.

        1. Dekoduj event z JSON bytes
        2. Przekaż do projection._handle_event()
        3. Ack wiadomość
        4. Zaktualizuj checkpoint w EventStore

        Args:
            projection: Projekcja do aktualizacji.
            msg: Wiadomość NATS JetStream.
        """
        event: DomainEvent | None = None
        try:
            # 1. Dekoduj event
            event = decode_event(msg.data)
            event_type = event.event_type if event else "unknown"

            # 2. Przetwórz przez projekcję
            await projection._handle_event(event)
            logger.debug(
                "[PROJECTION-WORKER] Processed %s → %s (version=%d)",
                projection.name,
                event_type,
                event.version,
            )

            # 3. Ack wiadomość
            await msg.ack()

            # 4. Zaktualizuj checkpoint w EventStore (jeśli dostępny)
            if self._event_store is not None and event is not None:
                try:
                    self._event_store.update_checkpoint(
                        projection_name=projection.name,
                        last_event_id=event.event_id,
                        last_version=event.version,
                    )
                except Exception as cp_err:
                    logger.warning(
                        "[PROJECTION-WORKER] Failed to update checkpoint for %s: %s",
                        projection.name,
                        cp_err,
                    )

        except Exception as exc:
            # Loguj błąd i nak (opóźnij retry)
            event_type_str = event.event_type if event else "unknown"
            logger.warning(
                "[PROJECTION-WORKER] Failed to process %s event %s: %s",
                projection.name,
                event_type_str,
                exc,
            )
            try:
                await msg.nak(delay=5)
            except Exception:
                pass

    # ── Fallback polling ─────────────────────────────────────────────────

    async def _fallback_poll_loop(self) -> None:
        """Okresowo polluj EventStore w poszukiwaniu nowych eventów.

        Działa jako fallback gdy JetStream jest niedostępny, oraz jako
        uzupełnienie gdy niektóre eventy nie dotarły przez NATS.
        """
        while not self._shutdown_event.is_set():
            try:
                await anyio.sleep(self._fallback_poll_seconds)

                if self._shutdown_event.is_set():
                    break

                for projection, _, _ in self._projections:
                    try:
                        processed = await projection.process()
                        if processed > 0:
                            logger.info(
                                "[PROJECTION-WORKER:FALLBACK] %s processed %d events",
                                projection.name,
                                processed,
                            )
                    except Exception as exc:
                        logger.warning(
                            "[PROJECTION-WORKER:FALLBACK] %s failed: %s",
                            projection.name,
                            exc,
                        )

            except anyio.CancelledError:
                break
            except Exception as exc:
                logger.error(
                    "[PROJECTION-WORKER:FALLBACK] Loop error: %s",
                    exc,
                )

    # ── Diagnostics ──────────────────────────────────────────────────────

    @property
    def is_connected(self) -> bool:
        """Czy worker jest połączony z NATS."""
        return self._connected

    def get_status(self) -> dict[str, Any]:
        """Zwróć status workera: połączenie, projekcje, zadania.

        Returns:
            Słownik z diagnostyką.
        """
        return {
            "nats_connected": self._connected,
            "nats_servers": self._nats_servers,
            "projections": [
                {
                    "name": proj.name,
                    "stream": stream,
                    "filter": filt or "*",
                }
                for proj, stream, filt in self._projections
            ],
            "consumer_tasks": len(self._consumer_tasks),
            "fallback_enabled": self._enable_fallback,
            "fallback_poll_seconds": self._fallback_poll_seconds,
        }


# ── Factory / helper ──────────────────────────────────────────────────────


async def create_default_worker(
    base_dir: str | Path | None = None,
    nats_servers: list[str] | str | None = None,
    enable_fallback: bool = True,
    poll_interval: float = 1.0,
    batch_size: int = 10,
    fallback_poll_seconds: float = 30.0,
) -> ProjectionWorker:
    """Utwórz domyślnego ProjectionWorkera z InvoiceProjection i DecisionProjection.

    Args:
        base_dir: Bazowy katalog dla EventStore i DB projekcji.
                  Jeśli None, używa AppConfig.
        nats_servers: Serwery NATS.
        enable_fallback: Czy włączyć fallback polling EventStore.
        poll_interval: Interwał pollowania JetStream pull consumer (sekundy).
        batch_size: Maksymalna liczba wiadomości w jednym fetchu.
        fallback_poll_seconds: Interwał fallback pollowania EventStore (sekundy).

    Returns:
        Zainicjalizowany ProjectionWorker z gotowymi projekcjami.
    """
    from nexus_ai.core.config import AppConfig
    from nexus_ai.events import EventStore

    if base_dir is None:
        config = AppConfig.from_toml()
        base_dir = config.base_dir
    else:
        base_dir = Path(base_dir)

    # EventStore
    event_store = EventStore(
        db_path=str(base_dir / "app_data" / "events.db"),
    )

    # Projekcje — oddzielne bazy SQLite dla każdej
    invoices_db = base_dir / "app_data" / "projections" / "invoices.db"
    decisions_db = base_dir / "app_data" / "projections" / "decisions.db"

    invoice_projection = InvoiceProjection(
        event_store=event_store,
        db_path=str(invoices_db),
    )
    decision_projection = DecisionProjection(
        event_store=event_store,
        db_path=str(decisions_db),
    )

    # Worker
    worker = ProjectionWorker(
        event_store=event_store,
        nats_servers=nats_servers,
        enable_fallback_poll=enable_fallback,
        poll_interval_seconds=poll_interval,
        batch_size=batch_size,
        fallback_poll_seconds=fallback_poll_seconds,
    )
    worker.add_projection(invoice_projection)
    worker.add_projection(decision_projection)

    return worker
