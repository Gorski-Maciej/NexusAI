# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.regulated hyper-granularity (Doc 45: R1576-R1607)
# Atom rules: VAT exemptions per profession, KUP, privilege, cross-border
# Rules: 32 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.regulated.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.regulated.hyper.no_match","package":"jdg.regulated.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.regulated.hyper.vat_exempt_doctor","package":"jdg.regulated.hyper","priority":1576,"_routing":"","_routing_reason":"Lekarz: zwolnienie VAT (terapia)","_legal_basis":"Art. 43 ust. 1 pkt 18-19 VAT","_warnings":["Lekarz — usługi terapeutyczne zwolnione z VAT"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.vat_no_exemption_lawyer","package":"jdg.regulated.hyper","priority":1577,"_routing":"","_routing_reason":"Adwokat/radca: brak zwolnienia VAT","_legal_basis":"Art. 41 VAT","_warnings":["Adwokat/radca prawny — usługi opodatkowane 23% VAT"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.kup_chamber_fees_full","package":"jdg.regulated.hyper","priority":1581,"_routing":"","_routing_reason":"Składki korporacyjne: KUP 100%","_legal_basis":"Art. 22 PIT","_warnings":["Składki korporacyjne (adwokacka, radcowska, lekarska) — KUP"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.zus_no_start_relief","package":"jdg.regulated.hyper","priority":1586,"_routing":"WARNING","_routing_reason":"ZUS: brak ulgi na start","_legal_basis":"Art. 18a SUS","_warnings":["Zawód regulowany — brak ulgi na start przy usługach dla byłego pracodawcy"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.privilege_attorney_client","package":"jdg.regulated.hyper","priority":1591,"_routing":"","_routing_reason":"Tajemnica adwokacka — wyłączenie z kontroli","_legal_basis":"Art. 180 § 3 OP","_warnings":["Dokumenty objęte tajemnicą adwokacką — wyłączone z kontroli US"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}
else := {"matched":true,"rule_id":"jdg.regulated.hyper.license_suspension_business_must_suspend","package":"jdg.regulated.hyper","priority":1599,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Zawieszenie licencji → zawieś JDG","_legal_basis":"Ustawy korporacyjne","_warnings":["Zawieszenie licencji zawodowej — obowiązek zawieszenia JDG!"]} {
    object.get(input.jdg_entrepreneur, "is_regulated_profession", false) == true
}
