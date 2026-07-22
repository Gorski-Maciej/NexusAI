"""
Testy dla nowych modułów v7.0 Security Audit.

Pokrywa:
  - ProgressiveRateLimiter — exponential backoff, IP blacklist
  - JWTKeyManager — multi-key rotation, kid support
  - SQLCipherRotationScheduler — auto-rotation schedule
  - RBAC Audit Log — log_rbac_change, get_rbac_audit_log
  - HKDF Key Separation — derive_context_key determinism
"""

from __future__ import annotations

import os
import time as _time

import pytest


# ═══════════════════════════════════════════════════════════════════════════
# Test: ProgressiveRateLimiter
# ═══════════════════════════════════════════════════════════════════════════

class TestProgressiveRateLimiter:
    """Testy progresywnego rate limitera z exponential backoff."""

    def test_initial_violation_blocks_60s(self):
        """Pierwsze 3 naruszenia → 60s blokady."""
        from nexus_ai.services.progressive_rate_limiter import ProgressiveRateLimiter

        limiter = ProgressiveRateLimiter()
        entry = limiter.record_violation("192.168.1.1")
        assert entry.violation_count == 1
        assert entry.current_backoff_seconds == 60.0
        assert not entry.permanently_banned

    def test_multiple_violations_increase_backoff(self):
        """Więcej naruszeń → dłuższa blokada."""
        from nexus_ai.services.progressive_rate_limiter import ProgressiveRateLimiter

        limiter = ProgressiveRateLimiter()

        for _ in range(3):
            limiter.record_violation("192.168.1.2")
        entry = limiter.record_violation("192.168.1.2")
        assert entry.violation_count == 4
        assert entry.current_backoff_seconds == 300.0  # 5 min tier

    def test_permanent_ban_after_threshold(self):
        """20+ naruszeń → permanent ban."""
        from nexus_ai.services.progressive_rate_limiter import ProgressiveRateLimiter

        limiter = ProgressiveRateLimiter()
        ip = "10.0.0.99"

        for _ in range(20):
            limiter.record_violation(ip)
        entry = limiter.record_violation(ip)
        assert entry.permanently_banned
        assert "10.0.0.99" in limiter.permanent_bans

    def test_is_blocked_returns_true_during_block(self):
        """IP jest zablokowane podczas trwania blokady."""
        from nexus_ai.services.progressive_rate_limiter import ProgressiveRateLimiter

        limiter = ProgressiveRateLimiter()
        limiter.record_violation("192.168.1.3")
        assert limiter.is_blocked("192.168.1.3")

    def test_is_blocked_returns_false_for_unknown(self):
        """Nieznane IP nie jest zablokowane."""
        from nexus_ai.services.progressive_rate_limiter import ProgressiveRateLimiter

        limiter = ProgressiveRateLimiter()
        assert not limiter.is_blocked("10.0.0.1")

    def test_unblock_removes_from_blacklist(self):
        """unblock() usuwa IP z blacklisty."""
        from nexus_ai.services.progressive_rate_limiter import ProgressiveRateLimiter

        limiter = ProgressiveRateLimiter()
        ip = "192.168.1.100"
        for _ in range(20):
            limiter.record_violation(ip)
        assert ip in limiter.permanent_bans

        limiter.unblock(ip)
        assert ip not in limiter.permanent_bans
        assert not limiter.is_blocked(ip)

    def test_stats_tracks_blocks(self):
        """Statystyki śledzą liczbę blokad."""
        from nexus_ai.services.progressive_rate_limiter import ProgressiveRateLimiter

        limiter = ProgressiveRateLimiter()
        for i in range(3):
            limiter.record_violation(f"192.168.1.{i}")
        stats = limiter.stats
        assert stats["total_blocks"] == 3


# ═══════════════════════════════════════════════════════════════════════════
# Test: JWTKeyManager
# ═══════════════════════════════════════════════════════════════════════════

