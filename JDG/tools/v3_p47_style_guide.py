#!/usr/bin/env python3
"""NexusAI JDG — V3-P47-I12 CITATION STYLE GUIDE — dokument konwencji cytowań
z przykładami poprawnych/niepoprawnych — część dokumentacji P41; kanon
wiązjący linter I02 i generator P36. Dowód: bundles/v3_p47_style_guide.json +
docs/V3_P47_CITATION_STYLE_GUIDE.md. Podanalizy: AN03.
"""
from __future__ import annotations

from pathlib import Path

from v3_p47_common import (DOCS_DIR, P47_RULE, citation_in_canon, rule_present,
                           utcnow_iso, write_bundle, write_json)

INNOVATION = "V3-P47-I12"
RULE = f"{P47_RULE}.citation_style_guide"

GUIDE_PATH = DOCS_DIR / "V3_P47_CITATION_STYLE_GUIDE.md"

VALID_EXAMPLES = [
    "Ustawa o VAT art. 109 ust. 6",
    "Ordynacja podatkowa art. 24b",
    "Ustawa o PIT art. 22a ust. 1 pkt 1",
    "Dz.U. 2024 poz. 1557 ze zm.",
    "[NIEZWERYFIKOWANE — ISAP]",
    "[BŁĄD_PODSTAWY_PRAWNEJ? — weryfikacja 4-eyes]",
]
INVALID_EXAMPLES = [
    "art. 12 i tak dalej",          # bez jednostki redakcyjnej
    "Ustawa o VAT bez artykułu",    # brak art.
    "poz. 1557",                    # publikator bez rocznika
    "art. 0",                       # artykuł niemożliwy (AP05)
]


def main() -> int:
    checks, findings = [], []

    guide_md = """# V3-P47 — KANON CYTOWAŃ PRAWNYCH (Citation Style Guide)

Status: kontrakt wyjściowy P47 (wiąże P41 dokumentacja i P36 generatory).
Zasada: TWIERDZENIE nie jest DOWODEM — każda podstawa prawna wymaga
weryfikacji w ISAP/RCL/MF i stempla 4-eyes (V3-P47-I10).

## Format kanoniczny

`<Akt — pełna nazwa> <art. N[di]> [ust. N] [pkt N | § N] [i nast]` oraz
`Dz.U. RRRR poz. N [ze zm.]` gdy publikator znany; jeśli NIE — jawny tag:

- `[NIEZWERYFIKOWANE — ISAP]` — twierdzenie czeka na weryfikację w publikatorze,
- `[BŁĄD_PODSTAWY_PRAWNEJ?]` — podejrzenie fikcji → I07 (SHADOW + RE-EXAMINE).

## Przykłady POPRAWNE

{valid}

## Przykłady NIEPOPRAWNE

{invalid}

## Zastosowanie

- Linter I02 blokuje PR z podstawami poza kanonem (0 błędów dozwolonych).
- Completeness score I08 wymaga łańcucha ≥3 jednostek: akt→art.→ust./pkt./§.
- KSeF/schematy XSD: cytuj art. ustawy o VAT (106na i nast.) [NIEZWERYFIKOWANE — ISAP].
- Wygenerowano: {now}
"""
    guide_md = guide_md.format(
        valid="\n".join(f"- `{v}`" for v in VALID_EXAMPLES),
        invalid="\n".join(f"- `{v}` — powód: brak wymaganej jednostki/publikatora" for v in INVALID_EXAMPLES),
        now=utcnow_iso(),
    )
    GUIDE_PATH.parent.mkdir(exist_ok=True)
    GUIDE_PATH.write_text(guide_md, encoding="utf-8")

    valid_ok = [v for v in VALID_EXAMPLES if citation_in_canon(v)]
    invalid_correctly_flagged = [v for v in INVALID_EXAMPLES if not citation_in_canon(v)]

    checks.append({"name": "guide_document_written", "status": "OK",
                   "detail": f"docs/V3_P47_CITATION_STYLE_GUIDE.md (kontrakt → P41/P36)"})
    checks.append({"name": "valid_examples_recognized",
                   "status": "OK" if len(valid_ok) == len(VALID_EXAMPLES) else "FAIL",
                   "detail": f"przykłady poprawne rozpoznane przez kanon: {len(valid_ok)}/{len(VALID_EXAMPLES)}"})
    checks.append({"name": "invalid_examples_rejected",
                   "status": "OK" if len(invalid_correctly_flagged) == len(INVALID_EXAMPLES) else "FAIL",
                   "detail": f"przykłady niepoprawne odrzucone przez kanon: "
                             f"{len(invalid_correctly_flagged)}/{len(INVALID_EXAMPLES)}"})

    has_rule = rule_present(RULE)
    checks.append({"name": "rule_present", "status": "OK" if has_rule else "FAIL",
                   "detail": f"reguła {RULE}: {has_rule}"})

    missing_valid = len(VALID_EXAMPLES) - len(valid_ok)
    if missing_valid:
        findings.append({"severity": "HIGH",
                         "message": f"przykłady poprawne niespójne z linterem: {missing_valid}"})

    routing = ("TRIAGE_QUEUE" if missing_valid or len(invalid_correctly_flagged) < len(INVALID_EXAMPLES)
               else "AUTO_FILE")
    metrics = {"guide_present": True, "examples_valid": len(valid_ok),
               "examples_invalid": len(INVALID_EXAMPLES) - len(invalid_correctly_flagged),
               "routing": routing}
    evidence = {"guide_path": str(GUIDE_PATH), "valid_examples": VALID_EXAMPLES,
                "invalid_examples": INVALID_EXAMPLES, "checks": checks,
                "findings": findings}
    write_bundle("style_guide", INNOVATION, metrics, evidence)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
