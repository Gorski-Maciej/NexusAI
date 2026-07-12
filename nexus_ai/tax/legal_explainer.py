"""
Legal Explainer (A3) — Deterministyczny generator uzasadnień podatkowych.
===========================================================================

Część strategicznego planu 48_JDG_STRATEGIC_IMPROVEMENTS_V2.md.
Bierze werdykt OPA oraz ślad ewaluacji i generuje czytelną notę podatkową
w języku polskim, wyjaśniającą DLACZEGO system podjął daną decyzję.

Zgodność z RODO art. 22 ust. 3 — prawo do uzyskania wyjaśnienia decyzji
opartej na zautomatyzowanym przetwarzaniu.

Usage:
    explainer = LegalExplainerEngine()
    text = explainer.explain(verdict, opa_trace, metadata)
    # → "📋 Faktura FV/2026/06/001 została zablokowana..."
"""

from __future__ import annotations

from typing import Any


# ── Szablony wyjaśnień ────────────────────────────────────────────────────────

EXPLANATION_TEMPLATES: dict[str, str] = {
    "BLOCKED": (
        "📋 **Faktura {invoice_number} została zablokowana**\n\n"
        "**Powód:** {rule_description}\n"
        "**Szczegóły:** {conditions}\n"
        "**Podstawa prawna:** {legal_basis}\n"
        "**Priorytet:** {priority}\n\n"
        "**Co zrobić:** {remediation}\n"
    ),
    "WARNING": (
        "⚠️ **Ostrzeżenie dla faktury {invoice_number}**\n\n"
        "**Uwaga:** {rule_description}\n"
        "**Ryzyko:** {risk_description}\n"
        "**Podstawa prawna:** {legal_basis}\n\n"
        "**Co zrobić:** {remediation}\n"
    ),
    "TRIAGE": (
        "🔍 **Faktura {invoice_number} wymaga ręcznej weryfikacji**\n\n"
        "**Przyczyna:** {rule_description}\n"
        "**Podstawa prawna:** {legal_basis}\n\n"
        "**Co zrobić:** Skontaktuj się z księgowym w celu ręcznej weryfikacji.\n"
    ),
    "OK": (
        "✅ **Faktura {invoice_number} — księgowanie standardowe**\n\n"
        "| Element | Wartość |\n"
        "|---------|--------|\n"
        "| VAT | {vat_rate} |\n"
        "| KUP | {kus_qualification} |\n"
        "| PKPiR kolumna | {pkpir_column} |\n"
        "| ZUS społeczne | {zus_social} |\n"
        "| ZUS zdrowotne | {zus_health} |\n\n"
        "**Podstawa prawna:** {legal_basis}\n"
    ),
    "NO_MATCH": (
        "❓ **Faktura {invoice_number} — nie znaleziono pasującej reguły**\n\n"
        "System nie może automatycznie określić sposobu księgowania tej faktury.\n"
        "**Co zrobić:** Faktura została przekazana do ręcznej weryfikacji (TRIAGE_QUEUE).\n"
    ),
}


# ── Remediacje (co zrobić gdy reguła blokuje) ────────────────────────────────

