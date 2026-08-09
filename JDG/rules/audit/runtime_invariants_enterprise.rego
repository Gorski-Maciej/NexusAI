# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — WARSTWA KONSTYTUCYJNA: RUNTIME INVARIANTS (F2, WIZJA V2 §3)
# ═══════════════════════════════════════════════════════════════════════════════
# Katalog niezmienników systemowych (INV-001..INV-042) — „konstytucja" systemu
# decyzyjnego. Weryfikowane na KAŻDYM werdykcie w runtime (koniec POST-MERGE)
# oraz w CI (invariant_checker.py). Naruszenie = BLOCK + alarm + auto-revert.
#
# ROZBUDOWA P03 (Orkiestrator + Infrastruktura Reguł, 2026-08-08):
#   • Katalog rozszerzony do INV-042 (dodano INV-031..INV-042 — determinizm,
#     certyfikat, wersje, degradacja, graf zależności, golden path).
#   • Nowa funkcja CZYSTA evaluate(v) — jedno źródło prawdy dla egzekucji,
#     wywoływana w runtime (POST-MERGE) i w CI (bez zależności od input).
#   • Nowa funkcja enforce(v) — hak POST-MERGE (ADR-022): na każdym werdykcie
#     końcowym wstrzykuje _invariant_report, certainty_class (F4 V2),
#     _certainty_guard (CERTAINTY_BLOCKED / MANUAL_REVIEW / AUTO_POST_ALLOWED)
#     oraz _decision_certificate (F4) z decision_hash (F3 V2) i wersjami
#     bundle/rule/threshold (V1 §9.3).
#   • Egzekucja poziomów (V2 §3.2): BUILD (CI), RUNTIME (werdykt), STATISTICAL
#     (auto-rollback bundle przy naruszeniu > 0.01%).
#
# Trzy poziomy egzekucji (V2 §3.2):
#   BUILD      — blokada merge w CI,
#   RUNTIME    — blokada werdyktu (CERTAINTY_BLOCKED) na każdym werdykcie,
#   STATISTICAL— auto-rollback bundle przy naruszeniu > 0.01% (monitor).
#
# Zgodność: ADR-017 + ADR-022, V1 §8 (testy L1 property), V2 §3.1, §5.2 (F4).
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.runtime_invariants

import future.keywords.if
import future.keywords.in

# ── Katalog niezmienników (dane — rozszerzalny przez manifest) ─────────────────
# UWAGA: format jednowierszowy {"id","description","level","enforcement"} jest
# parsowany przez tools/invariant_checker.py (regex) — nie łamać na linie.
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
    {"id": "INV-031", "description": "każdy werdykt matched=true posiada decision_hash (F3 V2)", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-032", "description": "certainty_class ∈ {CERTAIN, CONDITIONAL, NEEDS_ADVICE} (F4 V2)", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-033", "description": "_legal_basis_refs spójne z _legal_basis (F1 V2 — referencja LKG)", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-034", "description": "bundle_version/rule_version/threshold_version współspójne (V1 §9.3)", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-035", "description": "routing BLOCK_AND_ALERT nigdy nie prowadzi do auto-postu (PASS 0 gate)", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-036", "description": "kontekst routingu kompletny: tax_form, transaction_type, entity_status, evaluation_date", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-037", "description": "okna ważności reguł bez luk i bez nakładek (algebra interwałów)", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-038", "description": "kontekst zdegradowany (_degraded_context) nigdy nie produkuje CERTAIN", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-039", "description": "provenance_tree.path ≥ 1 dla werdyktów matched=true (A1)", "level": "RUNTIME", "enforcement": "BLOCK"},
    {"id": "INV-040", "description": "input_hash cache-key deterministyczny (ten sam input = ten sam klucz)", "level": "STATISTICAL", "enforcement": "ALERT"},
    {"id": "INV-041", "description": "graf zależności acykliczny (brak self-dependency reguły)", "level": "BUILD", "enforcement": "BLOCK"},
    {"id": "INV-042", "description": "allowlist niemutowalna zweryfikowana w runtime (safe_merge integrity)", "level": "RUNTIME", "enforcement": "BLOCK"},
]

