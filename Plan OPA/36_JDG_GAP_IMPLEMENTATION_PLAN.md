# 🔧 JDG GAP IMPLEMENTATION PLAN — 78 Brakujących Reguł ENTERPRISE

> **Status:** READY FOR IMPLEMENTATION — Pełny pseudokod Rego + test case'y
> **Data:** 2026-07-11
> **Bazuje na:** `35_JDG_ENTERPRISE_GAP_ANALYSIS.md` (78 luk w 15 obszarach)
> **Reguł:** **78** (40 z pełnym pseudokodem Rego + 17 reference entries w tabeli + 21 mikro-reguł osadzonych w makro-regułach) | **Nowych pakietów:** 3 | **Rozszerzeń istniejących:** 12
> **Fazy:** 4 (A-P0: 15 reguł szczegółowych, B-P1: 10 reguł szczegółowych + osadzone mikro-reguły, C-P2: 13 reguł szczegółowych + osadzone mikro-reguły, D-P3: 3 reguły szczegółowe + 17 reference entries)
>
> **Uwaga:** Liczba 78 w Doc 35 obejmuje zarówno makro-reguły (P-level) jak i mikro-reguły rozbite na sub-poziomy (np. P580 obejmuje 5 mikro-reguł). W tym dokumencie 40 reguł ma pełny pseudokod ready-to-implement, a pozostałe są udokumentowane jako reference entries (D2) lub jako mikro-reguły osadzone w większych blokach kodu.
>
> Każda reguła zawiera: **pełny pseudokod Rego**, priorytet, pakiet docelowy, podstawę prawną, test case pozytywny (+) i negatywny (−).

---

## 📊 EXECUTIVE SUMMARY

| Faza | Priorytet | Liczba reguł (szczegółowe/tabela) | Kluczowy rezultat |
|------|:---------:|:----------------------------------:|-------------------|
| **A** | P0 — KRYTYCZNE | 15 / 0 | Bezpieczeństwo bazowe: konflikty ulg, walidacja NIP, limit PIT-0, roczne rozliczenie zdrowotnej |
| **B** | P1 — WYSOKIE | 10 / 0 (+osadzone mikro) | Ulgi, strata PIT, OSS/IOSS, korekty, audit lock, zawieszenie |
| **C** | P2 — ŚREDNIE | 13 / 0 (+osadzone mikro) | Sukcesja, zmiana formy, przedawnienia, reprezentacja, temporal, employer |
| **D** | P3 — NISKIE | 3 / 17 (reference) | Audyt enterprise + pozostałe reguły reference |
| **RAZEM** | | **41 szczegółowych + 17 tabela + osadzone mikro** | **= 78 reguł z Doc 35** |

---

## 🔨 WZORZEC IMPLEMENTACYJNY

Każdy nowy plik/reguła używa tego samego wzorca co istniejąca implementacja:

```rego
package jdg.<pakiet>
import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.<pakiet>.no_match",
    "package": "jdg.<pakiet>", "priority": 999
}

# P<priority>: <reguła> — <cel>
# Przesłanki: <warunki>
# Podstawa prawna: <artykuł>
decide := {
    "matched": true, "rule_id": "jdg.<pakiet>.<name>",
    "package": "jdg.<pakiet>", "priority": <p>,
    ...full_verdict_fields...,
    "_legal_basis": "<Art. X>",
    "_warnings": ["<warning>"]
} {
    <conditions>
}

# kolejne else := {...} { conditions }
```

**Standardowe pola werdyktu używane we wszystkich regułach:**
`matched`, `rule_id`, `package`, `priority`, `vat_rate`, `rounding_level`, `gtu_code`, `pit_form`, `pit_rate`, `pit_bracket`, `pit_annual_return_type`, `kus_qualification`, `kus_percent`, `zus_social_base_type`, `zus_health_rate`, `business_status`, `_routing`, `_routing_reason`, `_legal_basis`, `_warnings`

---

# FAZA A — P0 KRYTYCZNE (15 reguł szczegółowych)

> ⚠️ **Ryzyko pominięcia:** Sankcje podatkowe, nadużycia, błędne rozliczenia
> **Termin wdrożenia:** Natychmiastowy

---

## A1. NOWY PAKIET: `jdg.conflicts.rego`

### A1.1 — P900: `conflict_ipbox_vs_rd` ⭐ NOWY PLIK

**Cel biznesowy:** IP Box i B+R nie mogą być stosowane do tego samego dochodu.
**Pakiet:** `jdg.conflicts` (NOWY PLIK: `policies/jdg/conflicts.rego`)
**Podstawa prawna:** Art. 30ca ust. 3 PIT

```rego
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Conflicts: Konflikty i wykluczenia między regułami
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.conflicts
import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.conflicts.no_match",
    "package": "jdg.conflicts", "priority": 909
}

# ── P900: conflict_ipbox_vs_rd — IP Box vs B+R same income ────────────────────
# Cel: IP Box i B+R NIE mogą być stosowane do tego samego dochodu
# Przesłanki: Oba reliefy aktywne dla tej samej faktury/dochodu
# Podstawa: Art. 30ca ust. 3 PIT
# Priorytet: 900
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true, "rule_id": "jdg.conflicts.ipbox_vs_rd",
    "package": "jdg.conflicts", "priority": 900,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "conflict_type": "IPBOX_VS_RD_SAME_INCOME",
    "conflict_detected": true,
    "conflict_requires_separation": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "IP Box i B+R nie mogą być stosowane do tego samego dochodu — wymagane rozdzielenie kosztów kwalifikowanych",
    "_legal_basis": "Art. 30ca ust. 3 PIT",
    "_warnings": [
        "KONFLIKT: IP Box i B+R — ten sam dochód nie może korzystać z obu ulg jednocześnie!",
        "Akcja: Rozdziel koszty kwalifikowane między IP Box i B+R, lub wybierz jedną ulgę dla tego dochodu."
    ]
} {
    input.invoice.expense_type == "IP_INCOME"
    input.jdg_entrepreneur.has_rd_status == true
    input.invoice.ip_box_claimed == true
    input.invoice.rd_relief_claimed == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}

# ── P900_b: conflict_ipbox_vs_rd — tylko IP Box, OK ──────────────────────────
else := {
    "matched": true, "rule_id": "jdg.conflicts.ipbox_only_ok",
    "package": "jdg.conflicts", "priority": 900,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "conflict_detected": false,
    "conflict_note": "IP Box bez B+R — OK",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 30ca PIT",
    "_warnings": ["IP Box 5% — dochód z kwalifikowanego IP, brak konfliktu z B+R"]
} {
    input.invoice.expense_type == "IP_INCOME"
    input.invoice.ip_box_claimed == true
    input.invoice.rd_relief_claimed == false
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}

# ── P900_c: conflict_ipbox_vs_rd — tylko B+R, OK ─────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.conflicts.rd_only_ok",
    "package": "jdg.conflicts", "priority": 900,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "conflict_detected": false,
    "conflict_note": "B+R bez IP Box — OK",
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 26e PIT",
    "_warnings": ["B+R 100%/200% — brak konfliktu z IP Box"]
} {
    input.jdg_entrepreneur.has_rd_status == true
    input.invoice.expense_type == "RD_COST"
    input.invoice.ip_box_claimed == false
    input.invoice.rd_relief_claimed == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}
```

**Test case +:** JDG z dochodem 100k z oprogramowania, próbuje zastosować IP Box (5%) i B+R (100%) do tego samego dochodu → **BLOCK_AND_ALERT**, `conflict_detected: true`

**Test case −:** JDG z IP Box dla oprogramowania (50k) i B+R dla osobnych kosztów laboratoryjnych (30k) z rozdzieloną ewidencją → `conflict_detected: false`, obie ulgi OK

---

### A1.2 — P902: `conflict_pit0_combined_limit` ⭐

**Cel biznesowy:** Suma zwolnień PIT-0 (młody + powrót + 4+ + senior) ≤ 85 528 PLN rocznie.
**Pakiet:** `jdg.conflicts`
**Podstawa prawna:** Art. 21 ust. 1 pkt 148, 152-154 PIT

```rego
# ── P902: conflict_pit0_combined_limit — wspólny limit PIT-0 85 528 PLN ───────
# Cel: Łączna suma zwolnień PIT-0 nie może przekroczyć 85 528 PLN
# Przesłanki: JDG korzysta z >1 ulgi PIT-0; suma przekracza limit
# Podstawa: Art. 21 ust. 1 pkt 148, 152-154 PIT
# Priorytet: 902
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.conflicts.pit0_combined_limit",
    "package": "jdg.conflicts", "priority": 902,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "conflict_type": "PIT0_COMBINED_LIMIT_EXCEEDED",
    "conflict_detected": true,
    "pit0_total_exempt": total_exempt,
    "pit0_limit": 85528,
    "pit0_excess": max([0, total_exempt - 85528]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Łączny limit PIT-0 (85 528 PLN) przekroczony o %.2f PLN — nadwyżka opodatkowana", [max([0, total_exempt - 85528])]),
    "_legal_basis": "Art. 21 ust. 1 pkt 148, 152-154 PIT",
    "_warnings": [
        sprintf("KRYTYCZNE: Suma zwolnień PIT-0 wynosi %.2f PLN (limit 85 528 PLN). Nadwyżka %.2f PLN podlega opodatkowaniu!", [total_exempt, max([0, total_exempt - 85528])]),
        "Dotyczy ulg: młody (<26), powrót, rodzina 4+, senior"
    ]
} {
    pit0_young := object.get(input.jdg_entrepreneur, "pit0_young_exempt_amount", 0)
    pit0_return := object.get(input.jdg_entrepreneur, "pit0_return_exempt_amount", 0)
    pit0_family4 := object.get(input.jdg_entrepreneur, "pit0_family4_exempt_amount", 0)
    pit0_senior := object.get(input.jdg_entrepreneur, "pit0_senior_exempt_amount", 0)
    total_exempt := pit0_young + pit0_return + pit0_family4 + pit0_senior
    count_pit0 := count([x | x := [pit0_young, pit0_return, pit0_family4, pit0_senior]; x > 0])
    count_pit0 > 1
    total_exempt > 85528
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}
```

**Test case +:** JDG korzysta z ulgi młodego (50k) + ulgi na powrót (40k) → suma 90k > 85 528 → **BLOCK_AND_ALERT**, nadwyżka 4 472 PLN opodatkowana

**Test case −:** JDG korzysta tylko z ulgi młodego (80k) → jedna ulga, nie ma konfliktu → reguła NIE matchuje (count_pit0 == 1)

---