REMEDIATION_TEMPLATES: dict[str, str] = {
    "BLOCK_AND_ALERT": (
        "Sprawdź poprawność danych faktury. Jeśli dane są prawidłowe, "
        "skontaktuj się z księgowym w celu wyjaśnienia blokady."
    ),
    "TRIAGE_QUEUE": (
        "Faktura oczekuje na ręczną weryfikację. Księgowy otrzymał "
        "powiadomienie i skontaktuje się z Tobą."
    ),
    "WHITELIST_MISSING": (
        "Kontrahent nie figuruje na Białej Liście MF. Zweryfikuj NIP "
        "kontrahenta. Jeśli NIP jest prawidłowy, poproś kontrahenta o "
        "aktualizację danych w CEIDG/KRS. Przelew na niezweryfikowany "
        "rachunek grozi odpowiedzialnością solidarną."
    ),
    "SPLIT_PAYMENT": (
        "Faktura wymaga mechanizmu podzielonej płatności (MPP). "
        "Przy przelewie wybierz opcję 'przelew MPP / split payment' "
        "w bankowości elektronicznej."
    ),
    "CASH_LIMIT": (
        "Płatność gotówkowa powyżej 15 000 PLN. Wydatek nie stanowi "
        "kosztu uzyskania przychodu. Rozważ płatność przelewem."
    ),
    "CEIDG_SUSPENDED": (
        "Kontrahent ma zawieszoną działalność w CEIDG. Zweryfikuj "
        "czy faktura dotyczy okresu sprzed zawieszenia."
    ),
    "DEFAULT": (
        "Skontaktuj się z księgowym w celu wyjaśnienia."
    ),
}


