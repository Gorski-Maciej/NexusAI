# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Rule Metadata + Temporal Validity
# ═══════════════════════════════════════════════════════════════════════════════
#
# Central metadata registry for all JDG rules.
# Contains: rules_metadata, temporal_validity, policy_version.
# Architecture: Single Source of Truth (SSoT).
# Package: jdg.metadata (imported by helpers, no imports).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.metadata

import future.keywords.in

# ── Policy Version ────────────────────────────────────────────────────────────

policy_version := "2026.07.16"

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
get_rule_metadata(rule_id) := object.get(rules_metadata, rule_id, {})

# Pobiera severity reguły
get_rule_severity(rule_id) := object.get(object.get(rules_metadata, rule_id, {}), "severity", "UNKNOWN")

# Lista wszystkich zarejestrowanych rule_id
all_registered_rules := object.keys(rules_metadata)

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
# - KSeF (Ustawa z 16.06.2023 o zmianie ustawy o VAT, Art. 106na-106ni)
#   → valid_from: "2026-02-01" (B2B; wg aktualnego harmonogramu MF)
# - Mały ZUS Plus (Art. 18c ustawy o SUS) → valid_from: "2019-04-01"
# - Ulga na start (Art. 18a ustawy o SUS) → valid_from: "2018-04-01" (z nowelizacji)
# - SLIM VAT 3 (Ustawa z 26.05.2023) → valid_from: "2023-07-01" — Art. 89a VAT 90 dni (SLIM VAT 3/2023)
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

    # ── KSeF 2026-02-01 — Obowiązkowy KSeF dla B2B (Art. 106na-106ni VAT) ─────
    "jdg.validation.ksef_upo_required": {
        "valid_from": "2026-02-01",
        "valid_to": null,
        "reason": "R0620 — KSeF obowiązkowy; wymagane UPO dla faktur B2B (Art.106na VAT)",
        "supersedes": null
    },
    "jdg.edge_cases.sanction_ksef_missing_100pct": {
        "valid_from": "2026-02-01",
        "valid_to": null,
        "reason": "R0647 — sankcja 100% VAT (max 500k) za brak faktury w KSeF (Art. 106ga ust. 1 VAT)",
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

    # ── SLIM VAT 3 (2023-07-01) — ulga na złe długi 90 dni (Art. 89a VAT) ──
    "jdg.edge_cases.sanction_bad_debt_debtor_30pct": {
        "valid_from": "2023-07-01",
        "valid_to": null,
        "reason": "R0652 — sankcja 30% VAT dla dłużnika; obowiązek korekty po 90 dniach (Art.89b) od 2023-07-01",
        "supersedes": null
    },

    # ── v7.0 ROZBUDOWA: Brakujące wpisy temporalne (Rekomendacja 5.2) ──

    # Ulga B+R (Art. 26e PIT) — wprowadzona 2018, rozszerzona 2022, 2023, 2025
    "jdg.allowances.relief_rd_standard": {
        "valid_from": "2018-01-01",
        "valid_to": null,
        "reason": "Ulga B+R 100% — Art. 26e PIT (wprowadzona 2018, rozszerzona 2022: 200% dla CBR)",
        "supersedes": null
    },
    "jdg.allowances.relief_rd_centrum": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Ulga B+R 200% dla Centrów B+R — Art. 26e ust. 10 PIT (Polski Ład 2022)",
        "supersedes": null
    },

    # IP Box (Art. 30ca PIT) — wprowadzony 2019, rozszerzenia 2022/2025
    "jdg.allowances.relief_ip_box": {
        "valid_from": "2019-01-01",
        "valid_to": null,
        "reason": "IP Box 5% od kwalifikowanego IP — Art. 30ca PIT (wprowadzony 2019, rozszerzony 2022)",
        "supersedes": null
    },

    # Exit Tax (Art. 30da PIT) — wprowadzony 2019
    "jdg.pit.exit_tax": {
        "valid_from": "2019-01-01",
        "valid_to": null,
        "reason": "Exit Tax 19% od przeniesienia aktywów za granicę — Art. 30da PIT",
        "supersedes": null
    },

    # MDR DAC6 (2021) — obowiązkowe raportowanie schematów podatkowych
    "jdg.mdr.dac6_reporting": {
        "valid_from": "2021-01-01",
        "valid_to": null,
        "reason": "MDR DAC6 — obowiązek raportowania schematów transgranicznych (Dyrektywa 2018/822, implementacja PL 2021)",
        "supersedes": null
    },

    # Tarcza COVID (2020-2021) — zwolnienia i ulgi pandemiczne
    "jdg.temporal.covid_legacy": {
        "valid_from": "2020-03-01",
        "valid_to": "2021-12-31",
        "reason": "P1617 — Tarcza COVID: zwolnienia ZUS, świadczenia postojowe, subwencje PFR (archiwalne po 2021)",
        "supersedes": null
    },

    # Art. 113 VAT — paragon z NIP limit 450 zł (2022-01-01)
    "jdg.vat.receipt_nip_limit_450": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Limit paragonu z NIP jako faktury uproszczonej: 450 PLN (od 2022-01-01, poprzednio 250 PLN)",
        "supersedes": null
    },

    # SLIM VAT 2 (2022) — uproszczenia w VAT
    "jdg.vat.slim_vat_2": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "SLIM VAT 2 — uproszczenia fakturowania, kursy walut, korekty (ustawa z 2021)",
        "supersedes": null
    },

    # SLIM VAT 3 (2023-07-01) — ulga na złe długi, WIS, faktury korygujące
    "jdg.vat.slim_vat_3": {
        "valid_from": "2023-07-01",
        "valid_to": null,
        "reason": "SLIM VAT 3 — 90 dni złe długi, WIS wiążące, faktury korygujące in minus (ustawa z 26.05.2023)",
        "supersedes": null
    },

    # Estonian CIT (2022) — CIT estoński dla JDG (spółek)
    "jdg.pit.estonian_cit": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Estoński CIT — opodatkowanie dopiero przy wypłacie zysku (Art. 24-24h CIT, rozszerzenia 2022/2025)",
        "supersedes": null
    },

    # Polski Ład — kwota wolna 30k (2022-01-01)
    "jdg.pit.tax_free_amount_30k": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Kwota wolna 30 000 PLN — Art. 27 ust. 1 PIT (Polski Ład 2022, wcześniej 8 000 PLN)",
        "supersedes": null
    },

    # Próg skali 120k (2022-01-01)
    "jdg.pit.scale_threshold_120k": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Próg skali 120 000 PLN — Art. 27 ust. 1 PIT (Polski Ład 2022, wcześniej 85 528 PLN)",
        "supersedes": null
    },

    # Limit ryczałtu 2M EUR (2022-01-01)
    "jdg.pit.lump_sum_2m_eur": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Limit ryczałtu 2 000 000 EUR — Polski Ład 2022 (wcześniej 250 000 EUR)",
        "supersedes": null
    },

    # PIT — Stawki skali: 17%/32% (2019-10-01), 18%/32% (2020), 12%/32% (2022)
    "jdg.pit.scale_rates_2019": {
        "valid_from": "2019-10-01",
        "valid_to": "2021-12-31",
        "reason": "PIT skala 17%/32% od 1.10.2019, kwota wolna 8 000 PLN (przed Polskim Ładem)",
        "supersedes": null
    },
    "jdg.pit.tax_free_30k_scale_12_32": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Polski Ład: skala 12%/32%, kwota wolna 30 000 PLN, kwota zmniejszająca 3 600 PLN",
        "supersedes": "jdg.pit.scale_rates_2019"
    },
    "jdg.pit.relief_shared_limit_85528": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Limit łączny ulg PIT-0: 85 528 PLN (mlodzi, powrot, 4+, senior)",
        "supersedes": null
    },

    # Jednorazowa amortyzacja de minimis 100k (2022)
    "jdg.accounting.depreciation_one_off_100k": {
        "valid_from": "2022-01-01",
        "valid_to": null,
        "reason": "Jednorazowa amortyzacja de minimis 100 000 PLN — Polski Ład 2022 (wcześniej 10 000 PLN)",
        "supersedes": null
    }
}

