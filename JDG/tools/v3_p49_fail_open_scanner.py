#!/usr/bin/env python3
"""NexusAI JDG — V3-P49 FAIL-OPEN PATH SCANNER (I02/I10 — rejestr ścieżek fail-open).

Skanuje canonical (JDG/rules/**/*.rego) i wykrywa anty-wzorzec AP03/AP07:
else-chain decyzyjny, którego OSTATNIA gałąź zwraca decision_mode AUTO_POST
lub SUGGEST — czyli regułę, która przy niepewności milcząco „ląduje" na
ścieżce pozytywnej (cichy AUTO_POST = najgroźniejsza klasa defektów fortecy).

Metoda: analiza strukturalna bloków (śledzenie granic gałęzi else po liniach,
precyzyjniej niż regex-per-match; lekcja P46 — sygnatura treściowa, nie
numery linii). Zgodność z kontraktem P03/P49: poprawna reguła kończy łańcuch
jawnym NEEDS_ADVICE / MANUAL_REVIEW / BLOCK.

Honesty (protokół 14): zero fantazji liczb — każdy wpis rejestru ma plik,
linię i decision_mode. Wynik = bundle v3_p49_fail_open_registry.json
(konwencja P48: gate=PASS = narzędzie URUCHOMIONE i dowód ZAPISANY; decyzja
TRIAGE/BLOCK żyje w metrics.routing).
"""
from __future__ import annotations

import re

from v3_p48_common import RULES_DIR, walk_rego
from v3_p49_common import read_json, write_p49_bundle
from pathlib import Path

FAIL_OPEN_MODES = {"AUTO_POST", "SUGGEST"}

BUNDLES = Path(__file__).resolve().parents[1] / "bundles"

ELSE_LINE = re.compile(r"^\s*\}?\s*else\s*(?::=|=)\s*(.*)$")
DECISION_MODE_RE = re.compile(r'"decision_mode"\s*:\s*"([A-Z_]+)"')


def strip_comments_keep_lines(src: str) -> list[str]:
    """Usuń komentarze (poza stringami) zachowując liczby linii."""
    out = []
    for line in src.splitlines():
        res = []
        instr = False
        esc = False
        for ch in line:
            if instr:
                res.append(ch)
                if esc:
                    esc = False
                elif ch == "\\":
                    esc = True
                elif ch == '"':
                    instr = False
            elif ch == '"':
                instr = True
                res.append(ch)
            elif ch == "#":
                break
            else:
                res.append(ch)
        out.append("".join(res))
    return out


def scan_file(rel: str, path) -> tuple[list[dict], int]:
    """Zwróć (findings, total_decision_chains) — łańcuch decyzyjny = else-chain
    z jawnym decision_mode w ostatniej gałęzi (dowód kontraktu P03)."""
    try:
        src = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return [], 0
    lines = strip_comments_keep_lines(src)
    n = len(lines)
    findings: list[dict] = []
    total_chains = 0
    i = 0
    while i < n:
        m = ELSE_LINE.match(lines[i])
        if not m:
            i += 1
            continue
        rest = m.group(1).strip()
        if rest and not rest.endswith("{"):
            # forma inline: `else := value` — gałąź jednowierszowa
            body = rest
            last_branch = True  # zakładamy koniec łańcucha (kolejna iteracja zweryfikuje)
            j = i + 1
        else:
            # forma blokowa: zbierz body do linii zaczynającej się od '}'
            body_lines = []
            j = i + 1
            while j < n and not lines[j].lstrip().startswith("}"):
                body_lines.append(lines[j])
                j += 1
            body = "\n".join(body_lines)
            last_branch = not (j < n and "else" in lines[j])
        modes = DECISION_MODE_RE.findall(body)
        if modes and last_branch:
            total_chains += 1
            if modes[-1] in FAIL_OPEN_MODES:
                findings.append({
                    "file": rel,
                    "line": i + 1,
                    "kind": "else_chain_fail_open",
                    "decision_mode": modes[-1],
                    "context": lines[i].strip()[:120],
                })
        i = max(j, i + 1)
    return findings, total_chains


def scan_rules(rules_dir=RULES_DIR) -> dict:
    files = walk_rego(rules_dir)
    findings: list[dict] = []
    total_chains = 0
    for rel, path in sorted(files.items()):
        f, c = scan_file(rel, path)
        findings.extend(f)
        total_chains += c
    explicit = total_chains - len(findings)
    score = round(explicit * 100.0 / total_chains, 2) if total_chains else 0.0
    return {"files_scanned": len(files), "findings": findings,
            "fail_open_paths": len(findings),
            "decision_chains_total": total_chains,
            "paths_explicit_else": explicit,
            "fail_closed_score_pct": score}


def main() -> int:
    previous = read_json(BUNDLES / "v3_p49_fail_open_registry.json") or {}
    result = scan_rules()
    findings = result["findings"]

    metrics = {
        "files_scanned": result["files_scanned"],
        "fail_open_paths": result["fail_open_paths"],
        "decision_chains_total": result["decision_chains_total"],
        "paths_explicit_else": result["paths_explicit_else"],
        "fail_closed_score_pct": result["fail_closed_score_pct"],
        "silent_auto_post_max": 0,  # próg v3_p49_silent_auto_post_max (ADR-002)
        "routing": "BLOCK_AND_ALERT" if findings else "AUTO_FILE",
        "previous_fail_open_paths": len(previous.get("evidence", {}).get("findings", [])),
    }
    evidence = {
        "findings": findings[:200],
        "note": ("Rejestr ścieżek fail-open (AP03/AP07): ostatnia gałąź else-chain "
                 "z decision_mode AUTO_POST/SUGGEST = kandydat cichego AUTO_POST. "
                 "Każdy wpis wymaga: else → NEEDS_ADVICE z powodem (I07) albo "
                 "jawnej whitelist dowodów (I02). Baseline = backlog jawny, "
                 "priorytetyzacja wg kwoty (kryterium 19 raportu P49)."),
        "scanned_at": read_json(BUNDLES / "v3_p49_fail_open_registry.json",
                                {}).get("evidence", {}).get("scanned_at") or None,
    }
    from v3_p49_common import utcnow_iso
    evidence["scanned_at"] = utcnow_iso()
    write_p49_bundle("fail_open_registry", "V3-P49-I02+I10", metrics, evidence)
    print(f"[V3-P49-SCANNER] files={result['files_scanned']} "
          f"fail_open_paths={result['fail_open_paths']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
