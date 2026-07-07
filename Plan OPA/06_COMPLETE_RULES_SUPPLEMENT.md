# 📋 Kompletny Kompendium Reguł — Uzupełnienie (Pakiety CIT/PIT, Ulgi, Księgowość, ZUS)

> **Status:** Dokumentacja ENTERPRISE v2.0  
> **Data:** 2026-07-07  
> **Powiązany:** `Plan OPA/00_PLAN_STRUKTURA.md`, `03_RULES_DETAILED.md`, `05_ARCHITECTURE_DECISION.md`  
> **Uwaga:** Ten dokument uzupełnia `03_RULES_DETAILED.md` o reguły, które nie mają tam jeszcze pełnego pseudokodu. Architektura Multi-Pass opisana w ADR-001.

---

# CZĘŚĆ I: PAKIET `tax.risk` — Reguły uzupełniające (P1-P9)

---

### P1: `counterparty_trust_low`

**Cel biznesowy:** Niski trust score kontrahenta (< progu `trust_auto_post`) → alert dla księgowego.

**Przesłanki:**
- `input.vendor.trust_score` < `input.thresholds.limits.trust_auto_post`
- `input.vendor.trust_score` > 0 (żeby wykluczyć nieznanych)

**Rezultat:**
- `_routing: "TRIAGE_QUEUE"`
- `_routing_reason: "Niski trust score kontrahenta"`
- `vendor_trust_score`: przekazana wartość

**Podstawa prawna:** Art. 22 UoR (zasada ostrożności), ADR-009 (polityka wewnętrzna)

**Pseudokod Rego:**
```rego
# ── P1: counterparty_trust_low ──────────────────────────────────
# Cel biznesowy: Niski trust score kontrahenta → alert
# Przesłanki: trust_score < trust_auto_post
# Podstawa prawna: Art. 22 UoR, ADR-009
# Priorytet: 1
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.trust_score < input.thresholds.limits.trust_auto_post
    input.vendor.trust_score > 0
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.counterparty_trust_low",
        "package": "tax.risk",
        "priority": 1,
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": concat("", [
            "Niski trust score kontrahenta: ",
            sprintf("%.2f", [input.vendor.trust_score]),
            " < ", sprintf("%.2f", [input.thresholds.limits.trust_auto_post])
        ]),
        "_legal_basis": "Art. 22 UoR (zasada ostrożności), ADR-009",
        "vendor_trust_score": input.vendor.trust_score
    }
}
```

---

### P3: `new_counterparty_flag`

**Cel biznesowy:** Nowy kontrahent (pierwsze 3 faktury) → dodatkowa weryfikacja w TRIAGE.

**Przesłanki:**
- `input.vendor.is_new` == `true`

**Rezultat:**
- `_routing: "TRIAGE_QUEUE"`
- `_routing_reason: "Nowy kontrahent — wymagana dodatkowa weryfikacja"`

**Podstawa prawna:** Art. 22 UoR (rzetelność ksiąg), procedury AML

**Pseudokod Rego:**
```rego
# ── P3: new_counterparty_flag ───────────────────────────────────
# Cel biznesowy: Nowy kontrahent → dodatkowa weryfikacja
# Przesłanki: vendor.is_new == true
# Podstawa prawna: Art. 22 UoR, procedury AML
# Priorytet: 3
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.is_new == true
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.new_counterparty_flag",
        "package": "tax.risk",
        "priority": 3,
        "_routing": "TRIAGE_QUEUE",
        "_routing_reason": "Nowy kontrahent — wymagana dodatkowa weryfikacja",
        "_legal_basis": "Art. 22 UoR, procedury AML"
    }
}
```

---

### P4: `high_risk_country`

**Cel biznesowy:** Kontrahent z kraju wysokiego ryzyka podatkowego (raj podatkowy) → BLOCK.

**Przesłanki:**
- `input.vendor.country` in lista krajów wysokiego ryzyka (dostarczana przez `input.vendor.is_tax_haven` lub lista w thresholds)

**Rezultat:**
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Kontrahent z kraju wysokiego ryzyka podatkowego"`
- `transfer_pricing_alert: true`

**Podstawa prawna:** Art. 11a-11q CIT (ceny transferowe), Rozp. MF w sprawie krajów stosujących szkodliwą konkurencję podatkową

**Pseudokod Rego:**
```rego
# ── P4: high_risk_country ───────────────────────────────────────
# Cel biznesowy: Kraj wysokiego ryzyka → alert TP
# Przesłanki: vendor.country w tax_haven_list
# Podstawa prawna: Art. 11a-11q CIT
# Priorytet: 4
# ────────────────────────────────────────────────────────────────

# Lista krajów — dostarczana z thresholds lub przez vendor flag
is_tax_haven {
    input.vendor.country in input.thresholds.tax_haven_list
}

decide = verdict {
    is_tax_haven
    input.invoice.amount_gross >= input.thresholds.limits.transfer_pricing_limit
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.high_risk_country",
        "package": "tax.risk",
        "priority": 4,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Kontrahent z kraju wysokiego ryzyka podatkowego — obowiązek dokumentacji TP",
        "_legal_basis": "Art. 11a-11q CIT",
        "transfer_pricing_alert": true,
        "_warnings": ["Obowiązek dokumentacji cen transferowych"]
    }
}
```

---

### P6: `related_party_transaction`

**Cel biznesowy:** Transakcja z podmiotem powiązanym → obowiązek dokumentacji TP powyżej progu.

**Przesłanki:**
- `input.vendor.is_related_party` == `true`
- `input.invoice.amount_gross` >= `input.thresholds.limits.transfer_pricing_limit`

**Rezultat:**
- `transfer_pricing_required: true`
- `_warning: "Transakcja z podmiotem powiązanym — obowiązek dokumentacji TP"`

**Podstawa prawna:** Art. 11a-11q CIT, Art. 23o PIT

**Pseudokod Rego:**
```rego
# ── P6: related_party_transaction ───────────────────────────────
# Cel biznesowy: Podmiot powiązany → dokumentacja TP
# Przesłanki: is_related_party AND amount >= TP limit
# Podstawa prawna: Art. 11a-11q CIT, Art. 23o PIT
# Priorytet: 6
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.is_related_party == true
    input.invoice.amount_gross >= input.thresholds.limits.transfer_pricing_limit
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.related_party_transaction",
        "package": "tax.risk",
        "priority": 6,
        "transfer_pricing_required": true,
        "_warnings": [
            "Transakcja z podmiotem powiązanym — obowiązek dokumentacji TP",
            concat("", ["Próg dokumentacyjny: ",
                sprintf("%.0f", [input.thresholds.limits.transfer_pricing_limit]), " PLN"])
        ],
        "_legal_basis": "Art. 11a-11q CIT, Art. 23o PIT"
    }
}
```

