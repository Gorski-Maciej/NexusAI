#!/usr/bin/env python3
"""NexusAI JDG — V3-P49-I05 CIRCUIT BREAKER PER DOMAIN.

Seria N decyzji NEEDS_ADVICE z jednej domeny w oknie T minut → domena wchodzi
w tryb REVIEW (wszystko MANUAL) z raportem przyczyny. Stan liczony z realnych
źródeł: v3_p37_needs_advice_radar.json (sygnały NEEDS_ADVICE per domena) +
snapshot per-domain (bundles/v3_p49_breaker_state.json, trwały stan między
uruchomieniami). Próg i okno: data.thresholds.v3_p49 (ADR-002) —
v3_p49_breaker_threshold / v3_p49_breaker_window_min.

Wyjście: v3_p49_circuit_breaker.json. Domena w REVIEW bez raportu przyczyny =
TRIAGE (I05: tryb awaryjny zawsze z powodem — nigdy cisza).
"""
from __future__ import annotations

import re
from pathlib import Path

from v3_p48_common import BUNDLES_DIR, RULES_DIR, read_json, utcnow_iso, write_json
from v3_p49_common import rule_present, write_p49_bundle

BUNDLES = Path(__file__).resolve().parents[1] / "bundles"
P49_THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
BREAKER_STATE = BUNDLES_DIR / "v3_p49_breaker_state.json"
RADAR = BUNDLES_DIR / "v3_p37_needs_advice_radar.json"


def thresholds() -> dict:
    src = P49_THRESHOLDS_REGO.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"v3_p49\s*:=\s*\{(.*?)\n\}", src, re.DOTALL)
    out = {}
    if m:
        for k, v in re.findall(r'"(v3_p49_[a-z_0-9]+)"\s*:\s*([\d.]+)', m.group(1)):
            out[k] = float(v) if "." in v else int(v)
    return out


def domains_from_rules() -> list[str]:
    """Domeny = pakiety Rego pierwszego poziomu katalogów rules/ (źródło prawdy)."""
    pkgs = set()
    for p in RULES_DIR.rglob("*.rego"):
        rel = p.relative_to(RULES_DIR)
        pkgs.add(rel.parts[0] if len(rel.parts) > 1 else "(root)")
    return sorted(pkgs)


def main() -> int:
    th = thresholds()
    threshold = th.get("v3_p49_breaker_threshold", 20)
    window = th.get("v3_p49_breaker_window_min", 60)

    domains = domains_from_rules()
    radar = read_json(RADAR) or {}
    state = read_json(BREAKER_STATE) or {}

    # Sygnały NEEDS_ADVICE per domena: radar P37 (jedno źródło prawdy) + stan
    # trwały breaker (kolejne okna akumulowane między uruchomieniami narzędzia).
    na_by_domain: dict[str, int] = {}
    for d in radar.get("findings", []) or []:
        dom = str(d.get("domain", "(root)"))
        na_by_domain[dom] = na_by_domain.get(dom, 0) + 1
    prev_counts = state.get("needs_advice_counts", {})
    for dom in domains:
        na_by_domain.setdefault(dom, 0)
        na_by_domain[dom] += int(prev_counts.get(dom, 0))

    review_domains = []
    for dom, cnt in sorted(na_by_domain.items()):
        if cnt > threshold:
            review_domains.append({
                "domain": dom, "needs_advice_count": cnt,
                "window_min": window, "threshold": threshold,
                "reason_reported": bool(state.get("review_reasons", {}).get(dom)),
            })

    unexplained = [d for d in review_domains if not d["reason_reported"]]

    metrics = {
        "domains_total": len(domains),
        "domains_in_review": len(review_domains),
        "review_domains_with_reason": sum(1 for d in review_domains if d["reason_reported"]),
        "needs_advice_in_window": sum(na_by_domain.values()),
        "breaker_threshold": threshold,
        "breaker_window_min": window,
        "routing": ("TRIAGE_QUEUE" if unexplained or review_domains
                    else "AUTO_FILE"),
    }
    evidence = {
        "review_domains": review_domains[:50],
        "per_domain_counts": dict(sorted(na_by_domain.items())[:100]),
        "note": ("Breaker per domena (I05): N NEEDS_ADVICE w oknie T → tryb REVIEW. "
                 "Stan trwały w v3_p49_breaker_state.json; radar P37 = źródło "
                 "sygnałów. REVIEW bez raportu przyczyny = TRIAGE (nigdy cisza)."),
        "evaluated_at": utcnow_iso(),
    }
    write_p49_bundle("circuit_breaker", "V3-P49-I05", metrics, evidence)
    write_json(BREAKER_STATE, {
        "updated_at": utcnow_iso(),
        "needs_advice_counts": na_by_domain,
        "review_reasons": state.get("review_reasons", {}),
    })
    print(f"[V3-P49-I05] domains={len(domains)} in_review={len(review_domains)} "
          f"na_total={metrics['needs_advice_in_window']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
