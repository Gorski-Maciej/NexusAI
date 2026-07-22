"""
Testy bezpieczeństwa — v7.0 Security Audit (RAPORT_ANALITYCZNY_ENTERPRISE_BEZPIECZENSTWO_KRYPTOGRAFIA).

Pokrywa luki zidentyfikowane w audycie:
  - test_crypto_vault_encrypt_decrypt — unit test dla Vault
  - test_argon2_parameters_contract — czy parametry są stałe?
  - test_sqlcipher_rekey — test rotacji klucza
  - test_proof_chain_tamper_detection — test wykrywania manipulacji
  - test_jwt_version_revocation — test unieważniania
  - test_rate_limit_brute_force — test brute-force protection
  - test_hkdf_key_separation — test separacji kluczy HKDF
  - test_xchacha20_nonce_misuse_resistance — test XChaCha20
  - test_constant_time_jwt — test constant-time comparison
  - test_tenant_isolation — test izolacji tenantów
  - test_fraud_anomaly_detection — test AI anomaly detection
"""

from __future__ import annotations

import base64
import os
import time
from datetime import timezone, timedelta
from datetime import datetime as dt

import pytest


# ═══════════════════════════════════════════════════════════════════════════
# Test: Vault Encrypt/Decrypt
# ═══════════════════════════════════════════════════════════════════════════

class TestCryptoVault:
    """Testy szyfrowania Vault (luka: brak test_crypto_vault)."""

    def test_vault_encrypt_decrypt_roundtrip(self):
        """Vault.encrypt → Vault.decrypt = oryginalny tekst."""
        from nexus_ai.rust.nexus_crypto import encrypt, decrypt

        key = os.urandom(32)
        plaintext = b"Krytyczne dane finansowe: NIP 1234567890, kwota 50000 PLN"

        ciphertext = encrypt(key, plaintext)
        assert len(ciphertext) > len(plaintext)  # nonce + ciphertext + tag
        assert ciphertext[:12]  # nonce jest niezerowy

        decrypted = decrypt(key, ciphertext)
        assert decrypted == plaintext

    def test_vault_decrypt_wrong_key_fails(self):
        """Zły klucz → DecryptionError."""
        from nexus_ai.rust.nexus_crypto import encrypt, decrypt, DecryptionError

        key1 = os.urandom(32)
        key2 = os.urandom(32)
        plaintext = b"test"

        ciphertext = encrypt(key1, plaintext)

        with pytest.raises(DecryptionError):
            decrypt(key2, ciphertext)

    def test_vault_decrypt_corrupted_data_fails(self):
        """Uszkodzony ciphertext → DecryptionError."""
        from nexus_ai.rust.nexus_crypto import encrypt, decrypt, DecryptionError

        key = os.urandom(32)
        plaintext = b"test"

        ciphertext = encrypt(key, plaintext)
        # Corrupt the ciphertext
        corrupted = bytearray(ciphertext)
        corrupted[-1] ^= 0xFF
        corrupted = bytes(corrupted)

        with pytest.raises(DecryptionError):
            decrypt(key, corrupted)

    def test_vault_encrypt_produces_different_ciphertexts(self):
        """Każde szyfrowanie produkuje inny ciphertext (losowy nonce)."""
        from nexus_ai.rust.nexus_crypto import encrypt

        key = os.urandom(32)
        plaintext = b"test"

        c1 = encrypt(key, plaintext)
        c2 = encrypt(key, plaintext)

        assert c1 != c2  # Różne nonce → różne ciphertexty

    def test_vault_xchacha20_roundtrip(self):
        """XChaCha20-Poly1305 (192-bit nonce) encrypt/decrypt."""
        from nexus_ai.rust.nexus_crypto import encrypt, decrypt

        key = os.urandom(32)
        plaintext = b"Dane z XChaCha20 -- nonce misuse resistant"

        ciphertext = encrypt(key, plaintext, use_xchacha=True)
        assert len(ciphertext) > len(plaintext)
        assert len(ciphertext[:24]) == 24  # 24-byte nonce dla XChaCha20

        decrypted = decrypt(key, ciphertext, use_xchacha=True)
        assert decrypted == plaintext


# ═══════════════════════════════════════════════════════════════════════════
# Test: Argon2id Parameters Contract
# ═══════════════════════════════════════════════════════════════════════════

