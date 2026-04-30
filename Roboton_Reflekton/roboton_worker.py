from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Protocol

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .ledger_client import TigerBeetleClient
from .models import CompanyProfile, LedgerTransfer, TransferStatus


class TaxClassifierAgent(Protocol):
    async def classify(self, payload: dict, company_policy: dict) -> dict: ...


@dataclass(slots=True)
class SimpleRuleBasedAgent:
    async def classify(self, payload: dict, company_policy: dict) -> dict:
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
    def __init__(self, session: AsyncSession, tb_client: TigerBeetleClient, agent: TaxClassifierAgent) -> None:
        self.session = session
        self.tb_client = tb_client
        self.agent = agent

    async def process_invoice_extracted(self, event: dict) -> LedgerTransfer:
        company_id = uuid.UUID(event["company_id"])
        company = await self.session.scalar(select(CompanyProfile).where(CompanyProfile.id == company_id))
        if company is None:
            raise ValueError("Nie znaleziono CompanyProfile dla eventu.")

        classification = await self.agent.classify(event, company.company_policy)
        ledger_map = company.tigerbeetle_ledger_map
        debit_account = ledger_map[classification["debit_symbol"]]
        credit_account = ledger_map[classification["credit_symbol"]]
        source_document_id = uuid.UUID(classification["source_document_id"])

        pending = await self.tb_client.create_two_phase_transfer(
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
        await self.session.commit()
        await self.session.refresh(transfer)
        return transfer
