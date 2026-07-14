# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.taxfree hyper-granularity (Doc 45: R1403-R1430)
# Atom rules: scale 30k, linear exclusion, multi-source, optimization
# Rules: 28 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.taxfree.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.taxfree.hyper.no_match","package":"jdg.taxfree.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.taxfree.hyper.scale_30k_amount","package":"jdg.taxfree.hyper","priority":1403,"_routing":"","_routing_reason":"Skala: 30k kwota wolna","_legal_basis":"Art. 27 ust. 1 PIT","_warnings":["Skala PIT — kwota wolna 30 000 PLN (redukcja podatku 3 600 PLN)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.scale_250_monthly","package":"jdg.taxfree.hyper","priority":1404,"_routing":"","_routing_reason":"Skala: 1/12 miesięcznie = 250 PLN","_legal_basis":"Art. 32 ust. 3 PIT","_warnings":["Pracodawca stosuje 250 PLN/mies. kwoty wolnej (1/12)"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.linear_no_free_amount","package":"jdg.taxfree.hyper","priority":1408,"_routing":"","_routing_reason":"Liniowy: brak kwoty wolnej","_legal_basis":"Art. 30c PIT","_warnings":["Podatek liniowy 19% — NIE korzysta z kwoty wolnej 30k!"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "LINEAR"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.multi_source_combined_limit","package":"jdg.taxfree.hyper","priority":1413,"_routing":"WARNING","_routing_reason":"Wieloźródłowość: limit łączny","_legal_basis":"Art. 27 PIT","_warnings":["JDG + etat + najem — kwota wolna stosowana łącznie, nie dubluj!"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
else := {"matched":true,"rule_id":"jdg.taxfree.hyper.joint_filing_60k","package":"jdg.taxfree.hyper","priority":1423,"_routing":"","_routing_reason":"Wspólne: 60k kwoty wolnej","_legal_basis":"Art. 6 ust. 2 PIT","_warnings":["Wspólne rozliczenie — 60 000 PLN kwoty wolnej + podwójny próg 240k"]} {
    object.get(input.jdg_entrepreneur, "tax_form", "") == "PIT_SCALE"
}
