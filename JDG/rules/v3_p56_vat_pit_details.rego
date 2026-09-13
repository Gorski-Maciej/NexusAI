# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P56 VAT I PIT — SZCZEGÓŁY MATERIALNE (V3 FORTRESS) —
# MIEJSCE ŚWIADCZENIA, GTU/PROCEDURY, KOSZTY ART. 22/23, ULGI I INTERAKCJE
# ===============================================================================
# Warstwa VAT/PIT ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu P56
# Sekcja 10):
#   I01 Place-of-supply rule pack (art. 28b B2B NIP UE → kraj kontrahenta;
#       art. 28k usługi elektroniczne; art. 42 WDT/WNT + swap ust. 10a;
#       import usług — odwrócone obciążenie; brak NIP UE = NEEDS_ADVICE),
#   I02 GTU classification as data (PKWiU→GTU_01..13 jako dane wersjonowane
#       z rocznikami — zmiana tabeli GTU = zmiana danych, nie kodu),
#   I03 Procedure markers engine (auto-oznaczanie pól JPK: MPP/TP/FP/WEW/GTU
#       z blokadą niezgodnych oznaczeń ręcznych — fail-closed),
#   I04 KIS interpretation registry (rejestr interpretacji KIS powiązanych
#       z regułami; reguła o wysokim ryzyku sporu bez interpretacji =
#       NEEDS_ADVICE),
#   I05 Cost exclusion guard (art. 23: reprezentacja, automobile — koszt
#       w kategorii wyłączonej = BLOCK; kategoria wątpliwa = NEEDS_ADVICE),
#   I06 Ryczałt table by PKWiU (stawki art. 12 jako dane z oknami rocznymi;
#       wiersz bez okna ważności = BLOCK — P53-I10),
#   I07 Mixed-sales proportion engine (art. 90 — proporcje odliczeń VAT
#       z przeliczeniem kwartalnym przy zmiennych obrotach),
#   I08 Relief interaction matrix (ryczałt↔ZUS↔kwota wolna↔IP Box — asercje
#       wzajemnej zgodności; konflikt ulg = MANUAL_REVIEW),
#   I09 Non-monetary income rules (art. 14 ust. 2 pkt 8 — świadczenia
#       nieodpłatne, darowizny otrzymane; brak wyceny = NEEDS_ADVICE),
#   I10 VAT-non-deductible→cost flow (VAT nieodliczony → koszt podatkowy —
#       spójność VAT↔PIT; rozjazd kwot = BLOCK),
#   I11 Suspicious-pattern advice (wzorce agresywne: fałszywe faktury,
#       schematy MPP → NEEDS_ADVICE z powodem; GAAR art. 119a obrona),
#   I12 Detail-coverage score (pokrycie kartami szczegółów per domena;
#       pokrycie poniżej progu = MANUAL_REVIEW).
#
# Zasady:
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p56 — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * Konwencja P54/P55: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (klucze I01_..–I12_.. w input.v3_p56); silniki liczą na danych narzędzi
#     rdzenia (vat_rate_engine, vat_mpp_auto_detector, p13_crossborder_toolkit,
#     pit_temporal_snapshot_engine, tax_form_whatif_simulator, p12_uor_*).
#   * Fail-closed (V1 zasada 6): brak snapshotu progów, luka NIP UE, wiersz
#     GTU/ryczałtu bez okna, niezgodne oznaczenie procedury, koszt wyłączony
#     art. 23, rozjazd VAT↔PIT, przychód bez wyceny = BLOCK / NEEDS_ADVICE —
#     nigdy ciche AUTO_POST (protokół 05 promptu P56).
#   * Honesty: wartości prawne [NIEZWERYFIKOWANE — ISAP/podatki.gov.pl] (Q01);
#     bez maskowania (konwencja P47–P55).
#   * Aktywacja: input.jdg_entrepreneur.v3_p56_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p56_vat_pit_details.<analiza>.
#   * Kontrakty: P03 (kontrakt werdyktu), P05/P53 (okna + day-0), P06
#     (ADR-002), VAT_MACRO_P03/VAT_MICRO_P04/PIT_MACRO_P05/PIT_MICRO_P06
#     (VAT/PIT macro/micro — rozszerzamy, nie duplikujemy), P13 (cross-border),
#     P14 (limit 200k), P18 (ryczałt zdrowotna), P46 (parametry-as-data),
#     P51 (pustynie prawne — wspólny rejestr), P55 (ZUS/ulgi — K-P55-2/
#     K-P55-4 accumulator@D wzorzec dla proporcji), P37 (metryki), P39
#     (bramki merge), P48 (mirror), P68 (re-certyfikacja).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p56_vat_pit_details
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p56_vat_pit_details

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p56_check", false) == true
_ctx := object.get(input, "v3_p56", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p56_snapshot := data.jdg.thresholds.v3_p56

_snapshot_ok = true {
	count(_p56_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p56_snapshot) > 0
	value := object.get(_p56_snapshot, key, null)
	value != null
} else = fallback

_not(x) = true {
	x == false
}

_not(x) = false {
	x == true
}

# ── Fail-closed gdy snapshot progów niedostępny ────────────────────────────────
fail_closed_decision := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.thresholds_missing",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P56 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Place-of-supply rule pack (art. 28b/28k/42; import usług) ────────────
# Silnik: p13_crossborder_toolkit + vat_rate_engine — wykrywa usługi B2B/WDT
# bez NIP UE (luka danych = pustynia P51). Luka → NEEDS_ADVICE.
i01_place_of_supply := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.place_of_supply",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456001,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("art. 28b/28k/42 — sprawdzane transakcje cross-border bez NIP UE: %v (pustynia miejsca świadczenia — P51)", [count(gaps)]),
	"metrics": {"cases_total": cases_total, "gaps_nip_ue": count(gaps)},
	"_legal_basis": "VAT art. 28b, 28k, 42 ust. 1, 42 ust. 10a [NIEZWERYFIKOWANE — ISAP]; P51 pustynie",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_place_of_supply_pack", {})
	cases_total := object.get(_ctx_i01, "cases_total", 0)
	gaps := object.get(_ctx_i01, "gaps_nip_ue", [])
	count(gaps) >= 1
}

