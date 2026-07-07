# Mapa Integracji Serwisów NexusAI → OPA Rules

> **Status:** Dokumentacja ENTERPRISE v1.0
> **Data:** 2026-07-07
> **Powiązany:** `05_ARCHITECTURE_DECISION.md`, `10_OPA_IMPLEMENTATION_GUIDE.md`
> **Źródła:** Analiza 12 plików `nexus_ai/services/`

---

## 1. Przegląd serwisów i ich mapowanie na pakiety OPA

| Serwis NexusAI | Plik | Pakiet OPA | Reguły | Typ integracji |
|---|---|---|---|---|
| **RiskGuard** | `risk_guard.py` | `tax.risk` | P0-P9 | Pre-filter (first-match) |
| **SemanticGuard** | `semantic_guard.py` | `tax.risk` | P5 | Pre-filter (anomaly scoring) |
| **FraudGraphScanner** | `fraud_graph_scanner.py` | `tax.risk` | P0 | Pre-filter (fraud detection) |
| **WhiteListService** | `white_list_service.py` | `tax.compliance` | P20-P21 | Compliance check |
| **VATReconciliationEngine** | `vat_reconciliation.py` | `tax.vat` | P276-P277 | Post-decision integrity |
| **TaxSimulator** | `tax_simulator.py` | `tax.simulator` | All | Shadow ledger |
| **OpaPolicyGenerator** | `opa_policy_generator.py` | Generator | — | Code generation |
| **AuditService** | `audit_service.py` | `tax.audit` | — | Decision logging |
| **IntegrityVerifier** | `integrity_verifier.py` | `tax.audit` | — | Chain integrity |
| **ComplianceAnalytics** | `compliance_analytics.py` | `tax.accounting` | P90-P94 | Ledger validation |
| **TaxStrategies** | `tax_strategies.py` | `tax.direct.*` | P70-P79 | Strategy selection |
| **DecisionStructs** | `decision_structs.py` | Shared | All | Verdict structure |

---

## 2. RiskGuard → `tax.risk` (P0-P9)

### Charakterystyka serwisu
- First-match-wins z regułami w SQLite
- Prog ryzyka zależny od `tax_form` + `expense_type`
- Akcje: `BLOCK_AND_ALERT`, `TRIAGE_QUEUE`, `ALLOW`

### Punkt integracji z OPA
```python
# risk_guard.py → OPA decision
async def evaluate_with_opa(risk_guard, invoice_context):
    """Zamiast SQLite first-match, uzyj OPA."""
    risk_result = risk_guard.evaluate(
        tax_form=invoice_context["company"]["tax_form"],
        expense_type=invoice_context["invoice"]["expense_type"],
        ai_confidence=invoice_context["confidence"]["fc_minimum"],
    )

    if risk_result["action"] != "ALLOW":
        return {
            "matched": True,
            "rule_id": f"risk.{risk_result['rule_id']}",
            "package": "tax.risk",
            "priority": 0,
            "_routing": risk_result["action"],
            "_routing_reason": risk_result["reason"],
        }

    # Jeśli ALLOW, przekaż dalej do OPA rules.rego
    return opa.evaluate("tax/decide", invoice_context)
```

### Mapowanie reguł
| RiskGuard rule_id | OPA rule_id | Priorytet |
|---|---|---|
| `default` | `tax.risk.fallback` | P9 |
| `cit_standard_representation` | `tax.routing.fc_representation_minimum` | P18 |
| `lump_sum_global` | `tax.routing.fc_global_minimum_low` | P19 |

---

## 3. SemanticGuard → `tax.risk` (P5)

### Charakterystyka serwisu
- Embeddingi faktur przez sqlite-vec
- Wykrywanie nagłych zmian profilu kontrahenta
- Anomaly scoring: `anomaly_score > 0.80` → `BLOCK_DECREE`

### Punkt integracji z OPA
```python
# semantic_guard.py → OPA risk.rego
async def prefilter_semantic(guard, invoice_text, vendor_nip):
    result = await guard.evaluate(invoice_text, vendor_nip)
    if result.action == AnomalyAction.BLOCK_DECREE:
        return {
            "matched": True,
            "rule_id": "tax.risk.semantic_guard_disallowed",
            "package": "tax.risk",
            "priority": 5,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": result.alert,
            "_anomaly_score": result.anomaly_score,
        }
    if result.action == AnomalyAction.WARN:
        return {
            "_warnings": [result.alert],
            "_anomaly_score": result.anomaly_score,
        }
    return None
```

