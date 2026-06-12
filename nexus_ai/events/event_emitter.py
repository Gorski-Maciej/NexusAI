"""
EventEmitter — warstwa integracji między DecisionEngine/TaxPipeline a Event Sourcing.

Łączy EventStore (append-only log) + JetStreamEventBus (pub/sub) w jeden
punkt wejścia dla emisji eventów domenowych.

Każda emisja:
  1. Tworzy event domenowy (np. DecisionMade, InvoiceSubmitted)
  2. Appenduje do EventStore (niezawodny, lokalny log)
  3. Publikuje przez JetStream (jeśli dostępny — graceful degradation)
  4. Loguje do structlog

Usage:
    emitter = EventEmitter(event_store=store, jetstream=bus)

    # Podczas decyzji:
    await emitter.emit_decision_made(
        invoice_id="inv-123",
        decision="AUTO_POST",
        trust_score=0.95,
        ai_confidence=0.92,
        alpha_vote="AUTO_POST",
        beta_vote="AUTO_POST",
        gamma_vote="SUGGEST",
        decision_pattern="trusted_vendor_low_amount",
        reasoning="Zaufany kontrahent, niska kwota — auto-post",
    )

    # Podczas zatwierdzenia:
    await emitter.emit_invoice_approved(
        invoice_id="inv-123",
        approved_by="system",
        trust_score=0.95,
    )
"""

from __future__ import annotations

from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.events import (
    DecisionMade,
    DecisionOverridden,
    DomainEvent,
    EventStore,
    InvoiceApproved,
    InvoiceBlocked,
    InvoiceCreated,
    InvoicePaid,
    InvoiceRejected,
    InvoiceSubmitted,
    JetStreamEventBus,
)

logger = get_logger("nexus.events.emitter")


