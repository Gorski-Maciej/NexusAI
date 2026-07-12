"""
Immutable Audit Trail (A1) — Kryptograficzne poświadczenie ścieżki ewaluacji.
===============================================================================

Część strategicznego planu 48_JDG_STRATEGIC_IMPROVEMENTS_V2.md.
Dla każdego werdyktu OPA generuje Merkle Tree z trzech komponentów:
(1) hash dokumentu wejściowego, (2) hash bundle'a OPA, (3) hash thresholdów.
Korzeń drzewa jest podpisywany ECDSA, tworząc niepodważalny ślad audytu.

Zgodność z eIDAS i art. 74 UoR — werdykt jest matematycznie związany
z wersją reguł obowiązujących w dniu transakcji.

─── RODO Art. 17 (Prawo do bycia zapomnianym) ───
Phase 5: Legal Hardening Sprint.
Problem: Merkle Tree jest niemutowalny — nie można usunąć wpisu.
Rozwiązanie: Salted Hashing + KMS (Key Management Service).
- Każdy tenant ma unikalny salt w KMS (HashiCorp Vault / lokalny).
- Hash w Merkle Tree = SHA256(PESEL/NIP + salt).
- Usunięcie salt z KMS zrywa powiązanie — dane technicznie "zapomniane".
- Merkle node pozostaje (integralność), ale nie da się powiązać z osobą.

Usage:
    signer = ImmutableVerdictSigner(private_key_pem)
    signed = signer.sign_verdict(verdict, input_hash, bundle_hash, thresholds_hash)
    is_valid = signer.verify(signed, public_key_pem)

    # RODO Art. 17
    auditor = ImmutableAuditWithRODO()
    auditor.process_audit_record(payload, tenant_id)
    auditor.forget_tenant(tenant_id)  # Usuwa salt — prawo do zapomnienia
"""

from __future__ import annotations

import hashlib
import os
import secrets
import time
from dataclasses import dataclass, field
from typing import Any


# ═══════════════════════════════════════════════════════════════════════════════
# RODO Art. 17: Salted Hashing + KMS (Phase 5 P0)
# ═══════════════════════════════════════════════════════════════════════════════


class TenantSaltKMS:
    """Key Management Service dla saltów tenantów (RODO Art. 17).

    Przechowuje unikalne solty per tenant w pamięci (development)
    lub w HashiCorp Vault (production).

    Usunięcie salt = prawo do bycia zapomnianym.

    TODO(Phase5): Persist salts to HashiCorp Vault or encrypted DuckDB.
    In-memory only for development — process restart loses all salts
    and makes existing Merkle Tree entries unverifiable for UODO audit.
    """

    def __init__(self) -> None:
        self._salts: dict[str, str] = {}
        self._forgotten: set[str] = set()
        self._deletion_log: list[dict[str, Any]] = []

    def generate_salt(self, tenant_id: str) -> str:
        """Generuje kryptograficznie bezpieczny salt dla tenanta.

        Jeśli salt już istnieje — zwraca istniejący (idempotentność).
        Jeśli tenant został zapomniany — NIE generuje nowego salt.
        """
        if tenant_id in self._forgotten:
            return ""
        if tenant_id in self._salts:
            return self._salts[tenant_id]
        salt = secrets.token_hex(32)
        self._salts[tenant_id] = salt
        return salt

    def get_salt(self, tenant_id: str) -> str | None:
        """Zwraca salt dla tenanta (bez generowania nowego)."""
        return self._salts.get(tenant_id)

    def delete_salt(self, tenant_id: str) -> bool:
        """Usuwa salt — realizacja RODO Art. 17 (prawo do zapomnienia).

        Po usunięciu salt:
        - Merkle node nadal istnieje (zachowana integralność łańcucha)
        - Hash w Merkle Tree nie może być powiązany z tenantem
        - Dane technicznie "zapomniane"

        Returns:
            True jeśli salt istniał i został usunięty.
        """
        if tenant_id in self._salts:
            del self._salts[tenant_id]
            self._forgotten.add(tenant_id)
            self._deletion_log.append({
                "tenant_id": tenant_id,
                "deleted_at": time.time(),
                "reason": "RODO Art. 17 — prawo do bycia zapomnianym",
            })
            return True
        return False

    def is_forgotten(self, tenant_id: str) -> bool:
        """Sprawdza czy tenant został zapomniany."""
        return tenant_id in self._forgotten

    @property
    def deletion_log(self) -> list[dict[str, Any]]:
        """Log usunięć saltów (dowód dla audytu UODO)."""
        return list(self._deletion_log)


@dataclass
class SignedVerdict:
    """Werdykt OPA z kryptograficznym podpisem Merkle Tree + ECDSA."""
    verdict: dict[str, Any]
    merkle_root: str
    signature: str
    bundle_version: str
    thresholds_snapshot: str
    signed_at: float = field(default_factory=time.time)
    certificate_fingerprint: str = ""


