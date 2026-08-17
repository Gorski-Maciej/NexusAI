# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PCC / PODATKI LOKALNE / AKCYZA / PODATEK ROLNY — ATOMIC
# (GLM52 P14 — pcc_lokalne_atomic_p14)
# Domknięcie największej luki pokrycia (LEGAL_COVERAGE IX ~1%, 225 punktów
# prawnych): PCC (art. 1-10 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789) — stawki 0,5-2%, wyłączenie VAT art. 2
# pkt 4, zwolnienie ≤1000 zł art. 9, PCC-3 w 14 dni art. 10), podatek od
# nieruchomości (art. 5 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234) — stawki gminne biznes vs mieszkalna, DN-1),
# środki transportowe (art. 8-14 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234) — >3,5 t, DT-1), akcyza (paliwa/
# alkohol/energia — art. 89-99 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220), skład podatkowy art. 16, e-DD),
# podatek rolny (2,5 q żyta × cena MRiRW).
# Wypełnia LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge:
# lewy argument wygrywa, INV-018).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.micro.pcc_lokalne_atomic_p14

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.no_match",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 99999,
}

# ── PCC: stawki i obowiązek (art. 1-10 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)) ──────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.pcc_sale.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14001,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "pcc_rate_pct": _pcc_sale_rate * 100,
    "pcc_tax_due": _round2(_amount * _pcc_sale_rate),
    "pcc3_deadline_days": _pcc3_days,
    "_routing": "pcc_sale",
    "_routing_reason": "Umowa sprzedaży rzeczy/praw majątkowych — PCC 2% (art. 7 ust. 1 pkt 1 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789))",
    "_legal_basis": "Art. 7 ust. 1 pkt 1 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
    "_warnings": ["[ATOMIC] PCC 2% od sprzedaży — PCC-3 w 14 dni (art. 10 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789))"],
} {
    object.get(input.pcc, "transaction_type", "") == "sale"
    _amount > 0
    not _vat_applicable
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.pcc_loan.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "pcc_rate_pct": _pcc_loan_rate * 100,
    "pcc_tax_due": _round2(_amount * _pcc_loan_rate),
    "pcc3_deadline_days": _pcc3_days,
    "_routing": "pcc_loan",
    "_routing_reason": "Umowa pożyczki — PCC 0,5% (art. 7 ust. 1 pkt 4 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789))",
    "_legal_basis": "Art. 7 ust. 1 pkt 4 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
    "_warnings": ["[ATOMIC] PCC 0,5% od pożyczki — PCC-3 w 14 dni"],
} {
    object.get(input.pcc, "transaction_type", "") == "loan"
    _amount > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.pcc_company.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "pcc_rate_pct": _pcc_company_rate * 100,
    "pcc_tax_due": _round2(_amount * _pcc_company_rate),
    "pcc3_deadline_days": _pcc3_days,
    "_routing": "pcc_company",
    "_routing_reason": "Umowa spółki — PCC 0,5% (art. 7 ust. 1 pkt 9 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789))",
    "_legal_basis": "Art. 7 ust. 1 pkt 9 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
    "_warnings": ["[ATOMIC] PCC 0,5% od umowy spółki — PCC-3 w 14 dni"],
} {
    object.get(input.pcc, "transaction_type", "") == "company"
    _amount > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.pcc_vat_exclusion.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14010,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "pcc_rate_pct": 0,
    "pcc_tax_due": 0,
    "_routing": "pcc_vat_exclusion",
    "_routing_reason": "Transakcja objęta VAT — wyłączona z PCC (art. 2 pkt 4 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789))",
    "_legal_basis": "Art. 2 pkt 4 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
    "_warnings": ["[ATOMIC] Czynność objęta VAT nie podlega PCC — arbiter VAT vs PCC"],
} {
    object.get(input.pcc, "transaction_type", "") != ""
    _vat_applicable
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.pcc_small_value.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14011,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "pcc_rate_pct": 0,
    "pcc_tax_due": 0,
    "_routing": "pcc_small_value",
    "_routing_reason": "Kwota ≤ 1000 zł — zwolniona z PCC (art. 9 pkt 1 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789))",
    "_legal_basis": "Art. 9 pkt 1 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
    "_warnings": ["[ATOMIC] PCC zwolniony — wartość ≤ 1000 zł"],
} {
    object.get(input.pcc, "transaction_type", "") != ""
    _amount > 0
    _amount <= _pcc_exemption_limit
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.pcc3_deadline.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14012,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "pcc3_days_elapsed": _days_elapsed,
    "pcc3_days_remaining": _pcc3_days - _days_elapsed,
    "_routing": "pcc3_deadline",
    "_routing_reason": "PCC-3 — deklaracja w 14 dni od powstania obowiązku (art. 10 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789))",
    "_legal_basis": "Art. 10 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
    "_warnings": ["[ATOMIC] PCC-3 wymagany — 14 dni od czynności"],
} {
    object.get(input.pcc, "transaction_type", "") != ""
    _days_elapsed >= 0
    _days_elapsed <= _pcc3_days
}

