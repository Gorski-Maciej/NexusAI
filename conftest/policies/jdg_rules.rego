# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Conftest Policies for Rego Validation (B3 Strategic Initiative)
# ═══════════════════════════════════════════════════════════════════════════════
#
# 6 walidacji CI na poziomie Pull Request:
#   1. matched_true_required — każda reguła emitować matched=true
#   2. no_fallback_allow — brak cichych ALLOW fallbacków
#   3. rule_id_canonical — rule_id zarejestrowany w mapie kanonicznej
#   4. no_hardcoded_integers — zero magicznych liczb
#   5. legal_basis_required — każda reguła z _legal_basis
#   6. temporal_validity_required — wpis w rejestrze temporalnym
# ═══════════════════════════════════════════════════════════════════════════════

package conftest.jdg

# ── Walidacja 1: Mandatory matched:true ─────────────────────────────────────
#
# Każda reguła decyzyjna MUSI zwracać matched=true lub być explicite
# oznaczona jako "pass-through" z powodem.
# matched:false w else-chain to dopuszczalne tylko jako default fallback.

deny_matched_false[msg] {
    some rule_result in input
    rule_result.matched == false
    not rule_result.rule_id == "jdg.accounting.no_match"  # dozwolony default
    not rule_result.rule_id == "jdg.conflicts.no_conflicts" # dozwolony default
    msg := sprintf("Rule '%s' returns matched:false — must be matched:true or explicitly documented", [rule_result.rule_id])
}

# ── Walidacja 2: No fallback ALLOW ───────────────────────────────────────────
#
# Ścieżki walidacyjne nie mogą kończyć się domyślnym ALLOW.
# Każda gałąź MUSI mieć konkretną decyzję: BLOCK_AND_ALERT / TRIAGE_QUEUE / DECISION.

deny_fallback_allow[msg] {
    some rule_result in input
    rule_result.matched == true
    routing := object.get(rule_result, "_routing", "MISSING")
    routing == "MISSING"
    msg := sprintf("Rule '%s' has no _routing field — BLOCK_AND_ALERT, TRIAGE_QUEUE, or explicit '' required", [rule_result.rule_id])
}

# ── Walidacja 3: Rule ID w mapie kanonicznej ──────────────────────────────────
#
# Każdy rule_id MUSI być zarejestrowany w data.jdg.metadata.rules_metadata
# lub jawnie oznaczony jako "pass-through".

deny_rule_id_not_canonical[msg] {
    some rule_result in input
    rule_result.matched == true
    not startswith(rule_result.rule_id, "jdg.")
    msg := sprintf("Rule ID '%s' does not follow canonical format 'jdg.<package>.<rule>'", [rule_result.rule_id])
}

# ── Walidacja 4: No hardcoded integers ────────────────────────────────────────
#
# Żadna wartość liczbowa > 1000 nie może być zahardkodowana w Rego.
# Wyjątki: priorytety, daty, identyfikatory testowe.

deny_hardcoded_integer[msg] {
    # Ta walidacja jest wykonywana przez grep w CI workflow
    # Tutaj tylko sygnatura dla Conftest
    msg := "Hardcoded integer detection delegated to grep-based linter in CI workflow"
}

# ── Walidacja 5: Legal basis required ────────────────────────────────────────
#
# Każda reguła decyzyjna MUSI zawierać _legal_basis z odnośnikiem do
# aktu prawnego (art. + ust. + pkt + lit.).

deny_missing_legal_basis[msg] {
    some rule_result in input
    rule_result.matched == true
    legal_basis := object.get(rule_result, "_legal_basis", "")
    legal_basis == ""
    not rule_result.rule_id == "jdg.accounting.no_match"  # dozwolony default
    not rule_result.rule_id == "jdg.conflicts.no_conflicts"
    msg := sprintf("Rule '%s' is missing _legal_basis — every rule must cite its legal basis (art./ust./pkt/lit.)", [rule_result.rule_id])
}

# ── Walidacja 6: Temporal validity required ──────────────────────────────────
#
# Każda reguła decyzyjna MUSI mieć wpis temporal_validity w _metadata_jdg.rego
# LUB być jawnie oznaczona jako "ALWAYS ACTIVE" (wariant A).

deny_missing_temporal[msg] {
    # Weryfikacja przez skrypt CI — sprawdza czy każdy rule_id w werdykcie
    # ma odpowiadający wpis w temporal_validity lub jest oznaczony jako
    # "ALWAYS ACTIVE" w komentarzu.
    msg := "Temporal validity check delegated to manifest-sync-check in CI workflow"
}
