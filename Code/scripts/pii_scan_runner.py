"""Daily log PII scanning entrypoint with report rotation and JSON artifacts."""
from __future__ import annotations

import argparse
from datetime import UTC, datetime
from pathlib import Path

from log_pii_scanner import scan_path

from core.msgspec_utils import msgspec_dumps


def main() -> int:
    parser = argparse.ArgumentParser(description='Run daily PII scan and write report.')
    parser.add_argument('--log-path', required=True)
    parser.add_argument('--report-dir', default='reports/pii')
    args = parser.parse_args()

    target = Path(args.log_path)
    report_dir = Path(args.report_dir)
    report_dir.mkdir(parents=True, exist_ok=True)

    scan_results = scan_path(target)
    finding_count = sum(len(items) for items in scan_results.values())

    ts = datetime.now(UTC).strftime('%Y%m%dT%H%M%SZ')
    text_report = report_dir / f'pii_scan_{ts}.txt'
    json_report = report_dir / f'pii_scan_{ts}.json'

    if finding_count:
        lines = [f'ALERT findings={finding_count}']
        serializable: dict[str, list[dict[str, str | int]]] = {}
        for file_name, findings in scan_results.items():
            if not findings:
                continue
            lines.append(f'file={file_name}')
            serializable[file_name] = []
            for f in findings:
                lines.append(f'{f.pattern} line={f.line_no} :: {f.line}')
                serializable[file_name].append({'pattern': f.pattern, 'line_no': f.line_no, 'line': f.line})

        text_report.write_text('\n'.join(lines), encoding='utf-8')
        json_report.write_text(msgspec_dumps({'findings': finding_count, 'files': serializable}, ensure_ascii=False, indent=2), encoding='utf-8')
        print(text_report)
        print(json_report)
        return 1

    text_report.write_text('OK no findings', encoding='utf-8')
    json_report.write_text(msgspec_dumps({'findings': 0, 'files': {}}, ensure_ascii=False, indent=2), encoding='utf-8')
    print(text_report)
    print(json_report)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
