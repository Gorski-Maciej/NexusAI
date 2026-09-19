# NEXUSAI JDG — V3-P68 RE-CERTYFIKACJA FORTECY (konwencja P51–P67)
# ==============================================================================
# Re-certyfikacja po falach naprawczych — NOWY DOWÓD STANU, nie powtórzenie
# certyfikatu P44. 12 innowacji (I01–I12; minimum z promptu P68 Sekcja 10):
#
#   I01 Hard gate certificate — certyfikat wyłącznie gdy wszystkie hard gates
#       zamknięte (zero stubów ACTIVE, zero hardcode wartości prawnych, 100%
#       podstaw zweryfikowanych lub oznaczonych, zero dryfu mirror, zero ścieżek
#       fail-open na AUTO_POST); naruszenie = BLOCK („brak re-certyfikacji”).
#   I02 Register settlement table — 23 rejestry P45–P67 z statusem
#       (DOMKNIĘTY/CZĘŚCIOWY), dowodem i trendem; brak rozliczenia = NEEDS_ADVICE.
#   I03 Filar scoreboard V3 — 9 filarów z statusem DOWIEDZONE/CZĘŚCIOWE/
#       DEKLAROWANE; status poza dozwolonym = NEEDS_ADVICE.
#   I04 Residual → V4 map — rejestr rezydualny (P64) musi mieć mapę fal V4;
#       brak = NEEDS_ADVICE (zero utraty wiedzy między kampaniami).
#   I05 Success metric freeze — definicja sukcesu jako dane (metryki + progi)
#       ZAMROŻONA przed oceną; poniżej minimum = NEEDS_ADVICE.
#   I06 Certificate WORM + signature — re-certyfikat podpisany i archiwizowany
#       WORM (P65-I08) z retencją; brak = NEEDS_ADVICE (dowód na lata).
#   I07 Renewal policy — polityka odnowienia (dni/epoka prawna P53/deploy
#       krytyczny P38); brak = NEEDS_ADVICE (certyfikat żywy, nie wieczny).
#   I08 Owner attestation — akceptacja właściciela (4-eyes biznesowe) w
#       evidence; brak = NEEDS_ADVICE (domknięcie po stronie biznesowej).
#   I09 Knowledge transfer pack — pakiet przekazania (rejestry, runbooki,
#       kontrakty, kontakty); poniżej minimum sekcji = NEEDS_ADVICE.
#   I10 Fortress self-portrait — auto-portret (diagram + tabela komponentów,
#       kontraktów, dowodów); brak = NEEDS_ADVICE.
#   I11 Truth-first attestation — DEKLAROWANE nie może być raportowane jako
#       DOWIEDZONE; naruszenie integralności = BLOCK (zero sellingu).
#   I12 Campaign post-mortem — post-mortem kampanii V3 wymagany (co zadziałało,
#       co nie, co zmienić w V4); brak = NEEDS_ADVICE.
#
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p68 — ADR-002 (P06),
#     okno temporalne valid_from (P05); zero hardcode.
#   * Fail-closed (V1 zasada 6; konwencja P51–P67): brak snapshotu progów =
#     NEEDS_ADVICE; bez flagi v3_p68_check = NO_MATCH; nigdy ciche AUTO_POST.
#   * Konwencja P54–P67: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (tools/v3_p68_engines.py czytają PRAWDZIWE źródła: ledger kampanii
#     v3_campaign_ledger.json (23 rejestry P45–P67), evidence final
#     certification v4 (LCI/TCL/RV, production NOT_CERTIFIED), zero_defect
#     certification, rule_registry (stuby/unikalność), thresholds_data
#     (hardcode), coverage_deserts + v3_p51_desert_register (pustynie),
#     golden_verdicts (replay P10), deployments.json (historia P38),
#     healthy_versions (stabilność), enterprise_operating_contract,
#     v3_p64_sweep_register (rejestr rezydualny), v3_p53_epoch_registry
#     (epoki — polityka odnowienia), v3_p67_learning_data (metryki pętli),
#     worm_storage (archiwum), v3_p66_chaos (resilience_pct), v3_p49
#     fail-open registry). Klucze w input.v3_p68 (I01_..–I12_..).
#   * Kontrakty: P03 (werdykt), P06 (ADR-002), P29 (raport JSON), P37/P58
#     (obserwowalność), P39 (CI), P44 (certyfikacja V3 — P68 to NOWY dowód,
#     nie powtórzenie), P47 (mediacje prawne), P49/P50 (P0 rezydualne),
#     P64 (rejestr rezydualny), P65 (kontrakt C2 natywnych testów OPA),
#     P66 (resilience trend), P67 (pętla uczenia, K1–K6). Akty: OP art. 199a
#     (interpretacje — status weryfikacji), UoR art. 4 ust. 1 i art. 74–75
#     (rzetelność i retencja dowodu), RODO art. 5.2/24/30 (rozliczalność),
#     eIDAS (podpis certyfikatu), AI Act (dokumentacja finalna) — WSZYSTKIE
#     [NIEZWERYFIKOWANE — ISAP].
#   * Aktywacja: input.jdg_entrepreneur.v3_p68_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p68_recertification_final.<analiza>.
#   * Priorytety: 468001–468012 (I01–I12).
#   * Pakiety importujące (main_jdg.rego): data.jdg.v3_p68_recertification_final →
#     final_verdict_p132 = safe_merge(final_verdict_p131, …).
# ==============================================================================