# ── PODATKI LOKALNE: nieruchomości + transport (ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)) ─────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.real_estate_building.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14020,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "local_tax_annual": _round2(_area_m2 * _building_business_rate),
    "_routing": "real_estate_building",
    "_routing_reason": "Budynek firmowy — podatek od nieruchomości wg stawki gminnej (art. 5 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234))",
    "_legal_basis": "Art. 5 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[ATOMIC] Podatek od nieruchomości — budynek firmowy, DN-1 w 14 dni"],
} {
    object.get(input.local, "property_type", "") == "building_business"
    _area_m2 > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.real_estate_land.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14021,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "local_tax_annual": _round2(_area_m2 * _land_business_rate),
    "_routing": "real_estate_land",
    "_routing_reason": "Grunt firmowy — podatek od nieruchomości wg stawki gminnej (art. 5 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234))",
    "_legal_basis": "Art. 5 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[ATOMIC] Podatek od nieruchomości — grunt firmowy, DN-1 w 14 dni"],
} {
    object.get(input.local, "property_type", "") == "land_business"
    _area_m2 > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.transport_heavy.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14030,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "transport_taxable": true,
    "_routing": "transport_heavy",
    "_routing_reason": "Pojazd >3,5 t — podatek od środków transportowych (art. 8 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234))",
    "_legal_basis": "Art. 8 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[ATOMIC] Podatek od środków transportowych — pojazd >3,5 t, DT-1"],
} {
    object.get(input.local, "gvw_t", 0) > _transport_heavy_threshold_t
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.dn1_deadline.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14031,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "dn1_deadline_days": _dn1_days,
    "_routing": "dn1_deadline",
    "_routing_reason": "DN-1 — deklaracja na podatek od nieruchomości (art. 6 ust. 9 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234))",
    "_legal_basis": "Art. 6 ust. 9 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[ATOMIC] DN-1 w 14 dni od nabycia/zmiany nieruchomości"],
} {
    object.get(input.local, "dn1_required", false) == true
}

# ── AKCYZA: paliwa / alkohol / energia (u. akcyzowa) ──────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.excise_gasoline.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14040,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "excise_due": _round2(_volume_l / 1000 * _excise_gasoline),
    "_routing": "excise_gasoline",
    "_routing_reason": "Benzyna — akcyza wg stawki 2026 (art. 89 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))",
    "_legal_basis": "Art. 89 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)",
    "_warnings": ["[ATOMIC] Akcyza paliwowa — benzyna, AKC-4 do 25. dnia"],
} {
    object.get(input.akcyza, "product", "") == "gasoline"
    _volume_l > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.excise_diesel.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14041,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "excise_due": _round2(_volume_l / 1000 * _excise_diesel),
    "_routing": "excise_diesel",
    "_routing_reason": "Olej napędowy — akcyza wg stawki 2026 (art. 89 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))",
    "_legal_basis": "Art. 89 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)",
    "_warnings": ["[ATOMIC] Akcyza paliwowa — ON, AKC-4 do 25. dnia"],
} {
    object.get(input.akcyza, "product", "") == "diesel"
    _volume_l > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.excise_ethanol.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14042,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "excise_due": _round2(_volume_hl * _excise_ethanol),
    "_routing": "excise_ethanol",
    "_routing_reason": "Alkohol etylowy — akcyza wg stawki 2026 (art. 93 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))",
    "_legal_basis": "Art. 93 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)",
    "_warnings": ["[ATOMIC] Akcyza alkoholowa — skład podatkowy wymagany"],
} {
    object.get(input.akcyza, "product", "") == "ethanol"
    _volume_hl > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.excise_wine.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14043,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "excise_due": _round2(_volume_hl * _excise_wine),
    "_routing": "excise_wine",
    "_routing_reason": "Wino — akcyza wg stawki 2026 (art. 95 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))",
    "_legal_basis": "Art. 95 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)",
    "_warnings": ["[ATOMIC] Akcyza od wina"],
} {
    object.get(input.akcyza, "product", "") == "wine"
    _volume_hl > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.excise_beer.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14044,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "excise_due": _round2(_volume_hl * _excise_beer),
    "_routing": "excise_beer",
    "_routing_reason": "Piwo — akcyza wg stawki 2026 (art. 94 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))",
    "_legal_basis": "Art. 94 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)",
    "_warnings": ["[ATOMIC] Akcyza od piwa"],
} {
    object.get(input.akcyza, "product", "") == "beer"
    _volume_hl > 0
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.excise_warehouse.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14050,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "excise_warehouse_required": true,
    "_routing": "excise_warehouse",
    "_routing_reason": "Produkcja wyrobów akcyzowych — skład podatkowy wymagany (art. 16 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))",
    "_legal_basis": "Art. 16 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)",
    "_warnings": ["[ATOMIC] Produkcja alkoholu/paliw bez składu podatkowego = przestępstwo skarbowe (art. 65 KKS)"],
} {
    object.get(input.akcyza, "produces", false) == true
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.excise_energy.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14051,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "excise_energy_note": "Akcyza od energii elektrycznej — stawka za MWh (art. 9 ust. 1 pkt 2 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))",
    "_routing": "excise_energy",
    "_routing_reason": "Energia elektryczna — wyroby akcyzowe (art. 9 ust. 1 pkt 2 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220))",
    "_legal_basis": "Art. 9 ust. 1 pkt 2 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2025 poz. 1220)",
    "_warnings": ["[ATOMIC] Energia elektryczna podlega akcyzie"],
} {
    object.get(input.akcyza, "energy_electricity", false) == true
}