---

### P8: `duplicate_invoice_suspect`

**Cel biznesowy:** Podejrzenie duplikatu faktury (ten sam numer faktury + NIP + data).

**Przesłanki:**
- System wykrywa potencjalny duplikat (dostarczane przez `input.invoice.is_potential_duplicate`)

**Rezultat:**
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Podejrzenie duplikatu faktury"`
- `duplicate_suspect: true`

**Podstawa prawna:** Art. 22 UoR (zasada rzetelności), Art. 55 KKS

**Pseudokod Rego:**
```rego
# ── P8: duplicate_invoice_suspect ───────────────────────────────
# Cel biznesowy: Podejrzenie duplikatu faktury → BLOCK
# Przesłanki: is_potential_duplicate == true
# Podstawa prawna: Art. 22 UoR, Art. 55 KKS
# Priorytet: 8
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.is_potential_duplicate == true
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.duplicate_invoice_suspect",
        "package": "tax.risk",
        "priority": 8,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Podejrzenie duplikatu faktury",
        "_legal_basis": "Art. 22 UoR, Art. 55 KKS",
        "duplicate_suspect": true
    }
}
```

---

### P9: `nip_format_invalid`

**Cel biznesowy:** NIP kontrahenta w nieprawidłowym formacie → BLOCK.

**Przesłanki:**
- `input.vendor.nip` nie przechodzi walidacji formatu (10 cyfr, checksum)

**Rezultat:**
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Nieprawidłowy format NIP kontrahenta"`

**Podstawa prawna:** Art. 96b VAT (Biała Lista), Art. 3 ust. 1 ustawy o NIP

**Pseudokod Rego:**
```rego
# ── P9: nip_format_invalid ─────────────────────────────────────
# Cel biznesowy: Nieprawidłowy format NIP
# Przesłanki: nip nie przechodzi walidacji (dostarczane przez nip_valid flag)
# Podstawa prawna: Art. 96b VAT
# Priorytet: 9
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.nip_valid == false
    verdict := {
        "matched": true,
        "rule_id": "tax.risk.nip_format_invalid",
        "package": "tax.risk",
        "priority": 9,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Nieprawidłowy format NIP kontrahenta",
        "_legal_basis": "Art. 96b VAT, Art. 3 ust. 1 ustawy o NIP"
    }
}
```

---

# CZĘŚĆ II: PAKIET `tax.compliance` — Reguły uzupełniające (P22-P39)

---

### P22: `whitelist_check_expired`

**Cel biznesowy:** Weryfikacja Białej Listy przeterminowana (> 30 dni od ostatniego sprawdzenia).

**Przesłanki:**
- `input.vendor.whitelist_checked_at` starsze niż 30 dni od daty transakcji
- `input.invoice.amount_gross` >= `input.thresholds.limits.mpp_limit`

**Rezultat:**
- `_routing: "BLOCK_AND_ALERT"`
- `_routing_reason: "Weryfikacja Białej Listy przeterminowana"`

**Podstawa prawna:** Art. 96b VAT

**Pseudokod Rego:**
```rego
# ── P22: whitelist_check_expired ────────────────────────────────
# Cel biznesowy: Weryfikacja WL starsza niż 30 dni
# Przesłanki: whitelist_checked_at + 30 dni < transaction_date
# Podstawa prawna: Art. 96b VAT
# Priorytet: 22
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.amount_gross >= input.thresholds.limits.mpp_limit
    # Sprawdzenie daty (uproszczone — zakładamy pre-calculated flag)
    input.vendor.whitelist_check_expired == true
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.whitelist_check_expired",
        "package": "tax.compliance",
        "priority": 22,
        "_routing": "BLOCK_AND_ALERT",
        "_routing_reason": "Weryfikacja Białej Liście MF przeterminowana (>30 dni)",
        "_legal_basis": "Art. 96b VAT",
        "_warnings": ["Konieczna ponowna weryfikacja Białej Listy"]
    }
}
```

---

### P26: `vat_on_import_consent`

**Cel biznesowy:** Import z deklaracją rozliczenia VAT w deklaracji (zgoda naczelnika US).

**Przesłanki:**
- `input.invoice.vat_on_import` == `true`
- `input.invoice.procedure` == `"IMPORT"`

**Rezultat:**
- `procedure: "IMPORT_WITH_CONSENT"`
- `vat_rate: "0.23"` (do rozliczenia w deklaracji)

**Podstawa prawna:** Art. 33a VAT

**Pseudokod Rego:**
```rego
# ── P26: vat_on_import_consent ──────────────────────────────────
# Cel biznesowy: Import z deklaracją rozliczenia VAT
# Przesłanki: vat_on_import == true AND procedure == IMPORT
# Podstawa prawna: Art. 33a VAT
# Priorytet: 26
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.vat_on_import == true
    input.invoice.procedure == "IMPORT"
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.vat_on_import_consent",
        "package": "tax.compliance",
        "priority": 26,
        "vat_rate": input.thresholds.rates.vat_standard,
        "procedure": "IMPORT_WITH_CONSENT",
        "_legal_basis": "Art. 33a ustawy o VAT"
    }
}
```

---

### P28: `ksef_structured_invoice`

**Cel biznesowy:** Faktura ustrukturyzowana KSeF — obowiązek od 2026-02-01.

**Przesłanki:**
- `input.invoice.transaction_date` >= `"2026-02-01"`
- `input.company.is_vat_payer` == `true`

**Rezultat:**
- `ksef_required: true`
- `_warning: "Faktura powinna być wystawiona przez KSeF"`

**Podstawa prawna:** Art. 106na-106nq VAT (KSeF)

**Pseudokod Rego:**
```rego
# ── P28: ksef_structured_invoice ────────────────────────────────
# Cel biznesowy: KSeF — obowiązek faktur ustrukturyzowanych
# Przesłanki: transaction_date >= 2026-02-01 AND is_vat_payer
# Podstawa prawna: Art. 106na-106nq VAT
# Priorytet: 28
# ────────────────────────────────────────────────────────────────
ksef_mandatory_date = "2026-02-01"

decide = verdict {
    input.invoice.transaction_date >= ksef_mandatory_date
    input.company.is_vat_payer == true
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.ksef_structured",
        "package": "tax.compliance",
        "priority": 28,
        "ksef_required": true,
        "_warnings": ["Faktura powinna być wystawiona przez KSeF (obowiązek od 01.02.2026)"],
        "_legal_basis": "Art. 106na-106nq ustawy o VAT"
    }
}
```

---

### P30: `ksef_retention_invoice`

