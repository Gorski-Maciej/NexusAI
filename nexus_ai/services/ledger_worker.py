"""Ledger worker — przetwarzanie zdarzeń księgowych z natywnymi pending transferami TB.

Zgodnie z audytem (Faza 2.7 + Faza 3):
- Natywne pending transfery TB (flags.pending) zamiast stubowych
- LedgerTransferCache zamiast LedgerTransfer (TB = source of truth)
- code, ledger, user_data_128 dla bogatych metadanych
- get_account_balances() zamiast ręcznego śledzenia sald
"""

from __future__ import annotations

import uuid
from typing import Protocol, final

import pendulum
from sqlmodel import select
from sqlmodel import Session

from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TRANSFER_CODE,
    TigerBeetleClient,
)
from nexus_ai.services.tigerbeetle.models import (
    CompanyProfile,
    FinancialPeriod,
    FinancialPeriodStatus,
    LedgerTransferCache,
)


class PeriodLockedException(Exception):
    pass


class TaxClassifierAgent(Protocol):
    def classify(self, payload: dict, company_policy: dict) -> dict: ...


@final
class SimpleRuleBasedAgent:
    """Prosty agent klasyfikacji — fallback regexowy."""

    def classify(self, payload: dict, company_policy: dict) -> dict:
        amount_minor = int(payload.get("amount_minor", 0))
        mixed_vehicle = bool(payload.get("mixed_vehicle_use", False))
        kup_ratio = 0.75 if mixed_vehicle else 1.0
        return {
            "debit_symbol": payload.get("debit_symbol", "401-01"),
            "credit_symbol": payload.get("credit_symbol", "202"),
            "amount_minor": amount_minor,
            "kup_ratio": kup_ratio,
            "reasoning": "rule-based fallback",
            "source_document_id": payload.get("source_document_id"),
            "contractor_nip": payload.get("contractor_nip", ""),
        }


@final
class LedgerWorker:
    """Worker przetwarzający zdarzenia księgowe z blokadą okresów finansowych.

    SUPERMOCE:
    - Natywne pending transfery TB zamiast stubowych TwoPhaseTransfer
    - LedgerTransferCache jako cache (TB = source of truth)
    - code/ledger/user_data_128 dla każdego transferu
    """

    def __init__(
        self, session: Session, tb_client: TigerBeetleClient, agent: TaxClassifierAgent
    ) -> None:
        self.session = session
        self.tb_client = tb_client
        self.agent = agent

    def _apply_financial_period_lock(self, company_id: uuid.UUID, event: dict) -> dict:
        issue_date = pendulum.parse(str(event["date_of_issue"])).date()
        tax_point_date = pendulum.parse(
            str(event.get("tax_point_date", event["date_of_issue"]))
        ).date()
        period_id = issue_date.format("YYYY-MM")

        period = self.session.scalar(
            select(FinancialPeriod).where(
                FinancialPeriod.company_id == company_id, FinancialPeriod.period_id == period_id
            )
        )
        if period is None or period.status != FinancialPeriodStatus.HARD_CLOSED:
            event.setdefault("posting_date", issue_date.isoformat())
            event.setdefault("tax_point_date", tax_point_date.isoformat())
            return event

        open_period = self.session.scalar(
            select(FinancialPeriod)
            .where(
                FinancialPeriod.company_id == company_id,
                FinancialPeriod.status == FinancialPeriodStatus.OPEN,
            )
            .order_by(FinancialPeriod.period_id.asc())
        )
        if open_period is None:
            raise PeriodLockedException("No OPEN financial period available for HARD_CLOSED shift")

        shifted_date = pendulum.Date.fromisoformat(f"{open_period.period_id}-01")
        event["posting_date"] = shifted_date.isoformat()
        event["tax_point_date"] = shifted_date.isoformat()
        metadata = dict(event.get("metadata", {}))
        metadata["late_submission_shifted"] = True
        metadata["original_period_id"] = period_id
        metadata["shifted_to_period_id"] = open_period.period_id
        event["metadata"] = metadata
        return event

    def process_invoice_extracted(self, event: dict) -> LedgerTransferCache:
        """SUPERMOC: Utwórz natywny pending transfer TB + cache w SQLite.

        Zamiast starego LedgerTransfer z ręcznym statusem, używamy:
        1. ``create_pending_transfer()`` — natywny pending TB
        2. ``LedgerTransferCache`` — tylko cache (TB = source of truth)
        """
        company_id = uuid.UUID(event["company_id"])
        event = self._apply_financial_period_lock(company_id, event)
        company = self.session.scalar(select(CompanyProfile).where(CompanyProfile.id == company_id))
        if company is None:
            raise ValueError("Nie znaleziono CompanyProfile dla eventu.")

        classification = self.agent.classify(event, company.company_policy)
        ledger_data = company.tigerbeetle_ledger_map
        debit_account = int(ledger_data[classification["debit_symbol"]])
        credit_account = int(ledger_data[classification["credit_symbol"]])
        amount_minor = int(classification["amount_minor"])
        source_document_id = uuid.UUID(classification["source_document_id"])

        # SUPERMOC: Natywny pending transfer TB
        # Zamiast TwoPhaseTransfer stuba, używamy TB flags.pending
        # create_pending_transfer zwraca klient-generowany transfer_id
        import uuid as uuid_mod
        timestamp_64 = int(pendulum.now("UTC").timestamp())
        tb_transfer_id = self.tb_client.create_pending_transfer(
            debit_account=debit_account,
            credit_account=credit_account,
            amount_minor=amount_minor,
            source_document_id=source_document_id,
            ledger=LEDGER["PLN"],
            code=TRANSFER_CODE["EXPENSE_NET"],
            user_data_64=timestamp_64,
            timeout=86400,  # 24h timeout dla pending transferu
        )

        if tb_transfer_id is None:
            raise RuntimeError("TigerBeetle pending transfer creation failed")

        classification.setdefault("contractor_nip", event.get("contractor_nip", ""))

        # SUPERMOC: LedgerTransferCache (TB = source of truth)
        # Brak statusu — TB przechowuje prawdziwy stan
        from nexus_ai.core.msgspec_utils import msgspec_dumps
        cache_entry = LedgerTransferCache(
            company_id=str(company_id),
            tb_transfer_id=tb_transfer_id,
            debit_account=debit_account,
            credit_account=credit_account,
            amount_minor=amount_minor,
            source_document_id=source_document_id.hex,
            ledger=LEDGER["PLN"],
            code=TRANSFER_CODE["EXPENSE_NET"],
            meta=msgspec_dumps({"classification": classification}),
        )
        self.session.add(cache_entry)
        self.session.commit()
        self.session.refresh(cache_entry)
        return cache_entry


# Alias dla kompatybilności wstecznej
RobotonWorker = LedgerWorker
