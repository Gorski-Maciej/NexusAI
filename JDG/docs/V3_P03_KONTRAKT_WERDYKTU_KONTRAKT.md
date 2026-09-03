# V3-P03 KONTRAKT WERDYKTU — KONTRAKT WIĄŻĄCY

Status: **WDROŻONY_100** · Raport: `raporty_glm52_v3/RAPORT_V3_P03_KONTRAKT_WERDYKTU.txt`
Prompt źródłowy: `prompty_v3/V3_PROMPT_P03_KONTRAKT_WERDYKTU.txt`
Generator: `tools/glm52_v3_campaign/` · Ledger: `bundles/v3_campaign_ledger.json` (P03)

Ten dokument jest **wiążącym kontraktem wyjściowym** części P03 (25-polowy kontrakt
werdyktu, kompozycja decyzji, klasa pewności). Wiąże P04 (invarianty), P11
(certyfikaty), P41 (API/integracje), P43 (WORM/retencja). Zmiana kontraktu wymaga
nowego raportu (major) lub raportu zmiany additive (minor).

---

## 1. Kanoniczny 25-polowy słownik werdyktu (wersja 1.0)

Źródło: `rules/r01_orchestrator_core_innovations_v9.rego` (verdict_25_fields) —
INV-043: werdykt `matched=true` wymaga kompletnego słownika.

| # | Pole | Typ | Kategoria |
|---|------|-----|-----------|
| 1 | matched | boolean | metadane |
| 2 | rule_id | string | metadane |
| 3 | package | string | metadane |
| 4 | priority | integer | metadane |
| 5 | vat_rate | string | decyzyjne |
| 6 | rounding_level | string | decyzyjne |
| 7 | gtu_code | string | decyzyjne |
| 8 | vat_exemption | string | decyzyjne |
| 9 | procedure | string | decyzyjne |
| 10 | pit_form | string | decyzyjne |
| 11 | pit_rate | string | decyzyjne |
| 12 | pit_bracket | string | decyzyjne |
| 13 | pit_annual_return_type | string | decyzyjne |
| 14 | kus_qualification | string | decyzyjne |
| 15 | kus_percent | number | decyzyjne |
| 16 | zus_social_base_type | string | decyzyjne |
| 17 | zus_health_rate | string | decyzyjne |
| 18 | business_status | string | decyzyjne |
| 19 | ceidg_registration_required | boolean | decyzyjne |
| 20 | valid_from | string | temporalne |
| 21 | valid_to | string/null | temporalne |
| 22 | _routing | string | dowodowe |
| 23 | _routing_reason | string | dowodowe |
| 24 | _legal_basis | string | dowodowe |
| 25 | _warnings | array | dowodowe |

## 2. Rozszerzenia additive wersji 1.1 (bez breaking change)

| Pole | Semantyka | Źródło |
|------|-----------|--------|
| certainty_class | CERTAIN/CONDITIONAL/NEEDS_ADVICE | F4 V2 §5.2, `runtime_invariants._classify` |
| certainty_guard | CERTAINTY_BLOCKED/MANUAL_REVIEW/AUTO_POST_ALLOWED | F4 V2 §5.2, INV-006/035 |
| invariant_refs | lista naruszonych/przeskanowanych INV | P03-I06, INV-032 |
| legal_basis_refs | węzły LKG: `PL/<akt>/art/<art>[/ust/<ust>][/pkt/<pkt>]` | P01 legal_node_id |
| golden_hash | sha256(warunki ewaluacji) — odtworzenie 1:1 | P03-I04, F3 V2 |
| _degraded_context | boolean — ścieżka degradacji (INV-038) | P03-I10 |
| _contract_complete | boolean — walidacja 25 pól | INV-043 |

Przykład JSON przed/po (additive — klucze 1.1 dodane, 1.0 nietknięte):
```json
{ "verdict_1_0": { "matched": true, "rule_id": "jdg.vat.rate_23", "vat_rate": "0.23",
    "_routing": "ALLOW", "_legal_basis": "Art. 41 ust. 1 VAT" },
  "verdict_1_1": { "certainty_class": "CERTAIN", "certainty_guard": "AUTO_POST_ALLOWED",
    "golden_hash": "sha256:<...>", "legal_basis_refs": [{"ref": "PL/vat/art/41/ust/1"}] } }
```

## 3. Zamknięta lista warunków CERTAIN (P03-AN03)

AUTO_POST dozwolony **WYŁĄCZNIE** przy jednoczesnym spełnieniu (I02/I11):
1. `certainty_class == CERTAIN` (pełny łańcuch dowodów),
2. `_certainty_guard == AUTO_POST_ALLOWED`,
3. `_routing ∈ {ALLOW, AUTO_POST}` — nigdy TRIAGE/BLOCK,
4. brak `_degraded_context` (INV-038),
5. kontrakt 25-polowy kompletny (INV-043),
6. `matched == true`.

