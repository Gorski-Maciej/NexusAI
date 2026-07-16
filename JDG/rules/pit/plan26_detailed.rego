# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.pit
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 10 (P508 DEPRECATED → jdg.pit.forms.pit_revenue_exclusions)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.pit
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.pit.no_match","package":"jdg.pit","priority":99999}

# jdg.pit.revenue_exclusions_detail — [DEPRECATED P508 → jdg.pit.forms.pit_revenue_exclusions]
# Usunięto duplikat. Kanoniczna wersja: JDG/rules/pit/forms.rego (priority 508)

# jdg.pit.income_with_inventory_calculation — Dochód = przychód - KUP + (remanent końcowy - początkowy)
decide :=   {"matched":true,"rule_id":"jdg.pit.income_with_inventory_calculation","package":"jdg.pit","priority":509,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dochód = przychód - KUP + (remanent końcowy - początkowy)","_legal_basis":"Art. 24 ust. 1-1b PIT","_warnings":[]} {
    object.get(input.invoice, "direction", "") == "SALE"; object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}

# jdg.pit.linear_former_employer_block — Były pracodawca — NIE można liniowego przez 3 lata
else :=   {"matched":true,"rule_id":"jdg.pit.linear_former_employer_block","package":"jdg.pit","priority":512,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Były pracodawca — NIE można liniowego przez 3 lata","_legal_basis":"Art. 30c ust. 2 pkt 1 PIT, Art. 9a ust. 3 PIT","_warnings":["Usługi dla byłego pracodawcy — NIE możesz rozliczać liniowo!"]} {
    input.jdg_entrepreneur.tax_form == "LINEAR"; input.jdg_entrepreneur.tax_form == "LINEAR"
}

# jdg.pit.lump_sum_statutory_exclusions — Wyłączenia z ryczałtu — apteki, kantory, części samochodowe
else :=   {"matched":true,"rule_id":"jdg.pit.lump_sum_statutory_exclusions","package":"jdg.pit","priority":524,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Wyłączenia z ryczałtu — apteki, kantory, części samochodowe","_legal_basis":"Art. 8 ust. 1-2 ustawy o ryczałcie","_warnings":["Branża wyłączona z ryczałtu — wymagana skala lub liniowy"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.lump_sum_loss_of_right_midyear — Utrata ryczałtu >2M EUR lub zmiana PKD
else :=   {"matched":true,"rule_id":"jdg.pit.lump_sum_loss_of_right_midyear","package":"jdg.pit","priority":525,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Utrata ryczałtu >2M EUR lub zmiana PKD","_legal_basis":"Art. 20 ustawy o ryczałcie","_warnings":["Utrata prawa do ryczałtu — od dnia X przechodzisz na skalę"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"; object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true
}

# jdg.pit.lump_sum_election_deadline_check — Termin oświadczenia o ryczałcie — 20. dzień po pierwszym przychodzie
else :=   {"matched":true,"rule_id":"jdg.pit.lump_sum_election_deadline_check","package":"jdg.pit","priority":526,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Termin oświadczenia o ryczałcie — 20. dzień po pierwszym przychodzie","_legal_basis":"Art. 9 ust. 1-4 ustawy o ryczałcie","_warnings":["Oświadczenie o ryczałcie niezłożone w terminie!"]} {
    input.jdg_entrepreneur.tax_form == "LUMP_SUM"
}

# jdg.pit.tax_card_rate_table_dynamic — Stawka karty podatkowej wg rodzaju działalności i gminy
else :=   {"matched":true,"rule_id":"jdg.pit.tax_card_rate_table_dynamic","package":"jdg.pit","priority":532,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Stawka karty podatkowej wg rodzaju działalności i gminy","_legal_basis":"Art. 23 ustawy o ryczałcie","_warnings":[]} {
    object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# jdg.pit.tax_card_loss_events_detection — Utrata karty podatkowej — zatrudnienie, zmiana PKD, podwykonawstwo
else :=   {"matched":true,"rule_id":"jdg.pit.tax_card_loss_events_detection","package":"jdg.pit","priority":533,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Utrata karty podatkowej — zatrudnienie, zmiana PKD, podwykonawstwo","_legal_basis":"Art. 27 ustawy o ryczałcie","_warnings":["Utrata prawa do karty podatkowej!"]} {
    object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"; object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"
}

# jdg.pit.kup_direct_vs_indirect_timing — KUP bezpośrednie (rok przychodu) vs pośrednie (data faktury)
else :=   {"matched":true,"rule_id":"jdg.pit.kup_direct_vs_indirect_timing","package":"jdg.pit","priority":572,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"KUP bezpośrednie (rok przychodu) vs pośrednie (data faktury)","_legal_basis":"Art. 22 ust. 5-5c PIT","_warnings":["KUP bezpośredni — potrącenie w roku osiągnięcia przychodu"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"
}

# jdg.pit.kup_detailed_exclusions_catalog — Szczegółowe NKUP — kary, straty, ubezpieczenie aut >150k
else :=   {"matched":true,"rule_id":"jdg.pit.kup_detailed_exclusions_catalog","package":"jdg.pit","priority":574,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Szczegółowe NKUP — kary, straty, ubezpieczenie aut >150k","_legal_basis":"Art. 23 PIT","_warnings":["Wydatek może być NKUP — sprawdź Art. 23 PIT"]} {
    object.get(input.invoice, "direction", "") == "PURCHASE"; object.get(input.invoice, "kus_qualification", "") == "NKUP"
}

# jdg.pit.loss_carry_forward_5years_5m — Strata — max 50% rocznie przez 5 lat lub 5M PLN jednorazowo
else :=   {"matched":true,"rule_id":"jdg.pit.loss_carry_forward_5years_5m","package":"jdg.pit","priority":615,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Strata — max 50% rocznie przez 5 lat lub 5M PLN jednorazowo","_legal_basis":"Art. 9 ust. 3 PIT","_warnings":["Strata do rozliczenia — max 50% rocznie lub 5M PLN"]} {
    object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true; object.get(input.jdg_entrepreneur, "has_rd_status", false) == true; object.get(input.invoice, "category_code", "") == "CAR"
}

# ═══════════════════════════════════════════════════════════════════════════════
# P.18 (Doc 50): IP Box — Art. 22p PIT — Definicja kwalifikowanego IP
# IP Box to preferencyjna stawka 5% od dochodu z kwalifikowanych praw własności
# intelektualnej (patent, program komputerowy, wzór użytkowy). Wymaga wyodrębnionej
# ewidencji + wskaźnika Nexus. NIE dla ryczałtu i karty podatkowej.
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched":true,"rule_id":"jdg.pit.a22p.r1","package":"jdg.pit","priority":550,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"",
    "ip_box_eligible":true,"ip_box_rate":"5%","ip_box_requires_nexus":true,
    "_routing":"","_routing_reason":"IP Box — preferencyjna stawka 5% od dochodu z kwalifikowanego IP",
    "_legal_basis":"Art. 22p PIT, Art. 30ca PIT",
    "_warnings":["IP BOX — 5% od dochodu z kwalifikowanego IP (patent, software, wzór). Wymagana wyodrębniona ewidencja + wskaźnik Nexus. NIE dla ryczałtu/karty podatkowej!"]
} {
    object.get(input.jdg_entrepreneur, "ip_box_eligible", false) == true
    object.get(input.jdg_entrepreneur, "tax_form", "") != "LUMP_SUM"
    object.get(input.jdg_entrepreneur, "tax_form", "") != "TAX_CARD"
    object.get(input.invoice, "ip_box_claimed", false) == true
}