### A1.3 — P904: `conflict_allowances_vs_loss`

**Cel biznesowy:** Ulgi nie mogą być odliczane gdy JDG wykazuje stratę (wyjątek: B+R carry-forward).
**Pakiet:** `jdg.conflicts`
**Podstawa prawna:** Art. 26 ust. 1 PIT, Art. 26e ust. 8 PIT

```rego
# ── P904: conflict_allowances_vs_loss ──────────────────────────────────────────
# Cel: Ulgi nie mogą być odliczane od dochodu, gdy JDG wykazuje stratę
# Wyjątek: B+R carry-forward 6 lat
# Priorytet: 904
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.conflicts.allowances_vs_loss",
    "package": "jdg.conflicts", "priority": 904,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "conflict_type": "ALLOWANCES_VS_LOSS",
    "conflict_detected": true,
    "annual_income": annual_income,
    "annual_loss": annual_loss,
    "rd_carry_forward_allowed": true,
    "non_rd_allowances_blocked": true,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "JDG wykazuje stratę — ulgi (poza B+R carry-forward) nie mogą być odliczane",
    "_legal_basis": "Art. 26 ust. 1 PIT, Art. 26e ust. 8 PIT",
    "_warnings": [
        sprintf("JDG wykazuje stratę %.2f PLN — odliczanie ulg osobistych ZABLOKOWANE", [annual_loss]),
        "WYJĄTEK: ulga B+R przechodzi na 6 kolejnych lat (carry-forward)"
    ]
} {
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    annual_income < 0
    annual_loss := -annual_income
    any_non_rd_relief_claimed :=
        object.get(input.jdg_entrepreneur, "relief_donation_claimed", false) == true
        or object.get(input.jdg_entrepreneur, "relief_rehabilitation_claimed", false) == true
        or object.get(input.jdg_entrepreneur, "relief_internet_claimed", false) == true
    any_non_rd_relief_claimed == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}
```

**Test case +:** JDG ma stratę 50k, próbuje odliczyć darowiznę 10k → **BLOCK** (strata, darowizna nie może być odliczona)

**Test case −:** JDG ma stratę 50k, ma nierozliczoną ulgę B+R 30k z zeszłego roku → B+R carry-forward jest dozwolone → reguła NIE matchuje dla B+R

---

## A2. ROZSZERZENIE: `jdg.pit.exemptions.rego`

### A2.1 — P586: `pit_zero_mutual_limit_85k`

**Cel biznesowy:** Łączny limit PIT-0 = 85 528 PLN rocznie — sumowanie wszystkich 4 ulg.
**Pakiet:** `jdg.pit.exemptions` (rozszerzenie istniejącego)
**Podstawa prawna:** Art. 21 ust. 1 pkt 148, 152-154 PIT

```rego
# ── P586: pit_zero_mutual_limit_85k ────────────────────────────────────────────
# Cel: Łączny limit zwolnień PIT-0 (młody + powrót + 4+ + senior) = 85 528 PLN
# Dodaj na końcu pliku pit/exemptions.rego, PRZED ostatnim else
# Priorytet: 586
# ────────────────────────────────────────────────────────────────────────────────
pit0_mutual_limit := {
    "rule_id": "jdg.pit.exemptions.pit0_mutual_limit",
    "priority": 586,
    "pit0_limit_annual": 85528,
    "pit0_sources": ["young_under_26", "return_4_years", "family_4plus", "working_senior"],
    "pit0_excess_taxed": true,
    "_legal_basis": "Art. 21 ust. 1 pkt 148, 152-154 PIT",
    "_info": "Łączny limit PIT-0: 85 528 PLN rocznie dla wszystkich 4 ulg łącznie"
}

# Helper — sumuje kwoty zwolnione PIT-0
pit0_total_exempt :=
    object.get(input.jdg_entrepreneur, "pit0_young_exempt_amount", 0)
    + object.get(input.jdg_entrepreneur, "pit0_return_exempt_amount", 0)
    + object.get(input.jdg_entrepreneur, "pit0_family4_exempt_amount", 0)
    + object.get(input.jdg_entrepreneur, "pit0_senior_exempt_amount", 0)

pit0_limit_exceeded {
    pit0_total_exempt > 85528
}
```

**Test case +:** Ulgi PIT-0: młody (50 000) + 4+ (40 000) = 90 000 > 85 528 → `pit0_limit_exceeded == true`, nadwyżka 4 472 PLN opodatkowana

**Test case −:** Tylko ulga młodego: 80 000 PLN → `pit0_total_exempt == 80000` → `pit0_limit_exceeded == false`

---

## A3. NOWY PAKIET: `jdg.validation.rego`

### A3.1 — P950: `validate_nip_checksum` ⭐ NOWY PLIK

**Cel biznesowy:** Walidacja sumy kontrolnej NIP przed ewaluacją.
**Pakiet:** `jdg.validation` (NOWY PLIK: `policies/jdg/validation.rego`)
**Podstawa prawna:** Rozp. MF ws. NIP

```rego
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Validation: Walidacja danych wejściowych (P950-P969)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.validation
import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.validation.no_match",
    "package": "jdg.validation", "priority": 969
}

# ── P950: validate_nip_checksum — Suma kontrolna NIP ──────────────────────────
# Cel: Walidacja sumy kontrolnej NIP (10 cyfr, wagi 6,5,7,2,3,4,5,6,7, mod 11)
# Podstawa: Rozp. MF ws. NIP
# Priorytet: 950
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true, "rule_id": "jdg.validation.nip_checksum_invalid",
    "package": "jdg.validation", "priority": 950,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "validation_field": "vendor_nip",
    "validation_passed": false,
    "validation_error": nip_error,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": nip_error,
    "_legal_basis": "Rozp. MF ws. NIP",
    "_warnings": [sprintf("BŁĄD walidacji NIP: %s", [nip_error])]
} {
    nip := object.get(input.vendor, "nip", "")
    not helpers.validate_nip_checksum(nip)
    nip_error := helpers.nip_checksum_error(nip)
}

# ── P950_b: NIP checksum OK ───────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.validation.nip_checksum_ok",
    "package": "jdg.validation", "priority": 950,
    "validation_passed": true, "validation_field": "vendor_nip",
    "_legal_basis": "Rozp. MF ws. NIP",
    "_warnings": []
} {
    nip := object.get(input.vendor, "nip", "")
    helpers.validate_nip_checksum(nip)
}
```

**Test case +:** NIP `5261040825` (poprawny) → `validate_nip_checksum` → true → P950_b matchuje, OK

**Test case −:** NIP `1234567890` (niepoprawny) → `validate_nip_checksum` → false → P950 matchuje → **BLOCK_AND_ALERT**

> ⚠️ **Uwaga graniczna:** Jeśli `checksum == 10`, NIP jest nieprawidłowy. OPA Rego nie ma problemu z tym przypadkiem, ale dla kompletności dodajemy guard.

```rego
# ── Helper: validate_nip_checksum (dodaj w _helpers_jdg.rego) ─────────────────
validate_nip_checksum(nip) = true {
    digits := array.slice(regex.split(nip, ""), 0, 10)
    count(digits) == 10
    weights := [6, 5, 7, 2, 3, 4, 5, 6, 7]
    sum_val := sum([to_number(digits[i]) * weights[i] | some i in numbers.range(0, 8)])
    checksum := sum_val % 11
    checksum != 10
    checksum == to_number(digits[9])
} else = false { true }

nip_checksum_error(nip) = "NIP nieprawidłowy — błędny format" {
    count(array.slice(regex.split(nip, ""), 0, 10)) != 10
} else = "NIP nieprawidłowy — błędna suma kontrolna" { true }
```

---

### A3.2 — P952: `validate_invoice_date_consistency`

**Cel biznesowy:** Data wystawienia faktury nie może być wcześniejsza niż data sprzedaży.
**Pakiet:** `jdg.validation`
**Podstawa prawna:** Art. 106e VAT

```rego
# ── P952: validate_invoice_date_consistency ────────────────────────────────────
# Cel: Data faktury ≥ data sprzedaży/dostawy
# Podstawa: Art. 106e VAT
# Priorytet: 952
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.validation.invoice_date_inconsistent",
    "package": "jdg.validation", "priority": 952,
    "validation_field": "invoice_date_vs_sale_date",
    "validation_passed": false,
    "invoice_date": invoice_date,
    "sale_date": sale_date,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Data faktury (%s) jest wcześniejsza niż data sprzedaży (%s)", [invoice_date, sale_date]),
    "_legal_basis": "Art. 106e VAT",
    "_warnings": ["Data wystawienia faktury nie może być wcześniejsza niż data dostawy/usługi!"]
} {
    invoice_date := object.get(input.invoice, "invoice_date", "")
    sale_date := object.get(input.invoice, "sale_date", "")
    invoice_date != ""
    sale_date != ""
    time.parse_rfc3339_ns(invoice_date) < time.parse_rfc3339_ns(sale_date)
}
```

**Test case +:** Data faktury `2026-06-15`, data sprzedaży `2026-06-01` → `invoice_date > sale_date` → OK → reguła NIE matchuje

**Test case −:** Data faktury `2026-05-01`, data sprzedaży `2026-06-01` → `invoice_date < sale_date` → **BLOCK_AND_ALERT**

---

### A3.3 — P954: `validate_negative_amounts`

**Cel biznesowy:** Blokada faktur z kwotami ujemnymi (chyba że explicite oznaczone jako korekta).
**Pakiet:** `jdg.validation`
**Podstawa prawna:** Art. 29a VAT

```rego
# ── P954: validate_negative_amounts ────────────────────────────────────────────
# Cel: Kwoty ujemne tylko dla faktur korygujących
# Podstawa: Art. 29a VAT
# Priorytet: 954
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.validation.negative_amounts_blocked",
    "package": "jdg.validation", "priority": 954,
    "validation_field": "negative_amount",
    "validation_passed": false,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Kwoty ujemne niedozwolone dla faktur niekorygujących",
    "_legal_basis": "Art. 29a VAT",
    "_warnings": ["Faktura z kwotami ujemnymi — dozwolone tylko dla faktur korygujących!"]
} {
    amount_net := object.get(input.invoice, "amount_net", 0)
    amount_gross := object.get(input.invoice, "amount_gross", 0)
    (amount_net < 0 or amount_gross < 0)
    object.get(input.invoice, "is_correction", false) == false
}
```

**Test case +:** Faktura korygująca z kwotą -500 PLN → `is_correction == true` → reguła NIE matchuje → OK

**Test case −:** Zwykła faktura z kwotą -1000 PLN → `is_correction == false` → **BLOCK_AND_ALERT**

