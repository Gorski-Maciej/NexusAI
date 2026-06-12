# ═══════════════════════════════════════════════════════════════════════════════
# nexus_crypto — Python bindings to Rust crypto module
# ═══════════════════════════════════════════════════════════════════════════════
#
# Provides:
#   encrypt(key, plaintext)       → bytes  (ChaCha20-Poly1305 AEAD)
#   decrypt(key, data)            → bytes  (ChaCha20-Poly1305 AEAD)
#   hash_password(password)       → str    (Argon2id PHC string)
#   verify_password(password, hash) → bool
#   sha256(data)                  → str    (hex digest)
#   derive_key(password, salt)    → (key, salt)  (Argon2id KDF → 32 bytes)
#
# Falls back to plaintext no-op when the native Rust extension is unavailable.
# ═══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import hashlib
import hmac
import os

from nexus_ai.core.logger import get_logger

logger = get_logger("nexus.crypto")

# Try to load the native Rust extension
try:
    from nexus_crypto._core import (
        decrypt as _rust_decrypt,
    )
    from nexus_crypto._core import (
        derive_key as _rust_derive_key,
    )
    from nexus_crypto._core import (  # type: ignore[import-untyped]
        encrypt as _rust_encrypt,
    )
    from nexus_crypto._core import (
        hash_password as _rust_hash_password,
    )
    from nexus_crypto._core import (
        sha256 as _rust_sha256,
    )
    from nexus_crypto._core import (
        verify_password as _rust_verify_password,
    )

    _HAS_NATIVE = True
except ImportError:
    _HAS_NATIVE = False
    logger.warning(
        "nexus-crypto native extension not available — "
        "using Python fallback (SHA-256 only). "
        "Build with: cd nexus_crypto && maturin develop --release"
    )


def encrypt(key: bytes, plaintext: bytes) -> bytes:
    """Encrypt plaintext with ChaCha20-Poly1305 AEAD.

    Falls back to plaintext if native extension unavailable.

    Args:
        key: 32-byte encryption key.
        plaintext: Data to encrypt.

    Returns:
        Ciphertext: nonce (12B) || encrypted data.
    """
    if _HAS_NATIVE:
        return _to_bytes(_rust_encrypt(key, plaintext))
    logger.warning("encrypt() called but native crypto unavailable — returning plaintext")
    return plaintext


def decrypt(key: bytes, data: bytes) -> bytes:
    """Decrypt data encrypted with `encrypt`.

    Args:
        key: 32-byte encryption key.
        data: nonce (12B) || ciphertext.

    Returns:
        Decrypted plaintext.
    """
    if _HAS_NATIVE:
        return _to_bytes(_rust_decrypt(key, data))
    logger.warning("decrypt() called but native crypto unavailable — returning as-is")
    return data


def hash_password(password: str) -> str:
    """Hash password using Argon2id.

    Falls back to PBKDF2-SHA256 if native unavailable.

    Args:
        password: Password string.

    Returns:
        PHC hash string (or salt+hash if fallback).
    """
    if _HAS_NATIVE:
        return _rust_hash_password(password)
    # Fallback: PBKDF2-SHA256 with random salt
    salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000)
    return f"$pbkdf2-sha256${salt.hex()}${dk.hex()}"


def verify_password(password: str, hash_str: str) -> bool:
    """Verify password against Argon2id hash.

    Args:
        password: Password to verify.
        hash_str: PHC hash string.

    Returns:
        True if password matches.
    """
    if _HAS_NATIVE:
        return _rust_verify_password(password, hash_str)
    # Fallback verification
    try:
        parts = hash_str.split("$")
        if len(parts) >= 4 and parts[1] == "pbkdf2-sha256":
            salt = bytes.fromhex(parts[2])
            expected = bytes.fromhex(parts[3])
            dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000)
            return hmac.compare_digest(dk, expected)
    except (ValueError, IndexError):
        pass
    return False


def _to_bytes(val):
    """Convert list[int] to bytes if needed (PyO3 compat on some platforms)."""
    if isinstance(val, (list, tuple)):
        return bytes(val)
    return val


def sha256(data: bytes) -> str:
    """Compute SHA-256 hex digest.

    Args:
        data: Input bytes.

    Returns:
        64-character hex string.
    """
    if _HAS_NATIVE:
        return _rust_sha256(data)
    return hashlib.sha256(data).hexdigest()


def derive_key(password: str, salt: bytes | None = None) -> tuple[bytes, bytes]:
    """Derive 32-byte encryption key from password using Argon2id.

    Args:
        password: Password to derive from.
        salt: Optional 16-byte salt. Generated randomly if None.

    Returns:
        (derived_key: 32 bytes, salt: 16 bytes)
    """
    if _HAS_NATIVE:
        k, s = _rust_derive_key(password, salt)
        return (_to_bytes(k), _to_bytes(s))
    # Fallback: PBKDF2-SHA256
    if salt is None:
        salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000, dklen=32)
    return (dk, salt)


__all__ = [
    "encrypt",
    "decrypt",
    "hash_password",
    "verify_password",
    "sha256",
    "derive_key",
]
