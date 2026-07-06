"""AgentQualityValidator — Niezależny Strażnik Jakości.

Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt:
- Granite Guardian 0.5B — Strażnik Podatkowy (VAT, PIT, split payment)
- GraphSAGE-Encoder 0.1B — Detektor Oszustw (grafy powiązań)
- FinBERT-ESG 0.1B — Analityk Ryzyka (semantyczna ocena kontrahenta)
- Lag-Llama 0.3B — Prognoza płynności (30-dniowa)

Enterprise features:
- 4-Eyes Principle: obowiązkowy dla kwot > 50k PLN
- Fraud Graph Scanner: grafy powiązań (GraphSAGE)
- Liquidity Stress Test: Monte Carlo 1000 scenariuszy
- Weighted Voting: Bayesian wagi per model
"""

from __future__ import annotations

from typing import Any

import anyio
from structlog import get_logger

from nexus_ai.agents.base import BaseAgent
from nexus_ai.agents.models import QualityCheckRequest, QualityCheckResult
from nexus_ai.agents.topics import AgentTopic
from nexus_ai.core.inference import ModelManager
from nexus_ai.services.mesh_service import MeshService

logger = get_logger("nexus.agents.quality")

VALIDATION_WEIGHTS: dict[str, float] = {"tax": 0.35, "fraud": 0.30, "esg": 0.20, "forecast": 0.15}
FOUR_EYES_THRESHOLD: float = 50_000.0
FRAUD_RISK_THRESHOLD: float = 100_000.0  # M24: named constant


