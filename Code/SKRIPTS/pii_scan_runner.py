"""Daily log PII scanning entrypoint with report rotation."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
from pathlib import Path

from log_pii_scanner import scan_file


def main() -> int:
    parser = argparse.ArgumentParser(description='Run daily PII scan and write report.')
    parser.add_argument('--log-path', required=True)
    parser.add_argument('--report-dir', default='reports/pii')
    args = parser.parse_args()

    log_path = Path(args.log_path)
    report_dir = Path(args.report_dir)
    report_dir.mkdir(parents=True, exist_ok=True)

    findings = scan_file(log_path)
    ts = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    report = report_dir / f'pii_scan_{ts}.txt'

    if findings:
        lines = [f'ALERT findings={len(findings)}']
        lines.extend([f'{f.pattern} line={f.line_no} :: {f.line}' for f in findings])
        report.write_text('\n'.join(lines), encoding='utf-8')
        print(report)
        return 1

    report.write_text('OK no findings', encoding='utf-8')
    print(report)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
