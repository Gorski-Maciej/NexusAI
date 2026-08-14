# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R08 GLM52 ORDYNACJA PODATKOWA + OBRONA PODATNIKA — INNOWACJE
# ═══════════════════════════════════════════════════════════════════════════════
# Package: jdg.r08_ordynacja_obrona_innovations
# Raport: RAPORT_08_ORDYNACJA_OBRONA.txt (Kampania GLM 5.2 — seria 08/25)
#
# Prompt 08/25 (Ordynacja podatkowa + obrona podatnika — postępowania,
# przedawnienie, korekty, KAS, sądy):
#   R08-INN-01 interest_calculator_temporal — kalkulator odsetek z PEŁNĄ
#                                           temporalnością: harmonogram stóp
#                                           per okres (stawki zmieniają się
#                                           w czasie — 200% lombardu),
#                                           odsetki per pod-okres + suma
#                                           (istniejące kalkulatory miały
#                                           pojedynczą stawkę)
#   R08-INN-02 proceeding_deadline_alerts_3lvl — asystent postępowania:
#                                           KAŻDY termin z 3 poziomami
#                                           alertów (RED ≤3 dni / AMBER ≤14
#                                           dni / GREEN) + next_action
#                                           (proceeding_tracker eskalował
#                                           dopiero PO terminie)
#   R08-INN-03 correspondence_autopack — auto-generator korespondencji z US
#                                           z podstawą prawną: pełny pakiet
#                                           (pismo + _legal_basis + checklist
#                                           + termin + tryb doręczenia) —
#                                           fail-closed na brak danych
#   R08-INN-04 judgment_predictor_wsa_nsa — predykcja wyroków WSA/NSA:
#                                           prawdopodobieństwo korzystnego
#                                           wyroku (0-100) na bazie trendu,
#                                           wagi precedensu, artykułu,
#                                           instancji (judicial_trend robił
#                                           analizę trendu — bez predykcji
#                                           wyniku konkretnej sprawy)
#   R08-INN-05 limitation_evidence_monitor — monitor przedawnień Z DOWODEM:
#                                           per zobowiązanie — data
#                                           przedawnienia, remaining_days,
#                                           statute_barred, certyfikat
#                                           dowodowy (decision_hash, wersje
#                                           bundle/rule/threshold) gotowy do
#                                           obrony przed US (art. 70 OrdPU)
#
# Zgodność: ADR-001..009/017/022, Ordynacja podatkowa (Dz.U. 2025 poz. 234),
#           art. 12/14b/21/44/53-56/56b/67a/70/72-81/81b/117ba/120-129/
#           138a-138o/139-141/193a/223/262/281-292; thresholds.ord (zero
#           hardcode); INV-018; First-Match-Wins else-chain.
# package: jdg.r08_ordynacja_obrona_innovations
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.r08_ordynacja_obrona_innovations

import future.keywords.if
import future.keywords.in

default decide := {"matched": false, "rule_id": "jdg.r08_ordynacja_obrona_innovations.no_match", "package": "jdg.r08_ordynacja_obrona_innovations", "priority": 999999}

# ── Progi zewnętrzne (ADR-002 — zero hardcode) ────────────────────────────────
_ord := object.get(object.get(data, "jdg", {}), "thresholds", {})
_th_ord := object.get(_ord, "ord", {})