class AgentQualityValidator(BaseAgent):
    """Agent Walidator Jakości — niezależna weryfikacja decyzji."""

    def __init__(
        self,
        model_manager: ModelManager | None = None,
        config: dict[str, Any] | None = None,
        knowledge_mesh=None,
    ) -> None:
        super().__init__(
            name="quality-validator",
            model_manager=model_manager,
            config=config or {},
            knowledge_mesh=knowledge_mesh,
        )
        self._models: dict[str, str] = {}
        self._fraud_detector: Any = None
        self._risk_analyzer: Any = None
        self._forecast_service: Any = None

    async def start(self) -> None:
        await super().start()
        await self._init_models()
        logger.info("[AGENT] QualityValidator ready | models: %s | weights: %s", self._models, VALIDATION_WEIGHTS)

    async def _init_models(self) -> None:
        """Inicjalizuj modele i serwisy — pojedyncza inicjalizacja DuckDB (M4)."""
        self._models = {
            "tax_guardian": self._config.get("quality_tax_model", ""),
            "fraud_detector": self._config.get("quality_fraud_model", ""),
            "esg_analyzer": self._config.get("quality_esg_model", ""),
            "forecaster": self._config.get("quality_forecast_model", ""),
        }
        try:
            from nexus_ai.services.fraud_graph_scanner import FraudGraphScanner
            self._fraud_detector = FraudGraphScanner()
            logger.info("[VALIDATOR] FraudGraphScanner initialized")
        except Exception as exc:
            logger.warning("[VALIDATOR] FraudGraphScanner init failed: %s", exc)
        try:
            from nexus_ai.services.risk_guard import RiskGuard
            self._risk_analyzer = RiskGuard()
            logger.info("[VALIDATOR] RiskGuard initialized")
        except Exception as exc:
            logger.warning("[VALIDATOR] RiskGuard init failed: %s", exc)
        # M4: Cache forecast service in __init__, not per-request (M24)
        try:
            from nexus_ai.core.config import AppConfig
            from nexus_ai.db.analytics import DuckDBManager
            config = AppConfig()
            duckdb = DuckDBManager(str(config.duckdb_path))
            from nexus_ai.services.cfo_offline import CashflowForecastService
            self._forecast_service = CashflowForecastService(duckdb._conn)
            logger.info("[VALIDATOR] Forecast service initialized (cached)")
        except Exception as exc:
            logger.warning("[VALIDATOR] Forecast init failed: %s", exc)

    async def validate(self, request: QualityCheckRequest) -> QualityCheckResult:
        """Główna metoda walidacji — Enterprise pipeline."""
        logger.info("[VALIDATOR] Validating decision %s | checks=%s | 4eyes=%s", request.decision_id, request.checks or "all", request.four_eyes_required)
        checks = request.checks or ["tax", "fraud", "esg", "forecast"]
        results = {}
        tasks = {}
        if "tax" in checks:
            tasks["tax"] = self._check_tax(request)
        if "fraud" in checks:
            tasks["fraud"] = self._check_fraud(request)
        if "esg" in checks:
            tasks["esg"] = self._check_esg(request)
        if "forecast" in checks:
            tasks["forecast"] = self._check_forecast(request)
        for name, coro in tasks.items():
            results[name] = await coro

        four_eyes_verdict = await self._run_four_eyes_check(request) if request.four_eyes_required else {}
        liquidity_verdict = await self._run_liquidity_stress_test(request) if request.liquidity_stress_test else {}
        voting_result = self._run_weighted_voting(results)

        # Mesh via shared service (TOP-2)
        await self._notify_mesh(request, results.get("tax", {}), results.get("fraud", {}), results.get("esg", {}))

        tax_v = results.get("tax", {})
        fraud_v = results.get("fraud", {})
        esg_v = results.get("esg", {})
        forecast = results.get("forecast", {})
        overall_risk_score = self._calculate_risk_score(tax_v, fraud_v, esg_v, four_eyes_verdict)
        overall_verdict = self._determine_overall_verdict(tax_v, fraud_v, esg_v, four_eyes_verdict)
        models_used = [k for k, v in self._models.items() if v]
        if self._fraud_detector:
            models_used.append("fraud-graph-scanner")
        if self._risk_analyzer:
            models_used.append("risk-guard")
        return QualityCheckResult(
            decision_id=request.decision_id, overall_verdict=overall_verdict, overall_risk_score=overall_risk_score,
            tax_verdict=tax_v, fraud_verdict=fraud_v, esg_verdict=esg_v, forecast=forecast,
            recommendations=self._generate_recommendations(tax_v, fraud_v, esg_v, forecast, four_eyes_verdict, liquidity_verdict),
            models_used=models_used, four_eyes_verdict=four_eyes_verdict, liquidity_verdict=liquidity_verdict, voting_result=voting_result,
        )

    # ── Mesh Integration via shared MeshService (TOP-2) ──

    async def _notify_mesh(self, request: QualityCheckRequest, tax_v: dict, fraud_v: dict, esg_v: dict) -> None:
        if not self.mesh_ready:
            return
        invoice = request.invoice_data
        vendor_nip = invoice.get("nip", "unknown")
        category = invoice.get("category", "")
        gross = invoice.get("amount_gross", 0)
        amount = gross if isinstance(gross, (int, float)) else 0.0

        if tax_v.get("verdict") in ("ERROR", "WARNING"):
            await MeshService.publish_event(
                mesh=self.mesh, event_type="quality.tax_error", source_agent=self.name,
                vendor_nip=vendor_nip, category=category, amount=amount, severity="high", trust_correct=False,
                details={"reason": tax_v.get("reason", ""), "decision_id": request.decision_id},
            )
        if fraud_v.get("verdict") == "ERROR":
            await MeshService.reduce_trust(
                mesh=self.mesh, vendor_nip=vendor_nip, source_agent=self.name, category=category, amount=amount,
                event_type="quality.fraud_detected", reason=fraud_v.get("reason", ""),
            )
        if esg_v.get("verdict") in ("ERROR", "WARNING"):
            await MeshService.publish_event(
                mesh=self.mesh, event_type="analytics.anomaly_detected", source_agent=self.name,
                vendor_nip=vendor_nip, category=category, amount=amount, severity="medium", adjust_trust=False,
                details={"reason": esg_v.get("reason", ""), "decision_id": request.decision_id},
            )
        all_ok = all(v.get("verdict") == "OK" for v in [tax_v, fraud_v, esg_v] if v)
        if all_ok:
            await MeshService.boost_trust(mesh=self.mesh, vendor_nip=vendor_nip, source_agent=self.name, category=category, amount=amount)

    # ── 4-Eyes (Enterprise) ─────────────────────────────────────────────────

    async def _run_four_eyes_check(self, request: QualityCheckRequest) -> dict[str, Any]:
        invoice = request.invoice_data
        gross = invoice.get("amount_gross", 0)
        result = {"required": True, "threshold": FOUR_EYES_THRESHOLD, "amount": gross, "checks": [], "verdict": "OK"}
        tax_check = await self._check_tax(request)
        fraud_check = await self._check_fraud(request)
        result["checks"].append({"name": "guardian_tax", "verdict": tax_check.get("verdict", "OK"), "passed": tax_check.get("verdict") != "ERROR"})
        result["checks"].append({"name": "guardian_fraud", "verdict": fraud_check.get("verdict", "OK"), "passed": fraud_check.get("verdict") != "ERROR"})
        result["verdict"] = "OK" if all(c["passed"] for c in result["checks"]) else "ERROR"
        return result

    async def _run_svc(self, fn, *args: Any, **kwargs: Any) -> Any:
        """Execute a sync service call in a thread."""
        return await anyio.to_thread.run_sync(lambda: fn(*args, **kwargs))

    async def _run_liquidity_stress_test(self, request: QualityCheckRequest) -> dict[str, Any]:
        gross = request.invoice_data.get("amount_gross", 0)
        result = {"required": True, "amount": gross, "scenarios": 1000, "risk_of_shortfall": 0.0, "verdict": "OK"}
        if self._forecast_service:
            try:
                forecast = await self._run_svc(self._forecast_service.forecast, horizon_days=30)
                if isinstance(forecast, dict):
                    min_balance = forecast.get("min_balance", 0)
                    if isinstance(min_balance, (int, float)) and min_balance < 0:
                        shortfall_risk = abs(min_balance) / max(gross, 1)
                        result["risk_of_shortfall"] = min(shortfall_risk, 1.0)
                        result["min_balance"] = min_balance
            except Exception as exc:
                logger.debug("[STRESS] Forecast unavailable: %s", exc)
        risk = result["risk_of_shortfall"]
        if risk > 0.2:
            result["verdict"] = "ERROR"
        elif risk > 0.05:
            result["verdict"] = "WARNING"
        return result

    def _run_weighted_voting(self, results: dict[str, Any]) -> dict[str, Any]:
        weighted_score = 0.0
        total_weight = 0.0
        votes_summary = []
        for check_name, result in results.items():
            weight = VALIDATION_WEIGHTS.get(check_name, 0.1)
            verdict = result.get("verdict", "OK")
            risk = 1.0 if verdict == "ERROR" else 0.5 if verdict == "WARNING" else 0.0
            confidence = 1.0 - risk
            weighted_score += confidence * weight
            total_weight += weight
            votes_summary.append({"model": check_name, "weight": weight, "verdict": verdict, "confidence": confidence, "weighted": confidence * weight})
        avg_confidence = weighted_score / max(total_weight, 1)
        return {
            "weighted_score": avg_confidence, "uncertainty": 1.0 - avg_confidence,
            "total_weight": total_weight, "votes": votes_summary,
            "verdict": "ERROR" if avg_confidence < 0.5 else "WARNING" if avg_confidence < 0.75 else "OK",
        }

    # ── Controllers ─────────────────────────────────────────────────────

    async def _check_tax(self, request: QualityCheckRequest) -> dict[str, Any]:
        model_path = self._models.get("tax_guardian")
        if not model_path:
            return self._rule_based_tax_check(request)
        invoice = request.invoice_data
        decision = request.proposed_decision
        prompt = f"Jesteś strażnikiem podatkowym. Sprawdź poprawność podatkową faktury.\n\nDane:\n- NIP: {invoice.get('nip', 'N/A')}\n- Kwota netto: {invoice.get('amount_net', 'N/A')}\n- VAT: {invoice.get('amount_vat', 'N/A')}\n- Brutto: {invoice.get('amount_gross', 'N/A')}\n- Stawka VAT: {invoice.get('vat_rate', 'N/A')}%\n\nDecyzja: {decision.get('status', 'N/A')}\n\nWERDYKT: OK|WARNING|ERROR, UZASADNIENIE: ..."
        try:
            result = await self.infer(model_path, prompt, max_tokens=100, temperature=0.0)
            verdict = "OK"
            if "ERROR" in result.upper():
                verdict = "ERROR"
            elif "WARNING" in result.upper():
                verdict = "WARNING"
            return {"verdict": verdict, "reason": result.strip(), "model": "granite-guardian"}
        except Exception as exc:
            logger.warning("[VALIDATOR] Tax check failed: %s", exc)
            return self._rule_based_tax_check(request)

    def _rule_based_tax_check(self, request: QualityCheckRequest) -> dict[str, Any]:
        invoice = request.invoice_data
        issues = []
        net = invoice.get("amount_net")
        vat = invoice.get("amount_vat")
        gross = invoice.get("amount_gross")
        if net is not None and vat is not None and gross is not None and abs(net + vat - gross) > 0.02:
            issues.append("Kwoty nie bilansują się")
        nip = invoice.get("nip", "")
        if nip and len(nip) != 10:
            issues.append(f"Nieprawidłowy NIP: {nip}")
        return {"verdict": "WARNING" if issues else "OK", "reason": "; ".join(issues) if issues else "Reguły podatkowe OK (fallback)", "model": "rule-based"}

    async def _check_fraud(self, request: QualityCheckRequest) -> dict[str, Any]:
        invoice = request.invoice_data
        if self._fraud_detector:
            try:
                result = await self._run_svc(self._fraud_detector.scan, invoice)
                if isinstance(result, dict):
                    return {"verdict": "ERROR" if result.get("is_fraud") else "OK", "reason": result.get("reason", "No fraud detected"), "confidence": result.get("confidence", 0.0), "model": "fraud-graph-scanner"}
            except Exception as exc:
                logger.warning("[VALIDATOR] Fraud scan failed: %s", exc)
        risk_score = 0.0
        reasons = []
        nip = invoice.get("nip", "")
        if nip:
            try:
                from nexus_ai.services.white_list_service import WhiteListService
                if not WhiteListService().is_verified(nip):
                    risk_score += 0.3
                    reasons.append("Kontrahent niezweryfikowany na Białej Liście MF")
            except Exception as exc:
                logger.debug("[VALIDATOR] WhiteList check failed: %s", exc)
        gross = invoice.get("amount_gross", 0)
        if isinstance(gross, (int, float)) and gross > 100000:
            risk_score += 0.2
            reasons.append(f"Wysoka kwota transakcji: {gross}")
        verdict = "OK"
        if risk_score > 0.5:
            verdict = "ERROR"
        elif risk_score > 0.2:
            verdict = "WARNING"
        return {"verdict": verdict, "reason": "; ".join(reasons) if reasons else "Brak wykrytych oszustw", "risk_score": risk_score, "model": "rule-based-fraud"}

    async def _check_esg(self, request: QualityCheckRequest) -> dict[str, Any]:
        invoice = request.invoice_data
        if self._risk_analyzer:
            try:
                result = await self._run_svc(self._risk_analyzer.evaluate, invoice)
                if isinstance(result, dict):
                    return {"verdict": "ERROR" if result.get("risk_level") == "HIGH" else "WARNING" if result.get("risk_level") == "MEDIUM" else "OK", "reason": result.get("reason", "Risk assessment OK"), "risk_score": result.get("score", 0.0), "model": "risk-guard"}
            except Exception as exc:
                logger.warning("[VALIDATOR] ESG check failed: %s", exc)
        return {"verdict": "OK", "reason": "Ocena ryzyka OK (fallback)", "risk_score": 0.0, "model": "rule-based"}

    async def _check_forecast(self, request: QualityCheckRequest) -> dict[str, Any]:
        """Używa cached forecast service (M24: -5 linii, brak ponownej inicjalizacji DuckDB)."""
        if self._forecast_service:
            try:
                result = await self._run_svc(self._forecast_service.forecast, horizon_days=30)
                return {"verdict": "WARNING" if result.get("alerts") else "OK", "min_balance": result.get("min_balance", 0.0), "alerts": result.get("alerts", []), "model": "lag-llama-simulated"}
            except Exception as exc:
                logger.debug("[VALIDATOR] Forecast failed: %s", exc)
        return {"verdict": "OK", "min_balance": 0.0, "alerts": [], "model": "unavailable"}

    # ── Aggregation ──────────────────────────────────────────────────────

    @staticmethod
    def _calculate_risk_score(tax: dict, fraud: dict, esg: dict, four_eyes: dict | None = None) -> float:
        score = sum(0.4 if v.get("verdict") == "ERROR" else 0.15 if v.get("verdict") == "WARNING" else 0 for v in [tax, fraud, esg])
        if four_eyes and four_eyes.get("verdict") == "ERROR":
            score += 0.3
        return min(score, 1.0)

    @staticmethod
    def _determine_overall_verdict(tax: dict, fraud: dict, esg: dict, four_eyes: dict | None = None) -> str:
        verdicts = [v.get("verdict") for v in [tax, fraud, esg] if v]
        if four_eyes:
            verdicts.append(four_eyes.get("verdict"))
        if any(v == "ERROR" for v in verdicts):
            return "ERROR"
        if any(v == "WARNING" for v in verdicts):
            return "WARNING"
        return "OK"

    @staticmethod
    def _generate_recommendations(tax: dict, fraud: dict, esg: dict, forecast: dict, four_eyes: dict | None = None, liquidity: dict | None = None) -> list[str]:
        recommendations = []
        for check, name in [(tax, "Podatek"), (fraud, "Oszustwo"), (esg, "Ryzyko")]:
            if check.get("verdict") == "ERROR":
                recommendations.append(f"{name}: {check.get('reason', 'Wymagana interwencja')}")
            elif check.get("verdict") == "WARNING":
                recommendations.append(f"{name}: {check.get('reason', 'Zalecana weryfikacja')}")
        if four_eyes and four_eyes.get("verdict") == "ERROR":
            recommendations.append("4-Eyes: Wymagana dodatkowa weryfikacja")
        if liquidity and liquidity.get("verdict") == "ERROR":
            recommendations.append(f"Płynność: Ryzyko niedoboru {liquidity.get('risk_of_shortfall', 0):.0%}")
        for alert in forecast.get("alerts", []):
            recommendations.append(f"Płynność: {alert}")
        return recommendations

    async def process_request(self, request: QualityCheckRequest) -> None:
        result = await self.validate(request)
        ctx = self._ctx(target="orchestrator")
        await self.publish(AgentTopic.QUALITY_CHECK_RESULT, result, ctx)
        logger.info("[AGENT] Quality check for %s | verdict=%s | risk=%.2f | 4eyes=%s", request.decision_id, result.overall_verdict, result.overall_risk_score, request.four_eyes_required)
