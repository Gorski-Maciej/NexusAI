#!/usr/bin/env python3
"""
NexusAI JDG — Advanced Rule Generator from Plan OPA 50
Parses Plan OPA 50 (1935+ legal points) and generates Rego rules systematically.
Each legal point becomes a proper Rego rule with:
- Correct Micro ID (jdg.<ustawa>.<artykul>.r<n>)
- Macro P-ID/R-ID mapping
- Proper else-chain structure
- Priority spacing
- Legal basis field
- Avoids duplicates with existing rules
"""
import re, os, sys
from collections import defaultdict
from datetime import datetime

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

OUTPUT_DIR = "JDG/rules"
PLAN50_PATH = "Plan OPA/50_JDG_BRAKUJACE_PUNKTY_PRAWNE.md"
DRY_RUN = "--dry-run" in sys.argv
FORCE = "--force" in sys.argv

# Priority ranges for each legal area (wide spacing for future insertions)
AREA_PRIORITY_BASE = {
    "vat": 50000,       # VAT: 50000-59999
    "pit": 60000,       # PIT: 60000-69999
    "ord": 70000,       # Ordynacja: 70000-79999
    "kks": 80000,       # KKS: 80000-89999
    "sus": 90000,       # ZUS/SUS: 90000-99999
    "ryczalt": 100000,  # Ryczałt: 100000-109999
    "pp": 110000,       # Prawo Przedsiębiorców: 110000-119999
    "uor": 120000,      # UoR: 120000-129999
    "pcc": 130000,      # PCC: 130000-139999
    "crossborder": 140000,  # Cross-border: 140000-149999
    "ceidg": 150000,    # CEIDG/Sukcesja: 150000-159999
    "zdrowotna": 160000,  # Zdrowotna: 160000-169999
    "aml": 170000,      # AML/RODO/BDO: 170000-179999
    "akcyza": 180000,   # Akcyza: 180000-189999
    "lokalne": 190000,  # Podatki lokalne: 190000-199999
}

# Map Plan OPA 50 section prefixes to output files and area codes
SECTION_MAP = {
    "V.": ("vat", "jdg/vat"),
    "P.": ("pit", "jdg/pit"),
    "OP.": ("ord", "jdg/ord"),
    "K.": ("kks", "jdg/kks"),
    "Z.": ("sus", "jdg/sus"),
    "R.": ("ryczalt", "jdg/ryczalt"),
    "PP.": ("pp", "jdg/pp"),
    "U.": ("uor", "jdg/uor"),
    "Pcc.": ("pcc", "jdg/pcc"),
    "PLO.": ("lokalne", "jdg/lokalne"),
    "Akc.": ("akcyza", "jdg/akcyza"),
    "CB.": ("crossborder", "jdg/crossborder"),
    "Suk.": ("ceidg", "jdg/ceidg"),
    "Zdr.": ("zdrowotna", "jdg/zdrowotna"),
    "AML.": ("aml", "jdg/aml"),
}

# ═══════════════════════════════════════════════════════════════════════════════
# COLLECT EXISTING RULE_IDS
# ═══════════════════════════════════════════════════════════════════════════════

def collect_existing_rule_ids(base_dir="JDG/rules"):
    """Collect all existing rule_ids to avoid duplicates."""
    existing = set()
    if not os.path.exists(base_dir):
        return existing
    for root, dirs, files in os.walk(base_dir):
        for f in files:
            if f.endswith(".rego"):
                path = os.path.join(root, f)
                try:
                    with open(path) as fh:
                        content = fh.read()
                        ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', content)
                        existing.update(ids)
                except:
                    pass
    return existing

# ═══════════════════════════════════════════════════════════════════════════════
# PARSE PLAN OPA 50
# ═══════════════════════════════════════════════════════════════════════════════

