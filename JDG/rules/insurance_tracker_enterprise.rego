# NexusAI JDG Enterprise — Insurance Obligation Tracker.
# Package: jdg.enterprise.insurance_tracker.

package jdg.enterprise.insurance_tracker

import future.keywords.if
import future.keywords.in

bool_text(value) := sprintf("%v", [value])
bool_not(value) := object.get({"true": false, "false": true}, bool_text(value), false)
both_true(a, b) := object.get({"true|true": true}, sprintf("%v|%v", [a, b]), false)

requires_oc_for(pkd) := object.get({
    "86.21.Z": true,
    "86.22.Z": true,
    "86.90.D": true,
    "86.90.A": true,
    "69.10.Z": true,
    "69.20.Z": true,
    "69.10.B": true,
    "69.10.C": true,
    "49.41.Z": true,
    "41.20.Z": true,
    "43.21.Z": true,
}, pkd, false)

action_for(missing, has_oc, expiry_days) := "WYKUP OBOWIĄZKOWE OC ZAWODOWE!" if {
    missing
} else := sprintf("ODNOWIENIE OC — wygasa za %d dni", [expiry_days]) if {
    has_oc
    expiry_days <= 30
} else := "" if {
    true
}

routing_for(missing, has_oc, expiry_days, required) := "BLOCK" if {
    missing
} else := "WARN" if {
    has_oc
    expiry_days <= 30
} else := "PASS" if {
    has_oc
    expiry_days > 30
} else := "PASS" if {
    not required
}

# INT-3350: Mandatory OC detector per PKD.
int_detect_mandatory_oc(payload) := {
    "pkd_code": pkd,
    "requires_oc": requires_oc,
    "has_oc": has_oc,
    "oc_expiry_days": expiry_days,
    "missing_oc": missing_oc,
    "action": action,
    "routing": routing,
} if {
    pkd := object.get(payload, "pkd_code", "")
    has_oc := object.get(payload, "has_professional_oc", false)
    expiry_days := object.get(payload, "oc_expiry_days", 999)
    requires_oc := requires_oc_for(pkd)
    missing_oc := both_true(requires_oc, bool_not(has_oc))
    action := action_for(missing_oc, has_oc, expiry_days)
    routing := routing_for(missing_oc, has_oc, expiry_days, requires_oc)
}

kup_amount_for(mandatory, premium, above_market) := premium if {
    mandatory
} else := 0 if {
    not mandatory
    above_market
} else := premium if {
    not mandatory
    not above_market
}

kup_pct_for(mandatory, above_market) := 100 if {
    mandatory
} else := 0 if {
    not mandatory
    above_market
} else := 100 if {
    not mandatory
    not above_market
}

# INT-3360: KUP calculator per policy.
int_kup_calculator(payload) := {
    "premium_annual": premium,
    "is_mandatory_oc": mandatory,
    "kup_deductible": kup_amount_for(mandatory, premium, above_market),
    "kup_pct": kup_pct_for(mandatory, above_market),
    "legal_basis": "Art. 22 ust. 1 PIT (OC obowiązkowe); Art. 23 ust. 1 pkt 40 PIT (limit wartości rynkowej)",
} if {
    mandatory := object.get(payload, "is_mandatory_oc", false)
    premium := object.get(payload, "premium_annual_pln", 0)
    above_market := object.get(payload, "is_above_market_value", false)
}

tax_treatment_for(claim_type) := "EXEMPT" if {
    claim_type == "PERSONAL_INJURY"
} else := "TAXABLE_REVENUE" if {
    claim_type == "BUSINESS_INTERRUPTION"
} else := "REVIEW" if {
    true
}

legal_basis_for(claim_type) := "Art. 21 ust. 1 pkt 3c PIT" if {
    claim_type == "PERSONAL_INJURY"
} else := "Art. 14 ust. 1 PIT" if {
    claim_type == "BUSINESS_INTERRUPTION"
} else := "Do weryfikacji"

# INT-3370: claim register + tax classification.
int_claim_classifier(claim) := {
    "claim_type": claim_type,
    "amount": amount,
    "tax_treatment": tax_treatment_for(claim_type),
    "legal_basis": legal_basis_for(claim_type),
} if {
    claim_type := object.get(claim, "type", "UNKNOWN")
    amount := object.get(claim, "amount_pln", 0)
}

# INT-3380: Build warnings.
build_int_warnings(oc_check, _, _) := ["🛡️ INSURANCE OBLIGATION TRACKER", warning] if {
    routing := object.get(oc_check, "routing", "PASS")
    warning := sprintf("   🚨 %s", [object.get(oc_check, "action", "")])
    routing in {"BLOCK", "WARN"}
} else := ["🛡️ INSURANCE OBLIGATION TRACKER", "   ✅ OC zgodne z wymogami"] if {
    true
}
