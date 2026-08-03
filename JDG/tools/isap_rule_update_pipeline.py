#!/usr/bin/env python3
"""
NexusAI JDG — ISAP RULE UPDATE PIPELINE (P01 Fundament OPA — Sekcja 6 Enterprise)
=================================================================================
Automatyzacja aktualizacji reguł wg zmian prawa (ISAP / Dziennik Ustaw):
  • ingest   — wczytaj zmianę prawa (JSON: akt, artykuł, data wejścia, nowa wartość)
  • impact   — oceń wpływ na reguły JDG (powiązanie akt→reguła przez legal_cartography)
  • plan     — wygeneruj plan migracji: nowe wersje reguł + okna ważności
  • emit     — zapisz rule_registry.json (hot-reload) + changelog thresholdów

Zgodność: P01 Sekcja 6 (ISAP automation + CI/CD pipeline reguł), A2 temporal,
          ADR-002 (progi z thresholds), legal_cartography z _metadata_jdg.rego.

Usage:
  python isap_rule_update_pipeline.py ingest --act "Ustawa o PIT" --article "Art. 27" \
      --effective 2027-01-01 --threshold pit.scale_threshold --value 150000
  python isap_rule_update_pipeline.py impact --threshold pit.scale_threshold
  python isap_rule_update_pipeline.py plan --threshold pit.scale_threshold
  python isap_rule_update_pipeline.py emit
"""

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
CHANGELOG_PATH = BASE / "bundles" / "threshold_changelog.json"
REGISTRY_PATH = BASE / "bundles" / "rule_registry.json"
IMPACT_PATH = BASE / "bundles" / "impact_analysis.json"

# Przykładowa mapa powiązań akt → reguły (źródło: legal_cartography z _metadata_jdg.rego)
LEGAL_TO_RULES = {
    "Art. 27 PIT": ["jdg.pit.forms.scale", "jdg.pit.scale_threshold_120k", "jdg.temporal.historical_pit_rate_2025"],
    "Art. 89a VAT": ["jdg.vat.a89a.r1", "jdg.edge_cases.sanction_bad_debt_debtor_30pct"],
    "Art. 113 VAT": ["jdg.vat.a113.r1", "jdg.edge_cases.vat_breach_mid_year"],
    "Art. 26e PIT": ["jdg.allowances.relief_rd_standard", "jdg.allowances.relief_rd_centrum"],
    "Art. 30ca PIT": ["jdg.allowances.relief_ip_box", "jdg.conflicts.ip_box_vs_rd_same_income"],
    "Art. 18c SUS": ["jdg.zus.maly_plus", "jdg.sus.a18c.r1"],
    "Art. 36a SUS": ["jdg.business.suspension_zus", "jdg.edge_cases.zus_declaration_zero_on_suspension"],
    "Art. 106na VAT": ["jdg.validation.ksef_upo_required", "jdg.temporal.ksef_delayed_2026"],
    "Art. 70 OP": ["jdg.temporal.statute_limitations_5yr", "jdg.liability.statute_5_years"],
}


def load_json(path: Path, default):
    if path.exists():
        try:
            return json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return default
    return default


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def _matches_act(act_key: str, act: str, article: str) -> bool:
    """Dopasowanie wpisu zmiany prawa do klucza LEGAL_TO_RULES.

    Klucz ma postać 'Art. 27 PIT' / 'Art. 89a VAT' / 'Art. 18c SUS' / 'Art. 70 OP'.
    Dopasowujemy, gdy:
      • artykuł z klucza (np. 'Art. 27') występuje w article LUB
      • skrót ustawy z klucza (np. 'PIT', 'VAT') występuje w act (case-insensitive).
    """
    key_lower = act_key.lower()
    act_lower = (act or "").lower()
    article_lower = (article or "").lower()
    # artykuł: pierwsze 2 słowa klucza (np. 'Art. 27')
    words = act_key.split()
    article_part = " ".join(words[:2]).lower() if len(words) >= 2 else key_lower
    # Precyzyjne dopasowanie: artykuł ma priorytet — gdy artykuł jest podany,
    # nie rozszerzamy wpływu na inne artykuły tej samej ustawy (impact analysis).
    if article_lower:
        return bool(article_part) and article_part in article_lower
    # Fallback (tylko gdy artykuł NIE jest podany): skrót ustawy z klucza
    # (np. 'PIT', 'VAT', 'SUS', 'OP') w nazwie aktu — dopasowanie granicą słowa
    # (re.search z \\b), by skróty 2-literowe jak 'OP' nie łapały fałszywych
    # trafień w środku wyrazów (np. „podatku" zawiera „op").
    act_abbr = re.escape(words[-1].lower()) if words else ""
    return bool(act_abbr) and re.search(rf"\b{act_abbr}\b", act_lower) is not None