def parse_plan50(path):
    """Parse Plan OPA 50 and extract structured legal points."""
    with open(path, encoding='utf-8') as f:
        content = f.read()
    
    points = []
    
    # Pattern for Class A points (detailed 8-field format)
    # Looks for: #### V.01. Art. XX ust. Y pkt Z — Description
    # Followed by bullet points with: **ID OPA:**, **Brzmienie:**, **Status:**, etc.
    
    # First find all section headers
    section_pattern = re.compile(
        r'####\s+([A-Z]+(?:\.[a-z]+)?)\.(\d+[a-z]*)\s*(?:[-–—]\s*)?\s*Art\.\s*([^—\n]+?)(?:—\s*(.+?))?\s*\n',
        re.MULTILINE
    )
    
    # Find all legal point blocks
    # Each point starts with #### <PREFIX>.<NUMBER>. Art. <article> — <description>
    # Followed by bullet list with structured fields
    
    for match in section_pattern.finditer(content):
        prefix = match.group(1)
        number = match.group(2)
        article = match.group(3).strip()
        description = match.group(4).strip() if match.group(4) else ""
        
        # Get the block after this header (until next #### or end)
        start = match.end()
        next_section = re.search(r'^####\s', content[start:], re.MULTILINE)
        if next_section:
            block = content[start:start + next_section.start()]
        else:
            block = content[start:start + 5000]  # Limit to avoid runaway
        
        # Extract fields from bullet points
        fields = {}
        field_patterns = {
            'id_opa': r'\*\*ID OPA[：:]\*\*\s*(?:`([^`]+)`|([^\n]+))',
            'brzmienie': r'\*\*Brzmienie[^:]*:\*\*\s*(.+?)(?=\n-|\n\*\*)',
            'status': r'\*\*Status[^:]*:\*\*\s*(.+?)(?=\n)',
            'prio': r'\*\*Prio[^:]*:\*\*\s*(.+?)(?=\n)',
            'ryzyko': r'\*\*Ryzyko[^:]*:\*\*\s*(.+?)(?=\n)',
            'logika': r'\*\*Logika OPA[^:]*:\*\*\s*(.+?)(?=\n)',
            'kod': r'\*\*Kod[^:]*:\*\*\s*(.+?)(?=\n)',
            'pokrewne': r'\*\*Pokrewne[^:]*:\*\*\s*(.+?)(?=\n)',
        }
        
        for field_name, pattern in field_patterns.items():
            m = re.search(pattern, block, re.DOTALL | re.IGNORECASE)
            if m:
                val = m.group(1) or m.group(2) or ""
                fields[field_name] = re.sub(r'`', '', val.strip())
        
        # Also try to extract the legacy 8-field format (Stare ID OPA / Nowe ID OPA)
        legacy_id = re.search(r'(?:Identyfikator OPA|ID OPA)\s*[⇔:]\s*(?:`([^`]+)`|([^\n]+))', block)
        if legacy_id and 'id_opa' not in fields:
            fields['id_opa'] = (legacy_id.group(1) or legacy_id.group(2) or "").strip('` ')
        
        # Determine area and file from prefix
        area = None
        file_prefix = None
        for sec_prefix, (area_code, file_pref) in SECTION_MAP.items():
            if prefix.startswith(sec_prefix):
                area = area_code
                file_prefix = file_pref
                break
        
        if not area:
            continue
        
        points.append({
            'prefix': prefix,
            'number': number,
            'article': article.strip(),
            'description': description.strip() if description else "",
            'area': area,
            'file_prefix': file_prefix,
            'fields': fields,
            'raw_block': block[:500],
        })
    
    return points


def extract_micro_id(point):
    """Extract or construct the Micro ID from a legal point."""
    fields = point.get('fields', {})
    
    # Try explicit id_opa field first
    if 'id_opa' in fields:
        id_val = fields['id_opa']
        # Clean up and extract the jdg.* ID
        micro_match = re.search(r'(jdg\.[a-z_]+\.[a-z0-9_]+(?:\.[a-z0-9_]+)*)', id_val)
        if micro_match:
            return micro_match.group(1)
        # If it contains a Macro P-ID, construct Micro from prefix+article
        macro_match = re.search(r'P(\d{2,6}[a-z_]*)', id_val)
        if macro_match:
            pass  # Fall through to construction
    
    # Construct Micro ID from section prefix and article
    prefix = point['prefix'].lower().rstrip('.')
    article = point['article']
    number = point['number']
    
    # Clean article: extract just the number
    art_num = re.search(r'(\d+[a-z]*)', article.replace('Art.', '').replace('art.', ''))
    if art_num:
        art_id = f"a{art_num.group(1)}"
    else:
        art_id = "generic"
    
    # Construct: jdg.<area>.<article>.r<number>
    area = point['area']
    return f"jdg.{area}.{art_id}.r{number}"


