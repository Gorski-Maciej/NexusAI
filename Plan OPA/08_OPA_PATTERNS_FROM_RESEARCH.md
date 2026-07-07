# 🎯 Wzorce Architektoniczne z Projektów Referencyjnych — Lekcje dla NexusAI

> **Status:** Analiza porównawcza v1.0  
> **Data:** 2026-07-07  
> **Projekty:** FINOS/OpenEAGO, OpenFisca, open-policy-agent/library  
> **Powiązany:** `05_ARCHITECTURE_DECISION.md`, `07_ADVANCED_RULES_EXPANSION.md`

---

## 1. FINOS / OpenEAGO — Tiered Policy Categorization

### Wzorzec: Trójwarstwowa kategoryzacja polityk

FINOS wprowadza rozróżnienie na trzy typy kontroli:

| Warstwa | Typ | Implementacja w NexusAI |
|---------|-----|------------------------|
| **Architectural** | Infrastruktura, szyfrowanie | Calm/konfiguracja systemowa |
| **Runtime** | Per-request enforcement | **OPA/Rego** — nasze 128 reguł |
| **Procedural** | Audyty okresowe, feedback loop | DecisionTraceLogger (już istnieje) |

**Lekcja dla NexusAI:** Nasz system już implementuje to rozróżnienie:
- Runtime = reguły OPA first-match-wins
- Procedural = DecisionTraceLogger z SHA-256 chain

### Wzorzec: Composite Risk Scoring

FINOS ocenia ryzyko w 4 wymiarach i stosuje "hard-stop thresholds":

```
RiskScore = f(financial, operational, compliance, security)

if RiskScore > HARD_STOP_THRESHOLD → BLOCK
else if RiskScore > TRIAGE_THRESHOLD → TRIAGE_QUEUE
else → AUTO_POST
```

**Lekcja dla NexusAI:** Nasze reguły P0-P9 (risk) i P10-P19 (routing) już implementują podobny mechanizm. Można rozszerzyć o zagregowany scoring:

```rego
# Propozycja: Composite Risk Score
composite_risk_score = score {
    score := (input.vendor.trust_score * 0.3) +
             (input.confidence.fc_minimum * 0.2) +
             (input.vendor.fraud_flag ? 0.5 : 0.0)
}

# Hard-stop threshold
block_if_high_risk {
    composite_risk_score < input.thresholds.limits.hard_stop_threshold
}
```

### Wzorzec: Jurisdiction-Aware Policies

FINOS stosuje "work contracts" z metadanymi jurysdykcyjnymi — reguły są wybierane dynamicznie na podstawie kraju.

**Lekcja dla NexusAI:** Nasz system już ma `input.vendor.country` jako kluczowy parametr dla reguł crossborder (P40-P49). Rozszerzenie o dynamiczne ładowanie country-pack (PL, EU, NON_EU) zwiększy skalowalność.

---

## 2. OpenFisca — Parameter-vs-Logic Bifurcation

### Wzorzec: Separacja parametrów od logiki ⭐ NAJWAŻNIEJSZY

To jest **dokładnie** to, co NexusAI już planuje w `02_THRESHOLDS_CATALOG.md`:

```
OpenFisca:         NexusAI:
─────────          ────────
YAML parameters  → DuckDB tax_thresholds
Python formulas  → Rego rules
Variables        → input.* fields
```

OpenFisca przechowuje parametry jako **wersjonowane drzewa YAML** z temporalnością:

```yaml
# OpenFisca-style parameter (inspiracja dla DuckDB)
rates:
  vat_standard:
    - value: "0.23"
      valid_from: "2024-01-01"
      valid_to: "2026-06-30"
    - value: "0.24"
      valid_from: "2026-07-01"
```

**Lekcja dla NexusAI:** Nasza tabela `tax_thresholds` w DuckDB już implementuje ten wzorzec. **Kluczowe usprawnienie:** dodać kolumnę `threshold_value_json` dla złożonych struktur (np. mapy KŚT group → rate).

