"""FactsAggregator — RAG layer collecting data from SQLite, DuckDB, and sqlite-vec for decision prompts."""
from __future__ import annotations

from collections.abc import Callable
from typing import Any, final

import anyio
from msgspec import Struct, field
from sqlmodel import Session, select, text

from nexus_ai.core.cache import get_cache
from nexus_ai.core.embeddings import EmbeddingService, get_embedding_service
from nexus_ai.core.logger import get_logger
from nexus_ai.services.decision_logger import CorrectionStats, GlobalDecision, TrustTrend

_few_shot_nexus = get_cache(default_ttl=300)
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import Invoice, InvoiceStatus
from nexus_ai.db.vector_store import VectorStore
from nexus_ai.services.decision_logger import DecisionLogger
from nexus_ai.services.rule_store import RuleStore
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient, TigerBeetleMapper
from nexus_ai.services.vendor_intelligence import VendorAnalyst

logger = get_logger(__name__)


@final
class FactSheet(Struct):
    """Structured fact sheet with data from all databases, ready for decision prompt injection."""

    invoice_id: str = ""
    contractor_nip: str = ""
    contractor_name: str = ""
    amount_net: float = 0.0
    amount_gross: float = 0.0
    category: str = ""
    issue_date: str = ""

    contractor_known: bool = False
    contractor_invoice_count: int = 0
    contractor_trust_score: float = 0.5
    contractor_vat_status: str = "unknown"
    recent_invoices: list[dict[str, Any]] = field(default_factory=list)
    user_correction_patterns: list[dict[str, Any]] = field(default_factory=list)

    trust_score_trend: TrustTrend = field(default_factory=TrustTrend)
    active_tax_rules: list[dict[str, Any]] = field(default_factory=list)
    vendor_intelligence: str = ""
    correction_stats: CorrectionStats = field(default_factory=CorrectionStats)

    similar_invoices: list[dict[str, Any]] = field(default_factory=list)

    ledger_available: bool = False
    ledger_accounts: dict[str, float] = field(default_factory=dict)

    global_recent_decisions: list[GlobalDecision] = field(default_factory=list)
    globally_similar_cases: list[GlobalDecision] = field(default_factory=list)

    ledger_total_turnover: float = 0.0
    ledger_recent_transfers: list[dict[str, Any]] = field(default_factory=list)

    sources_available: dict[str, bool] = field(default_factory=dict)
    build_duration_ms: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        return {"invoice": {"id": self.invoice_id, "contractor_nip": self.contractor_nip, "contractor_name": self.contractor_name,
                            "amount_net": self.amount_net, "amount_gross": self.amount_gross, "category": self.category, "issue_date": self.issue_date},
                "contractor": {"known": self.contractor_known, "invoice_count": self.contractor_invoice_count, "trust_score": self.contractor_trust_score, "vat_status": self.contractor_vat_status},
                "history": {"recent_invoices": self.recent_invoices[:5], "trust_score_trend": self.trust_score_trend, "user_correction_patterns": self.user_correction_patterns[:3]},
                "rules": {"active_tax_rules": self.active_tax_rules[:10], "vendor_intelligence": self.vendor_intelligence},
                "similar": {"invoices": self.similar_invoices[:3]},
                "ledger": {"available": self.ledger_available, "accounts": self.ledger_accounts, "total_turnover": self.ledger_total_turnover, "recent_transfers": self.ledger_recent_transfers[:3]},
                "sources": self.sources_available}

    def to_prompt_section(self) -> str:
        """Convert FactSheet to a prompt section string for AI model consumption."""
        lines = ["=== ARKUSZ FAKTÓW (FactsAggregator) ===", ""]
        src = self.sources_available
        lines.append(f"Źródła danych: SQLite={'✓' if src.get('sqlite') else '✗'}, DuckDB={'✓' if src.get('duckdb') else '✗'}, sqlite-vec={'✓' if src.get('vector_store') else '✗'}")
        lines.append("")
        lines.append(f"Faktura #{self.invoice_id}")
        lines.append(f"  Kontrahent: {self.contractor_name} (NIP: {self.contractor_nip})")
        lines.append(f"  Kwota netto: {self.amount_net:.2f} PLN")
        lines.append(f"  Kwota brutto: {self.amount_gross:.2f} PLN")
        lines.append(f"  Kategoria: {self.category}")
        lines.append(f"  Data wystawienia: {self.issue_date}\n")
        known = "znany" if self.contractor_known else "nowy"
        lines.append(f"Kontrahent: {known}")
        lines.append(f"  Liczba faktur: {self.contractor_invoice_count}, Trust score: {self.contractor_trust_score:.2f}, VAT: {self.contractor_vat_status}\n")
        if self.trust_score_trend.known:
            t = self.trust_score_trend
            lines.append(f"Trend trust score (30d): avg={t.avg_trust:.4f}, trend={t.trend}, records={t.records}\n")
        for inv in self.similar_invoices[:3]:
            lines.append(f"Podobna: ID={inv.get('id', '?')} kwota={inv.get('amount_gross', '?')} (dist={inv.get('_distance', 0):.4f})")
        if self.ledger_available:
            lines.append(f"Ledger: {len(self.ledger_accounts)} accounts, turnover={self.ledger_total_turnover:.2f} PLN")
        for rule in self.active_tax_rules[:5]:
            lines.append(f"Reguła: {rule.get('description_template', rule.get('condition_sql', '?'))}")
        for c in self.user_correction_patterns[:3]:
            lines.append(f"Korekta: {c.get('description', '')}")
        return "\n".join(lines)

    def build_few_shot_examples(self, max_examples: int = 3) -> str:
        """Build dynamic few-shot examples from historical decisions with NexusCache support."""
        data_hash = hash((str(self.recent_invoices), str(self.similar_invoices), str(self.globally_similar_cases),
                          str(self.global_recent_decisions), str(self.trust_score_trend.decisions_breakdown),
                          str(self.user_correction_patterns)))
        cache_key = f"few_shot:{data_hash}:{max_examples}"
        cached = _few_shot_nexus.get_sync(cache_key)
        if cached is not None:
            return cached

        examples: list[str] = []
        similar_count = min(len(self.similar_invoices), max_examples)
        remaining = max_examples - similar_count

        decision_map = {InvoiceStatus.PAID.value: "AUTO_POST", InvoiceStatus.APPROVED.value: "AUTO_POST",
                        InvoiceStatus.SUGGESTED.value: "SUGGEST", InvoiceStatus.PENDING_REVIEW.value: "ASK_USER",
                        InvoiceStatus.BLOCKED.value: "BLOCK"}

        for inv in self.similar_invoices[:similar_count]:
            d = inv.get("decision")
            if d and d.get("final_decision"):
                entry = (f"[Podobna faktura (dist={inv.get('_distance', 0):.4f})]\n"
                         f"  Kwota: {inv.get('amount_gross', '?')}, Kategoria: {inv.get('category', '?')}\n"
                         f"  Decyzja: {d['final_decision']}, Trust: {float(d.get('trust_score', 0)):.2f}")
                if d.get("decision_level"): entry += f"\n  Level: {d['decision_level']}"
                if d.get("decision_pattern"): entry += f"\n  Pattern: {d['decision_pattern']}"
                if d.get("user_correction"): entry += f"\n  Korekta: {d['user_correction']}"
                examples.append(entry)
            else:
                status = str(inv.get("status", "?")).upper()
                examples.append(f"[Podobna faktura (dist={inv.get('_distance', 0):.4f})]\n  Kwota: {inv.get('amount_gross', '?')}\n  Decyzja: {decision_map.get(status, 'SUGGEST')}, Status: {status}")

        for inv in self.globally_similar_cases[:remaining]:
            examples.append(f"[Globalny przypadek] NIP={inv.contractor_nip}, Kat={inv.category}, Decyzja={inv.decision}, Trust={inv.trust_score:.2f}")
            remaining -= 1
        for inv in self.global_recent_decisions[:remaining]:
            examples.append(f"[Globalny] NIP={inv.contractor_nip}, Kat={inv.category}, Decyzja={inv.decision}, Trust={inv.trust_score:.2f}")
            remaining -= 1
        for inv in self.recent_invoices[:remaining]:
            status = str(inv.get("status", "?")).upper()
            examples.append(f"[Historyczna] Kwota={inv.get('amount_gross', 0):.2f}, Kat={inv.get('category', '?')}, Decyzja={decision_map.get(status, 'SUGGEST')}, Status={status}")

        if self.trust_score_trend.known and self.trust_score_trend.decisions_breakdown:
            bd = self.trust_score_trend.decisions_breakdown
            examples.append(f"[Wzorzec decyzyjny] Liczba={self.trust_score_trend.records}, Rozkład={', '.join(f'{k}: {v}' for k, v in sorted(bd.items(), key=lambda x: -x[1]))}")
        if self.user_correction_patterns[:2]:
            examples.append("[Korekty]\n" + "\n".join(f"  - {c.get('description', '')}" for c in self.user_correction_patterns[:2]))

        if not examples:
            _few_shot_nexus.set_sync(cache_key, "", ttl=300)
            return ""
        result = "=== PRZYKŁADY FEW-SHOT ===" + "".join(f"\n\nPrzykład {i}:\n{e}" for i, e in enumerate(examples, 1))
        _few_shot_nexus.set_sync(cache_key, result, ttl=300)
        return result


