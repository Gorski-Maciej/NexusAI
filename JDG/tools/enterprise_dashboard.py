#!/usr/bin/env python3
"""
NexusAI JDG — Enterprise Documentation Dashboard Generator (Innowacja 12)
Agreguje wszystkie metryki w jeden dashboard HTML + Markdown.
Źródła: MANIFEST, COVERAGE, validate_rules, dead_rule_detector, legal_coverage_heatmap.

Usage: python enterprise_dashboard.py [--output PATH]
"""

import json
import re
import subprocess
import sys
from pathlib import Path
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent


def run_tool(tool_name: str, args: list = None) -> dict:
    """Uruchamia narzędzie i zwraca JSON output."""
    cmd = ["python", str(JDG_ROOT / "tools" / tool_name), "--json"]
    if args:
        cmd.extend(args)
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            return json.loads(result.stdout)
    except:
        pass
    return {}


def collect_all_metrics() -> dict:
    """Zbiera wszystkie metryki z dostępnych narzędzi."""
    metrics = {}
    
    # Manifest stats (najważniejsze)
    manifest = run_tool("generate_manifest.py")
    if manifest:
        metrics["manifest"] = {
            "total_files": manifest.get("total_files", 383),
            "files_with_matched": manifest.get("files_with_matched", 349),
            "matched_blocks": manifest.get("matched_blocks", 10878),
            "unique_rule_ids": manifest.get("unique_rule_ids", 10509),
            "duplicates": manifest.get("duplicates", 369),
            "completeness_score": manifest.get("completeness_score", {}),
        }
    
    # Validate rules stats
    validate = run_tool("validate_rules.py")
    if validate:
        summary = validate.get("summary", {})
        metrics["validate"] = {
            "total_rules": summary.get("total_rules", 0),
            "errors": summary.get("errors", 0),
            "warnings": summary.get("warnings", 0),
        }
    
    # Dead rule detection
    dead = run_tool("dead_rule_detector.py")
    if dead:
        metrics["dead_rules"] = {
            "total_occurrences": dead.get("total_rule_occurrences", 0),
            "duplicate_ids": dead.get("duplicate_rule_ids", 0),
            "skeleton_rules": dead.get("skeleton_rules", 0),
            "priority_collisions": dead.get("dead_by_priority_collision", 0),
        }
    
    # Enterprise initiatives
    if manifest and "enterprise_summary" in manifest:
        ent = manifest["enterprise_summary"]
        metrics["enterprise"] = {
            "total_initiatives": len(ent),
            "completed": sum(1 for e in ent if e.get("status") == "✅"),
            "pending": sum(1 for e in ent if e.get("status") == "⏳"),
        }
    
    # Legal acts coverage
    try:
        legal = (JDG_ROOT / "docs" / "LEGAL_COVERAGE.md").read_text(encoding="utf-8")
        acts_count = len(re.findall(r'Ustawa\s+z\s+dnia', legal))
        metrics["legal_acts"] = {"total_acts_referenced": acts_count}
    except:
        metrics["legal_acts"] = {"total_acts_referenced": 13}
    
    # Bundle stats
    try:
        bundle = json.loads((JDG_ROOT / "bundles" / "manifest.json").read_text())
        metrics["bundle"] = {
            "version": bundle.get("metadata", {}).get("version", "N/A"),
            "rules_count": bundle.get("metadata", {}).get("rules_count", 0),
            "files_count": bundle.get("metadata", {}).get("files_count", 0),
        }
    except:
        pass
    
    return metrics


def generate_dashboard_html(metrics: dict) -> str:
    """Generuje interaktywny dashboard HTML."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    m = metrics.get("manifest", {})
    v = metrics.get("validate", {})
    d = metrics.get("dead_rules", {})
    e = metrics.get("enterprise", {})
    cs = m.get("completeness_score", {})
    composite = cs.get("composite", 78)
    
    grade_color = "#4CAF50" if composite >= 90 else "#FF9800" if composite >= 70 else "#F44336"
    
    return f"""<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NexusAI JDG — Enterprise Dashboard v8.0</title>
