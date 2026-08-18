# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.edelivery

default decide := {"matched":false,"rule_id":"jdg.hyper.edelivery.no_match","package":"jdg.hyper.edelivery","priority":99999}

# jdg.hyper.edelivery.force_majeure.documents.backup_obligation — Dokumenty
decide :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.documents.backup_obligation","_legal_basis":"Art. 86 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Obowiązek posiadania backupu cyfrowego dokumentacji"]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.documents.electronic_preservation — Dokumenty
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.documents.electronic_preservation","_legal_basis":"Art. 86 § 2 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.insurance.cover_check — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.insurance.cover_check","_legal_basis":"Art. 14 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Sprawdzenie zakresu ubezpieczenia business interruption"]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.insurance.claim_procedure — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.insurance.claim_procedure","_legal_basis":"Art. 14 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.insurance.payout_tax_treatment — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.insurance.payout_tax_treatment","_legal_basis":"Art. 14 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Odszkodowanie jako przychód podatkowy"]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.suspension.automatic — Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.suspension.automatic","_legal_basis":"Art. 22 ustawy z dnia 6 marca 2018 r. — Prawo przedsiębiorców (Dz.U. 2025 poz. 123)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.suspension.zus_consequences — Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.suspension.zus_consequences","_legal_basis":"Art. 36a ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.suspension.tax_consequences — Zawieszenie
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.suspension.tax_consequences","_legal_basis":"Art. 44 ust. 6b ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.loss.carry_back — Strata
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.loss.carry_back","_legal_basis":"Art. 9 ust. 3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.loss.enhanced_deduction — Strata
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.loss.enhanced_deduction","_legal_basis":"Art. 9 ust. 3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.deadlines.mf_communication_monitoring — Terminy
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.deadlines.mf_communication_monitoring","_legal_basis":"Art. 47 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.), Art. 103 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.), Art. 44 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Kalendarz terminów: ZUS 10/15/20, VAT 25, PIT 20"]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.deadlines.auto_extension_application — Terminy
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.deadlines.auto_extension_application","_legal_basis":"Art. 47 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.), Art. 103 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.), Art. 44 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Kalendarz terminów: ZUS 10/15/20, VAT 25, PIT 20"]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.force_majeure.aggregate.impact_assessment — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.force_majeure.aggregate.impact_assessment","_legal_basis":"Art. 67a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.employment.kup_conditions — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.employment.kup_conditions","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.market_benchmark_test — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.market_benchmark_test","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.qualifications_check — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.qualifications_check","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.work_evidence_required — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.work_evidence_required","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.salary_above_market_red_flag — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.salary_above_market_red_flag","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.no_qualifications_red_flag — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.no_qualifications_red_flag","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.no_work_evidence_nkup — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.no_work_evidence_nkup","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.hyper.edelivery.family.spouse.contract_type.employment — Małżonek
else :=   {"matched":true,"rule_id":"jdg.hyper.edelivery.family.spouse.contract_type.employment","_legal_basis":"Art. 22 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.), KP","_warnings":["Umowa o pracę z małżonkiem → pełny ZUS, PIT-4R"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
