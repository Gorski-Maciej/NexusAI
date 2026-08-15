# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Business: CEIDG, zawieszenie, sukcesja (P900-P939)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Documentation metadata (kept as ordinary comments; not parsed by OPA)
# title: Business Lifecycle Package — CEIDG, Suspension, Succession
# description: |
#   Reguły cyklu życia JDG. Kolejność: P900 (CEIDG) → P902 (aktualizacja) →
#   P910 (zawieszenie) → P912 (KUP w zawieszeniu) →
#   P914 (ZUS w zawieszeniu — społeczne=0, zdrowotna NADAL! — AKTYWNA, NIE deprecated) →
#   P920 (sukcesja) → P930 (limit nieewidencjonowanej) → P932 (ZUS exemption).
#   Architektura: object.union — business.decide mergowane PO zus.decide# (P914 nie ustawia zus_health_rate, pozwala ZUS-owi zachować stawkę).
#   ⚠️ P914 NIE jest deprecated — to aktywna reguła kanoniczna.
# legal_basis: Art. 5-7 CEIDG, Art. 22-25 Prawa przedsiębiorców, Art. 36a SUS
# edge_cases:
#   - Zawieszenie: społeczne=0, zdrowotna NADAL (Art. 36a SUS)
#   - Dział. nieewidencjonowana: limit 75% min. wynagrodzenia (50% do 30.06.2023; od 2026: 225% kwartalnie)
#   - Sukcesja: NIP zmarłego + "w spadku"
# package: jdg.business
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.business
default decide := {"matched":false,"rule_id":"jdg.business.no_match","package":"jdg.business","priority":950}

suspension_warning(emp_count, _) = "Zawieszenie zablokowane — zatrudniasz pracowników!" {
    emp_count > 0
}

suspension_warning(_, susp_months) = "Przekroczono max 6 mies. zawieszenia — automatyczne wznowienie" {
    susp_months >= 6
}

suspension_triggered(emp_count, susp_months) {
    emp_count > 0
}

suspension_triggered(emp_count, susp_months) {
    susp_months >= 6
}

successor_requirements_met(has_appointed, has_consent, in_ceidg) = true {
    has_appointed
    has_consent
    in_ceidg
} else = false

suspension_risk_for(susp_months, emp_count) = true {
    susp_months >= 6
    emp_count == 0
} else = false

suspension_date_in_period(eval_date, start_date, end_date) = true {
    eval_date >= start_date
    eval_date <= end_date
} else = false

bool_not(value) = false {
    value == true
} else = true

suspension_allowed_expense(expense_type) {
    expense_type == "RENT"
}

suspension_allowed_expense(expense_type) {
    expense_type == "UTILITIES"
}

suspension_allowed_expense(expense_type) {
    expense_type == "SECURITY"
}

suspension_allowed_expense(expense_type) {
    expense_type == "LEASE_EXISTING"
}

suspension_allowed_expense(expense_type) {
    expense_type == "INSURANCE"
}

suspension_allowed_expense(expense_type) {
    expense_type == "ACCOUNTING"
}

form_change_allowed(new_form) {
    new_form == "SCALE"
}

form_change_allowed(new_form) {
    new_form == "LINEAR"
}

successor_routing_for(all_ok) = "" {
    all_ok == true
} else = "BLOCK_AND_ALERT"

successor_routing_reason_for(all_ok) = "" {
    all_ok == true
} else = "Zarządca sukcesyjny NIE spełnia wymogów — wymagane: powołanie + zgoda + wpis w CEIDG"

successor_warning_for(all_ok) = "Zarządca sukcesyjny prawidłowo ustanowiony" {
    all_ok == true
} else = "Zarządca sukcesyjny musi być powołany, wyrazić zgodę i być wpisany do CEIDG!"

suspension_risk_warning_for(is_at_risk) = "Ryzyko wykreślenia z CEIDG (>6 mies. bez pracowników)!" {
    is_at_risk == true
} else = "Zawieszenie w normie"

