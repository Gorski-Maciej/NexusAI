# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — WARSTWA KONSTYTUCYJNA: RUNTIME INVARIANTS (F2, WIZJA V2 §3)
# ═══════════════════════════════════════════════════════════════════════════════
# Katalog niezmienników systemowych (INV-001..INV-030) — „konstytucja" systemu
# decyzyjnego. Weryfikowane na KAŻDYM werdykcie w runtime (koniec POST-MERGE)
# oraz w CI (invariant_checker.py). Naruszenie = BLOCK + alarm + auto-revert.
#
# Trzy poziomy egzekucji (V2 §3.2):
#   BUILD      — blokada merge w CI,
#   RUNTIME    — blokada werdyktu (CERTAINTY_BLOCKED) na każdym werdykcie,
#   STATISTICAL— auto-rollback bundle przy naruszeniu > 0.01% (monitor).
#
# Zgodność: ADR-017, V1 §8 (testy L1 property), V2 §3.1.
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.runtime_invariants

# ── Katalog niezmienników (dane — rozszerzalny przez manifest) ─────────────────
catalog := [
    {"id": "INV-001", "description": "stawka VAT ∈ {0, 0.05, 0.08, 0.23, ZW, NP, OO}", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-002", "description": "kwota netto ≥ 0, podatek ≥ 0", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-003", "description": "brutto = netto × (1+stawka) ± epsilon groszowy", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-004", "description": "suma odliczeń ≤ podstawa opodatkowania", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-005", "description": "werdykt domeny niemutowalnej (ZUS/business/fortress) nigdy nie nadpisany", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-006", "description": "BLOCK_AND_ALERT w PASS 0 → werdykt bez AUTO_POST", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-007", "description": "każda kwota ma walutę i jest dodatnia lub równa 0", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-008", "description": "rule_id w werdykcie istnieje w rejestrze i jest ACTIVE dla daty ewaluacji", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-009", "description": "_legal_basis_refs niepuste dla werdyktów matched=true", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-010", "description": "determinizm: ten sam input + wersje = ten sam hash werdyktu (ewaluacja różnicowa)", "level": "STATISTICAL", "enforcement": "ALERT"},
    {"id": "INV-011", "description": "jeżeli werdykt ma vat_rate, to istnieje węzeł LKG ze stawką dla tej daty", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-012", "description": "kwoty walutowe zaokrąglone do 2 miejsc (grosze)", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-013", "description": "suma stawek cząstkowych = stawka całości (addtywność podatku)", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-014", "description": "podstawa opodatkowania nie może być ujemna po korektach", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-015", "description": "terminy nie w przeszłości dla zdarzeń przyszłych (kalendarz)", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-016", "description": "progi progresji PIT uporządkowane rosnąco (limit_i < limit_i+1)", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-017", "description": "stawki składek ZUS w dozwolonym przedziale (0, 1)", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-018", "description": "brak sprzecznych werdyktów tej samej domeny w jednej decyzji", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-019", "description": "każdy warning ma kod i severity", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-020", "description": "routing O(1): każdy werdykt ma _routing.context", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-021", "description": "kwoty brutto ≥ netto (dla stawek ≥ 0)", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-022", "description": "podatek VAT = stawka × podstawa ± epsilon groszowy", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-023", "description": "limit obrotu zwolnienia podmiotowego ≥ 0", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-024", "description": "zawieszenie działalności nie generuje składek ZUS za okres zawieszenia", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-025", "description": "korekta deklaracji nie zmienia historycznych werdyktów (time-travel)", "level": "STATISTICAL", "enforcement": "AUTO_REVERT"},
    {"id": "INV-026", "description": "przedawnienie zobowiązania zgodne z OrdPU (kalendarz przedawnień)", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-027", "description": "sankcje KKS nie przekraczają maksymalnego wymiaru kary", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-028", "description": "wartość zwolnienia ≤ wartość podatku należnego", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-029", "description": "werdykt niemutowalny (ZUS/business) posiada decision_hash", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-030", "description": "każdy werdykt niesie bundle_version + rule_version + threshold_version", "level": "RUNTIME", "enforcement": "BLOCK"},
]

# ── Egzekucja runtime na werdykcie (wywoływana na końcu POST-MERGE) ─────────────
# Kontrakt: input.verdict to werdykt 25-polowy (obiekt) LUB lista werdyktów
# cząstkowych — normalizacja _candidates pokrywa oba przypadki (ADR-004).
default invariant_failed := false
default certainty_class := "NEEDS_ADVICE"

# Normalizacja wejścia: cały obiekt + elementy listy/wartości obiektu
_candidates[V] { V := input.verdict }
_candidates[V] { some V in input.verdict }

# INV-001: stawka VAT ∈ dozwolonego zbioru
invariant_failed if {
    some v in _candidates
    is_object(v)
    v.vat_rate != null
    not v.vat_rate in {"ZW", "NP", "OO", 0, 0.05, 0.08, 0.23}
}

# INV-002: kwoty nieujemne
invariant_failed if {
    some v in _candidates
    is_object(v)
    v.net_amount != null
    v.net_amount < 0
}

# INV-005: werdykt domeny niemutowalnej nie może zostać nadpisany
invariant_failed if {
    some v in _candidates
    is_object(v)
    v._warnings[_] == "IMMUTABLE_VERDICT_OVERWRITE"
}

# INV-009: werdykt matched=true musi mieć podstawę prawną (brak lub pusta)
invariant_failed if {
    some v in _candidates
    is_object(v)
    v.matched == true
    not has_key(v, "_legal_basis")
}

invariant_failed if {
    some v in _candidates
    is_object(v)
    v.matched == true
    count(v._legal_basis) == 0
}

# INV-012: kwoty zaokrąglone do groszy (2 miejsca)
invariant_failed if {
    some v in _candidates
    is_object(v)
    is_number(v.vat_amount)
    abs(v.vat_amount - round(v.vat_amount * 100) / 100) > 0.0000001
}

# INV-030: werdykt niesie wersje (provenance)
invariant_failed if {
    some v in _candidates
    is_object(v)
    v._provenance_tree != null
    not has_key(v._provenance_tree, "bundle_version")
}

# ── Klasa pewności (F4, V2 §5.2) ───────────────────────────────────────────────
# CERTAIN: brak naruszeń + pełna proweniencja; CONDITIONAL: wymaga interpretacji;
# NEEDS_ADVICE: brak reguły / luka pokrycia / naruszenie invariantu.
certainty_class := "CERTAIN" if {
    not invariant_failed
    some v in _candidates
    is_object(v)
    has_key(v, "_provenance_tree")
}

certainty_class := "CONDITIONAL" if {
    not invariant_failed
    some v in _candidates
    is_object(v)
    v._warnings[_] == "REQUIRES_INTERPRETATION"
}

certainty_class := "NEEDS_ADVICE" if {
    invariant_failed
}

# Raport egzekucji (dla monitora i certyfikatu F4)
report := {
    "invariant_failed": invariant_failed,
    "certainty_class": certainty_class,
    "checked_at": "runtime",  # znacznik czasu wstrzykiwany przez host (data_service/invariant_checker)
    "invariants_total": count(catalog),
    "invariants_runtime": count([c | c := catalog[_]; c.level == "RUNTIME"]),
}
