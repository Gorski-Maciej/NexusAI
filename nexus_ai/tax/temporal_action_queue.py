"""
Temporal Action Queue (C2) — Przyszłe zdarzenia podatkowe przez Temporal.io.
================================================================================

Część strategicznego planu 29_JDG_STRATEGIC_IMPROVEMENTS.md.
OPA generuje przyszłe zdarzenia (_future_events) w werdykcie.
Temporal.io wykonuje je w odpowiednim momencie (np. sprawdzenie złych długów
po 90/150 dniach).

Dlaczego Temporal.io, nie Kafka: Temporal został zaprojektowany do trwałego,
gwarantowanego wykonywania akcji z opóźnieniem — workflow może spać miesiącami.
Kafka nie ma natywnego mechanizmu delayed delivery.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any


# ── Future Event Types ────────────────────────────────────────────────────────


class FutureEventType:
    """Typy przyszłych zdarzeń podatkowych."""
    CHECK_BAD_DEBT_CREDITOR = "CHECK_BAD_DEBT_CREDITOR"      # 150 dni (wierzyciel)
    CHECK_BAD_DEBT_DEBTOR = "CHECK_BAD_DEBT_DEBTOR"          # 90 dni (dłużnik)
    CHECK_STATUTE_OF_LIMITATIONS = "CHECK_STATUTE"            # 5 lat
    REMIND_DECLARATION = "REMIND_DECLARATION"                 # Termin deklaracji
    REMIND_ZUS_PAYMENT = "REMIND_ZUS_PAYMENT"                 # Termin ZUS
    REMIND_TAX_PAYMENT = "REMIND_TAX_PAYMENT"                 # Termin podatku
    REVALUATE_AFTER_LAW_CHANGE = "REVALUATE_AFTER_LAW_CHANGE"  # Po zmianie prawa
    ANNUAL_HEALTH_RECONCILIATION = "ANNUAL_HEALTH_RECONCILIATION"  # Roczne rozliczenie


# ── Future Event ──────────────────────────────────────────────────────────────


@dataclass
class FutureEvent:
    """Pojedyncze przyszłe zdarzenie wygenerowane przez OPA."""
    event_type: str
    trigger_date: str  # ISO format date
    invoice_id: str
    rule_id: str
    context: dict[str, Any] = field(default_factory=dict)


# ── Future Event Dispatcher ───────────────────────────────────────────────────


class FutureEventDispatcher:
    """Wysyła przyszłe zdarzenia z werdyktu OPA do Temporal.io.

    Działa jako bridge między stateless OPA a stateful Temporal.io.
    Odczytuje _future_events z werdyktu i startuje Temporal workflowy.
    """

    def __init__(self) -> None:
        self._temporal_client = None  # Inicjalizowane przy starcie

    async def initialize(self, temporal_host: str = "localhost:7233") -> None:
        """Inicjalizuje klienta Temporal.io."""
        try:
            # Temporal SDK — opcjonalna zależność
            from temporalio.client import Client
            self._temporal_client = await Client.connect(temporal_host)
        except ImportError:
            import structlog
            logger = structlog.get_logger()
            logger.warning("temporalio_not_installed",
                           message="Temporal SDK not installed. "
                                   "Future events will be logged only.")

    async def dispatch_events(
        self, verdict: dict[str, Any]
    ) -> list[dict[str, Any]]:
        """Wysyła przyszłe zdarzenia z werdyktu do Temporal.io.

        Returns:
            Lista zdarzeń, które zostały zaplanowane.
        """
        events = verdict.get("_future_events", [])
        if not events:
            return []

        dispatched: list[dict[str, Any]] = []

        for event_data in events:
            event = FutureEvent(
                event_type=event_data.get("type", "UNKNOWN"),
                trigger_date=event_data.get("trigger_date", ""),
                invoice_id=event_data.get("invoice_id", ""),
                rule_id=event_data.get("rule_id", ""),
                context=event_data.get("context", {}),
            )

            if self._temporal_client is not None:
                await self._start_temporal_workflow(event)
            else:
                self._log_future_event(event)

            dispatched.append({
                "event_type": event.event_type,
                "trigger_date": event.trigger_date,
                "invoice_id": event.invoice_id,
                "rule_id": event.rule_id,
            })

        return dispatched

    async def _start_temporal_workflow(self, event: FutureEvent) -> None:
        """Uruchamia Temporal workflow dla przyszłego zdarzenia."""
        if self._temporal_client is None:
            return

        trigger_dt = datetime.fromisoformat(event.trigger_date)
        delay = trigger_dt - datetime.now()

        if delay.total_seconds() <= 0:
            return  # Zdarzenie już przeterminowane

        try:
            await self._temporal_client.start_workflow(
                workflow="ReEvaluateInvoiceWorkflow",
                args=[event.invoice_id, event.rule_id, event.context],
                id=f"reeval-{event.invoice_id}-{event.rule_id}",
                task_queue="tax-future-events",
                start_delay=delay,
            )
        except Exception:
            import structlog
            logger = structlog.get_logger()
            logger.error("temporal_dispatch_failed",
                         event_type=event.event_type,
                         invoice_id=event.invoice_id)

    @staticmethod
    def _log_future_event(event: FutureEvent) -> None:
        """Loguje przyszłe zdarzenie (fallback gdy Temporal niedostępny)."""
        import structlog
        logger = structlog.get_logger()
        logger.info("future_event_scheduled",
                    event_type=event.event_type,
                    trigger_date=event.trigger_date,
                    invoice_id=event.invoice_id,
                    rule_id=event.rule_id)


# ── OPA Integration Helper ────────────────────────────────────────────────────

# Ten fragment pokazuje jak reguły OPA generują _future_events.
# Jest to pseudokod do integracji w .rego.

OPA_FUTURE_EVENTS_TEMPLATE = """
# W Rego — przykład dla P184 (złe długi — dłużnik):
bad_debt_debtor_correction_mandatory := verdict {
    input.invoice.is_paid == false
    input.invoice.days_overdue >= 90

    merged := object.union(verdict, {
        "vat_correction_mandatory": true,
        "_future_events": [
            {
                "type": "CHECK_BAD_DEBT_CREDITOR",
                "trigger_date": concat("", [
                    substring(input.invoice.due_date, 0, 10),
                    "+150d"
                ]),
                "invoice_id": input.invoice.id,
                "rule_id": "jdg.vat.bad_debt_creditor",
            }
        ]
    })
}
"""
