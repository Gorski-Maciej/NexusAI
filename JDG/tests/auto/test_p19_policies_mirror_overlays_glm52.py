#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# P19 — POLICIES MIRROR + OVERLAYS (GLM52) — testy pytest
# Pokrycie: OverlayEngine (algebra interwałów, day-edges, impact),
#           OverlayGenerator (skan, kandydaci, duchy, generate/verify),
#           DriftDashboard (scan, gate), bundle.sh (podpis w dystrybucji).
# ═══════════════════════════════════════════════════════════════════════════════
import json
import subprocess
import sys
from pathlib import Path

import pytest

JDG_ROOT = Path(__file__).resolve().parents[2]
TOOLS = JDG_ROOT / "tools"
POLICIES = JDG_ROOT.parent / "policies"


def run_tool(name: str, *args: str) -> dict:
    """Uruchom narzędzie P19 i zwróć wynik JSON."""
    out = subprocess.run(
        [sys.executable, str(TOOLS / name), *args],
        capture_output=True, text=True, cwd=JDG_ROOT, timeout=180,
    )
    assert out.returncode == 0, f"{name} {args} failed: {out.stderr[:500]}"
    return json.loads(out.stdout)


# ── OverlayEngine ─────────────────────────────────────────────────────────────
class TestOverlayEngine:
    def test_check_intervals_tcl_100(self):
        r = run_tool("overlay_engine.py", "check")
        assert r["tcl_100"] is True, r
        assert r["overlaps"] == [], r
        assert r["gaps"] == [], r
        assert r["overlays"] >= 2

    def test_year_boundary_is_contiguous(self):
        """2026-12-31 → 2027-01-01 to ciągłość, nie luka (P1624)."""
        r = run_tool("overlay_engine.py", "check")
        assert r["gate"] == "PASS"
        assert all("2026→2027" not in g.get("between", "") for g in r["gaps"])

    def test_day_edges_2026(self):
        r = run_tool("overlay_engine.py", "day-edges", "--year", "2026")
        assert r["year"] == 2026
        assert len(r["tests"]) >= 1
        t = r["tests"][0]
        assert t["day_minus_1"] == "2025-12-31"
        assert t["day_0"] == "2026-01-01"
        assert t["day_plus_1"] == "2026-01-02"
        assert t["boundary_ok"] is True

    def test_day_edges_2027(self):
        r = run_tool("overlay_engine.py", "day-edges", "--year", "2027")
        assert r["year"] == 2027
        assert len(r["tests"]) >= 1
        assert r["tests"][0]["day_0"] == "2027-01-01"

    def test_impact_2026_lists_planned_changes(self):
        r = run_tool("overlay_engine.py", "impact", "--year", "2026")
        assert r["year"] == 2026
        assert r["changes_count"] >= 3
        rules = {c["rule"] for c in r["changes"]}
        assert "jdg.pit.forms.scale" in rules
        assert all(c["status"] == "PLANNED" for c in r["changes"])

    def test_impact_2027_empty_placeholder(self):
        r = run_tool("overlay_engine.py", "impact", "--year", "2027")
        assert r["year"] == 2027
        assert r["changes_count"] == 0