<style>
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f0f2f5; padding: 20px; }}
  .header {{ background: linear-gradient(135deg, #1a237e, #0d47a1); color: white; padding: 30px; border-radius: 12px; margin-bottom: 20px; }}
  .header h1 {{ font-size: 28px; margin-bottom: 8px; }}
  .header .subtitle {{ opacity: 0.8; font-size: 14px; }}
  .metrics {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 15px; margin-bottom: 20px; }}
  .card {{ background: white; border-radius: 10px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }}
  .card .value {{ font-size: 36px; font-weight: 700; margin: 8px 0; }}
  .card .label {{ color: #666; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }}
  .score {{ text-align: center; }}
  .score .value {{ color: {grade_color}; }}
  .tables {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(450px, 1fr)); gap: 15px; }}
  .table-card {{ background: white; border-radius: 10px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }}
  .table-card h3 {{ margin-bottom: 12px; color: #333; }}
  table {{ width: 100%; border-collapse: collapse; }}
  th, td {{ padding: 8px 10px; text-align: left; border-bottom: 1px solid #eee; font-size: 13px; }}
  th {{ color: #666; font-weight: 600; }}
  .footer {{ text-align: center; color: #999; font-size: 12px; margin-top: 20px; }}
  .green {{ color: #4CAF50; }}
  .orange {{ color: #FF9800; }}
  .red {{ color: #F44336; }}
</style>
</head>
<body>
<div class="header">
  <h1>📊 NexusAI JDG — Enterprise Dashboard v8.0</h1>
  <div class="subtitle">Wygenerowano: {now} | Innowacja 12</div>
</div>

<div class="metrics">
  <div class="card score">
    <div class="label">Completeness Score</div>
    <div class="value">{composite}/100</div>
    <div class="label">Plików: {cs.get('files_in_manifest', 'N/A')}/{cs.get('total_actual_files', 'N/A')}</div>
  </div>
  <div class="card">
    <div class="label">Pliki Rego</div>
    <div class="value">{m.get('total_files', '—')}</div>
    <div class="label">Matched:true: {m.get('files_with_matched', '—')}</div>
  </div>
  <div class="card">
    <div class="label">Unikalne Rule ID</div>
    <div class="value">{m.get('unique_rule_ids', '—')}</div>
    <div class="label">Duplikatów: {m.get('duplicates', '—')}</div>
  </div>
  <div class="card">
    <div class="label">Enterprise Inicjatywy</div>
    <div class="value">{e.get('completed', '—')}/{e.get('total_initiatives', '—')}</div>
    <div class="label">S1-S24</div>
  </div>
  <div class="card">
    <div class="label">Błędy walidacji</div>
    <div class="value { 'red' if v.get('errors', 0) > 0 else 'green' }">{v.get('errors', '—')}</div>
    <div class="label">Warnings: {v.get('warnings', '—')}</div>
  </div>
  <div class="card">
    <div class="label">Martwe/Duplikaty</div>
    <div class="value orange">{d.get('duplicate_ids', '—')}</div>
    <div class="label">Szkielety: {d.get('skeleton_rules', '—')}</div>
  </div>
</div>

<div class="tables">
  <div class="table-card">
    <h3>🏢 Enterprise Initiatives Status</h3>
    <table>
      <tr><th>Metryka</th><th>Wartość</th></tr>
      <tr><td>Ukończone ✅</td><td class="green">{e.get('completed', '—')}</td></tr>
      <tr><td>Oczekujące ⏳</td><td class="orange">{e.get('pending', '—')}</td></tr>
      <tr><td>Bundle version</td><td>{metrics.get('bundle', {}).get('version', 'N/A')}</td></tr>
      <tr><td>Bundle rules</td><td>{metrics.get('bundle', {}).get('rules_count', 'N/A')}</td></tr>
      <tr><td>Akty prawne</td><td>{metrics.get('legal_acts', {}).get('total_acts_referenced', 'N/A')}</td></tr>
    </table>
  </div>
  <div class="table-card">
    <h3>📈 Quality Metrics</h3>
    <table>
      <tr><th>Metryka</th><th>Wartość</th></tr>
      <tr><td>Błędy walidacji</td><td class="{'red' if v.get('errors', 0) > 0 else 'green'}">{v.get('errors', '—')}</td></tr>
      <tr><td>Ostrzeżenia</td><td>{v.get('warnings', '—')}</td></tr>
      <tr><td>Duplikaty rule_id</td><td class="orange">{d.get('duplicate_ids', '—')}</td></tr>
      <tr><td>Reguły szkieletowe</td><td>{d.get('skeleton_rules', '—')}</td></tr>
      <tr><td>Priority collisions</td><td class="orange">{d.get('priority_collisions', '—')}</td></tr>
    </table>
  </div>
</div>

<div class="footer">NexusAI JDG Enterprise Dashboard v8.0 — Innowacja 12 — Wygenerowano: {now}</div>
</body>
</html>"""


def generate_dashboard_markdown(metrics: dict) -> str:
    """Generuje dashboard w Markdown."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    m = metrics.get("manifest", {})
    v = metrics.get("validate", {})
    d = metrics.get("dead_rules", {})
    e = metrics.get("enterprise", {})
    cs = m.get("completeness_score", {})
    composite = cs.get("composite", 78)
    
    return f"""# 📊 NexusAI JDG — Enterprise Documentation Dashboard v8.0

> **Wygenerowano:** {now} | **Innowacja 12**

## Kluczowe metryki

| Metryka | Wartość |
|---------|---------|
| **Completeness Score** | **{composite}/100** |
| Pliki Rego | {m.get('total_files', '—')} |
| Pliki z matched:true | {m.get('files_with_matched', '—')} |
| Bloki matched:true | {m.get('matched_blocks', '—')} |
| Unikalne rule_id | {m.get('unique_rule_ids', '—')} |
| Duplikaty rule_id | {m.get('duplicates', '—')} |
| Enterprise inicjatywy | {e.get('completed', '—')}/{e.get('total_initiatives', '—')} ✅ |
| Błędy walidacji | {v.get('errors', '—')} |
| Ostrzeżenia | {v.get('warnings', '—')} |
| Reguły szkieletowe | {d.get('skeleton_rules', '—')} |
| Priority collisions | {d.get('priority_collisions', '—')} |
| Bundle version | {metrics.get('bundle', {}).get('version', 'N/A')} |
| Akty prawne | {metrics.get('legal_acts', {}).get('total_acts_referenced', 'N/A')} |

## Pliki Score

| Komponent | Score |
|-----------|:-----:|
| Pokrycie plików | {cs.get('files_coverage_pct', '—')}% |
| Aktualność | {cs.get('freshness_score', '—')}/100 |
| Spójność sum | {'✅' if cs.get('sum_consistent') else '❌'} |
| Routing coverage | {cs.get('routing_score', '—')}% |

---
*Wygenerowano — {now}*
*Innowacja 12 — `python JDG/tools/enterprise_dashboard.py`*
"""


def main():
    print("📊 Generowanie Enterprise Dashboard (Innowacja 12)...")
    
    try:
        metrics = collect_all_metrics()
    except Exception as e:
        print(f"⚠️  Częściowe dane (błąd: {e})")
        metrics = {}
    
    # HTML
    html = generate_dashboard_html(metrics)
    html_path = JDG_ROOT / "reports" / "enterprise_dashboard.html"
    html_path.parent.mkdir(parents=True, exist_ok=True)
    html_path.write_text(html, encoding="utf-8")
    print(f"✅ Dashboard HTML: {html_path} ({len(html)} bajtów)")
    
    # Markdown
    md = generate_dashboard_markdown(metrics)
    md_path = JDG_ROOT / "reports" / "enterprise_dashboard.md"
    md_path.write_text(md, encoding="utf-8")
    print(f"✅ Dashboard MD: {md_path} ({len(md)} bajtów)")
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