# ── PODATEK ROLNY ─────────────────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.pcc_lokalne_atomic_p14.agricultural_tax.r1",
    "package": "jdg.micro.pcc_lokalne_atomic_p14",
    "priority": 14060,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "agricultural_tax_annual": _round2(_hectares * _rye_quintals_per_ha * _rye_price_per_quintal),
    "_routing": "agricultural_tax",
    "_routing_reason": "Podatek rolny — 2,5 q żyta × cena MRiRW (ustawa o podatku rolnym)",
    "_legal_basis": "Ustawa z dnia 15 listopada 1984 r. o podatku rolnym (t.j. ze zm.)",
    "_warnings": ["[ATOMIC] Podatek rolny — przelicznik 2,5 q żyta/ha, cena wg komunikatu MRiRW"],
} {
    object.get(input.rolny, "hectares", 0) > 0
}

# ── helpery ───────────────────────────────────────────────────────────────────
_amount := to_number(object.get(input.pcc, "amount", 0))
_vat_applicable := object.get(input.pcc, "vat_applicable", false) == true
_days_elapsed := to_number(object.get(input.pcc, "days_elapsed", 0))
_area_m2 := to_number(object.get(input.local, "area_m2", 0))
_volume_l := to_number(object.get(input.akcyza, "volume_l", 0))
_volume_hl := to_number(object.get(input.akcyza, "volume_hl", 0))
_hectares := to_number(object.get(input.rolny, "hectares", 0))

_pcc_sale_rate := data.thresholds.jdg.pcc_local_excise.pcc_sale_rate
_pcc_loan_rate := data.thresholds.jdg.pcc_local_excise.pcc_loan_rate
_pcc_company_rate := data.thresholds.jdg.pcc_local_excise.pcc_company_rate
_pcc_exemption_limit := data.thresholds.jdg.pcc_local_excise.pcc_exemption_limit
_pcc3_days := data.thresholds.jdg.pcc_local_excise.pcc3_deadline_days
_land_business_rate := data.thresholds.jdg.pcc_local_excise.land_business_rate
_building_business_rate := data.thresholds.jdg.pcc_local_excise.building_business_rate
_transport_heavy_threshold_t := 3.5
_dn1_days := data.thresholds.jdg.pcc_local_excise.transport_dn1_deadline_days
_excise_gasoline := data.thresholds.jdg.pcc_local_excise.excise_gasoline
_excise_diesel := data.thresholds.jdg.pcc_local_excise.excise_diesel
_excise_ethanol := data.thresholds.jdg.pcc_local_excise.excise_ethanol_per_hl
_excise_wine := data.thresholds.jdg.pcc_local_excise.excise_wine_per_hl
_excise_beer := data.thresholds.jdg.pcc_local_excise.excise_beer_per_plato
_rye_quintals_per_ha := 2.5
_rye_price_per_quintal := 89.63

_round2(x) = r {
    r := round(x * 100) / 100
}
