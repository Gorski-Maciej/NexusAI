"""
kks_defense_generator.py — v7.0 Audit Faza 2 M1: Auto-Generator Pism Obronnych KKS.

Raport v7.0, Rekomendacja #7:
  "Dodaj automatyczny generator pism obronnych KKS"

Raport v7.0, Genialny Pomysł #2:
  "Automatyczny generator strategii obrony przed US"

Enterprise v7.0 Audit:
  - Wniosek o czynny żal (Art. 16 KKS) z kalkulacją oszczędności
  - Korekta JPK_V7 / PIT-36 / PIT-36L
  - Pismo wyjaśniające do US
  - Wniosek o nadzwyczajne złagodzenie kary (Art. 17 KKS)
  - Wniosek o rozłożenie na raty / odroczenie (Art. 67a OrdPU)
  - Kalkulacja kary standardowej vs po czynnym żalu
  - Template engine z danymi z OPA verdicts
"""

from __future__ import annotations

import hashlib
from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.kks.defense")


# ═══════════════════════════════════════════════════════════════════════════
# Szablony pism
# ═══════════════════════════════════════════════════════════════════════════

_TEMPLATE_VOLUNTARY_DISCLOSURE = """
================================================================================
                    ZAWIADOMIENIE O CZYNNYM ŻALU
              (Art. 16 § 1-3 Kodeksu Karnego Skarbowego)
================================================================================

Miejscowość: {city}, dnia {date}

Do: Naczelnik {tax_office}
    {tax_office_address}

Od: {jdg_name}
    NIP: {jdg_nip}
    Adres: {jdg_address}

═══════════════════════════════════════════════════════════════════════════════

Działając na podstawie art. 16 § 1 Kodeksu Karnego Skarbowego, niniejszym
składam zawiadomienie o popełnieniu czynu zabronionego:

1. OPIS NIEPRAWIDŁOWOŚCI:
   {offense_description}

2. OKOLICZNOŚCI POPEŁNIENIA CZYNU:
   - Data czynu: {offense_date}
   - Dotyczy faktury nr: {invoice_number}
   - Kwota uszczuplenia: {tax_shortfall:.2f} PLN
   - Rodzaj nieprawidłowości: {offense_type}

3. RODZAJ NARUSZONEGO PRZEPISU:
   {legal_basis}

4. OSOBY WSPÓŁDZIAŁAJĄCE:
   Brak — czyn popełniony samodzielnie.

5. DOWODY WPŁATY:
   W załączeniu potwierdzenie przelewu na kwotę {payment_amount:.2f} PLN
   na rachunek {tax_office_account}.

6. ZAŁĄCZNIKI:
   - Korekta deklaracji {declaration_type}
   - Potwierdzenie wpłaty zaległości
   - Kopia faktury nr {invoice_number}

═══════════════════════════════════════════════════════════════════════════════
KALKULACJA KORZYŚCI Z CZYNNEGO ŻALU:
  - Kara standardowa (maks.): {max_penalty:,.2f} PLN
  - Po czynnym żalu:         0.00 PLN (immunitet)
  - OSZCZĘDNOŚĆ:             {max_penalty:,.2f} PLN ({savings_pct:.0f}%)
═══════════════════════════════════════════════════════════════════════════════

                                 Podpis: ____________________________
"""

_TEMPLATE_CORRECTION_COVER = """
================================================================================
                    PISMO PRZEWODNIE — KOREKTA DEKLARACJI
================================================================================

Miejscowość: {city}, dnia {date}

Do: Naczelnik {tax_office}

Od: {jdg_name}, NIP: {jdg_nip}

═══════════════════════════════════════════════════════════════════════════════

Składam korektę deklaracji {declaration_type} za okres {period}:

PRZYCZYNA KOREKTY:
{correction_reason}

ZMIANY:
- Przed korektą: {before_value:,.2f} PLN
- Po korekcie:   {after_value:,.2f} PLN
- Różnica:       {difference:,.2f} PLN ({direction})

UZASADNIENIE:
{justification}

W załączeniu:
- Skorygowana deklaracja {declaration_type}
- Dowód wpłaty różnicy podatku (jeśli dotyczy)

                                 Podpis: ____________________________
"""

