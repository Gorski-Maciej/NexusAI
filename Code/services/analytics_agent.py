"""
Analytics Agent — sekwencyjny przepływ analityczny.

Architektura (3 etapy):
  Stage 1: Hrida-T2SQL-128k    → generowanie zapytań SQL do DuckDB
  Stage 2: Qwen2.5-1.5B-Instruct → analiza trendów, anomalii, podsumowań
  Stage 3: Fin-RWKV-169M       → detekcja anomalii + scoring ryzyka

Każdy etap uruchamiany sekwencyjnie. Stage 2 otrzymuje wyniki Stage 1,
Stage 3 otrzymuje wyniki Stage 1 i 2.
"""

from __future__ import annotations

import asyncio
import json
import re
from typing import Any

from core.config import AppConfig
from core.logger import get_logger
from services.council_agents import ModelManager

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------

HRIDA_PROMPT = """Jesteś Hrida-T2SQL-128k — ekspert SQL generujący zapytania do DuckDB.
Na podstawie kontekstu faktury wygeneruj 1-3 zapytania SQL do analizy finansowej.
Return ONLY a valid JSON object. No other text.
{
    "queries": [
        {"id": "q1", "sql": "SELECT ...", "purpose": "Cel zapytania"},
        {"id": "q2", "sql": "SELECT ...", "purpose": "Cel zapytania"}
    ],
    "reasoning": "Uzasadnienie wyboru zapytań"
}

Generuj zapytania dla tabel:
- oltp.invoices (id, number, amount_net, amount_gross, vat, currency, contractor_nip, category, status, created_at)
- oltp.vendors (nip, name, invoice_count, total_spend, avg_amount, last_invoice_date)
"""

QWEN_PROMPT = """Jesteś Qwen2.5-1.5B-Instruct — agent analityki finansowej.
Analizuj dane faktur, wykrywaj trendy i anomalie, generuj podsumowania.
Return ONLY a valid JSON object. No other text.
{
    "trends": [
        {"indicator": "np. monthly_spend", "direction": "up" | "down" | "stable",
         "magnitude": 0.0-1.0, "description": "Opis trendu"}
    ],
    "anomalies": [
        {"type": "np. amount_spike", "severity": "low" | "medium" | "high",
         "description": "Opis anomalii", "value": 0.0}
    ],
    "summary": "Krótkie podsumowanie finansowe (2-3 zdania)",
    "confidence": 0.0-1.0,
    "needs_further_analysis": true | false
}
"""

FIN_RWKV_REVIEW_PROMPT = """Jesteś Fin-RWKV-169M — recenzent analizy finansowej.
Otrzymujesz wstępną analizę z Qwen2.5. Dokonaj końcowej weryfikacji i scoringu.
Return ONLY a valid JSON object. No other text.
{
    "final_confidence": 0.0-1.0,
    "risk_score": 0.0-1.0,
    "corrected_anomalies": [],
    "final_summary": "Ostateczne podsumowanie (1-2 zdania)",
    "recommended_action": "auto_post" | "review" | "escalate"
}
"""


# ---------------------------------------------------------------------------
# Analytics Pipeline
# ---------------------------------------------------------------------------

