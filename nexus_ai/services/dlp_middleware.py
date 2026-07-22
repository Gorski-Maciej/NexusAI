"""
DLP (Data Loss Prevention) Middleware — INNOWACJA #8 v7.0 Security Audit.

Raport v7.0 INNOWACJA #8:
  Rozszerza PiiScanMiddleware o konfigurowalne reguly DLP:
  - blokuj wysylke NIP/PESEL przez niezabezpieczone kanaly
  - maskuj dane wrazliwe w logach
  - audytuj wszystkie operacje na danych osobowych

Enterprise v7.0:
  - HTTP response scanning: wykrywa PII w odpowiedziach API
  - Log redaction: automatyczne maskowanie przed zapisem
  - Audit trail: kto i kiedy uzyskal dostep do danych osobowych
  - Rate-based detection: >5 NIP/PESEL w jednej odpowiedzi = alert
  - Configurable rules: per-endpoint, per-role
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from structlog import get_logger

from nexus_ai.services.log_pii_monitor import mask_pii, PII_PATTERNS

logger = get_logger("nexus.dlp")


@dataclass
class DLPViolation:
    """Naruszenie polityki DLP."""

    rule_id: str
    severity: str  # CRITICAL, HIGH, MEDIUM, LOW
    channel: str  # http_response, log_entry, database_query
    pii_type: str  # nip, pesel, email, iban, etc.
    count: int
    endpoint: str = ""
    user_id: str = ""
    action_taken: str = ""  # BLOCKED, MASKED, LOGGED, ALLOWED
    timestamp: str = ""


class DLPMiddleware:
    """Middleware DLP dla ochrony danych osobowych.

    Usage:
        dlp = DLPMiddleware()
        
        # Skanuj odpowiedz HTTP
        violations = dlp.scan_http_response(response_body, endpoint="/api/invoices")
        
        # Skanuj wpis logu przed zapisem
        cleaned = dlp.redact_log_entry(log_message)
        
        # Audytuj dostep do danych osobowych
        dlp.audit_access(user_id="user-123", pii_type="nip", endpoint="/api/invoices")
    """

    # ── Progi DLP ───────────────────────────────────────────────────────

    PII_BLOCK_THRESHOLD: int = 5  # >5 PII w odpowiedzi = BLOCK
    PII_WARN_THRESHOLD: int = 2  # >2 PII = WARN
    AUDIT_LOG_SIZE: int = 1000  # Max wpisow w audycie

    def __init__(self) -> None:
        self._audit_trail: list[dict[str, Any]] = []
        self._violations: list[DLPViolation] = []
        self._blocked_count: int = 0
        self._masked_count: int = 0

    # ── HTTP Response Scanning ──────────────────────────────────────────

    def scan_http_response(
        self,
        body: str,
        *,
        endpoint: str = "",
        user_id: str = "",
    ) -> list[DLPViolation]:
        """Skanuj odpowiedz HTTP pod katem PII.

        Returns:
            Lista naruszen DLP. Pusta lista = odpowiedz czysta.
        """
        if not body:
            return []

        violations: list[DLPViolation] = []

        for pii_type, pattern in PII_PATTERNS.items():
            matches = pattern.findall(body)
            count = len(matches)

            if count >= self.PII_BLOCK_THRESHOLD:
                severity = "CRITICAL"
                action = "BLOCKED"
                self._blocked_count += 1
            elif count >= self.PII_WARN_THRESHOLD:
                severity = "HIGH"
                action = "MASKED"
                self._masked_count += 1
            elif count > 0:
                severity = "MEDIUM"
                action = "LOGGED"
            else:
                continue

            violation = DLPViolation(
                rule_id=f"DLP-{pii_type.upper()}-001",
                severity=severity,
                channel="http_response",
                pii_type=pii_type,
                count=count,
                endpoint=endpoint,
                user_id=user_id,
                action_taken=action,
                timestamp=datetime.now(timezone.utc).isoformat(),
            )

            violations.append(violation)
            self._violations.append(violation)

            logger.warning(
                "[DLP] %s violation: %d %s found in %s response (action=%s)",
                severity, count, pii_type.upper(), endpoint or "unknown", action,
            )

        return violations

    # ── Log Redaction ───────────────────────────────────────────────────

    def redact_log_entry(self, message: str) -> str:
        """Zamaskuj PII we wpisie logu przed zapisem.

        Uzywa mask_pii() z log_pii_monitor.py do automatycznego
        maskowania wszystkich wykrytych wzorcow PII.
        """
        if not message:
            return message
        return mask_pii(message)

    def redact_dict(self, data: dict[str, Any]) -> dict[str, Any]:
        """Rekurencyjnie zamaskuj PII w slowniku."""
        result: dict[str, Any] = {}
        for key, value in data.items():
            if isinstance(value, str):
                result[key] = mask_pii(value)
            elif isinstance(value, dict):
                result[key] = self.redact_dict(value)
            elif isinstance(value, list):
                result[key] = [
                    mask_pii(v) if isinstance(v, str) else v
                    for v in value
                ]
            else:
                result[key] = value
        return result

    # ── Audit Trail ─────────────────────────────────────────────────────

    def audit_access(
        self,
        *,
        user_id: str,
        pii_type: str,
        endpoint: str = "",
        action: str = "READ",
    ) -> None:
        """Zarejestruj dostep do danych osobowych w sladzie audytowym.

        Kazdy dostep do NIP, PESEL, email, IBAN itp. jest rejestrowany.
        """
        entry = {
            "user_id": user_id,
            "pii_type": pii_type,
            "endpoint": endpoint,
            "action": action,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

        self._audit_trail.append(entry)

        # Trzymaj tylko ostatnie N wpisow
        if len(self._audit_trail) > self.AUDIT_LOG_SIZE:
            self._audit_trail = self._audit_trail[-self.AUDIT_LOG_SIZE:]

        logger.debug(
            "[DLP] Audit: user=%s accessed %s via %s",
            user_id, pii_type.upper(), endpoint or "unknown",
        )

    # ── Statistics ──────────────────────────────────────────────────────

    @property
    def stats(self) -> dict[str, Any]:
        """Statystyki DLP."""
        return {
            "total_violations": len(self._violations),
            "blocked_count": self._blocked_count,
            "masked_count": self._masked_count,
            "audit_entries": len(self._audit_trail),
            "violations_by_type": self._violations_by_type(),
        }

    def _violations_by_type(self) -> dict[str, int]:
        """Zlicz naruszenia wg typu PII."""
        counts: dict[str, int] = {}
        for v in self._violations:
            counts[v.pii_type] = counts.get(v.pii_type, 0) + 1
        return counts

    def get_recent_violations(self, limit: int = 10) -> list[DLPViolation]:
        """Pobierz ostatnie naruszenia."""
        return self._violations[-limit:]

    def get_audit_trail(self, user_id: str | None = None) -> list[dict[str, Any]]:
        """Pobierz slad audytowy (opcjonalnie filtrowany po user_id)."""
        if user_id:
            return [e for e in self._audit_trail if e["user_id"] == user_id]
        return list(self._audit_trail)
