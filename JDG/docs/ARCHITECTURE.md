# 🏗️ JDG Architecture Decision Records (ADR)

> **Status:** ENTERPRISE v3.0 | **Data:** 2026-07-13

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

---

## ADR-002: Zero Hardcoded Values

**Decyzja:** Żadna wartość liczbowa (stawka, próg, limit, data) nie jest zakodowana bezpośrednio w regułach Rego. Wszystko przez `data.thresholds.*`.

**Uzasadnienie:**
- Zmiany prawne (np. nowa stawka VAT, zmiana progów) wymagają tylko aktualizacji thresholdów, nie kodu Rego
- Hot-reload przez OPA Data API bez redeployu
- Ułatwia testowanie — testy mogą podstawiać różne wartości thresholdów

**Aktualny status:** ⚠️ Częściowo wdrożone. Wykryto ~265 zakodowanych wartości w 32 plikach. Migracja w toku (Faza C2).

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

---

## ADR-004: Standardowy Werdykt 25-Polowy

**Decyzja:** Każda reguła zwraca ustandaryzowany obiekt z 25 polami, nawet jeśli większość jest pusta.

**Uzasadnienie:**
- Ułatwia merge werdyktów z wielu pakietów (Multi-Pass)
- `safe_merge` w `main_jdg.rego` łączy werdykty bez utraty danych
- Klient może polegać na stałej strukturze JSON

**Pola obowiązkowe:**
`matched`, `rule_id`, `package`, `priority`, `vat_rate`, `rounding_level`, `gtu_code`, `procedure`, `vat_exemption`, `pit_form`, `pit_rate`, `pit_bracket`, `pit_annual_return_type`, `kus_qualification`, `kus_percent`, `zus_social_base_type`, `zus_health_rate`, `business_status`, `ceidg_registration_required`, `_routing`, `_routing_reason`, `_legal_basis`, `_warnings`

---

## ADR-005: Dual-Layer Architecture (Horyzont 2027+)

**Decyzja:** Długoterminowa architektura dwuwarstwowa:
- **Warstwa 1 (Macro):** ~500 reguł biznesowych/decyzyjnych (P-ID) — agregują Micro
- **Warstwa 2 (Micro):** ~7000 reguł atomowych/prawnych (`jdg.*`) — pojedyncze warunki logiczne

**Uzasadnienie:**
- Obecna architektura (633 reguł Macro) jest wystarczająca dla pokrycia biznesowego
- Dekompozycja na Micro umożliwia pełne pokrycie prawne (każdy artykuł → 8-15 reguł)
- Separacja pozwala na niezależną ewolucję obu warstw

**Status:** Plan strategiczny w `Plan OPA/41_JDG_MEGA_MATRIX_7000_RULES.md`. Nie rozpoczynaj implementacji Micro przed 2027.

---

## ADR-006: Immutable Audit Trail

**Decyzja:** Krytyczne werdykty (ZUS, zdrowotna) są oznaczane `immutable_verdict: true` i podpisywane HMAC-SHA256.

**Uzasadnienie:**
- Werdykty ZUS i zdrowotne mają bezpośredni wpływ finansowy
- Immutowalność zapobiega manipulacji post-factum
- Merkle Tree umożliwia weryfikację integralności całego łańcucha decyzji

**Implementacja:** `nexus_ai/tax/immutable_audit.py` + pole `immutable_verdict` w Rego

---

## ADR-007: Multi-Pass Evaluation (PAS)

**Decyzja:** Ewaluacja OPA odbywa się w wielu przebiegach (Multi-Pass), gdzie każdy przebieg (PAS) ocenia inną domenę.

**Kolejność PAS:**
1. **PAS 1:** Risk & Fraud (P0-P9) — blokada przy fraudzie
2. **PAS 2:** Routing & Confidence (P10-P19) — kierowanie do triage
3. **PAS 3:** Cross-border (P40-P49) — procedury transgraniczne
4. **PAS 4:** VAT (P50-P140) — stawki, zwolnienia, GTU
5. **PAS 5:** PIT (P500-P599) — formy, KUP, zaliczki
6. **PAS 6:** Allowances (P600-P635) — ulgi podatkowe
7. **PAS 7:** ZUS (P700-P1206) — składki, zasiłki
8. **PAS 8:** Accounting (P800-P870) — metody księgowe
9. **PAS 9:** Fallback (P1000+) — domyślne stawki

**Uzasadnienie:** Różne domeny są niezależne, ale niektóre zależą od wyników wcześniejszych (np. KUP zależy od stawki VAT). Multi-Pass umożliwia równoległą ewaluację niezależnych domen.

---

## ADR-008: Konwencja Nazewnicza Rule ID

**Format:** `jdg.<domena>.<kategoria>_<szczegół>`

**Przykłady:**
- `jdg.vat.substantive.fuel_pl` — VAT, stawka dla paliwa w PL
- `jdg.kks.empty_invoice_issued` — KKS, wystawienie pustej faktury
- `jdg.zus.health_linear` — ZUS, składka zdrowotna liniowy
- `jdg.edge_cases.vat_breach_mid_year` — Edge case, przekroczenie limitu VAT

---

*Wygenerowano przez NexusAI ADR Engine v1.0 — 2026-07-13*
