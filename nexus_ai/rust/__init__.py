# ═══════════════════════════════════════════════════════════════════════════════
# nexus_crypto — Python bindings to Rust crypto + tax module
# ═══════════════════════════════════════════════════════════════════════════════
#
# Provides:
#   Crypto primitives (Rust + PyO3):
#     encrypt/decrypt (ChaCha20-Poly1305), hash/verify_password (Argon2id),
#     sha256, hmac_sha256, blake2b, derive_key, generate_key, Sha256Hasher
#
#   Tax arithmetic (Rust + PyO3):
#     TaxMathEngine, to_grosze, to_zlotowki, multiply_net_by_vat, add_tax,
#     calculate_vat_by_policy, validate_invariants,
#     InvoicePositions, InvoiceSummary, ValidationResult, Money
#
# Custom exceptions (PyO3 native):
#   CryptoError, KeyLengthError, DecryptionError, EncryptionError,
#   IntegrityError, HashError
#
# Falls back to hashlib / pure Python when the native Rust extension
# is unavailable.
# ═══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

import hashlib
import hmac
import logging
import os

logger = logging.getLogger("nexus.crypto")


# ── Sha256Hasher — Python fallback (hashlib) ─────────────────────────────────


class Sha256Hasher:
    """Streaming SHA-256 hasher (Python fallback via hashlib).

    Usage::
        h = Sha256Hasher()
        h.update(chunk1)
        h.update(chunk2)
        hex_result = h.hexdigest()
        raw_bytes = h.digest()
        copy = h.copy()
    """

    def __init__(self) -> None:
        self._hasher = hashlib.sha256()

    def update(self, data: bytes) -> None:
        """Feed data into the hasher. Can be called multiple times."""
        self._hasher.update(data)

    def hexdigest(self) -> str:
        """Return the hex digest (64-char string)."""
        return self._hasher.hexdigest()

    def digest(self) -> bytes:
        """Return the raw 32-byte digest."""
        return self._hasher.digest()

    def copy(self) -> Sha256Hasher:
        """Return a copy of the hasher (preserves current state)."""
        new = Sha256Hasher.__new__(Sha256Hasher)
        new._hasher = self._hasher.copy()
        return new

    def __repr__(self) -> str:
        return "<Sha256Hasher>"


# ── Exception classes (Python fallback when native unavailable) ──────────────


class CryptoError(Exception):
    """Base exception for all nexus-crypto errors."""


class KeyLengthError(CryptoError):
    """Raised when an encryption key has an invalid length (must be 32 bytes)."""


class DecryptionError(CryptoError):
    """Raised when decryption fails."""


class EncryptionError(CryptoError):
    """Raised when encryption fails."""


class IntegrityError(CryptoError):
    """Raised when AEAD integrity verification fails."""


class HashError(CryptoError):
    """Raised when a hashing operation fails."""


# ── Try to load the native Rust extension ────────────────────────────────────

try:
    from nexus_crypto._core import (
        CryptoError as _CryptoError,
        DecryptionError as _DecryptionError,
        EncryptionError as _EncryptionError,
        HashError as _HashError,
        IntegrityError as _IntegrityError,
        KeyLengthError as _KeyLengthError,
    )
    from nexus_crypto._core import decrypt as _rust_decrypt
    from nexus_crypto._core import derive_key as _rust_derive_key
    from nexus_crypto._core import encrypt as _rust_encrypt
    from nexus_crypto._core import generate_key as _rust_generate_key
    from nexus_crypto._core import hash_password as _rust_hash_password
    from nexus_crypto._core import sha256 as _rust_sha256
    from nexus_crypto._core import verify_password as _rust_verify_password
    from nexus_crypto._core import (
        Sha256Hasher as _RustSha256Hasher,
        hmac_sha256 as _rust_hmac_sha256,
        blake2b as _rust_blake2b,
    )

    # Tax Math Engine
    from nexus_crypto._core import (
        TaxMathEngine as _RustTaxMathEngine,
        InvoicePositions as _RustInvoicePositions,
        InvoiceSummary as _RustInvoiceSummary,
        ValidationResult as _RustValidationResult,
        Money as _RustMoney,
        to_grosze as _rust_to_grosze,
        to_zlotowki as _rust_to_zlotowki,
        multiply_net_by_vat as _rust_multiply_net_by_vat,
        add_tax as _rust_add_tax,
        calculate_vat_by_policy as _rust_calculate_vat_by_policy,
        validate_invariants as _rust_validate_invariants,
    )

    # JWT verification
    from nexus_crypto._core import (
        decode_jwt_header as _rust_decode_jwt_header,
        verify_jwt as _rust_verify_jwt,
    )

    _HAS_NATIVE = True

    # Override Python fallback with native Rust implementations
    Sha256Hasher = _RustSha256Hasher  # type: ignore[misc]
    hmac_sha256 = _rust_hmac_sha256  # type: ignore[assignment]
    blake2b = _rust_blake2b  # type: ignore[assignment]

    # Override exception classes with native PyO3 implementations
    CryptoError = _CryptoError  # type: ignore[misc]
    KeyLengthError = _KeyLengthError  # type: ignore[misc]
    DecryptionError = _DecryptionError  # type: ignore[misc]
    EncryptionError = _EncryptionError  # type: ignore[misc]
    IntegrityError = _IntegrityError  # type: ignore[misc]
    HashError = _HashError  # type: ignore[misc]

    logger.info(
        "nexus-crypto native extension loaded successfully — "
        "Rust+PyO3 module with custom exceptions, TaxMathEngine, and JWT"
    )

