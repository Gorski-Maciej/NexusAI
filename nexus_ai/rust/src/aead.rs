// ═══════════════════════════════════════════════════════════════════════════════
// AEAD — ChaCha20-Poly1305 Authenticated Encryption
// ═══════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   1. encrypt(key, plaintext)          — ChaCha20-Poly1305 AEAD
//   2. decrypt(key, data)               — ChaCha20-Poly1305 AEAD + decryption
//   3. decrypt_into_sensitive(key, data) — decrypt into SensitiveBytes (RAII)
//
// Integracja z secure.rs:
//   - encrypt(key: &[u8], ...)           — działa też z &SensitiveBytes / &MlockedVec
//   - decrypt(key: &[u8], ...)           — działa też z &SensitiveBytes / &MlockedVec
//   - decrypt_into_sensitive(...)        — zwraca SensitiveBytes z plaintextem
//
// Wszystkie funkcje przyjmują &[u8] dla klucza — SensitiveBytes i MlockedVec
// implementują Deref<Target=[u8]>, więc działają bez konwersji.
//
// Conforms to the aa3fvcx.txt spec: replaces Fernet (AES-128-CBC+HMAC) with
// ChaCha20-Poly1305 AEAD as the primary encryption scheme.
// ═══════════════════════════════════════════════════════════════════════════════

use chacha20poly1305::{
    aead::{Aead, AeadCore, KeyInit, OsRng},
    ChaCha20Poly1305, Nonce,
};

use crate::secure::SensitiveBytes;

const NONCE_LEN: usize = 12;
const KEY_LEN: usize = 32;

// ═══════════════════════════════════════════════════════════════════════════════
// encrypt — ChaCha20-Poly1305 authenticated encryption
// ═══════════════════════════════════════════════════════════════════════════════
//
// Args:
//     key: 32-byte encryption key. Accepts &[u8], &SensitiveBytes, &MlockedVec
//           (wszystkie przez Deref<Target=[u8]>).
//     plaintext: Data to encrypt.
//
// Returns:
//     nonce (12B) || ciphertext — ready for storage or transmission.

/// Encrypt `plaintext` with `key` using ChaCha20-Poly1305.
/// Returns: nonce (12B) || ciphertext (variable)
pub fn encrypt(key: &[u8], plaintext: &[u8]) -> Result<Vec<u8>, String> {
    if key.len() != KEY_LEN {
        return Err(format!(
            "Key must be exactly {KEY_LEN} bytes, got {}",
            key.len()
        ));
    }
    let cipher = ChaCha20Poly1305::new_from_slice(key).map_err(|e| e.to_string())?;
    let nonce = ChaCha20Poly1305::generate_nonce(&mut OsRng);
    let ciphertext = cipher
        .encrypt(&nonce, plaintext)
        .map_err(|e| e.to_string())?;
    let mut result = nonce.to_vec();
    result.extend_from_slice(&ciphertext);
    Ok(result)
}

// ═══════════════════════════════════════════════════════════════════════════════
// decrypt — ChaCha20-Poly1305 authenticated decryption
// ═══════════════════════════════════════════════════════════════════════════════
//
// Args:
//     key: 32-byte encryption key (accepts &[u8], &SensitiveBytes, &MlockedVec).
//     data: nonce (12B) || ciphertext — output of encrypt().
//
// Returns:
//     Decrypted plaintext as Vec<u8>.
//     For RAII auto-zeroizing plaintext, use decrypt_into_sensitive().

/// Decrypt data created by `encrypt`.
/// Input: nonce (12B) || ciphertext
pub fn decrypt(key: &[u8], data: &[u8]) -> Result<Vec<u8>, String> {
    if key.len() != KEY_LEN {
        return Err(format!(
            "Key must be exactly {KEY_LEN} bytes, got {}",
            key.len()
        ));
    }
    if data.len() < NONCE_LEN {
        return Err("Data too short: missing nonce".to_string());
    }
    let (nonce_bytes, ciphertext) = data.split_at(NONCE_LEN);
    let cipher = ChaCha20Poly1305::new_from_slice(key).map_err(|e| e.to_string())?;
    let nonce = Nonce::from_slice(nonce_bytes);
    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| format!("Decryption failed: {e}"))
}

// ═══════════════════════════════════════════════════════════════════════════════
// decrypt_into_sensitive — decrypt with RAII-protected output
// ═══════════════════════════════════════════════════════════════════════════════
//
// Jak decrypt(), ale zwraca SensitiveBytes zamiast Vec<u8>.
// Plaintext jest automatycznie zerowany (zeroize) na drop.
//
// Usage:
//     let plaintext = decrypt_into_sensitive(&key, &ciphertext)?;
//     // ... use plaintext ...
//     // plaintext.drop() → zeroize automatically
//     // No need to manually zeroize!

