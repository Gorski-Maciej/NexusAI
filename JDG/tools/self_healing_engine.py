#!/usr/bin/env python3
"""
NexusAI JDG — Self-Healing Rule Engine (Innovation #1, P28 Grand Finale)
Po wykryciu błędu (validate_rules, dead_rule_detector) automatycznie proponuje naprawę.
Integracja z convert_true_to_conditions.py + fix_hyper_legal_basis.py.
Człowiek zatwierdza (4-Eyes).
"""
import sys, os, json, re, subprocess
from datetime import datetime
from pathlib import Path

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULES_DIR = os.path.join(BASE, "rules")

def run_tool(tool_name, *args):
    """Uruchom narzędzie JDG i zbierz output."""
    tool_path = os.path.join(BASE, "tools", f"{tool_name}.py")
    cmd = [sys.executable, tool_path] + list(args)
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout, result.stderr, result.returncode

def detect_dead_rules():
    """Faza 1: Wykryj martwe reguły."""
    stdout, stderr, code = run_tool("dead_rule_detector")
    dead_rules = []
    for line in stdout.split("\n"):
        if "DEAD" in line or "dead" in line.lower():
            dead_rules.append(line.strip())
    return dead_rules

def detect_tautologies():
    """Faza 1b: Wykryj tautologie."""
    stdout, stderr, code = run_tool("tautology_guard")
    tautologies = []
    for line in stdout.split("\n"):
        if "TAUTOLOGY" in line or "{ true }" in line:
            tautologies.append(line.strip())
    return tautologies

def propose_fix(issue):
    """Faza 2: Zaproponuj naprawę."""
    fixes = []
    
    if "dead" in issue.lower() or "DEAD" in issue:
        fixes.append({
            "action": "activate_or_deprecate",
            "tool": "convert_true_to_conditions.py --dry-run",
            "description": "Konwersja {true} -> realne warunki lub dodanie valid_to jeśli reguła archiwalna"
        })
    
    if "tautology" in issue.lower() or "true" in issue:
        fixes.append({
            "action": "convert_to_conditions",
            "tool": "convert_true_to_conditions.py",
            "description": "Zamiana { true } na rzeczywiste warunki na podstawie metadanych reguły"
        })
    
    if "hardcoded" in issue.lower():
        fixes.append({
            "action": "migrate_to_thresholds",
            "tool": None,
            "description": "Przeniesienie wartości do thresholds_jdg.rego + referencja data.thresholds.jdg.*"
        })
    
    return fixes

def generate_healing_report(issues, fixes):
    """Faza 3: Wygeneruj raport naprawczy."""
    report = {
        "generated_at": datetime.now().isoformat(),
        "engine_version": "1.0.0",
        "total_issues": len(issues),
        "issues": [],
        "auto_fixable": 0,
        "requires_human": 0
    }
    
    for i, issue in enumerate(issues):
        proposed = propose_fix(issue)
        entry = {
            "id": f"SELF_HEAL_{i+1:04d}",
            "issue": issue[:200],
            "proposed_fixes": proposed,
            "auto_approval_confidence": 0.0 if "hardcoded" in issue.lower() else 0.75
        }
        if all("hardcoded" not in f["description"].lower() for f in proposed):
            report["auto_fixable"] += 1
        else:
            report["requires_human"] += 1
        report["issues"].append(entry)
    
    return report

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Self-Healing Rule Engine v1.0               ║")
    print("║  Innovation #1: Auto-detect → Propose Fix → Human Approve ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    # Faza 1: Detekcja
    print("\n[Faza 1] Skanowanie reguł...")
    dead = detect_dead_rules()
    taut = detect_tautologies()
    all_issues = dead + taut
    
    if not all_issues:
        print("✅ Brak wykrytych problemów — system zdrowy!")
        return 0
    
    print(f"⚠️  Wykryto {len(all_issues)} potencjalnych problemów:")
    print(f"   - Martwe reguły: {len(dead)}")
    print(f"   - Tautologie: {len(taut)}")
    
    # Faza 2: Propozycje napraw
    print("\n[Faza 2] Generowanie propozycji napraw...")
    report = generate_healing_report(all_issues, [])
    
    print(f"   - Automatycznie naprawialne: {report['auto_fixable']}")
    print(f"   - Wymagające decyzji człowieka (4-Eyes): {report['requires_human']}")
    
    # Faza 3: Raport
    report_path = os.path.join(BASE, "reports", "self_healing_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n[Faza 3] Raport zapisany: {report_path}")
    print(f"\n📋 KPI: {report['auto_fixable']}/{report['total_issues']} problemów ma proponowaną naprawę")
    print("   Cel P28: ≥90% wykrytych błędów ma proponowaną naprawę")
    
    return 0 if report["requires_human"] == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
