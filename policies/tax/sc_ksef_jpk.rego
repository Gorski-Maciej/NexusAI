# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI SC — KSeF / JPK Integration Rules (Spółka Cywilna)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły dotyczące Krajowego Systemu e-Faktur (KSeF) i JPK_V7 dla SC.
# SC jako podatnik VAT ma obowiązek wystawiania i odbierania e-faktur.
#
# package: tax.sc_ksef_jpk
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.sc_ksef_jpk

import data.tax.helpers_sc
import data.tax.helpers as helpers

# ── Default ───────────────────────────────────────────────────────────────────
default decide := {
	"matched": false,
	"rule_id": "tax.sc_ksef_jpk.no_match",
	"package": "tax.sc_ksef_jpk",
	"priority": 600
}

# ═══════════════════════════════════════════════════════════════════════════════
# SKJ-001: sc_ksef_mandatory_b2b
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: SC jako czynny podatnik VAT ma obowiązek wystawiania faktur przez KSeF

decide := {
	"matched": true,
	"rule_id": "tax.sc_ksef_jpk.ksef_mandatory",
	"package": "tax.sc_ksef_jpk",
	"priority": 600,
	"ksef_required": true,
	"ksef_sender": input.partnership.nip,
	"_routing": "OK",
	"_routing_reason": "[SC] KSeF obowiązkowy — SC jako czynny podatnik VAT",
	"_legal_basis": "Art. 106ga-106gd VAT (KSeF obowiązkowy od 2026)",
	"_warnings": ["KSeF: Faktura musi być wystawiona przez Krajowy System e-Faktur"]
} {
	helpers_sc.sc_is_vat_payer
	input.vendor.is_business == true
}

# ═══════════════════════════════════════════════════════════════════════════════
# SKJ-002: sc_ksef_invoice_not_in_system
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Faktura B2B od kontrahenta PL nie znaleziona w KSeF → alert

else := {
	"matched": true,
	"rule_id": "tax.sc_ksef_jpk.invoice_not_in_ksef",
	"package": "tax.sc_ksef_jpk",
	"priority": 605,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Faktura zakupowa nie znaleziona w KSeF — weryfikuj autentyczność",
	"_legal_basis": "Art. 106ga VAT (KSeF — obowiązek wystawiania i odbierania)",
	"_warnings": [
		"KSeF: Faktura nie znaleziona w systemie — możliwe oszustwo VAT",
		"Bez faktury w KSeF = ryzyko zakwestionowania odliczenia VAT"
	]
} {
	input.vendor.is_business == true
	input.vendor.country == "PL"
	object.get(input.invoice, "ksef_id", "") == ""
	helpers_sc.sc_is_vat_payer
}

# ═══════════════════════════════════════════════════════════════════════════════
# SKJ-003: sc_jpk_v7_deadline_25th
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: JPK_V7 składane do 25 dnia następnego miesiąca

else := {
	"matched": true,
	"rule_id": "tax.sc_ksef_jpk.jpk_v7_due",
	"package": "tax.sc_ksef_jpk",
	"priority": 610,
	"jpk_v7_due": true,
	"jpk_v7_deadline": "25th_of_next_month",
	"jpk_v7_period": _jpk_period,
	"gtu_code": helpers.category_to_gtu(input.invoice.category_code),
	"_routing": "OK",
	"_routing_reason": "[SC] JPK_V7 — raportowanie VAT do 25 dnia następnego miesiąca",
	"_legal_basis": "Art. 99 ust. 11a VAT (JPK_V7), Rozporządzenie MF ws. JPK_VAT"
} {
	helpers_sc.sc_is_vat_payer
}

_jpk_period := period {
	date := input.invoice.transaction_date
	year := substring(date, 0, 4)
	month := substring(date, 5, 2)
	period := sprintf("%s-%s", [year, month])
}

# ═══════════════════════════════════════════════════════════════════════════════
# SKJ-004: sc_vat_whitelist_transfer_check
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Przelew >15k PLN → wymagana weryfikacja Białej Listy VAT

else := {
	"matched": true,
	"rule_id": "tax.sc_ksef_jpk.whitelist_transfer",
	"package": "tax.sc_ksef_jpk",
	"priority": 620,
	"whitelist_check_required": true,
	"whitelist_status": input.vendor.bank_account_on_whitelist,
	"_routing": route,
	"_routing_reason": "[SC] Przelew >15k PLN — wymagana weryfikacja rachunku na Białej Liście MF",
	"_legal_basis": "Art. 96b VAT (Biała Lista), Art. 117ba Ordynacji podatkowej",
	"_warnings": [w | not input.vendor.bank_account_on_whitelist; w := "UWAGA: Rachunek kontrahenta NIE znajduje się na Białej Liście MF!"]
} {
	input.invoice.amount_gross > helpers.sc_threshold_limit("whitelist_transfer_threshold_pln", 15000)
	input.vendor.country == "PL"
	not input.invoice.is_cash_payment
}

route := "OK" { input.vendor.bank_account_on_whitelist }
route := "BLOCK_AND_ALERT" { not input.vendor.bank_account_on_whitelist }

# ═══════════════════════════════════════════════════════════════════════════════
# SKJ-005: sc_cash_limit_enforcement
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Płatność gotówkowa >15k PLN → NKUP

else := {
	"matched": true,
	"rule_id": "tax.sc_ksef_jpk.cash_over_limit",
	"package": "tax.sc_ksef_jpk",
	"priority": 625,
	"income_tax_qualification": "non_deductible",
	"_routing": "BLOCK_AND_ALERT",
	"_routing_reason": sprintf("[SC] Płatność gotówkowa %.2f PLN > %.0f PLN — NIE stanowi KUP",
		[input.invoice.amount_gross, helpers.sc_threshold_limit("cash_payment_limit_pln", 15000)]),
	"_legal_basis": "Art. 22p PIT (limit płatności gotówkowych)",
	"_warnings": [
		"Płatność gotówkowa powyżej 15 000 PLN — wydatek NIE stanowi kosztu uzyskania przychodu",
		"Art. 22p PIT: obowiązek dokonywania płatności przez rachunek bankowy"
	]
} {
	input.invoice.is_cash_payment == true
	input.invoice.amount_gross > helpers.sc_threshold_limit("cash_payment_limit_pln", 15000)
}

# ═══════════════════════════════════════════════════════════════════════════════
# SKJ-999: sc_ksef_jpk_ok
# ═══════════════════════════════════════════════════════════════════════════════

else := {
	"matched": true,
	"rule_id": "tax.sc_ksef_jpk.all_ok",
	"package": "tax.sc_ksef_jpk",
	"priority": 699,
	"ksef_required": false,
	"whitelist_check_required": false,
	"_routing": "OK",
	"_routing_reason": "[SC] KSeF/JPK — wszystkie kontrole przeszły pomyślnie"
}
