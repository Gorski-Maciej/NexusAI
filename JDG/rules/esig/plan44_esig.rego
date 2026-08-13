# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.esig (Doc 44: P1900-P1906)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 7
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.esig
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.esig.no_match","package":"jdg.esig","priority":99999}

# jdg.esig.qualified_signature_requirement — P1900: Kwalifikowany podpis — deklaracje, odwołania, pełnomocnictwa
decide :=   {"matched":true,"rule_id":"jdg.esig.qualified_signature_requirement","package":"jdg.esig","priority":1900,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Kwalifikowany podpis elektroniczny — wymagany dla odwołań, pełnomocnictw, deklaracji","_legal_basis":"Art. 126 § 5 OP, eIDAS","_warnings":["Odwołania i pełnomocnictwa wymagają kwalifikowanego podpisu elektronicznego"],"valid_from":"2016-07-01","valid_to":null,"decision_mode":"SUGGEST"} {
    object.get(input.document, "electronic_signature_required", false) == true
}

# jdg.esig.signature_validity_monitoring — P1901: Monitorowanie ważności certyfikatu — 2 lata
else :=   {"matched":true,"rule_id":"jdg.esig.signature_validity_monitoring","package":"jdg.esig","priority":1901,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Certyfikat kwalifikowanego podpisu — wygasa po 2 latach","_legal_basis":"eIDAS, Art. 126 OP","_warnings":["Certyfikat podpisu wygasa — przedłuż przed terminem!"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}

# jdg.esig.ksef_invoice_signature — P1902: Podpis dla KSeF — token, pieczęć, podpis kwalifikowany
else :=   {"matched":true,"rule_id":"jdg.esig.ksef_invoice_signature","package":"jdg.esig","priority":1902,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"KSeF — token KSeF, pieczęć elektroniczna, lub kwalifikowany podpis","_legal_basis":"Ustawa o KSeF","_warnings":["KSeF wymaga tokenu, pieczęci elektronicznej lub kwalifikowanego podpisu"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}

# jdg.esig.document_authenticity — P1903: Autentyczność dokumentów — zakaz konwersji degradujących
else :=   {"matched":true,"rule_id":"jdg.esig.document_authenticity","package":"jdg.esig","priority":1903,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Autentyczność e-dokumentów — nie konwertuj na formaty tracące integralność","_legal_basis":"eIDAS, EN 16931","_warnings":["Zeskanowana faktura z KSeF traci status faktury ustrukturyzowanej"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}

# jdg.esig.cross_border_eidas — P1904: Uznawanie zagranicznych podpisów (kwalifikowane UE równoważne)
else :=   {"matched":true,"rule_id":"jdg.esig.cross_border_eidas","package":"jdg.esig","priority":1904,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"eIDAS — zagraniczne podpisy kwalifikowane (UE) równoważne polskim","_legal_basis":"Rozporządzenie eIDAS (910/2014)","_warnings":["Podpisy kwalifikowane z UE są równoważne polskim — uznawane automatycznie"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}

# jdg.esig.electronic_contracts — P1905: Elektroniczne umowy — forma elektroniczna (78¹ KC) i dokumentowa
else :=   {"matched":true,"rule_id":"jdg.esig.electronic_contracts","package":"jdg.esig","priority":1905,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Umowy elektroniczne — forma elektroniczna (78¹ KC), dokumentowa (77²-77³ KC)","_legal_basis":"Art. 77²-78¹ KC","_warnings":["E-umowy — forma elektroniczna (podpis kwalifikowany) lub dokumentowa (email/sms)"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}

# jdg.esig.einvoice_storage_standards — P1906: Standardy przechowywania e-faktur — EN 16931
else :=   {"matched":true,"rule_id":"jdg.esig.einvoice_storage_standards","package":"jdg.esig","priority":1906,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przechowywanie e-faktur — autentyczność, integralność, czytelność (EN 16931)","_legal_basis":"Art. 112a VAT, EN 16931","_warnings":["E-faktury przechowuj zgodnie z EN 16931 — autentyczność pochodzenia, integralność treści, czytelność"]} {
    object.get(input.document, "electronic_signature_required", false) == true
}
