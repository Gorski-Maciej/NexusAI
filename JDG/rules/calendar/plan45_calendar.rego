# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.calendar hyper-granularity (Doc 45: R1368-R1402)
# Atom rules: per-tax deadlines, alerts, shifts, annual forecast
# Rules: 35 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.calendar.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.calendar.hyper.no_match","package":"jdg.calendar.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.calendar.hyper.vat_monthly_25th","package":"jdg.calendar.hyper","priority":1368,"_routing":"WARNING","_routing_reason":"VAT: do 25. dnia miesiąca","_legal_basis":"Art. 103 VAT","_warnings":["VAT miesięczny — zapłać do 25. dnia miesiąca"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.pit_advance_20th","package":"jdg.calendar.hyper","priority":1373,"_routing":"WARNING","_routing_reason":"PIT: zaliczka do 20.","_legal_basis":"Art. 44 PIT","_warnings":["Zaliczka PIT — zapłać do 20. dnia miesiąca"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.zus_jdg_10th","package":"jdg.calendar.hyper","priority":1378,"_routing":"WARNING","_routing_reason":"ZUS: JDG bez prac. do 10.","_legal_basis":"Art. 47 SUS","_warnings":["ZUS — JDG bez pracowników: do 10. dnia miesiąca"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.zus_employees_15th","package":"jdg.calendar.hyper","priority":1379,"_routing":"WARNING","_routing_reason":"ZUS: z pracownikami do 15.","_legal_basis":"Art. 47 SUS","_warnings":["ZUS — JDG z pracownikami: do 15. dnia miesiąca"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.alert_7_days","package":"jdg.calendar.hyper","priority":1388,"_routing":"WARNING","_routing_reason":"Alert: 7 dni przed terminem","_legal_basis":"Art. 12 OP","_warnings":["Termin płatności za 7 dni — przygotuj środki"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}
else := {"matched":true,"rule_id":"jdg.calendar.hyper.weekend_shift_saturday","package":"jdg.calendar.hyper","priority":1398,"_routing":"","_routing_reason":"Przesunięcie: sobota → poniedziałek","_legal_basis":"Art. 12 § 5 OP","_warnings":["Termin w sobotę — przesunięty na poniedziałek"]} {
    object.get(input.jdg_entrepreneur, "has_payment_obligations", false) == true
}
