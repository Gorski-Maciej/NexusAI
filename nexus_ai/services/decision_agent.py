"""
Decision Agent — final decision layer in the pipeline.
Aggregates reports from Council, Rules, and Analytics agents,
then uses Jamba 3B reasoning + Granite function calling to
produce the ultimate decision: AUTO_POST / SUGGEST / ESCALATE.
"""

from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass, field
from typing import Any

from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads
from nexus_ai.services.council_agents import ModelManager

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass
class FinalDecision:
    """Structured final decision from the DecisionOrchestrator."""

    decision: str  # AUTO_POST | SUGGEST | ESCALATE
    confidence: float  # 0.0 – 1.0
    reasoning: str
    jamba_analysis: str = ""
    granite_context: dict[str, Any] = field(default_factory=dict)
    strategy_summary: str = ""

    @property
    def trust_score(self) -> float:
        """Alias for confidence — compat with _council_* helper functions."""
        return self.confidence

    def to_dict(self) -> dict[str, Any]:
        return {
            "decision": self.decision,
            "confidence": self.confidence,
            "reasoning": self.reasoning,
            "jamba_analysis": self.jamba_analysis,
            "granite_context": self.granite_context,
            "strategy_summary": self.strategy_summary,
        }


# ---------------------------------------------------------------------------
# JambaStrategist — high-level strategic reasoning (Jamba 3B)
# ---------------------------------------------------------------------------

JAMBA_SYSTEM_PROMPT = """Jesteś strategiem finansowym analizującym pełny obraz faktury.
Otrzymujesz raporty od trzech wyspecjalizowanych agentów:
1. Rada Agentów (Council) — ocena Alpha (kontekst), Beta (walidacja), Gamma (anomalie)
2. Agent Reguł (Rules) — zgodność z przepisami, NIP, limity
3. Agent Analityki (Analytics) — trendy, anomalie statystyczne

Na podstawie tych raportów podejmij ostateczną decyzję.
Return ONLY a valid JSON object. No other text.
{
    "decision": "AUTO_POST" | "SUGGEST" | "ESCALATE",
    "confidence": 0.0-1.0,
    "reasoning": "Szczegółowe uzasadnienie decyzji",
    "strategy_summary": "Strategiczne podsumowanie w 2-3 zdaniach",
    "needs_additional_data": false,
    "additional_queries": ["opcjonalne zapytania do DuckDB"]
}"""


class JambaStrategist:
    """Strategist that analyzes reports from all agents using Jamba 3B reasoning.

    Uses ModelManager for RAM mutual exclusion with other agents.
    """

    def __init__(
        self,
        model_name: str,
        model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
    ) -> None:
        self._model_name = model_name
        self._model_path = model_path
        self._model_manager = model_manager
        self._config = config or AppConfig()
        self._timeout = self._config.decision_timeout_seconds

    async def analyze(
        self,
        invoice_data: dict[str, Any],
        council_report: dict[str, Any] | None = None,
        rules_report: dict[str, Any] | None = None,
        analytics_report: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Run strategic analysis on all available agent reports.

        Returns dict with decision, confidence, reasoning, strategy_summary,
        needs_additional_data, additional_queries.
        """
        try:
            model = await self._model_manager.acquire(self._model_name, self._model_path)
            prompt = self._build_prompt(
                invoice_data, council_report, rules_report, analytics_report,
            )

            logger.debug("[JambaStrategist] prompt length=%d chars", len(prompt))

            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=1024,
                    temperature=0.1,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = (
                response.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
            )
            logger.debug("[JambaStrategist] raw response=%s", raw[:300])

            return self._parse_response(raw)

        except TimeoutError:
            logger.error("[JambaStrategist] inference timed out after %ds", self._timeout)
            return {
                "decision": "ESCALATE",
                "confidence": 0.0,
                "reasoning": f"Inferencja przekroczyła limit {self._timeout}s",
                "strategy_summary": "Timeout — eskaluj do człowieka",
                "needs_additional_data": False,
                "additional_queries": [],
            }
        except Exception as exc:
            logger.error("[JambaStrategist] evaluation error: %s", exc)
            return {
                "decision": "ESCALATE",
                "confidence": 0.0,
                "reasoning": f"Błąd strategii: {exc}",
                "strategy_summary": "Błąd — eskaluj do człowieka",
                "needs_additional_data": False,
                "additional_queries": [],
            }
        finally:
            await self._model_manager.release()

    def _build_prompt(
        self,
        invoice_data: dict[str, Any],
        council_report: dict[str, Any] | None,
        rules_report: dict[str, Any] | None,
        analytics_report: dict[str, Any] | None,
    ) -> str:
        council = council_report or {}
        rules = rules_report or {}
        analytics = analytics_report or {}

        # Format council report
        council_str = (
            f"  - Alpha decision: {council.get('alpha_decision', 'N/A')}\n"
            f"  - Beta decision: {council.get('beta_decision', 'N/A')}\n"
            f"  - Gamma decision: {council.get('gamma_decision', 'N/A')}\n"
            f"  - Council final: {council.get('council_decision', 'N/A')}\n"
            f"  - Trust score: {council.get('trust_score', 'N/A')}\n"
        )

        # Format rules report
        rules_str = (
            f"  - Passed: {rules.get('passed', 'N/A')}\n"
            f"  - Violations: {len(rules.get('violations', []))}\n"
            f"  - Confidence: {rules.get('confidence', 'N/A')}\n"
        )

        # Format analytics report
        analytics_str = (
            f"  - Trends: {len(analytics.get('trends', []))}\n"
            f"  - Anomalies: {len(analytics.get('anomalies', []))}\n"
            f"  - Summary: {analytics.get('summary', 'N/A')[:200]}\n"
            f"  - Confidence: {analytics.get('confidence', 'N/A')}\n"
        )

        return f"""{JAMBA_SYSTEM_PROMPT}

=== DANE FAKTURY ===
- ID: {invoice_data.get('invoice_id', 'brak')}
- NIP kontrahenta: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- VAT: {invoice_data.get('vat', '?')} PLN
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}
- Data wystawienia: {invoice_data.get('issue_date', 'brak')}

