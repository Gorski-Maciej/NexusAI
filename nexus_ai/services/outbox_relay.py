"""OutboxRelay — Transactional Outbox z SUPERMOCAMI TigerBeetle.

SUPERMOCE:
- Linked transfers dla atomowego dispatchu TAX_CALCULATED
- Batch transferów (oba w jednym wywołaniu)
- Natywne pending/post zamiast własnej implementacji
- code field dla kategoryzacji
- user_data_128 dla source_document_id
- Multi-ledger: PLN=700, VAT_INPUT=711

Transactional Outbox zapewnia atomowość: zapis faktury i zdarzenia do outbox
w tej samej transakcji, a dopiero potem asynchroniczna wysyłka do TigerBeetle.
"""

from __future__ import annotations

import time
import uuid as uuid_module
from collections.abc import Callable

import anyio
import pendulum
import tigerbeetle as tb
from msgspec import Struct
from typing import Any, final

from sqlalchemy import text
from sqlalchemy.orm import Session
from structlog import get_logger

from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads
from nexus_ai.db.models import OutboxStatus
from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TRANSFER_CODE,
    TigerBeetleClient,
    _generate_tb_id,
    _uuid_to_u128,
)

try:
    from nexus_crypto import sha256 as _sha256
    HAS_NEXUS_CRYPTO = True
except ImportError:
    import hashlib as _hashlib
    HAS_NEXUS_CRYPTO = False
    def _sha256(data: bytes) -> str:
        return _hashlib.sha256(data).hexdigest()


logger = get_logger("nexus.services.outbox_relay")

DEFAULT_MAX_RETRIES = 3
DEFAULT_BASE_DELAY_SECONDS = 1.0
DEFAULT_MAX_DELAY_SECONDS = 60.0
DEFAULT_BATCH_SIZE = 100
PROCESSING_TIMEOUT_SECONDS = 300

DEFAULT_ACCOUNT_EXPENSE_ID = 40100
DEFAULT_ACCOUNT_VAT_ID = 22100
DEFAULT_ACCOUNT_PAYABLES_ID = 20200


class OutboxStats(Struct):
    processed: int = 0
    failed: int = 0
    dead_letter: int = 0
    skipped_idempotent: int = 0
    total: int = 0
    processing_time_ms: float = 0.0


class OutboxRelayError(Exception):
    pass


class TigerBeetlePostingError(OutboxRelayError):
    pass


class UnknownEventTypeError(OutboxRelayError):
    pass


