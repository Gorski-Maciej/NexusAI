# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Stawki VAT, zwolnienia, GTU, OSS
# ═══════════════════════════════════════════════════════════════════════════════
#
# Pakiet:       jdg.vat.substantive
# Priorytety:   P50-P65
# Opis:         Stawki VAT, zwolnienia, GTU, OSS
#
# Architektura: First-Match-Wins else-chain
# Werdykt:      Standardowy JDG verdict (patrz doc 34, sekcja 1.2)
#
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.vat.substantive

import data.jdg.helpers
import data.jdg.metadata

# ── Default: no matching rule ──────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.substantive.no_match",
    "package": "jdg.vat.substantive",
    "priority": 75
}

# ═══════════════════════════════════════════════════════════════════════════════
# TODO: Zaimplementuj reguły first-match-wins dla P50-P65
# ═══════════════════════════════════════════════════════════════════════════════
#
# Wzorzec reguły:
#
# decide := {
#     "matched": true,
#     "rule_id": "jdg.vat.substantive.rule_name",
#     "package": "jdg.vat.substantive",
#     "priority": XXX,
#     "vat_rate": "",
#     "rounding_level": "",
#     "gtu_code": "",
#     "pit_form": "",
#     "pit_rate": "",
#     "pit_bracket": "",
#     "pit_annual_return_type": "",
#     "kus_qualification": "",
#     "kus_percent": 0,
#     "zus_social_base_type": "",
#     "zus_health_rate": "",
#     "business_status": "",
#     "ceidg_registration_required": false,
#     "relief_type": "",
#     "relief_limit": 0,
#     "relief_deductible": 0,
#     "relief_carry_forward_years": 0,
#     "_routing": "",
#     "_routing_reason": "",
#     "_legal_basis": "",
#     "_warnings": []
# } {
#     # Warunki dopasowania reguły
#     true  # ← Zastąp faktycznymi warunkami
# }
#
# else := { ... } { ... }  # Kolejna reguła w łańcuchu else
#
# ═══════════════════════════════════════════════════════════════════════════════