ref_lombard_rate := object.get(_th_ord, "reference_rate", 0.0625)        # stawka lombardowa NBP (2026)
base_interest_rate := object.get(_th_ord, "tax_interest_rate", 0.125)    # odsetki = 200% lombardu (art. 56)
reduced_interest_rate := object.get(_th_ord, "reduced_interest_rate", 0.0625)  # 50% po korekcie w 7 dni (art. 56b)
prolongation_fee_rate := object.get(_th_ord, "prolongation_fee_rate", 0.0625)  # opłata prolongacyjna 50% odsetek (art. 67b)
overpayment_rate := object.get(_th_ord, "overpayment_rate", 0.085)      # oprocentowanie nadpłaty (art. 78)
limitation_years := object.get(_th_ord, "limitation_years", 5)           # art. 70 § 1 — 5 lat
appeal_days := object.get(_th_ord, "appeal_days", 14)                    # art. 223 — odwołanie 14 dni
interpretation_days := object.get(_th_ord, "interpretation_days", 30)    # art. 14d — interpretacja 30 dni
summon_response_days := object.get(_th_ord, "summon_response_days", 7)   # odpowiedź na wezwanie
poa_days := object.get(_th_ord, "poa_days", 30)                          # pełnomocnictwo
white_list_days := object.get(_th_ord, "white_list_days", 30)            # art. 117ba — 30 dni
refund_months := object.get(_th_ord, "refund_months", 3)                 # art. 77 — zwrot nadpłaty
limitation_evidence_warn_days := object.get(_th_ord, "limitation_evidence_warn_days", 180)  # alarm z wyprzedzeniem

# ── Helper: zaokrąglenie 2 miejsca (spójne z p11/round2) ─────────────────────
round2(x) := floor((x * 100) + 0.5) / 100

# ═══════════════════════════════════════════════════════════════════════════════
# R08-INN-01: INTEREST CALCULATOR TEMPORAL — kalkulator odsetek z pełną
#             temporalnością (art. 53-56, 56b OrdPU)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza int_temporal: {principal, due_date, paid_date, periods:
# [{from, to, rate}] | violation_type}. Wynik: harmonogram per pod-okres
# (dni × stawka) + suma odsetek + stawka efektywna. Stawki zmieniają się
# w czasie (200% lombardu) — pojedyncza stawka to zaniżenie/zaniedbanie.
int_temp_input := object.get(input, "int_temporal", {})
int_temp_principal := max([0, object.get(int_temp_input, "principal", 0)])
int_temp_days := max([0, object.get(int_temp_input, "days", 0)])
int_temp_periods := object.get(int_temp_input, "periods", [])
int_temp_violation := object.get(int_temp_input, "violation_type", "STANDARD")

# Stawka per okres — z harmonogramu hosta; fallback do stawek bazowych.
int_temp_rate(period) := object.get(period, "rate", base_interest_rate)
int_temp_days_of(period) := max([0, object.get(period, "days", 0)])

int_temp_line(period) := {
    "from": object.get(period, "from", "?"),
    "to": object.get(period, "to", "?"),
    "days": int_temp_days_of(period),
    "rate_pct": round2(int_temp_rate(period) * 100),
    "interest": round2(int_temp_principal * int_temp_rate(period) * int_temp_days_of(period) / 365),
}

int_temp_schedule := [int_temp_line(p) | p := int_temp_periods[_]]
int_temp_total := sum([line.interest | line := int_temp_schedule[_]])

# Jeśli host nie podał harmonogramu — pojedynczy okres z pełną liczbą dni.
int_temp_effective_rate := base_interest_rate if {
    count(int_temp_periods) == 0
} else := int_temp_rate(int_temp_periods[0]) if {
    count(int_temp_periods) == 1
} else := round2(int_temp_total * 365 / (int_temp_principal * int_temp_days)) if {
    int_temp_principal > 0
    int_temp_days > 0
} else := 0

