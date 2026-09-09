# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P44 CERTYFIKACJA FINALNA FORTECY — ZAMKNIĘCIE KAMPANII V3
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa certyfikacji finalnej ENTERPRISE — 12 analiz (I01–I12; minimum z
# promptu P44 Sekcja 10):
#   I01 Hard Gate Certificate (certyfikat wyłącznie gdy wszystkie bramki twarde
#       zamknięte; otwarta luka P0 lub gate=false = NO_CERT z listą; zero
#       marketingu; produkcja zawsze NOT_CERTIFIED bez telemetrii zewn.),
#   I02 Filar Scoreboard (Legal Twin / Golden Oracle / Decision Certificate /
#       Law Radar / Declarative Change / Runtime Invariants: status
#       DOWIEDZONE/CZĘŚCIOWE/DEKLAROWANE z dowodem; filar DEKLAROWANE bez
#       planu = BLOCK; bez dowodu = TRIAGE),
#   I03 Campaign Aggregate Ledger (agregacja luk z raportów V3 z deduplikacją
#       po kluczu luki; duplikat bez scalenia = TRIAGE; agregat bez P0 = BLOCK),
#   I04 Owner Decision Map (mapa decyzyjna właściciela: działanie → zależności →
#       kto decyduje → priorytet; P0 bez przypisanej decyzji = BLOCK),
#   I05 V4 Inheritance Contract (kontrakty dziedziczone z V3 do V4: standard,
#       schemat, bramka; kontrakt bez source_of_truth = TRIAGE),
#   I06 Success Metric Freeze (definicja sukcesu jako dane: metryka + próg +
#       źródło pomiaru ZANIM certyfikacja; metryka bez progu = BLOCK),
#   I07 Certificate WORM + Signature (certyfikat finalny podpisany i w WORM z
#       retencją ≥ 5 lat (UoR art. 74-75 [NIEZWERYFIKOWANE]); brak podpisu =
#       BLOCK; brak WORM = BLOCK; retencja < próg = BLOCK),
#   I08 Knowledge Transfer Pack (pakiet przekazania: dokumenty, runbooki,
#       rejestry, kontakty decyzyjne; brakujący artefakt = TRIAGE),
#   I09 Certification Renewal Policy (certyfikat wygasa: nowelizacja, deploy
#       krytyczny, czas (progi dni); brak polityki wygaśnięcia = BLOCK;
#       odnowienie bez dowodu = TRIAGE),
#   I10 Legacy Cleanup Closure (finałowe zamknięcie fasad/martwych artefaktów
#       z P30/P36/P42; otwarte fasady > próg = TRIAGE),
#   I11 Owner Attestation (właściciel potwierdza przyjęcie certyfikatu z listą
#       zastrzeżeń — 4-eyes po stronie biznesowej; brak atestu = TRIAGE),
#   I12 Fortress Self-Portrait (auto-portret: komponent → kontrakt → dowód;
#       komponent bez dowodu = TRIAGE).
#
# Podanalizy (prompt P44 Sekcja 5):
#   AN01 rozliczenie filarów dokumentów świętych → I02, I06
#   AN02 rejestry luk i priorytetyzacja → I03, I04, I10
#   AN03 certyfikat finalny i hard gates → I01, I07, I09, I11
#   AN04 ścieżka V4 i dziedzictwo → I05, I08, I12
#
# Integracje (kontrakty między-częściowe):
#   * P00–P43 — kontrakty wyjściowe (lista w raporcie finalnym; I05),
#   * P42 — maturity ladder L0–L5 + zero_defect (I02; kontrakt K1),
#   * P43 — kontrakt K1–K5: rejestr security/DR dla P44 (I03/I08; kontrakt
#     wejściowy), tamper test (I07),
#   * P37 — metryki SLO + dashboardy (I06, I09; progi odnowienia),
#   * P38 — WORM + podpisy deploy (I07; ten sam łańcuch zaufania),
#   * P39 — testy jako bramki (I01; kontrola bramek w CI),
#   * P30/P36/P42 — rejestr fasad/martwych artefaktów (I10),
#   * UoR art. 74–75, RODO art. 5.2/24, eIDAS — podpis i retencja certyfikatu
#     [NIEZWERYFIKOWANE — ISAP pełnym skanem nie wykonano w tej sesji].
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p44 (rdzeń) — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * FAIL-CLOSED (V1 zasada 6): otwarta luka P0, brak podpisu/WOM, metryka
#     bez progu, brak polityki odnowienia = NO_CERT/BLOCK — nigdy cichy
#     certyfikat „na wrażenie”.
#   * Honesty: produkcja pozostaje NOT_CERTIFIED (dziedziczone z
#     final_certification_v4_gate.py); certyfikat dotyczy STANU REPOZYTORIUM.
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji.
#   * Aktywacja: input.jdg_entrepreneur.v3_p44_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p44_certyfikacja_finalna.<reguła>.
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p44_certyfikacja_finalna
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p44_certyfikacja_finalna

import future.keywords.in

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p44_check", false) == true
_ctx := object.get(input, "v3_p44", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p44_snapshot := data.jdg.thresholds.v3_p44

_snapshot_ok = true {
    count(_p44_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p44_snapshot) > 0
    value := object.get(_p44_snapshot, key, null)
    value != null
} else = fallback

_has_flag(key) = result {
    result := object.get(_ctx, key, false) == true
} else = false {
    true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
    "matched": true,
    "rule_id": "jdg.v3_p44_certyfikacja_finalna.thresholds_missing",
    "package": "jdg.v3_p44_certyfikacja_finalna",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "CERTYFIKACJA V3-P44: brak snapshotu data.jdg.thresholds.v3_p44.",
    "_legal_basis": "ADR-002 zero-hardcode; V1 zasada 6 (fail-closed)",
    "_warnings": ["[V3-P44] Brak snapshotu progów certyfikacji — certyfikacja ZABLOKOWANA."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p44_certyfikacja_finalna",
        "priority": priority,
        "threshold_version": object.get(_p44_snapshot, "v3_p44_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p44_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p44_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I01: HARD GATE CERTIFICATE — dowód, nie deklaracja (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_gates := object.get(_ctx, "hard_gates", {})
_gates_total := count(_gates)
_gates_failed := [name |
    some name
    val := _gates[name]
    val == false
]
_gates_open_p0 := object.get(_ctx, "open_p0_gaps", 0)

routing_hg01 = "BLOCK_AND_ALERT" {
    _gates_open_p0 > 0
} else = "BLOCK_AND_ALERT" {
    count(_gates_failed) > 0
} else = "AUTO_FILE" {
    _gates_total > 0
    count(_gates_failed) == 0
} else = "SUGGEST" {
    true
}

hard_gate_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "hard_gate_certificate"
    object.get(_ctx, "analysis", "") == "hard_gate_certificate"
    routing_hg01 == "AUTO_FILE"
    cert := _certificate(444001, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.hard_gate_certificate",
        "decision_mode": "CERTIFIED",
        "_routing": routing_hg01,
        "_routing_reason": "CERTYFIKACJA: wszystkie bramki twarde zamknięte, zero luk P0.",
        "_legal_basis": "V1 zasada 6 (fail-closed); Dokument święty 2 — Decision Certificate; P39 bramki CI",
        "_warnings": ["[V3-P44] Produkcja pozostaje NOT_CERTIFIED — certyfikat dotyczy stanu repozytorium."],
        "gates_total": _gates_total,
        "gates_failed": _gates_failed,
        "open_p0_gaps": _gates_open_p0,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "hard_gate_certificate"
    routing_hg01 == "BLOCK_AND_ALERT"
    cert := _certificate(444001, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.hard_gate_certificate",
        "decision_mode": "NO_CERT",
        "_routing": routing_hg01,
        "_routing_reason": "CERTYFIKACJA: otwarte luki P0 lub niepowodzenie bramek twardych — raport braku certyfikacji z listą.",
        "_legal_basis": "V1 zasada 6; P44-I01 hard gate; P44-I03 agregat luk",
        "_warnings": ["[V3-P44] Certyfikacja ODMOWA — zobacz gates_failed/open_p0_gaps."],
        "gates_total": _gates_total,
        "gates_failed": _gates_failed,
        "open_p0_gaps": _gates_open_p0,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I02: FILAR SCOREBOARD — DOWIEDZONE/CZĘŚCIOWE/DEKLAROWANE (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_pillars := object.get(_ctx, "pillars", {})
_pillars_declared := [name |
    some name
    p := _pillars[name]
    p.status == "DEKLAROWANE"
    object.get(p, "closure_plan", "") == ""
]
_pillars_no_evidence := [name |
    some name
    p := _pillars[name]
    object.get(p, "evidence", "") == ""
]

routing_sb02 = "BLOCK_AND_ALERT" {
    count(_pillars_declared) > 0
} else = "TRIAGE_QUEUE" {
    count(_pillars_no_evidence) > 0
} else = "AUTO_FILE" {
    count(_pillars) > 0
} else = "SUGGEST" {
    true
}

pillar_scoreboard_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "pillar_scoreboard"
    object.get(_ctx, "analysis", "") == "pillar_scoreboard"
    routing_sb02 == "AUTO_FILE"
    cert := _certificate(444002, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.pillar_scoreboard",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sb02,
        "_routing_reason": "CERTYFIKACJA: każdy filar ma status z dowodem i planem domknięcia.",
        "_legal_basis": "Dokument święty 2 (Wizja V2 — filary); P44-I02; P42 maturity ladder",
        "_warnings": [],
        "pillars_total": count(_pillars),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "pillar_scoreboard"
    routing_sb02 == "BLOCK_AND_ALERT"
    cert := _certificate(444002, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.pillar_scoreboard",
        "decision_mode": "BLOCK",
        "_routing": routing_sb02,
        "_routing_reason": "CERTYFIKACJA: filar DEKLAROWANE bez planu domknięcia — certyfikacja niemożliwa.",
        "_legal_basis": "Dokument święty 2; P44-I02; zero deklaracji bez dowodu (V1)",
        "_warnings": ["[V3-P44] Filary bez planu: nie skaluj certyfikatu."],
        "pillars_without_plan": _pillars_declared,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "pillar_scoreboard"
    routing_sb02 == "TRIAGE_QUEUE"
    cert := _certificate(444002, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.pillar_scoreboard",
        "decision_mode": "TRIAGE",
        "_routing": routing_sb02,
        "_routing_reason": "CERTYFIKACJA: filar bez dowodu (status bez artefaktu).",
        "_legal_basis": "Dokument święty 2; P44-I02",
        "_warnings": ["[V3-P44] Filary bez dowodu: dołącz artefakty."],
        "pillars_without_evidence": _pillars_no_evidence,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I03: CAMPAIGN AGGREGATE LEDGER — agregacja luk z deduplikacją (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_gap_aggregate := object.get(_ctx, "gap_aggregate", {})
_gap_unique := count(object.get(_gap_aggregate, "unique_gaps", []))
_gap_dupes := count(object.get(_gap_aggregate, "duplicate_keys", []))

routing_al03 = "BLOCK_AND_ALERT" {
    object.get(_gap_aggregate, "p0_open", 0) > 0
} else = "TRIAGE_QUEUE" {
    _gap_dupes > 0
} else = "AUTO_FILE" {
    _gap_unique > 0
} else = "SUGGEST" {
    true
}

aggregate_ledger_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "campaign_aggregate_ledger"
    object.get(_ctx, "analysis", "") == "campaign_aggregate_ledger"
    routing_al03 == "AUTO_FILE"
    cert := _certificate(444003, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.campaign_aggregate_ledger",
        "decision_mode": "AUTO_POST",
        "_routing": routing_al03,
        "_routing_reason": "CERTYFIKACJA: agregat luk z deduplikacją spójny (jedna luka = jeden wpis).",
        "_legal_basis": "P44-I03; P30 rejestr wdrożeń; standard P00 (V3-<KOD>-Lxx)",
        "_warnings": [],
        "unique_gaps": _gap_unique,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "campaign_aggregate_ledger"
    routing_al03 == "BLOCK_AND_ALERT"
    cert := _certificate(444003, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.campaign_aggregate_ledger",
        "decision_mode": "BLOCK",
        "_routing": routing_al03,
        "_routing_reason": "CERTYFIKACJA: otwarte luki P0 w agregacie kampanii.",
        "_legal_basis": "V1 zasada 6; P44-I03; P44-I01 hard gate",
        "_warnings": ["[V3-P44] Luki P0 blokują certyfikację."],
        "p0_open": object.get(_gap_aggregate, "p0_open", 0),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "campaign_aggregate_ledger"
    routing_al03 == "TRIAGE_QUEUE"
    cert := _certificate(444003, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.campaign_aggregate_ledger",
        "decision_mode": "TRIAGE",
        "_routing": routing_al03,
        "_routing_reason": "CERTYFIKACJA: duplikaty kluczy luk nie scalone w agregacie.",
        "_legal_basis": "P44-I03; deduplikacja po kluczu luki",
        "_warnings": ["[V3-P44] Zduplikowane klucze luk — scal wpisy."],
        "duplicate_keys": _gap_dupes,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I04: OWNER DECISION MAP — działanie→zależności→kto decyduje→priorytet (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_decision_map := object.get(_ctx, "owner_decision_map", [])
_map_p0_unassigned := [row |
    some row
    r := _decision_map[row]
    r.priority == "P0"
    object.get(r, "decision_owner", "") == ""
]

routing_dm04 = "BLOCK_AND_ALERT" {
    count(_map_p0_unassigned) > 0
} else = "AUTO_FILE" {
    count(_decision_map) > 0
} else = "SUGGEST" {
    true
}

owner_decision_map_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "owner_decision_map"
    object.get(_ctx, "analysis", "") == "owner_decision_map"
    routing_dm04 == "AUTO_FILE"
    cert := _certificate(444004, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.owner_decision_map",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dm04,
        "_routing_reason": "CERTYFIKACJA: mapa decyzyjna właściciela kompletna (każdy wiersz ma decydenta).",
        "_legal_basis": "P44-I04; 4-eyes (P43 dual-control) po stronie biznesowej",
        "_warnings": [],
        "rows": count(_decision_map),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "owner_decision_map"
    routing_dm04 == "BLOCK_AND_ALERT"
    cert := _certificate(444004, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.owner_decision_map",
        "decision_mode": "BLOCK",
        "_routing": routing_dm04,
        "_routing_reason": "CERTYFIKACJA: pozycja P0 bez przypisanego decydenta — nie da się zamknąć kampanii.",
        "_legal_basis": "P44-I04; V1 zasada 6",
        "_warnings": ["[V3-P44] Wiersze P0 bez decydenta."],
        "p0_unassigned": _map_p0_unassigned,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I05: V4 INHERITANCE CONTRACT — dziedziczenie bez utraty kontraktów (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_v4_contracts := object.get(_ctx, "v4_inheritance_contracts", [])
_v4_no_sot := [c |
    some c
    k := _v4_contracts[c]
    object.get(k, "source_of_truth", "") == ""
]

routing_ic05 = "TRIAGE_QUEUE" {
    count(_v4_no_sot) > 0
} else = "AUTO_FILE" {
    count(_v4_contracts) > 0
} else = "SUGGEST" {
    true
}

inheritance_contract_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "v4_inheritance_contract"
    object.get(_ctx, "analysis", "") == "v4_inheritance_contract"
    routing_ic05 == "AUTO_FILE"
    cert := _certificate(444005, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.v4_inheritance_contract",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ic05,
        "_routing_reason": "CERTYFIKACJA: każdy kontrakt dziedziczony ma źródło prawdy w V3.",
        "_legal_basis": "P44-I05; kontrakty wyjściowe P00–P43 (raporty_finalne)",
        "_warnings": [],
        "contracts": count(_v4_contracts),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "v4_inheritance_contract"
    routing_ic05 == "TRIAGE_QUEUE"
    cert := _certificate(444005, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.v4_inheritance_contract",
        "decision_mode": "TRIAGE",
        "_routing": routing_ic05,
        "_routing_reason": "CERTYFIKACJA: kontrakt dziedziczony bez source_of_truth — V4 nie może go egzekwować.",
        "_legal_basis": "P44-I05; standardy nazewnicze P00 (11.5)",
        "_warnings": ["[V3-P44] Kontrakty bez źródła prawdy."],
        "contracts_without_sot": _v4_no_sot,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I06: SUCCESS METRIC FREEZE — definicja sukcesu jako dane (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_success_metrics := object.get(_ctx, "success_metrics", [])
_metrics_no_threshold := [m |
    some m
    k := _success_metrics[m]
    object.get(k, "threshold", null) == null
]

routing_mf06 = "BLOCK_AND_ALERT" {
    count(_metrics_no_threshold) > 0
} else = "AUTO_FILE" {
    count(_success_metrics) > 0
} else = "SUGGEST" {
    true
}

metric_freeze_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "success_metric_freeze"
    object.get(_ctx, "analysis", "") == "success_metric_freeze"
    routing_mf06 == "AUTO_FILE"
    cert := _certificate(444006, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.success_metric_freeze",
        "decision_mode": "AUTO_POST",
        "_routing": routing_mf06,
        "_routing_reason": "CERTYFIKACJA: definicja sukcesu zamrożona jako dane (metryka+próg+źródło) przed certyfikacją.",
        "_legal_basis": "P44-I06; ADR-002 (parametry-as-data); P37 metryki SLO",
        "_warnings": [],
        "metrics": count(_success_metrics),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "success_metric_freeze"
    routing_mf06 == "BLOCK_AND_ALERT"
    cert := _certificate(444006, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.success_metric_freeze",
        "decision_mode": "BLOCK",
        "_routing": routing_mf06,
        "_routing_reason": "CERTYFIKACJA: metryka sukcesu bez progu — ocena na wrażeniu, nie na dowodzie.",
        "_legal_basis": "P44-I06; ADR-002",
        "_warnings": ["[V3-P44] Metryki bez progu."],
        "metrics_without_threshold": _metrics_no_threshold,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I07: CERTIFICATE WORM + SIGNATURE — podpis i retencja ≥ 5 lat (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_final_cert := object.get(_ctx, "final_certificate", {})
_cert_signed := object.get(_final_cert, "signature", "") != ""
_cert_worm := object.get(_final_cert, "worm", false) == true
_cert_retention := object.get(_final_cert, "retention_years", 0)
_retention_min := _th("v3_p44_certificate_retention_min_years", 5)

routing_ws07 = "BLOCK_AND_ALERT" {
    not _cert_signed
} else = "BLOCK_AND_ALERT" {
    not _cert_worm
} else = "BLOCK_AND_ALERT" {
    _cert_retention < _retention_min
} else = "AUTO_FILE" {
    true
}

worm_signature_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "certificate_worm_signature"
    object.get(_ctx, "analysis", "") == "certificate_worm_signature"
    routing_ws07 == "AUTO_FILE"
    cert := _certificate(444007, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.certificate_worm_signature",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ws07,
        "_routing_reason": "CERTYFIKACJA: certyfikat podpisany, w WORM, retencja zgodna z progiem.",
        "_legal_basis": "UoR art. 74-75 (retencja dowodów) [NIEZWERYFIKOWANE]; eIDAS (podpis) [NIEZWERYFIKOWANE]; P38 WORM+podpisy; P43-K3 tamper test",
        "_warnings": [],
        "retention_years": _cert_retention,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "certificate_worm_signature"
    routing_ws07 == "BLOCK_AND_ALERT"
    cert := _certificate(444007, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.certificate_worm_signature",
        "decision_mode": "BLOCK",
        "_routing": routing_ws07,
        "_routing_reason": "CERTYFIKACJA: certyfikat bez podpisu / bez WORM / z retencją poniżej progu = dowód nietrwały.",
        "_legal_basis": "UoR art. 74-75 [NIEZWERYFIKOWANE]; P38 WORM; P43-K3; V1 zasada 6",
        "_warnings": ["[V3-P44] Brak podpisu, WORM lub retencja < progu."],
        "signature_present": _cert_signed,
        "worm_present": _cert_worm,
        "retention_years": _cert_retention,
        "retention_min": _retention_min,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I08: KNOWLEDGE TRANSFER PACK — forteca operowalna przez innych (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_kt_pack := object.get(_ctx, "knowledge_transfer_pack", {})
_kt_missing := [a |
    some a
    v := object.get(_kt_pack, "required_artifacts", [])
    v[a] == false
]

routing_kt08 = "TRIAGE_QUEUE" {
    count(_kt_missing) > 0
} else = "AUTO_FILE" {
    count(object.get(_kt_pack, "required_artifacts", [])) > 0
} else = "SUGGEST" {
    true
}

knowledge_transfer_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "knowledge_transfer_pack"
    object.get(_ctx, "analysis", "") == "knowledge_transfer_pack"
    routing_kt08 == "AUTO_FILE"
    cert := _certificate(444008, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.knowledge_transfer_pack",
        "decision_mode": "AUTO_POST",
        "_routing": routing_kt08,
        "_routing_reason": "CERTYFIKACJA: pakiet przekazania kompletny (dokumenty, runbooki, rejestry, kontakty).",
        "_legal_basis": "P44-I08; P37 runbooki RB01–RB06; P41 knowledge transfer",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "knowledge_transfer_pack"
    routing_kt08 == "TRIAGE_QUEUE"
    cert := _certificate(444008, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.knowledge_transfer_pack",
        "decision_mode": "TRIAGE",
        "_routing": routing_kt08,
        "_routing_reason": "CERTYFIKACJA: brakujące artefakty pakietu przekazania.",
        "_legal_basis": "P44-I08; P41-I12",
        "_warnings": ["[V3-P44] Artefakty przekazania nieobecne."],
        "missing_artifacts": _kt_missing,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I09: CERTIFICATION RENEWAL POLICY — wygaśnięcie zamiast wieczności (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_renewal := object.get(_ctx, "renewal_policy", {})
_renewal_has_expiry := count(_renewal) > 0
_days_since := object.get(_renewal, "days_since_certification", 0)
_renewal_max_days := _th("v3_p44_cert_validity_max_days", 90)

routing_rp09 = "BLOCK_AND_ALERT" {
    not _renewal_has_expiry
} else = "TRIAGE_QUEUE" {
    _days_since > _renewal_max_days
} else = "TRIAGE_QUEUE" {
    object.get(_renewal, "renewal_without_evidence", false) == true
} else = "AUTO_FILE" {
    true
}

renewal_policy_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "certification_renewal_policy"
    object.get(_ctx, "analysis", "") == "certification_renewal_policy"
    routing_rp09 == "AUTO_FILE"
    cert := _certificate(444009, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.certification_renewal_policy",
        "decision_mode": "AUTO_POST",
        "_routing": routing_rp09,
        "_routing_reason": "CERTYFIKACJA: polityka odnowienia zdefiniowana (nowelizacja/deploy/czas) i w oknie.",
        "_legal_basis": "P44-I09; P37 SLO (metryki odnowienia); P38 deploy krytyczny",
        "_warnings": [],
        "days_since_certification": _days_since,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "certification_renewal_policy"
    routing_rp09 == "BLOCK_AND_ALERT"
    cert := _certificate(444009, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.certification_renewal_policy",
        "decision_mode": "BLOCK",
        "_routing": routing_rp09,
        "_routing_reason": "CERTYFIKACJA: brak polityki wygaśnięcia — certyfikat wieczysty to fikcja.",
        "_legal_basis": "P44-I09; V1 zasada 6",
        "_warnings": ["[V3-P44] Brak polityki odnowienia certyfikatu."],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "certification_renewal_policy"
    routing_rp09 == "TRIAGE_QUEUE"
    cert := _certificate(444009, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.certification_renewal_policy",
        "decision_mode": "TRIAGE",
        "_routing": routing_rp09,
        "_routing_reason": "CERTYFIKACJA: certyfikat po terminie ważności lub odnowienie bez dowodu.",
        "_legal_basis": "P44-I09; P37 progi",
        "_warnings": ["[V3-P44] Wygaśnięcie/odnowienie bez dowodu."],
        "days_since_certification": _days_since,
        "validity_max_days": _renewal_max_days,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I10: LEGACY CLEANUP CLOSURE — zero długu na start V4 (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_legacy_open := object.get(_ctx, "legacy_facades_open", 0)
_legacy_max := _th("v3_p44_legacy_facades_max", 0)

routing_lc10 = "TRIAGE_QUEUE" {
    _legacy_open > _legacy_max
} else = "AUTO_FILE" {
    true
}

legacy_cleanup_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legacy_cleanup_closure"
    object.get(_ctx, "analysis", "") == "legacy_cleanup_closure"
    routing_lc10 == "AUTO_FILE"
    cert := _certificate(444010, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.legacy_cleanup_closure",
        "decision_mode": "AUTO_POST",
        "_routing": routing_lc10,
        "_routing_reason": "CERTYFIKACJA: brak otwartych fasad/martwych artefaktów ponad próg.",
        "_legal_basis": "P44-I10; P30/P36/P42 rejestry fasad",
        "_warnings": [],
        "legacy_open": _legacy_open,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "legacy_cleanup_closure"
    routing_lc10 == "TRIAGE_QUEUE"
    cert := _certificate(444010, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.legacy_cleanup_closure",
        "decision_mode": "TRIAGE",
        "_routing": routing_lc10,
        "_routing_reason": "CERTYFIKACJA: otwarte fasady/martwe artefakty — dług techniczny przed V4.",
        "_legal_basis": "P44-I10; P36 legacy retirement",
        "_warnings": ["[V3-P44] Fasady otwarte ponad próg."],
        "legacy_open": _legacy_open,
        "legacy_max": _legacy_max,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I11: OWNER ATTESTATION — przyjęcie certyfikatu przez właściciela (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_attestation := object.get(_ctx, "owner_attestation", {})
_attestation_signed := object.get(_attestation, "signed", false) == true

routing_oa11 = "TRIAGE_QUEUE" {
    not _attestation_signed
} else = "AUTO_FILE" {
    true
}

owner_attestation_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "owner_attestation"
    object.get(_ctx, "analysis", "") == "owner_attestation"
    routing_oa11 == "AUTO_FILE"
    cert := _certificate(444011, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.owner_attestation",
        "decision_mode": "AUTO_POST",
        "_routing": routing_oa11,
        "_routing_reason": "CERTYFIKACJA: właściciel przyjął certyfikat z listą zastrzeżeń (4-eyes biznesowe).",
        "_legal_basis": "P44-I11; RODO art. 5.2 (rozliczalność) [NIEZWERYFIKOWANE]",
        "_warnings": [],
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "owner_attestation"
    routing_oa11 == "TRIAGE_QUEUE"
    cert := _certificate(444011, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.owner_attestation",
        "decision_mode": "TRIAGE",
        "_routing": routing_oa11,
        "_routing_reason": "CERTYFIKACJA: brak atestu właściciela — certyfikat bez strony biorącej.",
        "_legal_basis": "P44-I11; 4-eyes (P43-I03) po stronie biznesowej",
        "_warnings": ["[V3-P44] Oczekiwanie na atest właściciela."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P44-I12: FORTRESS SELF-PORTRAIT — komponent→kontrakt→dowód (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_self_portrait := object.get(_ctx, "self_portrait", {})
_sp_no_evidence := [c |
    some c
    v := _self_portrait[c]
    object.get(v, "evidence_link", "") == ""
]

routing_sp12 = "TRIAGE_QUEUE" {
    count(_sp_no_evidence) > 0
} else = "AUTO_FILE" {
    count(_self_portrait) > 0
} else = "SUGGEST" {
    true
}

self_portrait_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "fortress_self_portrait"
    object.get(_ctx, "analysis", "") == "fortress_self_portrait"
    routing_sp12 == "AUTO_FILE"
    cert := _certificate(444012, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.fortress_self_portrait",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sp12,
        "_routing_reason": "CERTYFIKACJA: auto-portret kompletny — każdy komponent ma dowód.",
        "_legal_basis": "P44-I12; P41 rejestr dokumentacji; P42 rejestr systemowy",
        "_warnings": [],
        "components": count(_self_portrait),
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "fortress_self_portrait"
    routing_sp12 == "TRIAGE_QUEUE"
    cert := _certificate(444012, {
        "rule_id": "jdg.v3_p44_certyfikacja_finalna.fortress_self_portrait",
        "decision_mode": "TRIAGE",
        "_routing": routing_sp12,
        "_routing_reason": "CERTYFIKACJA: komponenty bez łącza dowodu w auto-portrecie.",
        "_legal_basis": "P44-I12; P41-I12",
        "_warnings": ["[V3-P44] Komponenty bez dowodu."],
        "components_without_evidence": _sp_no_evidence,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := hard_gate_decision {
    hard_gate_decision.rule_id != ""
} else := pillar_scoreboard_decision {
    pillar_scoreboard_decision.rule_id != ""
} else := aggregate_ledger_decision {
    aggregate_ledger_decision.rule_id != ""
} else := owner_decision_map_decision {
    owner_decision_map_decision.rule_id != ""
} else := inheritance_contract_decision {
    inheritance_contract_decision.rule_id != ""
} else := metric_freeze_decision {
    metric_freeze_decision.rule_id != ""
} else := worm_signature_decision {
    worm_signature_decision.rule_id != ""
} else := knowledge_transfer_decision {
    knowledge_transfer_decision.rule_id != ""
} else := renewal_policy_decision {
    renewal_policy_decision.rule_id != ""
} else := legacy_cleanup_decision {
    legacy_cleanup_decision.rule_id != ""
} else := owner_attestation_decision {
    owner_attestation_decision.rule_id != ""
} else := self_portrait_decision {
    self_portrait_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p44_certyfikacja_finalna.no_match",
    "package": "jdg.v3_p44_certyfikacja_finalna",
    "priority": 999999,
}