# ── Temporal Validity Helpers ────────────────────────────────────────────────

# Czy reguła ma wpis w rejestrze temporalności (jest "temporalna")
is_temporal_rule(rule_id)  if {
    temporal_validity[rule_id]
}

# Lista wszystkich temporalnych rule_id
all_temporal_rules := object.keys(temporal_validity)

# Pobiera okres obowiązywania reguły ({} jeśli brak wpisu)
# object.get zachowuje wariant A: brak wpisu = ALWAYS ACTIVE.
get_rule_validity(rule_id) := object.get(temporal_validity, rule_id, {})

# ════════════════════════════════════════════════════════════════════════════════
# A2: TEMPORAL CAUSALITY CHAIN — Time-Travel Compliance (Strategic Initiative)
# ════════════════════════════════════════════════════════════════════════════════
# Umożliwia ewaluację reguł wg STANU PRAWNEGO z dnia transakcji, nie dzisiaj.
# Kluczowe dla kontroli KAS za zaległe lata (2022-2025).
#
# Mechanizm:
#   1. is_active_for_date(rule_id, eval_date) → true/false
#   2. Reguła bez wpisu w temporal_validity = ALWAYS ACTIVE
#   3. Reguła z valid_from > eval_date → NIE obowiązywała → pomiń
#   4. Reguła z valid_to < eval_date → już nie obowiązuje → pomiń
# ════════════════════════════════════════════════════════════════════════════════

