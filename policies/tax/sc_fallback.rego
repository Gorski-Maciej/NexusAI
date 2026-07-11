# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI SC Policies — SC-Specific Fallback (Spółka Cywilna)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: SC Package — sc_fallback
# description: SC-specific fallback z kompletnym kontekstem spółki cywilnej.
#   Zawsze zwraca werdykt — gwarantuje że każda faktura SC otrzyma decyzję.
#   Rozszerza tax.fallback o: partner tax forms, joint liability, VAT status SC.
# architecture: Multi-Pass (ADR-001) — ostatni pass przed final_verdict
# package: tax.sc_fallback
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package tax.sc_fallback

import data.tax.helpers_sc
import data.tax.helpers as helpers

# ── Default: no match yet ─────────────────────────────────────────────────────
default decide := {
	"matched": false,
	"rule_id": "tax.sc_fallback.no_match_init",
	"package": "tax.sc_fallback",
	"priority": 900
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCF-100: sc_domestic_fallback — domyślna stawka VAT 23% dla PL
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: Domyślna stawka VAT dla SC gdy kraj = PL i żadna konkretna reguła nie pasuje
# Przesłanki: vendor.country == PL, SC jest czynnym podatnikiem VAT
# Podstawa prawna: Art. 41 ust. 1 VAT

decide := {
	"matched": true,
	"rule_id": "tax.sc_fallback.domestic_sc",
	"package": "tax.sc_fallback",
	"priority": 900,
	"vat_rate": "0.23",
	"rounding_level": "position",
	"gtu_code": "",
	"procedure": "",
	"vat_exemption": "",
	"income_tax_qualification": "deductible_full",
	"partner_tax_forms": helpers_sc.partner_tax_forms,
	"joint_liability_active": true,
	"partnership_risk_score": helpers_sc.partnership_risk_score,
	"_routing": "",
	"_routing_reason": "[SC] Domyślna stawka VAT 23% PL — żadna szczegółowa reguła nie pasuje",
	"_legal_basis": "Art. 41 ust. 1 VAT, Art. 8 PIT (podział proporcjonalny wspólników)",
	"_warnings": []
} {
	input.vendor.country == "PL"
	helpers_sc.sc_is_vat_payer
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCF-200: sc_vat_exempt_fallback — SC zwolniona z VAT
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: SC zwolniona z VAT → stawka ZW, ale nadal musi rozliczać PIT wspólników
# Przesłanki: vendor.country == PL, SC zwolniona z VAT

else := {
	"matched": true,
	"rule_id": "tax.sc_fallback.vat_exempt_sc",
	"package": "tax.sc_fallback",
	"priority": 901,
	"vat_rate": "ZW",
	"vat_exemption": "EXEMPT",
	"vat_exemption_reason": object.get(input.partnership, "vat_exemption_reason", "Zwolnienie podmiotowe Art. 113 VAT"),
	"rounding_level": "position",
	"gtu_code": "",
	"procedure": "",
	"income_tax_qualification": "deductible_full",
	"partner_tax_forms": helpers_sc.partner_tax_forms,
	"joint_liability_active": true,
	"_routing": "",
	"_routing_reason": "[SC] SC zwolniona z VAT — stawka ZW, PIT wspólników bez zmian",
	"_legal_basis": "Art. 113 VAT (zwolnienie podmiotowe), Art. 8 PIT",
	"_warnings": ["SC zwolniona z VAT — brak prawa do odliczenia VAT naliczonego"]
} {
	input.vendor.country == "PL"
	not helpers_sc.sc_is_vat_payer
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCF-300: sc_dissolved_fallback — SC w likwidacji
# ═══════════════════════════════════════════════════════════════════════════════
# Cel: SC rozwiązana/w likwidacji — nadal odpowiada solidarnie za zobowiązania

else := {
	"matched": true,
	"rule_id": "tax.sc_fallback.dissolved_sc",
	"package": "tax.sc_fallback",
	"priority": 910,
	"vat_rate": "0.23",
	"rounding_level": "position",
	"gtu_code": "",
	"procedure": "",
	"income_tax_qualification": "deductible_full",
	"partnership_status": "DISSOLVED",
	"joint_liability_active": true,
	"joint_liability_total": helpers_sc.joint_liability_total,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Spółka w likwidacji — odpowiedzialność solidarna nadal obowiązuje",
	"_legal_basis": "Art. 875 KC (odpowiedzialność po rozwiązaniu SC)",
	"_warnings": [
		"SC W LIKWIDACJI: Odpowiedzialność solidarna wspólników trwa do całkowitego zaspokojenia wierzycieli",
		"Art. 875 § 2 KC: Każdy wspólnik odpowiada za zobowiązania istniejące przed rozwiązaniem"
	]
} {
	helpers_sc.partnership_dissolved
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCF-400: sc_suspended_fallback — SC zawieszona
# ═══════════════════════════════════════════════════════════════════════════════

else := {
	"matched": true,
	"rule_id": "tax.sc_fallback.suspended_sc",
	"package": "tax.sc_fallback",
	"priority": 911,
	"vat_rate": "0.23",
	"rounding_level": "position",
	"gtu_code": "",
	"procedure": "",
	"income_tax_qualification": "deductible_full",
	"partnership_status": "SUSPENDED",
	"joint_liability_active": true,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Spółka zawieszona — faktury w okresie zawieszenia podlegają dodatkowej weryfikacji",
	"_legal_basis": "Art. 22 UoR, Art. 864 KC",
	"_warnings": ["SC zawieszona — weryfikuj czy faktura nie dotyczy okresu sprzed zawieszenia"]
} {
	helpers_sc.partnership_suspended
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCF-500: sc_succession_fallback — SC w trakcie sukcesji (śmierć wspólnika)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
	"matched": true,
	"rule_id": "tax.sc_fallback.succession_sc",
	"package": "tax.sc_fallback",
	"priority": 912,
	"vat_rate": "0.23",
	"rounding_level": "position",
	"gtu_code": "",
	"procedure": "",
	"income_tax_qualification": "deductible_full",
	"partnership_status": "SUCCESSION",
	"succession_active": true,
	"joint_liability_active": true,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] Sukcesja w toku — śmierć wspólnika, spadkobiercy wchodzą w prawa i obowiązki",
	"_legal_basis": "Art. 872 KC (śmierć wspólnika), Art. 97 Ordynacji podatkowej (sukcesja podatkowa)",
	"_warnings": [
		"SUKCESJA: Spadkobiercy wchodzą w prawa i obowiązki zmarłego wspólnika",
		"Art. 872 KC: Spółka może trwać z pozostałymi wspólnikami lub zakończyć działalność"
	]
} {
	helpers_sc.partnership_in_succession
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCF-999: sc_no_match — Ostateczny fallback SC (zawsze pasuje)
# ═══════════════════════════════════════════════════════════════════════════════

else := {
	"matched": true,
	"rule_id": "tax.sc_fallback.no_match_sc",
	"package": "tax.sc_fallback",
	"priority": 999,
	"vat_rate": helpers.get_rate("vat_standard", "0.23"),
	"rounding_level": "position",
	"gtu_code": "",
	"procedure": "",
	"income_tax_qualification": "deductible_full",
	"entity_type": "SPOLKA_CYWILNA",
	"partnership_nip": input.partnership.nip,
	"partner_count": helpers_sc.partner_count,
	"partner_tax_forms": helpers_sc.partner_tax_forms,
	"joint_liability_total": helpers_sc.joint_liability_total,
	"liable_partners": helpers_sc.liable_partner_nips,
	"_routing": "TRIAGE_QUEUE",
	"_routing_reason": "[SC] NO_MATCHING_RULE — żadna reguła SC nie dopasowana. Zastosowano domyślne założenia.",
	"_legal_basis": "Fallback — domyślne założenia systemowe dla Spółki Cywilnej",
	"_warnings": [
		"NO_MATCHING_RULE — brak dopasowania żadnej reguły SC",
		"VAT: domyślnie 23%",
		"PIT: podział proporcjonalny Art. 8 PIT",
		"Odpowiedzialność: solidarna Art. 864 KC"
	]
} {
	true
}
