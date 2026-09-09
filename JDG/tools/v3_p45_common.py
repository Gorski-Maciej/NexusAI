#!/usr/bin/env python3
"""NexusAI JDG — V3-P45 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P45-I01..I12: skan reguł w
rules/v3_p45_stub_killer.rego + rules/v3_p45_conversions.rego, skan
parametrów w rules/thresholds_jdg.rego (blok v3_p45), wiring main_jdg
(final_verdict_p109) oraz zapis bundle dowodowych do bundles/.

Rejestr stubów (stub_register.json) jest SINGLE SOURCE OF TRUTH: generują go
narzędzia 6.1 (else_chain_dead_code_detector, tautology_guard) — liczby w
bundlach pochodzą z narzędzi, nie z deklaracji (honesty, V1 zasada 6).
"""
from __future__ import annotations

import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
TESTS = BASE / "tests"
DOCS = BASE / "docs"
REPORTS_V3 = BASE / "raporty_glm52_v3"
REPO_ROOT = BASE.parent

P45_RULES = RULES / "v3_p45_stub_killer.rego"
P45_CONVERSIONS = RULES / "v3_p45_conversions.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"
RULE_REGISTRY = BUNDLES / "rule_registry.json"
LEDGER = BUNDLES / "v3_campaign_ledger.json"

# Rejestr stubów i dowody narzędzi 6.1 (generowane, nie deklarowane)
STUB_REGISTER = BUNDLES / "stub_register.json"
STUB_REGISTER_MD = BUNDLES / "stub_register.md"
MUTATION_RESULTS = BUNDLES / "mutation_results.json"
MUTATION_RUNNER = TOOLS / "mutation_runner.py"

# Narzędzia detekcji 6.1 promptu P45 (świadek inwentaryzacji)
DETECTION_TOOLS = {
    "convert_true_to_conditions": TOOLS / "convert_true_to_conditions.py",
    "tautology_guard": TOOLS / "tautology_guard.py",
    "else_chain_dead_code_detector": TOOLS / "else_chain_dead_code_detector.py",
    "dead_rule_detector": TOOLS / "dead_rule_detector.py",
    "debug_converter": TOOLS / "debug_converter.py",
    "lint_rego_rules": TOOLS / "lint_rego_rules.py",
    "validate_rules": TOOLS / "validate_rules.py",
    "hardcoded_audit": TOOLS / "hardcoded_audit.py",
}

# Domeny krytyczne (stub w tej domenie udaje pokrycie VAT/PIT/ZUS/KKS —
# najgroźniejsze: generują błędne AUTO_POST materiałowe)
CRITICAL_DOMAINS = {"vat", "pit", "zus", "kks"}

# 12 narzędzi V3-P45 (12 innowacji)
P45_TOOLS = [
    "v3_p45_stub_register", "v3_p45_stub_forensics",
    "v3_p45_auto_convert_pipeline", "v3_p45_negative_assertion",
    "v3_p45_mutation_gate", "v3_p45_stub_free_badge",
    "v3_p45_template_policy", "v3_p45_stub_enabling_tests",
    "v3_p45_provenance", "v3_p45_stub_census",
    "v3_p45_legal_empty", "v3_p45_isap_parity",
]

# Bundle → innowacja (testy + audit)
BUNDLE_TO_INNOVATION = {
    "v3_p45_stub_register": "V3-P45-I01",
    "v3_p45_stub_forensics": "V3-P45-I02",
    "v3_p45_auto_convert_pipeline": "V3-P45-I03",
    "v3_p45_negative_assertion": "V3-P45-I04",
    "v3_p45_mutation_gate": "V3-P45-I05",
    "v3_p45_stub_free_badge": "V3-P45-I06",
    "v3_p45_template_policy": "V3-P45-I07",
    "v3_p45_stub_enabling_tests": "V3-P45-I08",
    "v3_p45_provenance": "V3-P45-I09",
    "v3_p45_stub_census": "V3-P45-I10",
    "v3_p45_legal_empty": "V3-P45-I11",
    "v3_p45_isap_parity": "V3-P45-I12",
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def read_json(path: Path):
    """Wczytaj JSON albo {} gdy plik nie istnieje/uszkodzony (fail-closed: {})."""
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8", errors="ignore"))
    except json.JSONDecodeError:
        return {}


def write_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2),
                    encoding="utf-8")


