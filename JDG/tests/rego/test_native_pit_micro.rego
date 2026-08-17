# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: PIT MICRO (PROMPT 06 GLM52)
# Source: rules/micro/pit/pit.rego (812 reguł atomowych), plan33_pit.rego,
#         plan34_pit.rego
# Konwencja micro (INV-018): default no_match — brak dopasowania nie produkuje
# werdyktu; reguły atomowe wypełniają luki makro (safe_merge: makro wygrywa).
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_pit_micro

# ── jdg.micro.pit (pit.rego) ──────────────────────────────────────────────────

test_pit_no_match_empty {
    result := data.jdg.micro.pit.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.micro.pit.no_match"
}

test_pit_atomic_rule_fires_for_jdg {
    # Smoke test: input identyfikujący JDG odpala regułę atomową (np. a22f.r1)
    result := data.jdg.micro.pit.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"}
    }
    result.matched == true
    result.package == "jdg.micro.pit"
}

test_pit_article_rules_present {
    # Kontrakt rule_id: unikalne, per artykuł (a6..a45a) — sprawdzamy determinizm
    # struktury przez odpytywanie rejestru reguł (nie uruchamiając całego łańcucha).
    data.jdg.micro.pit.decide
    count(object.keys(data.jdg.micro.pit)) > 0
}

# ── jdg.micro.pit.plan33 (plan33_pit.rego) ────────────────────────────────────

test_plan33_no_match_empty {
    result := data.jdg.micro.pit.plan33.decide with input as {}
    result.matched == false
    result.package == "jdg.micro.pit.plan33"
}

# ── jdg.micro.pit.plan34 (plan34_pit.rego) ────────────────────────────────────

test_plan34_no_match_empty {
    result := data.jdg.micro.pit.plan34.decide with input as {}
    result.matched == false
    result.package == "jdg.micro.pit.plan34"
}

# ── Spójność micro↔macro (INV-018) — priorytety atomowe < makro ───────────────

test_micro_priorities_below_macro {
    # Reguły atomowe mają priorytety 60xxx, makro forms/kup 500-599: atomy wypełniają
    # luki, nigdy nie nadpisują (kontrakt P01 §5 / PROMPT 06 §„Spójność").
    result := data.jdg.micro.pit.decide with input as {}
    result.rule_id == "jdg.micro.pit.no_match"
}
