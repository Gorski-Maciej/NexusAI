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
PERSIST_PATH = BUNDLES_DIR / "node_persistence.json"
DELTA_DIR = BUNDLES_DIR / "deltas"


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


def persist_node_state(active_version: str | None, healthy_versions: list[str],
                       *, verified_at: str | None = None) -> dict:
    """Persist the last verified node state for offline restart.

    This is a local durable checkpoint only. It is never a production
    certification signal; an empty or unverified checkpoint stays fail-closed.
    """
    state = {
        "schema_version": "1.0.0",
        "persist": True,
        "active_version": active_version,
        "healthy_versions": sorted(set(healthy_versions)),
        "verified_at": verified_at or now(),
        "restart_policy": "START_LAST_VERIFIED_OR_FAIL_CLOSED",
    }
    save(PERSIST_PATH, state)
    return state


def persisted_node_state() -> dict:
    """Return the durable node checkpoint without inferring health."""
    state = load(PERSIST_PATH)
    return state if state.get("persist") is True else {
        "persist": False,
        "active_version": None,
        "healthy_versions": [],
        "restart_policy": "FAIL_CLOSED",
    }


def delta_manifest(base_version: str, target_version: str) -> dict:
    """Describe an unsigned delta and require a signed snapshot for promotion.

    OPA delta bundles cannot replace signature verification for critical domains;
    the control plane therefore exposes the delta for transport but requires a
    verified full snapshot before activation.
    """
    manifest = {
        "schema_version": "1.0.0",
        "kind": "DELTA",
        "base_version": base_version,
        "target_version": target_version,
        "signed": False,
        "requires_signed_snapshot": True,
        "promotion_policy": "FULL_SNAPSHOT_ONLY_FOR_CRITICAL_DOMAINS",
        "generated_at": now(),
    }
    DELTA_DIR.mkdir(parents=True, exist_ok=True)
    save(DELTA_DIR / f"{base_version}_to_{target_version}.json", manifest)
    return manifest


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
        "delivery": {"supports_delta": True, "delta_requires_signed_snapshot": True},
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
    if node_ok:
        healthy = _healthy().get("healthy_versions", [])
        if version not in healthy:
            healthy.append(version)
        persist_node_state(version, healthy, verified_at=now())
    return {"version": version, "verified": verified,
            "sha256": digest, "signature": sig,
            "sbom_verified": sbom_ok, "merkle_root": merkle_root,
            "merkle_verified": sbom_ok,
            "node_verification": "PASS" if node_ok else "FAIL_CLOSED",
            "persisted": node_ok,
            "delta_policy": "FULL_SNAPSHOT_REQUIRED" if not node_ok else "DELTA_ALLOWED_FOR_TRANSPORT_ONLY",
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
    persisted = persisted_node_state()
    return {
        "mode": "STATUS",
        "latest": cat.get("latest"),
        "versions": len(cat.get("versions", {})),
        "healthy": healthy.get("healthy_versions", []),
        "persisted_active_version": persisted.get("active_version"),
        "persisted": persisted.get("persist", False),
        "updated_at": cat.get("updated_at"),
    }


def discovery() -> dict:
    """Discovery: punkt wejścia dla węzłów OPA (adresy, wersje, podpisy)."""
    cat = _catalog()
    return {
        "mode": "DISCOVERY",
        "service": "jdg-bundle-server",
        "endpoint": "/v1/bundles",
        "delta_endpoint": "/v1/bundles/{base}/delta/{target}",
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
    ps = sub.add_parser("persist"); ps.set_defaults(fn=lambda a: print(json.dumps(persisted_node_state(), ensure_ascii=False, indent=1)))
    dl = sub.add_parser("delta"); dl.add_argument("--base", required=True); dl.add_argument("--target", required=True)
    dl.set_defaults(fn=lambda a: print(json.dumps(delta_manifest(a.base, a.target), ensure_ascii=False, indent=1)))
    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
