"""Scan logs for potential PII leaks and emit findings."""
from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

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


def scan_text(text: str) -> list[Finding]:
    findings: list[Finding] = []
    lines = text.splitlines()
    for idx, line in enumerate(lines, start=1):
        for name, regex in PII_PATTERNS.items():
            if re.search(regex, line):
                findings.append(Finding(pattern=name, line_no=idx, line=line.strip()))
    return findings


def scan_file(path: Path) -> list[Finding]:
    return scan_text(path.read_text(encoding='utf-8', errors='ignore'))


def main() -> int:
    parser = argparse.ArgumentParser(description='Scan log files for possible PII leaks.')
    parser.add_argument('--path', required=True, help='Path to log file')
    parser.add_argument('--redact-output', help='Optional output path for redacted log copy')
    args = parser.parse_args()

    log_path = Path(args.path)
    findings = scan_file(log_path)
    if not findings:
        print('[pii-scan] OK - no findings')
        return 0

    print(f'[pii-scan] ALERT - {len(findings)} finding(s)')
    for f in findings:
        print(f'- [{f.pattern}] line {f.line_no}: {f.line}')

    if args.redact_output:
        redacted = log_path.read_text(encoding='utf-8', errors='ignore')
        for regex in PII_PATTERNS.values():
            redacted = re.sub(regex, '[REDACTED]', redacted)
        Path(args.redact_output).write_text(redacted, encoding='utf-8')
        print(f'[pii-scan] redacted copy written to {args.redact_output}')
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