_TEMPLATE_MITIGATION_REQUEST = """
================================================================================
           WNIOSEK O NADZWYCZAJNE ZŁAGODZENIE KARY (Art. 17 KKS)
================================================================================

Miejscowość: {city}, dnia {date}

Do: {court_name}

Od: {jdg_name}, NIP: {jdg_nip}

═══════════════════════════════════════════════════════════════════════════════

Wnoszę o nadzwyczajne złagodzenie kary na podstawie art. 17 KKS:

PRZESŁANKI:
{mitigation_factors}

OKOLICZNOŚCI ŁAGODZĄCE:
{mitigating_circumstances}

DOWODY:
- {evidence_list}

WNIOSEK:
Wnoszę o: {request}

                                 Podpis: ____________________________
"""

_TEMPLATE_INSTALLMENT_REQUEST = """
================================================================================
         WNIOSEK O ROZŁOŻENIE NA RATY / ODROCZENIE PŁATNOŚCI
                    (Art. 67a-67e Ordynacji Podatkowej)
================================================================================

Miejscowość: {city}, dnia {date}

Do: Naczelnik {tax_office}

Od: {jdg_name}, NIP: {jdg_nip}

═══════════════════════════════════════════════════════════════════════════════

Wnoszę o {request_type} na podstawie art. {legal_basis}:

KWOTA ZALEGŁOŚCI: {total_due:,.2f} PLN

PROPONOWANY HARMONOGRAM:
- Liczba rat: {installments}
- Kwota raty: {installment_amount:,.2f} PLN
- Termin płatności: {payment_day} dnia każdego miesiąca

UZASADNIENIE:
{justification}

OŚWIADCZENIE O SYTUACJI MAJĄTKOWEJ:
{financial_statement}

                                 Podpis: ____________________________
"""


# ═══════════════════════════════════════════════════════════════════════════
# Dane słownikowe
# ═══════════════════════════════════════════════════════════════════════════

OFFENSE_DESCRIPTIONS: dict[str, str] = {
    "EMPTY_INVOICE": "Wystawienie faktury dokumentującej czynność, która nie miała miejsca (art. 62 § 2 KKS)",
    "TAX_EVASION": "Złożenie deklaracji podatkowej niezgodnej ze stanem rzeczywistym (art. 54 § 1 KKS)",
    "UNRELIABLE_BOOKS": "Prowadzenie nierzetelnej dokumentacji księgowej (art. 56 § 1 KKS)",
    "UNRELIABLE_VAT": "Nierzetelne prowadzenie ewidencji VAT (art. 57 § 1 KKS)",
    "DECLARATION_NOT_FILED": "Niezłożenie deklaracji podatkowej w terminie (art. 77 KKS)",
    "TAX_UNPAID": "Niezapłacenie należnego podatku (art. 79 KKS)",
    "WRONG_VAT_RATE": "Zastosowanie niewłaściwej stawki VAT (art. 64 KKS)",
    "DESTROYED_DOCUMENTS": "Zniszczenie dokumentów księgowych (art. 68 KKS)",
    "OBSTRUCTION": "Utrudnianie kontroli podatkowej (art. 69 KKS)",
}


@dataclass
class DefenseDocument:
    """Wygenerowany dokument obronny."""

    doc_id: str
    doc_type: str  # voluntary_disclosure, correction_cover, mitigation, installment
    title: str
    content: str
    generated_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())
    invoice_id: str = ""
    jdg_id: str = ""
    hash: str = ""


@dataclass
class DefensePackage:
    """Kompletny pakiet dokumentów obronnych."""

    jdg_id: str
    invoice_id: str
    documents: list[DefenseDocument] = field(default_factory=list)
    estimated_savings_pln: float = 0.0
    savings_pct: float = 0.0
    summary: str = ""
    generated_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())


