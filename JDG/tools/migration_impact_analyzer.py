#!/usr/bin/env python3
"""
NexusAI JDG — Migration Impact Analyzer (Innowacja 7)
Analizuje wpływ migracji SQL na reguły Rego, API i narzędzia.
Mapuje tabele → reguły → endpointy → narzędzia.

Usage: python migration_impact_analyzer.py [--json]
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent
MIGRATIONS_DIR = JDG_ROOT / "migrations"
RULES_DIR = JDG_ROOT / "rules"


def parse_migration(filepath: Path) -> dict:
    """Parsuje plik migracji SQL i ekstrahuje tworzone tabele."""
    try:
        content = filepath.read_text(encoding="utf-8")
    except:
        return {"file": filepath.name, "tables": [], "columns": []}

    tables = re.findall(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)', content, re.IGNORECASE)
    columns = re.findall(r'(\w+)\s+(?:UUID|VARCHAR|INTEGER|NUMERIC|BOOLEAN|JSON|TIMESTAMP|BIGINT|TEXT)', content, re.IGNORECASE)
    
    return {
        "file": filepath.name,
        "tables": tables,
        "columns": columns,
        "size": len(content),
    }


def find_rules_referencing_table(table_name: str) -> list[str]:
    """Znajduje reguły Rego odwołujące się do tabeli (przez data.thresholds lub nazwę)."""
    rules = []
    search_terms = [
        table_name.lower(),
        table_name.replace("jdg_", "").lower(),
        table_name.replace("_", ".").lower(),
    ]
    
    for fp in sorted(RULES_DIR.rglob("*.rego")):
        try:
            content = fp.read_text(encoding="utf-8")
        except: continue
        
        rel = str(fp.relative_to(RULES_DIR))
        for term in search_terms:
            if term in content.lower():
                matching_rule_ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
                if matching_rule_ids:
                    rules.extend(matching_rule_ids[:5])
                break
    
    return list(dict.fromkeys(rules))[:10]


def find_endpoints_referencing_table(table_name: str) -> list[str]:
    """Znajduje endpointy API odwołujące się do tabeli."""
    try:
        spec = (JDG_ROOT / "api" / "openapi.yaml").read_text(encoding="utf-8")
    except:
        return []
    
    endpoints = []
    paths = re.findall(r'/\w+/\w+(?:/\{[^}]+\})?', spec)
    
    search_term = table_name.replace("jdg_", "").replace("_", "-")
    for path in paths:
        if search_term in path.lower():
            endpoints.append(path)
    
    return list(dict.fromkeys(endpoints))


def analyze_impact() -> dict:
    """Analizuje wpływ wszystkich migracji."""
    migrations = []
    for fp in sorted(MIGRATIONS_DIR.glob("*.sql")):
        mig = parse_migration(fp)
        
        # Dla każdej tabeli znajdź zależności
        table_impacts = []
        for table in mig["tables"]:
            rules = find_rules_referencing_table(table)
            endpoints = find_endpoints_referencing_table(table)
            table_impacts.append({
                "table": table,
                "affected_rules": len(rules),
                "sample_rules": rules[:3],
                "affected_endpoints": endpoints,
            })
        
        mig["table_impacts"] = table_impacts
        mig["total_affected_rules"] = sum(ti["affected_rules"] for ti in table_impacts)
        migrations.append(mig)
    
    return {
        "migrations": migrations,
        "total_migrations": len(migrations),
        "total_tables": sum(len(m["tables"]) for m in migrations),
        "total_affected_rules": sum(m["total_affected_rules"] for m in migrations),
    }


def generate_impact_report(data: dict) -> str:
    """Generuje raport wpływu migracji."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    lines = [
        "# 🗄️ Migration Impact Analysis — NexusAI JDG v8.0",
        "",
        f"> **Wygenerowano:** {now} | **Innowacja 7**",
        f"> **Migracji:** {data['total_migrations']} | **Tabel:** {data['total_tables']} | **Reguł dotkniętych:** {data['total_affected_rules']}",
        "",
        "## Analiza per migracja",
        "",
    ]
    
    for m in data["migrations"]:
        lines.extend([
            f"### `{m['file']}` ({m['size']} B)",
            "",
            "| Tabela | Reguły dotknięte | Przykładowe rule_id | Endpointy API |",
            "|--------|:----------------:|---------------------|---------------|",
        ])
        
        for ti in m.get("table_impacts", []):
            rules_str = ", ".join(f"`{r}`" for r in ti.get("sample_rules", [])[:2]) or "—"
            endpoints_str = ", ".join(f"`{e}`" for e in ti.get("affected_endpoints", [])) or "—"
            lines.append(
                f"| `{ti['table']}` | {ti['affected_rules']} | {rules_str} | {endpoints_str} |"
            )
        
        lines.append("")
    
    lines.extend([
        "---",
        f"*Wygenerowano — {now}*",
        "*Innowacja 7 — `python JDG/tools/migration_impact_analyzer.py`*",
    ])
    return "\n".join(lines)


def main():
    print("🗄️  Migration Impact Analyzer (Innowacja 7)")
    
    data = analyze_impact()
    print(f"   Migracji: {data['total_migrations']}")
    print(f"   Tabel: {data['total_tables']}")
    print(f"   Reguł dotkniętych: {data['total_affected_rules']}")
    
    report = generate_impact_report(data)
    output = JDG_ROOT / "reports" / "migration_impact.md"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(report, encoding="utf-8")
    print(f"✅ Raport: {output} ({len(report)} bajtów)")
    
    if "--json" in sys.argv:
        print(json.dumps({
            "timestamp": datetime.now().isoformat(),
            **{k: v for k, v in data.items() if k != "migrations"},
            "migration_files": [m["file"] for m in data["migrations"]],
        }, indent=2, ensure_ascii=False))
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
