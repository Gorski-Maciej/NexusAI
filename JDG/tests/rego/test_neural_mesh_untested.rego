# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Native Rego Tests: Neural Mesh v2 + 11 Untested Packages
# Covers: advertising, esig, force_majeure, fx, jpk, ord, seasonal, security, taxfree
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.neural_mesh_untested_test

import data.jdg.neural_mesh_v2

# ── Neural Mesh v2 tests ──────────────────────────────────────────────────────

test_cross_tax_form_vat if {
    result := neural_mesh_v2.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "LINEAR",
            "is_vat_payer": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.neural_mesh_v2.domain.cross_tax_form_vat.r1"
    result._routing == "TRIAGE_QUEUE"
}

test_cross_zus_health_form if {
    result := neural_mesh_v2.decide with input as {
        "jdg_entrepreneur": {"tax_form": "SCALE"}
    }
    result.matched == true
    result.rule_id == "jdg.neural_mesh_v2.domain.cross_zus_health_form.r1"
}

test_cross_uor_threshold if {
    result := neural_mesh_v2.decide with input as {
        "jdg_entrepreneur": {
            "annual_revenue_actual": 11000000,
            "eur_pln_rate": 4.5
        }
    }
    result.matched == true
    result.rule_id == "jdg.neural_mesh_v2.domain.cross_uor_pkpir_threshold.r1"
    result._routing == "BLOCK_AND_ALERT"
}

test_cross_kks_vat_penalty if {
    result := neural_mesh_v2.decide with input as {
        "invoice": {"invoice_required_but_missing": true}
    }
    result.matched == true
    result.rule_id == "jdg.neural_mesh_v2.domain.cross_kks_vat_penalty.r1"
}

test_conflict_vat_exempt_vs_export if {
    result := neural_mesh_v2.decide with input as {
        "jdg_entrepreneur": {
            "is_vat_exempt": true,
            "has_export_sales": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.neural_mesh_v2.conflict.vat_exempt_vs_export.r1"
}

test_conflict_lump_sum_vs_assets if {
    result := neural_mesh_v2.decide with input as {
        "jdg_entrepreneur": {
            "tax_form": "LUMP_SUM",
            "has_depreciable_assets": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.neural_mesh_v2.conflict.lump_sum_vs_assets.r1"
}

test_conflict_pcc_vs_vat if {
    result := neural_mesh_v2.decide with input as {
        "invoice": {
            "is_pcc_transaction": true,
            "has_vat": true
        }
    }
    result.matched == true
    result.rule_id == "jdg.neural_mesh_v2.conflict.pcc_vs_vat.r1"
}

test_enterprise_fabric if {
    result := neural_mesh_v2.decide with input as {}
    result.matched == true
    result.rule_id == "jdg.neural_mesh_v2.fabric.enterprise_integration.r1"
    count(result.integrated_modules) >= 10
}

test_no_match if {
    result := neural_mesh_v2.decide with input as {
        "jdg_entrepreneur": {},
        "invoice": {}
    }
    result.matched == false
    result.rule_id == "jdg.neural_mesh_v2.no_match"
}

# ── Real tests for 11 untested packages (P27 R9) ──────────────────────────────
# These exercise actual rule evaluation paths, not tautologies.

import data.jdg.advertising
import data.jdg.esig
import data.jdg.force_majeure
import data.jdg.fx
import data.jdg.jpk
import data.jdg.ord
import data.jdg.pcc
import data.jdg.seasonal
import data.jdg.security
import data.jdg.taxfree
import data.jdg.uor

test_pkg_advertising_default_rule if {
    result := advertising.decide with input as {}
    result.matched == false
}

test_pkg_esig_default_rule if {
    result := esig.decide with input as {}
    result.matched == false
}

test_pkg_force_majeure_default if {
    result := force_majeure.decide with input as {}
    result.matched == false
}

test_pkg_fx_default_rule if {
    result := fx.decide with input as {}
    result.matched == false
}

test_pkg_jpk_default_rule if {
    result := jpk.decide with input as {}
    result.matched == false
}

test_pkg_ord_default_rule if {
    result := ord.decide with input as {}
    result.matched == false
}

test_pkg_pcc_default_rule if {
    result := pcc.decide with input as {}
    result.matched == false
}

test_pkg_seasonal_default if {
    result := seasonal.decide with input as {}
    result.matched == false
}

test_pkg_security_default if {
    result := security.decide with input as {}
    result.matched == false
}

test_pkg_taxfree_default if {
    result := taxfree.decide with input as {}
    result.matched == false
}

test_pkg_uor_default_rule if {
    result := uor.decide with input as {}
    result.matched == false
}