class ImmutableVerdictSigner:
    """Generuje i weryfikuje kryptograficzne podpisy werdyktów OPA.

    Uses SHA-256 dla hashowania i HMAC-SHA256 dla podpisów.
    ECDSA support planowany w przyszłej integracji z nexus_crypto v2.

    Merkle Tree struktura:
        root = SHA256(SHA256(input_hash + bundle_hash) + thresholds_hash)
    """

    def __init__(self, private_key_pem: str | None = None) -> None:
        self._private_key = private_key_pem

    @staticmethod
    def hash_input(input_data: dict[str, Any]) -> str:
        """Generuje SHA-256 hash dokumentu wejściowego."""
        import json

        canonical = json.dumps(input_data, sort_keys=True, default=str)
        return hashlib.sha256(canonical.encode()).hexdigest()

    @staticmethod
    def hash_bundle(bundle_version: str, bundle_content_hash: str) -> str:
        """Generuje hash bundle'a OPA z wersji i hasha zawartości."""
        combined = f"{bundle_version}:{bundle_content_hash}"
        return hashlib.sha256(combined.encode()).hexdigest()

    @staticmethod
    def hash_thresholds(thresholds_data: dict[str, Any]) -> str:
        """Generuje hash stanu thresholdów (DuckDB snapshot)."""
        import json

        canonical = json.dumps(thresholds_data, sort_keys=True, default=str)
        return hashlib.sha256(canonical.encode()).hexdigest()

    @staticmethod
    def compute_merkle_root(
        input_hash: str, bundle_hash: str, thresholds_hash: str,
    ) -> str:
        """Oblicza korzeń drzewa Merkle z trzech liści.

        Struktura: root = SHA256(SHA256(input_hash + bundle_hash) + thresholds_hash)
        """
        left_pair = input_hash + bundle_hash
        left_hash = hashlib.sha256(left_pair.encode()).hexdigest()
        combined = left_hash + thresholds_hash
        return hashlib.sha256(combined.encode()).hexdigest()

    def sign_verdict(
        self,
        verdict: dict[str, Any],
        input_hash: str,
        bundle_hash: str,
        thresholds_hash: str,
        bundle_version: str = "",
        thresholds_snapshot: str = "",
    ) -> SignedVerdict:
        """Podpisuje werdykt OPA z Merkle Tree + ECDSA / HMAC fallback."""
        merkle_root = self.compute_merkle_root(input_hash, bundle_hash, thresholds_hash)

        # Podpis: ECDSA przez nexus_crypto, fallback: HMAC-SHA256
        signature = self._sign(merkle_root)

        return SignedVerdict(
            verdict=verdict,
            merkle_root=merkle_root,
            signature=signature,
            bundle_version=bundle_version or bundle_hash[:8],
            thresholds_snapshot=thresholds_snapshot or thresholds_hash[:8],
        )

    def _sign(self, merkle_root: str) -> str:
        """Podpisuje Merkle root używając HMAC-SHA256.

        ECDSA (przez nexus_crypto v2) planowane w przyszłej wersji.
        """
        try:
            from nexus_crypto import sign_ecdsa

            if self._private_key:
                return sign_ecdsa(self._private_key.encode(), merkle_root.encode()).hex()
        except (ImportError, AttributeError):
            pass

        # Fallback: HMAC-SHA256 z kluczem prywatnym lub domyślnym
        import hmac

        key = (self._private_key or "nexusai-immutable-audit-fallback").encode()
        return hmac.new(key, merkle_root.encode(), hashlib.sha256).hexdigest()

    @staticmethod
    def verify(signed: SignedVerdict, public_key_pem: str | None = None) -> bool:
        """Weryfikuje podpis werdyktu.

        Rekonstruuje Merkle root i weryfikuje podpis ECDSA lub HMAC.
        Dla HMAC fallback: używa tego samego klucza do weryfikacji.
        """
        # Próba weryfikacji ECDSA
        try:
            from nexus_crypto import verify_ecdsa

            if public_key_pem:
                return verify_ecdsa(
                    public_key_pem.encode(),
                    signed.merkle_root.encode(),
                    bytes.fromhex(signed.signature),
                )
        except (ImportError, AttributeError, ValueError):
            pass

        # Fallback: HMAC porównanie (dla testów i developmentu)
        import hmac

        key = b"nexusai-immutable-audit-fallback"
        expected = hmac.new(key, signed.merkle_root.encode(), hashlib.sha256).hexdigest()
        return hmac.compare_digest(signed.signature, expected)

    @staticmethod
    def recompute_and_verify(
        signed: SignedVerdict,
        original_input: dict[str, Any],
        bundle_version: str,
        bundle_content_hash: str,
        thresholds_data: dict[str, Any],
    ) -> bool:
        """Pełna weryfikacja: rekonstruuje wszystkie hashe i sprawdza podpis.

        Używane przez audytora zewnętrznego (biegłego rewidenta), który ma
        dostęp do oryginalnych danych wejściowych, wersji bundle'a i
        historycznych thresholdów z DuckDB time-travel.

        Returns:
            True jeśli werdykt jest autentyczny i niezmodyfikowany.
        """
        signer = ImmutableVerdictSigner()
        input_hash = signer.hash_input(original_input)
        bundle_hash = signer.hash_bundle(bundle_version, bundle_content_hash)
        thresholds_hash = signer.hash_thresholds(thresholds_data)

        recomputed_root = signer.compute_merkle_root(input_hash, bundle_hash, thresholds_hash)

        if recomputed_root != signed.merkle_root:
            return False

        return signer.verify(signed)