except ImportError as _exc:
    _HAS_NATIVE = False
    logger.warning(
        "nexus-crypto native extension not available (%s) — "
        "using Python fallback (hashlib). "
        "Build with: cd nexus_crypto && maturin build --release",
        _exc,
    )


# ── JWT verification wrappers (bridge from Rust to Python API) ──────────────


def verify_jwt(
    token: str,
    secret: str,
    required_issuer: str | None = None,
    required_audience: str | None = None,
) -> dict | None:
    """Verify a JWT token and return its claims as a Python dict.

    Performs full HS256 signature verification, expiration check,
    not-before check, and optional issuer/audience validation.

    Powered by Rust + jsonwebtoken crate when native module is available.

    Args:
        token: JWT token string (base64url-encoded, 3 parts).
        secret: HMAC-SHA256 secret key.
        required_issuer: Optional expected issuer.
        required_audience: Optional expected audience.

    Returns:
        Dict with decoded claims (sub, iss, aud, exp, nbf, tenant_id, etc.)
        or None if the token is invalid, expired, or tampered.

    Raises:
        ValueError: If the token format is invalid or signature wrong.
    """
    if _HAS_NATIVE:
        try:
            result = _rust_verify_jwt(token, secret, required_issuer, required_audience)
            return dict(result) if result else None
        except ValueError:
            return None
    return _fallback_verify_jwt(token, secret, required_issuer, required_audience)


def decode_jwt_header(token: str) -> dict | None:
    """Decode and return the JWT header without signature verification.

    Args:
        token: JWT token string.

    Returns:
        Dict with header fields (alg, typ) or None if invalid.
    """
    if _HAS_NATIVE:
        try:
            result = _rust_decode_jwt_header(token)
            return dict(result) if result else None
        except ValueError:
            return None
    return _fallback_decode_jwt_header(token)


def _fallback_verify_jwt(
    token: str,
    secret: str,
    required_issuer: str | None = None,
    required_audience: str | None = None,
) -> dict | None:
    """Pure Python fallback for JWT verification (when Rust is unavailable)."""
    import base64 as _b64
    import json
    import time as _time

    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None

        header_b64, payload_b64, signature_b64 = parts

        # Verify signature
        signed = f"{header_b64}.{payload_b64}".encode()
        expected_sig = hmac.new(secret.encode(), signed, hashlib.sha256).digest()
        expected_b64 = _b64.urlsafe_b64encode(expected_sig).rstrip(b"=").decode("utf-8")
        if not hmac.compare_digest(expected_b64, signature_b64):
            return None

        # Decode header
        padded = header_b64 + "=" * (-len(header_b64) % 4)
        header = json.loads(_b64.urlsafe_b64decode(padded))

        if str(header.get("alg", "")).upper() != "HS256":
            return None
        typ = str(header.get("typ", "JWT")).upper()
        if typ not in {"JWT", "AT+JWT"}:
            return None

        # Decode payload
        padded = payload_b64 + "=" * (-len(payload_b64) % 4)
        payload = json.loads(_b64.urlsafe_b64decode(padded))

        now = int(_time.time())

        # Validate exp
        exp = payload.get("exp")
        if exp is not None:
            if int(exp) < now:
                return None

        # Validate nbf
        nbf = payload.get("nbf")
        if nbf is not None:
            if int(nbf) > now:
                return None

        # Validate iss
        if required_issuer:
            if str(payload.get("iss", "")).strip() != required_issuer:
                return None

        # Validate aud
        if required_audience:
            aud = payload.get("aud")
            if isinstance(aud, str):
                if aud != required_audience:
                    return None
            elif isinstance(aud, list):
                if required_audience not in [str(x) for x in aud]:
                    return None
            else:
                return None

        return dict(payload)
    except Exception:
        return None