# ── I02: GTU classification as data ───────────────────────────────────────────
# Silnik: tabela PKWiU→GTU z vat_mpp_auto_detector/vat.rego; wiersz bez
# rocznika/okna ważności = BLOCK (P46 parametry-as-data; temporalność P53).
i02_gtu_data := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.gtu_classification_data",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456002,
	"decision": "BLOCK",
	"reason": sprintf("GTU jako dane — wiersze bez okna ważności/rocznika PKWiU: %v z %v (P46; P53-I10)", [count(bad), rows_total]),
	"metrics": {"rows_total": rows_total, "rows_missing_window": count(bad)},
	"_legal_basis": "VAT art. 109a ust. 10 [NIEZWERYFIKOWANE — ISAP]; P46; P53-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_gtu_classification_data", {})
	rows_total := object.get(_ctx_i02, "rows_total", 0)
	bad := object.get(_ctx_i02, "rows_missing_window", [])
	count(bad) >= 1
}

# ── I03: Procedure markers engine (MPP/TP/FP/WEW/GTU) ─────────────────────────
# Silnik: vat_mpp_auto_detector — auto-oznaczanie pól JPK; niezgodność
# oznaczenia ręcznego z regułą = BLOCK (błąd ludzki niedopuszczalny;
# MPP obowiązkowy: załącznik 15 / art. 17 ust. 1 pkt 4).
i03_procedure_markers := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.procedure_markers",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456003,
	"decision": "BLOCK",
	"reason": sprintf("pola JPK niezgodne z regułami procedur: %v z %v (MPP/TP/FP/WEW — fail-closed)", [count(conflicts), checks_total]),
	"metrics": {"checks_total": checks_total, "conflicts": count(conflicts)},
	"_legal_basis": "VAT art. 19a ust. 1 pkt 4, art. 17 ust. 1 pkt 4, art. 109a–109e [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_procedure_markers_engine", {})
	checks_total := object.get(_ctx_i03, "checks_total", 0)
	conflicts := object.get(_ctx_i03, "conflicts", [])
	count(conflicts) >= 1
}

