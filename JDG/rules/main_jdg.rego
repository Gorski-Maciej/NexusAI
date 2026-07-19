# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Main Orchestrator (Multi-Pass First-Match-Wins + Sharded Router)
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Main Orchestrator — Multi-Pass + Sharded Router (B1 Strategic Initiative)
# description: |
#   Główny plik decyzyjny JDG. Orkiestruje ewaluację wszystkich 40 pakietów
#   w architekturze Multi-Pass zgodnej z Doc 34, Sekcja 1.3.
#   B1: Sharded Index Router — hash kontekstu (tax_form × transaction_type ×
#   entity_flags × evaluation_date) → dynamiczny routing do specjalizowanych
#   ścieżek ewaluacji. Redukuje złożoność z O(N) do O(1).
#   Dodano 6 pakietów Klasy C (2026-07-16): mdr, tp, solidarity, edelivery, audit, residency.
#   Dodano 9 pakietów Enterprise: pkpir, depreciation, pcc, art21, sickness,
#   bdo, aml, rodo_extended, mdr_enterprise (2026-07-17).
#   Dodano 5 pakietów S1-S5 Enterprise v5.0 (2026-07-18): tax_optimization,
#   cross_domain_hub, judicial_rulings, audit_defense, strategic_advisor.
#   Dodano 5 pakietów S6-S10 Enterprise v5.1 (2026-07-18): ksef_resilience,
#   ppk_pfron, cashflow_predictor, form_transition, banking.
#   Rozbudowano banking_automation o PSD2/PolishAPI v3.x (2026-07-18):
#   AIS, PIS, OAuth2/eIDAS, Elixir/ExpressElixir, multi-bank profiles,
#   payment status tracking, batch payments XML/JSON, PSD2 audit trail.
#   Dodano 3 pakiety S11-S13 Enterprise v5.2 (2026-07-18):
#   annual_declaration (PIT-36/36L/28 auto-fill, advance reconciliation,
#   joint filing optimization, relief cross-validation),
#   jpk_v7_autogen (JPK_V7M sales/purchase registers, VAT-7 declaration,
#   GTU code auto-assignment, cross-check validation, KSeF extraction),
#   legislative_monitor (change detection, impact analysis, transitional
#   provisions, compliance calendar, rule versioning & temporal validity).
#   Dodano 3 pakiety S14-S16 Enterprise v6.0 (2026-07-19):
#   neural_mesh (Neural Rule Mesh — 13-domain cross-intelligence fabric,
#   synaptic rules connecting VAT×PIT×ZUS×KKS×OrdPU×PCC×UoR, global
#   deadline orchestrator, predictive audit risk engine 12-factor,
#   auto-healing correction pattern detector, global compliance scorecard),
#   nkup_enterprise (Art. 23 PIT complete — 57 NKUP categories: representation
#   detailed matrix, car expenses 75%/150k/225k limits, family wages,
#   donations, thin capitalization, enforcement costs, provisions),
#   exit_tax_mdr (Exit Tax Art. 30da + CFC Art. 30f + MDR/DAC6 + Transfer
#   Pricing + Estoński CIT analysis + Double Tax Treaty Analyzer).
#   Używa safe_merge() do scalania werdyktów z kolejnością: najniższy
#   priorytet wewnątrz, najwyższy na zewnątrz (overrides).
# architecture: Multi-Pass OPA (ADR-001) + Sharded Router (B1)
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
import data.jdg.kks.enterprise_penalties
import data.jdg.routing
import data.jdg.compliance
import data.jdg.compliance.aml
import data.jdg.crossborder
import data.jdg.crossborder.post_brexit
import data.jdg.vat.substantive
import data.jdg.vat.deductions
import data.jdg.vat.procedures
import data.jdg.pit.forms
import data.jdg.pit.kup
import data.jdg.pit.advances_returns
import data.jdg.pit.exemptions
import data.jdg.pit.art21_exemptions
import data.jdg.pit.transitions
import data.jdg.pit.elearning
import data.jdg.allowances
import data.jdg.zus
import data.jdg.zus.sickness_benefits
import data.jdg.zus.health_contribution
import data.jdg.mdr
import data.jdg.mdr.enterprise
import data.jdg.tp
import data.jdg.solidarity
import data.jdg.edelivery
import data.jdg.audit
import data.jdg.residency
import data.jdg.accounting
import data.jdg.accounting.pkpir
import data.jdg.accounting.pkpir_validation
import data.jdg.accounting.depreciation
import data.jdg.business
import data.jdg.business.gig_economy
import data.jdg.corrections
import data.jdg.conflicts
import data.jdg.liability
import data.jdg.representation
import data.jdg.local_taxes
import data.jdg.local_taxes.pcc_enterprise
import data.jdg.ksef_jpk
import data.jdg.international
import data.jdg.employer
import data.jdg.environmental
import data.jdg.environmental.bdo
import data.jdg.restructuring
import data.jdg.temporal
import data.jdg.digital
import data.jdg.api_fallback
import data.jdg.retention
import data.jdg.mpips
import data.jdg.rodo
import data.jdg.rodo_extended
import data.jdg.validation
import data.jdg.fallback
import data.jdg.metadata
import data.jdg.tax_optimization
import data.jdg.cross_domain_hub
import data.jdg.judicial_rulings
import data.jdg.audit_defense
import data.jdg.strategic_advisor
import data.jdg.ksef_resilience
import data.jdg.ppk_pfron
import data.jdg.cashflow_predictor
import data.jdg.form_transition
import data.jdg.banking
import data.jdg.annual_declaration
import data.jdg.jpk_v7_autogen
import data.jdg.legislative_monitor
import data.jdg.neural_mesh
import data.jdg.nkup_enterprise
import data.jdg.exit_tax_mdr
import data.jdg.pkpir_live
import data.jdg.uor_live
import data.jdg.local_taxes.excise_enterprise
import data.jdg.local_taxes.procedures_enterprise