unregistered_routing_for(exceeded) = "BLOCK_AND_ALERT" {
    exceeded == true
} else = ""

unregistered_routing_reason_for(exceeded) = "Przekroczony limit działalności nieewidencjonowanej — obowiązkowa rejestracja CEIDG w 7 dni!" {
    exceeded == true
} else = "Działalność nieewidencjonowana w limicie"

unregistered_limit_label_for(within) = "W LIMICIE" {
    within == true
} else = "PRZEKROCZONY — REJESTRACJA CEIDG WYMAGANA!"

suspension_status_for(in_period, resumed, eval_date, start_date) = "SUSPENDED" {
    in_period == true
} else = "ACTIVE" {
    resumed == true
} else = "PRE_SUSPENSION" {
    eval_date < start_date
}

suspension_period_warning_for(in_period, resumed, start_date, end_date, eval_date) = sprintf("Zawieszenie: okres [%s, %s], data ewaluacji %s — w okresie zawieszenia", [start_date, end_date, eval_date]) {
    in_period == true
} else = sprintf("Zawieszenie: okres [%s, %s] zakończony %s — działalność WZNOWIONA (dzień po końcu okresu)", [start_date, end_date, eval_date]) {
    resumed == true
} else = sprintf("Zawieszenie: okres [%s, %s] — data %s PRZED rozpoczęciem zawieszenia", [start_date, end_date, eval_date])

succession_limit_for(has_extension) = 60 {
    has_extension == true
} else = 24

succession_expiry_info_for(months_since, succession_limit) = sprintf("już wygasł (przekroczono %d mies.)", [succession_limit]) {
    months_since >= succession_limit
} else = sprintf("za %d mies.", [succession_limit - months_since])

# ══════ P916: business_resumption_procedure — Wznowienie po zawieszeniu ══════
# Cel: Wznowienie JDG z CEIDG — od daty złożenia wniosku (nie data przyszła)
# Podstawa prawna: Art. 22-25 Prawa przedsiębiorców
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched":true,"rule_id":"jdg.business.resumption_procedure",
    "package":"jdg.business","priority":916,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"ACTIVE",
    "resumption_date": resumption_date_val,
    "ceidg_registration_required":false,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22-25 Prawa przedsiębiorców",
    "_warnings":["Wznowienie działalności — od daty złożenia wniosku do CEIDG. Pamiętaj o wznowieniu ZUS i VAT."]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    input.jdg_entrepreneur.resumption_requested == true
    resumption_date_val := object.get(input.jdg_entrepreneur, "resumption_request_date", "")
}

# ══════ P917: maximum_suspension_period — Max 6 mies. + blokada przy pracownikach ══════
else := {
    "matched":true,"rule_id":"jdg.business.max_suspension_block",
    "package":"jdg.business","priority":917,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"SUSPENDED",
    "suspension_blocked_by_employees": emp_count > 0,
    "valid_from": "2018-04-30",
    "valid_to": null,
    "suspension_expired": susp_months >= 6,
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Nie można zawiesić JDG — zatrudniasz pracowników / przekroczono max 6 mies.",
    "_legal_basis":"Art. 22-25 Prawa przedsiębiorców",
    "_warnings":[sprintf("Zawieszenie %d mies., %d pracowników — %s",[susp_months, emp_count, warn_msg])]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    susp_months := object.get(input.jdg_entrepreneur,"suspension_months_continuous",0)
    emp_count := object.get(input.jdg_entrepreneur,"employee_count",0)
    warn_msg := suspension_warning(emp_count, susp_months)
    suspension_triggered(emp_count, susp_months)
}

