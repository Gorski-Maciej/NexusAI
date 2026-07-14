# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.esig hyper-granularity (Doc 45: R1340-R1367)
# Atom rules: qualified signature, profile zaufany, KSeF, documents, cross-border
# Rules: 28 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.esig.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.esig.hyper.no_match","package":"jdg.esig.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.esig.hyper.qualified_required_appeal","package":"jdg.esig.hyper","priority":1340,"_routing":"WARNING","_routing_reason":"Podpis kwalifikowany: odwołania, pełnomocnictwa","_legal_basis":"Art. 126 § 5 OP","_warnings":["Odwołania i pełnomocnictwa wymagają kwalifikowanego podpisu"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.profile_zaufany_sufficient","package":"jdg.esig.hyper","priority":1345,"_routing":"","_routing_reason":"Profil zaufany: wystarczający dla deklaracji","_legal_basis":"Art. 20a OP","_warnings":["Profil zaufany wystarcza dla większości deklaracji podatkowych"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.ksef_token_required","package":"jdg.esig.hyper","priority":1350,"_routing":"WARNING","_routing_reason":"KSeF: token wymagany","_legal_basis":"Ustawa o KSeF","_warnings":["KSeF wymaga tokena, pieczęci elektronicznej lub kwalifikowanego podpisu"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.document_authenticity_preserve","package":"jdg.esig.hyper","priority":1355,"_routing":"WARNING","_routing_reason":"Dokumenty: zachowaj autentyczność","_legal_basis":"eIDAS, EN 16931","_warnings":["Nie konwertuj e-faktur — utrata statusu faktury ustrukturyzowanej"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.cross_border_eidas_recognition","package":"jdg.esig.hyper","priority":1360,"_routing":"","_routing_reason":"eIDAS: podpisy UE równoważne","_legal_basis":"Rozp. eIDAS 910/2014","_warnings":["Podpisy kwalifikowane z UE — automatycznie uznawane w PL"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.contracts_electronic_form","package":"jdg.esig.hyper","priority":1365,"_routing":"","_routing_reason":"Umowy: forma elektroniczna","_legal_basis":"Art. 78¹ KC","_warnings":["E-umowy z podpisem kwalifikowanym równoważne formie pisemnej"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}
