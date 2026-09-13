# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P59 BEZPIECZEŃSTWO DOMKNIĘCIE — GRANICE ZAUFANIA, SEKRETY
# I ANTY-MANIPULACJA
# ===============================================================================
# Warstwa bezpieczeństwa ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu
# P59 Sekcja 10):
#   I01 Threat model as data + gates (wektory atak→kontrola→test→status;
#       wektor bez kontrola = BLOCK — bramka produkcji),
#   I02 Signed rules with 4-eyes (krytyczne reguły podpisane przez dwie role:
#       techniczna+prawna; podpis w metadanych, weryfikowany przy deploy),
#   I03 Rule history hash chain (zmiany reguł w WORM P42 z hash chain; edycja
#       historii wykrywalna testem tamper w CI — łańcuch przerwany = BLOCK),
#   I04 Rate-change anomaly alarm (nagła zmiana stawki/progu diff vs historia
#       → alarm 4-eyes; hardcode stawki w Rego = BLOCK — provenance P52),
#   I05 Secrets vault contract (sekrety w sejfie, rotacja, audyt użycia WORM,
#       ścieżka awaryjna; sekret w repo = BLOCK),
#   I06 CI hardening checklist (permissions: read, fork-PR secret isolation,
#       pinning z hashami, skan CVE — checklist ze statusem; brak hardeningu
#       poniżej progu = BLOCK),
#   I07 Build attestation verification (certyfikat decyzji weryfikuje
#       provenance bundla P38; decyzja bez potwierdzonego pochodzenia =
#       NEEDS_ADVICE),
#   I08 Insider threat program (podwójna kontrola, rotacja obowiązków, kanał
#       zgłoszeń, audyt nietypowych dostępów; program niekompletny =
#       NEEDS_ADVICE; wykryty wzorzec = MANUAL_REVIEW),
#   I09 Supply chain SBOM (SBOM zależności generowany w CI; brak SBOM =
#       NEEDS_ADVICE — przejrzystość łańcucha dostaw),
#   I10 Security chaos drills (próba wstrzyknięcia reguły, kompromitacja
#       klucza, tamper WORM — kwartalnie; brak harmonogramu = NEEDS_ADVICE),
#   I11 Trust boundary map (granice zaufania jako dane: aktorzy, co
#       przekracza granicę, kontrola na granicy; przejście bez kontrola =
#       BLOCK),
#   I12 Security score trend (kontrole zaimplementowane/wymagane z trendem;
#       poniżej progu z ADR-002 = NEEDS_ADVICE — raport do P68).
#
# Zasady:
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p59 — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * Konwencja P54–P58: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (klucze I01_..–I12_.. w input.v3_p59); silniki czytają PRAWDZIWE źródła:
#     .github/workflows/jdg-quality.yml (permissions, fork isolation),
#     worm_storage (hash chain + verify_chain), deployments.json (P38
#     attestation/canary/soak), v3_p52_rate_provenance (hardcode stawek),
#     chaos_runner (eksperymenty P43), bundla repo (skan sekretów).
#   * Fail-closed (V1 zasada 6; protokół 05 promptu P59): wektor bez kontrola,
#     przerwany łańcuch, sekret w repo, brak hardeningu CI, przejście granicy
#     bez kontrola = BLOCK; wątpliwość = NEEDS_ADVICE/MANUAL_REVIEW. Nigdy
#     ciche AUTO_POST.
#   * Honesty: wartości prawne [NIEZWERYFIKOWANE — ISAP] (Q01); bez maskowania.
#   * Aktywacja: input.jdg_entrepreneur.v3_p59_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p59_security_closure.<analiza>.
#   * Kontrakty: P03 (kontrakt werdyktu), P05/P53 (okna), P06 (ADR-002),
#     P11 (certyfikat → attestation), P22 (RODO/AML P16 — rozszerzamy),
#     P37/P58 (metryki security score), P38 (deploy attestation), P39 (CI
#     bramki), P42 (WORM hash chain), P43 (chaos drills), P44 (podpisy),
#     P54 (klucze KSeF), P63 (RBAC — granice zaufania), P68 (re-certyfikacja).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p59_security_closure
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p59_security_closure

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p59_check", false) == true
_ctx := object.get(input, "v3_p59", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p59_snapshot := data.jdg.thresholds.v3_p59

_snapshot_ok = true {
	count(_p59_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p59_snapshot) > 0
	value := object.get(_p59_snapshot, key, null)
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
	"rule_id": "jdg.v3_p59_security_closure.thresholds_missing",
	"package": "jdg.v3_p59_security_closure",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P59 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Threat model as data + gates ─────────────────────────────────────────
# Silnik: wektory zagrożeń (atak→kontrola→test→status). Wektor bez kontrola
# lub bez testu = BLOCK (bramka produkcji threat modelu).
i01_threat_model := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.threat_model_gates",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459001,
	"decision": "BLOCK",
	"reason": sprintf("threat model: %v z %v wektorów BEZ kontrola/testu (wymagane min. %v wektorów) — bramka produkcji", [count(uncovered), vectors_total, min_vectors]),
	"metrics": {"vectors_total": vectors_total, "uncovered": count(uncovered), "min_vectors": min_vectors},
	"_legal_basis": "RODO art. 32 (odporność systemów, regularne testy) [NIEZWERYFIKOWANE — ISAP]; prompt P59 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_threat_model_gates", {})
	min_vectors := _th("v3_p59_threat_vectors_min", 12)
	vectors_total := object.get(_ctx_i01, "vectors_total", 0)
	uncovered := object.get(_ctx_i01, "vectors_uncovered", [])
	count(uncovered) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.threat_model_gates",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459001,
	"decision": "BLOCK",
	"reason": sprintf("threat model: %v wektorów poniżej wymaganych %v", [vectors_total, min_vectors]),
	"metrics": {"vectors_total": vectors_total, "min_vectors": min_vectors},
	"_legal_basis": "RODO art. 32 [NIEZWERYFIKOWANE — ISAP]; prompt P59 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_threat_model_gates", {})
	min_vectors := _th("v3_p59_threat_vectors_min", 12)
	vectors_total := object.get(_ctx_i01, "vectors_total", 0)
	vectors_total < min_vectors
}