# Główna funkcja A2: sprawdza czy reguła obowiązywała w dniu transakcji
# Użycie w regułach: metadata.is_active_for_date("jdg.business.suspension_zus", input.evaluation_datetime)
is_active_for_date(rule_id, eval_date) = true {
    not is_temporal_rule(rule_id)
    # Reguła bez wpisu temporalnego = zawsze aktywna
}

is_active_for_date(rule_id, eval_date) = true {
    v := temporal_validity[rule_id]
    valid_from := object.get(v, "valid_from", "0000-01-01")
    valid_to := object.get(v, "valid_to", "9999-12-31")
    # Leksykograficzne porównanie dat ISO (YYYY-MM-DD)
    eval_date >= valid_from
    not valid_to  # null = nadal obowiązuje
}

is_active_for_date(rule_id, eval_date) = true {
    v := temporal_validity[rule_id]
    valid_from := object.get(v, "valid_from", "0000-01-01")
    valid_to := object.get(v, "valid_to", "9999-12-31")
    eval_date >= valid_from
    valid_to  # ma datę końcową
    eval_date <= valid_to
}

is_active_for_date(rule_id, eval_date) = false {
    v := temporal_validity[rule_id]
    valid_from := object.get(v, "valid_from", "9999-12-31")
    eval_date < valid_from
    # Reguła jeszcze nie obowiązywała
}

is_active_for_date(rule_id, eval_date) = false {
    v := temporal_validity[rule_id]
    valid_to := object.get(v, "valid_to", "9999-12-31")
    valid_to
    eval_date > valid_to
    # Reguła już nie obowiązuje
}

# Pobiera listę reguł aktywnych na daną datę
active_rules_for_date(eval_date) = active {
    all := object.keys(temporal_validity)
    active := [rule_id |
        some rule_id in all
        is_active_for_date(rule_id, eval_date)
    ]
}

# Pobiera listę reguł NIEAKTYWNYCH na daną datę (do logowania/warningów)
inactive_rules_for_date(eval_date) = inactive {
    all := object.keys(temporal_validity)
    inactive := [rule_id |
        some rule_id in all
        not is_active_for_date(rule_id, eval_date)
    ]
}