Każde odstępstwo → `MANUAL_REVIEW` / `CERTAINTY_BLOCKED` (INV-006/035).

## 4. Taksonomia błędów (wiązanie z P41)

- Źródło: `tools/v3_p03_error_taxonomy.py` → `bundles/v3_p03_error_taxonomy.json`
  + `docs/V3_P03_ERROR_TAXONOMY.md` (generowane z definicji — jedno źródło prawdy).
- Kody: `JDG-<SEVERITY>-<DOMENA>-<NUM>`; atrybuty: `retryable`, `http_status`,
  `severity`, `description`, `resolution`.
- Semantyka: retryable = ponów z backoff (NIGDY dla BLOCK); degradacja = WARNING
  z pełnym kontraktem (I10).

## 5. Semantyka pustych pól (P03-AN04)

- `null` — pole wymagane, wartość niedostępna (błąd/degradacja);
- `absent` — pole nieprodukowane przez ścieżkę (dryf kontraktu — luka);
- `N/A` — pole świadomie puste (nie dotyczy transakcji, np. `gtu_code` dla usługi);
- Walidator CI: pole wymagane puste w werdykcie `matched=true` = fail INV-043.

## 6. Degradacja kontraktu (P03-AN12)

- Każda ścieżka degradacji zwraca **pełny 25-polowy kontrakt** z `_degraded_context`
  i `_warnings` — nigdy skróconego werdyktu;
- Wzorce: DEGRADED_API / PARTIAL / BLOCKED / NO_MATCH (I10);
- Luka otwarta (L04): 4 ścieżki degradacji ze skróconym kontraktem (fallback/
  api_fallback) — do uzupełnienia pól temporalnych przed zamknięciem.

## 7. Zgodność OpenAPI (wiązanie z P41)

- `api/openapi.yaml` VerdictResponse: **19 pól** — 11 pól kanonicznych poza specyfikacją
  (package, priority, rounding_level, gtu_code, procedure, pit_bracket,
  pit_annual_return_type, kus_percent, ceidg_registration_required, valid_from,
  valid_to) → **L01 (P0)**: dodać pola do VerdictResponse (additive) przed P41.
- Bramka I05: diff OpenAPI bez diffu testów = fail merge (stan: BASELINE_REGISTERED).
- Golden replay I09: UVR=0 wymagany; decyzje historyczne odtwarzane na nowej wersji.

## 8. Metryki do obserwowalności (wiązanie z P37)

| Metryka | Typ | Próg |
|---|---|---|
| jdg_verdict_certain_pct | gauge | ≥ 50% |
| jdg_verdict_needs_advice_pct | gauge | ≤ 15% |
| jdg_verdict_non_certain_pct | gauge | ≤ 40% |
| jdg_verdict_certain_class_total | counter | tags: certainty_class, package |
| (z P02-I08) jdg_orchestrator_pass_duration_ms | histogram | p95 ≤ 5000 ms |

## 9. Werdykt jako obiekt dowodowy (wiązanie z P11/P43)

- Obiekt I07: werdykt + legal_refs + provenance path + seal (payload_hash,
  merkle_root, signature) + wersje bundle/rule/threshold + retencja (5 lat,
  Art. 86 § 1 OP; Art. 112 VAT);
- Podpis HSM: PENDING_4EYES do wdrożenia w P11/P43 — zero deklaracji bez realnego HSM;
- Eksport: PDF/XML/JSON_SEALED („werdykt papierowy" P03-AN09).

## 10. Bramki P03 (uruchamiane w CI/audycie)

| Bramka | Reguła | Stan |
|---|---|---|
| I01 Contract Version Matrix | 25 pól kanonicznych w OpenAPI i kontrakcie | **FAIL (11 pól)** → L01 |
| I02 Certainty Class Engine | determinizm + fail-closed semantyka | PASS |
| I03 Empty-Semantics Schema | 25 pól z dokumentacją pustki | PASS |
| I04 Golden Hash | deterministyczny + czuły na zmiany | PASS |
| I05 Contract Diff CI Gate | diff spec bez diffu testów = fail | PASS (baseline) |
| I06 Legal Refs Guard | 0 werdyktów materialnych bez _legal_basis | PASS |
| I07 Verdict Evidence Object | obiekt dowodowy kompletny | PASS |
| I08 Scoring Telemetry | alarmy dryfu klas (model) | **FAIL (alarm 1)** → L05 |
| I09 Client Compatibility | golden replay UVR=0, ścieżki w OpenAPI | PASS |
| I10 Degradation Contract | 0 ścieżek degradacji ze skróconym kontraktem | **FAIL (4)** → L04 |
| I11 AUTO_POST Gate | AUTO_POST tylko przy 6 warunkach | PASS |
| I12 Error Taxonomy | kody unikalne, docs z definicji | PASS |