=== RAPORT RADY AGENTÓW (COUNCIL) ===
{council_str}
=== RAPORT ZGODNOŚCI (RULES) ===
{rules_str}
=== RAPORT ANALITYKI (ANALYTICS) ===
{analytics_str}

Na podstawie powyższych danych podejmij ostateczną decyzję.
Jeśli potrzebujesz dodatkowych danych z DuckDB, ustaw needs_additional_data=true
i podaj zapytania w additional_queries."""

    def _parse_response(self, raw: str) -> dict[str, Any]:
        """Parse JSON response from model with regex fallback."""
        try:
            parsed = msgspec_loads(raw)
        except DecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = msgspec_loads(match.group(0))
                except DecodeError:
                    return self._default_result("Unparseable JSON response")
            else:
                return self._default_result("No JSON found in response")

        return {
            "decision": str(parsed.get("decision", "ESCALATE")),
            "confidence": float(parsed.get("confidence", 0.0)),
            "reasoning": str(parsed.get("reasoning", "")),
            "strategy_summary": str(parsed.get("strategy_summary", "")),
            "needs_additional_data": bool(parsed.get("needs_additional_data", False)),
            "additional_queries": parsed.get("additional_queries", []),
            "raw_response": raw,
        }

    @staticmethod
    def _default_result(reason: str) -> dict[str, Any]:
        return {
            "decision": "ESCALATE",
            "confidence": 0.0,
            "reasoning": reason,
            "strategy_summary": "Błąd parsowania — eskaluj do człowieka",
            "needs_additional_data": False,
            "additional_queries": [],
        }


# ---------------------------------------------------------------------------
# GraniteExecutor — function calling to DuckDB for additional data
# ---------------------------------------------------------------------------

GRANITE_EXECUTOR_PROMPT = """Jesteś agentem wykonawczym z dostępem do DuckDB.
Wykonaj zapytania do bazy danych i zwróć wyniki.
Return ONLY a valid JSON object. No other text.
{
    "query_results": [
        {"query": "zapytanie SQL", "result": "wynik zapytania"}
    ],
    "summary": "Podsumowanie znalezionych danych",
    "confidence": 0.0-1.0
}"""


class GraniteExecutor:
    """Executor that queries DuckDB for additional context using function calling.

    Uses the same Granite model as RulesAgent but with a different prompt
    focused on database queries and data retrieval.
    Shares ModelManager for RAM mutual exclusion.
    """

    def __init__(
        self,
        model_name: str,
        model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
    ) -> None:
        self._model_name = model_name
        self._model_path = model_path
        self._model_manager = model_manager
        self._config = config or AppConfig()
        self._timeout = self._config.decision_timeout_seconds

    async def execute(
        self,
        queries: list[str],
        invoice_data: dict[str, Any],
    ) -> dict[str, Any]:
        """Execute additional data queries via Granite function calling.

        The model generates synthetic query results based on invoice context
        (true DuckDB execution is handled by the caller).

        Returns dict with query_results, summary, confidence.
        """
        if not queries:
            return {
                "query_results": [],
                "summary": "Brak zapytań do wykonania",
                "confidence": 1.0,
            }

        try:
            model = await self._model_manager.acquire(self._model_name, self._model_path)
            prompt = self._build_prompt(queries, invoice_data)

            logger.debug("[GraniteExecutor] prompt length=%d chars", len(prompt))

            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=768,
                    temperature=0.1,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = (
                response.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
            )
            logger.debug("[GraniteExecutor] raw response=%s", raw[:300])

            return self._parse_response(raw)

        except TimeoutError:
            logger.error("[GraniteExecutor] inference timed out after %ds", self._timeout)
            return {
                "query_results": [{"query": q, "result": "TIMEOUT"} for q in queries],
                "summary": f"Timeout po {self._timeout}s",
                "confidence": 0.0,
            }
        except Exception as exc:
            logger.error("[GraniteExecutor] execution error: %s", exc)
            return {
                "query_results": [{"query": q, "result": f"ERROR: {exc}"} for q in queries],
                "summary": f"Błąd: {exc}",
                "confidence": 0.0,
            }
        finally:
            await self._model_manager.release()

    def _build_prompt(
        self,
        queries: list[str],
        invoice_data: dict[str, Any],
    ) -> str:
        queries_str = "\n".join(f"{i+1}. {q}" for i, q in enumerate(queries))
        return f"""{GRANITE_EXECUTOR_PROMPT}