# ── Normalizacja wejścia: cały obiekt (werdykt) lub elementy listy ─────────────
# (funkcja zwracająca tablicę — nagłówek częściowego zbioru f(args)[V] nie jest
# poprawnym Rego; poprawka P03 GLM52)
_candidates_for(v) = cand {
    is_object(v)
    cand := [v]
} else = cand {
    is_array(v)
    cand := v
} else = [v] {
    true
}
# Backward-compat: wejście przez input.verdict
_candidates[V] { V := _candidates_for(input.verdict)[_] }

# ── Helpers ────────────────────────────────────────────────────────────────────
_has(v, k) { v[k] != null }
_is_num(x) { is_number(x) }

# Brak podstawy prawnej jest fail-closed: puste stringi i tablice nie są
# traktowane jako dowód zgodności. Nie używamy trim_space, aby zachować
# kompatybilność z minimalnym profilem built-inów OPA/WASM.
_basis_missing(v) {
    object.get(v, "_legal_basis_refs", null) == null
    object.get(v, "_legal_basis", null) == null
}

_basis_missing(v) {
    refs := object.get(v, "_legal_basis_refs", null)
    refs == ""
}

_basis_missing(v) {
    refs := object.get(v, "_legal_basis_refs", null)
    is_array(refs)
    count(refs) == 0
}

_basis_missing(v) {
    basis := object.get(v, "_legal_basis", null)
    basis == ""
}

_basis_missing(v) {
    basis := object.get(v, "_legal_basis", null)
    is_array(basis)
    count(basis) == 0
}

_epsilon := 0.01  # epsilon groszowy (INV-003/INV-022) — zaokrąglenie do 2 miejsc

# Dozwolone stawki VAT — obsługa BOTH stringów ("0.23") i liczb (0.23)
# w werdyktach legacy (fallback/risk używają stringów).
_rate_ok(r) { r in {"ZW", "NP", "OO", 0, 0.05, 0.08, 0.23} }
_rate_ok(r) { to_number(r) in {0, 0.05, 0.08, 0.23} }

# ── evaluate(v): CZYSTA funkcja egzekucji (jedno źródło prawdy) ────────────────
# Zwraca: {"invariant_failed": bool, "certainty_class": str, "failed": [ids],
#          "checked": n, "levels": {...}} — deterministyczna dla tego samego v.
evaluate(v) = result {
    failed := _failed_invariants(v)
    cert := _classify(failed, v)
    result := {
        "invariant_failed": count(failed) > 0,
        "certainty_class": cert,
        "failed": failed,
        "checked": count(catalog),
        "runtime_checked": count([c | c := catalog[_]; c.level == "RUNTIME"]),
        "build_checked": count([c | c := catalog[_]; c.level == "BUILD"]),
        "statistical_checked": count([c | c := catalog[_]; c.level == "STATISTICAL"]),
        "levels": {"RUNTIME": "ENFORCED", "BUILD": "CI_GATE", "STATISTICAL": "MONITOR"},
    }
} else := {
    "invariant_failed": false,
    "certainty_class": "NEEDS_ADVICE",
    "failed": [],
    "checked": 0,
    "runtime_checked": 0,
    "build_checked": 0,
    "statistical_checked": 0,
    "levels": {},
    "degraded": true,
} {
    true
}