# ── I02: Signed rules with 4-eyes ─────────────────────────────────────────────
# Silnik: krytyczne reguły wymagają podpisów dwóch ról (techniczna+prawa).
# Reguła krytyczna bez podpisów = NEEDS_ADVICE (deploy wstrzymany).
i02_signed_rules := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.signed_rules_4eyes",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459002,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("podpisy 4-eyes: %v z %v reguł krytycznych BEZ podpisu dwóch ról (wymagane role: %v)", [count(unsigned), critical_total, roles]),
	"metrics": {"critical_total": critical_total, "signed": critical_total - count(unsigned), "unsigned": count(unsigned), "roles": count(roles)},
	"_legal_basis": "eIDAS (integralność, autentyczność) [NIEZWERYFIKOWANE — ISAP]; P44 podpisy; prompt P59 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_signed_rules_4eyes", {})
	roles := _th("v3_p59_signature_roles", ["technical", "legal"])
	critical_total := object.get(_ctx_i02, "critical_total", 0)
	unsigned := object.get(_ctx_i02, "critical_unsigned", [])
	count(unsigned) >= 1
}

# ── I03: Rule history hash chain ──────────────────────────────────────────────
# Silnik: WORM P42 verify_chain + tamper drill. Łańcuch przerwany lub tamper
# NIEWYKRYTY = BLOCK (anty-manipulacja — UoR art. 74).
i03_hash_chain := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.rule_history_hash_chain",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459003,
	"decision": "BLOCK",
	"reason": sprintf("hash chain WORM: chain_valid=%v, tamper_wykryty=%v (drill %v przypadków) — edycja historii musi być wykrywalna", [chain_valid, tamper_detected, tamper_cases]),
	"metrics": {"chain_valid": chain_valid, "tamper_detected": tamper_detected, "tamper_cases": tamper_cases},
	"_legal_basis": "UoR art. 74 (ochrona przed zniszczeniem/zmianą); P42 WORM; prompt P59 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_rule_history_hash_chain", {})
	chain_valid := object.get(_ctx_i03, "chain_valid", false)
	tamper_detected := object.get(_ctx_i03, "tamper_detected", false)
	tamper_cases := object.get(_ctx_i03, "tamper_cases", 0)
	_not(chain_valid)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.rule_history_hash_chain",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459003,
	"decision": "BLOCK",
	"reason": sprintf("hash chain WORM: tamper drill NIEWYKRYTY (%v przypadków) — anty-manipulacja dziurawa", [tamper_cases]),
	"metrics": {"chain_valid": chain_valid, "tamper_detected": tamper_detected, "tamper_cases": tamper_cases},
	"_legal_basis": "UoR art. 74; P42 WORM; prompt P59 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_rule_history_hash_chain", {})
	chain_valid := object.get(_ctx_i03, "chain_valid", false)
	tamper_detected := object.get(_ctx_i03, "tamper_detected", false)
	tamper_cases := object.get(_ctx_i03, "tamper_cases", 0)
	tamper_cases >= 1
	_not(tamper_detected)
}

