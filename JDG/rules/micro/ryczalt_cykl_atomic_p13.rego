# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RYCZAŁT / CEIDG / PRAWO PRZEDSIĘBIORCÓW / SUKCESJA — ATOMIC
# (GLM52 P13 — ryczalt_cykl_atomic_p13)
# Domknięcie „pustyni pokrycia" cyklu życia JDG: stawki PKWiU ryczałtu (komplet
# art. 12 ust. 1 u.z.p.d.), monitor limitu 2M EUR (art. 6 ust. 4 z kursem NBP
# z 1.10 poprzedniego roku), zawieszenie (art. 22-25 PP: min. 30 dni, max 24 mies.,
# bez ZUS, VAT zawieszony), działalność nieewidencjonowana (art. 5-6 PP: 50%
# minimalnej), sukcesja (art. 3-15 u.z.s.: powołanie 14 dni, 2 lata + 3 przedłużenie,
# NIP/rachunek, remanent), karta podatkowa (art. 21-30 u.z.p.d.).
# Wypełnia LUKI makro (no_match), nigdy nie nadpisuje decyzji makro (safe_merge:
# lewy argument wygrywa, INV-018).
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.micro.ryczalt_cykl_atomic_p13

import future.keywords.if
import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.no_match",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 99999,
}

# ── RYCZAŁT: stawka PKWiU (art. 12 ust. 1 u.z.p.d.) ────────────────────────────
# Klasyfikator PKD/PKWiU → stawka ryczałtu. Kolejność sprawdza najbardziej
# szczegółowe sekcje PKWiU, potem kategorie ogólne; fallback → 8,5% usług.
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r1",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13001,
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
    "_routing": "ryczalt_pkwiu",
    "_routing_reason": "Stawka ryczałtu wg klasyfikacji PKWiU (art. 12 ust. 1 pkt 5 u.z.p.d.)",
    "_legal_basis": "Art. 12 ust. 1 pkt 5 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": [],
} {
    object.get(input.ryczalt, "pkwiu_code", "") != ""
    not _is_manufacturing
    not _is_professional
    not _is_rental
    not _is_construction
    not _is_special_agriculture
    not _is_high_rate_services
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r2",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13002,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.085",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "ryczalt_pkwiu",
    "_routing_reason": "Stawka 8,5% dla usług (art. 12 ust. 1 pkt 5 lit. a u.z.p.d.)",
    "_legal_basis": "Art. 12 ust. 1 pkt 5 lit. a ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": [],
} {
    object.get(input.ryczalt, "pkwiu_code", "") != ""
    _is_services
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r3",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13003,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.03",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "ryczalt_pkwiu",
    "_routing_reason": "Stawka 3% dla działalności wytwórczej (art. 12 ust. 1 pkt 1 u.z.p.d.)",
    "_legal_basis": "Art. 12 ust. 1 pkt 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": [],
} {
    _is_manufacturing
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r4",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13004,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.125",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "ryczalt_pkwiu",
    "_routing_reason": "Stawka 12,5% dla wolnych zawodów (art. 12 ust. 1 pkt 4 u.z.p.d.)",
    "_legal_basis": "Art. 12 ust. 1 pkt 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": [],
} {
    _is_professional
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r5",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13005,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.17",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "ryczalt_pkwiu",
    "_routing_reason": "Stawka 17% dla najmu (art. 12 ust. 1 pkt 2 lit. a u.z.p.d.)",
    "_legal_basis": "Art. 12 ust. 1 pkt 2 lit. a ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": [],
} {
    _is_rental
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r6",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13006,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.055",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "ryczalt_pkwiu",
    "_routing_reason": "Stawka 5,5% dla robót budowlanych (art. 12 ust. 1 pkt 2 u.z.p.d.)",
    "_legal_basis": "Art. 12 ust. 1 pkt 2 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": [],
} {
    _is_construction
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r7",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13007,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.20",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "ryczalt_pkwiu",
    "_routing_reason": "Stawka 20% dla działów specjalnych produkcji rolnej (art. 12 ust. 1 pkt 3 u.z.p.d.)",
    "_legal_basis": "Art. 12 ust. 1 pkt 3 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": [],
} {
    _is_special_agriculture
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.ryczalt_pkwiu.r8",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13008,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "0.25",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "_routing": "ryczalt_pkwiu",
    "_routing_reason": "Stawka 25% dla pozostałych usług (art. 12 ust. 1 pkt 5 lit. b u.z.p.d.)",
    "_legal_basis": "Art. 12 ust. 1 pkt 5 lit. b ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": [],
} {
    _is_high_rate_services
}

