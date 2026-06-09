"""
Agent Orkiestrator — Centralny Mózg i Wirtualny Dyrektor Finansowy

Zgodnie z aa3fvcx.txt:
- Pozycja w systemie: Zarządzający. Jedyny punkt kontaktu z użytkownikiem
  i nadrzędny koordynator wszystkich agentów wykonawczych.
- Proces decyzyjny: Orkiestrator nigdy nie działa w pojedynkę. Każda decyzja
  przechodzi przez Walidatora Jakości, a krytyczne — dodatkowo przez Agentów
  Analitycznego i Ekstrakcji Danych.
- Wzorzec: "zero zaufania do pojedynczego modelu"

Integruje funkcjonalność z:
- OrchestratorAgent (decydowanie o przepływie pracy)
- CouncilOrchestrator (koordynacja walidacji)
- DecisionOrchestrator (końcowe decyzje AUTO_POST/SUGGEST/ESCALATE)
- JambaStrategist (strategiczne wnioskowanie)
- TrustScoreCalculator (obliczanie poziomu zaufania)
"""

from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass, field
from typing import Any

from nexus_ai.core.config import AppConfig
from nexus_ai.core.logger import get_logger
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads
from nexus_ai.core.protocol_executor import ProtocolExecutor, get_protocol_executor
from nexus_ai.roboton_reflekton.ledger_client import TigerBeetleClient
from nexus_ai.services.council_agents import (
    DecisionVerdict,
    ModelManager,
)
from nexus_ai.services.council_session import CouncilVerdict
from nexus_ai.services.decision_logger import DecisionLogger
from nexus_ai.services.facts_aggregator import FactsAggregator, FactSheet
from nexus_ai.services.ple_engine import PLEEngine
from nexus_ai.services.risk_guard import RiskGuard

# Bayesian Threshold Learner (opcjonalnie, graceful fallback)
try:
    from nexus_ai.services.bayesian_threshold_learner import BayesianThresholdLearner
except ImportError:
    BayesianThresholdLearner = None  # type: ignore[misc]

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

@dataclass(slots=True)
class OrchestratorDecision:
    """Struktura końcowej decyzji Orkiestratora."""

    decision: str  # AUTO_POST | SUGGEST | ASK_USER | BLOCK | ESCALATE
    confidence: float  # 0.0 – 1.0
    reasoning: str
    workflow_plan: list[str]  # które agenty uruchomić
    council_verdict: CouncilVerdict | None = None
    trust_components: dict[str, float] = field(default_factory=dict)
    adapted_thresholds: dict[str, float] = field(default_factory=dict)
    ple_pattern: dict[str, Any] | None = None
    risk_verdict: dict[str, Any] | None = None
    strategy_summary: str = ""
    jamba_analysis: str = ""
    granite_context: dict[str, Any] = field(default_factory=dict)

    @property
    def trust_score(self) -> float:
        """Alias dla confidence — kompatybilnosc z _council_* helper functions."""
        return self.confidence

    def to_dict(self) -> dict[str, Any]:
        return {
            "decision": self.decision,
            "confidence": self.confidence,
            "trust_score": self.confidence,
            "reasoning": self.reasoning,
            "workflow_plan": self.workflow_plan,
            "council_verdict": self.council_verdict.to_dict() if self.council_verdict else None,
            "trust_components": self.trust_components,
            "adapted_thresholds": self.adapted_thresholds,
            "ple_pattern": self.ple_pattern,
            "risk_verdict": self.risk_verdict,
            "strategy_summary": self.strategy_summary,
            "jamba_analysis": self.jamba_analysis,
            "granite_context": self.granite_context,
        }


# ---------------------------------------------------------------------------
# Workflow planner — decyduje które agenty uruchomić
# ---------------------------------------------------------------------------

WORKFLOW_PLANNER_PROMPT = """Jesteś inteligentnym orkiestratorem procesu fakturowania.
Otrzymujesz dane faktury i profil kontrahenta.
Twoim zadaniem jest zdecydować, które kontrole są potrzebne:

- EKSTRAKCJA — weryfikacja danych faktury przez Agent Ekstrakcji Danych
- WALIDACJA — walidacja jakości przez Agent Walidator Jakości
- ANALITYKA — analiza trendów i wykrywanie anomalii statystycznych
- DECYZJA — ostateczna decyzja na podstawie wszystkich raportów

Zasady optymalizacji:
- Dla PROSTYCH faktur (niska kwota, znany kontrahent) uruchom TYLKO EKSTRAKCJA + WALIDACJA
- Dla ZŁOŻONYCH faktur (wysoka kwota, nowy kontrahent) uruchom PEŁNY zestaw

Return ONLY a valid JSON object. No other text.
{
    "agents": ["EKSTRAKCJA", "WALIDACJA"] lub ["EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"],
    "reasoning": "Krótkie uzasadnienie decyzji (1-2 zdania)"
}"""


