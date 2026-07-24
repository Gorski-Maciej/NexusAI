"""
Zero-Trust Service Mesh — mTLS z automatyczną rotacją certyfikatów.

INNOWACJA #9 z Raportu v7.0: mTLS między wszystkimi komponentami
(API ↔ NATS, NATS ↔ Worker, Worker ↔ OPA). Certyfikaty automatycznie
rotowane przez wbudowane CA (Smallstep lub cert-manager).

Architektura:
    ┌────────┐    mTLS     ┌──────┐    mTLS     ┌────────┐
    │  API   │◄──────────►│ NATS │◄──────────►│ Worker │
    └────┬───┘             └──┬───┘             └───┬────┘
         │      mTLS          │       mTLS         │
         └────────────────────┼────────────────────┘
                              │
                        ┌─────▼──────┐
                        │   OPA CA   │ (wbudowane)
                        └────────────┘

Usage:
    ca = ZeroTrustCA(cert_dir="/etc/nexus/certs")
    await ca.initialize()  # Generuje root CA

    # Dla każdego komponentu:
    cert = await ca.issue_certificate(
        component="api",
        hosts=["api.nexus.local", "localhost", "127.0.0.1"],
    )
    # Użyj cert w Granian, NATS, etc.
"""

from __future__ import annotations

import datetime
import os
import threading as _threading
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.security.mesh")


# ── Zero-Trust CA ─────────────────────────────────────────────────────────


