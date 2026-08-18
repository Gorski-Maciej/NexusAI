# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 41

package jdg.hyper.sanctions

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.hyper.sanctions.no_match","package":"jdg.hyper.sanctions","priority":99999}

# jdg.hyper.sanctions.kks.conviction.extended_audit_period — Możliwość przedłużonej kontroli (60 dni zamiast 30)
decide :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.extended_audit_period","_legal_basis":"Art. 83 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.business_partner_trust_loss — Utrata zaufania kontrahentów
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.business_partner_trust_loss","_legal_basis":"Art. 105a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.joint_vat_liability_partners — Ryzyko odpowiedzialności solidarnej kontrahentów
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.joint_vat_liability_partners","_legal_basis":"Art. 105a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.supply_chain_due_diligence — Konieczność wzmożonej należytej staranności w łańcuchu dostaw
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.supply_chain_due_diligence","_legal_basis":"Art. 105a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.contract_termination_clauses — Kontrahenci mogą rozwiązać umowy
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.contract_termination_clauses","_legal_basis":"ustawy z dnia 23 kwietnia 1964 r. — Kodeks cywilny","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.conviction.isolation_from_business_networks — Izolacja od sieci biznesowych
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.conviction.isolation_from_business_networks","_legal_basis":"Art. 105a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["KKS+IZOLACJA — skazanie za przestępstwo skarbowe może skutkować wykluczeniem z obrotu gospodarczego"]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.misdemeanor_3_years — Zatarcie skazania za wykroczenie KKS — 3 lata
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.misdemeanor_3_years","_legal_basis":"Art. 21 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.crime_5_years — Zatarcie skazania za przestępstwo KKS — 5 lat
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.crime_5_years","_legal_basis":"Art. 21 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.effect_clean_record — Skutek zatarcia — "czysta karta"
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.effect_clean_record","_legal_basis":"Art. 106 ustawy z dnia 6 czerwca 1997 r. — Kodeks karny","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.business_ban_lift — Automatyczne zniesienie zakazu prowadzenia działalności
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.business_ban_lift","_legal_basis":"Art. 41 ustawy z dnia 6 czerwca 1997 r. — Kodeks karny","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.rehabilitation.tax_office_notification — Obowiązek powiadomienia US o zatarciu (przywrócenie normalnego trybu)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.rehabilitation.tax_office_notification","_legal_basis":"Art. 119b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.full_personal_liability — Egzekucja z całego majątku po skazaniu
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.full_personal_liability","_legal_basis":"Art. 26 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.no_asset_concealment — Zakaz ukrywania majątku przed egzekucją (Art. 36 OP + KKS)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.no_asset_concealment","_legal_basis":"Art. 36 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.), Art. 61 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.bank_account_seizure — Zajęcie rachunków bankowych
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.bank_account_seizure","_legal_basis":"Art. 75-89 ustawy z dnia 17 czerwca 1966 r. o postępowaniu egzekucyjnym w administracji","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.collateral_requirements — Wymóg złożenia zabezpieczenia majątkowego
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.collateral_requirements","_legal_basis":"Art. 33 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.kks.enforcement.insolvency_filing_obligation — Obowiązek złożenia wniosku o upadłość przy niewypłacalności
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.enforcement.insolvency_filing_obligation","_legal_basis":"Art. 21 ustawy z dnia 28 lutego 2003 r. — Prawo upadłościowe","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.exemption_doctor — Lekarz — zwolnienie z VAT (cel terapeutyczny)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.exemption_doctor","_legal_basis":"Art. 43 ust. 1 pkt 18-19 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.no_exemption_lawyer — Adwokat/radca — NIE zwolnienie (23% VAT)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.no_exemption_lawyer","_legal_basis":"Art. 41 ust. 1 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.exemption_nurse_midwife — Pielęgniarka/położna — zwolnienie z VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.exemption_nurse_midwife","_legal_basis":"Art. 43 ust. 1 pkt 19-20 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.education_tutor_exemption — Korepetycje/korepetytor — zwolnienie z VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.education_tutor_exemption","_legal_basis":"Art. 43 ust. 1 pkt 26-29 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.vat.exemption_psychologist — Psycholog/psychoterapeuta — zwolnienie z VAT
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.vat.exemption_psychologist","_legal_basis":"Art. 43 ust. 1 pkt 21 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.chamber_fees_full — Składki korporacyjne — pełny KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.chamber_fees_full","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.professional_insurance_kup — OC zawodowe — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.professional_insurance_kup","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.continuing_education_kup — Doskonalenie zawodowe — KUP (jeśli związane z JDG)
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.continuing_education_kup","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.books_journals_kup — Literatura fachowa — KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.books_journals_kup","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.kup.office_rent_home_office — Gabinet w domu — proporcja KUP
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.kup.office_rent_home_office","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.no_start_relief_former_employer — Brak ulgi na start przy świadczeniu usług dla byłego pracodawcy
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.no_start_relief_former_employer","_legal_basis":"Art. 18a ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.concurrent_chamber_and_jdg — Zbieg: praktyka zawodowa + JDG → składki z obu tytułów
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.concurrent_chamber_and_jdg","_legal_basis":"Art. 9 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.mandatory_sickness_insurance — Obowiązkowe ubezpieczenie chorobowe w niektórych zawodach
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.mandatory_sickness_insurance","_legal_basis":"Art. 11 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.dual_health_contribution — Podwójna składka zdrowotna przy równoległym zatrudnieniu
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.dual_health_contribution","_legal_basis":"Art. 82 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.zus.minimum_base_health — Minimalna podstawa składki zdrowotnej dla zawodu regulowanego
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.zus.minimum_base_health","_legal_basis":"Art. 81 ust. 2 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.attorney_client — Tajemnica adwokacka — dokumenty wyłączone z kontroli US
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.attorney_client","_legal_basis":"Art. 180 § 3 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.tax_advisor — Tajemnica doradcy podatkowego — ochrona przed kontrolą
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.tax_advisor","_legal_basis":"Art. 180 § 3 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.no_protection_for_business_records — Dokumenty biznesowe NIE są objęte tajemnicą
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.no_protection_for_business_records","_legal_basis":"Art. 180 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.mdr_transfer_to_client — Privilege → obowiązek MDR przechodzi na klienta
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.mdr_transfer_to_client","_legal_basis":"Art. 86a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.privilege.limits_crime_fraud_exception — Wyjątek crime-fraud: tajemnica nie chroni przestępstwa
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.privilege.limits_crime_fraud_exception","_legal_basis":"Art. 180 § 4 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.membership_mandatory — Przynależność do izby — obowiązkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.membership_mandatory","_legal_basis":"ustaw regulujących wykonywanie zawodów regulowanych","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.fees_tax_deductible — Składki izbowe potrącalne od dochodu
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.fees_tax_deductible","_legal_basis":"Art. 26 ust. 1 pkt 13 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.disciplinary_proceedings — Postępowanie dyscyplinarne — wpływ na działalność JDG
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.disciplinary_proceedings","_legal_basis":"ustaw regulujących wykonywanie zawodów regulowanych","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.license_suspension_consequences — Zawieszenie licencji → skutki podatkowe i ZUS
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.license_suspension_consequences","_legal_basis":"ustaw regulujących wykonywanie zawodów regulowanych","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# jdg.hyper.sanctions.regulated.chamber.practice_certificate_renewal — Odnowienie certyfikatu praktyki — termin
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.regulated.chamber.practice_certificate_renewal","_legal_basis":"ustaw regulujących wykonywanie zawodów regulowanych","_warnings":[]} if {
    object.get(input.invoice, "compliance_violation", false) == true
}