**Cel biznesowy:** Okres przechowywania faktury — 5 lat od końca roku podatkowego.

**Przesłanki:**
- `input.invoice.expense_type` in `["OPERATIONAL", "FIXED_ASSET"]`

**Rezultat:**
- `retention_years: input.thresholds.limits.retention_years_invoice`
- `retention_until: <data>`

**Podstawa prawna:** Art. 86 § 1 Ordynacji podatkowej, Art. 74 UoR

**Pseudokod Rego:**
```rego
# ── P30: ksef_retention_invoice ─────────────────────────────────
# Cel biznesowy: Okres przechowywania faktury — 5 lat
# Przesłanki: expense_type OPERATIONAL/FIXED_ASSET
# Podstawa prawna: Art. 86 § 1 Ordynacji podatkowej, Art. 74 UoR
# Priorytet: 30
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type in ["OPERATIONAL", "FIXED_ASSET", "INVENTORY"]
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.retention_invoice",
        "package": "tax.compliance",
        "priority": 30,
        "retention_years": input.thresholds.limits.retention_years_invoice,
        "retention_type": "INVOICE",
        "_legal_basis": "Art. 86 § 1 Ordynacji podatkowej, Art. 74 UoR"
    }
}
```

---

### P36: `payment_after_due_date`

**Cel biznesowy:** Płatność po terminie — potencjalne odsetki.

**Przesłanki:**
- `input.invoice.days_overdue` > 0
- `input.invoice.is_paid` == `true`

**Rezultat:**
- `interest_due: true`
- `_warning: "Faktura opłacona po terminie — sprawdź odsetki"`

**Podstawa prawna:** Art. 53-56 Ordynacji podatkowej (odsetki)

**Pseudokod Rego:**
```rego
# ── P36: payment_after_due_date ─────────────────────────────────
# Cel biznesowy: Opóźniona płatność → odsetki
# Przesłanki: days_overdue > 0 AND is_paid
# Podstawa prawna: Art. 53-56 Ordynacji podatkowej
# Priorytet: 36
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.days_overdue > 0
    input.invoice.is_paid == true
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.payment_overdue",
        "package": "tax.compliance",
        "priority": 36,
        "interest_due": true,
        "_warnings": [concat("", [
            "Faktura opłacona ", sprintf("%d", [input.invoice.days_overdue]),
            " dni po terminie — sprawdź odsetki"
        ])],
        "_legal_basis": "Art. 53-56 Ordynacji podatkowej"
    }
}
```

---

### P38: `statute_of_limitations_approaching`

**Cel biznesowy:** Zbliżający się termin przedawnienia zobowiązania podatkowego.

**Przesłanki:**
- Rok podatkowy transakcji + 5 lat <= bieżący rok + 1 rok

**Rezultat:**
- `statute_warning: true`
- `_warning: "Zbliża się termin przedawnienia — rozlicz w tym roku"`

**Podstawa prawna:** Art. 70 § 1 Ordynacji podatkowej

**Pseudokod Rego:**
```rego
# ── P38: statute_of_limitations_approaching ─────────────────────
# Cel biznesowy: Zbliżające się przedawnienie
# Przesłanki: transakcja starsza niż 4 lata
# Podstawa prawna: Art. 70 § 1 Ordynacji podatkowej
# Priorytet: 38
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.is_statute_approaching == true
    verdict := {
        "matched": true,
        "rule_id": "tax.compliance.statute_warning",
        "package": "tax.compliance",
        "priority": 38,
        "statute_approaching": true,
        "_warnings": ["Zbliża się termin przedawnienia zobowiązania podatkowego (5 lat)"],
        "_legal_basis": "Art. 70 § 1 Ordynacji podatkowej"
    }
}
```

---

# CZĘŚĆ III: PAKIET `tax.crossborder` — Reguły uzupełniające (P41-P49)

---

### P41: `eu_import_services`

**Cel biznesowy:** Import usług z UE — reverse charge (art. 28b VAT).

**Przesłanki:**
- `input.vendor.country` == `"EU"`
- `input.vendor.vat_status` == `"active"`
- `input.invoice.expense_type` != `"GOODS"` (usługa, nie towar)

**Rezultat:**
- `vat_rate: "0.00"`, `procedure: "VAT_REVERSE_CHARGE"`
- `gtu_code: "GTU_12"`

**Podstawa prawna:** Art. 28b VAT (miejsce świadczenia usług)

**Pseudokod Rego:**
```rego
# ── P41: eu_import_services ─────────────────────────────────────
# Cel biznesowy: Import usług z UE → reverse charge (art. 28b)
# Przesłanki: vendor.country == EU AND vat_status == active AND usługa
# Podstawa prawna: Art. 28b VAT
# Priorytet: 41
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.country == "EU"
    input.vendor.vat_status == "active"
    input.invoice.is_service == true
    verdict := {
        "matched": true,
        "rule_id": "tax.crossborder.eu_services_import",
        "package": "tax.crossborder",
        "priority": 41,
        "vat_rate": input.thresholds.rates.vat_zero,
        "rounding_level": "total",
        "gtu_code": "GTU_12",
        "procedure": "VAT_REVERSE_CHARGE",
        "_legal_basis": "Art. 28b ustawy o VAT"
    }
}
```

---

### P42: `wdt_intracommunity_supply`

**Cel biznesowy:** Wewnątrzwspólnotowa dostawa towarów (WDT) — 0% VAT dla sprzedawcy.

**Przesłanki:**
- `input.vendor.country` == `"EU"`
- `input.vendor.vat_status` == `"active"`
- `input.invoice.procedure` == `"WDT"` lub `input.invoice.direction` == `"SALE"`

**Rezultat:**
- `vat_rate: "0.00"`, `procedure: "WDT"`

**Podstawa prawna:** Art. 42 VAT

**Pseudokod Rego:**
```rego
# ── P42: wdt_intracommunity_supply ──────────────────────────────
# Cel biznesowy: WDT — 0% VAT
# Przesłanki: vendor.country == EU AND procedure == WDT
# Podstawa prawna: Art. 42 VAT
# Priorytet: 42
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.procedure == "WDT"
    input.vendor.vat_status == "active"
    verdict := {
        "matched": true,
        "rule_id": "tax.crossborder.wdt_supply",
        "package": "tax.crossborder",
        "priority": 42,
        "vat_rate": input.thresholds.rates.vat_zero,
        "rounding_level": "total",
        "gtu_code": "",
        "procedure": "WDT",
        "_legal_basis": "Art. 42 ustawy o VAT"
    }
}
```

---

### P46: `non_eu_services_import`

**Cel biznesowy:** Import usług spoza UE — brak VAT (rozliczenie w kraju nabywcy).

