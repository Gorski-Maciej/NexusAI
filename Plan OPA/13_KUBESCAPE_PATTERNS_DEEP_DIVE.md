# Kubescape/Regolibrary Patterns Deep Dive dla NexusAI

> **Status:** Dokumentacja ENTERPRISE v1.0
> **Data:** 2026-07-07
> **Powiązany:** `10_OPA_IMPLEMENTATION_GUIDE.md`, `08_OPA_PATTERNS_FROM_RESEARCH.md`
> **Źródło:** kubescape/regolibrary — analiza struktury 100+ reguł Rego

---

## 1. Hierarchia Rule → Control → Framework

Kubescape używa trójwarstwowej architektury, którą NexusAI może zaadaptować dla reguł podatkowych:

| Warstwa | Kubescape | NexusAI (adaptacja) |
|---|---|---|
| **Rule** | Pojedyncza reguła Rego (`raw.rego` + `rule.metadata.json`) | Pojedyncza reguła podatkowa (`P0-P290` w `policies/tax/*.rego`) |
| **Control** | Grupa reguł spełniająca wymóg bezpieczeństwa | Grupa reguł spełniająca wymóg prawny (np. `VAT_COMPLIANCE` = P20+P21+P25+P28) |
| **Framework** | Kolekcja controls (CIS, NSA) | Kolekcja obszarów prawnych (np. `FULL_VAT` = wszystkie 50+ reguł VAT) |

### Struktura wdrożeniowa dla NexusAI

```
policies/
├── tax/
│   ├── rules/           # Atomic rules (P0-P290)
│   ├── controls/        # Legal requirement groupings
│   │   ├── vat_compliance.json
│   │   ├── cit_deductions.json
│   │   └── crossborder_rules.json
│   └── frameworks/      # Full compliance frameworks
│       ├── full_vat_compliance.json
│       ├── full_cit_compliance.json
│       └── jpk_ksef_framework.json
```

### Przykład Control definition

```json
{
  "controlID": "CTRL-VAT-001",
  "name": "VAT Compliance - Full",
  "description": "Pełna zgodność VAT: Biała Lista, MPP, KSeF, stawki, GTU",
  "rulesNames": [
    "tax.compliance.whitelist_missing",
    "tax.compliance.split_payment_mandatory",
    "tax.compliance.ksef_structured_invoice",
    "tax.vat.substantive.vat_rate_fuel_pl",
    "tax.vat.gtu.gtu_mapping_by_category"
  ],
  "scanningScope": "invoice",
  "remediation": "Zweryfikuj fakturę pod kątem zgodności z przepisami VAT",
  "severity": "CRITICAL"
}
```

---

## 2. Test Framework Pattern

Kubescape używa katalogów `test/success/`, `test/failed_1/`, `test/failed_2/` z plikami `input` i `expected.json`. Adaptacja dla NexusAI:

### Struktura testów

```
policies/tests/
├── vat/
│   ├── fuel_pl_23/
│   │   ├── success/
│   │   │   └── input.json       # Poprawna faktura paliwowa PL
│   │   ├── failed_eu/
│   │   │   └── input.json       # Faktura paliwowa z EU (powinno być reverse charge)
│   │   └── failed_no_threshold/
│   │       └── input.json       # Brak thresholds (powinno fail graceful)
│   └── compliance/
│       ├── whitelist_missing/
│       │   ├── success/
│       │   │   └── input.json
│       │   └── failed_below_limit/
│       │       └── input.json
│       └── split_payment/
│           ├── success/
│           │   └── input.json
│           └── failed_not_sensitive/
│               └── input.json
```

### Wzorzec testu Rego

```rego
package tax.vat.substantive.test

import data.tax.vat.substantive

# ── Fixtures loaded from JSON files ──────────────────────────
test_fuel_pl_success {
    result := substantive.decide with input as data.tests.vat.fuel_pl_23.success.input
    result.matched == true
    result.vat_rate == "0.23"
    result.gtu_code == "GTU_04"
}

test_fuel_eu_reverse_charge {
    result := substantive.decide with input as data.tests.vat.fuel_pl_23.failed_eu.input
    result.vat_rate != "0.23"
}

test_fuel_missing_threshold_graceful {
    result := substantive.decide with input as data.tests.vat.fuel_pl_23.failed_no_threshold.input
    not result.matched
}
```

### Skrypt inicjalizacji nowej reguły (wzorzec z kubescape `init-rule.py`)

