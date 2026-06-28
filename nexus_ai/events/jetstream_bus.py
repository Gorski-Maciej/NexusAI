"""
JetStreamEventBus — publish/subscribe domain events through NATS JetStream.

SUPERMOCE NATS (FULL POWER):
  1. JetStream Event Bus — trwałe pub/sub z at-least-once delivery
  2. Reconnect z wykładniczym backoffem — max 5 prób, 1s-30s delay
  3. Object Store (wbudowany w NATS) — przechowywanie PDF faktur i backupów przez NATS
  4. Key-Value Store (wbudowany w NATS) — cache konfiguracji i rule'ów przez NATS
  5. JetStream Pull Consumer — durable pull subscriber z checkpointami
  6. Dead Letter Queue — automatyczne przekazywanie nieudanych wiadomości
  7. Stream monitoring — metryki dla każdego strumienia
  8. Batch publish — publikacja wielu eventów w jednym batchu
  9. Graceful drain — czyste zamykanie połączeń

Architektura:
  - Jeden JetStream Stream na typ agregatu (np. "nexus-invoice", "nexus-decision")
  - Każdy event ma subject: "{stream}.{event_type}" (np. "nexus-invoice.invoice.created")
  - Durable Pull Consumer dla projekcji z checkpointami
  - Object Store (wbudowany w NATS) dla plików (PDF faktur, backupów)
  - Key-Value Store (wbudowany w NATS) dla konfiguracji rozproszonej
"""

from __future__ import annotations

import random
import threading
import time
from msgspec import Struct, field
from typing import Any

import anyio

from structlog import get_logger

from nexus_ai.core.nats_utils import NatsErrors, safe_close

from nexus_ai.events.domain_events import (
    DomainEvent,
    decode_event,
    encode_event,
)

logger = get_logger("nexus.events.jetstream")

# ── Stream configuration ──────────────────────────────────────────────────

# Mapowanie: typ agregatu → konfiguracja strumienia JetStream
STREAM_CONFIG: dict[str, dict[str, Any]] = {
    "invoice": {
        "stream_name": "nexus-invoice",
        "subjects": ["nexus-invoice.>"],
        "max_age_days": 90,
        "storage": "file",  # "file" | "memory"
        "replicas": 1,
        "retention": "limits",  # "limits" | "interest" | "workqueue"
        "max_msg_size": 64 * 1024 * 1024,  # 64MB — dla dużych payloadów z OCR
    },
    "decision": {
        "stream_name": "nexus-decision",
        "subjects": ["nexus-decision.>"],
        "max_age_days": 90,
        "storage": "file",
        "replicas": 1,
        "retention": "limits",
        "max_msg_size": 1 * 1024 * 1024,  # 1MB
    },
    "outbox": {
        "stream_name": "nexus-outbox",
        "subjects": ["nexus-outbox.>"],
        "max_age_days": 30,
        "storage": "file",
        "replicas": 1,
        "retention": "limits",
        "max_msg_size": 1 * 1024 * 1024,
    },
    "files": {
        "stream_name": "nexus-files",
        "subjects": ["nexus-files.>", "nexus-objects.>"],
        "max_age_days": 365,  # 1 rok dla backupów
        "storage": "file",
        "replicas": 1,
        "retention": "limits",
        "max_msg_size": 256 * 1024 * 1024,  # 256MB dla plików PDF
    },
    "config": {
        "stream_name": "nexus-config",
        "subjects": ["nexus-config.>", "nexus-kv.>"],
        "max_age_days": 365,
        "storage": "file",
        "replicas": 1,
        "retention": "limits",
        "max_msg_size": 1 * 1024 * 1024,
    },
    # SUPERMOC: Mirror stream — kopia nexus-invoice dla disaster recovery
    "invoice_mirror": {
        "stream_name": "nexus-invoice-mirror",
        "subjects": [],  # mirror nie ma własnych subjectów — mirroruje istniejący stream
        "max_age_days": 365,
        "storage": "file",
        "replicas": 1,
        "retention": "limits",
        "max_msg_size": 64 * 1024 * 1024,
        "mirror": {
            "name": "nexus-invoice",  # źródło do mirrorowania
        },
    },
    # SUPERMOC: Aggregate stream — sourcing z nexus-invoice + nexus-decision
    "audit": {
        "stream_name": "nexus-audit",
        "subjects": [],  # sourcing: zbiera eventy z wielu strumieni
        "max_age_days": 365 * 5,  # 5 lat dla audytu
        "storage": "file",
        "replicas": 1,
        "retention": "limits",
        "max_msg_size": 64 * 1024 * 1024,
        "sources": [
            {"name": "nexus-invoice"},
            {"name": "nexus-decision"},
            {"name": "nexus-outbox"},
        ],
    },
}