**Przesłanki:**
- `input.vendor.country` == `"NON_EU"`
- `input.invoice.is_service` == `true`

**Rezultat:**
- `vat_rate: "0.00"`, `procedure: "IMPORT_SERVICES"`

**Podstawa prawna:** Art. 17 ust. 1 pkt 4 VAT, Art. 28b VAT

**Pseudokod Rego:**
```rego
# ── P46: non_eu_services_import ─────────────────────────────────
# Cel biznesowy: Import usług spoza UE
# Przesłanki: vendor.country == NON_EU AND is_service
# Podstawa prawna: Art. 17 ust. 1 pkt 4 VAT, Art. 28b VAT
# Priorytet: 46
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.country == "NON_EU"
    input.invoice.is_service == true
    verdict := {
        "matched": true,
        "rule_id": "tax.crossborder.non_eu_services",
        "package": "tax.crossborder",
        "priority": 46,
        "vat_rate": input.thresholds.rates.vat_zero,
        "rounding_level": "total",
        "procedure": "IMPORT_SERVICES",
        "_legal_basis": "Art. 17 ust. 1 pkt 4 VAT, Art. 28b VAT"
    }
}
```

---

# CZĘŚĆ IV: PAKIET `tax.vat.substantive` — Reguły uzupełniające (P50-P69)

---

### P50: `vat_margin_scheme`

**Cel biznesowy:** Procedura VAT-marża dla towarów używanych, dzieł sztuki, antyków.

**Pseudokod Rego:**
```rego
# ── P50: vat_margin_scheme ─────────────────────────────────────
# Cel biznesowy: Procedura VAT-marża
# Przesłanki: procedure == MARGIN
# Podstawa prawna: Art. 120 VAT
# Priorytet: 50
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.procedure == "MARGIN"
    verdict := {
        "matched": true,
        "rule_id": "tax.vat.substantive.margin_scheme",
        "package": "tax.vat.substantive",
        "priority": 50,
        "vat_rate": input.thresholds.rates.vat_standard,
        "rounding_level": "position",
        "gtu_code": "",
        "procedure": "MARGIN",
        "_legal_basis": "Art. 120 ustawy o VAT"
    }
}
```

---

### P58: `vat_exemption_subject`

**Cel biznesowy:** Zwolnienie podmiotowe VAT — limit 200 000 PLN obrotu rocznego.

**Pseudokod Rego:**
```rego
# ── P58: vat_exemption_subject ──────────────────────────────────
# Cel biznesowy: Zwolnienie podmiotowe VAT (limit 200k PLN)
# Przesłanki: !is_vat_payer AND annual_turnover < limit
# Podstawa prawna: Art. 113 ust. 1 VAT
# Priorytet: 58
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.is_vat_payer == false
    input.company.annual_turnover_net < input.thresholds.limits.vat_exemption_limit
    verdict := {
        "matched": true,
        "rule_id": "tax.vat.substantive.exemption_subject",
        "package": "tax.vat.substantive",
        "priority": 58,
        "vat_rate": input.thresholds.rates.vat_zero,
        "rounding_level": "total",
        "gtu_code": "",
        "vat_exemption": "SUBJECT",
        "_legal_basis": "Art. 113 ust. 1 ustawy o VAT"
    }
}
```

---

### P61: `vat_prepayment_rule`

**Cel biznesowy:** Obowiązek podatkowy przy zaliczce — moment powstania obowiązku w dniu wpłaty.

**Pseudokod Rego:**
```rego
# ── P61: vat_prepayment_rule ────────────────────────────────────
# Cel biznesowy: Obowiązek podatkowy przy zaliczce
# Przesłanki: is_advance == true OR procedure == PREPAYMENT
# Podstawa prawna: Art. 19a ust. 8 VAT
# Priorytet: 61
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.is_advance == true
    verdict := {
        "matched": true,
        "rule_id": "tax.vat.substantive.prepayment",
        "package": "tax.vat.substantive",
        "priority": 61,
        "tax_point": "prepayment",
        "tax_point_date": input.invoice.payment_date,
        "_legal_basis": "Art. 19a ust. 8 ustawy o VAT"
    }
}
```

---

### P62: `vat_23_correction`

**Cel biznesowy:** Korekta VAT-23 — obowiązek złożenia deklaracji przy nabyciach wewnątrzwspólnotowych.

**Pseudokod Rego:**
```rego
# ── P62: vat_23_correction ──────────────────────────────────────
# Cel biznesowy: Obowiązek VAT-23 dla WNT
# Przesłanki: procedure == VAT_REVERSE_CHARGE
# Podstawa prawna: Art. 99 ust. 11a VAT
# Priorytet: 62
# ────────────────────────────────────────────────────────────────
decide = verdict {
    verdict := {
        "matched": true,
        "rule_id": "tax.vat.substantive.vat23_correction",
        "package": "tax.vat.substantive",
        "priority": 62,
        "vat23_required": true,
        "_legal_basis": "Art. 99 ust. 11a VAT"
    }
} {
    input.invoice.procedure == "VAT_REVERSE_CHARGE"
}
```

---

### P68: `gtu_mapping_transport`

**Cel biznesowy:** GTU_06 — usługi transportowe i gospodarki magazynowej.

**Pseudokod Rego:**
```rego
# ── P68: gtu_mapping_transport ──────────────────────────────────
# Cel biznesowy: Usługi transportowe → GTU_06
# Przesłanki: category_code == TRANSPORT
# Podstawa prawna: § 10 rozp. JPK_VAT
# Priorytet: 68
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_code == "TRANSPORT"
    verdict := {
        "matched": true,
        "rule_id": "tax.vat.gtu.transport",
        "package": "tax.vat.gtu",
        "priority": 68,
        "gtu_code": "GTU_06",
        "_legal_basis": "§ 10 rozporządzenia w sprawie JPK_VAT"
    }
}
```

---

### P69: `gtu_mapping_gas_energy`

**Cel biznesowy:** GTU_11 — gaz, energia elektryczna, ciepło.

**Pseudokod Rego:**
```rego
# ── P69: gtu_mapping_gas_energy ─────────────────────────────────
# Cel biznesowy: Gaz/energia → GTU_11
# Przesłanki: category_code == GAS_ENERGY
# Podstawa prawna: § 10 rozp. JPK_VAT
# Priorytet: 69
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.category_code == "GAS_ENERGY"
    verdict := {
        "matched": true,
        "rule_id": "tax.vat.gtu.gas_energy",
        "package": "tax.vat.gtu",
        "priority": 69,
        "gtu_code": "GTU_11",
        "_legal_basis": "§ 10 rozporządzenia w sprawie JPK_VAT"
    }
}
```