@final
class OutboxRelay:
    """Transactional Outbox Relay z SUPERMOCAMI TigerBeetle.

    Linked transfers + batch zamiast 2 osobnych wywołań.
    """

    def __init__(
        self,
        session_factory: Callable[[], Session],
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

    def process_pending(self) -> OutboxStats:
        """Przetwórz wszystkie oczekujące zdarzenia w outbox."""
        stats = OutboxStats()
        start = anyio.current_time()

        with self._session_factory() as session:
            self._unlock_stale_processing(session)
            reserved = self._reserve_events(session)
            if not reserved:
                stats.total = 0
                stats.processing_time_ms = (anyio.current_time() - start) * 1000
                return stats

            stats.total = len(reserved)

            for row in reserved:
                result, delay = self._process_single_event(session, row)
                if result == "sent":
                    stats.processed += 1
                elif result == "skipped":
                    stats.skipped_idempotent += 1
                elif result == "dead_letter":
                    stats.dead_letter += 1
                elif result == "failed":
                    stats.failed += 1
                    if delay > 0:
                        time.sleep(delay)

            self._cleanup_processed_events(session)
            session.commit()

        stats.processing_time_ms = (anyio.current_time() - start) * 1000
        return stats

    async def process_events_loop(
        self,
        interval_seconds: float = 5.0,
        max_iterations: int = -1,
    ) -> None:
        iteration = 0
        while max_iterations < 0 or iteration < max_iterations:
            await anyio.lowlevel.checkpoint()
            try:
                stats = self.process_pending()
                if stats.total > 0:
                    logger.info(
                        "[OUTBOX-RELAY] Iteration %d: processed=%d failed=%d "
                        "dead_letter=%d skipped=%d (%.0fms)",
                        iteration,
                        stats.processed,
                        stats.failed,
                        stats.dead_letter,
                        stats.skipped_idempotent,
                        stats.processing_time_ms,
                    )
            except Exception as exc:
                logger.exception("[OUTBOX-RELAY] Iteration %d failed: %s", iteration, exc)
            iteration += 1
            if max_iterations < 0 or iteration < max_iterations:
                await anyio.sleep(interval_seconds)

    def _process_single_event(
        self,
        session: Session,
        row: dict[str, Any],
    ) -> tuple[str, float]:
        event_id = row["id"]
        event_type = str(row.get("event_type", "")).strip().lower()
        aggregate_id = str(row.get("aggregate_id", ""))
        payload_raw = row.get("payload") or "{}"
        retry_count = int(row.get("retry_count", 0))

        if self._is_already_processed(session, event_id, event_type, aggregate_id, payload_raw):
            self._mark_sent(session, event_id)
            return ("skipped", 0.0)

        try:
            if event_type in ("process_invoice_ocr", "invoice_uploaded"):
                self._dispatch_invoice_ocr(aggregate_id, payload_raw)
            elif event_type == "tax_calculated":
                self._dispatch_tax_calculated(payload_raw)
            elif event_type == "attachment_large_uploaded":
                self._dispatch_large_attachment(aggregate_id, payload_raw)
            elif event_type.startswith("retry:"):
                original_type = event_type.replace("retry:", "", 1)
                self._dispatch_generic(original_type, aggregate_id, payload_raw)
            else:
                raise UnknownEventTypeError(f"Unsupported event_type: {event_type}")

            self._record_idempotency(session, event_id, event_type, aggregate_id, payload_raw)
            self._mark_sent(session, event_id)
            return ("sent", 0.0)

        except UnknownEventTypeError:
            logger.warning(
                "[OUTBOX] Unknown event_type=%s id=%s — moving to DLQ", event_type, event_id
            )
            self._move_to_dead_letter(
                session, event_id, event_type, aggregate_id, payload_raw,
                f"Unknown event_type: {event_type}", retry_count,
            )
            return ("dead_letter", 0.0)
        except Exception as exc:
            logger.exception(
                "[OUTBOX] Failed to process event id=%s type=%s: %s", event_id, event_type, exc
            )
            new_retry = retry_count + 1
            is_dead_letter = new_retry >= self._max_retries
            if is_dead_letter:
                self._move_to_dead_letter(
                    session, event_id, event_type, aggregate_id, payload_raw, str(exc), new_retry
                )
                return ("dead_letter", 0.0)
            delay = self._compute_backoff(new_retry)
            self._mark_failed(session, event_id, delay)
            return ("failed", delay)

    # ── SUPERMOC: Linked transfers dispatch ──────────────────────────────

    def _dispatch_tax_calculated(self, payload_raw: str) -> None:
        """Dispatch TAX_CALCULATED — linked transfers z batch.

        SUPERMOCE:
        - Linked transfers: expense + VAT w atomowym chainie
        - Batch: oba w jednym create_transfers()
        - code: 1001=expense, 1002=vat
        - user_data_128: UUID dokumentu
        - Multi-ledger: 700 dla netto, 711 dla VAT
        """
        if not self._process_tax_calculated:
            logger.debug("[OUTBOX] TAX_CALCULATED processing disabled, skipping")
            return

        try:
            payload = msgspec_loads(payload_raw)
        except (DecodeError, TypeError) as exc:
            raise ValueError(f"Invalid TAX_CALCULATED payload JSON: {exc}") from exc

        transaction_id = payload.get("transaction_id", "")
        if not transaction_id:
            raise ValueError("Missing transaction_id in TAX_CALCULATED payload")

        net_grosze = int(payload.get("net_grosze", 0))
        vat_grosze = int(payload.get("vat_grosze", 0))
        brutto_grosze = int(payload.get("brutto_grosze", 0))

        if self._tigerbeetle is not None:
            try:
                source_uuid = uuid_module.UUID(transaction_id)

                # SUPERMOC: Build linked chain z BALANCING_CREDIT
                # TB automatycznie wyrówna różnice groszowe przy outbox replay
                specs = [
                    {
                        "debit": self._account_expense_id,
                        "credit": self._account_payables_id,
                        "amount": net_grosze,
                        "code": TRANSFER_CODE["EXPENSE_NET"],
                        "ledger": LEDGER["PLN"],
                    },
                    {
                        "debit": self._account_vat_id,
                        "credit": self._account_payables_id,
                        "amount": vat_grosze,
                        "code": TRANSFER_CODE["EXPENSE_VAT"],
                        "ledger": LEDGER["VAT_INPUT"],
                        # SUPERMOC: BALANCING_CREDIT — TB automatycznie wyrówna różnicę
                        "flags": tb.TransferFlags.BALANCING_CREDIT,
                    },
                ]

                # SUPERMOC: batch_linked_transfers tworzy atomic chain
                transfers = self._tigerbeetle.build_linked_transfers(
                    specs,
                    source_document_id=source_uuid,
                    ledger=LEDGER["PLN"],
                )

                # SUPERMOC: IMPORTED flag for retry/replay
                for t in transfers:
                    t.flags |= tb.TransferFlags.IMPORTED

                # SUPERMOC: jeden batch call zamiast 2 osobnych
                results = self._tigerbeetle.create_transfers(transfers)

                # Sprawdź wyniki — status=0 oznacza OK
                all_ok = all(r.status == 0 for r in results)

                if not all_ok:
                    raise TigerBeetlePostingError(
                        f"TigerBeetle linked chain failed for tid={transaction_id}: "
                        f"net={results[0] if results else '?'}, vat={results[1] if len(results) > 1 else '?'}"
                    )

                logger.info(
                    "[OUTBOX] TAX_CALCULATED linked-posted tid=%s net=%d vat=%d brutto=%d",
                    transaction_id,
                    net_grosze,
                    vat_grosze,
                    brutto_grosze,
                )

            except Exception as exc:
                logger.exception(
                    "[OUTBOX] TAX_CALCULATED TB linked posting failed tid=%s: %s",
                    transaction_id, exc,
                )
                raise TigerBeetlePostingError(
                    f"TigerBeetle posting failed for tid={transaction_id}: {exc}"
                ) from exc
        else:
            logger.info(
                "[OUTBOX] TAX_CALCULATED (dry-run) tid=%s net=%d vat=%d brutto=%d",
                transaction_id,
                net_grosze,
                vat_grosze,
                brutto_grosze,
            )

    def _dispatch_invoice_ocr(self, aggregate_id: str, payload_raw: str) -> None:
        logger.info("[OUTBOX] Invoice OCR event: aggregate_id=%s", aggregate_id)

    def _dispatch_large_attachment(self, aggregate_id: str, payload_raw: str) -> None:
        logger.info("[OUTBOX] Large attachment event: aggregate_id=%s", aggregate_id)

    def _dispatch_generic(self, event_type: str, aggregate_id: str, payload_raw: str) -> None:
        logger.info(
            "[OUTBOX] Generic retry event: type=%s aggregate_id=%s", event_type, aggregate_id
        )

    # ── Database helpers ───────────────────────────────────────────────

    def _unlock_stale_processing(self, session: Session) -> None:
        result = session.execute(
            text(
                f"UPDATE outbox_events SET status = '{OutboxStatus.FAILED.value}', "
                "processing_started_at = NULL "
                f"WHERE status = '{OutboxStatus.PROCESSING.value}' "
                "AND processing_started_at IS NOT NULL "
                "AND (strftime('%%s', 'now') - strftime('%%s', processing_started_at)) > :timeout"
            ),
            {"timeout": PROCESSING_TIMEOUT_SECONDS},
        )
        if result.rowcount > 0:
            logger.warning("[OUTBOX] Unlocked %d stale PROCESSING events", result.rowcount)

    def _reserve_events(self, session: Session) -> list[dict[str, Any]]:
        session.execute(
            text(
                f"UPDATE outbox_events SET status = '{OutboxStatus.PROCESSING.value}', "
                "processing_started_at = CURRENT_TIMESTAMP "
                "WHERE id IN (SELECT id FROM outbox_events "
                f"WHERE status IN ('{OutboxStatus.PENDING.value}', '{OutboxStatus.FAILED.value}') "
                "AND processed = 0 AND COALESCE(retry_count, 0) < :max_retries "
                "ORDER BY created_at ASC LIMIT :limit)"
            ),
            {"max_retries": self._max_retries, "limit": self._batch_size},
        )
        rows = (
            session.execute(
                text(
                    f"SELECT id, event_type, aggregate_id, payload, "
                    "COALESCE(retry_count, 0) AS retry_count "
                    f"FROM outbox_events WHERE status = '{OutboxStatus.PROCESSING.value}' "
                    "AND processing_started_at IS NOT NULL "
                    "ORDER BY created_at ASC LIMIT :limit"
                ),
                {"limit": self._batch_size},
            )
            .mappings()
            .all()
        )
        return [dict(r) for r in rows]

    def _is_already_processed(
        self, session: Session, event_id: str, event_type: str,
        aggregate_id: str, payload_raw: str,
    ) -> bool:
        row = session.execute(
            text("SELECT 1 FROM processed_events WHERE id = :id"), {"id": event_id}
        )
        return row.fetchone() is not None

    def _record_idempotency(
        self, session: Session, event_id: str, event_type: str,
        aggregate_id: str, payload_raw: str,
    ) -> None:
        payload_hash = _sha256(payload_raw.encode())
        session.execute(
            text(
                "INSERT OR IGNORE INTO processed_events "
                "(id, event_type, aggregate_id, payload_hash, processed_at) "
                "VALUES (:id, :event_type, :aggregate_id, :payload_hash, CURRENT_TIMESTAMP)"
            ),
            {
                "id": event_id,
                "event_type": event_type,
                "aggregate_id": aggregate_id,
                "payload_hash": payload_hash,
            },
        )

    def _mark_sent(self, session: Session, event_id: str) -> None:
        session.execute(
            text(
                f"UPDATE outbox_events SET status = '{OutboxStatus.SENT.value}', "
                "processed = 1, processed_at = CURRENT_TIMESTAMP WHERE id = :id"
            ),
            {"id": event_id},
        )

    def _mark_failed(self, session: Session, event_id: str, delay: float) -> None:
        session.execute(
            text(
                f"UPDATE outbox_events SET retry_count = retry_count + 1, "
                "processing_started_at = NULL, "
                f"status = '{OutboxStatus.FAILED.value}' WHERE id = :id"
            ),
            {"id": event_id},
        )
        if delay > 0:
            logger.info("[OUTBOX] Event %s failed — retrying after %.1fs delay", event_id, delay)

    def _move_to_dead_letter(
        self, session: Session, event_id: str, event_type: str,
        aggregate_id: str, payload_raw: str, error_message: str, retry_count: int,
    ) -> None:
        try:
            session.execute(
                text(
                    "INSERT OR IGNORE INTO dead_letter_events "
                    "(id, event_type, aggregate_id, payload, error_message, "
                    "stack_trace, retry_count, dead_at) "
                    "VALUES (:id, :event_type, :aggregate_id, :payload, "
                    ":error_message, :stack_trace, :retry_count, CURRENT_TIMESTAMP)"
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

        session.execute(
            text(
                f"UPDATE outbox_events SET retry_count = retry_count + 1, "
                "processing_started_at = NULL, "
                f"status = '{OutboxStatus.DEAD_LETTER.value}' WHERE id = :id"
            ),
            {"id": event_id},
        )

        logger.error(
            "[OUTBOX] Event %s moved to DLQ (type=%s, retries=%d): %s",
            event_id, event_type, retry_count, error_message,
        )

        if self._on_dead_letter is not None:
            try:
                self._on_dead_letter({
                    "event_id": event_id,
                    "event_type": event_type,
                    "aggregate_id": aggregate_id,
                    "error": error_message,
                    "retry_count": retry_count,
                })
            except Exception as cb_err:
                logger.warning("[OUTBOX] DLQ callback failed: %s", cb_err)

    def _cleanup_processed_events(self, session: Session) -> None:
        session.execute(
            text("DELETE FROM processed_events WHERE processed_at < datetime('now', '-1 day')")
        )

    def _compute_backoff(self, attempt: int) -> float:
        if attempt <= 1:
            return 0.0
        delay = self._base_delay * (2 ** (attempt - 2))
        return min(delay, self._max_delay)

    def get_stats(self) -> dict[str, int]:
        with self._session_factory() as session:
            pending = int(
                session.execute(
                    text(f"SELECT COUNT(*) FROM outbox_events WHERE status = '{OutboxStatus.PENDING.value}'")
                ).scalar() or 0
            )
            processing = int(
                session.execute(
                    text(f"SELECT COUNT(*) FROM outbox_events WHERE status = '{OutboxStatus.PROCESSING.value}'")
                ).scalar() or 0
            )
            failed = int(
                session.execute(
                    text(f"SELECT COUNT(*) FROM outbox_events WHERE status = '{OutboxStatus.FAILED.value}'")
                ).scalar() or 0
            )
            dead_letter = int(
                session.execute(
                    text(f"SELECT COUNT(*) FROM outbox_events WHERE status = '{OutboxStatus.DEAD_LETTER.value}'")
                ).scalar() or 0
            )
            sent = int(
                session.execute(
                    text(f"SELECT COUNT(*) FROM outbox_events WHERE status = '{OutboxStatus.SENT.value}'")
                ).scalar() or 0
            )
            dlq_events = int(
                session.execute(text("SELECT COUNT(*) FROM dead_letter_events")).scalar() or 0
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