```sql
-- Rozszerzenie tax_thresholds o struktury złożone
ALTER TABLE tax_thresholds ADD COLUMN threshold_value_json JSON;

-- Przykład: mapa KŚT
INSERT INTO tax_thresholds VALUES (
    'kst.depreciation_rates', NULL,
    '{"0": 0.0, "1": 0.025, "4": 0.30, "7": 0.20}',
    '2024-01-01', NULL,
    'Mapa grup KŚT → stawki amortyzacji',
    'KŚT zał. 1'
);
```

### Wzorzec: DAG-based Dependency Resolution

OpenFisca automatycznie rozwiązuje graf zależności między zmiennymi. Gdy żądasz `income_tax`, silnik rekurencyjnie oblicza `revenue`, `costs`, `deductions`.

**Lekcja dla NexusAI:** W architekturze Multi-Pass (ADR-001), VerdictMerger już implementuje podobną koncepcję — scala wyniki z wielu passów. Można rozszerzyć o **explicit dependency graph**:

```python
# Propozycja: Dependency Graph dla Multi-Pass
DEPENDENCY_GRAPH = {
    "tax.vat": [],                              # niezależny
    "tax.direct": ["tax.vat"],                   # zależy od VAT (procedure)
    "tax.allowances": ["tax.direct"],            # zależy od CIT/PIT
    "tax.accounting": [],                        # niezależny
    "tax.zus": [],                               # niezależny
}

def resolve_evaluation_order(passes, input_data):
    """Topological sort passów na podstawie grafu zależności."""
    # ...
```

### Wzorzec: Entity Hierarchy

OpenFisca definiuje hierarchię encji: `Person → Family → Household → TaxUnit`.

**Lekcja dla NexusAI:** Nasz `input` jest płaski (2 poziomy: `invoice.*`, `vendor.*`, `company.*`). Dla bardziej zaawansowanych scenariuszy (wspólne rozliczenie małżonków P76, holding VAT), hierarchia encji byłaby przydatna.

---

## 3. OPA Library — Organizacja Polityk

### Wzorzec: Struktura katalogów

Z oficjalnego `open-policy-agent/library`:

```
policies/
├── common/
│   └── utils.rego          # Funkcje pomocnicze
├── domain_a/
│   ├── policy.rego
│   └── policy_test.rego
├── domain_b/
│   ├── policy.rego
│   └── policy_test.rego
└── main.rego               # Importuje wszystkie
```

**Lekcja dla NexusAI:** Nasza planowana struktura `policies/tax/` (z `03_RULES_DETAILED.md`) jest zgodna z tym wzorcem. **Brakuje nam `common/utils.rego`** — wspólnych helperów:

```rego
# Propozycja: policies/tax/_helpers.rego
package tax.helpers

# Helper: bezpieczne porównanie z threshold
gte_threshold(value, threshold_key) {
    value >= object.get(input.thresholds, threshold_key, 999999999)
}

# Helper: sprawdzenie temporal validity
is_valid_period(date, valid_from, valid_to) {
    date >= valid_from
    valid_to == null
} else {
    date >= valid_from
    date <= valid_to
}

# Helper: konwersja kategorii na GTU
category_to_gtu(code) = "GTU_04" {
    code == "FUEL"
} else = "GTU_01" {
    code in ["IT_OFFICE", "ELECTRONICS"]
} else = "GTU_07" {
    code == "FOOD"
} else = "" {
    true
}
```

### Wzorzec: Testy Rego

Z `open-policy-agent/library` — każda polityka ma testy:

```rego
package tax.vat.substantive.test

test_fuel_pl_23_vat {
    result := data.tax.vat.substantive.decide with input as test_input_fuel_pl
    result.vat_rate == "0.23"
    result.gtu_code == "GTU_04"
}

test_fuel_eu_reverse_charge {
    result := data.tax.vat.substantive.decide with input as test_input_fuel_eu
    result.vat_rate == "0.00"
    result.procedure == "VAT_REVERSE_CHARGE"
}

# Edge case: brak thresholdów
test_no_thresholds_graceful {
    result := data.tax.vat.substantive.decide with input as test_input_no_thresholds
    result.matched == false
}
```

