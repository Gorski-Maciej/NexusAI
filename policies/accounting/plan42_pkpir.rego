# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.accounting
# Generated from Plan OPA specifications: 2026-07-13 13:59:36
# Rules: 1
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.accounting
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.accounting.no_match","package":"jdg.accounting","priority":99999}

# jdg.accounting.pkpir_remnant_consistency — Spis z natury — remanent końcowy = remanent początkowy następnego roku
decide :=   {"matched":true,"rule_id":"jdg.accounting.pkpir_remnant_consistency","package":"jdg.accounting","priority":816,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"BLOCK_AND_ALERT","_routing_reason":"Spis z natury — remanent końcowy = remanent początkowy następnego roku","_legal_basis":"§ 27-28 Rozporządzenia ws. PKPiR","_warnings":["Niezgodność remanentu — koniec roku N ≠ początek roku N+1"]} {
    object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true
}