# ═══════════════════════════════════════════════════════════════════════════════
# B1: SHARDED INDEX ROUTER — Context Hashing + Dynamic Path Selection
# ═══════════════════════════════════════════════════════════════════════════════
#
# Problem: 7,000 reguł w O(N) else-chain → 28s latency.
# Rozwiązanie: Router O(1) buduje hash kontekstu i wybiera specjalizowaną
# ścieżkę ewaluacji (shard) zamiast pełnego skanowania.
#
# Kontekst routingu:
#   - tax_form: SCALE / LINEAR / LUMP_SUM / TAX_CARD
#   - transaction_type: SALE / PURCHASE / EXPORT / IMPORT
#   - entity_flags: CEIDG_VALID / SUSPENDED / IN_SUCCESSIO / UNREGISTERED
#   - evaluation_date: kwartał roku
#
# W pełnej implementacji (Faza S2) router mapuje do dedykowanych shardów.
# Obecnie: prototyp — dynamiczna selekcja pakietów na podstawie kontekstu.
# ═══════════════════════════════════════════════════════════════════════════════

# ── Context Builder: ekstrahuje kluczowe flagi do routingu ───────────────────

routing_context := {
    "tax_form": object.get(input.jdg_entrepreneur, "tax_form", "SCALE"),
    "transaction_type": build_transaction_type(input),
    "entity_status": build_entity_status(input),
    "evaluation_quarter": build_evaluation_quarter(input),
    "is_cross_border": is_cross_border_transaction(input),
    "has_employees": object.get(input.jdg_entrepreneur, "has_employees", false),
    "is_vat_payer": is_vat_payer_check(input),
    "requires_ksef": requires_ksef_check(input)
}

# Pomocnicze
build_transaction_type(input) = tx_type {
    input.invoice.direction == "SALE"
    input.invoice.procedure == "EXPORT"
    tx_type := "EXPORT"
} else = tx_type {
    input.invoice.direction == "SALE"
    input.vendor.country != "PL"
    tx_type := "CROSS_BORDER_SALE"
} else = tx_type {
    input.invoice.direction == "SALE"
    tx_type := "DOMESTIC_SALE"
} else = tx_type {
    input.invoice.direction == "PURCHASE"
    input.vendor.country != "PL"
    tx_type := "IMPORT"
} else = tx_type {
    input.invoice.direction == "PURCHASE"
    tx_type := "DOMESTIC_PURCHASE"
} else = "UNKNOWN" {
    true
}

build_entity_status(input) = status {
    object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"
    status := "SUSPENDED"
} else = status {
    object.get(input.jdg_entrepreneur, "in_succession", false) == true
    status := "IN_SUCCESSIO"
} else = status {
    object.get(input.jdg_entrepreneur, "is_unregistered_activity", false) == true
    status := "UNREGISTERED"
} else = "ACTIVE" {
    true
}

build_evaluation_quarter(input) = quarter {
    eval_date := object.get(input, "evaluation_datetime", "2026-01-01")
    month := to_number(substring(eval_date, 5, 2))
    quarter = 1 { month <= 3 }
    quarter = 2 { month > 3; month <= 6 }
    quarter = 3 { month > 6; month <= 9 }
    quarter = 4 { month > 9 }
}

