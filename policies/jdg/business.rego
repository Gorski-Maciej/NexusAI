# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Business: CEIDG, zawieszenie, sukcesja (P900-P939)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Business Lifecycle Package — CEIDG, Suspension, Succession
# description: |
#   Reguły cyklu życia JDG. Kolejność: P900 (CEIDG) → P902 (aktualizacja) →
#   P910 (zawieszenie) → P912 (KUP w zawieszeniu) →
#   P914 (ZUS w zawieszeniu — społeczne=0, zdrowotna NADAL!) →
#   P920 (sukcesja) → P930 (limit nieewidencjonowanej) → P932 (ZUS exemption).
#   Architektura: object.union — business.decide mergowane PO zus.decide
#   (P914 nie ustawia zus_health_rate, pozwala ZUS-owi zachować stawkę).
# legal_basis: Art. 5-7 CEIDG, Art. 22-25 Prawa przedsiębiorców, Art. 36a SUS
# edge_cases:
#   - Zawieszenie: społeczne=0, zdrowotna NADAL (Art. 36a SUS)
#   - Dział. nieewidencjonowana: limit 50% min. wynagrodzenia
#   - Sukcesja: NIP zmarłego + "w spadku"
# package: jdg.business
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.business
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.business.no_match","package":"jdg.business","priority":949}

# ══════ P900: ceidg_registration_check — Obowiązek rejestracji CEIDG ══════
decide := {
    "matched":true,"rule_id":"jdg.business.ceidg_registration_check",
    "package":"jdg.business","priority":900,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"", "ceidg_registration_required":true,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Brak rejestracji CEIDG",
    "_legal_basis":"Art. 5-7 ustawy o CEIDG",
    "_warnings":["BRAK REJESTRACJI CEIDG — każda JDG musi być wpisana do CEIDG!"]
} {
    input.jdg_entrepreneur.ceidg_entry_date == null
}

# ══════ P902: ceidg_data_change_notification — Aktualizacja CEIDG 7 dni ══════
else := {
    "matched":true,"rule_id":"jdg.business.ceidg_data_change_overdue",
    "package":"jdg.business","priority":902,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","ceidg_update_overdue":true,
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":"Aktualizacja CEIDG przeterminowana",
    "_legal_basis":"Art. 12-15 ustawy o CEIDG",
    "_warnings":["Aktualizacja CEIDG przeterminowana — obowiązek w ciągu 7 dni od zmiany danych!"]
} {
    input.jdg_entrepreneur.ceidg_last_update_date != null
    # Data ostatniej aktualizacji starsza niż 7 dni od zmiany formy opodatkowania
    input.jdg_entrepreneur.tax_form_change_date != ""
}

# ══════ P910: business_suspension_valid — Zawieszenie JDG ══════
else := {
    "matched":true,"rule_id":"jdg.business.suspension_valid",
    "package":"jdg.business","priority":910,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"SUSPENDED",
    "ceidg_registration_required":false,
    "pit_advance_required":false,"vat_declaration_required":false,"kus_allowed":"MAINTENANCE_ONLY",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22-25 Prawa przedsiębiorców, Art. 44 ust. 10 PIT",
    "_warnings":["Działalność zawieszona — brak zaliczek PIT, deklaracje VAT tylko przy sprzedaży"]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
}

# ══════ P912: business_suspension_kup_restrictions ══════
else := {
    "matched":true,"rule_id":"jdg.business.suspension_kup_restrictions",
    "package":"jdg.business","priority":912,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"none","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"SUSPENDED",
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Wydatek niedozwolony w okresie zawieszenia",
    "_legal_basis":"Art. 22-25 Prawa przedsiębiorców",
    "_warnings":["Zawieszenie — dozwolone TYLKO stałe koszty utrzymania (czynsz, media, monitoring)"]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    input.invoice.expense_type not in {"RENT","UTILITIES","SECURITY","LEASE_EXISTING","INSURANCE","ACCOUNTING"}
    input.invoice.direction == "PURCHASE"
}