# ══════ P921a: succession_no_manager_grace — 2-mies. okno na powołanie zarządcy (R02 P1) ══════
# Cel: Po śmierci JDG bez zarządcy — spadkobiercy mają 2 miesiące na powołanie
# zarządcy sukcesyjnego (art. 3 u.z.s.). W oknie: TRIAGE_QUEUE (przypomnienie).
else := {
    "matched":true,"rule_id":"jdg.business.succession_no_manager_grace",
    "package":"jdg.business","priority":921,
    "valid_from":"2018-11-19",
    "valid_to":null,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"IN_SUCCESSIO",
    "succession_manager_missing":true,
    "succession_grace_days_left":max([0, 60 - days_since_death]),
    "succession_grace_deadline":"60 dni od śmierci",
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason":"Brak zarządcy sukcesyjnego — pozostało okno 2 mies. na powołanie (art. 3 u.z.s.)",
    "_legal_basis":"Art. 3, 14-15 ustawy o zarządzie sukcesyjnym; art. 30 ust. 2 ustawy o CEIDG",
    "_warnings":[sprintf("Brak zarządcy sukcesyjnego — %d dni po śmierci. Spadkobiercy mogą powołać zarządcę w ciągu 2 MIESIĘCY od śmierci (art. 3 u.z.s.). Po upływie terminu działalność WYGASA, a CEIDG wykreśla wpis z urzędu.", [days_since_death])]
} {
    input.jdg_entrepreneur.in_succession == true
    object.get(input.jdg_entrepreneur, "succession_manager_nip", "") == ""
    days_since_death := to_number(object.get(input.jdg_entrepreneur, "succession_days_elapsed", to_number(object.get(input.jdg_entrepreneur, "months_since_date_of_death", 0)) * 30))
    days_since_death < 60
}

# ══════ P921b: succession_no_manager_expiry — Wygaśnięcie działalności po 2 mies. (R02 P1) ══════
# Cel: Brak zarządcy po 2 miesiącach od śmierci → działalność WYGASA, wpis w CEIDG
# wykreślany z urzędu (art. 30 ust. 2 ustawy o CEIDG), NIP traci ważność.
else := {
    "matched":true,"rule_id":"jdg.business.succession_no_manager_expiry",
    "package":"jdg.business","priority":922,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"EXPIRED",
    "succession_manager_missing":true,
    "succession_expired":true,
    "ceidg_deregistration_required":true,
    "nip_status":"DECEASED_NO_SUCCESSOR",
    "_routing":"BLOCK_AND_ALERT",
    "_routing_reason":"Brak zarządcy sukcesyjnego po 2 miesiącach — działalność WYGASA, wykreślenie z CEIDG z urzędu",
    "_legal_basis":"Art. 3, 14-15 ustawy o zarządzie sukcesyjnym; art. 30 ust. 2 ustawy o CEIDG",
    "_warnings":["BRAK ZARZĄDCY SUKCESYJNEGO po 2 miesiącach od śmierci — działalność gospodarcza WYGASŁA. CEIDG wykreśla wpis z urzędu (w ciągu 7 dni po 2-mies. okresie). NIP wygasa. Spadkobiercy odpowiadają za zobowiązania do wysokości nabytego majątku."],
    "_future_events":[
        {
            "event_id":"succession_no_manager_ceidg_dereg",
            "event_type":"COMPLIANCE_CHECK",
            "description":"Wykreślenie zmarłego przedsiębiorcy z CEIDG z urzędu (brak zarządcy)",
            "due_date_horizon":"+7d",
            "action":"CEIDG_DEREGISTER_EX_OFFICIO",
            "priority":"CRITICAL"
        }
    ]
} {
    input.jdg_entrepreneur.in_succession == true
    object.get(input.jdg_entrepreneur, "succession_manager_nip", "") == ""
    days_since_death := to_number(object.get(input.jdg_entrepreneur, "succession_days_elapsed", to_number(object.get(input.jdg_entrepreneur, "months_since_date_of_death", 0)) * 30))
    days_since_death >= 60
}