is_cross_border_transaction(input) = true {
    input.vendor.country != "PL"
} else = false {
    true
}

is_vat_payer_check(input) = true {
    input.jdg_entrepreneur.vat_status == "ACTIVE"
} else = false {
    true
}

requires_ksef_check(input) = true {
    object.get(input, "evaluation_datetime", "2026-01-01") >= "2026-02-01"
    input.invoice.direction == "SALE"
    input.invoice.document_type == "INVOICE"
} else = false {
    true
}

# ── Shard Router: wybiera optymalną ścieżkę ewaluacji ───────────────────────

# Prototyp routera — w Fazie S2 (Sprinty 4-8) mapuje do dedykowanych shardów.
# Obecnie: zwraca listę pakietów z priorytetyzacją na podstawie kontekstu.
shard_selector(ctx) = shard_packages {
    ctx.is_cross_border == true
    shard_packages := ["risk", "kks", "routing", "compliance", "crossborder",
        "post_brexit", "vat.substantive", "vat.deductions", "vat.procedures"]
} else = shard_packages {
    ctx.transaction_type == "DOMESTIC_SALE"
    shard_packages := ["risk", "kks", "pit.forms", "pit.kup",
        "vat.substantive", "accounting", "business", "zus"]
} else = shard_packages {
    ctx.transaction_type == "DOMESTIC_PURCHASE"
    shard_packages := ["risk", "kks", "vat.substantive", "vat.deductions",
        "accounting", "corrections", "pit.kup"]
} else = shard_packages {
    ctx.entity_status == "SUSPENDED"
    shard_packages := ["risk", "kks", "routing", "business", "zus", "accounting"]
} else = shard_packages {
    # Fallback: pełny łańcuch bezpieczeństwa
    shard_packages := ["risk", "kks", "routing", "compliance"]
}

# ── Shard Routing Decision ───────────────────────────────────────────────────

# Na podstawie kontekstu decyduje czy użyć pełnego łańcucha czy shardu
use_full_chain(ctx) = true {
    # Pełny łańcuch wymagany gdy:
    # 1. Transakcja transgraniczna
    # 2. JDG zawieszona lub w sukcesji
    # 3. Wykryto potencjalne ryzyko fraud
    ctx.is_cross_border == true
}

use_full_chain(ctx) = true {
    ctx.entity_status != "ACTIVE"
}

use_full_chain(ctx) = false {
    # Shard wystarczy dla standardowych transakcji krajowych
    ctx.transaction_type == "DOMESTIC_SALE"
    ctx.entity_status == "ACTIVE"
    ctx.is_cross_border == false
}

