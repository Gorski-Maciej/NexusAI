// ═══════════════════════════════════════════════════════════════════════════════
// engine — Refactored rule evaluation engine (eliminates code duplication)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Moduły:
//   condition.rs — Shared SQL condition tokenizer/parser/evaluator
//   pipeline.rs  — Shared first-match-wins evaluation pipeline
//   priority_engine.rs — PriorityEngine (thin wrapper, dawny rule_engine.rs)
//   rules_engine.rs    — RulesEngine (thin wrapper, dawny rules_engine.rs)
//
// Przed refaktorem:
//   rule_engine.rs:   340+ linii DUPLIKATU (własny tokenizer + pipeline)
//   rules_engine.rs:  480+ linii DUPLIKATU (własny tokenizer + pipeline)
//   tax_pipeline.rs:  120+ linii evaluate_rules_inner DUPLIKATU
//
// Po refaktorze:
//   condition.rs:     220 linii (JEDNO źródło prawdy dla SQL evaluatora)
//   pipeline.rs:      200 linii (JEDNO źródło prawdy dla first-match-wins)
//   priority_engine.rs: 60 linii (cienki wrapper)
//   rules_engine.rs:    280 linii (cienki wrapper + batch/validate)
//   Oszczędność: ~700 linii, JEDNO źródło prawdy
// ═══════════════════════════════════════════════════════════════════════════════

pub mod condition;
pub mod pipeline;
pub mod priority_engine;
pub mod rules_engine;