decide := {
    "matched": true,
    "rule_id": "jdg.r08_ordynacja_obrona_innovations.interest_calculator_temporal",
    "package": "jdg.r08_ordynacja_obrona_innovations",
    "priority": 11001,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "int_principal": int_temp_principal,
    "int_days_total": int_temp_days,
    "int_schedule": int_temp_schedule,
    "int_interest_total": int_temp_total,
    "int_effective_rate_pct": int_temp_effective_rate,
    "int_reduced_rate_eligible": int_temp_violation == "CORRECTION_7DAYS",
    "int_reduced_savings": round2(int_temp_total * 0.5) if {int_temp_violation == "CORRECTION_7DAYS"} else 0,
    "_routing": "",
    "_routing_reason": "Kalkulator odsetek z pełną temporalnością — harmonogram stóp per okres (art. 53-56 OrdPU)",
    "_legal_basis": "OrdPU art. 53-56, 56b; art. 67b (opłata prolongacyjna); art. 78 (nadpłata)",
    "_warnings": [sprintf("ODSETKI TEMPORALNE: %s PLN za %d dni (stawka efektywna %.2f%%). Harmonogram: %d pod-okresów.", [round2(int_temp_total), int_temp_days, int_temp_effective_rate, count(int_temp_schedule)])],
} if {
    object.get(input.jdg_entrepreneur, "r08_ordynacja_check", false) == true
    object.get(input, "int_temporal", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R08-INN-02: PROCEEDING DEADLINE ALERTS 3LVL — asystent postępowania z
#             trzema poziomami alertów per termin (art. 120-129, 139-141, 223)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza proceeding_alerts: {deadlines: [{label, days_left, type}]}.
# Poziom: RED ≤3 dni (BLOCK_AND_ALERT), AMBER ≤14 dni (TRIAGE_QUEUE),
# GREEN >14 dni (brak routingu). Każdy termin dostaje next_action wg typu.
pr_alert_input := object.get(input, "proceeding_alerts", {})
pr_alert_deadlines := object.get(pr_alert_input, "deadlines", [])

pr_alert_level(days) := "RED" if {
    days <= 3
} else := "AMBER" if {
    days <= 14
} else := "GREEN" if {
    true
}

pr_alert_routing(level) := "BLOCK_AND_ALERT" if {
    level == "RED"
} else := "TRIAGE_QUEUE" if {
    level == "AMBER"
} else := "" if {
    true
}

pr_alert_next_action(alert_type, days) := "Złóż odwołanie NATYCHMIAST (art. 223 — 14 dni) — przekroczenie = decyzja ostateczna." if {
    alert_type == "APPEAL"
    days <= 14
} else := "Odpowiedz na wezwanie (art. 155) — kara porządkowa do 2 800 zł (art. 262)." if {
    alert_type == "SUMMON"
    days <= 7
} else := "Uzupełnij wniosek (art. 169) — bezczynność = pozostawienie bez rozpoznania." if {
    alert_type == "COMPLETION"
    days <= 14
} else := "Złóż ponaglenie na bezczynność (art. 141) — organ ma 2 miesiące (art. 139)." if {
    alert_type == "PROCEEDING"
    days <= 30
} else := "Monitoruj termin — przygotuj dokumentację." if {
    true
}

pr_alert_item(d) := {
    "label": object.get(d, "label", "termin"),
    "type": object.get(d, "type", "PROCEEDING"),
    "days_left": object.get(d, "days_left", 999),
    "level": pr_alert_level(object.get(d, "days_left", 999)),
    "next_action": pr_alert_next_action(object.get(d, "type", "PROCEEDING"), object.get(d, "days_left", 999)),
}

pr_alert_items := [pr_alert_item(d) | d := pr_alert_deadlines[_]]
pr_alert_red := count([i | i := pr_alert_items[_]; i.level == "RED"])
pr_alert_amber := count([i | i := pr_alert_items[_]; i.level == "AMBER"])
pr_alert_max_routing := "BLOCK_AND_ALERT" if {
    pr_alert_red > 0
} else := "TRIAGE_QUEUE" if {
    pr_alert_amber > 0
} else := "" if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r08_ordynacja_obrona_innovations.proceeding_deadline_alerts_3lvl",
    "package": "jdg.r08_ordynacja_obrona_innovations",
    "priority": 11002,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "pr_deadlines_total": count(pr_alert_items),
    "pr_red_count": pr_alert_red,
    "pr_amber_count": pr_alert_amber,
    "pr_alerts": pr_alert_items,
    "_routing": pr_alert_max_routing,
    "_routing_reason": sprintf("Asystent postępowania — %d terminów (RED: %d, AMBER: %d). %s", [count(pr_alert_items), pr_alert_red, pr_alert_amber, "RED ≤3 dni / AMBER ≤14 dni / GREEN"]),
    "_legal_basis": "OrdPU art. 120-129 (postępowanie), 139-141 (bezczynność/ponaglenie), 155/169 (wezwanie/uzupełnienie), 223 (odwołanie), 262 (kara porządkowa)",
    "_warnings": [sprintf("POSTĘPOWANIE — terminów: %d | RED (≤3 dni): %d | AMBER (≤14 dni): %d. Działaj wg next_action per termin.", [count(pr_alert_items), pr_alert_red, pr_alert_amber])],
} if {
    object.get(input.jdg_entrepreneur, "r08_ordynacja_check", false) == true
    object.get(input, "proceeding_alerts", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R08-INN-03: CORRESPONDENCE AUTOPACK — auto-generator korespondencji z US
#             z podstawą prawną (art. 14b/72-77/223/117ba, KKS art. 16)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza correspondence: {letter_type, taxpayer {nip,name}, case_ref,
# key_facts}. Wynik: gotowy pakiet pisma: template, _legal_basis, deadline,
# delivery (e-US/e-Doręczenia), checklist kompletności (fail-closed:
# missing_fields -> routing TRIAGE_QUEUE, nigdy AUTO_POST).
corr_input := object.get(input, "correspondence", {})
corr_type := object.get(corr_input, "letter_type", "")
corr_taxpayer := object.get(corr_input, "taxpayer", {})
corr_nip := object.get(corr_taxpayer, "nip", "")
corr_name := object.get(corr_taxpayer, "name", "")
corr_case_ref := object.get(corr_input, "case_ref", "")

corr_templates := {
    "wniosek_o_interpretacje": {
        "title": "Wniosek o interpretację indywidualną",
        "recipient": "Dyrektor Krajowej Informacji Skarbowej",
        "legal_basis": "OrdPU art. 14b § 1 (interpretacja indywidualna), art. 14d (termin 30 dni)",
        "deadline_days": 0,
        "fee_pln": 40,
        "required": ["Dane wnioskodawcy", "Przedmiot wniosku", "Stan faktyczny / zdarzenie przyszłe", "Własne stanowisko", "Opłata 40 zł"],
        "delivery": "e-US / e-Doręczenia",
    },
    "odwolanie": {
        "title": "Odwołanie od decyzji",
        "recipient": "Organ I instancji (przez, do organu odwoławczego)",
        "legal_basis": "OrdPU art. 220 § 1, art. 223 § 1 (termin 14 dni), art. 229 (organ odwoławczy)",
        "deadline_days": 14,
        "fee_pln": 0,
        "required": ["Nr i data decyzji", "Zarzuty", "Uzasadnienie", "Wniosek o uchylenie/zmianę", "Podpis"],
        "delivery": "e-US / e-Doręczenia / poczta",
    },
    "wniosek_o_zwrot_nadplaty": {
        "title": "Wniosek o stwierdzenie i zwrot nadpłaty",
        "recipient": "Naczelnik właściwego US",
        "legal_basis": "OrdPU art. 72 § 1, art. 75 § 1, art. 77 § 1 (termin 3 mies.), art. 78 (oprocentowanie)",
        "deadline_days": 0,
        "fee_pln": 0,
        "required": ["Kwota nadpłaty", "Rachunek bankowy", "Podstawa powstania nadpłaty", "Deklaracja korygująca (jeśli dotyczy)", "Podpis"],
        "delivery": "e-US / e-Doręczenia",
    },
    "czynny_zal": {
        "title": "Czynny żal — zawiadomienie o popełnieniu czynu zabronionego",
        "recipient": "Naczelnik właściwego US",
        "legal_basis": "KKS art. 16 § 1-2 (niepodleganie karze), OrdPU art. 12 (zawiadomienie)",
        "deadline_days": 0,
        "fee_pln": 0,
        "required": ["Ujawnienie czynu", "Okoliczności sprawy", "Uiszczenie uszczuplenia (jeśli dotyczy)", "Wniosek o odstąpienie od ukarania", "Podpis"],
        "delivery": "e-US / e-Doręczenia",
    },
    "wniosek_o_ulge_w_splacie": {
        "title": "Wniosek o ulgę w spłacie zobowiązania",
        "recipient": "Naczelnik właściwego US",
        "legal_basis": "OrdPU art. 67a § 1 (umorzenie/raty/odroczenie), art. 67b (opłata prolongacyjna)",
        "deadline_days": 0,
        "fee_pln": 0,
        "required": ["Kwota zobowiązania", "Okoliczności (ważny interes podatnika / interes publiczny)", "Proponowany harmonogram", "Dokumenty potwierdzające sytuację", "Podpis"],
        "delivery": "e-US / e-Doręczenia",
    },
    "powiadomienie_o_platnosci_na_rachunek": {
        "title": "Zawiadomienie o zapłacie na rachunek spoza Białej Listy",
        "recipient": "Naczelnik właściwego US",
        "legal_basis": "OrdPU art. 117ba § 3 (30 dni na zawiadomienie — brak = sankcja 20% odsetek), VAT art. 22p",
        "deadline_days": 30,
        "fee_pln": 0,
        "required": ["Numer faktury", "Nr rachunku kontrahenta", "Kwota płatności", "Data zapłaty", "NIP kontrahenta"],
        "delivery": "e-US / e-Doręczenia",
    },
}

corr_template := object.get(corr_templates, corr_type, {})

# Kompletność pakietu: dane podatnika + case_ref. Lista wymaganych sekcji
# trafia do checklisty — host potwierdza zawartość przez case_ref.
corr_missing_fields := [f | f := {"NIP podatnika": corr_nip, "Nazwa podatnika": corr_name, "Sygnatura sprawy": corr_case_ref}[f] == ""]

corr_ready := count(corr_missing_fields) == 0
corr_routing := "" if {
    corr_ready
} else := "TRIAGE_QUEUE" if {
    true
}

corr_deadline_days := object.get(corr_template, "deadline_days", 0)

decide := {
    "matched": true,
    "rule_id": "jdg.r08_ordynacja_obrona_innovations.correspondence_autopack",
    "package": "jdg.r08_ordynacja_obrona_innovations",
    "priority": 11003,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "corr_letter_type": corr_type,
    "corr_title": object.get(corr_template, "title", "NIEZNANY TYP"),
    "corr_recipient": object.get(corr_template, "recipient", ""),
    "corr_legal_basis": object.get(corr_template, "legal_basis", ""),
    "corr_fee_pln": object.get(corr_template, "fee_pln", 0),
    "corr_deadline_days": corr_deadline_days,
    "corr_delivery": object.get(corr_template, "delivery", "e-US"),
    "corr_checklist": object.get(corr_template, "required", []),
    "corr_missing_fields": corr_missing_fields,
    "corr_ready": corr_ready,
    "_routing": corr_routing,
    "_routing_reason": sprintf("Auto-generator korespondencji '%s' — %s. %s", [corr_type, object.get(corr_template, "title", "?"), "Uzupełnij brakujące pola przed wysyłką" if {not corr_ready} else "Pakiet gotowy do wysyłki"]),
    "_legal_basis": object.get(corr_template, "legal_basis", "OrdPU"),
    "_warnings": [sprintf("KORESPONDENCJA: '%s' do %s. Termin: %s. Tryb: %s.", [object.get(corr_template, "title", "?"), object.get(corr_template, "recipient", "US"), sprintf("%d dni", [corr_deadline_days]) if {corr_deadline_days > 0} else "bez terminu ustawowego", object.get(corr_template, "delivery", "e-US")])],
} if {
    object.get(input.jdg_entrepreneur, "r08_ordynacja_check", false) == true
    corr_type != ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# R08-INN-04: JUDGMENT PREDICTOR WSA/NSA — predykcja wyroku sądu
#             administracyjnego (WSA/NSA) dla konkretnej sprawy
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza judgment: {court, article, trend {total, favorable_pct},
# precedent_weight 0-10, taxpayer_strength 0-10}. Wynik: probability 0-100,
# confidence (HIGH/MEDIUM/LOW), factors, recommendation. Model: bayes-owy
# scoring — łączna waga: trend (40%), precedens (30%), siła argumentów (30%).
judg_input := object.get(input, "judgment", {})
judg_court := object.get(judg_input, "court", "WSA")
judg_article := object.get(judg_input, "article", "")
judg_trend := object.get(judg_input, "trend", {})
judg_trend_total := object.get(judg_trend, "total", 0)
judg_trend_favorable_pct := object.get(judg_trend, "favorable_pct", 50)
judg_precedent_weight := min([10, max([0, object.get(judg_input, "precedent_weight", 5)])])
judg_taxpayer_strength := min([10, max([0, object.get(judg_input, "taxpayer_strength", 5)])])

judg_trend_component := object.get(judg_trend, "favorable_pct", 50) * 0.40
judg_precedent_component := judg_precedent_weight * 10 * 0.30
judg_strength_component := judg_taxpayer_strength * 10 * 0.30

judg_probability := round2(judg_trend_component + judg_precedent_component + judg_strength_component)

judg_confidence := "HIGH" if {
    judg_trend_total >= 15
} else := "MEDIUM" if {
    judg_trend_total >= 5
} else := "LOW" if {
    true
}

judg_routing := "TRIAGE_QUEUE" if {
    judg_probability < 40
} else := "" if {
    true
}

judg_recommendation := "Rozważ odwołanie do NSA / skargę do WSA — wysoka szansa korzystnego wyroku." if {
    judg_probability >= 65
} else := "Analizuj opłacalność — szansa umiarkowana. Rozważ ugodę/mediację lub wzmocnienie argumentacji." if {
    judg_probability >= 40
} else := "Niska szansa korzystnego wyroku — rozważ strategię alternatywną (ugoda, interpretacja, korekta)." if {
    true
}

decide := {
    "matched": true,
    "rule_id": "jdg.r08_ordynacja_obrona_innovations.judgment_predictor_wsa_nsa",
    "package": "jdg.r08_ordynacja_obrona_innovations",
    "priority": 11004,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "judg_court": judg_court,
    "judg_article": judg_article,
    "judg_trend_total": judg_trend_total,
    "judg_favorable_pct": judg_trend_favorable_pct,
    "judg_precedent_weight": judg_precedent_weight,
    "judg_taxpayer_strength": judg_taxpayer_strength,
    "judg_probability_favorable": judg_probability,
    "judg_confidence": judg_confidence,
    "judg_factors": {
        "trend_component": round2(judg_trend_component),
        "precedent_component": round2(judg_precedent_component),
        "strength_component": round2(judg_strength_component),
    },
    "judg_recommendation": judg_recommendation,
    "_routing": judg_routing,
    "_routing_reason": sprintf("Predykcja wyroku %s (art. %s) — szansa korzystnego: %.1f%% (confidence %s). %s", [judg_court, judg_article, judg_probability, judg_confidence, judg_recommendation]),
    "_legal_basis": "OrdPU art. 229-236 (odwołanie do NSA), art. 3 § 1 PPSA (skarga do WSA); orzecznictwo NSA/WSA (trend)",
    "_warnings": [sprintf("PREDYKCJA WYROKU %s: %.1f%% szansy korzystnego rozstrzygnięcia (confidence %s). Liczba orzeczeń bazowych: %d.", [judg_court, judg_probability, judg_confidence, judg_trend_total])],
} if {
    object.get(input.jdg_entrepreneur, "r08_ordynacja_check", false) == true
    object.get(input, "judgment", {}) != {}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R08-INN-05: LIMITATION EVIDENCE MONITOR — monitor przedawnień Z DOWODEM
#             (art. 70 § 1 OrdPU — 5 lat; zawieszenie art. 70 § 4-6)
# ═══════════════════════════════════════════════════════════════════════════════
# Host dostarcza limitation_monitor: {liabilities: [{type, tax_year,
# suspended, suspension_reason}]}. Wynik: per zobowiązanie data
# przedawnienia, remaining_days, statute_barred, routing, + certyfikat
# dowodowy (F4-style: decision_hash, wersje bundle/rule/threshold) gotowy
# do obrony przed US.
lim_input := object.get(input, "limitation_monitor", {})
lim_liabilities := object.get(lim_input, "liabilities", [])
lim_current_year := object.get(input.jdg_entrepreneur, "current_year", 2026)
lim_bundle_version := object.get(input.jdg_entrepreneur, "bundle_version", "v9.0.0")

lim_deadline_year(l) := (to_number(object.get(l, "tax_year", 0)) + limitation_years)
lim_remaining_years(l) := lim_deadline_year(l) - to_number(lim_current_year)
lim_remaining_days(l) := lim_remaining_years(l) * 365

lim_item(l) := {
    "liability_type": object.get(l, "type", "TAX"),
    "tax_year": object.get(l, "tax_year", 0),
    "deadline": sprintf("31.12.%d", [lim_deadline_year(l)]),
    "remaining_days": lim_remaining_days(l),
    "statute_barred": lim_remaining_days(l) <= 0,
    "suspended": object.get(l, "suspended", false),
    "suspension_reason": object.get(l, "suspension_reason", ""),
    "max_extension_years": 10 if {object.get(l, "suspended", false)} else 0,
}

lim_items := [lim_item(l) | l := lim_liabilities[_]]
lim_barred_count := count([i | i := lim_items[_]; i.statute_barred])
lim_expiring_count := count([i | i := lim_items[_]; i.remaining_days <= limitation_evidence_warn_days; not i.statute_barred])

lim_decision_hash_input := concat("|", [sprintf("%s:%d", [i.liability_type, i.tax_year]) | i := lim_items[_]])

decide := {
    "matched": true,
    "rule_id": "jdg.r08_ordynacja_obrona_innovations.limitation_evidence_monitor",
    "package": "jdg.r08_ordynacja_obrona_innovations",
    "priority": 11005,
    "decision_mode": "SUGGEST",
    "valid_from": "2025-01-01",
    "valid_to": null,
    "lim_liabilities_total": count(lim_items),
    "lim_barred_count": lim_barred_count,
    "lim_expiring_count": lim_expiring_count,
    "lim_items": lim_items,
    "lim_evidence_certificate": {
        "decision_hash": "sha256:" + lim_decision_hash_input,
        "bundle_version": lim_bundle_version,
        "rule_version": "v9",
        "threshold_version": "v2026",
        "legal_basis": "OrdPU art. 70 § 1 (5 lat), § 4-6 (zawieszenie/przerwanie, max 10 lat)",
        "method": "statute_of_limitations_art70",
        "warn_days": limitation_evidence_warn_days,
    },
    "_routing": "BLOCK_AND_ALERT" if {
        lim_barred_count > 0
    } else := "TRIAGE_QUEUE" if {
        lim_expiring_count > 0
    } else := "" if {
        true
    },
    "_routing_reason": sprintf("Monitor przedawnień — %d zobowiązań: %d PRZEDAWNIONYCH (statute_barred), %d w oknie alarmowym (%d dni). Dowód: certyfikat z decision_hash.", [count(lim_items), lim_barred_count, lim_expiring_count, limitation_evidence_warn_days]),
    "_legal_basis": "OrdPU art. 70 § 1, 4-6; art. 21 § 1 pkt 1 (zawieszenie KKS)",
    "_warnings": [sprintf("PRZEDAWNIENIA: %d zobowiązań w monitorze — %d PRZEDAWNIONYCH, %d w oknie %d dni. Przedawnione = obowiązek wygasa, egzekucja niedopuszczalna (art. 70).", [count(lim_items), lim_barred_count, lim_expiring_count, limitation_evidence_warn_days])],
} if {
    object.get(input.jdg_entrepreneur, "r08_ordynacja_check", false) == true
    object.get(input, "limitation_monitor", {}) != {}
}
