# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.regulated hyper-granularity (Doc 45: R1576-R1607)
# Atom rules: VAT per profession, KUP, ZUS, privilege, chamber, cross-border
# Rules: 32 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.regulated.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.regulated.hyper.no_match","package":"jdg.regulated.hyper","priority":99999}

# ══ R1576-R1580: VAT Exemptions per Profession ══
decide := {"matched":true,"rule_id":"jdg.regulated.hyper.vat_exempt_doctor","package":"jdg.regulated.hyper","priority":1576,"_routing":"","_routing_reason":"Lekarz: zwolnienie VAT (terapia)","_legal_basis":"Art. 43 ust. 1 pkt 18-19 VAT","_warnings":["Lekarz/dentysta — usługi terapeutyczne zwolnione z VAT. Medycyna estetyczna = 23%"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "86.21.Z"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.vat_no_exemption_lawyer","package":"jdg.regulated.hyper","priority":1577,"_routing":"","_routing_reason":"Adwokat/radca: 23% VAT","_legal_basis":"Art. 41 ust. 1 VAT","_warnings":["Adwokat/radca prawny/doradca podatkowy — usługi opodatkowane 23% VAT"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "69.10.Z"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.vat_exempt_nurse_midwife","package":"jdg.regulated.hyper","priority":1578,"_routing":"","_routing_reason":"Pielęgniarka/położna: zwolnienie","_legal_basis":"Art. 43 ust. 1 pkt 19-20 VAT","_warnings":["Pielęgniarka/położna z licencją — usługi zwolnione z VAT"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "86.90.A"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.vat_exempt_tutor","package":"jdg.regulated.hyper","priority":1579,"_routing":"","_routing_reason":"Korepetytor: zwolnienie","_legal_basis":"Art. 43 ust. 1 pkt 26-29 VAT","_warnings":["Korepetytor z certyfikatem — usługi edukacyjne zwolnione z VAT"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "85.60.Z"
    object.get(input.jdg_entrepreneur, "qualifications_certified", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.vat_exempt_psychologist","package":"jdg.regulated.hyper","priority":1580,"_routing":"","_routing_reason":"Psycholog: zwolnienie","_legal_basis":"Art. 43 ust. 1 pkt 21 VAT","_warnings":["Psycholog/psychoterapeuta z licencją — usługi zwolnione z VAT"]} {
    object.get(input.jdg_entrepreneur, "pkd_main", "") == "86.90.E"
}

# ══ R1581-R1585: KUP for Regulated Professions ══
else := {"matched":true,"rule_id":"jdg.regulated.hyper.kup_chamber_fees_full","package":"jdg.regulated.hyper","priority":1581,"_routing":"","_routing_reason":"Składki korporacyjne: KUP 100%","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Składki izbowe (adwokacka, radcowska, lekarska) — KUP w dacie poniesienia"]} {
    object.get(input.invoice, "expense_type", "") == "CHAMBER_FEES"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.kup_professional_oc_kup","package":"jdg.regulated.hyper","priority":1582,"_routing":"","_routing_reason":"OC zawodowe: KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Obowiązkowe OC zawodowe — KUP 100%"]} {
    object.get(input.invoice, "expense_type", "") == "PROFESSIONAL_OC"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.kup_continuing_education","package":"jdg.regulated.hyper","priority":1583,"_routing":"","_routing_reason":"Doskonalenie zawodowe: KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Szkolenia i konferencje branżowe — KUP jeśli związane z JDG"]} {
    object.get(input.invoice, "expense_type", "") == "CONTINUING_EDUCATION"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.kup_professional_literature","package":"jdg.regulated.hyper","priority":1584,"_routing":"","_routing_reason":"Literatura fachowa: KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Książki i publikacje fachowe — KUP"]} {
    object.get(input.invoice, "expense_type", "") == "PROFESSIONAL_LITERATURE"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.kup_home_office_proportion","package":"jdg.regulated.hyper","priority":1585,"_routing":"","_routing_reason":"Gabinet w domu: KUP proporcjonalny","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Gabinet w domu — KUP proporcjonalny do powierzchni (m² gabinetu / m² całkowite)"]} {
    object.get(input.invoice, "expense_type", "") == "HOME_OFFICE"
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# ══ R1586-R1590: ZUS for Regulated Professions ══
else := {"matched":true,"rule_id":"jdg.regulated.hyper.zus_no_start_relief","package":"jdg.regulated.hyper","priority":1586,"_routing":"WARNING","_routing_reason":"Brak ulgi na start u byłego pracodawcy","_legal_basis":"Art. 18a SUS","_warnings":["Zawód regulowany — brak ulgi na start, jeśli świadczysz usługi dla byłego pracodawcy"]} {
    object.get(input.jdg_entrepreneur, "former_employer_client", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.zus_concurrent_titles","package":"jdg.regulated.hyper","priority":1587,"_routing":"","_routing_reason":"Zbieg: praktyka + JDG","_legal_basis":"Art. 9 SUS","_warnings":["Zbieg tytułów: praktyka zawodowa + JDG → składki z obu tytułów"]} {
    object.get(input.jdg_entrepreneur, "concurrent_titles", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.zus_sickness_mandatory","package":"jdg.regulated.hyper","priority":1588,"_routing":"","_routing_reason":"Chorobowe obowiązkowe","_legal_basis":"Art. 11 SUS","_warnings":["Zawód medyczny — obowiązkowe ubezpieczenie chorobowe"]} {
    object.get(input.jdg_entrepreneur, "sickness_insurance_mandatory", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.zus_dual_health","package":"jdg.regulated.hyper","priority":1589,"_routing":"","_routing_reason":"Podwójna składka zdrowotna","_legal_basis":"Art. 82 u.ś.o.z.","_warnings":["Równoległe zatrudnienie + JDG — składka zdrowotna z obu tytułów"]} {
    object.get(input.jdg_entrepreneur, "concurrent_employment", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.zus_min_health_base","package":"jdg.regulated.hyper","priority":1590,"_routing":"","_routing_reason":"Minimalna podstawa zdrowotna","_legal_basis":"Art. 81 ust. 2 u.ś.o.z.","_warnings":["Zawód regulowany na skali PIT — minimalna podstawa składki zdrowotnej = płaca minimalna"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}

# ══ R1591-R1595: Legal Privilege ══
else := {"matched":true,"rule_id":"jdg.regulated.hyper.privilege_attorney_client","package":"jdg.regulated.hyper","priority":1591,"_routing":"","_routing_reason":"Tajemnica adwokacka — wyłączenie","_legal_basis":"Art. 180 § 3 OP","_warnings":["Dokumenty objęte tajemnicą adwokacką/radcowską — wyłączone z kontroli US"]} {
    object.get(input.document, "attorney_privileged", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.privilege_tax_advisor","package":"jdg.regulated.hyper","priority":1592,"_routing":"","_routing_reason":"Tajemnica doradcy podatkowego","_legal_basis":"Art. 180 § 3 OP","_warnings":["Dokumenty objęte tajemnicą doradcy podatkowego — ochrona przed kontrolą"]} {
    object.get(input.document, "tax_advisor_privileged", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.privilege_business_records_no","package":"jdg.regulated.hyper","priority":1593,"_routing":"","_routing_reason":"Dokumenty biznesowe NIE objęte","_legal_basis":"Art. 180 OP","_warnings":["Dokumenty biznesowe (faktury, umowy handlowe) NIE są objęte tajemnicą zawodową"]} {
    object.get(input.document, "document_type", "") == "BUSINESS_RECORD"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.privilege_mdr_transfer","package":"jdg.regulated.hyper","priority":1594,"_routing":"WARNING","_routing_reason":"Privilege → MDR na klienta","_legal_basis":"Art. 86a OP","_warnings":["Tajemnica zawodowa — obowiązek MDR przechodzi na klienta"]} {
    object.get(input.jdg_entrepreneur, "mdr_scheme_detected", false) == true
    object.get(input.jdg_entrepreneur, "attorney_privilege_applies", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.privilege_crime_fraud_exception","package":"jdg.regulated.hyper","priority":1595,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Wyjątek crime-fraud","_legal_basis":"Art. 180 § 4 OP","_warnings":["Tajemnica NIE chroni dokumentów związanych z przestępstwem skarbowym!"]} {
    object.get(input.document, "kks_suspicion", false) == true
}

# ══ R1596-R1600: Chamber Membership ══
else := {"matched":true,"rule_id":"jdg.regulated.hyper.chamber_membership_mandatory","package":"jdg.regulated.hyper","priority":1596,"_routing":"WARNING","_routing_reason":"Przynależność do izby obowiązkowa","_legal_basis":"Ustawy korporacyjne","_warnings":["Zawód regulowany — obowiązkowa przynależność do samorządu zawodowego"]} {
    object.get(input.jdg_entrepreneur, "chamber_membership_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.chamber_fees_deductible","package":"jdg.regulated.hyper","priority":1597,"_routing":"","_routing_reason":"Składki izbowe — KUP (Art. 22 PIT) lub odliczenie od dochodu (Art. 26 PIT)","_legal_basis":"Art. 22 ust. 1 PIT / Art. 26 ust. 1 pkt 13 PIT","_warnings":["Składki izbowe — KUP (Art. 22 PIT) dla JDG; odliczenie od dochodu (Art. 26 PIT) dla etatu (v7.0 FIX KREG-3)"]} {
    object.get(input.invoice, "expense_type", "") == "CHAMBER_FEES"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.chamber_disciplinary","package":"jdg.regulated.hyper","priority":1598,"_routing":"WARNING","_routing_reason":"Postępowanie dyscyplinarne","_legal_basis":"Ustawy korporacyjne","_warnings":["Postępowanie dyscyplinarne w toku — ryzyko dla działalności JDG"]} {
    object.get(input.jdg_entrepreneur, "disciplinary_proceeding_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.chamber_license_suspension","package":"jdg.regulated.hyper","priority":1599,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Zawieszenie licencji → zawieś JDG","_legal_basis":"Ustawy korporacyjne","_warnings":["Zawieszenie licencji zawodowej — obowiązek zawieszenia JDG!"]} {
    object.get(input.jdg_entrepreneur, "license_suspended", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.chamber_certificate_renewal","package":"jdg.regulated.hyper","priority":1600,"_routing":"WARNING","_routing_reason":"Certyfikat — odnowienie","_legal_basis":"Ustawy korporacyjne","_warnings":["Certyfikat zawodowy wygasa — złóż wniosek o odnowienie"]} {
    object.get(input.jdg_entrepreneur, "certificate_expiring_soon", false) == true
}

# ══ R1601-R1605: Cross-Border ══
else := {"matched":true,"rule_id":"jdg.regulated.hyper.cross_border_eu_recognition","package":"jdg.regulated.hyper","priority":1601,"_routing":"","_routing_reason":"Kwalifikacje UE — automatyczne uznanie","_legal_basis":"Dyrektywa 2005/36/WE","_warnings":["Kwalifikacje z UE — automatyczne uznawanie (dla większości zawodów)"]} {
    object.get(input.jdg_entrepreneur, "qualification_origin", "") == "EU"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.cross_border_non_eu_nostrification","package":"jdg.regulated.hyper","priority":1602,"_routing":"TRIAGE_QUEUE","_routing_reason":"Kwalifikacje spoza UE — nostryfikacja","_legal_basis":"Ustawy branżowe","_warnings":["Kwalifikacje spoza UE — wymagana nostryfikacja dyplomu"]} {
    object.get(input.jdg_entrepreneur, "qualification_origin", "") == "NON_EU"
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.cross_border_temporary_services","package":"jdg.regulated.hyper","priority":1603,"_routing":"","_routing_reason":"Usługi tymczasowe w UE","_legal_basis":"Dyrektywa 2005/36/WE","_warnings":["Tymczasowe usługi w UE — może być wymagana deklaracja"]} {
    object.get(input.jdg_entrepreneur, "service_temporary_cross_border", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.cross_border_double_tax_risk","package":"jdg.regulated.hyper","priority":1604,"_routing":"WARNING","_routing_reason":"Podwójne opodatkowanie transgraniczne","_legal_basis":"Umowy UPO","_warnings":["Praca w 2 krajach — ryzyko podwójnego opodatkowania. Sprawdź UPO"]} {
    object.get(input.jdg_entrepreneur, "works_in_two_countries", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.cross_border_vat_abroad","package":"jdg.regulated.hyper","priority":1605,"_routing":"WARNING","_routing_reason":"VAT za granicą przy B2C","_legal_basis":"Art. 28k VAT, OSS","_warnings":["Usługi B2C do UE — może być wymagana rejestracja VAT za granicą (lub OSS)"]} {
    object.get(input.jdg_entrepreneur, "b2c_services_to_eu", false) == true
}

# ══ R1606-R1607: Aggregate ══
else := {"matched":true,"rule_id":"jdg.regulated.hyper.aggregate_risk_profile","package":"jdg.regulated.hyper","priority":1606,"_routing":"","_routing_reason":"Profil ryzyka zawodu regulowanego","_legal_basis":"—","_warnings":["Profil ryzyka: VAT, KUP, ZUS, tajemnica zawodowa — dla Twojego zawodu"]} {
    object.get(input.jdg_entrepreneur, "profession_risk_assessment_needed", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.aggregate_compliance_checklist","package":"jdg.regulated.hyper","priority":1607,"_routing":"","_routing_reason":"Checklista compliance roczna","_legal_basis":"—","_warnings":["Roczna checklista: OC ważne, składki izbowe opłacone, certyfikat aktualny"]} {
    object.get(input.jdg_entrepreneur, "annual_compliance_check", false) == true
}