def rule_present(rule_id: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(P45_RULES)
    return rule_id in hay


def conversion_rule_present(rule_id: str) -> bool:
    return rule_id in read(P45_CONVERSIONS)


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def main_jdg_wired(alias: str = "v3_p45_stub_killer") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p109" in main)


def opa_check(paths: list[Path], binary: str = "opa") -> tuple[bool, str]:
    """OPA check; na bin/opa19 wymagany --v0-compatible (syntax v0)."""
    exe = REPO_ROOT / "bin" / binary
    cmd = [str(exe), "check"]
    if binary == "opa19":
        cmd.append("--v0-compatible")
    cmd += [str(p) for p in paths]
    proc = subprocess.run(cmd, cwd=REPO_ROOT, capture_output=True, text=True,
                          timeout=120)
    return proc.returncode == 0, (proc.stdout + proc.stderr).strip()


def opa_test(paths: list[Path], binary: str = "opa") -> tuple[bool, int, str]:
    """OPA test; zwraca (ok, liczba przypadków PASS, output)."""
    exe = REPO_ROOT / "bin" / binary
    cmd = [str(exe), "test", "--v0-compatible"]
    if binary == "opa":
        cmd = [str(exe), "test"]
    cmd += [str(p) for p in paths]
    proc = subprocess.run(cmd, cwd=REPO_ROOT, capture_output=True, text=True,
                          timeout=300)
    out = proc.stdout + proc.stderr
    m = re.search(r"PASS: (\d+)/(\d+)", out)
    total = int(m.group(2)) if m else 0
    return proc.returncode == 0, total, out.strip()


def domain_of_file(rel_path: str) -> str:
    """Domena z pierwszego segmentu rules/<domena>/... albo nazwa pliku."""
    parts = rel_path.split("/")
    if len(parts) > 2 and parts[0] in ("rules", "JDG/rules"):
        return parts[1]
    name = Path(rel_path).stem
    return name.split("_")[0]


def is_critical_domain(domain: str) -> bool:
    return domain in CRITICAL_DOMAINS


def detect_stubs_from_tool() -> dict:
    """Uruchom else_chain_dead_code_detector i sparsuj wynik (liczniki
    z narzędzia, nie z deklaracji — protokół 06: dowodem jest wynik
    uruchomienia)."""
    proc = subprocess.run(
        ["python", str(TOOLS / "else_chain_dead_code_detector.py")],
        cwd=BASE, capture_output=True, text=True, timeout=300)
    out = proc.stdout + proc.stderr
    m = re.search(r"(\d+)\s+stubów bez CHECKPOINT,\s*(\d+)\s+identycznych"
                  r"\s+triggerów,\s*(\d+)\s+nieosiągalnych", out)
    stub_lines = re.findall(r"\[STUB_NO_CHECKPOINT\]\s+([\w.]+):", out)
    return {
        "stubs_no_checkpoint": int(m.group(1)) if m else len(stub_lines),
        "identical_triggers": int(m.group(2)) if m else 0,
        "unreachable": int(m.group(3)) if m else 0,
        "stub_rule_ids": stub_lines,
        "tool": "tools/else_chain_dead_code_detector.py",
        "run_at": now(),
    }


def detect_tautologies_from_tool() -> dict:
    """Uruchom tautology_guard i sparsuj licznik plików tautologicznych."""
    proc = subprocess.run(["python", str(TOOLS / "tautology_guard.py")],
                          cwd=BASE, capture_output=True, text=True, timeout=300)
    out = proc.stdout + proc.stderr
    m = re.search(r"(\d+)\s+plików z tautologiami", out)
    return {
        "tautological_test_files": int(m.group(1)) if m else 0,
        "tool": "tools/tautology_guard.py",
        "run_at": now(),
    }


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