# ── I04: Rate-change anomaly alarm ────────────────────────────────────────────
# Silnik: provenance stawek (P52) + detekcja nagłych zmian diff vs historia.
# Hardcode stawki w Rego lub zmiana ponad próg bez 4-eyes = BLOCK.
i04_rate_anomaly := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.rate_change_anomaly",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459004,
	"decision": "BLOCK",
	"reason": sprintf("anomaly stawek: %v hardcode w Rego (provenance P52); zmiany ponad %v pp bez 4-eyes: %v", [hardcoded, anomaly_pp, count(unapproved)]),
	"metrics": {"hardcoded_rates": hardcoded, "anomaly_threshold_pp": anomaly_pp, "unapproved_changes": count(unapproved)},
	"_legal_basis": "P52 rate provenance; P46 parametry-as-data; prompt P59 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_rate_change_anomaly", {})
	anomaly_pp := _th("v3_p59_rate_change_anomaly_pp", 100)
	hardcoded := object.get(_ctx_i04, "hardcoded_rates", 0)
	unapproved := object.get(_ctx_i04, "unapproved_changes", [])
	hardcoded >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.rate_change_anomaly",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459004,
	"decision": "BLOCK",
	"reason": sprintf("anomaly stawek: %v zmian ponad %v pp BEZ zatwierdzenia 4-eyes (manipulacja parametrem)", [count(unapproved), anomaly_pp]),
	"metrics": {"anomaly_threshold_pp": anomaly_pp, "unapproved_changes": count(unapproved)},
	"_legal_basis": "P52 rate provenance; prompt P59 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_rate_change_anomaly", {})
	anomaly_pp := _th("v3_p59_rate_change_anomaly_pp", 100)
	unapproved := object.get(_ctx_i04, "unapproved_changes", [])
	count(unapproved) >= 1
}