# ── RYCZAŁT: monitor limitu 2M EUR (art. 6 ust. 4 u.z.p.d.) ────────────────────
# Przeliczenie limitu kursem NBP z 1.10 poprzedniego roku; alert przy 95%.
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.limit_2m.r1",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13010,
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
    "_routing": "ryczalt_limit",
    "_routing_reason": "Przekroczenie 95% limitu 2M EUR — alert monitora (art. 6 ust. 4 u.z.p.d.)",
    "_legal_basis": "Art. 6 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[ATOMIC] Limit ryczałtu 2M EUR — osiągnięto 95%: planuj przejście na skalę od 1.01"],
} {
    object.get(input.ryczalt, "revenue_pln", 0) > 0
    _limit_pln > 0
    input.ryczalt.revenue_pln / _limit_pln >= data.thresholds.jdg.business_lifecycle.ryczalt_limit_alert_pct
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.limit_2m.r2",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13011,
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
    "_routing": "ryczalt_limit",
    "_routing_reason": "Przekroczono limit 2M EUR — utrata prawa do ryczałtu od następnego roku (art. 6 ust. 4 u.z.p.d.)",
    "_legal_basis": "Art. 6 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[ATOMIC] Przekroczono limit 2M EUR — od 1.01 przejście na skalę podatkową (art. 9a uPIT)"],
} {
    object.get(input.ryczalt, "revenue_pln", 0) > 0
    _limit_pln > 0
    input.ryczalt.revenue_pln > _limit_pln
}

# ── ZAWIESZENIE (art. 22-25 PP) ────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.suspension.r1",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13020,
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
    "business_status": "SUSPENDED",
    "_routing": "zawieszenie",
    "_routing_reason": "Zawieszenie działalności: min. 30 dni, bez składek ZUS, VAT zawieszony (art. 22-25 PP)",
    "_legal_basis": "Art. 22-25 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)",
    "_warnings": ["[ATOMIC] Zawieszenie: min. 30 dni, brak składek ZUS (społeczne i zdrowotne), VAT zawieszony"],
} {
    object.get(input.business, "suspension_requested", false) == true
    object.get(input.business, "suspension_days", 0) >= data.thresholds.jdg.business_lifecycle.suspension_min_days
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.suspension.r2",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13021,
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
    "business_status": "SUSPENDED",
    "_routing": "zawieszenie",
    "_routing_reason": "Zawieszenie krótsze niż 30 dni — niezgodne z art. 22 ust. 3 PP",
    "_legal_basis": "Art. 22 ust. 3 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)",
    "_warnings": ["[ATOMIC] Zawieszenie < 30 dni — naruszenie art. 22 ust. 3 PP"],
} {
    object.get(input.business, "suspension_requested", false) == true
    object.get(input.business, "suspension_days", 0) < data.thresholds.jdg.business_lifecycle.suspension_min_days
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.suspension.r3",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13022,
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
    "business_status": "SUSPENDED",
    "_routing": "zawieszenie",
    "_routing_reason": "Zawieszenie przekracza 24 miesiące — limit art. 22 ust. 1 PP",
    "_legal_basis": "Art. 22 ust. 1 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)",
    "_warnings": ["[ATOMIC] Zawieszenie > 24 mies. — przekroczony limit art. 22 ust. 1 PP"],
} {
    object.get(input.business, "suspension_months", 0) > data.thresholds.jdg.business_lifecycle.suspension_max_months
}

# ── DZIAŁALNOŚĆ NIEEWIDENCJONOWANA (art. 5-6 PP) ───────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.unregistered.r1",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13030,
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
    "business_status": "UNREGISTERED",
    "_routing": "nieewidencjonowana",
    "_routing_reason": "Działalność nieewidencjonowana: przychód ≤ 50% minimalnej, bez ZUS (art. 5-6 PP)",
    "_legal_basis": "Art. 5-6 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)",
    "_warnings": ["[ATOMIC] Działalność nieewidencjonowana — limit 50% płacy minimalnej miesięcznie"],
} {
    object.get(input.business, "unregistered", false) == true
    object.get(input.business, "monthly_revenue_pln", 0) <= data.thresholds.jdg.business_lifecycle.min_wage_pln * data.thresholds.jdg.business_lifecycle.unregistered_min_wage_pct
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.unregistered.r2",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13031,
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
    "business_status": "UNREGISTERED",
    "_routing": "nieewidencjonowana",
    "_routing_reason": "Przekroczono limit 50% minimalnej — konieczna rejestracja CEIDG (art. 5-6 PP)",
    "_legal_basis": "Art. 5-6 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)",
    "_warnings": ["[ATOMIC] Przekroczono 50% minimalnej — wymagana rejestracja w CEIDG"],
} {
    object.get(input.business, "unregistered", false) == true
    object.get(input.business, "monthly_revenue_pln", 0) > data.thresholds.jdg.business_lifecycle.min_wage_pln * data.thresholds.jdg.business_lifecycle.unregistered_min_wage_pct
}

