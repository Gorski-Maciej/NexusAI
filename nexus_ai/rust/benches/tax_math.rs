// ═══════════════════════════════════════════════════════════════════════════════
// TaxMathEngine — Criterion benchmarks
// ═══════════════════════════════════════════════════════════════════════════════
//
// Mierzy wydajność kluczowych funkcji TaxMathEngine:
//   - to_grosze             (string → i64)
//   - multiply_net_by_vat   (i64 * rate → rounded i64)
//   - add_tax               (net + vat → brutto)
//   - to_zlotowki           (i64 → string)
//   - parse_rate            (string validation)
//   - calculate_vat_by_policy (position level, sequential vs rayon)
//   - calculate_vat_by_policy (total level, rayon+SIMD)
//
// Uruchomienie:
//   cargo bench --bench tax_math
//   cargo bench --bench tax_math -- "calculate_vat"  # filtr
//
// ═══════════════════════════════════════════════════════════════════════════════

use criterion::{black_box, criterion_group, criterion_main, Criterion};
use nexus_crypto::tax;
use pyo3::prelude::*;

// ═══════════════════════════════════════════════════════════════════════════════
// Helper: create persistent Py<InvoicePositions> for PyO3-based benchmarks
// ═══════════════════════════════════════════════════════════════════════════════
//
// Zamiast zwracać Vec<PyRef<'_>> (problemy z lifetime), tworzymy Vec<Py<...>>
// które żyją poza closure. W closure borrowamy je przez .bind(py).borrow().

fn make_py_positions(
    py: Python<'_>,
    count: usize,
    base_net: i64,
    rate: &str,
) -> Vec<Py<tax::InvoicePositions>> {
    (0..count)
        .map(|i| {
            let net = base_net + (i as i64 * 100) % 999_999;
            let pos = tax::InvoicePositions::new(net, rate.to_string());
            Py::new(py, pos).expect("Failed to create InvoicePositions")
        })
        .collect()
}

/// Convert Vec<Py<T>> to Vec<PyRef<'_, T>> for a single call.
fn borrow_positions<'py>(
    py: Python<'py>,
    py_objects: &'py [Py<tax::InvoicePositions>],
) -> Vec<PyRef<'py, tax::InvoicePositions>> {
    py_objects
        .iter()
        .map(|p| p.bind(py).borrow())
        .collect()
}

// ═══════════════════════════════════════════════════════════════════════════════
// to_grosze — string → i64 conversion
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_to_grosze_tiny(c: &mut Criterion) {
    c.bench_function("to_grosze/tiny_0.01", |b| {
        b.iter(|| tax::to_grosze(black_box("0.01")))
    });
}

fn bench_to_grosze_typical(c: &mut Criterion) {
    c.bench_function("to_grosze/typical_1234.56", |b| {
        b.iter(|| tax::to_grosze(black_box("1234.56")))
    });
}

fn bench_to_grosze_large(c: &mut Criterion) {
    c.bench_function("to_grosze/large_999999999.99", |b| {
        b.iter(|| tax::to_grosze(black_box("999999999.99")))
    });
}

