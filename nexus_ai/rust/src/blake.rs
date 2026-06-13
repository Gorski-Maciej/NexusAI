// ═══════════════════════════════════════════════════════════════════════════════
// BLAKE2b — Deterministic hashing for TigerBeetle account IDs
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. blake2b(data, digest_size) — configurable output (1-64 bytes)
//
// Used for deterministic TigerBeetle account ID mapping (128-bit identifiers).
// ═══════════════════════════════════════════════════════════════════════════════

use blake2::{Blake2b512, Digest};

/// Compute BLAKE2b digest of `data` with configurable output size (1-64 bytes).
/// Used for deterministic TigerBeetle account ID mapping.
pub fn blake2b(data: &[u8], digest_size: u8) -> Result<Vec<u8>, String> {
    let size = digest_size.max(1).min(64) as usize;
    let mut hasher = Blake2b512::new();
    hasher.update(data);
    let result = hasher.finalize();
    // Blake2b512 produces 64 bytes; truncate to requested size
    Ok(result[..size].to_vec())
}
