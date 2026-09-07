#!/usr/bin/env python3
"""V3-P29: Generator dowodowych raportów 14-20 (raporty_enterprise_v3).

Anty-fasada: każdy raport jest BUDOWANY z dowodów w momencie generowania:
  1) rzeczywisty wynik bramki jakości v3 (subprocess --json),
  2) rzeczywista inwentaryzacja artefaktów (exists() na każdej ścieżce),
  3) blok z bundles/enterprise_v3_registry.json (stan, zmiany, luki),
  4) metadane części z tools/v3_parts_data_b.py (PARTS_B).
Żadna liczba ani status nie jest wpisana na stałe — jeśli bramka nie przejdzie,
raport odzwierciedla to (EVIDENCE_LEVEL: GATE_FAIL), nie udaje sukcesu.
"""
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from v3_parts_data_b import PARTS_B  # noqa: E402

REGISTRY = ROOT / "bundles" / "enterprise_v3_registry.json"

# (numer, plik bramki, raport out)
GATE_FOR_PART = {
    "14": "hyper_quality_v3_14_gate",
    "15": "enterprise_quality_v3_15_gate",
    "16": "tools_quality_v3_16_gate",
    "17": "tests_ci_quality_v3_17_gate",
    "18": "bundles_quality_v3_18_gate",
    "19": "api_ui_quality_v3_19_gate",
    "20": "docs_quality_v3_20_gate",
}

W = 78


def hr(title: str) -> str:
    return "=" * W + "\n" + title + "\n" + "=" * W


def sub(title: str) -> str:
    return "\n" + "-" * W + "\n" + title + "\n" + "-" * W


def run_gate(module: str) -> dict:
    proc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / f"{module}.py"), "--json"],
        cwd=ROOT, text=True, capture_output=True, timeout=120,
    )
    try:
        start = proc.stdout.index("{")
        end = proc.stdout.rindex("}") + 1
        return json.loads(proc.stdout[start:end])
    except (ValueError, json.JSONDecodeError):
        return {"status": "BRAMKA_NIEDOSTEPNA", "gates": {}, "stderr": proc.stderr[-400:]}


def artifact_exists(spec: str) -> bool:
    """Ścieżki w PARTS_B są relatywne do repo root (część z nich nie leży w JDG/,
    np. .github/workflows, policies). Sprawdzamy oba korzenie."""
    rel = spec[4:] if spec.startswith("dir:") else spec
    is_dir = spec.startswith("dir:")
    for base in (ROOT, ROOT.parent):
        p = base / rel
        if is_dir:
            if p.is_dir():
                return True
        elif p.exists():
            return True
    return False


def evidence_level(gate_status: str, artifacts: list[tuple[str, bool]]) -> str:
    if gate_status != "WDROZONY_100":
        return "GATE_FAIL"
    if all(ok for _, _, ok in artifacts):
        return "FULL"
    return "PARTIAL"


