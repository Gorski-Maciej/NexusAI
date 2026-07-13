# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Rule Metadata + Temporal Validity
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: Rule Metadata Registry — Versioning, Temporal Validity, Severity, Remediation
# description: |
#   Centralny rejestr metadanych dla wszystkich reguł JDG. Zawiera:
#   - rules_metadata: mapowanie rule_id → {version, severity, remediation, references}
#   - temporal_validity: per-rule valid_from / valid_to (Polski Ład, KSeF, ZUS, SLIM VAT 3)
#   - policy_version: wersja całego pakietu JDG (YYYY.MM.DD)
#   - Helpers: get_rule_metadata(), get_rule_severity(), is_temporal_rule(),
#     get_rule_validity(), all_registered_rules(), all_temporal_rules()
#   Używany przez wszystkie pakiety poprzez `import data.jdg.metadata`.
#   `import data.jdg.helpers` importuje z powrotem `import data.jdg.metadata`
#   dla helpers.is_active(rule_id, date_str) — bezpieczne (brak cyklu).
# architecture: Single Source of Truth (SSoT) dla metadanych reguł
#   + Temporal Bundle Routing (zgodne z Doc 34 §0.1 Temporalność)
# legal_basis: N/A (metadata — nie zawiera reguł podatkowych)
# edge_cases:
#   - Niezarejestrowane rule_id → get_rule_metadata/validity zwracają {} / null
#   - Brak wpisu w temporal_validity = reguła ZAWSZE AKTYWNA (wariant A — bezpieczny dla wstecznej kompatybilności)
#   - valid_to == null = obowiązuje do odwołania (open-ended)
#   - data ISO YYYY-MM-DD porównywana leksykograficznie (Rego >= dla stringów
#     działa poprawnie dla formatu ISO — potwierdzone przez istniejący kod
#     w validation.rego R0620: inv_date >= "2026-02-01")
# package: jdg.metadata
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.metadata

# ── Policy Version ────────────────────────────────────────────────────────────

policy_version := "2026.07.10"

# ── Rules Metadata Registry ───────────────────────────────────────────────────

rules_metadata := {
    # ── Risk Rules (P0-P9) ──
    "jdg.risk.fraud_graph_match": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "CRITICAL",
        "category": "FRAUD",
        "framework": ["VAT_COMPLIANCE", "JDG_SAFETY"],
        "remediation": "Zweryfikuj kontrahenta w grafie fraudowym VAT i zgłoś do KAS",
        "references": ["Art. 86 ust. 1 VAT", "Art. 55 KKS", "Doc 34 Sec 4.1"]
    },
    "jdg.risk.counterparty_trust_low": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "MEDIUM",
        "category": "RISK",
        "framework": ["VAT_COMPLIANCE", "JDG_SAFETY"],
        "remediation": "Zweryfikuj wiarygodność kontrahenta przed księgowaniem",
        "references": ["Art. 22 UoR", "Doc 34 Sec 4.1"]
    },

    # ── Allowances Rules (P600-P635) ──
    "jdg.allowances.relief_rd_centrum": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "INFO",
        "category": "TAX_ALLOWANCE",
        "framework": ["PIT_COMPLIANCE", "JDG_ALLOWANCES"],
        "remediation": "Ulga B+R 200% — wymagany status Centrum B+R",
        "references": ["Art. 26e ust. 10 PIT", "jdg.pit.a26e.r1-r15"]
    },
    "jdg.allowances.relief_rd_standard": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "INFO",
        "category": "TAX_ALLOWANCE",
        "framework": ["PIT_COMPLIANCE", "JDG_ALLOWANCES"],
        "remediation": "Ulga B+R 100% — odliczenie kosztów kwalifikowanych od dochodu",
        "references": ["Art. 26e ust. 1 PIT", "jdg.pit.a26e.r1-r15"]
    },
    "jdg.allowances.relief_ikze": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "INFO",
        "category": "TAX_ALLOWANCE",
        "framework": ["PIT_COMPLIANCE", "JDG_ALLOWANCES"],
        "remediation": "IKZE — odliczenie wpłat od dochodu (tylko w zeznaniu rocznym)",
        "references": ["Art. 26 ust. 1 pkt 2b PIT", "jdg.pit.a26b.r1-r6"]
    },
    "jdg.allowances.relief_ip_box": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "INFO",
        "category": "TAX_ALLOWANCE",
        "framework": ["PIT_COMPLIANCE", "JDG_ALLOWANCES"],
        "remediation": "IP Box — 5% od dochodów z kwalifikowanego IP (wymagana ewidencja + Nexus)",
        "references": ["Art. 30ca PIT", "jdg.pit.a30ca.r1-r10"]
    },
    "jdg.allowances.crypto_income_classification": {
        "version": "1.0.0",
        "author": "NexusAI JDG Team",
        "last_updated": "2026-07-10",
        "severity": "HIGH",
        "category": "TAX_CLASSIFICATION",
        "framework": ["PIT_COMPLIANCE", "JDG_SAFETY"],
        "remediation": "Krypto — kapitały pieniężne 19%, NIE łączy się z JDG!",
        "references": ["Art. 30b ust. 1 pkt 1 PIT", "Doc 34 Sec 4.7"]
    }
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# Pobiera metadane dla konkretnej reguły
get_rule_metadata(rule_id) = metadata {
    metadata := object.get(rules_metadata, rule_id, {})
}