package jdg.v3_p68_recertification_final

# ── Kontrakt wejściowy ────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p68_check", false) == true
_ctx := object.get(input, "v3_p68", {})

# ── Snapshot progów (ADR-002) ─────────────────────────────────────────────────
_p68_snapshot := data.jdg.thresholds.v3_p68

_snapshot_ok = true {
	count(_p68_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p68_snapshot) > 0
	value := object.get(_p68_snapshot, key, null)
	value != null
} else = fallback

_not(x) = true {
	x == false
}

# ── Fail-closed gdy snapshot progów niedostępny ───────────────────────────────
fail_closed_decision := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.thresholds_missing",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P68 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Hard gate certificate ────────────────────────────────────────────────
# Naruszenie któregokolwiek hard gate (stuby ACTIVE, hardcode wartości prawnych,
# podstawy nieoznaczone, dryf mirror, fail-open na AUTO_POST) = BLOCK —
# certyfikat wydawany WYŁĄCZNIE przy pełnym domknięciu (inaczej raport „brak
# re-certyfikacji” z listą — zero marketingu).
i01_hard_gates := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.hard_gate_certificate",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468001,
	"decision": "BLOCK",
	"reason": sprintf("hard gates: %v naruszonych z %v wymaganych (lista: %v) — brak re-certyfikacji do czasu naprawy (zero marketingu)", [violated_n, required, violated_list]),
	"metrics": {"violated": violated_n, "required": required, "violated_gates": violated_list},
	"_legal_basis": "prompt P68 Sekcja 2 (hard gates); P49 fail-closed; UoR art. 4 ust. 1 [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_hard_gates", {})
	required := _th("v3_p68_hard_gates_required", 5)
	violated_list := object.get(_ctx_i01, "violated_gates", [])
	violated_n := count(violated_list)
	violated_n > 0
}

# ── I02: Register settlement table ────────────────────────────────────────────
# Brak rozliczenia któregokolwiek z 23 rejestrów naprawczych = NEEDS_ADVICE —
# każdy rejestr (P45–P67) z statusem DOMKNIĘTY/CZĘŚCIOWY, dowodem i trendem.
i02_settlement := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.register_settlement",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468002,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("rozliczenie rejestrów: %v z %v wymaganych (brak: %v) — każdy rejestr P45–P67 musi mieć status, dowód i trend", [settled, total, missing]),
	"metrics": {"settled": settled, "total": total, "missing_registers": missing},
	"_legal_basis": "prompt P68 Sekcja 10-I02; P64 sweep; RODO art. 5.2 (rozliczalność) [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_settlement", {})
	total := _th("v3_p68_registers_total", 23)
	settled := object.get(_ctx_i02, "registers_settled", 0)
	missing := object.get(_ctx_i02, "registers_missing", [])
	settled < total
}

# ── I03: Filar scoreboard V3 ──────────────────────────────────────────────────
# Filarów poniżej 9 albo status poza {DOWIEDZONE, CZĘŚCIOWE, DEKLAROWANE} =
# NEEDS_ADVICE — prawdziwy obraz fortecy, nie broszura.
i03_pillars := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.pillar_scoreboard",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468003,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("scoreboard filarów: %v z %v; niepoprawne statusy: %v (dozwolone DOWIEDZONE/CZĘŚCIOWE/DEKLAROWANE)", [scored, total, invalid]),
	"metrics": {"pillars_scored": scored, "total": total, "invalid_statuses": invalid},
	"_legal_basis": "prompt P68 Sekcja 10-I03; README V3 definicja sukcesu",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_pillars", {})
	total := _th("v3_p68_pillars_total", 9)
	valid := _th("v3_p68_pillar_status_valid", ["DOWIEDZONE", "CZĘŚCIOWE", "DEKLAROWANE"])
	scored := object.get(_ctx_i03, "pillars_scored", 0)
	invalid := object.get(_ctx_i03, "invalid_statuses", [])
	scored < total
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.pillar_scoreboard",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468003,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("scoreboard filarów: statusy poza rejestrem dowodowym: %v — filar bez statusu DOWIEDZONE/CZĘŚCIOWE/DEKLAROWANE nie istnieje", [invalid]),
	"metrics": {"invalid_statuses": invalid},
	"_legal_basis": "prompt P68 Sekcja 10-I03/I11 (truth-first)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_pillars", {})
	valid := _th("v3_p68_pillar_status_valid", ["DOWIEDZONE", "CZĘŚCIOWE", "DEKLAROWANE"])
	invalid := object.get(_ctx_i03, "invalid_statuses", [])
	count(invalid) > 0
}