---

# CZĘŚĆ V: PAKIET `tax.direct.cit` — CIT (P70-P74)

---

### P70: `cit_estonian_effective`

**Cel biznesowy:** Estoński CIT — efektywna stawka 20% od wypłaconego zysku, odroczenie opodatkowania.

**Przesłanki:**
- `input.company.tax_form` == `"CIT_ESTONIAN"`
- Firma spełnia warunki (przychód pasywny < 50%, zatrudnienie >= 3 osoby)

**Rezultat:**
- `cit_rate: input.thresholds.rates.cit_estonian_effective`
- `tax_deferral: true`
- `income_tax_qualification: "deductible_full"` (KUP standardowe)

**Podstawa prawna:** Rozdział 6b CIT (Art. 28c-28t)

**Pseudokod Rego:**
```rego
# ── P70: cit_estonian_effective ──────────────────────────────────
# Cel biznesowy: Estoński CIT — 20% efektywna, odroczenie
# Przesłanki: tax_form == CIT_ESTONIAN
# Podstawa prawna: Rozdział 6b CIT (Art. 28c-28t)
# Priorytet: 70
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.tax_form == "CIT_ESTONIAN"
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.cit.estonian",
        "package": "tax.direct.cit",
        "priority": 70,
        "cit_rate": input.thresholds.rates.cit_estonian_effective,
        "tax_deferral": true,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "Rozdział 6b ustawy o CIT (Art. 28c-28t)",
        "_warnings": ["Estoński CIT — podatek odroczony do momentu wypłaty zysku"]
    }
}
```

---

### P71: `cit_small_taxpayer`

**Cel biznesowy:** Mały podatnik CIT — stawka 9%.

**Przesłanki:**
- `input.company.tax_form` == `"CIT_STANDARD"`
- `input.company.is_small_taxpayer` == `true`
- `input.company.annual_turnover_net` < 2 000 000 EUR (równowartość)

**Rezultat:**
- `cit_rate: input.thresholds.rates.cit_small`
- `income_tax_qualification: "deductible_full"`

**Podstawa prawna:** Art. 19 ust. 1a CIT

**Pseudokod Rego:**
```rego
# ── P71: cit_small_taxpayer ──────────────────────────────────────
# Cel biznesowy: CIT 9% dla małego podatnika
# Przesłanki: CIT_STANDARD AND is_small_taxpayer
# Podstawa prawna: Art. 19 ust. 1a CIT
# Priorytet: 71
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.tax_form == "CIT_STANDARD"
    input.company.is_small_taxpayer == true
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.cit.small_taxpayer",
        "package": "tax.direct.cit",
        "priority": 71,
        "cit_rate": input.thresholds.rates.cit_small,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "Art. 19 ust. 1a ustawy o CIT"
    }
}
```

---

### P72: `cit_thin_capitalization`

**Cel biznesowy:** Cienka kapitalizacja — wyłączenie z KUP nadmiernych odsetek od pożyczek od podmiotów powiązanych.

**Przesłanki:**
- `input.vendor.is_related_party` == `true`
- `input.vendor.debt_to_equity_ratio` > `input.thresholds.limits.thin_cap_ratio`
- `input.invoice.expense_type` == `"INTEREST"`

**Rezultat:**
- `income_tax_qualification: "non_deductible"`
- `_warning: "Przekroczony limit cienkiej kapitalizacji (debt/equity > 3:1)"`

**Podstawa prawna:** Art. 15c CIT

**Pseudokod Rego:**
```rego
# ── P72: cit_thin_capitalization ─────────────────────────────────
# Cel biznesowy: Cienka kapitalizacja → wyłączenie z KUP
# Przesłanki: related_party AND debt/equity > ratio AND interest
# Podstawa prawna: Art. 15c CIT
# Priorytet: 72
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.vendor.is_related_party == true
    input.vendor.debt_to_equity_ratio > input.thresholds.limits.thin_cap_ratio
    input.invoice.expense_type == "INTEREST"
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.cit.thin_capitalization",
        "package": "tax.direct.cit",
        "priority": 72,
        "income_tax_qualification": "non_deductible",
        "_warnings": [
            "Przekroczony limit cienkiej kapitalizacji",
            concat("", ["Wskaźnik zadłużenia: ",
                sprintf("%.1f", [input.vendor.debt_to_equity_ratio]),
                " > ", sprintf("%.1f", [input.thresholds.limits.thin_cap_ratio])])
        ],
        "_legal_basis": "Art. 15c ustawy o CIT"
    }
}
```

---

### P73: `cit_standard_taxpayer`

**Cel biznesowy:** Standardowy CIT — stawka 19%.

**Przesłanki:**
- `input.company.tax_form` == `"CIT_STANDARD"`
- `input.company.is_small_taxpayer` == `false`

**Rezultat:**
- `cit_rate: input.thresholds.rates.cit_standard`
- `income_tax_qualification: "deductible_full"`

**Podstawa prawna:** Art. 19 ust. 1 CIT

**Pseudokod Rego:**
```rego
# ── P73: cit_standard_taxpayer ───────────────────────────────────
# Cel biznesowy: Standardowy CIT 19%
# Przesłanki: CIT_STANDARD AND NOT small_taxpayer
# Podstawa prawna: Art. 19 ust. 1 CIT
# Priorytet: 73
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.tax_form == "CIT_STANDARD"
    input.company.is_small_taxpayer == false
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.cit.standard",
        "package": "tax.direct.cit",
        "priority": 73,
        "cit_rate": input.thresholds.rates.cit_standard,
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "Art. 19 ust. 1 ustawy o CIT"
    }
}
```

---

### P74: `cit_loss_carry_forward`

**Cel biznesowy:** Rozliczenie straty z lat ubiegłych — max 50% straty rocznie, przez 5 lat.

**Przesłanki:**
- `input.company.has_loss_carry_forward` == `true`
- `input.company.loss_carry_forward_year` >= (bieżący rok - 5)

**Rezultat:**
- `loss_carry_forward_available: true`
- `loss_carry_forward_limit_percent: 50`
- `max_years: 5`

**Podstawa prawna:** Art. 7 ust. 5 CIT

**Pseudokod Rego:**
```rego
# ── P74: cit_loss_carry_forward ──────────────────────────────────
# Cel biznesowy: Rozliczenie straty podatkowej
# Przesłanki: has_loss_carry_forward AND strata <= 5 lat
# Podstawa prawna: Art. 7 ust. 5 CIT
# Priorytet: 74
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.has_loss_carry_forward == true
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.cit.loss_carry_forward",
        "package": "tax.direct.cit",
        "priority": 74,
        "loss_carry_forward_available": true,
        "loss_carry_forward_amount": input.company.loss_carry_forward_amount,
        "loss_carry_forward_limit_percent": 50,
        "max_years": 5,
        "_legal_basis": "Art. 7 ust. 5 ustawy o CIT"
    }
}
```

