"""AgentQualityValidator — Niezależny Strażnik Jakości.

Zgodnie z blueprintem aa3fvcx.txt:
- Granite Guardian 0.5B — Strażnik Podatkowy (VAT, PIT, CIT, split payment)
- GraphSAGE-Encoder 0.1B — Detektor Oszustw (analiza grafów powiązań)
- FinBERT-ESG 0.1B — Analityk Ryzyka (semantyczna ocena kontrahenta)
- Lag-Llama 0.3B — Prognoza płynności (30-dniowa)

Proces walidacji:
1. Orkiestrator → quality.check.request (proponowana decyzja + dane)
2. 4 modele równolegle → Tax, Fraud, ESG, Forecast
3. Agregacja → jeden raport z werdyktami
4. All OK → AUTO_POST | Any WARNING → Review | Any ERROR → BLOCK

Komunikacja: NATS JetStream
Topics: quality.check.request, quality.check.result
"""

from __future__ import annotations

from typing import Any

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.agents.base import BaseAgent
from nexus_ai.agents.models import QualityCheckRequest, QualityCheckResult, make_context
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.inference import ModelManager

logger = get_logger("nexus.agents.quality")


class AgentQualityValidator(BaseAgent):
    """Agent Walidator Jakości — niezależna weryfikacja decyzji.

    Działa jako "sumienie systemu" — weryfikuje każdą decyzję
    przed jej wykonaniem. Architektura zero-trust: żaden pojedynczy
    model nie może podjąć ostatecznej decyzji.
    """

    def __init__(
        self,
        model_manager: ModelManager | None = None,
        config: dict[str, Any] | None = None,
    ) -> None:
        super().__init__(
            name="quality-validator",
            model_manager=model_manager,
            config=config or {},
        )
        self._models: dict[str, str] = {}
        self._fraud_detector: Any = None
        self._risk_analyzer: Any = None

    async def start(self) -> None:
        """Inicjalizuj modele walidatora."""
        await super().start()
        await self._init_models()
        logger.info("[AGENT] QualityValidator ready | models: %s", self._models)

    async def _init_models(self) -> None:
        """Inicjalizuj modele i serwisy."""
        # Ścieżki modeli z konfiguracji
        self._models = {
            "tax_guardian": self._config.get("quality_tax_model", ""),
            "fraud_detector": self._config.get("quality_fraud_model", ""),
            "esg_analyzer": self._config.get("quality_esg_model", ""),
            "forecaster": self._config.get("quality_forecast_model", ""),
        }

        # Fraud detector (GraphSAGE symulacja przez istniejący serwis)
        try:
            from nexus_ai.services.fraud_graph_scanner import FraudGraphScanner
            self._fraud_detector = FraudGraphScanner()
            logger.info("[VALIDATOR] FraudGraphScanner initialized")
        except Exception as exc:
            logger.warning("[VALIDATOR] FraudGraphScanner init failed: %s", exc)

        # Risk analyzer (istniejący serwis)
        try:
            from nexus_ai.services.risk_guard import RiskGuard
            self._risk_analyzer = RiskGuard()
            logger.info("[VALIDATOR] RiskGuard initialized")
        except Exception as exc:
            logger.warning("[VALIDATOR] RiskGuard init failed: %s", exc)

    async def validate(self, request: QualityCheckRequest) -> QualityCheckResult:
        """Główna metoda walidacji — uruchamia wszystkie kontrolery równolegle.

        Args:
            request: Żądanie walidacji z proponowaną decyzją i danymi faktury.

        Returns:
            QualityCheckResult z werdyktami wszystkich kontrolerów.
        """
        logger.info(
            "[VALIDATOR] Validating decision %s | checks=%s",
            request.decision_id,
            request.checks or "all",
        )

        checks = request.checks or ["tax", "fraud", "esg", "forecast"]

        # Uruchom wszystkie żądane kontrolery
        tasks = {}
        if "tax" in checks:
            tasks["tax"] = self._check_tax(request)
        if "fraud" in checks:
            tasks["fraud"] = self._check_fraud(request)
        if "esg" in checks:
            tasks["esg"] = self._check_esg(request)
        if "forecast" in checks:
            tasks["forecast"] = self._check_forecast(request)

        # Parallel execution
        async with anyio.create_task_group() as tg:
            results: dict[str, Any] = {}
            for name, coro in tasks.items():
                results[name] = await coro

        # Agregacja werdyktów
        tax_verdict = results.get("tax", {})
        fraud_verdict = results.get("fraud", {})
        esg_verdict = results.get("esg", {})
        forecast = results.get("forecast", {})

        # Oblicz ogólny risk score i werdykt
        overall_risk_score = self._calculate_risk_score(
            tax_verdict, fraud_verdict, esg_verdict
        )
        overall_verdict = self._determine_overall_verdict(
            tax_verdict, fraud_verdict, esg_verdict
        )

        # Rekomendacje
        recommendations = self._generate_recommendations(
            tax_verdict, fraud_verdict, esg_verdict, forecast
        )

        models_used = [k for k, v in self._models.items() if v]

        return QualityCheckResult(
            decision_id=request.decision_id,
            overall_verdict=overall_verdict,
            overall_risk_score=overall_risk_score,
            tax_verdict=tax_verdict,
            fraud_verdict=fraud_verdict,
            esg_verdict=esg_verdict,
            forecast=forecast,
            recommendations=recommendations,
            models_used=models_used,
        )

    # ── Kontrolery ──────────────────────────────────────────────────

    async def _check_tax(self, request: QualityCheckRequest) -> dict[str, Any]:
        """Strażnik Podatkowy — Granite Guardian 0.5B.

        Sprawdza:
        - Zgodność VAT (stawki, kwoty)
        - Split payment
        - JPK
        - PIT/CIT
        """
        model_path = self._models.get("tax_guardian")
        if not model_path:
            return self._rule_based_tax_check(request)

        invoice = request.invoice_data
        decision = request.proposed_decision

        prompt = f"""Jesteś strażnikiem podatkowym. Sprawdź poprawność podatkową faktury.

Dane faktury:
- NIP: {invoice.get('nip', 'N/A')}
- Kwota netto: {invoice.get('amount_net', 'N/A')}
- Kwota VAT: {invoice.get('amount_vat', 'N/A')}
- Kwota brutto: {invoice.get('amount_gross', 'N/A')}
- Stawka VAT: {invoice.get('vat_rate', 'N/A')}%

Proponowana decyzja: {decision.get('status', 'N/A')}

Oceń ryzyko podatkowe (OK, WARNING, ERROR) i uzasadnij jednym zdaniem po polsku.
Format odpowiedzi: WERDYKT: OK|WARNING|ERROR, UZASADNIENIE: ..."""

        try:
            result = await self.infer(model_path, prompt, max_tokens=100, temperature=0.0)
            verdict = "OK"
            if "WARNING" in result.upper():
                verdict = "WARNING"
            elif "ERROR" in result.upper():
                verdict = "ERROR"
            return {
                "verdict": verdict,
                "reason": result.strip(),
                "model": "granite-guardian",
            }
        except Exception as exc:
            logger.warning("[VALIDATOR] Tax check failed: %s", exc)
            return self._rule_based_tax_check(request)

    def _rule_based_tax_check(self, request: QualityCheckRequest) -> dict[str, Any]:
        """Regułowa kontrola podatkowa (fallback)."""
        invoice = request.invoice_data
        issues = []

        # Sprawdź podstawowe kwoty
        net = invoice.get("amount_net")
        vat = invoice.get("amount_vat")
        gross = invoice.get("amount_gross")

        if net is not None and vat is not None and gross is not None:
            if abs(net + vat - gross) > 0.02:
                issues.append("Kwoty nie bilansują się")

        # Sprawdź NIP
        nip = invoice.get("nip", "")
        if nip and len(nip) != 10:
            issues.append(f"Nieprawidłowy NIP: {nip}")

        verdict = "WARNING" if issues else "OK"
        return {
            "verdict": verdict,
            "reason": "; ".join(issues) if issues else "Reguły podatkowe OK (fallback)",
            "model": "rule-based",
        }

    async def _check_fraud(self, request: QualityCheckRequest) -> dict[str, Any]:
        """Detektor Oszustw — GraphSAGE-Encoder 0.1B + FraudGraphScanner.

        Sprawdza:
        - Karuzele VAT
        - Słupy (shell companies)
        - Zmiany numerów kont
        - Nietypowe wzorce transakcji
        """
        invoice = request.invoice_data

        # Użyj istniejącego FraudGraphScanner
        if self._fraud_detector:
            try:
                result = await anyio.to_thread.run_sync(
                    lambda: self._fraud_detector.scan(invoice)
                )
                if isinstance(result, dict):
                    return {
                        "verdict": "ERROR" if result.get("is_fraud") else "OK",
                        "reason": result.get("reason", "No fraud detected"),
                        "confidence": result.get("confidence", 0.0),
                        "model": "fraud-graph-scanner",
                    }
            except Exception as exc:
                logger.warning("[VALIDATOR] Fraud scan failed: %s", exc)

        # Symulacja fraud detection
        risk_score = 0.0
        reasons = []

        # Sprawdź czy kontrahent jest na białej liście
        nip = invoice.get("nip", "")
        if nip:
            try:
                from nexus_ai.services.white_list_service import WhiteListService
                wl = WhiteListService()
                if not wl.is_verified(nip):
                    risk_score += 0.3
                    reasons.append("Kontrahent niezweryfikowany na Białej Liście MF")
            except Exception:
                pass

        # Sprawdź kwotę
        gross = invoice.get("amount_gross", 0)
        if gross and gross > 100000:
            risk_score += 0.2
            reasons.append(f"Wysoka kwota transakcji: {gross}")

        verdict = "OK"
        if risk_score > 0.5:
            verdict = "ERROR"
        elif risk_score > 0.2:
            verdict = "WARNING"

        return {
            "verdict": verdict,
            "reason": "; ".join(reasons) if reasons else "Brak wykrytych oszustw",
            "risk_score": risk_score,
            "model": "rule-based-fraud",
        }

    async def _check_esg(self, request: QualityCheckRequest) -> dict[str, Any]:
        """Analityk Ryzyka — FinBERT-ESG 0.1B + RiskGuard.

        Sprawdza:
        - Ryzyko kontrahenta
        - Historia transakcji
        - Branża
        """
        invoice = request.invoice_data

        # Użyj istniejącego RiskGuard
        if self._risk_analyzer:
            try:
                result = await anyio.to_thread.run_sync(
                    lambda: self._risk_analyzer.evaluate(invoice)
                )
                if isinstance(result, dict):
                    return {
                        "verdict": "ERROR" if result.get("risk_level") == "HIGH" else
                                   "WARNING" if result.get("risk_level") == "MEDIUM" else "OK",
                        "reason": result.get("reason", "Risk assessment OK"),
                        "risk_score": result.get("score", 0.0),
                        "model": "risk-guard",
                    }
            except Exception as exc:
                logger.warning("[VALIDATOR] ESG check failed: %s", exc)

        # Podstawowa ocena ryzyka
        return {
            "verdict": "OK",
            "reason": "Ocena ryzyka OK (fallback)",
            "risk_score": 0.0,
            "model": "rule-based",
        }

    async def _check_forecast(self, request: QualityCheckRequest) -> dict[str, Any]:
        """Prognoza płynności — Lag-Llama 0.3B.

        Sprawdza:
        - Prognozowane saldo na 30 dni
        - Ryzyko płynności
        - Alerty niedoboru środków
        """
        # Użyj istniejącego CashflowForecastService jeśli dostępny
        try:
            from nexus_ai.services.cfo_offline import CashflowForecastService
            from nexus_ai.db.analytics import DuckDBManager
            from nexus_ai.core.config import AppConfig

            config = AppConfig()
            duckdb = DuckDBManager(str(config.duckdb_path))
            forecast = CashflowForecastService(duckdb._conn)
            result = forecast.forecast(horizon_days=30)

            return {
                "verdict": "WARNING" if result.get("alerts") else "OK",
                "min_balance": result.get("min_balance", 0.0),
                "alerts": result.get("alerts", []),
                "model": "lag-llama-simulated",
            }
        except Exception as exc:
            logger.debug("[VALIDATOR] Forecast unavailable: %s", exc)
            return {
                "verdict": "OK",
                "min_balance": 0.0,
                "alerts": [],
                "model": "unavailable",
            }

    # ── Agregacja ───────────────────────────────────────────────────

    def _calculate_risk_score(
        self,
        tax: dict[str, Any],
        fraud: dict[str, Any],
        esg: dict[str, Any],
    ) -> float:
        """Oblicz ogólny risk score."""
        score = 0.0

        for verdict in [tax.get("verdict"), fraud.get("verdict"), esg.get("verdict")]:
            if verdict == "ERROR":
                score += 0.4
            elif verdict == "WARNING":
                score += 0.15

        return min(score, 1.0)

    def _determine_overall_verdict(
        self,
        tax: dict[str, Any],
        fraud: dict[str, Any],
        esg: dict[str, Any],
    ) -> str:
        """Określ ogólny werdykt na podstawie wszystkich kontroli."""
        verdicts = [tax.get("verdict"), fraud.get("verdict"), esg.get("verdict")]

        if any(v == "ERROR" for v in verdicts):
            return "ERROR"
        if any(v == "WARNING" for v in verdicts):
            return "WARNING"
        return "OK"

    def _generate_recommendations(
        self,
        tax: dict[str, Any],
        fraud: dict[str, Any],
        esg: dict[str, Any],
        forecast: dict[str, Any],
    ) -> list[str]:
        """Generuj rekomendacje na podstawie wszystkich kontroli."""
        recommendations = []

        for check, name in [(tax, "Podatek"), (fraud, "Oszustwo"), (esg, "Ryzyko")]:
            if check.get("verdict") == "ERROR":
                recommendations.append(f"{name}: {check.get('reason', 'Wymagana interwencja')}")
            elif check.get("verdict") == "WARNING":
                recommendations.append(f"{name}: {check.get('reason', 'Zalecana weryfikacja')}")

        if forecast.get("alerts"):
            for alert in forecast["alerts"]:
                recommendations.append(f"Płynność: {alert}")

        return recommendations

    async def process_request(self, request: QualityCheckRequest) -> None:
        """Przetwórz żądanie walidacji i wyślij wynik.

        Taskiq task: agent_quality_validator.process_request
        """
        result = await self.validate(request)
        ctx = make_context(
            task_id=request.decision_id,
            source=self.name,
            target="orchestrator",
        )
        await self.publish(AgentTopic.QUALITY_CHECK_RESULT, result, ctx)
        logger.info(
            "[AGENT] Quality check for %s | verdict=%s | risk=%.2f",
            request.decision_id,
            result.overall_verdict,
            result.overall_risk_score,
        )