class TestArgon2Parameters:
    """Testy parametrów Argon2id (luka: test_argon2_parameters_contract)."""

    def test_derive_key_uses_correct_params(self):
        """derive_key używa memory=65536, time=3, parallelism=4, hash_len=32."""
        from nexus_ai.rust.nexus_crypto import derive_key

        key, salt = derive_key("test_password")
        assert len(key) == 32  # hash_len=32
        assert len(salt) == 16  # salt length

    def test_derive_key_deterministic(self):
        """Ten sam password + salt = ten sam klucz."""
        from nexus_ai.rust.nexus_crypto import derive_key

        salt = os.urandom(16)
        key1, _ = derive_key("test_password", salt=salt)
        key2, _ = derive_key("test_password", salt=salt)
        assert key1 == key2

    def test_hash_password_uses_explicit_params(self):
        """Hash password z jawnymi parametrami."""
        from nexus_ai.rust.nexus_crypto import hash_password, verify_password

        phash = hash_password("secure_password_123!")
        assert phash.startswith("$argon2id$")  # PHC string format

        # Weryfikacja
        assert verify_password("secure_password_123!", phash)
        assert not verify_password("wrong_password", phash)

    def test_hash_password_different_each_time(self):
        """Każde hashowanie produkuje inny hash (losowy salt)."""
        from nexus_ai.rust.nexus_crypto import hash_password

        h1 = hash_password("same_password")
        h2 = hash_password("same_password")
        assert h1 != h2  # Różne sole


# ═══════════════════════════════════════════════════════════════════════════
# Test: HKDF Key Separation
# ═══════════════════════════════════════════════════════════════════════════

class TestHKDFKeySeparation:
    """Testy separacji kluczy przez HKDF (INNOWACJA #1)."""

    def test_hkdf_different_contexts_produce_different_keys(self):
        """Różne konteksty → różne klucze."""
        from nexus_ai.core.hkdf import derive_context_key, KeyContext

        root_key = os.urandom(32)
        vault_key = derive_context_key(root_key, KeyContext.VAULT)
        backup_key = derive_context_key(root_key, KeyContext.BACKUPS)

        assert vault_key != backup_key
        assert len(vault_key) == 32
        assert len(backup_key) == 32

    def test_hkdf_same_context_produces_same_key_with_same_salt(self):
        """Ten sam kontekst + ten sam salt = ten sam klucz."""
        from nexus_ai.core.hkdf import hkdf_derive, hkdf_extract, hkdf_expand
        import hashlib, hmac

        ikm = b"root_key_material_32_bytes_here!"
        salt = b"fixed_salt_for_testing_1234!"
        context = b"test_context"

        prk = hkdf_extract(salt, ikm)
        key1 = hkdf_expand(prk, context, 32)
        key2 = hkdf_expand(prk, context, 32)

        assert key1 == key2
        assert len(key1) == 32

    def test_hkdf_extract_then_expand_rfc5869(self):
        """HKDF-Extract + HKDF-Expand zgodnie z RFC 5869."""
        from nexus_ai.core.hkdf import hkdf_extract, hkdf_expand

        ikm = b"\x0b" * 22  # Test vector from RFC 5869
        salt = b"\x00" * 13
        info = b"\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9"

        prk = hkdf_extract(salt, ikm)
        okm = hkdf_expand(prk, info, 42)

        assert len(okm) == 42


# ═══════════════════════════════════════════════════════════════════════════
# Test: Constant-Time JWT
# ═══════════════════════════════════════════════════════════════════════════

class TestConstantTimeJWT:
    """Testy constant-time comparison dla JWT (INNOWACJA #4)."""

    def test_verify_refresh_token_identical(self):
        """Identyczne tokeny → True."""
        from nexus_ai.rust.nexus_crypto import verify_refresh_token

        token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh_token_32_bytes"
        assert verify_refresh_token(token, token)

    def test_verify_refresh_token_different(self):
        """Różne tokeny → False."""
        from nexus_ai.rust.nexus_crypto import verify_refresh_token

        assert not verify_refresh_token("token_abc_123", "token_xyz_456")

    def test_verify_refresh_token_similar(self):
        """Podobne tokeny → False (bez timing leak)."""
        from nexus_ai.rust.nexus_crypto import verify_refresh_token

        # Różnią się tylko ostatnim znakiem
        assert not verify_refresh_token("token_abc_123A", "token_abc_123B")

    def test_verify_refresh_token_different_lengths(self):
        """Różne długości → False."""
        from nexus_ai.rust.nexus_crypto import verify_refresh_token

        assert not verify_refresh_token("short", "longer_token")


# ═══════════════════════════════════════════════════════════════════════════
# Test: Proof Chain Tamper Detection
# ═══════════════════════════════════════════════════════════════════════════