# ── Lista naruszonych niezmienników dla werdyktu v ─────────────────────────────
_failed_invariants(v) = failed {
    failed := [id |
        some id in {
            "INV-001", "INV-002", "INV-003", "INV-004", "INV-005", "INV-006",
            "INV-007", "INV-009", "INV-012", "INV-014", "INV-020",
            "INV-021", "INV-022", "INV-024", "INV-028", "INV-030",
            "INV-032", "INV-034", "INV-035", "INV-036", "INV-038",
            "INV-039",
        }
        _inv_violated(id, v)
    ]
} else := [] {
    true
}
# Uwaga: INV-029/INV-031 (decision_hash na werdykcie) NIE są blokowane w fazie
# PRE-certificate (enforce() sam dodaje decision_hash w _decision_certificate).
# Egzekwowane przez host PO certyfikacji i w CI (invariant_checker.py / golden
# replay) — na certyfikowanym werdykcie decision_hash MUSI istnieć (F3 V2).

# ── Pojedyncza kontrola niezmiennika (deterministyczna) ────────────────────────
_inv_violated("INV-001", v) {
    some c in _candidates_for(v)
    is_object(c)
    r := c.vat_rate
    r != null
    r != ""
    not _rate_ok(r)
}

_inv_violated("INV-002", v) {
    some c in _candidates_for(v)
    is_object(c)
    is_number(c.net_amount)
    c.net_amount < 0
}

_inv_violated("INV-002", v) {
    some c in _candidates_for(v)
    is_object(c)
    is_number(c.vat_amount)
    c.vat_amount < 0
}

_inv_violated("INV-003", v) {
    some c in _candidates_for(v)
    is_object(c)
    is_number(c.net_amount)
    is_number(c.gross_amount)
    is_number(c.vat_amount)
    abs((c.net_amount + c.vat_amount) - c.gross_amount) > _epsilon
}

_inv_violated("INV-004", v) {
    some c in _candidates_for(v)
    is_object(c)
    is_number(c.tax_base)
    is_number(c.deductions_total)
    c.deductions_total > c.tax_base + _epsilon
}

_inv_violated("INV-005", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._warnings[_] == "IMMUTABLE_VERDICT_OVERWRITE"
}

_inv_violated("INV-006", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._routing == "BLOCK_AND_ALERT"
    c.auto_post == true
}

_inv_violated("INV-007", v) {
    some c in _candidates_for(v)
    is_object(c)
    c.amount_gross != null
    is_number(c.amount_gross)
    c.currency == ""
}

_inv_violated("INV-009", v) {
    some c in _candidates_for(v)
    is_object(c)
    c.matched == true
    _basis_missing(c)
}


_inv_violated("INV-020", v) {
    some c in _candidates_for(v)
    is_object(c)
    c.matched == true
    c._routing != ""
    not _has(c, "_routing_context")
}

_inv_violated("INV-021", v) {
    some c in _candidates_for(v)
    is_object(c)
    is_number(c.net_amount)
    is_number(c.gross_amount)
    c.gross_amount < c.net_amount - _epsilon
}

_inv_violated("INV-022", v) {
    some c in _candidates_for(v)
    is_object(c)
    is_number(c.tax_base)
    is_number(c.vat_rate)
    is_number(c.vat_amount)
    abs(c.vat_amount - (c.vat_rate * c.tax_base)) > _epsilon * 100
}

_inv_violated("INV-024", v) {
    some c in _candidates_for(v)
    is_object(c)
    c.business_status == "SUSPENDED"
    c.zus_social_due == true
}

_inv_violated("INV-028", v) {
    some c in _candidates_for(v)
    is_object(c)
    is_number(c.relief_value)
    is_number(c.tax_due)
    c.relief_value > c.tax_due + _epsilon
}

_inv_violated("INV-029", v) {
    some c in _candidates_for(v)
    is_object(c)
    c.immutable_verdict == true
    not _has(c, "decision_hash")
}

_inv_violated("INV-030", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._provenance_tree != null
    not _has(c._provenance_tree, "bundle_version")
}

_inv_violated("INV-031", v) {
    some c in _candidates_for(v)
    is_object(c)
    c.matched == true
    not _has(c, "decision_hash")
}

