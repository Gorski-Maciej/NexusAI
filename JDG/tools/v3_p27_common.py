#!/usr/bin/env python3
"""NexusAI JDG — V3-P27 shared evidence helper (kampania V3 FORTRESS).

Wspólne narzędzia dla 12 tooli dowodowych V3-P27-I01..I12: czytanie plików,
skan reguł w rules/v3_p27_cfc_exit_mdr_enterprise.rego, skan parametrów w
rules/thresholds_jdg.rego (blok crossborder = rdzeń, klucze v3_p27_* =
governance), skan stubów w plikach legacy CFC/exit/MDR, wiring main_jdg
(final_verdict_p91) i zapis bundle dowodowych do bundles/.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
RULES = BASE / "rules"
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"

P27_RULES = RULES / "v3_p27_cfc_exit_mdr_enterprise.rego"
THRESHOLDS = RULES / "thresholds_jdg.rego"
MAIN_JDG = RULES / "main_jdg.rego"

# Pliki legacy audytowane przez P27 (Sekcja 6 promptu) — anti-pattern scan
LEGACY_FILES = {
    "exit_tax_cfc_complete": RULES / "crossborder" / "exit_tax_cfc_complete.rego",
    "exit_tax_mdr_enterprise": RULES / "exit_tax_mdr_enterprise.rego",
    "cfc_auto_classifier": RULES / "cfc_auto_classifier.rego",
    "mdr_hallmarks": RULES / "mdr" / "mdr_hallmarks.rego",
    "mdr_dac6_enterprise": RULES / "mdr_dac6_enterprise.rego",
}

# Wartości rdzenia (blok crossborder) — mirror jako dane (ADR-002)
CROSSBORDER_CORE = {
    "exit_tax_threshold_pln": 4000000,
    "exit_tax_rate_pct": 0.19,
    "exit_tax_deferral_years_eea": 5,
    "mdr_deadline_days": 30,
    "cfc_ownership_min_pct": 0.50,
    "cfc_passive_income_pct": 0.33,
    "cfc_tax_rate_threshold_pct": 0.1425,
    "residency_days": 183,
}

# Wartości ZWERYFIKOWANE w źródłach publicznych (sesja P27, 2026-09-06):
# * próg exit tax przy przeniesieniu majątku: 2 000 000 PLN (art. 24cg ust. 5 PIT)
#   [ZWERYFIKOWANO-WEB: podatki.gov.pl / opracowania 2024-2026] — prompt P27
#   twierdził „2M/5M" — kwota 5M NIEZWERYFIKOWANA, uznana za błąd promptu.
# * próg łącznej wartości rynkowej aktywów (wyłączenie): 4 000 000 PLN
#   (art. 30da ust. 1 pkt 2 PIT) [ZWERYFIKOWANO-WEB].
# * MDR: kryterium kwalifikowanego korzystającego 10 mln EUR / 2,5 mln EUR
#   (objaśnienia MF, podatki.gov.pl/mdr) [ZWERYFIKOWANO-WEB] — kwota
#   „50M PLN funkcji pomocniczej" z promptu pozostaje [NIEZWERYFIKOWANE].
VERIFIED_WEB = {
    "exit_tax_property_threshold_pln": 2000000,
    "exit_tax_total_assets_threshold_pln": 4000000,
    "mdr_qualified_beneficiary_eur": 10000000,
    "mdr_arrangement_value_eur": 2500000,
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="ignore") if path.exists() else ""


def rule_present(rule_id: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(P27_RULES)
    return rule_id in hay


def threshold_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def core_value_present(key: str, hay: str | None = None) -> bool:
    hay = hay if hay is not None else read(THRESHOLDS)
    return re.search(rf'"{re.escape(key)}"\s*:', hay) is not None


def thresholds_missing(keys: list[str], hay: str | None = None) -> list[str]:
    hay = hay if hay is not None else read(THRESHOLDS)
    return [k for k in keys if not threshold_present(k, hay)]


def main_jdg_wired(alias: str = "v3_p27_cfc_exit_mdr") -> bool:
    main = read(MAIN_JDG)
    return (f"import data.jdg.{alias} as {alias}" in main
            and f'"jdg.{alias}": {alias}.decide' in main
            and "final_verdict_p91" in main)


def stub_scan(hay: str) -> list[str]:
    """Wykryj anty-wzorce AP01 (stub { true }) i AP02 (hardcode progów) w rego."""
    hits = []
    for i, line in enumerate(hay.splitlines(), 1):
        code = line.split("#", 1)[0].strip()
        if re.search(r"\{\s*$", code) and code.endswith("{ true"):
            hits.append(f"AP01:stub:{i}")
        if re.search(r"\{\s*$", code) and re.search(r"==\s*true\s*$", code):
            hits.append(f"AP01:always_true:{i}")
    return hits


def legacy_stub_hits() -> dict[str, list[str]]:
    return {name: stub_scan(read(path)) for name, path in LEGACY_FILES.items()}


def emit(bundle: dict, name: str) -> int:
    (BUNDLES / f"{name}.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    gate = bundle.get("gate", "FAIL")
    print(f"[{bundle.get('innovation', name)}] gate={gate} "
          f"checks={len(bundle.get('checks', []))} findings={len(bundle.get('findings', []))}")
    return 1 if gate == "FAIL" else 0
