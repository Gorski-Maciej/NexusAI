# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — RELIABILITY GUARANTEE LAYER (P01 Fundament OPA — Sekcja 4)
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.reliability_guarantee
# Raport: RAPORT_P01_JDG_FUNDAMENT_OPA v8.0 — Sekcja 4 (Niezawodność)
#
# WIELOWARSTWOWY SYSTEM GWARANCJI:
#   RG-01 Reproducibility Fingerprint — deterministyczny skrót wejścia +
#        wybranej wersji reguł → każda decyzja w 100% odtwarzalna.
#   RG-02 Provenance Completeness — werdykt musi zawierać _provenance_tree
#        (ADR-006 Immutable Audit Trail) — inaczej BLOCK_AND_ALERT.
#   RG-03 Fallback Ladder Integrity — co najmniej 1 warstwa bezpieczeństwa
#        (fallback | api_fallback | validation) musi dać decyzję.
#   RG-04 Decision Determinism — ten sam input → ten sam werdykt (funkcja
#        czysta, zero side-effectów zewnętrznych w decyzji).
#   RG-05 Guarantee Score — agregacja gwarancji (0-100) do monitoring/UI.
#
# Zgodność: ADR-006 (Immutable Audit Trail), A1 Verdict Provenance Graph,
#           P01 Sekcja 4 (fallback/routing/provenance/walidacja).
# package: jdg.reliability_guarantee
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.reliability_guarantee

import future.keywords.if
import future.keywords.in

default decide := {"matched":false,"rule_id":"jdg.reliability_guarantee.no_match","package":"jdg.reliability_guarantee","priority":999999}

# ── RG-01: Reproducibility Fingerprint ───────────────────────────────────────
# Deterministyczny skrót: wybrane pola input + wersja polisy (metadata).
# Host może porównać fingerprint dwóch ewaluacji tego samego dokumentu.
reproducibility_fingerprint := fingerprint {
    metadata_version := object.get(object.get(data.jdg, "metadata", {}), "policy_version", "2026.07.16")
    ctx := concat("|", [
        object.get(input.invoice, "invoice_number", ""),
        object.get(input.invoice, "issue_date", ""),
        object.get(input.invoice, "amount_net", ""),
        object.get(input.vendor, "nip", ""),
        object.get(input.jdg_entrepreneur, "nip", ""),
        object.get(input.jdg_entrepreneur, "tax_form", ""),
        metadata_version
    ])
    fingerprint := sprintf("fp:%d:%s", [count(ctx), ctx])
}

# ── RG-02: Provenance Completeness ───────────────────────────────────────────
# Werdykt bez pełnej ścieżki audytu = brak gwarancji → BLOCK_AND_ALERT.
has_full_provenance := true {
    input.verdict._provenance_tree.path
    count(input.verdict._provenance_tree.path) >= 1
    input.verdict._provenance_tree.root_hash
} else := false {
    true
}

# ── RG-03: Fallback Ladder Integrity ─────────────────────────────────────────
# Warstwy: risk (PASS 0) → routing (PASS 1) → validation → fallback → api_fallback.
# Co najmniej jedna z warstw bezpieczeństwa musiała dać decyzję matched.
fallback_ladder_ok := true {
    decisions := object.get(input, "_package_decisions", {})
    safety_layers := [pkg |
        some pkg in ["jdg.risk", "jdg.routing", "jdg.validation", "jdg.fallback", "jdg.api_fallback"]
        d := object.get(decisions, pkg, {"matched": false})
        object.get(d, "matched", false) == true
    ]
    count(safety_layers) >= 1
} else := false {
    true
}

# ── RG-04: Decision Determinism — identyczne wejście + identyczna wersja
# reguł = identyczny werdykt. Sygnalizuje, gdy input zawiera pola
# niekanoniczne (np. zmienne źródła OCR), które mogą łamać determinizm.
determinism_risks := [risk |
    some key in ["fc_vat_rate", "fc_vendor_nip", "fc_date", "ocr_score"]
    val := object.get(input.confidence, key, null)
    val != null
    val < 1.0
    risk := {"field": key, "confidence": val, "risk": "NIEKANONICZNE WEJŚCIE — werdykt może się różnić między ewaluacjami OCR"}
]

