# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI SC Policies — SC-Specific Helpers (Spółka Cywilna)
# ═══════════════════════════════════════════════════════════════════════════════
#
# SC-specific helper functions building on top of tax.helpers.
# Handles: partner[] iteration, proportional Art. 8 PIT split,
# joint liability computation, partner tax form detection,
# aggregated risk scoring, and partnership-aware routing.
#
# architecture: Helper Library (extends tax.helpers)
# priority: N/A (helper library, not a decision rule)
# package: tax.helpers_sc
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package tax.helpers_sc

import data.tax.helpers as helpers

# ── Partner Iteration Helpers ─────────────────────────────────────────────────

# Liczba wspólników
partner_count := cnt {
	cnt := count(input.partners)
}

# Czy partner istnieje (wg id)
partner_exists(partner_id) {
	input.partners[_].id == partner_id
}

# Pobiera partnera po id
get_partner(partner_id) := p {
	p := input.partners[_]
	p.id == partner_id
}

# ── Proportional Split (Art. 8 PIT — FUNDAMENT SC) ──────────────────────────
#
# Art. 8 PIT: Przychody i koszty spółki dzielone są proporcjonalnie
# do udziałów wspólników określonych w umowie spółki.
# Jest to NAJWAŻNIEJSZA zasada SC — VAT jest spółki, PIT jest wspólników.

# Suma udziałów wszystkich wspólników (powinna = 100)
total_shares_pct := total {
	total := sum([p.share_percent | p := input.partners[_]])
}

# Udział wspólnika w przychodzie spółki (Art. 8 ust. 1 PIT)
partner_revenue_share(partner_id) := share {
	p := get_partner(partner_id)
	share := input.partnership.revenue_annual_net * (p.share_percent / 100)
}

# Udział wspólnika w kosztach spółki (Art. 8 ust. 2 PIT)
partner_cost_share(partner_id) := share {
	p := get_partner(partner_id)
	share := input.partnership.costs_annual * (p.share_percent / 100)
}

# Dochód wspólnika ze spółki (przed odliczeniami osobistymi)
partner_income_from_sc(partner_id) := income {
	income := partner_revenue_share(partner_id) - partner_cost_share(partner_id)
}

# ── Joint Liability Computations (Art. 864 KC) ───────────────────────────────

# Czy którykolwiek wspólnik ma zaległości ZUS
any_partner_zus_overdue {
	p := input.partners[_]
	p.zus_social_paid < p.zus_social_due
}

# Czy którykolwiek wspólnik ma zaległość podatkową
any_partner_tax_overdue {
	p := input.partners[_]
	object.get(p, "tax_overdue", false)
}

# Całkowite zobowiązanie solidarne SC (VAT + ZUS pracowniczy + PIT withholding)
joint_liability_total := total {
	total := object.get(input.partnership, "vat_liability_outstanding", 0) +
		object.get(input.partnership, "zus_employee_debt", 0) +
		object.get(input.partnership, "pit_withholding_debt", 0) +
		object.get(input.partnership, "other_public_debt", 0)
}

# Numer NIP wszystkich wspólników (dla egzekucji solidarnej)
liable_partner_nips := nips {
	nips := [p.nip | p := input.partners[_]]
}

# ── Partner Tax Form Detection ────────────────────────────────────────────────
#
# W spółce cywilnej KAŻDY wspólnik może mieć INNĄ formę opodatkowania PIT!
# To kluczowa różnica vs JDG.

# Mapa: partner_id → jego forma opodatkowania PIT
partner_tax_forms := forms {
	forms := {p.id: p.tax_form | p := input.partners[_]}
}

# Czy wszyscy wspólnicy mają tę samą formę opodatkowania?
all_partners_same_tax_form {
	forms := {p.tax_form | p := input.partners[_]}
	count(forms) == 1
}

# Czy którykolwiek wspólnik jest na skali podatkowej?
any_partner_on_scale {
	input.partners[_].tax_form == "PIT_SCALE"
}