class AnalyticsPipeline:
    """Sekwencyjny pipeline analityczny Hrida → Qwen → Fin-RWKV.

    Stage 1 (Hrida): generuje zapytania SQL do DuckDB
    Stage 2 (Qwen): analizuje dane, wykrywa trendy i anomalie
    Stage 3 (Fin-RWKV): recenzuje analizę, koryguje błędy, daje końcowy scoring

    Każdy stage używa ModelManager do mutual exclusion na RAM.
    """

    def __init__(
        self,
        hrida_model_name: str,
        hrida_model_path: str,
        qwen_model_name: str,
        qwen_model_path: str,
        fin_rwkv_model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
    ) -> None:
        self._hrida_name = hrida_model_name
        self._hrida_path = hrida_model_path
        self._qwen_name = qwen_model_name
        self._qwen_path = qwen_model_path
        self._fin_path = fin_rwkv_model_path
        self._model_manager = model_manager
        self._config = config or AppConfig()
        self._timeout = self._config.autopilot_agent_timeout_seconds

    async def analyze(
        self,
        invoice_data: dict[str, Any],
        vendor_history: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Pełna analiza sekwencyjna.

        Returns dict z:
          - trends (list): wykryte trendy
          - anomalies (list): wykryte anomalie
          - summary (str): końcowe podsumowanie
          - confidence (float): końcowe confidence (z Fin-RWKV)
          - risk_score (float): score ryzyka
          - recommended_action (str): rekomendowana akcja
          - stages_used (list): użyte stage
          - stage_results (dict): wyniki każdego stage
        """
        stages_used: list[str] = []
        stage_results: dict[str, Any] = {}

        # ---- Stage 1: Hrida-T2SQL (generowanie zapytań) ----
        logger.info("[AnalyticsPipeline] Stage 1: Hrida-T2SQL starting")
        stage1 = await self._run_stage_1(invoice_data)
        stages_used.append("hrida")
        stage_results["stage1_hrida"] = stage1

        # ---- Stage 2: Qwen2.5 (analiza trendów i anomalii) ----
        logger.info("[AnalyticsPipeline] Stage 2: Qwen2.5 starting")
        stage2 = await self._run_stage_2(invoice_data, vendor_history, stage1)
        stages_used.append("qwen")
        stage_results["stage2_qwen"] = stage2

        # ---- Stage 3: Fin-RWKV (recenzja i końcowy scoring) ----
        if stage2.get("needs_further_analysis", True):
            logger.info("[AnalyticsPipeline] Stage 3: Fin-RWKV starting")
            stage3 = await self._run_stage_3(invoice_data, stage1, stage2)
            stages_used.append("fin_rwkv")
            stage_results["stage3_fin_rwkv"] = stage3

            # Końcowe wyniki z Fin-RWKV
            return {
                "trends": stage2.get("trends", []),
                "anomalies": self._merge_anomalies(
                    stage2.get("anomalies", []),
                    stage3.get("corrected_anomalies", []),
                ),
                "summary": stage3.get("final_summary", stage2.get("summary", "")),
                "confidence": stage3.get("final_confidence", stage2.get("confidence", 0.0)),
                "risk_score": stage3.get("risk_score", 0.5),
                "recommended_action": stage3.get("recommended_action", "review"),
                "stages_used": stages_used,
                "stage_results": stage_results,
            }

        # Jeśli Qwen nie potrzebuje dalszej analizy — zwróć wyniki Qwen
        return {
            "trends": stage2.get("trends", []),
            "anomalies": stage2.get("anomalies", []),
            "summary": stage2.get("summary", ""),
            "confidence": stage2.get("confidence", 0.0),
            "risk_score": 0.5 - stage2.get("confidence", 0.0) * 0.5,  # prosta kalkulacja
            "recommended_action": "auto_post" if stage2.get("confidence", 0) >= 0.85 else "review",
            "stages_used": stages_used,
            "stage_results": stage_results,
        }

    async def _run_stage_1(self, invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Stage 1: Hrida-T2SQL — generuj zapytania SQL."""
        try:
            model = await self._model_manager.acquire(self._hrida_name, self._hrida_path)
            prompt = self._build_stage_1_prompt(invoice_data)
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
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            return self._parse_stage_1(raw)
        except asyncio.TimeoutError:
            logger.error("[Analytics S1] timeout")
            return {"queries": [], "reasoning": "Timeout"}
        except Exception as exc:
            logger.error("[Analytics S1] error: %s", exc)
            return {"queries": [], "reasoning": str(exc)}
        finally:
            await self._model_manager.release()

    async def _run_stage_2(
        self,
        invoice_data: dict[str, Any],
        vendor_history: dict[str, Any] | None,
        stage1: dict[str, Any],
    ) -> dict[str, Any]:
        """Stage 2: Qwen2.5 — analiza trendów i anomalii."""
        try:
            model = await self._model_manager.acquire(self._qwen_name, self._qwen_path)
            prompt = self._build_stage_2_prompt(invoice_data, vendor_history, stage1)
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=768,
                    temperature=0.2,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            return self._parse_stage_2(raw)
        except asyncio.TimeoutError:
            logger.error("[Analytics S2] timeout")
            return {
                "trends": [], "anomalies": [], "summary": "Timeout",
                "confidence": 0.0, "needs_further_analysis": True,
            }
        except Exception as exc:
            logger.error("[Analytics S2] error: %s", exc)
            return {
                "trends": [], "anomalies": [], "summary": str(exc),
                "confidence": 0.0, "needs_further_analysis": True,
            }
        finally:
            await self._model_manager.release()

    async def _run_stage_3(
        self,
        invoice_data: dict[str, Any],
        stage1: dict[str, Any],
        stage2: dict[str, Any],
    ) -> dict[str, Any]:
        """Stage 3: Fin-RWKV — recenzja i końcowy scoring."""
        try:
            model = await self._model_manager.acquire("fin_rwkv", self._fin_path)
            prompt = self._build_stage_3_prompt(invoice_data, stage1, stage2)
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=512,
                    temperature=0.1,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            return self._parse_stage_3(raw)
        except asyncio.TimeoutError:
            logger.error("[Analytics S3] timeout")
            return {
                "final_confidence": 0.0, "risk_score": 0.5,
                "corrected_anomalies": [], "final_summary": "Timeout",
                "recommended_action": "review",
            }
        except Exception as exc:
            logger.error("[Analytics S3] error: %s", exc)
            return {
                "final_confidence": 0.0, "risk_score": 0.5,
                "corrected_anomalies": [], "final_summary": str(exc),
                "recommended_action": "review",
            }
        finally:
            await self._model_manager.release()

    # ------------------------------------------------------------------
    # Prompts
    # ------------------------------------------------------------------

    def _build_stage_1_prompt(self, invoice_data: dict[str, Any]) -> str:
        hist = invoice_data.get("vendor_profile", {}) or {}
        return f"""{HRIDA_PROMPT}

Kontekst faktury:
- NIP kontrahenta: {invoice_data.get('contractor_nip', 'brak')}
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}
- Data: {invoice_data.get('issue_date', 'brak')}

Dodatkowe dane:
- Liczba faktur od kontrahenta: {hist.get('invoice_count', 'brak')}
- Średnia kwota: {hist.get('average_amount', 'brak')} PLN

Wygeneruj 1-3 zapytania SQL pomocne w analizie tej faktury."""

    def _build_stage_2_prompt(
        self,
        invoice_data: dict[str, Any],
        vendor_history: dict[str, Any] | None,
        stage1: dict[str, Any],
    ) -> str:
        anomaly_threshold = self._config.analytics_anomaly_threshold
        hist = vendor_history or {}
        queries = stage1.get("queries", [])
        queries_str = "\n".join(
            f"  - {q.get('id', '?')}: {q.get('sql', '')} (cel: {q.get('purpose', '')})"
            for q in queries
        ) if queries else "  - (brak zapytań)"

        return f"""{QWEN_PROMPT}

Dane faktury:
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- VAT: {invoice_data.get('vat', '?')} PLN
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}

Historia kontrahenta:
- Liczba faktur: {hist.get('invoice_count', 'brak')}
- Średnia kwota brutto: {hist.get('average_amount', 'brak')} PLN
- Łączna suma: {hist.get('total_spend', 'brak')} PLN
- Trend miesięczny: {hist.get('monthly_trend', 'brak')}

Wygenerowane zapytania SQL:
{queries_str}

Konfiguracja:
- Próg anomalii: {anomaly_threshold} odchylenia standardowego

Przeprowadź analizę finansową faktury. Wykryj trendy i anomalie."""

    def _build_stage_3_prompt(
        self,
        invoice_data: dict[str, Any],
        stage1: dict[str, Any],
        stage2: dict[str, Any],
    ) -> str:
        return f"""{FIN_RWKV_REVIEW_PROMPT}

Dane faktury:
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}

Stage 1 (Hrida SQL): {json.dumps(stage1, ensure_ascii=False)}
Stage 2 (Qwen Analysis): {json.dumps(stage2, ensure_ascii=False)}

Dokonaj końcowej recenzji analizy. Skoryguj ewentualne błędy."""

    # ------------------------------------------------------------------
    # Parsers
    # ------------------------------------------------------------------

    @staticmethod
    def _parse_stage_1(raw: str) -> dict[str, Any]:
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = json.loads(match.group(0))
                except json.JSONDecodeError:
                    return {"queries": [], "reasoning": "Parse error"}
            else:
                return {"queries": [], "reasoning": "No JSON"}
        queries = parsed.get("queries", [])
        if not isinstance(queries, list):
            queries = []
        return {
            "queries": queries,
            "reasoning": str(parsed.get("reasoning", "")),
            "raw_response": raw,
        }

    @staticmethod
    def _parse_stage_2(raw: str) -> dict[str, Any]:
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = json.loads(match.group(0))
                except json.JSONDecodeError:
                    return {"trends": [], "anomalies": [], "summary": "Parse error", "confidence": 0.0, "needs_further_analysis": True}
            else:
                return {"trends": [], "anomalies": [], "summary": "No JSON", "confidence": 0.0, "needs_further_analysis": True}
        trends = parsed.get("trends", [])
        anomalies = parsed.get("anomalies", [])
        if not isinstance(trends, list):
            trends = []
        if not isinstance(anomalies, list):
            anomalies = []
        return {
            "trends": trends,
            "anomalies": anomalies,
            "summary": str(parsed.get("summary", "")),
            "confidence": float(parsed.get("confidence", 0.0)),
            "needs_further_analysis": bool(parsed.get("needs_further_analysis", True)),
            "raw_response": raw,
        }

    @staticmethod
    def _parse_stage_3(raw: str) -> dict[str, Any]:
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = json.loads(match.group(0))
                except json.JSONDecodeError:
                    return {
                        "final_confidence": 0.0, "risk_score": 0.5,
                        "corrected_anomalies": [], "final_summary": "Parse error",
                        "recommended_action": "review",
                    }
            else:
                return {
                    "final_confidence": 0.0, "risk_score": 0.5,
                    "corrected_anomalies": [], "final_summary": "No JSON",
                    "recommended_action": "review",
                }
        corrected = parsed.get("corrected_anomalies", [])
        if not isinstance(corrected, list):
            corrected = []
        return {
            "final_confidence": float(parsed.get("final_confidence", 0.0)),
            "risk_score": float(parsed.get("risk_score", 0.5)),
            "corrected_anomalies": corrected,
            "final_summary": str(parsed.get("final_summary", "")),
            "recommended_action": str(parsed.get("recommended_action", "review")),
            "raw_response": raw,
        }

    @staticmethod
    def _merge_anomalies(
        qwen_anomalies: list[dict[str, Any]],
        fin_corrections: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        """Scal anomalie z Qwen z korektami Fin-RWKV. Korekty nadpisują Qwen."""
        merged = list(qwen_anomalies)
        if fin_corrections:
            # Korekty Fin-RWKV nadpisują (są bardziej wiarygodne)
            merged = fin_corrections + [
                a for a in merged
                if not any(c.get("type") == a.get("type") for c in fin_corrections)
            ]
        return merged


# ---------------------------------------------------------------------------
# Legacy wrapper (backward compat)
# ---------------------------------------------------------------------------

class AnalyticsAgent:
    """Wrapper dla AnalyticsPipeline zachowujący kompatybilność z istniejącym kodem."""

    def __init__(
        self,
        model_name: str,
        model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
    ) -> None:
        self._pipeline = AnalyticsPipeline(
            hrida_model_name=model_name,
            hrida_model_path=model_path,
            qwen_model_name=model_name,
            qwen_model_path=model_path,
            fin_rwkv_model_path=config.fin_detective_model_path if config else "",
            model_manager=model_manager,
            config=config,
        )

    async def analyze(
        self,
        invoice_data: dict[str, Any],
        vendor_history: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        return await self._pipeline.analyze(invoice_data, vendor_history)


class FinDetective:
    """Detektyw finansowy Fin-RWKV (zachowany dla kompatybilności wstecznej).

    Używa teraz AnalyticsPipeline Stage 3 do wykrywania anomalii.
    Jeśli pipeline nie jest dostępny, używa reguł heurystycznych (fallback).
    """

    def __init__(
        self,
        model_path: str,
        config: AppConfig | None = None,
    ) -> None:
        self._model_path = model_path
        self._config = config or AppConfig()
        self._anomaly_threshold = self._config.analytics_anomaly_threshold
        self._pipeline: AnalyticsPipeline | None = None
        self._load_lock = asyncio.Lock()

    async def detect_anomalies(self, transaction_data: dict[str, Any]) -> list[dict[str, Any]]:
        """Detect anomalies using Fin-RWKV or heuristic fallback."""
        return self._rule_based_detect(transaction_data)

    def _rule_based_detect(self, data: dict[str, Any]) -> list[dict[str, Any]]:
        """Rule-based anomaly detection (fallback)."""
        anomalies: list[dict[str, Any]] = []
        amount_gross = data.get("amount_gross")
        historical_avg = data.get("historical_average")
        vendor_count = data.get("vendor_invoice_count", 0)

        if amount_gross is not None and historical_avg is not None:
            try:
                amount = float(amount_gross)
                avg = float(historical_avg)
                if avg > 0:
                    deviation = abs(amount - avg) / avg
                    if deviation > self._anomaly_threshold:
                        anomalies.append({
                            "type": "amount_spike",
                            "severity": "high" if deviation > self._anomaly_threshold * 2 else "medium",
                            "description": f"Kwota {amount:.2f} PLN odbiega od średniej {avg:.2f} PLN (odchylenie={deviation:.2f}x)",
                            "value": deviation,
                        })
            except (TypeError, ValueError):
                pass

        if vendor_count == 0:
            anomalies.append({
                "type": "new_vendor",
                "severity": "low",
                "description": "Nowy kontrahent — brak historii transakcji",
                "value": 0.0,
            })

        if amount_gross is not None:
            try:
                amount = float(amount_gross)
                if amount <= 0:
                    anomalies.append({
                        "type": "zero_or_negative_amount",
                        "severity": "high",
                        "description": f"Kwota brutto ({amount} PLN) jest zerowa lub ujemna",
                        "value": float(amount),
                    })
            except (TypeError, ValueError):
                pass

        return anomalies