```bash
#!/bin/bash
# scripts/init-tax-rule.sh
# Generuje strukturę katalogów dla nowej reguły podatkowej

RULE_ID=$1
PACKAGE=$2

mkdir -p "policies/tests/${PACKAGE}/${RULE_ID}/success"
mkdir -p "policies/tests/${PACKAGE}/${RULE_ID}/failed_1"
mkdir -p "policies/tests/${PACKAGE}/${RULE_ID}/failed_2"

echo '{"invoice": {}, "vendor": {}, "company": {}, "thresholds": {}}' \
  > "policies/tests/${PACKAGE}/${RULE_ID}/success/input.json"

echo "Test scaffold created for rule: ${RULE_ID}"
```

---

## 3. Rule Metadata Schema (JSON)

Kubescape używa `rule.metadata.json` dla każdej reguły. Adaptacja dla NexusAI:

```json
{
  "ruleID": "tax.compliance.whitelist_missing",
  "name": "Biała Lista - kontrahent nie figuruje",
  "description": "Weryfikacja czy kontrahent figuruje na Białej Liście MF dla przelewów >15 000 PLN",
  "severity": "CRITICAL",
  "category": "VAT_COMPLIANCE",
  "framework": ["WHITE_LIST", "VAT"],
  "match": {
    "taxForms": ["CIT_STANDARD", "CIT_ESTONIAN", "LINEAR", "PIT_SCALE", "LUMP_SUM"],
    "vendorCountries": ["PL"],
    "minAmountGross": 15000
  },
  "controlConfigInputs": {
    "whitelist_check_cache_ttl": {
      "type": "integer",
      "default": 3600,
      "description": "Cache TTL for White List API calls (seconds)"
    }
  },
  "ruleDependencies": [
    "data.tax.helpers.gte_limit",
    "data.tax.helpers.is_valid_period"
  ],
  "remediation": "Sprawdź kontrahenta na Białej Liście MF. Jeśli brak — rozważ zgłoszenie do KAS.",
  "references": [
    "Art. 96b ustawy o VAT",
    "Art. 117ba Ordynacji podatkowej"
  ],
  "ruleQuery": "data.tax.compliance.decide",
  "version": "1.2.0",
  "lastUpdated": "2026-07-07",
  "validFrom": "2024-01-01",
  "validTo": null
}
```

### Metadane w Rego (alternatywa dla JSON)

```rego
# _metadata.rego — metadane inkorporowane w kodzie
# Wzorzec z kubescape: metadata jako reguły Rego
package tax.metadata

rule_metadata[rule_id] = {
    "severity": severity,
    "category": category,
    "remediation": remediation,
    "references": references,
    "version": version,
    "last_updated": last_updated
} {
    some rule_id, severity, category, remediation, references, version, last_updated
    metadata_rows := [
        ["tax.risk.fraud_graph_match", "CRITICAL", "FRAUD", "Zgłoś do KAS", ["Art. 86 VAT", "Art. 55 KKS"], "1.2.0", "2026-07-07"],
        ["tax.compliance.whitelist_missing", "HIGH", "COMPLIANCE", "Sprawdź Białą Listę MF", ["Art. 96b VAT", "Art. 117ba Ord."], "1.0.0", "2026-06-15"],
        ["tax.vat.substantive.fuel_pl_23", "INFO", "VAT_RATE", "Stosuj stawkę 23%", ["Art. 41 ust. 1 VAT"], "1.0.0", "2026-01-01"],
    ]
    [rule_id, severity, category, remediation, references, version, last_updated] := metadata_rows[_]
}
```

---

## 4. CI Pipeline dla reguł

Wzorzec z kubescape zaadaptowany dla NexusAI:

```yaml
# .github/workflows/opa-policies-ci.yml
name: OPA Policies CI

on:
  push:
    paths:
      - 'policies/**'
      - 'nexus_ai/tax/rules.rego'
  pull_request:
    paths:
      - 'policies/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: open-policy-agent/setup-opa@v1
        with:
          version: 0.60.0

      # 1. Syntax check (wszystkie pliki Rego)
      - name: OPA Check
        run: |
          opa check policies/tax/ --strict
          opa check nexus_ai/tax/rules.rego --strict

      # 2. Unit tests
      - name: OPA Test
        run: opa test policies/ -v --count=100

      # 3. Test coverage
      - name: OPA Coverage
        run: opa test policies/ --coverage | tee coverage.json

      # 4. Bundle build
      - name: OPA Build
        run: |
          opa build --bundle policies/tax/ --output nexusai-tax-policies.tar.gz
          opa build --bundle policies/compliance/ --output nexusai-compliance.tar.gz

      # 5. Metadata validation (wszystkie reguły mają metadane)
      - name: Metadata Check
        run: |
          opa eval --data policies/tax/_metadata.rego \
            'data.tax.metadata.rule_metadata' --format pretty

      # 6. Rule cross-reference validation
      - name: Cross-Reference Check
        run: |
          opa eval --data policies/tax/_metadata.rego \
            'count(data.tax.metadata.rule_metadata) >= 10' \
            --format pretty
```

