# 🏗️ ADR-001: Architektura Ewaluacji Reguł — Multi-Pass vs Single-Chain

> **Status:** Decyzja architektoniczna  
> **Data:** 2026-07-07  
> **Autor:** Zespół NexusAI  
> **Powiązany:** `Plan OPA/00_PLAN_STRUKTURA.md`, `03_RULES_DETAILED.md`

---

## 1. Problem

### 1.1 Single Chain Limitation

Tradycyjne podejście `first-match-wins` przez pojedynczy łańcuch `else = {...}` w Rego ma fundamentalne ograniczenie dla systemu wielodomenowego:

```rego
# PROBLEM: Gdy VAT matchuje, CIT nigdy nie jest ewaluowany
decide = verdict_vat  { vat_conditions }     # P52: FUEL → 23% VAT
else = verdict_cit   { cit_conditions }     # P70: CIT estoński — NIGDY nie osiągane
else = verdict_zus   { zus_conditions }     # P95: ZUS — NIGDY nie osiągane
```

**Konsekwencja:** Jeden dokument (faktura) potrzebuje **wielu decyzji z różnych domen**:
- Stawka VAT + GTU (domena `tax.vat`)
- Kwalifikacja KUP (domena `tax.direct`)
- Metoda amortyzacji (domena `tax.accounting`)
- Stawki ZUS (domena `tax.zus`)
- Ostrzeżenia compliance (domena `tax.compliance`)

### 1.2 Obszary gdzie single-chain działa poprawnie

| Domena | Typ decyzji | Single-chain OK? |
|--------|------------|:---:|
| `tax.risk` | Fraud/anomalia → BLOCK | ✅ Tak — blokuje wszystko |
| `tax.routing` | Niska pewność → TRIAGE/BLOCK | ✅ Tak — blokuje/ostrzega |
| `tax.compliance` | Biała lista, MPP, KSeF | ✅ Tak — ostrzeżenia |
| `tax.crossborder` | Reverse charge, import, export | ✅ Tak — procedura specjalna |
| `tax.vat.substantive` | Stawka VAT + GTU | ✅ Tak — jedna stawka |
| `tax.vat.gtu` | Mapowanie kategorii→GTU | ✅ Tak — jeden kod |
| `tax.direct.cit` | Stawka CIT + KUP | ⚠️ **NIE** — musi być po VAT |
| `tax.direct.pit` | Stawka PIT + KUP | ⚠️ **NIE** — musi być po VAT |
| `tax.allowances` | Ulgi podatkowe | ⚠️ **NIE** — musi być po CIT/PIT |
| `tax.accounting` | Amortyzacja, FIFO, FX | ⚠️ **NIE** — niezależna domena |
| `tax.zus` | Składki ZUS | ⚠️ **NIE** — niezależna domena |
| `tax.fallback` | Domyślna stawka PL | ✅ Tak — fallback |

---

## 2. Rozwiązanie: Multi-Pass Evaluation

### 2.1 Architektura

Zamiast jednego łańcucha `else`, system używa **wielu niezależnych ewaluacji OPA**, z których każda odpowiada za inną domenę:

```
                    ┌─────────────────────────────────────┐
                    │         OPA EVALUATION ENGINE        │
                    │                                      │
  input ──────────► │  PASS 0: RISK (fraud/anomaly)       │──► risk_verdict
                    │         ↓ (if not blocked)           │
                    │  PASS 1: ROUTING (confidence)       │──► routing_verdict
                    │         ↓ (if not triaged)           │
                    │  PASS 2: COMPLIANCE (whitelist/MPP) │──► compliance_verdict
                    │         ↓                            │
                    │  PASS 3: CROSSBORDER (EU/non-EU)   │──► crossborder_verdict
                    │         ↓                            │
                    │  PASS 4: VAT (+ GTU)               │──► vat_verdict
                    │         ↓                            │
                    │  PASS 5: DIRECT TAXES (CIT/PIT)    │──► direct_verdict
                    │         ↓                            │
                    │  PASS 6: ALLOWANCES                 │──► allowances_verdict
                    │         ↓                            │
                    │  PASS 7: ACCOUNTING                 │──► accounting_verdict
                    │         ↓                            │
                    │  PASS 8: ZUS                        │──► zus_verdict
                    │         ↓                            │
                    │  VERDICT MERGER                     │──► final_verdict
                    └─────────────────────────────────────┘
```

### 2.2 Każdy Pass używa własnego `else` chain wewnątrz swojej domeny

