# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.jpk
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 1
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.jpk
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.jpk.no_match","package":"jdg.jpk","priority":99999}

# jdg.jpk.filing_deadlines_detailed — JPK_V7 — miesięczny do 25., kwartalny do 25. po kwartale
decide :=   {"matched":true,"rule_id":"jdg.jpk.filing_deadlines_detailed","package":"jdg.jpk","priority":972,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"JPK_V7 — miesięczny do 25., kwartalny do 25. po kwartale","_legal_basis":"Art. 99 ust. 1-3 VAT","_warnings":["JPK_V7 niezłożony w terminie — ryzyko Art. 77 KKS"]} {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}
