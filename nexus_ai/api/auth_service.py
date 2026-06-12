from __future__ import annotations

from nexus_crypto import hash_password as nexus_hash_password
from nexus_crypto import verify_password as nexus_verify_password


def hash_password(password: str) -> str:
    """Hash password using Argon2id (nexus-crypto, Rust+PyO3).

    Zgodnie z aa3fvcx.txt (Punkt 8):
    - Argon2id (PHC winner) zastępuje PBKDF2
    - Odporny na ataki GPU i side-channel

    Format zwracanego hasha: PHC string (argon2).
    """
    return nexus_hash_password(password)


def verify_password(password: str, encoded: str) -> bool:
    """Verify password against Argon2id PHC hash (nexus-crypto).

    Obsługuje wyłącznie format Argon2id PHC (nexus-crypto).
    Legacy PBKDF2 hashe są obsługiwane przez nexus_ai.rust fallback.
    """
    try:
        return nexus_verify_password(password, encoded)
    except (ValueError, RuntimeError):
        return False
