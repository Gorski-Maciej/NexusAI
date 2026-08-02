#!/usr/bin/env python3
"""
NexusAI JDG — ISAP Legal Drift Alarm (Innowacja 14)
Monitoruje zmiany prawne przez porównanie podstaw prawnych w regułach
ze stanem faktycznym aktów. Wykrywa reguły, które mogą wymagać aktualizacji.

Usage: python isap_drift_alarm.py [--json] [--check-days N]
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime, timedelta


JDG_ROOT = Path(__file__).resolve().parent.parent
RULES_DIR = JDG_ROOT / "rules"


# Znane zmiany prawne wpływające na reguły (do automatycznej walidacji)
KNOWN_LEGAL_CHANGES = [
    {
        "date": "2025-07-01",
        "description": "SLIM VAT 3 — ulga złe długi: 150→90 dni",
        "affected_patterns": [r"bad_debt.*150", r"P189", r"150\s*dni"],
        "fix_applied": True,  # temporal.rego contains fix
    },
    {
        "date": "2026-02-01",
        "description": "KSeF obowiązkowy dla wszystkich podatników VAT czynnych",
        "affected_patterns": [r"ksef", r"e-faktur", r"faktur.*ustrukturyzowan"],
        "fix_applied": True,
    },
    {
        "date": "2026-01-01",
        "description": "Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS",
        "affected_patterns": [r"200000", r"200\s*000", r"zwolnienie.*podmiotowe"],
        "fix_applied": False,  # wartości mogą być nieaktualne
    },
]


def extract_legal_dates_from_rules() -> list[dict]:
    """Ekstrahuje daty z podstaw prawnych w regułach."""
    findings = []
    
    for fp in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = fp.read_text(encoding="utf-8")
        except: continue
        
        rel = str(fp.relative_to(RULES_DIR))
        
        # Szukaj dat w legal_basis i komentarzach
        dates = re.findall(r'(?:Dz\.U\.\s*)?(20\d{2})[^\d]', content)
        years = set(int(d) for d in dates if 2000 <= int(d) <= 2030)
        
        # Szukaj konkretnych artykułów które się zmieniły
        for change in KNOWN_LEGAL_CHANGES:
            for pattern in change["affected_patterns"]:
                if re.search(pattern, content, re.IGNORECASE):
                    findings.append({
                        "file": rel,
                        "change": change["description"],
                        "change_date": change["date"],
                        "fix_applied": change["fix_applied"],
                        "matched_pattern": pattern,
                    })
                    break
    
    return findings


def check_temporal_validity() -> list[dict]:
    """Sprawdza temporalność reguł (ADR-003)."""
    issues = []
    
    # Szukaj temporal.rego
    temporal_path = RULES_DIR / "temporal.rego"
    if temporal_path.exists():
        try:
            content = temporal_path.read_text(encoding="utf-8")
            temporal_entries = re.findall(r'"([^"]+)"\s*:\s*\{[^}]*"valid_from"\s*:\s*"([^"]*)"', content)
            
            for rule_id, valid_from in temporal_entries:
                try:
                    vf_date = datetime.strptime(valid_from, "%Y-%m-%d")
                    if vf_date > datetime.now():
                        issues.append({
                            "rule_id": rule_id,
                            "issue": f"Future valid_from: {valid_from}",
                            "severity": "INFO",
                        })
                except:
                    pass
        except:
            pass
    
    # Sprawdź daty w regułach vs dzisiejsza data
    now = datetime.now()
    for fp in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = fp.read_text(encoding="utf-8")
        except: continue
        
        # Szukaj zahardkodowanych dat w przeszłości
        dates = re.findall(r'"(20\d{2}-\d{2}-\d{2})"', content)
        for date_str in dates:
            try:
                d = datetime.strptime(date_str, "%Y-%m-%d")
                if d < now - timedelta(days=365 * 2):
                    rel = str(fp.relative_to(RULES_DIR))
                    issues.append({
                        "file": rel,
                        "issue": f"Potencjalnie nieaktualna data: {date_str} ({int((now - d).days / 365)} lat temu)",
                        "severity": "WARNING",
                    })
            except:
                pass
    
    return issues


def generate_alarm_report(findings, temporal_issues) -> str:
    """Generuje raport alarmu dryfu prawnego."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    lines = [
        "# 🚨 ISAP Legal Drift Alarm — NexusAI JDG v8.0",
        "",
        f"> **Wygenerowano:** {now} | **Innowacja 14**",
        f"> **Znanych zmian prawnych:** {len(KNOWN_LEGAL_CHANGES)}",
        f"> **Reguł dotkniętych zmianami:** {len(findings)}",
        f"> **Problemów temporalnych:** {len(temporal_issues)}",
        "",
        "## Znane zmiany prawne wpływające na reguły",
        "",
        "| Data | Opis | Fix wdrożony? |",
        "|------|------|:------------:|",
    ]
    
    for c in KNOWN_LEGAL_CHANGES:
        fix = "✅" if c["fix_applied"] else "❌"
        lines.append(f"| {c['date']} | {c['description']} | {fix} |")
    
    if findings:
        lines.extend([
            "",
            "## Reguły dotknięte zmianami prawnymi",
            "",
            "| Plik | Zmiana | Data zmiany | Fix? |",
            "|------|--------|:-----------:|:----:|",
        ])
        for f in findings[:30]:
            fix = "✅" if f["fix_applied"] else "⚠️"
            lines.append(f"| `{f['file'][:50]}` | {f['change'][:60]} | {f['change_date']} | {fix} |")
    
    if temporal_issues:
        lines.extend([
            "",
            "## Problemy temporalne",
            "",
            "| Lokalizacja | Problem | Severity |",
            "|-------------|---------|:--------:|",
        ])
        for ti in temporal_issues[:30]:
            loc = ti.get("rule_id", ti.get("file", "—"))
            lines.append(f"| `{loc[:50]}` | {ti['issue'][:80]} | {ti['severity']} |")
    
    lines.extend([
        "",
        "---",
        f"*Wygenerowano — {now}*",
        "*Innowacja 14 — `python JDG/tools/isap_drift_alarm.py`*",
    ])
    return "\n".join(lines)


def main():
    print("🚨 ISAP Legal Drift Alarm (Innowacja 14)")
    
    findings = extract_legal_dates_from_rules()
    temporal_issues = check_temporal_validity()
    
    print(f"   Znanych zmian: {len(KNOWN_LEGAL_CHANGES)}")
    print(f"   Reguł dotkniętych: {len(findings)}")
    print(f"   Problemów temporalnych: {len(temporal_issues)}")
    
    unfixed = [f for f in findings if not f["fix_applied"]]
    if unfixed:
        print(f"   ⚠️  Nienaprawionych: {len(unfixed)}")
    
    report = generate_alarm_report(findings, temporal_issues)
    output = JDG_ROOT / "reports" / "isap_drift_alarm.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(report, encoding="utf-8")
    print(f"✅ Raport: {output} ({len(report)} bajtów)")
    
    if "--json" in sys.argv:
        print(json.dumps({
            "timestamp": datetime.now().isoformat(),
            "known_changes": len(KNOWN_LEGAL_CHANGES),
            "affected_rules": len(findings),
            "temporal_issues": len(temporal_issues),
            "unfixed_count": len(unfixed),
        }, indent=2, ensure_ascii=False))
    
    return 1 if unfixed else 0


if __name__ == "__main__":
    sys.exit(main())
