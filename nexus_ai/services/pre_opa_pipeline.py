"""
v7.0 VAT/MPP ORKIESTRATOR — Pre-OPA Pipeline (Integration Bridge).

Orchestrates all pre-OPA checks before OPA evaluation:
1. MPP Annex 15 check (opa_mpp_bridge.py)
2. VAT Fraud Risk Scoring (pre_opa_fraud_check.py)
3. VAT Carousel Detection (pre_opa_carousel_check.py)
4. GTU Auto-Assignment (gtu_auto_assigner.py)
5. VAT Exemption Forecast (200k limit tracker)

Results are injected into the OPA input context under:
- input.invoice.mpp_*  (MPP check results)
- input.risk.fraud_*    (fraud risk scoring)
- input.risk.carousel_* (carousel detection)
- input.invoice.gtu_*   (GTU assignment)

This is the SINGLE ENTRY POINT for all pre-OPA intelligence.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.pre_opa_pipeline")


@dataclass
class PreOPAResult:
    """Skonsolidowany wynik wszystkich pre-OPA checków."""

    mpp_context: dict[str, Any] = field(default_factory=dict)
    fraud_context: dict[str, Any] = field(default_factory=dict)
    carousel_context: dict[str, Any] = field(default_factory=dict)
    gtu_context: dict[str, Any] = field(default_factory=dict)
    exemption_forecast: dict[str, Any] = field(default_factory=dict)
    requires_block: bool = False
    block_reason: str = ""
    all_warnings: list[str] = field(default_factory=list)

    def to_opa_input(self) -> dict[str, Any]:
        """Konwertuj do formatu OPA input."""
        opa_invoice = {}
        opa_invoice.update(self.mpp_context)
        opa_invoice.update(self.gtu_context)
        opa_invoice.update(self.exemption_forecast)

        opa_risk = {}
        opa_risk.update(self.fraud_context)
        opa_risk.update(self.carousel_context)

        return {
            "invoice": opa_invoice,
            "risk": opa_risk,
        }


class PreOPAPipeline:
    """v7.0: Centralny pipeline pre-OPA checków.

    Wywołuje wszystkie bridge'i przed ewaluacją OPA i konsoliduje
    wyniki do jednego kontekstu input.

    Usage:
        pipeline = PreOPAPipeline(
            mpp_bridge=OPAMPPBridge(mpp_engine),
            fraud_checker=PreOPAFraudChecker(scorer, carousel_checker),
            carousel_checker=PreOPACarouselChecker(),
            gtu_assigner=GTUAutoAssigner(),
            ksef_b2c_engine=KSeFB2CEngine(),
        )
        result = pipeline.run(invoice_data, contractor_data, history)
        opa_input.update(result.to_opa_input())
        # Teraz OPA widzi input.invoice.mpp_*, input.risk.fraud_*, etc.

    INTEGRATION POINT:
        Wywołaj PreOPAPipeline.run() przed ewaluacją OPA w warstwie przetwarzania faktur.
        Miejsce integracji: nexus_ai/tax/opa_evaluator.py lub task processor outbox.
        Przykład:
            from nexus_ai.services.pre_opa_pipeline import PreOPAPipeline
            pipeline = build_pre_opa_pipeline()  # factory z injected dependencies
            pre_opa = pipeline.run(invoice_data, contractor_data, history)
            opa_input = merge_dicts(base_opa_input, pre_opa.to_opa_input())
            verdict = opa.evaluate(opa_input)
    """

    def __init__(
        self,
        mpp_bridge: Any = None,
        fraud_checker: Any = None,
        carousel_checker: Any = None,
        gtu_assigner: Any = None,
        ksef_b2c_engine: Any = None,
    ) -> None:
        self._mpp_bridge = mpp_bridge
        self._fraud_checker = fraud_checker
        self._carousel_checker = carousel_checker
        self._gtu_assigner = gtu_assigner
        self._ksef_b2c_engine = ksef_b2c_engine

    def run(
        self,
        invoice_data: dict[str, Any],
        contractor_data: dict[str, Any] | None = None,
        transaction_history: list[dict[str, Any]] | None = None,
    ) -> PreOPAResult:
        """Uruchom wszystkie pre-OPA checki.

        Args:
            invoice_data: Dane faktury (amount_gross, category_code, cn_code, etc.).
            contractor_data: Dane kontrahenta (NIP, data rejestracji, etc.).
            transaction_history: Historia transakcji.

        Returns:
            PreOPAResult z wynikami wszystkich checków.
        """
        result = PreOPAResult()
        warnings: list[str] = []

        # 1. MPP Annex 15 Check
        if self._mpp_bridge:
            try:
                cn_code = invoice_data.get("cn_code", "")
                amount_gross = float(invoice_data.get("amount_gross", 0))
                is_split = invoice_data.get("split_payment_used", False)
                description = invoice_data.get("item_name", "")
                contractor_nip = contractor_data.get("nip", "") if contractor_data else ""

                mpp_ctx = self._mpp_bridge.evaluate(
                    invoice_data=invoice_data,
                    cn_code=cn_code,
                    amount_gross=amount_gross,
                    is_split_payment_used=is_split,
                    description=description,
                    contractor_nip=contractor_nip,
                )
                result.mpp_context = mpp_ctx.to_opa_input()

                if mpp_ctx.mpp_mandatory and not is_split:
                    result.requires_block = True
                    result.block_reason = "MPP required but not used"
                    warnings.append(mpp_ctx.mpp_sanction_warning)

                logger.info(
                    "[PIPELINE] MPP check: mandatory=%s items=%d",
                    mpp_ctx.mpp_mandatory,
                    len(mpp_ctx.mpp_items_matched),
                )
            except Exception as exc:
                logger.warning("[PIPELINE] MPP check failed: %s", exc)

        # 2. Fraud Risk Scoring + Carousel
        if self._fraud_checker:
            try:
                fraud_result = self._fraud_checker.check(
                    invoice_data, contractor_data, transaction_history,
                )
                result.fraud_context = fraud_result.to_opa_context()
                result.carousel_context = {
                    "carousel_detected": fraud_result.carousel_detected,
                    "carousel_entities": fraud_result.carousel_entities,
                }

                if fraud_result.fraud_risk_level == "RED":
                    result.requires_block = True
                    if not result.block_reason:
                        result.block_reason = f"Fraud score RED: {fraud_result.fraud_score:.0f}"
                    warnings.extend(fraud_result.recommendations)

                logger.info(
                    "[PIPELINE] Fraud check: score=%.1f level=%s carousel=%s",
                    fraud_result.fraud_score,
                    fraud_result.fraud_risk_level,
                    fraud_result.carousel_detected,
                )
            except Exception as exc:
                logger.warning("[PIPELINE] Fraud check failed: %s", exc)

        # 3. Dedicated Carousel Check (if separate from fraud checker)
        elif self._carousel_checker:
            try:
                carousel_result = self._carousel_checker.check(
                    invoice_data, contractor_data, transaction_history,
                )
                result.carousel_context = carousel_result

                if carousel_result.get("carousel_detected"):
                    result.requires_block = True
                    result.block_reason = "VAT carousel detected"
                    warnings.append(carousel_result.get("carousel_recommendation", ""))
            except Exception as exc:
                logger.warning("[PIPELINE] Carousel check failed: %s", exc)

        # 4. GTU Auto-Assignment
        if self._gtu_assigner:
            try:
                description = invoice_data.get("item_name", "")
                category_code = invoice_data.get("category_code", "")
                cn_code = invoice_data.get("cn_code", "")
                pkwiu_code = invoice_data.get("pkwiu_code", "")

                gtu_result = self._gtu_assigner.assign(
                    description=description,
                    category_code=category_code,
                    cn_code=cn_code,
                    pkwiu_code=pkwiu_code,
                )
                result.gtu_context = {
                    "gtu_code": gtu_result.primary_assignment.gtu_code,
                    "gtu_description": gtu_result.primary_assignment.gtu_description,
                    "gtu_confidence": gtu_result.primary_assignment.confidence,
                    "gtu_method": gtu_result.primary_assignment.method,
                    "gtu_alternative_codes": gtu_result.primary_assignment.alternative_codes,
                    "gtu_requires_review": gtu_result.requires_manual_review,
                }
                logger.info(
                    "[PIPELINE] GTU: %s confidence=%.2f method=%s",
                    gtu_result.primary_assignment.gtu_code,
                    gtu_result.primary_assignment.confidence,
                    gtu_result.primary_assignment.method,
                )
            except Exception as exc:
                logger.warning("[PIPELINE] GTU check failed: %s", exc)

        # 5. KSeF B2C Compliance Check (v7.0 NEW — naprawia lukę KSeF B2C 0/5)
        if self._ksef_b2c_engine:
            try:
                b2c_result = self._ksef_b2c_engine.evaluate_b2c_requirement(
                    invoice_data=invoice_data,
                    contractor_data=contractor_data,
                )
                result.mpp_context["ksef_b2c_applies"] = b2c_result.b2c_applies
                result.mpp_context["ksef_b2c_consumer_consent_required"] = b2c_result.consumer_consent_required
                result.mpp_context["ksef_b2c_exemption"] = b2c_result.exemption_reason

                if b2c_result.b2c_applies and not b2c_result.consumer_consent_required:
                    warnings.append(
                        f"KSeF B2C wymagane od 2026-07-01 — faktura {invoice_data.get('amount_gross', 0):.2f} PLN. "
                        f"Konsument musi wyrazić zgodę (opt-in)."
                    )

                logger.info(
                    "[PIPELINE] KSeF B2C: applies=%s consent=%s exemption=%s",
                    b2c_result.b2c_applies,
                    b2c_result.consumer_consent_required,
                    b2c_result.exemption_reason,
                )
            except Exception as exc:
                logger.warning("[PIPELINE] KSeF B2C check failed: %s", exc)

        # 6. VAT Exemption Forecast (200k limit)
        try:
            ytd_sales = float(invoice_data.get("sales_ytd_vat_exempt", 0))
            if ytd_sales > 100000:  # > 50% of 200k limit
                import pendulum
                days_elapsed = int(invoice_data.get("days_elapsed_this_year", 182))
                if days_elapsed > 0 and ytd_sales > 0:
                    daily_avg = ytd_sales / days_elapsed
                    remaining = 200000 - ytd_sales
                    days_remaining = int(remaining / daily_avg) if daily_avg > 0 else 999
                    forecast_date = pendulum.now("UTC").add(days=days_remaining)
                    result.exemption_forecast = {
                        "vat_breach_forecast": True,
                        "vat_breach_days_remaining": days_remaining,
                        "vat_breach_forecast_date": forecast_date.strftime("%Y-%m-%d"),
                        "daily_avg": round(daily_avg, 2),
                        "ytd_sales": round(ytd_sales, 2),
                        "remaining_headroom": round(remaining, 2),
                    }
                    warnings.append(
                        f"Limit VAT 200k: prognoza przekroczenia ~{forecast_date.strftime('%Y-%m-%d')} "
                        f"(za {days_remaining} dni, YTD: {ytd_sales:.0f} PLN)"
                    )
        except Exception as exc:
            logger.warning("[PIPELINE] Exemption forecast failed: %s", exc)

        result.all_warnings = warnings

        logger.info(
            "[PIPELINE] Complete: block=%s mpp=%s fraud=%s carousel=%s gtu=%s forecast=%s",
            result.requires_block,
            bool(result.mpp_context),
            bool(result.fraud_context),
            bool(result.carousel_context.get("carousel_detected")),
            bool(result.gtu_context.get("gtu_code")),
            bool(result.exemption_forecast),
        )

        return result
