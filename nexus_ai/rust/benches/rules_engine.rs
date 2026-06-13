// ═══════════════════════════════════════════════════════════════════════════════
// RulesEngine — Criterion benchmarks
// ═══════════════════════════════════════════════════════════════════════════════
//
// Mierzy wydajność kluczowych funkcji RulesEngine:
//   - evaluate        — pojedynczy kontekst (first-match-wins)
//   - batch_evaluate  — wiele kontekstów (sequential ≤ threshold, rayon >)
//   - sort_rules      — sortowanie reguł
//   - validate        — walidacja formatu + priorytetów
//
// Używa pipeline::* bezpośrednio (pure Rust, bez PyO3).
//
// Uruchomienie:
//   cargo bench --bench rules_engine
//   cargo bench --bench rules_engine -- "batch_evaluate"  # filtr
//
// ═══════════════════════════════════════════════════════════════════════════════

use criterion::{black_box, criterion_group, criterion_main, Criterion};
use nexus_crypto::engine::pipeline;
use rayon::prelude::*;
use serde_json::{json, Value};

// ═══════════════════════════════════════════════════════════════════════════════
// Test data generators
// ═══════════════════════════════════════════════════════════════════════════════

/// Generate N tax rules. Each rule has unique condition/action to avoid
/// early termination by first-match-wins (simulates real-world scenarios).
fn generate_rules(count: usize) -> Vec<Value> {
    (0..count)
        .map(|i| {
            let category = match i % 10 {
                0 => "FUEL",
                1 => "FOOD",
                2 => "EDUCATION",
                3 => "HEALTHCARE",
                4 => "TRANSPORT",
                5 => "IT_OFFICE",
                6 => "CONSTRUCTION",
                7 => "AGRICULTURE",
                8 => "ENTERTAINMENT",
                9 => "OTHER",
                _ => "UNKNOWN",
            };
            json!({
                "rule_id": format!("rule-{:04}", i),
                "condition_sql": format!("category_code = '{}'", category),
                "action_json": format!("{{\"vat_rate\": \"0.{:02}\", \"rounding_level\": \"position\"}}", (i % 5 + 5) * 5),
                "priority": (i as i64 % 100) + 1,
            })
        })
        .collect()
}

/// Generate N contexts that match different rules (to test full traversal).
fn generate_contexts(count: usize) -> Vec<serde_json::Map<String, Value>> {
    let categories = [
        "FUEL", "FOOD", "EDUCATION", "HEALTHCARE", "TRANSPORT",
        "IT_OFFICE", "CONSTRUCTION", "AGRICULTURE", "ENTERTAINMENT", "OTHER",
        "UNKNOWN", "MIXED",
    ];

    (0..count)
        .map(|i| {
            let mut ctx = serde_json::Map::new();
            ctx.insert(
                "category_code".to_string(),
                Value::String(categories[i % categories.len()].to_string()),
            );
            ctx.insert(
                "vendor_country".to_string(),
                Value::String(if i % 3 == 0 { "PL".to_string() } else { "EU".to_string() }),
            );
            ctx.insert(
                "amount_net".to_string(),
                Value::String(format!("{}", (i as i64 % 100_000) + 1000)),
            );
            ctx.insert(
                "transaction_date".to_string(),
                Value::String(format!("2024-{:02}-{:02}", (i % 12) + 1, (i % 28) + 1)),
            );
            ctx
        })
        .collect()
}

// ═══════════════════════════════════════════════════════════════════════════════
// evaluate — single context
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_evaluate_10_rules(c: &mut Criterion) {
    let rules = generate_rules(10);
    let mut ctx = serde_json::Map::new();
    ctx.insert("category_code".to_string(), json!("FUEL"));
    ctx.insert("vendor_country".to_string(), json!("PL"));

    c.bench_function("evaluate/10_rules", |b| {
        b.iter(|| pipeline::evaluate_rules_pipeline(black_box(&rules), black_box(&ctx)))
    });
}

fn bench_evaluate_100_rules(c: &mut Criterion) {
    let rules = generate_rules(100);
    let mut ctx = serde_json::Map::new();
    ctx.insert("category_code".to_string(), json!("OTHER"));
    ctx.insert("vendor_country".to_string(), json!("PL"));

    c.bench_function("evaluate/100_rules_match_last", |b| {
        // "OTHER" matches the last generated rule (index 9 + 10n), forcing
        // full traversal of all rules.
        b.iter(|| pipeline::evaluate_rules_pipeline(black_box(&rules), black_box(&ctx)))
    });
}

