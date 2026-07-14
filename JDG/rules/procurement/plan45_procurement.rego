# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.procurement hyper (Doc 45: R1270-R1299)
# Atom rules: zam. publiczne — certificates, exclusions, bids, EU funds, foreign
# Rules: 30 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.procurement.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.procurement.hyper.no_match","package":"jdg.procurement.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.procurement.hyper.tax_clearance_conditions","package":"jdg.procurement.hyper","priority":1270,"_routing":"","_routing_reason":"Zaświadczenie — warunki","_legal_basis":"Art. 306e OP","_warnings":["Zaświadczenie o niezaleganiu — wymagane dla zam. publicznych"]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.tax_clearance_procedure","package":"jdg.procurement.hyper","priority":1271,"_routing":"","_routing_reason":"Procedura uzyskania","_legal_basis":"Art. 306e OP","_warnings":["Wniosek przez e-US"]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.tax_clearance_deadline_7_3","package":"jdg.procurement.hyper","priority":1272,"_routing":"","_routing_reason":"Terminy: 7/3 dni","_legal_basis":"Art. 306n OP","_warnings":["7 dni standard / 3 dni tryb pilny (+ opłata)"]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.tax_clearance_validity","package":"jdg.procurement.hyper","priority":1273,"_routing":"","_routing_reason":"Ważność 3 miesiące","_legal_basis":"Art. 306e OP","_warnings":["Zaświadczenie ważne 3 miesiące od wydania"]} {
    object.get(input.document, "clearance_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.tax_clearance_download","package":"jdg.procurement.hyper","priority":1274,"_routing":"","_routing_reason":"Pobranie z e-US","_legal_basis":"OP","_warnings":["Zaświadczenie dostępne do pobrania z e-US"]} {
    object.get(input.document, "clearance_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.zus_clearance_conditions","package":"jdg.procurement.hyper","priority":1275,"_routing":"","_routing_reason":"Zaświadczenie ZUS — warunki","_legal_basis":"PZP","_warnings":["Zaświadczenie ZUS wymagane obok podatkowego"]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.zus_clearance_procedure","package":"jdg.procurement.hyper","priority":1276,"_routing":"","_routing_reason":"Procedura ZUS","_legal_basis":"PZP","_warnings":["Wniosek o zaświadczenie ZUS przez PUE ZUS"]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.zus_clearance_deadline","package":"jdg.procurement.hyper","priority":1277,"_routing":"","_routing_reason":"Termin ZUS — 7 dni","_legal_basis":"SUS","_warnings":["Zaświadczenie ZUS — 7 dni roboczych"]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.zus_clearance_validity","package":"jdg.procurement.hyper","priority":1278,"_routing":"","_routing_reason":"Ważność 3 miesiące","_legal_basis":"PZP","_warnings":["Zaświadczenie ZUS ważne 3 miesiące"]} {
    object.get(input.document, "zus_clearance_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.zus_clearance_download","package":"jdg.procurement.hyper","priority":1279,"_routing":"","_routing_reason":"Pobranie z PUE ZUS","_legal_basis":"SUS","_warnings":["Zaświadczenie ZUS dostępne w PUE ZUS"]} {
    object.get(input.document, "zus_clearance_obtained", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.exclusion_tax_arrears","package":"jdg.procurement.hyper","priority":1280,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Wykluczenie — zaległości","_legal_basis":"Art. 108 PZP","_warnings":["Zaległości podatkowe = wykluczenie obligatoryjne!"]} {
    object.get(input.jdg_entrepreneur, "has_tax_arrears", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.exclusion_kks","package":"jdg.procurement.hyper","priority":1281,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Wykluczenie — KKS","_legal_basis":"Art. 108 PZP","_warnings":["Skazanie KKS → wykluczenie z zam. publicznych"]} {
    object.get(input.jdg_entrepreneur, "kks_convicted", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.exclusion_penalties","package":"jdg.procurement.hyper","priority":1282,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Wykluczenie — kary","_legal_basis":"PZP","_warnings":["Kary → wykluczenie z zam. publicznych"]} {
    object.get(input.jdg_entrepreneur, "has_penalties", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.exclusion_mandatory","package":"jdg.procurement.hyper","priority":1283,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Wykluczenie obligatoryjne","_legal_basis":"Art. 108 PZP","_warnings":["Przesłanki obligatoryjne wykluczenia"]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.exclusion_optional","package":"jdg.procurement.hyper","priority":1284,"_routing":"","_routing_reason":"Wykluczenie fakultatywne","_legal_basis":"Art. 109 PZP","_warnings":["Przesłanki fakultatywne wykluczenia"]} {
    object.get(input.document, "public_procurement_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.bid_wadium_kup","package":"jdg.procurement.hyper","priority":1285,"_routing":"","_routing_reason":"Wadium — KUP","_legal_basis":"Art. 22 PIT","_warnings":["Wadium — KUP w dacie wpłaty"]} {
    object.get(input.document, "bid_bond_paid", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.bid_wadium_vat","package":"jdg.procurement.hyper","priority":1286,"_routing":"","_routing_reason":"Wadium — VAT","_legal_basis":"Art. 19a VAT","_warnings":["Wadium — poza VAT, chyba że przepadek = dostawa"]} {
    object.get(input.document, "bid_bond_paid", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.bid_security","package":"jdg.procurement.hyper","priority":1287,"_routing":"","_routing_reason":"Zabezpieczenie należytego wykonania","_legal_basis":"PZP","_warnings":["Zabezpieczenie 5-10% wartości umowy"]} {
    object.get(input.document, "bid_bond_paid", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.bid_return","package":"jdg.procurement.hyper","priority":1288,"_routing":"","_routing_reason":"Zwrot wadium","_legal_basis":"PZP","_warnings":["Zwrot wadium nie jest przychodem podatkowym"]} {
    object.get(input.document, "bid_bond_returned", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.bid_forfeit","package":"jdg.procurement.hyper","priority":1289,"_routing":"","_routing_reason":"Przepadek wadium","_legal_basis":"PZP","_warnings":["Przepadek wadium — skutki podatkowe"]} {
    object.get(input.document, "bid_bond_forfeited", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.eu_funds_certificates","package":"jdg.procurement.hyper","priority":1290,"_routing":"","_routing_reason":"Fundusze UE — certyfikaty","_legal_basis":"Rozporządzenia UE","_warnings":["Dodatkowe certyfikaty dla środków UE"]} {
    object.get(input.document, "eu_funds_involved", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.eu_funds_extra_requirements","package":"jdg.procurement.hyper","priority":1291,"_routing":"","_routing_reason":"Fundusze UE — dodatkowe wymogi","_legal_basis":"Rozporządzenia UE","_warnings":["Dodatkowe wymogi dla beneficjentów UE"]} {
    object.get(input.document, "eu_funds_involved", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.eu_funds_audit","package":"jdg.procurement.hyper","priority":1292,"_routing":"WARNING","_routing_reason":"Fundusze UE — kontrola","_legal_basis":"Rozporządzenia UE","_warnings":["Kontrola projektu UE — przygotuj dokumentację"]} {
    object.get(input.document, "eu_funds_involved", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.eu_funds_sanctions","package":"jdg.procurement.hyper","priority":1293,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Fundusze UE — sankcje","_legal_basis":"Rozporządzenia UE","_warnings":["Sankcje za nieprawidłowości w środkach UE"]} {
    object.get(input.document, "eu_funds_irregularities", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.eu_funds_settlement","package":"jdg.procurement.hyper","priority":1294,"_routing":"","_routing_reason":"Fundusze UE — rozliczenie","_legal_basis":"Rozporządzenia UE","_warnings":["Rozliczenie końcowe projektu UE"]} {
    object.get(input.document, "eu_funds_involved", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.foreign_tax_representative","package":"jdg.procurement.hyper","priority":1295,"_routing":"","_routing_reason":"Przedstawiciel podatkowy","_legal_basis":"PZP","_warnings":["JDG zagraniczne → przedstawiciel podatkowy"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "PL") != "PL"
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.foreign_residency","package":"jdg.procurement.hyper","priority":1296,"_routing":"","_routing_reason":"Rezydencja zagranicznego oferenta","_legal_basis":"PZP","_warnings":["Sprawdź rezydencję podatkową zagranicznego oferenta"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "PL") != "PL"
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.foreign_documents","package":"jdg.procurement.hyper","priority":1297,"_routing":"","_routing_reason":"Dokumenty zagraniczne","_legal_basis":"PZP","_warnings":["Dokumenty zagraniczne → apostille/tłumaczenie"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "PL") != "PL"
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.foreign_translations","package":"jdg.procurement.hyper","priority":1298,"_routing":"","_routing_reason":"Tłumaczenia przysięgłe","_legal_basis":"PZP","_warnings":["Tłumaczenie przysięgłe dokumentów zagranicznych"]} {
    object.get(input.document, "foreign_language_documents", false) == true
}
else := {"matched":true,"rule_id":"jdg.procurement.hyper.foreign_vat","package":"jdg.procurement.hyper","priority":1299,"_routing":"","_routing_reason":"VAT od zam. zagranicznych","_legal_basis":"VAT","_warnings":["VAT od zamówień zagranicznych — reverse charge lub NP"]} {
    object.get(input.jdg_entrepreneur, "tax_residence", "PL") != "PL"
}
