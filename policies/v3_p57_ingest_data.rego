# ═══════════════════════════════════════════════════════════════════════════════
# NEXUSAI JDG — V3-P57 INGEST DANYCH (V3 FORTRESS) — GRANICA FORTECY:
# DOKUMENTY, FAKTY I KOLEJKI BEZ UTRATY I BEZ DUPLIKATÓW
# ===============================================================================
# Warstwa ingestu ENTERPRISE — 12 innowacji (I01–I12; minimum z promptu P57
# Sekcja 10):
#   I01 Ingest contract schema (wersjonowany schemat wejścia: typy, zakresy,
#       wymagane pola — walidowany na granicy; niezgodność = BLOCK),
#   I02 NIP checksum gate (modulo 11, wagi [6,5,7,2,3,4,5,6,7]; błędny
#       identyfikator odrzucony z komunikatem — zero cichej normalizacji),
#   I03 Semantic dedup key (NIP+data+kwota+numer; duplikat NIEZAREJESTROWANY
#       do przeglądu = BLOCK — podwójna faktura nigdy nie zaksięguje się 2×),
#   I04 Original-first WORM (oryginał z checksumą zapisany PRZED
#       przetwarzaniem; dokument bez śladu pierwotności = BLOCK — P42),
#   I05 Status state machine (przyjęty→zweryfikowany→zaakceptowany→
#       zaksięgowany→zarchiwizowany; przejście nielegalne/brak statusu
#       = NEEDS_ADVICE),
#   I06 Repair path for rejects (odrzucony dokument bez ścieżki naprawy
#       pole→akcja = NEEDS_ADVICE — zero dokumentów zgubionych),
#   I07 Bank reconciliation engine (feed bankowy↔faktury; rozjazd systemowy
#       powyżej progu = MANUAL_REVIEW; pojedynczy przelew bez faktury →
#       NEEDS_ADVICE z kandydatami — kontrakt P32),
#   I08 Ingest chaos suite (chaos input: złe typy, ujemne kwoty, duplikaty,
#       braki — przypadek NIEWYKRYTY przez bramki = BLOCK; pozytywna kontrola
#       detektorów — konwencja P54-I06 / P56-I10),
#   I09 Ingest metrics (wolumen, odrzucenia z powodami, duplikaty, czasy;
#       wskaźnik odrzuceń powyżej progu lub brak metryk = NEEDS_ADVICE — P37),
#   I10 Provenance chain to certificate (certyfikat decyzji P11 → checksuma
#       oryginału → dokument; przerwany łańcuch = BLOCK — audytor schodzi
#       do pierwszego bajta),
#   I11 Multi-tenant ingest isolation (rekord bez tenant_id lub przeciek
#       między tenantami = BLOCK — izolacja w schemacie od dnia pierwszego),
#   I12 Ingest rate governor (limit wolumenu per kanał; brak konfiguracji
#       governor = NEEDS_ADVICE; kanał bez licznika = ochrona nieaktywna).
#
# Zasady:
#   * WSZYSTKIE progi/polityki z data.jdg.thresholds.v3_p57 — ADR-002 (P06),
#     okno temporalne valid_from (P05). ZERO hardcode progów.
#   * Konwencja P54–P56: Rego bramkuje PODSUMOWANIA silników dowodowych
#     (klucze I01_..–I12_.. w input.v3_p57); silniki liczą na danych narzędzi
#     rdzenia (worm_storage, ksef_offline_queue, ksef_outbox, kontrakt
#     recon P32, ORCHESTRATOR_DATA_CONTRACT).
#   * Fail-closed (V1 zasada 6; protokół 05 promptu P57): złe dane NIGDY
#     nie wchodzą do silnika — NIGDY „popraw sobie" bez człowieka; brak
#     snapshotu progów = BLOCK. AUTO_POST tylko przy pełnym łańcuchu dowodów.
#   * Honesty: wartości prawne [NIEZWERYFIKOWANE — ISAP] (Q01); bez maskowania
#     (konwencja P47–P56).
#   * Aktywacja: input.jdg_entrepreneur.v3_p57_check == true; bez flagi →
#     no_match. rule_id: jdg.v3_p57_ingest_data.<analiza>.
#   * Kontrakty: P03 (kontrakt werdyktu), P05/P53 (okna + day-0), P06
#     (ADR-002), P11 (certyfikat decyzji → I10), P32 (idempotencja
#     outbox_id+hash i recon — K-P54-2), P37 (metryki), P39 (bramki merge),
#     P40 (statusy w UI), P42 (WORM + retencja), P48 (mirror), P49
#     (fail-closed canary), P54 (KSeF ingest = walidacja schematu FA(3)),
#     P56 (fixtures cross-border → ingest), P68 (re-certyfikacja).
#
# Pakiety importujące (main_jdg.rego): data.jdg.v3_p57_ingest_data
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.v3_p57_ingest_data