# ── OverlayGenerator ──────────────────────────────────────────────────────────
class TestOverlayGenerator:
    def test_scan_catalog_large(self):
        r = run_tool("overlay_generator.py", "scan")
        assert r["rules"] > 10000, r

    def test_generate_2026_no_ghosts(self):
        r = run_tool("overlay_generator.py", "generate", "--year", "2026")
        assert r["gate"] == "PASS", r
        assert r["ghost_count"] == 0
        assert r["changes_total"] >= 3

    def test_generate_2027_placeholder(self):
        r = run_tool("overlay_generator.py", "generate", "--year", "2027")
        assert r["gate"] == "PASS", r
        assert r["ghost_count"] == 0

    def test_verify_2026_pass(self):
        r = run_tool("overlay_generator.py", "verify", "--year", "2026")
        assert r["gate"] == "PASS", r
        assert r["ghost_count"] == 0
        assert r["tcl_100"] is True

    def test_verify_2027_pass(self):
        r = run_tool("overlay_generator.py", "verify", "--year", "2027")
        assert r["gate"] == "PASS", r
        assert r["ghost_count"] == 0

    def test_manifest_has_lkg_metadata(self):
        mf = POLICIES / "jdg" / "bundles" / "overlays" / "v2026" / "manifest.json"
        assert mf.exists()
        d = json.loads(mf.read_text(encoding="utf-8"))
        assert d["generated_by"] == "overlay_generator.py"
        assert d["lkg"]["covered_nodes"] >= 100

    def test_candidate_rule_exists_in_catalog(self):
        """Kandydaci overlay muszą istnieć w rules/ (zero duchów P1617)."""
        from tools.overlay_generator import KNOWN_CANDIDATES, scan_rules
        catalog = {r["rule"] for r in scan_rules()}
        for cand in KNOWN_CANDIDATES:
            assert cand["rule"] in catalog, f"duch: {cand['rule']}"


# ── DriftDashboard ────────────────────────────────────────────────────────────
class TestDriftDashboard:
    def test_drift_zero(self):
        r = run_tool("drift_dashboard.py", "gate")
        assert r["gate"] == "PASS", r
        assert r["drifted"] == 0
        assert r["missing"] == 0
        assert r["drift_pct"] == 0.0
        assert r["total"] > 400

    def test_drift_manifest_timestamp(self):
        r = run_tool("drift_dashboard.py", "scan")
        assert r["last_sync"] is not None

    def test_mirror_file_exists_for_rules(self):
        """Każdy plik rules/ ma odpowiednik w policies/ (V1 §1)."""
        from tools.drift_dashboard import RULES_DIR, POLICIES_DIR
        missing = [p for p in RULES_DIR.rglob("*.rego")
                   if not (POLICIES_DIR / p.relative_to(RULES_DIR)).exists()]
        assert missing == [], f"brak mirrora: {[str(m) for m in missing[:5]]}"


# ── Bundle (podpis) ───────────────────────────────────────────────────────────
class TestBundle:
    def test_signed_bundle_dist_exists(self):
        dist = POLICIES / "jdg" / "bundles" / "dist"
        bundles = list(dist.glob("jdg-v2026.tar.gz"))
        assert bundles, "brak zbudowanego bundle jdg-v2026.tar.gz"

    def test_bundle_contains_signatures(self):
        import tarfile
        bundle = POLICIES / "jdg" / "bundles" / "dist" / "jdg-v2026.tar.gz"
        with tarfile.open(bundle, "r:gz") as tf:
            names = [n.removeprefix("./") for n in tf.getnames() if n not in (".", "./")]
            assert ".signatures.json" in names, names[:10]
            sig = json.loads(tf.extractfile("./.signatures.json").read())
        assert sig["alg"] == "SHA-256"
        assert sig["mode"] == "HSM-SHA256-Merkle"
        assert len(sig["files"]) > 400

    def test_bundle_signature_hashes_match_content(self):
        """Podpis per plik = faktyczny SHA-256 zawartości (integralność)."""
        import hashlib
        import io
        import tarfile
        bundle = POLICIES / "jdg" / "bundles" / "dist" / "jdg-v2026.tar.gz"
        with tarfile.open(bundle, "r:gz") as tf:
            sig = json.loads(tf.extractfile("./.signatures.json").read())
            # zweryfikuj 3 losowe pliki rego
            rego_files = [n for n in tf.getnames() if n.endswith(".rego")][:3]
            for name in rego_files:
                data = tf.extractfile(name).read()
                h = hashlib.sha256(data).hexdigest()
                key = name.removeprefix("./")
                assert sig["files"][key] == h, f"rozjazd podpisu: {name}"


if __name__ == "__main__":
    sys.exit(pytest.main([__file__, "-v"]))
