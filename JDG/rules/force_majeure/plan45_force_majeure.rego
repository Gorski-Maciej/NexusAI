# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.force_majeure hyper (Doc 45: R1161-R1192)
# Atom rules: siła wyższa — events, reliefs, insurance, suspension, loss
# Rules: 32 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.force_majeure.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.force_majeure.hyper.no_match","package":"jdg.force_majeure.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.force_majeure.hyper.event_detection","package":"jdg.force_majeure.hyper","priority":1161,"_routing":"TRIAGE_QUEUE","_routing_reason":"Siła wyższa: detekcja zdarzenia","_legal_basis":"Art. 67a OP","_warnings":["Zdarzenie siły wyższej — uruchom procedurę ulg"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.event_flood","package":"jdg.force_majeure.hyper","priority":1162,"_routing":"TRIAGE_QUEUE","_routing_reason":"Powódź → ulgi","_legal_basis":"Art. 67a OP","_warnings":["Powódź — sprawdź katalog ulg podatkowych i ZUS"]} {
    object.get(input.jdg_entrepreneur, "fm_event_type", "") == "FLOOD"
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.event_fire","package":"jdg.force_majeure.hyper","priority":1163,"_routing":"TRIAGE_QUEUE","_routing_reason":"Pożar → ulgi","_legal_basis":"Art. 67a OP","_warnings":["Pożar — sprawdź katalog ulg podatkowych i ZUS"]} {
    object.get(input.jdg_entrepreneur, "fm_event_type", "") == "FIRE"
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.event_pandemic","package":"jdg.force_majeure.hyper","priority":1164,"_routing":"TRIAGE_QUEUE","_routing_reason":"Pandemia → ulgi","_legal_basis":"Spec-regulacje MF","_warnings":["Pandemia/epidemia — sprawdź katalog ulg"]} {
    object.get(input.jdg_entrepreneur, "fm_event_type", "") == "PANDEMIC"
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.event_war","package":"jdg.force_majeure.hyper","priority":1165,"_routing":"TRIAGE_QUEUE","_routing_reason":"Wojna → ulgi","_legal_basis":"Spec-regulacje MF","_warnings":["Skutki działań wojennych — sprawdź katalog ulg"]} {
    object.get(input.jdg_entrepreneur, "fm_event_type", "") == "WAR"
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.event_natural_disaster_other","package":"jdg.force_majeure.hyper","priority":1166,"_routing":"TRIAGE_QUEUE","_routing_reason":"Inna klęska → ulgi","_legal_basis":"Art. 67a OP","_warnings":["Inna klęska żywiołowa — sprawdź katalog ulg"]} {
    object.get(input.jdg_entrepreneur, "fm_event_type", "") == "NATURAL_DISASTER_OTHER"
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_tax_deferral","package":"jdg.force_majeure.hyper","priority":1167,"_routing":"TRIAGE_QUEUE","_routing_reason":"Odroczenie terminu płatności","_legal_basis":"Art. 67a § 1 pkt 1 OP","_warnings":["Wniosek o odroczenie terminu płatności podatku"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_tax_installments","package":"jdg.force_majeure.hyper","priority":1168,"_routing":"TRIAGE_QUEUE","_routing_reason":"Rozłożenie na raty","_legal_basis":"Art. 67a § 1 pkt 2 OP","_warnings":["Wniosek o rozłożenie zaległości na raty"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_tax_remission","package":"jdg.force_majeure.hyper","priority":1169,"_routing":"TRIAGE_QUEUE","_routing_reason":"Umorzenie zaległości","_legal_basis":"Art. 67a § 1 pkt 3 OP","_warnings":["Wniosek o umorzenie zaległości podatkowych"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_tax_suspension","package":"jdg.force_majeure.hyper","priority":1170,"_routing":"TRIAGE_QUEUE","_routing_reason":"Zaniechanie poboru","_legal_basis":"Rozporządzenie MF","_warnings":["Zaniechanie poboru podatku na podstawie rozporządzenia MF"]} {
    object.get(input.jdg_entrepreneur, "tax_suspension_eligible", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_deadline_extension","package":"jdg.force_majeure.hyper","priority":1171,"_routing":"WARNING","_routing_reason":"Przedłużenie terminu deklaracji","_legal_basis":"Rozporządzenie MF","_warnings":["Przedłużenie terminu złożenia deklaracji z powodu siły wyższej"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_application_immediate","package":"jdg.force_majeure.hyper","priority":1172,"_routing":"WARNING","_routing_reason":"Wniosek niezwłocznie","_legal_basis":"Art. 67a OP","_warnings":["Wniosek o ulgę złóż niezwłocznie po zdarzeniu"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_interest_suspension","package":"jdg.force_majeure.hyper","priority":1173,"_routing":"","_routing_reason":"Zawieszenie odsetek","_legal_basis":"Art. 67a OP","_warnings":["Zawieszenie naliczania odsetek na czas rozpatrywania wniosku"]} {
    object.get(input.jdg_entrepreneur, "relief_applied", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_zus_deferral","package":"jdg.force_majeure.hyper","priority":1174,"_routing":"TRIAGE_QUEUE","_routing_reason":"Odroczenie składek ZUS","_legal_basis":"Art. 28 SUS","_warnings":["Wniosek o odroczenie składek ZUS"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_zus_installments","package":"jdg.force_majeure.hyper","priority":1175,"_routing":"TRIAGE_QUEUE","_routing_reason":"Układ ratalny ZUS","_legal_basis":"Art. 29 SUS","_warnings":["Wniosek o układ ratalny w ZUS"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_zus_remission","package":"jdg.force_majeure.hyper","priority":1176,"_routing":"TRIAGE_QUEUE","_routing_reason":"Umorzenie składek ZUS","_legal_basis":"Art. 29 SUS","_warnings":["Wniosek o umorzenie składek ZUS — szczególne przypadki"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.relief_zus_suspension","package":"jdg.force_majeure.hyper","priority":1177,"_routing":"","_routing_reason":"Zawieszenie obowiązku składek ZUS","_legal_basis":"Spec-regulacje","_warnings":["Zawieszenie obowiązku opłacania składek ZUS"]} {
    object.get(input.jdg_entrepreneur, "zus_suspended_by_law", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.docs_loss_reporting","package":"jdg.force_majeure.hyper","priority":1178,"_routing":"TRIAGE_QUEUE","_routing_reason":"Zgłoszenie utraty dokumentów — 7 dni","_legal_basis":"Art. 86 § 2 OP","_warnings":["UTrata dokumentów — zgłoś do US w 7 dni!"]} {
    object.get(input.jdg_entrepreneur, "documentation_lost", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.docs_reconstruction","package":"jdg.force_majeure.hyper","priority":1179,"_routing":"WARNING","_routing_reason":"Procedura odtworzenia","_legal_basis":"Art. 86 OP","_warnings":["Procedura odtworzenia zniszczonej dokumentacji"]} {
    object.get(input.jdg_entrepreneur, "documentation_lost", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.docs_backup_obligation","package":"jdg.force_majeure.hyper","priority":1180,"_routing":"","_routing_reason":"Obowiązek backupu cyfrowego","_legal_basis":"Art. 86 OP","_warnings":["Obowiązek posiadania backupu cyfrowego dokumentacji"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.docs_electronic_preservation","package":"jdg.force_majeure.hyper","priority":1181,"_routing":"","_routing_reason":"Kopie off-site / chmura","_legal_basis":"Art. 86 OP","_warnings":["Przechowuj kopie dokumentacji off-site / w chmurze"]} {
    object.get(input.jdg_entrepreneur, "documentation_preserved", false) == false
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.insurance_cover_check","package":"jdg.force_majeure.hyper","priority":1182,"_routing":"","_routing_reason":"Sprawdź zakres ubezpieczenia","_legal_basis":"Art. 22 PIT","_warnings":["Sprawdź zakres ubezpieczenia business interruption"]} {
    object.get(input.jdg_entrepreneur, "insurance_cover_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.insurance_claim_procedure","package":"jdg.force_majeure.hyper","priority":1183,"_routing":"WARNING","_routing_reason":"Procedura zgłoszenia szkody","_legal_basis":"Art. 22 PIT","_warnings":["Zgłoś szkodę do ubezpieczyciela — zachowaj terminy umowne"]} {
    object.get(input.jdg_entrepreneur, "insurance_cover_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.insurance_payout_tax","package":"jdg.force_majeure.hyper","priority":1184,"_routing":"","_routing_reason":"Odszkodowanie = przychód","_legal_basis":"Art. 14 PIT","_warnings":["Odszkodowanie z OC → przychód podatkowy"]} {
    object.get(input.jdg_entrepreneur, "insurance_payout_received", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.suspension_automatic","package":"jdg.force_majeure.hyper","priority":1185,"_routing":"TRIAGE_QUEUE","_routing_reason":"Auto-zawieszenie JDG","_legal_basis":"Art. 25 PP","_warnings":["Automatyczne zawieszenie JDG z powodu siły wyższej"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.suspension_zus_consequences","package":"jdg.force_majeure.hyper","priority":1186,"_routing":"","_routing_reason":"Skutki ZUS zawieszenia","_legal_basis":"Art. 36a SUS","_warnings":["Zawieszenie — brak składek społecznych, zdrowotna nadal"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.suspension_tax_consequences","package":"jdg.force_majeure.hyper","priority":1187,"_routing":"","_routing_reason":"Skutki podatkowe zawieszenia","_legal_basis":"Art. 44 PIT","_warnings":["Zawieszenie — deklaracje zerowe, zaliczki 0"]} {
    object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.loss_carry_back","package":"jdg.force_majeure.hyper","priority":1188,"_routing":"","_routing_reason":"Retrospektywne rozliczenie straty","_legal_basis":"Spec-regulacje MF","_warnings":["Możliwość retrospektywnego rozliczenia straty z siły wyższej"]} {
    object.get(input.jdg_entrepreneur, "tax_loss_carry_back_checked", false) == false
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.loss_enhanced_deduction","package":"jdg.force_majeure.hyper","priority":1189,"_routing":"","_routing_reason":"Zwiększony limit odliczenia straty","_legal_basis":"Spec-regulacje MF","_warnings":["Zwiększony limit odliczenia straty (np. 100% zamiast 50%)"]} {
    object.get(input.jdg_entrepreneur, "loss_deduction_enhanced", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.deadlines_mf_monitoring","package":"jdg.force_majeure.hyper","priority":1190,"_routing":"WARNING","_routing_reason":"Monitoruj komunikaty MF","_legal_basis":"Rozporządzenia MF","_warnings":["Monitoruj komunikaty MF o przedłużeniu terminów"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.deadlines_auto_extension","package":"jdg.force_majeure.hyper","priority":1191,"_routing":"","_routing_reason":"Automatyczne stosowanie przedłużonych terminów","_legal_basis":"Rozporządzenia MF","_warnings":["Automatycznie stosuj przedłużone terminy ogłaszane przez MF"]} {
    object.get(input.jdg_entrepreneur, "emergency_deadlines_checked", false) == false
}
else := {"matched":true,"rule_id":"jdg.force_majeure.hyper.impact_assessment","package":"jdg.force_majeure.hyper","priority":1192,"_routing":"TRIAGE_QUEUE","_routing_reason":"Ocena łącznego wpływu","_legal_basis":"Art. 67a OP","_warnings":["Ocena łącznego wpływu siły wyższej na finanse JDG"]} {
    object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true
}
