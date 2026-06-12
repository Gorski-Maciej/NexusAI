"""
FactsAggregator — dedykowana warstwa RAG (Retrieval-Augmented Generation).

Przed każdą decyzją (DecisionEngine) FactsAggregator zbiera dane ze wszystkich
trzech źródeł danych w systemie i pakuje je w jeden, ustrukturyzowany
"arkusz faktów" (FactSheet), który jest dołączany do promptu modelu decyzyjnego.

Źródła danych:
  1. SQLite (OLTP) — faktury, kontrahenci, wzorce korekt użytkownika
  2. DuckDB (OLAP) — reguły podatkowe, trust score trends, vendor intelligence
  3. sqlite-vec — podobne faktury na podstawie embeddingów semantycznych

Usage:
    aggregator = FactsAggregator(
        duckdb=duckdb_manager,
        vector_store=vector_store,
        embedding_service=embedding_service,
        db_session_factory=session_factory,
        decision_logger=decision_logger,
        rule_store=rule_store,
        vendor_analyst=vendor_analyst,
    )
    fact_sheet = await aggregator.build(invoice_data)
"""

from __future__ import annotations

import anyio
from msgspec import Struct, field
from typing import Any, Callable

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from nexus_ai.core.cache import get_cache
from nexus_ai.core.embeddings import EmbeddingService, get_embedding_service
from nexus_ai.core.logger import get_logger

# ── Globalny cache dla FactSheet (współdzielony między build() calls) ──
_few_shot_nexus = get_cache(default_ttl=300)  # 5 min TTL dla przykładów few-shot
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import ActiveLearningPattern, Contractor, Invoice
from nexus_ai.db.vector_store import VectorStore
from nexus_ai.services.tigerbeetle.client import TigerBeetleClient, TigerBeetleMapper
from nexus_ai.services.decision_logger import DecisionLogger
from nexus_ai.services.rule_store import RuleStore
from nexus_ai.services.vendor_intelligence import VendorAnalyst

logger = get_logger(__name__)

# ---------------------------------------------------------------------------
# FactSheet — struktura danych wyjściowych dla DecisionEngine
# ---------------------------------------------------------------------------