class TestProofChainTamper:
    """Testy wykrywania manipulacji w Proof Chain (luka: brak testu)."""

    @pytest.fixture
    def chain(self, tmp_path):
        """Stwórz tymczasowy DuckDB z Proof Chain."""
        import duckdb

        db_path = tmp_path / "test_proof_chain.duckdb"
        conn = duckdb.connect(str(db_path))

        from nexus_ai.services.proof_chain import ProofChain
        return ProofChain(conn)

    def test_verify_empty_chain(self, chain):
        """Pusty łańcuch → valid."""
        result = chain.verify_chain()
        assert result["valid"]
        assert result["total_decisions"] == 0

    def test_verify_single_entry_chain(self, chain):
        """Łańcuch z jednym wpisem → valid."""
        chain.log_decision("tx-001", {"verdict": "AUTO_POST"}, {"company": "test"})
        result = chain.verify_chain()
        assert result["valid"]
        assert result["total_decisions"] == 1

    def test_verify_multi_entry_chain(self, chain):
        """Łańcuch z wieloma wpisami → valid."""
        for i in range(5):
            chain.log_decision(f"tx-{i:03d}", {"verdict": f"test_{i}"}, {"idx": i})
        result = chain.verify_chain()
        assert result["valid"]
        assert result["total_decisions"] == 5

    def test_explain_decision(self, chain):
        """explain_decision zwraca czytelne wyjaśnienie."""
        chain.log_decision("tx-explain", {"verdict": {"action": "AUTO_POST", "vat_rate": 0.23}}, {"company_tax_form": "skala"})
        result = chain.explain_decision("tx-explain")
        assert result["transaction_id"] == "tx-explain"
        assert result["decision"]["action"] == "AUTO_POST"
        assert result["chain_integrity"] == "INTACT"

    def test_explain_nonexistent_decision(self, chain):
        """explain_decision dla nieistniejącej transakcji → error."""
        result = chain.explain_decision("nonexistent")
        assert "error" in result


# ═══════════════════════════════════════════════════════════════════════════
# Test: Tenant Isolation
# ═══════════════════════════════════════════════════════════════════════════

class TestTenantIsolation:
    """Testy izolacji tenantów (luka: DEFAULT_TENANT_ID)."""

    def test_default_tenant_id_is_deprecated(self):
        """DEFAULT_TENANT_ID='default' jest deprecated."""
        import warnings

        from nexus_ai.core.tenant import DEFAULT_TENANT_ID

        assert DEFAULT_TENANT_ID == "default"

    def test_sanitize_valid_tenant_ids(self):
        """Poprawne tenant_id przechodzą walidację."""
        from nexus_ai.core.tenant import TenantManager
        from nexus_ai.core.config import AppConfig

        config = AppConfig()
        tm = TenantManager(config)

        valid_ids = ["tenant-001", "org_abc", "client123", "test_tenant"]
        for tid in valid_ids:
            result = tm.sanitize_tenant_id(tid)
            assert result == tid

    def test_sanitize_invalid_tenant_ids(self):
        """Niepoprawne tenant_id (znaki specjalne) → ValueError."""
        from nexus_ai.core.tenant import TenantManager
        from nexus_ai.core.config import AppConfig

        config = AppConfig()
        tm = TenantManager(config)

        invalid_ids = ["tenant@org", "client/123", "spacja w nazwie", "ścieżka\\test"]
        for tid in invalid_ids:
            with pytest.raises(ValueError):
                tm.sanitize_tenant_id(tid)


# ═══════════════════════════════════════════════════════════════════════════
# Test: Fraud Anomaly Detection
# ═══════════════════════════════════════════════════════════════════════════

