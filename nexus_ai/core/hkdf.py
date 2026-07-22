"""
HKDF Key Separation — Key Derivation for Context-Specific Encryption Keys (INNOWACJA #1 v7.0).

Raport v7.0 INNOWACJA #1:
  Zamiast jednego klucza dla wszystkich danych, używamy HKDF-SHA256
  do wyprowadzenia osobnych kluczy dla każdego kontekstu:
    - root_key → HKDF(info="backups") → backup_key
    - root_key → HKDF(info="secrets") → secrets_key
    - root_key → HKDF(info="vault") → vault_key
  Każdy klucz ma inny cel — compromise jednego nie zagraża pozostałym.

Enterprise v7.0:
  - RFC 5869 HKDF-SHA256
  - Deterministic derivation (same root + same info = same key)
  - Salt from CSPRNG per session (prevents cross-session key reuse)
  - Context labels enforce domain separation
"""

from __future__ import annotations

import hashlib
import hmac
from typing import Final


# ── HKDF-SHA256 constants (RFC 5869) ──────────────────────────────────────
HASH_LEN: Final[int] = 32  # SHA-256 output length
MAX_OUTPUT_LEN: Final[int] = 255 * HASH_LEN  # Max 8160 bytes


def hkdf_extract(salt: bytes, ikm: bytes) -> bytes:
    """HKDF-Extract: PRK = HMAC-SHA256(salt, IKM).

    RFC 5869 Section 2.2.
    """
    if not salt:
        salt = b"\x00" * HASH_LEN
    return hmac.new(salt, ikm, hashlib.sha256).digest()


def hkdf_expand(prk: bytes, info: bytes, length: int = HASH_LEN) -> bytes:
    """HKDF-Expand: OKM = T(1) || T(2) || ...

    RFC 5869 Section 2.3.
    """
    if length > MAX_OUTPUT_LEN:
        raise ValueError(f"Output length {length} exceeds HKDF max {MAX_OUTPUT_LEN}")

    n = (length + HASH_LEN - 1) // HASH_LEN
    t = b""
    output = b""

    for i in range(1, n + 1):
        t = hmac.new(prk, t + info + bytes([i]), hashlib.sha256).digest()
        output += t

    return output[:length]


def hkdf_derive(ikm: bytes, salt: bytes | None = None, info: bytes = b"", length: int = HASH_LEN) -> bytes:
    """HKDF-SHA256: Extract-then-Expand (RFC 5869).

    Args:
        ikm: Input Keying Material (the root key).
        salt: Optional salt (CSPRNG recommended). If None, uses all-zeros.
        info: Context/label string (e.g., b"vault", b"backups", b"secrets").
        length: Desired output key length in bytes (default 32 = 256-bit).

    Returns:
        Derived key of specified length.
    """
    salt = salt or b"\x00" * HASH_LEN
    prk = hkdf_extract(salt, ikm)
    return hkdf_expand(prk, info, length)


# ── Predefined context labels for domain separation ───────────────────────

class KeyContext:
    """Domain separation labels for HKDF context strings."""

    VAULT: Final[bytes] = b"nexusai:vault:v7.0"
    BACKUPS: Final[bytes] = b"nexusai:backups:v7.0"
    SECRETS: Final[bytes] = b"nexusai:secrets:v7.0"
    SQLCIPHER: Final[bytes] = b"nexusai:sqlcipher:v7.0"
    JWT_REFRESH: Final[bytes] = b"nexusai:jwt-refresh:v7.0"
    PROOF_CHAIN: Final[bytes] = b"nexusai:proof-chain:v7.0"
    LOCAL_CACHE: Final[bytes] = b"nexusai:local-cache:v7.0"


def derive_context_key(root_key: bytes, context: bytes, *, length: int = 32) -> bytes:
    """Derive a context-specific key from the root key.

    Uses deterministic HKDF derivation (zero salt) so the same
    root_key + context always produces the same derived key.
    This is essential for key recovery -- encrypted data must be
    decryptable by re-deriving the same key.

    Usage:
        vault_key = derive_context_key(root_key, KeyContext.VAULT)
        backup_key = derive_context_key(root_key, KeyContext.BACKUPS)

    Compromise of one derived key does NOT compromise others.
    """
    # Zero salt for deterministic derivation (RFC 5869 allows this)
    return hkdf_derive(ikm=root_key, salt=None, info=context, length=length)
