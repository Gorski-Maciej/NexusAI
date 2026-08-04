"""
Boundary Fuzz Test Generator (B3) — Automatyczne testy graniczne.
================================================================================

Część strategicznego planu 29_JDG_STRATEGIC_IMPROVEMENTS.md.
Generuje testy dla wartości granicznych na podstawie # METADATA w .rego
i thresholdów z DuckDB.

Szacowany zysk: z 5% do ~95% pokrycia testami wartości granicznych.
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# ── Data Structures ───────────────────────────────────────────────────────────


@dataclass
class BoundaryTest:
    """Pojedynczy test graniczny dla reguły."""
    rule_id: str
    parameter: str
    value: float
    expected_category: str  # "BELOW", "AT", "ABOVE"
    description: str


@dataclass
class LimitConfig:
    """Konfiguracja limitu/progu do fuzz testowania."""
    name: str
    value: float
    rule_id: str
    legal_basis: str
    unit: str = "PLN"  # PLN, EUR, PERCENT, DAYS, MONTHS


# ── Limit Extractor ───────────────────────────────────────────────────────────


class ThresholdLimitExtractor:
    """Wyciąga limity i progi z DuckDB thresholds do fuzz testowania."""

    # Znane limity JDG (z Doc 22, thresholds)
    KNOWN_LIMITS: list[LimitConfig] = [
        LimitConfig("vat_exemption_limit", 200000.0, "P58", "Art. 113 ust. 1 VAT"),
        LimitConfig("cash_transaction_limit", 15000.0, "P35", "Art. 22p PIT"),
        LimitConfig("mpp_limit", 15000.0, "P25", "Art. 108a VAT"),
        LimitConfig("car_value_kup_limit", 150000.0, "P564", "Art. 23 ust. 1 pkt 47a PIT"),
        LimitConfig("car_electric_kup_limit", 225000.0, "P565", "Art. 23 ust. 1 pkt 47a PIT"),
        LimitConfig("lump_sum_tier_1_limit", 60000.0, "P724", "Art. 81 ust. 2a u. zdrowotnej"),
        LimitConfig("lump_sum_tier_2_limit", 300000.0, "P724", "Art. 81 ust. 2b u. zdrowotnej"),
        LimitConfig("lump_sum_annual_limit_eur", 2000000.0, "P523", "Ustawa o ryczałcie"),
        LimitConfig("tax_free_amount", 30000.0, "P508", "Art. 27 ust. 1 PIT"),
        LimitConfig("tax_scale_bracket", 120000.0, "P501", "Art. 27 ust. 1 PIT"),
        LimitConfig("health_deduction_linear_limit", 12900.0, "P722", "Art. 30c ust. 2 pkt 2 PIT"),
        LimitConfig("unregistered_activity_percent", 75.0, "P930", "Art. 5 ust. 1 pkt 1 Prawa przedsiębiorców (75% od 01.07.2023; 50% do 30.06.2023; 2026: 225% kwartalnie)"),
        LimitConfig("vat_simplified_receipt_limit", 450.0, "P36", "Art. 106e VAT"),
        LimitConfig("thermo_relief_limit", 53000.0, "P623", "Art. 26h PIT"),
        LimitConfig("rd_centrum_multiplier", 200.0, "P600", "Art. 26e ust. 10 PIT"),
        LimitConfig("rd_standard_multiplier", 100.0, "P600", "Art. 26e ust. 1 PIT"),
        LimitConfig("bad_debt_creditor_days", 150.0, "P189", "Art. 89a VAT"),
        LimitConfig("bad_debt_debtor_days", 90.0, "P184", "Art. 89b VAT"),
        LimitConfig("zus_start_relief_months", 6.0, "P740", "Art. 18a SUS"),
        LimitConfig("zus_maly_plus_months", 36.0, "P741", "Art. 18c SUS"),
        LimitConfig("zus_preferential_months", 24.0, "P742", "Art. 18a SUS"),
        LimitConfig("ksef_attachment_size_mb", 200.0, "P953", "Art. 106na VAT"),
        LimitConfig("retention_years", 5.0, "P990", "Art. 86 Ordynacji"),
        LimitConfig("overpayment_refund_days", 45.0, "P1169", "Art. 72 Ordynacji"),
        LimitConfig("nip_checksum_mod", 11.0, "R0613", "Art. 3 ustawy o NIP"),
    ]

    def get_limits(self, rule_ids: list[str] | None = None) -> list[LimitConfig]:
        """Zwraca limity dla podanych rule_id (lub wszystkie)."""
        if rule_ids is None:
            return list(self.KNOWN_LIMITS)
        return [l for l in self.KNOWN_LIMITS if l.rule_id in rule_ids]


# ── Boundary Fuzz Generator ──────────────────────────────────────────────────


class BoundaryFuzzGenerator:
    """Generuje testy graniczne dla reguł z limitami.

    Dla każdego limitu generuje 7 wartości testowych:
    - Znacząco poniżej (limit - 100)
    - Tuż poniżej (limit - 1)
    - Granica zmiennoprzecinkowa (limit - 0.01)
    - Dokładnie limit
    - Granica zmiennoprzecinkowa powyżej (limit + 0.01)
    - Tuż powyżej (limit + 1)
    - Znacząco powyżej (limit + 100)

    Wzorzec: Boundary Value Analysis (BVA) — standard inżynierii testów.
    """

    def __init__(self) -> None:
        self._extractor = ThresholdLimitExtractor()

    def generate_tests(
        self, rule_ids: list[str] | None = None
    ) -> list[BoundaryTest]:
        """Generuje testy graniczne dla wszystkich (lub wybranych) reguł."""
        limits = self._extractor.get_limits(rule_ids)
        tests: list[BoundaryTest] = []

        for limit in limits:
            tests.extend(self._generate_for_limit(limit))

        return tests

    @staticmethod
    def _generate_for_limit(limit: LimitConfig) -> list[BoundaryTest]:
        """Generuje 7 testów granicznych dla pojedynczego limitu."""
        edge_values = [
            (limit.value - 100, "BELOW", "znacząco poniżej"),
            (limit.value - 1, "BELOW", "tuż poniżej"),
            (limit.value - 0.01, "BELOW", "granica zmiennoprzecinkowa poniżej"),
            (limit.value, "AT", "dokładnie limit"),
            (limit.value + 0.01, "ABOVE", "granica zmiennoprzecinkowa powyżej"),
            (limit.value + 1, "ABOVE", "tuż powyżej"),
            (limit.value + 100, "ABOVE", "znacząco powyżej"),
        ]

        return [
            BoundaryTest(
                rule_id=limit.rule_id,
                parameter=limit.name,
                value=round(val, 2),
                expected_category=category,
                description=f"[{limit.rule_id}] {limit.name} = {round(val, 2)} {limit.unit} ({desc}) — {limit.legal_basis}",
            )
            for val, category, desc in edge_values
        ]

    def generate_pytest_fixtures(
        self, output_path: Path, rule_ids: list[str] | None = None
    ) -> None:
        """Generuje plik z pytest fixtures dla testów granicznych."""
        tests = self.generate_tests(rule_ids)

        lines = [
            '"""Auto-generated boundary fuzz tests — DO NOT EDIT MANUALLY.',
            'Generated by BoundaryFuzzGenerator (B3).',
            'Part of 29_JDG_STRATEGIC_IMPROVEMENTS.md',
            '"""',
            "",
            "import pytest",
            "",
            "",
        ]

        # Grupuj testy według rule_id
        from collections import defaultdict
        grouped: dict[str, list[BoundaryTest]] = defaultdict(list)
        for t in tests:
            grouped[t.rule_id].append(t)

        for rule_id, rule_tests in sorted(grouped.items()):
            lines.append(f"# ══ {rule_id}: {len(rule_tests)} boundary tests ══")
            lines.append("")
            lines.append(f"@pytest.mark.parametrize(")
            lines.append(f'    "value,expected_category",')
            params = [
                f'    ({t.value}, "{t.expected_category}"),  # {t.description}'
                for t in rule_tests
            ]
            lines.extend(params)
            lines.append(")")
            lines.append(
                f"def test_boundary_{rule_id.lower()}"
                f"(value: float, expected_category: str) -> None:"
            )
            lines.append(f'    """Boundary fuzz test for {rule_id}."""')
            lines.append(f"    # TODO: Implement OPA evaluation for {rule_id}")
            lines.append(f"    # result = evaluate_opa_rule(\"{rule_id}\", {{value}})")
            lines.append(f"    # assert result[\"category\"] == expected_category")
            lines.append(f"    pytest.fail('Not implemented — integrate with OPA evaluator for {rule_id}')")
            lines.append("")

        output_path.write_text("\n".join(lines))