class TestJWTKeyManager:
    """Testy JWT Key ID manager z multi-key rotation."""

    def test_rotate_key_creates_new_kid(self):
        """Rotacja tworzy nowy klucz z unikalnym kid."""
        from nexus_ai.api.jwt_kid import JWTKeyManager

        manager = JWTKeyManager()
        old_kid = manager.active_key.kid if manager.active_key else None

        new_key = manager.rotate_key()
        assert new_key.kid != old_kid if old_kid else True
        assert len(manager.all_kids) >= 1

    def test_rotate_key_preserves_old_key(self):
        """Stary klucz jest zachowany po rotacji (grace period)."""
        from nexus_ai.api.jwt_kid import JWTKeyManager

        manager = JWTKeyManager()
        manager.rotate_key("secret_key_1")
        first_kid = manager.active_key.kid

        manager.rotate_key("secret_key_2")
        assert len(manager.all_kids) == 2
        # Stary klucz wciąż istnieje
        assert manager.get_key(first_kid) is not None

    def test_get_key_returns_none_for_unknown_kid(self):
        """Nieznany kid → None."""
        from nexus_ai.api.jwt_kid import JWTKeyManager

        manager = JWTKeyManager()
        assert manager.get_key("nonexistent_kid") is None

    def test_verify_with_kid_unknown_kid_returns_none(self):
        """Weryfikacja z nieznanym kid → None."""
        from nexus_ai.api.jwt_kid import JWTKeyManager

        manager = JWTKeyManager()
        result = manager.verify_with_kid("fake_token", "nonexistent")
        assert result is None

    def test_stats_returns_active_kid(self):
        """Statystyki zawierają active_kid."""
        from nexus_ai.api.jwt_kid import JWTKeyManager

        manager = JWTKeyManager()
        manager.rotate_key("test_secret")
        stats = manager.stats
        assert stats["active_kid"] is not None
        assert stats["total_keys"] >= 1


# ═══════════════════════════════════════════════════════════════════════════
# Test: SQLCipherRotationScheduler
# ═══════════════════════════════════════════════════════════════════════════

class TestSQLCipherRotationScheduler:
    """Testy schedulera auto-rotacji SQLCipher."""

    def test_is_rotation_due_without_previous(self, tmp_path):
        """Bez poprzedniej rotacji → rotation is due."""
        from nexus_ai.db.sqlcipher_rotation_scheduler import SQLCipherRotationScheduler

        tracker = tmp_path / ".last_sqlcipher_rotation"
        db_path = tmp_path / "test.db"

        scheduler = SQLCipherRotationScheduler(
            db_path=db_path,
            rotation_tracker_path=tracker,
            interval_days=90,
        )
        assert scheduler.is_rotation_due()

    def test_is_rotation_due_after_recent_rotation(self, tmp_path):
        """Niedawna rotacja → not due."""
        from nexus_ai.db.sqlcipher_rotation_scheduler import SQLCipherRotationScheduler
        from datetime import datetime, timezone, timedelta

        tracker = tmp_path / ".last_sqlcipher_rotation"
        db_path = tmp_path / "test.db"

        # Zapisz niedawną rotację
        recent = (datetime.now(timezone.utc) - timedelta(days=10)).isoformat()
        tracker.write_text(recent)

        scheduler = SQLCipherRotationScheduler(
            db_path=db_path,
            rotation_tracker_path=tracker,
            interval_days=90,
        )
        assert not scheduler.is_rotation_due()

    def test_is_rotation_due_after_old_rotation(self, tmp_path):
        """Rotacja sprzed >90 dni → due."""
        from nexus_ai.db.sqlcipher_rotation_scheduler import SQLCipherRotationScheduler
        from datetime import datetime, timezone, timedelta

        tracker = tmp_path / ".last_sqlcipher_rotation"
        db_path = tmp_path / "test.db"

        old = (datetime.now(timezone.utc) - timedelta(days=100)).isoformat()
        tracker.write_text(old)

        scheduler = SQLCipherRotationScheduler(
            db_path=db_path,
            rotation_tracker_path=tracker,
            interval_days=90,
        )
        assert scheduler.is_rotation_due()

    def test_get_rotation_status(self, tmp_path):
        """get_rotation_status zwraca poprawne dane."""
        from nexus_ai.db.sqlcipher_rotation_scheduler import SQLCipherRotationScheduler

        tracker = tmp_path / ".last_sqlcipher_rotation"
        db_path = tmp_path / "test.db"

        scheduler = SQLCipherRotationScheduler(
            db_path=db_path,
            rotation_tracker_path=tracker,
        )
        status = scheduler.get_rotation_status()
        assert status["is_due"] is True
        assert status["interval_days"] == 90
        assert status["last_rotation"] is None


# ═══════════════════════════════════════════════════════════════════════════
# Test: RBAC Audit Log
# ═══════════════════════════════════════════════════════════════════════════

