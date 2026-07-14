# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.seasonal hyper-granularity (Doc 45: R1518-R1545)
# Atom rules: detection per industry, suspension, PIT/VAT/ZUS strategy
# Rules: 28 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.seasonal.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.seasonal.hyper.no_match","package":"jdg.seasonal.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.seasonal.hyper.detection_tourism","package":"jdg.seasonal.hyper","priority":1520,"_routing":"","_routing_reason":"Sezonowa: branża turystyczna","_legal_basis":"Art. 22 PP","_warnings":["Branża turystyczna — domniemanie sezonowości. Rozważ zawieszenie po sezonie"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.detection_construction_winter","package":"jdg.seasonal.hyper","priority":1522,"_routing":"","_routing_reason":"Sezonowa: budowlanka — przerwa zimowa","_legal_basis":"Art. 22 PP","_warnings":["Budowlanka — przerwa zimowa (XII-II). Rozważ zawieszenie"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.suspension_max_6_months","package":"jdg.seasonal.hyper","priority":1524,"_routing":"WARNING","_routing_reason":"Zawieszenie: max 6 mies.","_legal_basis":"Art. 22 PP","_warnings":["Zawieszenie sezonowe — max 6 miesięcy ciągłych"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.zus_suspension_no_social","package":"jdg.seasonal.hyper","priority":1528,"_routing":"","_routing_reason":"ZUS: zawieszenie → brak społecznych","_legal_basis":"Art. 36a SUS","_warnings":["Zawieszenie sezonowe — brak składek społecznych, zdrowotna nadal"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.pit_advances_simplified_recommendation","package":"jdg.seasonal.hyper","priority":1534,"_routing":"","_routing_reason":"PIT: zaliczki uproszczone zalecane","_legal_basis":"Art. 44 ust. 6b PIT","_warnings":["JDG sezonowa — zaliczki uproszczone: stała kwota miesięczna"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
else := {"matched":true,"rule_id":"jdg.seasonal.hyper.vat_zero_returns_suspension","package":"jdg.seasonal.hyper","priority":1538,"_routing":"","_routing_reason":"VAT: deklaracje zerowe w zawieszeniu","_legal_basis":"Art. 99 ust. 7a VAT","_warnings":["W zawieszeniu składaj deklaracje zerowe VAT"]} {
    object.get(input.jdg_entrepreneur, "is_seasonal_business", false) == true
}
