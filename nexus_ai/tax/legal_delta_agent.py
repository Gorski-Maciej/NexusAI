"""
Zero-Day Legal Delta AI Agent (C3) — Automatyczne śledzenie zmian prawa.
================================================================================

Część strategicznego planu 29_JDG_STRATEGIC_IMPROVEMENTS.md.
Monitoruje Dziennik Ustaw i RCL, mapuje zmiany na reguły OPA przez # METADATA,
generuje PR z proponowanymi aktualizacjami.

AI NIE zastępuje prawnika — eliminuje mozolne przeszukiwanie 294 reguł
w poszukiwaniu tych, których dotyczy zmiana. Ostateczna decyzja zawsze
należy do człowieka (HumanReview).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


# ── Data Structures ───────────────────────────────────────────────────────────


@dataclass
class LegalChange:
    """Pojedyncza zmiana prawna wykryta przez AI."""
    law_id: str  # Dz.U. pozycja
    article: str  # "Art. 113 ust. 1"
    change_type: str  # "AMENDMENT", "REPEAL", "NEW", "THRESHOLD_CHANGE"
    old_value: str | None
    new_value: str
    effective_date: str
    raw_text: str
    confidence: float  # 0.0-1.0 — pewność AI co do interpretacji


@dataclass
class AffectedRule:
    """Reguła OPA dotknięta zmianą prawną."""
    rule_id: str
    rule_name: str
    file_path: str
    legal_basis: str
    impact: str  # "THRESHOLD", "LOGIC", "DEPRECATE", "NEW_RULE"
    suggested_changes: dict[str, Any]


@dataclass
class LegalDeltaReport:
    """Raport z analizy zmiany prawnej."""
    change: LegalChange
    affected_rules: list[AffectedRule]
    requires_human_review: bool
    auto_fixable: bool
    pr_description: str


# ── Legislation Monitor ───────────────────────────────────────────────────────


class LegislationMonitor:
    """Monitoruje źródła prawne i wykrywa zmiany.

    W wersji produkcyjnej monitoruje:
    - Dziennik Ustaw (RCL API / RSS)
    - ISAP — Internetowy System Aktów Prawnych
    - Projekty ustaw w Sejmie (do symulacji what-if)

    Obecnie: stub implementacji — zwraca dane testowe.
    """

    # Znane źródła prawne monitorowane przez system
    MONITORED_SOURCES = [
        "https://dziennikustaw.gov.pl/rss",
        "https://isap.sejm.gov.pl",
        "https://www.sejm.gov.pl/Sejm10.nsf/proces.xsp",
    ]

    def check_for_changes(self) -> list[LegalChange]:
        """Sprawdza czy są nowe zmiany prawne od ostatniego sprawdzenia.

        Returns:
            Lista wykrytych zmian prawnych.
        """
        # TODO: Zaimplementować rzeczywiste monitorowanie RCL API
        # Obecnie: stub zwracający przykładowe dane
        return []

    def simulate_change(
        self, article: str, new_value: str, effective_date: str
    ) -> LegalChange:
        """Symuluje zmianę prawną dla celów testowych / what-if."""
        return LegalChange(
            law_id="SIM-2026-0001",
            article=article,
            change_type="THRESHOLD_CHANGE",
            old_value=None,
            new_value=new_value,
            effective_date=effective_date,
            raw_text=f"Symulacja: {article} → {new_value}",
            confidence=1.0,
        )


# ── Rule Mapper ───────────────────────────────────────────────────────────────


class RuleMapper:
    """Mapuje zmiany prawne na reguły OPA przez # METADATA legal_basis.

    Przeszukuje wszystkie pliki .rego w poszukiwaniu reguł, których
    podstawa prawna odpowiada zmienionemu artykułowi.
    """

    # Mapa: artykuł prawny → lista rule_id (z # METADATA w .rego)
    LEGAL_BASIS_MAP: dict[str, list[dict[str, Any]]] = {
        "Art. 113 ust. 1 VAT": [
            {
                "rule_id": "P58",
                "rule_name": "vat_exemption_subject_jdg",
                "file_path": "policies/jdg/vat/substantive.rego",
                "legal_basis": "Art. 113 ust. 1, Art. 113 ust. 9 ustawy o VAT",
                "threshold": "jdg.limits.vat_exemption_limit",
            }
        ],
        "Art. 27 ust. 1 PIT": [
            {
                "rule_id": "P500",
                "rule_name": "pit_form_scale",
                "file_path": "policies/jdg/pit/forms.rego",
                "legal_basis": "Art. 27 ust. 1 PIT",
                "threshold": "jdg.limits.tax_scale_bracket",
            },
            {
                "rule_id": "P508",
                "rule_name": "pit_scale_tax_free_amount",
                "file_path": "policies/jdg/pit/forms.rego",
                "legal_basis": "Art. 27 ust. 1 PIT",
                "threshold": "jdg.limits.tax_free_amount",
            },
        ],
        "Art. 89a VAT": [
            {
                "rule_id": "P189",
                "rule_name": "bad_debt_relief_creditor",
                "file_path": "policies/jdg/vat/deductions.rego",
                "legal_basis": "Art. 89a VAT",
                "threshold": "jdg.limits.bad_debt_creditor_days",
            },
        ],
        "Art. 89b VAT": [
            {
                "rule_id": "P184",
                "rule_name": "bad_debt_debtor_correction_mandatory",
                "file_path": "policies/jdg/vat/deductions.rego",
                "legal_basis": "Art. 89b VAT",
                "threshold": "jdg.limits.bad_debt_debtor_days",
            },
        ],
        "Art. 36a SUS": [
            {
                "rule_id": "P914/R0582",
                "rule_name": "business_suspension_zus",
                "file_path": "policies/jdg/business.rego",
                "legal_basis": "Art. 36a ustawy o SUS",
                "threshold": None,
            },
        ],
    }

    def map_change(self, change: LegalChange) -> list[AffectedRule]:
        """Mapuje zmianę prawną na dotknięte reguły OPA."""
        affected: list[AffectedRule] = []

        # Szukaj w mapie
        matching = self.LEGAL_BASIS_MAP.get(change.article, [])

        if not matching:
            # Próbuj częściowego dopasowania
            for article_key, rules in self.LEGAL_BASIS_MAP.items():
                if change.article.split(" ")[1] == article_key.split(" ")[1]:
                    matching = rules
                    break

        for rule_info in matching:
            impact = self._determine_impact(change, rule_info)
            affected.append(AffectedRule(
                rule_id=rule_info["rule_id"],
                rule_name=rule_info["rule_name"],
                file_path=rule_info["file_path"],
                legal_basis=rule_info["legal_basis"],
                impact=impact,
                suggested_changes={
                    "threshold_update": rule_info.get("threshold"),
                    "old_value": change.old_value,
                    "new_value": change.new_value,
                    "effective_date": change.effective_date,
                },
            ))

        return affected

    @staticmethod
    def _determine_impact(change: LegalChange, rule_info: dict[str, Any]) -> str:
        """Określa typ wpływu zmiany na regułę."""
        if change.change_type == "THRESHOLD_CHANGE":
            return "THRESHOLD"
        if change.change_type == "REPEAL":
            return "DEPRECATE"
        if change.change_type == "NEW":
            return "NEW_RULE"
        return "LOGIC"


# ── PR Generator ──────────────────────────────────────────────────────────────


class PRGenerator:
    """Generuje Pull Request z proponowanymi zmianami.

    PR zawiera:
    - Zmiany w DuckDB thresholds (nowe wartości)
    - Aktualizacje # METADATA w .rego
    - Adnotacje o dacie wejścia w życie
    - Propozycję nowego bundle (dla A2 Temporal Bundle Routing)
    """

    def generate_pr(
        self, report: LegalDeltaReport
    ) -> dict[str, Any]:
        """Generuje strukturę PR do review przez człowieka."""
        pr = {
            "title": f"[Legal Delta AI] {report.change.article}: "
                     f"{report.change.old_value} → {report.change.new_value}",
            "body": self._build_pr_body(report),
            "changes": [],
            "requires_human_review": report.requires_human_review,
            "auto_fixable": report.auto_fixable,
            "confidence": report.change.confidence,
        }

        for rule in report.affected_rules:
            if rule.impact == "THRESHOLD":
                pr["changes"].append({
                    "type": "threshold_update",
                    "file": "thresholds/duckdb/jdg_limits.sql",
                    "key": rule.suggested_changes["threshold_update"],
                    "old": report.change.old_value,
                    "new": report.change.new_value,
                })
                pr["changes"].append({
                    "type": "metadata_update",
                    "file": rule.file_path,
                    "rule_id": rule.rule_id,
                    "description": (
                        f"Zmiana progu z {report.change.old_value} "
                        f"na {report.change.new_value} "
                        f"(od {report.change.effective_date}, {report.change.law_id})"
                    ),
                })
            elif rule.impact == "DEPRECATE":
                pr["changes"].append({
                    "type": "deprecate_rule",
                    "file": rule.file_path,
                    "rule_id": rule.rule_id,
                    "new_bundle": f"jdg_v{report.change.effective_date[:4]}",
                })

        return pr

    @staticmethod
    def _build_pr_body(report: LegalDeltaReport) -> str:
        """Buduje treść PR w Markdown."""
        lines = [
            f"## 🤖 Auto-generated by Legal Delta AI Agent (C3)",
            "",
            f"**Zmiana prawna:** {report.change.article}",
            f"**Dz.U.:** {report.change.law_id}",
            f"**Data wejścia w życie:** {report.change.effective_date}",
            f"**Pewność AI:** {report.change.confidence:.0%}",
            "",
            "### Dotknięte reguły OPA:",
        ]

        for rule in report.affected_rules:
            lines.append(f"- `{rule.rule_id}` {rule.rule_name} ({rule.file_path})")
            lines.append(f"  - Wpływ: {rule.impact}")
            lines.append(f"  - Podstawa prawna: {rule.legal_basis}")

        lines.extend([
            "",
            "### ⚠️ Wymaga review przez człowieka",
            "",
            "AI agent wykrył zmianę i zaproponował aktualizacje.",
            "**Ostateczna decyzja należy do prawnika/developera.**",
            "",
            "Checklista review:",
            "- [ ] Poprawność interpretacji zmiany prawnej",
            "- [ ] Wszystkie dotknięte reguły zidentyfikowane",
            "- [ ] Nowe wartości progów zweryfikowane z tekstem ustawy",
            "- [ ] Testy graniczne (B3) przechodzą dla nowych wartości",
            "- [ ] Bundle temporalny (A2) utworzony dla nowego roku",
        ])

        return "\n".join(lines)


# ── Legal Delta Agent ─────────────────────────────────────────────────────────


class LegalDeltaAgent:
    """Główny agent AI do śledzenia zmian prawnych.

    Pipeline:
    1. LegislationMonitor wykrywa nowe akty prawne
    2. LLM (LegalNER) wydobywa zmiany z tekstu
    3. RuleMapper mapuje zmiany na reguły OPA
    4. PRGenerator tworzy PR do review
    5. HumanReview — człowiek zatwierdza lub koryguje
    """

    def __init__(self) -> None:
        self._monitor = LegislationMonitor()
        self._mapper = RuleMapper()
        self._pr_generator = PRGenerator()

    async def analyze_legal_change(
        self, article: str, new_value: str, effective_date: str
    ) -> dict[str, Any]:
        """Analizuje zmianę prawną i generuje propozycje aktualizacji.

        To jest tryb symulacji — w produkcji dane pochodziłyby z RCL API.
        """
        # Symuluj zmianę
        change = self._monitor.simulate_change(article, new_value, effective_date)

        # Mapuj na reguły
        affected = self._mapper.map_change(change)

        # Generuj raport
        report = LegalDeltaReport(
            change=change,
            affected_rules=affected,
            requires_human_review=change.confidence < 0.95 or len(affected) > 3,
            auto_fixable=all(r.impact == "THRESHOLD" for r in affected),
            pr_description=f"Zmiana {article}: {new_value}",
        )

        # Generuj PR
        pr = self._pr_generator.generate_pr(report)

        return {
            "change": {
                "article": change.article,
                "new_value": change.new_value,
                "effective_date": change.effective_date,
            },
            "affected_rules": len(affected),
            "requires_human_review": report.requires_human_review,
            "auto_fixable": report.auto_fixable,
            "pr": pr,
        }
