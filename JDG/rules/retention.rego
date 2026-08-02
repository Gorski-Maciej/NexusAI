# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Przechowywanie dokumentów (P990-P992)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.retention
#
# METADATA
# title: JDG Package — retention
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.retention
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.retention.no_match","package":"jdg.retention","priority":1002}

# ══ P990: tax_documents_retention_5yr — 5-letni okres przechowywania (standard) ══
decide := {
    "matched":true,"rule_id":"jdg.retention.tax_documents_5yr",
    "package":"jdg.retention","priority":990,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":5,"retention_start":"end_of_tax_year",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 86 § 1 Ordynacja podatkowa",
    "_warnings":["Okres przechowywania dokumentów podatkowych: 5 lat od końca roku kalendarzowego, w którym upłynął termin płatności podatku. Standard dla wszystkich ksiąg i dokumentów."]
} {
    input.retention.document_category == "TAX"
    input.retention.statute_triggered == false
}

# ══ P991: vat_invoices_retention_extended — Faktury VAT — przedłużony okres przechowywania ══
else := {
    "matched":true,"rule_id":"jdg.retention.vat_invoices_extended",
    "package":"jdg.retention","priority":990,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":5,"retention_start":"end_of_tax_year","retention_extended":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 112 VAT",
    "_warnings":["Faktury VAT — przechowywanie do upływu przedawnienia zobowiązania. De facto 5 lat + okres do końca roku. Zalecane 6 lat (bufor roczny). Kopie faktur w formie elektronicznej muszą być czytelne i dostępne."]
} {
    input.retention.document_category == "VAT_INVOICE"
}

# ══ P991b: vat_invoices_retention_10yr — Faktury VAT z nieruchomościami — 10 lat przechowywania ══
else := {
    "matched":true,"rule_id":"jdg.retention.vat_invoices_real_estate_10yr",
    "package":"jdg.retention","priority":991,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":10,"retention_extended":true,"retention_reason":"REAL_ESTATE",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 43 ust. 1 pkt 10 VAT (nieruchomości — 10 lat korekty VAT)",
    "_warnings":["Faktury związane z nieruchomościami — 10 lat przechowywania! Okres korekty VAT od nieruchomości wynosi 10 lat. Faktury zakupu i sprzedaży muszą być dostępne przez cały okres korekty."]
} {
    input.retention.document_category == "VAT_INVOICE"
    input.retention.related_to_real_estate == true
}

# ══ P992: hr_documents_retention — Dokumenty pracownicze — przedłużony okres ══
else := {
    "matched":true,"rule_id":"jdg.retention.hr_documents_extended",
    "package":"jdg.retention","priority":992,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":50,"retention_extended":true,"retention_reason":"HR",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 51u Ustawy o systemie ubezpieczeń społecznych (od 1 stycznia 2019: 10 lat)",
    "_warnings":["Dokumenty pracownicze — 50 lat dla zatrudnionych przed 1999 lub 10 lat dla zatrudnionych po 1 stycznia 2019 (po zgłoszeniu do ZUS). Przechowywać akta osobowe, listy płac, karty wynagrodzeń."]
} {
    input.retention.document_category == "HR"
    input.retention.employee_started_before_2019 == true
}

# ══ P992b: hr_documents_10yr_post_2019 — Dokumenty pracownicze (po 2019) ══
else := {
    "matched":true,"rule_id":"jdg.retention.hr_documents_10yr_post_2019",
    "package":"jdg.retention","priority":993,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":10,"retention_extended":false,"retention_reason":"HR_POST_2019",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 51u Ustawy o systemie ubezpieczeń społecznych",
    "_warnings":["Dokumenty pracownicze — 10 lat dla zatrudnionych po 1 stycznia 2019. Krótszy okres po skróceniu przez ZUS. Należy zgłosić raporty do ZUS w formie elektronicznej (ZUS OSW)."]
} {
    input.retention.document_category == "HR"
    input.retention.employee_started_before_2019 == false
}

# ══ P992c: electronic_archive_requirements — Wymogi archiwum elektronicznego ══
else := {
    "matched":true,"rule_id":"jdg.retention.electronic_archive_requirements",
    "package":"jdg.retention","priority":994,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_medium":"ELECTRONIC","retention_compliant":true,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Archiwum elektroniczne — wymogi autentyczności, czytelności i integralności",
    "_legal_basis":"Art. 112a VAT + Art. 106m-106n VAT + eIDAS",
    "_warnings":["Archiwum elektroniczne musi zapewniać: autentyczność pochodzenia, integralność treści, czytelność przez cały okres przechowywania. e-Faktury w formacie KSeF. Podpis kwalifikowany lub profil zaufany dla integralności."]
} {
    input.retention.document_category == "TAX"
    input.retention.storage_medium == "ELECTRONIC"
    input.retention.authenticity_proven == false
}

# ══════ P993-P995: ROZSZERZENIE RETENCJI — ZUS 10 lat + UoR 5 lat (Raport P26 R7) ══════