**Lekcja dla NexusAI:** Potrzebujemy rozbudowanych testów Rego dla wszystkich 128 reguł. Wzorzec: 1 test pozytywny + 1 test negatywny + 1 edge case per reguła = ~384 testów.

---

## 4. Wzorce specyficzne dla polskiego prawa podatkowego

### Wzorzec: Temporalność reguł (kluczowy dla PL)

Polskie prawo podatkowe zmienia się często (Polski Ład, Nowy Ład, Slim VAT...). Wzorzec temporalności z OpenFisca jest kluczowy:

```rego
# Wzorzec temporalności: ta sama reguła, różne stawki w czasie
vat_rate_for_date = rate {
    input.invoice.transaction_date >= "2026-07-01"
    rate := "0.24"  # nowa stawka
} else = rate {
    input.invoice.transaction_date >= "2024-01-01"
    rate := "0.23"  # stara stawka
} else = rate {
    input.invoice.transaction_date >= "2011-01-01"
    rate := "0.23"  # historyczna
}
```

### Wzorzec: Procedural rules (Ordynacja)

Reguły proceduralne (korekty, przedawnienia, terminy) różnią się od reguł merytorycznych (stawki, limity). FINOS rozróżnia Runtime vs Procedural — reguły proceduralne powinny być ewaluowane osobno:

```rego
# procedural.rego — reguły proceduralne (osobny pass)
package tax.procedural

# P180: Blokada korekty w trakcie kontroli
# P38:  Zbliżające się przedawnienie
# P36:  Odsetki od zaległości
# P28:  KSeF mandatory check
```

---

## 5. Rekomendacje dla NexusAI

### Natychmiastowe (Faza 3):

1. **Utworzyć `policies/tax/_helpers.rego`** — wspólne helpery dla wszystkich pakietów
2. **Dodać `threshold_value_json`** do DuckDB `tax_thresholds` dla złożonych struktur
3. **Rozpocząć pisanie testów Rego** — minimum 2 testy per reguła

### Średnioterminowe (Faza 4-5):

4. **Zaimplementować Composite Risk Scoring** (inspiracja FINOS) dla reguł P0-P9
5. **Dodać explicit dependency graph** do MultiPassOpaEvaluator (inspiracja OpenFisca)
6. **Wydzielić reguły proceduralne** do osobnego pliku (inspiracja FINOS Runtime/Procedural)

### Długoterminowe (Faza 6+):

7. **Dynamiczne country-packs** — osobne pliki Rego dla PL, EU, NON_EU (inspiracja OpenFisca)
8. **Entity hierarchy** — wsparcie dla struktur holdingowych, wspólnego rozliczenia
9. **Wersjonowanie thresholdów z temporalnością** — pełna historia zmian stawek

---

## 6. Podsumowanie: Macierz inspiracji

| Wzorzec | Źródło | Status w NexusAI | Priorytet |
|---------|--------|:---:|:---:|
| Parameter-vs-Logic bifurcation | OpenFisca | ✅ Zaimplementowane (DuckDB thresholds) | — |
| Tiered Policy Categorization | FINOS | ✅ Runtime + Procedural istnieje | — |
| Composite Risk Scoring | FINOS | ⚠️ Częściowo (P0-P9) | Faza 4 |
| DAG-based Dependency Resolution | OpenFisca | ⚠️ Multi-Pass bez explicit graph | Faza 4 |
| Jurisdiction-Aware Policies | FINOS | ⚠️ Tylko country_code | Faza 6 |
| Entity Hierarchy | OpenFisca | ❌ Niezaimplementowane | Faza 7 |
| Common Helpers (utils.rego) | OPA Library | ❌ Brak | Faza 3 |
| Rego Tests (2+/reguła) | OPA Library | ⚠️ Tylko podstawowe | Faza 3 |
| Temporalność parametrów | OpenFisca | ⚠️ DuckDB ma valid_from/to | Faza 5 |
| Procedural Rules Separation | FINOS | ❌ Niezaimplementowane | Faza 5 |

---

> **Następny krok:** Aktualizacja `04_INDEX.md` i `00_PLAN_STRUKTURA.md` z referencjami do nowych dokumentów.