fn bench_to_grosze_integer(c: &mut Criterion) {
    c.bench_function("to_grosze/integer_1000000", |b| {
        b.iter(|| tax::to_grosze(black_box("1000000")))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// to_zlotowki — i64 → string
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_to_zlotowki_small(c: &mut Criterion) {
    c.bench_function("to_zlotowki/small_1", |b| {
        b.iter(|| tax::to_zlotowki(black_box(1)))
    });
}

fn bench_to_zlotowki_typical(c: &mut Criterion) {
    c.bench_function("to_zlotowki/typical_123456", |b| {
        b.iter(|| tax::to_zlotowki(black_box(123456)))
    });
}

fn bench_to_zlotowki_large(c: &mut Criterion) {
    c.bench_function("to_zlotowki/large_99999999999", |b| {
        b.iter(|| tax::to_zlotowki(black_box(99_999_999_999)))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// multiply_net_by_vat — net_grosze × rate → rounded i64
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_multiply_standard(c: &mut Criterion) {
    c.bench_function("multiply_net_by_vat/standard_23pct_100000", |b| {
        b.iter(|| tax::multiply_net_by_vat(black_box(100_000), black_box("0.23")))
    });
}

fn bench_multiply_reduced(c: &mut Criterion) {
    c.bench_function("multiply_net_by_vat/reduced_8pct_99999", |b| {
        b.iter(|| tax::multiply_net_by_vat(black_box(99_999), black_box("0.08")))
    });
}

fn bench_multiply_zero(c: &mut Criterion) {
    c.bench_function("multiply_net_by_vat/zero", |b| {
        b.iter(|| tax::multiply_net_by_vat(black_box(0), black_box("0.23")))
    });
}

fn bench_multiply_tiny_straddle(c: &mut Criterion) {
    c.bench_function("multiply_net_by_vat/tiny_straddle_1gr_23pct", |b| {
        b.iter(|| tax::multiply_net_by_vat(black_box(1), black_box("0.23")))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// add_tax — net + vat → brutto (simple i64 add)
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_add_tax(c: &mut Criterion) {
    c.bench_function("add_tax/100000_plus_23000", |b| {
        b.iter(|| tax::add_tax(black_box(100_000), black_box(23_000)))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// parse_rate — rate string validation
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_parse_rate_standard(c: &mut Criterion) {
    c.bench_function("parse_rate/standard_0.23", |b| {
        b.iter(|| tax::parse_rate(black_box("0.23")))
    });
}

fn bench_parse_rate_reduced(c: &mut Criterion) {
    c.bench_function("parse_rate/reduced_0.08", |b| {
        b.iter(|| tax::parse_rate(black_box("0.08")))
    });
}

fn bench_parse_rate_exempt(c: &mut Criterion) {
    c.bench_function("parse_rate/exempt_0.00", |b| {
        b.iter(|| tax::parse_rate(black_box("0.00")))
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// calculate_vat_by_policy — pełna kalkulacja VAT
// ═══════════════════════════════════════════════════════════════════════════════
//
// Uwaga: wymaga PyO3 (Python::with_gil) aby tworzyć InvoicePositions.
// Py<InvoicePositions> są tworzone przed pengią i żyją poza nią.
// W closure borrowamy je przez .bind(py).borrow() do Vec<PyRef>.

fn bench_calculate_vat_position_10(c: &mut Criterion) {
    Python::with_gil(|py| {
        let py_objects: Vec<Py<tax::InvoicePositions>> = make_py_positions(py, 10, 100_000, "0.23");
        c.bench_function("calculate_vat/position_10_sequential", |b| {
            b.iter(|| {
                let refs = borrow_positions(py, &py_objects);
                tax::calculate_vat_by_policy(
                    black_box(refs),
                    black_box("0.23"),
                    black_box("position"),
                )
            })
        });
    });
}

fn bench_calculate_vat_position_64(c: &mut Criterion) {
    Python::with_gil(|py| {
        let py_objects: Vec<Py<tax::InvoicePositions>> = make_py_positions(py, 64, 100_000, "0.23");
        c.bench_function("calculate_vat/position_64_sequential_boundary", |b| {
            b.iter(|| {
                let refs = borrow_positions(py, &py_objects);
                tax::calculate_vat_by_policy(
                    black_box(refs),
                    black_box("0.23"),
                    black_box("position"),
                )
            })
        });
    });
}

fn bench_calculate_vat_position_1000(c: &mut Criterion) {
    Python::with_gil(|py| {
        let py_objects: Vec<Py<tax::InvoicePositions>> = make_py_positions(py, 1000, 100_000, "0.23");
        c.bench_function("calculate_vat/position_1000_rayon", |b| {
            b.iter(|| {
                let refs = borrow_positions(py, &py_objects);
                tax::calculate_vat_by_policy(
                    black_box(refs),
                    black_box("0.23"),
                    black_box("position"),
                )
            })
        });
    });
}

fn bench_calculate_vat_position_10000(c: &mut Criterion) {
    Python::with_gil(|py| {
        let py_objects: Vec<Py<tax::InvoicePositions>> = make_py_positions(py, 10_000, 100_000, "0.23");
        c.bench_function("calculate_vat/position_10000_rayon", |b| {
            b.iter(|| {
                let refs = borrow_positions(py, &py_objects);
                tax::calculate_vat_by_policy(
                    black_box(refs),
                    black_box("0.23"),
                    black_box("position"),
                )
            })
        });
    });
}

fn bench_calculate_vat_total_10(c: &mut Criterion) {
    Python::with_gil(|py| {
        let py_objects: Vec<Py<tax::InvoicePositions>> = make_py_positions(py, 10, 100_000, "0.23");
        c.bench_function("calculate_vat/total_10", |b| {
            b.iter(|| {
                let refs = borrow_positions(py, &py_objects);
                tax::calculate_vat_by_policy(
                    black_box(refs),
                    black_box("0.23"),
                    black_box("total"),
                )
            })
        });
    });
}

fn bench_calculate_vat_total_10000(c: &mut Criterion) {
    Python::with_gil(|py| {
        let py_objects: Vec<Py<tax::InvoicePositions>> = make_py_positions(py, 10_000, 100_000, "0.23");
        c.bench_function("calculate_vat/total_10000", |b| {
            b.iter(|| {
                let refs = borrow_positions(py, &py_objects);
                tax::calculate_vat_by_policy(
                    black_box(refs),
                    black_box("0.23"),
                    black_box("total"),
                )
            })
        });
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Criterion group & main
// ═══════════════════════════════════════════════════════════════════════════════

criterion_group! {
    name = tax_math_benches;
    config = Criterion::default()
        .sample_size(100)
        .warm_up_time(std::time::Duration::from_millis(500))
        .measurement_time(std::time::Duration::from_secs(3));
    targets =
        // to_grosze
        bench_to_grosze_tiny,
        bench_to_grosze_typical,
        bench_to_grosze_large,
        bench_to_grosze_integer,
        // to_zlotowki
        bench_to_zlotowki_small,
        bench_to_zlotowki_typical,
        bench_to_zlotowki_large,
        // multiply_net_by_vat
        bench_multiply_standard,
        bench_multiply_reduced,
        bench_multiply_zero,
        bench_multiply_tiny_straddle,
        // add_tax
        bench_add_tax,
        // parse_rate
        bench_parse_rate_standard,
        bench_parse_rate_reduced,
        bench_parse_rate_exempt,
        // calculate_vat_by_policy
        bench_calculate_vat_position_10,
        bench_calculate_vat_position_64,
        bench_calculate_vat_position_1000,
        bench_calculate_vat_position_10000,
        bench_calculate_vat_total_10,
        bench_calculate_vat_total_10000,
}

criterion_main!(tax_math_benches);