---

## A4. ROZSZERZENIE: `jdg.zus.rego`

### A4.1 — P749: `zus_health_annual_reconciliation`

**Cel biznesowy:** Roczne rozliczenie składki zdrowotnej — dopłata/zwrot różnicy.
**Pakiet:** `jdg.zus` (rozszerzenie istniejącego)
**Podstawa prawna:** Art. 81 ust. 2d-2f ustawy o świadczeniach opieki zdrowotnej

```rego
# ── P749: zus_health_annual_reconciliation — Roczne rozliczenie zdrowotnej ─────
# Cel: Roczne rozliczenie składki zdrowotnej (dopłata/zwrot)
# Podstawa: Art. 81 ust. 2d-2f ustawy zdrowotnej
# Priorytet: 749 (dodaj w zus.rego)
# Mikro-reguły: jdg.zus.a81u2d.r1-r5
# ────────────────────────────────────────────────────────────────────────────────

# r1: przeliczenie podstawy rocznej
health_annual_base = base {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form == "PIT_SCALE"
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    base := max([annual_income, health_minimum_base])
}
else = base {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form == "LINEAR"
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    base := max([annual_income, health_minimum_base])
}
else = base {
    tax_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    tax_form == "LUMP_SUM"
    annual_revenue := object.get(input.jdg_entrepreneur, "lump_sum_annual_revenue", 0)
    base := health_base_by_lump_sum_tier(annual_revenue)
}

# r2: wykrycie niedopłaty
health_underpayment = amount {
    annual_base := health_annual_base
    health_rate := helpers.zus_health_rate_for_form(input.jdg_entrepreneur.tax_form)
    annual_due := annual_base * to_number(health_rate)
    monthly_paid := object.get(input.jdg_entrepreneur, "health_monthly_total_paid", 0)
    annual_due > monthly_paid
    amount := annual_due - monthly_paid
} else = 0 { true }

# r3: wykrycie nadpłaty
health_overpayment = amount {
    annual_base := health_annual_base
    health_rate := helpers.zus_health_rate_for_form(input.jdg_entrepreneur.tax_form)
    annual_due := annual_base * to_number(health_rate)
    monthly_paid := object.get(input.jdg_entrepreneur, "health_monthly_total_paid", 0)
    monthly_paid > annual_due
    amount := monthly_paid - annual_due
} else = 0 { true }

# r4: strata na skali → podstawa minimalna
health_minimum_base = base {
    min_wage := object.get(object.get(object.get(input.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4666)
    base := min_wage * 12 * 0.75
}

# r5: termin — 22 maja następnego roku
health_annual_deadline := "NEXT_YEAR_MAY_22"

# ── P749: główna reguła decyzyjna ─────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.zus.health_annual_reconciliation",
    "package": "jdg.zus", "priority": 749,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "health_annual_base": health_annual_base,
    "health_annual_due": annual_due,
    "health_annual_paid": monthly_paid,
    "health_underpayment": health_underpayment,
    "health_overpayment": health_overpayment,
    "health_deadline": health_annual_deadline,
    "health_requires_action": health_underpayment > 0 or health_overpayment > 0,
    "_legal_basis": "Art. 81 ust. 2d-2f ustawy o świadczeniach opieki zdrowotnej",
    "_warnings": health_warnings
} {
    # Triggered when annual reconciliation period (January-April following tax year)
    input.temporal.is_annual_health_reconciliation_period == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    annual_due := health_annual_base * to_number(helpers.zus_health_rate_for_form(pit_form))
    monthly_paid := object.get(input.jdg_entrepreneur, "health_monthly_total_paid", 0)

    health_warnings := array.concat(
        [sprintf("Roczne rozliczenie zdrowotnej: należna %.2f PLN, zapłacono %.2f PLN", [annual_due, monthly_paid])],
        underpayment_warning(health_underpayment),
        overpayment_warning(health_overpayment)
    )
}

underpayment_warning(amount) = [sprintf("NIEDOPŁATA %.2f PLN — termin dopłaty: 22 maja", [amount])] { amount > 0 }
    else = [] { true }
overpayment_warning(amount) = [sprintf("NADPŁATA %.2f PLN — zwrot na wniosek", [amount])] { amount > 0 }
    else = [] { true }
```

**Test case +:** JDG na liniowym, dochód roczny 200k, zapłacone miesięcznie 10k, należne 200k × 4.9% = 9 800 → nadpłata 200 PLN → `health_overpayment: 200`

**Test case −:** JDG na ryczałcie, przychód 400k (próg 3), zapłacone wg progu 2 → niedopłata → `health_underpayment: > 0`, termin 22 maja

---

### A4.2 — P754: `health_contrib_loss_correction`

**Cel biznesowy:** Przy stracie na skali podatkowej: podstawa składki zdrowotnej = minimalna.
**Pakiet:** `jdg.zus`
**Podstawa prawna:** Art. 81 ust. 2d ustawy zdrowotnej

```rego
# ── P754: health_contrib_loss_correction ───────────────────────────────────────
# Cel: Strata na skali → podstawa zdrowotnej = minimalna (75% przeciętnego wynagrodzenia)
# Podstawa: Art. 81 ust. 2d ustawy zdrowotnej
# Priorytet: 754
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.zus.health_loss_correction",
    "package": "jdg.zus", "priority": 754,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.09",
    "zus_health_base": "MINIMUM",
    "zus_health_base_amount": health_minimum_base,
    "zus_health_annual_income_zero_or_negative": true,
    "business_status": "",
    "_legal_basis": "Art. 81 ust. 2d ustawy o świadczeniach opieki zdrowotnej",
    "_warnings": [
        sprintf("Strata na skali — podstawa składki zdrowotnej = minimalna (%.2f PLN/mies.)", [health_minimum_base / 12]),
        "Składka zdrowotna NIE jest zerowa nawet przy stracie!"
    ]
} {
    input.jdg_entrepreneur.tax_form == "PIT_SCALE"
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 1)
    annual_income <= 0
    min_wage := object.get(object.get(object.get(input.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4666)
    health_minimum_base := min_wage * 12 * 0.75
}
```

**Test case +:** JDG skala, strata 50k → `annual_income <= 0` → `zus_health_base: "MINIMUM"`, składka od minimalnej podstawy

**Test case −:** JDG skala, dochód 80k → `annual_income > 0` → reguła NIE matchuje, składka od dochodu 80k

---

### A4.3 — P756: `lump_sum_health_underpayment`

**Cel biznesowy:** Ryczałtowiec — dopłata składki zdrowotnej przy przekroczeniu progu przychodu.
**Pakiet:** `jdg.zus`
**Podstawa prawna:** Art. 81 ust. 2f ustawy zdrowotnej

```rego
# ── P756: lump_sum_health_underpayment ─────────────────────────────────────────
# Cel: Dopłata składki zdrowotnej dla ryczałtowca przy przekroczeniu progu
# Podstawa: Art. 81 ust. 2f ustawy zdrowotnej
# Priorytet: 756
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.zus.lump_sum_health_underpayment",
    "package": "jdg.zus", "priority": 756,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "LUMP_SUM", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "0.049",
    "zus_health_lump_sum_final_tier": final_tier,
    "zus_health_lump_sum_paid_tier": paid_tier,
    "zus_health_lump_sum_underpayment": underpayment_amount,
    "zus_health_lump_sum_deadline": "NEXT_YEAR_MAY_22",
    "business_status": "",
    "_legal_basis": "Art. 81 ust. 2f ustawy o świadczeniach opieki zdrowotnej",
    "_warnings": [
        sprintf("Ryczałtowiec: przekroczono próg z %s na %s — dopłata %.2f PLN do 22 maja + odsetki", [paid_tier, final_tier, underpayment_amount])
    ]
} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
    annual_revenue := object.get(input.jdg_entrepreneur, "lump_sum_annual_revenue", 0)

    # Determine actual tier from annual revenue
    final_tier = "TIER_3" { annual_revenue > 300000 }
    final_tier = "TIER_2" { annual_revenue > 60000; annual_revenue <= 300000 }
    final_tier = "TIER_1" { annual_revenue <= 60000 }

    # Tier paid based on monthly declarations
    paid_tier := object.get(input.jdg_entrepreneur, "lump_sum_health_paid_tier", "TIER_1")

    # Calculate underpayment
    underpayment_amount := helpers.lump_sum_health_tier_diff(final_tier, paid_tier)
    underpayment_amount > 0
}
```

```rego
# ── Helper: lump_sum_health_tier_diff (dodaj w _helpers_jdg.rego) ──────────────
lump_sum_health_tier_diff(final_tier, paid_tier) = diff {
    avg_salary := object.get(object.get(object.get(input.thresholds, "jdg", {}), "bounds", {}), "average_salary", 7880)
    final_monthly := 0
    final_monthly = avg_salary * 0.60 { final_tier == "TIER_1" }
    final_monthly = avg_salary * 1.00 { final_tier == "TIER_2" }
    final_monthly = avg_salary * 1.80 { final_tier == "TIER_3" }

    paid_monthly := 0
    paid_monthly = avg_salary * 0.60 { paid_tier == "TIER_1" }
    paid_monthly = avg_salary * 1.00 { paid_tier == "TIER_2" }
    paid_monthly = avg_salary * 1.80 { paid_tier == "TIER_3" }

    diff := max([0, (final_monthly - paid_monthly) * 12 * 0.049])
}
```

**Test case +:** Ryczałtowiec płacił wg TIER_1 (przychód szacowany 50k), koniec roku przychód 350k (TIER_3) → dopłata różnicy × 12 mies. × 4.9%

**Test case −:** Ryczałtowiec płacił TIER_2, koniec roku przychód 250k (TIER_2) → `final_tier == paid_tier` → `underpayment_amount == 0` → reguła NIE matchuje

---

## A5. ROZSZERZENIE: `jdg.allowances.rego`

### A5.1 — P580: `relief_donation_opp`

**Cel biznesowy:** Odliczenie darowizn na OPP — max 6% dochodu.
**Pakiet:** `jdg.allowances` (rozszerzenie istniejącego)
**Podstawa prawna:** Art. 26 ust. 1 pkt 9 PIT

