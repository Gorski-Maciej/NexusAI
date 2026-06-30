# Security automation (DAST + SAST)

This repository automates baseline security checks recommended by KORE:

- OWASP ZAP baseline/active scan against staging API
- Semgrep static analysis for `nexus_ai/`
- Ruff S rules for Python security scanning

## Run

```bash
ruff check nexus_ai/ --select S                          # Python security scan
pixi run --environment dev security-scan                   # Ruff S rules (lenient)
pixi run --environment dev security-scan-strict            # Ruff S rules (strict)
```

Reports are written to `reports/`.

For SAST-only emergency run:

```bash
ruff check nexus_ai/ --select S --no-fix
```