### Dane przekazywane do OPA
```json
{
  "invoice": {
    "semantic_anomaly_score": 0.85,
    "semantic_alert": "Drastyczna zmiana profilu...",
    "similar_invoices_count": 3
  }
}
```

---

## 4. FraudGraphScanner → `tax.risk` (P0)

### Charakterystyka serwisu
- Graf współdzielonych encji (IBAN, adres)
- Wykrywanie "ghost vendor" (pracownik = kontrahent)
- Alerty: `GHOST_VENDOR_SHARED_IBAN` (CRITICAL), `GHOST_VENDOR_SHARED_ADDRESS` (HIGH)

### Punkt integracji z OPA
```python
# fraud_graph_scanner.py → OPA risk.rego
def detect_and_flag(scanner, invoice_context):
    alerts = scanner.detect_shared_identity_links()
    for alert in alerts:
        if alert.vendor_id == invoice_context["vendor"]["nip"]:
            return {
                "matched": True,
                "rule_id": "tax.risk.fraud_graph_match",
                "package": "tax.risk",
                "priority": 0,
                "_routing": "BLOCK_AND_ALERT",
                "_routing_reason": f"{alert.rule_code}: {alert.shared_attribute}={alert.shared_value}",
                "fraud_severity": alert.severity,
            }
    return None
```

### Dane przekazywane do OPA
```json
{
  "vendor": {
    "fraud_flag": true,
    "fraud_rule_code": "GHOST_VENDOR_SHARED_IBAN",
    "fraud_severity": "CRITICAL"
  }
}
```

---

## 5. WhiteListService → `tax.compliance` (P20-P21)

### Charakterystyka serwisu
- API Białej Listy MF (`wl-api.mf.gov.pl`)
- Cache 1h (TTL 3600s)
- Circuit breaker (stamina.retry)
- Weryfikacja NIP + rachunku bankowego

### Punkt integracji z OPA
```python
# white_list_service.py → OPA compliance.rego
async def enrich_with_whitelist(service, invoice_context):
    nip = invoice_context["vendor"]["nip"]
    subject = await service.check_nip(nip)

    invoice_context["vendor"]["on_whitelist"] = subject is not None
    invoice_context["vendor"]["whitelist_checked_at"] = pendulum.now().isoformat()

    if invoice_context["invoice"]["amount_gross"] >= 15000:
        account = invoice_context["invoice"].get("vendor_account", "")
        if account:
            invoice_context["vendor"]["account_on_whitelist"] = (
                await service.verify_bank_account(nip, account)
            )

    return invoice_context
```

### Tryb offline (graceful degradation)
```rego
# compliance.rego — fallback dla offline WhiteList
whitelist_status := "UNKNOWN" {
    not input.vendor.whitelist_checked_at
}

export_whitelist_graceful {
    whitelist_status == "UNKNOWN"
    input._system.whitelist_api_available == false
    decision := {"_warnings": ["Whitelist check unavailable — manual verification required"]}
}
```

---

## 6. VATReconciliationEngine → `tax.vat` (P276-P277)

### Charakterystyka serwisu
- Weryfikacja integralności VAT między OCR, DuckDB i TigerBeetle
- Walidacja stawek (23, 8, 5, 0, np, zw)
- Sprawdzanie math: net + vat = gross
- Rekonsyliacja: DuckDB vs TigerBeetle

### Punkt integracji z OPA
```python
# vat_reconciliation.py → OPA feedback loop
async def reconcile_and_feedback(engine, invoice_id, ocr_results):
    integrity = engine.check_vat_integrity(invoice_id, ocr_results)
    if integrity.status == "FAILED":
        # Inform OPA o błędzie integralności dla przyszłych decyzji
        return {
            "matched": True,
            "rule_id": "vat.integrity.vat_mismatch",
            "package": "tax.vat.integrity",
            "priority": 0,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": f"VAT integrity failed: {integrity.errors}",
        }
    return None
```

---

## 7. TaxSimulator → `tax.simulator`

### Charakterystyka serwisu
- Shadow ledgers dla "co by było gdyby"
- DuckDB + Polars dla OLAP
- Symulacja różnych form opodatkowania
- Porównanie current vs simulated

