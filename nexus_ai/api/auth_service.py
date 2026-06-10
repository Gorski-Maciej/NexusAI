from __future__ import annotations

import base64
import os

from nexus_crypto import hash_password as nexus_hash_password
from nexus_crypto import verify_password as nexus_verify_password

PBKDF2_ITERATIONS = 120_000


def hash_password(password: str, *, salt: bytes | None = None) -> str:
    """Hash password using Argon2id (nexus-crypto, Rust+PyO3).

    Zgodnie z aa3fvcx.txt (Punkt 8):
    - Argon2id (PHC winner) zastępuje PBKDF2
    - Odporny na ataki GPU i side-channel

    Format zwracanego hasha: PHC string (argon2).
    """
    return nexus_hash_password(password)


def verify_password(password: str, encoded: str) -> bool:
    """Verify password against Argon2id PHC hash (nexus-crypto).

    Wspiera zarówno nowy format (Argon2id) jak i legacy PBKDF2.
    """
    # Próba weryfikacji przez Argon2id (nowy format)
    try:
        return nexus_verify_password(password, encoded)
    except Exception:
        pass

    # Fallback: legacy PBKDF2 (kompatybilność wsteczna)
    try:
        algo, iter_s, salt_b64, hash_b64 = encoded.split("$", 3)
        if algo != "pbkdf2_sha256":
            return False
        iters = int(iter_s)
        salt = base64.b64decode(salt_b64.encode())
        expected = base64.b64decode(hash_b64.encode())
        import hashlib
        import hmac
        check = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iters)
        return hmac.compare_digest(check, expected)
    except Exception:
        return False
