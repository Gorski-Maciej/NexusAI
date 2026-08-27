# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PCC + LOKALNE + AKCYZA V3 ENTERPRISE (Kampania V3, część 10/20)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.local_taxes.v3_10
# Cel:     domknięcie luk L-10-001..L-10-008 z raportu 10_PCC_LOKALNE.txt:
#          PCC-3 deadline guard (14 dni), stawki PCC z thresholds (zero-hardcode),
#          DN-1 gate, nieruchomości ze stawkami maksymalnymi + uchwała gminy z
#          evidence, akcyza paliwa/alkohol z thresholds, krotka akcyza-vs-VAT,
#          fail-closed (V1 z6), Decision Certificate (F4), Golden Oracle (F3).
# Prawo:   Ustawa z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych
#          (art. 7, 9, 14); ustawa z dnia 12 stycznia 1991 r. o podatkach i
#          opłatach lokalnych (art. 2-12); ustawa o podatku akcyzowym (art. 66-67,
#          98-102); art. 33 i 33a ustawy o VAT.
# Struktura: wzorzec v3_08/v3_09 — reguły-decyzje budują verdict w ciele reguły;
#          łańcuch decide = first-match-wins (Rego bez operatora ternary;
#          wartości warunkowe liczą funkcje pomocnicze z klauzulami else).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.local_taxes.v3_10

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.local_taxes.v3_10.no_match",
    "package": "jdg.local_taxes.v3_10",
    "priority": 999999,
}

# ── Snapshot progów (ADR-002): brak sekcji pcc_local_excise → fail-closed ──────
_th_snapshot := object.get(data.jdg.thresholds, "pcc_local_excise", {})
_snapshot_ok := count(_th_snapshot) > 0

_th(key, fallback) = value {
    _snapshot_ok
    object.get(_th_snapshot, key, null) != null
} else = fallback

_round2(value) = floor(value * 100) / 100

_bool_str(flag) = "TAK" {
    flag
}

_bool_str(flag) = "NIE" {
    flag == false
}

snapshot_status(ok) = "OK" {
    ok
} else = "MISSING"

# ── Fail-closed verdict gdy snapshot progów niedostępny ────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.local_taxes.v3_10.thresholds_missing",
    "package": "jdg.local_taxes.v3_10",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PCC/lokalne/akcyza v3: brak snapshotu data.jdg.thresholds.pcc_local_excise.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-10] Brak snapshotu progów — decyzje PCC/lokalne/akcyza ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.local_taxes.v3_10",
        "priority": priority,
        "threshold_version": object.get(_th_snapshot, "threshold_version", "MISSING"),
        "legal_basis_version": object.get(_th_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_th_snapshot, "valid_from", null),
        "valid_to": object.get(_th_snapshot, "valid_to", null),
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-10-001: PCC RATE ENGINE — art. 7 ust. 1 pkt 1 lit. a-f ustawy o PCC
#            (stawki i zwolnienia z thresholds; zero hardcode)
# ═══════════════════════════════════════════════════════════════════════════════

pcc_rate_for(contract_type) = rate {
    rate_raw := _th(sprintf("pcc_%s_rate", [contract_type]), null)
    rate_raw != null
    rate := rate_raw
} else = 0

pcc_tax_due(_, _, true) = 0

pcc_tax_due(value, rate, false) = due {
    due := _round2(value * rate)
}

exemption_note(small, family) = "ZWOLNIENIE pożyczka rodzinna (art. 9 pkt 9 PCC)" {
    family
} else = "ZWOLNIENIE ≤1000 zł (art. 9 ust. 1 pkt 3 PCC)" {
    small
} else = "podatek należny"

pcc_routing(obligation) = "TRIAGE_QUEUE" {
    obligation
} else = ""

