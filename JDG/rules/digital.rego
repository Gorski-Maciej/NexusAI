# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Kryptoaktywa, AI Act, MDR, API degradation (P630-P1895)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.digital
#
# METADATA
# title: JDG Package — digital (Gospodarka Cyfrowa: Kryptoaktywa, AI Act, MDR, API Fallback)
# description: |
#   v7.0 CLARIFICATION (P18 LUKA-D1): This package covers DIGITAL ECONOMY rules —
#   cryptocurrency (PIT-38, mining, MDR), AI Act compliance (risk classification,
#   deepfake disclosure), and API degradation/fallback. It does NOT handle e-Delivery
#   or ePUAP — those are in separate packages jdg.edelivery and jdg.epuap.
# architecture: Multi-Pass (ADR-001)
# package: jdg.digital
# scope: crypto_tax, ai_act, mdr_dac6, api_resilience
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.digital.no_match","package":"jdg.digital","priority":1905}

# ══ P630: crypto_taxable_event — PIT od kryptoaktywów — zdarzenie podatkowe ══
decide := {
    "matched":true,"rule_id":"jdg.digital.crypto_taxable_event",
    "package":"jdg.digital","priority":630,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"0.19","pit_bracket":"","pit_annual_return_type":"PIT-38",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","digital_tax_event":"CRYPTO_DISPOSAL","pit_38_due":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22d, 22e, 30b PIT",
    "_warnings":["Kryptoaktywa — zdarzenie podatkowe (PIT-38). Zbycie (wymiana/sprzedaż) generuje przychód. 19% od dochodu. Straty można odliczyć od zysków z krypto w tym samym roku. PIT-38 do 30 kwietnia."]
} {
    input.digital.asset_type == "CRYPTO"
    input.digital.action in {"SELL","EXCHANGE","SPEND"}
}

# ══ P1890: crypto_mining_business — Kopanie krypto jako działalność JDG ══
else := {
    "matched":true,"rule_id":"jdg.digital.crypto_mining_business",
    "package":"jdg.digital","priority":1890,
    "vat_rate":"0.23","rounding_level":"position","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","pit_qualifies_as_business":true,
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"STANDARD","zus_health_rate":"",
    "business_status":"","digital_tax_event":"CRYPTO_MINING_BUSINESS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 22d PIT + interpretacje KIS (np. 0114-KDIP2-1.4010.312.2023)",
    "_warnings":["Kopanie krypto jako działalność gospodarcza. Przychód z wydobytego krypto = wartość rynkowa w dniu otrzymania. KUP = koszty sprzętu + prąd + amortyzacja + lokal. VAT od sprzedaży sprzętu — 23%."]
} {
    input.digital.asset_type == "CRYPTO"
    input.digital.mode == "MINING"
    input.digital.activity_classification == "BUSINESS"
}

# ══ P1892: crypto_mdr_reporting — MDR — transakcje krypto powyżej progów ══
else := {
    "matched":true,"rule_id":"jdg.digital.crypto_mdr_reporting",
    "package":"jdg.digital","priority":1892,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","digital_tax_event":"MDR_SCHEME_REPORTABLE","mdr_deadline_days":30,
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"MDR — schemat podatkowy do zgłoszenia w 30 dni od udostępnienia",
    "_legal_basis":"Art. 86a-86o Ordynacja podatkowa (MDR) + DAC6",
    "_warnings":["MDR — schemat podatkowy raportowany. Kryptoaktywa/transgraniczne — obowiązek szczególny. MDR-1 w 30 dni. Uzasadnienie biznesowe wymagane. Kara do 21 mln PLN za brak raportowania!"]
} {
    input.digital.mdr_flag == true
    input.digital.cross_border == true
}

# ══ P1893: ai_act_compliance_check — AI Act — klasyfikacja systemu AI ══
else := {
    "matched":true,"rule_id":"jdg.digital.ai_act_compliance_check",
    "package":"jdg.digital","priority":1893,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","digital_regulatory":"EU_AI_ACT_APPLICABLE","ai_risk_category":"",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"AI Act — system AI podlega klasyfikacji ryzyka. Kategoria HIGH wymaga zgodności.",
    "_legal_basis":"Rozporządzenie UE 2024/1689 (AI Act)",
    "_warnings":["EU AI Act — klasyfikacja systemu AI wg ryzyka. High-risk (Rozdział III): rejestracja w bazie UE, ocena zgodności, dokumentacja techniczna, nadzór człowieka. Sankcje do 35 mln EUR lub 7% przychodu."]
} {
    input.digital.ai_system_deployed == true
    input.digital.ai_compliance_verified == false
}

# ══ P1894: api_degradation_fallback — Degradacja API — przełącznik fallback ══
else := {
    "matched":true,"rule_id":"jdg.digital.api_degradation_fallback",
    "package":"jdg.digital","priority":1894,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","digital_ops":"API_DEGRADED","api_fallback_active":true,
    "_routing":"FALLBACK_ACTIVE","_routing_reason":"API niedostępna — tryb fallback. Reguły z jdg.fallback jako override.",
    "_legal_basis":"Konfiguracja operacyjna — Art. 3 pkt 7 RODO (integralność i dostępność)",
    "_warnings":["DEGRADACJA API — fallback aktywny. OPA używa jdg.fallback dla wszystkich decyzji podatkowych. Tryb kryzysowy — tylko reguły krytyczne (no VAT 0%, no exemptions without evidence)."]
} {
    input.digital.api_status == "DEGRADED"
}

# ══ P1895: deepfake_ai_disclosure — AI Act — obowiązek ujawnienia AI (deepfake) ══
else := {
    "matched":true,"rule_id":"jdg.digital.deepfake_ai_disclosure",
    "package":"jdg.digital","priority":1895,
    "vat_rate":"","rounding_level":"","gtu_code":"","vat_exemption":"","procedure":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"","digital_regulatory":"EU_AI_ACT_TRANSPARENCY",
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"AI Act Art. 50 — obowiązek oznaczenia wygenerowanych treści",
    "_legal_basis":"Art. 50 Rozporządzenia UE 2024/1689 (AI Act)",
    "_warnings":["AI Act Art. 50 — obowiązek ujawnienia, że treść została wygenerowana przez AI. Oznaczenie watermarkiem. Dotyczy deepfake, chatbotów, systemów generatywnych. Od 2 lutego 2025 do 2 sierpnia 2026 (wdrażanie etapami)."]
} {
    input.digital.ai_content_generated == true
    input.digital.ai_disclosure_provided == false
}
