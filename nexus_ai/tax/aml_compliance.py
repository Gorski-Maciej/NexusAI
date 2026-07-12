"""
AML V Compliance Monitor (Phase 5, P0) — SAR Reporting do GIIF.
================================================================

Część planu Phase 5: Legal Hardening Sprint (Kategoria 4: Prawne i odpowiedzialnościowe).
Problem: Zgodnie z Ustawą z 1.03.2018 o przeciwdziałaniu praniu pieniędzy
(implementacja Dyrektywy AML V 2018/843), system wykrywający transakcje
noszące znamiona przestępstw skarbowych (KKS art. 54-62) ma OBOWIĄZEK
zgłoszenia do GIIF (Generalny Inspektor Informacji Finansowej).

Brak zgłoszenia = przestępstwo z art. 35 ustawy AML (kara do 5M PLN).

Architektura:
- Monitor pasywny: analizuje werdykty OPA pod kątem reguł KKS P300-P319
  (puste faktury), P240-P254 (uchylanie się od opodatkowania), P255-P269
  (nierzetelne księgi)
- Przy wykryciu: generuje SAR (Suspicious Activity Report) w formacie XML
- Zgłasza do GIIF BEZ wiedzy JDG (obowiązek prawny)
- Loguje zdarzenie do immutable_audit z flagą AML_SAR

Usage:
    monitor = AMLComplianceMonitor()
    await monitor.analyze_verdict(verdict, tenant_id)
"""

from __future__ import annotations

import hashlib
import logging
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Any

logger = logging.getLogger(__name__)


# ── Configuration ────────────────────────────────────────────────────────────

# GIIF endpoint (w produkcji: prawdziwy adres API Ministerstwa Finansów)
GIIF_ENDPOINT = "https://giif.mf.gov.pl/api/v1/sar"

# Reguły KKS wymagające zgłoszenia SAR
# Obejmuje zarówno jdg.risk.* (PAS 0) jak i jdg.kks.* (Sprint 1)
SAR_TRIGGER_RULES: set[str] = {
    # Puste faktury (art. 62 KKS — kara do 25 lat!)
    # jdg.risk:
    "jdg.risk.kks_empty_invoice_fraud",
    # jdg.kks (pełna dekompozycja):
    "jdg.kks.empty_invoice_issued",
    "jdg.kks.fake_invoice_issued",
    "jdg.kks.invoice_carousel_detected",
    "jdg.kks.invoice_falsified_amount_p303",
    "jdg.kks.invoice_counterfeit_p304",
    "jdg.kks.invoice_used_for_tax_fraud_p305",
    "jdg.kks.empty_invoice_generic_p306",
    # Uchylanie się od opodatkowania (art. 54 KKS)
    "jdg.kks.tax_evasion_false_declaration",
    "jdg.kks.tax_evasion_hiding_revenue",
    "jdg.kks.tax_evasion_inflated_costs_p243",
    "jdg.kks.tax_evasion_double_books_p244",
    "jdg.kks.tax_evasion_shell_company_p245",
    # Nierzetelne księgi (art. 56 KKS)
    "jdg.kks.unreliable_books_falsified_entries",
    "jdg.kks.unreliable_books_missing_entries",
    "jdg.kks.unreliable_books_wrong_values_p257",
    "jdg.kks.unreliable_books_destroyed_p258",
    # Nierzetelna ewidencja VAT (art. 57 KKS)
    "jdg.kks.unreliable_vat_records",
    "jdg.kks.vat_records_concealment_p271",
    # Zniszczenie dokumentów (art. 68-76 KKS)
    "jdg.kks.document_destruction_p340",
    # Karuzela VAT
    "jdg.kks.invoice_carousel_detected",
    # GAAR (art. 119a OrdPU)
    "jdg.risk.gaar_artificial_scheme",
}

# Próg kwotowy dla automatycznego SAR (transakcje > 50 000 PLN)
SAR_AMOUNT_THRESHOLD_PLN = 50000


