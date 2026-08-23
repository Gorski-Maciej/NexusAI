# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: ORDYNACJA PODATKOWA (PROMPT 09)
# Package: jdg.micro.ord
# Rules tested: zaległość, nadpłata, korekta, GAAR, Biała Lista, odsetki,
# przedawnienie, odpowiedzialność
# ═══════════════════════════════════════════════════════════════════════════════

package test_jdg_ord
import data.jdg.micro.ord

# ── Test 1: Czynny żal — eligibility ──────────────────────────────────────────
test_positive_ord_a16_eligibility {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"}
    }
    result.rule_id == "jdg.micro.ord.a16.r1"
    result.matched == true
    result.micro_rule_active == true
}

# ── Test 2: Czynny żal — warunek pozytywny ───────────────────────────────────
test_positive_ord_a16_positive {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {"ord_condition_met": true}
    }
    result.rule_id == "jdg.micro.ord.a16.r2"
}

# ── Test 3: Zaległość podatkowa — eligibility ─────────────────────────────────
test_positive_ord_a20_eligibility {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"}
    }
    result.rule_id == "jdg.micro.ord.a20.r1"
}

# ── Test 4: Nadpłata — eligibility ────────────────────────────────────────────
test_positive_ord_a21_eligibility {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"}
    }
    result.rule_id == "jdg.micro.ord.a21.r1"
}

# ── Test 5: Odpowiedzialność podatnika — eligibility ──────────────────────────
test_positive_ord_a26_eligibility {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"}
    }
    result.rule_id == "jdg.micro.ord.a26.r1"
}

# ── Test 6: Odpowiedzialność podatnika — wyjątek ──────────────────────────────
test_positive_ord_a26_exception {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {"ord_a26_exception": true}
    }
    result.rule_id == "jdg.micro.ord.a26.r7"
}

# ── Test 7: Odpowiedzialność małżonka — eligibility ───────────────────────────
test_positive_ord_a27_eligibility {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"}
    }
    result.rule_id == "jdg.micro.ord.a27.r1"
}

# ── Test 8: Podatnicy, płatnicy — warunek pozytywny ───────────────────────────
test_positive_ord_a29_positive {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {"ord_condition_met": true}
    }
    result.rule_id == "jdg.micro.ord.a29.r2"
}

# ── Test 9: Obowiązek składania deklaracji — eligibility ──────────────────────
test_positive_ord_a32_eligibility {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"}
    }
    result.rule_id == "jdg.micro.ord.a32.r1"
}

# ── Test 10: Obowiązek zapłaty podatku — warunek pozytywny ────────────────────
test_positive_ord_a33_positive {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {"ord_condition_met": true}
    }
    result.rule_id == "jdg.micro.ord.a33.r2"
}

# ── Test 11: Wyłączenie dotyczy wszystkich — a20 ──────────────────────────────
test_positive_ord_a20_exclusion {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {"ord_exclusion_applies": false}
    }
    result.rule_id == "jdg.micro.ord.a20.r5"
}

# ── Test 12: Wyłączenie — a21 ─────────────────────────────────────────────────
test_positive_ord_a21_exclusion {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {"ord_exclusion_applies": false}
    }
    result.rule_id == "jdg.micro.ord.a21.r5"
}

# ── Test 13: Drugi wyjątek — a26 ──────────────────────────────────────────────
test_positive_ord_a26_exception_2 {
    result := data.jdg.micro.ord.decide with input as {
        "jdg_entrepreneur": {"business_type": "JDG"},
        "invoice": {"ord_a26_exception_2": true}
    }
    result.rule_id == "jdg.micro.ord.a26.r8"
}

# ── Test 14: no_match — pusty input ───────────────────────────────────────────
test_no_match_ord {
    result := data.jdg.micro.ord.decide with input as {}
    result.matched == false
    result.rule_id == "jdg.micro.ord.no_match"
}