class KksDefenseGenerator:
    """Auto-generator dokumentów obronnych KKS.

    Raport v7.0, Rekomendacja #7 + Pomysł #2.

    Usage:
        gen = KksDefenseGenerator()
        package = gen.generate_defense_package(opa_verdict, invoice_data, jdg_data)
        print(package.documents[0].content)  # Wniosek o czynny żal
        print(f"Oszczędność: {package.estimated_savings_pln:,.2f} PLN")
    """

    def __init__(self) -> None:
        self._generated_count = 0
        self._doc_history: list[DefensePackage] = []

    # ── Główna metoda ──────────────────────────────────────────────────

    def generate_defense_package(
        self,
        opa_verdict: dict[str, Any],
        invoice_data: dict[str, Any],
        jdg_data: dict[str, Any] | None = None,
    ) -> DefensePackage:
        """Wygeneruj kompletny pakiet dokumentów obronnych.

        Args:
            opa_verdict: Werdykt OPA (rule_id, kks_offense_type, kks_penalty_severity, itd.).
            invoice_data: Dane faktury.
            jdg_data: Dane JDG (nazwa, NIP, adres, US).

        Returns:
            DefensePackage z wszystkimi wygenerowanymi dokumentami.
        """
        jdg = jdg_data or {}
        invoice_id = str(invoice_data.get("id", invoice_data.get("number", "unknown")))
        jdg_id = str(jdg.get("id", jdg.get("nip", "unknown")))
        documents: list[DefenseDocument] = []

        # 1. Wniosek o czynny żal (jeśli KKS flag)
        offense_type = opa_verdict.get("kks_offense_type", "")
        if offense_type:
            doc = self._generate_voluntary_disclosure(opa_verdict, invoice_data, jdg)
            documents.append(doc)

        # 2. Pismo przewodnie do korekty
        if opa_verdict.get("_routing") in ("BLOCK_AND_ALERT", "TRIAGE_QUEUE"):
            doc = self._generate_correction_cover(opa_verdict, invoice_data, jdg)
            documents.append(doc)

        # 3. Wniosek o nadzwyczajne złagodzenie kary
        if opa_verdict.get("kks_penalty_severity") in ("CRITICAL", "HIGH"):
            doc = self._generate_mitigation_request(opa_verdict, invoice_data, jdg)
            documents.append(doc)

        # 4. Wniosek o rozłożenie na raty (przy dużych kwotach)
        tax_shortfall = float(opa_verdict.get("kks_tax_shortfall",
                              invoice_data.get("tax_shortfall_pln", 0)))
        if tax_shortfall > 5000:
            doc = self._generate_installment_request(tax_shortfall, invoice_data, jdg)
            documents.append(doc)

        # Oblicz oszczędności
        max_daily_rates = opa_verdict.get("kks_max_daily_rates", 0)
        max_penalty = self._calculate_penalty(max_daily_rates, tax_shortfall)
        savings = max_penalty if documents else 0
        savings_pct = 67.0 if documents else 0  # Czynny żal ≈ 67% oszczędności

        package = DefensePackage(
            jdg_id=jdg_id,
            invoice_id=invoice_id,
            documents=documents,
            estimated_savings_pln=savings,
            savings_pct=savings_pct,
            summary=self._build_summary(documents, savings, offense_type),
        )

        self._generated_count += 1
        self._doc_history.append(package)

        logger.info(
            "[KKS-DEFENSE] Package generated | docs=%d | savings=%.0f PLN | offense=%s",
            len(documents), savings, offense_type,
        )

        return package

    # ── Generatory dokumentów ───────────────────────────────────────────

    def _generate_voluntary_disclosure(
        self, verdict: dict[str, Any], invoice: dict[str, Any], jdg: dict[str, Any],
    ) -> DefenseDocument:
        """Generuj wniosek o czynny żal."""
        offense_type = verdict.get("kks_offense_type", "UNKNOWN")
        max_daily_rates = verdict.get("kks_max_daily_rates", 0)
        tax_shortfall = float(verdict.get("kks_tax_shortfall",
                              invoice.get("tax_shortfall_pln", 0)))
        max_penalty = self._calculate_penalty(max_daily_rates, tax_shortfall)

        content = _TEMPLATE_VOLUNTARY_DISCLOSURE.format(
            city=jdg.get("city", "Warszawa"),
            date=date.today().strftime("%d.%m.%Y"),
            tax_office=jdg.get("tax_office", "właściwy Urząd Skarbowy"),
            tax_office_address=jdg.get("tax_office_address", ""),
            jdg_name=jdg.get("name", jdg.get("company_name", "Przedsiębiorca")),
            jdg_nip=jdg.get("nip", ""),
            jdg_address=jdg.get("address", ""),
            offense_description=OFFENSE_DESCRIPTIONS.get(
                offense_type, f"Naruszenie przepisów KKS — {offense_type}",
            ),
            offense_date=invoice.get("transaction_date", invoice.get("issue_date", "")),
            invoice_number=invoice.get("number", invoice.get("id", "")),
            tax_shortfall=tax_shortfall,
            offense_type=offense_type,
            legal_basis=verdict.get("_legal_basis", "Kodeks Karny Skarbowy"),
            payment_amount=tax_shortfall,
            tax_office_account=jdg.get("tax_office_account", ""),
            declaration_type=invoice.get("tax_declaration_type", "JPK_V7M"),
            max_penalty=max_penalty,
            savings_pct=100.0,
        )

        return DefenseDocument(
            doc_id=f"VD-{self._hash_id(invoice)}",
            doc_type="voluntary_disclosure",
            title="Zawiadomienie o czynnym żalu (Art. 16 § 1 KKS)",
            content=content,
            invoice_id=str(invoice.get("id", invoice.get("number", ""))),
            jdg_id=jdg.get("nip", ""),
            hash=self._hash_content(content),
        )

    def _generate_correction_cover(
        self, verdict: dict[str, Any], invoice: dict[str, Any], jdg: dict[str, Any],
    ) -> DefenseDocument:
        """Generuj pismo przewodnie do korekty deklaracji."""
        amount_net = float(invoice.get("amount_net", 0))
        input_vat = float(invoice.get("vat_rate", 0.23))
        tax_shortfall = float(verdict.get("kks_tax_shortfall", amount_net * input_vat))

        content = _TEMPLATE_CORRECTION_COVER.format(
            city=jdg.get("city", "Warszawa"),
            date=date.today().strftime("%d.%m.%Y"),
            tax_office=jdg.get("tax_office", "właściwy Urząd Skarbowy"),
            jdg_name=jdg.get("name", jdg.get("company_name", "Przedsiębiorca")),
            jdg_nip=jdg.get("nip", ""),
            declaration_type=invoice.get("tax_declaration_type", "JPK_V7M"),
            period=invoice.get("tax_period", date.today().strftime("%Y-%m")),
            correction_reason=OFFENSE_DESCRIPTIONS.get(
                verdict.get("kks_offense_type", ""), "Korekta danych",
            ),
            before_value=tax_shortfall,
            after_value=0.0,
            difference=tax_shortfall,
            direction="dopłata" if tax_shortfall > 0 else "nadpłata",
            justification="Korekta wynika z dobrowolnego ujawnienia nieprawidłowości "
                         "przed wszczęciem kontroli podatkowej.",
        )

        return DefenseDocument(
            doc_id=f"CC-{self._hash_id(invoice)}",
            doc_type="correction_cover",
            title=f"Pismo przewodnie — korekta {invoice.get('tax_declaration_type', 'deklaracji')}",
            content=content,
            invoice_id=str(invoice.get("id", invoice.get("number", ""))),
            jdg_id=jdg.get("nip", ""),
            hash=self._hash_content(content),
        )

    def _generate_mitigation_request(
        self, verdict: dict[str, Any], invoice: dict[str, Any], jdg: dict[str, Any],
    ) -> DefenseDocument:
        """Generuj wniosek o nadzwyczajne złagodzenie kary."""
        mitigating = []
        if verdict.get("kks_voluntary_disclosure"):
            mitigating.append("- Złożenie czynnego żalu przed wszczęciem postępowania")
        if not verdict.get("kks_aggravating"):
            mitigating.append("- Brak okoliczności obciążających")
        mitigating.append("- Naprawienie szkody w całości")
        mitigating.append("- Współpraca z organami podatkowymi")

        content = _TEMPLATE_MITIGATION_REQUEST.format(
            city=jdg.get("city", "Warszawa"),
            date=date.today().strftime("%d.%m.%Y"),
            court_name="Sąd Rejonowy właściwy dla siedziby US",
            jdg_name=jdg.get("name", jdg.get("company_name", "Przedsiębiorca")),
            jdg_nip=jdg.get("nip", ""),
            mitigation_factors="\n".join(mitigating),
            mitigating_circumstances="Czyn popełniony nieumyślnie, bez świadomości naruszenia przepisów.",
            evidence_list="Potwierdzenie wpłaty zaległości, korekta deklaracji, zawiadomienie o czynnym żalu",
            request="nadzwyczajne złagodzenie kary poprzez odstąpienie od jej wymierzenia",
        )

        return DefenseDocument(
            doc_id=f"MR-{self._hash_id(invoice)}",
            doc_type="mitigation",
            title="Wniosek o nadzwyczajne złagodzenie kary (Art. 17 KKS)",
            content=content,
            invoice_id=str(invoice.get("id", invoice.get("number", ""))),
            jdg_id=jdg.get("nip", ""),
            hash=self._hash_content(content),
        )

    def _generate_installment_request(
        self, tax_shortfall: float, invoice: dict[str, Any], jdg: dict[str, Any],
    ) -> DefenseDocument:
        """Generuj wniosek o rozłożenie na raty."""
        installments = min(12, max(3, int(tax_shortfall / 1000)))
        inst_amount = tax_shortfall / installments

        content = _TEMPLATE_INSTALLMENT_REQUEST.format(
            city=jdg.get("city", "Warszawa"),
            date=date.today().strftime("%d.%m.%Y"),
            tax_office=jdg.get("tax_office", "właściwy Urząd Skarbowy"),
            jdg_name=jdg.get("name", jdg.get("company_name", "Przedsiębiorca")),
            jdg_nip=jdg.get("nip", ""),
            request_type="rozłożenie na raty zaległości podatkowej",
            legal_basis="67a § 1 pkt 2 Ordynacji Podatkowej",
            total_due=tax_shortfall,
            installments=installments,
            installment_amount=inst_amount,
            payment_day=10,
            justification="Jednorazowa spłata mogłaby spowodować znaczne trudności finansowe "
                         "dla prowadzonej działalności gospodarczej.",
            financial_statement="Oświadczam, że moja sytuacja majątkowa uniemożliwia "
                              "jednorazową spłatę zaległości bez uszczerbku dla "
                              "prowadzonej działalności gospodarczej.",
        )

        return DefenseDocument(
            doc_id=f"IR-{self._hash_id(invoice)}",
            doc_type="installment",
            title="Wniosek o rozłożenie na raty (Art. 67a § 1 pkt 2 OrdPU)",
            content=content,
            invoice_id=str(invoice.get("id", invoice.get("number", ""))),
            jdg_id=jdg.get("nip", ""),
            hash=self._hash_content(content),
        )

    # ── Kalkulatory ─────────────────────────────────────────────────────

    @staticmethod
    def _calculate_penalty(max_daily_rates: int, tax_shortfall: float) -> float:
        """Oblicz maksymalną karę grzywny."""
        if max_daily_rates > 0:
            min_wage_daily = 4300.0 / 30  # Minimalne wynagrodzenie 2026
            max_daily = min_wage_daily * 400
            return max_daily_rates * max_daily
        return max(tax_shortfall * 1.5, 1000.0)

    @staticmethod
    def _build_summary(
        documents: list[DefenseDocument], savings: float, offense_type: str,
    ) -> str:
        """Zbuduj podsumowanie pakietu obronnego."""
        if not documents:
            return "Brak wykrytych nieprawidłowości KKS."

        doc_types = [d.doc_type for d in documents]
        lines = [
            "═══ PAKIET OBRONNY KKS ═══",
            f"Liczba dokumentów: {len(documents)}",
            f"Szacunkowa oszczędność: {savings:,.2f} PLN",
            "",
            "Wygenerowane dokumenty:",
        ]
        for i, doc in enumerate(documents, 1):
            lines.append(f"  {i}. {doc.title}")
        lines.append("")
        lines.append("ZALECANE DZIAŁANIA:")
        lines.append(f"  1. Złóż zawiadomienie o czynnym żalu NATYCHMIAST")
        lines.append(f"  2. Wpłać zaległość w ciągu 7 dni")
        lines.append(f"  3. Przechowuj kopie wszystkich dokumentów")
        return "\n".join(lines)

    # ── Helpers ─────────────────────────────────────────────────────────

    @staticmethod
    def _hash_id(invoice: dict[str, Any]) -> str:
        raw = str(invoice.get("id", invoice.get("number", str(datetime.now().timestamp()))))
        return hashlib.sha256(raw.encode()).hexdigest()[:12]

    @staticmethod
    def _hash_content(content: str) -> str:
        return hashlib.sha256(content.encode()).hexdigest()

    # ── Stats ───────────────────────────────────────────────────────────

    @property
    def generated_count(self) -> int:
        return self._generated_count

    def get_history(self, limit: int = 20) -> list[DefensePackage]:
        return self._doc_history[-limit:]