def generate(num: str, tag: str, out: str, scope: str, luki: str, pomysly: str,
             groups: list) -> str:
    gate_mod = GATE_FOR_PART[num]
    gate = run_gate(gate_mod)
    reg = json.loads(REGISTRY.read_text(encoding="utf-8"))
    block = reg.get("czesci", {}).get(num, {})
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    # inwentaryzacja artefaktów z grup części
    inv: list[tuple[str, str, bool]] = []  # (grupa, ścieżka, istnieje)
    for gname, specs in groups:
        for spec in specs:
            inv.append((gname, spec, artifact_exists(spec)))

    lines: list[str] = []
    lines.append(hr(f"RAPORT V3-{num} {tag} — V3 FORTRESS JDG"))
    lines.append("=" * W)
    lines.append("STATUS:                          " + ("WDROZONY_100" if gate.get("status") == "WDROZONY_100" else str(gate.get("status"))))
    lines.append("EVIDENCE_LEVEL:                  " + evidence_level(str(gate.get("status")), inv))
    lines.append(f"CODE:                            P{num} (część {num} kampanii V3)")
    lines.append(f"BRAMKA_JAKOSCI:                  tools/{gate_mod}.py")
    lines.append(f"WYNIK_BRAMKI:                    {gate.get('status')} "
                 f"({gate.get('gate_summary', {}).get('passed', '?')}/{gate.get('gate_summary', {}).get('total', '?')} bramek)")
    lines.append(f"DATA_GENERACJI:                  {now}")
    lines.append("METODOLOGIA:                     raport generowany z dowodów (bramka --json +")
    lines.append("                                 inwentaryzacja exists() + rejestr enterprise_v3)")
    lines.append("=" * W)

    lines.append(sub("SEKCJA A — ZAKRES CZĘŚCI (źródło: v3_parts_data_b.PARTS_B)"))
    lines.append(str(scope))

    lines.append(sub("SEKCJA B — LUKI ARCHIWALNE ROZPOZNAWE W CZĘŚCI"))
    lines.append(str(luki))

    lines.append(sub("SEKCJA C — WYNIK RZECZYWISTEGO URUCHOMIENIA BRAMKI (dowód)"))
    lines.append(f"komenda: python tools/{gate_mod}.py --json")
    for name, ok in (gate.get("gates") or {}).items():
        lines.append(f"  {'PASS' if ok else 'FAIL'} {name}")
    if gate.get("opa"):
        lines.append(f"  opa_check: available={gate['opa'].get('available')} "
                     f"passed={gate['opa'].get('passed')}")
    if gate.get("stderr"):
        lines.append(f"  stderr(ostatnie): {gate['stderr'][:200]}")

    lines.append(sub("SEKCJA D — INWENTARYZACJA ARTEFAKTÓW (exists() na każdej ścieżce)"))
    lines.append(f"{'STATUS':6} | GRUPA | ŚCIEŻKA")
    lines.append("-" * W)
    missing = 0
    for gname, spec, ok in inv:
        lines.append(f"{'OK' if ok else 'BRAK':6} | {gname} | {spec}")
        if not ok:
            missing += 1
    lines.append("-" * W)
    lines.append(f"RAZEM: {len(inv)} artefaktów, obecnych {len(inv) - missing}, brakujących {missing}")

    lines.append(sub("SEKCJA E — BLOK REJESTRU enterprise_v3_registry.json (część " + num + ")"))
    if block:
        lines.append(f"stan:                {block.get('stan')}")
        lines.append(f"zgodnosc_v1v2:       {block.get('zgodnosc_v1v2')}")
        lines.append(f"liczba_zmienionych_plikow: {block.get('liczba_zmienionych_plikow')}")
        for ch in block.get("lista_glownych_zmian", []):
            lines.append(f"  • {ch}")
        for l in block.get("luki_pozostale", []):
            lines.append(f"  luka pozostała: {l}")
        lines.append(f"raport:              {block.get('raport')}")
    else:
        lines.append("BRAK BLOKU W REJESTRZE — luka dokumentacyjna (wpis do rejestru luk P29).")

    lines.append(sub("SEKCJA F — POMYSŁY ROZWOJOWE CZĘŚCI (z kampanii źródłowej)"))
    if isinstance(pomysly, (list, tuple)):
        for p in pomysly:
            lines.append(str(p))
    else:
        lines.append(str(pomysly))

    lines.append(sub("SEKCJA G — METODOLOGIA I GRANICE DOWODU"))
    lines.append("1. Wynik bramki w Sekcji C to rzeczywisty uruchomiony proces (subprocess),")
    lines.append("   nie deklaracja — timestamp w nagłówku jest momentem tego uruchomienia.")
    lines.append("2. Inwentaryzacja w Sekcji D sprawdza istnienie plików/katalogów, nie ich treść;")
    lines.append("   treść weryfikują same bramki jakości (kontrole markerów) — patrz Sekcja C.")
    lines.append("3. Blok rejestru w Sekcji E pochodzi 1:1 z bundles/enterprise_v3_registry.json.")
    lines.append("4. Raport NIE deklaruje '100% zgodności' — status WDROZONY_100 pochodzi")
    lines.append("   wyłącznie z wyniku bramki i może się zmienić przy kolejnym uruchomieniu.")
    lines.append("")
    lines.append("RAPORT WYGENEROWANY AUTOMATYCZNIE przez tools/v3_p29_enterprise_reports_generate.py")
    lines.append("(część P29 kampanii V3 — domknięcie braku report_present w bramkach 14-20).")
    return "\n".join(lines) + "\n"


def main() -> int:
    if not REGISTRY.exists():
        print(f"BRAK rejestru: {REGISTRY}")
        return 1
    written = []
    for num, tag, out, _cons, scope, luki, pomysly, groups in PARTS_B:
        if num not in GATE_FOR_PART:
            continue
        text = generate(num, tag, out, scope, luki, pomysly, groups)
        path = ROOT / "raporty_enterprise_v3" / f"{out}.txt"
        path.write_text(text, encoding="utf-8")
        written.append(str(path.relative_to(ROOT)))
        print(f"OK {path.relative_to(ROOT)} ({len(text.splitlines())} linii)")
    print(f"\nWygenerowano {len(written)} raportów.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