# ── I04: Residual → V4 map ────────────────────────────────────────────────────
# Rejestr rezydualny bez mapy fal V4 = NEEDS_ADVICE — zero utraty wiedzy
# między kampaniami (P64 kontrakt handover).
i04_residual_map := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.residual_v4_map",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468004,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("mapa V4: wymagana=%v, obecna=%v, rejestry rezydualne bez właściciela=%v — luka bez planu ginie między kampaniami", [required, present, unmapped]),
	"metrics": {"required": required, "present": present, "unmapped_registers": unmapped},
	"_legal_basis": "prompt P68 Sekcja 10-I04; P64 handover V4 C1–C4",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_residual_map", {})
	required := _th("v3_p68_residual_v4_map_required", true)
	present := object.get(_ctx_i04, "v4_map_present", false)
	unmapped := count(object.get(_ctx_i04, "unmapped_registers", []))
	required == true
	_not(present)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.residual_v4_map",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468004,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("mapa V4: rejestry rezydualne bez przypisanej fali/priorytetu: %v", [unmapped]),
	"metrics": {"unmapped_registers": unmapped},
	"_legal_basis": "prompt P68 Sekcja 10-I04; P64 kontrakt C1",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_residual_map", {})
	unmapped := count(object.get(_ctx_i04, "unmapped_registers", []))
	unmapped > 0
}

# ── I05: Success metric freeze ────────────────────────────────────────────────
# Definicja sukcesu zamrożona JAKO DANE przed oceną — poniżej minimum metryk z
# progiem = NEEDS_ADVICE (ocena na dowodach, nie na wrażeniu).
i05_metric_freeze := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.success_metric_freeze",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("definicja sukcesu: %v metryk zamrożonych (min %v) — ocena bez zamrożonych progów jest subiektywna", [frozen, min_metrics]),
	"metrics": {"frozen_metrics": frozen, "min": min_metrics},
	"_legal_basis": "prompt P68 Sekcja 10-I05; P58 wspólne źródło",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_metric_freeze", {})
	min_metrics := _th("v3_p68_success_metrics_min", 5)
	frozen := object.get(_ctx_i05, "frozen_metrics", 0)
	frozen < min_metrics
}

# ── I06: Certificate WORM + signature ─────────────────────────────────────────
# Re-certyfikat bez archiwum WORM (P65-I08) i podpisu = NEEDS_ADVICE — dowód
# na lata musi być niezmienialny i autentyczny (eIDAS, retencja UoR 74–75).
i06_worm := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.certificate_worm_signature",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468006,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("certyfikat: worm=%v, signature=%v — dowód re-certyfikacji bez niezmienności/podpisu wygasa z sesją", [worm, signature]),
	"metrics": {"worm_archived": worm, "signed": signature},
	"_legal_basis": "eIDAS (integralność) [NIEZWERYFIKOWANE — ISAP]; UoR art. 74–75 (retencja) [NIEZWERYFIKOWANE — ISAP]; P65-I08 WORM",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_worm", {})
	worm_required := _th("v3_p68_worm_required", true)
	worm := object.get(_ctx_i06, "worm_archived", false)
	signature := object.get(_ctx_i06, "signed", false)
	worm_required == true
	_not(worm)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.certificate_worm_signature",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468006,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("certyfikat: podpis=%v — archiwum bez podpisu nie dowodzi autentyczności", [signature]),
	"metrics": {"signed": signature},
	"_legal_basis": "eIDAS [NIEZWERYFIKOWANE — ISAP]; prompt P68 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_worm", {})
	signature := object.get(_ctx_i06, "signed", false)
	_not(signature)
}

