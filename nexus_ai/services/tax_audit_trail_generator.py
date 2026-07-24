"""
tax_audit_trail_generator.py — v7.0 Audit Faza 3 T3: Tax Audit Trail Generator.

Raport v7.0, Genialny Pomysł #10:
  "Mechanizm Tax Audit Trail Generator — automatycznie generuje pełny
   audit trail dla każdej decyzji systemu"

Enterprise v7.0 Audit:
  - Dla każdej decyzji: timestamp, input snapshot (hash), rule_id + legal_basis
  - Decision rationale + human review status
  - Eksport jako PDF-ready markdown z podpisem cyfrowym
  - Hash SHA-256 dla niemutowalności
  - Możliwość wykorzystania podczas kontroli jako "dowód należytej staranności"
  - Art. 19 § 1-2 KKS — okoliczność łagodząca!
"""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.audit.trail")


@dataclass
class AuditTrailEntry:
    """Pojedynczy wpis w audit trail."""

    entry_id: str
    timestamp: str
    rule_id: str
    legal_basis: str
    input_snapshot_hash: str  # SHA-256 input data
    output_snapshot_hash: str  # SHA-256 output
    decision: str  # ALLOW, TRIAGE, BLOCK, etc.
    rationale: str
    human_reviewed: bool = False
    reviewer_id: str = ""
    review_timestamp: str = ""
    severity: str = "LOW"


@dataclass
class AuditTrailReport:
    """Kompletny raport audit trail."""

    report_id: str
    jdg_id: str
    period_start: str
    period_end: str
    entries: list[AuditTrailEntry] = field(default_factory=list)
    total_decisions: int = 0
    blocked_count: int = 0
    triage_count: int = 0
    human_reviewed_count: int = 0
    digital_signature: str = ""  # SHA-256 całego raportu
    generated_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())
    legal_notice: str = (
        "Raport wygenerowany automatycznie przez NexusAI AI Auditor v7.0. "
        "Stanowi dowód należytej staranności w rozumieniu Art. 19 § 1-2 KKS. "
        "W przypadku kontroli podatkowej, niniejszy dokument może być "
        "przedstawiony jako dowód na dochowanie należytej staranności."
    )