def _affected_rules_for(entries: list) -> set:
    """Zbiór reguł powiązanych z listą zmian prawa (przez mapę akt→reguły)."""
    rules = set()
    for e in entries:
        for act_key, rule_list in LEGAL_TO_RULES.items():
            if _matches_act(act_key, e.get("act", ""), e.get("article", "")):
                rules.update(rule_list)
    return rules


def cmd_ingest(args) -> None:
    changelog = load_json(CHANGELOG_PATH, {})
    entry = {
        "act": args.act,
        "article": args.article,
        "effective_from": args.effective,
        "threshold": args.threshold,
        "value": args.value,
        "ingested_at": date.today().isoformat(),
    }
    changelog.setdefault(args.threshold, []).append(entry)
    save_json(CHANGELOG_PATH, changelog)
    print(f"✅ Zapisano zmianę prawa dla {args.threshold}: {args.value} od {args.effective}")
    print(f"   Plik: {CHANGELOG_PATH} (host wstrzykuje jako data.jdg.threshold_changelog)")


def cmd_impact(args) -> None:
    changelog = load_json(CHANGELOG_PATH, {})
    entries = changelog.get(args.threshold, [])
    if not entries:
        sys.exit(f"ℹ️  Brak zmian dla {args.threshold}")
    rules = _affected_rules_for(entries)
    impact = {
        "threshold": args.threshold,
        "changes": entries,
        "affected_rules": sorted(rules),
        "affected_count": len(rules),
        "note": "Zaktualizuj reguły powiązane + okna ważności (valid_from = data wejścia w życie)",
    }
    save_json(IMPACT_PATH, impact)
    print(json.dumps(impact, indent=2, ensure_ascii=False))


def cmd_plan(args) -> None:
    changelog = load_json(CHANGELOG_PATH, {})
    entries = changelog.get(args.threshold, [])
    if not entries:
        sys.exit(f"ℹ️  Brak zmian dla {args.threshold}")
    registry = load_json(REGISTRY_PATH, {})
    plan = []
    for e in entries:
        # Dla każdej reguły powiązanej — nowa wersja CANDIDATE z oknem ważności
        rules = set()
        for act_key, rule_list in LEGAL_TO_RULES.items():
            if _matches_act(act_key, e.get("act", ""), e.get("article", "")):
                rules.update(rule_list)
        for rule_id in rules:
            versions = registry.setdefault(rule_id, {"versions": []})["versions"]
            prev_ver = versions[-1].get("version") if versions else "1.0.0"
            # Inkrementacja minor (1.0.0 → 1.1.0) z bezpiecznym fallbackiem
            try:
                major = int(prev_ver.split(".")[0])
                minor = int(prev_ver.split(".")[1]) if "." in prev_ver else 0
                next_ver = f"{major}.{minor + 1}.0"
            except (ValueError, IndexError):
                next_ver = f"{prev_ver}.1"
            versions.append({
                "version": next_ver,
                "valid_from": e["effective_from"],
                "valid_to": None,
                "status": "CANDIDATE",
                "rollout_pct": 5,
                "error_rate": 0.0,
                "supersedes": prev_ver,
                "change_reason": f"{e['act']} {e['article']} → {e['threshold']} = {e['value']}",
            })
            plan.append({"rule": rule_id, "new_version": next_ver, "supersedes": prev_ver,
                         "effective_from": e["effective_from"]})
    save_json(REGISTRY_PATH, registry)
    print(f"✅ Plan migracji wygenerowany: {len(plan)} nowych wersji (CANDIDATE, rollout 5%)")
    print(json.dumps(plan, indent=2, ensure_ascii=False))
    print("   Następny krok: walidacja w sandbox → awans do ACTIVE (rule_lifecycle_manager.py promote)")


def cmd_emit(args) -> None:
    changelog = load_json(CHANGELOG_PATH, {})
    registry = load_json(REGISTRY_PATH, {})
    print(json.dumps({
        "changelog": changelog,
        "rule_registry": registry,
        "emit_note": "Host wstrzykuje: data.jdg.threshold_changelog + data.jdg.rule_registry (hot-reload)",
    }, indent=2, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description="ISAP Rule Update Pipeline — P01 Sekcja 6")
    sub = p.add_subparsers(dest="cmd", required=True)

    i = sub.add_parser("ingest")
    i.add_argument("--act", required=True)
    i.add_argument("--article", required=True)
    i.add_argument("--effective", required=True)
    i.add_argument("--threshold", required=True)
    i.add_argument("--value", required=True, type=float)
    i.set_defaults(fn=cmd_ingest)

    im = sub.add_parser("impact")
    im.add_argument("--threshold", required=True)
    im.set_defaults(fn=cmd_impact)

    pl = sub.add_parser("plan")
    pl.add_argument("--threshold", required=True)
    pl.set_defaults(fn=cmd_plan)

    e = sub.add_parser("emit")
    e.set_defaults(fn=cmd_emit)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
