// ═══════════════════════════════════════════════════════════════════════════════
// Secure — Zeroize helpers for sensitive memory
// ═══════════════════════════════════════════════════════════════════════════════
//
// Uses the `zeroize` crate to securely clear sensitive data on drop.
// NOTE: Only affects Rust-side buffers (Vec<u8>). Python bytes objects
// are immutable — key zeroing must happen at the Python caller level
// (del key + gc.collect()).
// ═══════════════════════════════════════════════════════════════════════════════

use zeroize::Zeroize;

/// Securely zero out a mutable byte slice.
#[allow(dead_code)]
pub fn zero(data: &mut [u8]) {
    data.zeroize();
}

/// Securely zero out a Vec<u8>.
pub fn zero_vec(data: &mut Vec<u8>) {
    data.zeroize();
}