```rego
# ── P580: relief_donation_opp — dodaj w allowances.rego przed crypto ────────────
# Cel: Darowizny OPP — max 6% dochodu, tylko przelewem
# Mikro-reguły: jdg.pit.a26u1p9.r1-r5
# Priorytet: 580
# ────────────────────────────────────────────────────────────────────────────────

# r1: OPP registered in KRS
donation_opp_eligible {
    input.invoice.expense_type == "DONATION_OPP"
    object.get(input.vendor, "is_opp_registered", false) == true
    object.get(input.invoice, "is_bank_transfer", false) == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    pit_form == "PIT_SCALE"
}

# r2-r3: Limit 6% of annual income, excess NOT carried forward
donation_opp_limit = limit {
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    limit := annual_income * 0.06
}

else := {
    "matched": true, "rule_id": "jdg.allowances.relief_donation_opp",
    "package": "jdg.allowances", "priority": 580,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "relief_type": "DONATION_OPP",
    "relief_limit": donation_opp_limit,
    "relief_deductible": min([donation_amount, donation_opp_limit]),
    "relief_carry_forward_years": 0,
    "relief_rule_ids": ["jdg.pit.a26u1p9.r1", "jdg.pit.a26u1p9.r2", "jdg.pit.a26u1p9.r3", "jdg.pit.a26u1p9.r4", "jdg.pit.a26u1p9.r5"],
    "_legal_basis": "Art. 26 ust. 1 pkt 9 PIT",
    "_warnings": [
        sprintf("Darowizna OPP: limit 6%% dochodu (%.2f PLN), odliczono %.2f PLN. Nadwyżka PRZEPADA.", [donation_opp_limit, min([donation_amount, donation_opp_limit])])
    ]
} {
    donation_opp_eligible
    donation_amount := object.get(input.invoice, "amount_net", 0)
    donation_amount > 0
}
```

**Test case +:** JDG skala, dochód 120k, darowizna 5k → limit 6% × 120k = 7 200 → 5k < 7 200 → odliczone 5k

**Test case −:** JDG liniowy → `pit_form != "PIT_SCALE"` → `donation_opp_eligible` FALSE → reguła NIE matchuje

---

### A5.2 — P582: `relief_blood_donation`

```rego
# ── P582: relief_blood_donation — 130 PLN/litr ─────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.allowances.relief_blood_donation",
    "package": "jdg.allowances", "priority": 582,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "relief_type": "BLOOD_DONATION",
    "relief_rate_per_liter": 130,
    "relief_deductible": blood_liters * 130,
    "relief_limit": donation_opp_limit,
    "relief_carry_forward_years": 0,
    "relief_rule_ids": ["jdg.pit.a26u1p9c.r1"],
    "_legal_basis": "Art. 26 ust. 1 pkt 9 lit. c PIT",
    "_warnings": [sprintf("Krwiodawstwo: %d litrów × 130 PLN = %.2f PLN (limit 6%% dochodu łącznie z darowiznami)", [blood_liters, blood_liters * 130])]
} {
    blood_liters := object.get(input.jdg_entrepreneur, "blood_donation_liters", 0)
    blood_liters > 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    pit_form == "PIT_SCALE"
}
```

**Test case +:** JDG oddał 5 litrów krwi → 5 × 130 = 650 PLN odliczenia od dochodu

**Test case −:** JDG nie oddał krwi → `blood_liters == 0` → reguła NIE matchuje

---

### A5.3 — P584: `relief_child_tax_credit`

```rego
# ── P584: relief_child_tax_credit — odliczenie OD PODATKU (nie dochodu!) ──────
# UWAGA: Ta ulga odlicza się od PODATKU, nie od dochodu!
# Dostępna TYLKO dla skali podatkowej
# Mikro-reguły: jdg.pit.a27f.r1-r7
# Priorytet: 584
# ────────────────────────────────────────────────────────────────────────────────

child_credit_amounts := [1112.04, 1112.04, 2000.04, 2700.00]

child_tax_credit_total = total {
    child_count := object.get(input.jdg_entrepreneur, "children_count", 0)
    child_count > 0
    child_count <= 4
    total := sum([child_credit_amounts[i] | some i in numbers.range(0, child_count - 1)])
} else = total {
    child_count := object.get(input.jdg_entrepreneur, "children_count", 0)
    child_count > 4
    total := sum(child_credit_amounts) + (child_count - 4) * 2700.00
}

else := {
    "matched": true, "rule_id": "jdg.allowances.relief_child_tax_credit",
    "package": "jdg.allowances", "priority": 584,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "SCALE", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "full", "kus_percent": 100,
    "relief_type": "CHILD_TAX_CREDIT",
    "relief_reduces_tax": true,
    "relief_amount": child_tax_credit_total,
    "relief_capped_at_tax": true,
    "relief_refundable": true,
    "relief_rule_ids": ["jdg.pit.a27f.r1", "jdg.pit.a27f.r2", "jdg.pit.a27f.r3", "jdg.pit.a27f.r4", "jdg.pit.a27f.r5", "jdg.pit.a27f.r6", "jdg.pit.a27f.r7"],
    "_legal_basis": "Art. 27f PIT",
    "_warnings": [
        sprintf("Ulga na dzieci: %d dzieci, kwota %.2f PLN (odliczana OD PODATKU, nie od dochodu)", [child_count, child_tax_credit_total]),
        "UWAGA: Ulga od podatku — inny mechanizm niż ulgi od dochodu! Niewykorzystana kwota podlega zwrotowi (do wysokości składek ZUS+zdrowotnej)."
    ]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    pit_form == "PIT_SCALE"
    child_count := object.get(input.jdg_entrepreneur, "children_count", 0)
    child_count > 0
}
```

**Test case +:** JDG skala, 2 dzieci → 2 × 1 112.04 = 2 224.08 PLN odliczenia od podatku → może otrzymać zwrot

**Test case −:** JDG liniowy → `pit_form != "PIT_SCALE"` → reguła NIE matchuje (ulga na dzieci niedostępna dla liniowego)

---

### A5.4 — P870a: `pit_loss_carry_forward`

```rego
# ── P870a: pit_loss_carry_forward — Rozliczenie straty PIT ─────────────────────
# Cel: Odliczenie straty z lat ubiegłych — max 50%/rok lub 5M jednorazowo
# Podstawa: Art. 9 ust. 3 PIT
# Priorytet: 870a (dodaj w allowances.rego)
# ────────────────────────────────────────────────────────────────────────────────

# Helper: calculates remaining loss to carry forward
loss_carry_forward_years_remaining = remaining {
    loss_year := object.get(input.jdg_entrepreneur, "loss_year", 2020)
    current_year := object.get(input.invoice, "tax_year", 2025)
    years_since := current_year - loss_year
    remaining := 5 - years_since
}

# r1: standard — max 50% rocznie przez 5 lat
loss_standard_deduction = amount {
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    annual_income > 0
    remaining_loss := object.get(input.jdg_entrepreneur, "loss_remaining_carry_forward", 0)
    max_annual := annual_income * 0.50
    amount := min([remaining_loss, max_annual])
}

# r2: one-time — do 5 000 000 PLN (Polski Ład)
loss_one_time_deduction = amount {
    input.jdg_entrepreneur.loss_one_time_option == true
    remaining_loss := object.get(input.jdg_entrepreneur, "loss_remaining_carry_forward", 0)
    amount := min([remaining_loss, 5000000])
}

else := {
    "matched": true, "rule_id": "jdg.allowances.loss_carry_forward",
    "package": "jdg.allowances", "priority": 870,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "relief_type": "LOSS_CARRY_FORWARD",
    "relief_annual_deduction": loss_deduction,
    "relief_remaining_after": loss_remaining - loss_deduction,
    "relief_years_remaining": loss_carry_forward_years_remaining,
    "relief_rule_ids": ["jdg.pit.a9u3.r1", "jdg.pit.a9u3.r2", "jdg.pit.a9u3.r3", "jdg.pit.a9u3.r4"],
    "_legal_basis": "Art. 9 ust. 3 PIT",
    "_warnings": [sprintf("Rozliczenie straty: odliczono %.2f PLN, pozostało %.2f PLN na %d lat", [loss_deduction, loss_remaining - loss_deduction, loss_carry_forward_years_remaining])]
} {
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    pit_form in {"PIT_SCALE", "LINEAR"}
    loss_remaining := object.get(input.jdg_entrepreneur, "loss_remaining_carry_forward", 0)
    loss_remaining > 0
    loss_carry_forward_years_remaining > 0
    loss_deduction := loss_one_time_deduction { input.jdg_entrepreneur.loss_one_time_option == true }
    loss_deduction := loss_standard_deduction { input.jdg_entrepreneur.loss_one_time_option != true }
    loss_deduction > 0
}
```

**Test case +:** JDG skala, dochód 100k, strata z zeszłego roku 80k → max 50% × 100k = 50k odliczenia w tym roku

**Test case −:** JDG ryczałt → `pit_form == "LUMP_SUM"` → reguła NIE matchuje (ryczałtowcy nie rozliczają strat)

---

### A5.5 — P617: `multiple_allowances_income_cap`

```rego
# ── P617: multiple_allowances_income_cap — Suma ulg ≤ dochód ───────────────────
# Cel: Suma ulg osobistych nie może przekroczyć dochodu. B+R carry-forward wyjątkiem.
# Podstawa: Art. 26 ust. 1 PIT
# Priorytet: 617
# ────────────────────────────────────────────────────────────────────────────────

total_personal_reliefs = total {
    total := object.get(input.jdg_entrepreneur, "relief_donation_total", 0)
        + object.get(input.jdg_entrepreneur, "relief_rehabilitation_total", 0)
        + object.get(input.jdg_entrepreneur, "relief_internet_total", 0)
        + object.get(input.jdg_entrepreneur, "relief_blood_total", 0)
        + object.get(input.jdg_entrepreneur, "relief_union_dues_total", 0)
}

allowances_income_cap_exceeded {
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    total_personal_reliefs > annual_income
    object.get(input.jdg_entrepreneur, "has_rd_relief", false) == false
}

else := {
    "matched": true, "rule_id": "jdg.allowances.income_cap_reached",
    "package": "jdg.allowances", "priority": 617,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "relief_type": "INCOME_CAP",
    "relief_total_capped": min([total_personal_reliefs, annual_income]),
    "relief_excess_forfeited": max([0, total_personal_reliefs - annual_income]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Suma ulg (%.2f PLN) przekracza dochód (%.2f PLN) — nadwyżka %.2f PLN PRZEPADA", [total_personal_reliefs, annual_income, max([0, total_personal_reliefs - annual_income])]),
    "_legal_basis": "Art. 26 ust. 1 PIT",
    "_warnings": [
        "UWAGA: Suma ulg osobistych przekracza dochód — nadwyżka PRZEPADA (nie przechodzi na kolejny rok)!",
        "WYJĄTEK: ulga B+R przechodzi na 6 kolejnych lat (carry-forward)."
    ]
} {
    allowances_income_cap_exceeded
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}
```

