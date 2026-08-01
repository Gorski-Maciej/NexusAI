# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.jpk
# Generated from Plan OPA specifications: 2026-07-13 14:05:06
# Rules: 1
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.jpk
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.jpk.no_match","package":"jdg.jpk","priority":99999}

# jdg.jpk.filing_deadlines_detailed — JPK_V7 — miesięczny do 25., kwartalny do 25. po kwartale. JPK na żądanie: 14 dni (Art. 193a OrdPU) — termin podstawowy; w praktyce US daje 30 dni.
decide :=   {"matched":true,"rule_id":"jdg.jpk.filing_deadlines_detailed","package":"jdg.jpk","priority":972,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"WARNING","_routing_reason":"JPK_V7 — miesięczny do 25., kwartalny do 25. po kwartale; JPK na żądanie: 14 dni (max 30 dni w praktyce US)","_legal_basis":"Art. 99 ust. 1-3 VAT; Art. 193a OrdPU (14 dni na żądanie, możliwe przedłużenie do 30 dni)","_warnings":["JPK_V7 niezłożony w terminie — ryzyko Art. 77 KKS. JPK na żądanie US: 14 dni od doręczenia (możliwość przedłużenia do 30 dni)."]} {
    object.get(input.invoice, "days_to_deadline", 999) < 30
}
