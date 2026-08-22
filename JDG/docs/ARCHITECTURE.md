# 🏗️ JDG Architecture Decision Records (ADR) — v8.3

> **Status:** ENTERPRISE v8.3 | **Data:** 2026-08-22 | **22 ADR-y** (001–022)

---

## ADR-001: First-Match-Wins else-chain

**Decyzja:** Wszystkie pliki `.rego` używają deterministycznej ewaluacji `else`-chain zamiast `else-if` lub osobnych pakietów.

**Uzasadnienie:**
- OPA/Rego nie wspiera natywnie `else if`; `else := { ... } { condition }` to jedyny sposób na deterministyczną kolejność
- Priorytety numeryczne (`"priority": N`) są **metadanymi**, nie mechanizmem sortowania
- Kolejność w pliku = kolejność ewaluacji

**Konsekwencje:**
- Nowe reguły MUSZĄ być dodawane w odpowiednim miejscu w łańcuchu
- Nie można przeplatać helper rules (`:=`) z `else :=` w łańcuchu (helper rules muszą być przed lub po)
- Testy muszą weryfikować poprawność kolejności

**Status wdrożenia:** ✅ IMPLEMENTED (fundament od v1.0)
**Ostatnia weryfikacja:** 2026-08-02 — testy kolejności: 0 plików .rego w tests/ (⚠️ patrz ADR-013)

---

## ADR-002: Zero Hardcoded Values

**Decyzja:** Żadna wartość liczbowa (stawka, próg, limit, data) nie jest zakodowana bezpośrednio w regułach Rego. Wszystko przez `data.thresholds.*`.

**Uzasadnienie:**
- Zmiany prawne (np. nowa stawka VAT, zmiana progów) wymagają tylko aktualizacji thresholdów, nie kodu Rego
- Hot-reload przez OPA Data API bez redeployu
- Ułatwia testowanie — testy mogą podstawiać różne wartości thresholdów