class ZeroTrustCA:
    """Wbudowane Certificate Authority dla Zero-Trust Service Mesh.

    Zarządza:
    - Root CA (generowane przy pierwszym uruchomieniu)
    - Certyfikatami per komponent (API, NATS, Worker, OPA)
    - Automatyczną rotacją (domyślnie: 24h dla leaf, 30 dni dla CA)
    - Revocation list (CRL) dla skompromitowanych certyfikatów
    """

    __slots__ = (
        "_ca_cert",
        "_ca_key",
        "_cert_dir",
        "_crl",
        "_initialized",
        "_lock",
        "_root_ca_ttl_days",
        "_leaf_ttl_hours",
    )

    def __init__(
        self,
        cert_dir: str | Path = "app_data/certs/mesh",
        root_ca_ttl_days: int = 90,
        leaf_ttl_hours: int = 24,
    ) -> None:
        self._cert_dir = Path(cert_dir)
        self._cert_dir.mkdir(parents=True, exist_ok=True)
        self._root_ca_ttl_days = root_ca_ttl_days
        self._leaf_ttl_hours = leaf_ttl_hours
        self._ca_cert: Any = None
        self._ca_key: Any = None
        self._crl: list[str] = []
        self._initialized = False
        self._lock = _threading.Lock()

    async def initialize(self) -> bool:
        """Inicjalizuj CA — wygeneruj root cert jeśli nie istnieje.

        Returns:
            True jeśli CA jest gotowe.
        """
        with self._lock:
            if self._initialized:
                return True

            try:
                # Próbuj użyć cryptography (jeśli dostępne)
                from cryptography import x509
                from cryptography.x509.oid import NameOID
                from cryptography.hazmat.primitives import hashes, serialization
                from cryptography.hazmat.primitives.asymmetric import rsa
                from cryptography.hazmat.backends import default_backend

                root_key_path = self._cert_dir / "root-ca-key.pem"
                root_cert_path = self._cert_dir / "root-ca-cert.pem"

                if root_key_path.exists() and root_cert_path.exists():
                    # Wczytaj istniejące CA
                    with open(root_key_path, "rb") as f:
                        self._ca_key = serialization.load_pem_private_key(
                            f.read(), password=None, backend=default_backend()
                        )
                    with open(root_cert_path, "rb") as f:
                        self._ca_cert = x509.load_pem_x509_certificate(
                            f.read(), backend=default_backend()
                        )
                    logger.info("[ZeroTrust] Loaded existing root CA")
                else:
                    # Generuj nowe Root CA
                    self._ca_key = rsa.generate_private_key(
                        public_exponent=65537, key_size=4096, backend=default_backend()
                    )
                    subject = issuer = x509.Name([
                        x509.NameAttribute(NameOID.COUNTRY_NAME, "PL"),
                        x509.NameAttribute(NameOID.ORGANIZATION_NAME, "NexusAI Zero Trust Mesh"),
                        x509.NameAttribute(NameOID.COMMON_NAME, "NexusAI Root CA"),
                    ])
                    self._ca_cert = (
                        x509.CertificateBuilder()
                        .subject_name(subject)
                        .issuer_name(issuer)
                        .public_key(self._ca_key.public_key())
                        .serial_number(x509.random_serial_number())
                        .not_valid_before(datetime.datetime.now(datetime.timezone.utc))
                        .not_valid_after(
                            datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(days=self._root_ca_ttl_days)
                        )
                        .add_extension(
                            x509.BasicConstraints(ca=True, path_length=None),
                            critical=True,
                        )
                        .sign(self._ca_key, hashes.SHA256(), default_backend())
                    )

                    # Zapisz na dysk z odpowiednimi uprawnieniami
                    with open(root_key_path, "wb") as f:
                        f.write(self._ca_key.private_bytes(
                            encoding=serialization.Encoding.PEM,
                            format=serialization.PrivateFormat.PKCS8,
                            encryption_algorithm=serialization.NoEncryption(),
                        ))
                    root_key_path.chmod(0o600)

                    with open(root_cert_path, "wb") as f:
                        f.write(self._ca_cert.public_bytes(serialization.Encoding.PEM))
                    root_cert_path.chmod(0o644)

                    logger.info("[ZeroTrust] Generated new root CA (valid %d days)", self._root_ca_ttl_days)

                self._initialized = True
                return True

            except ImportError:
                logger.warning(
                    "[ZeroTrust] cryptography library not available. "
                    "Install with: pip install cryptography. "
                    "mTLS disabled — falling back to plaintext connections."
                )
                self._initialized = True  # Graceful degradation
                return True
            except Exception as exc:
                logger.error("[ZeroTrust] CA initialization failed: %s", exc)
                return False

    async def issue_certificate(
        self,
        component: str,
        hosts: list[str] | None = None,
        ttl_hours: int | None = None,
    ) -> tuple[str, str, str] | tuple[None, None, None]:
        """Wystaw certyfikat dla komponentu.

        Args:
            component: Nazwa komponentu (api, nats, worker, opa).
            hosts: Lista hostnames/IP (SAN).
            ttl_hours: TTL certyfikatu (domyślnie: self._leaf_ttl_hours).

        Returns:
            Tuple (cert_pem, key_pem, ca_cert_pem) lub (None, None, None).
        """
        if not self._initialized:
            await self.initialize()

        if self._ca_cert is None or self._ca_key is None:
            logger.warning("[ZeroTrust] CA not available — cannot issue cert for %s", component)
            return None, None, None

        hosts = hosts or ["localhost", "127.0.0.1"]
        ttl_hours = ttl_hours or self._leaf_ttl_hours

        try:
            from cryptography import x509
            from cryptography.x509.oid import NameOID
            from cryptography.hazmat.primitives import hashes, serialization
            from cryptography.hazmat.primitives.asymmetric import rsa
            from cryptography.hazmat.backends import default_backend

            # Generuj klucz dla komponentu
            component_key = rsa.generate_private_key(
                public_exponent=65537, key_size=2048, backend=default_backend()
            )

            # SAN (Subject Alternative Names)
            san_names = [x509.DNSName(host) for host in hosts]
            # Dodaj też IP addresses jeśli to IP
            import ipaddress
            for host in hosts:
                try:
                    ip = ipaddress.ip_address(host)
                    san_names.append(x509.IPAddress(ip))
                except ValueError:
                    pass

            cert = (
                x509.CertificateBuilder()
                .subject_name(x509.Name([
                    x509.NameAttribute(NameOID.COMMON_NAME, f"NexusAI {component}"),
                    x509.NameAttribute(NameOID.ORGANIZATION_NAME, "NexusAI"),
                ]))
                .issuer_name(self._ca_cert.subject)
                .public_key(component_key.public_key())
                .serial_number(x509.random_serial_number())
                .not_valid_before(datetime.datetime.now(datetime.timezone.utc))
                .not_valid_after(
                    datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=ttl_hours)
                )
                .add_extension(
                    x509.SubjectAlternativeName(san_names),
                    critical=False,
                )
                .add_extension(
                    x509.BasicConstraints(ca=False, path_length=None),
                    critical=True,
                )
                .add_extension(
                    x509.KeyUsage(
                        digital_signature=True,
                        key_encipherment=True,
                        content_commitment=False,
                        data_encipherment=False,
                        key_agreement=False,
                        key_cert_sign=False,
                        crl_sign=False,
                        encipher_only=False,
                        decipher_only=False,
                    ),
                    critical=True,
                )
                .add_extension(
                    x509.ExtendedKeyUsage([
                        x509.oid.ExtendedKeyUsageOID.SERVER_AUTH,
                        x509.oid.ExtendedKeyUsageOID.CLIENT_AUTH,
                    ]),
                    critical=False,
                )
                .sign(self._ca_key, hashes.SHA256(), default_backend())
            )

            cert_pem = cert.public_bytes(serialization.Encoding.PEM).decode()
            key_pem = component_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption(),
            ).decode()
            ca_pem = self._ca_cert.public_bytes(serialization.Encoding.PEM).decode()

            # Zapisz na dysk dla łatwego użycia
            cert_path = self._cert_dir / f"{component}-cert.pem"
            key_path = self._cert_dir / f"{component}-key.pem"
            cert_path.write_text(cert_pem)
            key_path.write_text(key_pem)
            cert_path.chmod(0o644)
            key_path.chmod(0o600)

            logger.info(
                "[ZeroTrust] Issued cert for '%s' (valid %dh, hosts: %s)",
                component, ttl_hours, ", ".join(hosts[:3]),
            )
            return cert_pem, key_pem, ca_pem

        except ImportError:
            logger.warning("[ZeroTrust] cryptography not available for cert issuance")
            return None, None, None

    async def revoke_certificate(self, component: str) -> None:
        """Unieważnij certyfikat komponentu (dodaj do CRL)."""
        with self._lock:
            cert_path = self._cert_dir / f"{component}-cert.pem"
            if component not in self._crl:
                self._crl.append(component)
            # Usuń cert jeśli istnieje
            if cert_path.exists():
                cert_path.unlink()
            logger.warning("[ZeroTrust] Revoked cert for '%s'", component)

    async def auto_rotate(self) -> dict[str, bool]:
        """Automatycznie rotuj wszystkie certyfikaty które wygasają."""
        results: dict[str, bool] = {}
        cert_files = list(self._cert_dir.glob("*-cert.pem"))
        for cert_file in cert_files:
            component = cert_file.stem.replace("-cert", "")
            if component in self._crl:
                continue
            try:
                cert, key, ca = await self.issue_certificate(component)
                results[component] = cert is not None
            except Exception as exc:
                logger.warning("[ZeroTrust] Auto-rotate failed for %s: %s", component, exc)
                results[component] = False
        return results

    def get_component_certs(self, component: str) -> dict[str, str] | None:
        """Zwróć certyfikaty dla komponentu.

        Returns:
            dict z kluczami: cert_pem, key_pem, ca_pem.
        """
        cert_path = self._cert_dir / f"{component}-cert.pem"
        key_path = self._cert_dir / f"{component}-key.pem"
        ca_path = self._cert_dir / "root-ca-cert.pem"

        if not cert_path.exists() or not key_path.exists():
            return None

        return {
            "cert_pem": cert_path.read_text(),
            "key_pem": key_path.read_text(),
            "ca_pem": ca_path.read_text() if ca_path.exists() else "",
        }

    @property
    def is_initialized(self) -> bool:
        return self._initialized

    @property
    def cert_count(self) -> int:
        return len(list(self._cert_dir.glob("*-cert.pem")))


# ── Global singleton ──────────────────────────────────────────────────────

_default_mesh: ZeroTrustCA | None = None


def get_zero_trust_mesh(
    cert_dir: str | Path = "app_data/certs/mesh",
) -> ZeroTrustCA:
    """Get global ZeroTrustCA singleton."""
    global _default_mesh
    if _default_mesh is None:
        _default_mesh = ZeroTrustCA(cert_dir=cert_dir)
    return _default_mesh


__all__ = [
    "ZeroTrustCA",
    "get_zero_trust_mesh",
]