# ── I07: Renewal policy ───────────────────────────────────────────────────────
# Brak polityki odnowienia (dni / epoka prawna P53 / deploy krytyczny P38) =
# NEEDS_ADVICE — certyfikat wieczny to fikcja (prawo i kod żyją).
i07_renewal := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.renewal_policy",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468007,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("polityka odnowienia: max_dni=%v, wygaśnięcie po epoce=%v, po deploymencie krytycznym=%v — certyfikat bez wygaśnięcia jest deklaratywny", [max_days, on_epoch, on_deploy]),
	"metrics": {"renewal_max_days": max_days, "on_epoch_change": on_epoch, "on_critical_deploy": on_deploy},
	"_legal_basis": "prompt P68 Sekcja 10-I07; P53 epoki; P38 deploy",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_renewal", {})
	max_days := _th("v3_p68_renewal_max_days", 90)
	on_epoch := _th("v3_p68_renewal_on_epoch_change", true)
	on_deploy := _th("v3_p68_renewal_on_critical_deploy", true)
	policy_days := object.get(_ctx_i07, "policy_max_days", 0)
	policy_epoch := object.get(_ctx_i07, "policy_on_epoch_change", false)
	policy_deploy := object.get(_ctx_i07, "policy_on_critical_deploy", false)
	policy_days <= 0
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.renewal_policy",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468007,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("polityka odnowienia: epoka=%v (wymagane %v), deploy krytyczny=%v (wymagane %v) — certyfikat musi wygasać przy zmianie prawa i kodu", [policy_epoch, on_epoch, policy_deploy, on_deploy]),
	"metrics": {"on_epoch_change": policy_epoch, "on_critical_deploy": policy_deploy},
	"_legal_basis": "prompt P68 Sekcja 10-I07; P53; P38",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_renewal", {})
	on_epoch := _th("v3_p68_renewal_on_epoch_change", true)
	on_deploy := _th("v3_p68_renewal_on_critical_deploy", true)
	policy_epoch := object.get(_ctx_i07, "policy_on_epoch_change", false)
	policy_deploy := object.get(_ctx_i07, "policy_on_critical_deploy", false)
	on_epoch == true
	_not(policy_epoch)
}

# ── I08: Owner attestation ────────────────────────────────────────────────────
# Brak akceptacji właściciela (4-eyes biznesowe) w evidence = NEEDS_ADVICE —
# komisja może stwierdzić stan, ale przyjęcie należy do biznesu.
i08_owner := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.owner_attestation",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("akceptacja właściciela: wymagana=%v, obecna=%v — re-certyfikat bez przyjęcia biznesowego pozostaje projektem, nie certyfikatem", [required, present]),
	"metrics": {"required": required, "present": present},
	"_legal_basis": "prompt P68 Sekcja 10-I08; RODO art. 24 (odpowiedzialność) [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_owner", {})
	required := _th("v3_p68_owner_attestation_required", true)
	present := object.get(_ctx_i08, "owner_attested", false)
	required == true
	_not(present)
}

# ── I09: Knowledge transfer pack ──────────────────────────────────────────────
# Pakiet przekazania poniżej minimum sekcji = NEEDS_ADVICE — forteca ma być
# operowalna przez innych, nie tylko przez autorów kampanii.
i09_kt_pack := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.knowledge_transfer_pack",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("knowledge transfer: %v sekcji (min %v) — rejestry, runbooki, kontrakty, kontakty, progi alarmów", [sections, min_sections]),
	"metrics": {"sections": sections, "min": min_sections},
	"_legal_basis": "prompt P68 Sekcja 10-I09; P60 dokumentacja",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_kt_pack", {})
	min_sections := _th("v3_p68_kt_pack_sections_min", 5)
	sections := object.get(_ctx_i09, "sections", 0)
	sections < min_sections
}

# ── I10: Fortress self-portrait ───────────────────────────────────────────────
# Auto-portret (diagram + tabela komponentów, kontraktów, dowodów) nieobecny =
# NEEDS_ADVICE — punkt wejścia dla każdego nowego członka zespołu.
i10_self_portrait := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.fortress_self_portrait",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("auto-portret: diagram=%v, tabela komponentów=%v — forteca bez mapy samej siebie jest nieosiągalna dla nowych", [diagram, table]),
	"metrics": {"diagram_present": diagram, "components_table_present": table},
	"_legal_basis": "prompt P68 Sekcja 10-I10; P00 mapa kanoniczna (aktualizacja)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_self_portrait", {})
	diagram := object.get(_ctx_i10, "diagram_present", false)
	table := object.get(_ctx_i10, "components_table_present", false)
	_not(diagram)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.fortress_self_portrait",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("auto-portret: tabela komponentów=%v — diagram bez tabeli komponentów/kontraktów/dowodów jest ozdobnikiem", [table]),
	"metrics": {"components_table_present": table},
	"_legal_basis": "prompt P68 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_self_portrait", {})
	table := object.get(_ctx_i10, "components_table_present", false)
	_not(table)
}