@final
class FactsAggregator:
    """Agregator Faktów — warstwa RAG przed decyzją. Zbiera dane z SQLite, DuckDB, sqlite-vec i TigerBeetle.

    Wynik (FactSheet) dołączany do promptu modelu jako sekcja === ARKUSZ FAKTÓW ===.
    """
    __slots__ = ('_cache', '_decision_logger', '_duckdb', '_embedding_service', '_rule_store', '_session_factory', '_tigerbeetle', '_vector_store', '_vendor_analyst')

    def __init__(self, duckdb: DuckDBManager | None = None, vector_store: VectorStore | None = None,
                 embedding_service: EmbeddingService | None = None, db_session_factory: Callable[[], Session] | None = None,
                 decision_logger: DecisionLogger | None = None, rule_store: RuleStore | None = None,
                 vendor_analyst: VendorAnalyst | None = None, tigerbeetle_client: TigerBeetleClient | None = None) -> None:
        self._duckdb = duckdb
        self._vector_store = vector_store
        self._embedding_service = embedding_service or get_embedding_service()
        self._session_factory = db_session_factory
        self._decision_logger = decision_logger
        self._rule_store = rule_store
        self._vendor_analyst = vendor_analyst
        self._tigerbeetle = tigerbeetle_client
        self._cache = get_cache(default_ttl=300)

    async def build(self, invoice_data: dict[str, Any]) -> FactSheet:
        """Zbuduj arkusz faktów ze wszystkich źródeł danych równolegle przez TaskGroup."""
        t0 = anyio.current_time()
        sheet = FactSheet(
            invoice_id=str(invoice_data.get("invoice_id", "") or invoice_data.get("id", "")),
            contractor_nip=str(invoice_data.get("contractor_nip", "") or ""),
            contractor_name=str((invoice_data.get("vendor_profile") or {}).get("name", "") or (invoice_data.get("contractor", {}) or {}).get("name", "") or ""),
            amount_net=float(invoice_data.get("amount_net", 0) or 0),
            amount_gross=float(invoice_data.get("amount_gross", 0) or 0),
            category=str(invoice_data.get("category", "") or ""),
            issue_date=str(invoice_data.get("issue_date", "") or invoice_data.get("date", "") or ""),
        )
        async with anyio.create_task_group() as tg:
            results: dict[str, Any] = {}
            if self._session_factory and sheet.contractor_nip:
                tg.start_soon(self._worker_fetch, "sqlite_contractor", sheet, results)
                tg.start_soon(self._worker_fetch, "sqlite_recent", sheet, results)
                tg.start_soon(self._worker_fetch, "sqlite_corrections", sheet, results)
            if self._decision_logger and sheet.contractor_nip:
                tg.start_soon(self._worker_fetch, "duckdb_trend", sheet, results)
                tg.start_soon(self._worker_fetch, "duckdb_correction_stats", sheet, results)
            if self._rule_store and sheet.issue_date:
                tg.start_soon(self._worker_fetch, "duckdb_rules", sheet, results)
            if self._vendor_analyst and sheet.contractor_nip:
                tg.start_soon(self._worker_fetch, "vendor_intel", sheet, results)
            if self._vector_store:
                tg.start_soon(self._worker_fetch, "vector_similar", sheet, results)
            if self._tigerbeetle and sheet.contractor_nip:
                tg.start_soon(self._worker_fetch, "tigerbeetle", sheet, results)
            if self._decision_logger:
                tg.start_soon(self._worker_fetch, "global_decisions", sheet, results)
                tg.start_soon(self._worker_fetch, "global_similar", sheet, results)

        source_status = {"sqlite": False, "duckdb": False, "vector_store": False}
        for name, result in results.items():
            try:
                match name:
                    case "sqlite_contractor" if result:
                        sheet.contractor_known = result.get("known", False)
                        sheet.contractor_invoice_count = result.get("invoice_count", 0)
                        sheet.contractor_trust_score = result.get("trust_score", 0.5)
                        sheet.contractor_vat_status = result.get("vat_status", "unknown")
                        sheet.contractor_name = result.get("name", sheet.contractor_name)
                        source_status["sqlite"] = True
                    case "sqlite_recent":
                        sheet.recent_invoices = result or []
                        if result: source_status["sqlite"] = True
                    case "sqlite_corrections":
                        sheet.user_correction_patterns = result or []
                        if result: source_status["sqlite"] = True
                    case "duckdb_trend" if result is not None:
                        sheet.trust_score_trend = result
                        if result.known: source_status["duckdb"] = True
                    case "duckdb_correction_stats" if result is not None:
                        sheet.correction_stats = result
                    case "duckdb_rules":
                        sheet.active_tax_rules = result or []
                        if result: source_status["duckdb"] = True
                    case "vendor_intel":
                        sheet.vendor_intelligence = result or ""
                        if result: source_status["duckdb"] = True
                    case "vector_similar":
                        sheet.similar_invoices = result or []
                        if result: source_status["vector_store"] = True
                    case "tigerbeetle" if result:
                        sheet.ledger_available = result.get("available", False)
                        sheet.ledger_accounts = result.get("accounts", {})
                        sheet.ledger_total_turnover = result.get("total_turnover", 0.0)
                        sheet.ledger_recent_transfers = result.get("recent_transfers", [])
                    case "global_decisions":
                        sheet.global_recent_decisions = result or []
                    case "global_similar":
                        sheet.globally_similar_cases = result or []
            except Exception as exc:
                logger.warning("[FactsAggregator] task %s failed: %s", name, exc)

        sheet.sources_available = source_status
        sheet.build_duration_ms = round((anyio.current_time() - t0) * 1000, 1)
        logger.info("[FactsAggregator] built fact sheet for invoice=%s sources=%s duration=%.1fms", sheet.invoice_id, {k for k, v in source_status.items() if v}, sheet.build_duration_ms)
        return sheet

    def _get_session(self) -> Session | None:
        """Utwórz sesję SQLAlchemy (sync)."""
        if self._session_factory is None: return None
        try: return self._session_factory()
        except Exception as exc:
            logger.warning("[FactsAggregator] failed to create DB session: %s", exc)
            return None

    async def _fetch_contractor_data(self, nip: str) -> dict[str, Any] | None:
        """Pobierz dane kontrahenta z SQLite — pojedyncze CTE zamiast 2 osobnych zapytań ORM."""
        session = self._get_session()
        if session is None: return None
        try:
            row = await anyio.to_thread.run_sync(lambda: session.execute(text("""
                        WITH contractor_data AS (
                            SELECT id, name, nip, vat_status FROM contractors WHERE nip = :nip LIMIT 1),
                        invoice_stats AS (
                            SELECT COUNT(*) AS invoice_count FROM invoices WHERE contractor_nip = :nip)
                        SELECT (SELECT COUNT(*) FROM contractor_data) > 0 AS is_known,
                               COALESCE((SELECT name FROM contractor_data), '') AS name,
                               COALESCE((SELECT vat_status FROM contractor_data), 'unknown') AS vat_status,
                               (SELECT invoice_count FROM invoice_stats) AS invoice_count"""), {"nip": nip}).fetchone())
            if row is None: return None
            count = int(row[3])
            return {"known": bool(row[0]), "name": str(row[1] or ""), "nip": nip, "invoice_count": count, "trust_score": min(count / 10.0, 1.0), "vat_status": str(row[2] or "unknown")}
        except Exception as exc:
            logger.warning("[FactsAggregator] contractor fetch failed: %s", exc)
            return None
        finally:
            session.close()

    async def _fetch_recent_invoices(self, nip: str, exclude_invoice_id: str = "") -> list[dict[str, Any]]:
        """Pobierz ostatnie 5 faktur dla kontrahenta z SQLite."""
        session = self._get_session()
        if session is None: return []
        try:
            rows = await anyio.to_thread.run_sync(lambda: session.execute(text(
                "SELECT id, number, amount_net, amount_gross, status, issue_date, processing_status FROM invoices WHERE contractor_nip = :nip AND id != :exclude_id ORDER BY created_at DESC LIMIT 5"),
                {"nip": nip, "exclude_id": exclude_invoice_id}).fetchall())
            return [{"id": str(r[0]), "number": str(r[1] or ""), "amount_net": float(r[2] or 0), "amount_gross": float(r[3] or 0), "category": str(r[6] or ""), "status": str(r[4] or ""), "date": str(r[5] or "")} for r in rows]
        except Exception as exc:
            logger.warning("[FactsAggregator] recent invoices fetch failed: %s", exc)
            return []
        finally:
            session.close()

    async def _fetch_user_corrections(self, nip: str) -> list[dict[str, Any]]:
        """Pobierz wzorce korekt użytkownika dla kontrahenta."""
        from nexus_ai.core.msgspec_utils import msgspec_loads
        session = self._get_session()
        if session is None: return []
        try:
            rows = await anyio.to_thread.run_sync(lambda: session.execute(text(
                "SELECT id, correction_payload, created_at FROM active_learning_patterns WHERE contractor_id = :nip ORDER BY created_at DESC LIMIT 10"),
                {"nip": nip}).fetchall())
            corrections = []
            for r in rows:
                try: payload = msgspec_loads(str(r[1]))
                except Exception: payload = {"raw": str(r[1])}
                corrections.append({"id": str(r[0]), "description": payload.get("description", payload.get("reasoning", "")), "timestamp": str(r[2])})
            return corrections
        except Exception as exc:
            logger.warning("[FactsAggregator] user corrections fetch failed: %s", exc)
            return []
        finally:
            session.close()

    async def _worker_fetch(self, name: str, sheet: FactSheet, results: dict[str, Any]) -> None:
        """Dispatcher dla równoległego pobierania danych przez TaskGroup. Wyjątki nie przerywają innych workerów."""
        try:
            match name:
                case "sqlite_contractor": result = await self._fetch_contractor_data(sheet.contractor_nip)
                case "sqlite_recent": result = await self._fetch_recent_invoices(sheet.contractor_nip)
                case "sqlite_corrections": result = await self._fetch_user_corrections(sheet.contractor_nip)
                case "duckdb_trend": result = await self._fetch_trust_score_trend(sheet.contractor_nip)
                case "duckdb_correction_stats": result = await self._fetch_correction_stats()
                case "duckdb_rules": result = await self._fetch_active_rules(sheet.issue_date)
                case "vendor_intel": result = await self._fetch_vendor_intelligence(sheet.contractor_nip)
                case "vector_similar": result = await self._fetch_similar_invoices({"contractor_nip": sheet.contractor_nip, "amount_gross": sheet.amount_gross, "category": sheet.category, "invoice_id": sheet.invoice_id})
                case "tigerbeetle": result = await self._fetch_ledger_history(sheet.contractor_nip, sheet.invoice_id)
                case "global_decisions": result = await self._fetch_global_recent_decisions()
                case "global_similar": result = await self._fetch_globally_similar_cases(category=sheet.category, amount_gross=sheet.amount_gross, limit=3)
                case _:
                    logger.warning("[FactsAggregator] unknown worker name: %s", name)
                    return
            results[name] = result
        except Exception as exc:
            logger.warning("[FactsAggregator] worker %s failed: %s", name, exc)
            results[name] = None

    async def _fetch_trust_score_trend(self, contractor_nip: str) -> TrustTrend | None:
        if self._decision_logger is None or not contractor_nip: return None
        try: return self._decision_logger.get_trust_score_trend(contractor_nip=contractor_nip, days=30)
        except Exception as exc:
            logger.warning("[FactsAggregator] trust score trend fetch failed: %s", exc)
            return None

    async def _fetch_correction_stats(self) -> CorrectionStats | None:
        if self._decision_logger is None: return None
        try: return self._decision_logger.get_user_correction_stats()
        except Exception as exc:
            logger.warning("[FactsAggregator] correction stats fetch failed: %s", exc)
            return None

    async def _fetch_active_rules(self, issue_date: str) -> list[dict[str, Any]]:
        if self._rule_store is None: return []
        try: return self._rule_store.get_active_rules(as_of=issue_date) or []
        except Exception as exc:
            logger.warning("[FactsAggregator] active rules fetch failed: %s", exc)
            return []

    async def _fetch_vendor_intelligence(self, nip: str) -> str:
        if self._vendor_analyst is None: return ""
        try: return str(self._vendor_analyst.analyze(nip) or "")
        except Exception as exc:
            logger.warning("[FactsAggregator] vendor intelligence fetch failed: %s", exc)
            return ""

    async def _fetch_global_recent_decisions(self) -> list[GlobalDecision]:
        if self._decision_logger is None: return []
        try: return self._decision_logger.get_recent_global_decisions(limit=5)
        except Exception as exc:
            logger.warning("[FactsAggregator] global decisions fetch failed: %s", exc)
            return []

    async def _fetch_globally_similar_cases(self, category: str = "", amount_gross: float = 0.0, limit: int = 3) -> list[GlobalDecision]:
        if self._decision_logger is None: return []
        try: return self._decision_logger.get_globally_similar_cases(category=category, amount_gross=amount_gross, limit=limit)
        except Exception as exc:
            logger.warning("[FactsAggregator] globally similar cases fetch failed: %s", exc)
            return []

    async def _fetch_similar_invoices(self, invoice_data: dict[str, Any]) -> list[dict[str, Any]]:
        """Znajdź podobne faktury semantycznie przez sqlite-vec i wzbogać o decyzje z DuckDB."""
        if self._vector_store is None: return []
        try:
            invoice_text = f"Faktura: {invoice_data.get('contractor_nip', '')} kwota={invoice_data.get('amount_gross', 0)} kategoria={invoice_data.get('category', '')} opis={invoice_data.get('description', '')}"
            embedding = await anyio.to_thread.run_sync(self._embedding_service.embed, invoice_text)
            if not embedding: return []
            similar = await anyio.to_thread.run_sync(self._vector_store.search_similar, query_vector=embedding, limit=5, distance_threshold=0.85)
            return await self._enrich_similar_with_decision(similar) if similar else []
        except Exception as exc:
            logger.warning("[FactsAggregator] similar invoices fetch failed: %s", exc)
            return []

    async def _enrich_similar_with_decision(self, similar: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Wzbogać podobne faktury o status z SQLite i decyzję z DuckDB (przez NexusCache z TTL 300s)."""
        has_sqlite = self._session_factory is not None
        has_ddb = self._decision_logger is not None
        if not similar: return similar
        if not has_sqlite:
            for inv in similar: inv["status"] = inv.get("status", "?")
        session = self._get_session() if has_sqlite else None
        try:
            for inv in similar:
                inv_id = str(inv.get("id", ""))
                if not inv_id: inv["status"] = "?"; continue
                cache_key = f"enrich:{inv_id}"
                cached = await self._cache.get(cache_key)
                if cached is not None:
                    inv["status"] = cached.get("status", "?")
                    inv["number"] = cached.get("number", "")
                    inv["amount_net"] = cached.get("amount_net", 0.0)
                    inv["amount_gross"] = cached.get("amount_gross", inv.get("amount_gross", 0))
                    inv["decision"] = cached.get("decision")
                    continue
                enriched: dict[str, Any] = {}
                if session is not None:
                    try:
                        row = await anyio.to_thread.run_sync(session.execute, select(Invoice).where(Invoice.id == inv_id))
                        db_invoice = row.scalar_one_or_none()
                        enriched.update({"status": str(db_invoice.status or "?"), "number": str(db_invoice.number or ""), "amount_net": float(db_invoice.amount_net or 0), "amount_gross": float(db_invoice.amount_gross or inv.get("amount_gross", 0))}) if db_invoice else enriched.update({"status": "?"})
                    except Exception as exc: logger.debug("[FactsAggregator] enrich %s failed: %s", inv_id, exc); enriched["status"] = "?"
                else: enriched["status"] = inv.get("status", "?")
                if has_ddb:
                    try:
                        decisions = await anyio.to_thread.run_sync(self._decision_logger.get_decisions_for_invoice, inv_id)
                        enriched["decision"] = decisions[0] if decisions else None
                    except Exception as exc: logger.debug("[FactsAggregator] decision fetch %s failed: %s", inv_id, exc); enriched["decision"] = None
                await self._cache.set(cache_key, enriched, ttl=300)
                inv["status"] = enriched.get("status", "?")
                if "number" in enriched: inv["number"] = enriched["number"]
                if "amount_net" in enriched: inv["amount_net"] = enriched["amount_net"]
                if "amount_gross" in enriched: inv["amount_gross"] = enriched["amount_gross"]
                inv["decision"] = enriched.get("decision")
            return similar
        except Exception as exc:
            logger.warning("[FactsAggregator] enrichment failed: %s — returning raw", exc)
            for inv in similar: inv.setdefault("status", "?"); inv.setdefault("decision", None)
            return similar
        finally:
            if session is not None: session.close()

    def set_tigerbeetle_client(self, client: TigerBeetleClient | None) -> None:
        """Ustaw klienta TigerBeetle po inicjalizacji (late injection przez DecisionEngine)."""
        self._tigerbeetle = client
        if client is not None: logger.info("[FactsAggregator] TigerBeetleClient attached")

    async def _fetch_ledger_history(self, contractor_nip: str, invoice_id: str) -> dict[str, Any]:
        """Pobierz historię księgową kontrahenta z TigerBeetle — salda kont, obrót, ostatnie transfery."""
        if self._tigerbeetle is None: return {}
        try:
            account_map = {"401-01": "401-01", "202": "202", "221-01": "221-01"}
            mapper = TigerBeetleMapper()
            accounts, total_turnover = {}, 0.0
            for sym in account_map:
                credits = await self._tigerbeetle.get_account_credits_posted(mapper.account_to_uint128(sym))
                balance = credits / 100.0
                accounts[sym] = balance
                total_turnover += balance
            recent_transfers = [{"account": sym, "balance_pln": round(b, 2), "note": "Saldo bieżące"} for sym, b in accounts.items() if b > 0]
            return {"available": bool(accounts), "accounts": {k: round(v, 2) for k, v in accounts.items()}, "total_turnover": round(total_turnover, 2), "recent_transfers": recent_transfers[:3]}
        except Exception as exc:
            logger.warning("[FactsAggregator] TigerBeetle ledger fetch failed: %s", exc)
            return {}


_default_aggregator: FactsAggregator | None = None


def get_facts_aggregator(duckdb: DuckDBManager | None = None, vector_store: VectorStore | None = None,
                         embedding_service: EmbeddingService | None = None, db_session_factory: Callable[[], Session] | None = None,
                         decision_logger: DecisionLogger | None = None, rule_store: RuleStore | None = None,
                         vendor_analyst: VendorAnalyst | None = None, tigerbeetle_client: TigerBeetleClient | None = None) -> FactsAggregator:
    """Zwraca globalną instancję FactsAggregator (singleton)."""
    global _default_aggregator
    if _default_aggregator is None:
        _default_aggregator = FactsAggregator(duckdb=duckdb, vector_store=vector_store, embedding_service=embedding_service,
                                               db_session_factory=db_session_factory, decision_logger=decision_logger,
                                               rule_store=rule_store, vendor_analyst=vendor_analyst, tigerbeetle_client=tigerbeetle_client)
    return _default_aggregator