def extract_macro_id(point):
    """Extract the Macro P-ID from a legal point."""
    fields = point.get('fields', {})
    if 'id_opa' in fields:
        macro_match = re.search(r'\(Macro:\s*(P\d+[a-z_]*)\)', fields['id_opa'])
        if macro_match:
            return macro_match.group(1)
        # Try the other format
        macro_match = re.search(r'Macro:\s*(P\d+[a-z_]*)', fields['id_opa'])
        if macro_match:
            return macro_match.group(1)
    
    # Try raw block
    macro_match = re.search(r'Macro:\s*(P\d+[a-z_]*)', point.get('raw_block', ''))
    if macro_match:
        return macro_match.group(1)
    
    return None


def extract_legal_basis(point):
    """Extract the legal basis from the point."""
    article = point['article']
    description = point.get('description', '')
    fields = point.get('fields', {})
    
    basis = f"Art. {article}"
    
    if 'brzmienie' in fields:
        brz = fields['brzmienie'][:200]
        basis = brz if len(brz) < 200 else brz[:197] + "..."
    
    return basis


def determine_routing(point):
    """Determine the routing based on priority."""
    fields = point.get('fields', {})
    prio = fields.get('prio', '').upper()
    
    if 'KRYTYCZNY' in prio:
        return "BLOCK_AND_ALERT"
    elif 'WAŻNY' in prio:
        return "TRIAGE_QUEUE"
    else:
        return "WARNING"


def determine_priority(point, existing_count):
    """Calculate priority number for a point."""
    area = point['area']
    base = AREA_PRIORITY_BASE.get(area, 200000)
    
    # Use the point number as offset within the area
    number = point['number']
    # Try to convert to int offset
    try:
        offset = int(re.sub(r'[a-z_]', '', number))
    except:
        offset = existing_count
    
    return base + offset * 10  # 10-point spacing


# ═══════════════════════════════════════════════════════════════════════════════
# REGO RULE GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

def generate_rule_rego(point, priority, rule_index_in_file):
    """Generate a single Rego rule."""
    micro_id = extract_micro_id(point)
    macro_id = extract_macro_id(point)
    area = point['area']
    package = f"jdg.{area}"
    routing = determine_routing(point)
    legal_basis = extract_legal_basis(point)
    fields = point.get('fields', {})
    
    description = point.get('description', '') or fields.get('brzmienie', '')[:100]
    description_clean = description.replace('"', "'").replace('\n', ' ')[:120]
    
    # Build the rule body
    rule_keyword = "decide" if rule_index_in_file == 0 else "else"
    
    # Simple condition based on article matching
    article_clean = point['article'].replace('Art.', '').replace('art.', '').strip()
    
    verdict = (
        f'  {{"matched":true,'
        f'"rule_id":"{micro_id}",'
        f'"package":"{package}",'
        f'"priority":{priority},'
        f'"vat_rate":"",'
        f'"rounding_level":"",'
        f'"gtu_code":"",'
        f'"pit_form":"",'
        f'"pit_rate":"",'
        f'"pit_bracket":"",'
        f'"pit_annual_return_type":"",'
        f'"kus_qualification":"",'
        f'"kus_percent":0,'
        f'"zus_social_base_type":"",'
        f'"zus_health_rate":"",'
        f'"business_status":"",'
        f'"_routing":"{routing}",'
        f'"_routing_reason":"{description_clean}",'
        f'"_legal_basis":"{legal_basis[:150]}"'
    )
    
    if macro_id:
        verdict += f',"_macro_id":"{macro_id}"'
    
    verdict += '}'
    
    # Build the condition
    condition = (
        f'{{ input.article == "{article_clean}";'
        f' input.legal_area == "{area}" }}'
    )
    
    rule = f'''
# {micro_id} — {description_clean[:100]}
{rule_keyword} := {verdict} {condition}
'''
    return rule


