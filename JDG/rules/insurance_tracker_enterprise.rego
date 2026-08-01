# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 14.8: Insurance Obligation Tracker
# v7.0 — Mandatory OC per PKD + expiration monitor + KUP + claims
# Package: jdg.enterprise.insurance_tracker
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.insurance_tracker

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# INT-3350: Mandatory OC detector per PKD
# ─────────────────────────────────────────────────────────────────────────────
int_detect_mandatory_oc(input) = oc {
    pkd := object.get(input, "pkd_code", "")
    has_oc := object.get(input, "has_professional_oc", false)
    oc_expiry_days := object.get(input, "oc_expiry_days", 999)

    requires_oc := pkd in {
        "86.21.Z", "86.22.Z", "86.90.D", "86.90.A",
        "69.10.Z", "69.20.Z", "69.10.B", "69.10.C",
        "49.41.Z", "41.20.Z", "43.21.Z",
    }
    missing_oc := requires_oc and not has_oc

    oc := {
        "pkd_code": pkd,
        "requires_oc": requires_oc,
        "has_oc": has_oc,
        "oc_expiry_days": oc_expiry_days,
        "missing_oc": missing_oc,
        "action": "WYKUP OBOWIĄZKOWE OC ZAWODOWE!" { missing_oc },
        "action": "ODNOWIENIE OC — wygasa za " + sprintf("%d dni", [oc_expiry_days]) { has_oc; oc_expiry_days <= 30 },
        "routing": "BLOCK" { missing_oc },
        "routing": "WARN" { has_oc; oc_expiry_days <= 30 },
        "routing": "PASS" { has_oc; oc_expiry_days > 30 },
        "routing": "PASS" { not requires_oc },
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# INT-3360: KUP calculator per policy
# ─────────────────────────────────────────────────────────────────────────────
int_kup_calculator(input) = kup {
    is_mandatory_oc := object.get(input, "is_mandatory_oc", false)
    premium_annual_pln := object.get(input, "premium_annual_pln", 0)
    is_above_market := object.get(input, "is_above_market_value", false)

    # Mandatory OC = 100% KUP (Art. 22 ust. 1 PIT)
    # Voluntary OC above market value = limited KUP (Art. 23 ust. 1 pkt 40 PIT)
    kup_amount := premium_annual_pln { is_mandatory_oc }
    kup_amount := 0 { not is_mandatory_oc; is_above_market }
    kup_amount := premium_annual_pln { not is_mandatory_oc; not is_above_market }

    kup := {
        "premium_annual": premium_annual_pln,
        "is_mandatory_oc": is_mandatory_oc,
        "kup_deductible": kup_amount,
        "kup_pct": 100 { is_mandatory_oc },
        "kup_pct": 0 { not is_mandatory_oc; is_above_market },
        "kup_pct": 100 { not is_mandatory_oc; not is_above_market },
        "legal_basis": "Art. 22 ust. 1 PIT (OC obowiązkowe); Art. 23 ust. 1 pkt 40 PIT (limit wartości rynkowej)",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# INT-3370: Claim register + tax classification
# ─────────────────────────────────────────────────────────────────────────────
int_claim_classifier(claim) = classification {
    claim_type := object.get(claim, "type", "UNKNOWN")
    amount := object.get(claim, "amount_pln", 0)

    is_personal_damage := claim_type == "PERSONAL_INJURY"
    is_bi := claim_type == "BUSINESS_INTERRUPTION"

    tax_treatment := "EXEMPT" { is_personal_damage }
    tax_treatment := "TAXABLE_REVENUE" { is_bi }
    legal_basis := "Art. 21 ust. 1 pkt 3c PIT" { is_personal_damage }
    legal_basis := "Art. 14 ust. 1 PIT" { is_bi }

    classification := {
        "claim_type": claim_type,
        "amount": amount,
        "tax_treatment": tax_treatment,
        "legal_basis": legal_basis,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# INT-3380: Build INT warnings
# ─────────────────────────────────────────────────────────────────────────────
build_int_warnings(oc_check, kup, claims) = warnings {
    missing_oc := object.get(oc_check, "missing_oc", false)
    routing := object.get(oc_check, "routing", "PASS")
    action := object.get(oc_check, "action", "")

    base := ["🛡️ INSURANCE OBLIGATION TRACKER"]

    oc_warn := array.concat(base, [
        sprintf("   🚨 %s", [action]),
    ]) { routing == "BLOCK" or routing == "WARN" }

    oc_warn := array.concat(base, ["   ✅ OC zgodne z wymogami"]) { routing == "PASS" }

    warnings := oc_warn
}