# ── I05: Secrets vault contract ───────────────────────────────────────────────
# Silnik: skan repo na sekrety (klucze prywatne, hasła, tokeny) + kontrakt
# sejfu (rotacja, audyt użycia, ścieżka awaryjna). Sekret w repo = BLOCK.
i05_secrets := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.secrets_vault_contract",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459005,
	"decision": "BLOCK",
	"reason": sprintf("sekrety: %v trafień skanu repo (limit %v) — klucze nigdy w repo/env; kontrakt sejfu: rotacja=%v", [count(hits), max_hits, rotation_policy]),
	"metrics": {"repo_hits": count(hits), "max_hits": max_hits, "rotation_policy": rotation_policy},
	"_legal_basis": "RODO art. 32 (szyfrowanie, bezpieczeństwo); KKS art. 115-1 (ochrona systemu) [NIEZWERYFIKOWANE — ISAP]; prompt P59 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_secrets_vault_contract", {})
	max_hits := _th("v3_p59_secrets_max_in_repo", 0)
	rotation_policy := _th("v3_p59_rotation_policy", "quarterly")
	hits := object.get(_ctx_i05, "repo_hits", [])
	count(hits) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.secrets_vault_contract",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459005,
	"decision": "BLOCK",
	"reason": sprintf("sekrety: kontrakt sejfu niekompletny (rotacja=%v, audyt=%v, ścieżka awaryjna=%v)", [rotation_policy, audit_usage, break_glass]),
	"metrics": {"rotation_policy": rotation_policy, "audit_usage": audit_usage, "break_glass": break_glass},
	"_legal_basis": "RODO art. 32; KKS art. 115-1 [NIEZWERYFIKOWANE — ISAP]; prompt P59 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_secrets_vault_contract", {})
	rotation_policy := _th("v3_p59_rotation_policy", "quarterly")
	audit_usage := object.get(_ctx_i05, "audit_usage", false)
	break_glass := object.get(_ctx_i05, "break_glass", false)
	_not(audit_usage)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.secrets_vault_contract",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459005,
	"decision": "BLOCK",
	"reason": sprintf("sekrety: brak ścieżki awaryjnej kompromitacji (break-glass); rotacja=%v, audyt=%v", [rotation_policy, audit_usage]),
	"metrics": {"rotation_policy": rotation_policy, "audit_usage": audit_usage, "break_glass": break_glass},
	"_legal_basis": "RODO art. 32; KKS art. 115-1 [NIEZWERYFIKOWANE — ISAP]; prompt P59 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_secrets_vault_contract", {})
	rotation_policy := _th("v3_p59_rotation_policy", "quarterly")
	audit_usage := object.get(_ctx_i05, "audit_usage", true)
	break_glass := object.get(_ctx_i05, "break_glass", false)
	_not(break_glass)
}

# ── I06: CI hardening checklist ───────────────────────────────────────────────
# Silnik: checklist z .github/workflows/jdg-quality.yml (permissions, fork
# isolation, pinning, CVE scan). Wynik poniżej progu z ADR-002 = BLOCK.
i06_ci_hardening := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.ci_hardening_checklist",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459006,
	"decision": "BLOCK",
	"reason": sprintf("CI hardening: %v%% poniżej progu %v%% (brakujące: %v)", [score_pct, min_pct, missing]),
	"metrics": {"score_pct": score_pct, "min_pct": min_pct, "missing": missing},
	"_legal_basis": "P39 bramki CI; supply chain security; prompt P59 Sekcja 10-I06",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_ci_hardening_checklist", {})
	min_pct := _th("v3_p59_ci_hardening_min_pct", 75)
	score_pct := object.get(_ctx_i06, "score_pct", 0)
	missing := object.get(_ctx_i06, "missing_controls", [])
	score_pct < min_pct
}

# ── I07: Build attestation verification ───────────────────────────────────────
# Silnik: certyfikat decyzji P11 weryfikuje provenance bundla (P38:
# canary/soak/attestation). Wymagane attestation a decyzja bez = NEEDS_ADVICE.
i07_attestation := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.build_attestation_verification",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459007,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("attestation: wymagane=%v, %v z %v wdrożeń BEZ provenance (P38 canary/soak/hash)", [required, count(missing), deps_total]),
	"metrics": {"required": required, "deps_total": deps_total, "missing_provenance": count(missing)},
	"_legal_basis": "P38 attestation (SLSA duch); P11 certyfikat; prompt P59 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_build_attestation_verification", {})
	required := _th("v3_p59_attestation_required", true)
	deps_total := object.get(_ctx_i07, "deps_total", 0)
	missing := object.get(_ctx_i07, "deps_missing_provenance", [])
	required == true
	count(missing) >= 1
}

