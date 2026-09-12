# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P51 PUSTYNIE PRAWNE — DOMKNIĘCIE LUK POKRYCIA AKT→REGUŁA→TEST
# (V3 FORTRESS) — ENTERPRISE
# ===============================================================================
# Warstwa pokrycia regulacyjnego ENTERPRISE — 12 innowacji (I01–I12; minimum
# z promptu P51 Sekcja 10):
#   I01 Desert register with SLA (rejestr pustyni: przepis, klasa, SLA,
#       właściciel, status; trend spadkowy → P37),
#   I02 Risk-weighted prioritization (score = częstość × kwota × niepewność
#       wykładni; kolejność domknięcia z uzasadnieniem liczbowym),
#   I03 Desert card template (karta pustyni: przepis → warunki → reguła →
#       testy → koszt — standard raportu, wiąże P41/P36),
#   I04 Coverage chain metric (CCR: % aktów z pełnym łańcuchem
#       akt→art→reguła→test — definition of done kampanii),
#   I05 Semi-auto rule drafting (generatory z guardem duplikatów K-P50-5;
#       szkic bez testu granicznego ≠ pokrycie — AP01),
#   I06 Cross-domain desert sweep (pustynie systemowe: odsetki, przedawnienie,
#       ulgi, KSeF terminy, waluty, korekty, terminy kalendarzowe),
#   I07 Coverage regression block (Law Radar P08: zmiana prawa bez planu
#       reguły → ticket z SLA; brak radaru = TRIAGE fail-closed),
#   I08 Desert heatmap by money impact (kwadranty HIGH/MED/LOW/COLD ważone
#       przepływem kwot domeny),
#   I09 Testless rule sweep (reguła bez testu + ghost testy — najszybsza
#       klasa domknięcia generatorem testów P36),
#   I10 Quarterly coverage goal (cele per domena: VAT 95% … nisze 70%;
#       MET/AT_RISK/MISSED, parametr 4-eyes Q02),
#   I11 Desert→vacancy mapping (pustynie × rejestry stubów P45 = jeden
#       rejestr ryzyka „fasada lub brak"),
#   I12 Legal coverage attestation (deklaracja pokrycia z licznikami i
#       zastrzeżeniami dla certyfikacji finalnej P68; liczniki niespójne
#       = BLOCK fail-closed).
#
# Zasady:
#   * WSZYSTKIE progi z data.jdg.thresholds.v3_p51 — ADR-002 (P06), okno
#     temporalne valid_from (P05). ZERO hardcode progów.
#   * Fail-closed (V1 zasada 6): brak snapshotu progów, niespójne liczniki
#     atestacji, bypass bramki = BLOCK — nigdy ciche AUTO_FILE przy wątpliwości
#     (pustynia = przepis bez pełnego łańcucha dowodu; księgowanie na pustyni
#     to zgadywanie, UoR art. 4 ust. 1 sprawdzalność [NIEZWERYFIKOWANE — ISAP]).
#   * Honesty: liczniki z narzędzi i bundli (nie deklaracje); pustynie są
#     baseline jawny — rejestr nie czyści BLOCK, dokumentuje plan (protokół 06
#     P51: deklaracje ≠ dowód; dowód = kod + test + wynik uruchomienia).
#   * _legal_basis: każde twierdzenie z aktem + status weryfikacji
#     [NIEZWERYFIKOWANE — ISAP] do czasu stempla 4-eyes (protokół 04;
#     konwencja P47/P48/P49/P50).
#   * Aktywacja: input.jdg_entrepreneur.v3_p51_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p51_coverage_deserts.<analiza>.
#   * Kontrakty: P00 (kanon artefaktów, coverage_canon.json jako baza),
#     P02/P29 (routing + bramki), P05 (temporalność), P06 (parametry-as-data),
#     P08 (Law Radar — I07 domyka pętlę), P36 (generatory), P37 (metryki),
#     P39 (bramki merge), P41 (karty pustyni w dokumentacji), P45 (rejestr
#     stubów — I11), P47 (podstawa podejrzana = podwójna luka), P48 (mirror),
#     P49 (fail-closed), P50 (guard duplikatów K-P50-5), P52 (testy granicze),
#     P68 (certyfikacja finalna — I12).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p51_coverage_deserts
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p51_coverage_deserts

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p51_check", false) == true
_ctx := object.get(input, "v3_p51", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p51_snapshot := data.jdg.thresholds.v3_p51

_snapshot_ok = true {
    count(_p51_snapshot) > 0
} else = false {
    true
}

_th(key, fallback) = value {
    count(_p51_snapshot) > 0
    value := object.get(_p51_snapshot, key, null)
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
    "rule_id": "jdg.v3_p51_coverage_deserts.thresholds_missing",
    "package": "jdg.v3_p51_coverage_deserts",
    "priority": 0,
    "decision_mode": "BLOCK",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "DESERTS V3-P51: brak snapshotu data.jdg.thresholds.v3_p51.",
    "_legal_basis": "ADR-002; V1 zasada 6 (fail-closed); UoR art. 4 ust. 1 (sprawdzalność) [NIEZWERYFIKOWANE — ISAP]",
    "_warnings": ["[V3-P51] Brak snapshotu progów pokrycia — kontrole pustyni ZABLOKOWANE."],
}

# ── Decision Certificate wrapper (V2 filar F4) ────────────────────────────────
_certificate(priority, extra) = merged {
    base := {
        "matched": true,
        "package": "jdg.v3_p51_coverage_deserts",
        "priority": priority,
        "threshold_version": object.get(_p51_snapshot, "v3_p51_threshold_version", "MISSING"),
        "legal_basis_version": object.get(_p51_snapshot, "legal_basis_version", "MISSING"),
        "valid_from": object.get(_p51_snapshot, "valid_from", null),
        "valid_to": null,
    }
    merged := object.union(base, extra)
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I01: DESERT REGISTER WITH SLA — rejestr pustyni (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_dr := object.get(_ctx, "desert_register", {})
_reg_deserts := object.get(_dr, "desert_nodes", -1)
_reg_p0 := object.get(_dr, "p0_count", 0)
_reg_no_rule := object.get(_dr, "no_rule", 0)
_reg_rule_no_test := object.get(_dr, "rule_no_test", 0)
_reg_test_no_rule := object.get(_dr, "test_no_rule", 0)
_p0_max := _th("v3_p51_p0_deserts_max", 0)

routing_dr01 = "BLOCK_AND_ALERT" {
    _has_flag("register_bypassed")
} else = "TRIAGE_QUEUE" {
    _reg_p0 > _p0_max
} else = "AUTO_FILE" {
    _reg_deserts == 0
} else = "TRIAGE_QUEUE" {
    true
}

desert_register_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_register"
    routing_dr01 == "AUTO_FILE"
    cert := _certificate(451001, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_register",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dr01,
        "_routing_reason": "DESERTS: zero pustyni pokrycia — pełny łańcuch akt→art→reguła→test.",
        "_legal_basis": "P51-I01; UoR art. 4 ust. 1 (sprawdzalność); Ordynacja art. 180 (dowody) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "desert_nodes": _reg_deserts,
        "no_rule": _reg_no_rule,
        "rule_no_test": _reg_rule_no_test,
        "test_no_rule": _reg_test_no_rule,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_register"
    routing_dr01 == "TRIAGE_QUEUE"
    cert := _certificate(451001, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_register",
        "decision_mode": "TRIAGE",
        "_routing": routing_dr01,
        "_routing_reason": "DESERTS: pustynie w rejestrze z SLA — domknięcie wg priorytetów I02; decyzje księgowe na pustyni = NEEDS_ADVICE.",
        "_legal_basis": "P51-I01; P51-I02; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Pustynie prawne otwarte — plan domknięcia per karta I03."],
        "desert_nodes": _reg_deserts,
        "p0_count": _reg_p0,
        "p0_max": _p0_max,
        "no_rule": _reg_no_rule,
        "rule_no_test": _reg_rule_no_test,
        "test_no_rule": _reg_test_no_rule,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_register"
    routing_dr01 == "BLOCK_AND_ALERT"
    cert := _certificate(451001, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_register",
        "decision_mode": "BLOCK",
        "_routing": routing_dr01,
        "_routing_reason": "DESERTS: bypass rejestru pustyni — BLOCK.",
        "_legal_basis": "P51-I01; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass desert register — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I02: RISK-WEIGHTED PRIORITIZATION — scoring pustyni (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_rk := object.get(_ctx, "desert_risk", {})
_rk_scored := object.get(_rk, "scored", -1)
_rk_unscored := object.get(_rk, "unscored", -1)
_rk_top := object.get(_rk, "top_risk_score", 0)
_rk_p0 := object.get(_rk, "p0_count", 0)
_rk_p1 := object.get(_rk, "p1_count", 0)

routing_rk02 = "BLOCK_AND_ALERT" {
    _has_flag("risk_bypassed")
} else = "TRIAGE_QUEUE" {
    _rk_scored <= 0
} else = "TRIAGE_QUEUE" {
    _rk_unscored > 0
} else = "TRIAGE_QUEUE" {
    _rk_p0 + _rk_p1 > 0
} else = "AUTO_FILE" {
    true
}

desert_risk_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_risk"
    routing_rk02 == "AUTO_FILE"
    cert := _certificate(451002, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_risk",
        "decision_mode": "AUTO_POST",
        "_routing": routing_rk02,
        "_routing_reason": "DESERTS: wszystkie pustynie o score'owane ryzyko; zero P0/P1.",
        "_legal_basis": "P51-I02; metodologia frequency × amount × uncertainty [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "scored": _rk_scored,
        "top_risk_score": _rk_top,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_risk"
    routing_rk02 == "TRIAGE_QUEUE"
    cert := _certificate(451002, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_risk",
        "decision_mode": "TRIAGE",
        "_routing": routing_rk02,
        "_routing_reason": "DESERTS: pustynie P0/P1 bez domknięcia lub scoring niepełny — kolejność wg ryzyka.",
        "_legal_basis": "P51-I02; AP07 (błędny AUTO_POST na pustyni) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Ryzyko pustyni niescore'owane lub P0/P1 otwarte."],
        "scored": _rk_scored,
        "unscored": _rk_unscored,
        "p0_count": _rk_p0,
        "p1_count": _rk_p1,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_risk"
    routing_rk02 == "BLOCK_AND_ALERT"
    cert := _certificate(451002, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_risk",
        "decision_mode": "BLOCK",
        "_routing": routing_rk02,
        "_routing_reason": "DESERTS: bypass priorytetyzacji ryzyka — BLOCK.",
        "_legal_basis": "P51-I02; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass desert risk — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I03: DESERT CARD TEMPLATE — karta pustyni (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_dc := object.get(_ctx, "desert_cards", {})
_cards_total := object.get(_dc, "cards_total", -1)
_cards_required := _th("v3_p51_cards_required", 10)
_template_present := object.get(_dc, "template_present", false)

routing_dc03 = "BLOCK_AND_ALERT" {
    _has_flag("cards_bypassed")
} else = "BLOCK_AND_ALERT" {
    not _template_present
} else = "TRIAGE_QUEUE" {
    _cards_total < _cards_required
} else = "AUTO_FILE" {
    true
}

desert_cards_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_cards"
    routing_dc03 == "AUTO_FILE"
    cert := _certificate(451003, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_cards",
        "decision_mode": "AUTO_POST",
        "_routing": routing_dc03,
        "_routing_reason": "DESERTS: komplet kart pustyni TOP-10 + szablon standardu.",
        "_legal_basis": "P51-I03; P41 (dokumentacja standardu kart) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "cards_total": _cards_total,
        "cards_required": _cards_required,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_cards"
    routing_dc03 == "TRIAGE_QUEUE"
    cert := _certificate(451003, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_cards",
        "decision_mode": "TRIAGE",
        "_routing": routing_dc03,
        "_routing_reason": "DESERTS: za mało kart pustyni (TOP-10 wg ryzyka) — recepta per pustynia niekompletna.",
        "_legal_basis": "P51-I03; P51-I04 (recepta per pustynia) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Karty pustyni poniżej wymaganego kompletu."],
        "cards_total": _cards_total,
        "cards_required": _cards_required,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_cards"
    routing_dc03 == "BLOCK_AND_ALERT"
    cert := _certificate(451003, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_cards",
        "decision_mode": "BLOCK",
        "_routing": routing_dc03,
        "_routing_reason": "DESERTS: brak szablonu karty pustyni / bypass — standard recepty naruszony.",
        "_legal_basis": "P51-I03; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Szablon karty pustyni nieobecny lub bypass — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I04: COVERAGE CHAIN METRIC — CCR: akt→art→reguła→test (AN01/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_cm := object.get(_ctx, "chain_metric", {})
_art_nodes := object.get(_cm, "article_nodes", 0)
_ccr := object.get(_cm, "CCR_pct", 0.0)
_chain_target := _th("v3_p51_chain_target_pct", 90.0)

routing_cm04 = "BLOCK_AND_ALERT" {
    _has_flag("chain_bypassed")
} else = "TRIAGE_QUEUE" {
    _art_nodes == 0
} else = "TRIAGE_QUEUE" {
    _ccr < _chain_target
} else = "AUTO_FILE" {
    true
}

chain_metric_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "chain_metric"
    routing_cm04 == "AUTO_FILE"
    cert := _certificate(451004, {
        "rule_id": "jdg.v3_p51_coverage_deserts.chain_metric",
        "decision_mode": "AUTO_POST",
        "_routing": routing_cm04,
        "_routing_reason": "DESERTS: CCR na celu kampanii — % aktów z pełnym łańcuchem dowodu.",
        "_legal_basis": "P51-I04; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "article_nodes": _art_nodes,
        "CCR_pct": _ccr,
        "chain_target_pct": _chain_target,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "chain_metric"
    routing_cm04 == "TRIAGE_QUEUE"
    cert := _certificate(451004, {
        "rule_id": "jdg.v3_p51_coverage_deserts.chain_metric",
        "decision_mode": "TRIAGE",
        "_routing": routing_cm04,
        "_routing_reason": "DESERTS: CCR poniżej celu kampanii (definition of done) — domknięcie łańcucha.",
        "_legal_basis": "P51-I04; cel kwantyfikowany promptu P51 5.4 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] CCR poniżej celu — plan domknięcia nóg łańcucha."],
        "article_nodes": _art_nodes,
        "CCR_pct": _ccr,
        "chain_target_pct": _chain_target,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "chain_metric"
    routing_cm04 == "BLOCK_AND_ALERT"
    cert := _certificate(451004, {
        "rule_id": "jdg.v3_p51_coverage_deserts.chain_metric",
        "decision_mode": "BLOCK",
        "_routing": routing_cm04,
        "_routing_reason": "DESERTS: bypass metryki łańcucha — BLOCK.",
        "_legal_basis": "P51-I04; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass chain metric — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I05: SEMI-AUTO RULE DRAFTING — generatory z guardem (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_sa := object.get(_ctx, "semi_auto_drafting", {})
_gen_total := object.get(_sa, "generators_total", 0)
_gen_guarded := object.get(_sa, "generators_guarded", 0)
_gen_stubs := object.get(_sa, "legacy_stub_factories", 0)
_gen_guarded_min := _th("v3_p51_generators_guarded_min", 4)

routing_sa05 = "BLOCK_AND_ALERT" {
    _has_flag("drafting_bypassed")
} else = "BLOCK_AND_ALERT" {
    _gen_stubs > 0
} else = "TRIAGE_QUEUE" {
    _gen_total == 0
} else = "TRIAGE_QUEUE" {
    _gen_guarded < _gen_guarded_min
} else = "AUTO_FILE" {
    true
}

semi_auto_drafting_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semi_auto_drafting"
    routing_sa05 == "AUTO_FILE"
    cert := _certificate(451005, {
        "rule_id": "jdg.v3_p51_coverage_deserts.semi_auto_drafting",
        "decision_mode": "AUTO_POST",
        "_routing": routing_sa05,
        "_routing_reason": "DESERTS: generatory objęte guardem duplikatów (K-P50-5); zero fabryk stubów.",
        "_legal_basis": "P51-I05; K-P50-5; AP01 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "generators_total": _gen_total,
        "generators_guarded": _gen_guarded,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semi_auto_drafting"
    routing_sa05 == "TRIAGE_QUEUE"
    cert := _certificate(451005, {
        "rule_id": "jdg.v3_p51_coverage_deserts.semi_auto_drafting",
        "decision_mode": "TRIAGE",
        "_routing": routing_sa05,
        "_routing_reason": "DESERTS: generator bez guard duplikatów lub skan pusty — podłączyć K-P50-5.",
        "_legal_basis": "P51-I05; K-P50-5; AP01/AP04 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Generatory bez guardu duplikatów."],
        "generators_total": _gen_total,
        "generators_guarded": _gen_guarded,
        "generators_guarded_min": _gen_guarded_min,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "semi_auto_drafting"
    routing_sa05 == "BLOCK_AND_ALERT"
    cert := _certificate(451005, {
        "rule_id": "jdg.v3_p51_coverage_deserts.semi_auto_drafting",
        "decision_mode": "BLOCK",
        "_routing": routing_sa05,
        "_routing_reason": "DESERTS: fabryka stubów {true} / bypass — AP01: szkielety udające pokrycie.",
        "_legal_basis": "P51-I05; AP01; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Fabryka stubów — ZABLOKOWANE do usunięcia."],
        "legacy_stub_factories": _gen_stubs,
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I06: CROSS-DOMAIN DESERT SWEEP — pustynie systemowe (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_ss := object.get(_ctx, "systemic_sweep", {})
_ss_classes := object.get(_ss, "systemic_classes", 0)
_ss_active := object.get(_ss, "active_systemic_classes", 0)
_ss_deserts := object.get(_ss, "systemic_deserts", 0)
_ss_deserts_max := _th("v3_p51_systemic_deserts_max", 0)

routing_ss06 = "BLOCK_AND_ALERT" {
    _has_flag("systemic_bypassed")
} else = "TRIAGE_QUEUE" {
    _ss_classes == 0
} else = "TRIAGE_QUEUE" {
    _ss_deserts > _ss_deserts_max
} else = "AUTO_FILE" {
    true
}

systemic_sweep_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "systemic_sweep"
    routing_ss06 == "AUTO_FILE"
    cert := _certificate(451006, {
        "rule_id": "jdg.v3_p51_coverage_deserts.systemic_sweep",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ss06,
        "_routing_reason": "DESERTS: klasy systemowe (odsetki/przedawnienie/waluty/terminy) w pełni pokryte.",
        "_legal_basis": "P51-I06; Ordynacja art. 56 (odsetki); art. 70 (przedawnienie) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "systemic_classes": _ss_classes,
        "systemic_deserts": _ss_deserts,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "systemic_sweep"
    routing_ss06 == "TRIAGE_QUEUE"
    cert := _certificate(451006, {
        "rule_id": "jdg.v3_p51_coverage_deserts.systemic_sweep",
        "decision_mode": "TRIAGE",
        "_routing": routing_ss06,
        "_routing_reason": "DESERTS: pustynie systemowe (przekrojowe) otwarte — łatwo przeoczyć w podziale domenowym.",
        "_legal_basis": "P51-I06; P51-AN02 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Pustynie systemowe — domknięcie przekrojowe."],
        "systemic_classes": _ss_classes,
        "active_systemic_classes": _ss_active,
        "systemic_deserts": _ss_deserts,
        "systemic_deserts_max": _ss_deserts_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "systemic_sweep"
    routing_ss06 == "BLOCK_AND_ALERT"
    cert := _certificate(451006, {
        "rule_id": "jdg.v3_p51_coverage_deserts.systemic_sweep",
        "decision_mode": "BLOCK",
        "_routing": routing_ss06,
        "_routing_reason": "DESERTS: bypass przebiegu systemowego — BLOCK.",
        "_legal_basis": "P51-I06; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass systemic sweep — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I07: COVERAGE REGRESSION BLOCK — Law Radar → pustynie (AN02)
# ═══════════════════════════════════════════════════════════════════════════════
_lr := object.get(_ctx, "law_radar_block", {})
_radar_present := object.get(_lr, "radar_present", false)
_lr_changes := object.get(_lr, "changes_without_rule_plan", 0)
_lr_changes_max := _th("v3_p51_law_radar_changes_max", 0)

routing_lr07 = "BLOCK_AND_ALERT" {
    _has_flag("radar_block_bypassed")
} else = "TRIAGE_QUEUE" {
    not _radar_present
} else = "TRIAGE_QUEUE" {
    _lr_changes > _lr_changes_max
} else = "AUTO_FILE" {
    true
}

law_radar_block_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "law_radar_block"
    routing_lr07 == "AUTO_FILE"
    cert := _certificate(451007, {
        "rule_id": "jdg.v3_p51_coverage_deserts.law_radar_block",
        "decision_mode": "AUTO_POST",
        "_routing": routing_lr07,
        "_routing_reason": "DESERTS: zmiany prawa z planem reguły — nowelizacje nie tworzą pustyni.",
        "_legal_basis": "P51-I07; P08 Law Radar (pętla ciągła) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "changes_without_rule_plan": _lr_changes,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "law_radar_block"
    routing_lr07 == "TRIAGE_QUEUE"
    cert := _certificate(451007, {
        "rule_id": "jdg.v3_p51_coverage_deserts.law_radar_block",
        "decision_mode": "TRIAGE",
        "_routing": routing_lr07,
        "_routing_reason": "DESERTS: zmiana prawa bez planu reguły (ticket SLA) lub brak radaru (bramka nieuruchomiona).",
        "_legal_basis": "P51-I07; P08; P25 (kalendarz zmian) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Zmiany prawa bez planu reguły — ticket z SLA."],
        "radar_present": _radar_present,
        "changes_without_rule_plan": _lr_changes,
        "changes_max": _lr_changes_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "law_radar_block"
    routing_lr07 == "BLOCK_AND_ALERT"
    cert := _certificate(451007, {
        "rule_id": "jdg.v3_p51_coverage_deserts.law_radar_block",
        "decision_mode": "BLOCK",
        "_routing": routing_lr07,
        "_routing_reason": "DESERTS: bypass bramki regresji pokrycia — BLOCK.",
        "_legal_basis": "P51-I07; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass coverage regression block — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I08: DESERT HEATMAP BY MONEY IMPACT — kwadranty (AN03)
# ═══════════════════════════════════════════════════════════════════════════════
_hm := object.get(_ctx, "desert_heatmap", {})
_hm_scored := object.get(_hm, "scored_deserts", -1)
_hm_quadrants := object.get(_hm, "quadrants", {})
_hm_high := object.get(_hm_quadrants, "HIGH", 0)
_hm_high_max := _th("v3_p51_heatmap_high_max", 0)

routing_hm08 = "BLOCK_AND_ALERT" {
    _has_flag("heatmap_bypassed")
} else = "TRIAGE_QUEUE" {
    _hm_scored <= 0
} else = "TRIAGE_QUEUE" {
    _hm_high > _hm_high_max
} else = "AUTO_FILE" {
    true
}

desert_heatmap_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_heatmap"
    routing_hm08 == "AUTO_FILE"
    cert := _certificate(451008, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_heatmap",
        "decision_mode": "AUTO_POST",
        "_routing": routing_hm08,
        "_routing_reason": "DESERTS: zero pustyni w kwadrancie HIGH — ryzyko kwotowe widoczne i opanowane.",
        "_legal_basis": "P51-I08; mapa cieplna ważona przepływem kwot [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "scored_deserts": _hm_scored,
        "high_quadrant": _hm_high,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_heatmap"
    routing_hm08 == "TRIAGE_QUEUE"
    cert := _certificate(451008, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_heatmap",
        "decision_mode": "TRIAGE",
        "_routing": routing_hm08,
        "_routing_reason": "DESERTS: pustynie kwadrantu HIGH (duże kwoty przez obszar bez reguły) — domknięcie pilne.",
        "_legal_basis": "P51-I08; AP07 (błędny AUTO_POST wysokiej kwoty) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Kwadrant HIGH — ryzyko kwotowe pustyni."],
        "scored_deserts": _hm_scored,
        "high_quadrant": _hm_high,
        "high_max": _hm_high_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "desert_heatmap"
    routing_hm08 == "BLOCK_AND_ALERT"
    cert := _certificate(451008, {
        "rule_id": "jdg.v3_p51_coverage_deserts.desert_heatmap",
        "decision_mode": "BLOCK",
        "_routing": routing_hm08,
        "_routing_reason": "DESERTS: bypass mapy cieplnej — BLOCK.",
        "_legal_basis": "P51-I08; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass desert heatmap — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I09: TESTLESS RULE SWEEP — reguła bez testu + ghost testy (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_ts := object.get(_ctx, "testless_sweep", {})
_ts_scanned := object.get(_ts, "rules_scanned", 0)
_ts_untested := object.get(_ts, "rules_without_test", 0)
_ts_ghost := object.get(_ts, "ghost_tests", 0)
_ts_untested_max := _th("v3_p51_testless_max", 0)
_ts_ghost_max := _th("v3_p51_ghost_tests_max", 0)

routing_ts09 = "BLOCK_AND_ALERT" {
    _has_flag("testless_bypassed")
} else = "TRIAGE_QUEUE" {
    _ts_scanned == 0
} else = "TRIAGE_QUEUE" {
    _ts_ghost > _ts_ghost_max
} else = "TRIAGE_QUEUE" {
    _ts_untested > _ts_untested_max
} else = "AUTO_FILE" {
    true
}

testless_sweep_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "testless_sweep"
    routing_ts09 == "AUTO_FILE"
    cert := _certificate(451009, {
        "rule_id": "jdg.v3_p51_coverage_deserts.testless_sweep",
        "decision_mode": "AUTO_POST",
        "_routing": routing_ts09,
        "_routing_reason": "DESERTS: każda reguła ma test natywny; zero ghost testów.",
        "_legal_basis": "P51-I09; P39 (bramki testowe) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "rules_scanned": _ts_scanned,
        "rules_without_test": _ts_untested,
        "ghost_tests": _ts_ghost,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "testless_sweep"
    routing_ts09 == "TRIAGE_QUEUE"
    cert := _certificate(451009, {
        "rule_id": "jdg.v3_p51_coverage_deserts.testless_sweep",
        "decision_mode": "TRIAGE",
        "_routing": routing_ts09,
        "_routing_reason": "DESERTS: reguły bez testu / ghost testy — domknięcie generatorem testów (P36).",
        "_legal_basis": "P51-I09; P36 (generator testów) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Reguły bez testu natywnego — plan domknięcia."],
        "rules_scanned": _ts_scanned,
        "rules_without_test": _ts_untested,
        "testless_max": _ts_untested_max,
        "ghost_tests": _ts_ghost,
        "ghost_max": _ts_ghost_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "testless_sweep"
    routing_ts09 == "BLOCK_AND_ALERT"
    cert := _certificate(451009, {
        "rule_id": "jdg.v3_p51_coverage_deserts.testless_sweep",
        "decision_mode": "BLOCK",
        "_routing": routing_ts09,
        "_routing_reason": "DESERTS: bypass przebiegu testless — BLOCK.",
        "_legal_basis": "P51-I09; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass testless sweep — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I10: QUARTERLY COVERAGE GOAL — cele per domena (AN03/AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_qg := object.get(_ctx, "quarterly_goals", {})
_qg_total := object.get(_qg, "goals_total", 0)
_qg_missed := object.get(_qg, "missed", 0)
_qg_missed_max := _th("v3_p51_goals_missed_max", 0)

routing_qg10 = "BLOCK_AND_ALERT" {
    _has_flag("goals_bypassed")
} else = "TRIAGE_QUEUE" {
    _qg_total == 0
} else = "TRIAGE_QUEUE" {
    _qg_missed > _qg_missed_max
} else = "AUTO_FILE" {
    true
}

quarterly_goals_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "quarterly_goals"
    routing_qg10 == "AUTO_FILE"
    cert := _certificate(451010, {
        "rule_id": "jdg.v3_p51_coverage_deserts.quarterly_goals",
        "decision_mode": "AUTO_POST",
        "_routing": routing_qg10,
        "_routing_reason": "DESERTS: cele kwartalne domeny osiągnięte (VAT 95% … nisze 70%).",
        "_legal_basis": "P51-I10; cel kwantyfikowany promptu P51 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "goals_total": _qg_total,
        "missed": _qg_missed,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "quarterly_goals"
    routing_qg10 == "TRIAGE_QUEUE"
    cert := _certificate(451010, {
        "rule_id": "jdg.v3_p51_coverage_deserts.quarterly_goals",
        "decision_mode": "TRIAGE",
        "_routing": routing_qg10,
        "_routing_reason": "DESERTS: domeny z celem MISSED — realistyczny plan kwartalny.",
        "_legal_basis": "P51-I10; Q02 (cele parametr 4-eyes) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Cele kwartalne nieosiągnięte — domknięcie wg planu."],
        "goals_total": _qg_total,
        "missed": _qg_missed,
        "missed_max": _qg_missed_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "quarterly_goals"
    routing_qg10 == "BLOCK_AND_ALERT"
    cert := _certificate(451010, {
        "rule_id": "jdg.v3_p51_coverage_deserts.quarterly_goals",
        "decision_mode": "BLOCK",
        "_routing": routing_qg10,
        "_routing_reason": "DESERTS: bypass celów kwartalnych — BLOCK.",
        "_legal_basis": "P51-I10; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass quarterly goals — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I11: DESERT→VACANCY MAPPING — pustynie × stuby P45 (AN01)
# ═══════════════════════════════════════════════════════════════════════════════
_vb := object.get(_ctx, "vacancy_bridge", {})
_vb_rows := object.get(_vb, "combined_register_rows", 0)
_vb_stubs := object.get(_vb, "stubs_total", 0)
_vb_deserts := object.get(_vb, "deserts", 0)
_vb_stubs_max := _th("v3_p51_stubs_total_max", 0)

routing_vb11 = "BLOCK_AND_ALERT" {
    _has_flag("vacancy_bypassed")
} else = "TRIAGE_QUEUE" {
    _vb_rows == 0
} else = "TRIAGE_QUEUE" {
    _vb_stubs > _vb_stubs_max
} else = "TRIAGE_QUEUE" {
    _vb_deserts > 0
} else = "AUTO_FILE" {
    true
}

vacancy_bridge_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "vacancy_bridge"
    routing_vb11 == "AUTO_FILE"
    cert := _certificate(451011, {
        "rule_id": "jdg.v3_p51_coverage_deserts.vacancy_bridge",
        "decision_mode": "AUTO_POST",
        "_routing": routing_vb11,
        "_routing_reason": "DESERTS: zero pustyni i zero stubów — jeden rejestr ryzyka pusty.",
        "_legal_basis": "P51-I11; P45 (rejestr stubów) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "deserts": _vb_deserts,
        "stubs_total": _vb_stubs,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "vacancy_bridge"
    routing_vb11 == "TRIAGE_QUEUE"
    cert := _certificate(451011, {
        "rule_id": "jdg.v3_p51_coverage_deserts.vacancy_bridge",
        "decision_mode": "TRIAGE",
        "_routing": routing_vb11,
        "_routing_reason": "DESERTS: reguły-fasady (stuby) lub pustynie w jednym rejestrze ryzyka.",
        "_legal_basis": "P51-I11; P45-I01; AP01 [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Fasada lub brak — wspólny rejestr ryzyka."],
        "deserts": _vb_deserts,
        "stubs_total": _vb_stubs,
        "stubs_max": _vb_stubs_max,
        "combined_register_rows": _vb_rows,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "vacancy_bridge"
    routing_vb11 == "BLOCK_AND_ALERT"
    cert := _certificate(451011, {
        "rule_id": "jdg.v3_p51_coverage_deserts.vacancy_bridge",
        "decision_mode": "BLOCK",
        "_routing": routing_vb11,
        "_routing_reason": "DESERTS: bypass mapowania pustynie→stuby — BLOCK.",
        "_legal_basis": "P51-I11; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Bypass vacancy bridge — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# V3-P51-I12: LEGAL COVERAGE ATTESTATION — deklaracja pokrycia (AN04)
# ═══════════════════════════════════════════════════════════════════════════════
_at := object.get(_ctx, "coverage_attestation", {})
_at_consistent := object.get(_at, "counter_consistent", false)
_at_attested := object.get(_at, "attested", false)
_at_caveats := object.get(_at, "caveats_count", 0)
_at_caveats_max := _th("v3_p51_caveats_max", 0)

routing_at12 = "BLOCK_AND_ALERT" {
    _has_flag("attestation_bypassed")
} else = "BLOCK_AND_ALERT" {
    not _at_consistent
} else = "AUTO_FILE" {
    _at_attested
} else = "TRIAGE_QUEUE" {
    _at_caveats > _at_caveats_max
} else = "TRIAGE_QUEUE" {
    true
}

coverage_attestation_decision = cert {
    _activated
    object.get(_ctx, "analysis", "") == "coverage_attestation"
    routing_at12 == "AUTO_FILE"
    cert := _certificate(451012, {
        "rule_id": "jdg.v3_p51_coverage_deserts.coverage_attestation",
        "decision_mode": "AUTO_POST",
        "_routing": routing_at12,
        "_routing_reason": "DESERTS: atestacja spójna, zero zastrzeżeń — P68 widzi dokładnie, co silnik wie.",
        "_legal_basis": "P51-I12; P68 (certyfikacja finalna) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": [],
        "attested": _at_attested,
        "caveats_count": _at_caveats,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "coverage_attestation"
    routing_at12 == "TRIAGE_QUEUE"
    cert := _certificate(451012, {
        "rule_id": "jdg.v3_p51_coverage_deserts.coverage_attestation",
        "decision_mode": "TRIAGE",
        "_routing": routing_at12,
        "_routing_reason": "DESERTS: atestacja z zastrzeżeniami — liczniki jawne dla certyfikatu P68.",
        "_legal_basis": "P51-I12; honesty (protokół 14 P51) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Atestacja z zastrzeżeniami — rejestr jawny."],
        "attested": _at_attested,
        "caveats_count": _at_caveats,
        "caveats_max": _at_caveats_max,
    })
} else = cert {
    _activated
    object.get(_ctx, "analysis", "") == "coverage_attestation"
    routing_at12 == "BLOCK_AND_ALERT"
    cert := _certificate(451012, {
        "rule_id": "jdg.v3_p51_coverage_deserts.coverage_attestation",
        "decision_mode": "BLOCK",
        "_routing": routing_at12,
        "_routing_reason": "DESERTS: liczniki atestacji niespójne / bypass — atestacja zablokowana (fail-closed).",
        "_legal_basis": "P51-I12; V1 zasada 6 (fail-closed) [NIEZWERYFIKOWANE — ISAP]",
        "_warnings": ["[V3-P51] Liczniki atestacji niespójne — ZABLOKOWANE."],
    })
}

# ═══════════════════════════════════════════════════════════════════════════════
# DECIDE — routing analiz (else-chain deterministyczny, fail-closed)
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
    not _snapshot_ok
} else := desert_register_decision {
    desert_register_decision.rule_id != ""
} else := desert_risk_decision {
    desert_risk_decision.rule_id != ""
} else := desert_cards_decision {
    desert_cards_decision.rule_id != ""
} else := chain_metric_decision {
    chain_metric_decision.rule_id != ""
} else := semi_auto_drafting_decision {
    semi_auto_drafting_decision.rule_id != ""
} else := systemic_sweep_decision {
    systemic_sweep_decision.rule_id != ""
} else := law_radar_block_decision {
    law_radar_block_decision.rule_id != ""
} else := desert_heatmap_decision {
    desert_heatmap_decision.rule_id != ""
} else := testless_sweep_decision {
    testless_sweep_decision.rule_id != ""
} else := quarterly_goals_decision {
    quarterly_goals_decision.rule_id != ""
} else := vacancy_bridge_decision {
    vacancy_bridge_decision.rule_id != ""
} else := coverage_attestation_decision {
    coverage_attestation_decision.rule_id != ""
} else := default_decide {
    true
}

default_decide := {
    "matched": false,
    "rule_id": "jdg.v3_p51_coverage_deserts.no_match",
    "package": "jdg.v3_p51_coverage_deserts",
    "priority": 999999,
}
