# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 41

package jdg.hyper.sanctions

default decide := {"matched":false,"rule_id":"jdg.hyper.sanctions.no_match","package":"jdg.hyper.sanctions","priority":99999}

# jdg.hyper.sanctions.kks.conviction.extended_audit_period — Możliwość przedłużonej kontroli (60 dni zamiast 30)
decide :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.extended_audit_period","package":"jdg.hyper.sanctions","priority":1560,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `audit_in_progress == true`","_legal_basis":"Art. 83 PP","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.business_partner_trust_loss — Utrata zaufania kontrahentów
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.business_partner_trust_loss","package":"jdg.hyper.sanctions","priority":1561,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `conviction_public == true`","_legal_basis":"—","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.joint_vat_liability_partners — Ryzyko odpowiedzialności solidarnej kontrahentów
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.joint_vat_liability_partners","package":"jdg.hyper.sanctions","priority":1562,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted_for_vat_fraud == true`","_legal_basis":"Art. 105a VAT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.supply_chain_due_diligence — Konieczność wzmożonej należytej staranności w łańcuchu dostaw
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.supply_chain_due_diligence","package":"jdg.hyper.sanctions","priority":1563,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true`","_legal_basis":"Art. 105a VAT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.contract_termination_clauses — Kontrahenci mogą rozwiązać umowy
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.contract_termination_clauses","package":"jdg.hyper.sanctions","priority":1564,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `contracts_have_moral_clause == true`","_legal_basis":"KC — klauzule umowne","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.isolation_from_business_networks — Izolacja od sieci biznesowych
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.isolation_from_business_networks","package":"jdg.hyper.sanctions","priority":1565,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `conviction_public == true`","_legal_basis":"Art. 105a VAT","_warnings":["KKS+IZOLACJA — skazanie za przestępstwo skarbowe może skutkować wykluczeniem z obrotu gospodarczego"]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.misdemeanor_3_years — Zatarcie skazania za wykroczenie KKS — 3 lata
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.misdemeanor_3_years","package":"jdg.hyper.sanctions","priority":1566,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_offense_type == "MISDEMEANOR"` AND `conviction_spent == false`","_legal_basis":"Art. 21 KKS","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.crime_5_years — Zatarcie skazania za przestępstwo KKS — 5 lat
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.crime_5_years","package":"jdg.hyper.sanctions","priority":1567,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_offense_type == "CRIME"` AND `conviction_spent == false`","_legal_basis":"Art. 21 KKS","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.effect_clean_record — Skutek zatarcia — "czysta karta"
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.effect_clean_record","package":"jdg.hyper.sanctions","priority":1568,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`conviction_spent == true`","_legal_basis":"Art. 106 KK","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.business_ban_lift — Automatyczne zniesienie zakazu prowadzenia działalności
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.business_ban_lift","package":"jdg.hyper.sanctions","priority":1569,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`conviction_spent == true` AND `business_ban_active == true`","_legal_basis":"Art. 41 KK","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.tax_office_notification — Obowiązek powiadomienia US o zatarciu (przywrócenie normalnego trybu)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.tax_office_notification","package":"jdg.hyper.sanctions","priority":1570,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`conviction_spent == true`","_legal_basis":"Praktyka","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.full_personal_liability — Egzekucja z całego majątku po skazaniu
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.full_personal_liability","package":"jdg.hyper.sanctions","priority":1571,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `tax_arrears > 0`","_legal_basis":"Art. 26 OP","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.no_asset_concealment — Zakaz ukrywania majątku przed egzekucją (Art. 36 OP + KKS)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.no_asset_concealment","package":"jdg.hyper.sanctions","priority":1572,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `enforcement_active == true`","_legal_basis":"Art. 36 OP, Art. 61 KKS","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.bank_account_seizure — Zajęcie rachunków bankowych
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.bank_account_seizure","package":"jdg.hyper.sanctions","priority":1573,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `tax_arrears > 0`","_legal_basis":"Art. 75-89 Ustawy o post. egz.","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.collateral_requirements — Wymóg złożenia zabezpieczenia majątkowego
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.collateral_requirements","package":"jdg.hyper.sanctions","priority":1574,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `tax_proceeding_active == true`","_legal_basis":"Art. 33 OP","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.insolvency_filing_obligation — Obowiązek złożenia wniosku o upadłość przy niewypłacalności
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.insolvency_filing_obligation","package":"jdg.hyper.sanctions","priority":1575,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_convicted == true` AND `insolvent == true`","_legal_basis":"Art. 21 Prawa upadłościowego","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.exemption_doctor — Lekarz — zwolnienie z VAT (cel terapeutyczny)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.exemption_doctor","package":"jdg.hyper.sanctions","priority":1576,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main` ∈ ["86.21.Z","86.22.Z"] AND `procedure_code in THERAPEUTIC_CODES`","_legal_basis":"Art. 43 ust. 1 pkt 18-19 VAT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.no_exemption_lawyer — Adwokat/radca — NIE zwolnienie (23% VAT)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.no_exemption_lawyer","package":"jdg.hyper.sanctions","priority":1577,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main` ∈ ["69.10.Z"]","_legal_basis":"Art. 41 ust. 1 VAT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.exemption_nurse_midwife — Pielęgniarka/położna — zwolnienie z VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.exemption_nurse_midwife","package":"jdg.hyper.sanctions","priority":1578,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main` ∈ ["86.90.A","86.90.C"] AND `license_valid == true`","_legal_basis":"Art. 43 ust. 1 pkt 19-20 VAT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.education_tutor_exemption — Korepetycje/korepetytor — zwolnienie z VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.education_tutor_exemption","package":"jdg.hyper.sanctions","priority":1579,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main` ∈ ["85.60.Z"] AND `qualifications_certified == true`","_legal_basis":"Art. 43 ust. 1 pkt 26-29 VAT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.exemption_psychologist — Psycholog/psychoterapeuta — zwolnienie z VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.exemption_psychologist","package":"jdg.hyper.sanctions","priority":1580,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`pkd_main` ∈ ["86.90.E"] AND `license_valid == true`","_legal_basis":"Art. 43 ust. 1 pkt 21 VAT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.chamber_fees_full — Składki korporacyjne — pełny KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.chamber_fees_full","package":"jdg.hyper.sanctions","priority":1581,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "CHAMBER_FEES"` AND `mandatory_by_law == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.professional_insurance_kup — OC zawodowe — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.professional_insurance_kup","package":"jdg.hyper.sanctions","priority":1582,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "PROFESSIONAL_OC"` AND `mandatory_by_law == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.continuing_education_kup — Doskonalenie zawodowe — KUP (jeśli związane z JDG)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.continuing_education_kup","package":"jdg.hyper.sanctions","priority":1583,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "CONTINUING_EDUCATION"` AND `related_to_business == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.books_journals_kup — Literatura fachowa — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.books_journals_kup","package":"jdg.hyper.sanctions","priority":1584,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "PROFESSIONAL_LITERATURE"`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.office_rent_home_office — Gabinet w domu — proporcja KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.office_rent_home_office","package":"jdg.hyper.sanctions","priority":1585,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "HOME_OFFICE"` AND `regulated_profession == true`","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.no_start_relief_former_employer — Brak ulgi na start przy świadczeniu usług dla byłego pracodawcy
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.no_start_relief_former_employer","package":"jdg.hyper.sanctions","priority":1586,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`regulated_profession == true` AND `former_employer_client == true`","_legal_basis":"Art. 18a SUS","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.concurrent_chamber_and_jdg — Zbieg: praktyka zawodowa + JDG → składki z obu tytułów
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.concurrent_chamber_and_jdg","package":"jdg.hyper.sanctions","priority":1587,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`concurrent_titles == true`","_legal_basis":"Art. 9 SUS","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.mandatory_sickness_insurance — Obowiązkowe ubezpieczenie chorobowe w niektórych zawodach
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.mandatory_sickness_insurance","package":"jdg.hyper.sanctions","priority":1588,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`regulated_profession in ["DOCTOR","DENTIST"]`","_legal_basis":"Art. 11 SUS","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.dual_health_contribution — Podwójna składka zdrowotna przy równoległym zatrudnieniu
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.dual_health_contribution","package":"jdg.hyper.sanctions","priority":1589,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`concurrent_employment == true` AND `regulated_profession == true`","_legal_basis":"Art. 82 u.ś.o.z.","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.minimum_base_health — Minimalna podstawa składki zdrowotnej dla zawodu regulowanego
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.minimum_base_health","package":"jdg.hyper.sanctions","priority":1590,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`regulated_profession == true` AND `tax_form == "PIT_SCALE"`","_legal_basis":"Art. 81 ust. 2 u.ś.o.z.","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.attorney_client — Tajemnica adwokacka — dokumenty wyłączone z kontroli US
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.attorney_client","package":"jdg.hyper.sanctions","priority":1591,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`profession == "ATTORNEY"` AND `document_labelled_privileged == true`","_legal_basis":"Art. 180 § 3 OP","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.tax_advisor — Tajemnica doradcy podatkowego — ochrona przed kontrolą
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.tax_advisor","package":"jdg.hyper.sanctions","priority":1592,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`profession == "TAX_ADVISOR"` AND `document_labelled_privileged == true`","_legal_basis":"Art. 180 § 3 OP","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.no_protection_for_business_records — Dokumenty biznesowe NIE są objęte tajemnicą
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.no_protection_for_business_records","package":"jdg.hyper.sanctions","priority":1593,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`document_type == "BUSINESS_RECORD"`","_legal_basis":"Art. 180 OP","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.mdr_transfer_to_client — Privilege → obowiązek MDR przechodzi na klienta
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.mdr_transfer_to_client","package":"jdg.hyper.sanctions","priority":1594,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`profession == "ATTORNEY"` AND `mdr_scheme_detected == true`","_legal_basis":"Art. 86a OP","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.limits_crime_fraud_exception — Wyjątek crime-fraud: tajemnica nie chroni przestępstwa
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.limits_crime_fraud_exception","package":"jdg.hyper.sanctions","priority":1595,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`kks_suspicion == true` AND `document_related_to_crime == true`","_legal_basis":"Art. 180 § 4 OP","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.membership_mandatory — Przynależność do izby — obowiązkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.membership_mandatory","package":"jdg.hyper.sanctions","priority":1596,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`regulated_profession == true`","_legal_basis":"Ustawy korporacyjne","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.fees_tax_deductible — Składki izbowe potrącalne od dochodu
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.fees_tax_deductible","package":"jdg.hyper.sanctions","priority":1597,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"`expense_type == "CHAMBER_FEES"`","_legal_basis":"Art. 26 ust. 1 pkt 13 PIT","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.disciplinary_proceedings — Postępowanie dyscyplinarne — wpływ na działalność JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.disciplinary_proceedings","package":"jdg.hyper.sanctions","priority":1598,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`disciplinary_proceeding_active == true`","_legal_basis":"Ustawy korporacyjne","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.license_suspension_consequences — Zawieszenie licencji → skutki podatkowe i ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.license_suspension_consequences","package":"jdg.hyper.sanctions","priority":1599,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`license_suspended == true`","_legal_basis":"Ustawy korporacyjne","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.practice_certificate_renewal — Odnowienie certyfikatu praktyki — termin
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.practice_certificate_renewal","package":"jdg.hyper.sanctions","priority":1600,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"`certificate_expiring_within_3_months == true`","_legal_basis":"Ustawy korporacyjne","_warnings":[]} {
    object.get(input.invoice, "compliance_violation", false) == true
}
