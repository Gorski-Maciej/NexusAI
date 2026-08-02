#!/usr/bin/env python3
"""
NexusAI JDG — Chaos Engineering for OPA (Innovation #15 / P27 I10, P28 Grand Finale)
Testy mutacyjne: usunięcie reguły, puste thresholds, uszkodzony bundle,
brak metadata — system musi je wykryć.
"""
import sys, os, json, random, tempfile, shutil, subprocess
from datetime import datetime

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULES_DIR = os.path.join(BASE, "rules")

CHAOS_SCENARIOS = [
    {
        "name": "DELETE_RANDOM_RULE",
        "description": "Usuń losową regułę z bundle — system musi to wykryć",
        "detection_tool": "validate_rules.py"
    },
    {
        "name": "EMPTY_THRESHOLDS",
        "description": "Opróżnij thresholds_jdg.rego — system musi wykryć brak progów",
        "detection_tool": "validate_rules.py --strict"
    },
    {
        "name": "CORRUPT_BUNDLE",
        "description": "Uszkodź bundle OPA (zamień losowe bajty) — system musi fallbackować",
        "detection_tool": "opa check"
    },
    {
        "name": "MISSING_METADATA",
        "description": "Usuń _metadata_jdg.rego — system musi wykryć brak metadata",
        "detection_tool": "lint_rego_rules.py"
    },
    {
        "name": "FUTURE_TEMPORAL",
        "description": "Ustaw wszystkie valid_from na rok 2099 — system musi wykryć 0 aktywnych reguł",
        "detection_tool": "temporal_drift_detector.py"
    },
    {
        "name": "DUPLICATE_RULE_IDS",
        "description": "Zduplikuj losowe rule_id — system musi wykryć kolizje",
        "detection_tool": "validate_rules.py --strict"
    }
]

def run_chaos_scenario(scenario, rules_copy_dir):
    """Wykonaj jeden scenariusz chaosu."""
    
    result = {
        "scenario": scenario["name"],
        "description": scenario["description"],
        "timestamp": datetime.now().isoformat(),
        "chaos_applied": False,
        "detected": False,
        "error": None
    }
    
    try:
        if scenario["name"] == "DELETE_RANDOM_RULE":
            # Wybierz losowy plik i usuń z niego regułę
            rego_files = []
            for root, _, files in os.walk(rules_copy_dir):
                for f in files:
                    if f.endswith(".rego"):
                        rego_files.append(os.path.join(root, f))
            
            if rego_files:
                target = random.choice(rego_files)
                with open(target, "r") as fh:
                    content = fh.read()
                
                # Znajdź i usuń blok reguły
                content = content.replace("_routing\":", "_ROUTING_REMOVED\":", 1)
                with open(target, "w") as fh:
                    fh.write(content)
                result["chaos_applied"] = True
        
        elif scenario["name"] == "EMPTY_THRESHOLDS":
            thresholds_file = os.path.join(rules_copy_dir, "thresholds_jdg.rego")
            if os.path.exists(thresholds_file):
                # Zastąp wartości zerami
                with open(thresholds_file, "r") as fh:
                    content = fh.read()
                import re
                content = re.sub(r'\d+\.\d+', '0.0', content)
                content = re.sub(r'(?<!")\b\d{3,}\b(?!"|\.\d)', '0', content)
                with open(thresholds_file, "w") as fh:
                    fh.write(content)
                result["chaos_applied"] = True
        
        elif scenario["name"] == "CORRUPT_BUNDLE":
            rego_files = []
            for root, _, files in os.walk(rules_copy_dir):
                for f in files:
                    if f.endswith(".rego") and "_metadata" not in f:
                        rego_files.append(os.path.join(root, f))
            
            if rego_files:
                target = random.choice(rego_files)
                with open(target, "ab") as fh:
                    fh.write(b"\x00\xFF\x00\xFF")
                result["chaos_applied"] = True
        
        elif scenario["name"] == "MISSING_METADATA":
            meta_file = os.path.join(rules_copy_dir, "_metadata_jdg.rego")
            if os.path.exists(meta_file):
                os.rename(meta_file, meta_file + ".chaos_backup")
                result["chaos_applied"] = True
        
        elif scenario["name"] == "FUTURE_TEMPORAL":
            temporal_file = os.path.join(rules_copy_dir, "_metadata_jdg.rego")
            if os.path.exists(temporal_file):
                with open(temporal_file, "r") as fh:
                    content = fh.read()
                content = content.replace('"valid_from": "20', '"valid_from": "2099')
                content = content.replace('"valid_to": null', '"valid_to": "2100-12-31"')
                with open(temporal_file, "w") as fh:
                    fh.write(content)
                result["chaos_applied"] = True
        
        # Uruchom narzędzie detekcji
        tool_path = os.path.join(BASE, "tools", scenario["detection_tool"].split()[0] + ".py")
        if os.path.exists(tool_path):
            cmd = [sys.executable, tool_path] + scenario["detection_tool"].split()[1:]
            proc = subprocess.run(cmd, capture_output=True, text=True, timeout=30, cwd=BASE)
            result["detected"] = proc.returncode != 0
            result["output"] = (proc.stdout + proc.stderr)[:500]
        
    except Exception as e:
        result["error"] = str(e)
    
    return result

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Chaos Engineering v1.0                     ║")
    print("║  Mutation Testing for OPA Rules (P28 Grand Finale)       ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    # Stwórz kopię rules
    tmp_dir = tempfile.mkdtemp(prefix="jdg_chaos_")
    rules_copy = os.path.join(tmp_dir, "rules")
    shutil.copytree(RULES_DIR, rules_copy)
    
    results = []
    for scenario in CHAOS_SCENARIOS:
        print(f"\n[CHAOS] {scenario['name']}: {scenario['description']}")
        result = run_chaos_scenario(scenario, rules_copy)
        status = "✅ WYKRYTO" if result["detected"] else "❌ NIE WYKRYTO"
        print(f"   Status: {status}")
        if result["error"]:
            print(f"   Error: {result['error']}")
        results.append(result)
    
    # Posprzątaj
    shutil.rmtree(tmp_dir, ignore_errors=True)
    
    detected = sum(1 for r in results if r["detected"])
    total = len(results)
    
    print(f"\n📊 Chaos Engineering Results:")
    print(f"   Scenariusze: {total}")
    print(f"   Wykryte anomalie: {detected} ({detected/total*100:.0f}%)")
    print(f"   Niewykryte: {total - detected}")
    
    # KPI
    print(f"\n📋 KPI: System wykrył {detected}/{total} mutacji")
    print("   Cel P28: 100% mutacji wykrywanych przez CI")
    
    report_path = os.path.join(BASE, "reports", "chaos_engineering_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump({
            "generated_at": datetime.now().isoformat(),
            "total_scenarios": total,
            "detected": detected,
            "detection_rate": detected / max(total, 1) * 100,
            "results": results
        }, f, indent=2, ensure_ascii=False)
    
    print(f"\n📄 Report: {report_path}")
    return 0 if detected == total else 1

if __name__ == "__main__":
    sys.exit(main())
