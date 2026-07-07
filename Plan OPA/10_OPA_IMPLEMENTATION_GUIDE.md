# 🛠️ Praktyczny Przewodnik Implementacji Rego — Wzorce ENTERPRISE

> **Status:** Przewodnik v1.0  
> **Data:** 2026-07-07  
> **Powiązany:** `05_ARCHITECTURE_DECISION.md`, `08_OPA_PATTERNS_FROM_RESEARCH.md`

---

## 1. Struktura plików Rego — wzorzec ENTERPRISE

Bazuje na wzorcach z kubescape/regolibrary (Rule → Control → Framework), styrainc/enterprise-opa (Bundle API + Decision Logging) i conftest/conftest (deny/violation + testy).

```
policies/
├── tax/
│   ├── _helpers.rego              # Wspólne funkcje pomocnicze
│   ├── _metadata.rego             # Metadane reguł (wersja, autor, data)
│   ├── risk.rego                  # P0-P9: Fraud, anomalie, semantic
│   ├── routing.rego               # P10-P19: Field confidence
│   ├── compliance.rego            # P20-P39: Biała lista, MPP, KSeF
│   ├── crossborder.rego           # P40-P49: UE reverse charge, import
│   ├── vat/
│   │   ├── substantive.rego       # P50-P64: Stawki VAT wg kategorii
│   │   └── gtu.rego               # P65-P69: Mapowanie GTU
│   ├── direct/
│   │   ├── cit.rego               # P70-P74: CIT
│   │   ├── pit.rego               # P74-P79: PIT
│   │   ├── leasing.rego           # P125-P127: Leasing
│   │   └── kup.rego               # P140-P142: KUP wyłączenia
│   ├── allowances.rego            # P80-P89: Ulgi podatkowe
│   ├── accounting/
│   │   ├── depreciation.rego      # P90-P91, P135-P139: Amortyzacja, KŚT
│   │   ├── ifrs.rego              # P120-P122, P215-P216: IFRS/MSSF
│   │   └── uor.rego               # P92-P94, P205-P208: RMK, FX, FIFO
│   ├── zus.rego                   # P95-P99: Składki ZUS
│   ├── ppk.rego                   # P110-P111: PPK
│   ├── excise.rego                # P115-P117: Akcyza
│   ├── environmental.rego         # P198-P199: Środowisko/BDO
│   ├── labor.rego                 # P192-P196: Prawo pracy, zasiłki
│   ├── local_tax.rego             # P190-P191: Podatki lokalne
│   ├── ngo.rego                   # P200-P201: NGO
│   ├── fallback.rego              # P100, P200: Domyślne
│   └── procedural.rego            # P180, P210-P211: Ordynacja proceduralne
├── compliance/
│   ├── aml.rego                   # P150-P152: AML
│   ├── ceidg.rego                 # P160-P165: CEIDG
│   ├── ksh.rego                   # P170: KSH
│   └── jpk.rego                   # P145-P147: JPK znaczniki
├── tests/
│   ├── vat_test.rego
│   ├── cit_test.rego
│   ├── pit_test.rego
│   ├── compliance_test.rego
│   ├── risk_test.rego
│   └── integration_test.rego
├── data/
│   ├── thresholds.json            # Parametry do testów
│   └── fixtures/                  # Fixtures testowe
├── main.rego                      # Importuje wszystkie pakiety
├── bundle.sh                      # Skrypt budowania OPA bundle
└── Makefile                       # opa test, opa build, opa check
```

---

## 2. Wzorzec `_helpers.rego`

```rego
package tax.helpers

# ── GTU mapping helper ──────────────────────────────────────
category_to_gtu(code) = "GTU_04" {
    code == "FUEL"
} else = "GTU_01" {
    code in ["IT_OFFICE", "ELECTRONICS"]
} else = "GTU_07" {
    code == "FOOD"
} else = "" {
    true
}

# ── Temporal validation ─────────────────────────────────────
is_valid_period(date) {
    date >= input.thresholds.valid_from
} {
    not input.thresholds.valid_to
} {
    date <= input.thresholds.valid_to
}

# ── Threshold comparison helpers ────────────────────────────
gte_threshold(value, key) {
    value >= object.get(input.thresholds.limits, key, 0)
}

lte_threshold(value, key) {
    value <= object.get(input.thresholds.limits, key, 999999999)
}

# ── Rate string to float converter ──────────────────────────
rate_to_float(rate_str) = num {
    num := to_number(rate_str)
}

# ── Amount in EUR converter ─────────────────────────────────
amount_in_eur = eur {
    eur := input.invoice.amount_gross / input.thresholds.rates.eur_pln
}
```

