"""
Semantic Bundle Manager (Phase 5, P2) — Semver Policy Bundle Versioning.
=========================================================================

Część planu Phase 5: Legal Hardening Sprint (Kategoria 7: Utrzymanie kodu).
Problem: Brak wersjonowania bundle'ów OPA uniemożliwia:
- Time-travel evaluation (odtworzenie decyzji na historycznych regułach)
- Rollback do poprzedniej wersji
- Audyt: która wersja reguł wygenerowała dany werdykt?

Rozwiązanie: Semver (MAJOR.MINOR.PATCH) + hash zawartości dla każdego
bundle'a OPA. Każdy werdykt zawiera bundle_version i bundle_hash.

Usage:
    manager = BundleManager(bundles_dir="policies/jdg/bundles")
    version = manager.get_current_version()
    await manager.rollback("1.2.3")
"""

from __future__ import annotations

import hashlib
import json
import logging
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


# ── Configuration ────────────────────────────────────────────────────────────

MANIFEST_FILENAME = "manifest.json"
DEFAULT_BUNDLES_DIR = Path("policies/jdg/bundles")


@dataclass
class BundleVersion:
    """Wersja bundle'a OPA (semver + hash)."""
    major: int
    minor: int
    patch: int
    hash: str  # SHA-256 całego bundle'a
    created_at: float = field(default_factory=time.time)
    description: str = ""
    is_active: bool = False
    is_deprecated: bool = False

    @property
    def semver(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}"

    @property
    def short_hash(self) -> str:
        return self.hash[:8]


@dataclass
class BundleManifest:
    """Manifest bundle'a — lista wszystkich wersji."""
    name: str
    versions: list[BundleVersion] = field(default_factory=list)
    current_version: str = ""

    @property
    def active_version(self) -> BundleVersion | None:
        for v in self.versions:
            if v.is_active:
                return v
        return None

    @property
    def latest_version(self) -> BundleVersion | None:
        if not self.versions:
            return None
        return max(self.versions, key=lambda v: (v.major, v.minor, v.patch))


