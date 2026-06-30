"""
Trace Generator -- generator ścieżki decyzyjnej (Element 1).

Komponent, który na podstawie werdyktu Zen‑Engine (oraz śladu ewaluacji)
generuje czytelny dla człowieka opis decyzji podatkowej.

Dwa podejścia:
  A (szablony) -- description_template z reguły z podmianą {placeholder}
  B (domyślny) -- automatyczny opis z werdyktu i kontekstu

Usage:
    generator = TraceGenerator()
    text = generator.generate(rule, context, verdict)
    trace = generator.generate_trace_json(evaluated_rules, verdict, context)
"""

from __future__ import annotations

import re
from typing import Any, final

from nexus_ai.core.msgspec_utils import msgspec_dumps

# ── Human-readable labels for verdict fields ─────────────────────────────

_VERDICT_LABELS: dict[str, dict[str, str]] = {
    "vat_rate": {},
    "income_tax_qualification": {
        "deductible_full": "odliczenie pełne",
        "deductible_limit": "odliczenie limitowane",
        "non_deductible": "brak odliczenia",
    },
    "rounding_level": {
        "position": "zaokrąglanie per pozycja",
        "total": "zaokrąglanie od sumy",
    },
    "gtu_code": {},
    "procedure": {
        "VAT_REVERSE_CHARGE": "odwrotne obciążenie VAT",
        "IMPORT": "import towarów",
        "MPP": "mechanizm podzielonej płatności",
        "SPLIT_PAYMENT": "mechanizm podzielonej płatności",
    },
    "transaction_mark": {
        "TP": "transakcja powiązana",
        "SW": "świadczenie usług",
    },
}

# ── Default template ────────────────────────────────────────────────────

DEFAULT_DESCRIPTION_TEMPLATE = (
    "Reguła {rule_id}: dla kategorii {category_code} "
    "(data {transaction_date}) – "
    "stawka VAT {vat_rate_percent}%, {income_tax_qualification_label}, "
    "metoda {rounding_level_label}{procedure_suffix}"
)

# ── Template field extractor ────────────────────────────────────────────

_TEMPLATE_PATTERN = re.compile(r"\{(\w+)\}")


@final
class TraceGenerator:
    """Generator Ścieżki Decyzyjnej -- tworzy czytelny opis decyzji.

    Usage:
        generator = TraceGenerator()
        text = generator.generate(rule, context, verdict)
    """

    @staticmethod
    def generate(
        rule: dict[str, Any] | None = None,
        context: dict[str, Any] | None = None,
        verdict: dict[str, Any] | None = None,
    ) -> str:
        """Generuj czytelny opis decyzji podatkowej.

        Używa szablonu z reguły (description_template), jeśli istnieje.
        W przeciwnym razie używa domyślnego szablonu.

        Args:
            rule: Słownik reguły (może zawierać ``description_template``,
                  ``rule_id``, ``condition_sql``).
            context: Słownik kontekstu (category_code, transaction_date, …).
            verdict: Słownik werdyktu (vat_rate, income_tax_qualification, …).

        Returns:
            Sformatowany tekst ścieżki decyzyjnej.
        """
        rule = rule or {}
        context = context or {}
        verdict = verdict or {}

        # Wybierz szablon
        template = rule.get("description_template") or DEFAULT_DESCRIPTION_TEMPLATE

        # Zbuduj słownik podmian
        replacements: dict[str, str] = {}

        # Podstawowe pola z kontekstu
        replacements["rule_id"] = str(rule.get("rule_id", "?"))
        for key in (
            "category_code",
            "transaction_date",
            "vendor_country",
            "company_tax_form",
            "vendor_vat_status",
        ):
            replacements[key] = str(context.get(key, "?"))

        # Pola z werdyktu
        vat_rate = verdict.get("vat_rate", "?")
        if vat_rate != "?":
            try:
                vat_rate_percent = int(float(str(vat_rate)) * 100)
            except (ValueError, TypeError):
                vat_rate_percent = "?"
        else:
            vat_rate_percent = "?"
        replacements["vat_rate_percent"] = str(vat_rate_percent)

        # Pozostałe pola werdyktu
        for key in (
            "vat_rate",
            "rounding_level",
            "income_tax_qualification",
            "gtu_code",
            "procedure",
            "transaction_mark",
        ):
            replacements[key] = str(verdict.get(key, "?"))

        # Pola z czytelnymi etykietami
        income_label = _resolve_label(verdict, "income_tax_qualification")
        rounding_label = _resolve_label(verdict, "rounding_level")
        procedure_label = _resolve_label(verdict, "procedure")
        replacements["income_tax_qualification_label"] = income_label
        replacements["rounding_level_label"] = rounding_label
        replacements["procedure_label"] = procedure_label

        # Procedure suffix (dla domyślnego szablonu)
        raw_procedure = verdict.get("procedure")
        if raw_procedure and procedure_label and procedure_label != "?":
            replacements["procedure_suffix"] = f", {procedure_label}"
        else:
            replacements["procedure_suffix"] = ""

        # Condition SQL (dla szczegółowego śladu)
        replacements["condition_sql"] = str(rule.get("condition_sql", ""))

        # Wszystkie pozostałe klucze z kontekstu i werdyktu jako fallback
        # (np. fc_vat_rate, fc_total_net dla reguł field-confidence)
        for k, v in context.items():
            if k not in replacements:
                replacements[k] = str(v)
        for k, v in verdict.items():
            if k not in replacements:
                replacements[k] = str(v)

        # Podstaw wszystkie {key} z replacements
        def _replacer(m: re.Match) -> str:
            key = m.group(1)
            return replacements.get(key, f"?{{{key}}}")

        result = _TEMPLATE_PATTERN.sub(_replacer, template)

        return result

    @staticmethod
    def generate_trace_json(
        evaluated_rules: list[dict[str, Any]] | None = None,
        final_verdict: dict[str, Any] | None = None,
        context: dict[str, Any] | None = None,
    ) -> str:
        """Generuj szczegółowy JSON śladu decyzyjnego.

        Zawiera listę wszystkich sprawdzanych reguł z wynikiem warunku
        oraz końcowy werdykt i snapshot kontekstu.

        Args:
            evaluated_rules: Lista słowników z polami:
                - rule_id, condition_sql, result (bool),
                  reason (str, opcjonalnie), selected (bool)
            final_verdict: Końcowy werdykt.
            context: Snapshot kontekstu w momencie decyzji.

        Returns:
            JSON string (sort_keys=True dla determinizmu).
        """
        trace: dict[str, Any] = {}

        if evaluated_rules:
            trace["evaluated_rules"] = evaluated_rules
        if final_verdict:
            trace["final_verdict"] = final_verdict
        if context:
            # Nie kopiuj całego kontekstu -- tylko kluczowe pola
            trace["context_snapshot"] = {
                k: context[k]
                for k in (
                    "category_code",
                    "transaction_date",
                    "vendor_country",
                    "company_tax_form",
                    "vendor_vat_status",
                )
                if k in context
            }

        return msgspec_dumps(trace, ensure_ascii=False, default=str, sort_keys=True)


# ── Helpers ─────────────────────────────────────────────────────────────


def _resolve_label(verdict: dict[str, Any], field: str) -> str:
    """Zwróć czytelną etykietę dla pola werdyktu."""
    raw = verdict.get(field)
    if raw is None:
        return "?"
    label_map = _VERDICT_LABELS.get(field, {})
    return label_map.get(str(raw), str(raw))
