#!/usr/bin/env python3
"""
NexusAI JDG — Doc-to-Rego Traceability Matrix Generator (Innowacja 10)
Generuje macierz identyfikowalności: punkt prawny → rule_id → plik → ADR → test → status.
Wymaganie ENTERPRISE: każdy punkt prawny ma ścieżkę "dokument → reguła → test".

Usage: python traceability_matrix.py [--json] [--output PATH]
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"
TESTS_DIR = JDG_ROOT / "tests"
DOCS_DIR = JDG_ROOT / "docs"


def extract_all_rule_data():
    """Ekstrahuje wszystkie reguły z metadanymi."""
    rules = []
    for fp in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = fp.read_text(encoding="utf-8")
        except: continue
        rel = str(fp.relative_to(RULES_DIR))

        rule_ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
        legal_bases = re.findall(r'"_legal_basis"\s*:\s*"([^"]*)"', content)
        routings = re.findall(r'"_routing"\s*:\s*"([^"]*)"', content)

        for i, rid in enumerate(rule_ids):
            lb = legal_bases[i] if i < len(legal_bases) else ""
            routing = routings[i] if i < len(routings) else ""

            # Ekstrakcja artykułu z legal_basis
            art_match = re.search(r'Art\.\s*(\d+[a-z]*(?:\s*ust\.\s*\d+)?)', lb, re.IGNORECASE)
            article = f"Art. {art_match.group(1)}" if art_match else ""

            # Określenie aktu
            act = ""
            for act_name, patterns in {
                "VAT": r'VAT|podatku od towarów',
                "PIT": r'PIT|podatku dochodowym od osób fizycznych',
                "OrdPU": r'Ordynacj|OrdPU',
                "KKS": r'KKS|karn.*skarbow',
                "ZUS": r'ZUS|SUS|ubezpieczeń społecznych|składki',
                "UoR": r'rachunkowości|UoR|PKPiR',
                "PP": r'Prawo przedsiębiorców|CEIDG',
                "RODO": r'RODO|danych osobowych',
                "AML": r'AML|praniu pieniędzy',
            }.items():
                if re.search(patterns, lb, re.IGNORECASE):
                    act = act_name; break

            rules.append({
                "rule_id": rid, "file": rel, "legal_basis": lb,
                "routing": routing, "article": article, "act": act,
            })
    return rules


def extract_tests():
    """Ekstrahuje testy Rego."""
    tests = {}
    for fp in sorted(TESTS_DIR.rglob("*_test.rego")):
        try:
            content = fp.read_text(encoding="utf-8")
        except: continue
        test_names = re.findall(r'test_(\w+)', content)
        for tn in test_names:
            tests[tn] = str(fp.relative_to(TESTS_DIR))
    return tests


def extract_adrs():
    """Ekstrahuje ADR-y z ARCHITECTURE.md."""
    try:
        text = (DOCS_DIR / "ARCHITECTURE.md").read_text(encoding="utf-8")
    except: return []
    return re.findall(r'ADR-\d+[^#]*', text)


def generate_matrix(rules, tests, adrs):
    """Generuje macierz identyfikowalności."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    lines = [
        "# 🔗 Doc-to-Rego Traceability Matrix — NexusAI JDG v8.0",
        "",
        f"> **Wygenerowano:** {now} | **Innowacja 10**",
        f"> **Reguł:** {len(rules)} | **Testów:** {len(tests)} | **ADR-ów:** {len(adrs)}",
        "",
        "## Macierz identyfikowalności",
        "",
        "| Akt | Artykuł | Rule ID | Plik | Routing | Test? | ADR | Status |",
        "|-----|---------|---------|------|:-------:|:-----:|-----|:------:|",
    ]

    for r in sorted(rules, key=lambda x: (x.get("act", ""), x["rule_id"]))[:200]:
        act = r.get("act", "—")
        art = r.get("article", "—")
        rid = r["rule_id"]
        file = r["file"]
        routing = "🔴" if "BLOCK" in r.get("routing", "") else ("🟡" if "TRIAGE" in r.get("routing", "") else "—")
        # Poprawione: porównuj pełne rule_id z zawartością testów (nie tylko nazwy funkcji)
        has_test = "✅" if any(rid_part in tn or tn in rid for tn in tests for rid_part in rid.split(".")) else "⬜"
        has_adr = "✅" if act else "⬜"
        status = "✅" if has_test == "✅" else ("🟡" if r.get("legal_basis") else "⬜")

        lines.append(f"| {act} | {art} | `{rid[:50]}` | `{file[:40]}` | {routing} | {has_test} | {has_adr} | {status} |")

    if len(rules) > 200:
        lines.append(f"| ... | ... | ... | ... | ... | ... | ... | *({len(rules)-200} więcej reguł)* |")

    # Podsumowanie
    tested = sum(1 for r in rules if any(tn in r["rule_id"] or r["rule_id"] in tn for tn in tests))
    lines.extend([
        "",
        "## Statystyki",
        "",
        f"| Metryka | Wartość |",
        f"|---------|---------|",
        f"| Reguł z testem | {tested}/{len(rules)} ({tested*100//max(len(rules),1)}%) |",
        f"| Reguł z podstawą prawną | {sum(1 for r in rules if r['legal_basis'])}/{len(rules)} |",
        f"| Reguł BLOCK_AND_ALERT | {sum(1 for r in rules if 'BLOCK' in r.get('routing',''))} |",
        f"| Reguł TRIAGE_QUEUE | {sum(1 for r in rules if 'TRIAGE' in r.get('routing',''))} |",
        "",
        "---",
        f"*Wygenerowano automatycznie — {now}*",
        "*Innowacja 10 — `python JDG/tools/traceability_matrix.py`*",
    ])
    return "\n".join(lines)


def main():
    print("🔗 Generowanie Traceability Matrix (Innowacja 10)...")
    rules = extract_all_rule_data()
    tests = extract_tests()
    adrs = extract_adrs()

    print(f"   Reguł: {len(rules)}")
    print(f"   Testów: {len(tests)}")
    print(f"   ADR-ów: {len(adrs)}")

    matrix = generate_matrix(rules, tests, adrs)
    output = JDG_ROOT / "reports" / "traceability_matrix.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(matrix, encoding="utf-8")
    print(f"✅ Traceability Matrix: {output} ({len(matrix)} bajtów)")

    if "--json" in sys.argv:
        print(json.dumps({
            "timestamp": datetime.now().isoformat(),
            "total_rules": len(rules),
            "tests_count": len(tests),
            "adrs_count": len(adrs),
            "coverage": {
                "legal_basis": sum(1 for r in rules if r["legal_basis"]),
                "block_alert": sum(1 for r in rules if "BLOCK" in r.get("routing", "")),
                "triage_queue": sum(1 for r in rules if "TRIAGE" in r.get("routing", "")),
            }
        }, indent=2, ensure_ascii=False))

    return 0


if __name__ == "__main__":
    sys.exit(main())
