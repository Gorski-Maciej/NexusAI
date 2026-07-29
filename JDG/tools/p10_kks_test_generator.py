#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — P10 INN09: KKS Atom Rule Test Auto-Generator
═══════════════════════════════════════════════════════════════════════════════

Auto-generuje testy dla każdej reguły atomowej KKS (474 reguł × 4 typy = 1896 testów):
  - Test pozytywny: input spełnia warunki → matched=true
  - Test negatywny: input nie spełnia → matched=false
  - Test brzegowy: input na granicy warunku
  - Test interakcji: interakcja z inną regułą

Użycie:
    python JDG/tools/p10_kks_test_generator.py --scan
    python JDG/tools/p10_kks_test_generator.py --generate --article 54
    python JDG/tools/p10_kks_test_generator.py --coverage-report

Autor: NexusAI
Data: 2026-07-29
"""

import re, json, sys
from pathlib import Path
from datetime import date

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
MICRO_KKS_PATH = PROJECT_ROOT / "JDG" / "rules" / "micro" / "kks" / "kks.rego"
PLAN33_PATH = PROJECT_ROOT / "JDG" / "rules" / "micro" / "plan33_kks.rego"

# ═══ Atom rule pattern: 12+8 per article ═══
ATOM_PATTERN = {
    "r1": "eligibility", "r2": "positive_1", "r3": "positive_2", "r4": "positive_3",
    "r5": "negative_1", "r6": "negative_2", "r7": "exception_1", "r8": "exception_2",
    "r9": "interaction_1", "r10": "interaction_2", "r11": "deadline", "r12": "sanction",
    "r13": "edge_case_1", "r14": "edge_case_2", "r15": "edge_case_3", "r16": "edge_case_4",
    "r17": "edge_case_5", "r18": "edge_case_6", "r19": "edge_case_7", "r20": "edge_case_8",
}

# ═══ KKS articles covered in micro-layer ═══
KKS_ARTICLES = [16, 20, 21] + list(range(54, 88))

# ═══ Test template ═══
TEST_TEMPLATE = '''# Auto-generated: P10 KKS Atom Rule Test — {rule_id} ({rule_type})
# Generated: {date}
# Article: Art. {article} KKS — {description}
# NOTE: This is a test STUB — requires OPA Rego execution environment to run.
# Run with: opa eval -i input.json -d JDG/rules/micro/kks/kks.rego "data.jdg.micro.kks"

def test_{test_name}():
    """{test_desc} — STUB (requires OPA runtime)"""
    input_data = {input_json}
    expected = {expected}
    # TODO: Implement OPA subprocess call to evaluate rule {rule_id}
    # result = opa_eval(input_data, "{rule_id}")
    # assert result["matched"] == expected, f"Expected matched={{expected}}"
    pass  # STUB — implement with opa eval subprocess
'''


class KKSAtomRuleScanner:
    """Scans micro/kks/kks.rego for atom rules and generates test coverage."""

    def scan_rules(self):
        if not MICRO_KKS_PATH.exists():
            return {"error": f"Micro file not found: {MICRO_KKS_PATH}"}

        content = MICRO_KKS_PATH.read_text()
        rules_found = []

        for art in KKS_ARTICLES:
            pattern = rf'rule_id.*jdg\.micro\.kks\.a{art}\.(r\d+)'
            matches = list(re.finditer(pattern, content))
            for m in matches:
                rule_num = m.group(1)
                rule_type = ATOM_PATTERN.get(rule_num, "unknown")
                rules_found.append({
                    "article": art,
                    "rule": rule_num,
                    "type": rule_type,
                    "rule_id": f"jdg.micro.kks.a{art}.{rule_num}",
                })

        # Coverage analysis
        coverage = {}
        for r in rules_found:
            art = r["article"]
            if art not in coverage:
                coverage[art] = {"found": 0, "rules": [], "expected_pattern": list(range(1, 21))}
            coverage[art]["found"] += 1
            coverage[art]["rules"].append(r["rule"])

        missing_rules = []
        for art, data in coverage.items():
            expected_max = 30 if art in (54, 56, 62) else 24 if art in (16, 57, 77, 80) else 20
            expected = [f"r{i}" for i in range(1, expected_max + 1)]
            missing = [r for r in expected if r not in data["rules"]]
            if missing:
                missing_rules.append({"article": art, "missing": missing, "count": len(missing)})

        plan33_count = 0
        if PLAN33_PATH.exists():
            plan33_content = PLAN33_PATH.read_text()
            plan33_count = len(re.findall(r'"rule_id":"jdg\.micro\.kks\.a\d+\.r\d+"', plan33_content))

        return {
            "total_atom_rules_found": len(rules_found),
            "articles_covered": len(coverage),
            "coverage": coverage,
            "missing_rules": missing_rules,
            "total_missing": sum(m["count"] for m in missing_rules),
            "plan33_supplementary": plan33_count,
            "test_coverage_0pct": f"{len(rules_found)} rules × 4 test types = {len(rules_found) * 4} potential tests",
        }

    def generate_tests(self, article_num):
        """Generate 4 test stubs per rule for a given article."""
        if not MICRO_KKS_PATH.exists():
            return {"error": "Micro file not found"}

        content = MICRO_KKS_PATH.read_text()
        pattern = rf'"rule_id":"jdg\.micro\.kks\.a{article_num}\.(r\d+)"'
        rule_ids = list(set(re.findall(pattern, content)))

        tests = []
        for rn in rule_ids:
            rule_id = f"jdg.micro.kks.a{article_num}.{rn}"
            rule_type = ATOM_PATTERN.get(rn, "unknown")
            article_desc = {54: "Uchylanie od podatku", 56: "Nierzetelne PKPiR", 57: "Ewidencja VAT",
                           62: "Puste faktury", 77: "Deklaracje", 16: "Czynny żal"}.get(article_num, "KKS")

            # 4 test templates per rule
            test_types = [
                {"suffix": "positive", "desc": "Test pozytywny", "matched": True, "input": {"kks_flag": True}},
                {"suffix": "negative", "desc": "Test negatywny", "matched": False, "input": {"kks_flag": False}},
                {"suffix": "boundary", "desc": "Test brzegowy", "matched": True, "input": {"kks_flag": True, "amount": 933200}},
                {"suffix": "interaction", "desc": "Test interakcji", "matched": True, "input": {"kks_flag": True, "has_vat": True}},
            ]

            for tt in test_types:
                test_name = f"kks_a{article_num}_{rn}_{tt['suffix']}"
                test_code = TEST_TEMPLATE.format(
                    rule_id=rule_id, rule_type=rule_type,
                    test_name=test_name, test_desc=tt["desc"],
                    input_json=json.dumps(tt["input"]), expected=str(tt["matched"]),
                    article=article_num, description=article_desc,
                    date=date.today().isoformat()
                )
                tests.append({"test_name": test_name, "rule_id": rule_id, "code": test_code.strip()})

        return {
            "article": article_num,
            "rules_found": len(rule_ids),
            "rule_ids": rule_ids,
            "tests_generated": len(tests),
            "test_code": "\n\n".join(t["code"] for t in tests),
            "coverage_pct": f"{len(tests) / (len(rule_ids) * 4) * 100:.0f}%" if rule_ids else "N/A",
        }

    def coverage_report(self):
        scan = self.scan_rules()
        total_rules = scan["total_atom_rules_found"]
        total_tests = total_rules * 4

        report = f"""P10 KKS ATOM RULE TEST COVERAGE REPORT
