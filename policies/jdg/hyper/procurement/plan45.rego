# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.procurement

default decide := {"matched":false,"rule_id":"jdg.hyper.procurement.no_match","package":"jdg.hyper.procurement","priority":99999}

# jdg.hyper.procurement.family.cooperation.notification_to_zus_7days — ZUS
decide :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.cooperation.notification_to_zus_7days","_legal_basis":"Art. 36 ust. 14 ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)","_warnings":["Zgłoszenie osoby współpracującej w 7 dni"]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.cooperation.pit_treatment — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.cooperation.pit_treatment","_legal_basis":"Art. 23 ust. 1 pkt 10 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.car.usage.mixed_75pct_kup — Samochód
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.car.usage.mixed_75pct_kup","_legal_basis":"Art. 23 ust. 1 pkt 46 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Auto używane przez rodzinę → 75% KUP"]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.car.usage.mileage_log_family — Samochód
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.car.usage.mileage_log_family","_legal_basis":"Art. 23 ust. 1 pkt 46 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.car.usage.vat_deduction_50pct — Samochód
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.car.usage.vat_deduction_50pct","_legal_basis":"Art. 86a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["VAT od auta rodzinnego → 50%"]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.gift_to_spouse — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.gift_to_spouse","_legal_basis":"Art. 4a ustawy z dnia 28 lipca 1983 r. o podatku od spadków i darowizn","_warnings":["Darowizna dla dzieci → grupa 0, SD-Z2 w 6 mies."]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.gift_to_children — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.gift_to_children","_legal_basis":"Art. 4a ustawy z dnia 28 lipca 1983 r. o podatku od spadków i darowizn","_warnings":["Darowizna dla dzieci → grupa 0, SD-Z2 w 6 mies."]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.sale_arm_length — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.sale_arm_length","_legal_basis":"Art. 14 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.vat_opodatkowanie — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.vat_opodatkowanie","_legal_basis":"Art. 7 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Sprzedaż majątku firmowego rodzinie → VAT naliczony"]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.asset.transfer.pcc_exemption — Majątek
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.asset.transfer.pcc_exemption","_legal_basis":"Art. 4a ustawy z dnia 28 lipca 1983 r. o podatku od spadków i darowizn","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.joint_filing.conditions — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.joint_filing.conditions","_legal_basis":"Art. 6 ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.joint_filing.benefit_calculation — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.joint_filing.benefit_calculation","_legal_basis":"Art. 6 ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.joint_filing.deadline_april30 — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.joint_filing.deadline_april30","_legal_basis":"Art. 45 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.joint_filing.exclusions — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.joint_filing.exclusions","_legal_basis":"Art. 6 ust. 2 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.single_parent.preferential_calculation — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.single_parent.preferential_calculation","_legal_basis":"Art. 6 ust. 4 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.single_parent.child_custody_required — PIT
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.single_parent.child_custody_required","_legal_basis":"Art. 6 ust. 4 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.health_insurance.family_members — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.health_insurance.family_members","_legal_basis":"Art. 66 ustawy z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (Dz.U. 2025 poz. 890)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.health_insurance.kup_deduction — Ubezpieczenie
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.health_insurance.kup_deduction","_legal_basis":"Art. 23 ust. 1 pkt 58 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.pit4r.obligation — Płatnik
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.pit4r.obligation","_legal_basis":"Art. 38 ust. 1a ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.pit11.deadline_feb28 — Płatnik
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.pit11.deadline_feb28","_legal_basis":"Art. 39 ust. 1 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}

# jdg.hyper.procurement.family.succession.planning_inheritance — Sukcesja
else :=   {"matched":true,"rule_id":"jdg.hyper.procurement.family.succession.planning_inheritance","_legal_basis":"Art. 4a ustawy z dnia 28 lipca 1983 r. o podatku od spadków i darowizn","_warnings":[]} {
    object.get(input.document, "public_procurement_active", false) == true
}