---

## 3. Wzorzec `_metadata.rego` — Metadane wg kubescape

```rego
package tax.metadata

# Każda reguła ma metadane śledzące wersję i autora
# Inspiracja: kubescape/regolibrary — rule.metadata.json

rules_metadata = {
    "tax.risk.fraud_graph_match": {
        "version": "1.2.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-07-07",
        "severity": "CRITICAL",
        "category": "FRAUD",
        "framework": ["VAT_COMPLIANCE", "AML"],
        "remediation": "Zweryfikuj kontrahenta w grafie fraudowym i zgłoś do KAS",
        "references": ["Art. 86 ust. 1 VAT", "Art. 55 KKS"]
    },
    "tax.compliance.whitelist_missing": {
        "version": "1.0.0",
        "author": "NexusAI Tax Team",
        "last_updated": "2026-06-15",
        "severity": "HIGH",
        "category": "COMPLIANCE",
        "framework": ["VAT_COMPLIANCE", "WHITE_LIST"],
        "remediation": "Sprawdź kontrahenta na Białej Liście MF przed przelewem",
        "references": ["Art. 96b VAT", "Art. 117ba Ordynacji"]
    }
}

# Get metadata for a specific rule
get_rule_metadata(rule_id) = metadata {
    metadata := object.get(rules_metadata, rule_id, {})
}
```

---

## 4. Wzorzec testów Rego — wg conftest + kubescape

Bazuje na konwencji `*_test.rego` z conftest i strukturze `success/failed` z kubescape.

```rego
# tests/vat_test.rego
package tax.vat.substantive.test

import data.tax.vat.substantive

# ── Fixtures ────────────────────────────────────────────────
test_input_fuel_pl = {
    "invoice": {
        "category_code": "FUEL",
        "transaction_date": "2026-06-15",
        "amount_net": 1000,
        "amount_gross": 1230,
        "vendor_country": "PL"
    },
    "vendor": {"country": "PL", "vat_status": "active"},
    "company": {"tax_form": "CIT_STANDARD"},
    "thresholds": {"rates": {"vat_standard": "0.23"}}
}

test_input_education_pl = {
    "invoice": {
        "category_code": "EDUCATION",
        "transaction_date": "2026-06-15",
        "amount_net": 5000,
        "amount_gross": 5000,
        "vendor_country": "PL"
    },
    "vendor": {"country": "PL"},
    "thresholds": {"rates": {"vat_standard": "0.23", "vat_zero": "0.00"}}
}

# ── Positive tests ──────────────────────────────────────────
test_fuel_pl_23_vat_positive {
    result := substantive.decide with input as test_input_fuel_pl
    result.vat_rate == "0.23"
    result.matched == true
    result.gtu_code == "GTU_04"
}

test_education_exempt_positive {
    result := substantive.decide with input as test_input_education_pl
    result.vat_rate == "0.00"
    result.matched == true
    result.rounding_level == "total"
}

# ── Negative tests ──────────────────────────────────────────
test_unknown_category_fallback {
    result := substantive.decide with input as object.union(
        test_input_fuel_pl,
        {"invoice": {"category_code": "UNKNOWN_XYZ"}}
    )
    result.vat_rate == "0.23"  # domestic fallback
}

# ── Edge cases ──────────────────────────────────────────────
test_missing_thresholds_graceful {
    result := substantive.decide with input as json.remove(
        test_input_fuel_pl, ["/thresholds"]
    )
    not result.matched  # should fail gracefully
}

test_zero_amount_no_error {
    result := substantive.decide with input as object.union(
        test_input_fuel_pl,
        {"invoice": {"amount_net": 0, "amount_gross": 0}}
    )
    result.matched == true  # still should match on category
}
```

---

## 5. Wzorzec OPA Bundle — wg styrainc