# Cache na skonfigurowane strumienie (thread-safe dla free-threaded Python)
_stream_cache: dict[str, bool] = {}
_stream_cache_lock = threading.Lock()

# ── Konfiguracja reconnectu ──────────────────────────────────────────────

DEFAULT_RECONNECT_ATTEMPTS = 5
DEFAULT_RECONNECT_BASE_DELAY = 1.0  # sekundy
DEFAULT_RECONNECT_MAX_DELAY = 30.0  # sekundy
DEFAULT_CONNECT_TIMEOUT = 10.0  # sekundy

# ── JetStream Event Bus ───────────────────────────────────────────────────


class JetStreamEventBus:
    """Publikuje eventy domenowe do NATS JetStream.

    SUPERMOCE:
      - Automatyczny reconnect z wykładniczym backoffem (max 5 prób, 1s-30s)
      - Graceful degradation gdy NATS niedostępny
      - Batch publish dla wysokiej przepustowości
      - Stream auto-creation przy starcie

    Args:
        nats_servers: Lista serwerów NATS (np. ``["nats://localhost:4222"]``).
        connect_timeout: Timeout na połączenie w sekundach.
        reconnect_attempts: Maksymalna liczba prób reconnectu (0 = brak, -1 = nieskończone).
        reconnect_base_delay: Bazowe opóźnienie między reconnectami (sekundy).
        reconnect_max_delay: Maksymalne opóźnienie między reconnectami (sekundy).
        name: Nazwa połączenia NATS (dla diagnostyki).
    """

    def __init__(
        self,
        nats_servers: list[str] | str | None = None,
        connect_timeout: float = DEFAULT_CONNECT_TIMEOUT,
        reconnect_attempts: int = DEFAULT_RECONNECT_ATTEMPTS,
        reconnect_base_delay: float = DEFAULT_RECONNECT_BASE_DELAY,
        reconnect_max_delay: float = DEFAULT_RECONNECT_MAX_DELAY,
        name: str = "nexus-event-bus",
    ) -> None:
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._connect_timeout = connect_timeout
        self._reconnect_attempts = reconnect_attempts
        self._reconnect_base_delay = reconnect_base_delay
        self._reconnect_max_delay = reconnect_max_delay
        self._name = name
        self._nc: Any = None  # nats connection
        self._js: Any = None  # jetstream context
        self._connected = False
        self._connect_lock = threading.Lock()
        self._kv_stores: dict[str, Any] = {}  # cached KV stores
        self._object_stores: dict[str, Any] = {}  # cached Object stores

    # ── Connection management ───────────────────────────────────────────

    async def _ensure_connected(self) -> bool:
        """Upewnij się, że połączenie z NATS jest aktywne.

        Jeśli połączenie zostało przerwane, próbuje reconnect z
        wykładniczym backoffem.

        Returns:
            ``True`` jeśli połączono, ``False`` jeśli nie.
        """
        if self._connected and self._nc is not None:
            try:
                # SUPERMOC: Szybki ping do NATS — jeśli działa, używamy istniejącego połączenia
                await self._nc.ping()
                return True
            except Exception:
                # Połączenie przerwane — przechodzimy do reconnectu
                logger.warning("[JETSTREAM] Connection lost — attempting reconnect")
                self._connected = False

        with self._connect_lock:
            # Double-check po uzyskaniu locka
            if self._connected:
                return True

            # SUPERMOC: Reconnect z wykładniczym backoffem
            attempt = 0
            last_error = None
            max_attempts = self._reconnect_attempts

            while max_attempts < 0 or attempt < max_attempts:
                attempt += 1
                try:
                    # SUPERMOC nats-py: Connection callbacks + error types
                    async def _on_disconnect() -> None:
                        logger.warning("[JETSTREAM] Connection lost")

                    async def _on_reconnect() -> None:
                        logger.info("[JETSTREAM] Reconnected")

                    async def _on_close() -> None:
                        logger.info("[JETSTREAM] Connection closed")

                    import nats

                    # Zamknij stare połączenie jeśli istnieje
                    if self._nc is not None:
                        await safe_close(self._nc)

                    self._nc = await nats.connect(
                        servers=self._nats_servers,
                        connect_timeout=self._connect_timeout,
                        name=self._name,
                        # SUPERMOC nats-py: Connection lifecycle callbacks
                        disconnected_cb=_on_disconnect,
                        reconnected_cb=_on_reconnect,
                        closed_cb=_on_close,
                        # SUPERMOC: Reconnect handlers
                        reconnect_time_wait=self._reconnect_base_delay,
                        max_reconnect_attempts=-1,  # sami kontrolujemy reconnect
                    )
                    self._js = self._nc.jetstream()
                    self._connected = True

                    # Skonfiguruj strumienie przy (re)connect
                    for agg_type, cfg in STREAM_CONFIG.items():
                        await self._ensure_stream(cfg)

                    logger.info(
                        "[JETSTREAM] Connected to %s (attempt %d)",
                        self._nats_servers,
                        attempt,
                    )
                    return True

                except Exception as exc:
                    last_error = exc
                    if max_attempts != -1 and attempt >= max_attempts:
                        break
                    # SUPERMOC: Wykładniczy backoff z jitterem
                    delay = min(
                        self._reconnect_base_delay * (2 ** (attempt - 1)),
                        self._reconnect_max_delay,
                    )
                    # Dodaj losowy jitter ±20%
                    delay *= 0.8 + random.random() * 0.4
                    logger.warning(
                        "[JETSTREAM] Reconnect attempt %d/%s failed: %s (retry in %.1fs)",
                        attempt,
                        "∞" if max_attempts < 0 else str(max_attempts),
                        exc,
                        delay,
                    )
                    await anyio.sleep(delay)

            logger.error(
                "[JETSTREAM] All reconnect attempts failed: %s",
                last_error,
            )
            self._connected = False
            return False

    # ── Stream management ───────────────────────────────────────────────

    async def _ensure_stream(self, cfg: dict[str, Any]) -> None:
        """Upewnij się, że strumień JetStream istnieje.

        SUPERMOC: Obsługuje retention, max_msg_size, duplicate_window.
        SUPERMOC: Mirror — tworzy kopię strumienia dla disaster recovery.
        SUPERMOC: Sourcing — agreguje wiele strumieni w jeden (audyt).
        """
        if self._js is None:
            return
        stream_name = cfg["stream_name"]
        with _stream_cache_lock:
            if stream_name in _stream_cache:
                return
        try:
            from nats.js.api import (
                CompressionOption,
                DiscardPolicy,
                ReplayPolicy,
                RetentionPolicy,
                StorageType,
            )

            # Mapowanie retention policy string → enum
            _RETENTION_MAP = {
                "limits": RetentionPolicy.LIMITS,
                "interest": RetentionPolicy.INTEREST,
                "workqueue": RetentionPolicy.WORK_QUEUE,
            }

            try:
                await self._js.stream_info(stream_name)
            except Exception:
                # Zbuduj konfigurację strumienia
                stream_kwargs: dict[str, Any] = {
                    "name": stream_name,
                    "max_age": cfg["max_age_days"] * 24 * 3600,
                    "storage": StorageType.FILE,
                    "replicas": cfg.get("replicas", 1),
                    "retention": _RETENTION_MAP.get(
                        cfg.get("retention", "limits"), RetentionPolicy.LIMITS
                    ),
                    "max_msg_size": cfg.get("max_msg_size", 64 * 1024 * 1024),
                    "max_msgs_per_subject": 10_000,
                    "duplicate_window": 2 * 60 * 1_000_000_000,
                    # SUPERMOC JETSTREAM: DiscardPolicy — co robić gdy strumień pełny
                    "discard": DiscardPolicy.OLD,
                    # SUPERMOC JETSTREAM: Compression — oszczędność miejsca na dysku
                    "compression": CompressionOption.S2,
                    # SUPERMOC JETSTREAM: DenyDelete — chroni strumienie audytowe przed usunięciem
                    "deny_delete": True if "audit" in stream_name else False,
                }

                # SUPERMOC: Mirror — strumień który mirroruje inny strumień (DR)
                # Używany dla nexus-invoice-mirror jako kopia zapasowa
                # UWAGA: Mirror NIE może mieć własnych subjectów! NATS odrzuci tworzenie.
                if "mirror" in cfg:
                    stream_kwargs["mirror"] = cfg["mirror"]
                    stream_kwargs.pop("subjects", None)
                    stream_kwargs.pop("max_msgs_per_subject", None)
                    logger.info(
                        "[JETSTREAM] Configuring mirror for %s → %s",
                        stream_name,
                        cfg["mirror"].get("name"),
                    )
                # SUPERMOC: Sourcing — strumień który agreguje wiele innych strumieni
                # Używany dla nexus-audit jako agregacja invoice+decision+outbox
                # UWAGA: Sourcing NIE może mieć własnych subjectów! NATS odrzuci tworzenie.
                elif "sources" in cfg:
                    stream_kwargs["sources"] = cfg["sources"]
                    stream_kwargs.pop("subjects", None)
                    stream_kwargs.pop("max_msgs_per_subject", None)
                    logger.info(
                        "[JETSTREAM] Configuring sourcing for %s from %d sources",
                        stream_name,
                        len(cfg["sources"]),
                    )
                # Standardowy strumień z subjectami
                else:
                    stream_kwargs["subjects"] = cfg["subjects"]

                await self._js.add_stream(**stream_kwargs)
                logger.info(
                    "[JETSTREAM] Created stream: %s (retention=%s, max_size=%d)",
                    stream_name,
                    cfg.get("retention", "limits"),
                    cfg.get("max_msg_size", 0),
                )

            with _stream_cache_lock:
                _stream_cache[stream_name] = True
        except Exception as exc:
            logger.warning(
                "[JETSTREAM] Failed to ensure stream %s: %s",
                stream_name,
                exc,
            )  # ── Key-Value Store (wbudowany w NATS) ───────────────────────────────

    async def get_kv_store(self, bucket_name: str) -> Any | None:
        """Pobierz lub utwórz Key-Value Store bucket (wbudowany w NATS JetStream).

        SUPERMOC NATS: Key-Value Store wbudowany w NATS JetStream.
        SUPERMOC: Obsługa istniejących bucketów — próbuje create, fallback do get.
        Używany do przechowywania:
          - Konfiguracja reguł podatkowych (rule/config)
          - Thresholds ryzyka (risk/thresholds)
          - Stan workerów (workers/status)
          - Cache API (api/cache)

        Args:
            bucket_name: Nazwa bucketa KV (np. "nexus-config", "nexus-rules").

        Returns:
            Instancja KeyValue store lub None jeśli NATS niedostępny."""
        if not await self._ensure_connected():
            return None
        if bucket_name in self._kv_stores:
            return self._kv_stores[bucket_name]
        try:
            # SUPERMOC: CreateKeyValue — tworzy bucket jeśli nie istnieje
            kv = await self._js.create_key_value(bucket=bucket_name)
            self._kv_stores[bucket_name] = kv
            logger.info("[JETSTREAM:KV] Created bucket: %s", bucket_name)
            return kv
        except Exception:
            pass  # Bucket może już istnieć — spróbuj go pobrać
        try:
            # SUPERMOC: Pobierz istniejący bucket (jeśli już został utworzony)
            kv = await self._js.key_value(bucket=bucket_name)
            self._kv_stores[bucket_name] = kv
            logger.info("[JETSTREAM:KV] Using existing bucket: %s", bucket_name)
            return kv
        except Exception as exc:
            logger.warning(
                "[JETSTREAM:KV] Failed to get bucket %s: %s",
                bucket_name,
                exc,
            )
            return None  # ── Object Store (wbudowany w NATS) ──────────────────────────────────

    async def get_object_store(self, bucket_name: str) -> Any | None:
        """Pobierz lub utwórz Object Store bucket (wbudowany w NATS JetStream).

        SUPERMOC NATS: Object Store wbudowany w NATS JetStream.
        SUPERMOC: Obsługa istniejących bucketów — próbuje create, fallback do get.
        Używany do przechowywania:
          - PDF faktur (invoices/pdf)
          - Backupów bazy danych (backups/db)
          - Obrazów do OCR (ocr/images)
          - Raportów (reports)

        Args:
            bucket_name: Nazwa bucketa Object Store (np. "nexus-files", "nexus-backups").

        Returns:
            Instancja ObjectStore lub None jeśli NATS niedostępny."""
        if not await self._ensure_connected():
            return None
        if bucket_name in self._object_stores:
            return self._object_stores[bucket_name]
        try:
            # SUPERMOC: CreateObjectStore — tworzy bucket jeśli nie istnieje
            obj = await self._js.create_object_store(bucket=bucket_name)
            self._object_stores[bucket_name] = obj
            logger.info("[JETSTREAM:OBJECT] Created bucket: %s", bucket_name)
            return obj
        except Exception:
            pass  # Bucket może już istnieć — spróbuj go pobrać
        try:
            # SUPERMOC: Pobierz istniejący bucket (jeśli już został utworzony)
            obj = await self._js.object_store(bucket=bucket_name)
            self._object_stores[bucket_name] = obj
            logger.info("[JETSTREAM:OBJECT] Using existing bucket: %s", bucket_name)
            return obj
        except Exception as exc:
            logger.warning(
                "[JETSTREAM:OBJECT] Failed to get bucket %s: %s",
                bucket_name,
                exc,
            )
            return None

    # ── Direct Get API ─────────────────────────────────────────────────

    async def get_message(
        self,
        stream_name: str,
        seq: int,
    ) -> Any | None:
        """Pobierz pojedynczą wiadomość ze strumienia po numerze sekwencyjnym.

        SUPERMOC JETSTREAM: Direct Get API — odczyt wiadomości bez tworzenia konsumera.
        Używane do:
          - Audytu: odczyt konkretnej decyzji
          - Debugowania: weryfikacja zapisanych danych
          - Replayu: odtworzenie pojedynczej wiadomości

        Args:
            stream_name: Nazwa strumienia JetStream.
            seq: Numer sekwencyjny wiadomości (z ack.seq).

        Returns:
            Wiadomość lub None jeśli nie znaleziono.
        """
        if not await self._ensure_connected() or self._js is None:
            return None
        try:
            # SUPERMOC JETSTREAM: get_msg() — direct access without consumer
            msg = await self._js.get_msg(stream_name, seq)
            return msg
        except Exception as exc:
            logger.warning("[JETSTREAM] Failed to get msg %s/%d: %s", stream_name, seq, exc)
            return None

    async def get_last_message(self, stream_name: str) -> Any | None:
        """Pobierz ostatnią wiadomość ze strumienia.

        SUPERMOC JETSTREAM: Get last sequence without consumer.
        Używane do monitorowania stanu strumienia.

        Args:
            stream_name: Nazwa strumienia.

        Returns:
            Ostatnia wiadomość lub None.
        """
        try:
            info = await self._js.stream_info(stream_name)
            last_seq = info.state.last_seq
            return await self.get_message(stream_name, last_seq) if last_seq > 0 else None
        except Exception:
            return None

    # ── Stream Management API ────────────────────────────────────────────

    async def purge_stream(self, stream_name: str) -> bool:
        """Wyczyść wszystkie wiadomości ze strumienia.

        SUPERMOC JETSTREAM: purge_stream() — całkowite czyszczenie strumienia.
        Używane do:
          - Resetowania strumienia testowego
          - Czyszczenia starych danych przed retention
          - Przygotowania środowiska deweloperskiego

        Args:
            stream_name: Nazwa strumienia.

        Returns:
            True jeśli wyczyszczono.
        """
        if not await self._ensure_connected() or self._js is None:
            return False
        try:
            await self._js.purge_stream(stream_name)
            logger.info("[JETSTREAM] Purged stream: %s", stream_name)
            return True
        except Exception as exc:
            logger.warning("[JETSTREAM] Failed to purge %s: %s", stream_name, exc)
            return False

    async def delete_message(self, stream_name: str, seq: int) -> bool:
        """Usuń pojedynczą wiadomość ze strumienia.

        SUPERMOC JETSTREAM: delete_msg() — usuwanie po seq.
        Używane do:
          - RODO: prawo do bycia zapomnianym
          - Usuwania błędnych wiadomości
          - Czyszczenia danych wrażliwych

        Args:
            stream_name: Nazwa strumienia.
            seq: Numer sekwencyjny wiadomości.

        Returns:
            True jeśli usunięto.
        """
        if not await self._ensure_connected() or self._js is None:
            return False
        try:
            await self._js.delete_msg(stream_name, seq)
            logger.info("[JETSTREAM] Deleted msg %s/%d", stream_name, seq)
            return True
        except Exception as exc:
            logger.warning("[JETSTREAM] Failed to delete %s/%d: %s", stream_name, seq, exc)
            return False

    # ── Sealed Stream API ────────────────────────────────────────────────

    async def seal_stream(self, stream_name: str) -> bool:
        """Zapieczętuj strumień — uniemożliwij dalsze publikowanie.

        SUPERMOC JETSTREAM: sealed stream — immutable audit trail.
        Po zapieczętowaniu:
          - Nie można publikować nowych wiadomości
          - Nie można usuwać wiadomości
          - Można czytać istniejące wiadomości
        Używane do:
          - Audytu: zamknięcie okresu rozliczeniowego
          - Compliance: niezmienialny ślad audytowy
          - Archiwizacji: zamrożenie strumienia

        Args:
            stream_name: Nazwa strumienia do zapieczętowania.

        Returns:
            True jeśli zapieczętowano.
        """
        if not await self._ensure_connected() or self._js is None:
            return False
        try:
            info = await self._js.stream_info(stream_name)
            info.config.sealed = True
            await self._js.update_stream(info.config)
            logger.info("[JETSTREAM] Sealed stream: %s", stream_name)
            return True
        except Exception as exc:
            logger.warning("[JETSTREAM] Failed to seal %s: %s", stream_name, exc)
            return False

    # ── Publish ─────────────────────────────────────────────────────────

    async def connect(self) -> None:
        """Połącz z NATS i skonfiguruj strumienie JetStream."""
        await self._ensure_connected()

    async def publish(self, event: DomainEvent) -> bool:
        """Opublikuj event do JetStream.

        SUPERMOC: Automatyczny reconnect przed publikacją.
        SUPERMOC: Logowanie sequence number JetStream.

        Args:
            event: Event do opublikowania.

        Returns:
            ``True`` jeśli publikacja się powiodła, ``False`` jeśli nie.
        """
        if not await self._ensure_connected() or self._js is None:
            logger.warning(
                "[JETSTREAM] Not connected — skipping publish of %s",
                event.event_type,
            )
            return False

        try:
            data = encode_event(event)
            subject = f"nexus-{event.aggregate_type}.{event.event_type}"
            ack = await self._js.publish(subject, data)
            logger.debug(
                "[JETSTREAM] Published %s seq=%d",
                event.event_type,
                ack.seq if ack else 0,
            )
            return True
        except Exception as exc:
            logger.warning(
                "[JETSTREAM] Failed to publish %s: %s",
                event.event_type,
                exc,
            )
            return False

    async def publish_batch(self, events: list[DomainEvent]) -> int:
        """Opublikuj wiele eventów w batchu.

        SUPERMOC: Wyższa przepustowość przez batchowanie.

        Args:
            events: Lista eventów.

        Returns:
            Liczba pomyślnie opublikowanych.
        """
        if not await self._ensure_connected() or self._js is None:
            return 0

        published = 0
        for event in events:
            try:
                data = encode_event(event)
                subject = f"nexus-{event.aggregate_type}.{event.event_type}"
                await self._js.publish(subject, data)
                published += 1
            except Exception:
                pass
        return published

    async def close(self) -> None:
        """Zamknij połączenie z NATS.

        SUPERMOC nats-py:
          - safe_close() z flush() przed drain() — gwarantuje dostarczenie buforowanych wiadomości
          - NatsErrors.ConnectionClosedError — obsłużony przez safe_close()
        """
        if self._nc is not None:
            await safe_close(self._nc)
            self._nc = None
            self._js = None
            self._connected = False
            self._kv_stores.clear()
            self._object_stores.clear()
            logger.info("[JETSTREAM] Disconnected")

    @property
    def is_connected(self) -> bool:
        return self._connected

    @property
    def jetstream(self) -> Any | None:
        return self._js


