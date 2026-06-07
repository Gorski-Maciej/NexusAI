"""Scan logs for potential PII leaks and optionally create redacted copies/reports."""
from __future__ import annotations

import argparse
import re
from dataclasses import asdict, dataclass
from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_dumps

PII_PATTERNS: dict[str, str] = {
    "PESEL": r"\b\d{11}\b",
    "NIP": r"\b\d{3}[- ]?\d{3}[- ]?\d{2}[- ]?\d{2}\b",
    "REGON": r"\b\d{9}(\d{5})?\b",
    "IBAN_PL": r"\bPL\d{26}\b",
}


@dataclass(frozen=True)
class Finding:
    pattern: str
    line_no: int
    line: str


def _normalize_digits(value: str) -> str:
    return "".join(ch for ch in value if ch.isdigit())


def _is_valid_pesel(value: str) -> bool:
    digits = _normalize_digits(value)
    if len(digits) != 11:
        return False
    weights = [1, 3, 7, 9, 1, 3, 7, 9, 1, 3]
    checksum = sum(int(d) * w for d, w in zip(digits[:10], weights, strict=True))
    control = (10 - (checksum % 10)) % 10
    return control == int(digits[10])


def _is_valid_nip(value: str) -> bool:
    digits = _normalize_digits(value)
    if len(digits) != 10:
        return False
    weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]
    checksum = sum(int(d) * w for d, w in zip(digits[:9], weights, strict=True)) % 11
    return checksum != 10 and checksum == int(digits[9])


def _match_is_valid(pattern: str, matched_value: str) -> bool:
    if pattern == "PESEL":
        return _is_valid_pesel(matched_value)
    if pattern == "NIP":
        return _is_valid_nip(matched_value)
    return True


def scan_text(text: str) -> list[Finding]:
    findings: list[Finding] = []
    lines = text.splitlines()
    for idx, line in enumerate(lines, start=1):
        for name, regex in PII_PATTERNS.items():
            for match in re.finditer(regex, line):
                matched = match.group(0)
                if _match_is_valid(name, matched):
                    findings.append(Finding(pattern=name, line_no=idx, line=line.strip()))
    return findings


def scan_file(path: Path) -> list[Finding]:
    return scan_text(path.read_text(encoding="utf-8", errors="ignore"))


def scan_path(path: Path) -> dict[str, list[Finding]]:
    if path.is_file():
        return {str(path): scan_file(path)}
    if not path.exists():
        return {}

    result: dict[str, list[Finding]] = {}
    for file_path in sorted(p for p in path.rglob("*") if p.is_file()):
        if file_path.suffix.lower() in {".log", ".txt", ".json", ".ndjson"}:
            result[str(file_path)] = scan_file(file_path)
    return result


def _redact_text(text: str) -> str:
    redacted = text
    for regex in PII_PATTERNS.values():
        redacted = re.sub(regex, "[REDACTED]", redacted)
    return redacted


def main() -> int:
    parser = argparse.ArgumentParser(description="Scan log files for possible PII leaks.")
    parser.add_argument("--path", required=True, help="Path to log file or directory")
    parser.add_argument("--redact-output", help="Optional output path for redacted log copy")
    parser.add_argument("--json-report", help="Optional JSON report path")
    args = parser.parse_args()

    target = Path(args.path)
    scans = scan_path(target)
    total_findings = sum(len(items) for items in scans.values())

    if total_findings == 0:
        print("[pii-scan] OK - no findings")
        if args.json_report:
            Path(args.json_report).write_text(msgspec_dumps({"total_findings": 0, "files": {}}, ensure_ascii=False, indent=2), encoding="utf-8")
        return 0

    print(f"[pii-scan] ALERT - {total_findings} finding(s)")
    for file_name, findings in scans.items():
        if not findings:
            continue
        print(f"# file={file_name}")
        for f in findings:
            print(f"- [{f.pattern}] line {f.line_no}: {f.line}")

    if args.redact_output and target.is_file():
        redacted = _redact_text(target.read_text(encoding="utf-8", errors="ignore"))
        Path(args.redact_output).write_text(redacted, encoding="utf-8")
        print(f"[pii-scan] redacted copy written to {args.redact_output}")

    if args.json_report:
        payload = {
            "total_findings": total_findings,
            "files": {
                file_name: [asdict(item) for item in findings]
                for file_name, findings in scans.items()
                if findings
            },
        }
        Path(args.json_report).write_text(msgspec_dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
