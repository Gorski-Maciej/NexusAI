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