class TestRBACAuditLog:
    """Testy RBAC audit log (v7.0)."""

    def test_log_rbac_change_adds_entry(self):
        """log_rbac_change dodaje wpis do audytu."""
        from nexus_ai.api.rbac import log_rbac_change, get_rbac_audit_log

        log_rbac_change("user-1", "admin", "viewer", "accountant", "promotion")
        entries = get_rbac_audit_log()
        assert len(entries) >= 1
        last = entries[-1]
        assert last["user_id"] == "user-1"
        assert last["old_role"] == "viewer"
        assert last["new_role"] == "accountant"
        assert last["changed_by"] == "admin"

    def test_get_rbac_audit_log_filters_by_user(self):
        """get_rbac_audit_log filtruje po user_id."""
        from nexus_ai.api.rbac import log_rbac_change, get_rbac_audit_log

        log_rbac_change("user-A", "admin", "viewer", "accountant", "")
        log_rbac_change("user-B", "admin", "accountant", "auditor", "")

        entries_a = get_rbac_audit_log(user_id="user-A")
        assert all(e["user_id"] == "user-A" for e in entries_a)

    def test_get_rbac_audit_log_respects_limit(self):
        """get_rbac_audit_log respektuje limit."""
        from nexus_ai.api.rbac import log_rbac_change, get_rbac_audit_log

        for i in range(10):
            log_rbac_change(f"user-{i}", "admin", "viewer", "accountant", "")

        entries = get_rbac_audit_log(limit=5)
        assert len(entries) <= 5


# ═══════════════════════════════════════════════════════════════════════════
# Test: HKDF Key Separation Integration
# ═══════════════════════════════════════════════════════════════════════════

class TestHKDFIntegration:
    """Testy integracji HKDF z systemami (Vault, Secrets)."""

    def test_key_context_all_unique(self):
        """Wszystkie KeyContext są unikalne."""
        from nexus_ai.core.hkdf import KeyContext

        contexts = [
            KeyContext.VAULT,
            KeyContext.BACKUPS,
            KeyContext.SECRETS,
            KeyContext.SQLCIPHER,
            KeyContext.JWT_REFRESH,
            KeyContext.PROOF_CHAIN,
            KeyContext.LOCAL_CACHE,
        ]
        assert len(contexts) == len(set(contexts))

    def test_derive_context_key_is_deterministic(self):
        """Ten sam root_key + context = ten sam klucz."""
        from nexus_ai.core.hkdf import derive_context_key, KeyContext

        root_key = os.urandom(32)
        k1 = derive_context_key(root_key, KeyContext.VAULT)
        k2 = derive_context_key(root_key, KeyContext.VAULT)
        assert k1 == k2

    def test_derive_context_key_different_lengths(self):
        """Różne długości kluczy są obsługiwane."""
        from nexus_ai.core.hkdf import derive_context_key, KeyContext

        root_key = os.urandom(32)
        key16 = derive_context_key(root_key, KeyContext.VAULT, length=16)
        key32 = derive_context_key(root_key, KeyContext.VAULT, length=32)
        assert len(key16) == 16
        assert len(key32) == 32
        assert key16 != key32  # Różne długości = różne klucze


# ═══════════════════════════════════════════════════════════════════════════
# Test: Vault Key Versioning
# ═══════════════════════════════════════════════════════════════════════════

class TestVaultKeyVersioning:
    """Testy key versioning w Vault (v7.0)."""

    def test_encrypt_with_version_adds_prefix(self):
        """encrypt_with_version dodaje prefix v1:."""
        from nexus_ai.core.crypto import Vault
        from nexus_ai.core.config import AppConfig
        import base64, os

        config = AppConfig()
        config.encryption_key = base64.urlsafe_b64encode(os.urandom(32)).decode()
        vault = Vault(config)

        if vault.has_key:
            encrypted = vault.encrypt_with_version("test_data")
            assert encrypted.startswith("v1:")
            # Weryfikacja decrypt_with_version
            decrypted = vault.decrypt_with_version(encrypted)
            assert decrypted == "test_data"

    def test_decrypt_without_version_prefix_is_backward_compat(self):
        """Dane bez prefixu wersji → decrypt_with_version używa ChaCha20."""
        from nexus_ai.core.crypto import Vault
        from nexus_ai.core.config import AppConfig
        import base64, os

        config = AppConfig()
        config.encryption_key = base64.urlsafe_b64encode(os.urandom(32)).decode()
        vault = Vault(config)

        if vault.has_key:
            # Szyfruj starą metodą (bez prefixu)
            encrypted_legacy = vault.encrypt("legacy_data")
            # Powinno się odszyfrować decrypt_with_version
            decrypted = vault.decrypt_with_version(encrypted_legacy)
            assert decrypted == "legacy_data"