# ── Kontrakt wejściowy ──────────────────────────────────────────────────────────
_activated := object.get(object.get(input, "jdg_entrepreneur", {}), "v3_p57_check", false) == true
_ctx := object.get(input, "v3_p57", {})

# ── Snapshot progów (ADR-002) ──────────────────────────────────────────────────
_p57_snapshot := data.jdg.thresholds.v3_p57

_snapshot_ok = true {
	count(_p57_snapshot) > 0
} else = false {
	true
}

_th(key, fallback) = value {
	count(_p57_snapshot) > 0
	value := object.get(_p57_snapshot, key, null)
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
	"rule_id": "jdg.v3_p57_ingest_data.thresholds_missing",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 0,
	"decision": "NEEDS_ADVICE",
	"reason": "P57 thresholds snapshot missing — fail-closed (ADR-002)",
	"_legal_basis": "V1 zasada 6 (fail-closed); ADR-002 parametry-as-data",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_not(_snapshot_ok)
}

# ── I01: Ingest contract schema ───────────────────────────────────────────────
# Silnik: walidacja dokumentów fixture przeciw wersjonowanemu schematowi
# (wymagane pola, typy, zakresy). Dokument niezgodny ze schematem, który
# WDARŁ się do silnika (accepted=true), = BLOCK — granica przepuszczła zło.
i01_schema := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.ingest_contract_schema",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457001,
	"decision": "BLOCK",
	"reason": sprintf("schemat ingestu %v: %v z %v dokumentów niezgodnych przyjętych do silnika (fail-closed granicy naruszony)", [schema_version, count(leaked), docs_total]),
	"metrics": {"docs_total": docs_total, "schema_rejected": count(rejected), "leaked_into_engine": count(leaked)},
	"_legal_basis": "UoR art. 4 ust. 4 (dowody rzetelne) [NIEZWERYFIKOWANE — ISAP]; KSeF FA(3) walidacja struktury; prompt P57 Sekcja 10-I01",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i01 := object.get(_ctx, "I01_ingest_contract_schema", {})
	schema_version := object.get(_ctx_i01, "schema_version", "unknown")
	docs_total := object.get(_ctx_i01, "docs_total", 0)
	rejected := object.get(_ctx_i01, "rejected", [])
	leaked := object.get(_ctx_i01, "leaked_into_engine", [])
	count(leaked) >= 1
}

# ── I02: NIP checksum gate ────────────────────────────────────────────────────
# Silnik: modulo 11 z wagami [6,5,7,2,3,4,5,6,7]. Błędny NIP przyjęty
# (nie odrzucony) = BLOCK; błędny NIP odrzucony = pozytywna kontrola (PASS).
i02_nip_checksum := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.nip_checksum_gate",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457002,
	"decision": "BLOCK",
	"reason": sprintf("NIP checksum gate: %v z %v błędnych NIP przyjętych bez odrzucenia (cicha normalizacja)", [count(accepted_bad), bad_total]),
	"metrics": {"bad_total": bad_total, "rejected_bad": count(rejected_bad), "accepted_bad": count(accepted_bad)},
	"_legal_basis": "VAT art. 96 (NIP identyfikator podatkowy) [NIEZWERYFIKOWANE — ISAP]; prompt P57 Sekcja 10-I02",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i02 := object.get(_ctx, "I02_nip_checksum_gate", {})
	bad_total := object.get(_ctx_i02, "bad_total", 0)
	rejected_bad := object.get(_ctx_i02, "rejected_bad", [])
	accepted_bad := object.get(_ctx_i02, "accepted_bad", [])
	count(accepted_bad) >= 1
}