# ══ P993b: zus_archival_50yr_pre1999 — Archiwum ZUS — 50 lat dla dokumentów sprzed 1999 (MUSI być przed P993!) ══
else := {
    "matched":true,"rule_id":"jdg.retention.zus_archival_50yr_pre1999",
    "package":"jdg.retention","priority":993,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":50,"retention_reason":"ZUS_ARCHIVAL_PRE1999",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 125a ust. 4 Ustawy SUS (zasób archiwalny ZUS)",
    "_warnings":["Archiwum ZUS sprzed 1999 — 50 lat! Dokumenty płacowe i ubezpieczeniowe sprzed 1 stycznia 1999 podlegają 50-letniemu okresowi archiwizacji jako zasób archiwalny ZUS. Dotyczy: list płac, kart wynagrodzeń, akt osobowych."]
} {
    input.retention.document_category == "ZUS"
    input.retention.pre_1999_records == true
}

# ══ P993: zus_documents_retention_10yr — Dokumenty ZUS — 10 lat przechowywania ══
else := {
    "matched":true,"rule_id":"jdg.retention.zus_documents_10yr",
    "package":"jdg.retention","priority":994,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":10,"retention_reason":"ZUS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 125a ust. 1 Ustawy o systemie ubezpieczeń społecznych",
    "_warnings":["Dokumenty ZUS — 10 lat przechowywania! Dotyczy: DRA, RCA, RSA, ZUS ZUA, ZUS ZWUA, oraz dokumentacji płacowej będącej podstawą wymiaru składek. Okres liczony od dnia przekazania dokumentów do ZUS."]
} {
    input.retention.document_category == "ZUS"
}

# ══ P995: uor_accounting_retention_5yr — Dokumenty księgowe UoR — 5 lat ══
else := {
    "matched":true,"rule_id":"jdg.retention.uor_accounting_5yr",
    "package":"jdg.retention","priority":995,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":5,"retention_reason":"UOR_ACCOUNTING",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 74 Ustawy o rachunkowości",
    "_warnings":["Dokumenty księgowe UoR — 5 lat od początku roku następującego po roku obrotowym, którego dotyczą. Dotyczy: ksiąg rachunkowych, dowodów księgowych, sprawozdań finansowych, dokumentacji inwentaryzacyjnej. W przypadku postępowań podatkowych — do upływu przedawnienia."]
} {
    input.retention.document_category == "UOR_ACCOUNTING"
}

# ══ P995b: uor_annual_reports_permanent — Roczne sprawozdania finansowe — trwałe przechowywanie ══
else := {
    "matched":true,"rule_id":"jdg.retention.uor_annual_reports_permanent",
    "package":"jdg.retention","priority":996,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":999,"retention_permanent":true,"retention_reason":"UOR_ANNUAL_REPORTS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 74 ust. 2 UoR",
    "_warnings":["ROCZNE SPRAWOZDANIA FINANSOWE — TRWAŁE PRZECHOWYWANIE! Zatwierdzone roczne sprawozdania finansowe podlegają trwałemu przechowywaniu. Nie mogą być zniszczone po 5 latach jak pozostałe dokumenty księgowe."]
} {
    input.retention.document_category == "UOR_ACCOUNTING"
    input.retention.is_annual_report == true
}

# ══════ P996-998: RETENCJA KONTRAKTOWA — Umowy i dokumentacja prawna ══════

# ══ P996: contract_retention_6yr — Umowy handlowe — 6 lat od wykonania ══
else := {
    "matched":true,"rule_id":"jdg.retention.contracts_6yr",
    "package":"jdg.retention","priority":997,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":6,"retention_reason":"CONTRACTS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 118 KC (przedawnienie roszczeń z działalności gospodarczej)",
    "_warnings":["Umowy — 6 lat od dnia wymagalności roszczenia (dla JDG). Przechowuj umowy do upływu okresu przedawnienia roszczeń + 1 rok buforu. Dotyczy: umowy z kontrahentami, umowy najmu, umowy o dzieło/zlecenie."]
} {
    input.retention.document_category == "CONTRACTS"
}

# ══ P997: insurance_docs_retention — Polisy ubezpieczeniowe — 3 lata od wygaśnięcia ══
else := {
    "matched":true,"rule_id":"jdg.retention.insurance_3yr",
    "package":"jdg.retention","priority":998,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":3,"retention_reason":"INSURANCE",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 819 KC (przedawnienie roszczeń z umowy ubezpieczenia)",
    "_warnings":["Polisy ubezpieczeniowe — 3 lata od dnia zdarzenia ubezpieczeniowego. Dotyczy: OC, majątkowe, komunikacyjne, zdrowotne. Po upływie 3 lat roszczenia z umowy ubezpieczenia przedawniają się."]
} {
    input.retention.document_category == "INSURANCE"
}

# ══ P998: gdpr_consent_retention — Zgody RODO — do wycofania + 5 lat ══
else := {
    "matched":true,"rule_id":"jdg.retention.gdpr_consents",
    "package":"jdg.retention","priority":999,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","retention_period_years":5,"retention_reason":"GDPR_CONSENT",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"RODO + Art. 74 UoR (dowód księgowy)",
    "_warnings":["Zgody RODO — przechowuj przez okres przetwarzania + 5 lat po wycofaniu zgody (dla celów dowodowych). Dokumentacja zgód i ich wycofania jest kluczowa w przypadku kontroli PUODO."]
} {
    input.retention.document_category == "GDPR_CONSENT"
}
