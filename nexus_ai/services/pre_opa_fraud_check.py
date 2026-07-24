"""
v7.0 VAT/MPP ORKIESTRATOR — Pre-OPA Fraud Check Bridge (QF-1).

Synchroniczny bridge między VATFraudRiskScorer a regułami OPA.
Przed ewaluacją OPA, wykonuje 5-wymiarowy scoring ryzyka fraudu
i wstrzykuje wyniki jako input.risk.fraud_score do kontekstu OPA.

Raport v7.0 LUKA: vat_fraud_risk_scorer.py jest odizolowany od OPA.
Ten bridge zamyka tę lukę.

Integracja z risk.rego:
- P10: vat_fraud_risk_score — używa input.risk.fraud_score
- P11: vat_fraud_carousel_flag — używa input.risk.carousel_detected
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.pre_opa_fraud")


# ── Risk thresholds ──────────────────────────────────────────────────────────

FRAUD_GREEN_THRESHOLD = 30
FRAUD_YELLOW_THRESHOLD = 60
FRAUD_RED_THRESHOLD = 100


@dataclass
class PreOPAFraudResult:
    """Wynik pre-OPA fraud check — wstrzykiwany do input.risk."""

    fraud_score: float = 0.0
    fraud_risk_level: str = "UNKNOWN"  # GREEN, YELLOW, RED
    fraud_flags: list[str] = field(default_factory=list)
    fraud_dimensions: dict[str, float] = field(default_factory=dict)
    requires_mpp: bool = False
    requires_manual_review: bool = False
    potential_mdr: bool = False
    carousel_detected: bool = False
    carousel_entities: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)

    def to_opa_context(self) -> dict[str, Any]:
        """Konwertuj wynik do kontekstu OPA input.risk."""
        return {
            "fraud_score": self.fraud_score,
            "fraud_risk_level": self.fraud_risk_level,
            "fraud_flags": self.fraud_flags,
            "fraud_dimensions": self.fraud_dimensions,
            "requires_mpp": self.requires_mpp,
            "requires_manual_review": self.requires_manual_review,
            "potential_mdr": self.potential_mdr,
            "carousel_detected": self.carousel_detected,
            "carousel_entities": self.carousel_entities,
            "fraud_recommendations": self.recommendations,
        }


class PreOPAFraudChecker:
    """v7.0: Synchroniczny bridge VATFraudRiskScorer → OPA.

    Używany przed ewaluacją OPA do wstrzyknięcia wyników scoringu
    ryzyka fraudu do kontekstu OPA (input.risk).

    Usage:
        checker = PreOPAFraudChecker(scorer, carousel_checker)
        result = checker.check(invoice_data, contractor_data, history)
        opa_input["risk"] = result.to_opa_context()
    """

    def __init__(
        self,
        fraud_scorer: Any = None,
        carousel_checker: Any = None,
    ) -> None:
        """Inicjalizacja bridge'a.

        Args:
            fraud_scorer: Instancja VATFraudRiskScorer (opcjonalnie).
            carousel_checker: Instancja PreOPACarouselChecker (opcjonalnie).
        """
        self._scorer = fraud_scorer
        self._carousel = carousel_checker

    def check(
        self,
        invoice_data: dict[str, Any],
        contractor_data: dict[str, Any] | None = None,
        transaction_history: list[dict[str, Any]] | None = None,
    ) -> PreOPAFraudResult:
        """Wykonaj pre-OPA fraud check.

        Wykonuje synchronicznie:
        1. 5-wymiarowy scoring VATFraudRiskScorer (jeśli dostępny)
        2. Carousel detection (jeśli dostępny)
        3. Zwraca skonsolidowany wynik do wstrzyknięcia do OPA.

        Wszystkie operacje są synchroniczne — asynchroniczne
        metody scorera są wywoływane przez synchroniczny wrapper
        (jeśli scorer jest dostępny i async, używamy _run_async_sync).

        Args:
            invoice_data: Dane faktury.
            contractor_data: Dane kontrahenta.
            transaction_history: Historia transakcji.

        Returns:
            PreOPAFraudResult gotowy do wstrzyknięcia do OPA.
        """
        result = PreOPAFraudResult()

        # 1. Fraud scoring (jeśli scorer dostępny)
        if self._scorer is not None:
            try:
                score_result = self._run_scorer_sync(
                    invoice_data, contractor_data, transaction_history,
                )
                if score_result is not None:
                    result.fraud_score = score_result.get("total_score", 0.0)
                    result.fraud_risk_level = score_result.get("risk_level", "UNKNOWN")
                    result.fraud_flags = score_result.get("flags", [])
                    result.fraud_dimensions = score_result.get("dimensions", {})
                    result.requires_mpp = score_result.get("requires_mpp", False)
                    result.requires_manual_review = score_result.get(
                        "requires_manual_review", False,
                    )
                    result.potential_mdr = score_result.get("potential_mdr", False)
                    result.recommendations = score_result.get("recommendations", [])
            except Exception as exc:
                logger.warning("[PRE-OPA-FRAUD] Scoring failed: %s", exc)

        # 2. Carousel detection (jeśli checker dostępny)
        if self._carousel is not None:
            try:
                carousel_result = self._carousel.check(
                    invoice_data, contractor_data, transaction_history,
                )
                if carousel_result:
                    result.carousel_detected = carousel_result.get(
                        "carousel_detected", False,
                    )
                    result.carousel_entities = carousel_result.get("entities", [])
                    if result.carousel_detected:
                        result.fraud_risk_level = "RED"
                        result.fraud_score = max(result.fraud_score, 85.0)
                        result.fraud_flags.append(
                            f"VAT CAROUSEL: {len(result.carousel_entities)} entities"
                        )
            except Exception as exc:
                logger.warning("[PRE-OPA-FRAUD] Carousel check failed: %s", exc)

        # 3. Heurystyczna detekcja pustej faktury (QF-2)
        heuristic_flags = self._heuristic_empty_invoice_check(invoice_data)
        if heuristic_flags:
            result.fraud_flags.extend(heuristic_flags)
            result.fraud_score = max(result.fraud_score, 40.0)
            if result.fraud_risk_level == "GREEN":
                result.fraud_risk_level = "YELLOW"

        logger.info(
            "[PRE-OPA-FRAUD] Score=%.1f level=%s flags=%d carousel=%s",
            result.fraud_score,
            result.fraud_risk_level,
            len(result.fraud_flags),
            result.carousel_detected,
        )

        return result

    def _run_scorer_sync(
        self,
        invoice_data: dict[str, Any],
        contractor_data: dict[str, Any] | None,
        transaction_history: list[dict[str, Any]] | None,
    ) -> dict[str, Any] | None:
        """Synchroniczny wrapper dla async VATFraudRiskScorer.score().

        Jeśli scorer ma async metodę score(), używamy asyncio.run()
        do synchronicznego wywołania. Jeśli scorer ma synchroniczną
        metodę, wywołujemy ją bezpośrednio.
        """
        import asyncio
        import inspect

        if not self._scorer:
            return None

        score_method = getattr(self._scorer, "score", None)
        if score_method is None:
            return None

        try:
            if inspect.iscoroutinefunction(score_method):
                # Async scorer — użyj asyncio.run()
                try:
                    loop = asyncio.get_event_loop()
                    if loop.is_running():
                        # Jesteśmy już w event loopie — użyj run_coroutine_threadsafe
                        import concurrent.futures
                        future = asyncio.run_coroutine_threadsafe(
                            score_method(invoice_data, contractor_data, transaction_history),
                            loop,
                        )
                        score_obj = future.result(timeout=5.0)
                    else:
                        score_obj = asyncio.run(
                            score_method(invoice_data, contractor_data, transaction_history),
                        )
                except RuntimeError:
                    score_obj = asyncio.run(
                        score_method(invoice_data, contractor_data, transaction_history),
                    )
            else:
                # Sync scorer — wywołaj bezpośrednio
                score_obj = score_method(invoice_data, contractor_data, transaction_history)
        except Exception as exc:
            logger.warning("[PRE-OPA-FRAUD] Scorer call failed: %s", exc)
            return None

        # Konwersja obiektu na dict
        if score_obj is None:
            return None

        if hasattr(score_obj, "__dict__"):
            return {
                "total_score": getattr(score_obj, "total_score", 0.0),
                "risk_level": getattr(score_obj, "risk_level", "UNKNOWN"),
                "flags": getattr(score_obj, "flags", []),
                "dimensions": getattr(score_obj, "dimensions", {}),
                "requires_mpp": getattr(score_obj, "requires_mpp", False),
                "requires_manual_review": getattr(score_obj, "requires_manual_review", False),
                "potential_mdr": getattr(score_obj, "potential_mdr", False),
                "recommendations": getattr(score_obj, "recommendations", []),
            }

        if isinstance(score_obj, dict):
            return score_obj

        return None

    def _heuristic_empty_invoice_check(
        self, invoice_data: dict[str, Any],
    ) -> list[str]:
        """QF-2: Heurystyczna detekcja pustych faktur.

        Sprawdza:
        - Okrągła kwota (zakończona na 000) + nowy kontrahent + duża kwota
        - Brak adresu dostawy przy sprzedaży towarów
        - Okrągła kwota + brak potwierdzenia dostawy

        Returns:
            Lista flag ostrzegawczych.
        """
        flags: list[str] = []
        amount = float(invoice_data.get("amount_gross", 0))
        is_round = amount > 0 and amount % 1000 == 0
        is_new = invoice_data.get("contractor_is_new", False)
        delivery = invoice_data.get("delivery_confirmed", True)
        has_address = invoice_data.get("delivery_address", "")
        category = invoice_data.get("category_code", "")
        goods_categories = {"GOODS", "MERCHANDISE", "PRODUCTS", "RAW_MATERIALS"}

        # Okrągła kwota + nowy kontrahent + >10 000 PLN
        if is_round and is_new and amount > 10000:
            flags.append(
                f"HEURISTIC_EMPTY: Okrągła kwota {amount:.0f} PLN + nowy kontrahent"
            )

        # Brak adresu dostawy przy sprzedaży towarów
        if category in goods_categories and not has_address:
            flags.append(
                f"HEURISTIC_EMPTY: Brak adresu dostawy dla kategorii {category}"
            )

        # Okrągła kwota + brak potwierdzenia dostawy
        if is_round and not delivery and amount > 5000:
            flags.append(
                f"HEURISTIC_EMPTY: Okrągła kwota {amount:.0f} PLN + brak potwierdzenia dostawy"
            )

        return flags

    def quick_score_sync(
        self,
        amount_gross: float = 0.0,
        contractor_is_new: bool = False,
        contractor_country: str = "PL",
        category_code: str = "",
        is_first_transaction: bool = False,
    ) -> dict[str, Any]:
        """Szybki synchroniczny scoring dla prostych przypadków.

        Nie wymaga pełnego VATFraudRiskScorer — używa prostych
        heurystyk do oceny ryzyka. Przydatne gdy scorer jest
        niedostępny (fallback).

        Returns:
            Dict z podstawowym wynikiem scoringu.
        """
        score = 0.0
        flags: list[str] = []

        # Nowy kontrahent
        if contractor_is_new:
            score += 15
            flags.append("Nowy kontrahent")

        # Pierwsza transakcja
        if is_first_transaction:
            score += 10
            flags.append("Pierwsza transakcja")

        # Okrągła kwota
        if amount_gross > 0 and amount_gross % 1000 == 0:
            score += 5
            flags.append(f"Okrągła kwota: {amount_gross:.0f} PLN")

        # Wysoka kwota
        if amount_gross > 50000:
            score += 15
            flags.append(f"Wysoka kwota: {amount_gross:.0f} PLN")

        # Zagraniczny spoza UE
        eu_countries = {
            "AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
            "DE", "GR", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
            "PL", "PT", "RO", "SK", "SI", "ES", "SE",
        }
        if contractor_country and contractor_country not in eu_countries:
            score += 10
            flags.append(f"Kontrahent spoza UE: {contractor_country}")

        # Nietypowa kategoria
        unusual_categories = {"GAMBLING", "PRECIOUS_METALS", "WASTE", "PHARMA"}
        if category_code in unusual_categories:
            score += 10
            flags.append(f"Nietypowa kategoria: {category_code}")

        # Decyzja
        if score <= 30:
            risk_level = "GREEN"
        elif score <= 60:
            risk_level = "YELLOW"
        else:
            risk_level = "RED"

        return {
            "total_score": round(score, 1),
            "risk_level": risk_level,
            "flags": flags,
            "dimensions": {
                "counterparty": 0.0,
                "transaction": score,
                "chain": 0.0,
                "document": 0.0,
                "behavioral": 0.0,
            },
            "requires_mpp": score > 30,
            "requires_manual_review": risk_level in ("YELLOW", "RED"),
            "potential_mdr": risk_level == "RED",
            "recommendations": (
                ["BLOCK_AND_ALERT — wysokie ryzyko fraudu"]
                if risk_level == "RED"
                else ["TRIAGE_QUEUE — zalecana weryfikacja"]
                if risk_level == "YELLOW"
                else ["Auto-post — niskie ryzyko"]
            ),
        }
