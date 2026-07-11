# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — VAT Deductions (SC)
# ═══════════════════════════════════════════════════════════════════════════════
# 
# Reguły odliczeń VAT dla spółki cywilnej.
# Stub — pełna implementacja w toku (zgodnie z planem 37_ULTIMATE_GRANULARITY).
#
# package: tax.vat.deductions
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.vat.deductions

default decide := {
	"matched": false,
	"rule_id": "tax.vat.deductions.no_match",
	"package": "tax.vat.deductions",
	"priority": 120,
	"vat_rate": "",
	"rounding_level": ""
}