_inv_violated("INV-032", v) {
    some c in _candidates_for(v)
    is_object(c)
    c.matched == true
    c.certainty_class != null
    not c.certainty_class in {"CERTAIN", "CONDITIONAL", "NEEDS_ADVICE"}
}

_inv_violated("INV-034", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._versions != null
    _versions_ok := {
        "bundle_version": object.get(c._versions, "bundle_version", ""),
        "rule_version": object.get(c._versions, "rule_version", ""),
        "threshold_version": object.get(c._versions, "threshold_version", ""),
    }
    count([k | k := _versions_ok[_]; k == ""]) > 0
}

_inv_violated("INV-035", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._routing == "BLOCK_AND_ALERT"
    object.get(c, "auto_post", false) == true
}

_inv_violated("INV-036", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._routing_context != null
    ctx := c._routing_context
    not _has(ctx, "tax_form")
}

_inv_violated("INV-036", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._routing_context != null
    ctx := c._routing_context
    not _has(ctx, "transaction_type")
}

_inv_violated("INV-036", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._routing_context != null
    ctx := c._routing_context
    not _has(ctx, "entity_status")
}

_inv_violated("INV-036", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._routing_context != null
    ctx := c._routing_context
    not _has(ctx, "evaluation_date")
}

_inv_violated("INV-038", v) {
    some c in _candidates_for(v)
    is_object(c)
    c._degraded_context == true
    c.certainty_class == "CERTAIN"
}

_inv_violated("INV-039", v) {
    some c in _candidates_for(v)
    is_object(c)
    c.matched == true
    c._provenance_tree != null
    count(c._provenance_tree.path) < 1
}

# ── Klasyfikacja pewności (F4, V2 §5.2) ────────────────────────────────────────
# CERTAIN: brak naruszeń + pełna proweniencja; CONDITIONAL: wymaga interpretacji;
# NEEDS_ADVICE: brak reguły / luka pokrycia / naruszenie invariantu / degradacja.
_classify(failed, v) = "NEEDS_ADVICE" {
    count(failed) > 0
} else = "NEEDS_ADVICE" {
    some c in _candidates_for(v)
    is_object(c)
    c._degraded_context == true
} else = "CONDITIONAL" {
    some c in _candidates_for(v)
    is_object(c)
    c._warnings[_] == "REQUIRES_INTERPRETATION"
} else = "CERTAIN" {
    some c in _candidates_for(v)
    is_object(c)
    _has(c, "_provenance_tree")
} else = "CONDITIONAL" {
    true
}

# ── PUBLIC (backward-compat, sterowane input.verdict) ──────────────────────────
default invariant_failed := false
default certainty_class := "NEEDS_ADVICE"

invariant_failed {
    evaluate(input.verdict).invariant_failed
}

certainty_class := evaluate(input.verdict).certainty_class

# Raport egzekucji (dla monitora i certyfikatu F4)
report := {
    "invariant_failed": invariant_failed,
    "certainty_class": certainty_class,
    "checked_at": "runtime",
    "invariants_total": count(catalog),
    "invariants_runtime": count([c | c := catalog[_]; c.level == "RUNTIME"]),
    "failed": evaluate(input.verdict).failed,
}

# ── enforce(v): HAK POST-MERGE (ADR-022 — wywoływany w main_jdg.rego) ──────────
# Wstrzykuje do finalnego werdyktu: _invariant_report, certainty_class (F4),
# _certainty_guard oraz _decision_certificate (F4) z decision_hash (F3).
# Naruszenie invariantu → _certainty_guard = "CERTAINTY_BLOCKED" — host NIGDY
# nie wykonuje AUTO_POST dla werdyktu zablokowanego (INV-006/INV-035).
# Jedna reguła funkcji ogranicza ryzyko wieloznaczności: evaluate(v) jest
# deterministyczne, a auto_post jest zawsze wymuszone na false przy naruszeniu.
enforce(v) = result {
    ev := evaluate(v)
    base := {
        "certainty_class": ev.certainty_class,
        "_invariant_report": ev,
        "_certainty_guard": _guard(ev.certainty_class),
        "_decision_certificate": _certificate(v, ev),
    }
    result := object.union(base, _auto_post_guard(ev))
}