use_full_chain(ctx) = false {
    ctx.transaction_type == "DOMESTIC_PURCHASE"
    ctx.entity_status == "ACTIVE"
} else = true {
    true
}

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
# fallback → validation → mpips → rodo → retention → edelivery → digital →
# api_fallback → temporal → restructuring → environmental → employer →
# residency → tp → international → ksef_jpk → local_taxes →
# representation → audit → liability → corrections → mdr →
# gig_economy → business → accounting → zus → solidarity → allowances →
# elearning → transitions → exemptions → advances_returns → kup → forms →
# procedures → deductions → substantive → crossborder → post_brexit →
# compliance → routing → kks → risk
##    safe_merge chroni werdykty z flagą immutable_verdict=true
# (ZUS P720/P722/P724, business P914) przed przypadkowym nadpisaniem.
#
# PAS 8: conflicts pakiet działa POST-MERGE — analizuje input.invoice oraz
# input.jdg_entrepreneur (dane źródłowe) i wykrywa konflikty między domenami
# (IP Box vs B+R, reprezentacja vs marketing, auto VAT vs KUP, bad debt timing).
# NIE zmienia wartości — tylko flaguje do _cross_domain_conflicts.
final_verdict = safe_merge(risk.decide,
    safe_merge(kks.decide,
    safe_merge(enterprise_penalties.decide,
    safe_merge(routing.decide,
    safe_merge(compliance.decide,
    safe_merge(aml.decide,
    safe_merge(post_brexit.decide,
    safe_merge(crossborder.decide,
    safe_merge(substantive.decide,
    safe_merge(deductions.decide,
    safe_merge(procedures.decide,
    safe_merge(forms.decide,
    safe_merge(kup.decide,
    safe_merge(advances_returns.decide,
    safe_merge(exemptions.decide,
    safe_merge(art21_exemptions.decide,
    safe_merge(transitions.decide,
    safe_merge(elearning.decide,
    safe_merge(allowances.decide,
    safe_merge(solidarity.decide,
    safe_merge(zus.decide,
    safe_merge(sickness_benefits.decide,
    safe_merge(health_contribution.decide,
    safe_merge(accounting.decide,
    safe_merge(pkpir.decide,
    safe_merge(pkpir_validation.decide,
    safe_merge(depreciation.decide,
    safe_merge(business.decide,
    safe_merge(gig_economy.decide,
    safe_merge(mdr.decide,
    safe_merge(mdr_enterprise.decide,
    safe_merge(corrections.decide,
    safe_merge(liability.decide,
    safe_merge(audit.decide,
    safe_merge(representation.decide,
    safe_merge(local_taxes.decide,
    safe_merge(pcc_enterprise.decide,
    safe_merge(ksef_jpk.decide,
    safe_merge(international.decide,
    safe_merge(tp.decide,
    safe_merge(residency.decide,
    safe_merge(employer.decide,
    safe_merge(environmental.decide,
    safe_merge(bdo.decide,
    safe_merge(restructuring.decide,
    safe_merge(temporal.decide,
    safe_merge(api_fallback.decide,
    safe_merge(digital.decide,
    safe_merge(retention.decide,
    safe_merge(edelivery.decide,
    safe_merge(rodo.decide,
    safe_merge(rodo_extended.decide,
    safe_merge(mpips.decide,
    safe_merge(validation.decide,
        fallback.decide
    )))))))))))))))))))))))))))))))))))))))))))))))))

# ── PAS 8: Cross-Domain Conflict Detection (Post-Merge) ────────────────────
# conflicts.decide analizuje już scalony final_verdict i wykrywa
# konflikty między domenami (np. IP Box vs B+R na tym samym dochodzie,
# reprezentacja vs marketing, auto VAT 50% vs KUP 75%).
# Wynik jest dołączany do final_verdict przez object.union — pole
# _cross_domain_conflicts jest tylko do odczytu, nie zmienia decyzji.
#
# PAS 9: Enterprise Strategic Layer (Post-Merge Intelligence) — 5 pakietów
# S1-S5 pracuje na już scalonym finalnym werdykcie. Dodają metadane
# analityczne, optymalizacyjne i strategiczne. NIE zmieniają decyzji
# podatkowych — tylko dostarczają rekomendacji i kontekstu biznesowego.
final_verdict_with_conflicts = object.union(final_verdict, conflicts.decide)

# Enterprise Enrichment: dodaj analizy strategiczne do finalnego werdyktu
# PAS 9: S1-S5 — analizy strategiczne (tax_opt, cross_domain, judicial, audit, strategic)
# PAS 10: S6-S10 — moduły operacyjne enterprise v5.1 (KSeF, PPK/PFRON, cashflow, form_transition, banking)
# PAS 11: S11-S13 — moduły deklaracyjno-monitorujące enterprise v5.2 (annual_declaration, jpk_v7_autogen, legislative_monitor)
final_verdict_enriched = object.union(final_verdict_with_conflicts,
    object.union(tax_optimization.decide,
    object.union(cross_domain_hub.decide,
    object.union(judicial_rulings.decide,
    object.union(audit_defense.decide,
    object.union(strategic_advisor.decide,
    object.union(ksef_resilience.decide,
    object.union(ppk_pfron.decide,
    object.union(cashflow_predictor.decide,
    object.union(form_transition.decide,
    object.union(banking.decide,
    object.union(annual_declaration.decide,
    object.union(jpk_v7_autogen.decide,
    object.union(legislative_monitor.decide,
    # ── PAS 12: Enterprise v6.0 Neural & Compliance Layer (2026-07-19) ──
    # S14: Neural Rule Mesh — cross-domain intelligence fabric
    # S15: NKUP Enterprise Complete — Art. 23 PIT full coverage  
    # S16: Exit Tax + MDR Enterprise — cross-border tax obligations
    object.union(neural_mesh.decide,
    object.union(nkup_enterprise.decide,
    object.union(exit_tax_mdr.decide,
    # ── PAS 13: Enterprise v6.1 Accounting Live Layer (2026-07-19) ──
    # S17: PKPiR Enterprise Live — active column 1-17 validation
    # S18: UoR Enterprise Live — full accounting law compliance
    object.union(pkpir_live.decide,
    object.union(uor_live.decide,
    # ── PAS 14: Enterprise v6.2 Class IX Complete (2026-07-19) ──
    # S19: Excise Enterprise Complete — fuels, alcohol, tobacco, energy, warehouse
    # S20: Local Procedures Enterprise — PCC enforcement, property exemptions, cross-tax
    object.union(excise_enterprise.decide,
        procedures_enterprise.decide
    ))))))))))))))))))