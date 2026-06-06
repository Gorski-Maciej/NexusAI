from __future__ import annotations

import re
from pathlib import Path
from urllib import request

from core.msgspec_utils import msgspec_dumps_bytes

PII_PATTERNS: dict[str, re.Pattern[str]] = {
    "pesel": re.compile(r"\b\d{11}\b"),
    "nip": re.compile(r"\b\d{10}\b"),
    "iban_pl": re.compile(r"\bPL\d{26}\b"),
    "email": re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"),
}


def scan_logs_for_pii(log_dir: Path, max_files: int = 200) -> dict[str, int]:
    findings: dict[str, int] = {name: 0 for name in PII_PATTERNS}
    if not log_dir.exists():
        return findings

    files = sorted(log_dir.glob("**/*.log"), key=lambda p: p.stat().st_mtime, reverse=True)[:max_files]
    for file_path in files:
        try:
            content = file_path.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        for name, pattern in PII_PATTERNS.items():
            findings[name] += len(pattern.findall(content))
    return findings


def notify_dpo(webhook_url: str, findings: dict[str, int], retries: int = 3) -> bool:
    if not webhook_url:
        return False
    payload = msgspec_dumps_bytes({"event": "pii_scan_alert", "findings": findings})
    for _ in range(max(retries, 1)):
        req = request.Request(webhook_url, data=payload, headers={"Content-Type": "application/json"}, method="POST")
        try:
            with request.urlopen(req, timeout=5) as response:
                if 200 <= response.status < 300:
                    return True
        except Exception:
            continue
    return False
