# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE KSeF RESILIENCE FIREWALL (Innovation 8.1, P18 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise KSeF Resilience Firewall — Multi-Layer Outage Protection
# description: |
#   ENTERPRISE v7.0 — Wielowarstwowa ochrona przed awariami KSeF z SLO.
#   Rozszerza KSR-1600-1648 o proaktywny firewall z prognozowaniem awarii.
#
#   WARSTWY OCHRONY:
#   - Layer 1: Health Check & Early Warning (degradacja API, maintenance windows)
#   - Layer 2: Circuit Breaker (automatyczne wstrzymanie przy >50% błędów)
#   - Layer 3: Rate Limiter (ochrona przed throttlingiem API KSeF)
#   - Layer 4: Fallback Router (przełączanie na tryb offline)
#   - Layer 5: Recovery Orchestrator (koordynacja powrotu po awarii)
#
#   SLO (Service Level Objectives):
#   - Availability target: 99.5% monthly
#   - Max offline duration: 168h (7 dni)
#   - Recovery Time Objective (RTO): <4h po przywróceniu KSeF
#   - Recovery Point Objective (RPO): 0 (wszystkie faktury w outbox)
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 106na-106nq VAT; Enterprise SRE Best Practices
# package: jdg.ksef_firewall
# deprecated: false
# priority_range: 2300-2329
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.ksef_firewall

import data.jdg.helpers
import data.jdg.thresholds

default decide := {
    "matched": false, "rule_id": "jdg.ksef_firewall.no_match",
    "package": "jdg.ksef_firewall", "priority": 9999
}

# ═══════════════════════════════════════════════════════════════════════════════
# KFW-2300: FIREWALL STATUS — Całościowy status firewalla KSeF
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.ksef_firewall.firewall_status",
    "package": "jdg.ksef_firewall",
    "priority": 2300,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_firewall_layer_1_health": layer1,
    "ksef_firewall_layer_2_circuit": layer2,
    "ksef_firewall_layer_3_rate_limit": layer3,
    "ksef_firewall_layer_4_fallback": layer4,
    "ksef_firewall_layer_5_recovery": layer5,
    "ksef_firewall_overall_status": overall,
    "ksef_firewall_slo_compliance_pct": slo_pct,
    "_routing": fw_routing,
    "_routing_reason": fw_reason,
    "_legal_basis": "Enterprise SRE Framework; Art. 106na-106nq VAT",
    "_warnings": build_firewall_warnings(overall, layer1, layer2, layer3, layer4, layer5, slo_pct)
} {
    input.ksef_firewall_check == true

    # Layer 1: API Health
    api_up := object.get(input, "ksef_api_available", true)
    api_degraded := object.get(input, "ksef_api_degraded", false)
    layer1 := "GREEN" { api_up; not api_degraded }
    layer1 := "YELLOW" { api_up; api_degraded }
    layer1 := "RED" { not api_up }

    # Layer 2: Circuit Breaker
    error_rate := object.get(input, "ksef_error_rate_pct", 0)
    layer2 := "GREEN" { error_rate < 10 }
    layer2 := "YELLOW" { error_rate >= 10; error_rate < 50 }
    layer2 := "RED" { error_rate >= 50 }

    # Layer 3: Rate Limiter
    rate_utilization := object.get(input, "ksef_rate_utilization_pct", 0)
    layer3 := "GREEN" { rate_utilization < 70 }
    layer3 := "YELLOW" { rate_utilization >= 70; rate_utilization < 90 }
    layer3 := "RED" { rate_utilization >= 90 }

    # Layer 4: Fallback
    offline_active := object.get(input, "ksef_offline_mode_active", false)
    layer4 := "GREEN" { not offline_active }
    layer4 := "YELLOW" { offline_active }

    # Layer 5: Recovery
    recovery_in_progress := object.get(input, "ksef_recovery_in_progress", false)
    recovery_complete := object.get(input, "ksef_recovery_complete", false)
    layer5 := "GREEN" { recovery_complete; not recovery_in_progress }
    layer5 := "YELLOW" { recovery_in_progress }
    layer5 := "RED" { not recovery_complete; not recovery_in_progress; offline_active }

    # Overall status
    any_red := layer1 == "RED" or layer2 == "RED" or layer3 == "RED" or layer4 == "RED" or layer5 == "RED"
    any_yellow := layer1 == "YELLOW" or layer2 == "YELLOW" or layer3 == "YELLOW" or layer4 == "YELLOW" or layer5 == "YELLOW"
    overall := "RED" { any_red }
    overall := "YELLOW" { any_yellow; not any_red }
    overall := "GREEN" { not any_red; not any_yellow }

    slo_pct := object.get(input, "ksef_slo_monthly_uptime_pct", 99.7)

    fw_routing := "BLOCK_AND_ALERT" { overall == "RED" }
    fw_routing := "TRIAGE_QUEUE" { overall == "YELLOW" }
    fw_routing := "" { true }
    red_layers := []
    red_layers := array.concat(red_layers, ["L1"]) { layer1 == "RED" }
    red_layers := array.concat(red_layers, ["L2"]) { layer2 == "RED" }
    red_layers := array.concat(red_layers, ["L3"]) { layer3 == "RED" }
    red_layers := array.concat(red_layers, ["L4"]) { layer4 == "RED" }
    red_layers := array.concat(red_layers, ["L5"]) { layer5 == "RED" }
    fw_reason := sprintf("KSeF FIREWALL RED — warstwy: %s. Awaria krytyczna!", [concat(",", red_layers)]) { overall == "RED" }
    fw_reason := "KSeF Firewall YELLOW — monitoruj warstwy." { overall == "YELLOW" }
    fw_reason := "KSeF Firewall GREEN — wszystkie warstwy operacyjne." { true }
}

