# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE POWER OF ATTORNEY AUTO-MANAGER (Innovation 9.10 / BP-10, P19 v7.0)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise Power of Attorney Auto-Manager — PPS-1/PPO-1/UPL-1 Registry
# description: |
#   ENTERPRISE v7.0 — Automatyczne zarządzanie pełnomocnictwami podatkowymi.
#   Wypełnia lukę M2 z raportu P19: brak obsługi a138m-o (pełnomocnik do doręczeń).
#
#   KLUCZOWE FUNKCJE:
#   - Rejestr pełnomocnictw (PPS-1 — szczególne, PPO-1 — ogólne, UPL-1 — deklaracje)
#   - Monitorowanie ważności i terminów odnowienia
#   - Integracja z CRPO (Centralny Rejestr Pełnomocnictw Ogólnych)
#   - Pełnomocnictwo do doręczeń (Art. 138m-o OrdPU) zintegrowane z e-Doręczeniami
#   - Auto-odnawianie i alerty przed wygaśnięciem
#
# architecture: Enterprise v7.0 First-Match-Wins
# legal_basis: Art. 138a-138o OrdPU; Art. 80a-80d OrdPU (CRPO)
# package: jdg.poa_manager
# deprecated: false
# priority_range: 3120-3149
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.poa_manager

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.poa_manager.no_match",
    "package": "jdg.poa_manager", "priority": 9999
}

# POA types per OrdPU
poa_types := {
    "PPS-1": {"name": "Pełnomocnictwo szczególne", "form": "PPS-1", "law": "Art. 138f OrdPU"},
    "PPO-1": {"name": "Pełnomocnictwo ogólne", "form": "PPO-1/FOP", "law": "Art. 138a OrdPU"},
    "UPL-1": {"name": "Upoważnienie do podpisywania deklaracji", "form": "UPL-1", "law": "Art. 80a OrdPU"},
    "DELIVERY": {"name": "Pełnomocnictwo do doręczeń", "form": "PPS-1", "law": "Art. 138m OrdPU"},
}

# ═══════════════════════════════════════════════════════════════════════════════
# POA-3120: POA REGISTRY — Rejestr pełnomocnictw
# ═══════════════════════════════════════════════════════════════════════════════

decide := {
    "matched": true,
    "rule_id": "jdg.poa_manager.poa_registry",
    "package": "jdg.poa_manager",
    "priority": 3120,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "poa_total_active": total_active,
    "poa_types_held": types_held,
    "poa_crpo_registered": crpo_registered,
    "poa_delivery_agent_assigned": delivery_agent,
    "poa_delivery_agent_bae": delivery_bae,
    "_routing": poa_routing,
    "_routing_reason": poa_reason,
    "_legal_basis": "Art. 138a-138o OrdPU; Art. 80a OrdPU (UPL-1)",
    "_warnings": build_poa_warnings(total_active, types_held, crpo_registered, delivery_agent)
} {
    input.poa_registry_check == true
    active_poas := object.get(input, "poa_active_list", [])
    total_active := count(active_poas)
    types_held := [object.get(p, "type", "") | p := active_poas[_]]
    crpo_registered := object.get(input.jdg_entrepreneur, "poa_crpo_registered", false)
    delivery_agent := object.get(input.jdg_entrepreneur, "has_delivery_agent", false)
    delivery_bae := object.get(input.jdg_entrepreneur, "delivery_agent_bae", "")

    poa_routing := "TRIAGE_QUEUE" { not delivery_agent }
    poa_routing := "BLOCK_AND_ALERT" { not crpo_registered; total_active > 0 }
    poa_routing := "" { true }
    poa_reason := sprintf("BRAK pełnomocnika do doręczeń — obowiązkowe dla e-Doręczeń od 2025/2026!", []) { not delivery_agent }
    poa_reason := "Pełnomocnictwa niezarejestrowane w CRPO — dopełnij formalności." { not crpo_registered; total_active > 0 }
    poa_reason := "" { true }
}

build_poa_warnings(total, types, crpo, delivery) = warnings {
    type_list := concat(", ", types)
    warnings := [
        sprintf("📋 REJESTR PEŁNOMOCNICTW — %d aktywnych", [total]),
        sprintf("   Typy: %s", [type_list]),
        sprintf("   CRPO: %s", ["zarejestrowany ✓" { crpo } else "NIEZAREJESTROWANY ⚠️"]),
        sprintf("   Pełnomocnik do doręczeń: %s", ["TAK ✓" { delivery } else "BRAK 🚨"]),
        "─────────────────────────────────────────",
        "⚠️ Pełnomocnik do doręczeń (Art. 138m-o) jest KLUCZOWY dla e-Doręczeń!",
        "   Bez niego fikcja doręczenia (14 dni) może mieć katastrofalne skutki.",
    ]
}

# ═══════════════════════════════════════════════════════════════════════════════
# POA-3130: POA EXPIRY MONITOR — Monitorowanie wygasania pełnomocnictw
# ═══════════════════════════════════════════════════════════════════════════════

else := {
    "matched": true,
    "rule_id": "jdg.poa_manager.poa_expiry_monitor",
    "package": "jdg.poa_manager",
    "priority": 3130,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "poa_expiring_count": expiring_count,
    "poa_oldest_expiry_days": oldest_days,
    "poa_renewal_needed_count": renewal_count,
    "_routing": exp_routing,
    "_routing_reason": exp_reason,
    "_legal_basis": "Art. 138g OrdPU (wygaśnięcie pełnomocnictwa)",
    "_warnings": build_expiry_warnings(expiring_count, oldest_days, renewal_count)
} {
    input.poa_expiry_check == true
    poas := object.get(input, "poa_active_list", [])
    expiring := [p | p := poas[_]; object.get(p, "days_to_expiry", 999) <= 30]
    expiring_count := count(expiring)
    oldest_days := min([object.get(p, "days_to_expiry", 999) | p := expiring[_]]) { expiring_count > 0 }
    oldest_days := 999 { expiring_count == 0 }
    renewal_count := count([p | p := expiring[_]; object.get(p, "days_to_expiry", 999) <= 7])

    exp_routing := "BLOCK_AND_ALERT" { renewal_count > 0 }
    exp_routing := "TRIAGE_QUEUE" { expiring_count > 0 }
    exp_routing := "" { true }
    exp_reason := sprintf("PEŁNOMOCNICTWA WYGASNĄ ZA ≤7 DNI: %d — NATYCHMIAST odnow!", [renewal_count]) { renewal_count > 0 }
    exp_reason := sprintf("%d pełnomocnictw wygasa w ciągu 30 dni.", [expiring_count]) { expiring_count > 0 }
    exp_reason := "" { true }
}

build_expiry_warnings(expiring, oldest, renewal) = warnings {
    renewal > 0
    warnings := [sprintf("🚨 %d PEŁNOMOCNICTW WYGAŚNIE W CIĄGU 7 DNI — ODNÓW NATYCHMIAST!", [renewal])]
} else = warnings {
    expiring > 0
    warnings := [sprintf("⚠️ %d pełnomocnictw wygaśnie za %d dni — zaplanuj odnowienie.", [expiring, oldest])]
} else = ["✅ Wszystkie pełnomocnictwa ważne >30 dni."]
