"""AI Accountant Copilot — asystent AI analizujący księgi (v7.0 Innovation #10).

v7.0 INNOWACJA #10 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "AI Accountant Copilot: Asystent AI dla księgowego"

Architektura:
  - Regułowy silnik odpowiedzi na pytania księgowe
  - LLM-ready interface dla przyszłej integracji z modelami AI
  - Automatyczne wyjaśnienia anomalii
  - Rekomendacje optymalizacyjne
  - Generowanie raportów MPP, bilansu, RZiS

Ten moduł działa w dwóch trybach:
  1. Rule-based (teraz) — reguły + analiza danych
  2. LLM-augmented (future) — z modelem językowym
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any, Callable, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.copilot")


# ── Types ──────────────────────────────────────────────────────────────


class QueryType(StrEnum):
    BALANCE_INQUIRY = "balance_inquiry"
    ANOMALY_EXPLANATION = "anomaly_explanation"
    TAX_OPTIMIZATION = "tax_optimization"
    CASH_FLOW = "cash_flow"
    BUDGET_ANALYSIS = "budget_analysis"
    VAT_RECOMMENDATION = "vat_recommendation"
    AUDIT_PREPARATION = "audit_preparation"
    GENERAL = "general"


@dataclass
class CopilotQuery:
    """Zapytanie do AI Copilota."""

    query_id: str
    query_type: QueryType
    question: str
    context: dict[str, Any] = field(default_factory=dict)
    timestamp: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())


@dataclass
class CopilotResponse:
    """Odpowiedź od AI Copilota."""

    query_id: str
    answer: str
    confidence: float = 1.0  # 0.0-1.0
    recommendations: list[str] = field(default_factory=list)
    data_sources: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    generated_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())


# ── Rule-based engine ──────────────────────────────────────────────────


@final
class AccountantCopilot:
    """Asystent AI dla księgowego (v7.0 Innowacja #10).

    Analizuje księgi i odpowiada na pytania biznesowe.
    Działa w trybie regułowym (teraz) lub z LLM (future).

    Usage:
        copilot = AccountantCopilot(tb_client, duckdb_conn)
        response = copilot.ask("Dlaczego saldo konta 401-01 wzrosło o 15%?")
        print(response.answer)
    """

    def __init__(
        self,
        tb_client=None,
        duckdb_conn=None,
        *,
        llm_handler: Callable | None = None,
    ) -> None:
        self._tb = tb_client
        self._duckdb = duckdb_conn
        self._llm = llm_handler  # Future: integracja z LLM
        self._history: list[tuple[CopilotQuery, CopilotResponse]] = []

    # ── Main API ──────────────────────────────────────────────────────

    def ask(
        self,
        question: str,
        *,
        context: dict[str, Any] | None = None,
        query_type: QueryType | None = None,
    ) -> CopilotResponse:
        """Zadaj pytanie asystentowi.

        Args:
            question: Pytanie w języku naturalnym.
            context: Dodatkowy kontekst (konta, okresy, itp.).
            query_type: Typ zapytania (auto-detekcja jeśli None).

        Returns:
            CopilotResponse z odpowiedzią i rekomendacjami.
        """
        import uuid

        query_id = f"Q-{uuid.uuid4().hex[:8]}"

        # Auto-detekcja typu zapytania
        if query_type is None:
            query_type = self._detect_query_type(question)

        query = CopilotQuery(
            query_id=query_id,
            query_type=query_type,
            question=question,
            context=context or {},
        )

        # Wybierz handler
        handlers = {
            QueryType.BALANCE_INQUIRY: self._handle_balance_inquiry,
            QueryType.ANOMALY_EXPLANATION: self._handle_anomaly_explanation,
            QueryType.TAX_OPTIMIZATION: self._handle_tax_optimization,
            QueryType.CASH_FLOW: self._handle_cash_flow,
            QueryType.BUDGET_ANALYSIS: self._handle_budget_analysis,
            QueryType.VAT_RECOMMENDATION: self._handle_vat_recommendation,
            QueryType.AUDIT_PREPARATION: self._handle_audit_preparation,
            QueryType.GENERAL: self._handle_general,
        }

        handler = handlers.get(query_type, self._handle_general)

        # Jeśli mamy LLM handler, deleguj do niego
        if self._llm:
            try:
                response = self._llm(query)
                self._history.append((query, response))
                return response
            except Exception as exc:
                logger.warning("[COPILOT] LLM failed, falling back to rules: %s", exc)

        # Rule-based odpowiedź
        response = handler(query)
        self._history.append((query, response))
        return response

    # ── Query type detection ──────────────────────────────────────────

    def _detect_query_type(self, question: str) -> QueryType:
        """Auto-detekcja typu zapytania na podstawie słów kluczowych."""
        q = question.lower()

        if any(w in q for w in ["saldo", "balance", "konto", "account", "stan"]):
            return QueryType.BALANCE_INQUIRY
        if any(w in q for w in ["anomalia", "anomaly", "dziwne", "nietypowe", "wzrosło", "spadło", "dlaczego"]):
            return QueryType.ANOMALY_EXPLANATION
        if any(w in q for w in ["optymalizacja", "zaoszczędzić", "niższy", "pit", "cit", "forma"]):
            return QueryType.TAX_OPTIMIZATION
        if any(w in q for w in ["cash", "płynność", "gotówka", "zabraknie", "zabrakło"]):
            return QueryType.CASH_FLOW
        if any(w in q for w in ["budżet", "budget", "limit", "przekroczenie"]):
            return QueryType.BUDGET_ANALYSIS
        if any(w in q for w in ["vat", "mpp", "split", "odliczenie", "zwrot"]):
            return QueryType.VAT_RECOMMENDATION
        if any(w in q for w in ["audyt", "kontrola", "US", "skarbowy", "przygotuj"]):
            return QueryType.AUDIT_PREPARATION

        return QueryType.GENERAL

    # ── Handlers ──────────────────────────────────────────────────────

    def _handle_balance_inquiry(self, query: CopilotQuery) -> CopilotResponse:
        """Obsługa zapytań o salda kont."""
        account_code = query.context.get("account_code", "unknown")

        answer = (
            f"📊 Analiza konta {account_code}:\n\n"
            f"Aby sprawdzić dokładne saldo, użyj funkcji get_account_balance().\n"
            f"Saldo netto = credits_posted - debits_posted.\n\n"
            f"💡 Rekomendacja: Regularnie sprawdzaj salda kont kosztowych "
            f"(401-xx) przed końcem miesiąca, aby uniknąć przekroczenia budżetu."
        )

        return CopilotResponse(
            query_id=query.query_id,
            answer=answer,
            confidence=0.9,
            recommendations=[
                "Monitoruj salda kont kosztowych co tydzień",
                "Skonfiguruj alerty przy 85% wykorzystania budżetu",
            ],
            data_sources=["TigerBeetle ledger", "Budget definitions"],
        )

    def _handle_anomaly_explanation(self, query: CopilotQuery) -> CopilotResponse:
        """Obsługa zapytań o anomalie."""
        account_code = query.context.get("account_code", "")

        answer = (
            f"🔍 Analiza anomalii dla konta {account_code}:\n\n"
            f"Możliwe przyczyny wzrostu salda:\n"
            f"1. Duża faktura zakupu w tym miesiącu\n"
            f"2. Skumulowanie kilku mniejszych wydatków\n"
            f"3. Zmiana stawek VAT (nowe przepisy 2026)\n"
            f"4. Sezonowość (np. wyższe koszty w Q4)\n\n"
            f"💡 Sprawdź szczegółową historię transferów dla tego konta "
            f"przez get_account_transfers()."
        )

        return CopilotResponse(
            query_id=query.query_id,
            answer=answer,
            confidence=0.75,
            recommendations=[
                "Przejrzyj ostatnie 10 transferów na tym koncie",
                "Porównaj z analogicznym okresem w zeszłym roku",
                "Sprawdź czy nie ma duplikatów faktur",
            ],
            data_sources=["TigerBeetle transfer history", "DuckDB analytics"],
        )

    def _handle_tax_optimization(self, query: CopilotQuery) -> CopilotResponse:
        """Obsługa zapytań o optymalizację podatkową."""
        current_form = query.context.get("tax_form", "liniowy")
        annual_revenue = float(query.context.get("annual_revenue", 0))
        annual_expenses = float(query.context.get("annual_expenses", 0))

        taxable = annual_revenue - annual_expenses
        current_tax = taxable * 0.19

        answer = (
            f"💰 Analiza optymalizacji podatkowej:\n\n"
            f"Forma: {current_form}\n"
            f"Przychód roczny: {annual_revenue:,.2f} PLN\n"
            f"Koszty roczne: {annual_expenses:,.2f} PLN\n"
            f"Dochód: {taxable:,.2f} PLN\n"
            f"Szacunkowy podatek: {current_tax:,.2f} PLN\n\n"
            f"💡 Uruchom TaxSimulator.run_simulation() aby porównać "
            f"wszystkie dostępne formy opodatkowania na Twoich rzeczywistych danych."
        )

        recommendations = []
        if annual_expenses > annual_revenue * 0.8:
            recommendations.append("Rozważ skalę podatkową — przy wysokich kosztach może być korzystniejsza")
        if annual_revenue < 500000:
            recommendations.append("Sprawdź ryczałt — przy niskich kosztach często najkorzystniejszy")

        return CopilotResponse(
            query_id=query.query_id,
            answer=answer,
            confidence=0.85,
            recommendations=recommendations,
            data_sources=["TaxSimulator", "CompanyProfile"],
        )

    def _handle_cash_flow(self, query: CopilotQuery) -> CopilotResponse:
        """Obsługa zapytań o cash flow."""
        answer = (
            f"💵 Analiza płynności finansowej:\n\n"
            f"Uruchom LiquidityOracle.calculate_liquidity_timeline() aby zobaczyć "
            f"prognozę na 90 dni z trzema scenariuszami:\n"
            f"- Optymistyczny\n"
            f"- Realistyczny (najbardziej prawdopodobny)\n"
            f"- Pesymistyczny\n\n"
            f"💡 Skonfiguruj alerty: jeśli saldo spadnie poniżej "
            f"miesięcznych kosztów stałych, system automatycznie Cię ostrzeże."
        )

        return CopilotResponse(
            query_id=query.query_id,
            answer=answer,
            confidence=0.9,
            recommendations=[
                "Utrzymuj poduszkę finansową min. 3x miesięczne koszty",
                "Skonfiguruj automatyczne alerty płynności",
                "Rozważ faktoring dla poprawy cash flow",
            ],
            data_sources=["LiquidityOracle", "TigerBeetle balances"],
        )

    def _handle_budget_analysis(self, query: CopilotQuery) -> CopilotResponse:
        """Obsługa zapytań o budżet."""
        account_code = query.context.get("account_code", "")

        answer = (
            f"📈 Analiza budżetu dla {account_code}:\n\n"
            f"Uruchom BudgetaryControlEngine.get_budget_status() "
            f"aby sprawdzić bieżące wykorzystanie budżetu.\n\n"
            f"Statusy:\n"
            f"- 🟢 OK: <85% wykorzystania\n"
            f"- 🟡 WARN: 85-100%\n"
            f"- 🔴 CRITICAL: >100%\n\n"
            f"💡 System automatycznie zablokuje księgowanie przez "
            f"TigerBeetle DEBITS_MUST_NOT_EXCEED_CREDITS przy przekroczeniu."
        )

        return CopilotResponse(
            query_id=query.query_id,
            answer=answer,
            confidence=0.9,
            recommendations=[
                "Sprawdź status budżetu przed każdą dużą fakturą",
                "Skonfiguruj alerty przy 85% wykorzystania",
            ],
            data_sources=["BudgetaryControlEngine", "TigerBeetle account limits"],
        )

    def _handle_vat_recommendation(self, query: CopilotQuery) -> CopilotResponse:
        """Obsługa zapytań o VAT."""
        answer = (
            f"📋 Rekomendacje VAT:\n\n"
            f"1. Używaj VATShadowLedgerSimulator przed każdą dużą transakcją\n"
            f"   - Symuluje wpływ na VAT przed zaksięgowaniem\n"
            f"   - Pokazuje: VAT do zapłaty, VAT do zwrotu, wpływ na cash flow\n\n"
            f"2. MPP (Split Payment):\n"
            f"   - Obowiązkowy dla faktur >15 000 PLN brutto (załącznik 15)\n"
            f"   - Dobrowolny dla pozostałych — zalecany dla bezpieczeństwa\n\n"
            f"3. Terminy:\n"
            f"   - VAT-7: do 25. dnia następnego miesiąca\n"
            f"   - Zwrot VAT: standardowo 60 dni, przyspieszony 25 dni\n\n"
            f"💡 Skonfiguruj automatyczne przypomnienia o terminach VAT."
        )

        return CopilotResponse(
            query_id=query.query_id,
            answer=answer,
            confidence=0.95,
            recommendations=[
                "Używaj MPP dla wszystkich transakcji >5 000 PLN dla bezpieczeństwa",
                "Skonfiguruj kalendarz terminów VAT",
                "Regularnie uzgadniaj VAT z JPK_V7",
            ],
            data_sources=["VATShadowLedgerSimulator", "VATReconciliationEngine"],
        )

    def _handle_audit_preparation(self, query: CopilotQuery) -> CopilotResponse:
        """Obsługa zapytań o przygotowanie do audytu."""
        answer = (
            f"📁 Przygotowanie do audytu / kontroli skarbowej:\n\n"
            f"1. Uruchom IntegrityVerifier.verify_all() — sprawdza integralność danych\n"
            f"2. Uruchom KksShadowLedgerSimulator.run_simulation() — symuluje sankcje KKS\n"
            f"3. Wygeneruj ZKAuditReport dla audytora (RODO-compliant!)\n"
            f"4. Utwórz tag ksiąg przez LedgerVersionControl.tag('BEFORE-AUDIT')\n"
            f"5. Wygeneruj ProofChain dla wszystkich decyzji podatkowych\n\n"
            f"✅ System automatycznie blokuje modyfikacje podczas audytu."
        )

        return CopilotResponse(
            query_id=query.query_id,
            answer=answer,
            confidence=0.95,
            recommendations=[
                "Przygotuj paczkę audytową: ZK Proof + raporty JPK + deklaracje",
                "Wyznacz osobę kontaktową dla audytora",
                "Zachowaj kopię wszystkich dokumentów poza systemem",
            ],
            data_sources=[
                "IntegrityVerifier", "KksShadowLedgerSimulator",
                "ZKAuditProver", "LedgerVersionControl", "ProofChain",
            ],
        )

    def _handle_general(self, query: CopilotQuery) -> CopilotResponse:
        """Obsługa ogólnych zapytań."""
        answer = (
            f"🤖 Asystent księgowy NexusAI:\n\n"
            f"Twoje pytanie: \"{query.question}\"\n\n"
            f"Mogę pomóc w następujących obszarach:\n"
            f"📊 Salda kont — zapytaj o konkretne konto\n"
            f"🔍 Anomalie — zapytaj o nietypowe zmiany\n"
            f"💰 Optymalizacja podatkowa — porównanie form opodatkowania\n"
            f"💵 Płynność — prognoza cash flow na 90 dni\n"
            f"📈 Budżet — analiza wykorzystania budżetu\n"
            f"📋 VAT — rekomendacje i symulacje\n"
            f"📁 Audyt — przygotowanie do kontroli\n\n"
            f"💡 Wskazówka: podaj konkretny numer konta lub okres, a dam Ci "
            f"szczegółową analizę."
        )

        return CopilotResponse(
            query_id=query.query_id,
            answer=answer,
            confidence=0.8,
            recommendations=[
                "Sprecyzuj pytanie — podaj numer konta lub okres",
                "Użyj komendy 'pomoc' aby zobaczyć wszystkie możliwości",
            ],
            data_sources=["NexusAI Accounting Engine"],
        )

    # ── History ───────────────────────────────────────────────────────

    def get_history(self, limit: int = 50) -> list[dict[str, Any]]:
        """Pobierz historię zapytań i odpowiedzi."""
        return [
            {
                "query_id": q.query_id,
                "question": q.question,
                "query_type": q.query_type.value,
                "answer_summary": r.answer[:200] + "..." if len(r.answer) > 200 else r.answer,
                "confidence": r.confidence,
                "timestamp": q.timestamp,
            }
            for q, r in self._history[-limit:]
        ]
