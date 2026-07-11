# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI SC — Joint Liability Enforcement Rules (Spółka Cywilna)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły odpowiedzialności solidarnej SC: Art. 864 KC, regres między
# wspólnikami (Art. 376 KC), egzekucja, podział odpowiedzialności.
#
# package: tax.sc_liability
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.sc_liability

import data.tax.helpers_sc
import data.tax.helpers as helpers

# ── Default ───────────────────────────────────────────────────────────────────
default decide := {
	"matched": false,
	"rule_id": "tax.sc_liability.no_match",
	"package": "tax.sc_liability",
	"priority": 500
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCL-001: sc_joint_liability_all_partners
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Wszyscy wspólnicy odpowiadają solidarnie całym swoim majątkiem (Art. 864 KC)

decide := {
	"matched": true,
	"rule_id": "tax.sc_liability.joint_all",
	"package": "tax.sc_liability",
	"priority": 500,
	"joint_liability": true,
	"liability_type": "SOLIDARNA_864_KC",
	"liable_partners": helpers_sc.liable_partner_nips,
	"joint_liability_total": helpers_sc.joint_liability_total,
	"per_partner_exposure": helpers_sc.joint_liability_total / helpers_sc.partner_count,
	"_routing": "OK",
	"_routing_reason": sprintf("[SC] Odpowiedzialność solidarna: %d wspólników, łącznie %.2f PLN",
		[helpers_sc.partner_count, helpers_sc.joint_liability_total]),
	"_legal_basis": "Art. 864 KC (odpowiedzialność solidarna wspólników SC)",
	"_warnings": [] | _add_warnings
} {
	helpers_sc.joint_liability_total > 0
}

_add_warnings := [w |
	helpers_sc.any_partner_zus_overdue
	w := "UWAGA: Zaległości ZUS wspólnika — ryzyko egzekucji z majątku wszystkich wspólników"
]

# ═══════════════════════════════════════════════════════════════════════════════
# SCL-002: sc_regress_right
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Wspólnik który spłacił dług SC ma roszczenie regresowe do pozostałych
#      proporcjonalnie do ich udziałów (Art. 376 KC)

else := {
	"matched": true,
	"rule_id": "tax.sc_liability.regress_right",
	"package": "tax.sc_liability",
	"priority": 510,
	"regress_active": true,
	"regress_basis": "PROPORTIONAL_TO_SHARES",
	"regress_details": _regress_per_partner,
	"_routing": "OK",
	"_routing_reason": "[SC] Roszczenie regresowe — wspólnik który spłacił ma prawo żądać zwrotu od pozostałych",
	"_legal_basis": "Art. 376 KC (regres między dłużnikami solidarnymi) + Art. 864 KC",
	"_warnings": [
		"Art. 376 KC: Wspólnik który spłacił dług SC może żądać zwrotu od pozostałych",
		"Zwrot proporcjonalny do udziałów w SC"
	]
} {
	object.get(input.partnership, "regress_claim_active", false)
}

_regress_per_partner := per_partner {
	total := object.get(input.partnership, "regress_amount", 0)
	total > 0
	per_partner := {
		p.id: {
			"share_percent": p.share_percent,
			"amount_owed": total * (p.share_percent / 100)
		}
		| p := input.partners[_]
		p.id != input.partnership.regress_claimant_id
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCL-003: sc_creditor_enforcement
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Wierzyciel SC może egzekwować dług od dowolnego wspólnika
#      (lub od wszystkich) — Art. 366 KC w zw. z Art. 864 KC

else := {
	"matched": true,
	"rule_id": "tax.sc_liability.creditor_enforcement",
	"package": "tax.sc_liability",
	"priority": 520,
	"enforcement_rights": "ANY_PARTNER_OR_ALL",
	"joint_liability_total": helpers_sc.joint_liability_total,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Wierzyciel może egzekwować dług od KAŻDEGO wspólnika z osobna lub WSZYSTKICH łącznie",
	"_legal_basis": "Art. 366 KC (solidarność bierna) + Art. 864 KC",
	"_warnings": [
		"WIERZYCIEL MOŻE EGZEKWOWAĆ DŁUG OD DOWOLNEGO WSPÓLNIKA",
		"Art. 366 KC: aż do zupełnego zaspokojenia wierzyciela"
	]
} {
	helpers_sc.joint_liability_total > 0
	object.get(input.partnership, "creditor_enforcement_active", false)
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCL-004: sc_spouse_liability_limit
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Małżonek wspólnika NIE odpowiada za długi SC z majątku osobistego
#      (tylko z majątku wspólnego jeśli wyraził zgodę)

else := {
	"matched": true,
	"rule_id": "tax.sc_liability.spouse_limited",
	"package": "tax.sc_liability",
	"priority": 530,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Odpowiedzialność małżonka — tylko majątek wspólny + zgoda na prowadzenie SC",
	"_legal_basis": "Art. 41 KRO (odpowiedzialność małżonka), Art. 864 KC",
	"_warnings": [
		"Małżonek wspólnika odpowiada TYLKO z majątku wspólnego i TYLKO jeśli wyraził zgodę",
		"Majątek osobisty małżonka NIE podlega egzekucji za długi SC"
	]
} {
	helpers_sc.joint_liability_total > 0
	object.get(input.partnership, "spouse_consent_for_sc", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCL-005: sc_no_liability_exposure
# ═══════════════════════════════════════════════════════════════════════════════

else := {
	"matched": true,
	"rule_id": "tax.sc_liability.no_exposure",
	"package": "tax.sc_liability",
	"priority": 599,
	"joint_liability": false,
	"joint_liability_total": 0,
	"_routing": "OK",
	"_routing_reason": "[SC] Brak zobowiązań solidarnych — SC bez długów publicznoprawnych",
	"_legal_basis": "Art. 864 KC (brak zobowiązań = brak odpowiedzialności)",
	"_warnings": []
} {
	helpers_sc.joint_liability_total == 0
}