class BundleManager:
    """Manager wersjonowania bundle'ów OPA.

    Zapewnia:
    - Semver versioning (MAJOR.MINOR.PATCH)
    - SHA-256 hashowanie zawartości
    - Aktywację/dezaktywację wersji
    - Rollback do poprzedniej wersji
    - Listę wszystkich wersji z historią
    """

    def __init__(self, bundles_dir: Path | None = None) -> None:
        self._bundles_dir = bundles_dir or DEFAULT_BUNDLES_DIR
        self._manifest_path = self._bundles_dir / MANIFEST_FILENAME
        self._manifest: BundleManifest | None = None
        self._load_manifest()

    def _load_manifest(self) -> None:
        """Wczytuje manifest z pliku lub tworzy nowy."""
        if self._manifest_path.exists():
            data = json.loads(self._manifest_path.read_text())
            versions = [
                BundleVersion(
                    major=v["major"],
                    minor=v["minor"],
                    patch=v["patch"],
                    hash=v["hash"],
                    created_at=v.get("created_at", 0),
                    description=v.get("description", ""),
                    is_active=v.get("is_active", False),
                    is_deprecated=v.get("is_deprecated", False),
                )
                for v in data.get("versions", [])
            ]
            self._manifest = BundleManifest(
                name=data.get("name", "jdg"),
                versions=versions,
                current_version=data.get("current_version", ""),
            )
        else:
            self._manifest = BundleManifest(name="jdg")
            self._save_manifest()

    def _save_manifest(self) -> None:
        """Zapisuje manifest do pliku JSON."""
        if self._manifest is None:
            return

        self._bundles_dir.mkdir(parents=True, exist_ok=True)
        payload = {
            "name": self._manifest.name,
            "current_version": self._manifest.current_version,
            "versions": [
                {
                    "major": v.major,
                    "minor": v.minor,
                    "patch": v.patch,
                    "hash": v.hash,
                    "created_at": v.created_at,
                    "description": v.description,
                    "is_active": v.is_active,
                    "is_deprecated": v.is_deprecated,
                }
                for v in self._manifest.versions
            ],
        }
        self._manifest_path.write_text(json.dumps(payload, indent=2))

    def register_version(
        self,
        major: int,
        minor: int,
        patch: int,
        bundle_content: str,
        description: str = "",
    ) -> BundleVersion:
        """Rejestruje nową wersję bundle'a.

        Args:
            major: Major version (breaking changes).
            minor: Minor version (new features).
            patch: Patch version (bug fixes).
            bundle_content: Zawartość bundle'a do hashowania.
            description: Opis zmian.

        Returns:
            Zarejestrowana wersja.
        """
        if self._manifest is None:
            self._load_manifest()
        assert self._manifest is not None

        # Oblicz SHA-256 bundle'a
        bundle_hash = hashlib.sha256(bundle_content.encode()).hexdigest()

        # Sprawdź czy ta wersja już istnieje
        for existing in self._manifest.versions:
            if existing.semver == f"{major}.{minor}.{patch}":
                logger.warning(
                    f"[Bundle] Version {existing.semver} already exists "
                    f"(hash: {existing.short_hash})"
                )
                return existing

        version = BundleVersion(
            major=major,
            minor=minor,
            patch=patch,
            hash=bundle_hash,
            description=description,
            is_active=False,
        )

        self._manifest.versions.append(version)
        self._save_manifest()

        logger.info(
            f"[Bundle] Registered version {version.semver} "
            f"(hash: {version.short_hash}, desc: {description})"
        )
        return version

    def activate_version(self, semver: str) -> bool:
        """Aktywuje wskazaną wersję (dezaktywuje pozostałe).

        Args:
            semver: Wersja do aktywacji (np. "1.2.3").

        Returns:
            True jeśli aktywacja się powiodła.
        """
        if self._manifest is None:
            return False

        target = None
        for v in self._manifest.versions:
            if v.semver == semver and not v.is_deprecated:
                target = v
                break

        if target is None:
            logger.error(
                f"[Bundle] Version {semver} not found or deprecated"
            )
            return False

        # Dezaktywuj wszystkie
        for v in self._manifest.versions:
            v.is_active = False

        # Aktywuj wybraną
        target.is_active = True
        self._manifest.current_version = semver
        self._save_manifest()

        logger.info(f"[Bundle] Activated version {semver} (hash: {target.short_hash})")
        return True

    def rollback(self) -> BundleVersion | None:
        """Rollback do poprzedniej aktywnej wersji.

        Returns:
            Poprzednia wersja lub None jeśli brak.
        """
        if self._manifest is None:
            return None

        active = self._manifest.active_version
        if active is None:
            return None

        # Znajdź poprzednią niezdeprecjonowaną wersję
        sorted_versions = sorted(
            self._manifest.versions,
            key=lambda v: (v.major, v.minor, v.patch),
            reverse=True,
        )

        found_active = False
        for v in sorted_versions:
            if found_active and not v.is_deprecated:
                self.activate_version(v.semver)
                logger.warning(
                    f"[Bundle] ROLLBACK: {active.semver} → {v.semver}"
                )
                return v
            if v.semver == active.semver:
                found_active = True

        logger.error("[Bundle] No previous version available for rollback")
        return None

    def get_current_version(self) -> BundleVersion | None:
        """Zwraca aktualnie aktywną wersję."""
        if self._manifest is None:
            return None
        return self._manifest.active_version

    def get_version(self, semver: str) -> BundleVersion | None:
        """Znajduje wersję po semver."""
        if self._manifest is None:
            return None
        for v in self._manifest.versions:
            if v.semver == semver:
                return v
        return None

    def list_versions(self) -> list[BundleVersion]:
        """Lista wszystkich zarejestrowanych wersji."""
        if self._manifest is None:
            return []
        return sorted(
            self._manifest.versions,
            key=lambda v: (v.major, v.minor, v.patch),
            reverse=True,
        )

    def deprecate_version(self, semver: str) -> bool:
        """Oznacza wersję jako zdeprecjonowaną."""
        if self._manifest is None:
            return False

        for v in self._manifest.versions:
            if v.semver == semver:
                v.is_deprecated = True
                v.is_active = False
                self._save_manifest()
                logger.info(f"[Bundle] Deprecated version {semver}")
                return True

        return False

    @staticmethod
    def compute_bundle_hash(policies_dir: str | Path) -> str:
        """Oblicza SHA-256 wszystkich plików .rego w katalogu.

        Używane do weryfikacji integralności bundle'a.
        """
        dir_path = Path(policies_dir)
        hasher = hashlib.sha256()

        for rego_file in sorted(dir_path.rglob("*.rego")):
            content = rego_file.read_bytes()
            hasher.update(content)

        return hasher.hexdigest()