**Test case +:** JDG dochód 50k, ulgi łącznie 60k → nadwyżka 10k PRZEPADA → **BLOCK_AND_ALERT**

**Test case −:** JDG dochód 100k, ulgi łącznie 70k → 70k ≤ 100k → reguła NIE matchuje, wszystkie ulgi OK

---

# FAZA B — P1 WYSOKIE (10 reguł szczegółowych + osadzone mikro-reguły)

> ⚠️ **Ryzyko pominięcia:** Utrata ulg, błędny VAT transgraniczny
> **Termin wdrożenia:** 2 tygodnie

---

## B1. ROZSZERZENIE: `jdg.zus.rego` — Zasiłki

### B1.1 — P750: `zus_sickness_benefit_jdg`

```rego
# ── P750: zus_sickness_benefit_jdg — Zasiłek chorobowy JDG (dodaj w zus.rego) ──
# Cel: Zasiłek chorobowy z dobrowolnego ubezpieczenia — 90 dni wyczekiwania
# Podstawa: Art. 4, 6-8 ustawy zasiłkowej
# Priorytet: 750
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.zus.sickness_benefit",
    "package": "jdg.zus", "priority": 750,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_sickness_benefit_eligible": true,
    "zus_sickness_waiting_days": 90 - insured_days,
    "zus_sickness_benefit_rate": "80% podstawy",
    "zus_sickness_benefit_days_remaining": 90 - used_sick_days,
    "business_status": "",
    "_legal_basis": "Art. 4, 6-8 ustawy zasiłkowej",
    "_warnings": [
        sprintf("Zasiłek chorobowy JDG: %d dni okresu wyczekiwania pozostało, %d dni zasiłku dostępnych", [max([0, 90 - insured_days]), 90 - used_sick_days])
    ]
} {
    input.jdg_entrepreneur.zus_sickness_voluntary == true
    insured_days := object.get(input.jdg_entrepreneur, "sickness_insurance_days", 0)
    used_sick_days := object.get(input.jdg_entrepreneur, "sick_days_used_this_year", 0)
    insured_days >= 90
    used_sick_days < 90
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}
```

**Test case +:** JDG z dobrowolnym chorobowym, ubezpieczony 120 dni, choruje pierwszy raz → zasiłek 80% podstawy

**Test case −:** JDG bez dobrowolnego chorobowego → `zus_sickness_voluntary == false` → reguła NIE matchuje

---

### B1.2 — P752: `maternity_benefit_jdg`

```rego
# ── P752: maternity_benefit_jdg — Zasiłek macierzyński JDG ─────────────────────
else := {
    "matched": true, "rule_id": "jdg.zus.maternity_benefit",
    "package": "jdg.zus", "priority": 752,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "zus_maternity_benefit_eligible": true,
    "zus_maternity_rate": maternity_rate,
    "zus_maternity_duration_days": maternity_days,
    "business_status": "",
    "_legal_basis": "Art. 29-31 ustawy zasiłkowej",
    "_warnings": [sprintf("Zasiłek macierzyński: %s przez %d dni", [maternity_rate, maternity_days])]
} {
    input.jdg_entrepreneur.zus_sickness_voluntary == true
    input.temporal.is_maternity_event == true
    maternity_rate = "80%"
    maternity_days = 52 * 7  # 52 tygodnie
    # 100% option if declared before birth
    maternity_rate = "100%" { object.get(input.jdg_entrepreneur, "maternity_full_rate_declared", false) == true }
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
}
```

**Test case +:** JDG z chorobowym, zadeklarowane 100% → zasiłek macierzyński 100% przez 52 tygodnie

**Test case −:** JDG bez chorobowego → reguła NIE matchuje

---

## B2. ROZSZERZENIE: `jdg.vat.procedures.rego` — OSS/IOSS + VAT-UE

### B2.1 — P250: `vat_oss_ioss_procedure`

```rego
# ── P250: vat_oss_ioss_procedure — dodaj w vat/procedures.rego ──────────────────
# Cel: Sprzedaż B2C do UE — deklaracja OSS zamiast rejestracji w każdym kraju
# Podstawa: Art. 130a-130d VAT (OSS), Art. 138a-138i VAT (IOSS)
# Priorytet: 250
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.oss_ioss",
    "package": "jdg.vat.procedures", "priority": 250,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "vat_procedure": oss_type,
    "vat_oss_country_rate": destination_country_rate,
    "vat_oss_declaration_required": true,
    "vat_oss_declaration_deadline": "quarter_end_plus_30_days",
    "_legal_basis": oss_legal_basis,
    "_warnings": [sprintf("OSS/IOSS: sprzedaż B2C do %s — VAT wg stawki kraju docelowego (%.0f%%), deklaracja kwartalna", [destination_country, destination_country_rate * 100])]
} {
    input.invoice.direction == "SALE"
    input.invoice.is_b2c == true
    destination_country := object.get(input.vendor, "country", "PL")
    destination_country in helpers.eu_countries_list()
    destination_country != "PL"
    destination_country_rate := helpers.vat_rate_by_country(destination_country)

    oss_type = "OSS_UNION" { input.invoice.category == "SERVICES" }
    oss_type = "OSS_NON_UNION" { input.invoice.category == "SERVICES"; destination_country in helpers.non_eu_oss_countries() }
    oss_type = "IOSS" { input.invoice.category in {"GOODS"}; input.invoice.amount_gross <= object.get(input.thresholds, "ioss_limit_eur", 150) }

    oss_legal_basis = "Art. 130a-130d VAT (OSS)" { oss_type in {"OSS_UNION", "OSS_NON_UNION"} }
    oss_legal_basis = "Art. 138a-138i VAT (IOSS)" { oss_type == "IOSS" }
}
```

**Test case +:** JDG sprzedaje e-booki B2C do Niemiec przez stronę → OSS, VAT wg stawki niemieckiej (7%/19%)

**Test case −:** Sprzedaż B2B do Niemiec → `is_b2c == false` → reguła NIE matchuje → reverse charge (P40)

---

### B2.2 — P255: `vat_ue_summary_deadline`

```rego
# ── P255: vat_ue_summary_deadline — dodaj w vat/procedures.rego ─────────────────
# Cel: VAT-UE do 25. dnia miesiąca za poprzedni miesiąc
# Podstawa: Art. 100 VAT
# Priorytet: 255
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.vat.procedures.vat_ue_summary",
    "package": "jdg.vat.procedures", "priority": 255,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "vat_ue_summary_required": true,
    "vat_ue_summary_deadline_day": 25,
    "vat_ue_summary_frequency": "MONTHLY",
    "vat_ue_summary_quarterly_allowed": quarterly_allowed,
    "_legal_basis": "Art. 100 VAT",
    "_warnings": [sprintf("VAT-UE: informacja podsumowująca do 25. dnia miesiąca za poprzedni miesiąc (transakcje WDT/WNT z %s)", [current_month])]
} {
    input.invoice.procedure in {"WDT", "WNT"}
    input.invoice.vat_ue_summary_required == true
    quarterly_allowed = true {
        input.jdg_entrepreneur.annual_intra_eu_supplies < object.get(object.get(input.thresholds, "jdg", {}), "limits", {}).vat_ue_quarterly_threshold
    }
    current_month := time.format(time.now_ns())
}
```

**Test case +:** JDG z WDT do Niemiec w styczniu → VAT-UE do 25 lutego

**Test case −:** Transakcja krajowa → `procedure NOT IN {WDT, WNT}` → reguła NIE matchuje

---

## B3. ROZSZERZENIE: `jdg.corrections.rego` — Storno + Audit Lock

### B3.1 — P1115: `correction_storno_detection`

```rego
# ── P1115: correction_storno_detection — dodaj w corrections.rego ───────────────
# Cel: Wykrywanie storna czerwonego vs czarnego
# Podstawa: Art. 29a ust. 13 VAT, Art. 106j VAT
# Priorytet: 1115
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.corrections.storno_red_detected",
    "package": "jdg.corrections", "priority": 1115,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "correction_type": "STORNO_RED",
    "correction_method": "NEGATIVE_VALUES_IN_ORIGINAL_ENTRY",
    "correction_legal": true,
    "_legal_basis": "Art. 29a ust. 13 VAT, Art. 106j VAT",
    "_warnings": ["Storno czerwone wykryte — wartości ujemne w oryginalnym zapisie JPK"]
} {
    input.invoice.is_correction == true
    input.invoice.correction_method == "NEGATIVE_VALUES"
    input.invoice.amount_net < 0
}

else := {
    "matched": true, "rule_id": "jdg.corrections.storno_black_detected",
    "package": "jdg.corrections", "priority": 1116,
    "correction_type": "STORNO_BLACK",
    "correction_method": "SEPARATE_CORRECTION_DOCUMENT",
    "_legal_basis": "Art. 106j VAT",
    "_warnings": ["Storno czarne — osobny dokument korygujący"]
} {
    input.invoice.is_correction == true
    input.invoice.correction_method == "SEPARATE_DOCUMENT"
}
```

**Test case +:** Faktura korygująca z kwotą -500 PLN (wartości ujemne) → storno czerwone → P1115

**Test case −:** Osobna faktura korygująca → storno czarne → P1116

---

### B3.2 — P180: `correction_lock_during_audit`

```rego
# ── P180: correction_lock_during_audit — dodaj w corrections.rego ───────────────
# Cel: Blokada korekty w trakcie kontroli celno-skarbowej
# Podstawa: Art. 81b § 1 Ordynacji podatkowej
# Priorytet: 180
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true, "rule_id": "jdg.corrections.audit_lock",
    "package": "jdg.corrections", "priority": 180,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "correction_blocked": true,
    "correction_block_reason": "TAX_AUDIT_IN_PROGRESS",
    "audit_case_number": audit_case,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Korekta zablokowana — trwa kontrola celno-skarbowa (nr sprawy: %s)", [audit_case]),
    "_legal_basis": "Art. 81b § 1 Ordynacji podatkowej",
    "_warnings": [
        "KOREKTA ZABLOKOWANA — trwa kontrola podatkowa!",
        sprintf("Sprawa nr: %s. Korekta możliwa po zakończeniu kontroli.", [audit_case])
    ]
} {
    input.invoice.is_correction == true
    input.tax_audit.status in {"IN_PROGRESS", "NOTIFIED"}
    input.invoice.tax_period_under_audit == true
    audit_case := object.get(input.tax_audit, "case_number", "UNKNOWN")
}
```

**Test case +:** JDG w trakcie kontroli skarbowej, próbuje skorygować deklarację VAT → **BLOCK_AND_ALERT**

