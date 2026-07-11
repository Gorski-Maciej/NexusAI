"""
What-If Tax Arbitrage (C1) — Proaktywna optymalizacja podatkowa.
================================================================================

Część strategicznego planu 29_JDG_STRATEGIC_IMPROVEMENTS.md.
Uruchamia równoległe ewaluacje OPA z mutacjami danych wejściowych,
identyfikując korzystniejsze scenariusze podatkowe.

Guardrails: Wszystkie rekomendacje są sprawdzane przez P0-P9 (fraud/GAAR).
System NIGDY nie sugeruje działań oznaczonych jako ryzykowne.
"""

from __future__ import annotations

import asyncio
from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Any


# ── Data Structures ───────────────────────────────────────────────────────────


@dataclass
class TaxScenario:
    """Pojedynczy scenariusz podatkowy (normalny lub zmutowany)."""
    name: str
    description: str
    input_data: dict[str, Any]
    is_mutation: bool = False


@dataclass
class ScenarioResult:
    """Wynik ewaluacji pojedynczego scenariusza."""
    scenario: TaxScenario
    verdict: dict[str, Any]
    tax_total: float  # Całkowity podatek (PIT + VAT + ZUS)
    evaluation_time_ms: float


@dataclass
class TaxRecommendation:
    """Rekomendacja podatkowa dla JDG."""
    scenario: TaxScenario
    savings: float  # Oszczędność vs baseline
    explanation: str
    risk_level: str  # "LOW", "MEDIUM", "HIGH"
    blocked: bool = False  # Czy zablokowana przez GAAR/fraud?


# ── Mutation Engine ───────────────────────────────────────────────────────────


class MutationEngine:
    """Generuje zmutowane wersje input dla analizy what-if.

    Mutacje są ograniczone do legalnych strategii — nie generuje
    mutacji, które same w sobie są nielegalne (np. fałszowanie daty).
    Wszystkie mutacje reprezentują realne, legalne wybory biznesowe.
    """

    def generate_mutations(
        self, baseline: dict[str, Any]
    ) -> list[TaxScenario]:
        """Generuje listę scenariuszy what-if na podstawie baseline."""
        mutations: list[TaxScenario] = []

        jdg = baseline.get("jdg_entrepreneur", {})
        invoice = baseline.get("invoice", {})

        # Mutacja 1: Przesunięcie daty na początek następnego miesiąca
        if invoice.get("transaction_date"):
            try:
                tx_date = date.fromisoformat(str(invoice["transaction_date"]))
                next_month = tx_date.replace(day=1)
                if next_month.month == 12:
                    next_month = next_month.replace(year=next_month.year + 1, month=1)
                else:
                    next_month = next_month.replace(month=next_month.month + 1)

                if (next_month - tx_date).days <= 31:  # Tylko jeśli blisko
                    mutated = self._deep_copy(baseline)
                    mutated["invoice"]["transaction_date"] = next_month.isoformat()
                    mutations.append(TaxScenario(
                        name="delay_to_next_month",
                        description=f"Przesunięcie faktury na {next_month.isoformat()} "
                                    f"(oszczędność {abs((next_month - tx_date).days)} dni)",
                        input_data=mutated,
                        is_mutation=True,
                    ))
            except (ValueError, TypeError):
                pass

        # Mutacja 2: Zmiana formy opodatkowania (symulacja)
        current_form = jdg.get("tax_form", "PIT_SCALE")
        alternative_forms = {
            "PIT_SCALE": [("LINEAR", "Podatek liniowy 19%")],
            "LINEAR": [("PIT_SCALE", "Skala podatkowa 12%/32%")],
            "LUMP_SUM": [("PIT_SCALE", "Skala podatkowa 12%/32%")],
        }

        for alt_form, alt_desc in alternative_forms.get(current_form, []):
            mutated = self._deep_copy(baseline)
            mutated["jdg_entrepreneur"]["tax_form"] = alt_form
            mutations.append(TaxScenario(
                name=f"form_change_{current_form}_to_{alt_form}",
                description=f"Symulacja: {alt_desc} zamiast {current_form}",
                input_data=mutated,
                is_mutation=True,
            ))

        return mutations

    @staticmethod
    def _deep_copy(data: dict[str, Any]) -> dict[str, Any]:
        """Głęboka kopia słownika (bez importu copy)."""
        import json
        return json.loads(json.dumps(data))


# ── Arbitrage Engine ──────────────────────────────────────────────────────────


