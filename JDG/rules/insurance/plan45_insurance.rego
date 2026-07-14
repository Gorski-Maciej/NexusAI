# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.insurance hyper-granularity (Doc 45: R1608-R1635)
# Atom rules: detection per industry, KUP, claims, VAT, gaps
# Rules: 28 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.insurance.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.insurance.hyper.no_match","package":"jdg.insurance.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.insurance.hyper.detection_medical","package":"jdg.insurance.hyper","priority":1609,"_routing":"WARNING","_routing_reason":"OC: lekarz — obowiązkowe","_legal_basis":"Ustawa o zawodzie lekarza","_warnings":["Zawód medyczny — obowiązkowe OC zawodowe"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.detection_construction","package":"jdg.insurance.hyper","priority":1610,"_routing":"WARNING","_routing_reason":"OC: budowlanka — obowiązkowe","_legal_basis":"Art. 648 KC","_warnings":["Branża budowlana — obowiązkowe OC"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.premium_mandatory_100pct_kup","package":"jdg.insurance.hyper","priority":1613,"_routing":"","_routing_reason":"OC obowiązkowe: 100% KUP","_legal_basis":"Art. 22 ust. 1 PIT","_warnings":["Składka OC obowiązkowego — KUP w 100%"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.claim_payout_revenue","package":"jdg.insurance.hyper","priority":1618,"_routing":"","_routing_reason":"Odszkodowanie: przychód","_legal_basis":"Art. 14 ust. 1 PIT","_warnings":["Odszkodowanie z OC — przychód podatkowy"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.claim_personal_injury_exempt","package":"jdg.insurance.hyper","priority":1621,"_routing":"","_routing_reason":"Odszkodowanie osobowe: zwolnione","_legal_basis":"Art. 21 ust. 1 pkt 3c PIT","_warnings":["Odszkodowanie za uszczerbek na zdrowiu — zwolnione z PIT"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.vat_exemption_insurance","package":"jdg.insurance.hyper","priority":1623,"_routing":"","_routing_reason":"VAT: ubezpieczenia zwolnione","_legal_basis":"Art. 43 ust. 1 pkt 37 VAT","_warnings":["Usługi ubezpieczeniowe — zwolnione z VAT. Assistance może być 23%"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.gap_mandatory_missing","package":"jdg.insurance.hyper","priority":1633,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Luka: brak obowiązkowego OC","_legal_basis":"Ustawy branżowe","_warnings":["Brak obowiązkowego OC — kara + odpowiedzialność odszkodowawcza osobista!"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
else := {"matched":true,"rule_id":"jdg.insurance.hyper.gap_policy_expiring_30days","package":"jdg.insurance.hyper","priority":1635,"_routing":"WARNING","_routing_reason":"Polisa wygasa za <30 dni","_legal_basis":"Ogólne","_warnings":["Polisa OC wygasa — odnów przed terminem!"]} {
    object.get(input.jdg_entrepreneur, "requires_mandatory_insurance", false) == true
}