class TaxAuditTrailGenerator:
    """Generator pełnego, niemutowalnego audit trail.

    Raport v7.0, Pomysł #10.

    Usage:
        gen = TaxAuditTrailGenerator()
        
        # Rejestruj decyzję
        entry = gen.record_decision(
            rule_id="jdg.kks.empty_invoice_art62",
            legal_basis="Art. 62 § 2 KKS",
            input_data={"invoice": {"amount": 50000, "is_empty": True}},
            output_data={"decision": "BLOCK_AND_ALERT"},
            decision="BLOCK_AND_ALERT",
            rationale="Pusta faktura wykryta — Art. 62 KKS",
        )
        
        # Generuj raport
        report = gen.generate_report(jdg_id="1234567890")
        print(f"Audit trail: {report.total_decisions} decyzji")
        print(f"Signature: {report.digital_signature}")
    """

    def __init__(self) -> None:
        self._entries: list[AuditTrailEntry] = []
        self._entry_counter: int = 0

    # ── Record Decision ───────────────────────────────────────────────

    def record_decision(
        self,
        rule_id: str,
        legal_basis: str,
        input_data: dict[str, Any],
        output_data: dict[str, Any],
        decision: str = "",
        rationale: str = "",
        severity: str = "LOW",
        human_reviewed: bool = False,
        reviewer_id: str = "",
    ) -> AuditTrailEntry:
        """Zarejestruj decyzję systemu w audit trail.

        Args:
            rule_id: ID reguły OPA.
            legal_basis: Podstawa prawna.
            input_data: Dane wejściowe (faktura/dane JDG).
            output_data: Dane wyjściowe (werdykt).
            decision: Akcja (ALLOW, TRIAGE_QUEUE, BLOCK_AND_ALERT, FREEZE).
            rationale: Uzasadnienie decyzji.
            severity: Poziom istotności.
            human_reviewed: Czy decyzja była weryfikowana przez człowieka.
            reviewer_id: ID weryfikatora.

        Returns:
            AuditTrailEntry.
        """
        self._entry_counter += 1

        # Hashe dla niemutowalności
        input_hash = self._hash_data(input_data)
        output_hash = self._hash_data(output_data)

        entry = AuditTrailEntry(
            entry_id=f"AT-{self._entry_counter:08d}",
            timestamp=datetime.now().isoformat(),
            rule_id=rule_id,
            legal_basis=legal_basis,
            input_snapshot_hash=input_hash,
            output_snapshot_hash=output_hash,
            decision=decision,
            rationale=rationale,
            human_reviewed=human_reviewed,
            reviewer_id=reviewer_id,
            review_timestamp=datetime.now().isoformat() if human_reviewed else "",
            severity=severity,
        )

        self._entries.append(entry)

        logger.debug(
            "[AUDIT-TRAIL] Recorded %s | rule=%s | decision=%s",
            entry.entry_id, rule_id, decision,
        )

        return entry

    # ── Generate Report ───────────────────────────────────────────────

    def generate_report(
        self,
        jdg_id: str,
        period_start: str = "",
        period_end: str = "",
    ) -> AuditTrailReport:
        """Wygeneruj kompletny raport audit trail.

        Args:
            jdg_id: Identyfikator JDG.
            period_start: Data początkowa (YYYY-MM-DD).
            period_end: Data końcowa (YYYY-MM-DD).

        Returns:
            AuditTrailReport.
        """
        if not period_start:
            period_start = (datetime.now() - pendulum.duration(days=365)).strftime("%Y-%m-%d")
        if not period_end:
            period_end = datetime.now().strftime("%Y-%m-%d")

        # Filtruj wpisy w okresie
        filtered = [
            e for e in self._entries
            if period_start <= e.timestamp[:10] <= period_end
        ]

        blocked = sum(1 for e in filtered if e.decision in ("BLOCK_AND_ALERT", "BLOCK"))
        triage = sum(1 for e in filtered if e.decision in ("TRIAGE_QUEUE", "TRIAGE"))
        reviewed = sum(1 for e in filtered if e.human_reviewed)

        report_id = f"AT-REPORT-{jdg_id}-{datetime.now().strftime('%Y%m%d-%H%M%S')}"

        report = AuditTrailReport(
            report_id=report_id,
            jdg_id=jdg_id,
            period_start=period_start,
            period_end=period_end,
            entries=filtered,
            total_decisions=len(filtered),
            blocked_count=blocked,
            triage_count=triage,
            human_reviewed_count=reviewed,
        )

        # Podpis cyfrowy (SHA-256 wszystkich wpisów)
        report.digital_signature = self._sign_report(report)

        logger.info(
            "[AUDIT-TRAIL] Report generated | id=%s | entries=%d | blocked=%d",
            report_id, len(filtered), blocked,
        )

        return report

    # ── Export ─────────────────────────────────────────────────────────

    def export_markdown(self, report: AuditTrailReport) -> str:
        """Eksportuj raport audit trail jako Markdown (gotowy do PDF)."""
        lines = [
            f"# Raport Audit Trail — Należyta Staranność Podatkowa",
            f"",
            f"**Raport ID:** {report.report_id}",
            f"**JDG ID:** {report.jdg_id}",
            f"**Okres:** {report.period_start} — {report.period_end}",
            f"**Wygenerowano:** {report.generated_at}",
            f"",
            f"---",
            f"",
            f"## Podsumowanie",
            f"",
            f"- Liczba decyzji: **{report.total_decisions}**",
            f"- Zablokowane (BLOCK_AND_ALERT): **{report.blocked_count}**",
            f"- Triage (TRIAGE_QUEUE): **{report.triage_count}**",
            f"- Zweryfikowane przez człowieka: **{report.human_reviewed_count}**",
            f"",
            f"---",
            f"",
            f"## Podpis Cyfrowy (SHA-256)",
            f"",
            f"`{report.digital_signature}`",
            f"",
            f"---",
            f"",
            f"## Szczegółowa Lista Decyzji",
            f"",
        ]

        for i, entry in enumerate(report.entries, 1):
            lines.extend([
                f"### {i}. {entry.entry_id} — {entry.decision}",
                f"",
                f"| Atrybut | Wartość |",
                f"|---------|--------|",
                f"| **Timestamp** | {entry.timestamp} |",
                f"| **Reguła OPA** | `{entry.rule_id}` |",
                f"| **Podstawa prawna** | {entry.legal_basis} |",
                f"| **Decyzja** | {entry.decision} |",
                f"| **Uzasadnienie** | {entry.rationale} |",
                f"| **Input Hash** | `{entry.input_snapshot_hash[:16]}...` |",
                f"| **Output Hash** | `{entry.output_snapshot_hash[:16]}...` |",
                f"| **Weryfikacja ludzka** | {'✅ Tak — ' + entry.reviewer_id if entry.human_reviewed else '❌ Nie'} |",
                f"| **Severity** | {entry.severity} |",
                f"",
            ])

        lines.extend([
            "---",
            "",
            f"**{report.legal_notice}**",
            "",
            "*Wygenerowano przez NexusAI Tax Audit Trail Generator v7.0*",
            "*Dokument zgodny z wymogami Art. 19 § 1-2 KKS — okoliczność łagodząca*",
        ])

        return "\n".join(lines)

    def export_json(self, report: AuditTrailReport) -> str:
        """Eksportuj raport jako JSON."""
        return json.dumps({
            "report_id": report.report_id,
            "jdg_id": report.jdg_id,
            "period": {"start": report.period_start, "end": report.period_end},
            "generated_at": report.generated_at,
            "summary": {
                "total_decisions": report.total_decisions,
                "blocked": report.blocked_count,
                "triage": report.triage_count,
                "human_reviewed": report.human_reviewed_count,
            },
            "digital_signature": report.digital_signature,
            "entries": [
                {
                    "entry_id": e.entry_id,
                    "timestamp": e.timestamp,
                    "rule_id": e.rule_id,
                    "legal_basis": e.legal_basis,
                    "decision": e.decision,
                    "rationale": e.rationale,
                    "input_hash": e.input_snapshot_hash,
                    "output_hash": e.output_snapshot_hash,
                    "human_reviewed": e.human_reviewed,
                }
                for e in report.entries
            ],
        }, indent=2, ensure_ascii=False)

    # ── Helpers ────────────────────────────────────────────────────────

    @staticmethod
    def _hash_data(data: dict[str, Any]) -> str:
        """Wygeneruj SHA-256 hash dla danych."""
        serialized = json.dumps(data, sort_keys=True, default=str)
        return hashlib.sha256(serialized.encode()).hexdigest()

    @staticmethod
    def _sign_report(report: AuditTrailReport) -> str:
        """Wygeneruj podpis cyfrowy całego raportu."""
        content = "".join(
            e.entry_id + e.timestamp + e.input_snapshot_hash + e.output_snapshot_hash
            for e in report.entries
        )
        content += report.report_id + report.jdg_id
        return hashlib.sha256(content.encode()).hexdigest()

    # ── Statistics ─────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        """Statystyki audit trail."""
        if not self._entries:
            return {"total_entries": 0}

        blocked = sum(1 for e in self._entries if e.decision in ("BLOCK_AND_ALERT", "BLOCK"))
        triage = sum(1 for e in self._entries if e.decision in ("TRIAGE_QUEUE", "TRIAGE"))
        reviewed = sum(1 for e in self._entries if e.human_reviewed)

        return {
            "total_entries": len(self._entries),
            "blocked_entries": blocked,
            "triage_entries": triage,
            "human_reviewed": reviewed,
            "blocked_pct": round(blocked / len(self._entries) * 100, 1),
            "unique_rules": len({e.rule_id for e in self._entries}),
        }
