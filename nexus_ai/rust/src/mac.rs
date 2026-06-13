// ═══════════════════════════════════════════════════════════════════════════════
// MAC — HMAC-SHA256 Message Authentication Code
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. hmac_sha256(key, data) — 32-byte HMAC-SHA256 digest
//
// Used for JWT signature verification and API request authentication.
// ═══════════════════════════════════════════════════════════════════════════════

use hmac::{Hmac, Mac};
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

/// Compute HMAC-SHA256 of `data` with `key`.
/// Returns 32 bytes (raw digest).
pub fn hmac_sha256(key: &[u8], data: &[u8]) -> Result<[u8; 32], String> {
    let mut mac = HmacSha256::new_from_slice(key).map_err(|e| e.to_string())?;
    mac.update(data);
    let result = mac.finalize();
    let code = result.into_bytes();
    let mut digest = [0u8; 32];
    digest.copy_from_slice(&code);
    Ok(digest)
}
