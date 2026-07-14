# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.esig hyper-granularity (Doc 45: R1340-R1367)
# Atom rules: qualified signature, profile zaufany, KSeF, documents,
#   cross-border eIDAS, contracts
# Rules: 28 atom — each with differentiated trigger conditions
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.esig.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.esig.hyper.no_match","package":"jdg.esig.hyper","priority":99999}

# ══ R1340-R1344: Qualified Electronic Signature ══
decide := {"matched":true,"rule_id":"jdg.esig.hyper.qualified_required_appeal","package":"jdg.esig.hyper","priority":1340,"_routing":"WARNING","_routing_reason":"Kwalifikowany: odwołania i pełnomocnictwa","_legal_basis":"Art. 126 § 5 OP","_warnings":["Odwołania od decyzji i pełnomocnictwa procesowe — wymagany kwalifikowany podpis elektroniczny"]} {
    object.get(input.document, "document_type", "") == "APPEAL"
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.qualified_exceptions","package":"jdg.esig.hyper","priority":1341,"_routing":"","_routing_reason":"Wyjątki od kwalifikowanego","_legal_basis":"Art. 126 § 5 OP","_warnings":["Profil zaufany wystarczy dla: deklaracji podatkowych, zgłoszeń CEIDG, wniosków ZUS"]} {
    object.get(input.document, "document_type", "") == "TAX_DECLARATION"
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.qualified_certificate_validity","package":"jdg.esig.hyper","priority":1342,"_routing":"WARNING","_routing_reason":"Certyfikat: ważność 2 lata","_legal_basis":"eIDAS","_warnings":["Certyfikat kwalifikowanego podpisu — ważny 2 lata od wydania"]} {
    object.get(input.jdg_entrepreneur, "qualified_cert_expiring_soon", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.qualified_expiry_alert","package":"jdg.esig.hyper","priority":1343,"_routing":"WARNING","_routing_reason":"Certyfikat wygasa — alert","_legal_basis":"eIDAS","_warnings":["Certyfikat kwalifikowanego podpisu wygasa za <30 dni — odnów!"]} {
    object.get(input.jdg_entrepreneur, "qualified_cert_days_remaining", 999) <= 30
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.qualified_renewal_procedure","package":"jdg.esig.hyper","priority":1344,"_routing":"","_routing_reason":"Odnowienie certyfikatu","_legal_basis":"eIDAS","_warnings":["Odnowienie — wniosek u dostawcy usług zaufania (CenCert, EuroCert, KIR)"]} {
    object.get(input.jdg_entrepreneur, "qualified_cert_expired", false) == true
}

# ══ R1345-R1349: Profile Zaufany ══
else := {"matched":true,"rule_id":"jdg.esig.hyper.profile_zaufany_sufficient","package":"jdg.esig.hyper","priority":1345,"_routing":"","_routing_reason":"Profil zaufany — wystarczający dla deklaracji","_legal_basis":"Art. 20a OP","_warnings":["Profil zaufany ePUAP wystarcza dla: PIT, VAT, CEIDG, ZUS — nie potrzebujesz podpisu kwalifikowanego"]} {
    object.get(input.document, "document_type", "") == "TAX_DECLARATION"
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.profile_zaufany_limitations","package":"jdg.esig.hyper","priority":1346,"_routing":"WARNING","_routing_reason":"Profil zaufany — ograniczenia","_legal_basis":"Art. 20a OP","_warnings":["Profil zaufany NIE wystarcza dla: odwołań od decyzji, pełnomocnictw procesowych, skarg do WSA"]} {
    object.get(input.document, "document_type", "") == "APPEAL"
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.profile_zaufany_validity","package":"jdg.esig.hyper","priority":1347,"_routing":"","_routing_reason":"Profil zaufany — ważność 3 lata","_legal_basis":"Art. 20a OP","_warnings":["Profil zaufany ważny 3 lata — przedłuż online przez bankowość elektroniczną lub wideorozmowę"]} {
    object.get(input.jdg_entrepreneur, "profile_zaufany_expiring_soon", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.profile_zaufany_extension","package":"jdg.esig.hyper","priority":1348,"_routing":"WARNING","_routing_reason":"Przedłużenie profilu zaufanego","_legal_basis":"Art. 20a OP","_warnings":["Przedłuż profil zaufany — przez internet (bank) lub osobiście (US, ZUS)"]} {
    object.get(input.jdg_entrepreneur, "profile_zaufany_days_remaining", 999) <= 30
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.profile_zaufany_renewed","package":"jdg.esig.hyper","priority":1349,"_routing":"","_routing_reason":"Profil zaufany odnowiony","_legal_basis":"Art. 20a OP","_warnings":["Profil zaufany został odnowiony"]} {
    object.get(input.jdg_entrepreneur, "profile_zaufany_renewed_today", false) == true
}

# ══ R1350-R1354: KSeF Signatures ══
else := {"matched":true,"rule_id":"jdg.esig.hyper.ksef_token_required","package":"jdg.esig.hyper","priority":1350,"_routing":"WARNING","_routing_reason":"KSeF: token wymagany","_legal_basis":"Ustawa o KSeF","_warnings":["KSeF — wymagany token KSeF, pieczęć elektroniczna lub kwalifikowany podpis"]} {
    object.get(input.document, "document_type", "") == "KSEF_INVOICE"
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.ksef_seal_vs_signature","package":"jdg.esig.hyper","priority":1351,"_routing":"","_routing_reason":"KSeF: pieczęć vs podpis","_legal_basis":"Ustawa o KSeF","_warnings":["Pieczęć elektroniczna (qualified e-seal) — dla JDG. Podpis kwalifikowany — dla osoby fizycznej"]} {
    object.get(input.document, "ksef_auth_method", "") == "SEAL"
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.ksef_authorization","package":"jdg.esig.hyper","priority":1352,"_routing":"","_routing_reason":"KSeF: autoryzacja","_legal_basis":"Ustawa o KSeF","_warnings":["Autoryzacja faktury w KSeF — token lub pieczęć elektroniczna"]} {
    object.get(input.document, "ksef_auth_completed", false) == false
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.ksef_token_expiry","package":"jdg.esig.hyper","priority":1353,"_routing":"WARNING","_routing_reason":"KSeF: ważność tokena","_legal_basis":"Ustawa o KSeF","_warnings":["Token KSeF — wygasa, wygeneruj nowy przed upływem ważności"]} {
    object.get(input.jdg_entrepreneur, "ksef_token_expiring_soon", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.ksef_token_generation","package":"jdg.esig.hyper","priority":1354,"_routing":"","_routing_reason":"KSeF: generowanie tokena","_legal_basis":"Ustawa o KSeF","_warnings":["Wygeneruj nowy token KSeF na portalu e-Urząd Skarbowy"]} {
    object.get(input.jdg_entrepreneur, "ksef_token_needed", false) == true
}

# ══ R1355-R1359: Document Authenticity ══
else := {"matched":true,"rule_id":"jdg.esig.hyper.document_authenticity_preserve","package":"jdg.esig.hyper","priority":1355,"_routing":"WARNING","_routing_reason":"Zachowaj autentyczność e-dokumentów","_legal_basis":"eIDAS, EN 16931","_warnings":["Nie konwertuj e-faktur na PDF/skan — utrata statusu faktury ustrukturyzowanej!"]} {
    object.get(input.document, "document_type", "") == "KSEF_INVOICE"
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.document_integrity_check","package":"jdg.esig.hyper","priority":1356,"_routing":"","_routing_reason":"Integralność dokumentu","_legal_basis":"eIDAS","_warnings":["Sprawdź integralność dokumentu — podpis elektroniczny musi być zweryfikowany"]} {
    object.get(input.document, "signature_verified", false) == false
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.document_format_requirements","package":"jdg.esig.hyper","priority":1357,"_routing":"","_routing_reason":"Format dokumentu","_legal_basis":"eIDAS","_warnings":["E-dokumenty: XML, PDF z podpisem PAdES, XAdES — zgodne z eIDAS"]} {
    object.get(input.document, "format_validated", false) == false
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.document_conversion_loss","package":"jdg.esig.hyper","priority":1358,"_routing":"WARNING","_routing_reason":"Konwersja e-faktury → utrata statusu","_legal_basis":"EN 16931","_warnings":["Konwersja XML → PDF → utrata statusu faktury ustrukturyzowanej i mocy dowodowej"]} {
    object.get(input.document, "conversion_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.document_retention_format","package":"jdg.esig.hyper","priority":1359,"_routing":"","_routing_reason":"Retencja w oryginalnym formacie","_legal_basis":"Art. 86 OP","_warnings":["Przechowuj e-dokumenty w oryginalnym formacie z podpisem — przez okres przedawnienia"]} {
    object.get(input.document, "retention_policy_applied", false) == false
}

# ══ R1360-R1364: Cross-Border eIDAS ══
else := {"matched":true,"rule_id":"jdg.esig.hyper.cross_border_eidas_recognition","package":"jdg.esig.hyper","priority":1360,"_routing":"","_routing_reason":"eIDAS: podpisy UE równoważne","_legal_basis":"Rozp. eIDAS 910/2014","_warnings":["Podpisy kwalifikowane z UE — automatycznie uznawane w Polsce (eIDAS)"]} {
    object.get(input.vendor, "country", "PL") != "PL"
    object.get(input.vendor, "eu_country", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.cross_border_tsl_check","package":"jdg.esig.hyper","priority":1361,"_routing":"","_routing_reason":"Lista TSL — weryfikacja","_legal_basis":"eIDAS","_warnings":["Sprawdź listę TSL (Trusted Service List) — czy dostawca podpisu jest zaufany"]} {
    object.get(input.vendor, "country", "PL") != "PL"
    object.get(input.vendor, "tsl_checked", false) == false
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.cross_border_verification","package":"jdg.esig.hyper","priority":1362,"_routing":"","_routing_reason":"Weryfikacja podpisu zagranicznego","_legal_basis":"eIDAS","_warnings":["Zweryfikuj poprawność zagranicznego podpisu kwalifikowanego"]} {
    object.get(input.vendor, "foreign_signature_verified", false) == false
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.cross_border_non_eu_signatures","package":"jdg.esig.hyper","priority":1363,"_routing":"WARNING","_routing_reason":"Podpisy spoza UE","_legal_basis":"eIDAS","_warnings":["Podpisy spoza UE — nie są automatycznie uznawane, wymagana dodatkowa weryfikacja"]} {
    object.get(input.vendor, "country", "PL") != "PL"
    object.get(input.vendor, "eu_country", false) == false
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.cross_border_advanced_signature","package":"jdg.esig.hyper","priority":1364,"_routing":"","_routing_reason":"Podpis zaawansowany — moc dowodowa","_legal_basis":"eIDAS","_warnings":["Podpis zaawansowany ma ograniczoną moc dowodową — preferowany kwalifikowany"]} {
    object.get(input.document, "signature_level", "") == "ADVANCED"
}

# ══ R1365-R1367: Electronic Contracts ══
else := {"matched":true,"rule_id":"jdg.esig.hyper.contracts_electronic_form","package":"jdg.esig.hyper","priority":1365,"_routing":"","_routing_reason":"E-umowy z podpisem kwalifikowanym","_legal_basis":"Art. 78¹ KC","_warnings":["E-umowy z kwalifikowanym podpisem = równoważne formie pisemnej (art. 78¹ KC)"]} {
    object.get(input.document, "contract_e_signed", false) == true
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.contracts_documentary_form","package":"jdg.esig.hyper","priority":1366,"_routing":"","_routing_reason":"Forma dokumentowa","_legal_basis":"Art. 77² KC","_warnings":["Forma dokumentowa (email, SMS) — wystarczająca dla umów niewymagających formy pisemnej"]} {
    object.get(input.document, "contract_form", "") == "DOCUMENTARY"
}
else := {"matched":true,"rule_id":"jdg.esig.hyper.contracts_equivalence_written","package":"jdg.esig.hyper","priority":1367,"_routing":"","_routing_reason":"Równoważność formy pisemnej","_legal_basis":"Art. 78¹ KC","_warnings":["E-umowa z kwalifikowanym podpisem = dokument prywatny z pełną mocą dowodową"]} {
    object.get(input.document, "contract_form_validated", false) == true
}