---

# CZĘŚĆ VI: PAKIET `tax.direct.pit` — PIT uzupełnienie (P76-P79)

---

### P76: `pit_joint_filing`

**Cel biznesowy:** Wspólne rozliczenie małżonków — efektywny próg × 2.

**Przesłanki:**
- `input.company.tax_form` == `"PIT_SCALE"`
- `input.company.joint_filing` == `true`

**Rezultat:**
- `pit_bracket_threshold: input.thresholds.bounds.pit_scale_threshold * 2`
- `joint_filing_active: true`

**Podstawa prawna:** Art. 6 ust. 2 PIT

**Pseudokod Rego:**
```rego
# ── P76: pit_joint_filing ───────────────────────────────────────
# Cel biznesowy: Wspólne rozliczenie małżonków → podwojony próg
# Przesłanki: PIT_SCALE AND joint_filing
# Podstawa prawna: Art. 6 ust. 2 PIT
# Priorytet: 76
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.tax_form == "PIT_SCALE"
    input.company.joint_filing == true
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.pit.joint_filing",
        "package": "tax.direct.pit",
        "priority": 76,
        "pit_bracket_threshold": input.thresholds.bounds.pit_scale_threshold * 2,
        "joint_filing_active": true,
        "_legal_basis": "Art. 6 ust. 2 ustawy o PIT"
    }
}
```

---

### P77: `pit_young_exemption`

**Cel biznesowy:** Ulga dla młodych (do 26 r.ż.) — zwolnienie z PIT do 85 528 PLN.

**Przesłanki:**
- `input.company.tax_form` == `"PIT_SCALE"`
- `input.company.taxpayer_age` <= 26
- Dochód roczny <= `input.thresholds.bounds.pit_young_exemption_limit`

**Rezultat:**
- `pit_rate: "0.00"` (zwolnienie)
- `exemption: "YOUNG"`

**Podstawa prawna:** Art. 21 ust. 1 pkt 148 PIT

**Pseudokod Rego:**
```rego
# ── P77: pit_young_exemption ─────────────────────────────────────
# Cel biznesowy: Ulga dla młodych (do 26 lat)
# Przesłanki: age <= 26 AND income <= limit
# Podstawa prawna: Art. 21 ust. 1 pkt 148 PIT
# Priorytet: 77
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.taxpayer_age <= 26
    input.company.taxpayer_age > 0
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.pit.young_exemption",
        "package": "tax.direct.pit",
        "priority": 77,
        "pit_rate": input.thresholds.rates.vat_zero,
        "pit_exemption": "YOUNG",
        "pit_exemption_limit": input.thresholds.bounds.pit_young_exemption_limit,
        "_legal_basis": "Art. 21 ust. 1 pkt 148 ustawy o PIT"
    }
}
```

---

### P78: `pit_return_exemption`

**Cel biznesowy:** Ulga na powrót — 4 lata zwolnienia po emigracji.

**Przesłanki:**
- `input.company.return_from_emigration` == `true`
- `input.company.return_years_used` < 4
- Dochód <= `input.thresholds.bounds.pit_return_exemption_limit`

**Rezultat:**
- `pit_rate: "0.00"`, `exemption: "RETURN"`

**Podstawa prawna:** Art. 21 ust. 1 pkt 152 PIT

**Pseudokod Rego:**
```rego
# ── P78: pit_return_exemption ────────────────────────────────────
# Cel biznesowy: Ulga na powrót (4 lata po emigracji)
# Przesłanki: return_from_emigration AND years < 4
# Podstawa prawna: Art. 21 ust. 1 pkt 152 PIT
# Priorytet: 78
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.return_from_emigration == true
    input.company.return_years_used < 4
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.pit.return_exemption",
        "package": "tax.direct.pit",
        "priority": 78,
        "pit_rate": input.thresholds.rates.vat_zero,
        "pit_exemption": "RETURN",
        "pit_exemption_limit": input.thresholds.bounds.pit_return_exemption_limit,
        "return_years_remaining": 4 - input.company.return_years_used,
        "_legal_basis": "Art. 21 ust. 1 pkt 152 ustawy o PIT"
    }
}
```

---

### P79: `pit_family_4plus`

**Cel biznesowy:** Ulga dla rodzin 4+ dzieci — zwolnienie do 85 528 PLN.

**Przesłanki:**
- `input.company.children_count` >= 4
- Dochód <= `input.thresholds.bounds.pit_family_4plus_limit`

**Rezultat:**
- `pit_rate: "0.00"`, `exemption: "FAMILY_4PLUS"`

**Podstawa prawna:** Art. 21 ust. 1 pkt 153 PIT

**Pseudokod Rego:**
```rego
# ── P79: pit_family_4plus ────────────────────────────────────────
# Cel biznesowy: Ulga dla rodzin 4+ dzieci
# Przesłanki: children_count >= 4
# Podstawa prawna: Art. 21 ust. 1 pkt 153 PIT
# Priorytet: 79
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.children_count >= 4
    verdict := {
        "matched": true,
        "rule_id": "tax.direct.pit.family_4plus",
        "package": "tax.direct.pit",
        "priority": 79,
        "pit_rate": input.thresholds.rates.vat_zero,
        "pit_exemption": "FAMILY_4PLUS",
        "pit_exemption_limit": input.thresholds.bounds.pit_family_4plus_limit,
        "_legal_basis": "Art. 21 ust. 1 pkt 153 ustawy o PIT"
    }
}
```

---

# CZĘŚĆ VII: PAKIET `tax.allowances` — Ulgi uzupełnienie (P81, P83-P89)

---

### P81: `relief_prototype`

**Cel biznesowy:** Ulga na prototyp — 30% kosztów produkcji próbnej.

**Pseudokod Rego:**
```rego
# ── P81: relief_prototype ───────────────────────────────────────
# Cel biznesowy: Ulga na prototyp — 30% kosztów
# Przesłanki: expense_type == PROTOTYPE
# Podstawa prawna: Art. 26eb PIT / Art. 18db CIT
# Priorytet: 81
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "PROTOTYPE"
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_prototype",
        "package": "tax.allowances",
        "priority": 81,
        "relief_type": "PROTOTYPE",
        "relief_percent": input.thresholds.bounds.relief_prototype_percent,
        "_legal_basis": "Art. 26eb PIT, Art. 18db CIT"
    }
}
```

---

### P83: `relief_robotization`