fn bench_evaluate_1000_rules_no_match(c: &mut Criterion) {
    let rules = generate_rules(1000);
    let mut ctx = serde_json::Map::new();
    ctx.insert("category_code".to_string(), json!("NONEXISTENT"));
    ctx.insert("vendor_country".to_string(), json!("PL"));

    c.bench_function("evaluate/1000_rules_no_match", |b| {
        // No rule matches → full traversal of all 1000 rules
        b.iter(|| pipeline::evaluate_rules_pipeline(black_box(&rules), black_box(&ctx)))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// evaluate_single (used by batch_evaluate internally)
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_evaluate_single(c: &mut Criterion) {
    let rules = generate_rules(50);
    let mut ctx = serde_json::Map::new();
    ctx.insert("category_code".to_string(), json!("FUEL"));

    c.bench_function("evaluate_single/50_rules", |b| {
        b.iter(|| pipeline::evaluate_single(black_box(&rules), black_box(&ctx)))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// batch_evaluate — sequential (small) vs rayon (large)
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_batch_evaluate_5(c: &mut Criterion) {
    // 5 contexts × 100 rules — sequential path
    let rules = generate_rules(100);
    let contexts = generate_contexts(5);

    c.bench_function("batch_evaluate/5_ctx_100_rules_sequential", |b| {
        b.iter(|| {
            for ctx in &contexts {
                let _ = pipeline::evaluate_single(&rules, ctx);
            }
        })
    });
}

fn bench_batch_evaluate_64(c: &mut Criterion) {
    // 64 contexts — boundary between sequential and parallel
    let rules = generate_rules(100);
    let contexts = generate_contexts(64);

    c.bench_function("batch_evaluate/64_ctx_100_rules_boundary", |b| {
        b.iter(|| {
            for ctx in &contexts {
                let _ = pipeline::evaluate_single(&rules, ctx);
            }
        })
    });
}

fn bench_batch_evaluate_1000(c: &mut Criterion) {
    // 1000 contexts with 200 rules — rayon parallel path
    let rules = generate_rules(200);
    let contexts = generate_contexts(1000);

    c.bench_function("batch_evaluate/1000_ctx_200_rules_rayon", |b| {
        b.iter(|| {
            let _: Vec<_> = contexts
                .par_iter()
                .map(|ctx| pipeline::evaluate_single(&rules, ctx))
                .collect();
        })
    });
}

fn bench_batch_evaluate_10000(c: &mut Criterion) {
    // 10k contexts with 50 rules — large parallel workload
    let rules = generate_rules(50);
    let contexts = generate_contexts(10_000);

    c.bench_function("batch_evaluate/10000_ctx_50_rules_rayon", |b| {
        b.iter(|| {
            let _: Vec<_> = contexts
                .par_iter()
                .map(|ctx| pipeline::evaluate_single(&rules, ctx))
                .collect();
        })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// sort_rules
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_sort_rules_10(c: &mut Criterion) {
    let mut rules = generate_rules(10);
    // Shuffle to make sorting non-trivial
    rules.reverse();

    c.bench_function("sort_rules/10", |b| {
        b.iter(|| {
            let mut copy = rules.clone();
            pipeline::sort_rules(&mut copy);
            black_box(copy)
        })
    });
}

fn bench_sort_rules_1000(c: &mut Criterion) {
    let mut rules = generate_rules(1000);
    rules.reverse();

    c.bench_function("sort_rules/1000", |b| {
        b.iter(|| {
            let mut copy = rules.clone();
            pipeline::sort_rules(&mut copy);
            black_box(copy)
        })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// validate — format + priorities
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_validate_format_10(c: &mut Criterion) {
    let rules = generate_rules(10);

    c.bench_function("validate_format/10", |b| {
        b.iter(|| pipeline::validate_rules_format(black_box(&rules)))
    });
}

fn bench_validate_format_1000(c: &mut Criterion) {
    let rules = generate_rules(1000);

    c.bench_function("validate_format/1000", |b| {
        b.iter(|| pipeline::validate_rules_format(black_box(&rules)))
    });
}

fn bench_validate_priorities_100(c: &mut Criterion) {
    let rules = generate_rules(100);

    c.bench_function("validate_priorities/100", |b| {
        b.iter(|| pipeline::validate_priorities(black_box(&rules)))
    });
}

fn bench_validate_priorities_1000(c: &mut Criterion) {
    let rules = generate_rules(1000);

    c.bench_function("validate_priorities/1000", |b| {
        b.iter(|| pipeline::validate_priorities(black_box(&rules)))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// JSON serialization helpers (used by RulesEngine)
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_eval_result_to_json(c: &mut Criterion) {
    let result = pipeline::EvalResult {
        matched: true,
        rule_id: "rule-0042".to_string(),
        priority: 10,
        verdict: json!({"vat_rate": "0.23", "_rule_id": "rule-0042", "_priority": 10}),
        evaluated_rules: (0..50)
            .map(|i| pipeline::RuleEvaluation {
                rule_id: format!("rule-{:04}", i),
                condition_sql: format!("category_code = '{}'", match i % 10 {
                    0 => "FUEL", 1 => "FOOD", 2 => "EDUCATION",
                    3 => "HEALTHCARE", 4 => "TRANSPORT", 5 => "IT_OFFICE",
                    6 => "CONSTRUCTION", 7 => "AGRICULTURE",
                    8 => "ENTERTAINMENT", 9 => "OTHER",
                    _ => "UNKNOWN",
                }),
                matched: i == 42,
                selected: i == 42,
            })
            .collect(),
        error: String::new(),
    };

    c.bench_function("eval_result_to_json/50_rules", |b| {
        b.iter(|| pipeline::eval_result_to_json(black_box(&result)))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Criterion group & main
// ═══════════════════════════════════════════════════════════════════════════════

criterion_group! {
    name = rules_engine_benches;
    config = Criterion::default()
        .sample_size(100)
        .warm_up_time(std::time::Duration::from_millis(500))
        .measurement_time(std::time::Duration::from_secs(3));
    targets =
        // evaluate
        bench_evaluate_10_rules,
        bench_evaluate_100_rules,
        bench_evaluate_1000_rules_no_match,
        // evaluate_single
        bench_evaluate_single,
        // batch_evaluate (sequential vs rayon)
        bench_batch_evaluate_5,
        bench_batch_evaluate_64,
        bench_batch_evaluate_1000,
        bench_batch_evaluate_10000,
        // sort
        bench_sort_rules_10,
        bench_sort_rules_1000,
        // validate
        bench_validate_format_10,
        bench_validate_format_1000,
        bench_validate_priorities_100,
        bench_validate_priorities_1000,
        // serialization
        bench_eval_result_to_json,
}

criterion_main!(rules_engine_benches);