class LegalExplainerEngine:
    """Generuje czytelne uzasadnienia decyzji OPA w języku polskim.

    Używa szablonów i metadanych z # METADATA w plikach .rego
    do budowy kontekstowych wyjaśnień.
    """

    def __init__(self) -> None:
        pass

    def explain(
        self,
        verdict: dict[str, Any],
        metadata: dict[str, str] | None = None,
    ) -> str:
        """Generuje wyjaśnienie decyzji na podstawie werdyktu OPA.

        Args:
            verdict: Werdykt OPA z polami rule_id, _routing, _warnings itp.
            metadata: Opcjonalne metadane z # METADATA (title, legal_basis, ...).

        Returns:
            Tekst wyjaśnienia w języku polskim, gotowy do wyświetlenia w UI.
        """
        routing = verdict.get("_routing", "")
        warnings = verdict.get("_warnings", [])
        rule_id = verdict.get("rule_id", "unknown")
        invoice_number = verdict.get("invoice_number", "?")

        meta = metadata or {}

        if routing == "BLOCK_AND_ALERT":
            template = EXPLANATION_TEMPLATES["BLOCKED"]
            return template.format(
                invoice_number=invoice_number,
                rule_description=meta.get("description", f"Reguła {rule_id}"),
                conditions=self._format_conditions(verdict),
                legal_basis=meta.get("legal_basis", verdict.get("_legal_basis", "—")),
                priority=str(verdict.get("priority", "—")),
                remediation=self._get_remediation(rule_id, routing),
            )

        if warnings:
            template = EXPLANATION_TEMPLATES["WARNING"]
            return template.format(
                invoice_number=invoice_number,
                rule_description=meta.get("description", f"Reguła {rule_id}"),
                risk_description=", ".join(
                    w for w in (warnings if isinstance(warnings, list) else [warnings])
                    if isinstance(w, str)
                ),
                legal_basis=meta.get("legal_basis", verdict.get("_legal_basis", "—")),
                remediation=self._get_remediation(rule_id, routing),
            )

        if routing == "TRIAGE_QUEUE":
            template = EXPLANATION_TEMPLATES["TRIAGE"]
            return template.format(
                invoice_number=invoice_number,
                rule_description=meta.get("description", f"Reguła {rule_id}"),
                legal_basis=meta.get("legal_basis", verdict.get("_legal_basis", "—")),
            )

        if not verdict.get("matched"):
            return EXPLANATION_TEMPLATES["NO_MATCH"].format(
                invoice_number=invoice_number,
            )

        # Standardowe księgowanie — OK
        template = EXPLANATION_TEMPLATES["OK"]
        return template.format(
            invoice_number=invoice_number,
            vat_rate=f"{verdict.get('vat_rate', '—')} ({self._vat_rate_label(verdict.get('vat_rate', ''))})",
            kus_qualification=self._kus_label(verdict.get("kus_qualification", "")),
            pkpir_column=str(verdict.get("pkpir_column", "—")),
            zus_social=str(verdict.get("zus_social_base_type", "—")),
            zus_health=f"{verdict.get('zus_health_rate', '—')} ({verdict.get('zus_health_limit_type', '—')})",
            legal_basis=meta.get("legal_basis", verdict.get("_legal_basis", "—")),
        )

    @staticmethod
    def _format_conditions(verdict: dict[str, Any]) -> str:
        """Formatuje spełnione przesłanki reguły."""
        parts: list[str] = []
        for key, value in verdict.items():
            if key.startswith("_") or key in ("matched", "rule_id", "package", "priority"):
                continue
            if value not in ("", None, False, 0):
                parts.append(f"• {key}: {value}")
        return "\n".join(parts) if parts else "—"

    @staticmethod
    def _get_remediation(rule_id: str, routing: str) -> str:
        """Zwraca tekst remediacji dla danej reguły."""
        rule_lower = rule_id.lower()
        if "white" in rule_lower or "whitelist" in rule_lower:
            return REMEDIATION_TEMPLATES["WHITELIST_MISSING"]
        if "split" in rule_lower or "mpp" in rule_lower:
            return REMEDIATION_TEMPLATES["SPLIT_PAYMENT"]
        if "cash" in rule_lower:
            return REMEDIATION_TEMPLATES["CASH_LIMIT"]
        if "ceidg" in rule_lower or "suspend" in rule_lower:
            return REMEDIATION_TEMPLATES["CEIDG_SUSPENDED"]
        if routing == "BLOCK_AND_ALERT":
            return REMEDIATION_TEMPLATES["BLOCK_AND_ALERT"]
        if routing == "TRIAGE_QUEUE":
            return REMEDIATION_TEMPLATES["TRIAGE_QUEUE"]
        return REMEDIATION_TEMPLATES["DEFAULT"]

    @staticmethod
    def _vat_rate_label(rate: str) -> str:
        """Zamienia stawkę VAT/PIT/ZUS na czytelną etykietę."""
        labels = {
            # VAT
            "0.23": "23% (stawka podstawowa)",
            "0.08": "8% (stawka obniżona)",
            "0.05": "5% (stawka obniżona)",
            "0.00": "zwolnione / 0%",
            # PIT — skala
            "0.12": "12% (skala — I próg)",
            "0.32": "32% (skala — II próg)",
            # PIT — liniowy
            "0.19": "19% (podatek liniowy)",
            # Ryczałt
            "0.17": "17% (ryczałt)",
            "0.15": "15% (ryczałt)",
            "0.14": "14% (ryczałt)",
            "0.12": "12% (ryczałt / skala)",
            "0.10": "10% (ryczałt)",
            "0.085": "8,5% (ryczałt)",
            "0.055": "5,5% (ryczałt)",
            "0.03": "3% (ryczałt)",
            "0.02": "2% (ryczałt)",
            # IP Box
            "0.05": "5% (IP Box)",
            # ZUS
            "0.09": "9% (składka zdrowotna — skala)",
            "0.049": "4,9% (składka zdrowotna — liniowy/ryczałt)",
            "0.1952": "19,52% (składka emerytalna)",
            "0.08": "8% (składka rentowa)",
            "0.0245": "2,45% (składka chorobowa / FP)",
            "0.0167": "1,67% (składka wypadkowa)",
        }
        return labels.get(rate, rate)

    @staticmethod
    def _kus_label(kus: str) -> str:
        """Zamienia kwalifikację KUP na czytelną etykietę."""
        labels = {
            "full": "100% KUP",
            "partial": "częściowy KUP",
            "none": "NKUP (niestanowiący KUP)",
            "limited_car_150k": "KUP limitowany (auto >150k PLN)",
            "private_mixed": "KUP proporcjonalny (użytek mieszany)",
        }
        return labels.get(kus, kus)


def explain_verdict(
    verdict: dict[str, Any],
    metadata: dict[str, str] | None = None,
) -> str:
    """Skrócona funkcja pomocnicza do generowania wyjaśnień."""
    engine = LegalExplainerEngine()
    return engine.explain(verdict, metadata)