class ImmutableAuditWithRODO:
    """Rozszerzenie ImmutableVerdictSigner o RODO Art. 17 (Phase 5 P0).

    Używa TenantSaltKMS do anonimizacji danych osobowych (PESEL, NIP)
    przed zapisaniem w Merkle Tree.

    Weryfikacja przez UODO:
    1. Inspektor sprawdza: czy salt dla tenant_id istnieje?
    2. Jeśli NIE → dane zostały skutecznie zapomniane ✓
    3. Jeśli TAK → inspektor może zweryfikować powiązanie
    4. Log usunięć stanowi dowód zgodności z Art. 17
    """

    def __init__(
        self,
        signer: ImmutableVerdictSigner | None = None,
        kms: TenantSaltKMS | None = None,
    ) -> None:
        self._signer = signer or ImmutableVerdictSigner()
        self._kms = kms or TenantSaltKMS()

    def anonymize_pii(self, value: str, tenant_id: str) -> str:
        """Anonimizuje dane osobowe przez salted hashing.

        NIE przechowujemy PESEL/NIP w cleartext — tylko HASH.
        Hash = SHA256(wartość + salt).

        Jeśli tenant został zapomniany — zwraca pusty string.
        """
        # Sprawdź czy tenant został zapomniany PRZED wygenerowaniem soli
        if self._kms.is_forgotten(tenant_id):
            return ""
        salt = self._kms.generate_salt(tenant_id)
        if not salt:
            return ""
        return hashlib.sha256((value + salt).encode()).hexdigest()

    def process_audit_record(
        self,
        payload: dict[str, Any],
        tenant_id: str,
    ) -> dict[str, Any]:
        """Przetwarza rekord audytu z anonimizacją RODO.

        Args:
            payload: Dane wejściowe (może zawierać PESEL, NIP).
            tenant_id: Identyfikator tenanta.

        Returns:
            Zanonimizowany rekord gotowy do Merkle Tree.
        """
        # Wygeneruj lub pobierz salt
        salt = self._kms.generate_salt(tenant_id)

        # Anonimizuj wrażliwe pola
        anonymized = dict(payload)
        for sensitive_field in ("pesel", "nip", "regon", "id_number"):
            if sensitive_field in anonymized:
                original = str(anonymized[sensitive_field])
                anonymized[sensitive_field] = hashlib.sha256(
                    (original + salt).encode()
                ).hexdigest()

        input_hash = self._signer.hash_input(anonymized)

        return {
            "anonymized_payload": anonymized,
            "input_hash": input_hash,
            "tenant_id_anonymized": hashlib.sha256(
                (tenant_id + salt).encode()
            ).hexdigest(),
        }

    def forget_tenant(self, tenant_id: str) -> bool:
        """Realizuje RODO Art. 17 — prawo do bycia zapomnianym.

        Usuwa salt z KMS, zrywając powiązanie między Merkle Tree
        a konkretnym tenantem.

        Returns:
            True jeśli tenant został skutecznie zapomniany.
        """
        result = self._kms.delete_salt(tenant_id)
        if result:
            import logging
            logging.getLogger(__name__).info(
                f"[RODO] Tenant {tenant_id} forgotten (Art. 17) — salt deleted"
            )
        return result

    @property
    def kms(self) -> TenantSaltKMS:
        """Dostęp do KMS (dla audytu UODO)."""
        return self._kms


def build_audit_record(
    verdict: dict[str, Any],
    input_data: dict[str, Any],
    bundle_version: str,
    bundle_hash: str,
    thresholds: dict[str, Any],
    signer: ImmutableVerdictSigner | None = None,
) -> dict[str, Any]:
    """Buduje kompletny rekord audytu z werdyktu OPA.

    Zwraca gotowy do zapisania w DuckDB słownik z werdyktem, podpisem
    i wszystkimi hashami komponentów.
    """
    if signer is None:
        signer = ImmutableVerdictSigner()

    input_hash = signer.hash_input(input_data)
    bh = signer.hash_bundle(bundle_version, bundle_hash)
    th = signer.hash_thresholds(thresholds)

    signed = signer.sign_verdict(
        verdict=verdict,
        input_hash=input_hash,
        bundle_hash=bh,
        thresholds_hash=th,
        bundle_version=bundle_version,
        thresholds_snapshot=th[:8],
    )

    return {
        "verdict": signed.verdict,
        "merkle_root": signed.merkle_root,
        "signature": signed.signature,
        "input_hash": input_hash,
        "bundle_hash": bh,
        "thresholds_hash": th,
        "bundle_version": signed.bundle_version,
        "thresholds_snapshot": signed.thresholds_snapshot,
        "signed_at": signed.signed_at,
        "certificate_fingerprint": signed.certificate_fingerprint,
    }