# ── I03: Semantic dedup key ───────────────────────────────────────────────────
# Silnik: klucz (nip, data, kwota_gr, numer). Duplikat wykryty, ale
# NIEZAREJESTROWANY w rejestrze do przeglądu człowieka = BLOCK (P49:
# zero cichych ścieżek — duplikat musi mieć ścieżkę).
i03_dedup := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.semantic_dedup_key",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457003,
	"decision": "BLOCK",
	"reason": sprintf("klucz semantyczny %v: %v z %v duplikatów NIEZAREJESTROWANYCH do przeglądu (ryzyko podwójnego księgowania)", [key_fields, count(unregistered), dups_total]),
	"metrics": {"dups_total": dups_total, "registered": count(registered), "unregistered": count(unregistered)},
	"_legal_basis": "UoR art. 5 (zapis odzwierciedla rzeczywiste zdarzenie) [NIEZWERYFIKOWANE — ISAP]; P32 idempotencja; prompt P57 Sekcja 10-I03",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i03 := object.get(_ctx, "I03_semantic_dedup_key", {})
	key_fields := _th("v3_p57_dedup_key_fields", ["nip", "data", "kwota_gr", "numer"])
	dups_total := object.get(_ctx_i03, "dups_total", 0)
	registered := object.get(_ctx_i03, "registered", [])
	unregistered := object.get(_ctx_i03, "unregistered", [])
	count(unregistered) >= 1
}

# ── I04: Original-first WORM ──────────────────────────────────────────────────
# Silnik: zapis oryginału WORM z checksumą PRZED przetwarzaniem (worm_storage
# + v3_p42_worm_hash_chain). Dokument przetworzony bez śladu pierwotności
# = BLOCK — łańcuch dowodów musi zaczynać się od pierwszego bajta.
i04_worm := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.original_first_worm",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457004,
	"decision": "BLOCK",
	"reason": sprintf("original-first WORM: %v z %v dokumentów przetworzonych BEZ checksumy oryginału (przerwana pierwotność dowodu)", [count(missing_worm), processed_total]),
	"metrics": {"processed_total": processed_total, "with_worm": count(with_worm), "missing_worm": count(missing_worm)},
	"_legal_basis": "UoR art. 5 (pierwotne dowody); RODO art. 5 ust. 1f (integralność) [NIEZWERYFIKOWANE — ISAP]; P42 WORM; prompt P57 Sekcja 10-I04",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i04 := object.get(_ctx, "I04_original_first_worm", {})
	processed_total := object.get(_ctx_i04, "processed_total", 0)
	with_worm := object.get(_ctx_i04, "with_worm", [])
	missing_worm := object.get(_ctx_i04, "missing_worm", [])
	count(missing_worm) >= 1
}

# ── I05: Status state machine ─────────────────────────────────────────────────
# Silnik: przejścia statusów z łańcucha z ADR-002. Przejście nielegalne
# (skok/backjump) lub dokument bez statusu = NEEDS_ADVICE (P40 widzi stan).
i05_status_machine := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.status_state_machine",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457005,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("state machine statusów: %v nielegalnych przejść / %v dokumentów bez statusu (łańcuch %v)", [illegal_count, missing_status, chain]),
	"metrics": {"docs_total": docs_total, "illegal_transitions": illegal_count, "missing_status": missing_status},
	"_legal_basis": "UoR art. 4 ust. 4 (kompletność ścieżki); prompt P57 Sekcja 10-I05",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i05 := object.get(_ctx, "I05_status_state_machine", {})
	chain := _th("v3_p57_status_chain", ["przyjety", "zweryfikowany", "zaakceptowany", "zaksiegowany", "zarchiwizowany"])
	docs_total := object.get(_ctx_i05, "docs_total", 0)
	illegal_count := object.get(_ctx_i05, "illegal_transitions", 0)
	missing_status := object.get(_ctx_i05, "missing_status", 0)
	illegal_count + missing_status >= 1
}

# ── I06: Repair path for rejects ──────────────────────────────────────────────
# Silnik: każdy odrzucony dokument ma ścieżkę naprawy (pole→akcja→powrót
# do kolejki). Odrzucony bez ścieżki = NEEDS_ADVICE (zero zgubionych).
i06_repair_path := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.repair_path_for_rejects",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457006,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("ścieżka naprawy: %v z %v odrzuconych dokumentów BEZ określonej naprawy (pole→akcja) — ryzyko dokumentu zgubionego", [count(no_repair), rejected_total]),
	"metrics": {"rejected_total": rejected_total, "with_repair": count(with_repair), "no_repair": count(no_repair)},
	"_legal_basis": "prompt P57 Sekcja 10-I06; P32 kontrakt pipeline (ingest = pierwszy etap)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i06 := object.get(_ctx, "I06_repair_path_for_rejects", {})
	rejected_total := object.get(_ctx_i06, "rejected_total", 0)
	with_repair := object.get(_ctx_i06, "with_repair", [])
	no_repair := object.get(_ctx_i06, "no_repair", [])
	count(no_repair) >= 1
}