class FactSheet(Struct):
    """Ustrukturyzowany arkusz faktów zebranych przed decyzją.

    Zawiera dane ze wszystkich trzech baz, gotowe do wstrzyknięcia
    do promptu modelu decyzyjnego (Jamba 3B, Granite 3.2 3B).
    """

    # ── SQLite (OLTP) ──────────────────────────────────────────────

    # Podstawowe dane faktury
    invoice_id: str = ""
    contractor_nip: str = ""
    contractor_name: str = ""
    amount_net: float = 0.0
    amount_gross: float = 0.0
    category: str = ""
    issue_date: str = ""

    # Historia kontrahenta
    contractor_known: bool = False
    contractor_invoice_count: int = 0
    contractor_trust_score: float = 0.5
    contractor_vat_status: str = "unknown"

    # Historyczne faktury tego samego kontrahenta (ostatnie 5)
    recent_invoices: list[dict[str, Any]] = field(default_factory=list)

    # Wzorce korekt użytkownika (active learning)
    user_correction_patterns: list[dict[str, Any]] = field(default_factory=list)

    # ── DuckDB (OLAP) ──────────────────────────────────────────────

    # Trend trust score dla kontrahenta
    trust_score_trend: dict[str, Any] = field(default_factory=dict)

    # Aktywne reguły podatkowe
    active_tax_rules: list[dict[str, Any]] = field(default_factory=list)

    # Vendor intelligence (jeśli dostępne)
    vendor_intelligence: str = ""

    # Statystyki korekt użytkownika (globalne)
    correction_stats: dict[str, Any] = field(default_factory=dict)

    # ── sqlite-vec (embeddingi) ───────────────────────────────────

    # Podobne faktury semantycznie (z embeddingów)
    similar_invoices: list[dict[str, Any]] = field(default_factory=list)

    # ── TigerBeetle (secure ledger) ───────────────────────────────

    # Czy dane z ledgera są dostępne
    ledger_available: bool = False

    # Salda kont księgowych kontrahenta (symbol -> kwota w PLN)
    ledger_accounts: dict[str, float] = field(default_factory=dict)

    # ── Globalne decyzje (wszyscy kontrahenci) ──────────────────

    # Ostatnie decyzje ze wszystkich kontrahentów (do few-shot learning)
    # Pobierane z DecisionLogger.trust_score_cache — podobne przypadki
    # z globalnej bazy, poszerzające perspektywę modelu poza jednego kontrahenta.
    global_recent_decisions: list[dict[str, Any]] = field(default_factory=list)

    # Globalnie podobne przypadki — jak global_recent_decisions, ale filtrowane
    # po kategorii i priorytetyzowane po trust_score (nie tylko ostatnie).
    # Pobierane z DecisionLogger.get_globally_similar_cases() — szuka przypadków
    # o tej samej kategorii i podobnej kwocie, niezależnie od kontrahenta.
    # Daje modelowi lepsze przykłady few-shot niż surowe ostatnie decyzje.
    globally_similar_cases: list[dict[str, Any]] = field(default_factory=list)

    # Łączny obrót (suma transferów) dla kontrahenta
    ledger_total_turnover: float = 0.0

    # Ostatnie transfery (z TigerBeetle)
    ledger_recent_transfers: list[dict[str, Any]] = field(default_factory=list)

    # ── Metadane ─────────────────────────────────────────────────

    # Które źródła danych były dostępne
    sources_available: dict[str, bool] = field(default_factory=dict)

    # Czas budowania w ms
    build_duration_ms: float = 0.0

    # (Cache przeniesiony do NexusCache — _few_shot_nexus na poziomie modułu)
    # Klucz: few_shot:{data_hash}:{max_examples}, TTL: 300s, L1 RAM + L2 SQLite

    def to_dict(self) -> dict[str, Any]:
        """Konwertuj FactSheet na słownik (do wstrzyknięcia w prompt)."""
        return {
            "invoice": {
                "id": self.invoice_id,
                "contractor_nip": self.contractor_nip,
                "contractor_name": self.contractor_name,
                "amount_net": self.amount_net,
                "amount_gross": self.amount_gross,
                "category": self.category,
                "issue_date": self.issue_date,
            },
            "contractor": {
                "known": self.contractor_known,
                "invoice_count": self.contractor_invoice_count,
                "trust_score": self.contractor_trust_score,
                "vat_status": self.contractor_vat_status,
            },
            "history": {
                "recent_invoices": self.recent_invoices[:5],
                "trust_score_trend": self.trust_score_trend,
                "user_correction_patterns": self.user_correction_patterns[:3],
            },
            "rules": {
                "active_tax_rules": self.active_tax_rules[:10],
                "vendor_intelligence": self.vendor_intelligence,
            },
            "similar": {
                "invoices": self.similar_invoices[:3],
            },
            "ledger": {
                "available": self.ledger_available,
                "accounts": self.ledger_accounts,
                "total_turnover": self.ledger_total_turnover,
                "recent_transfers": self.ledger_recent_transfers[:3],
            },
            "sources": self.sources_available,
        }

    def to_prompt_section(self) -> str:
        """Konwertuj FactSheet na sekcję promptu dla modelu.

        Returns:
            String gotowy do wklejenia w prompt jako sekcja === ARKUSZ FAKTÓW ===.
        """
        lines = ["=== ARKUSZ FAKTÓW (FactsAggregator) ==="]
        lines.append("")

        # Źródła danych
        src = self.sources_available
        lines.append(
            f"Źródła danych: SQLite={'✓' if src.get('sqlite') else '✗'}, "
            f"DuckDB={'✓' if src.get('duckdb') else '✗'}, "
            f"sqlite-vec={'✓' if src.get('vector_store') else '✗'}"
        )
        lines.append("")

        # Podstawowe dane
        lines.append(f"Faktura #{self.invoice_id}")
        lines.append(f"  Kontrahent: {self.contractor_name} (NIP: {self.contractor_nip})")
        lines.append(f"  Kwota netto: {self.amount_net:.2f} PLN")
        lines.append(f"  Kwota brutto: {self.amount_gross:.2f} PLN")
        lines.append(f"  Kategoria: {self.category}")
        lines.append(f"  Data wystawienia: {self.issue_date}")
        lines.append("")

        # Kontrahent
        known = "znany" if self.contractor_known else "nowy"
        lines.append(f"Kontrahent: {known}")
        lines.append(f"  Liczba faktur w historii: {self.contractor_invoice_count}")
        lines.append(f"  Trust score: {self.contractor_trust_score:.2f}")
        lines.append(f"  Status VAT: {self.contractor_vat_status}")
        lines.append("")

        # Trend trust score
        trend = self.trust_score_trend
        if trend.get("known"):
            lines.append(f"Trend trust score (ostatnie 30 dni):")
            lines.append(f"  Średnia: {trend.get('avg_trust', 0):.4f}")
            lines.append(f"  Trend: {trend.get('trend', 'brak')}")
            lines.append(f"  Liczba decyzji: {trend.get('records', 0)}")
            lines.append("")

        # Podobne faktury (z embeddingów)
        similar = self.similar_invoices[:3]
        if similar:
            lines.append("Podobne faktury (semantycznie):")
            for i, inv in enumerate(similar, 1):
                dist = inv.get("_distance", 0)
                lines.append(
                    f"  {i}. ID={inv.get('id', '?')} "
                    f"kwota={inv.get('amount_gross', '?')} "
                    f"kategoria={inv.get('category', '?')} "
                    f"(odległość: {dist:.4f})"
                )
            lines.append("")

        # TigerBeetle (secure ledger)
        if self.ledger_available:
            lines.append("TigerBeetle (secure ledger):")

            # Mapa symboli księgowych na opisy — zgodna z _fetch_ledger_history()
            # Zdefiniowana przed blokami warunkowymi, żeby była dostępna zarówno
            # dla sekcji sald kont jak i dla sekcji transferów (obie mogą wystąpić
            # niezależnie — ledger_accounts może być puste ale transfers nie i odwrotnie).
            ACCOUNT_LABELS = {
                "401-01": "Usługi obce (expense)",
                "202": "Rozrachunki z dostawcami (payables)",
                "221-01": "VAT naliczony (input VAT)",
            }

            if self.ledger_accounts:
                lines.append("  Salda kont (zaksięgowane):")

                for sym, bal in sorted(self.ledger_accounts.items()):
                    label = ACCOUNT_LABELS.get(sym, f"Konto {sym}")
                    lines.append(f"    {label}")
                    lines.append(f"      → {bal:.2f} PLN")

                # Podsumowanie kont — które z bilansem dodatnim, które zerowe
                active = {sym: bal for sym, bal in self.ledger_accounts.items() if bal > 0}
                zero = {sym: bal for sym, bal in self.ledger_accounts.items() if bal == 0}
                if active:
                    lines.append(f"  Aktywne konta: {len(active)}")
                if zero:
                    lines.append(f"  Konta zerowe: {len(zero)}")

            lines.append(f"  Łączny obrót: {self.ledger_total_turnover:.2f} PLN")

            transfers = self.ledger_recent_transfers[:3]
            if transfers:
                lines.append("  Ostatnie transfery:")
                for i, t in enumerate(transfers, 1):
                    account = t.get("account", "?")
                    label = ACCOUNT_LABELS.get(account, f"Konto {account}")
                    lines.append(f"    {i}. {label}")
                    lines.append(f"        kwota: {t.get('balance_pln', t.get('amount', '?'))} PLN")
                    if t.get("note"):
                        lines.append(f"        ({t['note']})")
            lines.append("")

        # Aktywne reguły podatkowe
        rules = self.active_tax_rules[:5]
        if rules:
            lines.append("Aktywne reguły podatkowe:")
            for i, rule in enumerate(rules, 1):
                lines.append(
                    f"  {i}. {rule.get('description_template', rule.get('condition_sql', '?'))}"
                )
            lines.append("")

        # Korekty użytkownika
        corrections = self.user_correction_patterns[:3]
        if corrections:
            lines.append("Ostatnie korekty użytkownika:")
            for c in corrections:
                lines.append(f"  - {c.get('description', '')}")
            lines.append("")

        return "\n".join(lines)

    def build_few_shot_examples(self, max_examples: int = 3) -> str:
        """Zbuduj dynamiczne przykłady few-shot z historycznych decyzji.

        Wykorzystuje dane zebrane w FactSheet:
          - recent_invoices (ostatnie faktury tego kontrahenta)
          - trust_score_trend.decisions_breakdown (statystyki decyzji)
          - user_correction_patterns (korekty użytkownika)
          - similar_invoices (semantycznie podobne faktury)
          - global_recent_decisions (ostatnie decyzje wszystkich kontrahentów
            z globalnej bazy DuckDB, poszerzające perspektywę poza jednego
            kontrahenta)

        Wynik jest cache'owany: jeśli dane źródłowe się nie zmieniły,
        metoda zwraca zapamiętany string bez przeliczania.

        Args:
            max_examples: Maksymalna liczba przykładów (domyślnie 3).

        Returns:
            String z przykładami few-shot gotowymi do wstrzyknięcia w prompt.
            Pusty string jeśli brak danych.
        """
        # Sprawdź NexusCache (L1 RAM + L2 SQLite) — jeśli dane źródłowe
        # się nie zmieniły, zwróć cache bez przeliczania.
        # Klucz uwzględnia hash danych źródłowych i max_examples.
        data_hash = hash(
            (
                str(self.recent_invoices),
                str(self.similar_invoices),
                str(self.globally_similar_cases),
                str(self.global_recent_decisions),
                str(self.trust_score_trend.get("decisions_breakdown", {})),
                str(self.user_correction_patterns),
            )
        )
        cache_key = f"few_shot:{data_hash}:{max_examples}"
        cached = _few_shot_nexus.get_sync(cache_key)
        if cached is not None:
            logger.debug(
                "[FactSheet] few-shot cache HIT: %d chars (key=%s)", len(cached), cache_key
            )
            return cached

        examples: list[str] = []

        # 1. Przykłady z podobnych faktur semantycznie (najlepsze dla few-shot)
        #    Podobne faktury mają wyższy priorytet niż historyczne, bo są
        #    semantycznie bliższe bieżącej fakturze — lepsze przykłady dla modelu.
        #    Dzięki _enrich_similar_with_decision() mają:
        #      - 'status' z SQLite (Invoice.status)
        #      - 'decision' z DuckDB (decisions) z pełną decyzją DecisionEngine
        #    Gdy decision jest dostępny, preferujemy final_decision z DecisionEngine
        #    nad prostym mapowaniem statusu z SQLite.
        similar_count = min(len(self.similar_invoices), max_examples)
        remaining = max_examples - similar_count

        for inv in self.similar_invoices[:similar_count]:
            amount = inv.get("amount_gross", "?")
            category = inv.get("category", "?")
            distance = inv.get("_distance", 0)

            # Status z SQLite (wzbogacony przez _enrich_similar_with_decision)
            raw_status = inv.get("status")
            status = str(raw_status).upper() if raw_status is not None else "?"

            # Pełna decyzja z DuckDB — jeśli dostępna, preferujemy ją
            decision_data = inv.get("decision")
            if decision_data and decision_data.get("final_decision"):
                decision = str(decision_data["final_decision"])
                trust = float(decision_data.get("trust_score", 0.0))
                level = str(decision_data.get("decision_level", ""))
                pattern = str(decision_data.get("decision_pattern", ""))
                correction = (
                    str(decision_data.get("user_correction", ""))
                    if decision_data.get("user_correction")
                    else ""
                )

                entry = (
                    f"[Podobna faktura (semantycznie, odległość: {distance:.4f})]\n"
                    f"  Kwota brutto: {amount}\n"
                    f"  Kategoria: {category}\n"
                    f"  Decyzja: {decision}\n"
                    f"  Trust score: {trust:.2f}\n"
                    f"  Status w systemie: {status}"
                )
                if level:
                    entry += f"\n  Poziom decyzyjny: {level}"
                if pattern:
                    entry += f"\n  Wzorzec: {pattern}"
                if correction:
                    entry += f"\n  Korekta użytkownika: {correction}"

                examples.append(entry)
            else:
                # Fallback: mapuj status z SQLite na decyzję
                decision_map = {
                    "PAID": "AUTO_POST",
                    "APPROVED": "AUTO_POST",
                    "SUGGESTED": "SUGGEST",
                    "PENDING": "ASK_USER",
                    "BLOCKED": "BLOCK",
                }
                decision = decision_map.get(status, "SUGGEST")

                examples.append(
                    f"[Podobna faktura (semantycznie, odległość: {distance:.4f})]\n"
                    f"  Kwota brutto: {amount}\n"
                    f"  Kategoria: {category}\n"
                    f"  Podjęta decyzja: {decision}\n"
                    f"  Status: {status}"
                )

        # 2. Globalnie podobne przypadki — dopasowane po kategorii i priorytetyzowane
        #    po trust_score (z DuckDB). Lepsze dla few-shot niż surowe ostatnie decyzje,
        #    bo są rzeczywiście podobne do bieżącej faktury.
        global_sim_count = min(len(self.globally_similar_cases), remaining)
        remaining -= global_sim_count

        for inv in self.globally_similar_cases[:global_sim_count]:
            nip = inv.get("contractor_nip", "?")
            cat = inv.get("category", "?")
            decision = inv.get("decision", "SUGGEST")
            trust = inv.get("trust_score", 0.0)
            ai_conf = inv.get("ai_confidence", 0.0)

            examples.append(
                f"[Globalnie podobny przypadek (inny kontrahent, kategoria: {cat})]\n"
                f"  NIP: {nip}\n"
                f"  Kategoria: {cat}\n"
                f"  Podjęta decyzja: {decision}\n"
                f"  Trust score: {trust:.2f}"
            )

        # 3. Globalne decyzje — ostatnie decyzje wszystkich kontrahentów z DuckDB
        #    (dopełnienie do max_examples po podobnych fakturach i globalnie podobnych)
        global_count = min(len(self.global_recent_decisions), remaining)
        remaining -= global_count

        for inv in self.global_recent_decisions[:global_count]:
            nip = inv.get("contractor_nip", "?")
            cat = inv.get("category", "?")
            decision = inv.get("decision", "SUGGEST")
            trust = inv.get("trust_score", 0.0)

            examples.append(
                f"[Globalna decyzja (inny kontrahent)]\n"
                f"  NIP: {nip}\n"
                f"  Kategoria: {cat}\n"
                f"  Podjęta decyzja: {decision}\n"
                f"  Trust score: {trust:.2f}"
            )

        # 4. Dodaj ostatnie faktury tego samego kontrahenta (dopełnienie)
        recent_count = min(len(self.recent_invoices), remaining)

        for inv in self.recent_invoices[:recent_count]:
            amount = inv.get("amount_gross", 0)
            category = inv.get("category", "?")

            # Status może być None lub nie-string — bezpieczna konwersja
            raw_status = inv.get("status")
            status = str(raw_status).upper() if raw_status is not None else "?"

            # Mapuj status na decyzję
            decision_map = {
                "PAID": "AUTO_POST",
                "APPROVED": "AUTO_POST",
                "SUGGESTED": "SUGGEST",
                "PENDING": "ASK_USER",
                "BLOCKED": "BLOCK",
            }
            decision = decision_map.get(status, "SUGGEST")

            examples.append(
                f"[Historyczna faktura]\n"
                f"  Kwota brutto: {amount:.2f} PLN\n"
                f"  Kategoria: {category}\n"
                f"  Podjęta decyzja: {decision}\n"
                f"  Status: {status}"
            )

        # 5. Dodaj kontekst z trendu decyzji
        trend = self.trust_score_trend
        decisions_bd = trend.get("decisions_breakdown", {}) if trend.get("known") else {}
        if decisions_bd:
            breakdown = ", ".join(
                f"{k}: {v}" for k, v in sorted(decisions_bd.items(), key=lambda x: -x[1])
            )
            context = (
                f"\n[Wzorzec decyzyjny dla tego kontrahenta]\n"
                f"  Liczba decyzji: {trend.get('records', 0)} w ostatnich 30 dniach\n"
                f"  Rozkład decyzji: {breakdown}\n"
                f"  Trend trust score: {trend.get('trend', 'stable')} (śr. {trend.get('avg_trust', 0):.2f})"
            )
            examples.append(context)

        # 6. Dodaj korekty użytkownika jeśli dostępne
        corrections = self.user_correction_patterns[:2]
        if corrections:
            corrections_text = "\n[Ostatnie korekty użytkownika]\n"
            for c in corrections:
                corrections_text += f"  - {c.get('description', 'brak opisu')}\n"
            examples.append(corrections_text.strip())

        if not examples:
            _few_shot_nexus.set_sync(cache_key, "", ttl=300)
            return ""

        result = "=== PRZYKŁADY FEW-SHOT (historyczne decyzje) ==="
        for i, example in enumerate(examples, 1):
            result += f"\n\nPrzykład {i}:\n{example}"

        # Zapisz do NexusCache (L1 RAM + L2 SQLite) z TTL 300s
        _few_shot_nexus.set_sync(cache_key, result, ttl=300)
        logger.debug("[FactSheet] few-shot cached: %d chars (key=%s)", len(result), cache_key)

        return result