# Pobiera severity reguły
get_rule_severity(rule_id) = severity {
    severity := object.get(object.get(rules_metadata, rule_id, {}), "severity", "UNKNOWN")
}

# Lista wszystkich zarejestrowanych rule_id
all_registered_rules = keys {
    keys := object.keys(rules_metadata)
}

# ════════════════════════════════════════════════════════════════════════════════
# TEMPORAL VALIDITY REGISTRY
# ════════════════════════════════════════════════════════════════════════════════
# Per-rule okres obowiązywania. Reguła bez wpisu = ALWAYS ACTIVE (wariant A).
# Daty w formacie ISO YYYY-MM-DD. Porównywanie leksykograficzne (string sort).
#
# Źródła prawne skrótowo:
# - Polski Ład 2022 (Ustawa z 29.10.2021 o zmianie ustawy o PIT i ustawy o świadczeniach)
#   → valid_from: "2022-01-01" — Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych
#                  → valid_from: "2022-04-01" — Art. 36a SUS (zawieszenie JDG, zdrowotna NADAL)
# - KSeF (Ustawa z 16.06.2023 o zmianie ustawy o VAT, Art. 106na-106nq)
#   → valid_from: "2026-02-01" (B2B; wg aktualnego harmonogramu MF)
# - Mały ZUS Plus (Art. 18c ustawy o SUS) → valid_from: "2019-04-01"
# - Ulga na start (Art. 18a ustawy o SUS) → valid_from: "2018-04-01" (z nowelizacji)
# - SLIM VAT 3 (Ustawa z 26.05.2023) → valid_from: "2023-07-01" — Art. 89a VAT 150 dni
# ════════════════════════════════════════════════════════════════════════════════