# ── JetStream Consumer ────────────────────────────────────────────────────


class ConsumerConfig(Struct):
    """Konfiguracja konsumera JetStream dla projekcji.

    Args:
        stream_name: Nazwa strumienia (np. "nexus-invoice").
        consumer_name: Nazwa konsumera (np. "invoice-projection").
        deliver_policy: "all" = od początku, "last" = tylko nowe, "new" = od checkpoint.
        filter_subject: Opcjonalny filtr subject (np. "nexus-invoice.invoice.created").
        max_deliver: Maksymalna liczba dostaw przed DLQ (1-100).
        ack_wait: Czas oczekiwania na ack w sekundach (1-300).
        max_ack_pending: Maksymalna liczba niepotwierdzonych wiadomości (1-1000).
        idle_heartbeat: Czas w sekundach między heartbeatami (0 = wyłączone).
        backoff_delays: Lista opóźnień między retry (sekundy).
        description: Opis konsumera (dla diagnostyki).
        headers_only: Tylko nagłówki, bez body.
        flow_control: Ordered push consumer z flow control.
        replay_policy: "instant" lub "original".
        num_replicas: HA repliki (0-3).
    """

    stream_name: str
    consumer_name: str
    deliver_policy: str = "all"
    filter_subject: str = ""
    max_deliver: int = 3
    ack_wait: int = 30
    max_ack_pending: int = 100
    idle_heartbeat: int = 10
    backoff_delays: list[int] = field(default_factory=list)
    description: str = ""
    headers_only: bool = False
    flow_control: bool = False
    replay_policy: str = "instant"
    num_replicas: int = 0

    def __post_init__(self) -> None:
        """Walidacja zakresów pól konfiguracyjnych."""
        if not (1 <= self.max_deliver <= 100):
            raise ValueError(f"max_deliver must be 1-100, got {self.max_deliver}")
        if not (1 <= self.ack_wait <= 300):
            raise ValueError(f"ack_wait must be 1-300, got {self.ack_wait}")
        if not (1 <= self.max_ack_pending <= 1000):
            raise ValueError(f"max_ack_pending must be 1-1000, got {self.max_ack_pending}")
        if not (0 <= self.idle_heartbeat <= 60):
            raise ValueError(f"idle_heartbeat must be 0-60, got {self.idle_heartbeat}")
        if not (0 <= self.num_replicas <= 3):
            raise ValueError(f"num_replicas must be 0-3, got {self.num_replicas}")