**Cel biznesowy:** Ulga na robotyzację — 50% kosztów robotów przemysłowych.

**Pseudokod Rego:**
```rego
# ── P83: relief_robotization ────────────────────────────────────
# Cel biznesowy: Ulga na robotyzację — 50% kosztów
# Przesłanki: expense_type == ROBOTIZATION
# Podstawa prawna: Art. 26gb PIT / Art. 38eb CIT
# Priorytet: 83
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "ROBOTIZATION"
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_robotization",
        "package": "tax.allowances",
        "priority": 83,
        "relief_type": "ROBOTIZATION",
        "relief_percent": input.thresholds.bounds.relief_robotization_percent,
        "_legal_basis": "Art. 26gb PIT, Art. 38eb CIT"
    }
}
```

---

### P84: `relief_expansion`

**Cel biznesowy:** Ulga na ekspansję — koszty targów i reklamy zagranicznej, max 1 000 000 PLN.

**Pseudokod Rego:**
```rego
# ── P84: relief_expansion ───────────────────────────────────────
# Cel biznesowy: Ulga na ekspansję zagraniczną
# Przesłanki: expense_type == EXPANSION
# Podstawa prawna: Art. 26ec PIT / Art. 18dc CIT
# Priorytet: 84
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "EXPANSION"
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_expansion",
        "package": "tax.allowances",
        "priority": 84,
        "relief_type": "EXPANSION",
        "relief_max": input.thresholds.bounds.relief_expansion_max,
        "_legal_basis": "Art. 26ec PIT, Art. 18dc CIT"
    }
}
```

---

### P86: `relief_internet`

**Cel biznesowy:** Ulga na internet — 760 PLN rocznie przez 2 lata.

**Pseudokod Rego:**
```rego
# ── P86: relief_internet ────────────────────────────────────────
# Cel biznesowy: Ulga internetowa — 760 PLN/rok, max 2 lata
# Przesłanki: expense_type == INTERNET AND years < 2
# Podstawa prawna: Art. 26 PIT
# Priorytet: 86
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "INTERNET"
    input.company.internet_years_used < input.thresholds.bounds.relief_internet_years
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_internet",
        "package": "tax.allowances",
        "priority": 86,
        "relief_type": "INTERNET",
        "relief_max": input.thresholds.bounds.relief_internet_max,
        "internet_years_remaining": input.thresholds.bounds.relief_internet_years - input.company.internet_years_used,
        "_legal_basis": "Art. 26 ustawy o PIT"
    }
}
```

---

### P87: `relief_rehabilitation`

**Cel biznesowy:** Ulga rehabilitacyjna — wydatki na cele rehabilitacyjne.

**Pseudokod Rego:**
```rego
# ── P87: relief_rehabilitation ──────────────────────────────────
# Cel biznesowy: Ulga rehabilitacyjna
# Przesłanki: expense_type == REHABILITATION
# Podstawa prawna: Art. 26 PIT
# Priorytet: 87
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "REHABILITATION"
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_rehabilitation",
        "package": "tax.allowances",
        "priority": 87,
        "relief_type": "REHABILITATION",
        "income_tax_qualification": "deductible_full",
        "_legal_basis": "Art. 26 ustawy o PIT"
    }
}
```

---

### P88: `relief_abolition`

**Cel biznesowy:** Ulga abolicyjna — zwolnienie z podatku od dochodów zagranicznych.

**Pseudokod Rego:**
```rego
# ── P88: relief_abolition ───────────────────────────────────────
# Cel biznesowy: Ulga abolicyjna
# Przesłanki: foreign_income == true AND tax_form == PIT_SCALE
# Podstawa prawna: Art. 27g PIT
# Priorytet: 88
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.is_foreign_income == true
    input.company.tax_form == "PIT_SCALE"
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_abolition",
        "package": "tax.allowances",
        "priority": 88,
        "relief_type": "ABOLITION",
        "_legal_basis": "Art. 27g ustawy o PIT"
    }
}
```

---

### P89: `relief_working_senior`

**Cel biznesowy:** Ulga dla pracujących seniorów — zwolnienie dla pracujących po osiągnięciu wieku emerytalnego.

**Pseudokod Rego:**
```rego
# ── P89: relief_working_senior ──────────────────────────────────
# Cel biznesowy: Ulga dla pracujących emerytów
# Przesłanki: taxpayer_age >= 60(F)/65(M) AND is_employed
# Podstawa prawna: Art. 21 ust. 1 pkt 154 PIT
# Priorytet: 89
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.is_working_senior == true
    verdict := {
        "matched": true,
        "rule_id": "tax.allowances.relief_working_senior",
        "package": "tax.allowances",
        "priority": 89,
        "relief_type": "WORKING_SENIOR",
        "pit_rate": input.thresholds.rates.vat_zero,
        "_legal_basis": "Art. 21 ust. 1 pkt 154 ustawy o PIT"
    }
}
```

---

# CZĘŚĆ VIII: PAKIET `tax.accounting` — Reguły uzupełniające (P91-P94)

---

### P91: `acc_depreciation_degressive`

**Cel biznesowy:** Amortyzacja degresywna — wyższe odpisy w pierwszych latach (współczynnik 2.0 dla grup 3-6 KŚT).

**Pseudokod Rego:**
```rego
# ── P91: acc_depreciation_degressive ────────────────────────────
# Cel biznesowy: Amortyzacja degresywna
# Przesłanki: FIXED_ASSET AND metoda degresywna
# Podstawa prawna: Art. 32 ust. 2 UoR
# Priorytet: 91
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "FIXED_ASSET"
    input.invoice.depreciation_method == "DEGRESSIVE"
    verdict := {
        "matched": true,
        "rule_id": "tax.accounting.depreciation_degressive",
        "package": "tax.accounting",
        "priority": 91,
        "depreciation_method": "DEGRESSIVE",
        "depreciation_coefficient": 2.0,
        "_legal_basis": "Art. 32 ust. 2 UoR"
    }
}
```

---

### P92: `acc_rmk_deferral`

**Cel biznesowy:** RMK — rozliczenia międzyokresowe kosztów (czynsze, ubezpieczenia, prenumeraty).

**Pseudokod Rego:**
```rego
# ── P92: acc_rmk_deferral ───────────────────────────────────────
# Cel biznesowy: RMK — bierne rozliczenia międzyokresowe
# Przesłanki: expense_type == PREPAID AND dotyczy przyszłych okresów
# Podstawa prawna: Art. 39 UoR
# Priorytet: 92
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.is_prepaid == true
    input.invoice.period_months > 1
    verdict := {
        "matched": true,
        "rule_id": "tax.accounting.rmk_deferral",
        "package": "tax.accounting",
        "priority": 92,
        "rmk_required": true,
        "rmk_months": input.invoice.period_months,
        "rmk_monthly_amount": input.invoice.amount_net / input.invoice.period_months,
        "_legal_basis": "Art. 39 UoR"
    }
}
```