class WorkflowPlanner:
    """Planer przepływu pracy — decyduje które agenty uruchomić."""

    def __init__(
        self,
        model_name: str,
        model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
        protocol_executor: ProtocolExecutor | None = None,
    ) -> None:
        self._model_name = model_name
        self._model_path = model_path
        self._model_manager = model_manager
        self._config = config or AppConfig()
        self._timeout = self._config.autopilot_agent_timeout_seconds
        self._protocol_executor = protocol_executor or get_protocol_executor()

    async def plan(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
        fact_sheet_text: str | None = None,
    ) -> dict[str, Any]:
        """Zaplanuj przepływ pracy — które agenty uruchomić.

        Args:
            invoice_data: Dane faktury.
            vendor_profile: Profil kontrahenta (opcjonalnie).
            fact_sheet_text: Arkusz faktów z FactsAggregator (RAG) — opcjonalnie.

        Returns:
            Słownik z agentami do uruchomienia i reasoningiem.
        """
        try:
            model = await self._model_manager.acquire(self._model_name, self._model_path)
            prompt = self._build_prompt(invoice_data, vendor_profile, fact_sheet_text)
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=256,
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
            return self._parse_response(raw)
        except TimeoutError:
            logger.error("[WorkflowPlanner] timeout after %ds, fallback to full workflow", self._timeout)
            return {"agents": ["EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"],
                    "reasoning": f"Timeout po {self._timeout}s"}
        except Exception as exc:
            logger.error("[WorkflowPlanner] error: %s", exc)
            return {"agents": ["EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"],
                    "reasoning": f"Błąd: {exc}"}
        finally:
            await self._model_manager.release()

    def _build_prompt(self, invoice_data: dict[str, Any], vendor_profile: dict[str, Any] | None, fact_sheet_text: str | None = None) -> str:
        vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}

        # Użyj ProtocolExecutor do zbudowania promptu z protocols.toml
        # Fallback: inline WORKFLOW_PLANNER_PROMPT jeśli protokół niedostępny
        try:
            base_prompt = self._protocol_executor.build_prompt("workflow_planner")
        except Exception:
            base_prompt = WORKFLOW_PLANNER_PROMPT

        prompt = f"""{base_prompt}

=== DANE FAKTURY ===
- NIP kontrahenta: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}
- OCR confidence: {invoice_data.get('ocr_confidence', 0.5)}

=== PROFIL KONTRAHENTA ===
- Znany: {'tak' if vendor.get('known', False) else 'nie'}
- Liczba faktur: {vendor.get('invoice_count', 0)}
- Trust score: {vendor.get('trust_score', 0.5)}

=== KRYTERIA ===
Faktura jest PROSTA (→ tylko EKSTRAKCJA + WALIDACJA) gdy:
- Kwota brutto ≤ 5000 PLN
- Kontrahent znany (invoice_count ≥ 3)
- OCR confidence ≥ 0.85

W przeciwnym razie faktura jest ZŁOŻONA (→ pełny zestaw agentów)."""

        if fact_sheet_text:
            # Dołącz arkusz faktów (RAG) dla lepszej decyzji planera
            prompt += f"\n\n=== ARKUSZ FAKTÓW (RAG) ===\n{fact_sheet_text}"

        prompt += "\n\n=== DECYZJA ===\nNa podstawie powyższych danych podejmij decyzję.\nReturn ONLY a valid JSON object. No other text."

        return prompt

    def _parse_response(self, raw: str) -> dict[str, Any]:
        try:
            parsed = msgspec_loads(raw)
        except DecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = msgspec_loads(match.group(0))
                except DecodeError:
                    return {"agents": ["EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"],
                            "reasoning": "Unparseable JSON"}
            else:
                return {"agents": ["EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"],
                        "reasoning": "No JSON found"}

        agents_raw = parsed.get("agents", [])
        if not isinstance(agents_raw, list) or not agents_raw:
            return {"agents": ["EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"],
                    "reasoning": "Empty agents list"}

        known = {"EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"}
        mapped = [a for a in agents_raw if a.strip().upper() in known]
        if not mapped:
            return {"agents": ["EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"],
                    "reasoning": "No known agents"}

        return {"agents": mapped, "reasoning": str(parsed.get("reasoning", "")), "raw_response": raw}


# ---------------------------------------------------------------------------
# Trust Score Calculator
# ---------------------------------------------------------------------------