# ════════════════════════════════════════════════════════════════════════════════
# A3: LEGAL CARTOGRAPHY — RDF/SPARQL Ontology Mapping (Strategic Initiative)
# ════════════════════════════════════════════════════════════════════════════════
# Mapa ontologiczna łącząca artykuły ustaw z regułami JDG.
# Format: legal_provisions — każdy artykuł to węzeł, reguła to relacja.
# Umożliwia zapytania SPARQL: "Które reguły pokrywają Art. 113 VAT?"
# Prefixy: lex: (akt prawny), jdg: (reguła), cito: (cytowanie)
# ════════════════════════════════════════════════════════════════════════════════

legal_cartography := {
    # ── VAT ──
    "lex:VAT:Art5": {
        "title": "Definicja dostawy towarów",
        "jdg_rules": ["jdg.vat.a5.r1"],
        "coverage": "COMPLETE",
        "thresholds": []
    },
    "lex:VAT:Art17": {
        "title": "Reverse charge — usługi budowlane i import",
        "jdg_rules": ["jdg.vat.a17.r5", "jdg.crossborder.eu_reverse_charge"],
        "coverage": "COMPLETE",
        "thresholds": []
    },
    "lex:VAT:Art41": {
        "title": "Stawki podstawowe VAT (23%, 8%, 5%, 0%)",
        "jdg_rules": ["jdg.vat.a41.r1"],
        "coverage": "COMPLETE",
        "thresholds": ["vat_rate_standard_23", "vat_rate_reduced_8", "vat_rate_reduced_5"]
    },
    "lex:VAT:Art43": {
        "title": "Zwolnienia przedmiotowe (40 punktów)",
        "jdg_rules": ["jdg.vat.a43.r1"],
        "coverage": "PARTIAL",
        "thresholds": [],
        "gaps": ["art43_pkt10", "art43_pkt11", "art43_pkt12"]
    },
    "lex:VAT:Art86": {
        "title": "Odliczenie VAT naliczonego",
        "jdg_rules": ["jdg.vat.a86.r1"],
        "coverage": "COMPLETE",
        "thresholds": ["vat_deduction_proportion"]
    },
    "lex:VAT:Art89a": {
        "title": "Złe długi — wierzyciel (korekta in plus)",
        "jdg_rules": ["jdg.vat.a89a.r1", "jdg.conflicts.bad_debt_creditor_vat_corrected_but_not_pit"],
        "coverage": "COMPLETE",
        "thresholds": ["bad_debt_days"],
        "temporal_note": "150 dni → 90 dni (SLIM VAT 3/2023-07-01)"
    },
    "lex:VAT:Art89b": {
        "title": "Złe długi — dłużnik (korekta in minus)",
        "jdg_rules": ["jdg.vat.a89b.r1"],
        "coverage": "COMPLETE",
        "thresholds": ["bad_debt_days", "bad_debt_debtor_sanction_30pct"]
    },
    "lex:VAT:Art106e": {
        "title": "Elementy faktury (paragon ≤ 450 zł z NIP)",
        "jdg_rules": ["jdg.vat.a106e.r10"],
        "coverage": "COMPLETE",
        "thresholds": ["receipt_nip_limit"]
    },
    "lex:VAT:Art113": {
        "title": "Zwolnienie podmiotowe do 200 000 PLN",
        "jdg_rules": ["jdg.vat.a113.r1", "jdg.edge_cases.vat_breach_mid_year"],
        "coverage": "COMPLETE",
        "thresholds": ["vat_subject_exemption_limit"]
    },

    # ── PIT ──
    "lex:PIT:Art14": {
        "title": "Przychody z działalności gospodarczej",
        "jdg_rules": ["jdg.pit.a14.r1", "jdg.pit.forms.pit_revenue_exclusions"],
        "coverage": "COMPLETE",
        "thresholds": []
    },
    "lex:PIT:Art22": {
        "title": "Koszty uzyskania przychodu",
        "jdg_rules": ["jdg.pit.a22.r1", "jdg.pit.kup.direct_vs_indirect"],
        "coverage": "COMPLETE",
        "thresholds": ["kup_direct_revenue_year", "kup_indirect_invoice_date"]
    },
    "lex:PIT:Art23": {
        "title": "Wydatki niestanowiące KUP (NKUP)",
        "jdg_rules": ["jdg.pit.a23.r1"],
        "coverage": "PARTIAL",
        "thresholds": [],
        "gaps": ["art23_pkt23_representation_detail", "art23_pkt46_car_75pct", "art23_pkt47_lease_limit"]
    },
    "lex:PIT:Art27": {
        "title": "Skala podatkowa 12%/32%",
        "jdg_rules": ["jdg.pit.a27.r1", "jdg.pit.forms.scale"],
        "coverage": "COMPLETE",
        "thresholds": ["pit_scale_threshold", "pit_scale_low_rate", "pit_scale_high_rate", "pit_tax_free_amount"]
    },
    "lex:PIT:Art30c": {
        "title": "Podatek liniowy 19%",
        "jdg_rules": ["jdg.pit.a30c.r1", "jdg.pit.forms.linear"],
        "coverage": "COMPLETE",
        "thresholds": ["pit_linear_rate", "linear_former_employer_block_years"]
    },
    "lex:PIT:Art30ca": {
        "title": "IP Box — 5% od kwalifikowanego IP",
        "jdg_rules": ["jdg.pit.a30ca.r1"],
        "coverage": "COMPLETE",
        "thresholds": ["ip_box_rate", "nexus_indicator_required"]
    },
    "lex:PIT:Art30f": {
        "title": "CFC — zagraniczna spółka kontrolowana",
        "jdg_rules": ["jdg.crossborder.cfc_jdg_controlled"],
        "coverage": "COMPLETE",
        "thresholds": ["cfc_control_threshold_50pct", "cfc_passive_income_33pct"]
    },
    "lex:PIT:Art30da": {
        "title": "Exit Tax — przeniesienie aktywów za granicę",
        "jdg_rules": ["jdg.pit.a30da.r1"],
        "coverage": "COMPLETE",
        "thresholds": ["exit_tax_rate_19pct"],
        "temporal_note": "Obowiązuje od 2019-01-01"
    },

    # ── MDR DAC6 / SLIM VAT 2/3 / Estonian CIT / Polski Ład ──
    "lex:OP:Art86a-86o": {
        "title": "MDR DAC6 — raportowanie schematów podatkowych",
        "jdg_rules": ["jdg.mdr.dac6_reporting"],
        "coverage": "COMPLETE",
        "thresholds": ["mdr_daily_penalty", "mdr_sanction_max"],
        "temporal_note": "Obowiązuje od 2021-01-01"
    },
    "lex:VAT:SLIM2": {
        "title": "SLIM VAT 2 — uproszczenia fakturowania, kursy walut",
        "jdg_rules": ["jdg.vat.slim_vat_2"],
        "coverage": "PARTIAL",
        "thresholds": [],
        "temporal_note": "Obowiązuje od 2022-01-01"
    },
    "lex:VAT:SLIM3": {
        "title": "SLIM VAT 3 — złe długi 90 dni, WIS",
        "jdg_rules": ["jdg.vat.slim_vat_3"],
        "coverage": "COMPLETE",
        "thresholds": ["bad_debt_days"],
        "temporal_note": "Obowiązuje od 2023-07-01"
    },
    "lex:CIT:Art24-24h": {
        "title": "Estoński CIT",
        "jdg_rules": ["jdg.pit.estonian_cit"],
        "coverage": "PARTIAL",
        "thresholds": [],
        "temporal_note": "Obowiązuje od 2022-01-01"
    },
    "lex:PIT:Art27_kwota_wolna": {
        "title": "Kwota wolna 30 000 PLN",
        "jdg_rules": ["jdg.pit.tax_free_amount_30k"],
        "coverage": "COMPLETE",
        "thresholds": ["tax_free_amount"],
        "temporal_note": "30k od 2022 (Polski Ład)"
    },
    "lex:PIT:Art27_prog": {
        "title": "Próg skali 120 000 PLN",
        "jdg_rules": ["jdg.pit.scale_threshold_120k"],
        "coverage": "COMPLETE",
        "thresholds": ["scale_threshold"],
        "temporal_note": "120k od 2022 (Polski Ład)"
    },
    "lex:PIT:Art6_ryczalt": {
        "title": "Limit ryczałtu 2M EUR",
        "jdg_rules": ["jdg.pit.lump_sum_2m_eur"],
        "coverage": "COMPLETE",
        "thresholds": ["lump_sum_annual_eur"],
        "temporal_note": "2M EUR od 2022"
    },
    "lex:PIT:Art22k": {
        "title": "Amortyzacja de minimis 100k PLN",
        "jdg_rules": ["jdg.accounting.depreciation_one_off_100k"],
        "coverage": "COMPLETE",
        "thresholds": ["one_off_de_minimis_limit"],
        "temporal_note": "100k od 2022 (Polski Ład)"
    },

    # ── KKS ──
    "lex:KKS:Art54": {
        "title": "Ulga na start (6 mies.)",
        "jdg_rules": ["jdg.sus.a18a.r1"],
        "coverage": "COMPLETE",
        "thresholds": ["start_relief_months"]
    },
    "lex:SUS:Art18c": {
        "title": "Mały ZUS Plus (36 mies.)",
        "jdg_rules": ["jdg.sus.a18c.r1"],
        "coverage": "COMPLETE",
        "thresholds": ["maly_zus_plus_months", "maly_zus_plus_income_limit"]
    },
    "lex:SUS:Art36a": {
        "title": "Zawieszenie JDG a składki",
        "jdg_rules": ["jdg.sus.a36a.r1", "jdg.business.suspension_zus"],
        "coverage": "COMPLETE",
        "thresholds": ["suspension_social_zero", "suspension_health_still_due"]
    },

    # ── Ordynacja Podatkowa ──
    "lex:OP:Art70": {
        "title": "Przedawnienie zobowiązań (5 lat)",
        "jdg_rules": ["jdg.ord.a70.r1", "jdg.liability.statute_5_years"],
        "coverage": "COMPLETE",
        "thresholds": ["statute_of_limitations_years"]
    },
    "lex:OP:Art81": {
        "title": "Korekty deklaracji",
        "jdg_rules": ["jdg.ord.a81.r1", "jdg.corrections.vat_declaration_period"],
        "coverage": "COMPLETE",
        "thresholds": []
    },
    "lex:OP:Art117ba": {
        "title": "Biała Lista — weryfikacja rachunku",
        "jdg_rules": ["jdg.ord.a117ba.r1"],
        "coverage": "COMPLETE",
        "thresholds": ["whitelist_verification_days"]
    },

    # ── KKS ──
    "lex:KKS:Art54": {
        "title": "Podanie nieprawdy w deklaracji",
        "jdg_rules": ["jdg.kks.a54.r1"],
        "coverage": "PARTIAL",
        "thresholds": [],
        "gaps": ["kks_art54_penalty_graduation", "kks_art54_materiality_threshold"]
    },
    "lex:KKS:Art62": {
        "title": "Pusta faktura / szara strefa",
        "jdg_rules": ["jdg.kks.a62.r7"],
        "coverage": "COMPLETE",
        "thresholds": ["empty_invoice_sanction_30pct"]
    }
}

# ── Legal Cartography Helpers ──────────────────────────────────────────────

# Znajdź wszystkie reguły pokrywające dany artykuł
rules_for_provision(provision_id) = rules {
    provision := legal_cartography[provision_id]
    rules := provision.jdg_rules
} else = [] {
    true
}

# Sprawdź czy artykuł ma pełne pokrycie
is_fully_covered(provision_id) = true {
    legal_cartography[provision_id].coverage == "COMPLETE"
}

# Lista artykułów z niepełnym pokryciem
gaps_in_coverage = gaps {
    gaps := [prov |
        some prov in object.keys(legal_cartography)
        legal_cartography[prov].coverage != "COMPLETE"
    ]
}