temporal_validity := {
    # ── P914 / R0582 — ZUS w zawieszeniu JDG (Art. 36a SUS) ────────────────
    # Polski Ład 2022 zmienił Art.36a: społeczne=0, ale zdrowotna NADAL należna.
    "jdg.business.suspension_zus": {
        "valid_from": "2022-04-01",
        "valid_to": null,
        "reason": "P914 — ZUS w zawieszeniu. DEPRECATED → R0582 (zdrowotna NADAL należna)",
        "supersedes": null
    },
    "jdg.edge_cases.zus_declaration_zero_on_suspension": {
        "valid_from": "2022-04-01",
        "valid_to": null,
        "reason": "R0582 — kanoniczna wersja P914; Art.36a SUS (społeczne=0, zdrowotna=NADAL) — Dz.U. 2022 poz. 1740 (Polski Ład 2.0)",
        "supersedes": "P914"
    },

    # ── Polski Ład 2022-01-01 — Składka zdrowotna (Art. 81 ustawy o świadczeniach) ──
    "jdg.zus.health_scale": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Polski Ład: 9% od dochodu, NIE podlega odliczeniu od PIT na skali",
        "supersedes": null
    },
    "jdg.zus.health_linear": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Polski Ład: 4.9% od dochodu, odliczenie max 12900 PLN/rok",
        "supersedes": null
    },
    "jdg.zus.health_lump_sum": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Polski Ład: składka ryczałtowa w 3 progach (60k/300k przeciętnego wynagrodzenia)",
        "supersedes": null
    },
    "jdg.edge_cases.pit_health_contrib_scale_9pct_no_deduction": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "R0573 — Polski Ład: 9% zdrowotnej NIE odlicza się od PIT na skali",
        "supersedes": null
    },
    "jdg.edge_cases.pit_linear_health_underpayment": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "R0563 — liniowy: limit odliczenia zdrowotnej 12900 PLN/rok (Polski Ład)",
        "supersedes": null
    },
    "jdg.edge_cases.pit_lump_sum_health_progressive": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "R0564 — ryczałt: progi zdrowotnej dla 3 progów (Polski Ład)",
        "supersedes": null
    },

    # ── KSeF 2026-02-01 — Obowiązkowy KSeF dla B2B (Art. 106na-106nq VAT) ─────
    "jdg.validation.ksef_upo_required": {
        "valid_from": "2026-02-01",
        "valid_to": null,
        "reason": "R0620 — KSeF obowiązkowy; wymagane UPO dla faktur B2B (Art.106na VAT)",
        "supersedes": null
    },
    "jdg.edge_cases.sanction_ksef_missing_100pct": {
        "valid_from": "2026-02-01",
        "valid_to": null,
        "reason": "R0647 — sankcja 100% VAT (max 500k) za brak faktury w KSeF (Art. 106nq VAT)",
        "supersedes": null
    },
    "jdg.edge_cases.deadline_ksef_offline_7_days": {
        "valid_from": "2026-02-01",
        "valid_to": null,
        "reason": "R0666 — awaria KSeF: 7 dni na przesłanie faktur (Art. 106ne VAT)",
        "supersedes": null
    },

    # ── ZUS — Ulgi od art. 18a / 18c SUS ──────────────────────────────────
    "jdg.zus.start_relief": {
        "valid_from": "2018-04-01",
        "valid_to": null,
        "reason": "P740 — ulga na start (6 mies.) — Art. 18a ustawy o SUS (wprowadzona 2018-04-01)",
        "supersedes": null
    },
    "jdg.zus.maly_plus": {
        "valid_from": "2019-04-01",
        "valid_to": null,
        "reason": "P741 — Mały ZUS Plus (36 mies.) — Art. 18c ustawy o SUS (wprowadzony 2019-04-01)",
        "supersedes": null
    },
    "jdg.zus.preferential": {
        "valid_from": "2018-04-01",
        "valid_to": null,
        "reason": "P742 — preferencyjny ZUS (24 mies.) — Art. 18a ustawy o SUS",
        "supersedes": null
    },

    # ── SLIM VAT 3 (2023-07-01) — ulga na złe długi 150 dni (Art. 89a VAT) ──
    "jdg.edge_cases.sanction_bad_debt_debtor_30pct": {
        "valid_from": "2023-07-01",
        "valid_to": null,
        "reason": "R0652 — sankcja 30% VAT dla dłużnika; obowiązek korekty po 90 dniach (Art.89b) od 2023-07-01",
        "supersedes": null
    }
}

# ── Temporal Validity Helpers ────────────────────────────────────────────────

# Czy reguła ma wpis w rejestrze temporalności (jest "temporalna")
is_temporal_rule(rule_id) {
    temporal_validity[rule_id]
}

# Lista wszystkich temporalnych rule_id
all_temporal_rules = keys {
    keys := object.keys(temporal_validity)
}

# Pobiera okres obowiązywania reguły ({} jeśli brak wpisu)
get_rule_validity(rule_id) = v {
    not is_temporal_rule(rule_id)
    v := {}
}

get_rule_validity(rule_id) = v {
    is_temporal_rule(rule_id)
    v := temporal_validity[rule_id]
}