DEFAULT_WEIGHTS = {
    "ai_confidence": 0.30,
    "vendor_reliability": 0.25,
    "data_consistency": 0.20,
    "context_trust": 0.10,
    "risk_guard": 0.15,
}

DEFAULT_THRESHOLDS = {
    "auto_post": 0.92,
    "suggest": 0.75,
    "ask_user": 0.50,
}


class TrustScoreCalculator:
    """Oblicza Trust Score z 4 komponentów + RiskGuard."""

    def __init__(
        self,
        config: AppConfig | None = None,
        duckdb=None,
        risk_guard: RiskGuard | None = None,
    ) -> None:
        self._config = config or AppConfig()
        self._duckdb = duckdb
        self._risk_guard = risk_guard
        self._weights = dict(DEFAULT_WEIGHTS)

    def calculate(
        self,
        extracted_data: dict[str, Any],
        alpha_verdict: DecisionVerdict,
        beta_verdict: DecisionVerdict,
        gamma_verdict: DecisionVerdict,
    ) -> dict[str, Any]:
        """Oblicz złożony Trust Score."""
        ocr_conf = float(extracted_data.get("ocr_confidence", 0.5))
        layout_conf = float(extracted_data.get("layout_confidence", 0.5))
        amount_consensus = 1.0 if extracted_data.get("amount_consensus", True) else 0.3
        llm_val = float(extracted_data.get("llm_validation", 0.5))

        ai_score = ocr_conf * 0.30 + layout_conf * 0.25 + amount_consensus * 0.25 + llm_val * 0.20

        vendor = extracted_data.get("vendor_profile", {}) or {}
        v_known = 1.0 if vendor.get("known", False) else 0.0
        v_count = min(float(vendor.get("invoice_count", 0)) / 10.0, 1.0)
        v_trust = float(vendor.get("trust_score", 0.5))
        v_cat = 1.0 if vendor.get("category_consistent", True) else 0.3
        vendor_score = v_known * 0.30 + v_count * 0.25 + v_trust * 0.30 + v_cat * 0.15

        math_ok = 1.0 if self._check_math(extracted_data) else 0.0
        nip_ok = 1.0 if self._check_nip(extracted_data.get("contractor_nip", "")) else 0.0
        bank_ok = 1.0 if extracted_data.get("bank_account_consistent", True) else 0.3
        amount_typ = 1.0 if extracted_data.get("amount_typical", True) else 0.0
        data_score = math_ok * 0.30 + nip_ok * 0.30 + bank_ok * 0.20 + amount_typ * 0.20

        auto_approve = 1.0 if vendor.get("auto_approve", False) else 0.0
        cat_pref = 1.0 if vendor.get("category_preference_match", True) else 0.3
        context_score = auto_approve * 0.60 + cat_pref * 0.40

        risk_score = 1.0
        risk_verdict: dict[str, Any] | None = None
        if self._risk_guard:
            try:
                fields_conf = {}
                raw_fc = extracted_data.get("field_confidence", {}) or {}
                if isinstance(raw_fc, dict):
                    for fn, entry in raw_fc.items():
                        if isinstance(entry, dict) and "confidence" in entry:
                            fields_conf[fn] = float(entry["confidence"])
                if not fields_conf:
                    fields_conf["overall_ocr"] = ocr_conf
                fields_conf["llm_validation"] = llm_val
                verdict = self._risk_guard.evaluate(
                    fields_with_confidence=fields_conf,
                    tax_form=str(extracted_data.get("company_tax_form", "") or ""),
                    expense_type=str(extracted_data.get("expense_type", "") or ""),
                )
                risk_verdict = {
                    "is_safe": verdict.is_safe,
                    "action": verdict.action,
                    "reason": verdict.reason,
                }
                if verdict.action == "BLOCK_AND_ALERT":
                    risk_score = 0.0
                elif verdict.action == "TRIAGE_QUEUE":
                    risk_score = 0.4
                elif not verdict.is_safe:
                    risk_score = 0.7
            except Exception as exc:
                logger.debug("[TrustScore] RiskGuard failed: %s", exc)

        trust_score = (
            ai_score * self._weights["ai_confidence"]
            + vendor_score * self._weights["vendor_reliability"]
            + data_score * self._weights["data_consistency"]
            + context_score * self._weights["context_trust"]
            + risk_score * self._weights["risk_guard"]
        )

        return {
            "trust_score": round(min(max(trust_score, 0.0), 1.0), 4),
            "components": {
                "ai_confidence": round(ai_score, 4),
                "vendor_reliability": round(vendor_score, 4),
                "data_consistency": round(data_score, 4),
                "context_trust": round(context_score, 4),
                "risk_guard": round(risk_score, 4),
            },
            "risk_verdict": risk_verdict,
        }

    async def get_adapted_thresholds(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
        ple_engine: PLEEngine | None = None,
    ) -> dict[str, float]:
        base = dict(DEFAULT_THRESHOLDS)
        if not self._config.autopilot_adaptation_enabled:
            return base
        vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}
        adj = self._config.autopilot_adaptation_learning_rate
        category = str(invoice_data.get("category", "")).lower()
        recurring = {"paliwo", "czynsz", "media", "telekomunikacja", "leasing"}
        problematic = {"usługi it", "doradztwo", "marketing", "szkolenia"}
        if category in recurring:
            base["auto_post"] -= adj * 0.5
            base["suggest"] -= adj * 0.3
        elif category in problematic:
            base["auto_post"] += adj * 1.0
            base["suggest"] += adj * 0.5
        v_known = vendor.get("known", False)
        v_count = int(vendor.get("invoice_count", 0))
        if v_known and v_count >= self._config.autopilot_vendor_alpha_proximity_min:
            base["auto_post"] -= adj * 1.0
            base["suggest"] -= adj * 0.5
        elif not v_known:
            base["auto_post"] += adj * 2.0
            base["suggest"] += adj * 1.0
        amount = float(invoice_data.get("amount_gross", 0) or 0)
        low = self._config.autopilot_low_amount_threshold
        if amount <= low:
            base["auto_post"] -= adj * 0.5
            base["suggest"] -= adj * 0.3
        elif amount >= low * 20:
            base["auto_post"] += adj * 2.0
            base["suggest"] += adj * 1.0
        elif amount >= low * 4:
            base["auto_post"] += adj * 0.5
            base["suggest"] += adj * 0.3
        if ple_engine and invoice_data.get("contractor_nip"):
            try:
                adapted = await ple_engine.get_adapted_thresholds(
                    base, invoice_data["contractor_nip"], category
                )
                if adapted:
                    base = adapted
            except Exception:
                pass
        for k in base:
            base[k] = round(min(max(base[k], 0.0), 1.0), 4)
        return base

    @staticmethod
    def _check_math(data: dict[str, Any]) -> bool:
        net = float(data.get("amount_net", 0) or 0)
        vat = float(data.get("vat", 0) or 0)
        gross = float(data.get("amount_gross", 0) or 0)
        if gross == 0:
            return True
        return abs((net + vat) - gross) <= 0.01

    @staticmethod
    def _check_nip(nip: str) -> bool:
        s = "".join(ch for ch in str(nip) if ch.isdigit())
        if len(s) != 10:
            return False
        w = (6, 5, 7, 2, 3, 4, 5, 6, 7)
        c = sum(int(d) * w[i] for i, d in enumerate(s[:9])) % 11
        return c != 10 and c == int(s[9])


