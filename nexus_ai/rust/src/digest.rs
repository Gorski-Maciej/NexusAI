// ═══════════════════════════════════════════════════════════════════════════════
// Digest — SHA-256 (one-shot + streaming)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. sha256_hex(data) — one-shot hex digest
//   2. StreamingSha256 — incremental hasher with hexdigest()/digest()/copy()
//
// Conforms to aa3fvcx.txt: replaces hashlib.sha256() for streaming operations
// (model verification, document fingerprinting).
// ═══════════════════════════════════════════════════════════════════════════════

use sha2::{Digest, Sha256};

/// Compute SHA-256 hex digest of `data` (one-shot).
pub fn sha256_hex(data: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(data);
    hex::encode(hasher.finalize())
}

/// Streaming SHA-256 hasher.
/// Python wrapper: `Sha256Hasher`
pub struct StreamingSha256 {
    inner: Sha256,
}

impl StreamingSha256 {
    pub fn new() -> Self {
        Self {
            inner: Sha256::new(),
        }
    }

    pub fn update(&mut self, data: &[u8]) {
        self.inner.update(data);
    }

    /// Return hex digest without consuming the hasher.
    pub fn hexdigest(&self) -> String {
        hex::encode(self.inner.clone().finalize())
    }

    /// Return raw 32-byte digest without consuming the hasher.
    pub fn digest(&self) -> [u8; 32] {
        self.inner.clone().finalize().into()
    }

    /// Return a deep copy of the streaming hasher.
    pub fn copy(&self) -> Self {
        Self {
            inner: self.inner.clone(),
        }
    }
}
