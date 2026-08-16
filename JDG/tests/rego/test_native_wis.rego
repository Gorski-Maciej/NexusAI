# ═══════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: WIS (PROMPT 04)
# Source: rules/micro/vat/r03_vat_micro_articles.rego (art. 42a-42h VAT)
# Package: jdg.micro.vat.r03 (a42a..a42h)
# Rules tested: wniosek WIS, termin 3 mies., moc wiążąca 5 lat
# ═══════════════════════════════════════════════════════════════

package test_jdg_wis
import data.jdg.micro.vat.r03

# 1. jdg.micro.vat.a42a.r1 — definicja i zakres WIS (art. 42a ust. 1)
test_positive_a42a {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a42a_check": true, "business_type": "JDG"}
    }
    result.rule_id == "jdg.micro.vat.a42a.r1"
    result.matched == true
    result.wis.applicable == true
}

test_negative_a42a {
    result := data.jdg.micro.vat.r03.decide with input as {}
    result.rule_id != "jdg.micro.vat.a42a.r1"
}

# 2. jdg.micro.vat.a42b.r1 — przesłanki wniosku (art. 42b)
test_positive_a42b {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a42b_check": true},
        "invoice": {"cn_ambiguous": true}
    }
    result.rule_id == "jdg.micro.vat.a42b.r1"
    result.matched == true
}

# 3. jdg.micro.vat.a42g.r1 — termin wydania WIS (3 miesiące, art. 42g)
test_positive_a42g {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a42g_check": true}
    }
    result.rule_id == "jdg.micro.vat.a42g.r1"
    result.matched == true
    result.wis.applicable == true
}

# 4. jdg.micro.vat.a42h.r1 — moc wiążąca WIS (5 lat, art. 42h)
test_positive_a42h {
    result := data.jdg.micro.vat.r03.decide with input as {
        "jdg_entrepreneur": {"vat_a42h_check": true}
    }
    result.rule_id == "jdg.micro.vat.a42h.r1"
    result.matched == true
    result._legal_basis != ""
}