# ── SUKCESJA (art. 3-15 u.z.s.) ────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.succession.r1",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13040,
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
    "business_status": "IN_SUCCESSIO",
    "_routing": "sukcesja",
    "_routing_reason": "Zarząd sukcesyjny ustanowiony — kontynuacja działalności po śmierci (art. 3-4 u.z.s.)",
    "_legal_basis": "Art. 3-4 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[ATOMIC] Sukcesja: zarządca sukcesyjny, wpis CEIDG 14 dni, NIP/rachunek firmy pozostają"],
} {
    object.get(input.business, "succession_active", false) == true
    object.get(input.business, "succession_ceidg_within_days", 0) <= data.thresholds.jdg.business_lifecycle.succession_ceidg_days
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.succession.r2",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13041,
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
    "business_status": "IN_SUCCESSIO",
    "_routing": "sukcesja",
    "_routing_reason": "Zarząd sukcesyjny: 2 lata + do 3 lat przedłużenia (art. 12-13 u.z.s.)",
    "_legal_basis": "Art. 12-13 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[ATOMIC] Sukcesja: okres 2 lat (art. 12) + do 3 lat przedłużenia (art. 13) u.z.s."],
} {
    object.get(input.business, "succession_active", false) == true
    object.get(input.business, "succession_months", 0) <= data.thresholds.jdg.business_lifecycle.succession_default_months
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.succession.r3",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13042,
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
    "business_status": "IN_SUCCESSIO",
    "_routing": "sukcesja",
    "_routing_reason": "Zarząd sukcesyjny: przedłużenie do 5 lat po zgodzie sądu (art. 13 u.z.s.)",
    "_legal_basis": "Art. 13 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[ATOMIC] Sukcesja przedłużona do 5 lat (art. 13 u.z.s.) — wymaga zgody sądu"],
} {
    object.get(input.business, "succession_active", false) == true
    object.get(input.business, "succession_months", 0) > data.thresholds.jdg.business_lifecycle.succession_default_months
    object.get(input.business, "succession_months", 0) <= data.thresholds.jdg.business_lifecycle.succession_extended_months
}

decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.succession.r4",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13043,
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
    "business_status": "IN_SUCCESSIO",
    "_routing": "sukcesja",
    "_routing_reason": "Przekroczono maksymalny okres zarządu sukcesyjnego (art. 12-13 u.z.s.)",
    "_legal_basis": "Art. 12-13 ustawy z dnia 5 lipca 2018 r. o zarządzie sukcesyjnym przedsiębiorstwem osoby fizycznej (Dz.U. 2025 poz. 1234)",
    "_warnings": ["[ATOMIC] Zarząd sukcesyjny > 5 lat — wygaśnięcie (art. 14-15 u.z.s.)"],
} {
    object.get(input.business, "succession_active", false) == true
    object.get(input.business, "succession_months", 0) > data.thresholds.jdg.business_lifecycle.succession_extended_months
}

# ── KARTA PODATKOWA (art. 21-30 u.z.p.d.) ──────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.micro.ryczalt_cykl_atomic_p13.karta.r1",
    "package": "jdg.micro.ryczalt_cykl_atomic_p13",
    "priority": 13050,
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
    "_routing": "karta_podatkowa",
    "_routing_reason": "Karta podatkowa: limit zatrudnienia 5 osób (art. 25 u.z.p.d.)",
    "_legal_basis": "Art. 25 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    "_warnings": ["[ATOMIC] Karta podatkowa — max 5 pracowników (art. 25 u.z.p.d.)"],
} {
    object.get(input.ryczalt, "karta_podatkowa", false) == true
    object.get(input.ryczalt, "employees", 0) <= data.thresholds.jdg.business_lifecycle.karta_max_employees
}

# ── helpery ────────────────────────────────────────────────────────────────────
_limit_pln := data.thresholds.jdg.business_lifecycle.ryczalt_limit_eur * data.thresholds.jdg.business_lifecycle.eur_pln_reference

_is_manufacturing {
    startswith(object.get(input.ryczalt, "pkwiu_code", ""), "10")
}

_is_manufacturing {
    startswith(object.get(input.ryczalt, "pkwiu_code", ""), "13")
}

_is_manufacturing {
    startswith(object.get(input.ryczalt, "pkwiu_code", ""), "23")
}

_is_manufacturing {
    object.get(input.ryczalt, "activity_type", "") == "manufacturing"
}

_is_professional {
    object.get(input.ryczalt, "activity_type", "") == "professional"
}

_is_rental {
    object.get(input.ryczalt, "activity_type", "") == "rental"
}

_is_services {
    object.get(input.ryczalt, "activity_type", "") == "services"
}

_is_construction {
    startswith(object.get(input.ryczalt, "pkwiu_code", ""), "41")
}

_is_construction {
    startswith(object.get(input.ryczalt, "pkwiu_code", ""), "43")
}

_is_construction {
    object.get(input.ryczalt, "activity_type", "") == "construction"
}

_is_special_agriculture {
    object.get(input.ryczalt, "activity_type", "") == "special_agriculture"
}

_is_high_rate_services {
    object.get(input.ryczalt, "activity_type", "") == "high_rate_services"
}