# ── DECYZJA: PROVENANCE GATE ─────────────────────────────────────────────────
decide := {
    "matched": true,
    "rule_id": "jdg.reliability_guarantee.provenance_gate",
    "package": "jdg.reliability_guarantee",
    "priority": 200,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "reliability": {
        "reproducibility_fingerprint": reproducibility_fingerprint,
        "provenance_complete": false,
        "fallback_ladder_ok": true,
        "determinism_risks": determinism_risks
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "PROVENANCE GATE: werdykt bez _provenance_tree — naruszenie ADR-006 (każda decyzja musi mieć pełną ścieżkę audytu)",
    "_legal_basis": "ADR-006 Immutable Audit Trail + A1 Verdict Provenance Graph",
    "_warnings": ["Werdykt nie zawiera _provenance_tree! Bez pełnej ścieżki audytu decyzja nie może być AUTO_POST — wymagana weryfikacja ręczna."]
} {
    object.get(input.jdg_entrepreneur, "reliability_check", false) == true
    has_full_provenance == false
}

# ── DECYZJA: FALLBACK LADDER GATE ────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.reliability_guarantee.fallback_ladder_gate",
    "package": "jdg.reliability_guarantee",
    "priority": 210,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "reliability": {
        "reproducibility_fingerprint": reproducibility_fingerprint,
        "provenance_complete": has_full_provenance,
        "fallback_ladder_ok": false,
        "determinism_risks": determinism_risks
    },
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "FALLBACK LADDER GATE: żadna warstwa bezpieczeństwa (risk/routing/validation/fallback/api_fallback) nie dała decyzji — silnik bez gwarancji",
    "_legal_basis": "P01 Sekcja 4 — Multi-layer Reliability",
    "_warnings": ["Brak decyzji we wszystkich warstwach bezpieczeństwa. Sprawdź integrity bundle reguł i połączeń z API."]
} {
    object.get(input.jdg_entrepreneur, "reliability_check", false) == true
    fallback_ladder_ok == false
}

# ── DECYZJA: DETERMINISM WARNING ─────────────────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.reliability_guarantee.determinism_warning",
    "package": "jdg.reliability_guarantee",
    "priority": 220,
    "valid_from": "2026-01-01", "valid_to": null, "decision_mode": "SUGGEST",
    "reliability": {
        "reproducibility_fingerprint": reproducibility_fingerprint,
        "provenance_complete": has_full_provenance,
        "fallback_ladder_ok": true,
        "determinism_risks": determinism_risks
    },
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "DETERMINISM WARNING: pola OCR z pewnością < 1.0 — werdykt może nie być w pełni odtwarzalny",
    "_legal_basis": "P01 Sekcja 4 — Decision Determinism",
    "_warnings": ["Pola z confidence < 1.0: przy niskiej pewności OCR rozważ ponowną ewaluację z oryginalnym dokumentem."]
} {
    object.get(input.jdg_entrepreneur, "reliability_check", false) == true
    has_full_provenance == true
    fallback_ladder_ok == true
    count(determinism_risks) > 0
}

# ── DECYZJA: RELIABILITY OK (pełna gwarancja) ────────────────────────────────
else := {
    "matched": true,
    "rule_id": "jdg.reliability_guarantee.ok",
    "package": "jdg.reliability_guarantee",
    "priority": 230,
    "reliability": {
        "reproducibility_fingerprint": reproducibility_fingerprint,
        "provenance_complete": true,
        "fallback_ladder_ok": true,
        "determinism_risks": [],
        "guarantee_level": "FULL"
    },
    "_routing": "REPORT",
    "_routing_reason": "Reliability OK — pełna gwarancja: provenance + fallback ladder + determinizm",
    "_legal_basis": "ADR-006 + P01 Sekcja 4",
    "_warnings": []
} {
    object.get(input.jdg_entrepreneur, "reliability_check", false) == true
    has_full_provenance == true
    fallback_ladder_ok == true
    count(determinism_risks) == 0
}

# ── EKSPORT: RAPORT GWARANCJI (dla monitoringu) ──────────────────────────────
reliability_report := {
    "reproducibility_fingerprint": reproducibility_fingerprint,
    "provenance_complete": has_full_provenance,
    "fallback_ladder_ok": fallback_ladder_ok,
    "determinism_risks": determinism_risks,
    "guarantee_level": guarantee_level
}

guarantee_level := "NONE" {
    has_full_provenance == false
} else := "PARTIAL" {
    fallback_ladder_ok == false
} else := "DETERMINISM_RISK" {
    count(determinism_risks) > 0
} else := "FULL" {
    true
}