# ── I11: Truth-first attestation ──────────────────────────────────────────────
# DEKLAROWANE raportowane jako DOWIEDZONE = BLOCK — naruszenie integralności
# dowodowej (zero sellingu; każde twierdzenie z artefaktem).
i11_truth_first := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.truth_first_integrity",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468011,
	"decision": "BLOCK",
	"reason": sprintf("truth-first: %v filarów DEKLAROWANE raportowanych jako DOWIEDZONE — certyfikat z fałszywym statusem dowodowym jest nieważny", [misreported]),
	"metrics": {"misreported_pillars": misreported},
	"_legal_basis": "prompt P68 Sekcja 10-I11; protokół 06 (dowód > deklaracja)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_truth_first", {})
	misreported := count(object.get(_ctx_i11, "misreported_as_evidenced", []))
	misreported > 0
}

# ── I12: Campaign post-mortem ─────────────────────────────────────────────────
# Brak post-mortemu kampanii V3 = NEEDS_ADVICE — proces kampanii też się uczy
# (co zadziałało, co nie, co zmienić w V4; sprzężenie z pętlą P67).
i12_post_mortem := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.campaign_post_mortem",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 468012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("post-mortem: wymagany=%v, obecny=%v — kampania bez rozliczenia procesu powtarza błędy w V4", [required, present]),
	"metrics": {"required": required, "present": present},
	"_legal_basis": "prompt P68 Sekcja 10-I12; P67 pętla uczenia (proces jako obiekt uczenia)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_post_mortem", {})
	required := _th("v3_p68_post_mortem_required", true)
	present := object.get(_ctx_i12, "post_mortem_present", false)
	required == true
	_not(present)
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P67):
# najpierw BLOCK, potem NEEDS_ADVICE, na końcu PASS.
# Bez flagi v3_p68_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i01_hard_gates {
	_snapshot_ok
	_activated
	i01_hard_gates.decision == "BLOCK"
} else := i11_truth_first {
	_snapshot_ok
	_activated
	i11_truth_first.decision == "BLOCK"
} else := i02_settlement {
	_snapshot_ok
	_activated
	i02_settlement.decision == "NEEDS_ADVICE"
} else := i03_pillars {
	_snapshot_ok
	_activated
	i03_pillars.decision == "NEEDS_ADVICE"
} else := i04_residual_map {
	_snapshot_ok
	_activated
	i04_residual_map.decision == "NEEDS_ADVICE"
} else := i05_metric_freeze {
	_snapshot_ok
	_activated
	i05_metric_freeze.decision == "NEEDS_ADVICE"
} else := i06_worm {
	_snapshot_ok
	_activated
	i06_worm.decision == "NEEDS_ADVICE"
} else := i07_renewal {
	_snapshot_ok
	_activated
	i07_renewal.decision == "NEEDS_ADVICE"
} else := i08_owner {
	_snapshot_ok
	_activated
	i08_owner.decision == "NEEDS_ADVICE"
} else := i09_kt_pack {
	_snapshot_ok
	_activated
	i09_kt_pack.decision == "NEEDS_ADVICE"
} else := i10_self_portrait {
	_snapshot_ok
	_activated
	i10_self_portrait.decision == "NEEDS_ADVICE"
} else := i12_post_mortem {
	_snapshot_ok
	_activated
	i12_post_mortem.decision == "NEEDS_ADVICE"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p68_recertification_final.no_match",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P68 niewyzwolony (brak flagi v3_p68_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P67",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p68_recertification_final.all_green",
	"package": "jdg.v3_p68_recertification_final",
	"priority": 1,
	"decision": "PASS",
	"reason": "P68: re-certyfikacja fortecy domknięta (12 analiz: hard gates, rozliczenie 23 rejestrów naprawczych, scoreboard 9 filarów DOWIEDZONE/CZĘŚCIOWE/DEKLAROWANE, mapa rezydualna V4, zamrożona definicja sukcesu, WORM+podpis certyfikatu, polityka odnowienia, akceptacja właściciela, knowledge transfer, auto-portret, truth-first, post-mortem). Status produkcji: NOT_CERTIFIED — jawne ograniczenie certyfikatu.",
	"metrics": {"analyses": 12},
	"_legal_basis": "OP art. 199a; UoR art. 4 ust. 1, 74–75; RODO art. 5.2, 24, 30; eIDAS; AI Act [NIEZWERYFIKOWANE — ISAP]; prompt P68 Sekcja 10",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