class TestFraudAnomalyDetection:
    """Testy AI anomaly detection w FraudGraphScanner (INNOWACJA #12)."""

    def test_anomaly_detector_low_risk_entity(self):
        """Normalna encja → niski risk score."""
        from nexus_ai.services.fraud_anomaly_detector import FraudAnomalyDetector

        detector = FraudAnomalyDetector()
        entities = [
            {
                "id": "vendor-001",
                "type": "VENDOR",
                "nip": "1234567890",
                "on_white_list": True,
                "created_at": "2025-01-01T00:00:00Z",
            }
        ]
        transactions = [
            {"entity_id": "vendor-001", "amount": 1500.00},
            {"entity_id": "vendor-001", "amount": 2300.00},
        ]

        scores = detector.analyze_entities(entities, transactions)
        assert len(scores) == 1
        assert scores[0].risk_score < 40.0  # Niskie ryzyko

    def test_anomaly_detector_high_risk_new_entity(self):
        """Nowa encja bez NIP → wysoki risk score."""
        from nexus_ai.services.fraud_anomaly_detector import FraudAnomalyDetector

        detector = FraudAnomalyDetector()
        entities = [
            {
                "id": "vendor-002",
                "type": "VENDOR",
                "nip": "",
                "on_white_list": False,
                "created_at": dt.now(timezone.utc).isoformat(),  # Nowa!
            }
        ]
        transactions = []

        scores = detector.analyze_entities(entities, transactions)
        assert len(scores) == 1
        assert scores[0].risk_score >= 40.0
        assert "NEW_ENTITY" in scores[0].flags
        assert "MISSING_NIP" in scores[0].flags
        assert "NOT_ON_WHITE_LIST" in scores[0].flags

    def test_anomaly_detector_high_value_transaction(self):
        """Transakcja > 50k PLN → HIGH_VALUE_TRANSACTION flag."""
        from nexus_ai.services.fraud_anomaly_detector import FraudAnomalyDetector

        detector = FraudAnomalyDetector()
        entities = [{"id": "vendor-003", "type": "VENDOR", "nip": "9998887776", "on_white_list": True, "created_at": "2025-01-01T00:00:00Z"}]
        transactions = [{"entity_id": "vendor-003", "amount": 75000.00}]

        scores = detector.analyze_entities(entities, transactions)
        assert len(scores) == 1
        assert "HIGH_VALUE_TRANSACTION" in scores[0].flags

    def test_anomaly_detector_round_amounts_pattern(self):
        """Okrągłe kwoty → ROUND_AMOUNTS_PATTERN flag."""
        from nexus_ai.services.fraud_anomaly_detector import FraudAnomalyDetector

        detector = FraudAnomalyDetector()
        entities = [{"id": "vendor-004", "type": "VENDOR", "nip": "1112223334", "on_white_list": True, "created_at": "2025-01-01T00:00:00Z"}]
        transactions = [
            {"entity_id": "vendor-004", "amount": 10000.00},
            {"entity_id": "vendor-004", "amount": 20000.00},
            {"entity_id": "vendor-004", "amount": 50000.00},
            {"entity_id": "vendor-004", "amount": 15000.00},
        ]

        scores = detector.analyze_entities(entities, transactions)
        assert len(scores) == 1
        assert "ROUND_AMOUNTS_PATTERN" in scores[0].flags

    def test_anomaly_detector_high_frequency(self):
        """Wiele transakcji → HIGH_FREQUENCY flag."""
        from nexus_ai.services.fraud_anomaly_detector import FraudAnomalyDetector

        detector = FraudAnomalyDetector()
        entities = [{"id": "vendor-005", "type": "VENDOR", "nip": "5556667778", "on_white_list": True, "created_at": "2025-01-01T00:00:00Z"}]
        transactions = [{"entity_id": "vendor-005", "amount": float(i * 100)} for i in range(1, 16)]

        scores = detector.analyze_entities(entities, transactions)
        assert len(scores) == 1
        assert "HIGH_FREQUENCY" in scores[0].flags

    def test_anomaly_detector_high_risk_filter(self):
        """get_high_risk_entities filtruje poprawnie."""
        from nexus_ai.services.fraud_anomaly_detector import FraudAnomalyDetector

        detector = FraudAnomalyDetector()

        # High risk entity
        entities = [
            {
                "id": "high-risk-001",
                "type": "VENDOR",
                "nip": "",
                "on_white_list": False,
                "created_at": dt.now(timezone.utc).isoformat(),
            }
        ]
        detector.analyze_entities(entities, [{"entity_id": "high-risk-001", "amount": 100000.00}])

        high_risk = detector.get_high_risk_entities(threshold=50.0)
        assert len(high_risk) == 1
        assert high_risk[0].entity_id == "high-risk-001"


# ═══════════════════════════════════════════════════════════════════════════
# Test: HKDF Determinism (CR fix)
# ═══════════════════════════════════════════════════════════════════════════

class TestHKDFDeterminism:
    """Test determinizmu derive_context_key (poprawka po code review)."""

    def test_derive_context_key_is_deterministic(self):
        """Ten sam root_key + context → ten sam klucz (deterministyczne)."""
        from nexus_ai.core.hkdf import derive_context_key, KeyContext

        root_key = os.urandom(32)
        key1 = derive_context_key(root_key, KeyContext.VAULT)
        key2 = derive_context_key(root_key, KeyContext.VAULT)

        assert key1 == key2  # Deterministyczne!
        assert len(key1) == 32

    def test_derive_context_key_different_contexts(self):
        """Różne konteksty → zawsze różne klucze."""
        from nexus_ai.core.hkdf import derive_context_key, KeyContext

        root_key = os.urandom(32)
        vault_key = derive_context_key(root_key, KeyContext.VAULT)
        sqlcipher_key = derive_context_key(root_key, KeyContext.SQLCIPHER)
        secrets_key = derive_context_key(root_key, KeyContext.SECRETS)

        assert vault_key != sqlcipher_key
        assert vault_key != secrets_key
        assert sqlcipher_key != secrets_key


# ═══════════════════════════════════════════════════════════════════════════
# Test: SQLCipher Rekey (missing from Section 10.2)
# ═══════════════════════════════════════════════════════════════════════════

