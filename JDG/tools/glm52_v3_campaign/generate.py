# -*- coding: utf-8 -*-
"""Generator kampanii V3 „FORTRESS” — pakiety promptów GLM 5.2 dla modułu JDG.

Użycie:
    python JDG/tools/glm52_v3_campaign/generate.py            # render + walidacja
    python JDG/tools/glm52_v3_campaign/generate.py --check    # tylko walidacja bez zapisu

Walidacje (twarde, exit 1 przy błędzie):
  1. Schemat części — każda ma komplet kluczy (code, slug, title, role, expertise,
     mission, subparts, file_groups, legal, innovations, in_contracts, out_contracts,
     acceptance_extra) i poprawną strukturę zagnieżdżeń.
  2. Ścieżki — każdy plik/katalog wskazany w częściach i mirrorach istnieje w repo.
  3. Minimum pliku — każdy prompt >= MIN_LINES linii i >= MIN_CHARS znaków.
  4. Frazy obowiązkowe — każda z PHRASES występuje >= MIN_PHRASE razy w każdym promptcie.
  5. Unikalność — kody części (P00..P92), slugi i nazwy plików wyjściowych.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT_DIR = os.path.join(ROOT, "JDG", "prompty_v3")

sys.path.insert(0, HERE)

import common  # noqa: E402
from parts_a import PARTS as A  # noqa: E402
from parts_b import PARTS as B  # noqa: E402
from parts_c import PARTS as C  # noqa: E402
from parts_d import PARTS as D  # noqa: E402
from parts_e import PARTS as E  # noqa: E402
from parts_f import PARTS as F  # noqa: E402
from parts_g import PARTS as G  # noqa: E402
from parts_h import PARTS as H  # noqa: E402
from parts_i import PARTS as I  # noqa: E402
from parts_j import PARTS as J  # noqa: E402

REQUIRED_KEYS = ["code", "slug", "title", "role", "expertise", "mission", "subparts",
                 "file_groups", "legal", "innovations", "in_contracts", "out_contracts",
                 "acceptance_extra"]


def check_schema(parts):
    errs = []
    codes = set()
    slugs = set()
    fnames = set()
    for p in parts:
        code = p.get("code", "??")
        for k in REQUIRED_KEYS:
            if k not in p:
                errs.append(f"{code}: brak klucza '{k}'")
        if code in codes:
            errs.append(f"{code}: zduplikowany kod części")
        codes.add(code)
        if p.get("slug") in slugs:
            errs.append(f"{code}: zduplikowany slug '{p.get('slug')}'")
        slugs.add(p.get("slug", ""))
        fname = f"V3_PROMPT_{code}_{p.get('slug', 'X')}.txt"
        if fname in fnames:
            errs.append(f"{code}: zduplikowana nazwa pliku {fname}")
        fnames.add(fname)
        if not isinstance(p.get("mission"), list) or len(p.get("mission", [])) < 2:
            errs.append(f"{code}: mission < 2 paragrafów")
        for i, sp in enumerate(p.get("subparts", []), 1):
            if "name" not in sp or "goal" not in sp or "questions" not in sp:
                errs.append(f"{code}: podanaliza 5.{i} niekompletna")
            elif len(sp["questions"]) < 3:
                errs.append(f"{code}: podanaliza 5.{i} < 3 pytań audytowych")
        for i, g in enumerate(p.get("file_groups", []), 1):
            if "name" not in g or "files" not in g:
                errs.append(f"{code}: grupa plików 6.{i} niekompletna")
            else:
                for desc, path in g["files"]:
                    if not path.startswith(("JDG/", "policies/")):
                        errs.append(f"{code}: podejrzana ścieżka '{path}' (poza JDG/ i policies/)")
        if len(p.get("legal", [])) < 5:
            errs.append(f"{code}: sekcja legal < 5 aktów")
        if len(p.get("innovations", [])) < 12:
            errs.append(f"{code}: innowacji {len(p.get('innovations', []))} < 12 (wymóg: min. 12 tematów)")
        if not p.get("in_contracts") or not p.get("out_contracts"):
            errs.append(f"{code}: brak kontraktów we/wy")
    expected = [f"P{i:02d}" for i in range(len(parts))]
    got = sorted(codes)
    if got != expected:
        missing = [c for c in expected if c not in codes]
        extra = [c for c in codes if c not in expected]
        errs.append(f"kody części nieciągłe: brak={missing}, nadmiar={extra}")
    return errs


def main():
    check_only = "--check" in sys.argv
    parts = A + B + C + D + E + F + G + H + I + J
    parts[-1]["is_last"] = True  # Ostatnia część = re-certyfikacja finalna fortecy
    print(f"Kampania V3: {len(parts)} części (P00–P{len(parts)-1:02d})")

    all_errs = []

    schema_errs = check_schema(parts)
    all_errs += schema_errs
    if schema_errs:
        print("\n--- BŁĘDY SCHEMATU ---")
        for e in schema_errs:
            print("  !", e)

    path_errs = common.validate_paths(parts, extra_paths=[p for _d, p in common.MIRROR_DOCS] +
                                                        [p for _d, p in common.HOLY_DOCS] +
                                                        [p for _d, p in common.BASE_DOCS] +
                                                        [common.BBB_DOC[1]])
    if path_errs:
        print("\n--- BŁĘDY ŚCIEŻEK ---")
        for e in path_errs:
            print("  !", e)
        all_errs += path_errs

    min_errs = []
    rendered = []
    final_code = parts[-1]["code"]
    for i, p in enumerate(parts):
        prev_part = parts[i - 1] if i > 0 else None
        next_part = parts[i + 1] if i + 1 < len(parts) else None
        text = common.render_part(p, prev_part, next_part, final_code=final_code)
        rendered.append((p, text))
        min_errs += common.validate_prompt(text, p["code"])

    if min_errs:
        print("\n--- BŁĘDY MINIMUM (linie/znaki/frazy) ---")
        for e in min_errs:
            print("  !", e)
        all_errs += min_errs

    readme_text = common.render_readme(parts)

    if all_errs:
        print(f"\nWYNIK: {len(all_errs)} błędów — NIE zapisano plików.")
        sys.exit(1)

    if check_only:
        stats = [(p["code"], text.count("\n"), len(text)) for p, text in rendered]
        lo = min(s[1] for s in stats)
        hi = max(s[1] for s in stats)
        print(f"Walidacja OK. Linie promptów: min={lo}, max={hi} (seria: P00–{final_code}).")
        sys.exit(0)

    os.makedirs(OUT_DIR, exist_ok=True)
    written = []
    for p, text in rendered:
        fname = f"V3_PROMPT_{p['code']}_{p['slug']}.txt"
        with open(os.path.join(OUT_DIR, fname), "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
        written.append((fname, text.count("\n"), len(text)))

    with open(os.path.join(OUT_DIR, "README_V3_KAMPANIA_GLM52.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write(readme_text)

    print(f"\nZapisano {len(written)} promptów + README do: JDG/prompty_v3/")
    lo = min(w[1] for w in written)
    hi = max(w[1] for w in written)
    cmin = min(w[2] for w in written)
    print(f"Linie: min={lo}, max={hi}; znaki: min={cmin}.")
    for fname, nlines, nchars in written:
        print(f"  {fname}: {nlines} linii, {nchars} znaków")
    print(f"\nKampania gotowa. Wklejaj prompty do GLM 5.2 pojedynczo, w czystych sesjach, wg kolejności P00 → {final_code}.")


if __name__ == "__main__":
    main()
