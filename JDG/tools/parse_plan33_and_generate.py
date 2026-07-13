#!/usr/bin/env python3
"""
NexusAI JDG — Plan OPA 33 Parser & Micro-Rules Generator.
Parses Plan OPA/33_JDG_MASSIVE_RULE_CATALOG.md and generates .rego micro-rule files
with { true } stubs, organized by domain (vat, pit, ord, zus, ryc, health, kks, pcc,
uor, ceidg, succ, ksef, jpk, cb, tp, est, mdr, rodo, prop, etc.).
"""
import re, os, sys, json
from datetime import datetime
from collections import defaultdict

BASE = "JDG/rules"
PLAN33_PATH = "Plan OPA/33_JDG_MASSIVE_RULE_CATALOG.md"
DRY_RUN = "--dry-run" in sys.argv

# ═══════════════════════════════════════════════════════════════════════════════
# DOMAIN → PACKAGE MAPPING
# ═══════════════════════════════════════════════════════════════════════════════

DOMAIN_TO_PACKAGE = {
    "vat": "jdg.micro.vat",
    "pit": "jdg.micro.pit",
    "ord": "jdg.micro.ord",
    "zus": "jdg.micro.zus",
    "ryc": "jdg.micro.ryc",
    "health": "jdg.micro.health",
    "kks": "jdg.micro.kks",
    "pcc": "jdg.micro.pcc",
    "uor": "jdg.micro.uor",
    "ceidg": "jdg.micro.ceidg",
    "succ": "jdg.micro.succ",
    "ksef": "jdg.micro.ksef",
    "jpk": "jdg.micro.jpk",
    "cb": "jdg.micro.cb",
    "tp": "jdg.micro.tp",
    "est": "jdg.micro.est",
    "mdr": "jdg.micro.mdr",
    "rodo": "jdg.micro.rodo",
    "prop": "jdg.micro.prop",
    "prop_transport": "jdg.micro.prop_transport",
    "tax_trans": "jdg.micro.tax_trans",
    "agricultural_tax": "jdg.micro.agricultural_tax",
}

# Priority base per domain (will use rule_number * step)
DOMAIN_PRIORITY_BASE = {
    "vat": 500,
    "pit": 1200,
    "ord": 1800,
    "zus": 2300,
    "ryc": 3000,
    "health": 4400,
    "kks": 3600,
    "pcc": 4000,
    "uor": 4800,
    "ceidg": 5200,
    "succ": 5400,
    "ksef": 5600,
    "jpk": 5900,
    "cb": 6200,
    "tp": 6500,
    "est": 6600,
    "mdr": 6800,
    "rodo": 6900,
    "prop": 7100,
    "prop_transport": 7550,
    "tax_trans": 7400,
    "agricultural_tax": 7500,
}

# ═══════════════════════════════════════════════════════════════════════════════
# PARSER: Extract tables from markdown
# ═══════════════════════════════════════════════════════════════════════════════

def extract_domain_from_id(rule_id):
    """Extract domain from rule ID like jdg.vat.a5.r1 -> vat, jdg.pit.a22.r5 -> pit"""
    parts = rule_id.replace("`", "").strip().split(".")
    if len(parts) >= 2:
        return parts[1]
    return "unknown"


def parse_markdown_tables(filepath):
    """Parse all markdown tables and return list of rule dicts."""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    rules = []
    in_table = False
    table_lines = []
    current_section = ""
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Track section headers
        if stripped.startswith("## ") or stripped.startswith("### ") or stripped.startswith("#### "):
            current_section = stripped.lstrip("#").strip()
        
        # Detect table start/end
        is_table_line = stripped.startswith("|") and not stripped.startswith("|---") and not stripped.startswith("|:--")
        is_separator = stripped.startswith("|---") or stripped.startswith("|:--")
        
        if is_table_line and not is_separator:
            if not in_table:
                in_table = True
                table_lines = []
            table_lines.append(stripped)
        elif is_separator:
            continue  # skip separator lines
        else:
            if in_table and table_lines:
                # Process collected table
                rules.extend(process_table_block(table_lines, current_section))
                table_lines = []
            in_table = False
    
    # Process last table if any
    if in_table and table_lines:
        rules.extend(process_table_block(table_lines, current_section))
    
    return rules