═══════════════════════════════════════════════════════
Generated: {date.today().isoformat()}
Micro rules scanned: {total_rules}
Potential auto-tests: {total_tests} (4 per rule)
Articles covered: {scan['articles_covered']}
Plan33 supplementary: {scan['plan33_supplementary']}

Coverage per article (TOP 10):
"""
        for art in sorted(scan["coverage"].keys())[:10]:
            data = scan["coverage"][art]
            expected = 30 if art in (54, 56, 62) else 24 if art in (16, 57, 77, 80) else 20
            report += f"  Art. {art}: {data['found']}/{expected} rules ({data['found']/expected*100:.0f}%) — {data['found']*4} potential tests\n"

        if scan["missing_rules"]:
            report += f"\n⚠️  MISSING RULES: {scan['total_missing']} across {len(scan['missing_rules'])} articles\n"
            for m in scan["missing_rules"][:5]:
                report += f"  Art. {m['article']}: missing {m['count']} rules: {', '.join(m['missing'][:5])}\n"

        report += f"""
Test Implementation Status:
  Generated: 0/{total_tests} (0%)
  To implement: {total_tests} test functions
  Estimated effort: ~{total_tests * 2} lines of Python test code
  Recommendation: Generate incrementally — start with Art. 54/56/62 (highest coverage)
"""
        return report


def main():
    import argparse
    parser = argparse.ArgumentParser(description="P10 KKS Atom Rule Test Auto-Generator")
    parser.add_argument("--scan", action="store_true", help="Scan all micro rules")
    parser.add_argument("--generate", action="store_true", help="Generate test stubs")
    parser.add_argument("--article", type=int, default=54, help="Article number (default: 54)")
    parser.add_argument("--coverage-report", action="store_true", help="Full coverage report")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    scanner = KKSAtomRuleScanner()

    if args.scan:
        r = scanner.scan_rules()
        if args.json:
            print(json.dumps(r, indent=2, ensure_ascii=False))
        else:
            print(f"\n  🔍 KKS ATOM SCAN: {r['total_atom_rules_found']} rules in {r['articles_covered']} articles")
            print(f"     Missing rules: {r['total_missing']} | Plan33: {r['plan33_supplementary']}")
            print(f"     Potential auto-tests: {r['total_atom_rules_found'] * 4}")

    if args.generate:
        r = scanner.generate_tests(args.article)
        if args.json:
            print(json.dumps(r, indent=2, ensure_ascii=False))
        else:
            print(f"\n  📝 GENERATED TESTS: Art. {r['article']} — {r['rules_found']} rules → {r['tests_generated']} tests")
            print(r["test_code"][:2000])

    if args.coverage_report:
        print(scanner.coverage_report())


if __name__ == "__main__":
    main()