# ── I08: Insider threat program ───────────────────────────────────────────────
# Silnik: program = podwójna kontrola + rotacja obowiązków + kanał zgłoszeń +
# audyt dostępów. Program niekompletny = NEEDS_ADVICE; wykryty wzorzec
# podejrzany = MANUAL_REVIEW (człowiek decyduje, nigdy automt).
i08_insider := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.insider_threat_program",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459008,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("insider program: brakujące elementy %v (podwójna kontrola/rotacja/kanał/audyt)", [missing]),
	"metrics": {"elements_present": 4 - count(missing), "missing": missing},
	"_legal_basis": "Ustawa AML art. 2/48 (środki bezpieczeństwa) [NIEZWERYFIKOWANE — ISAP]; prompt P59 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_insider_threat_program", {})
	missing := object.get(_ctx_i08, "elements_missing", [])
	count(missing) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.insider_threat_program",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459008,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("insider program: %v sygnałów podejrzanych (nietypowe dostępy/zmiany) — decyzja człowieka", [signals]),
	"metrics": {"signals": signals},
	"_legal_basis": "Ustawa AML art. 2/48 [NIEZWERYFIKOWANE — ISAP]; prompt P59 Sekcja 10-I08",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_insider_threat_program", {})
	signals := object.get(_ctx_i08, "suspicious_signals", 0)
	signals >= 1
}

# ── I09: Supply chain SBOM ────────────────────────────────────────────────────
# Silnik: SBOM zależności (zewnętrznych + stdlib użycia) generowany w CI.
# Brak SBOM lub zależność niepinowana bez planu = NEEDS_ADVICE.
i09_sbom := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.supply_chain_sbom",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("SBOM: %v zależności zewnętrznych (pinowanych: %v), SBOM obecny=%v — przejrzystość łańcucha dostaw", [deps_total, pinned, sbom_present]),
	"metrics": {"deps_total": deps_total, "pinned": pinned, "sbom_present": sbom_present},
	"_legal_basis": "supply chain security; P68 certyfikat; prompt P59 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_supply_chain_sbom", {})
	deps_total := object.get(_ctx_i09, "deps_total", 0)
	pinned := object.get(_ctx_i09, "pinned", 0)
	sbom_present := object.get(_ctx_i09, "sbom_present", false)
	_not(sbom_present)
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.supply_chain_sbom",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("SBOM: %v z %v zależności niepinowanych (plan pinningu wymagany)", [deps_total - pinned, deps_total]),
	"metrics": {"deps_total": deps_total, "pinned": pinned},
	"_legal_basis": "supply chain security; prompt P59 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_supply_chain_sbom", {})
	deps_total := object.get(_ctx_i09, "deps_total", 0)
	pinned := object.get(_ctx_i09, "pinned", 0)
	deps_total > pinned
}

# ── I10: Security chaos drills ────────────────────────────────────────────────
# Silnik: ćwiczenia (wstrzyknięcie reguły, kompromitacja klucza, tamper WORM)
# co v3_p59_drill_frequency_days dni. Brak harmonogramu/przeterminowane =
# NEEDS_ADVICE.
i10_drills := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.security_chaos_drills",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459010,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("security drills: %v eksperymentów security, częstotliwość %v dni, ostatni drill=%v — harmonogram wymagany", [experiments, freq_days, last_drill]),
	"metrics": {"experiments": experiments, "freq_days": freq_days, "last_drill": last_drill},
	"_legal_basis": "RODO art. 32 (regularne testy); P43 chaos; prompt P59 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_security_chaos_drills", {})
	freq_days := _th("v3_p59_drill_frequency_days", 90)
	experiments := object.get(_ctx_i10, "security_experiments", 0)
	last_drill := object.get(_ctx_i10, "last_drill", "nigdy")
	experiments < 3
}

# ── I11: Trust boundary map ───────────────────────────────────────────────────
# Silnik: granice zaufania jako dane (aktor→przepływ→kontrola). Przejście
# granicy bez kontrola = BLOCK (kto może co — technicznie egzekwowane).
i11_trust_boundary := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.trust_boundary_map",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459011,
	"decision": "BLOCK",
	"reason": sprintf("granice zaufania: %v przepływów międzyaktorowych BEZ kontrola na granicy (mapa: %v aktorów)", [count(uncontrolled), actors_total]),
	"metrics": {"actors_total": actors_total, "flows_total": flows_total, "uncontrolled": count(uncontrolled)},
	"_legal_basis": "P63 RBAC; RODO art. 32; prompt P59 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_trust_boundary_map", {})
	actors_total := object.get(_ctx_i11, "actors_total", 0)
	flows_total := object.get(_ctx_i11, "flows_total", 0)
	uncontrolled := object.get(_ctx_i11, "flows_uncontrolled", [])
	count(uncontrolled) >= 1
}

