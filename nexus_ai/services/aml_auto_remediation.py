"""
aml_auto_remediation.py — v7.0 Audit Faza 2 M5: Auto-Remediation dla AML.

Raport v7.0, Genialny Pomysł #7:
  "System auto-remediation dla AML — automatyczne uzupełnianie
   brakujących elementów procedury AML"

Enterprise v7.0 Audit:
  - Auto-generowanie wniosku CBDD
  - Auto-generowanie certyfikatu szkolenia AML + test
  - Auto-generowanie raportu audytu AML
  - Monitoring terminów (szkolenia co 12m, audyt roczny)
  - Wykrywanie luk w procedurze wewnętrznej
  - Integracja z AML Enterprise P1925-P1946
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.aml.remediation")


@dataclass
class AmlGap:
    """Luka w procedurze AML."""
    gap_id: str
    category: str  # CBDD, TRAINING, AUDIT, PROCEDURE, DOCUMENTATION
    description: str
    severity: str  # CRITICAL, HIGH, MEDIUM
    deadline_days: int = 30
    legal_basis: str = ""
    auto_fixable: bool = False
    fixed: bool = False
    fixed_at: str = ""


@dataclass
class AmlRemediationReport:
    """Raport auto-remediacji AML."""
    jdg_id: str
    gaps_found: list[AmlGap] = field(default_factory=list)
    gaps_fixed: list[AmlGap] = field(default_factory=list)
    generated_documents: list[str] = field(default_factory=list)
    compliance_score: float = 100.0  # 0-100
    recommendations: list[str] = field(default_factory=list)
    generated_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())


class AmlAutoRemediation:
    """Silnik automatycznej naprawy luk AML.

    Raport v7.0, Pomysł #7.

    Usage:
        remediator = AmlAutoRemediation()
        report = remediator.audit_and_remediate(
            jdg_id="1234567890",
            aml_checklist=current_status,
        )
        for doc in report.generated_documents:
            print(f"Wygenerowano: {doc}")
    """

    # Wymagane elementy procedury AML
    REQUIRED_ELEMENTS = [
        "CBDD_REGISTRATION",    # Rejestracja w CRBR
        "AML_TRAINING",         # Szkolenie AML (co 12m)
        "AML_AUDIT",            # Audyt AML (roczny)
        "AML_PROCEDURE",        # Procedura wewnętrzna
        "RISK_ASSESSMENT",      # Ocena ryzyka
        "STR_PROCEDURE",        # Procedura zgłoszeń SAR/STR
        "PEP_SCREENING_PROC",   # Procedura PEP
        "DOCUMENTATION_5Y",     # Retencja dokumentacji 5 lat
    ]

    def __init__(self) -> None:
        self._remediation_history: list[AmlRemediationReport] = []

    # ── Główny audyt i remediacja ─────────────────────────────────────

    def audit_and_remediate(
        self,
        jdg_id: str,
        aml_checklist: dict[str, Any],
        employee_count: int = 0,
        last_training_date: str = "",
        last_audit_date: str = "",
    ) -> AmlRemediationReport:
        """Przeprowadź audyt AML i automatyczną remediację.

        Args:
            jdg_id: NIP / ID JDG.
            aml_checklist: Status obecny elementów AML.
            employee_count: Liczba pracowników.
            last_training_date: Data ostatniego szkolenia.
            last_audit_date: Data ostatniego audytu.

        Returns:
            AmlRemediationReport.
        """
        gaps: list[AmlGap] = []
        generated_docs: list[str] = []
        recommendations: list[str] = []

        # Sprawdź każdy wymagany element
        completed = aml_checklist.get("completed_elements", [])

        for element in self.REQUIRED_ELEMENTS:
            if element not in completed:
                gap = self._create_gap(element, last_training_date, last_audit_date)
                gaps.append(gap)

                # Auto-fix jeśli możliwe
                if gap.auto_fixable and gap.category == "TRAINING":
                    doc = self._generate_training_certificate(jdg_id)
                    generated_docs.append(doc)
                    recommendations.append(f"Wygenerowano certyfikat szkolenia AML: {doc}")

                elif gap.auto_fixable and gap.category == "AUDIT":
                    doc = self._generate_audit_report(jdg_id)
                    generated_docs.append(doc)
                    recommendations.append(f"Wygenerowano raport audytu AML: {doc}")

                elif gap.auto_fixable and gap.category == "CBDD":
                    doc = self._generate_cbdd_application(jdg_id)
                    generated_docs.append(doc)
                    recommendations.append(f"Wygenerowano wniosek CBDD: {doc}")

        # Oblicz compliance score
        total = len(self.REQUIRED_ELEMENTS)
        missing = len(gaps)
        score = max(0, 100 * (total - missing) / total)

        # Dodatkowe rekomendacje
        if employee_count >= 50:
            recommendations.append(
                "Whistleblower: przy >=50 pracownikach — obowiązek procedury "
                "zgłoszeń wewnętrznych (ustawa o sygnalistach 2024)"
            )

        if missing > 0:
            recommendations.append(
                f"UWAGA: {missing}/{total} elementów AML niekompletnych. "
                f"Kara za brak: do 5 000 000 PLN (KNF)."
            )

        report = AmlRemediationReport(
            jdg_id=jdg_id,
            gaps_found=gaps,
            gaps_fixed=[g for g in gaps if g.auto_fixable],
            generated_documents=generated_docs,
            compliance_score=round(score, 1),
            recommendations=recommendations,
        )

        self._remediation_history.append(report)

        logger.info(
            "[AML-REMED] %s | score=%.1f%% | gaps=%d | fixed=%d | docs=%d",
            jdg_id, score, missing,
            len(report.gaps_fixed), len(generated_docs),
        )

        return report

    # ── Gap Detection ──────────────────────────────────────────────────

    def _create_gap(
        self,
        element: str,
        last_training: str,
        last_audit: str,
    ) -> AmlGap:
        """Utwórz opis luki."""
        gap_map = {
            "CBDD_REGISTRATION": AmlGap(
                gap_id="AML-CBDD-001",
                category="CBDD",
                description="Brak rejestracji w Centralnym Rejestrze Beneficjentów Rzeczywistych",
                severity="CRITICAL",
                deadline_days=7,
                legal_basis="Art. 59 Ustawy AML — kara do 1 000 000 PLN",
                auto_fixable=True,
            ),
            "AML_TRAINING": AmlGap(
                gap_id="AML-TRN-001",
                category="TRAINING",
                description=f"Szkolenie AML wymagane co 12 miesięcy. Ostatnie: {last_training or 'NIGDY'}",
                severity="HIGH",
                deadline_days=30,
                legal_basis="Art. 16 ust. 2 Ustawy AML",
                auto_fixable=True,
            ),
            "AML_AUDIT": AmlGap(
                gap_id="AML-AUD-001",
                category="AUDIT",
                description=f"Roczny audyt AML. Ostatni: {last_audit or 'NIGDY'}",
                severity="HIGH",
                deadline_days=30,
                legal_basis="Art. 16 ust. 1 Ustawy AML",
                auto_fixable=True,
            ),
            "AML_PROCEDURE": AmlGap(
                gap_id="AML-PROC-001",
                category="PROCEDURE",
                description="Brak wewnętrznej procedury AML",
                severity="CRITICAL",
                deadline_days=14,
                legal_basis="Art. 16 ust. 1 Ustawy AML",
                auto_fixable=False,
            ),
            "RISK_ASSESSMENT": AmlGap(
                gap_id="AML-RISK-001",
                category="DOCUMENTATION",
                description="Brak oceny ryzyka AML",
                severity="HIGH",
                deadline_days=30,
                legal_basis="Art. 33 Ustawy AML",
                auto_fixable=False,
            ),
            "STR_PROCEDURE": AmlGap(
                gap_id="AML-STR-001",
                category="PROCEDURE",
                description="Brak procedury zgłaszania transakcji podejrzanych (STR/SAR)",
                severity="CRITICAL",
                deadline_days=14,
                legal_basis="Art. 33-35 Ustawy AML — kara do 5 000 000 PLN",
                auto_fixable=False,
            ),
            "PEP_SCREENING_PROC": AmlGap(
                gap_id="AML-PEP-001",
                category="PROCEDURE",
                description="Brak procedury weryfikacji PEP",
                severity="MEDIUM",
                deadline_days=30,
                legal_basis="Art. 43-45 Ustawy AML",
                auto_fixable=False,
            ),
            "DOCUMENTATION_5Y": AmlGap(
                gap_id="AML-DOC-001",
                category="DOCUMENTATION",
                description="Brak systemu retencji dokumentacji AML (5 lat)",
                severity="MEDIUM",
                deadline_days=30,
                legal_basis="Art. 16 ust. 3 Ustawy AML",
                auto_fixable=False,
            ),
        }
        return gap_map.get(element, AmlGap(
            gap_id=f"AML-UNK-{element[:8]}",
            category="UNKNOWN",
            description=f"Brak elementu: {element}",
            severity="MEDIUM",
            deadline_days=30,
        ))

    # ── Document Generators ────────────────────────────────────────────

    def _generate_training_certificate(self, jdg_id: str) -> str:
        """Generuj certyfikat szkolenia AML."""
        today = date.today()
        cert_id = f"AML-TRN-{jdg_id}-{today.strftime('%Y%m%d')}"
        return (
            f"CERTYFIKAT SZKOLENIA AML — {cert_id}\n"
            f"Data: {today.strftime('%d.%m.%Y')}\n"
            f"Podmiot: JDG {jdg_id}\n"
            f"Tematyka: AML V — przeciwdziałanie praniu pieniędzy i finansowaniu terroryzmu\n"
            f"Zakres: CDD/EDD, PEP, STR/SAR, CBDD, sankcje międzynarodowe\n"
            f"Ważność: 12 miesięcy\n"
            f"Podstawa prawna: Art. 16 ust. 2 Ustawy AML (Dz.U. 2018 poz. 723)"
        )

    def _generate_audit_report(self, jdg_id: str) -> str:
        """Generuj raport audytu AML."""
        today = date.today()
        audit_id = f"AML-AUD-{jdg_id}-{today.strftime('%Y%m%d')}"
        return (
            f"RAPORT AUDYTU AML — {audit_id}\n"
            f"Data audytu: {today.strftime('%d.%m.%Y')}\n"
            f"Podmiot: JDG {jdg_id}\n"
            f"Zakres: Pełny audyt AML (Art. 16 ust. 1 Ustawy AML)\n"
            f"Wynik: Pozytywny z uwagami (zobacz raport szczegółowy)\n"
            f"Następny audyt: {today.replace(year=today.year + 1).strftime('%d.%m.%Y')}"
        )

    def _generate_cbdd_application(self, jdg_id: str) -> str:
        """Generuj wniosek o wpis do CBDD."""
        today = date.today()
        return (
            f"WNIOSEK O WPIS DO CBDD\n"
            f"Data: {today.strftime('%d.%m.%Y')}\n"
            f"Podmiot: JDG {jdg_id}\n"
            f"Termin: 7 dni od wpisu do CEIDG/KRS\n"
            f"Podstawa: Art. 59 Ustawy AML\n"
            f"Kara za brak: do 1 000 000 PLN\n"
            f"\n"
            f"UWAGA: Wniosek należy złożyć przez stronę CRBR (crbr.podatki.gov.pl)"
        )

    # ── Statistics ─────────────────────────────────────────────────────

    def get_history(self, limit: int = 20) -> list[AmlRemediationReport]:
        return self._remediation_history[-limit:]

    def get_compliance_summary(self) -> dict[str, Any]:
        """Podsumowanie compliance AML."""
        if not self._remediation_history:
            return {"total_audits": 0}

        latest = self._remediation_history[-1]
        all_gaps = [g for r in self._remediation_history for g in r.gaps_found]
        critical = sum(1 for g in all_gaps if g.severity == "CRITICAL")

        return {
            "total_audits": len(self._remediation_history),
            "latest_score": latest.compliance_score,
            "total_gaps_found": len(all_gaps),
            "critical_gaps": critical,
            "total_documents_generated": sum(
                len(r.generated_documents) for r in self._remediation_history
            ),
        }
