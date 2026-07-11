# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI Tax Policies — VAT Procedures (SC)
# ═══════════════════════════════════════════════════════════════════════════════
# 
# Reguły procedur VAT (MPP, split payment, WNT, WDT, trójstronne).
# Stub — pełna implementacja w toku (zgodnie z planem 37_ULTIMATE_GRANULARITY).
#
# package: tax.vat.procedures
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.vat.procedures

default decide := {
	"matched": false,
	"rule_id": "tax.vat.procedures.no_match",
	"package": "tax.vat.procedures",
	"priority": 140,
	"procedure": "",
	"vat_rate": "",
	"rounding_level": ""
}