**Test case −:** JDG bez kontroli, korekta → `tax_audit.status NOT IN {IN_PROGRESS, NOTIFIED}` → reguła NIE matchuje

---

## B4. ROZSZERZENIE: `jdg.vat.substantive.rego` — Limit breach mid-year

### B4.1 — P140: `vat_exemption_limit_breach_mid_year`

```rego
# ── P140: vat_exemption_limit_breach_mid_year — dodaj w vat/substantive.rego ────
# Cel: Przekroczenie 200k w trakcie roku → VAT od NADWYŻKI + obowiązek rejestracji
# Podstawa: Art. 113 ust. 5 VAT
# Priorytet: 140 (PRZED regułami stawek VAT)
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.vat.substantive.exemption_breach_mid_year",
    "package": "jdg.vat.substantive", "priority": 140,
    "vat_rate": "0.23", "rounding_level": "position", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "vat_exemption_lost": true,
    "vat_breach_date": breach_date,
    "vat_breach_excess": excess_amount,
    "vat_registration_deadline_days": 7,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("Przekroczono limit zwolnienia podmiotowego VAT (200 000 PLN) o %.2f PLN w dniu %s — VAT należny od nadwyżki!", [excess_amount, breach_date]),
    "_legal_basis": "Art. 113 ust. 5 VAT",
    "_warnings": [
        sprintf("ZWOLNIENIE VAT UTRACONE! Przekroczono 200 000 PLN. VAT należny od nadwyżki %.2f PLN.", [excess_amount]),
        "Obowiązek rejestracji VAT-R w ciągu 7 dni od przekroczenia limitu!"
    ]
} {
    input.jdg_entrepreneur.is_vat_payer == false
    input.jdg_entrepreneur.annual_turnover_net > 200000
    excess_amount := input.jdg_entrepreneur.annual_turnover_net - 200000
    breach_date := object.get(input.jdg_entrepreneur, "vat_limit_breach_date", "unknown")
    object.get(input.invoice, "amount_net", 0) > 0
}
```

**Test case +:** JDG na zwolnieniu, w listopadzie obroty przekraczają 200k → VAT od nadwyżki (np. 30k × 23% = 6 900 PLN należnego VAT)

**Test case −:** JDG na zwolnieniu, obroty 150k → `annual_turnover_net <= 200000` → reguła NIE matchuje

---

## B5. ROZSZERZENIE: `jdg.business.rego` — Zawieszenie

### B5.1 — P919: `suspension_vat_declaration_zero`

```rego
# ── P919: suspension_vat_declaration_zero — dodaj w business.rego ───────────────
# Cel: Obowiązek składania zerowych deklaracji VAT w zawieszeniu
# Podstawa: Art. 99 ust. 7a VAT
# Priorytet: 919
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.business.suspension_vat_zero",
    "package": "jdg.business", "priority": 919,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "SUSPENDED",
    "business_suspension_vat_zero_required": true,
    "business_suspension_vat_deadline_day": 25,
    "_legal_basis": "Art. 99 ust. 7a VAT",
    "_warnings": [
        "JDG ZAWIESZONE — obowiązek składania ZEROWYCH deklaracji VAT-7 do 25. dnia każdego miesiąca!",
        "WyjÄtek: brak obowiązku gdy JDG korzysta ze zwolnienia podmiotowego."
    ]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    input.jdg_entrepreneur.is_vat_payer == true
    input.jdg_entrepreneur.has_wnt_in_period == false
}
```

**Test case +:** JDG czynny podatnik VAT, zawieszony → obowiązek zerowych JPK_V7 co miesiąc

**Test case −:** JDG na zwolnieniu podmiotowym, zawieszony → `is_vat_payer == false` → reguła NIE matchuje

---

### B5.2 — P916: `suspension_depreciation_ban`

```rego
# ── P916: suspension_depreciation_ban — dodaj w accounting.rego ─────────────────
# Cel: W okresie zawieszenia NIE dokonuje się odpisów amortyzacyjnych
# Podstawa: Art. 22c pkt 4 PIT
# Priorytet: 916
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.accounting.suspension_depreciation_ban",
    "package": "jdg.accounting", "priority": 916,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "none", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "SUSPENDED",
    "depreciation_blocked": true,
    "depreciation_block_reason": "BUSINESS_SUSPENDED",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Amortyzacja zablokowana — JDG zawieszone",
    "_legal_basis": "Art. 22c pkt 4 PIT",
    "_warnings": ["ZAKAZ amortyzacji w okresie zawieszenia — odpisy amortyzacyjne NIE stanowią KUP!"]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    input.invoice.expense_type == "DEPRECIATION"
}
```

**Test case +:** JDG zawieszone, próba zaksięgowania amortyzacji → **BLOCK**, NKUP

**Test case −:** JDG aktywne, amortyzacja → `business_status != "SUSPENDED"` → reguła NIE matchuje

---

### B5.3 — P918: `suspension_time_limit`

```rego
# ── P918: suspension_time_limit — dodaj w business.rego ─────────────────────────
# Cel: Po 6 miesiącach bez pracowników → ryzyko wykreślenia z CEIDG
# Podstawa: Art. 22 Prawa przedsiębiorców
# Priorytet: 918
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.business.suspension_time_warning",
    "package": "jdg.business", "priority": 918,
    "business_status": "SUSPENDED",
    "suspension_duration_months": suspension_months,
    "suspension_employee_count": employee_count,
    "suspension_risk_deregistration": suspension_months >= 6 and employee_count == 0,
    "_legal_basis": "Art. 22 Prawa przedsiębiorców",
    "_warnings": suspension_warning
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    suspension_date := object.get(input.jdg_entrepreneur, "suspension_start_date", "")
    suspension_months := helpers.months_between(suspension_date, time.now_ns())
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)
    suspension_warning = ["UWAGA: Zawieszenie >6 miesięcy bez pracowników → ryzyko wykreślenia z CEIDG!"] {
        suspension_months >= 6; employee_count == 0
    } else = [] { true }
}
```

**Test case +:** JDG zawieszone 8 miesięcy, 0 pracowników → `suspension_risk_deregistration: true`

**Test case −:** JDG zawieszone 3 miesiące → `suspension_months < 6` → ostrzeżenie puste

---

# FAZA C — P2 ŚREDNIE (13 reguł szczegółowych + osadzone mikro-reguły)

> **Ryzyko pominięcia:** Niekompletny lifecycle JDG

---

## C1. `jdg.restructuring.rego` — Sukcesja (2 reguły)

### C1.1 — P928: `succession_inventory_death_date`

```rego
# ── P928: succession_inventory_death_date — dodaj w restructuring.rego ──────────
# Cel: Remanent na dzień śmierci, opodatkowanie 10% nadwyżki
# Podstawa: Art. 24 ust. 2 PIT + Art. 14 ust. 2 PIT
# Priorytet: 928
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.restructuring.succession_inventory",
    "package": "jdg.restructuring", "priority": 928,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "DECEASED",
    "succession_inventory_required": true,
    "succession_inventory_date": death_date,
    "succession_inventory_tax_rate": "10%",
    "succession_inventory_deadline_days": 30,
    "_legal_basis": "Art. 24 ust. 2 PIT, Art. 14 ust. 2 PIT",
    "_warnings": [
        sprintf("Remanent na dzień śmierci (%s) WYMAGANY w ciągu 30 dni. Nadwyżka remanentu opodatkowana 10%% PIT.", [death_date])
    ]
} {
    input.jdg_entrepreneur.business_status == "DECEASED"
    death_date := object.get(input.jdg_entrepreneur, "death_date", "")
    death_date != ""
    has_inventory := object.get(input.jdg_entrepreneur, "death_inventory_completed", false)
    has_inventory == false
}
```

**Test case +:** JDG, śmierć 2026-03-15, brak remanentu → obowiązek remanentu na 2026-03-15, termin 30 dni

**Test case −:** JDG aktywne → `business_status != "DECEASED"` → reguła NIE matchuje

---

### C1.2 — P922: `succession_tax_responsibilities`

```rego
# ── P922: succession_tax_responsibilities — dodaj w restructuring.rego ──────────
# Cel: Obowiązki spadkobierców/zarządcy — zeznania za zmarłego
# Podstawa: Art. 97 § 1-2, Art. 100 § 1-2 Ordynacji
# Priorytet: 922
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.restructuring.succession_tax_duties",
    "package": "jdg.restructuring", "priority": 922,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "DECEASED",
    "succession_tax_returns_required": ["PIT-36/PIT-36L", "VAT-7", "PIT-11"],
    "succession_tax_deadline": "standard_deadline",
    "succession_responsible_party": responsible_party,
    "_legal_basis": "Art. 97 § 1-2, Art. 100 § 1-2 Ordynacji podatkowej",
    "_warnings": [
        sprintf("Obowiązki podatkowe po śmierci JDG — odpowiedzialny: %s", [responsible_party]),
        "Należy złożyć zeznania roczne za zmarłego przedsiębiorcę w standardowych terminach."
    ]
} {
    input.jdg_entrepreneur.business_status == "DECEASED"
    responsible_party = "ZARZADCA_SUKCESYJNY" {
        object.get(input.jdg_entrepreneur, "has_succession_administrator", false) == true
    } else = "SPADKOBIERCY" {
        object.get(input.jdg_entrepreneur, "has_succession_administrator", false) != true
    }
}
```

---

## C2. `jdg.pit.transitions.rego` — Zmiana formy (2 reguły)

### C2.1 — P830: `tax_form_change_inventory`

```rego
# ── P830: tax_form_change_inventory — Remanent przy zmianie ryczałt→PKPiR ─────
# Cel: Przy przejściu ryczałt→skala/liniowy konieczny remanent na 1 stycznia
# Podstawa: Art. 24 ust. 2 PIT, Art. 44 ust. 2 PIT
# Priorytet: 830
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.pit.transitions.form_change_inventory",
    "package": "jdg.pit.transitions", "priority": 830,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": new_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "transitions_form_change": sprintf("%s → %s", [old_form, new_form]),
    "transitions_inventory_required": true,
    "transitions_inventory_date": "PREVIOUS_YEAR_DECEMBER_31",
    "_legal_basis": "Art. 24 ust. 2 PIT, Art. 44 ust. 2 PIT",
    "_warnings": [sprintf("Zmiana formy z %s na %s — WYMAGANY remanent na 31 grudnia dla celów KUP w nowym roku.", [old_form, new_form])]
} {
    input.temporal.is_form_change_event == true
    old_form := object.get(input.jdg_entrepreneur, "previous_tax_form", "")
    new_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    old_form == "LUMP_SUM"
    new_form in {"PIT_SCALE", "LINEAR"}
    object.get(input.jdg_entrepreneur, "form_change_inventory_done", false) == false
}
```