```rego
# vat.rego — first-match-wins wewnątrz domeny VAT
package tax.vat

default decide = {"matched": false, "vat_rate": ""}

# P40: EU reverse charge
decide = {"matched": true, "vat_rate": "0.00", "procedure": "VAT_REVERSE_CHARGE", ...} {
    input.vendor.country == "EU"
    input.vendor.vat_status == "active"
}
# P45: Non-EU import
else = {"matched": true, "vat_rate": "0.23", "procedure": "IMPORT", ...} {
    input.vendor.country == "NON_EU"
}
# P50: VAT margin scheme
else = {"matched": true, "vat_rate": "0.23", "procedure": "MARGIN", ...} {
    input.invoice.procedure == "MARGIN"
}
# P52: FUEL in PL → 23%
else = {"matched": true, "vat_rate": "0.23", "gtu_code": "GTU_04", ...} {
    input.invoice.category_code == "FUEL"
    input.vendor.country == "PL"
}
# ... więcej reguł VAT
# P100: Domestic fallback
else = {"matched": true, "vat_rate": input.thresholds.rates.vat_standard, ...} {
    input.vendor.country == "PL"
}
```

### 2.3 Verdict Merger (Python/Rust)

```python
class VerdictMerger:
    """Scala werdykty z wielu passów OPA w jeden finalny werdykt."""
    
    def merge(self, passes: list[dict]) -> dict:
        verdict = {
            "matched": True,
            "rule_id": [],
            "packages": [],
            
            # VAT
            "vat_rate": None,
            "rounding_level": None,
            "gtu_code": None,
            "procedure": None,
            
            # Income tax
            "income_tax_qualification": None,
            "cit_rate": None,
            "pit_rate": None,
            "pit_bracket": None,
            
            # Routing
            "_routing": None,
            "_routing_reason": [],
            
            # Compliance
            "mpp_required": False,
            "_warnings": [],
            
            # Allowances
            "reliefs": [],
            
            # Accounting
            "depreciation_method": None,
            "fx_revaluation_required": False,
            
            # ZUS
            "zus_health_rate": None,
            "zus_base_percent": None,
            
            # Audit
            "_legal_basis": [],
        }
        
        for p in passes:
            if p.get("_routing") in ("BLOCK_AND_ALERT", "TRIAGE_QUEUE"):
                verdict["_routing"] = p["_routing"]
                verdict["_routing_reason"].append(p.get("_routing_reason", ""))
            
            # VAT pass
            if "vat_rate" in p and p["vat_rate"]:
                verdict["vat_rate"] = p["vat_rate"]
                verdict["gtu_code"] = p.get("gtu_code", "")
                verdict["procedure"] = p.get("procedure", "")
                verdict["rounding_level"] = p.get("rounding_level", "position")
                verdict["rule_id"].append(p.get("rule_id", ""))
                verdict["packages"].append(p.get("package", ""))
                verdict["_legal_basis"].append(p.get("_legal_basis", ""))
            
            # Direct tax pass
            if "cit_rate" in p:
                verdict["cit_rate"] = p["cit_rate"]
            if "pit_rate" in p:
                verdict["pit_rate"] = p["pit_rate"]
            if "income_tax_qualification" in p:
                verdict["income_tax_qualification"] = p["income_tax_qualification"]
            
            # Warnings
            if "_warnings" in p:
                verdict["_warnings"].extend(p["_warnings"])
            
            # Allowances
            if "relief_type" in p:
                verdict["reliefs"].append({
                    "type": p["relief_type"],
                    "percent": p.get("relief_percent"),
                    "max": p.get("relief_max"),
                })
            
            # Accounting
            if "depreciation_method" in p:
                verdict["depreciation_method"] = p["depreciation_method"]
            if "fx_revaluation_required" in p:
                verdict["fx_revaluation_required"] = True
            
            # ZUS
            if "zus_health_rate" in p:
                verdict["zus_health_rate"] = p["zus_health_rate"]
            if "zus_base_percent" in p:
                verdict["zus_base_percent"] = p["zus_base_percent"]
        
        return verdict
```

### 2.4 Orkiestracja passów

```python
class MultiPassOpaEvaluator:
    """Orkiestruje ewaluację Multi-Pass."""
    
    PASSES = [
        ("tax/risk", "data.tax.risk.decide"),
        ("tax/routing", "data.tax.routing.decide"),
        ("tax/compliance", "data.tax.compliance.decide"),
        ("tax/crossborder", "data.tax.crossborder.decide"),
        ("tax/vat", "data.tax.vat.decide"),
        ("tax/direct", "data.tax.direct.decide"),
        ("tax/allowances", "data.tax.allowances.decide"),
        ("tax/accounting", "data.tax.accounting.decide"),
        ("tax/zus", "data.tax.zus.decide"),
    ]
    
    async def evaluate(self, opa_client, input_data: dict) -> dict:
        verdicts = []
        should_abort = False
        
        for policy_path, query in self.PASSES:
            if should_abort:
                break
            
            result = await opa_client.evaluate(query, input_data)
            
            if result and result.get("matched"):
                verdicts.append(result)
                
                # RISK i ROUTING mogą abortować dalsze passy
                if result.get("_routing") == "BLOCK_AND_ALERT":
                    should_abort = True
        
        merger = VerdictMerger()
        return merger.merge(verdicts)
```