# Czy którykolwiek wspólnik jest na liniowym?
any_partner_on_linear {
	input.partners[_].tax_form == "LINEAR"
}

# Czy którykolwiek wspólnik jest na ryczałcie?
any_partner_on_lump_sum {
	input.partners[_].tax_form == "LUMP_SUM"
}

# Czy którykolwiek wspólnik jest na karcie podatkowej?
any_partner_on_tax_card {
	input.partners[_].tax_form == "TAX_CARD"
}

# ── Partnership Status Checks ─────────────────────────────────────────────────

# Czy spółka jest aktywna?
partnership_active {
	input.partnership.status == "ACTIVE"
}

# Czy spółka jest rozwiązana/w likwidacji?
partnership_dissolved {
	input.partnership.status == "DISSOLVED"
}

# Czy spółka jest zawieszona?
partnership_suspended {
	input.partnership.status == "SUSPENDED"
}

# Czy spółka jest w trakcie sukcesji (śmierć wspólnika)?
partnership_in_succession {
	input.partnership.status == "SUCCESSION"
}

# ── VAT Registration Status ───────────────────────────────────────────────────

# Czy SC jest czynnym podatnikiem VAT?
sc_is_vat_payer {
	input.partnership.is_vat_payer == true
}

# Czy SC jest zwolniona z VAT?
sc_is_vat_exempt {
	input.partnership.is_vat_payer == false
	input.partnership.vat_exemption_reason != ""
}

# ── Accounting Method Detection ───────────────────────────────────────────────

# Czy SC prowadzi pełną księgowość?
sc_has_full_accounting {
	input.partnership.accounting_method == "FULL_ACCOUNTING"
}

# Czy SC prowadzi PKPiR?
sc_has_pkpir {
	input.partnership.accounting_method == "PKPIR"
}

# ── Aggregated Risk Scoring for Partnership ───────────────────────────────────

# Partner-specific risk score (0.0 = safe, 1.0 = highest risk)
partner_risk_score(partner_id) := score {
	p := get_partner(partner_id)
	factors := [
		f | p.zus_social_paid < p.zus_social_due; f := 0.3
	]
	factors2 := [
		f | object.get(p, "tax_overdue", false); f := 0.4
	]
	factors3 := [
		f | object.get(p, "suspended", false); f := 0.3
	]
	all_factors := array.concat(array.concat(factors, factors2), factors3)
	score := min([sum(all_factors), 1.0])
}

# Partnership aggregate risk score
partnership_risk_score := score {
	partner_scores := [partner_risk_score(p.id) | p := input.partners[_]]
	score := sum(partner_scores) / count(partner_scores)
}

# ── SC-Specific Routing Reason Builder ────────────────────────────────────────

# Buduje routing reason z kontekstem SC
sc_routing_reason(category, details) := reason {
	reason := concat("", [
		"[SC-", input.partnership.nip, "] ", category, ": ", details
	])
}

# ── Revenue Threshold Checks ──────────────────────────────────────────────────

# Czy przychód SC przekracza limit zwolnienia z VAT?
sc_exceeds_vat_exemption {
	input.partnership.revenue_annual_net > helpers.get_rate("vat_exemption_limit_pln", helpers.sc_threshold_limit("vat_exemption_limit_pln", 200000))
}

# Czy przychód SC przekracza limit dla pełnej księgowości (2M EUR)?
sc_exceeds_full_accounting_limit {
	input.partnership.revenue_annual_net > helpers.sc_threshold_limit("full_accounting_limit_eur", 2000000) * helpers.sc_threshold_rate("eur_pln", 4.35)
}

# ── MPP / Split Payment Detection for SC ──────────────────────────────────────

# Czy SC musi stosować MPP?
sc_mpp_mandatory {
	input.invoice.amount_gross > helpers.sc_threshold_limit("mpp_limit", 15000)
	helpers.is_mpp_sensitive(input.invoice.category_code)
}

