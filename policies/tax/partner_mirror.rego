# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — Partner Data Mirror (ScPartnerMirror)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Mechanizm separacji danych wspólników z zachowaniem RODO i odpowiedzialności
# solidarnej. Dzieli werdykt na PartnerPrivateVerdict (tylko dla danego
# wspólnika) i PartnershipRiskMirror (zagregowane ryzyka dla wszystkich).
#
# Ulepszenie #2 z 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md
#
# package: tax.partner_mirror
# rule:     private_verdict, risk_mirror, decide
# ═══════════════════════════════════════════════════════════════════════════════

package tax.partner_mirror

# ── Partner Private Verdict (per partner, tylko jego dane) ────────────────────
# Zawiera pełne dane podatkowe TYLKO jednego wspólnika

private_verdict[p.id] := verdict {
    p := input.partners[_]
    verdict := {
        "partner_id": p.id,
        "nip": p.nip,
        "share_percent": p.share_percent,
        "tax_form": p.tax_form,
        "tax_form_display": _tax_form_display(p.tax_form),
        "pit_rate": _pit_rate(p),
        "pit_annual_income_share": object.get(p, "income_share", 0),
        "pit_advance_due": object.get(p, "monthly_advance", 0),
        "zus_social_status": p.zus_status,
        "zus_health_rate": _health_rate(p),
        "allowances_applied": _allowance_list(p),
        "annual_return_type": _return_type(p.tax_form),
        "annual_return_deadline": _return_deadline(p.tax_form),
        "_private": true,
        "_visible_to": [p.id]
    }
}

# ── Partnership Risk Mirror (zagregowane, zanonimizowane ryzyka) ──────────────
# Widoczny dla WSZYSTKICH wspólników — bez danych osobowych

risk_mirror := mirror {
    total := count(input.partners)
    mirror := {
        "total_partners": total,
        "risk_level": _aggregate_risk_level,
        "partners_with_zus_overdue": count({p.id | p := input.partners[_]; p.zus_social_paid < p.zus_social_due}),
        "partners_with_tax_overdue": count({p.id | p := input.partners[_]; object.get(p, "tax_overdue", false)}),
        "tax_form_distribution": _tax_form_distribution,
        "joint_liability_exposure": _joint_liability_exposure,
        "aggregate_warnings": _aggregate_warnings,
        "_visibility": "ALL_PARTNERS",
        "_anonymization": "AGGREGATED_ONLY"
    }
}

# ── Risk Level Calculation ────────────────────────────────────────────────────
_aggregate_risk_level := "CRITICAL" {
    count({p.id | p := input.partners[_]; p.zus_social_paid < p.zus_social_due}) >= count(input.partners) / 2
    count({p.id | p := input.partners[_]; object.get(p, "tax_overdue", false)}) > 0
}

_aggregate_risk_level := "HIGH" {
    count({p.id | p := input.partners[_]; p.zus_social_paid < p.zus_social_due}) > 0
}

_aggregate_risk_level := "MEDIUM" {
    count({p.id | p := input.partners[_]; object.get(p, "suspended", false)}) > 0
}

_aggregate_risk_level := "LOW" {
    true
}

# ── Tax Form Distribution (anonymized) ────────────────────────────────────────
_tax_form_distribution := dist {
    dist := {
        f: count({p.id | p := input.partners[_]; p.tax_form == f})
        | f := {"PIT_SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD", "IP_BOX"}
    }
}

# ── Joint Liability Exposure ──────────────────────────────────────────────────
_joint_liability_exposure := exposure {
    exposure := {
        "vat_debt_total": object.get(input.partnership, "vat_liability_outstanding", 0),
        "zus_employee_debt": object.get(input.partnership, "zus_employee_debt", 0),
        "pit_withholding_debt": object.get(input.partnership, "pit_withholding_debt", 0),
        "total_exposure": object.get(input.partnership, "vat_liability_outstanding", 0) +
            object.get(input.partnership, "zus_employee_debt", 0) +
            object.get(input.partnership, "pit_withholding_debt", 0),
        "liable_parties": [p.nip | p := input.partners[_]]
    }
}

# ── Aggregate Warnings ────────────────────────────────────────────────────────
_aggregate_warnings := warnings {
    m := [w |
        p := input.partners[_]
        p.zus_social_paid < p.zus_social_due
        w := "PARTNER_ZUS_OVERDUE_EXISTS"
    ]
    t := [w |
        p := input.partners[_]
        object.get(p, "tax_overdue", false)
        w := "PARTNER_TAX_OVERDUE_EXISTS"
    ]
    warnings := array.concat(m, t)
}

# ── Helpers ───────────────────────────────────────────────────────────────────

_tax_form_display("PIT_SCALE") := "Skala podatkowa 12%/32%"
_tax_form_display("LINEAR") := "Podatek liniowy 19%"
_tax_form_display("LUMP_SUM") := "Ryczałt ewidencjonowany"
_tax_form_display("TAX_CARD") := "Karta podatkowa"
_tax_form_display("IP_BOX") := "IP Box 5%"
_tax_form_display(_) := "Nieznana forma"

_pit_rate(p) := 0.12 { p.tax_form == "PIT_SCALE"; p.income_share <= 120000 }
_pit_rate(p) := 0.32 { p.tax_form == "PIT_SCALE"; p.income_share > 120000 }
_pit_rate(p) := 0.19 { p.tax_form == "LINEAR" }
_pit_rate(p) := 0.05 { p.tax_form == "IP_BOX" }
_pit_rate(p) := 0 { p.tax_form == "TAX_CARD" }

_health_rate(p) := 0.09 { p.tax_form == "PIT_SCALE" }
_health_rate(p) := 0.049 { p.tax_form == "LINEAR" }
_health_rate(p) := 0.09 { p.tax_form in {"LUMP_SUM", "TAX_CARD"} }

_allowance_list(p) := [a | a := _allowances_applied(p)]

_allowances_applied(p) := "B+R" { object.get(p, "rnd_deduction", 0) > 0 }
_allowances_applied(p) := "IP_BOX" { p.tax_form == "IP_BOX" }
_allowances_applied(p) := "YOUNG" { object.get(p, "age", 100) < 26 }
_allowances_applied(p) := "FAMILY_4PLUS" { object.get(p, "children_count", 0) >= 4 }

_return_type("PIT_SCALE") := "PIT-36"
_return_type("LINEAR") := "PIT-36L"
_return_type("LUMP_SUM") := "PIT-28"
_return_type("TAX_CARD") := "PIT-36"
_return_type("IP_BOX") := "PIT-36"

_return_deadline("LUMP_SUM") := "2027-02-28"
_return_deadline(_) := "2027-04-30"

# ── Decision Rule ─────────────────────────────────────────────────────────────
default decide := {
    "matched": false,
    "rule_id": "tax.partner_mirror.no_data",
    "package": "tax.partner_mirror",
    "priority": 75
}

decide := {
    "matched": true,
    "rule_id": "tax.partner_mirror.split_active",
    "package": "tax.partner_mirror",
    "priority": 75,
    "partner_private_verdicts": [v | v := private_verdict[_]],
    "partnership_risk_mirror": risk_mirror,
    "_routing": "OK",
    "_routing_reason": "Werdykt podzielony: PartnerPrivateVerdict + PartnershipRiskMirror",
    "_legal_basis": "RODO (Art. 5 minimalizacja danych) + Art. 864 KC (odpowiedzialność solidarna)"
} {
    count(input.partners) >= 2
    input.partnership.status == "ACTIVE"
}
