# Performance smoke/load tests (k6)

This folder provides a production-like **load profile** for the invoice upload path.

## Run locally

```bash
k6 run tests/performance/k6_invoice_upload.js \
  -e BASE_URL=http://localhost:8000 \
  -e TOKEN=<jwt> \
  -e VUS=50 \
  -e DURATION=5m
```

## Recommended SLOs
- p95 upload latency < 1200 ms
- error rate < 2%

## Notes
- This test intentionally targets `/api/v2/invoices/upload` because it exercises streamed upload, idempotency, outbox write, and audit trail.
- For CI, run against staging after deploy and archive result artifacts (`--summary-export`).

## CI gate with thresholds

```bash
python Code/scripts/performance_engineering.py \
  --base-url http://localhost:8000 \
  --token <jwt> \
  --vus 50 \
  --duration 5m
```

The runner exports `reports/performance/k6_summary.json` and fails when p95 or error-rate thresholds are breached.
