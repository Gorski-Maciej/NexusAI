from __future__ import annotations

import uuid
from datetime import date
from dataclasses import dataclass
from typing import Protocol

from sqlalchemy import select
from sqlalchemy.orm import Session

from .ledger_client import TigerBeetleClient
from .models import (
    CompanyProfile,
    FinancialPeriod,
    FinancialPeriodStatus,
    LedgerTransfer,
    TransferStatus,
)


class PeriodLockedException(Exception):  # noqa: N818
    pass


class TaxClassifierAgent(Protocol):
    def classify(self, payload: dict, company_policy: dict) -> dict: ...


@dataclass(slots=True)
class SimpleRuleBasedAgent:
    def classify(self, payload: dict, company_policy: dict) -> dict:
        amount_minor = int(payload.get("amount_minor", 0))
        mixed_vehicle = bool(payload.get("mixed_vehicle_use", False))
        kup_ratio = 0.75 if mixed_vehicle else 1.0
        return {
            "debit_symbol": payload.get("debit_symbol", "401-01"),
            "credit_symbol": payload.get("credit_symbol", "202"),
            "amount_minor": amount_minor,
            "kup_ratio": kup_ratio,
            "reasoning": "rule-based fallback for CrewAI",
            "source_document_id": payload.get("source_document_id"),
            "contractor_nip": payload.get("contractor_nip", ""),
        }


class RobotonWorker:
    def __init__(self, session: Session, tb_client: TigerBeetleClient, agent: TaxClassifierAgent) -> None:
        self.session = session
        self.tb_client = tb_client
        self.agent = agent

    def _apply_financial_period_lock(self, company_id: uuid.UUID, event: dict) -> dict:
        issue_date = date.fromisoformat(str(event["date_of_issue"]))
        tax_point_date = date.fromisoformat(str(event.get("tax_point_date", event["date_of_issue"])))
        period_id = issue_date.format("YYYY-MM")

        period = self.session.scalar(
            select(FinancialPeriod).where(FinancialPeriod.company_id == company_id, FinancialPeriod.period_id == period_id)
        )
        if period is None or period.status != FinancialPeriodStatus.HARD_CLOSED:
            event.setdefault("posting_date", issue_date.isoformat())
            event.setdefault("tax_point_date", tax_point_date.isoformat())
            return event

        open_period = self.session.scalar(
            select(FinancialPeriod)
            .where(FinancialPeriod.company_id == company_id, FinancialPeriod.status == FinancialPeriodStatus.OPEN)
            .order_by(FinancialPeriod.period_id.asc())
        )
        if open_period is None:
            raise PeriodLockedException("No OPEN financial period available for HARD_CLOSED shift")

        shifted_date = date.fromisoformat(f"{open_period.period_id}-01")
        event["posting_date"] = shifted_date.isoformat()
        event["tax_point_date"] = shifted_date.isoformat()
        metadata = dict(event.get("metadata", {}))
        metadata["late_submission_shifted"] = True
        metadata["original_period_id"] = period_id
        metadata["shifted_to_period_id"] = open_period.period_id
        event["metadata"] = metadata
        return event

    def process_invoice_extracted(self, event: dict) -> LedgerTransfer:
        company_id = uuid.UUID(event["company_id"])
        event = self._apply_financial_period_lock(company_id, event)
        company = self.session.scalar(select(CompanyProfile).where(CompanyProfile.id == company_id))
        if company is None:
            raise ValueError("Nie znaleziono CompanyProfile dla eventu.")

        classification = self.agent.classify(event, company.company_policy)
        ledger_map = company.tigerbeetle_ledger_map
        debit_account = ledger_map[classification["debit_symbol"]]
        credit_account = ledger_map[classification["credit_symbol"]]
        source_document_id = uuid.UUID(classification["source_document_id"])

        pending = self.tb_client.create_two_phase_transfer(
            debit_account=debit_account,
            credit_account=credit_account,
            amount_minor=int(classification["amount_minor"]),
            source_document_id=source_document_id,
        )

        classification.setdefault("contractor_nip", event.get("contractor_nip", ""))

        transfer = LedgerTransfer(
            company_id=company_id,
            source_account=debit_account,
            target_account=credit_account,
            amount_minor=int(classification["amount_minor"]),
            source_document_id=source_document_id,
            status=TransferStatus.PENDING,
            meta={"tb_pending_id": pending.pending_id, "classification": classification},
        )
        self.session.add(transfer)
        self.session.commit()
        self.session.refresh(transfer)
        return transfer
