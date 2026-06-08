from __future__ import annotations

from dataclasses import dataclass

from litestar import Litestar, get, post
from litestar.di import Provide
from litestar.response import ServerSentEvent
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy import create_engine

from nexus_ai.core.config import AppConfig

from .decision_trees import CompanyDecisionTree
from .ledger_client import TigerBeetleClient
from .ledger_initializer import LedgerInitializer
from .models import CompanyProfile, LegalForm, TaxForm, TaxPolicy
from .reconciliation_engine import AlertHub, ReconciliationEngine

# Zgodnie z aa3fvcx.txt: SQLite (sync) zamiast PostgreSQL / aiosqlite
# Python 3.13t (free-threaded): brak GIL — sync engine działa bezpiecznie z wielu wątków
_config = AppConfig()
_db_path = _config.sqlite_path.as_posix()
engine = create_engine(f"sqlite:///{_db_path}", echo=False)
SessionLocal = sessionmaker(engine, expire_on_commit=False)
tb_client = TigerBeetleClient()
alert_hub = AlertHub()
reconciliation_engine = ReconciliationEngine(session_factory=SessionLocal, tb_client=tb_client, alert_hub=alert_hub)


def provide_session() -> Session:
    with SessionLocal() as session:
        yield session


@dataclass
class CompanyCreateRequest:
    name: str
    nip: str
    legal_form: LegalForm
    tax_form: TaxForm
    ksef_token: str
    vat_proportion: float = 1.0


@dataclass
class ApproveTransferRequest:
    pending_id: int


@post("/company/create")
async def create_company(data: CompanyCreateRequest, session: AsyncSession) -> dict:
    if not data.ksef_token.strip():
        raise ValueError("Token KSeF jest wymagany.")

    tree = CompanyDecisionTree(
        legal_form=data.legal_form,
        tax_form=data.tax_form,
        ksef_active=True,
        vat_proportion=data.vat_proportion,
    )
    decision_tree, policy = tree.validate_and_build()

    ledger = await LedgerInitializer(tb_client=tb_client).configure_ledger(
        legal_form=data.legal_form,
        tax_form=data.tax_form,
    )

    company = CompanyProfile(
        name=data.name,
        nip=data.nip,
        legal_form=data.legal_form,
        ksef_active=True,
        ksef_token=data.ksef_token,
        vat_proportion=data.vat_proportion,
        tigerbeetle_ledger_map=ledger,
        company_policy={"decision_tree": decision_tree, "tax_policy": policy},
    )
    session.add(company)
    await session.flush()

    tax_policy = TaxPolicy(
        company_id=company.id,
        tax_form=data.tax_form,
        pit_costs_enabled=bool(policy.get("pit_costs_enabled", True)),
        requires_full_ledger=bool(policy.get("requires_full_ledger", False)),
    )
    session.add(tax_policy)
    await session.commit()

    return {"company_id": str(company.id), "ledger_accounts": len(ledger)}


@post("/ledger/approve-transfer")
async def approve_transfer(data: ApproveTransferRequest) -> dict:
    approved = await tb_client.post_pending_transfer(data.pending_id)
    return {"pending_id": data.pending_id, "approved": approved}


@get("/alerts/missing-invoice/stream")
async def missing_invoice_alert_stream() -> ServerSentEvent:
    async def stream() -> object:
        async for event in alert_hub.subscribe():
            yield event

    return ServerSentEvent(stream())


async def _on_startup() -> None:
    await reconciliation_engine.start()


async def _on_shutdown() -> None:
    await reconciliation_engine.stop()


app = Litestar(
    route_handlers=[create_company, approve_transfer, missing_invoice_alert_stream],
    dependencies={"session": Provide(provide_session)},
    on_startup=[_on_startup],
    on_shutdown=[_on_shutdown],
)
