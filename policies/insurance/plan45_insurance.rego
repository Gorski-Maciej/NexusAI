# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.insurance hyper-granularity (Doc 45: R1608-R1635)
# Atom rules: mandatory per industry, KUP, claims, VAT, voluntary, gaps
# Rules: 28 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.insurance.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.insurance.hyper.no_match","package":"jdg.insurance.hyper","priority":99999}

# ══ R1608-R1612: Mandatory Insurance Detection ══
decide := {"matched":true,"rule_id":"jdg.insurance.hyper.detection_legal","package":"jdg.insurance.hyper","priority":1608,"_routing":"WARNING","_routing_reason":"OC: prawnicy — obowiązkowe","_legal_basis":"Rozp. MS ws. OC adwokatów/radców","_warnings":["Adwokat/radca prawny — obowiązkowe OC zawodowe"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "69.10.Z"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.detection_medical","package":"jdg.insurance.hyper","priority":1609,"_routing":"WARNING","_routing_reason":"OC: lekarze — obowiązkowe","_legal_basis":"Ustawa o zawodzie lekarza","_warnings":["Lekarz/stomatolog — obowiązkowe OC zawodowe"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "86.21.Z"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.detection_construction","package":"jdg.insurance.hyper","priority":1610,"_routing":"WARNING","_routing_reason":"OC: budowlanka — obowiązkowe","_legal_basis":"Art. 648 KC","_warnings":["Branża budowlana — obowiązkowe OC za szkody powstałe w związku z wykonywaniem robót"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "41.10.Z"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.detection_transport","package":"jdg.insurance.hyper","priority":1611,"_routing":"WARNING","_routing_reason":"OC: transport — obowiązkowe","_legal_basis":"Ustawa o transporcie drogowym","_warnings":["Przewoźnik drogowy — obowiązkowe OC przewoźnika"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "49.41.Z"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.detection_tax_advisor","package":"jdg.insurance.hyper","priority":1612,"_routing":"WARNING","_routing_reason":"OC: doradca podatkowy — obowiązkowe","_legal_basis":"Ustawa o doradztwie podatkowym","_warnings":["Doradca podatkowy — obowiązkowe OC zawodowe"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "69.20.Z"
}

# ══ R1613-R1617: KUP Treatment ══
else := {"matched":true,"rule_id":"jdg.insurance.hyper.kup_mandatory_full","package":"jdg.insurance.hyper","priority":1613,"_routing":"","_routing_reason":"OC obowiązkowe: 100% KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Składka na obowiązkowe OC — KUP w 100%"]} {
    object.get(input.invoice, "expense_type", "") == "MANDATORY_OC_PREMIUM"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.kup_mandatory_over_limit","package":"jdg.insurance.hyper","priority":1614,"_routing":"","_routing_reason":"OC ponad minimum: proporcja","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Składka OC ponad ustawowe minimum — KUP jeśli uzasadnione biznesowo"]} {
    object.get(input.invoice, "insurance_coverage_exceeds_minimum", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.kup_voluntary_oc","package":"jdg.insurance.hyper","priority":1615,"_routing":"","_routing_reason":"Dobrowolne OC biznesowe: KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Dobrowolne OC z uzasadnieniem biznesowym — KUP"]} {
    object.get(input.invoice, "expense_type", "") == "VOLUNTARY_OC"
    object.get(input.invoice, "business_justification", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.kup_life_insurance_limited","package":"jdg.insurance.hyper","priority":1616,"_routing":"","_routing_reason":"Ubezpieczenie na życie: limit KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Ubezpieczenie na życie — KUP tylko składki za pracowników (do limitu)"]} {
    object.get(input.invoice, "expense_type", "") == "LIFE_INSURANCE"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.kup_property_full","package":"jdg.insurance.hyper","priority":1617,"_routing":"","_routing_reason":"Ubezpieczenie mienia: KUP 100%","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Ubezpieczenie mienia firmowego — KUP 100%"]} {
    object.get(input.invoice, "expense_type", "") == "PROPERTY_INSURANCE"
}

# ══ R1618-R1622: Insurance Claims ══
else := {"matched":true,"rule_id":"jdg.insurance.hyper.claim_payout_revenue","package":"jdg.insurance.hyper","priority":1618,"_routing":"","_routing_reason":"Odszkodowanie: przychód podatkowy","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":["Odszkodowanie z OC/mienia — przychód podatkowy JDG"]} {
    object.get(input.jdg_entrepreneur, "insurance_payout_received", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.claim_reduced_by_loss","package":"jdg.insurance.hyper","priority":1619,"_routing":"","_routing_reason":"Odszkodowanie pomniejszone o stratę","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":["Przychód z odszkodowania = kwota odszkodowania - udokumentowana strata"]} {
    object.get(input.jdg_entrepreneur, "payout_compensates_for_loss", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.claim_business_interruption","package":"jdg.insurance.hyper","priority":1620,"_routing":"","_routing_reason":"BI: odszkodowanie opodatkowane","_legal_basis":"Art. 14 PIT","_warnings":["Odszkodowanie za przerwę w działalności (BI) — w pełni opodatkowane"]} {
    object.get(input.jdg_entrepreneur, "bi_insurance_payout", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.claim_personal_injury_exempt","package":"jdg.insurance.hyper","priority":1621,"_routing":"","_routing_reason":"Odszkodowanie osobowe: zwolnione","_legal_basis":"Art. 21 ust. 1 pkt 3c PIT","_warnings":["Odszkodowanie za uszczerbek na zdrowiu — zwolnione z PIT"]} {
    object.get(input.jdg_entrepreneur, "personal_injury_claim", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.claim_late_interest_taxable","package":"jdg.insurance.hyper","priority":1622,"_routing":"","_routing_reason":"Odsetki od opóźnionego odszkodowania","_legal_basis":"Art. 17 ust. 1 PIT","_warnings":["Odsetki od opóźnionej wypłaty odszkodowania — opodatkowane jako przychód z kapitałów"]} {
    object.get(input.jdg_entrepreneur, "late_payout_interest_received", false) == true
}

# ══ R1623-R1627: VAT on Insurance ══
else := {"matched":true,"rule_id":"jdg.insurance.hyper.vat_exemption_insurance","package":"jdg.insurance.hyper","priority":1623,"_routing":"","_routing_reason":"VAT: ubezpieczenia zwolnione","_legal_basis":"Art. 43 ust. 1 pkt 37 VAT","_warnings":["Usługi ubezpieczeniowe — zwolnione z VAT"]} {
    object.get(input.invoice, "expense_type", "") == "INSURANCE_SERVICE"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.vat_assistance_23pct","package":"jdg.insurance.hyper","priority":1624,"_routing":"","_routing_reason":"Assistance: 23% VAT","_legal_basis":"Art. 41 VAT","_warnings":["Usługi assistance niebędące integralną częścią ubezpieczenia — 23% VAT"]} {
    object.get(input.invoice, "expense_type", "") == "ASSISTANCE"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.vat_damage_assessment_23pct","package":"jdg.insurance.hyper","priority":1625,"_routing":"","_routing_reason":"Wycena szkód: 23% VAT","_legal_basis":"Art. 41 VAT","_warnings":["Wycena szkód przez niezależnego eksperta — 23% VAT"]} {
    object.get(input.invoice, "service_type", "") == "DAMAGE_ASSESSMENT"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.vat_broker_23pct","package":"jdg.insurance.hyper","priority":1626,"_routing":"","_routing_reason":"Broker: 23% VAT","_legal_basis":"Art. 41 VAT","_warnings":["Usługi brokera ubezpieczeniowego — 23% VAT"]} {
    object.get(input.invoice, "provider_type", "") == "INSURANCE_BROKER"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.vat_personal_insurance_blocked","package":"jdg.insurance.hyper","priority":1627,"_routing":"","_routing_reason":"Ubezpieczenie osobiste: VAT nieodliczalny","_legal_basis":"Art. 88 VAT","_warnings":["Ubezpieczenia osobiste niezwiązane z JDG — VAT nie podlega odliczeniu"]} {
    object.get(input.invoice, "insurance_personal_not_business", false) == true
}

# ══ R1628-R1632: Voluntary Insurance ══
else := {"matched":true,"rule_id":"jdg.insurance.hyper.voluntary_cyber","package":"jdg.insurance.hyper","priority":1628,"_routing":"","_routing_reason":"Cyber-OC: KUP","_legal_basis":"Art. 22 PIT","_warnings":["Cyber-OC — rekomendowane dla IT JDG, KUP 100%"]} {
    object.get(input.invoice, "expense_type", "") == "CYBER_INSURANCE"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.voluntary_dno","package":"jdg.insurance.hyper","priority":1629,"_routing":"","_routing_reason":"D&O: KUP","_legal_basis":"Art. 22 PIT","_warnings":["Ubezpieczenie D&O dla zarządzających — KUP"]} {
    object.get(input.invoice, "expense_type", "") == "DAO_INSURANCE"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.voluntary_key_person","package":"jdg.insurance.hyper","priority":1630,"_routing":"","_routing_reason":"Key person: KUP","_legal_basis":"Art. 22 PIT","_warnings":["Ubezpieczenie kluczowej osoby (właściciela) — KUP jeśli uzasadnione"]} {
    object.get(input.invoice, "expense_type", "") == "KEY_PERSON_INSURANCE"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.voluntary_trade_credit","package":"jdg.insurance.hyper","priority":1631,"_routing":"","_routing_reason":"Ubezpieczenie należności: KUP","_legal_basis":"Art. 22 PIT","_warnings":["Ubezpieczenie należności handlowych — KUP"]} {
    object.get(input.invoice, "expense_type", "") == "TRADE_CREDIT_INSURANCE"
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.voluntary_inventory_theft","package":"jdg.insurance.hyper","priority":1632,"_routing":"","_routing_reason":"Ubezpieczenie od kradzieży: KUP","_legal_basis":"Art. 22 PIT","_warnings":["Ubezpieczenie zapasów od kradzieży — KUP"]} {
    object.get(input.invoice, "expense_type", "") == "THEFT_INSURANCE"
}

# ══ R1633-R1635: Gaps ══
else := {"matched":true,"rule_id":"jdg.insurance.hyper.gap_mandatory_missing","package":"jdg.insurance.hyper","priority":1633,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Brak obowiązkowego OC","_legal_basis":"Ustawy branżowe","_warnings":["Brak obowiązkowego OC — kara administracyjna + odpowiedzialność odszkodowawcza osobista!"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
    object.get(input.jdg_entrepreneur, "insurance_policy_active", false) == false
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.gap_sum_insufficient","package":"jdg.insurance.hyper","priority":1634,"_routing":"WARNING","_routing_reason":"Suma ubezpieczenia poniżej minimum","_legal_basis":"Ustawy branżowe","_warnings":["Suma ubezpieczenia poniżej wymaganego minimum — zwiększ OC!"]} {
    object.get(input.jdg_entrepreneur, "insurance_sum_below_minimum", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.gap_policy_expiring_30days","package":"jdg.insurance.hyper","priority":1635,"_routing":"WARNING","_routing_reason":"Polisa wygasa za <30 dni","_legal_basis":"—","_warnings":["Polisa OC wygasa za mniej niż 30 dni — odnów natychmiast!"]} {
    object.get(input.jdg_entrepreneur, "policy_days_remaining", 999) <= 30
}