**Aktualny status:** ⚠️ PARTIALLY IMPLEMENTED
- Wykryto ~265 zakodowanych wartości w 32 plikach (audyt z 2026-07-13)
- Migracja 001 tworzy tabelę `jdg_tax_thresholds` z wersjonowaniem temporalnym
- Bundles/manifest.json deklaruje serwis `thresholds` (http://thresholds-service:8080)
- **Skala pozostałości:** nieznana — wymaga audytu wyczerpującego (R8)
- **Szacowane ukończenie:** Faza C7 (60% wykonane)

---

## ADR-003: Temporalność Reguł

**Decyzja:** Reguły zawierają `valid_from` / `valid_to` zarządzane przez `temporal.rego` i `_metadata_jdg.rego`.

**Uzasadnienie:**
- Polski Ład 2022 zmienił składkę zdrowotną (9%/4.9% zamiast odliczenia)
- SLIM VAT 3 (2023) zmienił ulgę złe długi (150→90 dni)
- KSeF obowiązkowy od 2026-02-01
- Reguły muszą stosować właściwe prawo dla daty transakcji (nie daty bieżącej)

**Implementacja:**
```rego
# temporal.rego
temporal_validity := {
    "jdg.zus.health_scale": {"valid_from": "2022-01-01", "valid_to": null},
    "jdg.vat.substantive.bad_debt_relief_creditor_90d": {"valid_from": "2023-01-01", "valid_to": null},
    "jdg.vat.substantive.bad_debt_relief_creditor_150d": {"valid_from": null, "valid_to": "2022-12-31"},
}
```

**Status wdrożenia:** ✅ IMPLEMENTED (temporal.rego, _metadata_jdg.rego, migracja 001 rule_versions)

---

## ADR-004: Standardowy Werdykt 25-Polowy

**Decyzja:** Każda reguła zwraca ustandaryzowany obiekt z 25 polami, nawet jeśli większość jest pusta.

**Uzasadnienie:**
- Ułatwia merge werdyktów z wielu pakietów (Multi-Pass)
- `safe_merge` w `main_jdg.rego` łączy werdykty bez utraty danych
- Klient może polegać na stałej strukturze JSON

**Status wdrożenia:** ✅ IMPLEMENTED (validate_rules.py sprawdza _legal_basis/_routing/_warnings)

---

## ADR-005: Dual-Layer Architecture (Horyzont 2027+)

**Decyzja:** Długoterminowa architektura dwuwarstwowa:
- **Warstwa 1 (Macro):** ~500 reguł biznesowych/decyzyjnych — agregują Micro
- **Warstwa 2 (Micro):** ~7000 reguł atomowych/prawnych — pojedyncze warunki logiczne

**⚠️ AKTUALIZACJA v8.0:** Horyzont PRZYSPIESZONY.
- `rules/micro/` zawiera już **106 plików** reguł mikro (nie czekamy do 2027!)
- Zasady konsolidacji mikro z makro — patrz **ADR-010**
- Implementacja mikro rozpoczęta "w tle" — zobacz `generate_micro_rules.py`, `generate_massive_rules.py`

**Status wdrożenia:** ⚠️ PARTIALLY IMPLEMENTED (rozpoczęte wcześniej niż planowano)

---

## ADR-006: Immutable Audit Trail

**Decyzja:** Krytyczne werdykty (ZUS, zdrowotna) są oznaczane `immutable_verdict: true` i podpisywane HMAC-SHA256.

**Uzasadnienie:**
- Werdykty ZUS i zdrowotne mają bezpośredni wpływ finansowy
- Immutowalność zapobiega manipulacji post-factum
- Merkle Tree umożliwia weryfikację integralności całego łańcucha decyzji

**Implementacja:** `nexus_ai/tax/immutable_audit.py` + pole `immutable_verdict` w Rego

**Status wdrożenia:** ✅ IMPLEMENTED (migracja 001: jdg_verdict_audit)

---

## ADR-007: Multi-Pass Evaluation

**Decyzja:** Ewaluacja OPA odbywa się w wielu przebiegach (Multi-Pass PASS 0-8 + POST-MERGE).

**Status wdrożenia:** ✅ IMPLEMENTED (spójne z openapi.yaml, ADR-007 i README)

---

## ADR-008: Konwencja Nazewnicza Rule ID

**Format:** `jdg.<domena>.<kategoria>_<szczegół>`

**⚠️ AKTUALIZACJA v8.0:** Wykryto **336 zduplikowanych rule_id** (te same reguły w makro i micro, lub duplikaty z generacji masowej). Konwencja wymaga dopisania zasad deduplikacji — patrz **ADR-010**.

**Status wdrożenia:** ✅ IMPLEMENTED (wymaga uzupełnienia o deduplikację)

---

## ADR-009: Sharded Router (B1) — [NOWY, v8.0]

**Decyzja:** Orkiestrator `main_jdg.rego` dzieli pakiety na shardy według kontekstu (tax_form × transaction_type × entity_flags × evaluation_date) z O(1) hashowaniem.

**Uzasadnienie:**
- ~55 pakietów w orkiestratorze — ewaluacja wszystkich na raz to ~50-100ms
- Sharded Router redukuje do 5-25 reguł na shard → p95 < 5ms
- Każdy shard ma dedykowany zestaw reguł

**Implementacja:** `main_jdg.rego` + `routing.rego`

**Status wdrożenia:** ✅ IMPLEMENTED (działa w orkiestratorze)

---

## ADR-010: Mikro-Atomy + Deduplikacja — [NOWY, v8.0]

**Decyzja:** 
1. `rules/micro/` zawiera 106 plików atomowych — status: PRODUKCYJNY (nie "horyzont 2027").
2. Deduplikacja 336 rule_id: każdy duplikat przechodzi proces merge/rename/remove.
3. Zasady generowania: `generate_micro_rules.py` (759 linii) + `generate_massive_rules.py` (1507 linii).

**Zasady deduplikacji:**
- Jeśli ta sama reguła w makro i micro → zachowaj wersję makro, usuń z micro
- Jeśli ten sam rule_id w różnych plikach → rename z sufiksem kontekstu
- Reguły z `generate_missing_rules.py` (checkpoint rules) → prefix `chk_`

**Status wdrożenia:** ⚠️ PARTIALLY — mikro istnieje (106 plików), deduplikacja do wykonania (Faza 3)

---

## ADR-011: Policy Bundles + Wersjonowanie — [NOWY, v8.0]

**Decyzja:** Bundle OPA budowany przez `bundle.sh` (v8.0) z zachowaniem struktury katalogów.

**Zasady:**
- `bundle.sh` kopiuje pliki .rego z zachowaniem ścieżek względnych (fix R1 — 8 kolizji nazw)
- Weryfikacja: liczba plików w bundle == liczba plików na dysku
- Wersjonowanie: data + opcjonalny tag
- Deployment: `curl -X PUT --data-binary @bundle.tar.gz http://opa-server:8181/v1/bundles/jdg`

**Status wdrożenia:** ✅ IMPLEMENTED (bundle.sh v8.0)

---

## ADR-012: Metryki Pokrycia (Definicja "Reguły") — [NOWY, v8.0]

**Decyzja:** Wprowadzenie 3 rozłącznych metryk pokrycia:

| Metryka | Definicja | Wartość (2026-08-22) |
|---------|-----------|----------------------|
| **M1: Bloki matched:true** | Liczba wystąpień `"matched": true` we wszystkich plikach Rego | **11 811** |
| **M2: Unikalne rule_id** | Liczba unikalnych identyfikatorów reguł (dedup) | **11 808** |
| **M3: Punkty Doc 50** | Liczba punktów prawnych z Doc 50 zmapowanych na rule_id | 29/29 raportów GLM52 WDROZONY_100 |

**Źródło jednej prawdy:** MANIFEST.md (auto-generowany przez generate_manifest.py v8.0)

**Status wdrożenia:** ✅ IMPLEMENTED (generate_manifest.py v8.0 liczy M1 i M2; M3 w COVERAGE_REPORT.md; MANIFEST 2026-08-22: 472 pliki / 88/100 Completeness)

---

## ADR-013: Testy Rego — [NOWY, v8.0]

**Decyzja:** Wprowadzenie polityki testowania Rego.

**Zasady:**
- Testy Rego (`_test.rego`) dla wszystkich kluczowych pakietów (VAT, PIT, ZUS, KKS)
- Minimum 1 test per pakiet weryfikujący else-chain (kolejność reguł)
- `opa test JDG/tests/ -v` w CI
- Pokrycie testami: cel >=20 plików testowych do Q4 2026

**Aktualny stan:** ✅ **207 natywnych plików testowych Rego** w `JDG/tests/` (w tym `tests/rego/` 103 + `tests/rego/micro/` 25 + testy natywne ETAP 14–28) + **198 testów pytest** (`tests/`, `tests/auto/`). Cel >=20 plików przekroczony ~10×.

**Status wdrożenia:** ✅ IMPLEMENTED (Faza 4 — przekroczone; testy natywne `test_native_*.rego` dla każdego ETAP 14–28)

---

## ADR-014: Rozliczalność Narzędzi — [NOWY, v8.0]

**Decyzja:** Segregacja plików .py w JDG/tools/ na kategorie.

**Kategorie:**
| Kategoria | Opis | Przykłady |
|-----------|------|-----------|
| **core/** | Główne narzędzia produkcyjne | `generate_manifest.py`, `validate_rules.py` |
| **legacy/** | Narzędzia jednej kampanii | `p11_accounting_toolkit.py` |
| **one-shot/** | Jednorazowe fixy/konwersje | `fix_*.py`, `dedup_*.py` |
| **tests/** | Generatory testów | `generate_test_suite.py` |

**Status wdrożenia:** ✅ IMPLEMENTED (tools/README.md, R15)

---

## ADR-015: Konwencja Checkpoint-Stubów (P26 R12) — [NOWY, v8.1]

**Status:** ✅ Zaakceptowane (2026-08-02)

**Problem:** Wiele reguł Rego używa warunku `{ true }` jako placeholder podczas developmentu. Bez konwencji nie da się odróżnić intencjonalnego zawsze-prawdziwego triggera od niedokończonego stubu.

**Decyzja:** Każda reguła z warunkiem `{ true }` MUSI być oznaczona:
1. `# CHECKPOINT-STUB` w komentarzu nad regułą
2. `_routing_reason` zawiera `[CHECKPOINT-STUB]`
3. `_warnings` zawiera `[CHECKPOINT-STUB: <opis planowanego triggera>]`

**Narzędzia:**
- `dead_rule_detector.py` flaguje reguły `{ true }` bez CHECKPOINT-STUB
- `validate_rules.py` raportuje CHECKPOINT-STUB jako WARNING
- `initiative_numbering_auditor.py` weryfikuje spójność numeracji S1-S24

**Konsekwencje:** Wszystkie nowe reguły przechodzące code review z `{ true }` muszą być oznaczone jako CHECKPOINT-STUB.

---

## ADR-016: Legal Twin / Legal Knowledge Graph (LKG) — [NOWY, v8.2 / P01 V2 F1]

**Status:** ✅ Zaakceptowane (2026-08-08, P01 Fundament)

**Decyzja:** Ewolucja tabeli `jdg_legal_cartography` do pełnego **Legal Knowledge Graph** (`legal_graph`, migracja 003): akty → artykuły → ustępy → punkty z wersjonowaniem czasowym (jak reguły). Każda reguła i parametr dwukierunkowo powiązane z węzłami prawa. Podstawa prawna przestaje być stringiem — staje się **referencją** do węzła LKG (`_legal_basis_refs`).

**Metryki:** LCI (Legal Coverage Index ≥ 99%), TCL (Temporal Continuity 100%), RV (Rule–Law Verification 100%).

**Narzędzia:** `tools/legal_twin.py` (build LKG + indeksy), bramka RV w CI.

---

## ADR-017: Warstwa Konstytucyjna — Runtime Invariants — [NOWY, v8.2 / P01 V2 F2]

**Status:** ✅ Zaakceptowane (2026-08-08, P01 Fundament)

**Decyzja:** Katalog ~30 twardych niezmienników (INV-001..030) egzekwowanych na **każdym werdykcie w runtime** (koniec POST-MERGE w `main_jdg.rego`), a nie tylko w CI. Naruszenie = `CERTAINTY_BLOCKED` + alarm + auto-revert. Trzy poziomy: BUILD (blokada merge), RUNTIME (blokada werdyktu), STATISTICAL (auto-rollback bundle).

**Artefakty:** `rules/audit/runtime_invariants_enterprise.rego` (katalog INV + reguły egzekucji), `tools/invariant_checker.py` (bramka CI).

---

## ADR-018: Golden Oracle + Ewaluacja Różnicowa — [NOWY, v8.2 / P01 V2 F3]

**Status:** ✅ Zaakceptowane (2026-08-08, P01 Fundament)

**Decyzja:** Repozytorium złotych werdyktów (tabela `golden_verdicts`, migracja 003) jako „oracle przeszłości": żadna zmiana nie może zmienić historycznego werdyktu bez uzasadnienia w diffie prawnym (UVR = 0). Ewaluacja różnicowa: domeny krytyczne liczone na ≥ 2 węzłach, hash werdyktu (`decision_hash`) musi się zgadzać.

**Narzędzia:** `tools/golden_replay.py` (record/replay/annotate/report), bramka GOLDEN_REPLAY w CI.

---

## ADR-019: Decision Certificate — [NOWY, v8.2 / P01 V2 F4]

**Status:** ✅ Zaakceptowane (2026-08-08, P01 Fundament)

**Decyzja:** Każdy werdykt generuje certyfikat decyzyjny z klasą pewności `CERTAIN` / `CONDITIONAL` / `NEEDS_ADVICE` oraz pieczęcią kryptograficzną (SHA-256 → Merkle → podpis HSM), weryfikowalną offline. Eksport PDF+XML dla KAS. AUTO_POST tylko dla CERTAIN.

**Narzędzia:** `tools/decision_certificate.py` (issue/verify/classes/export), tabela `decision_certificates` (migracja 003).

---

## ADR-020: Law Radar — Proaktywna Adaptacja — [NOWY, v8.2 / P01 V2 F5]

**Status:** ✅ Zaakceptowane (2026-08-08, P01 Fundament)

**Decyzja:** Monitoring **projektów ustaw** (RCL, Sejm, Senat) — nie tylko opublikowanych nowelizacji. Reguły przygotowywane z wyprzedzeniem (SHADOW, `valid_from` = data wejścia) — w dniu wejścia tylko promote. KPI: `lead_time_avg ≥ 30 dni` przed wejściem w życie.

**Narzędzia:** `tools/law_radar.py` (track/radar/status/prepare), tabela `draft_law_radar` (migracja 003).

---

## ADR-021: Declarative Change — [NOWY, v8.2 / P01 V2 F6]

**Status:** ✅ Zaakceptowane (2026-08-08, P01 Fundament)

**Decyzja:** Interfejs deklaratywny zmiany: człowiek opisuje zmianę w języku prostym (np. „stawka VAT 23% → 8% od 2027-01-01"), system mapuje na parametr/regułę, generuje diff, testy, impact, golden replay, PR 4-eyes i wdraża kanarkowo. Automatyzacja NIGDY: bez zdrowych metryk kanara, bez 2 podpisów dla domen niemutowalnych, bez dowodu zero referencji przy usuwaniu.

**Narzędzia:** `tools/declarative_change.py` (plan/execute/template/history), integracja z data_service (ścieżka danych < 1 min).

---

## ADR-022: Orkiestrator Forteca — POST-MERGE Invariants + Decision Certificate — [NOWY, v8.3 / P03 GLM52]

**Status:** ✅ Zaakceptowane (2026-08-08, P03 GLM52 Orkiestrator)

**Decyzja:** Na **końcu POST-MERGE** (`main_jdg.rego` → `final_verdict_enforced`) każdy werdykt przechodzi przez egzekucję runtime invariants (F2 V2) i otrzymuje:
- `_invariant_report` — wynik czystej funkcji `evaluate(v)` (INV-001..042, poziomy RUNTIME/BUILD/STATISTICAL),
- `certainty_class` (F4 V2 §5.2): `CERTAIN` / `CONDITIONAL` / `NEEDS_ADVICE`,
- `_certainty_guard` — `AUTO_POST_ALLOWED` / `MANUAL_REVIEW` / `CERTAINTY_BLOCKED`; **host NIGDY nie wykonuje AUTO_POST dla CERTAINTY_BLOCKED** (INV-006/INV-035),
- `_decision_certificate` — certyfikat F4: `decision_hash` (F3 V2, ewaluacja różnicowa) + wersje `bundle_version` / `rule_version` / `threshold_version` (V1 §9.3) + `legal_basis_refs` (F1),
- `_routing_context` — kontekst routingu O(1) (INV-020/INV-036, ADR-009).

**Katalog:** INV-001..042 w `rules/audit/runtime_invariants_enterprise.rego` — rozszerzony o determinizm (INV-010/040), certyfikat (INV-031/032/034), degradację (INV-038), graf (INV-041), allowlist (INV-042). `evaluate(v)` jest jednoźródłową funkcją czystą — używana przez runtime, host i CI (invariant_checker.py).

**Innowacje P03:** `rules/p03_orchestrator_innovations_v9.rego` — 14 INN (cache Merkle INN-01/12, shadow twin INN-02, dowody SMT/Z3 INN-03, benchmarki INN-04, cold-start INN-05, WASM+fallback INN-06, degraded context INN-07, kill-switch INN-08, graf zależności INN-09, certyfikat INN-10, propagacja pewności INN-11, hot-path INN-13, lifecycle INN-14). Temporalność: `temporal.rego` P1627–P1632 (algebra interwałów, pinning progów, law radar lead ≥ 30, retroaktywność, dryft, dowód wersji). Bramka zero-hardcode: `tools/hardcoded_audit_gate.py` (HARDCODED_AUDIT, cel 0 → data.thresholds/DuckDB, hot-reload < 1 min).

**Artefakty:** `rules/audit/runtime_invariants_enterprise.rego`, `rules/p03_orchestrator_innovations_v9.rego`, `rules/temporal.rego` (P1627–P1632), `rules/provenance.rego` (wersje V1 §9.3), `tools/hardcoded_audit_gate.py`, `final_verdict_enforced` w `main_jdg.rego`.

---

*Wygenerowano przez NexusAI ADR Engine v8.3 — 2026-08-08 (P03 GLM52 Orkiestrator)*
*ADR-022 dodany na podstawie raport_enterprise_P03.txt (Orkiestrator + Infrastruktura Reguł)*
*ADR-016..021 dodane na podstawie WIZJA_OPA_ENTERPRISE_V2.md §1.1 (V2 filary F1–F6)*
*ADR-009..014 dodane na podstawie RAPORT_P25_JDG_DOCS_FINAL_AUDIT_v7.0 (R7)*
*ADR-015 dodany na podstawie RAPORT_P26_JDG_MISSING_REGO_FILES_v7.0 (R12)*