---

## 3. Wewnętrzne First-Match-Wins

### 3.1 Gdzie first-match-wins nadal obowiązuje

Wewnątrz **każdego pojedynczego pliku Rego** chain `else` jest zachowany. Na przykład w `vat.rego`:

```
P40 (EU reverse charge) → P45 (non-EU import) → P50 (margin) → P52 (fuel PL) → ... → P100 (domestic fallback)
```

Tylko **jedna** stawka VAT jest zwracana — ta z najwyższym priorytetem. Ale inne domeny (CIT, accounting) są ewaluowane niezależnie.

### 3.2 Wyjątki od multi-pass

Jeśli RISK (P0-P9) lub ROUTING (P10-P19) zwróci `BLOCK_AND_ALERT`, dalsze passy są abortowane — dokument wymaga manualnej inspekcji.

Jeśli zwróci `TRIAGE_QUEUE`, dalsze passy mogą być kontynuowane (dostarczają propozycje dla triage), ale z flagą.

---

## 4. Wpływ na istniejący kod

### 4.1 `nexus_ai/tax/rules.rego` (obecny)

Obecny plik łączy wszystkie reguły w jeden `else` chain. **To działa dla fazy 0-2** (VAT + compliance + crossborder), ale NIE skaluje się do CIT/PIT/accounting.

**Plan migracji:**
1. **Faza 1 (teraz):** Rozdzielić `rules.rego` na pliki per-domena zgodnie ze strukturą `policies/` z `03_RULES_DETAILED.md`
2. **Faza 2:** Zaimplementować `MultiPassOpaEvaluator` w Python
3. **Faza 3:** Przetestować integracyjnie

### 4.2 Kompatybilność wsteczna

Podczas migracji, istniejący `OpaClient.evaluate()` może być opakowany w adapter:

```python
class OpaClientAdapter:
    """Adapter zapewniający kompatybilność wsteczną."""
    
    def __init__(self, opa_client, use_multi_pass: bool = False):
        self._client = opa_client
        self._use_multi_pass = use_multi_pass
        self._multi_pass = MultiPassOpaEvaluator() if use_multi_pass else None
    
    async def evaluate(self, input_data: dict) -> dict:
        if self._use_multi_pass:
            return await self._multi_pass.evaluate(self._client, input_data)
        else:
            # Legacy single-pass
            return await self._client.evaluate("tax/decide", input_data)
```

---

## 5. Priorytetyzacja domen (kolejność passów)

| Pass | Domena | Priorytet | Abortuje na BLOCK? |
|------|--------|:---------:|:------------------:|
| 0 | `tax.risk` | P0-P9 | ✅ Tak |
| 1 | `tax.routing` | P10-P19 | ✅ Tak |
| 2 | `tax.compliance` | P20-P39 | ❌ Nie (tylko warningi) |
| 3 | `tax.crossborder` | P40-P49 | ❌ Nie |
| 4 | `tax.vat` | P50-P69 | ❌ Nie |
| 5 | `tax.direct` | P70-P79 | ❌ Nie |
| 6 | `tax.allowances` | P80-P89 | ❌ Nie |
| 7 | `tax.accounting` | P90-P94 | ❌ Nie |
| 8 | `tax.zus` | P95-P99 | ❌ Nie |

---

## 6. Ryzyka i mitygacje

| Ryzyko | Mitygacja |
|--------|----------|
| Zwiększona liczba wywołań OPA (9 zamiast 1) | Cache'owanie thresholdów, bulk-evaluation przez OPA REST API |
| Niespójność między passami | VerdictMerger — deterministyczne scalanie |
| Złożoność testowania | Każdy pass testowany niezależnie (Rego test) + testy integracyjne merger'a |
| Utrzymanie spójności z DuckDB | Pojedyncza transakcja budująca `input` dla wszystkich passów |

---

> **Następny krok:** Implementacja `05_ENTERPRISE_RULES_COMPENDIUM.md` — kompletny opis wszystkich reguł z pseudokodem uwzględniający architekturę multi-pass.
