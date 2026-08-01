# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 14.7: Regulated Profession Compliance Checker
# v7.0 — Per-profession checklists (licenses, dues, insurance, training)
# Package: jdg.enterprise.regulated_compliance
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.regulated_compliance

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# RPC-3300: Profession detector from PKD/CEIDG
# ─────────────────────────────────────────────────────────────────────────────
rpc_detect_profession(input) = profession {
    pkd := object.get(input, "pkd_code", "")

    profession_map := {
        "86.21.Z": "LEKARZ",
        "86.22.Z": "LEKARZ_SPECJALISTA",
        "86.90.D": "PIELEGNIARKA",
        "69.10.Z": "ADWOKAT",
        "69.20.Z": "DORADCA_PODATKOWY",
        "86.90.A": "PSYCHOLOG",
        "85.59.B": "KOREPETYTOR",
        "69.10.B": "NOTARIUSZ",
        "69.10.C": "KOMORNIK",
    }

    profession := object.get(profession_map, pkd, "UNREGULATED")
}

# ─────────────────────────────────────────────────────────────────────────────
# RPC-3310: License + chamber dues compliance
# ─────────────────────────────────────────────────────────────────────────────
rpc_license_check(profession, input) = check {
    has_license := object.get(input, "has_professional_license", false)
    license_expiry_days := object.get(input, "license_expiry_days", 999)
    chamber_dues_paid := object.get(input, "chamber_dues_paid", false)
    chamber_dues_amount := object.get(input, "chamber_dues_annual_pln", 0)

    license_expiring := has_license and license_expiry_days <= 30
    dues_missing := not chamber_dues_paid

    # Buduj gaps array przez flagi (unikamy redeklaracji)
    gaps := []
    gaps := array.concat(gaps, ["LICENSE_EXPIRING"]) { license_expiring }
    gaps := array.concat(gaps, ["CHAMBER_DUES_UNPAID"]) { dues_missing }

    routing := "WARN" { count(gaps) > 0 }
    routing := "PASS" { count(gaps) == 0 }

    check := {
        "profession": profession,
        "has_license": has_license,
        "license_expiring": license_expiring,
        "chamber_dues_paid": chamber_dues_paid,
        "chamber_dues_amount_kup": chamber_dues_amount,
        "gaps": gaps,
        "routing": routing,
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# RPC-3320: VAT exemption + 14% lump-sum for medical professions
# ─────────────────────────────────────────────────────────────────────────────
rpc_tax_rules(profession, input) = rules {
    is_medical := profession in {"LEKARZ", "LEKARZ_SPECJALISTA", "PIELEGNIARKA", "PSYCHOLOG"}
    is_legal := profession in {"ADWOKAT", "DORADCA_PODATKOWY", "NOTARIUSZ", "KOMORNIK"}

    vat_exempt := is_medical or profession == "KOREPETYTOR"
    lump_sum_14 := is_medical and object.get(input, "revenue_from_medical_only", false)

    vat_legal := "Art. 43 ust. 1 pkt 19 ustawy o VAT" { vat_exempt }
    vat_legal := "" { not vat_exempt }
    lump_legal := "Art. 12 ust. 1 pkt 2 u.z.p.d." { lump_sum_14 }
    lump_legal := "" { not lump_sum_14 }

    rules := {
        "profession": profession,
        "vat_exempt_medical": vat_exempt,
        "vat_legal_basis": vat_legal,
        "lump_sum_14pct": lump_sum_14,
        "lump_sum_legal_basis": lump_legal,
        "kup_chamber_dues": is_legal,
        "kup_chamber_basis": "Art. 22 ust. 1 PIT",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# RPC-3330: Professional secrecy vs mandatory reporting (MDR/AML)
# ─────────────────────────────────────────────────────────────────────────────
rpc_secrecy_mdr_balance(profession, input) = balance {
    has_secrecy := profession in {"ADWOKAT", "DORADCA_PODATKOWY", "NOTARIUSZ"}
    mdr_trigger := object.get(input, "mdr_triggered", false)
    mdr_transferred := object.get(input, "mdr_transferred_to_client", false)
    crime_fraud := object.get(input, "crime_fraud_exception", false)

    must_report := true { crime_fraud }
    must_report := true { mdr_triggered; not mdr_transferred; not crime_fraud }
    must_report := false { true }

    balance := {
        "has_professional_secrecy": has_secrecy,
        "mdr_triggered": mdr_triggered,
        "mdr_transferred_to_client": mdr_transferred,
        "crime_fraud_exception": crime_fraud,
        "must_report": must_report,
        "legal_basis": "Art. 86a § 4 OrdPU (MDR przekazany klientowi); Art. 180 § 4 KPK (wyjątek crime-fraud)",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# RPC-3340: Build RPC warnings
# ─────────────────────────────────────────────────────────────────────────────
build_rpc_warnings(check, rules, balance) = warnings {
    gaps := object.get(check, "gaps", [])
    profession := object.get(check, "profession", "UNREGULATED")

    base := [sprintf("🏥 REGULATED PROFESSION COMPLIANCE — %s", [profession])]

    gap_warn := array.concat(base, [
        sprintf("   ⚠️ Luki: %s", [concat(", ", gaps)]),
    ]) { count(gaps) > 0 }

    gap_warn := array.concat(base, ["   ✅ Pełna zgodność"]) { count(gaps) == 0 }

    base2 := gap_warn

    secrecy_warn := array.concat(base2, [
        "   🔒 Tajemnica zawodowa + MDR: obowiązek raportowania przeniesiony na klienta (Art. 86a § 4 OrdPU)",
    ]) { object.get(balance, "mdr_transferred_to_client", false) }

    secrecy_warn := base2 { not object.get(balance, "mdr_transferred_to_client", false) }

    warnings := secrecy_warn
}