def generate_rego_file(area, points, existing_ids, file_path):
    """Generate a complete .rego file for an area."""
    
    # Filter out points that already exist
    new_points = []
    for p in points:
        mid = extract_micro_id(p)
        if mid not in existing_ids:
            new_points.append(p)
    
    if not new_points:
        print(f"  [{area}] All {len(points)} points already covered — skipping")
        return 0
    
    # Calculate priorities
    existing_count = len([pid for pid in existing_ids if f"jdg.{area}." in pid])
    
    rules = []
    for i, point in enumerate(new_points):
        priority = determine_priority(point, existing_count)
        rule = generate_rule_rego(point, priority, i)
        rules.append(rule)
    
    # Build file content
    header = f'''# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — {area.upper()} Legal Points from Plan OPA 50
# Generated: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
# Points: {len(new_points)} rules (from {len(points)} total in Plan OPA 50)
# Convention: jdg.{area}.a<article>.r<number>
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.{area}
import data.jdg.helpers
default decide := {{"matched":false,"rule_id":"jdg.{area}.no_match","package":"jdg.{area}","priority":{AREA_PRIORITY_BASE.get(area, 200000)}}}
'''
    
    content = header + '\n'.join(rules)
    
    # Create directory if needed
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    if not DRY_RUN:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  [{area}] Generated {len(new_points)} rules → {file_path}")
    else:
        print(f"  [DRY RUN] [{area}] Would generate {len(new_points)} rules → {file_path}")
    
    return len(new_points)


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    print("=" * 70)
    print("NexusAI JDG — Advanced Rule Generator from Plan OPA 50")
    print("=" * 70)
    
    # Parse Plan OPA 50
    print("\n[1] Parsing Plan OPA 50...")
    points = parse_plan50(PLAN50_PATH)
    print(f"    Found {len(points)} legal points")
    
    # Group by area
    by_area = defaultdict(list)
    for p in points:
        by_area[p['area']].append(p)
    
    print(f"    Areas: {len(by_area)}")
    for area, pts in sorted(by_area.items()):
        print(f"      {area}: {len(pts)} points")
    
    # Collect existing IDs
    print("\n[2] Collecting existing rule_ids...")
    existing_ids = collect_existing_rule_ids()
    print(f"    Existing unique rule_ids: {len(existing_ids)}")
    
    # Generate rules per area
    print("\n[3] Generating Rego rules...")
    
    # Define output file mapping
    area_to_file = {
        "vat": "JDG/rules/vat/plan50_substantive.rego",
        "pit": "JDG/rules/pit/plan50_substantive.rego",
        "ord": "JDG/rules/ordynacja/plan50_substantive.rego",
        "kks": "JDG/rules/kks/plan50_substantive.rego",
        "sus": "JDG/rules/zus/plan50_substantive.rego",
        "ryczalt": "JDG/rules/ryczalt/plan50_substantive.rego",
        "pp": "JDG/rules/pp/plan50_substantive.rego",
        "uor": "JDG/rules/uor/plan50_substantive.rego",
        "pcc": "JDG/rules/pcc/plan50_substantive.rego",
        "lokalne": "JDG/rules/lokalne/plan50_substantive.rego",
        "akcyza": "JDG/rules/akcyza/plan50_substantive.rego",
        "crossborder": "JDG/rules/crossborder/plan50_substantive.rego",
        "ceidg": "JDG/rules/ceidg/plan50_substantive.rego",
        "zdrowotna": "JDG/rules/zdrowotna/plan50_substantive.rego",
        "aml": "JDG/rules/aml/plan50_substantive.rego",
    }
    
    total_generated = 0
    for area, pts in sorted(by_area.items()):
        file_path = area_to_file.get(area, f"JDG/rules/{area}/plan50_substantive.rego")
        count = generate_rego_file(area, pts, existing_ids, file_path)
        total_generated += count
    
    print(f"\n{'=' * 70}")
    print(f"SUMMARY")
    print(f"  Total legal points parsed: {len(points)}")
    print(f"  Total rules generated: {total_generated}")
    print(f"  Existing rules (not duplicated): {len(existing_ids)}")
    print(f"  Areas covered: {len(by_area)}")
    
    if DRY_RUN:
        print("\n  ⚠️ DRY RUN — no files written. Use without --dry-run to generate.")
    
    print(f"{'=' * 70}")


if __name__ == "__main__":
    main()