def process_table_block(table_lines, section):
    """Process a single table block and extract rule data."""
    if not table_lines:
        return []
    
    # Parse header to understand column mapping
    header = parse_table_row(table_lines[0])
    data_rows = table_lines[1:]
    
    rules = []
    for row_str in data_rows:
        cells = parse_table_row(row_str)
        if not cells:
            continue
        
        rule_data = extract_rule_data(header, cells, section)
        if rule_data:
            rules.append(rule_data)
    
    return rules


def parse_table_row(row_str):
    """Parse a markdown table row into cells."""
    # Split by | but handle escaped pipes and code ticks
    row_str = row_str.strip().strip("|")
    cells = []
    current = ""
    in_code = False
    
    for ch in row_str:
        if ch == '`':
            in_code = not in_code
            current += ch
        elif ch == '|' and not in_code:
            cells.append(current.strip())
            current = ""
        else:
            current += ch
    
    if current.strip():
        cells.append(current.strip())
    
    return cells


def extract_rule_data(header, cells, section):
    """Extract rule data from header and cells."""
    if len(cells) < 2:
        return None
    
    # Build column map
    col_map = {}
    for i, h in enumerate(header):
        h_lower = h.lower().strip().strip('`').strip()
        col_map[i] = h_lower
    
    # Find ID column (first column that looks like a rule ID or P-number)
    rule_id = ""
    for i, cell in enumerate(cells):
        cell_clean = cell.strip().strip('`').strip()
        # ID patterns: jdg.vat.a5.r1, P630, P590b
        if re.match(r'^(jdg\.\w+\.|P\d+)', cell_clean):
            rule_id = cell_clean
            break
    
    if not rule_id:
        return None
    
    # Skip P-prefixed enterprise rules (they go elsewhere, not micro)
    if re.match(r'^P\d+', rule_id):
        return None
    
    # Extract domain
    domain = extract_domain_from_id(rule_id)
    if domain == "unknown":
        return None
    
    # Extract other fields
    rule_name = ""
    condition = ""
    result = ""
    legal_basis = ""
    extra_field = ""
    
    for i, cell in enumerate(cells):
        cell_clean = cell.strip().strip('`').strip()
        if cell_clean == rule_id or cell_clean == rule_id.strip('`'):
            continue
        
        col_name = col_map.get(i, "")
        
        if col_name in ("nazwa reguły", "nazwa reguly", "nazwa", "name", "ulga", "źródło", "strona",
                        "wydatek wyłączony", "wydatek wylaczony", "przedmiot zwolnienia"):
            rule_name = cell_clean
        elif col_name in ("warunek", "condition"):
            condition = cell_clean if condition == "" else condition
        elif col_name in ("rezultat", "result", "stawka", "kwota", "limit/stawka", "limit",
                          "moment obowiązku", "moment obowiazku"):
            result = cell_clean if result == "" else result
        elif col_name in ("podstawa", "podstawa prawna", "legal basis"):
            legal_basis = cell_clean
        elif col_name in ("limit", "limit/stawka", "kwota"):
            extra_field = cell_clean
    
    # If condition is empty, it might be in a differently-named column
    if condition == "" and len(cells) >= 3:
        # Try to find condition from context
        for i, cell in enumerate(cells):
            cell_clean = cell.strip().strip('`').strip()
            if cell_clean != rule_id and cell_clean != rule_name and cell_clean != result and cell_clean != legal_basis:
                if len(cell_clean) > 5 and not cell_clean.startswith("Art.") and not cell_clean.startswith("jdg.") and not cell_clean.startswith("P"):
                    condition = cell_clean
                    break
    
    # Build description from condition + result
    description = condition
    if result:
        description += f" → {result}"
    
    return {
        "rule_id": rule_id,
        "domain": domain,
        "name": rule_name,
        "condition": condition,
        "result": result,
        "legal_basis": legal_basis,
        "description": description,
        "section": section,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# CROSS-REFERENCE: Load existing rule IDs
# ═══════════════════════════════════════════════════════════════════════════════

def load_existing_rule_ids():
    """Load all existing rule IDs from JDG/rules/ directory, EXCLUDING plan33 files."""
    import glob
    ids = set()
    pattern = os.path.join(BASE, "**", "*.rego")
    for fpath in glob.glob(pattern, recursive=True):
        if "plan33_" in os.path.basename(fpath):
            continue  # skip auto-generated plan33 files
        try:
            with open(fpath, 'r', encoding='utf-8') as f:
                content = f.read()
            for m in re.finditer(r'"rule_id"\s*:\s*"([^"]+)"', content):
                ids.add(m.group(1))
        except Exception:
            pass
    return ids


# ═══════════════════════════════════════════════════════════════════════════════
# GENERATOR: Create .rego files
# ═══════════════════════════════════════════════════════════════════════════════

def build_verdict(rule_id, package, priority, routing_reason, legal_basis):
    """Build a verdict JSON string without using .format() to avoid brace conflicts."""
    rr = routing_reason.replace('\\', '\\\\').replace('"', '\\"')
    lb = legal_basis.replace('\\', '\\\\').replace('"', '\\"')
    return (
        '{"matched":true,'
        f'"rule_id":"{rule_id}",'
        f'"package":"{package}",'
        f'"priority":{priority},'
        '"vat_rate":"","rounding_level":"","gtu_code":"",'
        '"pit_form":"","pit_rate":"","pit_bracket":"",'
        '"pit_annual_return_type":"","kus_qualification":"","kus_percent":0,'
        '"zus_social_base_type":"","zus_health_rate":"","business_status":"",'
        '"_routing":"",'
        f'"_routing_reason":"{rr}",'
        f'"_legal_basis":"{lb}",'
        '"_warnings":[]}'
    )



def generate_rego_files(rules, dry_run=False):
    """Generate .rego files grouped by domain."""
    # Group rules by domain
    by_domain = defaultdict(list)
    for r in rules:
        by_domain[r["domain"]].append(r)
    
    generated = {}
    
    for domain, domain_rules in sorted(by_domain.items()):
        package = DOMAIN_TO_PACKAGE.get(domain)
        if not package:
            print(f"  ⚠️ Unknown domain: {domain}, skipping {len(domain_rules)} rules")
            continue
        
        # Sort rules by ID for consistent ordering
        domain_rules.sort(key=lambda r: r["rule_id"])
        
        # Deduplicate by rule_id (Plan OPA 33 may have duplicate IDs in different sections)
        seen_ids = set()
        deduped = []
        dupe_count = 0
        for r in domain_rules:
            if r["rule_id"] not in seen_ids:
                seen_ids.add(r["rule_id"])
                deduped.append(r)
            else:
                dupe_count += 1
        if dupe_count > 0:
            print(f"  ℹ️ {domain}: removed {dupe_count} duplicate rule IDs")
        domain_rules = deduped
        
        # Assign priorities
        base = DOMAIN_PRIORITY_BASE.get(domain, 1000)
        for idx, r in enumerate(domain_rules):
            r["priority"] = base + idx
        
        # Build file content
        lines = []
        lines.append(f"# Generated from Plan OPA 33 — Micro-rules for {domain}")
        lines.append(f"# {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append(f"# Rules: {len(domain_rules)} (new, deduplicated)")
        lines.append(f"")
        lines.append(f"package {package}")
        lines.append(f"")
        
        # Default decide
        default_str = '{"matched":false,"rule_id":"' + package + '.no_match","package":"' + package + '","priority":99999}'
        lines.append(f"default decide := {default_str}")
        lines.append(f"")
        
        # Rules
        for idx, r in enumerate(domain_rules):
            # Comment line
            desc = r.get("description", r.get("condition", ""))
            desc = desc.replace('"', '\\"')
            name = r.get("name", "")
            comment = f"# {r['rule_id']}"
            if name:
                comment += f" — `{name}`"
            if desc:
                # Truncate long descriptions
                if len(desc) > 120:
                    desc = desc[:117] + "..."
                comment += f": {desc}"
            lines.append(comment)
            
            # Build verdict
            routing_reason = r.get("condition", "")
            legal_basis = r.get("legal_basis", "")
            verdict = build_verdict(
                rule_id=r["rule_id"],
                package=package,
                priority=r["priority"],
                routing_reason=routing_reason,
                legal_basis=legal_basis,
            )
            
            # Rule line
            kw = "decide" if idx == 0 else "else"
            lines.append(f'{kw} :=   {verdict} {{')
            lines.append(f'    true')
            lines.append(f'}}')
            lines.append(f'')
        
        # Write file
        domain_dir = os.path.join(BASE, "micro")
        os.makedirs(domain_dir, exist_ok=True)
        filename = f"plan33_{domain}.rego"
        filepath = os.path.join(domain_dir, filename)
        
        content = '\n'.join(lines)
        
        if dry_run:
            print(f"  [DRY RUN] {filename}: {len(domain_rules)} rules would be generated")
        else:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  ✅ {filename}: {len(domain_rules)} rules generated")
        
        generated[domain] = len(domain_rules)
    
    return generated


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    print("=" * 70)
    print("NexusAI JDG — Plan OPA 33 Parser & Micro-Rules Generator")
    print("=" * 70)
    
    # Parse Plan OPA 33
    print(f"\n📖 Parsing {PLAN33_PATH}...")
    all_rules = parse_markdown_tables(PLAN33_PATH)
    print(f"   Parsed {len(all_rules)} rules from markdown tables")
    
    # Stats by domain
    by_domain = defaultdict(int)
    for r in all_rules:
        by_domain[r["domain"]] += 1
    
    print(f"\n📊 Rules by domain:")
    for domain, count in sorted(by_domain.items(), key=lambda x: -x[1]):
        print(f"   {domain}: {count}")
    
    # Load existing rule IDs
    print(f"\n🔍 Loading existing rule IDs...")
    existing_ids = load_existing_rule_ids()
    print(f"   Found {len(existing_ids)} existing rule IDs")
    
    # Filter out existing
    new_rules = [r for r in all_rules if r["rule_id"] not in existing_ids]
    print(f"\n✨ New rules (not in codebase): {len(new_rules)} / {len(all_rules)}")
    
    # Stats by domain for new rules
    new_by_domain = defaultdict(int)
    for r in new_rules:
        new_by_domain[r["domain"]] += 1
    
    print(f"   New rules by domain:")
    for domain, count in sorted(new_by_domain.items(), key=lambda x: -x[1]):
        print(f"     {domain}: {count}")
    
    if not new_rules:
        print("\n✅ No new rules to generate. All Plan OPA 33 rules already exist!")
        return
    
    # Generate
    print(f"\n📝 Generating .rego files...")
    generated = generate_rego_files(new_rules, dry_run=DRY_RUN)
    
    total = sum(generated.values())
    print(f"\n{'=' * 70}")
    print(f"SUMMARY")
    print(f"  Total new rules generated: {total}")
    print(f"  Files: {len(generated)}")
    for domain, count in sorted(generated.items()):
        pkg = DOMAIN_TO_PACKAGE.get(domain, "unknown")
        print(f"    {pkg} (plan33_{domain}.rego): {count} rules")
    
    if DRY_RUN:
        print(f"\n  ⚠️ DRY RUN — use without --dry-run to write files.")
    else:
        print(f"\n  ✅ Files written to JDG/rules/micro/")
    
    print(f"{'=' * 70}")


if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    main()