# ── I04: KIS interpretation registry ──────────────────────────────────────────
# Silnik: rejestr interpretacji (ID, data, teza) vs reguły wysokiego ryzyka
# sporu. Reguła bez interpretacji = NEEDS_ADVICE (wykładnia udokumentowana).
i04_kis_registry := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.kis_interpretation_registry",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456004,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("reguły wysokiego ryzyka sporu bez interpretacji KIS: %v (rejestr: %v wpisów)", [count(uncovered), registry_size]),
	"metrics": {"registry_size": registry_size, "uncovered": count(uncovered)},
	"_legal_basis": "ORD-IN art. 14b–14k [NIEZWERYFIKOWANE — ISAP]; P51 karty szczegółów",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_kis_interpretation_registry", {})
	registry_size := object.get(_ctx_i04, "registry_size", 0)
	uncovered := object.get(_ctx_i04, "uncovered_topics", [])
	count(uncovered) >= 1
}

# ── I05: Cost exclusion guard (art. 23 — wyłączenia) ──────────────────────────
# Silnik: p12_uor_toolkit/koszty — kategorie art. 23 (reprezentacja,
# automobile). Koszt w kategorii wyłączonej = BLOCK (zawsze).
i05_cost_exclusion := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.cost_exclusion_guard",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456005,
	"decision": "BLOCK",
	"reason": sprintf("koszty w kategoriach wyłączonych art. 23: %v z %v (reprezentacja/automobile — fail-closed)", [count(excluded), costs_total]),
	"metrics": {"costs_total": costs_total, "excluded": count(excluded)},
	"_legal_basis": "PIT art. 23 ust. 1 pkt 4, pkt 23 [NIEZWERYFIKOWANE — ISAP]; P03 koszt objęty",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_cost_exclusion_guard", {})
	costs_total := object.get(_ctx_i05, "costs_total", 0)
	excluded := object.get(_ctx_i05, "excluded_ids", [])
	count(excluded) >= 1
}

# ── I06: Ryczałt table by PKWiU (art. 12) ─────────────────────────────────────
# Silnik: pit_temporal_snapshot_engine — stawki jako dane z oknami rocznymi.
# Wiersz bez okna ważności = BLOCK (P46; P53-I10; test per wiersz).
i06_ryczalt_table := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.ryczalt_table_by_pkwiu",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456006,
	"decision": "BLOCK",
	"reason": sprintf("tabela ryczałtu art. 12 — wiersze bez okna ważności: %v z %v", [count(bad), rows_total]),
	"metrics": {"rows_total": rows_total, "rows_missing_window": count(bad)},
	"_legal_basis": "UoPR art. 12 [NIEZWERYFIKOWANE — ISAP]; P46; P53-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_ryczalt_table_by_pkwiu", {})
	rows_total := object.get(_ctx_i06, "rows_total", 0)
	bad := object.get(_ctx_i06, "rows_missing_window", [])
	count(bad) >= 1
}

# ── I07: Mixed-sales proportion engine (art. 90) ──────────────────────────────
# Silnik: proporcje odliczeń VAT przy obrotach mieszanych; obroty zmienne
# w roku = wymagane przeliczenie kwartalne → MANUAL_REVIEW (kontrola człowieka
# nad deklaracją, nie ciche AUTO_POST).
i07_proportions := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.mixed_sales_proportions",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456007,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("art. 90 — obroty mieszane ze zmiennymi obrotami w roku: proporcja bazowa %.2f%% wymaga przeliczenia kwartalnego", [ratio_pct]),
	"metrics": {"ratio_pct": ratio_pct, "quarterly_recalc": 1},
	"_legal_basis": "VAT art. 90 ust. 3, ust. 6 [NIEZWERYFIKOWANE — ISAP]; P52 prorata",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_mixed_sales_proportions", {})
	taxable := object.get(_ctx_i07, "taxable_turnover", 0)
	exempt := object.get(_ctx_i07, "exempt_turnover", 0)
	total := taxable + exempt
	total > 0
	ratio_pct := (taxable / total) * 100
	object.get(_ctx_i07, "turnover_varies_in_year", false) == true
}