# ---------------------------------------------------------------------------
# Jamba Strategist — strategiczne wnioskowanie
# ---------------------------------------------------------------------------

JAMBA_SYSTEM_PROMPT = """Jesteś strategiem finansowym analizującym pełny obraz faktury.
Otrzymujesz raporty od wyspecjalizowanych agentów:
1. Agent Walidator Jakości — ocena jakości danych i anomalii
2. Agent Analityczny — trendy i anomalie statystyczne
3. Agent Ekstrakcji Danych — dane surowe z faktury

Na podstawie tych raportów podejmij ostateczną decyzję.
Return ONLY a valid JSON object. No other text.
{
    "decision": "AUTO_POST" | "SUGGEST" | "ESCALATE",
    "confidence": 0.0-1.0,
    "reasoning": "Szczegółowe uzasadnienie decyzji",
    "strategy_summary": "Strategiczne podsumowanie w 2-3 zdaniach"
}"""


class JambaStrategist:
    """Strateg analizujący raporty agentów przez Jamba 3B."""

    def __init__(
        self,
        model_name: str,
        model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
        protocol_executor: ProtocolExecutor | None = None,
    ) -> None:
        self._model_name = model_name
        self._model_path = model_path
        self._model_manager = model_manager
        self._config = config or AppConfig()
        self._timeout = self._config.decision_timeout_seconds
        self._protocol_executor = protocol_executor or get_protocol_executor()

    async def analyze(
        self,
        invoice_data: dict[str, Any],
        quality_report: dict[str, Any] | None = None,
        analytics_report: dict[str, Any] | None = None,
        extraction_report: dict[str, Any] | None = None,
        fact_sheet_text: str | None = None,
        few_shot_examples: str | None = None,
    ) -> dict[str, Any]:
        try:
            model = await self._model_manager.acquire(self._model_name, self._model_path)
            prompt = self._build_prompt(
                invoice_data, quality_report, analytics_report,
                extraction_report, fact_sheet_text, few_shot_examples,
            )
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
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            return self._parse_response(raw)
        except TimeoutError:
            return {"decision": "ESCALATE", "confidence": 0.0,
                    "reasoning": f"Timeout po {self._timeout}s",
                    "strategy_summary": "Timeout — eskaluj do człowieka"}
        except Exception as exc:
            return {"decision": "ESCALATE", "confidence": 0.0,
                    "reasoning": f"Błąd: {exc}",
                    "strategy_summary": "Błąd — eskaluj do człowieka"}
        finally:
            await self._model_manager.release()

    def _build_prompt(self, invoice_data, quality_report, analytics_report, extraction_report, fact_sheet_text=None, few_shot_examples=None):
        q = quality_report or {}
        a = analytics_report or {}
        e = extraction_report or {}

        # Użyj ProtocolExecutor do zbudowania promptu strategicznego z protocols.toml
        # build_orchestrator_prompt_with_flag() zwraca (prompt, sop_loaded) gdzie
        # sop_loaded=True oznacza że SOP z protocols.toml został w pełni załadowany.
        sop_loaded = False
        try:
            prompt_with_sop, sop_loaded = self._protocol_executor.build_orchestrator_prompt_with_flag(
                invoice_data=invoice_data,
                fact_sheet_text=fact_sheet_text,
                few_shot_examples=few_shot_examples,
            )
            base_prompt = prompt_with_sop
        except Exception:
            # Fallback: inline JAMBA_SYSTEM_PROMPT — używany tylko gdy ProtocolLoader
            # lub protocols.toml jest niedostępny (np. błąd importu, brak pliku)
            base_prompt = JAMBA_SYSTEM_PROMPT

        # fact_sheet_text ma własny nagłówek (=== ARKUSZ FAKTÓW ===)
        fact_sheet_section = f"\n{fact_sheet_text}" if fact_sheet_text else ""

        # few_shot_examples ma własny nagłówek (=== PRZYKŁADY FEW-SHOT ===)
        few_shot_block = f"\n\n{few_shot_examples}\n" if few_shot_examples else ""

        # Jeśli SOP został w pełni załadowany (sop_loaded=True), prompt zawiera
        # już wszystkie sekcje (SOP, arkusz faktów, few-shot, dane faktury).
        # Wystarczy dodać raporty agentów.
        if sop_loaded:
            return f"""{base_prompt}

=== RAPORT WALIDATORA JAKOŚCI ===
- Decyzja: {q.get('decision', 'N/A')}
- Poziom: {q.get('level', 'N/A')}
- Zaufanie: {q.get('trust_score', 'N/A')}

=== RAPORT ANALITYCZNY ===
- Trendy: {len(a.get('trends', []))}
- Anomalie: {len(a.get('anomalies', []))}
- Podsumowanie: {a.get('summary', 'N/A')[:200]}

=== RAPORT EKSTRAKCJI DANYCH ===
- Pola: {len(e.get('extracted_fields', []))}
- Średnie zaufanie: {e.get('avg_confidence', 0.5)}

Return ONLY a valid JSON object. No other text."""

        # Fallback: standardowy prompt z inline stałej
        # Używany gdy ProtocolExecutor nie mógł załadować SOP (fallback)
        return f"""{base_prompt}

=== DANE FAKTURY ===
- ID: {invoice_data.get('invoice_id', 'brak')}
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}{fact_sheet_section}{few_shot_block}
=== RAPORT WALIDATORA JAKOŚCI ===
- Decyzja: {q.get('decision', 'N/A')}
- Poziom: {q.get('level', 'N/A')}
- Zaufanie: {q.get('trust_score', 'N/A')}

=== RAPORT ANALITYCZNY ===
- Trendy: {len(a.get('trends', []))}
- Anomalie: {len(a.get('anomalies', []))}
- Podsumowanie: {a.get('summary', 'N/A')[:200]}

=== RAPORT EKSTRAKCJI DANYCH ===
- Pola: {len(e.get('extracted_fields', []))}
- Średnie zaufanie: {e.get('avg_confidence', 0.5)}
{few_shot_block}

Return ONLY a valid JSON object. No other text."""

    def _parse_response(self, raw: str) -> dict[str, Any]:
        try:
            parsed = msgspec_loads(raw)
        except DecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = msgspec_loads(match.group(0))
                except DecodeError:
                    return {"decision": "ESCALATE", "confidence": 0.0,
                            "reasoning": "Unparseable JSON", "strategy_summary": ""}
            else:
                return {"decision": "ESCALATE", "confidence": 0.0,
                        "reasoning": "No JSON", "strategy_summary": ""}
        return {
            "decision": str(parsed.get("decision", "ESCALATE")),
            "confidence": float(parsed.get("confidence", 0.0)),
            "reasoning": str(parsed.get("reasoning", "")),
            "strategy_summary": str(parsed.get("strategy_summary", "")),
            "raw_response": raw,
        }


