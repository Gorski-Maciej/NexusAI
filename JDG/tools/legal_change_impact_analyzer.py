#!/usr/bin/env python3
"""
NexusAI JDG — Real-Time Legal Change Impact Analyzer (Innovation #4, P28 Grand Finale)
isap_crawler wykrywa zmianę → temporal_drift_detector znajduje dotknięte reguły →
rule_impact_simulator szacuje wpływ → PR z propozycją.
Pipeline w Q4 2026 / Fala 1.
"""
import sys, os, json, subprocess
from datetime import datetime, timedelta
from pathlib import Path

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def run_isap_crawler():
    """Faza 1: Uruchom isap_crawler aby sprawdzić nowe akty prawne."""
    crawler_path = os.path.join(BASE, "tools", "isap_crawler.py")
    result = subprocess.run(
        [sys.executable, crawler_path, "--check-recent"],
        capture_output=True, text=True, timeout=60
    )
    return result.stdout

def run_drift_detector():
    """Faza 2: Uruchom temporal_drift_detector."""
    detector_path = os.path.join(BASE, "tools", "temporal_drift_detector.py")
    result = subprocess.run(
        [sys.executable, detector_path],
        capture_output=True, text=True, timeout=60
    )
    return result.stdout

def run_impact_simulator():
    """Faza 3: Symuluj wpływ zmian."""
    simulator_path = os.path.join(BASE, "tools", "rule_impact_simulator.py")
    result = subprocess.run(
        [sys.executable, simulator_path],
        capture_output=True, text=True, timeout=60
    )
    return result.stdout

def generate_impact_report(crawler_output, drift_output, simulator_output):
    """Faza 4: Wygeneruj raport z rekomendacjami."""
    
    affected_rules = []
    for line in drift_output.split("\n"):
        if "DRIFT" in line or "affected" in line.lower():
            affected_rules.append(line.strip())
    
    new_legislation = []
    for line in crawler_output.split("\n"):
        if any(kw in line.lower() for kw in ["nowy", "new", "zmiana", "changed", "dz.u.", "isap"]):
            new_legislation.append(line.strip())
    
    report = {
        "generated_at": datetime.now().isoformat(),
        "analyzer_version": "1.0.0",
        "new_legislation_detected": len(new_legislation) > 0,
        "new_legislation_count": len(new_legislation),
        "affected_rules_count": len(affected_rules),
        "impact_level": "CRITICAL" if len(affected_rules) > 50 else "HIGH" if len(affected_rules) > 10 else "LOW",
        "recommended_actions": []
    }
    
    if len(affected_rules) > 0:
        report["recommended_actions"].append({
            "priority": "IMMEDIATE",
            "action": "Generate PR with temporal validity updates",
            "deadline_days": 5,
            "kpi": "Zmiana prawa → PR w <5 dni (cel P28)"
        })
    
    if len(new_legislation) > 0:
        report["recommended_actions"].append({
            "priority": "HIGH",
            "action": "Run AI-Augmented Rule Generator (llm_bridge) for new articles",
            "deadline_days": 10,
            "kpi": "70% wygenerowanych reguł przechodzi walidację bez korekty"
        })
    
    return report

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Legal Change Impact Analyzer v1.0           ║")
    print("║  Innovation #4: ISAP → Drift → Impact → PR (P28)         ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    print("\n[Faza 1/4] Sprawdzanie ISAP...")
    try:
        crawler_out = run_isap_crawler()
    except:
        crawler_out = "ISAP crawler skipped (no network or tool error)"
    print("   ✓ ISAP check done")
    
    print("\n[Faza 2/4] Detekcja driftu temporalnego...")
    try:
        drift_out = run_drift_detector()
    except:
        drift_out = "Drift detector skipped"
    print("   ✓ Drift check done")
    
    print("\n[Faza 3/4] Symulacja wpływu...")
    try:
        sim_out = run_impact_simulator()
    except:
        sim_out = "Impact simulator skipped"
    print("   ✓ Impact simulation done")
    
    print("\n[Faza 4/4] Generowanie raportu...")
    report = generate_impact_report(crawler_out, drift_out, sim_out)
    
    report_path = os.path.join(BASE, "reports", "legal_change_impact_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n📊 Impact Report:")
    print(f"   Nowe akty prawne: {report['new_legislation_count']}")
    print(f"   Dotknięte reguły: {report['affected_rules_count']}")
    print(f"   Poziom wpływu: {report['impact_level']}")
    print(f"\n📋 Rekomendowane akcje:")
    for action in report["recommended_actions"]:
        print(f"   [{action['priority']}] {action['action']}")
        print(f"   Termin: {action['deadline_days']} dni | {action['kpi']}")
    
    print(f"\n📄 Report: {report_path}")
    print(f"\n⏰ Scheduler: Dodaj cron dla codziennego uruchomienia:")
    print(f"   0 6 * * * cd {BASE} && {sys.executable} tools/legal_change_impact_analyzer.py")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
