# Security automation (DAST + SAST)

This repository includes a helper script to automate baseline security checks recommended by KORE:

- OWASP ZAP baseline/active scan against staging API
- Semgrep static analysis for `Code/`

## Run

```bash
python Code/scripts/security_scan.py --target http://localhost:8000 --mode baseline
python Code/scripts/security_scan.py --target http://staging.example --mode full
```

Reports are written to `reports/`.

## Daily PII scan

```bash
python Code/scripts/pii_scan_runner.py --log-path app_data/logs/app.log --report-dir reports/pii
```

Exit code `1` indicates potential leak findings.

## OTEL buffer replay

```bash
python Code/scripts/otel_buffer_replayer.py --endpoint http://localhost:4318/v1/traces
```

## Outbox targeted replay

```bash
python Code/scripts/outbox_dead_letter_replayer.py --db nexus_oltp.db --ids-file /tmp/outbox_ids.txt --status-to FAILED --dry-run
```

For SAST-only emergency run:

```bash
python Code/scripts/security_scan.py --target http://localhost:8000 --skip-zap
```
