# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.edelivery (Doc 44: P1870-P1877)
# Generated from Plan OPA specifications: 2026-07-14
# Rules: 8
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.edelivery
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.edelivery.no_match","package":"jdg.edelivery","priority":99999}

# jdg.edelivery.fiction_detection — Fikcja doręczenia e-Doręczeń po 14 dniach
decide :=   {"matched":true,"rule_id":"jdg.edelivery.fiction_detection","package":"jdg.edelivery","priority":1870,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Fikcja doręczenia e-Doręczeń po 14 dniach","_legal_basis":"Ustawa o doręczeniach elektronicznych","_warnings":["PISMO UZNANE ZA DORĘCZONE PRZEZ FIKCJĘ! Sprawdź natychmiast e-US!"]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# jdg.edelivery.platform_monitoring — P1871: Monitorowanie konta e-US (bez epuap)
else :=   {"matched":true,"rule_id":"jdg.edelivery.platform_monitoring","package":"jdg.edelivery","priority":1871,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Monitorowanie konta e-US","_legal_basis":"Art. 144b Ordynacji podatkowej","_warnings":["Nowe pisma na e-US — sprawdź skrzynkę"]} {
    object.get(input.document, "edelivery_notification", false) == true
    object.get(input.document, "epuap_profile_active", true) == true
}

# jdg.edelivery.epuap_profile — P1872: Profil zaufany ePUAP (bez kwalifikowanego podpisu)
else :=   {"matched":true,"rule_id":"jdg.edelivery.epuap_profile","package":"jdg.edelivery","priority":1872,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"Profil zaufany ePUAP — obowiązek dla JDG do komunikacji z US, ZUS, CEIDG","_legal_basis":"Art. 20a Ordynacji podatkowej","_warnings":["Brak profilu zaufanego ePUAP — załóż dla komunikacji z organami"]} {
    object.get(input.document, "edelivery_notification", false) == true
    object.get(input.document, "epuap_profile_active", false) == false
}

# jdg.edelivery.qualified_signature — P1873: Kwalifikowany podpis (gdy epuap istnieje)
else :=   {"matched":true,"rule_id":"jdg.edelivery.qualified_signature","package":"jdg.edelivery","priority":1873,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kiedy wymagany kwalifikowany podpis — pisma procesowe, pełnomocnictwa, odwołania","_legal_basis":"Art. 126 § 5 Ordynacji podatkowej","_warnings":["Odwołania i pełnomocnictwa wymagają kwalifikowanego podpisu elektronicznego"]} {
    object.get(input.document, "edelivery_notification", false) == true
    object.get(input.document, "epuap_profile_active", false) == true
    object.get(input.document, "qualified_signature_held", false) == false
}

# jdg.edelivery.document_retention — P1874: Przechowywanie dokumentów elektronicznych — 5 lat
else :=   {"matched":true,"rule_id":"jdg.edelivery.document_retention","package":"jdg.edelivery","priority":1874,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Retencja dokumentów elektronicznych — integralność, autentyczność, czytelność","_legal_basis":"Art. 86 OP, eIDAS","_warnings":["Dokumenty elektroniczne przechowuj min. 5 lat — zapewnij integralność i czytelność"]} {
    object.get(input.document, "edelivery_notification", false) == true
    object.get(input.document, "document_retention_checked", false) == false
}

# jdg.edelivery.evidence_value — P1875: Moc dowodowa dokumentów elektronicznych
else :=   {"matched":true,"rule_id":"jdg.edelivery.evidence_value","package":"jdg.edelivery","priority":1875,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Moc dowodowa e-faktur, e-umów, e-dowodów zapłaty","_legal_basis":"Art. 180a-194 Ordynacji podatkowej","_warnings":["E-dokumenty mają moc dowodową jeśli spełniają wymogi autentyczności"]} {
    object.get(input.document, "edelivery_notification", false) == true
    object.get(input.document, "evidence_value_checked", false) == false
}

# jdg.edelivery.cross_border_e_comm — P1876: Komunikacja z zagranicznymi organami — DAC, CRS
else :=   {"matched":true,"rule_id":"jdg.edelivery.cross_border_e_comm","package":"jdg.edelivery","priority":1876,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Komunikacja z zagranicznymi organami — DAC, CRS, spontaniczna","_legal_basis":"Dyrektywy DAC, CRS","_warnings":["Wymiana informacji podatkowych z zagranicą — DAC na żądanie, CRS automatyczna"]} {
    object.get(input.document, "edelivery_notification", false) == true
    object.get(input.document, "cross_border_e_comm", false) == true
}

# jdg.edelivery.archive_retention — P1877: Retencja korespondencji (bez komunikacji transgranicznej)
else :=   {"matched":true,"rule_id":"jdg.edelivery.archive_retention","package":"jdg.edelivery","priority":1877,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Retencja korespondencji z US — 5 lat od zakończenia postępowania","_legal_basis":"Art. 86 Ordynacji podatkowej","_warnings":["Korespondencję z US przechowuj 5 lat od zakończenia postępowania"]} {
    object.get(input.document, "edelivery_notification", false) == true
    object.get(input.document, "retention_policy_active", false) == false
}
