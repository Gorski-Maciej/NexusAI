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
import data.jdg.kks
import data.jdg.routing
import data.jdg.compliance
import data.jdg.crossborder
import data.jdg.vat.substantive
import data.jdg.vat.deductions
import data.jdg.vat.procedures
import data.jdg.pit.forms
import data.jdg.pit.kup
import data.jdg.pit.advances
import data.jdg.pit.exemptions
import data.jdg.pit.transitions
import data.jdg.allowances
import data.jdg.zus
import data.jdg.accounting
import data.jdg.business
import data.jdg.corrections
import data.jdg.conflicts
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
import data.jdg.mpips
import data.jdg.rodo
import data.jdg.validation
import data.jdg.fallback
# ENTERPRISE v4.0 — Strategic Intelligence Packages
import data.jdg.zus.benefits
import data.jdg.local.enterprise
import data.jdg.accounting.pkpir_validation
import data.jdg.strategic
import data.jdg.pit.transition_intel

# ═══════════════════════════════════════════════════════════════════════════════
# Safe Merge helpers (Phase 5 P0 — ochrona niemutowalnych werdyktów ZUS)
#
# Problem: object.union nadpisuje klucze bez ostrzeżenia. Jeśli risk.decide
# (nadrzędny w chainie) ustawi zus_health_rate na "", nadpisze poprawną
# stawkę z pakietu zus (P720/P722/P724).
#
# Rozwiązanie: safe_merge — jeśli pierwszy argument ma immutable_verdict=true,
# jego wartości NIE są nadpisywane przez drugi argument.
# ═══════════════════════════════════════════════════════════════════════════════

# Helper: sprawdza czy werdykt ma flagę immutable_verdict
has_immutable_flag(v) {
    object.get(v, "immutable_verdict", false) == true
}

# safe_merge(a, b): bezpieczny merge dwóch werdyktów.
#
# Trzy przypadki:
# 1. a ma immutable_verdict=true → zwróć a (a chronione przed nadpisaniem przez b)
# 2. b ma immutable_verdict=true → object.union(b, a) (b wygrywa konflikty)
#    Propaguje flagę immutable w górę łańcucha — chroni ZUS przed risk.decide
# 3. ani a ani b nie mają immutable_verdict → object.union(a, b) (a wygrywa,
#    zachowując oryginalną semantykę: zewnętrzny pakiet ma wyższy priorytet)
#
# UWAGA: Przypadek 2 oznacza, że gdy ZUS (z immutable_verdict) jest w łańcuchu,
# jego wartości wygrywają nawet z risk.decide. To zamierzone — ZUS jest
# prawnie niemutowalny. W praktyce risk BLOCK_AND_ALERT zachodzi PRZED
# mergem (PASS 0), więc nie ma konfliktu z routingiem.
safe_merge(a, b) = a {
    has_immutable_flag(a)
}

safe_merge(a, b) = object.union(b, a) {
    has_immutable_flag(b)
}

safe_merge(a, b) = object.union(a, b) {
    not has_immutable_flag(a)
    not has_immutable_flag(b)
}

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
#
# Phase 5 P0: Używamy safe_merge zamiast object.union, aby chronić
# niemutowalne werdykty ZUS (P720/P722/P724) przed nadpisaniem przez
# risk.decide lub inne pakiety z wyższym priorytetem.
#
# Kolejność (od najniższego priorytetu wewnątrz do najwyższego na zewnątrz):
 # fallback → retention → digital → temporal → restructuring → environmental →
# employer → international → ksef_jpk → local_taxes → representation →
# liability → corrections → business → accounting → zus → allowances →
# transitions → exemptions → advances_returns → kup → forms → procedures →
# deductions → substantive → crossborder → compliance → routing → kks → risk
##    safe_merge chroni werdykty z flagą immutable_verdict=true
# (ZUS P720/P722/P724, business P914) przed przypadkowym nadpisaniem.
#
# PAS 8: conflicts pakiet działa POST-MERGE — analizuje input.invoice oraz
# input.jdg_entrepreneur (dane źródłowe) i wykrywa konflikty między domenami
# (IP Box vs B+R, reprezentacja vs marketing, auto VAT vs KUP, bad debt timing).
# NIE zmienia wartości — tylko flaguje do _cross_domain_conflicts.
final_verdict = safe_merge(risk.decide,
    safe_merge(kks.decide,
    safe_merge(routing.decide,
    safe_merge(compliance.decide,
    safe_merge(crossborder.decide,
    safe_merge(substantive.decide,
    safe_merge(deductions.decide,
    safe_merge(procedures.decide,
    safe_merge(forms.decide,
    safe_merge(kup.decide,
    safe_merge(advances.decide,
    safe_merge(exemptions.decide,
    safe_merge(transitions.decide,
    safe_merge(transition_intel.decide,
    safe_merge(allowances.decide,
    safe_merge(zus.decide,
    safe_merge(benefits.decide,
    safe_merge(accounting.decide,
    safe_merge(pkpir_validation.decide,
    safe_merge(business.decide,
    safe_merge(strategic.decide,
    safe_merge(corrections.decide,
    safe_merge(liability.decide,
    safe_merge(representation.decide,
    safe_merge(local_taxes.decide,
    safe_merge(enterprise.decide,
    safe_merge(ksef_jpk.decide,
    safe_merge(international.decide,
    safe_merge(employer.decide,
    safe_merge(environmental.decide,
    safe_merge(restructuring.decide,
    safe_merge(temporal.decide,
    safe_merge(digital.decide,
    safe_merge(retention.decide,
    safe_merge(rodo.decide,
    safe_merge(mpips.decide,
    safe_merge(validation.decide,
        fallback.decide
    ))))))))))))))))))))))))))))))))))))))))))

# ── PAS 8: Cross-Domain Conflict Detection (Post-Merge) ────────────────────
# conflicts.decide analizuje już scalony final_verdict i wykrywa
# konflikty między domenami (np. IP Box vs B+R na tym samym dochodzie,
# reprezentacja vs marketing, auto VAT 50% vs KUP 75%).
# Wynik jest dołączany do final_verdict przez object.union — pole
# _cross_domain_conflicts jest tylko do odczytu, nie zmienia decyzji.
final_verdict_with_conflicts = object.union(final_verdict, conflicts.decide)