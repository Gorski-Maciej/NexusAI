# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI SC — Main Orchestrator (Multi-Pass First-Match-Wins)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: SC Main Orchestrator — Multi-Pass Evaluation Engine for Spółka Cywilna
# description: |
#   Główny plik decyzyjny dla Spółki Cywilnej. Orkiestruje ewaluację wszystkich
#   22+ pakietów w architekturze Multi-Pass.
#   KLUCZOWA RÓŻNICA vs JDG: VAT jest spółki (pojedyncza decyzja), PIT jest
#   wspólników (per-partner decyzje). Odpowiedzialność solidarna (Art. 864 KC).
# architecture: Multi-Pass OPA (ADR-001)
# legal_basis: N/A (orchestrator — nie zawiera reguł podatkowych)
# edge_cases:
#   - Jeśli RISK lub ROUTING zwrócą BLOCK_AND_ALERT, dalsze passy abortowane
#   - object.union nadpisuje klucze bez ostrzeżenia — kolejność mergowania jest krytyczna
#   - PartnerMirror dzieli werdykt na private + risk_mirror per RODO
# priority: N/A (orchestrator)
# package: tax.main_sc
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package tax.main_sc

import data.tax.risk
import data.tax.routing
import data.tax.compliance
import data.tax.crossborder
import data.tax.temporal
import data.tax.vat.substantive
import data.tax.vat.deductions
import data.tax.vat.procedures
import data.tax.anomaly
import data.tax.partner_mirror
import data.tax.what_if
import data.tax.sc_fallback
import data.tax.helpers_sc

# ═══════════════════════════════════════════════════════════════════════════════
# Multi-Pass Architecture for Spółka Cywilna
#
# INPUT ──► PASS 0: RISK ───────► PASS 1: ROUTING ────► PASS 2: COMPLIANCE ──►
#              │ (BLOCK→abort)      │ (BLOCK→abort)       │
#              ▼                    ▼                     ▼
#         risk_verdict          routing_verdict       compliance_verdict
#
#         PASS 3: CROSSBORDER ─► PASS 4: TEMPORAL ────► PASS 5: VAT (spółka) ─►
#              │                    │                      │
#              ▼                    ▼                      ▼
#         cross_verdict         temporal_verdict       vat_verdict
#
#         PASS 6: ANOMALY ─────► PASS 7: PARTNER_MIRROR ► PASS 8: WHAT_IF ────►
#              │                    │                      │
#              ▼                    ▼                      ▼
#         anomaly_verdict       mirror_verdict         simulation_verdict
#
#         PASS 9: SC_FALLBACK ─► FINAL_VERDICT
#              │
#              ▼
#         sc_fallback_verdict
#
# ► VERDICT MERGER ──► final_sc_verdict
# ═══════════════════════════════════════════════════════════════════════════════

# ── Merged Final Verdict ──────────────────────────────────────────────────────
# Scala wszystkie pass-y w jeden finalny werdykt SC.
# Kolejność: najniższy priorytet wewnątrz, najwyższy na zewnątrz (overrides).
# Ostatni w łańcuchu = sc_fallback (zawsze pasuje, gwarantuje werdykt).
final_sc_verdict = object.union(risk.decide,
    object.union(routing.decide,
    object.union(compliance.decide,
    object.union(crossborder.decide,
    object.union(temporal.decide,
    object.union(substantive.decide,
    object.union(deductions.decide,
    object.union(procedures.decide,
    object.union(anomaly.decide,
    object.union(partner_mirror.decide,
    object.union(what_if.decide,
        sc_fallback.decide
    )))))))))))
)

# ── SC-Specific Context Inject ────────────────────────────────────────────────
# Dodaje kontekst spółki cywilnej do werdyktu: partnerzy, joint liability, etc.

sc_context := ctx {
	ctx := {
		"entity_type": "SPOLKA_CYWILNA",
		"partnership_nip": input.partnership.nip,
		"partnership_status": input.partnership.status,
		"partner_count": helpers_sc.partner_count,
		"partner_ids": [p.id | p := input.partners[_]],
		"partner_tax_forms": helpers_sc.partner_tax_forms,
		"joint_liability_total": helpers_sc.joint_liability_total,
		"liable_partners": helpers_sc.liable_partner_nips,
		"partnership_risk_score": helpers_sc.partnership_risk_score,
		"has_partner_zus_overdue": helpers_sc.any_partner_zus_overdue,
		"has_partner_tax_overdue": helpers_sc.any_partner_tax_overdue,
		"sc_is_vat_payer": helpers_sc.sc_is_vat_payer,
		"sc_accounting_method": input.partnership.accounting_method,
		"evaluation_timestamp": time.now_ns()
	}
}

# ── Complete Verdict with SC Context ──────────────────────────────────────────
# Łączy merged verdict + SC-specific context
complete_verdict := object.union(final_sc_verdict, sc_context)

# ── Routing-Based Abort Detection ─────────────────────────────────────────────
# Wykrywa czy którykolwiek z wczesnych passów zablokował przetwarzanie

evaluation_blocked {
	final_sc_verdict._routing == "BLOCK_AND_ALERT"
}

evaluation_triage {
	final_sc_verdict._routing == "TRIAGE_QUEUE"
}

evaluation_ok {
	not evaluation_blocked
	not evaluation_triage
}

# ── Evaluation Summary ────────────────────────────────────────────────────────
# Podsumowanie przebiegu ewaluacji dla audytu

evaluation_summary := summary {
	summary := {
		"entity_type": "SPOLKA_CYWILNA",
		"passes_executed": [
			"risk", "routing", "compliance", "crossborder",
			"temporal", "vat_substantive", "vat_deductions", "vat_procedures",
			"anomaly", "partner_mirror", "what_if", "sc_fallback"
		],
		"status": status,
		"matched_rule": object.get(final_sc_verdict, "rule_id", "UNKNOWN"),
		"matched_package": object.get(final_sc_verdict, "package", "UNKNOWN"),
		"partners_evaluated": helpers_sc.partner_count,
		"joint_liability_exposure": helpers_sc.joint_liability_total,
		"risk_score": helpers_sc.partnership_risk_score
	}
}

status := "BLOCKED" { evaluation_blocked }
status := "TRIAGE" { evaluation_triage }
status := "OK" { evaluation_ok }