# ══════ P929c: succession_manager_appointment_valid — Ważność zarządcy ══════
else := {
    "matched":true,"rule_id":"jdg.business.succession_manager_valid",
    "package":"jdg.business","priority":929,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"IN_SUCCESSIO",
    "succession_manager_valid": all_ok,
    "_routing": routing_flag,
    "_routing_reason": routing_reason,
    "_legal_basis":"Art. 3-4 u.z.s.",
    "_warnings":[warn_msg]
} {
    input.jdg_entrepreneur.in_succession == true
    has_appointed := object.get(input.jdg_entrepreneur, "succession_manager_appointed", false)
    has_consent := object.get(input.jdg_entrepreneur, "succession_manager_consent", false)
    in_ceidg := object.get(input.jdg_entrepreneur, "succession_manager_in_ceidg", false)
    all_ok := successor_requirements_met(has_appointed, has_consent, in_ceidg)
    routing_flag := successor_routing_for(all_ok)
    routing_reason := successor_routing_reason_for(all_ok)
    warn_msg := successor_warning_for(all_ok)
}

# ══════ P929d: succession_time_limits — Zarząd max 2 lata (5 lat z sądem) ══════
else := {
    "matched":true,"rule_id":"jdg.business.succession_expiry",
    "package":"jdg.business","priority":930,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"IN_SUCCESSIO",
    "succession_expires_in_months": max([0, succession_limit - months_since]),
    "succession_expired": months_since >= succession_limit,
    "_routing":"TRIAGE_QUEUE",
    "_routing_reason": sprintf("Zarząd sukcesyjny wygasa za %d miesięcy", [max([0, succession_limit - months_since])]),
    "_legal_basis":"Art. 12-15 u.z.s.",
    "_warnings":[sprintf("Zarząd sukcesyjny trwa %d mies. (max %d). Wygaśnięcie: %s.", [months_since, succession_limit, expiry_info])],
    "_future_events":[{
        "event_id":"succession_expiry",
        "event_type":"SUCCESSION_EXPIRY",
        "description":sprintf("Zarząd sukcesyjny wygasa za %d miesięcy", [max([0, succession_limit - months_since])]),
        "due_date_horizon":sprintf("+%dmo", [max([0, succession_limit - months_since])]),
        "action":"TERMINATE_JDG_SUCCESSIO",
        "priority":"CRITICAL"
    }]
} {
    input.jdg_entrepreneur.in_succession == true
    months_since := object.get(input.jdg_entrepreneur, "months_since_date_of_death", 0)
    has_extension := object.get(input.jdg_entrepreneur, "succession_court_extended", false)
    succession_limit := succession_limit_for(has_extension)
    expiry_info := succession_expiry_info_for(months_since, succession_limit)
}

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
    not suspension_allowed_expense(input.invoice.expense_type)
    input.invoice.direction == "PURCHASE"
}