# ══════ P914: business_suspension_zus — Zawieszenie → społeczne=0, zdrowotna NADAL ══════
# Architektura: main_jdg.rego używa object.union (multi-pass). Ponieważ business.decide
# jest mergowane PO zus.decide, usunięcie zus_health_rate z P914 sprawia, że object.union
# zachowuje stawkę zdrowotną już ustawioną przez pakiet zus (P720/P722/P724).
# ⚠️ Edge case: jeśli zus.decide zwróci default no_match (brak zus_health_rate),
# merged verdict będzie miał zus_health_due:true bez stawki. W praktyce nie występuje
# (P720-P724 pokrywają wszystkie 4 formy opodatkowania), ale warto mieć świadomość.
else := {
    "matched":true,"rule_id":"jdg.business.suspension_zus",
    "package":"jdg.business","priority":914,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_due":false,"zus_health_due":true,
    "zus_social_base_type":"SUSPENDED",
    "business_status":"SUSPENDED",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 36a ustawy o SUS (społeczne=0, ALE zdrowotna NADAL należna!)",
    "_warnings":["Zawieszenie — ZUS społeczne=0 (składka zdrowotna NADAL należna wg stawki z pakietu zus)"],
    "_future_events":[
        {
            "event_id":"suspension_health_quarterly",
            "event_type":"TAX_OBLIGATION",
            "description":"Kwartalna składka zdrowotna w okresie zawieszenia",
            "due_date_horizon":"+30d",
            "action":"PAY_ZUS_HEALTH",
            "priority":"HIGH"
        },
        {
            "event_id":"suspension_end_reactivation",
            "event_type":"COMPLIANCE_CHECK",
            "description":"Wznów pełne składki ZUS po zakończeniu zawieszenia",
            "due_date_horizon":"on_resume",
            "action":"RESTORE_FULL_ZUS",
            "priority":"CRITICAL"
        }
    ]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
}

# ══════ P920: succession_continuity — Sukcesja po śmierci ══════
else := {
    "matched":true,"rule_id":"jdg.business.succession_continuity",
    "package":"jdg.business","priority":920,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"IN_SUCCESSIO","nip_status":"DECEASED_IN_SUCCESSIO",
    "succession_manager_active":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Ustawa o zarządzie sukcesyjnym",
    "_warnings":["Sukcesja — działalność kontynuowana przez zarządcę sukcesyjnego pod NIP zmarłego (z dopiskiem 'w spadku')"]
} {
    input.jdg_entrepreneur.in_succession == true
    input.jdg_entrepreneur.succession_manager_nip != null
}

# ══════ P930: unregistered_activity_limit ══════
else := {
    "matched":true,"rule_id":"jdg.business.unregistered_activity_limit_exceeded",
    "package":"jdg.business","priority":930,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","unregistered_activity_limit_exceeded":true,"ceidg_registration_required":true,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Przekroczony limit działalności nieewidencjonowanej",
    "_legal_basis":"Art. 5 Prawa przedsiębiorców",
    "_warnings":["Przekroczony limit dział. nieewidencjonowanej (50% min. wynagrodzenia) — OBOWIĄZKOWA rejestracja CEIDG w 7 dni!"]
} {
    input.jdg_entrepreneur.is_unregistered_activity == true
    monthly_rev := object.get(input.jdg_entrepreneur,"monthly_revenue_current",0)
    min_wage := object.get(object.get(object.get(data.thresholds,"jdg",{}),"bounds",{}),"minimum_wage_gross",4666)
    monthly_rev > floor(0.50 * min_wage)
}

# ══════ P932: unregistered_activity_zus_exemption ══════
else := {
    "matched":true,"rule_id":"jdg.business.unregistered_zus_exemption",
    "package":"jdg.business","priority":932,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_due":false,"zus_health_due":false,
    "zus_social_base_type":"UNREGISTERED","zus_health_rate":"0.00",
    "business_status":"",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 5 Prawa przedsiębiorców",
    "_warnings":["Działalność nieewidencjonowana — brak obowiązku ZUS"]
} {
    input.jdg_entrepreneur.is_unregistered_activity == true
}