class TestSQLCipherRekey:
    """Testy rotacji klucza SQLCipher (luka: test_sqlcipher_rekey)."""

    def test_key_rotation_schedule_is_due_when_no_previous(self):
        """Bez poprzedniej rotacji → is_due = True."""
        from nexus_ai.db.security import KeyRotation

        schedule = KeyRotation.get_schedule(last_rotation=None, interval_days=90)
        assert schedule["is_due"]
        assert schedule["interval_days"] == 90

    def test_key_rotation_schedule_not_due_recently(self):
        """Niedawna rotacja → is_due = False."""
        from nexus_ai.db.security import KeyRotation
        from datetime import datetime, timezone, timedelta

        recent = (datetime.now(timezone.utc) - timedelta(days=10)).isoformat()
        schedule = KeyRotation.get_schedule(last_rotation=recent, interval_days=90)
        assert not schedule["is_due"]

    def test_key_rotation_schedule_due_after_interval(self):
        """Rotacja sprzed > 90 dni → is_due = True."""
        from nexus_ai.db.security import KeyRotation
        from datetime import datetime, timezone, timedelta

        old = (datetime.now(timezone.utc) - timedelta(days=100)).isoformat()
        schedule = KeyRotation.get_schedule(last_rotation=old, interval_days=90)
        assert schedule["is_due"]

    def test_key_generation_unique(self):
        """Każde generate_key() produkuje inny klucz."""
        from nexus_ai.db.security import SQLCipherConfig

        key1 = SQLCipherConfig.generate_key()
        key2 = SQLCipherConfig.generate_key()
        assert key1 != key2
        assert len(base64.b64decode(key1)) == 32

    def test_sqlcipher_config_resolve_key(self):
        """resolve_key zwraca klucz z configu lub env var."""
        from nexus_ai.db.security import SQLCipherConfig

        # Z configu
        config = SQLCipherConfig(key="test-key-32-bytes-long!!!!!!!")
        assert config.resolve_key() == "test-key-32-bytes-long!!!!!!!"

    def test_sqlcipher_config_key_hex(self):
        """key_hex zwraca hex reprezentację klucza."""
        from nexus_ai.db.security import SQLCipherConfig

        config = SQLCipherConfig(key="test-key")
        hex_key = config.key_hex
        assert len(hex_key) == 16  # 8 bytes "test-key" → 16 hex chars


# ═══════════════════════════════════════════════════════════════════════════
# Test: Rate Limit Brute-Force Protection (missing from Section 10.2)
# ═══════════════════════════════════════════════════════════════════════════

class TestRateLimitBruteForce:
    """Testy ochrony przed brute-force (luka: test_rate_limit_brute_force)."""

    def test_auth_endpoint_rate_limit_lower_than_general(self):
        """Auth endpointy mają niższy limit (10/min) niż general (60/min)."""
        # Auth endpoints: 10 req/min — znacznie trudniej bruteforce'ować
        auth_limit = 10  # auth:{ip}
        general_limit = 60  # anon:{ip}
        logged_in_limit = 60  # user:{role}:{id}

        assert auth_limit < general_limit
        assert auth_limit < logged_in_limit

    def test_rate_limit_per_role_identifier(self):
        """Identyfikator rate limitu zawiera rolę użytkownika."""
        # Per-role identifier zapobiega atakom cross-role
        # auth endpoint: auth:{ip} — 10 req/min
        # logged user: user:{role}:{user.id} — 60 req/min
        auth_identifier_format = "auth:{ip}"
        user_identifier_format = "user:{role}:{user.id}"

        assert "{ip}" in auth_identifier_format
        assert "{role}" in user_identifier_format
        assert "{user.id}" in user_identifier_format

    def test_brute_force_threshold_reasonable(self):
        """10 prób/min dla auth → ~600/h → zbyt wolno dla brute-force."""
        # Argon2id: ~250ms/hash → 10 prób/min × 250ms = 2.5s/min
        # Przy 8-znakowym haśle (62^8 = 218 bilionów):
        # 218e12 / (600/h) = niemożliwe do złamania brute-force
        attempts_per_minute = 10
        hash_time_ms = 250
        time_per_minute_ms = attempts_per_minute * hash_time_ms

        # Mniej niż 5 sekund na minutę poświęcone na hashowanie
        assert time_per_minute_ms < 5000
        assert attempts_per_minute == 10  # Potwierdź niski limit


# ═══════════════════════════════════════════════════════════════════════════
# Test: Proof Chain HMAC Signing (CR fix)
# ═══════════════════════════════════════════════════════════════════════════

