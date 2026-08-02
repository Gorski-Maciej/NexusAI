#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Judgment Predictor (C1 Strategic Initiative) [EKSPERYMENTALNY]
═══════════════════════════════════════════════════════════════════════════════

STATUS v8.1 (P27 R12): EKSPERYMENTALNY — Deterministic scoring heuristic, NIE model ML.
Używaj z flagą --experimental. Nazwa "predictor" jest myląca — to kalkulator
ryzyka KKS + scoring regułowy, nie predykcja ML (brak sklearn/tensorflow/torch).

Symulator kontroli US + Ostrzegator KKS — shadow mode evaluation.

API `/simulate` — klient ładuje roboczy `input`, system PRZED wystawieniem
faktury/opłaceniem ostrzega o potencjalnych karach KKS i ryzykach.

Architektura:
  1. Shadow mode — uruchamia wszystkie reguły Rego w trybie "what-if"
  2. Severity scoring (LOW / MEDIUM / HIGH / CRITICAL)
  3. Kalkulacja potencjalnych kar KKS (Art. 54-83 KKS)
  4. Ranking zagrożeń dla użytkownika

Użycie:
    from JDG.tools.judgment_predictor import JudgmentPredictor
    predictor = JudgmentPredictor()
    result = predictor.predict(input_data)
    print(result.risk_summary)

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-17
Wersja: 1.0.0
"""

import hashlib
import json
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any


# ── Typy ──────────────────────────────────────────────────────────────────────

class Severity(str, Enum):
    """Poziomy ryzyka KKS."""
    LOW = "LOW"           # Małe ryzyko — informacyjne
    MEDIUM = "MEDIUM"     # Średnie ryzyko — zalecana korekta
    HIGH = "HIGH"          # Wysokie ryzyko — wymagana natychmiastowa uwaga
    CRITICAL = "CRITICAL"  # Krytyczne — potencjalne przestępstwo skarbowe


class RiskCategory(str, Enum):
    """Kategorie ryzyka podatkowego."""
    KKS_CRIMINAL = "KKS_CRIMINAL"          # Przestępstwo skarbowe (Art. 54-76)
    KKS_MISDEMEANOR = "KKS_MISDEMEANOR"    # Wykroczenie skarbowe (Art. 77-83)
    WHITELIST = "WHITELIST"                 # Biała lista VAT
    SPLIT_PAYMENT = "SPLIT_PAYMENT"         # MPP — mechanizm podzielonej płatności
    VAT_EXEMPTION = "VAT_EXEMPTION"         # Próg zwolnienia VAT 200k
    BAD_DEBT = "BAD_DEBT"                   # Ulga na złe długi
    CASH_LIMIT = "CASH_LIMIT"               # Limit transakcji gotówkowych 15k
    DOCUMENTATION = "DOCUMENTATION"         # Braki w dokumentacji
    DEADLINE = "DEADLINE"                   # Przekroczone terminy
    TP_RISK = "TP_RISK"                     # Ryzyko cen transferowych


@dataclass
class RiskFinding:
    """Pojedyncze znalezisko ryzyka."""
    rule_id: str
    category: RiskCategory
    severity: Severity
    legal_basis: str
    description: str
    recommendation: str
    potential_fine_pln: float = 0.0
    probability: float = 0.0  # 0.0 - 1.0
    expected_cost_pln: float = 0.0
    is_blocker: bool = False

    def __post_init__(self):
        self.expected_cost_pln = self.potential_fine_pln * self.probability


@dataclass
class PredictionResult:
    """Pełny wynik predykcji."""
    input_hash: str
    evaluated_at: str
    total_findings: int
    findings: list[RiskFinding] = field(default_factory=list)
    risk_score: float = 0.0  # 0-100
    max_severity: Severity = Severity.LOW
    total_potential_fines: float = 0.0
    total_expected_cost: float = 0.0
    summary: str = ""

    @property
    def risk_level(self) -> str:
        if self.risk_score >= 70:
            return "KRYTYCZNE — natychmiastowa korekta wymagana"
        elif self.risk_score >= 40:
            return "WYSOKIE — zalecana pilna weryfikacja"
        elif self.risk_score >= 15:
            return "ŚREDNIE — przeanalizuj przed finalizacją"
        else:
            return "NISKIE — standardowe bezpieczeństwo"


# ── KKS Fine Calculator ────────────────────────────────────────────────────────

class KKSFineCalculator:
    """
    Kalkulator kar na podstawie Kodeksu Karnego Skarbowego.

    Stawka dzienna = 1/30 minimalnego wynagrodzenia (2026: ~4666 PLN / 30 ≈ 155 PLN)
    Max stawka dzienna = 400 × stawka podstawowa
    Max grzywna = 720 stawek × max stawka dzienna
    """

    MIN_WAGE_2026 = 4666.0  # PLN brutto
    DAILY_RATE_BASE = MIN_WAGE_2026 / 30  # ~155.53 PLN
    MAX_DAILY_RATE_MULTIPLIER = 400

    # Kary z Art. 54-83 KKS
    OFFENSE_FINES = {
        # Przestępstwa skarbowe (Art. 54-76)
        "TAX_EVASION": {  # Art. 54 § 1
            "max_daily_rates": 720,
            "severity": Severity.CRITICAL,
            "description": "Uchylanie się od opodatkowania",
            "imprisonment_years": 5,
        },
        "UNRELIABLE_BOOKS": {  # Art. 56
            "max_daily_rates": 240,
            "severity": Severity.HIGH,
            "description": "Nierzetelne księgi / PKPiR",
        },
        "UNRELIABLE_VAT": {  # Art. 57
            "max_daily_rates": 240,
            "severity": Severity.HIGH,
            "description": "Nierzetelna ewidencja VAT",
        },
        "EMPTY_INVOICE": {  # Art. 62 § 2
            "max_daily_rates": 720,
            "severity": Severity.CRITICAL,
            "description": "Pusta faktura",
            "imprisonment_years": 25,
        },
        "FAKE_INVOICE": {  # Art. 62 § 1
            "max_daily_rates": 720,
            "severity": Severity.CRITICAL,
            "description": "Fałszywa faktura",
            "imprisonment_years": 25,
        },
        "VAT_CAROUSEL": {  # Art. 62 § 2
            "max_daily_rates": 720,
            "severity": Severity.CRITICAL,
            "description": "Karuzela VAT",
            "imprisonment_years": 15,
        },
        "UNJUSTIFIED_REFUND": {  # Art. 76
            "max_daily_rates": 720,
            "severity": Severity.CRITICAL,
            "description": "Nienależny zwrot podatku",
            "imprisonment_years": 5,
        },

        # Wykroczenia skarbowe (Art. 77-83)
        "DECLARATION_NOT_FILED": {  # Art. 77
            "max_daily_rates": 180,
            "severity": Severity.HIGH,
            "description": "Niezłożenie deklaracji",
        },
        "TAX_UNPAID": {  # Art. 79
            "max_daily_rates": 180,
            "severity": Severity.HIGH,
            "description": "Niezapłacenie podatku w terminie",
        },
        "INCORRECT_DATA": {  # Art. 80
            "max_daily_rates": 120,
            "severity": Severity.MEDIUM,
            "description": "Wadliwe dane w deklaracji",
        },

        # Sankcje administracyjne
        "WHITELIST_VIOLATION": {  # Art. 117ba OP
            "penalty_percent": 0.30,
            "severity": Severity.HIGH,
            "description": "Przelew na rachunek spoza Białej Listy",
        },
        "SPLIT_PAYMENT_VIOLATION": {  # Art. 108a VAT
            "penalty_percent": 0.30,
            "severity": Severity.HIGH,
            "description": "Brak MPP dla transakcji >15k PLN (zał. 15)",
        },
        "CASH_LIMIT_VIOLATION": {  # Art. 22p PIT
            "penalty_percent": 0.20,
            "severity": Severity.HIGH,
            "description": "Transakcja gotówkowa >15k PLN",
        },
        "DAC7_NON_REPORTING": {  # Art. 39q OP
            "max_fine_pln": 1_000_000,
            "severity": Severity.CRITICAL,
            "description": "Niezłożenie raportu DAC7",
        },
        "MDR_NON_REPORTING": {  # Art. 86f OP
            "max_fine_pln": 2_000_000,
            "severity": Severity.CRITICAL,
            "description": "Niezgłoszenie schematu podatkowego MDR",
        },
        "KSEF_NON_COMPLIANCE": {  # Art. 106nq VAT
            "penalty_percent": 1.00,
            "severity": Severity.HIGH,
            "description": "Niewystawienie faktury przez KSeF",
        },
    }

    @classmethod
    def calculate_fine(cls, offense_type: str, amount_pln: float = 0.0) -> dict:
        """Oblicz potencjalną karę dla danego typu naruszenia."""
        offense = cls.OFFENSE_FINES.get(offense_type, {})
        result = {
            "offense_type": offense_type,
            "description": offense.get("description", offense_type),
            "severity": offense.get("severity", Severity.MEDIUM),
        }

        # Kara procentowa od kwoty
        if "penalty_percent" in offense:
            fine = amount_pln * offense["penalty_percent"]
            result["min_fine_pln"] = fine
            result["max_fine_pln"] = fine
            result["fine_method"] = "percentage"

        # Kara stała
        elif "max_fine_pln" in offense:
            result["min_fine_pln"] = offense["max_fine_pln"] * 0.1
            result["max_fine_pln"] = offense["max_fine_pln"]
            result["fine_method"] = "fixed"

        # Kara w stawkach dziennych
        elif "max_daily_rates" in offense:
            base_rate = cls.DAILY_RATE_BASE
            max_rate = base_rate * cls.MAX_DAILY_RATE_MULTIPLIER
            max_daily_rates = offense["max_daily_rates"]

            # Minimum: 10 stawek × stawka podstawowa
            result["min_fine_pln"] = 10 * base_rate
            # Maximum: max stawek × max stawka
            result["max_fine_pln"] = max_daily_rates * max_rate
            result["expected_fine_pln"] = (max_daily_rates // 4) * base_rate
            result["fine_method"] = "daily_rates"

        else:
            result["min_fine_pln"] = 500.0
            result["max_fine_pln"] = 5000.0
            result["fine_method"] = "default"

        return result


# ── Judgment Predictor ─────────────────────────────────────────────────────────

class JudgmentPredictor:
    """
    Główny silnik predykcji ryzyka podatkowego.

    Tryb shadow mode — nie modyfikuje głównej decyzji systemu,
    tylko dostarcza dodatkową warstwę "what-if" z oceną ryzyka.
    """

    def __init__(self):
        self.fine_calculator = KKSFineCalculator()

    def predict(self, input_data: dict) -> PredictionResult:
        """
        Główna metoda predykcji.

        Args:
            input_data: Dane wejściowe JDG (invoice, entrepreneur, vendor, etc.)

        Returns:
            PredictionResult z pełną analizą ryzyka
        """
        input_json = json.dumps(input_data, sort_keys=True, ensure_ascii=False)
        input_hash = hashlib.sha256(input_json.encode()).hexdigest()[:16]

        findings: list[RiskFinding] = []

        # ── Shadow evaluation wszystkich kategorii ryzyka ────────────────────
        findings.extend(self._check_whitelist(input_data))
        findings.extend(self._check_split_payment(input_data))
        findings.extend(self._check_cash_limit(input_data))
        findings.extend(self._check_vat_exemption(input_data))
        findings.extend(self._check_bad_debt(input_data))
        findings.extend(self._check_kks_offenses(input_data))
        findings.extend(self._check_documentation(input_data))
        findings.extend(self._check_deadlines(input_data))
        findings.extend(self._check_tp_risk(input_data))

        # ── Agregacja ───────────────────────────────────────────────────────
        risk_score = self._calculate_risk_score(findings)
        max_severity = self._calculate_max_severity(findings)
        total_fines = sum(f.potential_fine_pln for f in findings)
        total_expected = sum(f.expected_cost_pln for f in findings)

        result = PredictionResult(
            input_hash=input_hash,
            evaluated_at=datetime.now().isoformat(),
            total_findings=len(findings),
            findings=findings,
            risk_score=risk_score,
            max_severity=max_severity,
            total_potential_fines=total_fines,
            total_expected_cost=total_expected,
            summary=self._build_summary(findings, risk_score, total_fines),
        )

        return result

    # ── Shadow check: Biała lista VAT ───────────────────────────────────────

    def _check_whitelist(self, data: dict) -> list[RiskFinding]:
        findings = []
        vendor = data.get("vendor", {})
        invoice = data.get("invoice", {})
        amount = invoice.get("amount_gross", 0)

        # Art. 117ba OP — przelew >15k PLN musi iść na konto z Białej Listy
        if vendor.get("whitelist_verified") is False and amount > 15000:
            fine_info = self.fine_calculator.calculate_fine(
                "WHITELIST_VIOLATION", amount
            )
            findings.append(RiskFinding(
                rule_id="jdg.compliance.whitelist_missing_over_limit",
                category=RiskCategory.WHITELIST,
                severity=Severity.HIGH,
                legal_basis="Art. 117ba Ordynacji podatkowej + Art. 22 ust. 4aa PIT",
                description=f"Płatność {amount:,.2f} PLN na rachunek spoza Białej Listy VAT",
                recommendation="Zmień status kontrahenta w CEIDG przed płatnością "
                               "lub wybierz rachunek zweryfikowany na Białej Liście.",
                potential_fine_pln=fine_info.get("min_fine_pln", amount * 0.30),
                probability=0.87,
            ))

        return findings

    # ── Shadow check: Split Payment MPP ──────────────────────────────────────

    def _check_split_payment(self, data: dict) -> list[RiskFinding]:
        findings = []
        invoice = data.get("invoice", {})
        amount = invoice.get("amount_gross", 0)

        # Lista załącznika nr 15 do VAT (towary/usługi objęte MPP)
        MPP_GOODS = {
            "steel", "fuel", "coal", "electronics",
            "construction", "scrap", "precious_metals",
            "auto_parts", "cpus", "hardware",
        }

        goods_type = invoice.get("goods_type", "").lower()

        if goods_type in MPP_GOODS and amount >= 15000:
            if invoice.get("split_payment_used") is not True:
                fine_info = self.fine_calculator.calculate_fine(
                    "SPLIT_PAYMENT_VIOLATION", amount
                )
                findings.append(RiskFinding(
                    rule_id="jdg.compliance.split_payment_mandatory",
                    category=RiskCategory.SPLIT_PAYMENT,
                    severity=Severity.HIGH,
                    legal_basis="Art. 108a VAT",
                    description=f"Transakcja {amount:,.2f} PLN za '{goods_type}' "
                                 f"bez MPP (załącznik nr 15 do VAT)",
                    recommendation="Użyj mechanizmu podzielonej płatności "
                                   "dla tej transakcji.",
                    potential_fine_pln=fine_info.get("min_fine_pln", amount * 0.30),
                    probability=0.75,
                    is_blocker=True,
                ))

        return findings

    # ── Shadow check: Limit gotówkowy ────────────────────────────────────────

    def _check_cash_limit(self, data: dict) -> list[RiskFinding]:
        findings = []
        invoice = data.get("invoice", {})
        amount = invoice.get("amount_gross", 0)
        payment_method = invoice.get("payment_method", "")

        if payment_method == "CASH" and amount > 15000:
            fine_info = self.fine_calculator.calculate_fine(
                "CASH_LIMIT_VIOLATION", amount
            )
            findings.append(RiskFinding(
                rule_id="jdg.compliance.cash_transaction_over_limit",
                category=RiskCategory.CASH_LIMIT,
                severity=Severity.HIGH,
                legal_basis="Art. 22p ustawy o PIT",
                description=f"Transakcja gotówkowa {amount:,.2f} PLN "
                             f"powyżej limitu 15 000 PLN",
                recommendation="Zrealizuj płatność przelewem bankowym. "
                               "Koszt nie będzie stanowił KUP!",
                potential_fine_pln=amount * 0.20,
                probability=0.95,
                is_blocker=True,
            ))

        return findings

    # ── Shadow check: Próg zwolnienia VAT ────────────────────────────────────

    def _check_vat_exemption(self, data: dict) -> list[RiskFinding]:
        findings = []
        entrepreneur = data.get("jdg_entrepreneur", {})
        invoice = data.get("invoice", {})

        ytd_revenue = entrepreneur.get("ytd_revenue_pln", 0)
        invoice_amount = invoice.get("amount_net", 0)

        if ytd_revenue + invoice_amount > 200000:
            if entrepreneur.get("vat_exempt") is True:
                findings.append(RiskFinding(
                    rule_id="jdg.edge_cases.limit_vat_exemption_200k",
                    category=RiskCategory.VAT_EXEMPTION,
                    severity=Severity.HIGH,
                    legal_basis="Art. 113 ust. 1 i 5 VAT",
                    description=f"Przekroczenie progu zwolnienia VAT "
                                 f"(200 000 PLN) — YTD: {ytd_revenue:,.2f} + "
                                 f"faktura: {invoice_amount:,.2f}",
                    recommendation="Zarejestruj się jako czynny podatnik VAT "
                                   "w ciągu 7 dni od przekroczenia progu!",
                    probability=0.90,
                    is_blocker=True,
                ))

        return findings

    # ── Shadow check: Ulga na złe długi ──────────────────────────────────────

    def _check_bad_debt(self, data: dict) -> list[RiskFinding]:
        findings = []
        invoice = data.get("invoice", {})

        days_overdue = invoice.get("days_overdue", 0)

        if days_overdue >= 90:  # SLIM VAT 3 — 90 dni
            findings.append(RiskFinding(
                rule_id="jdg.kks.bad_debt_vat_relief",
                category=RiskCategory.BAD_DEBT,
                severity=Severity.MEDIUM,
                legal_basis="Art. 89a ust. 1a VAT (SLIM VAT 3)",
                description=f"Faktura przeterminowana {days_overdue} dni — "
                             f"możliwość korekty VAT (ulga na złe długi)",
                recommendation="Złóż korektę JPK_V7M w bieżącym okresie. "
                               "Termin: 3 miesiące od upływu 90 dni.",
                probability=0.70,
            ))

        return findings

    # ── Shadow check: KKS Offenses (Art. 54-83) ──────────────────────────────

    def _check_kks_offenses(self, data: dict) -> list[RiskFinding]:
        findings = []
        invoice = data.get("invoice", {})

        # Puste faktury (Art. 62 KKS) — CRITICAL
        if invoice.get("is_empty_invoice") is True:
            fine_info = self.fine_calculator.calculate_fine("EMPTY_INVOICE")
            findings.append(RiskFinding(
                rule_id="jdg.kks.empty_invoice_art62",
                category=RiskCategory.KKS_CRIMINAL,
                severity=Severity.CRITICAL,
                legal_basis="Art. 62 § 2 KKS",
                description="Wykryto pustą fakturę — dokumentującą czynność "
                            "która nie miała miejsca!",
                recommendation="NATYCHMIAST zgłoś czynny żal do KAS! "
                               "Kara: do 25 lat pozbawienia wolności!",
                potential_fine_pln=fine_info.get("max_fine_pln", 100000),
                probability=0.95,
                is_blocker=True,
            ))

        # Nierzetelne księgi (Art. 56 KKS)
        if invoice.get("books_entries_falsified") is True:
            fine_info = self.fine_calculator.calculate_fine("UNRELIABLE_BOOKS")
            findings.append(RiskFinding(
                rule_id="jdg.kks.unreliable_pkpir_art56",
                category=RiskCategory.KKS_CRIMINAL,
                severity=Severity.CRITICAL,
                legal_basis="Art. 56 § 1-4 KKS",
                description="Nierzetelne PKPiR — celowe zaniżenie przychodów "
                            "lub zawyżenie kosztów",
                recommendation="Natychmiast skoryguj ewidencję PKPiR i złóż czynny żal!",
                potential_fine_pln=fine_info.get("expected_fine_pln", 40000),
                probability=0.85,
            ))

        # Uchylanie się od opodatkowania (Art. 54 KKS)
        if invoice.get("declaration_data_falsified") is True:
            fine_info = self.fine_calculator.calculate_fine("TAX_EVASION")
            findings.append(RiskFinding(
                rule_id="jdg.kks.tax_evasion_false_declaration",
                category=RiskCategory.KKS_CRIMINAL,
                severity=Severity.CRITICAL,
                legal_basis="Art. 54 § 1 KKS",
                description="Fałszywa deklaracja podatkowa — uchylanie się "
                            "od opodatkowania",
                recommendation="Złóż korektę deklaracji + czynny żal. "
                               "Kara: do 720 stawek + pozbawienie wolności!",
                potential_fine_pln=fine_info.get("max_fine_pln", 50000),
                probability=0.80,
                is_blocker=True,
            ))

        return findings

    # ── Shadow check: Dokumentacja ────────────────────────────────────────────

    def _check_documentation(self, data: dict) -> list[RiskFinding]:
        findings = []
        entrepreneur = data.get("jdg_entrepreneur", {})

        # Brak dokumentów
        if entrepreneur.get("documents_destroyed_count", 0) > 0:
            findings.append(RiskFinding(
                rule_id="jdg.kks.documents_destroyed_art60",
                category=RiskCategory.DOCUMENTATION,
                severity=Severity.CRITICAL,
                legal_basis="Art. 60 § 1 KKS + Art. 86 Ordynacji podatkowej",
                description=f"Zniszczono {entrepreneur['documents_destroyed_count']} "
                             f"dokumentów księgowych",
                recommendation="Odtwórz dokumenty z kopii zapasowych. "
                               "Złóż zawiadomienie do US w ciągu 7 dni.",
                potential_fine_pln=50000,
                probability=0.90,
            ))

        return findings

    # ── Shadow check: Terminy ─────────────────────────────────────────────────

    def _check_deadlines(self, data: dict) -> list[RiskFinding]:
        findings = []
        invoice = data.get("invoice", {})

        # Niezłożenie deklaracji
        if invoice.get("declaration_missing") is True:
            fine_info = self.fine_calculator.calculate_fine("DECLARATION_NOT_FILED")
            findings.append(RiskFinding(
                rule_id="jdg.kks.tax_return_non_filing_art77",
                category=RiskCategory.DEADLINE,
                severity=Severity.HIGH,
                legal_basis="Art. 77 § 1-3 KKS",
                description="Niezłożenie deklaracji podatkowej w terminie",
                recommendation="Złóż deklarację niezwłocznie. "
                               "Grzywna do 180 stawek dziennych!",
                potential_fine_pln=fine_info.get("expected_fine_pln", 10000),
                probability=0.80,
            ))

        return findings

    # ── Shadow check: Ceny transferowe ────────────────────────────────────────

    def _check_tp_risk(self, data: dict) -> list[RiskFinding]:
        findings = []
        vendor = data.get("vendor", {})

        # Transakcja z podmiotem powiązanym (rodzina)
        if vendor.get("is_related_party") is True:
            invoice = data.get("invoice", {})
            amount = invoice.get("amount_gross", 0)

            if amount > 500000:  # Próg dokumentacji TP
                findings.append(RiskFinding(
                    rule_id="jdg.crossborder.tp_jdg_family",
                    category=RiskCategory.TP_RISK,
                    severity=Severity.MEDIUM,
                    legal_basis="Art. 23o-23zf PIT (TP dla JDG)",
                    description=f"Transakcja {amount:,.2f} PLN z podmiotem "
                                 f"powiązanym przekracza próg 500k PLN",
                    recommendation="Przygotuj dokumentację cen transferowych "
                                   "(TPR-C / TPR-P). Termin: 10 miesięcy po "
                                   "zakończeniu roku podatkowego.",
                    probability=0.60,
                ))

        return findings

    # ── Agregacja ryzyka ──────────────────────────────────────────────────────

    def _calculate_risk_score(self, findings: list[RiskFinding]) -> float:
        """
        Oblicz skumulowany wskaźnik ryzyka (0-100).
        Wagi: CRITICAL=25, HIGH=15, MEDIUM=5, LOW=1
        """
        if not findings:
            return 0.0

        severity_weights = {
            Severity.CRITICAL: 25.0,
            Severity.HIGH: 15.0,
            Severity.MEDIUM: 5.0,
            Severity.LOW: 1.0,
        }

        raw_score = sum(
            severity_weights.get(f.severity, 1.0) * f.probability
            for f in findings
        )

        # Normalizacja do 0-100
        return min(raw_score, 100.0)

    def _calculate_max_severity(self, findings: list[RiskFinding]) -> Severity:
        severity_order = {
            Severity.LOW: 0,
            Severity.MEDIUM: 1,
            Severity.HIGH: 2,
            Severity.CRITICAL: 3,
        }
        if not findings:
            return Severity.LOW
        return max(findings, key=lambda f: severity_order[f.severity]).severity

    def _build_summary(
        self, findings: list[RiskFinding], risk_score: float, total_fines: float
    ) -> str:
        """Buduj podsumowanie tekstowe."""
        if not findings:
            return "✅ Brak wykrytych zagrożeń KKS. Transakcja bezpieczna."

        critical = [f for f in findings if f.severity == Severity.CRITICAL]
        high = [f for f in findings if f.severity == Severity.HIGH]
        blockers = [f for f in findings if f.is_blocker]

        parts = []
        if blockers:
            parts.append(f"🚫 {len(blockers)} BLOKERÓW — NIE realizuj bez korekty!")
        if critical:
            parts.append(f"🔴 {len(critical)} zagrożeń KRYTYCZNYCH")
        if high:
            parts.append(f"🟠 {len(high)} zagrożeń WYSOKICH")

        parts.append(f"💰 Potencjalne kary: {total_fines:,.0f} PLN")
        parts.append(f"📊 Skumulowany wskaźnik ryzyka: {risk_score:.1f}/100")

        return " | ".join(parts)


# ── Fast API endpoint builder ─────────────────────────────────────────────────

def build_simulate_response(predictor: JudgmentPredictor, input_data: dict) -> dict:
    """
    Buduje odpowiedź API dla endpointu /jdg/simulate.

    Zwraca pełny wynik predykcji w formacie JSON gotowym do użycia w UI.
    """
    result = predictor.predict(input_data)

    return {
        "status": "ok",
        "timestamp": result.evaluated_at,
        "input_hash": result.input_hash,
        "risk_summary": {
            "risk_level": result.risk_level,
            "risk_score": round(result.risk_score, 1),
            "max_severity": result.max_severity.value,
            "total_findings": result.total_findings,
            "total_potential_fines_pln": round(result.total_potential_fines, 2),
            "total_expected_cost_pln": round(result.total_expected_cost, 2),
            "summary": result.summary,
        },
        "findings": [
            {
                "rule_id": f.rule_id,
                "category": f.category.value,
                "severity": f.severity.value,
                "legal_basis": f.legal_basis,
                "description": f.description,
                "recommendation": f.recommendation,
                "potential_fine_pln": round(f.potential_fine_pln, 2),
                "probability_percent": round(f.probability * 100, 1),
                "is_blocker": f.is_blocker,
            }
            for f in result.findings
        ],
    }


# ── CLI ────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="NexusAI JDG — Judgment Predictor (C1 Strategic Initiative)"
    )
    parser.add_argument("--input", type=str, help="Path to input JSON file")
    parser.add_argument("--demo", action="store_true", help="Run demo prediction")

    args = parser.parse_args()

    predictor = JudgmentPredictor()

    if args.demo:
        demo_input = {
            "invoice": {
                "amount_gross": 25000.00,
                "amount_net": 20325.20,
                "vat_rate": "23%",
                "vat_amount": 4674.80,
                "goods_type": "steel",
                "payment_method": "CASH",
                "split_payment_used": False,
                "is_empty_invoice": False,
                "books_entries_falsified": False,
                "days_overdue": 120,
                "declaration_missing": False,
            },
            "vendor": {
                "name": "StalBud Sp. z o.o.",
                "nip": "1234567890",
                "whitelist_verified": False,
                "is_related_party": False,
            },
            "jdg_entrepreneur": {
                "nip": "9876543210",
                "ytd_revenue_pln": 210000.00,
                "vat_exempt": True,
                "documents_destroyed_count": 0,
            },
        }

        print("═" * 78)
        print("  NexusAI JDG — Judgment Predictor DEMO")
        print("  Tryb: shadow mode (what-if analysis)")
        print("═" * 78)
        print()

        result = predictor.predict(demo_input)
        response = build_simulate_response(predictor, demo_input)

        print(json.dumps(response, indent=2, ensure_ascii=False))

    elif args.input:
        with open(args.input, encoding="utf-8") as f:
            input_data = json.load(f)

        result = predictor.predict(input_data)
        response = build_simulate_response(predictor, input_data)

        print(json.dumps(response, indent=2, ensure_ascii=False))

    else:
        parser.print_help()
