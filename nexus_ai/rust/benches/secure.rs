// ═══════════════════════════════════════════════════════════════════════════════
// Secure — Criterion benchmarks for SensitiveBytes & MlockedVec
// ═══════════════════════════════════════════════════════════════════════════════
//
// Mierzy wydajność:
//   - SensitiveBytes::new()       — alokacja + RAII wrapper (Zeroizing<Vec<u8>>)
//   - SensitiveBytes::from_vec()  — wrap istniejącego Vec<u8>
//   - SensitiveBytes drop         — auto-zeroize on drop
//   - MlockedVec::new()           — alokacja + mlock (jeśli dostępne)
//   - MlockedVec::from_vec()      — mlock istniejącego Vec
//   - Vec<u8> baseline            — porównanie kosztu alokacji raw
//   - decrypt_into_sensitive()    — decrypt + RAII wrap (przez aead)
//   - copy_from_slice do SensitiveBytes
//
// Uruchomienie:
//   cargo bench --bench secure
//   cargo bench --bench secure -- "SensitiveBytes"  # filtr
//
// ═══════════════════════════════════════════════════════════════════════════════

use criterion::{black_box, criterion_group, criterion_main, Criterion};
use nexus_crypto::secure::{MlockedVec, SensitiveBytes};

// ═══════════════════════════════════════════════════════════════════════════════
// SensitiveBytes benchmarks
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_sensitive_bytes_new_32(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/new_32_B", |b| {
        b.iter(|| SensitiveBytes::new(black_box(32)))
    });
}

fn bench_sensitive_bytes_new_256(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/new_256_B", |b| {
        b.iter(|| SensitiveBytes::new(black_box(256)))
    });
}

fn bench_sensitive_bytes_new_4096(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/new_4_KiB", |b| {
        b.iter(|| SensitiveBytes::new(black_box(4096)))
    });
}

fn bench_sensitive_bytes_new_1m(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/new_1_MiB", |b| {
        b.iter(|| SensitiveBytes::new(black_box(1_048_576)))
    });
}

fn bench_sensitive_bytes_from_vec_32(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/from_vec_32_B", |b| {
        b.iter(|| {
            let data = vec![0xABu8; 32];
            SensitiveBytes::from_vec(black_box(data))
        })
    });
}

fn bench_sensitive_bytes_from_vec_4096(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/from_vec_4_KiB", |b| {
        b.iter(|| {
            let data = vec![0xABu8; 4096];
            SensitiveBytes::from_vec(black_box(data))
        })
    });
}

