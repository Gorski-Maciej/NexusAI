"""
Biometric MFA — dwuskladnikowe uwierzytelnianie biometryczne (INNOWACJA #10 v7.0).

Raport v7.0 INNOWACJA #10:
  Dodac biometrie (odcisk palca / Face ID) jako drugi
  skladnik uwierzytelniania dla krytycznych operacji
  (zatwierdzanie przelewu > 50k PLN, zmiana planu kont).

Enterprise v7.0:
  - Platform detection: Touch ID (macOS/iOS), Windows Hello, Linux (howdy)
  - Challenge-response: generuj nonce → podpisz biometrycznie → zweryfikuj
  - Thresholds: operacje > 50k PLN wymagaja MFA
  - Session MFA caching: 15 minut bez ponownego pytania
  - Fallback: TOTP/HOTP gdy biometria niedostepna
  - Audit: kazda proba MFA jest logowana
"""

from __future__ import annotations

import hashlib
import hmac
import os
import platform
import time as _time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.mfa")


class MFAMethod(Enum):
    """Metody MFA."""

    BIOMETRIC = "biometric"  # Odcisk palca / Face ID
    TOTP = "totp"  # Time-based One-Time Password (fallback)
    HOTP = "hotp"  # HMAC-based OTP


class MFAOperation(Enum):
    """Operacje wymagajace MFA."""

    TRANSFER_OVER_50K = "transfer_over_50k"
    CHANGE_TAX_FORM = "change_tax_form"
    DELETE_COMPANY = "delete_company"
    EXPORT_ALL_DATA = "export_all_data"
    ADMIN_SETTINGS = "admin_settings"


@dataclass
class MFAChallenge:
    """Wyzwanie MFA."""

    challenge_id: str
    nonce: str  # Base64 losowego nonce
    operation: MFAOperation
    method: MFAMethod
    created_at: float  # timestamp
    expires_at: float  # timestamp + 5 minut
    verified: bool = False


@dataclass
class MFASession:
    """Sesja MFA — cache na 15 minut."""

    user_id: str
    verified_at: float
    operations: set[MFAOperation] = field(default_factory=set)