# ---------------------------------------------------------------------------
# FactsAggregator — główna klasa
# ---------------------------------------------------------------------------


class FactsAggregator:
    """Agregator Faktów — warstwa RAG przed decyzją.

    Przed każdą decyzją (DecisionEngine) FactsAggregator zbiera dane z:

      1. SQLite (OLTP) — przez SQLAlchemy Session
      2. DuckDB (OLAP) — przez DuckDBManager
      3. sqlite-vec — przez VectorStore + EmbeddingService

    Wynik (FactSheet) jest dołączany do promptu modelu jako sekcja
    === ARKUSZ FAKTÓW ===, dzięki czemu model nie musi samodzielnie
    szukać danych — dostaje je gotowe.
    """

    def __init__(
        self,
        duckdb: DuckDBManager | None = None,
        vector_store: VectorStore | None = None,
        embedding_service: EmbeddingService | None = None,
        db_session_factory: Callable[[], Session] | None = None,
        decision_logger: DecisionLogger | None = None,
        rule_store: RuleStore | None = None,
        vendor_analyst: VendorAnalyst | None = None,
        tigerbeetle_client: TigerBeetleClient | None = None,
    ) -> None:
        self._duckdb = duckdb
        self._vector_store = vector_store
        self._embedding_service = embedding_service or get_embedding_service()
        self._session_factory = db_session_factory
        self._decision_logger = decision_logger
        self._rule_store = rule_store
        self._vendor_analyst = vendor_analyst
        self._tigerbeetle = tigerbeetle_client

        # NexusCache dla _enrich_similar_with_decision()
        # Klucz: enrich:{invoice_id}, wartość: dict (status/number/amount/decision)
        # TTL: 300s (5 min) — wystarczy na czas budowania FactSheet, nie kumuluje starych ID.
        # Wielopoziomowe: L1 RAM (błyskawiczny odczyt w pętli) + L2 SQLite (persistence).
        self._cache = get_cache(default_ttl=300)

    # ── Główna metoda ──────────────────────────────────────────────

    async def build(self, invoice_data: dict[str, Any]) -> FactSheet:
        """Zbuduj arkusz faktów ze wszystkich źródeł danych.

        Args:
            invoice_data: Dane faktury (wytrahowane przez OCR + wzbogacone).

        Returns:
            FactSheet z danymi ze wszystkich dostępnych źródeł.
        """
        import time

        t0 = time.monotonic()

        sheet = FactSheet(
            invoice_id=str(invoice_data.get("invoice_id", "") or invoice_data.get("id", "")),
            contractor_nip=str(invoice_data.get("contractor_nip", "") or ""),
            contractor_name=str(
                (invoice_data.get("vendor_profile") or {}).get("name", "")
                or (invoice_data.get("contractor", {}) or {}).get("name", "")
                or ""
            ),
            amount_net=float(invoice_data.get("amount_net", 0) or 0),
            amount_gross=float(invoice_data.get("amount_gross", 0) or 0),
            category=str(invoice_data.get("category", "") or ""),
            issue_date=str(
                invoice_data.get("issue_date", "") or invoice_data.get("date", "") or ""
            ),
        )

        # Uruchom wszystkie źródła równolegle przez TaskGroup
        # Każdy worker zapisuje swój wynik do wspólnego słownika `results`
        async with anyio.create_task_group() as tg:
            results: dict[str, Any] = {}

            # 1. SQLite — dane kontrahenta i historia
            if self._session_factory and sheet.contractor_nip:
                tg.start_soon(self._worker_fetch, "sqlite_contractor", sheet, results)
                tg.start_soon(self._worker_fetch, "sqlite_recent", sheet, results)
                tg.start_soon(self._worker_fetch, "sqlite_corrections", sheet, results)

            # 2. DuckDB — trust score trend i reguły podatkowe
            if self._decision_logger and sheet.contractor_nip:
                tg.start_soon(self._worker_fetch, "duckdb_trend", sheet, results)
                tg.start_soon(self._worker_fetch, "duckdb_correction_stats", sheet, results)

            if self._rule_store and sheet.issue_date:
                tg.start_soon(self._worker_fetch, "duckdb_rules", sheet, results)

            # 3. Vendor intelligence z DuckDB
            if self._vendor_analyst and sheet.contractor_nip:
                tg.start_soon(self._worker_fetch, "vendor_intel", sheet, results)

            # 4. sqlite-vec — podobne faktury semantycznie
            if self._vector_store:
                tg.start_soon(self._worker_fetch, "vector_similar", sheet, results)

            # 5. TigerBeetle — historia księgowań kontrahenta
            if self._tigerbeetle and sheet.contractor_nip:
                tg.start_soon(self._worker_fetch, "tigerbeetle", sheet, results)

            # 6. Globalne decyzje
            if self._decision_logger:
                tg.start_soon(self._worker_fetch, "global_decisions", sheet, results)

            # 7. Globalnie podobne przypadki
            if self._decision_logger:
                tg.start_soon(self._worker_fetch, "global_similar", sheet, results)

        # Zbierz wyniki (po zakończeniu TaskGroup — wszystkie workery skończone)
        source_status = {"sqlite": False, "duckdb": False, "vector_store": False}

        for name, result in results.items():
            try:
                if name == "sqlite_contractor":
                    if result:
                        sheet.contractor_known = result.get("known", False)
                        sheet.contractor_invoice_count = result.get("invoice_count", 0)
                        sheet.contractor_trust_score = result.get("trust_score", 0.5)
                        sheet.contractor_vat_status = result.get("vat_status", "unknown")
                        sheet.contractor_name = result.get("name", sheet.contractor_name)
                        source_status["sqlite"] = True

                elif name == "sqlite_recent":
                    sheet.recent_invoices = result or []
                    if result:
                        source_status["sqlite"] = True

                elif name == "sqlite_corrections":
                    sheet.user_correction_patterns = result or []
                    if result:
                        source_status["sqlite"] = True

                elif name == "duckdb_trend":
                    sheet.trust_score_trend = result or {}
                    if result and result.get("known"):
                        source_status["duckdb"] = True

                elif name == "duckdb_correction_stats":
                    sheet.correction_stats = result or {}

                elif name == "duckdb_rules":
                    sheet.active_tax_rules = result or []
                    if result:
                        source_status["duckdb"] = True

                elif name == "vendor_intel":
                    sheet.vendor_intelligence = result or ""
                    if result:
                        source_status["duckdb"] = True

                elif name == "vector_similar":
                    sheet.similar_invoices = result or []
                    if result:
                        source_status["vector_store"] = True

                elif name == "tigerbeetle":
                    if result:
                        sheet.ledger_available = result.get("available", False)
                        sheet.ledger_accounts = result.get("accounts", {})
                        sheet.ledger_total_turnover = result.get("total_turnover", 0.0)
                        sheet.ledger_recent_transfers = result.get("recent_transfers", [])
                        if result.get("available"):
                            source_status.setdefault("tigerbeetle", True)

                elif name == "global_decisions":
                    sheet.global_recent_decisions = result or []
                    if result:
                        source_status.setdefault("global", True)

                elif name == "global_similar":
                    sheet.globally_similar_cases = result or []
                    if result:
                        source_status.setdefault("global", True)

            except Exception as exc:
                logger.warning("[FactsAggregator] task %s failed: %s", name, exc)

        sheet.sources_available = source_status
        sheet.build_duration_ms = round((time.monotonic() - t0) * 1000, 1)

        logger.info(
            "[FactsAggregator] built fact sheet for invoice=%s sources=%s duration=%.1fms",
            sheet.invoice_id,
            {k for k, v in source_status.items() if v},
            sheet.build_duration_ms,
        )

        return sheet

    # ── SQLite (OLTP) — metody pomocnicze ──────────────────────────

    def _get_session(self) -> Session | None:
        """Utwórz sesję SQLAlchemy."""
        if self._session_factory is None:
            return None
        try:
            return self._session_factory()
        except Exception as exc:
            logger.warning("[FactsAggregator] failed to create DB session: %s", exc)
            return None

    async def _fetch_contractor_data(self, nip: str) -> dict[str, Any] | None:
        """Pobierz dane kontrahenta z SQLite.

        Args:
            nip: NIP kontrahenta.

        Returns:
            Słownik z danymi kontrahenta lub None.
        """
        session = self._get_session()
        if session is None:
            return None

        try:
            contractor = await anyio.to_thread.run_sync(
                session.execute,
                select(Contractor).where(Contractor.nip == nip),
            )
            contractor_row = contractor.scalar_one_or_none()

            # Policz faktury dla kontrahenta
            invoice_count = await anyio.to_thread.run_sync(
                session.execute,
                select(Invoice).where(Invoice.contractor_nip == nip),
            )
            count = len(invoice_count.scalars().all())

            if contractor_row is None:
                return {
                    "known": False,
                    "name": "",
                    "invoice_count": count,
                    "trust_score": 0.5,
                    "vat_status": "unknown",
                }

            return {
                "known": True,
                "name": contractor_row.name or "",
                "nip": contractor_row.nip,
                "invoice_count": count,
                "trust_score": min(count / 10.0, 1.0),  # prosty trust score z liczby faktur
                "vat_status": contractor_row.vat_status or "unknown",
            }
        except Exception as exc:
            logger.warning("[FactsAggregator] contractor fetch failed: %s", exc)
            return None
        finally:
            session.close()

    async def _fetch_recent_invoices(
        self, nip: str, exclude_invoice_id: str = ""
    ) -> list[dict[str, Any]]:
        """Pobierz ostatnie 5 faktur dla kontrahenta z SQLite.

        Args:
            nip: NIP kontrahenta.
            exclude_invoice_id: ID faktury do wykluczenia (bieżąca).

        Returns:
            Lista ostatnich faktur.
        """
        session = self._get_session()
        if session is None:
            return []

        try:
            stmt = (
                select(Invoice)
                .where(Invoice.contractor_nip == nip)
                .where(Invoice.id != exclude_invoice_id)
                .order_by(Invoice.created_at.desc())
                .limit(5)
            )
            result = await anyio.to_thread.run_sync(session.execute, stmt)
            invoices = result.scalars().all()

            return [
                {
                    "id": inv.id,
                    "number": inv.number or "",
                    "amount_net": float(inv.amount_net or 0),
                    "amount_gross": float(inv.amount_gross or 0),
                    "category": inv.processing_status or "",
                    "status": inv.status,
                    "date": str(inv.issue_date or ""),
                }
                for inv in invoices
            ]
        except Exception as exc:
            logger.warning("[FactsAggregator] recent invoices fetch failed: %s", exc)
            return []
        finally:
            session.close()

    async def _fetch_user_corrections(self, nip: str) -> list[dict[str, Any]]:
        """Pobierz wzorce korekt użytkownika dla kontrahenta.

        Args:
            nip: NIP kontrahenta.

        Returns:
            Lista korekt użytkownika.
        """
        from nexus_ai.core.msgspec_utils import msgspec_loads

        session = self._get_session()
        if session is None:
            return []

        try:
            stmt = (
                select(ActiveLearningPattern)
                .where(ActiveLearningPattern.contractor_id == nip)
                .order_by(ActiveLearningPattern.created_at.desc())
                .limit(10)
            )
            result = await anyio.to_thread.run_sync(session.execute, stmt)
            patterns = result.scalars().all()

            corrections = []
            for p in patterns:
                try:
                    payload = msgspec_loads(p.correction_payload)
                except Exception:
                    payload = {"raw": p.correction_payload}

                corrections.append(
                    {
                        "id": p.id,
                        "description": payload.get("description", payload.get("reasoning", "")),
                        "timestamp": str(p.created_at),
                    }
                )

            return corrections
        except Exception as exc:
            logger.warning("[FactsAggregator] user corrections fetch failed: %s", exc)
            return []
        finally:
            session.close()

    # ── Worker dispatcher (wywoływany z TaskGroup) ────────────────

    async def _worker_fetch(
        self,
        name: str,
        sheet: FactSheet,
        results: dict[str, Any],
    ) -> None:
        """Dispatcher for parallel data fetching — wywoływany przez TaskGroup.

        Każdy worker zapisuje swój wynik do `results[name]`.
        Wyjątki są łapane i logowane — nie przerywają innych workerów.
        """
        try:
            if name == "sqlite_contractor":
                result = await self._fetch_contractor_data(sheet.contractor_nip)
            elif name == "sqlite_recent":
                result = await self._fetch_recent_invoices(sheet.contractor_nip)
            elif name == "sqlite_corrections":
                result = await self._fetch_user_corrections(sheet.contractor_nip)
            elif name == "duckdb_trend":
                result = await self._fetch_trust_score_trend()
            elif name == "duckdb_correction_stats":
                result = await self._fetch_correction_stats()
            elif name == "duckdb_rules":
                result = await self._fetch_active_rules(sheet.issue_date)
            elif name == "vendor_intel":
                result = await self._fetch_vendor_intelligence(sheet.contractor_nip)
            elif name == "vector_similar":
                result = await self._fetch_similar_invoices(
                    {
                        "contractor_nip": sheet.contractor_nip,
                        "amount_gross": sheet.amount_gross,
                        "category": sheet.category,
                        "invoice_id": sheet.invoice_id,
                    }
                )
            elif name == "tigerbeetle":
                result = await self._fetch_ledger_history(sheet.contractor_nip, sheet.invoice_id)
            elif name == "global_decisions":
                result = await self._fetch_global_recent_decisions()
            elif name == "global_similar":
                result = await self._fetch_globally_similar_cases(
                    category=sheet.category,
                    amount_gross=sheet.amount_gross,
                )
            else:
                logger.warning("[FactsAggregator] unknown worker name: %s", name)
                return

            results[name] = result

        except Exception as exc:
            logger.warning("[FactsAggregator] worker %s failed: %s", name, exc)
            results[name] = None

    # ── DuckDB helpers (implementacje dla _worker_fetch) ────────────────

    async def _fetch_trust_score_trend(self) -> dict[str, Any]:
        """Pobierz trend trust score z DecisionLogger (DuckDB)."""
        if self._decision_logger is None or not hasattr(
            self._decision_logger, "get_trust_score_trend"
        ):
            return {}
        try:
            trend = self._decision_logger.get_trust_score_trend()
            return trend or {}
        except Exception as exc:
            logger.warning("[FactsAggregator] trust score trend fetch failed: %s", exc)
            return {}

    async def _fetch_correction_stats(self) -> dict[str, Any]:
        """Pobierz globalne statystyki korekt użytkownika."""
        if self._decision_logger is None:
            return {}
        try:
            stats = self._decision_logger.get_correction_stats()
            return stats or {}
        except Exception as exc:
            logger.warning("[FactsAggregator] correction stats fetch failed: %s", exc)
            return {}

    async def _fetch_active_rules(self, issue_date: str) -> list[dict[str, Any]]:
        """Pobierz aktywne reguły podatkowe z RuleStore."""
        if self._rule_store is None:
            return []
        try:
            rules = self._rule_store.get_active_rules(as_of=issue_date)
            return rules or []
        except Exception as exc:
            logger.warning("[FactsAggregator] active rules fetch failed: %s", exc)
            return []

    async def _fetch_vendor_intelligence(self, nip: str) -> str:
        """Pobierz vendor intelligence z VendorAnalyst."""
        if self._vendor_analyst is None:
            return ""
        try:
            intel = self._vendor_analyst.analyze(nip)
            return str(intel) if intel else ""
        except Exception as exc:
            logger.warning("[FactsAggregator] vendor intelligence fetch failed: %s", exc)
            return ""

    async def _fetch_global_recent_decisions(self) -> list[dict[str, Any]]:
        """Pobierz ostatnie globalne decyzje z DecisionLogger."""
        if self._decision_logger is None or not hasattr(
            self._decision_logger, "get_recent_decisions_global"
        ):
            return []
        try:
            decisions = self._decision_logger.get_recent_decisions_global(limit=5)
            return decisions or []
        except Exception as exc:
            logger.warning("[FactsAggregator] global decisions fetch failed: %s", exc)
            return []

    async def _fetch_globally_similar_cases(
        self,
        category: str = "",
        amount_gross: float = 0.0,
    ) -> list[dict[str, Any]]:
        """Pobierz globalnie podobne przypadki z DecisionLogger."""
        if self._decision_logger is None or not hasattr(
            self._decision_logger, "get_globally_similar_cases"
        ):
            return []
        try:
            cases = self._decision_logger.get_globally_similar_cases(
                category=category,
                amount=amount_gross,
                limit=3,
            )
            return cases or []
        except Exception as exc:
            logger.warning("[FactsAggregator] globally similar cases fetch failed: %s", exc)
            return []

    # ── sqlite-vec — podobieństwo semantyczne ─────────────────────

    async def _fetch_similar_invoices(self, invoice_data: dict[str, Any]) -> list[dict[str, Any]]:
        """Znajdź podobne faktury semantycznie przez sqlite-vec i wzbogać o decyzje.

        Krok 1: Generuje embedding z opisu faktury.
        Krok 2: Szuka najbliższych sąsiadów w sqlite-vec.
        Krok 3: Dla każdej podobnej faktury pobiera z SQLite status/decyzję
                (jeśli dostępne), aby móc użyć ich jako przykładów few-shot.

        Args:
            invoice_data: Dane faktury do stworzenia embeddingu.

        Returns:
            Lista podobnych faktur wzbogaconych o status/decyzję z SQLite.
        """
        if self._vector_store is None:
            return []

        try:
            # Stwórz tekstową reprezentację faktury do embeddingu
            invoice_text = (
                f"Faktura: {invoice_data.get('contractor_nip', '')} "
                f"kwota={invoice_data.get('amount_gross', 0)} "
                f"kategoria={invoice_data.get('category', '')} "
                f"opis={invoice_data.get('description', '')}"
            )

            # Generuj embedding
            embedding = await anyio.to_thread.run_sync(self._embedding_service.embed, invoice_text)

            if not embedding:
                return []

            # Szukaj podobnych w sqlite-vec
            similar = await anyio.to_thread.run_sync(
                self._vector_store.search_similar,
                query_vector=embedding,
                limit=5,
                distance_threshold=0.85,
            )

            if not similar:
                return []

            # Krok 3: Wzbogać podobne faktury o status/decyzję z SQLite
            # Dzięki temu build_few_shot_examples() może pokazać prawdziwe
            # decyzje użytkownika dla podobnych faktur, a nie "dane niedostępne".
            enriched = await self._enrich_similar_with_decision(similar)
            return enriched

        except Exception as exc:
            logger.warning("[FactsAggregator] similar invoices fetch failed: %s", exc)
            return []

    async def _enrich_similar_with_decision(
        self, similar: list[dict[str, Any]]
    ) -> list[dict[str, Any]]:
        """Wzbogać podobne faktury o status/decyzję z DuckDB.

        Dla każdej podobnej faktury z sqlite-vec:
          1. Próbuje znaleźć odpowiadający jej rekord w SQLite (Invoice) i dołączyć status.
          2. Jeśli dostępny jest DecisionLogger, pobiera pełną decyzję z DuckDB
             (decisions) — zawiera alpha_vote, beta_vote, gamma_vote,
             final_decision, trust_score, trust_components, decision_level,
             decision_pattern, user_correction.

        Dzięki temu build_few_shot_examples() może pokazać nie tylko status z SQLite,
        ale pełną decyzję DecisionEngine dla podobnych faktur.

        Args:
            similar: Lista podobnych faktur z sqlite-vec.

        Returns:
            Ta sama lista wzbogacona o pola:
              - 'status' (z SQLite, lub '?' jeśli brak)
              - 'decision' (dict z DuckDB, lub None jeśli brak)
        """
        has_sqlite = self._session_factory is not None
        has_ddb = self._decision_logger is not None

        if not similar:
            return similar

        if not has_sqlite:
            # Bez sesji SQLite — zwróć jak jest, z oznaką braku decyzji
            for inv in similar:
                inv["status"] = inv.get("status", "?")

        session = self._get_session() if has_sqlite else None

        try:
            for inv in similar:
                inv_id = str(inv.get("id", ""))
                if not inv_id:
                    inv["status"] = "?"
                    continue

                # Sprawdź NexusCache (L1 RAM + L2 SQLite) — jeśli ID było już
                # wcześniej wzbogacone, pomiń zapytania i użyj zapamiętanych danych.
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

                # ── Krok 1: SQLite — podstawowy status ──────────────
                if session is not None:
                    try:
                        row = await anyio.to_thread.run_sync(
                            session.execute,
                            select(Invoice).where(Invoice.id == inv_id),
                        )
                        db_invoice = row.scalar_one_or_none()

                        if db_invoice is not None:
                            enriched.update(
                                {
                                    "status": str(db_invoice.status or "?"),
                                    "number": str(db_invoice.number or ""),
                                    "amount_net": float(db_invoice.amount_net or 0),
                                    "amount_gross": float(
                                        db_invoice.amount_gross or inv.get("amount_gross", 0)
                                    ),
                                }
                            )
                        else:
                            enriched["status"] = "?"
                    except Exception as exc:
                        logger.debug(
                            "[FactsAggregator] failed to enrich similar invoice %s: %s",
                            inv_id,
                            exc,
                        )
                        enriched["status"] = "?"
                else:
                    enriched["status"] = inv.get("status", "?")

                # ── Krok 2: DuckDB — pełna decyzja z DecisionEngine ─
                if has_ddb:
                    try:
                        decisions = await anyio.to_thread.run_sync(
                            self._decision_logger.get_decisions_for_invoice,
                            inv_id,
                        )
                        if decisions:
                            # Weź najnowszą decyzję (pierwsza po ORDER BY timestamp DESC)
                            enriched["decision"] = decisions[0]
                        else:
                            enriched["decision"] = None
                    except Exception as exc:
                        logger.debug(
                            "[FactsAggregator] failed to fetch decision for %s: %s",
                            inv_id,
                            exc,
                        )
                        enriched["decision"] = None

                # Zapisz do NexusCache (L1 RAM + L2 SQLite) z TTL 300s
                await self._cache.set(cache_key, enriched, ttl=300)

                # Aplikuj wzbogacone pola na oryginalny słownik
                inv["status"] = enriched.get("status", "?")
                if "number" in enriched:
                    inv["number"] = enriched["number"]
                if "amount_net" in enriched:
                    inv["amount_net"] = enriched["amount_net"]
                if "amount_gross" in enriched:
                    inv["amount_gross"] = enriched["amount_gross"]
                inv["decision"] = enriched.get("decision")

            return similar

        except Exception as exc:
            logger.warning("[FactsAggregator] enrichment failed: %s — returning raw results", exc)
            for inv in similar:
                inv.setdefault("status", "?")
                inv.setdefault("decision", None)
            return similar
        finally:
            if session is not None:
                session.close()

    def set_tigerbeetle_client(self, client: TigerBeetleClient | None) -> None:
        """Ustaw lub zaktualizuj TigerBeetleClient po inicjalizacji.

        Pozwala na późne wstrzyknięcie klienta TigerBeetle — np. przez
        DecisionEngine, który otrzymuje tigerbeetle_client jako parametr
        i przekazuje go do FactsAggregator po utworzeniu.

        Args:
            client: Instancja TigerBeetleClient lub None.
        """
        self._tigerbeetle = client
        if client is not None:
            logger.info("[FactsAggregator] TigerBeetleClient attached for ledger history")

    # ── TigerBeetle — historia księgowań kontrahenta ────────────────

    async def _fetch_ledger_history(self, contractor_nip: str, invoice_id: str) -> dict[str, Any]:
        """Pobierz historię księgową kontrahenta z TigerBeetle (secure ledger).

        Dla danego kontrahenta sprawdza:
          - Salda kont (expense, VAT, payables)
          - Łączny obrót (suma kredytów na wszystkich kontach)
          - Ostatnie transfery (ostatnie 3)

        TigerBeetleClient używa mapowania: Polish account symbol → uint128 ID.
        Domyślne konta: 401-01 (usługi), 202 (rozrachunki), 221-01 (VAT naliczony).

        Args:
            contractor_nip: NIP kontrahenta (nieużywane w stubie, ale
                            rezerwowane pod przyszłe filtrowanie).
            invoice_id: ID faktury do wykluczenia.

        Returns:
            Słownik z danymi ledgerowymi lub {} przy błędzie.
            Zawiera pola: available (bool), accounts (dict), total_turnover (float),
            recent_transfers (list[dict]).
        """
        if self._tigerbeetle is None:
            return {}

        try:
            # Domyślna mapa kont księgowych (Polish chart of accounts)
            # W produkcji pobierana z Company.tigerbeetle_ledger_map
            account_map = {
                "401-01": "401-01",  # Usługi obce (expense)
                "202": "202",  # Rozrachunki z dostawcami (payables)
                "221-01": "221-01",  # VAT naliczony
            }

            # Użyj TigerBeetleMapper do konwersji symboli na uint128
            mapper = TigerBeetleMapper()
            accounts: dict[str, float] = {}
            total_turnover = 0.0

            for sym in account_map:
                account_id = mapper.account_to_uint128(sym)
                credits = await self._tigerbeetle.get_account_credits_posted(account_id)
                # credits są w minor units (grosze) — konwersja na PLN
                balance = credits / 100.0
                accounts[sym] = balance
                total_turnover += balance

            # Ostatnie transfery — TigerBeetleClient (stub) przechowuje
            # _pending_transfers i _account_credits_posted, ale nie ma
            # metody do listowania transferów per konto.
            # W produkcji: query TigerBeetle by source_document_id lub account.
            # Na razie zwracamy puste — logika rozszerzalna.
            recent_transfers: list[dict[str, Any]] = [
                {
                    "account": account_sym,
                    "balance_pln": round(balance, 2),
                    "note": "Saldo bieżące",
                }
                for account_sym, balance in accounts.items()
                if balance > 0
            ]

            return {
                "available": bool(accounts),
                "accounts": {k: round(v, 2) for k, v in accounts.items()},
                "total_turnover": round(total_turnover, 2),
                "recent_transfers": recent_transfers[:3],
            }

        except Exception as exc:
            logger.warning("[FactsAggregator] TigerBeetle ledger fetch failed: %s", exc)
            return {}