```bash
#!/bin/bash
# bundle.sh — budowanie OPA bundle dla NexusAI
# Inspiracja: styrainc/enterprise-opa (Bundle API) + kubescape (bundle.py)

opa build \
    --bundle policies/tax \
    --bundle policies/compliance \
    --output nexusai-tax-policies.tar.gz \
    --revision "v$(date +%Y.%m.%d)-$(git rev-parse --short HEAD)"

# Ew. publikacja do OCI registry:
# oras push my-registry/nexusai/policies:latest nexusai-tax-policies.tar.gz
```

---

## 6. Makefile — workflow deweloperski

```makefile
.PHONY: test check build clean

# Uruchom wszystkie testy Rego
test:
	opa test policies/ -v

# Sprawdź poprawność składni wszystkich plików
check:
	opa check policies/ --strict

# Zbuduj bundle
build:
	./bundle.sh

# Wyczyść wygenerowane pliki
clean:
	rm -f *.tar.gz

# Test integracyjny (wymaga uruchomionego OPA server)
integration-test:
	curl -X POST http://localhost:8181/v1/data/tax/decide \
		-H "Content-Type: application/json" \
		-d @test_input.json | jq .
```

---

## 7. Wzorzec Decision Logging — wg styrainc

```rego
# W każdej regule dodajemy metadane audytowe
# Inspiracja: styrainc/enterprise-opa decision logging

audit_context := {
    "timestamp": input._audit.timestamp,
    "user_id": input._audit.user_id,
    "session_id": input._audit.session_id,
    "trace_id": input._audit.trace_id
}

# Każdy werdykt rozszerzony o kontekst audytowy
enriched_verdict = v {
    v := object.union(verdict, {"_audit": audit_context})
}
```

---

## 8. Wzorzec Dynamic Configuration — wg kubescape

```rego
# controlConfigInputs — parametryzowalne progi
# Inspiracja: kubescape/regolibrary rule.metadata.json → controlConfigInputs

# Zamiast hardcoded:
# input.invoice.amount_gross >= 15000

# Użyj konfiguracji:
mpp_threshold := object.get(
    input.thresholds.limits, "mpp_limit", 15000
)

# Przyszłościowo: dynamiczne przełączniki reguł
rule_enabled(rule_id) {
    not input._config.disabled_rules[rule_id]
}
```

---

## 9. Wzorzec: Procedural vs Runtime Rules — wg FINOS

```rego
# Rozróżnienie reguł proceduralnych od runtime
# Inspiracja: FINOS OpenEAGO — Tiered Categorization

# Runtime (szybkie first-match-wins):
#   risk.rego, routing.rego, compliance.rego, vat.rego, direct.rego

# Procedural (osobny pass po runtime):
#   procedural.rego, uor.rego (sprawozdania, terminy)
```

---

## 10. Wzorzec: Wersjonowanie i walidacja

```rego
# Wersja polityki — śledzenie zmian
# Inspiracja: kubescape/regolibrary metadata versioning

policy_version := "2026.07.07"

# Walidacja struktury input przed ewaluacją
# Inspiracja: conftest/conftest input validation patterns
validate_input {
    input.invoice.category_code
    input.invoice.transaction_date
    input.vendor.country
    input.vendor.vat_status
    input.company.tax_form
}
```

---

## 11. Deployment — rekomendowany flow

```
1. Git commit → GitHub Actions CI
2. CI: opa check → opa test → opa build (bundle)
3. Bundle publikowany do OCI registry
4. OPA Server: hot-reload przez Bundle API
5. NATS: powiadomienie o nowej wersji polityk
6. Monitoring: Decision Logs → Splunk/Kafka
```

---

## 12. Checklist wdrożeniowa

- [ ] `policies/tax/_helpers.rego` — wspólne helpery
- [ ] `policies/tax/_metadata.rego` — metadane reguł
- [ ] Minimum 2 testy na regułę (pozytywny + negatywny)
- [ ] `opa check --strict` przechodzi bez błędów
- [ ] `opa test policies/ -v` — wszystkie testy zielone
- [ ] Bundle build: `opa build --bundle policies/`
- [ ] Decision logging włączone
- [ ] Hot-reload przez Bundle API
- [ ] Monitoring działających reguł (metryki Prometheus)

---

> **Następny krok:** Wdrożenie fazy 3 — migracja thresholdów i pierwsze pliki `.rego` zgodnie z tym przewodnikiem.