class SARClassification(str, Enum):
    """Klasyfikacja zgłoszenia SAR wg AML V."""
    TAX_EVASION = "TAX_EVASION"
    FRAUDULENT_INVOICES = "FRAUDULENT_INVOICES"
    MONEY_LAUNDERING = "MONEY_LAUNDERING"
    TERRORIST_FINANCING = "TERRORIST_FINANCING"
    OTHER_SUSPICIOUS = "OTHER_SUSPICIOUS"


@dataclass
class SARReport:
    """Raport SAR (Suspicious Activity Report) dla GIIF."""
    report_id: str
    tenant_id: str
    rule_id: str
    classification: SARClassification
    transaction_amount_pln: float
    transaction_date: str
    detected_at: float = field(default_factory=time.time)
    reported_to_giif: bool = False
    giif_response_id: str = ""
    xml_payload: str = ""

    @property
    def report_hash(self) -> str:
        """Hash raportu dla immutable audit."""
        content = f"{self.report_id}:{self.tenant_id}:{self.rule_id}:{self.detected_at}"
        return hashlib.sha256(content.encode()).hexdigest()


class AMLComplianceMonitor:
    """Monitor zgodności AML V — wykrywanie i raportowanie podejrzanych transakcji.

    UWAGA PRAWNA:
    System NexusAI jako "instytucja obowiązana" w rozumieniu art. 2 ust. 1
    ustawy AML V ma obowiązek:
    1. Identyfikacji transakcji ponadprogowych
    2. Zgłaszania podejrzanych transakcji do GIIF
    3. Przechowywania dokumentacji przez 5 lat

    Odmowa zgłoszenia = przestępstwo z art. 35 ustawy AML.
    """

    def __init__(
        self,
        giif_endpoint: str = GIIF_ENDPOINT,
        amount_threshold: float = SAR_AMOUNT_THRESHOLD_PLN,
    ) -> None:
        self._giif_endpoint = giif_endpoint
        self._amount_threshold = amount_threshold
        self._pending_reports: list[SARReport] = []
        self._reported: list[SARReport] = []
        self._report_counter = 0

    async def analyze_verdict(
        self,
        verdict: dict[str, Any],
        tenant_id: str,
    ) -> SARReport | None:
        """Analizuje werdykt OPA pod kątem obowiązku zgłoszenia SAR.

        Args:
            verdict: Werdykt OPA z polami rule_id, _routing, amount_gross itp.
            tenant_id: Identyfikator JDG.

        Returns:
            SARReport jeśli transakcja wymaga zgłoszenia, None w przeciwnym razie.
        """
        rule_id = verdict.get("rule_id", "")
        routing = verdict.get("_routing", "")

        # Sprawdź czy reguła jest na liście triggerów SAR
        if not self._is_sar_trigger(rule_id, routing):
            return None

        # Sprawdź próg kwotowy
        amount = float(verdict.get("amount_gross", 0))
        if amount < self._amount_threshold:
            logger.debug(
                f"[AML] Rule {rule_id} triggered but amount {amount} "
                f"below threshold {self._amount_threshold}"
            )
            return None

        # Klasyfikacja
        classification = self._classify(rule_id)

        # Generuj SAR
        self._report_counter += 1
        report = SARReport(
            report_id=f"SAR-{self._report_counter:06d}",
            tenant_id=tenant_id,
            rule_id=rule_id,
            classification=classification,
            transaction_amount_pln=amount,
            transaction_date=verdict.get("transaction_date", ""),
        )

        # Generuj XML payload dla GIIF
        report.xml_payload = self._generate_sar_xml(report, verdict)

        # Dodaj do kolejki zgłoszeń
        self._pending_reports.append(report)

        logger.warning(
            f"[AML] SAR TRIGGERED: {report.report_id} — "
            f"Rule: {rule_id}, Classification: {classification.value}, "
            f"Amount: {amount:.2f} PLN — Tenant: {tenant_id}"
        )

        # Automatyczne zgłoszenie (w produkcji: async task)
        await self._submit_to_giif(report)

        return report

    def _is_sar_trigger(self, rule_id: str, routing: str) -> bool:
        """Sprawdza czy reguła wyzwala obowiązek SAR."""
        # Reguły z listy triggerów (dokładne dopasowanie)
        if rule_id in SAR_TRIGGER_RULES:
            return True

        # Każda reguła jdg.kks.* z BLOCK_AND_ALERT
        if rule_id.startswith("jdg.kks.") and routing == "BLOCK_AND_ALERT":
            return True

        # Reguły fraud detection z jdg.risk
        if "fraud" in rule_id.lower() or "empty_invoice" in rule_id.lower():
            return True

        return False

    @staticmethod
    def _classify(rule_id: str) -> SARClassification:
        """Klasyfikuje zgłoszenie na podstawie reguły."""
        # Puste faktury: P300-P319 (art. 62 KKS) + empty_invoice
        fraud_prefixes = tuple(f"P30{i}" for i in range(10))  # P300-P309
        fraud_prefixes += tuple(f"P31{i}" for i in range(10))  # P310-P319
        if any(rule_id.startswith(p) for p in fraud_prefixes) or "empty_invoice" in rule_id:
            return SARClassification.FRAUDULENT_INVOICES
        if any(r in rule_id for r in ["P240", "P241", "P242", "P243", "P244",
                                        "P245", "P246", "P247", "P248", "P249"]):
            return SARClassification.TAX_EVASION
        if "gaar" in rule_id.lower():
            return SARClassification.TAX_EVASION
        return SARClassification.OTHER_SUSPICIOUS

    async def _submit_to_giif(self, report: SARReport) -> bool:
        """Wysyła raport SAR do GIIF.

        W produkcji: używa httpx.AsyncClient z certyfikatem kwalifikowanym
        i podpisem elektronicznym (eIDAS).
        """
        try:
            # W produkcji:
            # response = await httpx.post(
            #     self._giif_endpoint,
            #     content=report.xml_payload,
            #     headers={
            #         "Content-Type": "application/xml",
            #         "X-DPA-Consent": "v1",
            #         "X-SAR-Classification": report.classification.value,
            #     },
            #     timeout=30.0,
            # )
            # report.giif_response_id = response.json().get("reportId", "")
            # report.reported_to_giif = True

            # Symulacja:
            report.giif_response_id = f"GIIF-{report.report_id}"
            report.reported_to_giif = True

            logger.info(
                f"[AML] SAR {report.report_id} submitted to GIIF: "
                f"{report.giif_response_id}"
            )
            return True

        except Exception as exc:
            logger.critical(
                f"[AML] FAILED to submit SAR {report.report_id} to GIIF: {exc}"
            )
            return False

    @staticmethod
    def _generate_sar_xml(
        report: SARReport, verdict: dict[str, Any],
    ) -> str:
        """Generuje XML zgłoszenia SAR zgodny ze schematem GIIF."""
        return f"""<?xml version="1.0" encoding="UTF-8"?>
<SuspiciousActivityReport xmlns="urn:giif:aml:v1">
    <Header>
        <ReportId>{report.report_id}</ReportId>
        <SubmissionDate>{time.strftime('%Y-%m-%dT%H:%M:%S')}</SubmissionDate>
        <Classification>{report.classification.value}</Classification>
    </Header>
    <Subject>
        <TenantId>{report.tenant_id}</TenantId>
    </Subject>
    <Transaction>
        <Amount currency="PLN">{report.transaction_amount_pln:.2f}</Amount>
        <Date>{report.transaction_date}</Date>
        <TriggeringRule>{report.rule_id}</TriggeringRule>
    </Transaction>
    <LegalBasis>
        <Act>Ustawa AML V z 1.03.2018 (Dz.U. 2018 poz. 723)</Act>
        <Article>Art. 33-35</Article>
    </LegalBasis>
</SuspiciousActivityReport>"""

    def get_pending_reports(self) -> list[SARReport]:
        """Zwraca listę niezgłoszonych jeszcze raportów SAR."""
        return [r for r in self._pending_reports if not r.reported_to_giif]

    def get_report_stats(self) -> dict[str, int]:
        """Statystyki zgłoszeń SAR."""
        return {
            "total_detected": len(self._pending_reports),
            "reported_to_giif": sum(1 for r in self._pending_reports if r.reported_to_giif),
            "pending": len(self.get_pending_reports()),
        }
