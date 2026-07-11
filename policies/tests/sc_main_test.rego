# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI SC — Integration Tests (Spółka Cywilna)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Testy integracyjne dla głównego orchestratora SC i wszystkich nowych
# pakietów: main_sc, sc_fallback, sc_partnership, sc_liability, sc_ksef_jpk.
#
# Usage: opa test policies/ -v
# ═══════════════════════════════════════════════════════════════════════════════

package tax.main_sc_test

# ── Test Data Fixtures ────────────────────────────────────────────────────────

# Standardowa SC: 2 wspólników, VAT czynny, aktywna
sc_active_input := {
	"invoice": {
		"transaction_date": "2026-07-11",
		"amount_net": 10000,
		"amount_gross": 12300,
		"currency": "PLN",
		"direction": "PURCHASE",
		"category_code": "IT_OFFICE",
		"is_cash_payment": false,
		"expense_type": "OPERATIONAL",
		"category_avg_amount": 8000,
		"category_stddev_amount": 2000
	},
	"vendor": {
		"nip": "1234567890",
		"country": "PL",
		"is_business": true,
		"trust_score": 0.95,
		"fraud_flag": false,
		"is_new": false,
		"bank_account_on_whitelist": true,
		"tax_residence": "PL",
		"transaction_count_with_partner": 10
	},
	"partnership": {
		"nip": "9876543210",
		"name": "Test SC",
		"status": "ACTIVE",
		"is_vat_payer": true,
		"accounting_method": "PKPIR",
		"revenue_annual_net": 500000,
		"costs_annual": 300000,
		"employee_count": 0,
		"vat_liability_outstanding": 0,
		"zus_employee_debt": 0,
		"pit_withholding_debt": 0,
		"other_public_debt": 0,
		"formation_document": "WRITTEN"
	},
	"partners": [
		{
			"id": "P1",
			"nip": "1111111111",
			"share_percent": 60,
			"tax_form": "PIT_SCALE",
			"zus_status": "STANDARD",
			"zus_social_due": 1500,
			"zus_social_paid": 1500,
			"tax_overdue": false,
			"suspended": false,
			"monthly_costs": 5000
		},
		{
			"id": "P2",
			"nip": "2222222222",
			"share_percent": 40,
			"tax_form": "LINEAR",
			"zus_status": "STANDARD",
			"zus_social_due": 1500,
			"zus_social_paid": 1500,
			"tax_overdue": false,
			"suspended": false,
			"monthly_costs": 5000
		}
	],
	"thresholds": {
		"limits": {"trust_auto_post": 0.92, "cash_payment_limit_pln": 15000, "mpp_limit": 15000},
		"rates": {"vat_standard": 0.23, "eur_pln": 4.35},
		"fc_thresholds": {"vendor_nip": 0.80, "cit_standard_vat_rate": 0.98},
		"valid_from": "2026-01-01"
	},
	"confidence": {
		"fc_vat_rate": 0.99,
		"fc_vendor_nip": 0.99
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 1: main_sc should merge all passes into final_sc_verdict
# ═══════════════════════════════════════════════════════════════════════════════

test_main_sc_merges_all_passes {
	result := tax.main_sc.final_sc_verdict with input as sc_active_input
	result.matched == true
	result.rule_id != ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 2: main_sc should include SC context
# ═══════════════════════════════════════════════════════════════════════════════

test_main_sc_includes_sc_context {
	ctx := tax.main_sc.sc_context with input as sc_active_input
	ctx.entity_type == "SPOLKA_CYWILNA"
	ctx.partner_count == 2
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 3: complete_verdict should contain all required fields
# ═══════════════════════════════════════════════════════════════════════════════

test_main_sc_complete_verdict {
	cv := tax.main_sc.complete_verdict with input as sc_active_input
	cv.entity_type == "SPOLKA_CYWILNA"
	cv.partner_count == 2
	cv.joint_liability_total == 0
	cv.matched == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 4: sc_fallback should match domestic SC
# ═══════════════════════════════════════════════════════════════════════════════

test_sc_fallback_domestic {
	result := tax.sc_fallback.decide with input as sc_active_input
	result.matched == true
	result.rule_id == "tax.sc_fallback.domestic_sc"
	result.vat_rate == "0.23"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 5: sc_fallback should handle dissolved SC
# ═══════════════════════════════════════════════════════════════════════════════

test_sc_fallback_dissolved {
	dissolved_input := json.patch(sc_active_input, [
		{"op": "replace", "path": "/partnership/status", "value": "DISSOLVED"},
		{"op": "replace", "path": "/partnership/vat_liability_outstanding", "value": 50000}
	])
	result := tax.sc_fallback.decide with input as dissolved_input
	result.rule_id == "tax.sc_fallback.dissolved_sc"
	result._routing == "TRIAGE_QUEUE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 6: sc_partnership should alert on verbal contract
# ═══════════════════════════════════════════════════════════════════════════════

test_sc_partnership_verbal_contract {
	verbal_input := json.patch(sc_active_input, [
		{"op": "replace", "path": "/partnership/formation_document", "value": "VERBAL"}
	])
	result := tax.sc_partnership.decide with input as verbal_input
	result.rule_id == "tax.sc_partnership.formation_verbal"
	result._routing == "TRIAGE_QUEUE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 7: sc_liability should report no liability for clean SC
# ═══════════════════════════════════════════════════════════════════════════════

test_sc_liability_no_exposure {
	result := tax.sc_liability.decide with input as sc_active_input
	result.rule_id == "tax.sc_liability.no_exposure"
	result.joint_liability == false
	result.joint_liability_total == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 8: sc_liability should report joint liability when debts exist
# ═══════════════════════════════════════════════════════════════════════════════

test_sc_liability_joint_active {
	debt_input := json.patch(sc_active_input, [
		{"op": "replace", "path": "/partnership/vat_liability_outstanding", "value": 100000}
	])
	result := tax.sc_liability.decide with input as debt_input
	result.rule_id == "tax.sc_liability.joint_all"
	result.joint_liability == true
	result.joint_liability_total == 100000
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 9: sc_ksef_jpk should require KSeF for B2B VAT payer SC
# ═══════════════════════════════════════════════════════════════════════════════

test_sc_ksef_mandatory {
	result := tax.sc_ksef_jpk.decide with input as sc_active_input
	result.rule_id == "tax.sc_ksef_jpk.ksef_mandatory"
	result.ksef_required == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 10: helper_sc should correctly compute partner income shares
# ═══════════════════════════════════════════════════════════════════════════════

test_helpers_sc_partner_count {
	cnt := tax.helpers_sc.partner_count with input as sc_active_input
	cnt == 2
}

test_helpers_sc_proportional_split {
	income_p1 := tax.helpers_sc.partner_revenue_share("P1") with input as sc_active_input
	cost_p1 := tax.helpers_sc.partner_cost_share("P1") with input as sc_active_input

	# P1 ma 60% udziału, przychód 500k → 300k
	income_p1 == 300000
	cost_p1 == 180000
}

test_helpers_sc_joint_liability {
	total := tax.helpers_sc.joint_liability_total with input as sc_active_input
	total == 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 11: Simulation mode (What-If Engine)
# ═══════════════════════════════════════════════════════════════════════════════

test_what_if_simulation_active {
	sim_input := json.patch(sc_active_input, [
		{"op": "add", "path": "/_mode", "value": "SIMULATION"},
		{"op": "add", "path": "/_simulation_params", "value": {
			"scenario_name": "Test zmiany formy opodatkowania",
			"partner_id": "P1",
			"new_tax_form": "LINEAR",
			"new_share_percent": 70
		}}
	])
	result := tax.what_if.decide with input as sim_input
	result.matched == true
	result.rule_id == "tax.what_if.simulation_active"
	result.simulation.mode == "SIMULATION"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 12: Partner Mirror should split verdict for 2+ partners
# ═══════════════════════════════════════════════════════════════════════════════

test_partner_mirror_split {
	result := tax.partner_mirror.decide with input as sc_active_input
	result.matched == true
	result.rule_id == "tax.partner_mirror.split_active"
	count(result.partner_private_verdicts) == 2
	result.partnership_risk_mirror.total_partners == 2
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 13: Temporal Sandbox should select correct period
# ═══════════════════════════════════════════════════════════════════════════════

test_temporal_period_selection {
	temporal_input := json.patch(sc_active_input, [
		{"op": "add", "path": "/thresholds/_temporal_periods", "value": [
			{"id": "P2025", "valid_from": "2025-01-01", "valid_to": "2025-12-31", "thresholds": {"rates": {"vat_standard": 0.22}}},
			{"id": "P2026", "valid_from": "2026-01-01", "thresholds": {"rates": {"vat_standard": 0.23}}}
		]}
	])
	result := tax.temporal.decide with input as temporal_input
	result.matched == true
	result.effective_period != ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 14: Anomaly detection should flag amount > 3 sigma
# ═══════════════════════════════════════════════════════════════════════════════

test_anomaly_amount_zscore {
	anomaly_input := json.patch(sc_active_input, [
		{"op": "replace", "path": "/invoice/amount_net", "value": 16000},
		{"op": "replace", "path": "/invoice/category_avg_amount", "value": 6000},
		{"op": "replace", "path": "/invoice/category_stddev_amount", "value": 2000}
	])
	result := tax.anomaly.decide with input as anomaly_input
	result.rule_id == "tax.anomaly.amount_zscore"
	result.anomaly_detected == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# Test 15: evaluation_summary for active SC
# ═══════════════════════════════════════════════════════════════════════════════

test_main_sc_evaluation_summary {
	summary := tax.main_sc.evaluation_summary with input as sc_active_input
	summary.entity_type == "SPOLKA_CYWILNA"
	summary.partners_evaluated == 2
	summary.joint_liability_exposure == 0
}