def _fallback_decode_jwt_header(token: str) -> dict | None:
    """Pure Python fallback for JWT header decoding."""
    import base64 as _b64
    import json

    try:
        parts = token.split(".")
        if len(parts) != 3:
            return None
        padded = parts[0] + "=" * (-len(parts[0]) % 4)
        return json.loads(_b64.urlsafe_b64decode(padded))
    except Exception:
        return None


# ── Crypto primitives ───────────────────────────────────────────────────────


def encrypt(key: bytes, plaintext: bytes) -> bytes:
    """Encrypt plaintext with ChaCha20-Poly1305 AEAD.

    Falls back to plaintext if native extension unavailable.

    Args:
        key: 32-byte encryption key.
        plaintext: Data to encrypt.

    Returns:
        Ciphertext: nonce (12B) || encrypted data.

    Raises:
        KeyLengthError: If key is not exactly 32 bytes.
        EncryptionError: If encryption fails.
    """
    if _HAS_NATIVE:
        return _to_bytes(_rust_encrypt(key, plaintext))
    logger.warning("encrypt() called but native crypto unavailable — returning plaintext")
    return plaintext


def decrypt(key: bytes, data: bytes) -> bytes:
    """Decrypt data encrypted with `encrypt`."""
    if _HAS_NATIVE:
        return _to_bytes(_rust_decrypt(key, data))
    logger.warning("decrypt() called but native crypto unavailable — returning as-is")
    return data


def hash_password(password: str) -> str:
    """Hash password using Argon2id. Falls back to PBKDF2-SHA256."""
    if _HAS_NATIVE:
        return _rust_hash_password(password)
    salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000)
    return f"$pbkdf2-sha256${salt.hex()}${dk.hex()}"


def verify_password(password: str, hash_str: str) -> bool:
    """Verify password against Argon2id hash."""
    if _HAS_NATIVE:
        return _rust_verify_password(password, hash_str)
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


def sha256(data: bytes) -> str:
    """Compute SHA-256 hex digest."""
    if _HAS_NATIVE:
        return _rust_sha256(data)
    return hashlib.sha256(data).hexdigest()


def hmac_sha256(key: bytes, data: bytes) -> bytes:
    """Compute HMAC-SHA256 digest."""
    if _HAS_NATIVE:
        return _to_bytes(_rust_hmac_sha256(key, data))
    return hmac.new(key, data, hashlib.sha256).digest()


def blake2b(data: bytes, digest_size: int = 64) -> bytes:
    """Compute BLAKE2b digest."""
    if _HAS_NATIVE:
        return _to_bytes(_rust_blake2b(data, digest_size))
    return hashlib.blake2b(data, digest_size=digest_size).digest()


def generate_key() -> bytes:
    """Generate a cryptographically secure 32-byte key."""
    if _HAS_NATIVE:
        return _to_bytes(_rust_generate_key())
    return os.urandom(32)


def derive_key(password: str, salt: bytes | None = None) -> tuple[bytes, bytes]:
    """Derive 32-byte encryption key from password using Argon2id."""
    if _HAS_NATIVE:
        k, s = _rust_derive_key(password, salt)
        return (_to_bytes(k), _to_bytes(s))
    if salt is None:
        salt = os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 600_000, dklen=32)
    return (dk, salt)


def _to_bytes(val):
    """Convert list[int] to bytes if needed (PyO3 compat on some platforms)."""
    if isinstance(val, (list, tuple)):
        return bytes(val)
    return val


# ── Tax Math Engine wrappers (bridge from Rust to Python API) ────────────────


def to_grosze(amount: str) -> int:
    """Convert a decimal string to grosze (i64) with ROUND_HALF_UP.

    Args:
        amount: Amount in złotówki as string (e.g. "123.45").

    Returns:
        Amount in grosze, always rounded to nearest integer.
    """
    if _HAS_NATIVE:
        return _rust_to_grosze(amount)
    from decimal import ROUND_HALF_UP, Decimal

    d = Decimal(amount)
    return int((d * Decimal("100")).to_integral_value(rounding=ROUND_HALF_UP))