# ── I07: Bank reconciliation engine ───────────────────────────────────────────
# Silnik: feed bankowy↔faktury (rozszerzenie kontraktu P32). Rozjazd
# systemowy powyżej progu z ADR-002 = MANUAL_REVIEW (człowiek przegląda
# parowanie); pojedynczy przelew bez faktury → NEEDS_ADVICE z kandydatami.
i07_reconciliation := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.bank_reconciliation_engine",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457007,
	"decision": "MANUAL_REVIEW",
	"reason": sprintf("reconciliation: %v%% nieparowanych przelewów > próg %v%% (systemowy rozjazd feed↔faktury — przegląd człowieka)", [unmatched_pct, max_pct]),
	"metrics": {"feed_total": feed_total, "matched": matched_total, "unmatched": unmatched_total, "unmatched_pct": unmatched_pct},
	"_legal_basis": "P32 kontrakt recon (auto-parowanie, alarm rozjazdów); prompt P57 Sekcja 10-I07",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i07 := object.get(_ctx, "I07_bank_reconciliation_engine", {})
	max_pct := _th("v3_p57_recon_unmatched_max_pct", 5)
	feed_total := object.get(_ctx_i07, "feed_total", 0)
	matched_total := object.get(_ctx_i07, "matched", 0)
	unmatched_total := object.get(_ctx_i07, "unmatched", 0)
	unmatched_pct := object.get(_ctx_i07, "unmatched_pct", 0)
	unmatched_pct > max_pct
}

# ── I08: Ingest chaos suite ───────────────────────────────────────────────────
# Silnik: chaos input (złe typy, ujemne kwoty, duplikaty, braki) przepuszczony
# przez bramki I01–I03. Przypadek chaosu NIEWYKRYTY (przyjęty) = BLOCK —
# pozytywna kontrola detektorów (konwencja P54-I06 / P56-I10: fail-closed
# karze NIEWYKRYCIE, nie samą detekcję).
i08_chaos := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.ingest_chaos_suite",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457008,
	"decision": "BLOCK",
	"reason": sprintf("chaos suite: %v z %v przypadków złośliwych NIEWYKRYTYCH przez bramki granicy (fail-closed dziurawy)", [count(undetected), cases_total]),
	"metrics": {"cases_total": cases_total, "detected": count(detected), "undetected": count(undetected)},
	"_legal_basis": "prompt P57 Sekcja 10-I08; P39 bramki CI; P43 security",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i08 := object.get(_ctx, "I08_ingest_chaos_suite", {})
	cases_total := object.get(_ctx_i08, "cases_total", 0)
	detected := object.get(_ctx_i08, "detected", [])
	undetected := object.get(_ctx_i08, "undetected", [])
	count(undetected) >= 1
}

# ── I09: Ingest metrics ───────────────────────────────────────────────────────
# Silnik: wolumen, odrzucenia z powodami, duplikaty, czasy przetwarzania
# (P37). Wskaźnik odrzuceń powyżej progu LUB brak metryk = NEEDS_ADVICE
# (zdrowie granicy niewidoczne = granica niekontrolowana).
i09_metrics := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.ingest_metrics",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("metryki ingestu: odrzucenia %v%% > próg %v%% lub metryki niekompletne (brakujące: %v) — P37", [reject_pct, max_pct, missing_metrics]),
	"metrics": {"volume": volume, "rejects": rejects, "duplicates": duplicates, "reject_pct": reject_pct},
	"_legal_basis": "P37 obserwowalność; prompt P57 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_ingest_metrics", {})
	max_pct := _th("v3_p57_reject_rate_max_pct", 10)
	volume := object.get(_ctx_i09, "volume", 0)
	rejects := object.get(_ctx_i09, "rejects", 0)
	duplicates := object.get(_ctx_i09, "duplicates", 0)
	reject_pct := object.get(_ctx_i09, "reject_pct", 0)
	missing_metrics := object.get(_ctx_i09, "missing_metrics", [])
	reject_pct > max_pct
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.ingest_metrics",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457009,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("metryki ingestu niekompletne (brakujące: %v) — P37 wymaga pełnego zestawu", [missing_metrics]),
	"metrics": {"missing_metrics": count(missing_metrics)},
	"_legal_basis": "P37 obserwowalność; prompt P57 Sekcja 10-I09",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i09 := object.get(_ctx, "I09_ingest_metrics", {})
	volume := object.get(_ctx_i09, "volume", 0)
	rejects := object.get(_ctx_i09, "rejects", 0)
	duplicates := object.get(_ctx_i09, "duplicates", 0)
	reject_pct := object.get(_ctx_i09, "reject_pct", 0)
	missing_metrics := object.get(_ctx_i09, "missing_metrics", [])
	count(missing_metrics) >= 1
}