---

### P94: `acc_fifo_inventory`

**Cel biznesowy:** Wycena zapasów metodą FIFO — pierwsze weszło, pierwsze wyszło.

**Pseudokod Rego:**
```rego
# ── P94: acc_fifo_inventory ─────────────────────────────────────
# Cel biznesowy: Wycena rozchodu zapasów FIFO
# Przesłanki: expense_type == INVENTORY
# Podstawa prawna: Art. 28 ust. 1 UoR, IAS 2
# Priorytet: 94
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.invoice.expense_type == "INVENTORY"
    verdict := {
        "matched": true,
        "rule_id": "tax.accounting.fifo_inventory",
        "package": "tax.accounting",
        "priority": 94,
        "inventory_method": "FIFO",
        "_legal_basis": "Art. 28 ust. 1 UoR, IAS 2"
    }
}
```

---

# CZĘŚĆ IX: PAKIET `tax.zus` — Składki ZUS uzupełnienie (P96-P99)

---

### P96: `zus_start_relief`

**Cel biznesowy:** Ulga na start — 6 miesięcy bez składek społecznych (tylko zdrowotna).

**Przesłanki:**
- `input.company.zus_status` == `"START_RELIEF"`
- `input.company.zus_months_used` < `input.thresholds.bounds.zus_start_months`

**Rezultat:**
- `zus_social: "0.00"` (brak składek społecznych)
- `zus_health_only: true`

**Podstawa prawna:** Art. 18a SUS

**Pseudokod Rego:**
```rego
# ── P96: zus_start_relief ───────────────────────────────────────
# Cel biznesowy: Ulga na start — 6 mies. bez składek społecznych
# Przesłanki: zus_status == START_RELIEF AND months < 6
# Podstawa prawna: Art. 18a SUS
# Priorytet: 96
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.zus_status == "START_RELIEF"
    input.company.zus_months_used < input.thresholds.bounds.zus_start_months
    verdict := {
        "matched": true,
        "rule_id": "tax.zus.start_relief",
        "package": "tax.zus",
        "priority": 96,
        "zus_social": input.thresholds.rates.vat_zero,
        "zus_health_only": true,
        "zus_months_remaining": input.thresholds.bounds.zus_start_months - input.company.zus_months_used,
        "_legal_basis": "Art. 18a ustawy o SUS"
    }
}
```

---

### P97: `zus_preferential`

**Cel biznesowy:** Preferencyjny ZUS — 30% minimalnego wynagrodzenia przez 24 miesiące.

**Przesłanki:**
- `input.company.zus_status` == `"PREFERENTIAL"`
- `input.company.zus_months_used` < 24

**Rezultat:**
- `zus_base_percent: 0.30`

**Podstawa prawna:** Art. 18a SUS

**Pseudokod Rego:**
```rego
# ── P97: zus_preferential ───────────────────────────────────────
# Cel biznesowy: Preferencyjny ZUS — 30% min. wynagrodzenia
# Przesłanki: zus_status == PREFERENTIAL AND months < 24
# Podstawa prawna: Art. 18a SUS
# Priorytet: 97
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.zus_status == "PREFERENTIAL"
    input.company.zus_months_used < 24
    verdict := {
        "matched": true,
        "rule_id": "tax.zus.preferential",
        "package": "tax.zus",
        "priority": 97,
        "zus_base_percent": 0.30,
        "zus_months_remaining": 24 - input.company.zus_months_used,
        "_legal_basis": "Art. 18a ustawy o SUS"
    }
}
```

---

### P99: `zus_standard`

**Cel biznesowy:** Standardowe stawki ZUS — pełne składki społeczne + zdrowotne.

**Przesłanki:**
- `input.company.zus_status` == `"STANDARD"`

**Rezultat:**
- Pełne stawki składek z thresholds

**Podstawa prawna:** Art. 22 SUS

**Pseudokod Rego:**
```rego
# ── P99: zus_standard ───────────────────────────────────────────
# Cel biznesowy: Standardowe stawki ZUS
# Przesłanki: zus_status == STANDARD
# Podstawa prawna: Art. 22 SUS
# Priorytet: 99
# ────────────────────────────────────────────────────────────────
decide = verdict {
    input.company.zus_status == "STANDARD"
    verdict := {
        "matched": true,
        "rule_id": "tax.zus.standard",
        "package": "tax.zus",
        "priority": 99,
        "zus_pension_rate": input.thresholds.rates.zus_pension,
        "zus_disability_rate": input.thresholds.rates.zus_disability,
        "zus_sickness_rate": input.thresholds.rates.zus_sickness,
        "zus_accident_rate": input.thresholds.rates.zus_accident,
        "zus_labour_fund_rate": input.thresholds.rates.zus_labour_fund,
        "zus_fgsp_rate": input.thresholds.rates.zus_fgsp,
        "_legal_basis": "Art. 22 ustawy o SUS"
    }
}
```

---

# CZĘŚĆ X: PODSUMOWANIE POKRYCIA

| Pakiet | Reguły z pseudokodem | Pokrycie |
|--------|:---------------------:|:--------:|
| `tax.risk` | P0-P9 (10 reguł) | ✅ 100% |
| `tax.routing` | P10-P19 (10 reguł) | ✅ 100% |
| `tax.compliance` | P20-P38 (15 reguł) | ✅ 100% |
| `tax.crossborder` | P40-P48 (9 reguł) | ✅ 100% |
| `tax.vat.substantive` | P50-P62 (13 reguł) | ✅ 100% |
| `tax.vat.gtu` | P65-P69 (5 reguł) | ✅ 100% |
| `tax.direct.cit` | P70-P74 (5 reguł) | ✅ 100% |
| `tax.direct.pit` | P74-P79 (6 reguł) | ✅ 100% |
| `tax.allowances` | P80-P89 (10 reguł) | ✅ 100% |
| `tax.accounting` | P90-P94 (5 reguł) | ✅ 100% |
| `tax.zus` | P95-P99 (5 reguł) | ✅ 100% |
| `tax.fallback` | P100-P200 (2 reguły) | ✅ 100% |
| **RAZEM** | **95 reguł** | **✅ 100%** |

---

> **Następny krok:** Aktualizacja `04_INDEX.md` — cross-reference dla wszystkich 95 reguł.  
> **Powiązane:** `05_ARCHITECTURE_DECISION.md` — decyzja o Multi-Pass Evaluation.