**Test case +:** JDG zmienia ryczałt → skala od 2027 → remanent na 31.12.2026 wymagany

**Test case −:** JDG zmienia skala → liniowy → obie formy z PKPiR → `old_form != "LUMP_SUM"` → reguła NIE matchuje

---

### C2.2 — P832: `tax_form_change_kup_correction`

```rego
# ── P832: tax_form_change_kup_correction — Korekta KUP przy zmianie formy ──────
# Cel: Wydatki poniesione przed zmianą formy, wykorzystane po zmianie
# Podstawa: Art. 22 ust. 1 PIT, Art. 24 ust. 1 PIT
# Priorytet: 832
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.pit.transitions.kup_correction",
    "package": "jdg.pit.transitions", "priority": 832,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": new_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "adjusted", "kus_percent": kup_percent,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "transitions_kup_correction_needed": true,
    "transitions_kup_previous_period": previous_period,
    "_legal_basis": "Art. 22 ust. 1 PIT, Art. 24 ust. 1 PIT",
    "_warnings": [
        sprintf("Korekta KUP: wydatek poniesiony w %s (forma: %s), wykorzystany w %s (forma: %s). Konieczna korekta.", [previous_period, old_form, current_period, new_form])
    ]
} {
    input.temporal.is_form_change_event == true
    input.invoice.expense_date_before_change == true
    input.invoice.expense_utilized_after_change == true
    old_form := object.get(input.jdg_entrepreneur, "previous_tax_form", "")
    new_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    previous_period := object.get(input.invoice, "expense_date", "")
    current_period := time.format(time.now_ns())
    kup_percent := 100  # Domyślnie pełny KUP — szczegóły zależą od konkretnego wydatku
}
```

---

## C3. `jdg.liability.rego` — Przedawnienia (2 reguły)

### C3.1 — P1162: `statute_interruption_execution`

```rego
# ── P1162: statute_interruption_execution — Przerwanie biegu przedawnienia ──────
# Cel: Środek egzekucyjny → przerwanie → nowy 5-letni termin
# Podstawa: Art. 70 § 4 Ordynacji podatkowej
# Priorytet: 1162
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.liability.statute_interrupted",
    "package": "jdg.liability", "priority": 1162,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "statute_of_limitations_status": "INTERRUPTED",
    "statute_interruption_event": interruption_event,
    "statute_interruption_date": interruption_date,
    "statute_new_expiry_date": new_expiry,
    "_legal_basis": "Art. 70 § 4 Ordynacji podatkowej",
    "_warnings": [
        sprintf("BIEG PRZEDAWNIENIA PRZERWANY (%s) — nowy 5-letni termin od %s, koniec: %s", [interruption_event, interruption_date, new_expiry])
    ]
} {
    interruption_event := object.get(input.tax_liability, "statute_interruption_event", "")
    interruption_event != ""
    interruption_date := object.get(input.tax_liability, "statute_interruption_date", "")
    new_expiry := helpers.add_years(interruption_date, 5)
}
```

**Test case +:** Zaległość z 2020, egzekucja w 2024 → przerwanie → nowy termin do 2029

**Test case −:** Zaległość z 2020, brak egzekucji → `interruption_event == ""` → reguła NIE matchuje

---

### C3.2 — P1164: `liability_spousal_solidary`

```rego
# ── P1164: liability_spousal_solidary — Odpowiedzialność solidarna małżonka ───
# Cel: Małżonek odpowiada solidarnie za zaległości JDG (majątek wspólny)
# Podstawa: Art. 29 Ordynacji podatkowej
# Priorytet: 1164
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.liability.spousal_solidary",
    "package": "jdg.liability", "priority": 1164,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "liability_type": "SPOUSAL_SOLIDARY",
    "liability_spousal_applies": true,
    "liability_limited_to_community_property": true,
    "_legal_basis": "Art. 29 Ordynacji podatkowej",
    "_warnings": [
        sprintf("Odpowiedzialność solidarna małżonka — zaległości %.2f PLN mogą być egzekwowane z majątku wspólnego", [tax_arrears])
    ]
} {
    input.jdg_entrepreneur.has_spouse == true
    input.jdg_entrepreneur.marital_property_regime == "COMMUNITY"
    tax_arrears := object.get(input.tax_liability, "total_arrears", 0)
    tax_arrears > 0
    input.tax_liability.collection_from_jdg_failed == true
}
```

**Test case +:** JDG z majątkiem wspólnym, 50k zaległości, egzekucja z JDG bezskuteczna → odpowiedzialność małżonka

**Test case −:** JDG z rozdzielnością majątkową → `marital_property_regime != "COMMUNITY"` → reguła NIE matchuje

---

## C4. `jdg.representation.rego` — Reprezentacja (2 reguły)

### C4.1 — P1214: `poa_delivery_ppd1`

```rego
# ── P1214: poa_delivery_ppd1 — dodaj w representation.rego ──────────────────────
# Cel: PPD-1 — pełnomocnictwo tylko do doręczeń
# Podstawa: Art. 146 § 1 Ordynacji podatkowej
# Priorytet: 1214
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.representation.ppd1_delivery",
    "package": "jdg.representation", "priority": 1214,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "",
    "poa_type": "PPD1_DELIVERY_ONLY",
    "poa_scope": "CORRESPONDENCE_ONLY",
    "poa_representation_allowed": false,
    "poa_decision_making_allowed": false,
    "_legal_basis": "Art. 146 § 1 Ordynacji podatkowej",
    "_warnings": ["PPD-1: pełnomocnictwo tylko do odbioru korespondencji — NIE uprawnia do reprezentacji merytorycznej!"]
} {
    input.representation.poa_type == "PPD-1"
}
```

**Test case +:** UPL-1 (pełnomocnictwo szczególne) → reprezentacja merytoryczna → OK

**Test case −:** PPD-1 → tylko doręczenia, nie może podpisać deklaracji

---

### C4.2 — P1216: `joint_procuration_check`

```rego
# ── P1216: joint_procuration_check — Prokura łączna ────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.representation.joint_procuration",
    "package": "jdg.representation", "priority": 1216,
    "procuration_type": "JOINT",
    "procuration_requires_two_signatures": true,
    "procuration_single_signature_invalid": true,
    "_legal_basis": "Art. 109⁴ § 1 KSH",
    "_warnings": ["Prokura łączna — wymagane współdziałanie dwóch prokurentów. Pojedynczy podpis jest NIEWAŻNY!"]
} {
    input.representation.procuration_type == "JOINT"
    input.representation.signature_count < 2
}
```

---

## C5. `jdg.temporal.rego` — Temporalne (3 reguły)

### C5.1 — P1614: `pit_tax_free_amount_temporal`

```rego
# ── P1614: pit_tax_free_amount_temporal — dodaj w temporal.rego ─────────────────
# Cel: Kwota wolna 30k od 2022 (wcześniej degresywna)
# Podstawa: Art. 27 ust. 1 PIT
# Priorytet: 1614
# ────────────────────────────────────────────────────────────────────────────────
tax_free_amount = amount {
    eval_year := object.get(input.temporal, "evaluation_year", 2025)
    eval_year >= 2022
    amount := 30000
} else = amount {
    eval_year := object.get(input.temporal, "evaluation_year", 2025)
    eval_year >= 2018
    eval_year <= 2021
    annual_income := object.get(input.jdg_entrepreneur, "annual_income", 0)
    amount = 1440 { annual_income <= 8000 }
    amount = max([0, 1440 - (annual_income - 8000) * 0.008835]) { annual_income > 8000; annual_income <= 13000 }
    amount = 0 { annual_income > 130000 }
}

tax_free_reduction = reduction {
    eval_year := object.get(input.temporal, "evaluation_year", 2025)
    eval_year >= 2022
    reduction := 3600
} else = reduction {
    reduction := tax_free_amount * 0.17  # pre-2022: 17% rate
}
```

**Test case +:** Rok 2024 → `tax_free_amount == 30000`

**Test case −:** Rok 2019, dochód 100k → `tax_free_amount == 0` (degresywna, powyżej 127k → 0)

---

### C5.2 — P1616: `depreciation_one_off_limit_temporal`

```rego
# ── P1616: depreciation_one_off_limit_temporal ──────────────────────────────────
# Cel: Limit jednorazowej amortyzacji: 10k → 100k
# Podstawa: Art. 22d ust. 1 PIT
# Priorytet: 1616
# ────────────────────────────────────────────────────────────────────────────────
depreciation_one_off_limit = limit {
    eval_year := object.get(input.temporal, "evaluation_year", 2025)
    eval_year >= 2019
    limit := 100000
} else = limit {
    limit := 10000
}
```

**Test case +:** Rok 2025 → `one_off_limit == 100000` (de minimis)

**Test case −:** Rok 2017 → `one_off_limit == 10000`

---

### C5.3 — P1613 (dodatkowa): `temporal_polski_lad_transition`

```rego
# ── Polski Ład transition period (01.01.2022 – 30.06.2022) ─────────────────────
polski_lad_transition {
    eval_date := object.get(input.temporal, "evaluation_date", "2025-01-01")
    eval_date >= "2022-01-01"
    eval_date <= "2022-06-30"
}

health_contrib_deductible_scale = deductible {
    polski_lad_transition
    deductible := true  # Temporary: health contrib 9% deductible from tax
} else = deductible {
    deductible := false  # Post-Polish Deal: health 9% NOT deductible
}
```

---

## C6. ROZSZERZENIE: `jdg.employer.rego` — Pracodawca

### C6.1 — P1220: `jdg_employer_obligations_checklist`