/// Decrypt data and return the plaintext wrapped in SensitiveBytes (RAII).
///
/// The returned SensitiveBytes is automatically zeroized on drop.
/// Prefer this over decrypt() when handling sensitive plaintext.
///
/// Args:
///     key: 32-byte encryption key (accepts &[u8], &SensitiveBytes, &MlockedVec).
///     data: nonce (12B) || ciphertext from encrypt().
///
/// Returns:
///     SensitiveBytes containing the decrypted plaintext.
pub fn decrypt_into_sensitive(key: &[u8], data: &[u8]) -> Result<SensitiveBytes, String> {
    let plaintext = decrypt(key, data)?;
    log::debug!(
        "decrypt_into_sensitive: {} bytes plaintext wrapped in SensitiveBytes (RAII)",
        plaintext.len()
    );
    Ok(SensitiveBytes::from_vec(plaintext))
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tests — AEAD encrypt/decrypt + decrypt_into_sensitive
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    fn test_key() -> Vec<u8> {
        vec![0xABu8; 32]
    }

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let key = test_key();
        let plaintext = b"Hello, NexusAI AEAD!";

        let ciphertext = encrypt(&key, plaintext).expect("encrypt should succeed");
        assert!(ciphertext.len() > plaintext.len(), "ciphertext should include nonce");
        assert_eq!(ciphertext.len(), 12 + plaintext.len() + 16 /* tag */);

        let decrypted = decrypt(&key, &ciphertext).expect("decrypt should succeed");
        assert_eq!(decrypted, plaintext, "decrypted should match original");
    }

    #[test]
    fn test_encrypt_different_keys() {
        let key1 = test_key();
        let mut key2 = test_key();
        key2[0] = 0x42; // different key
        let plaintext = b"Sensitive data";

        let ciphertext = encrypt(&key1, plaintext).expect("encrypt with key1");
        let result = decrypt(&key2, &ciphertext);
        assert!(result.is_err(), "decrypt with wrong key should fail");
    }

    #[test]
    fn test_encrypt_wrong_key_length() {
        let short_key = vec![0xABu8; 16]; // 16 bytes, not 32
        let result = encrypt(&short_key, b"test");
        assert!(result.is_err(), "encrypt with short key should fail");
        assert!(result.unwrap_err().contains("Key must be exactly"));
    }

    #[test]
    fn test_decrypt_wrong_key_length() {
        let short_key = vec![0xABu8; 16];
        let result = decrypt(&short_key, &[0u8; 32]);
        assert!(result.is_err(), "decrypt with short key should fail");
        assert!(result.unwrap_err().contains("Key must be exactly"));
    }

    #[test]
    fn test_decrypt_short_data() {
        let key = test_key();
        let result = decrypt(&key, &[0u8; 4]);
        assert!(result.is_err(), "decrypt with too short data should fail");
        assert!(result.unwrap_err().contains("missing nonce"));
    }

    #[test]
    fn test_decrypt_tampered_ciphertext() {
        let key = test_key();
        let plaintext = b"Tamper test data";

        let mut ciphertext = encrypt(&key, plaintext).expect("encrypt");
        // Tamper with a byte in the ciphertext portion (after nonce)
        if ciphertext.len() > 13 {
            ciphertext[13] ^= 0xFF; // flip bits
        }

        let result = decrypt(&key, &ciphertext);
        assert!(result.is_err(), "decrypt of tampered data should fail");
    }

    #[test]
    fn test_encrypt_empty_plaintext() {
        let key = test_key();
        let ciphertext = encrypt(&key, b"").expect("encrypt empty should succeed");
        let decrypted = decrypt(&key, &ciphertext).expect("decrypt empty should succeed");
        assert_eq!(decrypted, b"", "empty plaintext roundtrip");
    }

    #[test]
    fn test_encrypt_large_data() {
        let key = test_key();
        let plaintext = vec![0x42u8; 1_000_000]; // 1 MB

        let ciphertext = encrypt(&key, &plaintext).expect("encrypt large data");
        let decrypted = decrypt(&key, &ciphertext).expect("decrypt large data");
        assert_eq!(decrypted, plaintext, "large data roundtrip");
    }

    #[test]
    fn test_decrypt_into_sensitive_roundtrip() {
        let key = test_key();
        let plaintext = b"Sensitive data — will be zeroized on drop";

        let ciphertext = encrypt(&key, plaintext).expect("encrypt");
        let sensitive = decrypt_into_sensitive(&key, &ciphertext).expect("decrypt_into_sensitive");

        // Should match original
        assert_eq!(sensitive.len(), plaintext.len());
        assert_eq!(&sensitive[..], &plaintext[..]);

        // Should be SensitiveBytes (with RAII zeroize)
        let hex = sensitive.hexdigest();
        assert_eq!(hex.len(), 16); // first 8 bytes as hex
    }

    #[test]
    fn test_encrypt_deterministic_nonce() {
        // Nonce should be different each time (ChaCha20Poly1305::generate_nonce uses OsRng)
        let key = test_key();
        let plaintext = b"Same plaintext";

        let ct1 = encrypt(&key, plaintext).expect("encrypt 1");
        let ct2 = encrypt(&key, plaintext).expect("encrypt 2");

        // Nonces (first 12 bytes) should differ
        assert_ne!(&ct1[..12], &ct2[..12], "nonces should be different");
    }
}