# ══════ P914: business_suspension_zus — Zawieszenie → społeczne=0, zdrowotna NADAL ══════
# v7.0 FIX: Dodano immutable_verdict=true — chroni werdykt ZUS w zawieszeniu
# przed nadpisaniem przez risk.decide i inne pakiety z wyższym priorytetem.
# Architektura: main_jdg.rego używa safe_merge. Ponieważ business.decide
# jest mergowane PO zus.decide, usunięcie zus_health_rate z P914 sprawia, że safe_merge
# zachowuje stawkę zdrowotną już ustawioną przez pakiet zus (P720/P722/P724).
# immutable_verdict=true gwarantuje, że ZUS zawieszenia nie zostanie nadpisany.
else := {
    "matched":true,"rule_id":"jdg.business.suspension_zus",
    "package":"jdg.business","priority":914,
    "immutable_verdict": true,
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

# ══════ P930: unregistered_activity_limit (R02 P1 — limit z data.thresholds, temporalny) ══════
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
    "_legal_basis":"Art. 5 ust. 1 pkt 1 Prawa przedsiębiorców",
    "_warnings":["Przekroczony limit dział. nieewidencjonowanej (75% min. wynagrodzenia; kwartalnie 225% od 2026 — limit z data.thresholds) — OBOWIĄZKOWA rejestracja CEIDG w 7 dni!"]
} {
    input.jdg_entrepreneur.is_unregistered_activity == true
    monthly_rev := to_number(object.get(input.jdg_entrepreneur,"monthly_revenue_current",0))
    min_wage := to_number(object.get(object.get(object.get(data.thresholds,"jdg",{}),"bounds",{}),"minimum_wage_gross",4800))
    eval_date := object.get(input, "evaluation_date", object.get(input.jdg_entrepreneur, "effective_date", "2026-01-01"))
    unreg_pct := to_number(data.jdg.thresholds.unregistered_limit_pct(eval_date))
    monthly_rev > floor(min_wage * unreg_pct * 100) / 100
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

# ══════ P916: suspension_depreciation_ban — Zakaz amortyzacji w zawieszeniu (Doc 35) ══════
else := {
    "matched":true,"rule_id":"jdg.business.suspension_depreciation_ban",
    "package":"jdg.business","priority":916,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"NKUP","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"SUSPENDED",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Amortyzacja w zawieszeniu = niedozwolona",
    "_legal_basis":"Art. 22c pkt 4 PIT",
    "_warnings":["Zawieszenie JDG → NIE dokonuje się odpisów amortyzacyjnych. Odpisy za okres zawieszenia PRZEPADAJĄ!"]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    input.invoice.category_code == "DEPRECIATION"
}

# ══════ P919: suspension_vat_zero — Zerowe deklaracje VAT w zawieszeniu (Doc 35) ══════
else := {
    "matched":true,"rule_id":"jdg.business.suspension_vat_zero",
    "package":"jdg.business","priority":919,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"SUSPENDED",
    "vat_declaration_required":true,"vat_declaration_type":"ZERO_RETURN",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 99 ust. 7a VAT",
    "_warnings":["Zawieszenie JDG → obowiązek składania ZEROWYCH deklaracji VAT-7/JPK_V7. Wyjątek: brak obowiązku jeśli brak WNT."]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    input.jdg_entrepreneur.vat_status == "ACTIVE"
    object.get(input.jdg_entrepreneur,"has_wnt_transactions",false)==false
}

# ══════ P922: succession_tax_responsibilities — Rozliczenia podatkowe po śmierci (Doc 35) ══════
else := {
    "matched":true,"rule_id":"jdg.business.succession_tax_responsibilities",
    "package":"jdg.business","priority":922,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"IN_SUCCESSIO",
    "tax_filing_required":true,"filed_by":"SUCCESSION_MANAGER_OR_HEIRS",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Zeznania za zmarłego — obowiązek spadkobierców",
    "_legal_basis":"Art. 97 § 1-2, Art. 100 § 1-2 Ordynacji podatkowej",
    "_warnings":["ŚMIERĆ JDG → spadkobiercy/zarządca sukcesyjny składają zeznania za zmarłego. PIT-36/PIT-36L + VAT-7 + ZUS DRA za okres do dnia śmierci."]
} {
    input.jdg_entrepreneur.in_succession == true
    object.get(input.jdg_entrepreneur,"succession_tax_filings_done",true)==false
}

# ══════ P928: succession_inventory_death_date — Remanent na dzień śmierci (Doc 35) ══════
else := {
    "matched":true,"rule_id":"jdg.business.succession_inventory_death",
    "package":"jdg.business","priority":928,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"IN_SUCCESSIO",
    "inventory_required":true,"inventory_date":"DATE_OF_DEATH",
    "remnant_tax_rate":0.10,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Remanent na dzień śmierci — 10% podatek",
    "_legal_basis":"Art. 24 ust. 2 PIT + Art. 14 ust. 2 PIT",
    "_warnings":["ŚMIERĆ JDG → obowiązek sporządzenia remanentu na dzień śmierci. 10% zryczałtowany podatek od nadwyżki remanentu nad wartością początkową."]
} {
    input.jdg_entrepreneur.in_succession == true
    object.get(input.jdg_entrepreneur,"inventory_remnant_value",0)>0
    object.get(input.jdg_entrepreneur,"succession_inventory_filed",true)==false
}

# ══════ P830: tax_form_change_inventory — Remanent przy zmianie formy opodatkowania (Doc 35) ══════
else := {
    "matched":true,"rule_id":"jdg.business.tax_form_change_inventory",
    "package":"jdg.business","priority":830,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","form_change_inventory_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Zmiana formy opodatkowania — wymagany remanent",
    "_legal_basis":"Art. 24 ust. 2 PIT, Art. 44 ust. 2 PIT",
    "_warnings":[sprintf("Zmiana formy z %s na %s → konieczny remanent na 1 stycznia dla prawidłowego ustalenia KUP.",[old_form,new_form])]
} {
    old_form:=object.get(input.jdg_entrepreneur,"previous_tax_form","")
    new_form:=input.jdg_entrepreneur.tax_form
    old_form!=""
    old_form!=new_form
    old_form=="LUMP_SUM"
    form_change_allowed(new_form)
}

# ══════ P918: suspension_time_limit — Zawieszenie >6 mies. bez pracowników (Doc 36) ══════
else := {
    "matched":true,"rule_id":"jdg.business.suspension_time_warning",
    "package":"jdg.business","priority":918,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"SUSPENDED",
    "suspension_months":susp_months,"suspension_risk_deregistration":is_at_risk,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22 Prawa przedsiębiorców",
    "_warnings":[sprintf("Zawieszenie %d miesięcy, %d pracowników — %s",[susp_months,emp_count,warn_msg])]
} {
    input.jdg_entrepreneur.business_status == "SUSPENDED"
    susp_months := object.get(input.jdg_entrepreneur,"suspension_months_continuous",0)
    emp_count := object.get(input.jdg_entrepreneur,"employee_count",0)
    is_at_risk := suspension_risk_for(susp_months, emp_count)
    warn_msg := suspension_risk_warning_for(is_at_risk)
}

# ══════ P832: tax_form_change_kup_correction — Korekta KUP przy zmianie formy (Doc 35) ══════
else := {
    "matched":true,"rule_id":"jdg.business.tax_form_change_kup_correction",
    "package":"jdg.business","priority":832,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","kup_correction_required":true,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Korekta KUP — wydatki poniesione przed zmianą formy",
    "_legal_basis":"Art. 22 ust. 1 PIT, Art. 24 ust. 1 PIT",
    "_warnings":["Zmiana formy opodatkowania → korekta KUP. Wydatki poniesione przed zmianą formy, a wykorzystane po zmianie, podlegają korekcie."]
} {
    object.get(input.jdg_entrepreneur,"tax_form_changed_this_year",false)==true
    object.get(input.jdg_entrepreneur,"has_pre_change_expenses",false)==true
}

# ═══════════════════════════════════════════════════════════════════════════════
# R02 — AUDYT LIMITU DZIAŁALNOŚCI NIEEWIDENCJONOWANEJ (P931, T1) + GRANICA ZAWIESZENIA (T3)
# ═══════════════════════════════════════════════════════════════════════════════
# R02 P1: limit w 100% z data.thresholds (płaca minimalna + procent temporalny) —
# zero hardcode kwot. 2026+: tryb kwartalny (225% płacy min.).
# Historia: 50% mies. (do 30.06.2023) → 75% mies. (01.07.2023) → 225% kwartalnie (2026).

# Helper: efektywny limit (kwartalny jeśli dostępny przychód kwartalny w trybie kwartalnym)
r02_eff_limit(q_mode, q_rev, quarterly_limit, monthly_limit) = v {
    q_mode == true
    q_rev > 0
    v := quarterly_limit
} else = v {
    v := monthly_limit
}

# Helper: efektywny przychód do porównania z limitem
r02_eff_rev(q_mode, q_rev, monthly_rev) = v {
    q_mode == true
    q_rev > 0
    v := q_rev
} else = v {
    v := monthly_rev
}

# ══════ P931: unregistered_limit_check — Audyt limitu nieewidencjonowanej (R02 P1/T1) ══════
else := {
    "matched":true,"rule_id":"jdg.business.unregistered_limit_check",
    "package":"jdg.business","priority":931,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "unregistered_limit_monthly":limit_monthly,
    "unregistered_limit_quarterly":limit_quarterly,
    "unregistered_limit_pct":unreg_pct,
    "unregistered_quarterly_mode":quarterly_mode,
    "unregistered_revenue_checked":eff_rev,
    "unregistered_limit_applied":eff_limit,
    "unregistered_within_limit":within,
    "unregistered_activity_limit_exceeded":exceeded,
    "ceidg_registration_required":exceeded,
    "_routing":routing_flag,
    "_routing_reason":routing_reason,
    "_legal_basis":"Art. 5 ust. 1 pkt 1 Prawa przedsiębiorców",
    "_warnings":[warn_msg]
} {
    input.business_unregistered_limit_check == true
    min_wage := to_number(object.get(object.get(object.get(data.thresholds,"jdg",{}),"bounds",{}),"minimum_wage_gross",4800))
    eval_date := object.get(input, "evaluation_date", object.get(input.jdg_entrepreneur, "effective_date", "2026-01-01"))
    unreg_pct := to_number(data.jdg.thresholds.unregistered_limit_pct(eval_date))
    qm := to_number(data.jdg.thresholds.unregistered_quarterly_multiplier(eval_date))
    limit_monthly := floor(min_wage * unreg_pct * 100) / 100
    limit_quarterly := floor(min_wage * qm * 100) / 100
    quarterly_mode := qm > 0
    monthly_revenue_value := to_number(object.get(input.jdg_entrepreneur,"monthly_revenue_current",0))
    quarterly_revenue_value := to_number(object.get(input.jdg_entrepreneur,"quarterly_revenue",0))
    eff_limit := r02_eff_limit(quarterly_mode, quarterly_revenue_value, limit_quarterly, limit_monthly)
    eff_rev := r02_eff_rev(quarterly_mode, quarterly_revenue_value, monthly_revenue_value)
    exceeded := eff_rev > eff_limit
    within := bool_not(exceeded)
    routing_flag := unregistered_routing_for(exceeded)
    routing_reason := unregistered_routing_reason_for(exceeded)
    within_label := unregistered_limit_label_for(within)
    warn_msg := sprintf("Działalność nieewidencjonowana: limit %.2f PLN/mies. (%.0f%% płacy min. %.0f PLN; kwartalnie %.2f PLN od 2026). Przychód ewaluowany: %.2f PLN — %s", [limit_monthly, unreg_pct * 100, min_wage, limit_quarterly, eff_rev, within_label])
}

# ══════ P918b: suspension_period_boundary — Granica okresu zawieszenia (R02 T3) ══════
# Cel: Zawieszenie obejmuje okres [start, end] włącznie; dzień po zakończeniu =
# wznowienie. Test T3: 31.12 23:59 (w okresie) vs 1.01 00:01 (wznowienie).
else := {
    "matched":true,"rule_id":"jdg.business.suspension_period_boundary",
    "package":"jdg.business","priority":918,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":status_flag,
    "suspension_in_period":in_period,
    "suspension_resumed":resumed,
    "suspension_start_date":start_date,
    "suspension_end_date":end_date,
    "suspension_eval_date":eval_date,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22-25 Prawa przedsiębiorców",
    "_warnings":[warn_msg]
} {
    input.business_suspension_check == true
    start_date := object.get(input.business_suspension, "start_date", "")
    end_date := object.get(input.business_suspension, "end_date", "")
    eval_date := object.get(input.business_suspension, "eval_date", object.get(input, "evaluation_date", ""))
    start_date != ""
    end_date != ""
    eval_date != ""
    in_period := suspension_date_in_period(eval_date, start_date, end_date)
    resumed := eval_date > end_date
    status_flag := suspension_status_for(in_period, resumed, eval_date, start_date)
    warn_msg := suspension_period_warning_for(in_period, resumed, start_date, end_date, eval_date)
}