build_firewall_warnings(overall, l1, l2, l3, l4, l5, slo) = warnings {
    warnings := [
        "═══════════════════════════════════════════",
        sprintf("🛡️ KSeF RESILIENCE FIREWALL — %s", [overall]),
        sprintf("   L1 Health Check:  %s", [l1]),
        sprintf("   L2 Circuit Breaker: %s", [l2]),
        sprintf("   L3 Rate Limiter:    %s", [l3]),
        sprintf("   L4 Fallback:        %s", [l4]),
        sprintf("   L5 Recovery:        %s", [l5]),
        sprintf("   SLO (uptime): %.1f%% / target 99.5%%", [slo]),
        "═══════════════════════════════════════════",
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# KFW-2310: RATE LIMITER — Ochrona przed throttlingiem API KSeF
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_firewall.rate_limiter",
    "package": "jdg.ksef_firewall",
    "priority": 2310,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_rate_current_rpm": current_rpm,
    "ksef_rate_limit_rpm": rate_limit,
    "ksef_rate_utilization_pct": utilization,
    "ksef_rate_throttle_active": throttle_active,
    "ksef_rate_next_slot_seconds": next_slot_sec,
    "_routing": rate_routing,
    "_routing_reason": rate_reason,
    "_legal_basis": "API KSeF Rate Limits (10 req/min per NIP); Art. 106na VAT",
    "_warnings": [
        sprintf("⚡ KSeF RATE LIMITER: %d/%d RPM (%.0f%%)", [current_rpm, rate_limit, utilization]),
        sprintf("   %s", [throttle_text]),
    ]
} {
    input.ksef_rate_limiter_check == true
    current_rpm := object.get(input, "ksef_requests_per_minute", 0)
    rate_limit := 10  # API KSeF: 10 requests per minute per NIP
    utilization := current_rpm * 100 / rate_limit
    throttle_active := utilization >= 100
    next_slot_sec := 60 { throttle_active }
    next_slot_sec := 0 { not throttle_active }

    throttle_text := "Throttle NIEaktywny — normalna praca." { not throttle_active }
    throttle_text := sprintf("THROTTLE AKTYWNY — następne okno za %ds", [next_slot_sec]) { throttle_active }

    rate_routing := "BLOCK_AND_ALERT" { throttle_active; utilization >= 150 }
    rate_routing := "TRIAGE_QUEUE" { throttle_active }
    rate_routing := "" { true }
    rate_reason := "KSeF RATE LIMIT PRZEKROCZONY — wstrzymaj wysyłkę na 60s!" { throttle_active }
    rate_reason := "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# KFW-2320: RECOVERY ORCHESTRATOR — Koordynacja powrotu po awarii
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.ksef_firewall.recovery_orchestrator",
    "package": "jdg.ksef_firewall",
    "priority": 2320,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ksef_recovery_phase": recovery_phase,
    "ksef_recovery_phase_progress_pct": progress_pct,
    "ksef_recovery_rto_target_hours": 4,
    "ksef_recovery_elapsed_hours": elapsed_h,
    "ksef_recovery_rto_compliant": rto_ok,
    "_routing": rec_routing,
    "_routing_reason": rec_reason,
    "_legal_basis": "Enterprise SRE RTO/RPO; Art. 106ne VAT",
    "_warnings": build_recovery_warnings(recovery_phase, progress_pct, elapsed_h, rto_ok)
} {
    input.ksef_recovery_orchestrate == true
    ksef_online := object.get(input, "ksef_api_available", false)
    pending := object.get(input, "ksef_offline_queue_count", 0)
    sent_count := object.get(input, "ksef_recovery_sent_count", 0)
    elapsed_h := object.get(input, "ksef_recovery_elapsed_hours", 0)

    # Recovery phases: 1=Verify, 2=TokenRefresh, 3=BatchSend, 4=VerifyUPO, 5=Complete
    recovery_phase := 1 { pending > 0; sent_count == 0; ksef_online }
    recovery_phase := 2 { pending > 0; sent_count == 0; not ksef_online; elapsed_h > 0 }
    recovery_phase := 3 { sent_count > 0; sent_count < pending }
    recovery_phase := 4 { sent_count >= pending; pending > 0 }
    recovery_phase := 5 { pending == 0 or (sent_count >= pending and pending > 0) }
    progress_pct := sent_count * 100 / max([pending, 1])
    rto_ok := elapsed_h <= 4

    rec_routing := "TRIAGE_QUEUE" { recovery_phase < 5 }
    rec_routing := "" { true }
    rec_reason := sprintf("Recovery faza %d/5: %d/%d faktur (%.0f%%). RTO: %s.", [recovery_phase, sent_count, pending, progress_pct, "OK" { rto_ok } else sprintf("PRZEKROCZONY o %dh", [elapsed_h - 4])]) { recovery_phase < 5 }
    rec_reason := "Recovery zakończony — wszystkie faktury wysłane." { recovery_phase == 5 }
}

build_recovery_warnings(phase, progress, elapsed, rto) = warnings {
    phase_names := {1:"Weryfikacja API", 2:"Odświeżenie tokena", 3:"Batch send", 4:"Weryfikacja UPO", 5:"Zakończone"}
    name := object.get(phase_names, phase, "Nieznana")
    rto_text := "✓" { rto }
    rto_text := "✗ PRZEKROCZONY!" { not rto }
    warnings := [
        sprintf("🔄 KSeF RECOVERY — FAZA %d: %s (%.0f%%)", [phase, name, progress]),
        sprintf("   Czas od przywrócenia: %.1f godz. | RTO 4h: %s", [elapsed, rto_text]),
    ]
}