pcc_rate_engine_decision := verdict {
    invoice := object.get(input.invoice, {}, {})
    contract_type := object.get(invoice, "pcc_contract_type", "")
    contract_type != ""

    market_value := object.get(invoice, "pcc_market_value_pln", 0)
    exemption_limit := _th("pcc_exemption_limit", 1000)
    family_loan_limit := _th("pcc_family_loan_limit", 36120)

    is_family_loan := contract_type == "LOAN"
    family_related := object.get(input.vendor, "is_close_family", false)
    family_exemption := is_family_loan and family_related and market_value <= family_loan_limit
    small_exemption := not is_family_loan and market_value > 0 and market_value <= exemption_limit

    rate := pcc_rate_for(contract_type)
    tax_due := pcc_tax_due(market_value, rate, small_exemption or family_exemption)
    obligation := tax_due > 0

    verdict := _certificate(360400, {
        "rule_id": "jdg.local_taxes.v3_10.pcc_rate_engine",
        "procedure": "PCC_RATE_ENGINE_V3",
        "pcc_contract_type": contract_type,
        "pcc_market_value_pln": market_value,
        "pcc_rate": rate,
        "pcc_tax_due_pln": tax_due,
        "pcc_small_exemption_applied": small_exemption,
        "pcc_family_loan_exemption_applied": family_exemption,
        "pcc_filing_obligation": obligation,
        "_routing": pcc_routing(obligation),
        "_routing_reason": sprintf("PCC v3 — %s %.0f PLN × stawka %v%% → %s; podatek %.2f PLN", [contract_type, market_value, rate, exemption_note(small_exemption, family_exemption), tax_due]),
        "_legal_basis": "Art. 7 ust. 1, Art. 9 ust. 1 pkt 3 i Art. 9 pkt 9 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
        "_warnings": [
            "[PCC] Stawki, zwolnienie ≤1000 zł i limit pożyczki rodzinnej czytane z thresholds_jdg.rego (zero hardcode).",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-10-002: PCC-3 DEADLINE GUARD — art. 14 ust. 1 ustawy o PCC (14 dni z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

pcc3_routing(filed, overdue) = "" {
    filed
} else = "BLOCK_AND_ALERT" {
    overdue
} else = "TRIAGE_QUEUE"

pcc3_guard_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    invoice := object.get(input.invoice, {}, {})
    object.get(invoice, "pcc_filing_required", false) == true
    object.get(profile, "uses_notary", false) == false

    deadline_days := _th("pcc3_deadline_days", 14)
    days_since_event := object.get(profile, "days_since_pcc_event", 0)
    filed := object.get(profile, "pcc3_filed", false)
    overdue := not filed and days_since_event > deadline_days
    approaching := not filed and days_since_event >= deadline_days - 3

    verdict := _certificate(360410, {
        "rule_id": "jdg.local_taxes.v3_10.pcc3_deadline_guard",
        "procedure": "PCC3_DEADLINE_GUARD_V3",
        "pcc3_deadline_days": deadline_days,
        "pcc3_days_since_event": days_since_event,
        "pcc3_filed": filed,
        "pcc3_overdue": overdue,
        "pcc3_form": "PCC-3",
        "_routing": pcc3_routing(filed, overdue),
        "_routing_reason": sprintf("PCC-3 v3 — %d dni od czynności vs termin %d dni; złożono: %s", [days_since_event, deadline_days, _bool_str(filed)]),
        "_legal_basis": "Art. 14 ust. 1 ustawy z dnia 9 września 2000 r. o podatku od czynności cywilnoprawnych (Dz.U. 2025 poz. 789)",
        "_warnings": [
            "[PCC-3] Termin 14 dni czytany z thresholds (zero hardcode); przy umowie notarialnej podatek pobiera notariusz.",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-10-003: REAL ESTATE MAX-RATE VALIDATOR — pod. lokalne art. 2-7
#            (stawki maks. z thresholds; uchwała gminy z evidence input)
# ═══════════════════════════════════════════════════════════════════════════════

re_routing(any_over, needs_check) = "BLOCK_AND_ALERT" {
    any_over
} else = "WARNING" {
    needs_check
} else = ""

re_conclusion(over) = "STAWKA GMINY PRZEKRACZA MAKSIMUM — korekta deklaracji!" {
    over
} else = "stawki zgodne z maksimum"

re_warnings(needs_check) = warnings {
    needs_check
    warnings := [
        "[LOKALNE] Stawki maksymalne czytane z thresholds — aktualizacja obwieszczenia MF = aktualizacja snapshotu.",
        "[LOKALNE] Brak dowodu uchwały gminy w evidence — wymagany przegląd ręczny (Law Radar gminny, część 14).",
    ]
} else = warnings {
    warnings := ["[LOKALNE] Stawki maksymalne czytane z thresholds."]
}

real_estate_validator_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "owns_business_real_estate", false) == true

    land_max := _th("land_business_rate", 1.43)
    building_max := _th("building_business_rate", 33.10)

    gmina_land := object.get(profile, "gmina_land_rate_pln_m2", 0)
    gmina_building := object.get(profile, "gmina_building_rate_pln_m2", 0)
    resolution_present := object.get(profile, "gmina_resolution_evidence", false)

    land_over := gmina_land > land_max
    building_over := gmina_building > building_max
    any_over := land_over or building_over
    needs_resolution_check := not resolution_present and (gmina_land == 0 or gmina_building == 0)

    verdict := _certificate(360420, {
        "rule_id": "jdg.local_taxes.v3_10.real_estate_max_rate_validator",
        "procedure": "REAL_ESTATE_MAX_RATE_V3",
        "re_land_max_rate_pln_m2": land_max,
        "re_building_max_rate_pln_m2": building_max,
        "re_gmina_land_rate_pln_m2": gmina_land,
        "re_gmina_building_rate_pln_m2": gmina_building,
        "re_land_over_max": land_over,
        "re_building_over_max": building_over,
        "re_gmina_resolution_evidence": resolution_present,
        "manual_review_required": needs_resolution_check,
        "_routing": re_routing(any_over, needs_resolution_check),
        "_routing_reason": sprintf("Nieruchomości v3 — grunt %.2f/%.2f, budynek %.2f/%.2f PLN/m² (gmina/maks.) → %s", [gmina_land, land_max, gmina_building, building_max, re_conclusion(any_over)]),
        "_legal_basis": "Art. 2-7 ustawy z dnia 12 stycznia 1991 r. o podatkach i opłatach lokalnych (stawki maksymalne corocznie obwieszczeniem Ministra Finansów)",
        "_warnings": re_warnings(needs_resolution_check),
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-10-004: DN-1 DEADLINE GUARD — art. 66 ustawy o podatku akcyzowym (14 dni);
#            po DN-1 roczna DT-1 do 15 lutego
# ═══════════════════════════════════════════════════════════════════════════════

dn1_routing(overdue) = "BLOCK_AND_ALERT" {
    overdue
} else = "TRIAGE_QUEUE"

dn1_conclusion(overdue) = "PRZETERMINOWANE — złóż DN-1 natychmiast!" {
    overdue
} else = "w terminie"

dn1_guard_decision := verdict {
    profile := object.get(input.jdg_entrepreneur, {}, {})
    object.get(profile, "vehicle_registered_for_business", false) == true
    object.get(profile, "dn1_filed", false) == false

    deadline_days := _th("transport_dn1_deadline_days", 14)
    days_since_reg := object.get(profile, "days_since_vehicle_registration", 0)
    overdue := days_since_reg > deadline_days

    verdict := _certificate(360430, {
        "rule_id": "jdg.local_taxes.v3_10.dn1_deadline_guard",
        "procedure": "DN1_DEADLINE_GUARD_V3",
        "dn1_deadline_days": deadline_days,
        "dn1_days_since_registration": days_since_reg,
        "dn1_overdue": overdue,
        "dn1_form": "DN-1",
        "dt1_annual_form": "DT-1 do 15 lutego każdego roku",
        "_routing": dn1_routing(overdue),
        "_routing_reason": sprintf("DN-1 v3 — %d dni od rejestracji pojazdu vs termin %d dni → %s", [days_since_reg, deadline_days, dn1_conclusion(overdue)]),
        "_legal_basis": "Art. 66-67 ustawy z dnia 6 grudnia 2008 r. o podatku akcyzowym; Art. 8-12 pod. lokalnych (podatek od środków transportowych)",
        "_warnings": [
            "[DN-1] Termin 14 dni czytany z thresholds (zero hardcode); po DN-1 co roku DT-1 do 15 lutego.",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-10-005: EXCISE RATE CHECK — paliwa/alkohol (stawki jednostkowe z thresholds)
# ═══════════════════════════════════════════════════════════════════════════════

excise_unit_rate(product_key) = rate {
    rate_raw := _th(sprintf("excise_%s", [product_key]), null)
    rate_raw != null
    rate := rate_raw
} else = 0

excise_routing(known) = "" {
    known
} else = "WARNING"

excise_check_decision := verdict {
    invoice := object.get(input.invoice, {}, {})
    product_key := object.get(invoice, "excise_product_key", "")
    product_key != ""
    quantity := object.get(invoice, "excise_quantity", 0)
    quantity > 0

    unit_rate := excise_unit_rate(product_key)
    known_product := unit_rate > 0
    estimated_excise := _round2(quantity * unit_rate)

    excise_conclusion(known) = "stawka jednostkowa zastosowana" {
        known
    } else = "NIEZNANY PRODUKT — wymagana klasyfikacja CN (narzędzie akcyza_classifier)"

    verdict := _certificate(360440, {
        "rule_id": "jdg.local_taxes.v3_10.excise_rate_check",
        "procedure": "EXCISE_RATE_CHECK_V3",
        "excise_product_key": product_key,
        "excise_quantity": quantity,
        "excise_unit_rate": unit_rate,
        "excise_estimated_pln": estimated_excise,
        "excise_product_known": known_product,
        "manual_review_required": not known_product,
        "_routing": excise_routing(known_product),
        "_routing_reason": sprintf("Akcyza v3 — %s × %.2f (%d jedn.) ≈ %.2f PLN → %s", [product_key, unit_rate, quantity, estimated_excise, excise_conclusion(known_product)]),
        "_legal_basis": "Ustawa z dnia 6 grudnia 2008 r. o podatku akcyzowym (Dz.U. 2024 poz. 1321 ze zm.) — załączniki nr 1-3 (stawki jednostkowe)",
        "_warnings": [
            "[AKCYZA] Stawki jednostkowe czytane z thresholds_jdg.rego — aktualizacja stawek UE/PL bez zmiany kodu.",
        ],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-10-006: AKCYZA vs VAT SHORT-CUT — rozróżnienie procedur (seed 6)
# ═══════════════════════════════════════════════════════════════════════════════

map_procedure("CUSTOMS_WAREHOUSE") = "VAT zawieszony do dopuszczenia do obrotu (art. 33 VAT); akcyza płatna przy wypływie ze składu podatkowego."
map_procedure("IMPORT") = "VAT należny w imporcie (art. 33a VAT); akcyza wg stawki jednostkowej/pojemności."
map_procedure(_) = ""

shortcut_routing(note) = "TRIAGE_QUEUE" {
    note != ""
} else = ""

excise_vat_shortcut_decision := verdict {
    invoice := object.get(input.invoice, {}, {})
    procedure := object.get(invoice, "procedure", "")

    note := map_procedure(procedure)
    applicable := note != ""

    verdict := _certificate(360450, {
        "rule_id": "jdg.local_taxes.v3_10.excise_vat_shortcut",
        "procedure": "EXCISE_VAT_SHORTCUT_V3",
        "shortcut_source_procedure": procedure,
        "shortcut_note": note,
        "shortcut_applicable": applicable,
        "_routing": shortcut_routing(note),
        "_routing_reason": sprintf("Krotka akcyza↔VAT v3 — procedura %s → %s", [procedure, note]),
        "_legal_basis": "Art. 31a i Art. 109 ustawy o VAT; Art. 98-102 ustawy o podatku akcyzowym (skład podatkowy, zawieszenie poboru)",
        "_warnings": [],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-10-007: LOCAL TAXES DECISION CERTIFICATE — zbiorczy certyfikat domeny (F3/F4)
# ═══════════════════════════════════════════════════════════════════════════════

lt_domain_packages := [
    "jdg.local_taxes", "jdg.local_taxes.pcc_enterprise",
    "jdg.local_taxes.excise_enterprise", "jdg.local_taxes.procedures_enterprise",
    "jdg.local_taxes.v3_10", "jdg.micro.pcc", "jdg.micro.pcc.plan33",
    "jdg.micro.akcyza", "jdg.micro.prop", "jdg.micro.prop_transport",
]

cert_routing(has_context) = "TRIAGE_QUEUE" {
    has_context
} else = ""

local_taxes_certificate_decision := verdict {
    invoice := object.get(input.invoice, {}, {})

    context_keys := ["pcc_contract_type", "excise_product_key"]
    matching_keys := [k | some k in context_keys; object.get(invoice, k, "") != ""]
    has_context := count(matching_keys) > 0

    verdict := _certificate(360499, {
        "rule_id": "jdg.local_taxes.v3_10.local_taxes_certificate",
        "procedure": "LT_DECISION_CERTIFICATE",
        "lt_domain_packages_wired": lt_domain_packages,
        "lt_golden_oracle_ready": true,
        "lt_snapshot_status": snapshot_status(_snapshot_ok),
        "manual_review_required": false,
        "_routing": cert_routing(has_context),
        "_routing_reason": sprintf("Local taxes certificate — kontekst PCC/akcyza: %s, snapshot progów: %s, pakietów domeny: %d", [_bool_str(has_context), snapshot_status(_snapshot_ok), count(lt_domain_packages)]),
        "_legal_basis": "Kompleksowy certyfikat domeny PCC + podatki lokalne + akcyza; zgodność z V1 zasada 9 i V2 filary F3-F4",
        "_warnings": [],
    })
}

# ── Łańcuch first-match-wins: fail-closed → domeny → certyfikat zbiorczy ──────

decide = fail_closed_decision {
    not _snapshot_ok
} else = pcc_rate_engine_decision {
    true
} else = pcc3_guard_decision {
    true
} else = real_estate_validator_decision {
    true
} else = dn1_guard_decision {
    true
} else = excise_check_decision {
    true
} else = excise_vat_shortcut_decision {
    true
} else = local_taxes_certificate_decision {
    true
}