class WhatIfArbitrageEngine:
    """Silnik what-if: ewaluuje scenariusze i generuje rekomendacje.

    Guardrails:
    - Każda mutacja jest sprawdzana przez reguły fraud/GAAR (P0-P9)
    - Rekomendacje zablokowane przez GAAR nie są prezentowane
    - System rekomenduje tylko legalne strategie optymalizacyjne
    """

    def __init__(self) -> None:
        self._mutation_engine = MutationEngine()

    async def analyze(
        self,
        opa_client: Any,
        baseline_input: dict[str, Any],
    ) -> dict[str, Any]:
        """Przeprowadza pełną analizę what-if i zwraca rekomendacje."""
        # 1. Ewaluuj baseline
        baseline_verdict = await opa_client.evaluate(
            "data.jdg.main.final_verdict", baseline_input
        )
        baseline_tax = self._compute_total_tax(baseline_verdict)

        # 2. Generuj mutacje
        mutations = self._mutation_engine.generate_mutations(baseline_input)

        # 3. Ewaluuj wszystkie mutacje równolegle
        async def eval_scenario(scenario: TaxScenario) -> ScenarioResult:
            import time
            start = time.monotonic()
            verdict = await opa_client.evaluate(
                "data.jdg.main.final_verdict", scenario.input_data
            )
            elapsed = (time.monotonic() - start) * 1000
            return ScenarioResult(
                scenario=scenario,
                verdict=verdict,
                tax_total=self._compute_total_tax(verdict),
                evaluation_time_ms=elapsed,
            )

        results = await asyncio.gather(*[
            eval_scenario(TaxScenario("baseline", "Scenariusz bazowy", baseline_input))
        ])
        mutation_results = await asyncio.gather(*[
            eval_scenario(m) for m in mutations
        ])

        baseline_result = results[0]

        # 4. Generuj rekomendacje z guardrails
        recommendations: list[TaxRecommendation] = []
        for result in mutation_results:
            savings = baseline_tax - result.tax_total

            # Guardrail: sprawdź czy mutacja nie triggeruje fraud/GAAR
            blocked = self._is_blocked_by_fraud(result.verdict)

            if savings > 0 and not blocked:
                recommendations.append(TaxRecommendation(
                    scenario=result.scenario,
                    savings=savings,
                    explanation=self._build_explanation(result, baseline_result),
                    risk_level=self._assess_risk(result),
                    blocked=False,
                ))
            elif blocked:
                recommendations.append(TaxRecommendation(
                    scenario=result.scenario,
                    savings=0,
                    explanation="Scenariusz zablokowany przez reguły fraud/GAAR — "
                                "NIE rekomendowany",
                    risk_level="HIGH",
                    blocked=True,
                ))

        # Sortuj: największe oszczędności pierwsze
        recommendations.sort(key=lambda r: r.savings, reverse=True)

        return {
            "baseline": {
                "scenario": baseline_result.scenario.name,
                "tax_total": baseline_tax,
                "verdict": baseline_result.verdict,
            },
            "mutations_evaluated": len(mutation_results),
            "recommendations": [
                {
                    "scenario": r.scenario.name,
                    "description": r.scenario.description,
                    "savings_pln": round(r.savings, 2),
                    "risk_level": r.risk_level,
                    "blocked": r.blocked,
                    "explanation": r.explanation,
                }
                for r in recommendations
            ],
        }

    @staticmethod
    def _compute_total_tax(verdict: dict[str, Any]) -> float:
        """Oblicza przybliżony całkowity podatek z werdyktu."""
        total = 0.0
        # Pobierz rzeczywistą podstawę z werdyktu lub użyj domyślnej
        amount_net = float(verdict.get("amount_net", 0) or 0)
        if amount_net == 0:
            amount_net = 10000  # Domyślna podstawa jeśli brak danych
        # PIT
        pit_rate_str = str(verdict.get("pit_rate", "0"))
        if pit_rate_str and pit_rate_str != "0":
            rate = float(pit_rate_str.replace("%", "")) / 100
            if rate > 0:
                total += rate * amount_net
        # VAT
        vat_rate_str = str(verdict.get("vat_rate", "0"))
        if vat_rate_str and vat_rate_str not in ("0", "0.00", ""):
            total += float(vat_rate_str) * amount_net
        return total

    @staticmethod
    def _is_blocked_by_fraud(verdict: dict[str, Any]) -> bool:
        """Sprawdza czy werdykt zawiera flagi fraud/GAAR."""
        routing = verdict.get("_routing", "")
        if routing in ("BLOCK_AND_ALERT", "TRIAGE_QUEUE"):
            return True
        if verdict.get("gaar_risk") is True:
            return True
        if verdict.get("fraud_detected") is True:
            return True
        return False

    @staticmethod
    def _build_explanation(
        result: ScenarioResult, baseline: ScenarioResult
    ) -> str:
        """Buduje wyjaśnienie rekomendacji."""
        savings = baseline.tax_total - result.tax_total
        return (
            f"Scenariusz '{result.scenario.name}' oszczędza "
            f"{savings:.2f} PLN vs baseline. "
            f"{result.scenario.description}."
        )

    @staticmethod
    def _assess_risk(result: ScenarioResult) -> str:
        """Ocenia poziom ryzyka scenariusza."""
        warnings = result.verdict.get("_warnings", [])
        if len(warnings) > 3:
            return "MEDIUM"
        if any("GAAR" in str(w) or "fraud" in str(w).lower() for w in warnings):
            return "HIGH"
        return "LOW"
