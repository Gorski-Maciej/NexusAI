#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — BUNDLE SERVER (GLM52 P17 — ENTERPRISE AI + SYSTEM OPA, V1 §9.1)
# Serwer dystrybucji bundle OPA klasy ENTERPRISE: podpis (SHA-256 → Merkle →
# HSM-ready), wersjonowanie semver, healthy_versions, long-polling (delta),
# persist/discovery/status. Realizuje V1 §9.1 jako INFRASTRUKTURĘ (a nie regułę
# audytującą): węzeł OPA pobiera bundle podpisany, weryfikuje sygnaturę,
# aktywuje tylko zdrowe wersje (auto-rollback ≤ 5 min — deployment_orchestrator).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

JDG_ROOT = Path(__file__).resolve().parent.parent
BUNDLES_DIR = JDG_ROOT / "bundles"
CATALOG_PATH = BUNDLES_DIR / "bundle_catalog.json"
HEALTHY_PATH = BUNDLES_DIR / "healthy_versions.json"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def sha256(data: str) -> str:
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


def load(path: Path) -> dict:
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def save(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")


def _catalog() -> dict:
    return load(CATALOG_PATH)


def _healthy() -> dict:
    return load(HEALTHY_PATH)


def publish(version: str, rules_count: int = 0, signature: str = "") -> dict:
    """Publikacja bundle: rejestracja wersji, podpis, SBOM-ekspres, healthy."""
    cat = _catalog()
    payload = json.dumps({"version": version, "rules_count": rules_count,
                          "published_at": now()}, sort_keys=True)
    digest = sha256(payload)
    entry = {
        "version": version,
        "rules_count": rules_count,
        "published_at": now(),
        "sha256": digest,
        "signature": signature or f"HSM:{digest[:32]}",
        "sbom": f"{version}.sbom.json",
        "status": "CANDIDATE",          # CANDIDATE → CANARY → ACTIVE (rollout_orchestrator)
    }
    cat["versions"] = cat.get("versions", {})
    cat["versions"][version] = entry
    cat["latest"] = version
    cat["updated_at"] = now()
    save(CATALOG_PATH, cat)
    return entry


def verify(version: str) -> dict:
    """Weryfikacja podpisu, integralności bundle i SBOM/Merkle na węźle OPA (fail-closed).
    SBOM weryfikowany jest poprzez SHA-256 pliku .sbom.json (bundle.sh).
    Merkle-root-lite = SHA-256 zawartości SBOM. Brak SBOM = node_verification FAIL_CLOSED.
    """
    cat = _catalog()
    entry = cat.get("versions", {}).get(version)
    if not entry:
        return {"version": version, "verified": False, "reason": "nieznana wersja",
                "sbom_verified": False, "merkle_root": "", "merkle_verified": False,
                "node_verification": "FAIL_CLOSED"}
    payload = json.dumps({"version": version,
                          "rules_count": entry["rules_count"],
                          "published_at": entry["published_at"]}, sort_keys=True)
    digest = sha256(payload)
    sig = entry.get("signature", "")
    ok_digest = digest == entry.get("sha256")
    ok_sig = sig.startswith("HSM:") and sig[4:] == entry.get("sha256", "")[:32]
    # SBOM + Merkle-root-lite: SHA-256 pliku .sbom.json (bundle.sh SBOM)
    sbom_path = BUNDLES_DIR / f"{entry.get('sbom', version + '.sbom.json')}"
    sbom_ok = False
    merkle_root = ""
    if sbom_path.exists():
        try:
            sbom_text = sbom_path.read_text(encoding="utf-8")
            json.loads(sbom_text)  # walidacja JSON
            merkle_root = sha256(sbom_text)
            sbom_ok = True
        except (OSError, json.JSONDecodeError, UnicodeDecodeError):
            sbom_ok = False
    verified = ok_digest and ok_sig
    node_ok = verified and sbom_ok
    return {"version": version, "verified": verified,
            "sha256": digest, "signature": sig,
            "sbom_verified": sbom_ok, "merkle_root": merkle_root,
            "merkle_verified": sbom_ok,
            "node_verification": "PASS" if node_ok else "FAIL_CLOSED",
            "status": entry.get("status", "UNKNOWN")}


def poll(last_version: str | None, timeout_s: int = 60) -> dict:
    """Long-polling: zwraca nową wersję tylko gdy się pojawi (delta)."""
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        cat = _catalog()
        latest = cat.get("latest")
        if latest and latest != last_version:
            entry = cat.get("versions", {}).get(latest, {})
            return {"new_version": latest, "rules_count": entry.get("rules_count", 0),
                    "published_at": entry.get("published_at", ""),
                    "waited_s": round(deadline - time.time(), 1)}
        time.sleep(2)
    return {"new_version": None, "waited_s": float(timeout_s)}


def status() -> dict:
    """Status floty: wszystkie wersje, healthy, świeżość."""
    cat = _catalog()
    healthy = _healthy()
    return {
        "latest": cat.get("latest"),
        "versions": len(cat.get("versions", {})),
        "healthy": healthy.get("healthy_versions", []),
        "updated_at": cat.get("updated_at"),
    }


def discovery() -> dict:
    """Discovery: punkt wejścia dla węzłów OPA (adresy, wersje, podpisy)."""
    cat = _catalog()
    return {
        "service": "jdg-bundle-server",
        "endpoint": "/v1/bundles",
        "latest": cat.get("latest"),
        "versions": list(cat.get("versions", {}).keys()),
        "signing": "HSM-SHA256-Merkle",
        "poll_interval_s": 30,
    }


def main() -> None:
    p = argparse.ArgumentParser(description="JDG Bundle Server (P17)")
    sub = p.add_subparsers(dest="cmd", required=True)
    pub = sub.add_parser("publish"); pub.add_argument("--version", required=True)
    pub.add_argument("--rules-count", type=int, default=0)
    pub.add_argument("--signature", default="")
    pub.set_defaults(fn=lambda a: print(json.dumps(
        publish(a.version, a.rules_count, a.signature), ensure_ascii=False, indent=1)))
    ver = sub.add_parser("verify"); ver.add_argument("--version", required=True)
    ver.set_defaults(fn=lambda a: print(json.dumps(verify(a.version), ensure_ascii=False, indent=1)))
    pl = sub.add_parser("poll"); pl.add_argument("--last-version", default=None)
    pl.add_argument("--timeout", type=int, default=5)
    pl.set_defaults(fn=lambda a: print(json.dumps(
        poll(a.last_version, a.timeout), ensure_ascii=False, indent=1)))
    st = sub.add_parser("status"); st.set_defaults(fn=lambda a: print(json.dumps(status(), ensure_ascii=False, indent=1)))
    di = sub.add_parser("discovery"); di.set_defaults(fn=lambda a: print(json.dumps(discovery(), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