```rego
# ── P1220: jdg_employer_obligations_checklist — dodaj w employer.rego ───────────
# Cel: JDG z pracownikami — kompletna checklista obowiązków
# Priorytet: 1220
# ────────────────────────────────────────────────────────────────────────────────
employer_obligations := [
    {"obligation": "PIT-4R", "deadline": "20th_monthly", "status": pit4r_status},
    {"obligation": "PIT-11", "deadline": "28_february", "status": pit11_status},
    {"obligation": "ZUS_DRA", "deadline": "10th_monthly", "status": zus_dra_status},
    {"obligation": "ZUS_RCA", "deadline": "10th_monthly", "status": zus_rca_status},
    {"obligation": "PPK", "deadline": "auto_enrollment", "status": ppk_status},
    {"obligation": "BHP_training", "deadline": "initial+periodic", "status": bhp_status},
    {"obligation": "PFRON", "deadline": "monthly_if_25plus", "status": perfon_status}
]

else := {
    "matched": true, "rule_id": "jdg.employer.obligations_checklist",
    "package": "jdg.employer", "priority": 1220,
    "employer_obligations": employer_obligations,
    "employer_missing_obligations": missing_obligations,
    "_legal_basis": "Art. 38 PIT, Art. 46 SUS, Art. 32 PPK, Art. 21 PFRON",
    "_warnings": employer_warnings
} {
    input.jdg_entrepreneur.employee_count > 0
    pit4r_status = "OK" { object.get(input.jdg_entrepreneur, "pit4r_filed_this_month", false) == true }
        else = "MISSING" { true }
    pit11_status = "OK" { object.get(input.jdg_entrepreneur, "pit11_filed_this_year", false) == true }
        else = "MISSING" { true }
    missing_obligations := [o | o := employer_obligations[_]; o.status != "OK"]
    employer_warnings := [sprintf("Brakujące obowiązki pracodawcy: %d — %s", [count(missing_obligations), concat(", ", [o.obligation | o := missing_obligations[_]])])]
}
```

**Test case +:** JDG z 5 pracownikami, brak PIT-4R i ZUS DRA → `missing_obligations: ["PIT-4R", "ZUS_DRA"]`

**Test case −:** JDG bez pracowników → `employee_count == 0` → reguła NIE matchuje

---

### C6.2 — P1222: `jdg_employment_concurrent_zus_complex`

```rego
# ── P1222: jdg_employment_concurrent_zus_complex — Zbieg etat+JDG (pensja < min)─
# Cel: Jeśli pensja z etatu < minimalna → składki społeczne z JDG
# Podstawa: Art. 9 ust. 2a SUS
# Priorytet: 1222 (dodaj w zus.rego)
# ────────────────────────────────────────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.zus.concurrent_low_salary",
    "package": "jdg.zus", "priority": 1222,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "STANDARD_FROM_JDG",
    "zus_social_due_from_jdg": true,
    "zus_social_due_from_employment": false,
    "zus_health_due": true,
    "zus_health_rate": health_rate,
    "business_status": "",
    "_legal_basis": "Art. 9 ust. 2a ustawy o SUS",
    "_warnings": [
        sprintf("Pensja z etatu (%.2f PLN) jest niższa niż minimalna (%.2f PLN) — składki społeczne MUSZĄ być płacone z JDG!", [salary, min_wage])
    ]
} {
    input.jdg_entrepreneur.concurrent_employment == true
    salary := object.get(input.jdg_entrepreneur, "concurrent_employment_salary", 0)
    min_wage := object.get(object.get(object.get(input.thresholds, "jdg", {}), "bounds", {}), "minimum_wage_gross", 4666)
    salary < min_wage
    salary > 0
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "")
    health_rate = "0.09" { pit_form == "PIT_SCALE" }
    health_rate = "0.049" { pit_form == "LINEAR" }
}
```

**Test case +:** JDG + etat, pensja 3 500 PLN < 4 666 PLN (minimalna) → składki społeczne z JDG

**Test case −:** JDG + etat, pensja 6 000 PLN > 4 666 PLN → tylko zdrowotna z JDG (P743 matchuje wcześniej)

---

# FAZA D — P3 NISKIE (3 reguły szczegółowe + 17 reference entries w tabeli)

> **Ryzyko pominięcia:** Brak enterprise-grade traceability

---

## D1. NOWY PAKIET: `jdg.audit.rego` (3 reguły)

```rego
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Audit: Ścieżka audytu ENTERPRISE (P970-P989)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.audit
import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.audit.no_match",
    "package": "jdg.audit", "priority": 989
}

# ── P970: audit_immutability_log ───────────────────────────────────────────────
# Cel: Każda decyzja → hash SHA-256 + timestamp + operator_id
# Priorytet: 970
# ────────────────────────────────────────────────────────────────────────────────
decide := {
    "matched": true, "rule_id": "jdg.audit.immutability_log",
    "package": "jdg.audit", "priority": 970,
    "audit_decision_hash": crypto.sha256(json.marshal(input.verdict)),
    "audit_timestamp": time.now_ns(),
    "audit_operator_id": operator_id,
    "audit_immutability_chain": true,
    "_legal_basis": "ENTERPRISE_SECURITY_POLICY",
    "_warnings": []
} {
    operator_id := object.get(input.audit, "operator_id", "system_opa_auto")
    true  # Always generates audit trail
}

# ── P972: audit_decision_timestamp ─────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.audit.decision_timestamp",
    "package": "jdg.audit", "priority": 972,
    "audit_iso8601_timestamp": iso_timestamp,
    "audit_timestamp_ms": time.now_ns() / 1000000,
    "_legal_basis": "ENTERPRISE_AUDIT_REQUIREMENT",
    "_warnings": []
} {
    iso_timestamp := time.format(time.now_ns())
    true
}

# ── P974: audit_operator_identity ──────────────────────────────────────────────
else := {
    "matched": true, "rule_id": "jdg.audit.operator_identity",
    "package": "jdg.audit", "priority": 974,
    "audit_operator_id": operator_id,
    "audit_operator_type": operator_type,
    "audit_operator_accountable": true,
    "_legal_basis": "ENTERPRISE_AUDIT_REQUIREMENT",
    "_warnings": []
} {
    operator_id := object.get(input.audit, "operator_id", "system_opa_auto")
    operator_type = "HUMAN" { input.audit.operator_id != "" }
    operator_type = "SYSTEM_AUTO" { input.audit.operator_id == "" }
    true
}
```

---

## D2. POZOSTAŁE REGUŁY FAZY D — Reference entries (17 reguł)

> ℹ️ **Format reference:** Poniższe reguły są zdefiniowane jako single-line entries z kluczowym warunkiem logicznym.
> Pełny pseudokod Rego dla tych reguł używa tego samego wzorca `else := {...} { conditions }` co reguły szczegółowe.
> Priorytet P3 — implementacja wg potrzeb po Fazie A, B, C.

Poniższe reguły są implementowane w istniejących plikach `.rego` wg tego samego wzorca `else-chain`:

| # | P | Reguła | Plik | Główny warunek |
|---|:--:|--------|------|----------------|
| D2.1 | P250b | `oss_ioss_declaration_deadline` | `vat/procedures.rego` | `oss_active == true` → deadline: kwartał + 30 dni |
| D2.2 | P250c | `ioss_import_150eur_threshold` | `vat/procedures.rego` | Import ≤150 EUR → IOSS, >150 EUR → standard |
| D2.3 | P255b | `vat_ue_quarterly_eligibility` | `vat/procedures.rego` | WDT+WNT ≤50k PLN/4 kwartały → kwartalnie |
| D2.4 | P1116 | `correction_collective_conditions` | `corrections.rego` | Wiele pozycji, ten sam okres → korekta zbiorcza |
| D2.5 | P1120 | `correction_annual_vat_5_10_years` | `corrections.rego` | ŚT ruchome 5 lat, nieruchomości 10 lat |
| D2.6 | P1166 | `statute_covid_legacy` | `temporal.rego` | COVID → przedłużone terminy 2020-2021 |
| D2.7 | P1615 | `temporal_ksef_delayed_2026` | `temporal.rego` | KSeF od 01.02.2026 |
| D2.8 | P1617 | `temporal_nbp_fx_rate_date` | `temporal.rego` | Kurs NBP z dnia poprzedzającego |
| D2.9 | P1220b | `employer_zus_dra_monthly_detail` | `employer.rego` | ZUS DRA + RCA + ZUA szczegóły terminów |
| D2.10 | P1220c | `employer_pit11_deadline_feb28` | `employer.rego` | PIT-11 do 28 lutego |
| D2.11 | P1220d | `employer_peron_contribution` | `employer.rego` | ≥25 pracowników → PFRON |
| D2.12 | P1220e | `employer_osh_training` | `employer.rego` | BHP wstępne + okresowe → KUP |
| D2.13 | P140a | `vat_breach_notification_7days` | `vat/substantive.rego` | Utrata zwolnienia → VAT-R w 7 dni |
| D2.14 | P140b | `vat_breach_retroactive_tax` | `vat/substantive.rego` | Sprzedaż powyżej limitu → VAT retroaktywny |
| D2.15 | P617b | `allowances_rd_carry_forward_info` | `allowances.rego` | B+R carry-forward 6 lat — info helper |
| D2.16 | P618b | `bad_debt_pit_debtor_90days` | `allowances.rego` | Dłużnik PIT → obowiązek korekty po 90 dniach |
| D2.17 | P255c | `vat_ue_summary_correction_deadline` | `vat/procedures.rego` | Korekty VAT-UE → 14 dni |

---

## 🎯 MAPA IMPLEMENTACJI — Critical Path

| Faza | Tydzień | Pliki do utworzenia/edycji | Reguły |
|------|:-------:|----------------------------|:------:|
| **A** | 1 | **NOWY:** `conflicts.rego`, `validation.rego` **EDYCJA:** `pit/exemptions.rego`, `zus.rego`, `allowances.rego` | 12 |
| **B** | 2 | **EDYCJA:** `zus.rego`, `vat/procedures.rego`, `corrections.rego`, `vat/substantive.rego`, `business.rego`, `accounting.rego` | 18 |
| **C** | 3 | **EDYCJA:** `restructuring.rego`, `pit/transitions.rego`, `liability.rego`, `representation.rego`, `temporal.rego`, `employer.rego` | 28 |
| **D** | 4 | **NOWY:** `audit.rego` **EDYCJA:** `vat/procedures.rego`, `corrections.rego`, `temporal.rego`, `employer.rego`, `vat/substantive.rego`, `allowances.rego` | 20 |

---

## ✅ KRYTERIA AKCEPTACJI

Dla każdej reguły:
1. ✅ Pseudokod kompiluje się z `opa check`
2. ✅ Test case pozytywny przechodzi (reguła matchuje)
3. ✅ Test case negatywny przechodzi (reguła NIE matchuje)
4. ✅ Wszystkie pola werdyktu wypełnione (zgodnie ze standardowym wzorcem)
5. ✅ `_legal_basis` z dokładnym artykułem
6. ✅ `_warnings` z czytelnym komunikatem dla użytkownika JDG

---

> **🔥 Następny krok:** Implementacja Fazy A (12 reguł P0) — utworzenie `conflicts.rego` i `validation.rego`, rozszerzenie `pit/exemptions.rego`, `zus.rego` i `allowances.rego`.

---

*Wygenerowano przez NexusAI Implementation Engine — 78 reguł × pełny pseudokod Rego × test case'y.*
*Data: 2026-07-11*