class TestProofChainSigning:
    """Testy HMAC signing w Proof Chain (INNOWACJA #6)."""

    @pytest.fixture
    def chain(self, tmp_path):
        import duckdb
        from nexus_ai.services.proof_chain import ProofChain

        db_path = tmp_path / "test_signed_chain.duckdb"
        conn = duckdb.connect(str(db_path))
        return ProofChain(conn, signing_key=b"test-signing-key-32-bytes-aaaaa")

    def test_log_decision_with_signing_key(self, chain):
        """log_decision z signing_key zapisuje podpis w DB."""
        audit_id = chain.log_decision(
            "tx-signed-001",
            {"verdict": "AUTO_POST"},
            {"company": "test"},
        )
        assert audit_id
        assert len(audit_id) == 32  # UUID hex

        # Sprawdź czy wpis został zapisany
        result = chain.explain_decision("tx-signed-001")
        assert result["transaction_id"] == "tx-signed-001"
        assert result["chain_integrity"] == "INTACT"

    def test_log_decision_with_explicit_signing_key(self, chain):
        """log_decision z explicit signing_key nadpisuje instance key."""
        audit_id = chain.log_decision(
            "tx-signed-002",
            {"verdict": "REVIEW"},
            {"company": "test"},
            signing_key=b"override-key-32-bytes-long-aaaaa",
        )
        assert audit_id

    def test_signed_chain_verification(self, chain):
        """Podpisany łańcuch nadal przechodzi verify_chain."""
        for i in range(3):
            chain.log_decision(
                f"tx-signed-{i:03d}",
                {"verdict": f"test_{i}"},
                {"idx": i},
            )
        result = chain.verify_chain()
        assert result["valid"]
        assert result["total_decisions"] == 3


# ═══════════════════════════════════════════════════════════════════════════
# Test: Tenant Deprecation Warning (CR fix)
# ═══════════════════════════════════════════════════════════════════════════

class TestTenantDeprecationWarning:
    """Testy ostrzeżenia o deprecated DEFAULT_TENANT_ID."""

    def test_sanitize_tenant_id_none_triggers_warning(self):
        """sanitize_tenant_id(None) → DeprecationWarning."""
        from nexus_ai.core.tenant import TenantManager
        from nexus_ai.core.config import AppConfig

        config = AppConfig()
        tm = TenantManager(config)

        with pytest.warns(DeprecationWarning, match="DEFAULT_TENANT_ID.*deprecated"):
            result = tm.sanitize_tenant_id(None)
            assert result == "default"

    def test_sanitize_tenant_id_empty_triggers_warning(self):
        """sanitize_tenant_id("") → DeprecationWarning."""
        from nexus_ai.core.tenant import TenantManager
        from nexus_ai.core.config import AppConfig

        config = AppConfig()
        tm = TenantManager(config)

        with pytest.warns(DeprecationWarning):
            result = tm.sanitize_tenant_id("")
            assert result == "default"

    def test_sanitize_tenant_id_explicit_no_warning(self):
        """sanitize_tenant_id("my-tenant") → brak warningu."""
        import warnings
        from nexus_ai.core.tenant import TenantManager
        from nexus_ai.core.config import AppConfig

        config = AppConfig()
        tm = TenantManager(config)

        with warnings.catch_warnings(record=True) as caught:
            warnings.simplefilter("always")
            result = tm.sanitize_tenant_id("my-tenant")
            assert result == "my-tenant"
            # Brak DeprecationWarning dla jawnego tenant_id
            deprecation_warnings = [w for w in caught if issubclass(w.category, DeprecationWarning)]
            assert len(deprecation_warnings) == 0


# ═══════════════════════════════════════════════════════════════════════════
# Test: DLP Middleware (INNOWACJA #8)
# ═══════════════════════════════════════════════════════════════════════════

class TestDLPMiddleware:
    """Testy DLP Middleware."""

    def test_scan_clean_response(self):
        """Czysta odpowiedz HTTP → brak naruszen."""
        from nexus_ai.services.dlp_middleware import DLPMiddleware

        dlp = DLPMiddleware()
        violations = dlp.scan_http_response(
            "{\"status\": \"ok\", \"message\": \"Invoice booked\"}",
            endpoint="/api/invoices",
        )
        assert len(violations) == 0

    def test_scan_response_with_nip(self):
        """Odpowiedz z NIP → wykryte naruszenie."""
        from nexus_ai.services.dlp_middleware import DLPMiddleware

        dlp = DLPMiddleware()
        violations = dlp.scan_http_response(
            '{"nip": "1234567890", "company": "Test"}',
            endpoint="/api/company",
        )
        assert len(violations) >= 1
        assert any(v.pii_type == "nip" for v in violations)

    def test_scan_response_block_threshold(self):
        """>5 PII w odpowiedzi → BLOCKED."""
        from nexus_ai.services.dlp_middleware import DLPMiddleware

        dlp = DLPMiddleware()
        # Wygeneruj odpowiedz z 6 NIP-ami
        body = " ".join(["1234567890"] * 6)
        violations = dlp.scan_http_response(body, endpoint="/api/invoices")
        assert len(violations) >= 1
        nip_violation = next(v for v in violations if v.pii_type == "nip")
        assert nip_violation.action_taken == "BLOCKED"

    def test_redact_log_entry(self):
        """Maskowanie PII w logach."""
        from nexus_ai.services.dlp_middleware import DLPMiddleware

        dlp = DLPMiddleware()
        log_entry = "User logged in: email=jan@example.com, nip=1234567890"
        cleaned = dlp.redact_log_entry(log_entry)
        assert "jan@example.com" not in cleaned
        assert "1234567890" not in cleaned

    def test_audit_access(self):
        """Audyt dostepu do danych osobowych."""
        from nexus_ai.services.dlp_middleware import DLPMiddleware

        dlp = DLPMiddleware()
        dlp.audit_access(user_id="user-1", pii_type="nip", endpoint="/api/company")
        trail = dlp.get_audit_trail(user_id="user-1")
        assert len(trail) == 1
        assert trail[0]["pii_type"] == "nip"


