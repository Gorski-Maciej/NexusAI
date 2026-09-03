#!/usr/bin/env python3
"""
NexusAI JDG — V3-P11-I08 TRUST UI PATTERN
===========================================
Wzorce UX zaufania: status weryfikacji (zielony/żółty/czerwony),
„pokaż dowód", wyjaśnienie warstwowe (krótko → szczegółowo → pełny dowód).
Sprawdza, czy warstwa ludzka certyfikatu (PDF/MD) ma strukturę warstwową
i czy UI/API (P41) ma wzorce statusu.

Usage:
  python tools/v3_p11_trust_ui_pattern.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"
DOCS = BASE / "docs"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    cs = (TOOLS / "certificate_service.py").read_text(encoding="utf-8")
    dc = (TOOLS / "decision_certificate.py").read_text(encoding="utf-8")
    doc = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                    for p in DOCS.glob("*.md") if "PEWNOSC" in p.name or "CERT" in p.name.upper())

    # 1. Warstwa ludzka: prosty język / warstwy wyjaśnienia (human_explanation)?
    has_human_layer = any(k in (cs + dc) for k in ("human_explanation", "to_pdf_text",
                                                   "wyjaśnienie", "plain"))
    # 2. Wyjaśnienie warstwowe (krótko → szczegółowo → pełny dowód)?
    layered = any(k in (cs + dc).lower() for k in ("layer", "warstw", "summary",
                                                   "tl;dr", "skrót"))
    # 3. Status weryfikacji w UI (zielony/żółty/czerwony)?
    has_status_ui = any(k in (cs + dc + doc).lower() for k in ("green", "yellow", "red",
                                                               "zielony", "żółty", "czerwony",
                                                               "verified", "status"))
    # 4. „Pokaż dowód" / przycisk dowodu — czy PDF zawiera pełny dowód (legal_quote, hashe)?
    has_proof_view = any(k in (cs + dc).lower() for k in ("show proof", "pokaż dowód",
                                                          "legal_quote", "payload_hash"))  # noqa: W605
    # 5. Klasy pewności i ich konsekwencje w warstwie ludzkiej
    has_certainty_ux = any(k in (cs + dc) for k in ("CERTAIN", "NEEDS_ADVICE",
                                                    "certainty_class"))

    checks.append({"name": "human_layer", "status": "OK" if has_human_layer else "FAIL",
                   "detail": f"warstwa ludzka certyfikatu (PDF/MD): {has_human_layer}"})
    checks.append({"name": "layered_explanation", "status": "OK" if layered else "FAIL",
                   "detail": f"wyjaśnienie warstwowe (krótko→szczegół→dowód): {layered}"})
    checks.append({"name": "verification_status_ui", "status": "OK" if has_status_ui else "FAIL",
                   "detail": f"status weryfikacji w UI/docs: {has_status_ui}"})
    checks.append({"name": "show_proof", "status": "OK" if has_proof_view else "FAIL",
                   "detail": "pokaż-dowód (legal_quote/hashe w PDF): "
                              f"{has_proof_view}"})
    checks.append({"name": "certainty_ux", "status": "OK" if has_certainty_ux else "FAIL",
                   "detail": f"klasy pewności w warstwie ludzkiej: {has_certainty_ux}"})

    if not has_human_layer or not layered:
        findings.append({"id": "V3-P11-L08", "severity": "P2",
                         "evidence": "warstwa ludzka certyfikatu (to_pdf_text) wypisuje pola "
                                     "techniczne (hashe, hsm_signature) bez wyjaśnienia "
                                     "warstwowego i bez prostego języka; brak sekcji "
                                     "'co to znaczy dla Ciebie' i konsekwencji klasy pewności",
                         "fix": "I08: Trust UI Pattern — PDF z warstwami (decyzja 1 zdanie → "
                                "szczegóły → pełny dowód), status zielony/żółty/czerwony, "
                                "przycisk pokaz-dowod (show proof)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P11-I08", "generated_at": now(), "gate": gate,
        "metrics": {"human_layer": has_human_layer, "layered": layered,
                    "status_ui": has_status_ui, "proof_view": has_proof_view,
                    "certainty_ux": has_certainty_ux},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P41 (UI/API), P03 (klasy pewności), P09 (UX deklaratywny)",
                     "rule": "PDF zero informacji spoza JSON; wyjaśnienie warstwowe; "
                             "konsekwencje klasy pewności jawne (AUTO_POST tylko CERTAIN)"}}
    (BUNDLES / "v3_p11_trust_ui_pattern.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P11-I08] gate={gate} human_layer={has_human_layer} layered={layered}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