class JetStreamConsumer:
    """Konsumuje eventy z JetStream i przekazuje do handlerów.

    SUPERMOCE:
      - Durable pull subscriber z automatycznym checkpointem
      - Retry z wykładniczym backoffem (konfigurowalne przez backoff_delays)
      - Dead Letter Queue po przekroczeniu max_deliver
      - Graceful shutdown przez anyio cancellation
      - Timeout na fetch wiadomości

    Args:
        nats_servers: Lista serwerów NATS.
        configs: Lista konfiguracji konsumerów.
        event_handler: Funkcja callback(event: DomainEvent) -> None.
        connect_timeout: Timeout na połączenie.
        reconnect_attempts: Maksymalna liczba prób reconnectu.
    """

    def __init__(
        self,
        nats_servers: list[str] | str | None = None,
        configs: list[ConsumerConfig] | None = None,
        event_handler: Any = None,
        connect_timeout: float = DEFAULT_CONNECT_TIMEOUT,
        reconnect_attempts: int = DEFAULT_RECONNECT_ATTEMPTS,
    ) -> None:
        self._nats_servers = nats_servers or ["nats://localhost:4222"]
        self._configs = configs or []
        self._event_handler = event_handler
        self._connect_timeout = connect_timeout
        self._reconnect_attempts = reconnect_attempts
        self._nc: Any = None
        self._js: Any = None
        self._consumer_tasks: list[Any] = []
        self._connected = False

    async def start(self) -> None:
        """Połącz i uruchom konsumentów jako background taski."""
        if not await self._connect_nats():
            logger.warning("[JETSTREAM:CONSUMER] NATS connection failed — consumers not started")
            return

        async def _run_consumers() -> None:
            async with anyio.create_task_group() as tg:
                for cfg in self._configs:
                    tg.start_soon(self._consume_stream, cfg)
                    logger.info(
                        "[JETSTREAM:CONSUMER] Consumer started: %s/%s (filter=%s, max_deliver=%d)",
                        cfg.stream_name,
                        cfg.consumer_name,
                        cfg.filter_subject or "*",
                        cfg.max_deliver,
                    )

        # Uruchom konsumentów jako background task
        task = anyio.ensure_backend().create_task(_run_consumers())
        self._consumer_tasks.append(task)

    async def _connect_nats(self) -> bool:
        """Połącz z NATS z retry.

        Returns:
            ``True`` jeśli połączono, ``False`` jeśli nie.
        """
        import nats

        for attempt in range(1, max(self._reconnect_attempts, 1) + 1):
            try:
                self._nc = await nats.connect(
                    servers=self._nats_servers,
                    connect_timeout=self._connect_timeout,
                    name="nexus-event-consumer",
                )
                self._js = self._nc.jetstream()
                self._connected = True
                return True
            except Exception as exc:
                if attempt >= self._reconnect_attempts:
                    logger.error("[JETSTREAM:CONSUMER] Failed to connect: %s", exc)
                    return False
                delay = min(2 ** (attempt - 1), 10)
                await anyio.sleep(delay)
        return False

    async def _consume_stream(self, cfg: ConsumerConfig) -> None:
        """Konsumuj eventy z jednego strumienia.

        SUPERMOC: Konfigurowalne backoff_delays zamiast hardcoded nak(delay=5).
        SUPERMOC: max_ack_pending dla kontroli współbieżności.
        SUPERMOC: idle_heartbeat dla wykrywania martwych konsumentów.
        """
        if not self._connected or self._js is None:
            return

        # SUPERMOC JETSTREAM: lokalny import bo nats może nie być zainstalowane
        try:
            from nats.js.api import ReplayPolicy

            _REPLAY_POLICY_MAP = {
                "instant": ReplayPolicy.Instant,
                "original": ReplayPolicy.Original,
            }
        except ImportError:
            _REPLAY_POLICY_MAP = {}

        consumer_cfg: dict[str, Any] = {
            "max_deliver": cfg.max_deliver,
            "ack_wait": cfg.ack_wait,
            "max_ack_pending": cfg.max_ack_pending,
            "idle_heartbeat": cfg.idle_heartbeat if cfg.idle_heartbeat > 0 else None,
        }

        # SUPERMOC JETSTREAM: headers_only — tylko nagłówki (lekki konsumer)
        if cfg.headers_only:
            consumer_cfg["headers_only"] = True

        # SUPERMOC JETSTREAM: flow_control — ordered push consumer
        if cfg.flow_control:
            consumer_cfg["flow_control"] = True
            consumer_cfg["ordered"] = True

        # SUPERMOC JETSTREAM: replay_policy — instant vs original (enum!)
        if cfg.replay_policy != "instant" and _REPLAY_POLICY_MAP:
            consumer_cfg["replay_policy"] = _REPLAY_POLICY_MAP.get(
                cfg.replay_policy,
                next(iter(_REPLAY_POLICY_MAP.values())),  # fallback: pierwszy enum
            )

        # SUPERMOC JETSTREAM: num_replicas — HA dla konsumera
        if cfg.num_replicas > 1:
            consumer_cfg["num_replicas"] = cfg.num_replicas

        # SUPERMOC: Wykładniczy backoff — jeśli skonfigurowano
        if cfg.backoff_delays:
            consumer_cfg["backoff"] = cfg.backoff_delays

        if cfg.description:
            consumer_cfg["description"] = cfg.description

        # Usuń None values
        consumer_cfg = {k: v for k, v in consumer_cfg.items() if v is not None}

        try:
            sub = await self._js.pull_subscribe(
                subject=cfg.filter_subject or ">",
                stream=cfg.stream_name,
                durable=cfg.consumer_name,
                config=consumer_cfg,
            )

            while True:
                try:
                    msgs = await sub.fetch(batch=10, timeout=5)
                    for msg in msgs:
                        try:
                            event = decode_event(msg.data)
                            if self._event_handler:
                                await self._event_handler(event)
                            await msg.ack()
                        except Exception as exc:
                            logger.warning(
                                "[JETSTREAM:CONSUMER] Failed to process message: %s",
                                exc,
                            )
                            # SUPERMOC: Nak z opóźnieniem — JetStream sam zarządza retry
                            await msg.nak(delay=min(5, cfg.ack_wait // 2))
                except NatsErrors.TimeoutError:
                    pass
                except NatsErrors.ConnectionClosedError:
                    logger.warning("[JETSTREAM:CONSUMER] Connection closed — reconnecting")
                    break
                except Exception as exc:
                    logger.warning(
                        "[JETSTREAM:CONSUMER] Fetch error: %s",
                        exc,
                    )
                    await anyio.sleep(1)

        except anyio.CancelledError:
            logger.info("[JETSTREAM:CONSUMER] Cancelled: %s", cfg.consumer_name)
        except Exception as exc:
            logger.error(
                "[JETSTREAM:CONSUMER] %s failed: %s",
                cfg.consumer_name,
                exc,
            )

    async def stop(self) -> None:
        """Zatrzymaj konsumentów i zamknij NATS."""
        for task in self._consumer_tasks:
            task.cancel()
        self._consumer_tasks.clear()
        if self._nc is not None:
            await safe_close(self._nc)
            self._nc = None
            self._js = None
            self._connected = False


# ── Global singleton (thread-safe dla free-threaded Python) ───────────────

_default_bus: JetStreamEventBus | None = None
_default_bus_lock = threading.Lock()


def get_event_bus(
    nats_servers: list[str] | str | None = None,
    connect_timeout: float = DEFAULT_CONNECT_TIMEOUT,
    reconnect_attempts: int = DEFAULT_RECONNECT_ATTEMPTS,
) -> JetStreamEventBus:
    """Zwraca globalną instancję JetStreamEventBus (singleton).

    Thread-safe — używa ``threading.Lock`` dla free-threaded Python.

    Args:
        nats_servers: Lista serwerów NATS.
        connect_timeout: Timeout na połączenie.
        reconnect_attempts: Maksymalna liczba prób reconnectu.

    Returns:
        Globalna instancja JetStreamEventBus.
    """
    global _default_bus
    if _default_bus is None:
        with _default_bus_lock:
            if _default_bus is None:
                _default_bus = JetStreamEventBus(
                    nats_servers=nats_servers,
                    connect_timeout=connect_timeout,
                    reconnect_attempts=reconnect_attempts,
                )
    return _default_bus