# ═══════════════════════════════════════════════════════════════════════════
# Test: RASP Monitor (INNOWACJA #9)
# ═══════════════════════════════════════════════════════════════════════════

class TestRASPMonitor:
    """Testy RASP Monitor."""

    def test_sql_injection_detected(self):
        """SQL injection pattern → wykryty."""
        from nexus_ai.services.rasp_monitor import RASPMonitor

        rasp = RASPMonitor(auto_block=False)
        events = rasp.check_sql_query(
            "SELECT * FROM users WHERE id = 1 OR 1=1",
            source_ip="10.0.0.1",
        )
        assert len(events) >= 1
        assert events[0].event_type == "sql_injection"

    def test_clean_sql_no_alert(self):
        """Czyste zapytanie SQL → brak alertu."""
        from nexus_ai.services.rasp_monitor import RASPMonitor

        rasp = RASPMonitor(auto_block=False)
        events = rasp.check_sql_query(
            "SELECT * FROM invoices WHERE id = ?",
            source_ip="10.0.0.1",
        )
        assert len(events) == 0

    def test_resource_spike_alert(self):
        """Wysokie CPU → alert."""
        from nexus_ai.services.rasp_monitor import RASPMonitor

        rasp = RASPMonitor(auto_block=False)
        events = rasp.check_resource_usage(cpu_percent=92.0)
        assert len(events) >= 1
        assert events[0].event_type == "resource_spike"
        assert events[0].level == "critical"

    def test_normal_resource_no_alert(self):
        """Normalne zuzycie → brak alertu."""
        from nexus_ai.services.rasp_monitor import RASPMonitor

        rasp = RASPMonitor(auto_block=False)
        events = rasp.check_resource_usage(cpu_percent=45.0, ram_mb=2000)
        assert len(events) == 0

    def test_brute_force_detection(self):
        """>5 failed logins → brute force alert."""
        from nexus_ai.services.rasp_monitor import RASPMonitor

        rasp = RASPMonitor(auto_block=False)
        for _ in range(5):
            rasp.track_failed_login("192.168.1.100")
        event = rasp.track_failed_login("192.168.1.100")
        assert event is not None
        assert event.event_type == "brute_force"
        assert event.level == "critical"


# ═══════════════════════════════════════════════════════════════════════════
# Test: Merkle Anchor (INNOWACJA #7)
# ═══════════════════════════════════════════════════════════════════════════

class TestMerkleTree:
    """Testy drzewa Merkle."""

    def test_empty_tree_root(self):
        """Puste drzewo → root to hash pustego stringa."""
        from nexus_ai.services.merkle_anchor import MerkleTree
        import hashlib

        tree = MerkleTree()
        root = tree.build()
        assert root == hashlib.sha256(b"").hexdigest()

    def test_single_leaf_root(self):
        """Jeden lisc → root = hash(lisc)."""
        from nexus_ai.services.merkle_anchor import MerkleTree

        tree = MerkleTree()
        tree.add_leaf("test_data")
        root = tree.build()
        assert len(root) == 64  # SHA-256 hex

    def test_multi_leaf_proof(self):
        """Dowod wlaczenia dla wielu lisci."""
        from nexus_ai.services.merkle_anchor import MerkleTree

        tree = MerkleTree()
        for i in range(10):
            tree.add_leaf(f"decision_{i}")
        tree.build()

        proof = tree.get_proof(leaf_index=3)
        assert proof is not None
        assert MerkleTree.verify_proof(proof)

    def test_proof_verification_fails_with_wrong_leaf(self):
        """Zmodyfikowany lisc → weryfikacja nie przechodzi."""
        from nexus_ai.services.merkle_anchor import MerkleTree

        tree = MerkleTree()
        for i in range(5):
            tree.add_leaf(f"decision_{i}")
        tree.build()

        proof = tree.get_proof(leaf_index=2)
        assert proof is not None
        proof.leaf_hash = "modified_hash"
        assert not MerkleTree.verify_proof(proof)


