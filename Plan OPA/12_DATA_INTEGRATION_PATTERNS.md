# OPA Data Integration Patterns dla NexusAI

> **Status:** Dokumentacja ENTERPRISE v1.0
> **Data:** 2026-07-07
> **Powiązany:** `10_OPA_IMPLEMENTATION_GUIDE.md`, `05_ARCHITECTURE_DECISION.md`
> **Źródła:** open-policy-agent/contrib, open-policy-agent/opa, OPAL (Permit.io), FINOS

---

## 1. Przegląd wzorców integracji danych

OPA jest silnikiem decyzyjnym działającym w pamięci. Nie utrzymuje własnego stanu — wszystkie dane muszą być dostarczone z zewnątrz. Dla systemu podatkowego klasy ENTERPRISE jak NexusAI, kluczowe jest wybranie odpowiedniego wzorca integracji dla każdego typu danych.

| Wzorzec | Typ danych | Latencja | Skala | Zastosowanie w NexusAI |
|---|---|---|---|---|
| **Overload Input** | Per-request (faktura) | <1ms | Mała | Pełny kontekst faktury w zapytaniu OPA |
| **Bundle API** | Semi-statyczne (stawki, progi) | Minuty | Średnia | `input.thresholds.*` — stawki VAT, CIT, limity |
| **Push Data** | Dynamiczne (kursy walut) | Sekundy | Duża | Kursy NBP, status Białej Listy MF |
| **Dynamic Pull** | Referencyjne (Biała Lista API) | Milisekundy | Ogromna | Weryfikacja NIP online, fraud graph, kursy NBP |

---

## 2. Wzorzec 1: Overload Input (per-request)

### Opis
Aplikacja wysyła pełny kontekst decyzji w każdym żądaniu do OPA. Najprostszy i najszybszy wzorzec.

### Zastosowanie w NexusAI
Każda faktura wysyłana do OPA zawiera kompletny `input`:
```json
{
  "invoice": {
    "amount_net": 10000,
    "amount_gross": 12300,
    "category_code": "FUEL",
    "transaction_date": "2026-07-07",
    "vendor_country": "PL"
  },
  "vendor": {
    "nip": "1234567890",
    "vat_status": "active",
    "country": "PL"
  },
  "company": {
    "tax_form": "CIT_STANDARD",
    "is_small_taxpayer": false
  },
  "thresholds": { /* z Bundle API */ }
}
```

### Zalety
- Zero zależności od zewnętrznych źródeł w runtime
- Determinizm — ta sama decyzja dla tego samego input
- Łatwe testowanie

### Wady
- Duży payload dla każdego żądania
- Thresholdy muszą być wstrzyknięte przez aplikację

---

## 3. Wzorzec 2: Bundle API (dane semi-statyczne)

### Opis
OPA okresowo pobiera bundle zawierający zarówno polityki Rego, jak i pliki danych (JSON). Idealne dla stawek podatkowych, progów i limitów.

### Zastosowanie w NexusAI
```bash
# Struktura OPA Bundle
bundle/
  policy.rego          # Reguły
  data.json            # Dane statyczne (thresholdy)
  .manifest            # Metadane bundla
```

```json
// data.json w bundlu
{
  "thresholds": {
    "rates": {
      "vat_standard": "0.23",
      "vat_reduced_8": "0.08",
      "vat_reduced_5": "0.05",
      "cit_standard": "0.19",
      "cit_small": "0.09",
      "eur_pln": 4.28
    },
    "limits": {
      "mpp_limit": 15000,
      "whitelist_limit": 15000,
      "vat_exemption_limit": 200000,
      "cash_transaction_limit": 15000
    }
  }
}
```

### Flow aktualizacji
```
1. DuckDB RuleStore → eksport thresholds.json
2. CI/CD pipeline: opa build --bundle policies/ --data thresholds.json
3. Bundle publish do OCI registry
4. OPA Server: hot-reload przez Bundle API
5. NATS event: "new_thresholds_deployed"
```

### Zalety
- Wersjonowane dane (git + OCI)
- Hot-reload bez restartu OPA
- Spójność: polityki + dane zawsze razem

### Wady
- Opóźnienie w propagacji zmian (minuty)
- Nie nadaje się dla danych zmieniających się co sekundę

---

## 4. Wzorzec 3: Push Data (dane dynamiczne)

### Opis
Zewnętrzny replikator danych pushuje zmiany do OPA przez REST API (`PUT /v1/data`). Idealne dla kursów walut, statusów kontrahentów.

### Zastosowanie w NexusAI
```
NBP API → kursy walut → Replikator → PUT /v1/data/fx/rates → OPA
MF API → Biała Lista → Replikator → PATCH /v1/data/whitelist → OPA
```

```python
# Python Replikator — push kursów NBP do OPA
async def push_fx_rates_to_opa():
    rates = await fetch_nbp_rates()
    await opa_client.put_data("/fx/rates", {
        "eur_pln": rates["EUR"],
        "usd_pln": rates["USD"],
        "updated_at": datetime.now().isoformat()
    })
```