### Punkt integracji z OPA
```python
# tax_simulator.py → OPA shadow evaluation
async def simulate_with_opa(simulator, invoices, target_tax_form):
    """Zamiast DuckDB RuleStore, uzyj OPA z innym kontekstem."""
    context = {
        "company": {"tax_form": target_tax_form},
        "thresholds": simulator.load_thresholds(),
    }

    results = []
    for inv in invoices:
        input_data = {**context, "invoice": inv}
        verdict = opa.evaluate("tax/decide", input_data)
        results.append(verdict)

    return aggregate_results(results)
```

---

## 8. OpaPolicyGenerator

### Charakterystyka serwisu
- Konwertuje reguły DuckDB → Rego source code
- Generuje else-chain dla first-match-wins
- SQL-to-Rego translator
- Generuje OPA data documents

### Usprawnienie: zamiast generować Rego, użyj natywnego OPA
```python
# Zamiast generatora — bezpośrednie OPA:
# DuckDB RuleStore → OPA Bundle (data.json)
# Reguły Rego → OPA Bundle (policy.rego)
# Ładowane przez Bundle API bez generowania kodu
```

---

## 9. AuditService → `tax.audit`

### Punkt integracji z OPA
```python
# Decision logging z każdej ewaluacji OPA
async def log_opa_decision(audit_service, session, decision):
    audit_service.log_change(
        session=session,
        user_id=decision.get("_audit", {}).get("user_id", "OPA"),
        action=f"OPA_DECISION_{decision.get('rule_id', 'UNKNOWN')}",
        target_id=decision.get("_audit", {}).get("trace_id", ""),
        old_data={},
        new_data=decision,
    )
```

---

## 10. Architektura przepływu decyzji

```
┌─────────────────────────────────────────────────────────────┐
│                    PIPELINE DECYZYJNY                        │
│                                                              │
│  1. OCR Pipeline ──► input.invoice, input.confidence         │
│  2. FraudGraphScanner ──► input.vendor.fraud_flag            │
│  3. SemanticGuard ──► input.invoice.semantic_anomaly_score   │
│  4. WhiteListService ──► input.vendor.on_whitelist           │
│  5. GUS/BIR Client ──► input.vendor.* (dane rejestrowe)     │
│                                                              │
│         ▼                                                    │
│   ┌─────────────────┐                                        │
│   │  OPA EVALUATION  │  Multi-Pass (ADR-001)                 │
│   │                  │                                       │
│   │  Pass 1: risk    │  P0-P9   (fraud, anomalie)            │
│   │  Pass 2: routing │  P10-P19 (field confidence)           │
│   │  Pass 3: compl.  │  P20-P39 (whitelist, MPP, KSeF)       │
│   │  Pass 4: crossb. │  P40-P49 (reverse charge, import)     │
│   │  Pass 5: VAT     │  P50-P69 (stawki, GTU)                │
│   │  Pass 6: direct  │  P70-P79 (CIT/PIT, KUP)               │
│   │  Pass 7: allow.  │  P80-P89 (ulgi)                       │
│   │  Pass 8: account │  P90-P94 (amortyzacja, FIFO)          │
│   │  Pass 9: ZUS     │  P95-P99 (składki)                    │
│   │  Pass 10+: ext.  │  P110-P290 (wszystkie rozszerzenia)   │
│   └────────┬────────┘                                        │
│            ▼                                                 │
│   ┌─────────────────┐                                        │
│   │  VERDICT MERGER  │  (ADR-001)                             │
│   │  Łączy werdykty  │                                       │
│   │  10+ passów      │                                       │
│   └────────┬────────┘                                        │
│            ▼                                                 │
│   ┌─────────────────┐                                        │
│   │  POST-DECISION   │                                       │
│   │  - VAT Reconcile │                                       │
│   │  - Audit Log     │                                       │
│   │  - TigerBeetle   │                                       │
│   │  - NATS event    │                                       │
│   └─────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 11. Rekomendacje implementacyjne

| Priorytet | Rekomendacja | Serwisy |
|---|---|---|
| **P0** | Migracja RiskGuard SQLite → OPA risk.rego | RiskGuard, SemanticGuard, FraudGraphScanner |
| **P1** | WhiteListService jako `http.send` w OPA (z cache) | WhiteListService |
| **P2** | TaxSimulator używa OPA shadow evaluation | TaxSimulator |
| **P3** | VATReconciliation jako post-decision hook | VATReconciliationEngine |
| **P4** | Decision logging przez NATS → Kafka | AuditService |
| **P5** | OpaPolicyGenerator → Bundle API (bez generowania kodu) | OpaPolicyGenerator |

---

> **Następny krok:** Aktualizacja `04_INDEX.md` i `00_PLAN_STRUKTURA.md`.