# ── I08: Relief interaction matrix ────────────────────────────────────────────
# Silnik: tax_form_whatif_simulator + dane P55 — macierz ryczałt↔ZUS↔kwota
# wolna↔IP Box; konflikt par (np. IP Box przy ryczałcie) = MANUAL_REVIEW
# (K-P55-2; asercje wzajemnej zgodności testowane, nie zakładane).
i08_relief_matrix := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.relief_interaction_matrix",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456008,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("konflikty ulg w macierzy interakcji (ryczałt↔ZUS↔kwota wolna↔IP Box): %v przy %v aktywnych ulgach", [count(conflicts), active_count]),
	"metrics": {"reliefs_active": active_count, "conflicts": count(conflicts)},
	"_legal_basis": "PIT art. 30ca, 30f; UoPR art. 12; P55 K-P55-2 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_relief_interaction_matrix", {})
	active_count := object.get(_ctx_i08, "reliefs_active", 0)
	conflicts := object.get(_ctx_i08, "conflicts", [])
	count(conflicts) >= 1
}

# ── I09: Non-monetary income rules (art. 14 ust. 2 pkt 8) ─────────────────────
# Silnik: przychody nieodpłatne (świadczenia, darowizny otrzymane) — brak
# wyceny = NEEDS_ADVICE (pustynia PIT; wycena obowiązkowa).
i09_non_monetary := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.non_monetary_income",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("przychody nieodpłatne bez wyceny (art. 14 ust. 2 pkt 8): %v z %v — NEEDS_ADVICE", [count(unvalued), items_total]),
	"metrics": {"items_total": items_total, "unvalued": count(unvalued)},
	"_legal_basis": "PIT art. 14 ust. 2 pkt 8 [NIEZWERYFIKOWANE — ISAP]; P51 pustynie",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_non_monetary_income", {})
	items_total := object.get(_ctx_i09, "items_total", 0)
	unvalued := object.get(_ctx_i09, "unvalued_ids", [])
	count(unvalued) >= 1
}

# ── I10: VAT-non-deductible→cost flow (spójność VAT↔PIT) ──────────────────────
# Silnik: p12_uor_accounting_toolkit — VAT nieodliczony (prekluzja, proporcje
# art. 90) → koszt podatkowy. Rozjazd kwot między ewidencjami = BLOCK
# (jedno źródło prawdy VAT↔PIT).
i10_vat_cost_flow := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.vat_nondeductible_cost_flow",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456010,
	"decision": "BLOCK",
	"reason": sprintf("rozjazd VAT nieodliczony ↔ koszt podatkowy (spójność VAT↔PIT): %v z %v pozycji", [count(mismatches), items_total]),
	"metrics": {"items_total": items_total, "mismatches": count(mismatches)},
	"_legal_basis": "VAT art. 86/90 + PIT art. 22 ust. 1 [NIEZWERYFIKOWANE — ISAP]; P03/P05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_vat_nondeductible_cost_flow", {})
	items_total := object.get(_ctx_i10, "items_total", 0)
	mismatches := object.get(_ctx_i10, "mismatch_ids", [])
	count(mismatches) >= 1
}

