# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.family

default decide := {"matched":false,"rule_id":"jdg.hyper.family.no_match","package":"jdg.hyper.family","priority":99999}

# jdg.hyper.family.audit.representation.access_to_files — Pełnomocnik
decide :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.representation.access_to_files","package":"jdg.hyper.family","priority":1150,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Prawo wglądu w akta sprawy (Art. 178 OP)","_legal_basis":"R1151","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.representation.participation_rights — Pełnomocnik
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.representation.participation_rights","package":"jdg.hyper.family","priority":1151,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Udział we wszystkich czynnościach kontrolnych (Art. 138e OP)","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.cross_border.mutual_assistance — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.cross_border.mutual_assistance","package":"jdg.hyper.family","priority":1152,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Współpraca z organami innych krajów UE","_legal_basis":"R1153","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.cross_border.simultaneous_audit — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.cross_border.simultaneous_audit","package":"jdg.hyper.family","priority":1153,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kontrola jednoczesna w kilku krajach UE","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.cross_border.presence_foreign_officials — Transgraniczne
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.cross_border.presence_foreign_officials","package":"jdg.hyper.family","priority":1154,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Udział zagranicznych kontrolerów w kontroli w PL","_legal_basis":"R1155","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.closure.decision_issuance — Zamknięcie
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.closure.decision_issuance","package":"jdg.hyper.family","priority":1155,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Decyzja wymiarowa po zakończeniu kontroli","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.closure.decision_deadline — Zamknięcie
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.closure.decision_deadline","package":"jdg.hyper.family","priority":1156,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Decyzja wydawana bez zbędnej zwłoki","_legal_basis":"R1157","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.closure.correction_window — Zamknięcie
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.closure.correction_window","package":"jdg.hyper.family","priority":1157,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Możliwość korekty po zakończeniu kontroli","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.follow_up.recommendations — Post-kontrola
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.follow_up.recommendations","package":"jdg.hyper.family","priority":1158,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zalecenia pokontrolne do wdrożenia","_legal_basis":"R1159","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.follow_up.deadline_monitoring — Post-kontrola
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.follow_up.deadline_monitoring","package":"jdg.hyper.family","priority":1159,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Monitoring terminów wdrożenia zaleceń","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.audit.aggregate.risk_score_update — Agregacja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.audit.aggregate.risk_score_update","package":"jdg.hyper.family","priority":1160,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Aktualizacja profilu ryzyka po zakończeniu kontroli","_legal_basis":"R-ID","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.detection — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.detection","package":"jdg.hyper.family","priority":1161,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Identyfikacja zdarzenia siły wyższej: powódź, pożar, pandemia, wojna","_legal_basis":"R1162","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.flood — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.flood","package":"jdg.hyper.family","priority":1162,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Powódź → katalog ulg podatkowych i ZUS","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.fire — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.fire","package":"jdg.hyper.family","priority":1163,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pożar → katalog ulg","_legal_basis":"R1164","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.pandemic — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.pandemic","package":"jdg.hyper.family","priority":1164,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Pandemia/epidemia → katalog ulg","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.war_effects — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.war_effects","package":"jdg.hyper.family","priority":1165,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skutki działań wojennych → katalog ulg","_legal_basis":"R1166","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.event.natural_disaster_other — Detekcja
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.event.natural_disaster_other","package":"jdg.hyper.family","priority":1166,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Inna klęska żywiołowa → katalog ulg","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.relief.tax_deferral — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.relief.tax_deferral","package":"jdg.hyper.family","priority":1167,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Odroczenie terminu płatności podatku (Art. 67a § 1 pkt 1 OP)","_legal_basis":"R1168","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.relief.tax_installments — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.relief.tax_installments","package":"jdg.hyper.family","priority":1168,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Rozłożenie na raty (Art. 67a § 1 pkt 2 OP)","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.relief.tax_remission — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.relief.tax_remission","package":"jdg.hyper.family","priority":1169,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umorzenie zaległości w całości lub części (Art. 67a § 1 pkt 3 OP)","_legal_basis":"R1170","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}

# jdg.hyper.family.force_majeure.relief.tax_suspension — Ulga podatkowa
else :=   {"matched":true,"rule_id":"jdg.hyper.family.force_majeure.relief.tax_suspension","package":"jdg.hyper.family","priority":1170,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zaniechanie poboru podatku na podstawie rozporządzenia MF","_legal_basis":"","_warnings":[]} {
    object.get(input.vendor, "relation_to_entrepreneur", "") != ""
}