# ══ L-SN-1 Fix: VAT/KSeF Sanctions (P23 P0) — R1601-R1612 ══
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.vat.30pct_understatement","_legal_basis":"Art. 112b ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Sankcja VAT 30% — niezłożenie deklaracji lub zaniżenie zobowiązania = 30% kwoty zaniżenia. 20% przy korekcie przed kontrolą. 100% przy zorganizowanej grupie zakupowej"]} if {
    object.get(input.jdg_entrepreneur, "vat_understatement_detected", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.vat.30pct_undue_deduction","_legal_basis":"Art. 112c ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Sankcja VAT 30% — nienależne odliczenie VAT (np. z pustej faktury). 20% przy korekcie deklaracji przed dniem doręczenia zawiadomienia o kontroli"]} if {
    object.get(input.jdg_entrepreneur, "undue_vat_deduction_detected", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.ksef.500k_pln_no_invoice","_legal_basis":"Art. 106n ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.) (od 01.02.2026)","_warnings":["Sankcja KSeF od 01.02.2026 — brak faktury w KSeF: do 500 000 PLN (100% kwoty podatku z faktury, min. 1 000 PLN). 50% kary przy złożeniu faktury w terminie 14 dni"]} if {
    object.get(input.jdg_entrepreneur, "ksef_violation_detected", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.ksef.50pct_14day_correction","_legal_basis":"Art. 106n ust. 4 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["KSeF — złóż zaległą fakturę w ciągu 14 dni od terminu → kara 50%. Po 14 dniach: kara 100%. Czynny żal (Art. 16 KKS) może zwolnić z odpowiedzialności"]} if {
    object.get(input.jdg_entrepreneur, "ksef_late_invoice_days", 0) <= 14
    object.get(input.jdg_entrepreneur, "ksef_late_invoice_days", 0) > 0
}
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.jpk.on_demand_193a_ordpu","_legal_basis":"Art. 193a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Brak JPK na żądanie organu (7 dni od doręczenia) — kara porządkowa. Obowiązek dotyczy JPK_VAT, JPK_FA, JPK_KR i innych struktur JPK"]} if {
    object.get(input.document, "jpk_on_demand_overdue", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.ordinal.penalty_2800_pln","_legal_basis":"Art. 262 § 2 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Kara porządkowa: 2 800 PLN (niestawiennictwo, odmowa zeznań). Kara przymuszająca: do 5 600 PLN (wielokrotnie). Maks. łącznie 16 800 PLN"]} if {
    object.get(input.jdg_entrepreneur, "ordinal_penalty_risk", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.voluntary_disclosure_art16","_legal_basis":"Art. 16 § 1-2 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Czynny żal — złóż zawiadomienie do US PRZED wszczęciem postępowania = zwolnienie z odpowiedzialności KKS. Warunek: wpłata należności w ciągu 7 dni"]} if {
    object.get(input.jdg_entrepreneur, "voluntary_disclosure_eligible", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.small_value_fine_250_5000","_legal_basis":"Art. 48 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Wykroczenie skarbowe (mała wartość uszczuplenia ≤5 × płaca minimalna) — grzywna 250-5 000 PLN. Wartości podlegają rewaloryzacji"]} if {
    object.get(input.jdg_entrepreneur, "kks_small_value_violation", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.sanctions.kks.interest_150pct","_legal_basis":"Art. 56 § 1 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)","_warnings":["Odsetki karne — 150% stawki odsetek za zwłokę (aktualnie ~22% rocznie). Naliczane od dnia popełnienia czynu do dnia zapłaty"]} if {
    object.get(input.jdg_entrepreneur, "penalty_interest_applicable", false) == true
}
else := {"matched":true,"rule_id":"jdg.hyper.sanctions.aggregate_sanction_risk_score","_legal_basis":"Art. 54-56 ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.), Art. 112b-112c ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Agregacja ryzyka sankcyjnego: VAT 30%, KSeF 500k, KKS, kary porządkowe. Priorytet: czynny żal > korekta > odwołanie > spór sądowy"]} if {
    object.get(input.jdg_entrepreneur, "sanction_risk_score_requested", false) == true
}