# ---------------------------------------------------------------------------
# Agent Orkiestrator — główna klasa
# ---------------------------------------------------------------------------

class AgentOrchestrator:
    """Agent Orkiestrator — Centralny Mózg i Wirtualny Dyrektor Finansowy.

    Zgodnie z aa3fvcx.txt:
    - Zarządza: koordynuje wszystkich agentów wykonawczych
    - Punkt kontaktu z użytkownikiem
    - Każda decyzja przechodzi przez Walidatora Jakości
    - Wzorzec: zero zaufania do pojedynczego modelu

    Ulepszenie (2026): Bayesowski System Adaptacyjnych Progów
    - BayesianThresholdLearner zastępuje sztywne DEFAULT_THRESHOLDS
    - Każdy kontrahent ma własny rozkład Beta
    - System uczy się z każdej decyzji użytkownika

    Przepływ:
    1. WorkflowPlanner → plan działania (które agenty uruchomić)
    2. Uruchomienie zaplanowanych agentów
    3. JambaStrategist → końcowa decyzja
    4. Bayesian thresholds → adaptacyjne progi zamiast sztywnych
    5. Zwrócenie OrchestratorDecision
    """

    def __init__(
        self,
        workflow_planner: WorkflowPlanner,
        trust_calculator: TrustScoreCalculator,
        jamba_strategist: JambaStrategist,
        facts_aggregator: FactsAggregator | None = None,
        decision_logger: DecisionLogger | None = None,
        ple_engine: PLEEngine | None = None,
        bayesian_learner: Any | None = None,
        tigerbeetle_client: TigerBeetleClient | None = None,
        config: AppConfig | None = None,
    ) -> None:
        self._planner = workflow_planner
        self._calculator = trust_calculator
        self._jamba = jamba_strategist
        self._facts = facts_aggregator
        self._logger = decision_logger
        self._ple = ple_engine
        self._bayesian = bayesian_learner
        self._config = config or AppConfig()

        # Zintegruj TigerBeetleClient z FactsAggregator — warstwa RAG
        # ma dostęp do secure ledger podczas każdej decyzji.
        # Jeśli aggregator już istnieje, ustaw mu klienta przez setter.
        # Jeśli nie istnieje ale mamy tigerbeetle_client, utwórz aggregator.
        self._tigerbeetle = tigerbeetle_client
        if tigerbeetle_client is not None:
            if self._facts is not None:
                self._facts.set_tigerbeetle_client(tigerbeetle_client)
                logger.info(
                    "[AgentOrchestrator] TigerBeetleClient attached to existing FactsAggregator"
                )
            else:
                # Auto-twórz FactsAggregator z tigerbeetle_client
                # Pozostałe komponenty będą None — init nastąpi przy pierwszym build()
                self._facts = FactsAggregator(tigerbeetle_client=tigerbeetle_client)
                logger.info(
                    "[AgentOrchestrator] FactsAggregator auto-created with TigerBeetleClient"
                )

    async def orchestrate(
        self,
        invoice_id: str,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
        quality_report: dict[str, Any] | None = None,
        analytics_report: dict[str, Any] | None = None,
        extraction_report: dict[str, Any] | None = None,
    ) -> OrchestratorDecision:
        """Główna pętla orkiestracji — planuj, wykonaj, zdecyduj.

        Args:
            invoice_id: ID faktury.
            invoice_data: Surowe dane faktury.
            vendor_profile: Profil kontrahenta (opcjonalnie).
            quality_report: Raport z Agenta Walidatora Jakości.
            analytics_report: Raport z Agenta Analitycznego.
            extraction_report: Raport z Agenta Ekstrakcji Danych.

        Returns:
            OrchestratorDecision z końcową decyzją.
        """
        logger.info("[AgentOrchestrator] orchestrating invoice_id=%s", invoice_id)

        # Krok 0: Zbuduj arkusz faktów ze wszystkich źródeł danych (RAG)
        # FactsAggregator zbiera dane z SQLite, DuckDB i sqlite-vec
        # i pakuje w jeden FactSheet, który jest dołączany do promptów
        # Uwaga: nie mutujemy invoice_data — fact_sheet_text przekazujemy
        # osobno do JambaStrategist, co zapobiega skutkom ubocznym.
        fact_sheet: FactSheet | None = None
        fact_sheet_text: str | None = None
        if self._facts is not None:
            fact_sheet = await self._facts.build(invoice_data)
            fact_sheet_text = fact_sheet.to_prompt_section()
            logger.info(
                "[AgentOrchestrator] facts aggregated: sources=%s duration=%.1fms",
                fact_sheet.sources_available,
                fact_sheet.build_duration_ms,
            )

        # Krok 1: Zaplanuj przepływ pracy (z arkuszem faktów dla lepszych decyzji)
        plan = await self._planner.plan(invoice_data, vendor_profile, fact_sheet_text=fact_sheet_text)
        workflow = plan.get("agents", ["EKSTRAKCJA", "WALIDACJA", "ANALITYKA", "DECYZJA"])

        # Krok 1b: Zbuduj przykłady few-shot z FactSheet
        few_shot_examples: str | None = None
        if fact_sheet is not None:
            few_shot_examples = fact_sheet.build_few_shot_examples(max_examples=3)
            if few_shot_examples:
                logger.info(
                    "[AgentOrchestrator] few-shot examples built: %d chars",
                    len(few_shot_examples),
                )

        # Krok 2: Fast-path Jamba — pomiń gdy plan SIMPLE i Rada FULL_APPROVE
        # Oszczędność: ~5s (inferencja Jamba 3B) dla każdej prostej faktury
        plan_is_simple = (
            len(workflow) <= 2
            and "EKSTRAKCJA" in workflow
            and "WALIDACJA" in workflow
        )
        council_full_approve = (
            quality_report is not None
            and quality_report.get("action") == "AUTO_POST"
            and quality_report.get("level") == "LEVEL_1_AUTO"
        )

        if plan_is_simple and council_full_approve:
            # Fast-path: Rada już podjęła decyzję AUTO_POST z LEVEL_1_AUTO
            # JambaStrategist tylko potwierdzi — pomijamy go oszczędzając ~5s
            logger.info(
                "[AgentOrchestrator] FAST-PATH: simple plan + council full approve — "
                "skipping JambaStrategist (saves ~5s) for invoice_id=%s",
                invoice_id,
            )
            jamba_confidence = float(quality_report.get("trust_score", 0.92))
            decision = "AUTO_POST"
            jamba_result = {
                "decision": decision,
                "confidence": jamba_confidence,
                "reasoning": quality_report.get("deliberation", "Pełny konsensus Rady Agentów — fast-path"),
                "strategy_summary": "Fast-path: SIMPLE plan + FULL_APPROVE — brak potrzeby strategicznej analizy",
                "raw_response": "",
            }
        else:
            # Standardowa ścieżka: uruchom JambaStrategist
            jamba_result = await self._jamba.analyze(
                invoice_data=invoice_data,
                quality_report=quality_report,
                analytics_report=analytics_report,
                extraction_report=extraction_report,
                fact_sheet_text=fact_sheet_text,
                few_shot_examples=few_shot_examples,
            )

        jamba_confidence = float(jamba_result.get("confidence", 0.0))
        decision = jamba_result.get("decision", "ESCALATE")
        if decision not in ("AUTO_POST", "SUGGEST", "ESCALATE"):
            decision = "ESCALATE"

        # Krok 2b: Bayesowskie adaptacyjne progi
        # Jeśli BayesianThresholdLearner jest dostępny, pobierz adaptacyjne
        # progi dla tego kontrahenta i kategorii. Progi te są niższe dla
        # zaufanych kontrahentów i wyższe dla nowych/problemowych.
        bayesian_thresholds: dict[str, float] | None = None
        if self._bayesian is not None:
            try:
                bayesian_thresholds = self._bayesian.get_thresholds(
                    contractor_nip=str(invoice_data.get("contractor_nip", "unknown")),
                    category=str(invoice_data.get("category", "__global__")),
                    amount_gross=float(invoice_data.get("amount_gross", 0) or 0),
                )
                logger.debug(
                    "[AgentOrchestrator] bayesian thresholds=%s",
                    bayesian_thresholds,
                )
            except Exception as exc:
                logger.warning(
                    "[AgentOrchestrator] Bayesian threshold fetch failed: %s", exc
                )

        # Decyzja końcowa z adaptacyjnymi progami
        # Jeśli Jamba zwróciło SUGGEST/ESCALATE, szanuj to
        # Jeśli AUTO_POST, sprawdź czy confidence >= bayesowski próg
        if decision == "AUTO_POST" and bayesian_thresholds is not None:
            if jamba_confidence < bayesian_thresholds.get("auto_post", 0.92):
                # Bayes mówi: za niskie confidence dla auto_post
                if jamba_confidence >= bayesian_thresholds.get("suggest", 0.75):
                    decision = "SUGGEST"
                    logger.info(
                        "[AgentOrchestrator] bayesian override: AUTO_POST→SUGGEST "
                        "(jamba=%.4f < bayesian_auto=%.4f)",
                        jamba_confidence, bayesian_thresholds["auto_post"],
                    )
                else:
                    decision = "ASK_USER"
                    logger.info(
                        "[AgentOrchestrator] bayesian override: AUTO_POST→ASK_USER "
                        "(jamba=%.4f < bayesian_suggest=%.4f)",
                        jamba_confidence, bayesian_thresholds["suggest"],
                    )

        # Krok 3: Zapisz do PLE (uczenie się na decyzjach)
        if self._ple:
            try:
                await self._ple.record_decision(
                    invoice_id=invoice_id,
                    decision=decision,
                    trust_score=jamba_confidence,
                    trust_components={"jamba_confidence": jamba_confidence},
                    contractor_nip=str(invoice_data.get("contractor_nip", "unknown")),
                    category=str(invoice_data.get("category", "unknown")),
                    amount_gross=float(invoice_data.get("amount_gross", 0) or 0),
                    metadata={
                        "workflow": workflow,
                        "reasoning": jamba_result.get("reasoning", ""),
                        "strategy_summary": jamba_result.get("strategy_summary", ""),
                        "bayesian_thresholds": bayesian_thresholds,
                    },
                )
            except Exception as exc:
                logger.warning("[AgentOrchestrator] PLE recording failed: %s", exc)

        # Krok 4: Zapisz auto-decyzję do Bayesa
        # Auto-decyzje mają mniejszą wagę niż decyzje użytkownika,
        # ale wciąż pomagają budować profil kontrahenta.
        if self._bayesian is not None and decision in ("AUTO_POST", "SUGGEST"):
            try:
                self._bayesian.record_auto_decision(
                    contractor_nip=str(invoice_data.get("contractor_nip", "unknown")),
                    category=str(invoice_data.get("category", "__global__")),
                    approved=(decision == "AUTO_POST"),
                    amount_gross=float(invoice_data.get("amount_gross", 0) or 0),
                )
            except Exception as exc:
                logger.warning(
                    "[AgentOrchestrator] Bayesian auto-record failed: %s", exc
                )

        logger.info(
            "[AgentOrchestrator] invoice_id=%s decision=%s confidence=%.4f "
            "bayesian=%s workflow=%s",
            invoice_id, decision, jamba_confidence,
            bayesian_thresholds is not None, workflow,
        )

        return OrchestratorDecision(
            decision=decision,
            confidence=jamba_confidence,
            reasoning=jamba_result.get("reasoning", ""),
            workflow_plan=workflow,
            strategy_summary=jamba_result.get("strategy_summary", ""),
            jamba_analysis=jamba_result.get("raw_response", ""),
            adapted_thresholds=bayesian_thresholds or {},
            granite_context={
                "fact_sheet_sources": fact_sheet.sources_available,
                "fact_sheet_duration_ms": fact_sheet.build_duration_ms,
                "fact_sheet_summary": {
                    "contractor_known": fact_sheet.contractor_known,
                    "contractor_invoice_count": fact_sheet.contractor_invoice_count,
                    "similar_invoices_count": len(fact_sheet.similar_invoices),
                    "active_rules_count": len(fact_sheet.active_tax_rules),
                },
            } if fact_sheet else {},
        )

    async def plan_workflow(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Public wrapper wokół WorkflowPlanner z mapowaniem na broker task names.

        Mapuje nazwy logiczne (EKSTRAKCJA, WALIDACJA, ANALITYKA, DECYZJA)
        na rzeczywiste nazwy broker task names.

        Args:
            invoice_data: Dane faktury.
            vendor_profile: Profil kontrahenta (opcjonalnie).

        Returns:
            dict z agentami (broker task names) i reasoningiem.
        """
        plan = await self._planner.plan(invoice_data, vendor_profile)
        agents = plan.get("agents", [])

        # Mapowanie nazw logicznych na broker task names
        # Mapowanie nazw logicznych na broker task names
        # Uwaga: EKSTRAKCJA jest juz wykonana przez process_invoice_ocr przed
        # ta funkcja, wiec nie powinna byc ponownie kickowana.
        TASK_MAP = {
            "WALIDACJA": "council_decide",
            "ANALITYKA": "analytics_run",
            "DECYZJA": "decision_evaluate",
        }
        mapped_agents = []
        for logical_name in agents:
            task_name = TASK_MAP.get(logical_name.strip().upper())
            if task_name:
                mapped_agents.append(task_name)

        if not mapped_agents:
            # Fallback: pełny zestaw
            mapped_agents = ["council_decide", "rules_check", "analytics_run", "decision_evaluate"]

        return {
            "agents": mapped_agents,
            "reasoning": plan.get("reasoning", ""),
        }
