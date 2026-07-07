# nexus_crypto/__init__.py
"""Pure Python fallback for nexus-crypto (Rust+PyO3).

Provides the identical public API using standard library + common packages:
  - ChaCha20-Poly1305 AEAD:  encrypt / decrypt (via cryptography)
  - Argon2id KDF:            derive_key, hash_password, verify_password (via argon2-cffi)
  - SHA-256:                 sha256, Sha256Hasher (via hashlib)
  - BLAKE2b:                 blake2b (via hashlib)
  - JWT HS256:              verify_jwt (via pyjwt)
  - PriorityEngine:          legacy priority resolver
  - TemporalManager:         legacy temporal rule manager
"""

from __future__ import annotations

import hashlib
import os
from typing import Any


# ═══════════════════════════════════════════════════════════════════════════════
# Exceptions
# ═══════════════════════════════════════════════════════════════════════════════

class DecryptionError(Exception):
    """Raised when AEAD decryption fails (wrong key, corrupted data)."""
    pass


# ═══════════════════════════════════════════════════════════════════════════════
# SHA-256 (one-shot + streaming)
# ═══════════════════════════════════════════════════════════════════════════════

def sha256(data: bytes | str) -> str:
    """One-shot SHA-256 → lowercase hex string."""
    if isinstance(data, str):
        data = data.encode("utf-8")
    return hashlib.sha256(data).hexdigest()


class Sha256Hasher:
    """Streaming SHA-256 hasher — drop-in replacement for the Rust version.

    Usage::

        h = Sha256Hasher()
        h.update(chunk1)
        h.update(chunk2)
        digest = h.hexdigest()
    """
    __slots__ = ('_hash',)

    def __init__(self) -> None:
        self._hash = hashlib.sha256()

    @staticmethod
    def hexdigest_static(data: bytes) -> str:
        """One-shot hex digest without creating an instance."""
        return hashlib.sha256(data).hexdigest()

    def update(self, data: bytes) -> None:
        self._hash.update(data)

    def hexdigest(self) -> str:
        return self._hash.hexdigest()

    def digest(self) -> bytes:
        return self._hash.digest()


# ═══════════════════════════════════════════════════════════════════════════════
# BLAKE2b
# ═══════════════════════════════════════════════════════════════════════════════

def blake2b(data: bytes, *, digest_size: int = 16) -> bytes:
    """BLAKE2b hash → raw digest bytes.

    Used by TigerBeetle client for deterministic u128 ID generation.
    """
    return hashlib.blake2b(data, digest_size=digest_size).digest()


# ═══════════════════════════════════════════════════════════════════════════════
# AEAD: ChaCha20-Poly1305 (via cryptography)
# ═══════════════════════════════════════════════════════════════════════════════

def _ensure_key_bytes(key: bytes | str | bytearray) -> bytes:
    if isinstance(key, bytearray):
        return bytes(key)
    if isinstance(key, str):
        return key.encode("utf-8")
    return key


def encrypt(key: bytes | str | bytearray, plaintext: bytes) -> bytes:
    """ChaCha20-Poly1305 AEAD encrypt.

    Returns: 12-byte nonce || ciphertext+tag
    """
    from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305

    key_bytes = _ensure_key_bytes(key)
    nonce = os.urandom(12)
    chacha = ChaCha20Poly1305(key_bytes)
    ciphertext = chacha.encrypt(nonce, plaintext, None)
    return nonce + ciphertext


def decrypt(key: bytes | str | bytearray, data: bytes) -> bytes:
    """ChaCha20-Poly1305 AEAD decrypt.

    Expects: 12-byte nonce || ciphertext+tag

    Raises:
        DecryptionError: on authentication failure.
    """
    from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305

    key_bytes = _ensure_key_bytes(key)
    if len(data) < 12:
        raise DecryptionError("Ciphertext too short for AEAD (nonce+tag)")
    nonce = data[:12]
    ciphertext = data[12:]
    chacha = ChaCha20Poly1305(key_bytes)
    try:
        return chacha.decrypt(nonce, ciphertext, None)
    except Exception as exc:
        raise DecryptionError(f"AEAD decryption failed: {exc}") from exc