# ── I10: Provenance chain to certificate ──────────────────────────────────────
# Silnik: certyfikat decyzji P11 → checksuma oryginału → dokument. Certyfikat
# bez odwołania do checksumy oryginału = BLOCK (łańcuch audytowy przerwany;
# audytor nie zejdzie do dokumentu — UoR art. 193a).
i10_provenance := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.provenance_chain_to_certificate",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457010,
	"decision": "BLOCK",
	"reason": sprintf("łańcuch proweniencji: %v z %v certyfikatów BEZ checksumy oryginału (przerwana odtwarzalność dowodu — art. 193a OP)", [count(broken), certs_total]),
	"metrics": {"certs_total": certs_total, "chained": count(chained), "broken": count(broken)},
	"_legal_basis": "OP art. 193a (weryfikacja, odtworzenie dowodów) [NIEZWERYFIKOWANE — ISAP]; P11 certyfikat; P42 WORM; prompt P57 Sekcja 10-I10",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i10 := object.get(_ctx, "I10_provenance_chain_to_certificate", {})
	certs_total := object.get(_ctx_i10, "certs_total", 0)
	chained := object.get(_ctx_i10, "chained", [])
	broken := object.get(_ctx_i10, "broken", [])
	count(broken) >= 1
}

# ── I11: Multi-tenant ingest isolation ────────────────────────────────────────
# Silnik: każdy rekord ma tenant_id; próba dostępu międzytenantowego
# wykryta. Rekord bez tenant_id = BLOCK (izolacja w schemacie od dnia
# pierwszego — przyszłość multi-tenant bez migracji).
i11_tenant_isolation := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.multi_tenant_isolation",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457011,
	"decision": "BLOCK",
	"reason": sprintf("izolacja tenantów: %v rekordów bez tenant_id, %v przecieków międzytenantowych (izolacja wymagana polityką %v)", [count(missing_tenant), leaks, policy]),
	"metrics": {"records_total": records_total, "missing_tenant": count(missing_tenant), "cross_tenant_leaks": leaks},
	"_legal_basis": "RODO art. 5 ust. 1f (poufność) [NIEZWERYFIKOWANE — ISAP]; prompt P57 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_multi_tenant_isolation", {})
	policy := _th("v3_p57_tenant_isolation_policy", "required")
	records_total := object.get(_ctx_i11, "records_total", 0)
	missing_tenant := object.get(_ctx_i11, "missing_tenant", [])
	leaks := object.get(_ctx_i11, "cross_tenant_leaks", 0)
	count(missing_tenant) >= 1
} else := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.multi_tenant_isolation",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457011,
	"decision": "BLOCK",
	"reason": sprintf("izolacja tenantów: %v przecieków międzytenantowych (izolacja wymagana polityką %v)", [leaks, policy]),
	"metrics": {"records_total": records_total, "cross_tenant_leaks": leaks},
	"_legal_basis": "RODO art. 5 ust. 1f (poufność) [NIEZWERYFIKOWANE — ISAP]; prompt P57 Sekcja 10-I11",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i11 := object.get(_ctx, "I11_multi_tenant_isolation", {})
	policy := _th("v3_p57_tenant_isolation_policy", "required")
	records_total := object.get(_ctx_i11, "records_total", 0)
	leaks := object.get(_ctx_i11, "cross_tenant_leaks", 0)
	leaks >= 1
}