def to_zlotowki(grosze: int) -> str:
    """Convert grosze back to złotówki string with 2 decimal places.

    Args:
        grosze: Amount in grosze.

    Returns:
        Decimal amount in złotówki as string (e.g. "123.45").
    """
    if _HAS_NATIVE:
        return _rust_to_zlotowki(grosze)
    from decimal import ROUND_HALF_UP, Decimal

    return str((Decimal(grosze) / Decimal("100")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def multiply_net_by_vat(net_grosze: int, vat_rate: str) -> int:
    """Multiply net amount (grosze) by VAT rate, rounded to full grosze.

    Args:
        net_grosze: Net amount in grosze.
        vat_rate: VAT rate as string (e.g. "0.23").

    Returns:
        VAT amount in grosze, rounded to nearest integer.
    """
    if _HAS_NATIVE:
        return _rust_multiply_net_by_vat(net_grosze, vat_rate)
    from decimal import ROUND_HALF_UP, Decimal

    vat_decimal = Decimal(str(net_grosze)) * Decimal(vat_rate)
    return int(vat_decimal.to_integral_value(rounding=ROUND_HALF_UP))


def add_tax(net_grosze: int, vat_grosze: int) -> int:
    """Sum net and VAT in grosze to get brutto."""
    if _HAS_NATIVE:
        return _rust_add_tax(net_grosze, vat_grosze)
    return net_grosze + vat_grosze


def calculate_vat_by_policy(
    positions: list,
    vat_rate: str,
    rounding_level: str,
) -> int:
    """Calculate total VAT according to the chosen rounding strategy.

    ``position`` — round per line, then sum.
    ``total``    — sum net first, then round once.

    Args:
        positions: List of InvoicePositions-like objects (must have .net_grosze and .vat_rate).
        vat_rate: VAT rate as string (e.g. "0.23").
        rounding_level: Must be "position" or "total".

    Returns:
        Total VAT amount in grosze.
    """
    if _HAS_NATIVE:
        # Convert Python positions to Rust InvoicePositions
        rust_positions = [_RustInvoicePositions(p.net_grosze, str(p.vat_rate)) for p in positions]
        return _rust_calculate_vat_by_policy(rust_positions, vat_rate, rounding_level)
    from decimal import ROUND_HALF_UP, Decimal

    rate = Decimal(vat_rate)
    if rounding_level == "position":
        total_vat = 0
        for pos in positions:
            vat_decimal = Decimal(str(pos.net_grosze)) * rate
            total_vat += int(vat_decimal.to_integral_value(rounding=ROUND_HALF_UP))
        return total_vat
    if rounding_level == "total":
        total_net = sum(pos.net_grosze for pos in positions)
        vat_decimal = Decimal(str(total_net)) * rate
        return int(vat_decimal.to_integral_value(rounding=ROUND_HALF_UP))
    raise ValueError(f"Unknown rounding_level: {rounding_level!r}; expected 'position' or 'total'")


def validate_invariants(positions: list, summary) -> object:
    """Validate the three mathematical invariants of an invoice.

    Args:
        positions: List of InvoicePositions-like objects.
        summary: InvoiceSummary-like object with netto_grosze, vat_grosze, brutto_grosze.

    Returns:
        ValidationResult.
    """
    if _HAS_NATIVE:
        rust_positions = [_RustInvoicePositions(p.net_grosze, str(p.vat_rate)) for p in positions]
        return _rust_validate_invariants(
            rust_positions,
            _RustInvoiceSummary(summary.netto_grosze, summary.vat_grosze, summary.brutto_grosze),
        )
    # Pure Python fallback
    from decimal import ROUND_HALF_UP, Decimal

    errors: list[str] = []
    sum_net = sum(p.net_grosze for p in positions)
    if sum_net != summary.netto_grosze:
        diff = sum_net - summary.netto_grosze
        errors.append(
            f"Invariant 1: sum(position netto)={sum_net} gr "
            f"\u2260 summary netto={summary.netto_grosze} gr, diff={diff:+d} gr"
        )
    sum_vat = 0
    for p in positions:
        rate = Decimal(str(p.vat_rate))
        vat_decimal = Decimal(str(p.net_grosze)) * rate
        sum_vat += int(vat_decimal.to_integral_value(rounding=ROUND_HALF_UP))
    if sum_vat != summary.vat_grosze:
        diff = sum_vat - summary.vat_grosze
        errors.append(
            f"Invariant 2: sum(position VAT)={sum_vat} gr "
            f"\u2260 summary VAT={summary.vat_grosze} gr, diff={diff:+d} gr"
        )
    calculated_brutto = summary.netto_grosze + summary.vat_grosze
    if calculated_brutto != summary.brutto_grosze:
        diff = calculated_brutto - summary.brutto_grosze
        errors.append(
            f"Invariant 3: netto ({summary.netto_grosze} gr) + "
            f"VAT ({summary.vat_grosze} gr) = {calculated_brutto} gr "
            f"\u2260 brutto ({summary.brutto_grosze} gr), diff={diff:+d} gr"
        )
    if errors:
        return ValidationResult(is_valid=False, error_message="; ".join(errors))
    return ValidationResult(is_valid=True)


class InvoicePositions:
    """A single invoice line item in grosze.

    Rust-powered when native module is available.
    """

    def __init__(self, net_grosze: int, vat_rate: str) -> None:
        object.__setattr__(self, "net_grosze", net_grosze)
        object.__setattr__(self, "vat_rate", vat_rate)

    def __setattr__(self, name: str, value: Any) -> None:
        raise AttributeError(f"InvoicePositions is immutable: cannot set {name}")

    def __delattr__(self, name: str) -> None:
        raise AttributeError(f"InvoicePositions is immutable: cannot delete {name}")

    @property
    def vat_grosze(self) -> int:
        """VAT for this line, rounded to full grosze."""
        return multiply_net_by_vat(self.net_grosze, self.vat_rate)

    def __repr__(self) -> str:
        return f"InvoicePositions(net_grosze={self.net_grosze}, vat_rate={self.vat_rate!r})"


class InvoiceSummary:
    """Invoice totals in grosze."""

    def __init__(self, netto_grosze: int, vat_grosze: int, brutto_grosze: int) -> None:
        self.netto_grosze = netto_grosze
        self.vat_grosze = vat_grosze
        self.brutto_grosze = brutto_grosze

    def __repr__(self) -> str:
        return (
            f"InvoiceSummary(netto_grosze={self.netto_grosze}, "
            f"vat_grosze={self.vat_grosze}, brutto_grosze={self.brutto_grosze})"
        )


class ValidationResult:
    """Result of invariant validation."""

    def __init__(self, is_valid: bool, error_message: str = "") -> None:
        self.is_valid = is_valid
        self.error_message = error_message

    def __repr__(self) -> str:
        if self.is_valid:
            return "ValidationResult(is_valid=True)"
        return f"ValidationResult(is_valid=False, error_message={self.error_message!r})"

    def __bool__(self) -> bool:
        return self.is_valid


# Override with Rust implementations when native is available
if _HAS_NATIVE:
    # Use Rust classes directly (they accept same constructor args)
    InvoicePositions = _RustInvoicePositions  # type: ignore[misc]
    InvoiceSummary = _RustInvoiceSummary  # type: ignore[misc]
    ValidationResult = _RustValidationResult  # type: ignore[misc]


class RoundingPolicy:
    """Convenience wrapper around rounding strategy constants and logic."""

    POSITION = "position"
    TOTAL = "total"

    @staticmethod
    def calculate(
        positions: list,
        vat_rate: str,
        rounding_level: str,
    ) -> int:
        """Delegate to calculate_vat_by_policy."""
        return calculate_vat_by_policy(positions, vat_rate, rounding_level)


class TaxMathEngine:
    """Infallible tax math — integer-only, ROUND_HALF_UP, no floats.

    All methods are static. Use as a namespace for clarity.
    """

    to_grosze = staticmethod(to_grosze)
    to_zlotowki = staticmethod(to_zlotowki)
    multiply_net_by_vat = staticmethod(multiply_net_by_vat)
    add_tax = staticmethod(add_tax)
    calculate_vat_by_policy = staticmethod(calculate_vat_by_policy)
    validate_invariants = staticmethod(validate_invariants)


__all__ = [
    # Crypto
    "encrypt", "decrypt", "hash_password", "verify_password",
    "sha256", "derive_key", "generate_key", "Sha256Hasher",
    "hmac_sha256", "blake2b",
    # Custom exceptions
    "CryptoError", "KeyLengthError", "DecryptionError",
    "EncryptionError", "IntegrityError", "HashError",
    # Tax Math Engine
    "TaxMathEngine", "to_grosze", "to_zlotowki",
    "multiply_net_by_vat", "add_tax", "calculate_vat_by_policy",
    "validate_invariants", "InvoicePositions", "InvoiceSummary",
    "ValidationResult", "RoundingPolicy",
    # JWT
    "verify_jwt", "decode_jwt_header",
]