# ═══════════════════════════════════════════════════════════════════════════════
# Argon2id KDF + Password hashing (via argon2-cffi)
# ═══════════════════════════════════════════════════════════════════════════════

def derive_key(password: str, salt: bytes | None = None) -> tuple[bytes, bytes]:
    """Derive 32-byte encryption key using Argon2id.

    Returns:
        (key: 32 bytes, salt: 16 bytes)
    """
    from argon2.low_level import hash_secret_raw, Type

    if salt is None:
        salt = os.urandom(16)
    key = hash_secret_raw(
        secret=password.encode("utf-8"),
        salt=salt,
        time_cost=3,
        memory_cost=65536,
        parallelism=4,
        hash_len=32,
        type=Type.ID,
    )
    return key, salt


def hash_password(password: str) -> str:
    """Hash password using Argon2id → PHC string.

    Compatible with Litestar's built-in Argon2 hashing.
    """
    from argon2 import PasswordHasher

    ph = PasswordHasher()
    return ph.hash(password)


def verify_password(password: str, encoded: str) -> bool:
    """Verify password against Argon2id PHC hash string."""
    from argon2 import PasswordHasher
    from argon2.exceptions import VerifyMismatchError

    ph = PasswordHasher()
    try:
        return ph.verify(encoded, password)
    except VerifyMismatchError:
        return False
    except Exception:
        return False


# ═══════════════════════════════════════════════════════════════════════════════
# JWT HS256 (via pyjwt)
# ═══════════════════════════════════════════════════════════════════════════════

def verify_jwt(
    token: str,
    secret: str,
    required_issuer: str | None = None,
    required_audience: str | None = None,
) -> dict[str, Any] | None:
    """Verify HS256 JWT and return claims dict.

    Returns ``None`` on any failure (expired, bad signature, wrong issuer).
    """
    import jwt

    try:
        options: dict[str, Any] = {"verify_exp": True}
        if required_issuer:
            options["require"] = ["exp", "iss"]
        claims: dict[str, Any] = jwt.decode(
            token,
            secret,
            algorithms=["HS256"],
            issuer=required_issuer,
            audience=required_audience,
            options=options,
        )
        return claims
    except Exception:
        return None


# ═══════════════════════════════════════════════════════════════════════════════
# PriorityEngine — legacy priority-based rule solver
# ═══════════════════════════════════════════════════════════════════════════════

class PriorityEngine:
    """Legacy priority-based rule engine (Python fallback).

    API compatible with the Rust-native implementation.
    """

    @classmethod
    def resolve(cls, rules, eval_fn):
        """Resolve rules by priority — first match wins.

        Args:
            rules: list of objects with .condition_sql, .action_json, .rule_id, .priority
            eval_fn: callable that takes condition_sql → bool

        Returns:
            MatchResult-like object with matched, rule_id, priority, verdict, error.
        """
        sorted_rules = cls.sort_rules(rules)
        for rule in sorted_rules:
            try:
                if eval_fn(rule.condition_sql):
                    import json as _json

                    verdict = {}
                    if rule.action_json:
                        try:
                            verdict = _json.loads(rule.action_json)
                        except _json.JSONDecodeError:
                            verdict = {}
                    verdict["_rule_id"] = rule.rule_id
                    verdict["_priority"] = rule.priority
                    return type(
                        "MatchResult",
                        (),
                        {
                            "matched": True,
                            "rule_id": rule.rule_id,
                            "priority": rule.priority,
                            "verdict": verdict,
                            "error": "",
                        },
                    )()
            except Exception:
                continue
        return type(
            "MatchResult",
            (),
            {"matched": False, "rule_id": "", "priority": 0, "verdict": {}, "error": "No matching rule"},
        )()

    @staticmethod
    def sort_rules(rules):
        """Sort rules by priority (ascending — lower = higher priority)."""
        return sorted(rules, key=lambda r: r.priority)

    @staticmethod
    def validate_priorities(rules):
        """Detect priority conflicts (same priority + same condition)."""
        warnings: list[dict[str, Any]] = []
        for i, r1 in enumerate(rules):
            for j, r2 in enumerate(rules):
                if i >= j:
                    continue
                if r1.priority == r2.priority and r1.condition_sql == r2.condition_sql:
                    warnings.append({"condition_sql": r1.condition_sql, "priority": r1.priority})
        return warnings