---

## 5. Bundle Creation Pattern (bundle.py)

Kubescape używa `scripts/bundle.py` do agregacji reguł. Adaptacja dla NexusAI:

```python
#!/usr/bin/env python3
"""scripts/bundle.py — Build OPA bundles for NexusAI tax policies.

Inspired by kubescape/regolibrary/scripts/bundle.py
"""

import json
import subprocess
import sys
from pathlib import Path
from pathlib import Path
from datetime import UTC, datetime


def collect_bundle_metadata(policies_dir: Path) -> dict:
    """Collect metadata from all rule files."""
    rules = []
    for rego_file in policies_dir.rglob("*.rego"):
        if rego_file.name.startswith("_"):
            continue  # Skip helpers/metadata
        rules.append({
            "file": str(rego_file.relative_to(policies_dir)),
            "package": extract_package(rego_file),
            "size": rego_file.stat().st_size,
        })
    return {
        "rules": rules,
        "count": len(rules),
        "built_at": datetime.now(UTC).isoformat(),
        "revision": get_git_revision(),
    }


def extract_package(rego_file: Path) -> str:
    """Extract package name from Rego file."""
    content = rego_file.read_text()
    for line in content.splitlines():
        if line.strip().startswith("package "):
            return line.strip().split()[1]
    return "unknown"


def get_git_revision() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"],
            text=True,
        ).strip()
    except Exception:
        return "dev"


def build_bundles(policies_dir: str = "policies", output_dir: str = "dist"):
    root = Path(policies_dir)
    dist = Path(output_dir)
    dist.mkdir(exist_ok=True)

    # Collect metadata
    metadata = collect_bundle_metadata(root)
    meta_path = dist / "bundle-metadata.json"
    meta_path.write_text(json.dumps(metadata, indent=2, ensure_ascii=False))

    # Build bundles per framework
    frameworks = [
        ("vat", ["tax/vat/", "tax/compliance.rego", "tax/crossborder.rego"]),
        ("direct", ["tax/direct/", "tax/allowances.rego"]),
        ("accounting", ["tax/accounting/", "tax/zus.rego"]),
        ("risk", ["tax/risk.rego", "tax/routing.rego"]),
    ]

    for name, paths in frameworks:
        cmd = ["opa", "build"]
        for path in paths:
            cmd.extend(["--bundle", f"{root}/{path}"])
        cmd.extend(["--output", f"{dist}/nexusai-{name}.tar.gz"])
        subprocess.run(cmd, check=True)
        print(f"Built: {dist}/nexusai-{name}.tar.gz")

    print(f"Total rules: {metadata['count']}")


if __name__ == "__main__":
    build_bundles(*sys.argv[1:3] if len(sys.argv) > 2 else ("policies", "dist"))
```

---

## 6. Rule Lifecycle Management

Wzorzec z kubescape (`useFromKubescapeVersion` / `useUntilKubescapeVersion`):

```json
{
  "ruleID": "tax.vat.substantive.fuel_pl_23",
  "ruleLifecycle": {
    "useFromVersion": "2024-01-01",
    "useUntilVersion": null,
    "deprecationNotice": null,
    "replacedBy": null,
    "validFromKSeF": "2026-02-01"
  }
}
```

### Implementacja w Rego

```rego
package tax.vat.substantive

# Temporalna walidacja reguły
# Wzorzec: kubescape version gating
rule_active {
    input.invoice.transaction_date >= "2024-01-01"
    not input.invoice.transaction_date >= "2030-01-01"  # brak daty końcowej
}
```

---

## 7. Rekomendacje dla NexusAI

| Wzorzec kubescape | Adaptacja NexusAI | Priorytet |
|---|---|---|
| Rule → Control → Framework | Reguła → Wymóg prawny → Obszar Compliance | Wysoki |
| `rule.metadata.json` | `_metadata.rego` z inkorporowanymi danymi | Wysoki |
| `init-rule.py` scaffolding | `scripts/init-tax-rule.sh` | Średni |
| `test/success/`, `test/failed_1/` | Katalogi testów per reguła | Wysoki |
| `bundle.py` aggregate | `scripts/bundle.py` z podziałem na frameworki | Wysoki |
| `controlConfigInputs` | `input.thresholds.*` (już zaimplementowane) | ✅ Zrobione |
| `ruleDependencies` | `import data.tax.helpers` (już zaimplementowane) | ✅ Zrobione |
| CI pipeline | GitHub Actions (do wdrożenia) | Średni |
| Version gating | Temporal validation (już zaimplementowane) | ✅ Zrobione |

---

> **Następny krok:** `14_SPECIALIZED_TAX_RULES.md` — 21 nowych reguł (P270-P290).
