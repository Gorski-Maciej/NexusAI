"""
log_pii_monitor.py — PII Detection & Masking for NexusAI logs.

Enterprise v7.0 Rec #8: Maskowanie NIP/email/PESEL w logach (RODO compliance).

Features:
  - PII_MASK_PATTERNS: regex-based masking for NIP, PESEL, email, IBAN, REGON, phone
  - mask_pii(): inline masking for any string (use in structlog processors)
  - scan_logs_for_pii(): post-factum scanning of log files
  - PiiMaskingProcessor: structlog processor for automatic log masking
  - notify_dpo(): webhook notification for PII scan alerts
"""

from __future__ import annotations

import os
import re
from pathlib import Path
from urllib import request

from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps_bytes

logger = get_logger("nexus.pii_monitor")

# ── PII Detection Patterns ───────────────────────────────────────────────────

PII_PATTERNS: dict[str, re.Pattern[str]] = {
    "pesel": re.compile(r"\b\d{11}\b"),
    "nip": re.compile(r"\b\d{10}\b"),
    "iban_pl": re.compile(r"\bPL\d{26}\b"),
    "email": re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
    "regon": re.compile(r"\b\d{9}\b"),
    "phone": re.compile(r"\b(?:\+48[\s-]?)?\d{3}[\s-]?\d{3}[\s-]?\d{3}\b"),
    "bank_account": re.compile(r"\b\d{2}[\s]?\d{4}[\s]?\d{4}[\s]?\d{4}[\s]?\d{4}[\s]?\d{4}[\s]?\d{4}\b"),
}

# ── PII Masking Rules (Rec #8 v7.0: Enterprise) ─────────────────────────────

PII_MASK_MAP: dict[str, tuple[re.Pattern[str], str]] = {
    "nip": (re.compile(r"\b(\d{3})(\d{7})\b"), r"\1*******"),
    "pesel": (re.compile(r"\b(\d{2})(\d{9})\b"), r"\1*********"),
    "email": (re.compile(r"\b([A-Za-z0-9._%+-]{1,3})[A-Za-z0-9._%+-]*@([A-Za-z0-9.-]+\.[A-Za-z]{2,})\b"), r"\1***@\2"),
    "iban_pl": (re.compile(r"\bPL(\d{2})\d{24}\b"), r"PL\1************************"),
    "regon": (re.compile(r"\b(\d{2})(\d{7})\b"), r"\1*******"),
    "phone": (re.compile(r"\b(\+48[\s-]?)?(\d{3})[\s-]?\d{3}[\s-]?\d{3}\b"), r"\1\2***"),
}

# Maximum length of strings to scan (avoid scanning huge payloads)
PII_MAX_SCAN_LENGTH: int = int(os.getenv("PII_MAX_SCAN_LENGTH", "100000"))


def mask_pii(text: str) -> str:
    """Mask all PII in a string. Safe for any text (logs, events, messages).

    Enterprise v7.0 Rec #8: Maskuje NIP, PESEL, email, IBAN, REGON, telefon
    przed zapisem do logów — RODO Art. 32 compliance.

    Args:
        text: Raw text that may contain PII.

    Returns:
        Text with all detected PII masked (e.g., "527*******@gmail.com").
    """
    if not text or not isinstance(text, str):
        return text
    if len(text) > PII_MAX_SCAN_LENGTH:
        return text[:PII_MAX_SCAN_LENGTH] + "...[TRUNCATED]"

    result = text
    for name, (pattern, replacement) in PII_MASK_MAP.items():
        try:
            result = pattern.sub(replacement, result)
        except Exception:
            logger.debug("[PII Mask] failed to apply mask for %s", name)
    return result


# ── Structlog Processor (Rec #8 v7.0) ────────────────────────────────────────


class PiiMaskingProcessor:
    """Structlog processor that masks PII before log entries are emitted.

    Enterprise v7.0 Rec #8: Automatyczne maskowanie NIP/email w logach.
    Integruje się z łańcuchem processorów structlog.

    Usage:
        structlog.configure(
            processors=[
                PiiMaskingProcessor(),
                structlog.processors.JSONRenderer(),
            ]
        )
    """

    def __call__(self, logger_instance, method_name: str, event_dict: dict) -> dict:
        """Process a log event dict, masking any PII in values."""
        masked: dict = {}
        for key, value in event_dict.items():
            if isinstance(value, str):
                masked[key] = mask_pii(value)
            elif isinstance(value, dict):
                masked[key] = {
                    k: mask_pii(v) if isinstance(v, str) else v
                    for k, v in value.items()
                }
            elif isinstance(value, (list, tuple)):
                masked[key] = [
                    mask_pii(v) if isinstance(v, str) else v
                    for v in value
                ]
            else:
                masked[key] = value
        return masked


# ── Post-factum Log Scanning ─────────────────────────────────────────────────


def scan_logs_for_pii(log_dir: Path, max_files: int = 200) -> dict[str, int]:
    """Scan log files for PII patterns (post-factum audit).

    Args:
        log_dir: Directory containing log files.
        max_files: Max number of recent log files to scan.

    Returns:
        Dict mapping PII type to count of occurrences found.
    """
    findings: dict[str, int] = {name: 0 for name in PII_PATTERNS}
    if not log_dir.exists():
        return findings

    files = sorted(log_dir.glob("**/*.log"), key=lambda p: p.stat().st_mtime, reverse=True)[
        :max_files
    ]
    for file_path in files:
        try:
            content = file_path.read_text(encoding="utf-8", errors="ignore")
        except Exception as exc:
            logger.debug("[PII Monitor] failed to read log file %s: %s", file_path, exc)
            continue
        for name, pattern in PII_PATTERNS.items():
            findings[name] += len(pattern.findall(content))
    return findings


def notify_dpo(webhook_url: str, findings: dict[str, int], retries: int = 3) -> bool:
    """Notify Data Protection Officer about PII scan results via webhook.

    Args:
        webhook_url: Webhook URL for DPO notifications.
        findings: Dictionary of PII type → count.
        retries: Number of retry attempts.

    Returns:
        True if notification was delivered successfully.
    """
    if not webhook_url:
        return False
    payload = msgspec_dumps_bytes({"event": "pii_scan_alert", "findings": findings})
    for _ in range(max(retries, 1)):
        req = request.Request(
            webhook_url, data=payload, headers={"Content-Type": "application/json"}, method="POST"
        )
        try:
            with request.urlopen(req, timeout=5) as response:
                if 200 <= response.status < 300:
                    return True
        except Exception as exc:
            logger.debug("[PII Monitor] webhook attempt failed: %s", exc)
            continue
    return False