# ═══════════════════════════════════════════════════════════════════════════════
# TemporalManager — legacy temporal rule manager
# ═══════════════════════════════════════════════════════════════════════════════

class TemporalManager:
    """Legacy temporal rule manager (Python fallback).

    API compatible with the Rust-native implementation.
    """
    __slots__ = ('_conn',)

    def __init__(self, conn) -> None:
        self._conn = conn

    def get_active_rules(self, as_of_date):
        """Return rules valid on *as_of_date*."""
        date_str = as_of_date.isoformat() if hasattr(as_of_date, 'isoformat') else str(as_of_date)
        rows = self._conn.execute(
            "SELECT rule_id, condition_sql, action_json, priority, valid_from, valid_to, rule_set_id "
            "FROM tax_rules WHERE valid_from <= ? AND (valid_to IS NULL OR valid_to >= ?) "
            "ORDER BY priority ASC",
            (date_str, date_str),
        ).fetchall()
        result = []
        for r in rows:
            result.append(
                type(
                    "TemporalRule",
                    (),
                    {
                        "rule_id": str(r[0]),
                        "condition_sql": str(r[1]),
                        "action_json": str(r[2]),
                        "priority": int(r[3]),
                        "valid_from": str(r[4]),
                        "valid_to": str(r[5]) if r[5] else None,
                        "rule_set_id": str(r[6]) if len(r) > 6 else "",
                    },
                )()
            )
        return result

    def get_validity_window(self, rule_id: str) -> dict[str, str | None] | None:
        """Return {valid_from, valid_to} for *rule_id* or None."""
        row = self._conn.execute(
            "SELECT valid_from, valid_to FROM tax_rules WHERE rule_id = ?",
            (rule_id,),
        ).fetchone()
        if row is None:
            return None
        return {"valid_from": str(row[0]), "valid_to": str(row[1]) if row[1] else None}

    def is_rule_active_on(self, rule_id: str, as_of_date) -> bool:
        """Check if *rule_id* is active on *as_of_date*."""
        date_str = as_of_date.isoformat() if hasattr(as_of_date, 'isoformat') else str(as_of_date)
        row = self._conn.execute(
            "SELECT 1 FROM tax_rules WHERE rule_id = ? AND valid_from <= ? "
            "AND (valid_to IS NULL OR valid_to >= ?)",
            (rule_id, date_str, date_str),
        ).fetchone()
        return row is not None

    @staticmethod
    def validate_temporal_overlap(rules) -> list[dict[str, Any]]:
        """Detect temporal overlaps for rules with the same condition."""
        conflicts: list[dict[str, Any]] = []
        for i, r1 in enumerate(rules):
            for j, r2 in enumerate(rules):
                if i >= j:
                    continue
                if r1.condition_sql == r2.condition_sql:
                    try:
                        v1_f = str(r1.valid_from)
                        v1_t = str(r1.valid_to) if getattr(r1, 'valid_to', None) else "9999-12-31"
                        v2_f = str(r2.valid_from)
                        v2_t = str(r2.valid_to) if getattr(r2, 'valid_to', None) else "9999-12-31"
                        if v1_f <= v2_t and v2_f <= v1_t:
                            conflicts.append({"condition_sql": r1.condition_sql})
                    except Exception:
                        pass
        return conflicts


# ═══════════════════════════════════════════════════════════════════════════════
# Public API
# ═══════════════════════════════════════════════════════════════════════════════

__all__ = [
    # Exceptions
    "DecryptionError",
    # AEAD
    "encrypt",
    "decrypt",
    # KDF
    "derive_key",
    "hash_password",
    "verify_password",
    # Hashes
    "sha256",
    "Sha256Hasher",
    "blake2b",
    # JWT
    "verify_jwt",
    # Legacy engines
    "PriorityEngine",
    "TemporalManager",
]
