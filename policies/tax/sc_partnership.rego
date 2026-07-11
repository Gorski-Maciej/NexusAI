# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI SC — Partnership Lifecycle Rules (Spółka Cywilna)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Reguły cyklu życia spółki cywilnej: powstanie, zmiany składu,
# rozwiązanie, likwidacja, sukcesja, zawieszenie.
# Implementuje reguły z GR-330 do GR-493 z planu 37_ULTIMATE_GRANULARITY.
#
# package: tax.sc_partnership
# rule:     decide (first-match-wins else chain)
# ═══════════════════════════════════════════════════════════════════════════════

package tax.sc_partnership

import data.tax.helpers_sc
import data.tax.helpers as helpers

# ── Default ───────────────────────────────────────────────────────────────────
default decide := {
	"matched": false,
	"rule_id": "tax.sc_partnership.no_match",
	"package": "tax.sc_partnership",
	"priority": 330
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCP-001: sc_formation_contract_written
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Umowa SC wymaga formy pisemnej dla celów dowodowych (Art. 860 KC)

decide := {
	"matched": true,
	"rule_id": "tax.sc_partnership.formation_verbal",
	"package": "tax.sc_partnership",
	"priority": 330,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Umowa ustna — ograniczona zdolność dowodowa. Zalecana forma pisemna.",
	"_legal_basis": "Art. 860 § 1 KC",
	"_warnings": ["Umowa SC ustna — forma pisemna zalecana dla celów dowodowych"]
} {
	input.partnership.formation_document == "VERBAL"
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCP-002: sc_partner_addition_requires_all_consent
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Przyjęcie nowego wspólnika wymaga zgody wszystkich istniejących (Art. 860 § 2 KC)

else := {
	"matched": true,
	"rule_id": "tax.sc_partnership.partner_addition_no_consent",
	"package": "tax.sc_partnership",
	"priority": 340,
	"_routing": "BLOCK_AND_ALERT",
	"_routing_reason": "[SC] Próba dodania wspólnika bez zgody wszystkich — operacja zablokowana",
	"_legal_basis": "Art. 860 § 2 KC (zmiana umowy SC wymaga zgody wszystkich)",
	"_warnings": ["Nowy wspólnik wymaga zgody 100% dotychczasowych wspólników"]
} {
	input.partnership.pending_partner_addition
	object.get(input.partnership, "all_partners_consented_to_addition", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCP-003: sc_partner_share_change
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Zmiana udziałów wymaga aneksu do umowy (Art. 860 § 2 KC)

else := {
	"matched": true,
	"rule_id": "tax.sc_partnership.share_change_no_annex",
	"package": "tax.sc_partnership",
	"priority": 345,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Zmiana udziałów bez aneksu — weryfikuj podstawę zmiany",
	"_legal_basis": "Art. 860 § 2 KC (zmiana umowy wymaga zgody wszystkich)",
	"_warnings": ["Zmiana udziałów bez formalnego aneksu do umowy SC"]
} {
	input.partnership.share_change_pending
	object.get(input.partnership, "share_change_annex", false) == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCP-010: sc_dissolution_all_agree
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Rozwiązanie SC wymaga zgody wszystkich wspólników (Art. 874 KC)

else := {
	"matched": true,
	"rule_id": "tax.sc_partnership.dissolution_all_agree",
	"package": "tax.sc_partnership",
	"priority": 385,
	"_routing": "OK",
	"_routing_reason": "[SC] Rozwiązanie SC za zgodą wszystkich wspólników",
	"_legal_basis": "Art. 874 KC",
	"_warnings": ["Rozwiązanie SC — podział majątku, odpowiedzialność solidarna trwa"]
} {
	helpers_sc.partnership_dissolved
	object.get(input.partnership, "all_partners_agreed_to_dissolve", false)
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCP-020: sc_succession_partner_death
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Śmierć wspólnika → sukcesja spadkobierców (Art. 872 KC + Art. 97 Ordynacji)

else := {
	"matched": true,
	"rule_id": "tax.sc_partnership.succession_death",
	"package": "tax.sc_partnership",
	"priority": 400,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Sukcesja po śmierci wspólnika — spadkobiercy wchodzą w prawa i obowiązki",
	"_legal_basis": "Art. 872 KC, Art. 97 § 1 Ordynacji podatkowej",
	"_warnings": [
		"Śmierć wspólnika — spadkobiercy odpowiadają za zobowiązania do wartości spadku",
		"Spółka może trwać z pozostałymi wspólnikami (jeśli umowa tak stanowi)"
	]
} {
	helpers_sc.partnership_in_succession
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCP-030: sc_suspension_max_months
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Zawieszenie SC max 24 miesiące

else := {
	"matched": true,
	"rule_id": "tax.sc_partnership.suspension_over_24m",
	"package": "tax.sc_partnership",
	"priority": 420,
	"_routing": "BLOCK_AND_ALERT",
	"_routing_reason": sprintf("[SC] Zawieszenie przekracza %d miesięcy — wymagane wznowienie lub rozwiązanie",
		[object.get(helpers.sc_threshold_limit("suspension_max_months", 24), "", 24)]),
	"_legal_basis": "Art. 22 Prawo przedsiębiorców",
	"_warnings": ["Zawieszenie SC max 24 miesiące — po tym terminie obowiązek wznowienia lub rozwiązania"]
} {
	helpers_sc.partnership_suspended
	object.get(input.partnership, "suspension_months", 0) > helpers.sc_threshold_limit("suspension_max_months", 24)
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCP-040: sc_post_dissolution_liability
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Po rozwiązaniu SC wspólnicy nadal odpowiadają solidarnie (Art. 875 KC)

else := {
	"matched": true,
	"rule_id": "tax.sc_partnership.post_dissolution_liability",
	"package": "tax.sc_partnership",
	"priority": 430,
	"joint_liability_active": true,
	"joint_liability_total": helpers_sc.joint_liability_total,
	"liable_partners": helpers_sc.liable_partner_nips,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Odpowiedzialność solidarna po rozwiązaniu SC — Art. 875 KC",
	"_legal_basis": "Art. 875 § 2 KC (odpowiedzialność za zobowiązania istniejące przed rozwiązaniem)",
	"_warnings": [
		"Art. 875 KC: Po rozwiązaniu SC wspólnicy odpowiadają solidarnie za długi istniejące przed rozwiązaniem",
		"Wierzyciele mogą dochodzić roszczeń od każdego byłego wspólnika osobno lub od wszystkich łącznie"
	]
} {
	helpers_sc.partnership_dissolved
	helpers_sc.joint_liability_total > 0
}