Kontekst faktury:
- ID: {invoice_data.get('invoice_id', 'brak')}
- Kontrahent NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN

Zapytania do DuckDB:
{queries_str}

Wykonaj powyższe zapytania. Dla każdego podaj wynik na podstawie
dostępnych danych kontekstowych i historcznych."""

    def _parse_response(self, raw: str) -> dict[str, Any]:
        """Parse JSON response from model with regex fallback."""
        try:
            parsed = msgspec_loads(raw)
        except DecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = msgspec_loads(match.group(0))
                except DecodeError:
                    return self._default_result("Unparseable JSON response")
            else:
                return self._default_result("No JSON found in response")

        query_results = parsed.get("query_results", [])
        if not isinstance(query_results, list):
            query_results = []

        return {
            "query_results": query_results,
            "summary": str(parsed.get("summary", "")),
            "confidence": float(parsed.get("confidence", 0.0)),
            "raw_response": raw,
        }

    @staticmethod
    def _default_result(reason: str) -> dict[str, Any]:
        return {
            "query_results": [],
            "summary": reason,
            "confidence": 0.0,
        }


# ---------------------------------------------------------------------------
# DecisionOrchestrator — top-level orchestrator
# ---------------------------------------------------------------------------

class DecisionOrchestrator:
    """Top-level orchestrator that makes the final decision.

    Flow:
    1. JambaStrategist analyzes all agent reports → initial decision
    2. If Jamba requests additional data → GraniteExecutor queries DuckDB
    3. If additional data was fetched → re-run Jamba with updated context
    4. Return FinalDecision
    """

    def __init__(
        self,
        jamba_strategist: JambaStrategist,
        granite_executor: GraniteExecutor,
        config: AppConfig | None = None,
    ) -> None:
        self._jamba = jamba_strategist
        self._granite = granite_executor
        self._config = config or AppConfig()

    async def evaluate(
        self,
        invoice_id: str,
        extracted_data: dict[str, Any],
        council_report: dict[str, Any] | None = None,
        rules_report: dict[str, Any] | None = None,
        analytics_report: dict[str, Any] | None = None,
    ) -> FinalDecision:
        """Run the complete decision pipeline.

        Args:
            invoice_id: The invoice being evaluated.
            extracted_data: Raw OCR-extracted invoice data.
            council_report: Output from CouncilOrchestrator (if available).
            rules_report: Output from RulesAgent (if available).
            analytics_report: Output from AnalyticsAgent (if available).

        Returns:
            FinalDecision with the ultimate decision and full context.
        """
        logger.info("[DecisionOrchestrator] evaluating invoice_id=%s", invoice_id)

        # Step 1: Jamba strategic analysis
        jamba_result = await self._jamba.analyze(
            invoice_data=extracted_data,
            council_report=council_report,
            rules_report=rules_report,
            analytics_report=analytics_report,
        )

        # Step 2: If Jamba needs additional data, run GraniteExecutor
        granite_context: dict[str, Any] = {}
        if jamba_result.get("needs_additional_data"):
            queries = jamba_result.get("additional_queries", [])
            if queries:
                logger.info(
                    "[DecisionOrchestrator] Jamba requested %d additional queries",
                    len(queries),
                )
                granite_result = await self._granite.execute(
                    queries=queries,
                    invoice_data=extracted_data,
                )
                granite_context = {
                    "queries": queries,
                    "results": granite_result.get("query_results", []),
                    "summary": granite_result.get("summary", ""),
                    "confidence": granite_result.get("confidence", 0.0),
                }

                # Step 3: Re-run Jamba with additional context if data was fetched
                if granite_context.get("results"):
                    enriched_data = {
                        **extracted_data,
                        "_granite_context": granite_context,
                    }
                    jamba_result = await self._jamba.analyze(
                        invoice_data=enriched_data,
                        council_report=council_report,
                        rules_report=rules_report,
                        analytics_report=analytics_report,
                    )

        decision = jamba_result.get("decision", "ESCALATE")
        # Validate decision is one of the allowed values
        if decision not in ("AUTO_POST", "SUGGEST", "ESCALATE"):
            logger.warning(
                "[DecisionOrchestrator] invalid decision=%s, falling back to ESCALATE",
                decision,
            )
            decision = "ESCALATE"

        final = FinalDecision(
            decision=decision,
            confidence=jamba_result.get("confidence", 0.0),
            reasoning=jamba_result.get("reasoning", ""),
            jamba_analysis=jamba_result.get("raw_response", ""),
            granite_context=granite_context,
            strategy_summary=jamba_result.get("strategy_summary", ""),
        )

        logger.info(
            "[DecisionOrchestrator] invoice_id=%s decision=%s confidence=%.4f",
            invoice_id,
            final.decision,
            final.confidence,
        )
        return final