# ── Factory ──────────────────────────────────────────────────────────────

_default_aggregator: FactsAggregator | None = None


def get_facts_aggregator(
    duckdb: DuckDBManager | None = None,
    vector_store: VectorStore | None = None,
    embedding_service: EmbeddingService | None = None,
    db_session_factory: Callable[[], Session] | None = None,
    decision_logger: DecisionLogger | None = None,
    rule_store: RuleStore | None = None,
    vendor_analyst: VendorAnalyst | None = None,
    tigerbeetle_client: TigerBeetleClient | None = None,
) -> FactsAggregator:
    """Zwraca globalną instancję FactsAggregator (singleton).

    Args:
        duckdb: DuckDBManager dla zapytań OLAP.
        vector_store: VectorStore dla sqlite-vec.
        embedding_service: EmbeddingService do generowania embeddingów.
        db_session_factory: Fabryka sesji SQLAlchemy dla SQLite.
        decision_logger: DecisionLogger dla trust score trend.
        rule_store: RuleStore dla aktywnych reguł podatkowych.
        vendor_analyst: VendorAnalyst dla inteligencji kontrahentów.
        tigerbeetle_client: TigerBeetleClient dla historii księgowań.

    Returns:
        Globalna instancja FactsAggregator.
    """
    global _default_aggregator
    if _default_aggregator is None:
        _default_aggregator = FactsAggregator(
            duckdb=duckdb,
            vector_store=vector_store,
            embedding_service=embedding_service,
            db_session_factory=db_session_factory,
            decision_logger=decision_logger,
            rule_store=rule_store,
            vendor_analyst=vendor_analyst,
            tigerbeetle_client=tigerbeetle_client,
        )
    return _default_aggregator