### OPAL — zarządzanie Push Data na skalę
[OPAL](https://www.opal.ac/) (Open Policy Administration Layer) to narzędzie do zarządzania strumieniem danych do OPA w czasie rzeczywistym. Używa:
- **Policy Store** (git) dla polityk
- **Data Sources** dla danych dynamicznych
- **OPAL Client** jako sidecar przy OPA

### Zalety
- Sub-sekundowa aktualizacja danych
- Skalowalne (wiele instancji OPA)

### Wady
- Złożoność infrastruktury (replikator + OPAL)
- Ryzyko niespójności między instancjami OPA

---

## 5. Wzorzec 4: Dynamic Pull (http.send)

### Opis
Podczas ewaluacji reguły, OPA wykonuje `http.send` do zewnętrznego API. Używane dla danych, które muszą być "perfekcyjnie świeże".

### Zastosowanie w NexusAI

#### 5a. Weryfikacja Białej Listy MF
```rego
package tax.compliance.whitelist

# Dynamiczne sprawdzenie statusu VAT kontrahenta przez API MF
check_whitelist_status(nip) = response {
    response := http.send({
        "url": sprintf("https://apilista.mf.gov.pl/api/check/%s", [nip]),
        "method": "GET",
        "headers": {"Authorization": "Bearer secret"},
        "cache": true,
        "cache_duration_seconds": 3600  # cache na 1h
    })
}

whitelist_active {
    resp := check_whitelist_status(input.vendor.nip)
    resp.body.status == "active"
}
```

#### 5b. Fraud Graph Scanner
```rego
package tax.risk.fraud

fraud_check(nip) = response {
    response := http.send({
        "url": sprintf("http://fraud-service:8080/graph/%s", [nip]),
        "method": "GET",
        "timeout": "2s"
    })
}

fraud_detected {
    result := fraud_check(input.vendor.nip)
    result.body.risk_score > 0.8
}
```

### Zalety
- Dane zawsze aktualne w momencie decyzji
- Nie wymaga replikatora

### Wady
- Opóźnienie sieciowe (wpływ na latency decyzji)
- Zależność od dostępności zewnętrznego API
- Niedeterminizm (ten sam input może dać różny wynik)

---

## 6. Wzorzec 5: Data Filtering (Partial Evaluation)

### Opis
OPA nie zwraca decyzji tak/nie, ale generuje filtr (np. SQL WHERE clause), który aplikacja wykonuje na bazie danych. Wzorzec z open-policy-agent/contrib.

### Zastosowanie w NexusAI
```rego
package tax.filtering

# Generowanie filtru SQL dla faktur danego użytkownika
allowed_invoices[query] {
    query := sprintf(
        "SELECT * FROM invoices WHERE company_id = '%s' AND status != 'DELETED' AND amount_gross < %d",
        [input.user.company_id, input.thresholds.audit_limit]
    )
}
```

Aplikacja odbiera filtr i wykonuje:
```python
filter_sql = opa.evaluate("data.tax.filtering.allowed_invoices")
invoices = duckdb.execute(filter_sql).fetchall()
```

### Zalety
- Skaluje się do milionów rekordów
- Dane nie przechodzą przez OPA

### Wady
- Złożoność translacji Rego → SQL
- Ograniczone do prostych filtrów

---

## 7. Decision Logging Pattern

### Opis
Każda decyzja OPA jest logowana dla audytu. Wzorzec z styrainc/enterprise-opa.

### Implementacja
```rego
package tax.audit

audit_entry = {
    "timestamp": time.now_ns(),
    "decision_id": uuid.rfc4122(input._request_id),
    "rule_id": input._matched_rule,
    "input_hash": crypto.sha256(input),
    "user": input._audit.user_id
}
```

```yaml
# OPA config.yaml — decision logging
decision_logs:
  plugin: kafka_plugin
  config:
    topic: nexusai-tax-decisions
    brokers: ["kafka:9092"]
```

---

## 8. Rekomendowana architektura dla NexusAI

```
                   ┌──────────────┐
                   │   DuckDB     │  RuleStore (stawki, progi)
                   │  RuleStore   │
                   └──────┬───────┘
                          │ eksport JSON
                   ┌──────▼───────┐
                   │  CI/CD       │
                   │  opa build   │  Bundle = polityki + data.json
                   └──────┬───────┘
                          │ OCI push
          ┌───────────────┼───────────────┐
          │               │               │
   ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
   │ OPA Server  │ │ OPA Server  │ │ OPA Server  │  (HA)
   │ Instance 1  │ │ Instance 2  │ │ Instance 3  │
   └──────┬──────┘ └──────┬──────┘ └──────┬──────┘
          │               │               │
          │  ┌────────────┼───────────────┘
          │  │            │
   ┌──────▼──▼────────────▼───────┐
   │     Python/Rust App          │
   │  (Overload Input pattern)    │
   │  input = faktura +           │
   │  thresholds z Bundle         │
   └──────────────┬───────────────┘
                  │
   ┌──────────────▼───────────────┐
   │  Dynamic Pull (opcjonalny)   │
   │  - Biała Lista MF            │
   │  - Fraud Graph               │
   │  - Kursy NBP (fallback)      │
   └──────────────────────────────┘
```

---

## 9. Checklist wdrożeniowa

- [ ] Bundle API: OPA pobiera polityki + thresholds z OCI registry
- [ ] Overload Input: Aplikacja wysyła full context w każdym żądaniu
- [ ] Push Data: Replikator NBP pushuje kursy walut co 5 min
- [ ] Dynamic Pull (opcjonalnie): Biała Lista MF przez `http.send` z cache 1h
- [ ] Decision Logging: Wszystkie decyzje do Kafka/Splunk
- [ ] OPAL (opcjonalnie): Dla środowisk wymagających sub-sekundowej aktualizacji danych
- [ ] Data Filtering: Dla raportów audytowych na dużych zbiorach

---

> **Następny krok:** Wdrożenie Bundle API dla `policies/tax/` z thresholds z DuckDB RuleStore.
