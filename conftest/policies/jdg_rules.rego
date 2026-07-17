# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Conftest Policies for Rego Validation (B3 Strategic Initiative)
# ═══════════════════════════════════════════════════════════════════════════════
#
# 6 namespaces odpowiadających matrycy CI:
#   1. matched_true_required — każda reguła emituje matched=true
#   2. no_fallback_allow — brak cichych ALLOW fallbacków
#   3. rule_id_canonical — rule_id w mapie kanonicznej
#   4. no_hardcoded_integers — zero magicznych liczb
#   5. legal_basis_required — każda reguła z _legal_basis
#   6. temporal_validity_required — wpis w rejestrze temporalnym
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# Namespace 1: matched_true_required
# Każda reguła decyzyjna MUSI zwracać matched=true.
# matched:false w else-chain = dopuszczalne TYLKO jako jawny default fallback.
# ═══════════════════════════════════════════════════════════════════════════════
package conftest.matched_true_required

deny_matched_false[msg] {
    some rule_result in input
    rule_result.matched == false
    rid := object.get(rule_result, "rule_id", "")
    not rid in data.conftest.canonical_map._default_fallbacks
    msg := sprintf("Rule '%s' returns matched:false — must be matched:true or explicitly documented as default fallback", [rid])
}

# ═══════════════════════════════════════════════════════════════════════════════
# Namespace 2: no_fallback_allow
# Ścieżki walidacyjne nie mogą kończyć się domyślnym ALLOW.
# Każda gałąź MUSI mieć konkretny _routing: BLOCK_AND_ALERT / TRIAGE_QUEUE / "".
# ═══════════════════════════════════════════════════════════════════════════════
package conftest.no_fallback_allow

deny_fallback_allow[msg] {
    some rule_result in input
    rule_result.matched == true
    routing := object.get(rule_result, "_routing", "MISSING")
    routing == "MISSING"
    msg := sprintf("Rule '%s' has no _routing field — BLOCK_AND_ALERT, TRIAGE_QUEUE, or explicit '' required", [rule_result.rule_id])
}

# ═══════════════════════════════════════════════════════════════════════════════
# Namespace 3: rule_id_canonical
# Każdy rule_id MUSI być w formacie 'jdg.<package>.<rule>' lub być
# zarejestrowany w canonical_map.json.
# ═══════════════════════════════════════════════════════════════════════════════


# ═══════════════════════════════════════════════════════════════════════════════
# Namespace 4: no_hardcoded_integers
# Żadna wartość liczbowa > 1000 nie może być zahardkodowana w Rego
# (poza thresholds_jdg.rego i _metadata_jdg.rego).
# Delegowane do grep-based lintera w CI — tu sygnatura dla Conftest.
# ═══════════════════════════════════════════════════════════════════════════════
package conftest.no_hardcoded_integers

deny_hardcoded[msg] {
    msg := "Hardcoded integer detection: delegated to grep-based linter in CI workflow and JDG/tools/lint_rego_rules.py"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Namespace 5: legal_basis_required
# Każda reguła decyzyjna MUSI zawierać _legal_basis z odnośnikiem do
# aktu prawnego (art. + ust. + pkt + lit.).
# ═══════════════════════════════════════════════════════════════════════════════
package conftest.legal_basis_required

deny_missing_legal_basis[msg] {
    some rule_result in input
    rule_result.matched == true
    legal_basis := object.get(rule_result, "_legal_basis", "")
    legal_basis == ""
    rid := object.get(rule_result, "rule_id", "")
    not rid in data.conftest.legal_basis_map._exempt_rules
    msg := sprintf("Rule '%s' missing _legal_basis — every rule must cite legal basis (art./ust./pkt/lit.)", [rid])
}

# Pełna walidacja _legal_basis delegowana do JDG/tools/lint_rego_rules.py

# ═══════════════════════════════════════════════════════════════════════════════
# Namespace 6: temporal_validity_required
# Każda reguła decyzyjna MUSI mieć wpis temporal_validity w
# _metadata_jdg.rego LUB być jawnie oznaczona jako "ALWAYS ACTIVE".
# ═══════════════════════════════════════════════════════════════════════════════
package conftest.temporal_validity_required

# Pełna walidacja temporalna delegowana do JDG/tools/lint_rego_rules.py + DuckDB
# Conftest sprawdza tylko obecność wpisu w temporal_registry seed data
deny_missing_temporal[msg] {
    some rule_result in input
    rule_result.matched == true
    rid := object.get(rule_result, "rule_id", "")
    not data.conftest.temporal_registry._entries[rid]
    msg := sprintf("Rule '%s' has no temporal validity entry in seed registry — add to conftest/data/temporal_registry.json", [rid])
}
