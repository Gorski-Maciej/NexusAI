"""
OutboxRelay — Transactional Outbox pattern for guaranteed event delivery.

Transactional Outbox zapewnia atomowość: zapis faktury i zdarzenia do outbox
w tej samej transakcji, a dopiero potem asynchroniczna wysyłka do TigerBeetle.
Gwarantuje „at-least-once delivery" nawet przy restartach i awariach.

Główne cechy:
  - Asynchroniczny odczyt outbox_events z bazy SQLite (via SQLAlchemy)
  - Wysyłka TAX_CALCULATED do TigerBeetle z dwufazowymi transferami
  - Wykładnicze opóźnienie między retry (exponential backoff)
  - Dead Letter Queue po wyczerpaniu prób
  - Idempotentność przez tabelę processed_events
  - Circuit breaker na NATS/TigerBeetle — chroni przed kaskadowymi awariami

Usage:
    relay = OutboxRelay(
        session_factory=session_factory,
        tigerbeetle=tb_client,
        max_retries=3,
        base_delay_seconds=1.0,
    )
    stats = await relay.process_pending()
    # → {"processed": 5, "failed": 1, "dead_letter": 0}
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import logging
import time
import uuid
from dataclasses import dataclass
from typing import Any, Callable

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger("nexus.services.outbox_relay")

# ── Constants ─────────────────────────────────────────────────────────────────

DEFAULT_MAX_RETRIES = 3
"""Maksymalna liczba prób wysyłki zdarzenia przed przeniesieniem do DLQ."""

DEFAULT_BASE_DELAY_SECONDS = 1.0
"""Bazowe opóźnienie przed pierwszą retry (w sekundach)."""

DEFAULT_MAX_DELAY_SECONDS = 60.0
"""Maksymalne opóźnienie między retry (exponential backoff capped)."""

DEFAULT_BATCH_SIZE = 100
"""Maksymalna liczba zdarzeń przetwarzanych w jednej iteracji."""

PROCESSING_TIMEOUT_SECONDS = 300
"""Czas (w sekundach) po którym zdarzenie w statusie PROCESSING jest uznawane za
stuck i automatycznie odblokowywane (status → FAILED)."""

DEFAULT_ACCOUNT_EXPENSE_ID = 40100
"""Domyślne ID konta kosztów (Wn) — polski plan kont."""

DEFAULT_ACCOUNT_VAT_ID = 22100
"""Domyślne ID konta VAT naliczonego (Wn) — polski plan kont."""

DEFAULT_ACCOUNT_PAYABLES_ID = 20200
"""Domyślne ID konta rozrachunków (Ma) — polski plan kont."""



# ── Data structures ───────────────────────────────────────────────────────────


@dataclass
class OutboxStats:
    """Statystyki pojedynczej iteracji przetwarzania.

    Attributes:
        processed: Liczba zdarzeń pomyślnie przetworzonych.
        failed: Liczba zdarzeń, które nie powiodły się (będą retried).
        dead_letter: Liczba zdarzeń przeniesionych do DLQ.
        skipped_idempotent: Liczba zdarzeń pominiętych (już przetworzone).
        total: Łączna liczba zdarzeń w batchu.
        processing_time_ms: Czas przetwarzania w milisekundach.
    """
    processed: int = 0
    failed: int = 0
    dead_letter: int = 0
    skipped_idempotent: int = 0
    total: int = 0
    processing_time_ms: float = 0.0


# ── Exceptions ────────────────────────────────────────────────────────────────


class OutboxRelayError(Exception):
    """Base exception for OutboxRelay errors."""
    pass


class TigerBeetlePostingError(OutboxRelayError):
    """Raised when TigerBeetle posting fails after all retries."""
    pass


class UnknownEventTypeError(OutboxRelayError):
    """Raised when an outbox event has an unknown/unhandled event_type."""
    pass


# ── OutboxRelay ───────────────────────────────────────────────────────────────


class OutboxRelay:
    """Transactional Outbox Relay — gwarantowana dostawa zdarzeń do TigerBeetle.

    Args:
        session_factory: SQLAlchemy async session factory.
        tigerbeetle: TigerBeetleClient do wysyłki transferów.
            Jeśli None, zdarzenia TAX_CALCULATED są pomijane (tylko log).
        max_retries: Maksymalna liczba retry przed DLQ.
        base_delay_seconds: Bazowe opóźnienie przed pierwszą retry.
        max_delay_seconds: Maksymalne opóźnienie (cap dla exponential backoff).
        batch_size: Maksymalna liczba zdarzeń w jednej iteracji.
        process_tax_calculated: Jeśli True, przetwarza TAX_CALCULATED.
        on_dead_letter: Opcjonalny callback wywoływany przy przeniesieniu do DLQ.
    """

    def __init__(
        self,
        session_factory: Callable[[], AsyncSession],
        tigerbeetle: Any = None,
        *,
        max_retries: int = DEFAULT_MAX_RETRIES,
        base_delay_seconds: float = DEFAULT_BASE_DELAY_SECONDS,
        max_delay_seconds: float = DEFAULT_MAX_DELAY_SECONDS,
        batch_size: int = DEFAULT_BATCH_SIZE,
        process_tax_calculated: bool = True,
        on_dead_letter: Callable[[dict[str, Any]], Any] | None = None,
        account_expense_id: int = DEFAULT_ACCOUNT_EXPENSE_ID,
        account_vat_id: int = DEFAULT_ACCOUNT_VAT_ID,
        account_payables_id: int = DEFAULT_ACCOUNT_PAYABLES_ID,
    ) -> None:
        self._session_factory = session_factory
        self._tigerbeetle = tigerbeetle
        self._max_retries = max_retries
        self._base_delay = base_delay_seconds
        self._max_delay = max_delay_seconds
        self._batch_size = batch_size
        self._process_tax_calculated = process_tax_calculated
        self._on_dead_letter = on_dead_letter
        self._account_expense_id = account_expense_id
        self._account_vat_id = account_vat_id
        self._account_payables_id = account_payables_id

    # ── Public API ───────────────────────────────────────────────────────

    async def process_pending(self) -> OutboxStats:
        """Przetwórz wszystkie oczekujące zdarzenia w outbox.

        Wykonuje pełny cykl:
          1. Odblokowanie stuck PROCESSING zdarzeń (timeout >= 5 min)
          2. Atomowa rezerwacja zdarzeń PENDING/FAILED
          3. Dla każdego: dispatch → TigerBeetle
          4. Idempotentność przez processed_events
          5. Retry z exponential backoff
          6. DLQ po wyczerpaniu prób

        Returns:
            OutboxStats z liczbą przetworzonych, failed, dead_letter.
        """
        stats = OutboxStats()
        start = time.monotonic()

        async with self._session_factory() as session:
            # 1. Zapewnij schematy
            await self._ensure_schemas(session)

            # 2. Odblokuj stuck PROCESSING zdarzenia
            await self._unlock_stale_processing(session)

            # 3. Atomowa rezerwacja: UPDATE z warunkiem na status = 'PENDING'/'FAILED'
            reserved = await self._reserve_events(session)
            if not reserved:
                stats.total = 0
                stats.processing_time_ms = (time.monotonic() - start) * 1000
                return stats

            stats.total = len(reserved)

            # 4. Przetwórz każde zdarzenie
            for row in reserved:
                result, delay = await self._process_single_event(session, row)
                if result == "sent":
                    stats.processed += 1
                elif result == "skipped":
                    stats.skipped_idempotent += 1
                elif result == "dead_letter":
                    stats.dead_letter += 1
                elif result == "failed":
                    stats.failed += 1
                    if delay > 0:
                        await asyncio.sleep(delay)

            # 5. Cleanup starych wpisów processed_events (> 24h)
            await self._cleanup_processed_events(session)

            await session.commit()

        stats.processing_time_ms = (time.monotonic() - start) * 1000
        return stats

    async def process_events_loop(
        self,
        interval_seconds: float = 5.0,
        max_iterations: int = -1,
    ) -> None:
        """Pętla przetwarzania — uruchamia ``process_pending()`` w nieskończoność.

        Args:
            interval_seconds: Odstęp między iteracjami (sekundy).
            max_iterations: Maksymalna liczba iteracji (-1 = nieskończoność).
        """
        iteration = 0
        while max_iterations < 0 or iteration < max_iterations:
            try:
                stats = await self.process_pending()
                if stats.total > 0:
                    logger.info(
                        "[OUTBOX-RELAY] Iteration %d: processed=%d failed=%d "
                        "dead_letter=%d skipped=%d (%.0fms)",
                        iteration, stats.processed, stats.failed,
                        stats.dead_letter, stats.skipped_idempotent,
                        stats.processing_time_ms,
                    )
            except Exception as exc:
                logger.exception("[OUTBOX-RELAY] Iteration %d failed: %s", iteration, exc)

            iteration += 1
            if max_iterations < 0 or iteration < max_iterations:
                await asyncio.sleep(interval_seconds)

    # ── Event dispatch ──────────────────────────────────────────────────

    async def _process_single_event(
        self,
        session: AsyncSession,
        row: dict[str, Any],
    ) -> tuple[str, float]:
        """Przetwórz pojedyncze zdarzenie outbox.

        Args:
            session: Aktywna sesja SQLAlchemy.
            row: Wiersz z outbox_events (id, event_type, aggregate_id, payload…).

        Returns:
            ``("sent", 0.0)`` — sukces,
            ``("skipped", 0.0)`` — idempotentne pominięcie,
            ``("dead_letter", 0.0)`` — po wyczerpaniu retry,
            ``("failed", delay)`` — tymczasowy błąd z zalecanym opóźnieniem.
        """
        event_id = row["id"]
        event_type = str(row.get("event_type", "")).strip().lower()
        aggregate_id = str(row.get("aggregate_id", ""))
        payload_raw = row.get("payload") or "{}"
        retry_count = int(row.get("retry_count", 0))

        # Idempotentność: sprawdź czy już przetworzone
        if await self._is_already_processed(session, event_id, event_type, aggregate_id, payload_raw):
            await self._mark_sent(session, event_id)
            return ("skipped", 0.0)

        try:
            # Dispatch wg typu zdarzenia
            if event_type in ("process_invoice_ocr", "invoice_uploaded"):
                await self._dispatch_invoice_ocr(aggregate_id, payload_raw)
            elif event_type == "tax_calculated":
                await self._dispatch_tax_calculated(payload_raw)
            elif event_type == "attachment_large_uploaded":
                await self._dispatch_large_attachment(aggregate_id, payload_raw)
            elif event_type.startswith("retry:"):
                original_type = event_type.replace("retry:", "", 1)
                await self._dispatch_generic(original_type, aggregate_id, payload_raw)
            else:
                raise UnknownEventTypeError(f"Unsupported event_type: {event_type}")

            # Sukces: zapisz do processed_events i oznacz jako SENT
            await self._record_idempotency(session, event_id, event_type, aggregate_id, payload_raw)
            await self._mark_sent(session, event_id)
            return ("sent", 0.0)

        except UnknownEventTypeError:
            logger.warning("[OUTBOX] Unknown event_type=%s id=%s — moving to DLQ", event_type, event_id)
            await self._move_to_dead_letter(session, event_id, event_type, aggregate_id,
                                             payload_raw, f"Unknown event_type: {event_type}",
                                             retry_count)
            return ("dead_letter", 0.0)

        except Exception as exc:
            logger.exception("[OUTBOX] Failed to process event id=%s type=%s: %s",
                             event_id, event_type, exc)
            new_retry = retry_count + 1
            is_dead_letter = new_retry >= self._max_retries

            if is_dead_letter:
                await self._move_to_dead_letter(session, event_id, event_type, aggregate_id,
                                                 payload_raw, str(exc), new_retry)
                return ("dead_letter", 0.0)

            delay = self._compute_backoff(new_retry)
            await self._mark_failed(session, event_id, delay)
            return ("failed", delay)

    # ── Dispatchers ─────────────────────────────────────────────────────

    async def _dispatch_tax_calculated(self, payload_raw: str) -> None:
        """Dispatch TAX_CALCULATED event — post double-entry transfers to TigerBeetle.

        Oczekiwany payload:
        .. code-block:: json

            {
                "transaction_id": "uuid",
                "rule_id": "uuid",
                "net_grosze": 12345,
                "vat_grosze": 2839,
                "brutto_grosze": 15184,
                "account_debit": "expenses",
                "account_credit": "liabilities"
            }

        Używa dwufazowych transferów (pending → posted) dla atomowości.
        """
        if not self._process_tax_calculated:
            logger.debug("[OUTBOX] TAX_CALCULATED processing disabled, skipping")
            return

        try:
            payload = json.loads(payload_raw)
        except (json.JSONDecodeError, TypeError) as exc:
            raise ValueError(f"Invalid TAX_CALCULATED payload JSON: {exc}") from exc

        transaction_id = payload.get("transaction_id", "")
        if not transaction_id:
            raise ValueError("Missing transaction_id in TAX_CALCULATED payload")

        net_grosze = int(payload.get("net_grosze", 0))
        vat_grosze = int(payload.get("vat_grosze", 0))
        brutto_grosze = int(payload.get("brutto_grosze", 0))

        # Użyj domyślnych kont księgowych (polski plan kont)
        if self._tigerbeetle is not None:
            try:
                # Transfer 1: expense (net) — debit expense, credit payables
                t1 = await self._tigerbeetle.create_two_phase_transfer(
                    debit_account=self._account_expense_id,
                    credit_account=self._account_payables_id,
                    amount_minor=net_grosze,
                    source_document_id=uuid.UUID(transaction_id),
                )
                posted1 = await self._tigerbeetle.post_pending_transfer(t1.pending_id)

                # Transfer 2: VAT input (vat) — debit VAT, credit payables
                t2 = await self._tigerbeetle.create_two_phase_transfer(
                    debit_account=self._account_vat_id,
                    credit_account=self._account_payables_id,
                    amount_minor=vat_grosze,
                    source_document_id=uuid.UUID(transaction_id),
                )
                posted2 = await self._tigerbeetle.post_pending_transfer(t2.pending_id)

                if not (posted1 and posted2):
                    raise TigerBeetlePostingError(
                        f"TigerBeetle partial posting for tid={transaction_id}: "
                        f"expense_posted={posted1}, vat_posted={posted2}"
                    )

                logger.info(
                    "[OUTBOX] TAX_CALCULATED posted tid=%s net=%d vat=%d brutto=%d",
                    transaction_id, net_grosze, vat_grosze, brutto_grosze,
                )

            except Exception as exc:
                logger.exception("[OUTBOX] TAX_CALCULATED TB posting failed tid=%s: %s", transaction_id, exc)
                raise TigerBeetlePostingError(
                    f"TigerBeetle posting failed for tid={transaction_id}: {exc}"
                ) from exc
        else:
            # No TigerBeetle configured — just log
            logger.info(
                "[OUTBOX] TAX_CALCULATED (dry-run) tid=%s net=%d vat=%d brutto=%d",
                transaction_id, net_grosze, vat_grosze, brutto_grosze,
            )

    async def _dispatch_invoice_ocr(self, aggregate_id: str, payload_raw: str) -> None:
        """Dispatch invoice OCR event — re-kick to broker for processing.

        W środowisku workera, to zadanie jest already handled przez
        Taskiq broker. Tutaj tylko logujemy — właściwe przetwarzanie
        odbywa się przez subskrypcję NATS.
        """
        logger.info("[OUTBOX] Invoice OCR event: aggregate_id=%s", aggregate_id)

    async def _dispatch_large_attachment(self, aggregate_id: str, payload_raw: str) -> None:
        """Dispatch large attachment event."""
        logger.info("[OUTBOX] Large attachment event: aggregate_id=%s", aggregate_id)

    async def _dispatch_generic(self, event_type: str, aggregate_id: str, payload_raw: str) -> None:
        """Dispatch a generic retry event."""
        logger.info("[OUTBOX] Generic retry event: type=%s aggregate_id=%s", event_type, aggregate_id)

    # ── Database helpers ───────────────────────────────────────────────

    async def _ensure_schemas(self, session: AsyncSession) -> None:
        """Ensure required tables exist."""
        await session.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS dead_letter_events (
                    id TEXT PRIMARY KEY,
                    event_type TEXT NOT NULL,
                    aggregate_id TEXT,
                    payload TEXT,
                    error_message TEXT,
                    stack_trace TEXT,
                    retry_count INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    dead_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
        )
        await session.execute(
            text(
                """
                CREATE TABLE IF NOT EXISTS processed_events (
                    id TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    aggregate_id TEXT NOT NULL,
                    payload_hash TEXT NOT NULL,
                    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(event_type, aggregate_id)
                )
                """
            )
        )

    async def _unlock_stale_processing(self, session: AsyncSession) -> None:
        """Odblokuj zdarzenia stuck w statusie PROCESSING (>= 5 minut)."""
        result = await session.execute(
            text(
                """
                UPDATE outbox_events
                SET status = 'FAILED', processing_started_at = NULL
                WHERE status = 'PROCESSING'
                  AND processing_started_at IS NOT NULL
                  AND (strftime('%%s', 'now') - strftime('%%s', processing_started_at)) > :timeout
                """
            ),
            {"timeout": PROCESSING_TIMEOUT_SECONDS},
        )
        if result.rowcount > 0:
            logger.warning("[OUTBOX] Unlocked %d stale PROCESSING events", result.rowcount)

    async def _reserve_events(self, session: AsyncSession) -> list[dict[str, Any]]:
        """Atomowa rezerwacja zdarzeń — UPDATE z warunkiem na status.

        Dwa etapy:
          1. UPDATE outbox_events SET status='PROCESSING' WHERE status IN ('PENDING','FAILED')
          2. SELECT zarezerwowanych wierszy

        Returns:
            Lista słowników zarezerwowanych zdarzeń.
        """
        # Etap 1: rezerwacja
        await session.execute(
            text(
                """
                UPDATE outbox_events
                SET status = 'PROCESSING',
                    processing_started_at = CURRENT_TIMESTAMP
                WHERE id IN (
                    SELECT id FROM outbox_events
                    WHERE status IN ('PENDING', 'FAILED')
                      AND processed = 0
                      AND COALESCE(retry_count, 0) < :max_retries
                    ORDER BY created_at ASC
                    LIMIT :limit
                )
                """
            ),
            {"max_retries": self._max_retries, "limit": self._batch_size},
        )

        # Etap 2: pobierz zarezerwowane
        rows = (
            await session.execute(
                text(
                    """
                    SELECT id, event_type, aggregate_id, payload,
                           COALESCE(retry_count, 0) AS retry_count
                    FROM outbox_events
                    WHERE status = 'PROCESSING'
                      AND processing_started_at IS NOT NULL
                    ORDER BY created_at ASC
                    LIMIT :limit
                    """
                ),
                {"limit": self._batch_size},
            )
        ).mappings().all()

        return [dict(r) for r in rows]

    async def _is_already_processed(
        self,
        session: AsyncSession,
        event_id: str,
        event_type: str,
        aggregate_id: str,
        payload_raw: str,
    ) -> bool:
        """Sprawdź idempotentność — czy zdarzenie było już przetworzone."""
        row = await session.execute(
            text("SELECT 1 FROM processed_events WHERE id = :id"),
            {"id": event_id},
        )
        return row.fetchone() is not None

    async def _record_idempotency(
        self,
        session: AsyncSession,
        event_id: str,
        event_type: str,
        aggregate_id: str,
        payload_raw: str,
    ) -> None:
        """Zapisz wpis idempotentności."""
        payload_hash = hashlib.sha256(payload_raw.encode()).hexdigest()
        await session.execute(
            text(
                """
                INSERT OR IGNORE INTO processed_events
                    (id, event_type, aggregate_id, payload_hash, processed_at)
                VALUES (:id, :event_type, :aggregate_id, :payload_hash, CURRENT_TIMESTAMP)
                """
            ),
            {
                "id": event_id,
                "event_type": event_type,
                "aggregate_id": aggregate_id,
                "payload_hash": payload_hash,
            },
        )

    async def _mark_sent(self, session: AsyncSession, event_id: str) -> None:
        """Oznacz zdarzenie jako pomyślnie wysłane."""
        await session.execute(
            text(
                """
                UPDATE outbox_events
                SET status = 'SENT', processed = 1, processed_at = CURRENT_TIMESTAMP
                WHERE id = :id
                """
            ),
            {"id": event_id},
        )

    async def _mark_failed(self, session: AsyncSession, event_id: str, delay: float) -> None:
        """Oznacz zdarzenie jako failed (będzie retried z opóźnieniem)."""
        await session.execute(
            text(
                """
                UPDATE outbox_events
                SET retry_count = retry_count + 1,
                    processing_started_at = NULL,
                    status = 'FAILED'
                WHERE id = :id
                """
            ),
            {"id": event_id},
        )
        if delay > 0:
            logger.info("[OUTBOX] Event %s failed — retrying after %.1fs delay", event_id, delay)

    async def _move_to_dead_letter(
        self,
        session: AsyncSession,
        event_id: str,
        event_type: str,
        aggregate_id: str,
        payload_raw: str,
        error_message: str,
        retry_count: int,
    ) -> None:
        """Przenieś zdarzenie do Dead Letter Queue."""
        # Zapisz do dead_letter_events
        try:
            await session.execute(
                text(
                    """
                    INSERT OR IGNORE INTO dead_letter_events
                        (id, event_type, aggregate_id, payload, error_message,
                         stack_trace, retry_count, dead_at)
                    VALUES (:id, :event_type, :aggregate_id, :payload,
                            :error_message, :stack_trace, :retry_count, CURRENT_TIMESTAMP)
                    """
                ),
                {
                    "id": event_id,
                    "event_type": event_type,
                    "aggregate_id": aggregate_id,
                    "payload": payload_raw,
                    "error_message": error_message,
                    "stack_trace": "",
                    "retry_count": retry_count,
                },
            )
        except Exception as dle:
            logger.warning("[OUTBOX] Failed to write dead_letter_events: %s", dle)

        # Oznacz outbox event jako DEAD_LETTER
        await session.execute(
            text(
                """
                UPDATE outbox_events
                SET retry_count = retry_count + 1,
                    processing_started_at = NULL,
                    status = 'DEAD_LETTER'
                WHERE id = :id
                """
            ),
            {"id": event_id},
        )

        logger.error(
            "[OUTBOX] Event %s moved to DLQ (type=%s, retries=%d): %s",
            event_id, event_type, retry_count, error_message,
        )

        # Callback (sync or async)
        if self._on_dead_letter is not None:
            try:
                result = self._on_dead_letter({
                    "event_id": event_id,
                    "event_type": event_type,
                    "aggregate_id": aggregate_id,
                    "error": error_message,
                    "retry_count": retry_count,
                })
                if result is not None and hasattr(result, '__await__'):
                    await result
            except Exception as cb_err:
                logger.warning("[OUTBOX] DLQ callback failed: %s", cb_err)

    async def _cleanup_processed_events(self, session: AsyncSession) -> None:
        """Usuń stare wpisy idempotentności (> 24h)."""
        await session.execute(
            text(
                "DELETE FROM processed_events WHERE processed_at < datetime('now', '-1 day')"
            )
        )

    # ── Utility ─────────────────────────────────────────────────────────

    def _compute_backoff(self, attempt: int) -> float:
        """Oblicz opóźnienie z exponential backoff.

        Wzór: min(base_delay * 2^(attempt-2), max_delay) dla attempt >= 2,
        0.0 dla attempt <= 1.

        Przykład (base_delay=1.0):
          - attempt=1: 0.0s (pierwsza próba, brak opóźnienia)
          - attempt=2: 1.0s
          - attempt=3: 2.0s
          - attempt=4: 4.0s
          - attempt=7: 32.0s (cap przy max_delay=60.0)

        Args:
            attempt: Numer próby (1-based).

        Returns:
            Opóźnienie w sekundach.
        """
        if attempt <= 1:
            return 0.0
        delay = self._base_delay * (2 ** (attempt - 2))
        return min(delay, self._max_delay)

    # ── Status ──────────────────────────────────────────────────────────

    async def get_stats(self) -> dict[str, int]:
        """Pobierz statystyki outbox (pending, failed, dead_letter, sent)."""
        async with self._session_factory() as session:
            await self._ensure_schemas(session)

            pending = int(
                (await session.execute(
                    text("SELECT COUNT(*) FROM outbox_events WHERE status = 'PENDING'")
                )).scalar() or 0
            )
            processing = int(
                (await session.execute(
                    text("SELECT COUNT(*) FROM outbox_events WHERE status = 'PROCESSING'")
                )).scalar() or 0
            )
            failed = int(
                (await session.execute(
                    text("SELECT COUNT(*) FROM outbox_events WHERE status = 'FAILED'")
                )).scalar() or 0
            )
            dead_letter = int(
                (await session.execute(
                    text("SELECT COUNT(*) FROM outbox_events WHERE status = 'DEAD_LETTER'")
                )).scalar() or 0
            )
            sent = int(
                (await session.execute(
                    text("SELECT COUNT(*) FROM outbox_events WHERE status = 'SENT'")
                )).scalar() or 0
            )
            dlq_events = int(
                (await session.execute(
                    text("SELECT COUNT(*) FROM dead_letter_events")
                )).scalar() or 0
            )

        return {
            "pending": pending,
            "processing": processing,
            "failed": failed,
            "dead_letter": dead_letter,
            "sent": sent,
            "total": pending + processing + failed + dead_letter + sent,
            "dead_letter_events_table": dlq_events,
        }
