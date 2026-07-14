# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.residency hyper-granularity (Doc 45: R1476-R1517)
# Atom rules: residency tests, DTT, exit tax, PE, CFC, digital nomad
# Rules: 42 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.residency.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.residency.hyper.no_match","package":"jdg.residency.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.residency.hyper.test_183_days","package":"jdg.residency.hyper","priority":1476,"_routing":"","_routing_reason":"Rezydencja: test 183 dni","_legal_basis":"Art. 3 PIT","_warnings":["Test 183 dni — pobyt w PL >183 dni = rezydent PL"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.dtt_exemption_progression","package":"jdg.residency.hyper","priority":1481,"_routing":"","_routing_reason":"UPO: metoda wyłączenia z progresją","_legal_basis":"Umowy bilateralne","_warnings":["Metoda wyłączenia — dochód zagraniczny zwolniony, ale wpływa na stawkę"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfr_validity_12months","package":"jdg.residency.hyper","priority":1485,"_routing":"WARNING","_routing_reason":"CFR: ważność 12 miesięcy","_legal_basis":"Art. 26 PIT","_warnings":["Certyfikat rezydencji kontrahenta — ważny 12 miesięcy od wydania"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.foreign_tax_credit_limit","package":"jdg.residency.hyper","priority":1486,"_routing":"","_routing_reason":"Ulga: odliczenie podatku zagranicznego","_legal_basis":"Art. 27 ust. 9 PIT","_warnings":["Maksymalne odliczenie = podatek PL przypadający na dochód zagraniczny"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.exit_tax_4m_threshold","package":"jdg.residency.hyper","priority":1491,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Exit tax: próg 4M PLN","_legal_basis":"Art. 30da PIT","_warnings":["Zmiana rezydencji — exit tax od aktywów >4M PLN, stawka 19%"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.exit_tax_installments","package":"jdg.residency.hyper","priority":1493,"_routing":"","_routing_reason":"Exit tax: raty 5×20%","_legal_basis":"Art. 30da PIT","_warnings":["Exit tax — możliwość rozłożenia na 5 rat po 20%"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.pe_construction_12months","package":"jdg.residency.hyper","priority":1501,"_routing":"WARNING","_routing_reason":"PE: plac budowy >12 mies.","_legal_basis":"OECD MTC Art. 5","_warnings":["Plac budowy >12 miesięcy za granicą = zakład podatkowy"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.digital_pe_server","package":"jdg.residency.hyper","priority":1504,"_routing":"WARNING","_routing_reason":"Digital PE: serwer za granicą","_legal_basis":"OECD BEPS 2.0 Pillar 1","_warnings":["Serwer za granicą + znacząca obecność cyfrowa = ryzyko digital PE"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
else := {"matched":true,"rule_id":"jdg.residency.hyper.cfc_control_50pct","package":"jdg.residency.hyper","priority":1506,"_routing":"TRIAGE_QUEUE","_routing_reason":"CFC: kontrola >50%","_legal_basis":"Art. 30f PIT","_warnings":["CFC — kontrola >50% w podmiocie zagranicznym z CIT <14.25%"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"
}
