# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Main Orchestrator (Multi-Pass First-Match-Wins)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Main Orchestrator — Multi-Pass Evaluation Engine
# description: |
#   Główny plik decyzyjny JDG. Orkiestruje ewaluację wszystkich 29 pakietów
#   w architekturze Multi-Pass zgodnej z Doc 34, Sekcja 1.3.
#   30 pakietów = 29 plików reguł + ten główny orchestrator.
#   Używa object.union() do scalania werdyktów z kolejnością: najniższy
#   priorytet wewnątrz, najwyższy na zewnątrz (overrides).
# architecture: Multi-Pass OPA (ADR-001)
# legal_basis: N/A (orchestrator — nie zawiera reguł podatkowych)
# edge_cases:
#   - Jeśli RISK lub ROUTING zwrócą BLOCK_AND_ALERT, dalsze passy abortowane
#   - object.union nadpisuje klucze bez ostrzeżenia — kolejność mergowania jest krytyczna
# priority: N/A (orchestrator)
# package: jdg.main
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.main

import data.jdg.risk
import data.jdg.routing
import data.jdg.compliance
import data.jdg.crossborder
import data.jdg.vat.substantive
import data.jdg.vat.deductions
import data.jdg.vat.procedures
import data.jdg.pit.forms
import data.jdg.pit.kup
import data.jdg.pit.advances_returns
import data.jdg.pit.exemptions
import data.jdg.pit.transitions
import data.jdg.allowances
import data.jdg.zus
import data.jdg.accounting
import data.jdg.business
import data.jdg.corrections
import data.jdg.liability
import data.jdg.representation
import data.jdg.local_taxes
import data.jdg.ksef_jpk
import data.jdg.international
import data.jdg.employer
import data.jdg.environmental
import data.jdg.restructuring
import data.jdg.temporal
import data.jdg.digital
import data.jdg.retention
import data.jdg.fallback

# ═══════════════════════════════════════════════════════════════════════════════
# Multi-Pass Architecture (zgodna z Doc 34, Sekcja 1.3)
#
# INPUT ──► PASS 0: RISK ──────► PASS 1: ROUTING ──► PASS 2: COMPLIANCE ──────►
#              │ (BLOCK→abort)      │ (BLOCK→abort)     │
#              ▼                    ▼                   ▼
#         risk_verdict        routing_verdict     compliance_verdict
#
#         PASS 3: CROSSBORDER ──► PASS 4: VAT ──────► PASS 5: PIT ───────────►
#              │                    │                    │
#              ▼                    ▼                    ▼
#         cross_verdict        vat_verdict          pit_verdict
#
#         PASS 6: ALLOWANCES ──► PASS 7: ACCOUNTING ─► PASS 8: ZUS+BUSINESS+ ─►
#              │                    │                    │
#              ▼                    ▼                    ▼
#         allowances_verdict  accounting_verdict    misc_verdict
#
#         ► VERDICT MERGER ──► final_verdict
# ═══════════════════════════════════════════════════════════════════════════════

# ── Merged Final Verdict ──────────────────────────────────────────────────────
# Scala wszystkie pass-y w jeden finalny werdykt JDG.
# object.union przyjmuje 2 argumenty — używamy zagnieżdżonych wywołań.
# Kolejność: najniższy priorytet wewnątrz, najwyższy na zewnątrz (overrides).
final_verdict = object.union(risk.decide,
    object.union(routing.decide,
    object.union(compliance.decide,
    object.union(crossborder.decide,
    object.union(substantive.decide,
    object.union(deductions.decide,
    object.union(procedures.decide,
    object.union(forms.decide,
    object.union(kup.decide,
    object.union(advances_returns.decide,
    object.union(exemptions.decide,
    object.union(transitions.decide,
    object.union(allowances.decide,
    object.union(zus.decide,
    object.union(accounting.decide,
    object.union(business.decide,
    object.union(corrections.decide,
    object.union(liability.decide,
    object.union(representation.decide,
    object.union(local_taxes.decide,
    object.union(ksef_jpk.decide,
    object.union(international.decide,
    object.union(employer.decide,
    object.union(environmental.decide,
    object.union(restructuring.decide,
    object.union(temporal.decide,
    object.union(digital.decide,
    object.union(retention.decide,
        fallback.decide
    ))))))))))))))))))))))))))))))
)
