# NexusAI JDG — Digital economy policies: crypto, AI Act, MDR and API fallback.

package jdg.digital

import future.keywords.in

default decide := {
    "matched": false,
    "rule_id": "jdg.digital.no_match",
    "package": "jdg.digital",
    "priority": 1905
}

base_fields := {
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "vat_exemption": "",
    "procedure": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": ""
}

# P630: crypto taxable event.
decide := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.digital.crypto_taxable_event",
    "package": "jdg.digital",
    "priority": 630,
    "pit_rate": "0.19",
    "pit_annual_return_type": "PIT-38",
    "digital_tax_event": "CRYPTO_DISPOSAL",
    "pit_38_due": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22d, 22e, 30b PIT",
    "_warnings": ["Kryptoaktywa — zdarzenie podatkowe (PIT-38). Zbycie (wymiana/sprzedaż) generuje przychód. 19% od dochodu. PIT-38 do 30 kwietnia."]
}) if {
    input.digital.asset_type == "CRYPTO"
    input.digital.action in {"SELL", "EXCHANGE", "SPEND"}
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.digital.crypto_mining_business",
    "package": "jdg.digital",
    "priority": 1890,
    "vat_rate": "0.23",
    "procedure": "position",
    "pit_qualifies_as_business": true,
    "zus_social_base_type": "STANDARD",
    "digital_tax_event": "CRYPTO_MINING_BUSINESS",
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 22d PIT + interpretacje KIS",
    "_warnings": ["Kopanie krypto jako działalność gospodarcza. Przychód z wydobytego krypto = wartość rynkowa w dniu otrzymania. KUP = sprzęt + prąd + amortyzacja + lokal."]
}) if {
    input.digital.asset_type == "CRYPTO"
    input.digital.mode == "MINING"
    input.digital.activity_classification == "BUSINESS"
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.digital.crypto_mdr_reporting",
    "package": "jdg.digital",
    "priority": 1892,
    "digital_tax_event": "MDR_SCHEME_REPORTABLE",
    "mdr_deadline_days": 30,
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "MDR — schemat podatkowy do zgłoszenia w 30 dni od udostępnienia",
    "_legal_basis": "Art. 86a-86o Ordynacja podatkowa (MDR) + DAC6",
    "_warnings": ["MDR — schemat podatkowy raportowany. Kryptoaktywa/transgraniczne — MDR-1 w 30 dni. Uzasadnienie biznesowe wymagane."]
}) if {
    input.digital.mdr_flag == true
    input.digital.cross_border == true
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.digital.ai_act_compliance_check",
    "package": "jdg.digital",
    "priority": 1893,
    "digital_regulatory": "EU_AI_ACT_APPLICABLE",
    "ai_risk_category": "",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AI Act — system AI podlega klasyfikacji ryzyka. Kategoria HIGH wymaga zgodności.",
    "_legal_basis": "Rozporządzenie UE 2024/1689 (AI Act)",
    "_warnings": ["EU AI Act — klasyfikacja systemu AI wg ryzyka. High-risk wymaga rejestracji, oceny zgodności, dokumentacji technicznej i nadzoru człowieka."]
}) if {
    input.digital.ai_system_deployed == true
    input.digital.ai_compliance_verified == false
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.digital.api_degradation_fallback",
    "package": "jdg.digital",
    "priority": 1894,
    "digital_ops": "API_DEGRADED",
    "api_fallback_active": true,
    "_routing": "FALLBACK_ACTIVE",
    "_routing_reason": "API niedostępna — tryb fallback. Reguły z jdg.fallback jako override.",
    "_legal_basis": "Konfiguracja operacyjna — integralność i dostępność",
    "_warnings": ["DEGRADACJA API — fallback aktywny. OPA używa jdg.fallback dla decyzji podatkowych."]
}) if {
    input.digital.api_status == "DEGRADED"
} else := object.union(base_fields, {
    "matched": true,
    "rule_id": "jdg.digital.deepfake_ai_disclosure",
    "package": "jdg.digital",
    "priority": 1895,
    "digital_regulatory": "EU_AI_ACT_TRANSPARENCY",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "AI Act Art. 50 — obowiązek oznaczenia wygenerowanych treści",
    "_legal_basis": "Art. 50 Rozporządzenia UE 2024/1689 (AI Act)",
    "_warnings": ["AI Act Art. 50 — obowiązek ujawnienia, że treść została wygenerowana przez AI. Dotyczy deepfake, chatbotów i systemów generatywnych."]
}) if {
    input.digital.ai_content_generated == true
    input.digital.ai_disclosure_provided == false
}
