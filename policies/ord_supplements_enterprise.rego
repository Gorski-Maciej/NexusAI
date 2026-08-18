# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — P19 Supplement: Missing OrdPU Article Supplements
# v7.0 FIX (K72-2, a128-a133, a138m-o, a73): Supplementary micro-level rules
# for gaps identified in P19 report Sections 10.1-10.4
# Package: jdg.enterprise.ord_supplements
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.ord_supplements

import data.jdg.helpers

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION A: Art. 73 — Overpayment via Decision (K72-2)
# ═══════════════════════════════════════════════════════════════════════════════

# ORS-3400: a73 detection
a73_overpayment_by_decision(input) = check {
    has_decision := object.get(input, "tax_authority_decision", false)
    decision_type := object.get(input, "decision_type", "UNKNOWN")
    overpayment_amount := object.get(input, "overpayment_amount_pln", 0)
    days_since_decision := object.get(input, "days_since_decision", 0)

    is_refund_eligible := has_decision and decision_type == "OVERPAYMENT" and overpayment_amount > 0
    deadline_exceeded := days_since_decision > 30

    action := "WNIOSEK O ZWROT NADPŁATY + ODSETKI (art. 78 OrdPU)" { is_refund_eligible; deadline_exceeded }
    action := "OCZEKIWANIE NA ZWROT (30 dni)" { is_refund_eligible; not deadline_exceeded }
    action := "BRAK PODSTAW" { true }

    routing := "TRIAGE" { is_refund_eligible }
    routing := "PASS" { true }

    check := {
        "article": "73",
        "has_decision": has_decision,
        "decision_type": decision_type,
        "overpayment_amount": overpayment_amount,
        "is_refund_eligible": is_refund_eligible,
        "days_since_decision": days_since_decision,
        "refund_deadline_days": 30,
        "deadline_exceeded": deadline_exceeded,
        "action": action,
        "legal_basis": "Art. 73 § 1 pkt 1 + Art. 78 OrdPU",
        "routing": routing,
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION B: Art. 128-133 — Procedural Rectifications
# ═══════════════════════════════════════════════════════════════════════════════

# ORS-3410: a128
a128_rectification(input) = check {
    has_obvious_error := object.get(input, "obvious_error", false)
    action := "WNIOSEK O SPROSTOWANIE (art. 215 OrdPU)" { has_obvious_error }
    action := "N/D" { true }
    routing := "ALLOW" { has_obvious_error }
    routing := "PASS" { true }

    check := {
        "article": "128",
        "has_obvious_error": has_obvious_error,
        "action": action,
        "deadline": "Bezterminowo",
        "routing": routing,
    }
}

# ORS-3411: a129
a129_supplement(input) = check {
    has_omission := object.get(input, "decision_omission", false)
    action := "WNIOSEK O UZUPEŁNIENIE DECYZJI" { has_omission }
    action := "N/D" { true }
    routing := "ALLOW" { has_omission }
    routing := "PASS" { true }

    check := {
        "article": "129",
        "has_omission": has_omission,
        "action": action,
        "deadline": "14 dni od wykrycia",
        "routing": routing,
    }
}

# ORS-3412: a130
a130_clarification(input) = check {
    has_ambiguity := object.get(input, "decision_ambiguity", false)
    action := "WNIOSEK O WYJAŚNIENIE TREŚCI DECYZJI" { has_ambiguity }
    action := "N/D" { true }
    routing := "ALLOW" { has_ambiguity }
    routing := "PASS" { true }

    check := {
        "article": "130",
        "has_ambiguity": has_ambiguity,
        "action": action,
        "routing": routing,
    }
}

# ORS-3413: a131
a131_correction(input) = check {
    has_substantive_error := object.get(input, "substantive_error", false)
    action := "WNIOSEK O KOREKTĘ DECYZJI + UZASADNIENIE" { has_substantive_error }
    action := "N/D" { true }
    routing := "TRIAGE" { has_substantive_error }
    routing := "PASS" { true }

    check := {
        "article": "131",
        "has_substantive_error": has_substantive_error,
        "action": action,
        "routing": routing,
    }
}

# ORS-3414: a132
a132_revocation(input) = check {
    new_evidence := object.get(input, "new_evidence", false)
    fraud_detected := object.get(input, "fraud_detected", false)
    qualifies := new_evidence or fraud_detected

    action := "WNIOSEK O UCHYLENIE DECYZJI OSTATECZNEJ" { qualifies }
    action := "N/D" { true }
    deadline_text := "5 lat (art. 240 § 1 pkt 5 OrdPU)" { new_evidence }
    deadline_text := "Bezterminowo" { fraud_detected }
    deadline_text := "N/D" { true }
    routing := "TRIAGE" { qualifies }
    routing := "BLOCK" { not qualifies }

    check := {
        "article": "132",
        "new_evidence": new_evidence,
        "fraud_detected": fraud_detected,
        "action": action,
        "deadline": deadline_text,
        "routing": routing,
    }
}

# ORS-3415: a133
a133_reopening(input) = check {
    procedural_defect := object.get(input, "procedural_defect", false)
    party_excluded := object.get(input, "party_excluded", false)
    new_facts := object.get(input, "new_facts", false)
    grounds := procedural_defect or party_excluded or new_facts

    action := "WNIOSEK O WZNOWIENIE POSTĘPOWANIA" { grounds }
    action := "N/D" { true }
    routing := "TRIAGE" { grounds }
    routing := "PASS" { true }

    check := {
        "article": "133",
        "grounds": {
            "procedural_defect": procedural_defect,
            "party_excluded": party_excluded,
            "new_facts": new_facts,
        },
        "can_reopen": grounds,
        "action": action,
        "deadline": "1 miesiąc od powzięcia wiadomości (art. 241 § 2 OrdPU)",
        "routing": routing,
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION C: Art. 138m-o — Delivery Proxy
# ═══════════════════════════════════════════════════════════════════════════════

# ORS-3420: a138m
a138m_delivery_proxy(input) = check {
    has_delivery_proxy := object.get(input, "has_delivery_proxy", false)
    proxy_expiry := object.get(input, "proxy_expiry_days", 0)
    edelivery_active := object.get(input, "edelivery_active", false)

    requires_proxy := edelivery_active and not has_delivery_proxy
    expiring_soon := has_delivery_proxy and proxy_expiry <= 30

    action := "ZAREJESTRUJ PEŁNOMOCNIKA DO DORĘCZEŃ (PPS-1)" { requires_proxy }
    action := "ODNOWIENIE PEŁNOMOCNICTWA (PPS-1)" { expiring_soon }
    action := "OK" { true }
    routing := "WARN" { requires_proxy or expiring_soon }
    routing := "PASS" { true }

    check := {
        "article": "138m",
        "has_delivery_proxy": has_delivery_proxy,
        "requires_proxy": requires_proxy,
        "expiring_soon": expiring_soon,
        "action": action,
        "deadline": "Przed 2026-10-01 (e-Doręczenia obowiązkowe)",
        "routing": routing,
    }
}

# ORS-3421: a138n
a138n_proxy_scope(input) = check {
    covers_all_proceedings := object.get(input, "covers_all_proceedings", false)
    covers_enforcement := object.get(input, "covers_enforcement", false)

    # Flags
    gap_proc := 1 { not covers_all_proceedings }
    gap_proc := 0 { covers_all_proceedings }
    gap_enforce := 1 { not covers_enforcement }
    gap_enforce := 0 { covers_enforcement }

    has_gaps := gap_proc + gap_enforce > 0
    action := "ROZSZERZ ZAKRES PEŁNOMOCNICTWA" { has_gaps }
    action := "OK" { true }
    routing := "WARN" { has_gaps }
    routing := "PASS" { true }

    check := {
        "article": "138n",
        "covers_all_proceedings": covers_all_proceedings,
        "covers_enforcement": covers_enforcement,
        "has_gaps": has_gaps,
        "action": action,
        "routing": routing,
    }
}

# ORS-3422: a138o
a138o_crpo_sync(input) = check {
    crpo_registered := object.get(input, "crpo_registered", false)
    crpo_expiry := object.get(input, "crpo_expiry_days", 0)

    needs_sync := not crpo_registered
    needs_renewal := crpo_registered and crpo_expiry <= 60
    needs_action := needs_sync or needs_renewal

    action := "SYNCHRONIZUJ Z CRPO (Centralny Rejestr Pełnomocnictw)" { needs_sync }
    action := "ODNOWIENIE WPISU CRPO" { needs_renewal }
    action := "OK" { true }
    routing := "WARN" { needs_action }
    routing := "PASS" { true }

    check := {
        "article": "138o",
        "crpo_registered": crpo_registered,
        "crpo_expiry_days": crpo_expiry,
        "needs_sync": needs_sync,
        "needs_renewal": needs_renewal,
        "action": action,
        "routing": routing,
        "legal_basis": "Art. 138o OrdPU + Ustawa o e-Doręczeniach",
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECTION D: Aggregated warnings (no cumulative redeclaration)
# ═══════════════════════════════════════════════════════════════════════════════

build_ors_warnings(a73, a128, a129, a130, a131, a132, a133, a138m, a138n, a138o) = warnings {
    a73_flag := 1 { object.get(a73, "is_refund_eligible", false) }
    a73_flag := 0 { not object.get(a73, "is_refund_eligible", false) }
    a128_flag := 1 { object.get(a128, "has_obvious_error", false) }
    a128_flag := 0 { not object.get(a128, "has_obvious_error", false) }
    a129_flag := 1 { object.get(a129, "has_omission", false) }
    a129_flag := 0 { not object.get(a129, "has_omission", false) }
    a132_flag := 1 { object.get(a132, "new_evidence", false) or object.get(a132, "fraud_detected", false) }
    a132_flag := 0 { not (object.get(a132, "new_evidence", false) or object.get(a132, "fraud_detected", false)) }
    a133_flag := 1 { object.get(a133, "can_reopen", false) }
    a133_flag := 0 { not object.get(a133, "can_reopen", false) }
    a138m_flag := 1 { object.get(a138m, "requires_proxy", false) or object.get(a138m, "expiring_soon", false) }
    a138m_flag := 0 { not (object.get(a138m, "requires_proxy", false) or object.get(a138m, "expiring_soon", false)) }

    active_count := a73_flag + a128_flag + a129_flag + a132_flag + a133_flag + a138m_flag

    status := "Brak aktywnych luk — OK" { active_count == 0 }
    status := sprintf("%d aktywnych luk do obsłużenia", [active_count]) { active_count > 0 }

    warnings := ["📋 ORD SUPPLEMENTS — Gaps closed per P19 report", sprintf("   Status: %s", [status])]
}