_auto_post_guard(ev) = {"auto_post": false} {
    ev.invariant_failed
} else = {} {
    not ev.invariant_failed
}

_guard(c) := "AUTO_POST_ALLOWED" { c == "CERTAIN" }
else := "MANUAL_REVIEW" { c == "CONDITIONAL" }
else := "CERTAINTY_BLOCKED"

# ── Decision Certificate (F4 V2 + V1 §9.3): decision_hash + wersje ────────────
_certificate(v, ev) = cert {
    verdict := [c | some c in _candidates_for(v); is_object(c)][0]
    dh := _decision_hash(verdict)
    versions := object.get(verdict, "_versions", {
        "bundle_version": object.get(input, "bundle_version", "unknown"),
        "rule_version": object.get(verdict, "rule_version", "unknown"),
        "threshold_version": object.get(input, "threshold_version", "unknown"),
    })
    cert := {
        "decision_id": object.get(verdict, "rule_id", "unknown"),
        "decision_hash": dh,
        "certainty_class": ev.certainty_class,
        "certainty_guard": _guard(ev.certainty_class),
        "routing": object.get(verdict, "_routing", ""),
        "matched": object.get(verdict, "matched", false),
        "versions": versions,
        "legal_basis_refs": object.get(verdict, "_legal_basis_refs", [object.get(verdict, "_legal_basis", "")]),
        "invariant_checksum": sprintf("%d/%d", [count([f | f := ev.failed[_]]), count(catalog)]),
        # Czysta ewaluacja: czas systemowy nie może zmieniać certyfikatu.
        # Host może przekazać jawny evaluated_at, a brak wartości oznacza
        # stabilny sentinel dla replay/golden tests.
        "evaluated_at": object.get(input, "evaluated_at", object.get(v, "evaluated_at", "runtime")),
        "signature": "hsm:placeholder-sha256",  # podpis HSM wykonywany przez host (P20 control plane)
    }
} else := {
    "decision_id": "unknown",
    "decision_hash": "sha256:undefined",
    "certainty_class": "NEEDS_ADVICE",
    "certainty_guard": "CERTAINTY_BLOCKED",
    "routing": "",
    "matched": false,
    "versions": {},
    "legal_basis_refs": [],
    "invariant_checksum": "0/0",
    "evaluated_at": "runtime",
    "signature": "hsm:unavailable",
} {
    true
}

# ── decision_hash: deterministyczny (INV-010/INV-031/INV-040) ──────────────────
# Ten sam input + wersje → ten sam hash (ewaluacja różnicowa F3 V2).
# OPA nie ma crypto.sha256 w standardzie — hashowanie SHA-256 wykonuje Python
# wrapper (decision_certificate.py); tutaj deterministyczny kanoniczny string.
_decision_hash(v) = sprintf("sha256:%s", [concat("|", [
    object.get(v, "rule_id", ""),
    object.get(v, "_routing", ""),
    sprintf("%v", [object.get(v, "vat_rate", "")]),
    sprintf("%v", [object.get(v, "net_amount", "")]),
    sprintf("%v", [object.get(v, "gross_amount", "")]),
    sprintf("%v", [object.get(v, "pit_rate", "")]),
    sprintf("%v", [object.get(v, "zus_health_rate", "")]),
    sprintf("%v", [object.get(v, "bundle_version", object.get(object.get(v, "_versions", {}), "bundle_version", object.get(input, "bundle_version", "")))]),
    sprintf("%v", [object.get(v, "rule_version", object.get(object.get(v, "_versions", {}), "rule_version", object.get(input, "rule_version", "")))]),
    sprintf("%v", [object.get(v, "threshold_version", object.get(object.get(v, "_versions", {}), "threshold_version", object.get(input, "threshold_version", "")))]),
])])