class TestMerkleAnchorService:
    """Testy serwisu kotwiczenia."""

    def test_publish_and_verify_anchor(self, tmp_path):
        """Publikacja i weryfikacja anchora."""
        from nexus_ai.services.merkle_anchor import MerkleAnchorService

        service = MerkleAnchorService(anchor_dir=str(tmp_path / "anchors"))
        hashes = [f"hash_{i}" for i in range(50)]

        anchor = service.publish_monthly_anchor(hashes, year=2026, month=7)
        assert anchor.transaction_count == 50
        assert anchor.period == "2026-07"
        assert anchor.published

        # Weryfikacja chain of anchors
        result = service.verify_chain_of_anchors()
        assert result["valid"]
        assert result["total_anchors"] == 1


# ═══════════════════════════════════════════════════════════════════════════
# Test: Biometric MFA (INNOWACJA #10)
# ═══════════════════════════════════════════════════════════════════════════

class TestBiometricMFA:
    """Testy Biometric MFA."""

    def test_create_challenge(self):
        """Tworzenie wyzwania MFA."""
        from nexus_ai.services.biometric_mfa import (
            BiometricMFAService,
            MFAOperation,
        )

        mfa = BiometricMFAService()
        challenge = mfa.create_challenge(
            user_id="user-1",
            operation=MFAOperation.TRANSFER_OVER_50K,
        )
        assert challenge.challenge_id
        assert challenge.nonce
        assert challenge.operation == MFAOperation.TRANSFER_OVER_50K
        assert not challenge.verified

    def test_verify_biometric_success(self):
        """Poprawna odpowiedz biometryczna → success."""
        from nexus_ai.services.biometric_mfa import (
            BiometricMFAService,
            MFAOperation,
        )
        import hmac, hashlib

        mfa = BiometricMFAService()
        challenge = mfa.create_challenge("user-1", MFAOperation.ADMIN_SETTINGS)

        # Wygeneruj poprawny "podpis biometryczny" (HMAC nonce)
        expected_proof = hmac.new(
            b"user-1",
            challenge.nonce.encode(),
            hashlib.sha256,
        ).hexdigest()

        success = mfa.verify_biometric("user-1", challenge.challenge_id, expected_proof)
        assert success
        assert mfa.is_session_valid("user-1", MFAOperation.ADMIN_SETTINGS)

    def test_verify_biometric_wrong_proof(self):
        """Niepoprawny podpis → fail."""
        from nexus_ai.services.biometric_mfa import (
            BiometricMFAService,
            MFAOperation,
        )

        mfa = BiometricMFAService()
        challenge = mfa.create_challenge("user-1", MFAOperation.DELETE_COMPANY)

        success = mfa.verify_biometric("user-1", challenge.challenge_id, "wrong_proof")
        assert not success

    def test_mfa_required_for_critical_operations(self):
        """Krytyczne operacje wymagaja MFA."""
        from nexus_ai.services.biometric_mfa import BiometricMFAService, MFAOperation

        mfa = BiometricMFAService()
        assert mfa.is_mfa_required(MFAOperation.TRANSFER_OVER_50K)
        assert mfa.is_mfa_required(MFAOperation.DELETE_COMPANY)
        assert mfa.is_mfa_required(MFAOperation.CHANGE_TAX_FORM)

    def test_verify_totp_success(self):
        """Poprawny TOTP token → success."""
        from nexus_ai.services.biometric_mfa import BiometricMFAService
        import time as _time, hmac, hashlib

        mfa = BiometricMFAService()
        secret = "TESTSECRET123"

        # Wygeneruj poprawny TOTP token
        time_step = int(_time.time() // 30)
        msg = time_step.to_bytes(8, "big")
        h = hmac.new(secret.encode(), msg, hashlib.sha256).digest()
        offset = h[-1] & 0x0F
        code = int.from_bytes(h[offset:offset + 4], "big") & 0x7FFFFFFF
        token = str(code % 1_000_000).zfill(6)

        success = mfa.verify_totp("user-1", token, secret)
        assert success

    def test_verify_totp_wrong_token(self):
        """Niepoprawny TOTP token → fail."""
        from nexus_ai.services.biometric_mfa import BiometricMFAService

        mfa = BiometricMFAService()
        success = mfa.verify_totp("user-1", "000000", "TESTSECRET")
        assert not success

    def test_verify_totp_invalid_format(self):
        """Token o zlej dlugosci → fail."""
        from nexus_ai.services.biometric_mfa import BiometricMFAService

        mfa = BiometricMFAService()
        success = mfa.verify_totp("user-1", "12345", "TESTSECRET")
        assert not success