class BiometricMFAService:
    """Serwis biometrycznego MFA.

    Usage:
        mfa = BiometricMFAService()
        
        # Wygeneruj wyzwanie dla krytycznej operacji
        challenge = mfa.create_challenge(
            user_id="user-123",
            operation=MFAOperation.TRANSFER_OVER_50K,
        )
        
        # Zweryfikuj odpowiedz biometryczna
        success = mfa.verify_biometric(
            user_id="user-123",
            challenge_id=challenge.challenge_id,
            biometric_proof="signature_data",
        )
        
        # Sprawdz czy MFA jest wymagane
        required = mfa.is_mfa_required(MFAOperation.TRANSFER_OVER_50K)
    """

    CHALLENGE_TTL: int = 300  # 5 minut
    SESSION_TTL: int = 900  # 15 minut
    MFA_AMOUNT_THRESHOLD: float = 50000.0  # PLN
    AUDIT_LOG_MAX: int = 1000  # Max wpisow audytu

    def __init__(self) -> None:
        self._challenges: dict[str, MFAChallenge] = {}
        self._sessions: dict[str, MFASession] = {}
        self._audit_log: list[dict[str, Any]] = []
        self._available_method = self._detect_platform()

    def _detect_platform(self) -> MFAMethod | None:
        """Wykryj dostepna metode biometryczna."""
        system = platform.system()

        if system == "Darwin":  # macOS
            logger.info("[MFA] Platform: macOS — Touch ID available")
            return MFAMethod.BIOMETRIC
        elif system == "Windows":
            logger.info("[MFA] Platform: Windows — Windows Hello available")
            return MFAMethod.BIOMETRIC
        elif system == "Linux":
            # howdy (Linux face recognition) — sprawdz czy zainstalowane
            try:
                result = os.system("which howdy > /dev/null 2>&1")
                if result == 0:
                    logger.info("[MFA] Platform: Linux — howdy (Face ID) available")
                    return MFAMethod.BIOMETRIC
            except Exception:
                pass
            logger.info("[MFA] Platform: Linux — biometric unavailable, fallback to TOTP")
            return MFAMethod.TOTP

        return MFAMethod.TOTP  # Fallback

    # ── Challenge Management ─────────────────────────────────────────────

    def create_challenge(
        self,
        user_id: str,
        operation: MFAOperation,
        *,
        method: MFAMethod | None = None,
    ) -> MFAChallenge:
        """Wygeneruj wyzwanie MFA.

        Args:
            user_id: ID uzytkownika.
            operation: Operacja wymagajaca MFA.
            method: Metoda MFA (auto-detect if None).

        Returns:
            MFAChallenge z nonce i TTL.
        """
        import uuid

        method = method or self._available_method or MFAMethod.TOTP

        challenge_id = uuid.uuid4().hex
        nonce = os.urandom(32).hex()
        now = _time.monotonic()

        challenge = MFAChallenge(
            challenge_id=challenge_id,
            nonce=nonce,
            operation=operation,
            method=method,
            created_at=now,
            expires_at=now + self.CHALLENGE_TTL,
        )

        self._challenges[challenge_id] = challenge

        logger.info(
            "[MFA] Challenge created: id=%s, user=%s, operation=%s, method=%s",
            challenge_id[:8], user_id, operation.value, method.value,
        )

        return challenge

    # ── Verification ────────────────────────────────────────────────────

    def verify_biometric(
        self,
        user_id: str,
        challenge_id: str,
        biometric_proof: str,
    ) -> bool:
        """Zweryfikuj odpowiedz biometryczna.

        W produkcji: wywoluje systemowe API biometryczne
        (Touch ID, Windows Hello, howdy).
        Obecnie: weryfikuje HMAC nonce jako stub.

        Args:
            user_id: ID uzytkownika.
            challenge_id: ID wyzwania.
            biometric_proof: Podpis biometryczny (stub: HMAC nonce).

        Returns:
            True jesli MFA przeszlo pomyslnie.
        """
        challenge = self._challenges.get(challenge_id)
        if challenge is None:
            self._audit("MFA_FAIL", user_id, reason="challenge_not_found")
            return False

        # Sprawdz TTL
        if _time.monotonic() > challenge.expires_at:
            self._audit("MFA_FAIL", user_id, reason="challenge_expired")
            del self._challenges[challenge_id]
            return False

        # Weryfikacja (stub: HMAC challenge nonce z user_id jako klucz)
        expected = hmac.new(
            user_id.encode("utf-8"),
            challenge.nonce.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest()

        if not hmac.compare_digest(expected, biometric_proof):
            self._audit("MFA_FAIL", user_id, reason="invalid_proof")
            return False

        # Sukces
        challenge.verified = True

        # Utworz sesje MFA (15 min cache)
        self._sessions[user_id] = MFASession(
            user_id=user_id,
            verified_at=_time.monotonic(),
            operations={challenge.operation},
        )

        self._audit("MFA_SUCCESS", user_id, operation=challenge.operation.value)
        logger.info("[MFA] Verified: user=%s, operation=%s", user_id, challenge.operation.value)

        return True

    def verify_totp(self, user_id: str, token: str, secret: str) -> bool:
        """Zweryfikuj TOTP (fallback gdy biometria niedostepna).

        Args:
            user_id: ID uzytkownika.
            token: 6-cyfrowy kod TOTP.
            secret: Base32 TOTP secret.

        Returns:
            True jesli token poprawny.
        """
        # TOTP verification (stub — w produkcji uzywa pyotp)
        if not token or len(token) != 6:
            self._audit("MFA_FAIL", user_id, reason="invalid_totp_format")
            return False

        # Simple HMAC-based TOTP stub
        try:
            time_step = int(_time.time() // 30)
            msg = time_step.to_bytes(8, "big")
            h = hmac.new(secret.encode("utf-8"), msg, hashlib.sha256).digest()
            offset = h[-1] & 0x0F
            code = int.from_bytes(h[offset:offset + 4], "big") & 0x7FFFFFFF
            expected = str(code % 1_000_000).zfill(6)

            if hmac.compare_digest(expected, token):
                self._audit("MFA_SUCCESS", user_id, method="totp")
                return True
        except Exception as exc:
            logger.warning("[MFA] TOTP verification failed: %s", exc)

        self._audit("MFA_FAIL", user_id, reason="invalid_totp")
        return False

    # ── MFA Requirements ─────────────────────────────────────────────────

    def is_mfa_required(self, operation: MFAOperation) -> bool:
        """Czy ta operacja wymaga MFA?"""
        return operation in {
            MFAOperation.TRANSFER_OVER_50K,
            MFAOperation.CHANGE_TAX_FORM,
            MFAOperation.DELETE_COMPANY,
            MFAOperation.EXPORT_ALL_DATA,
            MFAOperation.ADMIN_SETTINGS,
        }

    def is_session_valid(self, user_id: str, operation: MFAOperation) -> bool:
        """Czy istnieje wazna sesja MFA dla tej operacji?"""
        session = self._sessions.get(user_id)
        if session is None:
            return False

        if _time.monotonic() - session.verified_at > self.SESSION_TTL:
            del self._sessions[user_id]
            return False

        return operation in session.operations

    # ── Audit ────────────────────────────────────────────────────────────

    def _audit(
        self,
        event: str,
        user_id: str,
        *,
        reason: str = "",
        operation: str = "",
        method: str = "",
    ) -> None:
        """Zapisz zdarzenie MFA w audycie."""
        self._audit_log.append({
            "event": event,
            "user_id": user_id,
            "reason": reason,
            "operation": operation,
            "method": method or (self._available_method.value if self._available_method else "totp"),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })

        # Trim do maksymalnego rozmiaru
        if len(self._audit_log) > self.AUDIT_LOG_MAX:
            self._audit_log = self._audit_log[-self.AUDIT_LOG_MAX:]

    @property
    def audit_trail(self) -> list[dict[str, Any]]:
        return list(self._audit_log)

    @property
    def available_method(self) -> MFAMethod | None:
        return self._available_method