# ── I11: Suspicious-pattern advice (GAAR art. 119a obrona) ────────────────────
# Silnik: vat_innovation_tools/pit_innovation_tools — wzorce agresywne
# (fałszywe faktury, schematy MPP — sztuczne podziały poniżej progu).
# Sygnał wysoki = NEEDS_ADVICE z powodem (obrona GAAR: decyzja człowieka).
i11_suspicious := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.suspicious_pattern_advice",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456011,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("wzorce agresywne wymagające człowieka (GAAR art. 119a obrona): %v z %v sygnałów", [count(hits), signals_total]),
	"metrics": {"signals_total": signals_total, "high_hits": count(hits)},
	"_legal_basis": "VAT art. 19a ust. 1 pkt 4; STL art. 119a [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_suspicious_pattern_advice", {})
	signals_total := object.get(_ctx_i11, "signals_total", 0)
	hits := object.get(_ctx_i11, "high_hits", [])
	count(hits) >= 1
}

# ── I12: Detail-coverage score ────────────────────────────────────────────────
# Silnik: pokrycie kartami szczegółów (przepis→warunki→reguła→test→
# interpretacja) per domena. Pokrycie poniżej progu z ADR-002 = MANUAL_REVIEW
# (P51 cel 100% dla przypadków HIGH-frequency).
i12_coverage := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.detail_coverage_score",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 456012,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("pokrycie kartami szczegółów poniżej progu %v%%: domeny %v z %v", [min_pct, count(below), domains_total]),
	"metrics": {"domains_total": domains_total, "below_min": count(below), "min_coverage_pct": min_pct},
	"_legal_basis": "P51 pustynie prawne — miernik pokrycia; prompt P56 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_detail_coverage_score", {})
	min_pct := _th("v3_p56_coverage_min_pct", 80)
	domains_total := object.get(_ctx_i12, "domains_total", 0)
	below := object.get(_ctx_i12, "domains_below_min", [])
	count(below) >= 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P55):
# najpierw BLOCK, potem NEEDS_ADVICE/MANUAL_REVIEW, na końcu PASS.
# Bez flagi v3_p56_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i02_gtu_data {
	_snapshot_ok
	_activated
	i02_gtu_data.decision == "BLOCK"
} else := i03_procedure_markers {
	_snapshot_ok
	_activated
	i03_procedure_markers.decision == "BLOCK"
} else := i05_cost_exclusion {
	_snapshot_ok
	_activated
	i05_cost_exclusion.decision == "BLOCK"
} else := i06_ryczalt_table {
	_snapshot_ok
	_activated
	i06_ryczalt_table.decision == "BLOCK"
} else := i10_vat_cost_flow {
	_snapshot_ok
	_activated
	i10_vat_cost_flow.decision == "BLOCK"
} else := i01_place_of_supply {
	_snapshot_ok
	_activated
	i01_place_of_supply.decision == "NEEDS_ADVICE"
} else := i04_kis_registry {
	_snapshot_ok
	_activated
	i04_kis_registry.decision == "NEEDS_ADVICE"
} else := i09_non_monetary {
	_snapshot_ok
	_activated
	i09_non_monetary.decision == "NEEDS_ADVICE"
} else := i11_suspicious {
	_snapshot_ok
	_activated
	i11_suspicious.decision == "NEEDS_ADVICE"
} else := i07_proportions {
	_snapshot_ok
	_activated
	i07_proportions.decision == "MANUAL_REVIEW"
} else := i08_relief_matrix {
	_snapshot_ok
	_activated
	i08_relief_matrix.decision == "MANUAL_REVIEW"
} else := i12_coverage {
	_snapshot_ok
	_activated
	i12_coverage.decision == "MANUAL_REVIEW"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p56_vat_pit_details.no_match",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P56 niewyzwolony (brak flagi v3_p56_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P55",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p56_vat_pit_details.all_green",
	"package": "jdg.v3_p56_vat_pit_details",
	"priority": 1,
	"decision": "PASS",
	"reason": "P56: brak naruszeń szczegółów materialnych VAT/PIT (12 analiz zielonych)",
	"metrics": {"analyses": 12},
	"_legal_basis": "VAT art. 28b/28k/42/90/109a–109e; PIT art. 14/22/23/30ca/30f; UoPR art. 12 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