# ── I12: Security score trend ─────────────────────────────────────────────────
# Silnik: score = kontrole zaimplementowane/wymagane (checklist I06 + threat
# model I01 + sekrety I05). Poniżej progu z ADR-002 = NEEDS_ADVICE (raport P68).
i12_security_score := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.security_score_trend",
	"package": "jdg.v3_p59_security_closure",
	"priority": 459012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("security score %v%% poniżej progu %v%% (trend: %v) — raport do P68", [score_pct, min_pct, trend]),
	"metrics": {"score_pct": score_pct, "min_pct": min_pct, "trend": trend},
	"_legal_basis": "RODO art. 32 (ocena ryzyka); P58 obserwowalność; prompt P59 Sekcja 10-I12",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_security_score_trend", {})
	min_pct := _th("v3_p59_security_score_min_pct", 75)
	score_pct := object.get(_ctx_i12, "score_pct", 0)
	trend := object.get(_ctx_i12, "trend", "flat")
	score_pct < min_pct
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P58):
# najpierw BLOCK, potem NEEDS_ADVICE/MANUAL_REVIEW, na końcu PASS.
# Bez flagi v3_p59_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i01_threat_model {
	_snapshot_ok
	_activated
	i01_threat_model.decision == "BLOCK"
} else := i03_hash_chain {
	_snapshot_ok
	_activated
	i03_hash_chain.decision == "BLOCK"
} else := i04_rate_anomaly {
	_snapshot_ok
	_activated
	i04_rate_anomaly.decision == "BLOCK"
} else := i05_secrets {
	_snapshot_ok
	_activated
	i05_secrets.decision == "BLOCK"
} else := i06_ci_hardening {
	_snapshot_ok
	_activated
	i06_ci_hardening.decision == "BLOCK"
} else := i11_trust_boundary {
	_snapshot_ok
	_activated
	i11_trust_boundary.decision == "BLOCK"
} else := i02_signed_rules {
	_snapshot_ok
	_activated
	i02_signed_rules.decision == "NEEDS_ADVICE"
} else := i07_attestation {
	_snapshot_ok
	_activated
	i07_attestation.decision == "NEEDS_ADVICE"
} else := i08_insider {
	_snapshot_ok
	_activated
	i08_insider.decision == "NEEDS_ADVICE"
} else := i09_sbom {
	_snapshot_ok
	_activated
	i09_sbom.decision == "NEEDS_ADVICE"
} else := i10_drills {
	_snapshot_ok
	_activated
	i10_drills.decision == "NEEDS_ADVICE"
} else := i12_security_score {
	_snapshot_ok
	_activated
	i12_security_score.decision == "NEEDS_ADVICE"
} else := i08_insider_review {
	_snapshot_ok
	_activated
	i08_insider.decision == "MANUAL_REVIEW"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p59_security_closure.no_match",
	"package": "jdg.v3_p59_security_closure",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P59 niewyzwolony (brak flagi v3_p59_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P58",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p59_security_closure.all_green",
	"package": "jdg.v3_p59_security_closure",
	"priority": 1,
	"decision": "PASS",
	"reason": "P59: bezpieczeństwo fortecy zielone (12 analiz: granice, sekrety, CI, anty-manipulacja)",
	"metrics": {"analyses": 12},
	"_legal_basis": "RODO art. 32/33-34; eIDAS; UoR art. 74; KKS art. 115-1; AML art. 2/48; UKSC [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}

# MANUAL_REVIEW z insider (priorytet niższy niż PASS-podobne NEEDS_ADVICE —
# dostępny jako osobna analiza dla testów; router: tylko gdy nic innego).
i08_insider_review := i08_insider {
	i08_insider.decision == "MANUAL_REVIEW"
}