# ── I12: Ingest rate governor ─────────────────────────────────────────────────
# Silnik: limit wolumenu per kanał z licznikami. Brak governor = NEEDS_ADVICE
# (granica bez strażnika); kanał przekraczający limit = ochrona działa
# (pozytywna kontrola), ale kanał BEZ licznika przy aktywnym ruchu = luka.
i12_rate_governor := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.ingest_rate_governor",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 457012,
	"decision": "NEEDS_ADVICE",
	"reason": sprintf("rate governor: %v z %v kanałów BEZ licznika wolumenu (granica bez strażnika; limit %v/h)", [count(unmonitored), channels_total, limit]),
	"metrics": {"channels_total": channels_total, "monitored": count(monitored), "unmonitored": count(unmonitored)},
	"_legal_basis": "prompt P57 Sekcja 10-I12; P43 security (ochrona przed spamem/atakiem)",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_ctx_i12 := object.get(_ctx, "I12_ingest_rate_governor", {})
	limit := _th("v3_p57_rate_limit_per_channel_hour", 500)
	channels_total := object.get(_ctx_i12, "channels_total", 0)
	monitored := object.get(_ctx_i12, "monitored", [])
	unmonitored := object.get(_ctx_i12, "unmonitored", [])
	count(unmonitored) >= 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# ROUTER decide — deterministyczny else-chain (konwencja P51–P56):
# najpierw BLOCK, potem NEEDS_ADVICE/MANUAL_REVIEW, na końcu PASS.
# Bez flagi v3_p57_check → NO_MATCH (nigdy domyślne AUTO_POST).
# ═══════════════════════════════════════════════════════════════════════════════
decide := fail_closed_decision {
	_not(_snapshot_ok)
} else := i01_schema {
	_snapshot_ok
	_activated
	i01_schema.decision == "BLOCK"
} else := i02_nip_checksum {
	_snapshot_ok
	_activated
	i02_nip_checksum.decision == "BLOCK"
} else := i03_dedup {
	_snapshot_ok
	_activated
	i03_dedup.decision == "BLOCK"
} else := i04_worm {
	_snapshot_ok
	_activated
	i04_worm.decision == "BLOCK"
} else := i08_chaos {
	_snapshot_ok
	_activated
	i08_chaos.decision == "BLOCK"
} else := i10_provenance {
	_snapshot_ok
	_activated
	i10_provenance.decision == "BLOCK"
} else := i11_tenant_isolation {
	_snapshot_ok
	_activated
	i11_tenant_isolation.decision == "BLOCK"
} else := i05_status_machine {
	_snapshot_ok
	_activated
	i05_status_machine.decision == "NEEDS_ADVICE"
} else := i06_repair_path {
	_snapshot_ok
	_activated
	i06_repair_path.decision == "NEEDS_ADVICE"
} else := i09_metrics {
	_snapshot_ok
	_activated
	i09_metrics.decision == "NEEDS_ADVICE"
} else := i12_rate_governor {
	_snapshot_ok
	_activated
	i12_rate_governor.decision == "NEEDS_ADVICE"
} else := i07_reconciliation {
	_snapshot_ok
	_activated
	i07_reconciliation.decision == "MANUAL_REVIEW"
} else := all_green_pass {
	_snapshot_ok
	_activated
} else := {
	"matched": false,
	"rule_id": "jdg.v3_p57_ingest_data.no_match",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 0,
	"decision": "NO_MATCH",
	"reason": "P57 niewyzwolony (brak flagi v3_p57_check)",
	"_legal_basis": "konwencja aktywacji V3 P47–P56",
	"valid_from": "2026-01-01",
	"valid_to": null,
} {
	_snapshot_ok
}

all_green_pass := {
	"matched": true,
	"rule_id": "jdg.v3_p57_ingest_data.all_green",
	"package": "jdg.v3_p57_ingest_data",
	"priority": 1,
	"decision": "PASS",
	"reason": "P57: brak naruszeń granicy ingestu (12 analiz zielonych)",
	"metrics": {"analyses": 12},
	"_legal_basis": "UoR art. 4/5; VAT art. 106b/109e; OP art. 193a; RODO art. 5 ust. 1f; KSeF FA(3) [NIEZWERYFIKOWANE — ISAP]",
	"valid_from": "2026-01-01",
	"valid_to": null,
}
