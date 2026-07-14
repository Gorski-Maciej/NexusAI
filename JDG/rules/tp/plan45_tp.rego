# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.tp hyper-granularity (Doc 45: R1431-R1475)
# Atom rules: TP thresholds, files, benchmarking, safe harbor, sanctions
# Rules: 45 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.tp.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.tp.hyper.no_match","package":"jdg.tp.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.tp.hyper.threshold_2m_goods","package":"jdg.tp.hyper","priority":1436,"_routing":"WARNING","_routing_reason":"TP: próg 2M PLN — transakcje towarowe","_legal_basis":"Art. 23zf PIT","_warnings":["Transakcje towarowe >2M PLN z podmiotem powiązanym — obowiązek dokumentacji TP"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.threshold_1m_financial","package":"jdg.tp.hyper","priority":1437,"_routing":"WARNING","_routing_reason":"TP: próg 1M PLN — transakcje finansowe","_legal_basis":"Art. 23zf PIT","_warnings":["Transakcje finansowe >1M PLN z podmiotem powiązanym — dokumentacja TP"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.threshold_500k_services","package":"jdg.tp.hyper","priority":1438,"_routing":"WARNING","_routing_reason":"TP: próg 0.5M PLN — usługi/niematerialne","_legal_basis":"Art. 23zf PIT","_warnings":["Usługi/niematerialne >0.5M PLN z podmiotem powiązanym — dokumentacja TP"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.local_file_deadline_10months","package":"jdg.tp.hyper","priority":1441,"_routing":"WARNING","_routing_reason":"TP: Local File — termin 10 mies.","_legal_basis":"Art. 23zf PIT","_warnings":["Local File — termin: 10 miesięcy po zakończeniu roku podatkowego"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.tpr_deadline_nov30","package":"jdg.tp.hyper","priority":1451,"_routing":"WARNING","_routing_reason":"TP: TPR-C — termin 30 listopada","_legal_basis":"Art. 23zh PIT","_warnings":["TPR-C — złóż do 30 listopada za poprzedni rok"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.safe_harbor_5pct_margin","package":"jdg.tp.hyper","priority":1461,"_routing":"","_routing_reason":"TP: safe harbor — marża 5%","_legal_basis":"Art. 23zf PIT","_warnings":["Low value-adding services — safe harbor: marża 5%, pułap 30% kosztów"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.adjustment_10pct_penalty","package":"jdg.tp.hyper","priority":1466,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: doszacowanie — 10% dodatkowe","_legal_basis":"Art. 58 OP","_warnings":["Doszacowanie dochodu TP — 10% dodatkowego opodatkowania + odsetki"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
else := {"matched":true,"rule_id":"jdg.tp.hyper.sanction_no_docs_10pct","package":"jdg.tp.hyper","priority":1471,"_routing":"BLOCK_AND_ALERT","_routing_reason":"TP: brak dokumentacji — 10% sankcja","_legal_basis":"Art. 56 KKS","_warnings":["Brak dokumentacji TP — 10% dodatkowego zobowiązania!"]} {
    object.get(input.vendor, "is_related_party", false) == true
}