class EventEmitter:
    """Emituje eventy domenowe przez EventStore + JetStream.

    Args:
        event_store: Instancja EventStore (append-only log).
        jetstream: Opcjonalna instancja JetStreamEventBus (pub/sub).
    """

    def __init__(
        self,
        event_store: EventStore,
        jetstream: JetStreamEventBus | None = None,
    ) -> None:
        self._store = event_store
        self._jetstream = jetstream

    # ── Decision events ────────────────────────────────────────────────

    async def emit_decision_made(
        self,
        invoice_id: str,
        decision: str,
        trust_score: float = 0.0,
        ai_confidence: float = 0.0,
        alpha_vote: str = "",
        beta_vote: str = "",
        gamma_vote: str = "",
        decision_pattern: str = "",
        reasoning: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """Emituj DecisionMade — decyzja podjęta przez DecisionEngine.

        Tworzy DecisionMade event, appenduje do EventStore i publikuje
        przez JetStream (jeśli dostępny).

        Args:
            invoice_id: ID faktury.
            decision: Decyzja (AUTO_POST | SUGGEST | ASK_USER | BLOCK).
            trust_score: Wynik trust score (0.0-1.0).
            ai_confidence: Pewność AI (0.0-1.0).
            alpha_vote: Głos alfa (np. "AUTO_POST").
            beta_vote: Głos beta.
            gamma_vote: Głos gamma.
            decision_pattern: Wzorzec decyzyjny.
            reasoning: Uzasadnienie decyzji.
            metadata: Dodatkowe metadane.

        Returns:
            event_id wyemitowanego eventu.
        """
        version = self._next_version("decision", invoice_id)
        event = DecisionMade(
            aggregate_id=f"decision:{invoice_id}",
            version=version,
            invoice_id=invoice_id,
            decision=decision,
            trust_score=trust_score,
            ai_confidence=ai_confidence,
            alpha_vote=alpha_vote,
            beta_vote=beta_vote,
            gamma_vote=gamma_vote,
            decision_pattern=decision_pattern,
            reasoning=reasoning,
            metadata=metadata or {},
        )
        return await self._emit("decision", f"decision:{invoice_id}", event)

    async def emit_decision_overridden(
        self,
        invoice_id: str,
        original_decision: str,
        user_decision: str,
        user_id: str,
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """Emituj DecisionOverridden — decyzja nadpisana przez użytkownika.

        Args:
            invoice_id: ID faktury.
            original_decision: Oryginalna decyzja systemu.
            user_decision: Decyzja użytkownika.
            user_id: ID użytkownika.
            metadata: Dodatkowe metadane.

        Returns:
            event_id wyemitowanego eventu.
        """
        version = self._next_version("decision", invoice_id)
        event = DecisionOverridden(
            aggregate_id=f"decision:{invoice_id}",
            version=version,
            invoice_id=invoice_id,
            original_decision=original_decision,
            user_decision=user_decision,
            user_id=user_id,
            metadata=metadata or {},
        )
        return await self._emit("decision", f"decision:{invoice_id}", event)

    # ── Invoice events ─────────────────────────────────────────────────

    async def emit_invoice_created(
        self,
        invoice_id: str,
        number: str = "",
        contractor_nip: str = "",
        contractor_name: str = "",
        amount_net: float = 0.0,
        amount_gross: float = 0.0,
        currency: str = "PLN",
        category: str = "",
        issue_date: str = "",
        file_path: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """Emituj InvoiceCreated — faktura utworzona po OCR."""
        version = self._next_version("invoice", invoice_id)
        event = InvoiceCreated(
            aggregate_id=invoice_id,
            version=version,
            number=number,
            contractor_nip=contractor_nip,
            contractor_name=contractor_name,
            amount_net=amount_net,
            amount_gross=amount_gross,
            currency=currency,
            category=category,
            issue_date=issue_date,
            file_path=file_path,
            metadata=metadata or {},
        )
        return await self._emit("invoice", invoice_id, event)

    async def emit_invoice_submitted(
        self,
        invoice_id: str,
        amount_gross: float = 0.0,
        contractor_nip: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """Emituj InvoiceSubmitted — faktura przesłana do decyzji."""
        version = self._next_version("invoice", invoice_id)
        event = InvoiceSubmitted(
            aggregate_id=invoice_id,
            version=version,
            amount_gross=amount_gross,
            contractor_nip=contractor_nip,
            metadata=metadata or {},
        )
        return await self._emit("invoice", invoice_id, event)

    async def emit_invoice_approved(
        self,
        invoice_id: str,
        approved_by: str = "system",
        trust_score: float = 0.0,
        decision_level: str = "auto",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """Emituj InvoiceApproved — faktura zatwierdzona."""
        version = self._next_version("invoice", invoice_id)
        event = InvoiceApproved(
            aggregate_id=invoice_id,
            version=version,
            approved_by=approved_by,
            trust_score=trust_score,
            decision_level=decision_level,
            metadata=metadata or {},
        )
        return await self._emit("invoice", invoice_id, event)

    async def emit_invoice_rejected(
        self,
        invoice_id: str,
        rejected_by: str = "system",
        reason: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """Emituj InvoiceRejected — faktura odrzucona."""
        version = self._next_version("invoice", invoice_id)
        event = InvoiceRejected(
            aggregate_id=invoice_id,
            version=version,
            rejected_by=rejected_by,
            reason=reason,
            metadata=metadata or {},
        )
        return await self._emit("invoice", invoice_id, event)

    async def emit_invoice_blocked(
        self,
        invoice_id: str,
        blocked_by: str = "risk_guard",
        reason: str = "",
        risk_score: float = 0.0,
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """Emituj InvoiceBlocked — faktura zablokowana przez RiskGuard."""
        version = self._next_version("invoice", invoice_id)
        event = InvoiceBlocked(
            aggregate_id=invoice_id,
            version=version,
            blocked_by=blocked_by,
            reason=reason,
            risk_score=risk_score,
            metadata=metadata or {},
        )
        return await self._emit("invoice", invoice_id, event)

    async def emit_invoice_paid(
        self,
        invoice_id: str,
        amount_gross: float = 0.0,
        paid_at: str = "",
        transaction_id: str = "",
        metadata: dict[str, Any] | None = None,
    ) -> str:
        """Emituj InvoicePaid — faktura opłacona (przez TigerBeetle)."""
        version = self._next_version("invoice", invoice_id)
        event = InvoicePaid(
            aggregate_id=invoice_id,
            version=version,
            amount_gross=amount_gross,
            paid_at=paid_at or pendulum.now("UTC").isoformat(),
            transaction_id=transaction_id,
            metadata=metadata or {},
        )
        return await self._emit("invoice", invoice_id, event)

    # ── Internal methods ───────────────────────────────────────────────

    def _next_version(self, aggregate_type: str, aggregate_id: str) -> int:
        """Pobierz następną wersję dla agregatu."""
        return self._store.get_version(
            aggregate_type=aggregate_type,
            aggregate_id=aggregate_id,
        ) + 1

    async def _emit(
        self,
        aggregate_type: str,
        aggregate_id: str,
        event: DomainEvent,
    ) -> str:
        """Wewnętrzna metoda: append + publish."""
        try:
            # 1. Append do EventStore (append-only log)
            self._store.append_events(
                aggregate_type=aggregate_type,
                aggregate_id=aggregate_id,
                events=[event],
            )
            logger.info(
                "[EVENT-EMITTER] Appended %s:%s version=%d to EventStore",
                event.event_type,
                event.aggregate_id,
                event.version,
            )

            # 2. Publikuj przez JetStream (jeśli dostępny)
            if self._jetstream is not None:
                published = await self._jetstream.publish(event)
                if not published:
                    logger.warning(
                        "[EVENT-EMITTER] JetStream publish failed for %s:%s "
                        "(event stored in EventStore, will be retried)",
                        event.event_type,
                        event.aggregate_id,
                    )
            else:
                logger.debug(
                    "[EVENT-EMITTER] No JetStream bus — event %s:%s stored locally",
                    event.event_type,
                    event.aggregate_id,
                )

            return event.event_id

        except Exception as exc:
            logger.error(
                "[EVENT-EMITTER] Failed to emit %s:%s: %s",
                event.event_type,
                event.aggregate_id,
                exc,
            )
            raise


# ── Global singleton ──────────────────────────────────────────────────────

_default_emitter: EventEmitter | None = None


def get_event_emitter(
    event_store: EventStore | None = None,
    jetstream: JetStreamEventBus | None = None,
) -> EventEmitter:
    """Zwraca globalną instancję EventEmitter (singleton).

    Args:
        event_store: Instancja EventStore. Wymagana przy pierwszym wywołaniu.
        jetstream: Opcjonalna instancja JetStreamEventBus.

    Returns:
        Globalna instancja EventEmitter.
    """
    global _default_emitter
    if _default_emitter is None:
        if event_store is None:
            from nexus_ai.core.config import AppConfig

            config = AppConfig.from_toml()
            from nexus_ai.events.event_store import EventStore

            event_store = EventStore(
                db_path=str(config.base_dir / "app_data" / "events.db")
            )
        _default_emitter = EventEmitter(
            event_store=event_store,
            jetstream=jetstream,
        )
    return _default_emitter