fn bench_sensitive_bytes_copy_from(c: &mut Criterion) {
    let source = [0x42u8; 256];
    c.bench_function("SensitiveBytes/copy_from_slice_256_B", |b| {
        b.iter(|| {
            let mut buf = SensitiveBytes::new(256);
            buf.copy_from_slice(black_box(&source));
            black_box(buf[0])
        })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// SensitiveBytes vs Vec<u8> — porównanie kosztu alokacji
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_vec_u8_new_32(c: &mut Criterion) {
    c.bench_function("Vec<u8>/new_32_B_baseline", |b| {
        b.iter(|| vec![0u8; black_box(32)])
    });
}

fn bench_vec_u8_new_4096(c: &mut Criterion) {
    c.bench_function("Vec<u8>/new_4_KiB_baseline", |b| {
        b.iter(|| vec![0u8; black_box(4096)])
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// SensitiveBytes drop + zeroize — time to allocate, fill, and drop
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_sensitive_bytes_alloc_fill_drop_32(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/alloc_fill_drop_32_B", |b| {
        b.iter(|| {
            let mut buf = SensitiveBytes::new(32);
            buf.copy_from_slice(&[0xFFu8; 32]);
            black_box(buf[0]);
            // drop → auto-zeroize
        })
    });
}

fn bench_sensitive_bytes_alloc_fill_drop_4096(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/alloc_fill_drop_4_KiB", |b| {
        b.iter(|| {
            let mut buf = SensitiveBytes::new(4096);
            buf.copy_from_slice(&[0xFFu8; 4096]);
            black_box(buf[0]);
        })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// MlockedVec benchmarks (jeśli mlock jest dostępny)
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_mlocked_vec_new_32(c: &mut Criterion) {
    c.bench_function("MlockedVec/new_32_B", |b| {
        b.iter(|| {
            match MlockedVec::new(32) {
                Ok(v) => Some(v),
                Err(_) => None, // graceful degradation
            }
        })
    });
}

fn bench_mlocked_vec_new_4096(c: &mut Criterion) {
    c.bench_function("MlockedVec/new_4_KiB", |b| {
        b.iter(|| {
            match MlockedVec::new(4096) {
                Ok(v) => Some(v),
                Err(_) => None,
            }
        })
    });
}

fn bench_mlocked_vec_from_vec_32(c: &mut Criterion) {
    c.bench_function("MlockedVec/from_vec_32_B", |b| {
        b.iter(|| {
            let data = vec![0xABu8; 32];
            match MlockedVec::from_vec(data) {
                Ok(v) => Some(v),
                Err(_) => None,
            }
        })
    });
}

fn bench_mlocked_vec_zeroize_and_unlock(c: &mut Criterion) {
    c.bench_function("MlockedVec/zeroize_and_unlock", |b| {
        b.iter(|| {
            if let Ok(mut copy) = MlockedVec::new(4096) {
                copy.copy_from_slice(&[0xFFu8; 4096]);
                copy.zeroize_and_unlock();
                black_box(copy.len());
            }
        })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// AEAD decrypt_into_sensitive przez SensitiveBytes
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_decrypt_into_sensitive_small(c: &mut Criterion) {
    // Setup: szyfrujemy mały plaintext
    let key = [0x42u8; 32];
    let plaintext = b"Hello, NexusAI!";
    let ciphertext = nexus_crypto::aead::encrypt(&key, plaintext).unwrap();

    c.bench_function("decrypt_into_sensitive/small_16_B", |b| {
        b.iter(|| {
            let result = nexus_crypto::aead::decrypt_into_sensitive(
                black_box(&key),
                black_box(&ciphertext),
            );
            black_box(result.unwrap()[0])
        })
    });
}

fn bench_decrypt_into_sensitive_large(c: &mut Criterion) {
    // Setup: szyfrujemy duży plaintext (1 KiB)
    let key = [0x42u8; 32];
    let plaintext = vec![0xABu8; 1024];
    let ciphertext = nexus_crypto::aead::encrypt(&key, &plaintext).unwrap();

    c.bench_function("decrypt_into_sensitive/large_1_KiB", |b| {
        b.iter(|| {
            let result = nexus_crypto::aead::decrypt_into_sensitive(
                black_box(&key),
                black_box(&ciphertext),
            );
            black_box(result.unwrap()[0])
        })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Comparison: Vec<u8> drop vs SensitiveBytes drop (zeroize cost)
// ═══════════════════════════════════════════════════════════════════════════════

fn bench_vec_drop_4096(c: &mut Criterion) {
    c.bench_function("Vec<u8>/drop_4_KiB_baseline", |b| {
        b.iter(|| {
            let v = vec![0xFFu8; 4096];
            black_box(v[0]);
            drop(v);
        })
    });
}

fn bench_sensitive_bytes_drop_4096(c: &mut Criterion) {
    c.bench_function("SensitiveBytes/drop_zeroize_4_KiB", |b| {
        b.iter(|| {
            let mut buf = SensitiveBytes::new(4096);
            buf.copy_from_slice(&[0xFFu8; 4096]);
            black_box(buf[0]);
            // drop → auto-zeroize
        })
    });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Criterion group & main
// ═══════════════════════════════════════════════════════════════════════════════

criterion_group! {
    name = secure_benches;
    config = Criterion::default()
        .sample_size(100)
        .warm_up_time(std::time::Duration::from_millis(500))
        .measurement_time(std::time::Duration::from_secs(3));
    targets =
        // SensitiveBytes allocation
        bench_sensitive_bytes_new_32,
        bench_sensitive_bytes_new_256,
        bench_sensitive_bytes_new_4096,
        bench_sensitive_bytes_new_1m,
        bench_sensitive_bytes_from_vec_32,
        bench_sensitive_bytes_from_vec_4096,
        bench_sensitive_bytes_copy_from,
        // Vec<u8> baseline
        bench_vec_u8_new_32,
        bench_vec_u8_new_4096,
        // alloc + fill + drop (zeroize)
        bench_sensitive_bytes_alloc_fill_drop_32,
        bench_sensitive_bytes_alloc_fill_drop_4096,
        // MlockedVec
        bench_mlocked_vec_new_32,
        bench_mlocked_vec_new_4096,
        bench_mlocked_vec_from_vec_32,
        bench_mlocked_vec_zeroize_and_unlock,
        // AEAD decrypt_into_sensitive
        bench_decrypt_into_sensitive_small,
        bench_decrypt_into_sensitive_large,
        // Drop comparison
        bench_vec_drop_4096,
        bench_sensitive_bytes_drop_4096,
}

criterion_main!(secure_benches);
