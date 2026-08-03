# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R04 PIT AUDYT — testy rego (raport raporty_audyt_glm52/R04_PIT.txt)
# Uruchom: opa test JDG/rules JDG/tests/rego/test_pit_audyt_r04_enterprise.rego
# ═══════════════════════════════════════════════════════════════════════════════
# Pokrycie R04:
#  - P1: stuby { true } usunięte — brak fałszywego matched:true (checklist C03/C18)
#  - P1: kumulacja ulg T9 (IP Box + B+R + termo ≤ dochód) — nowe reguły C155/C156
#  - P1: ulga dla klasy średniej 2026 (zniesiona od 2023) — reguła temporalna P1625/P1626
#  - P2: termin zaliczek 20. dnia vs dni wolne — P559 przesunięcie terminu
#  - P2/T9: PIT-28 vs PIT-36L — wybór formy przez silnik
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.tests.pit_audyt_r04

import data.jdg.pit.cross_relief
import data.jdg.pit.donation_relief
import data.jdg.pit.family_estonian
import data.jdg.pit.ipbox
import data.jdg.pit.rd_relief
import data.jdg.pit.tax_loss_harvesting
import data.jdg.pit.thermo_relief
import data.jdg.pit.art21_exemptions
import data.jdg.temporal
import data.jdg.pit.advances

# ── P1: STUBY USUNIĘTE — brak fałszywego matched:true (C03/C18) ─────────────

test_r04_no_false_positive_cross_relief if {
    result := cross_relief.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

test_r04_no_false_positive_donation if {
    result := donation_relief.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

test_r04_no_false_positive_family_estonian if {
    result := family_estonian.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

test_r04_no_false_positive_ipbox if {
    result := ipbox.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

test_r04_no_false_positive_rd_relief if {
    result := rd_relief.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

test_r04_no_false_positive_tax_loss if {
    result := tax_loss_harvesting.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

test_r04_no_false_positive_thermo if {
    result := thermo_relief.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

test_r04_no_false_positive_art21 if {
    result := art21_exemptions.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

# ── P1: KUMULACJA ULG T9 — limit dochodu (C155/C156) ────────────────────────

test_r04_accumulation_exceeded if {
    result := cross_relief.decide with input as {
        "cross_relief_accumulation_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_taxable_income": 100000,
            "ip_box_qualifying_income": 60000,
            "rd_total_qualified_costs": 50000,
            "thermo_total_costs": 20000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.cross_relief.accumulation_limit"
    result.cross_relief_accumulation_exceeded == true
    result._routing == "BLOCK_AND_ALERT"
}

test_r04_accumulation_within_limit if {
    result := cross_relief.decide with input as {
        "cross_relief_accumulation_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_taxable_income": 200000,
            "ip_box_qualifying_income": 60000,
            "rd_total_qualified_costs": 50000,
            "thermo_total_costs": 20000
        }
    }
    result.matched == true
    result.rule_id == "jdg.pit.cross_relief.accumulation_ok"
    result.cross_relief_accumulation_exceeded == false
    result._routing == ""
}

test_r04_accumulation_exact_limit if {
    result := cross_relief.decide with input as {
        "cross_relief_accumulation_check": true,
        "jdg_entrepreneur": {
            "tax_form": "PIT_SCALE",
            "annual_taxable_income": 130000,
            "ip_box_qualifying_income": 60000,
            "rd_total_qualified_costs": 50000,
            "thermo_total_costs": 20000
        }
    }
    # 60 000 + 50 000 + 20 000 = 130 000 == dochód → OK (≤ dochód)
    result.rule_id == "jdg.pit.cross_relief.accumulation_ok"
    result.cross_relief_accumulation_exceeded == false
}

# ── P1: ULGA DLA KLASY ŚREDNIEJ 2026 (P1625/P1626) ──────────────────────────

test_r04_middle_class_relief_2026_inactive if {
    result := temporal.decide with input as {
        "temporal": {
            "middle_class_relief_check": true,
            "effective_date_year": 2026
        }
    }
    result.middle_class_relief_active == false
    result.middle_class_relief_year == 2026
}

test_r04_middle_class_relief_2022_active if {
    result := temporal.decide with input as {
        "temporal": {
            "middle_class_relief_check": true,
            "effective_date_year": 2022
        }
    }
    result.middle_class_relief_active == true
    result.middle_class_relief_year == 2022
}

test_r04_middle_class_relief_2023_inactive if {
    result := temporal.decide with input as {
        "temporal": {
            "middle_class_relief_check": true,
            "effective_date_year": 2023
        }
    }
    result.middle_class_relief_active == false
}

# ── P2: TERMIN ZALICZEK 20. DNIA VS DNI WOLNE (P559) ────────────────────────

test_r04_deadline_saturday_shift if {
    result := advances.decide with input as {
        "pit_advance_deadline_check": true,
        "pit_advance_deadline": {"due_weekday": 6, "due_is_public_holiday": false},
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.pit_advance_deadline_shifted == true
    result.pit_advance_shifted_due_day == 22
}

test_r04_deadline_sunday_shift if {
    result := advances.decide with input as {
        "pit_advance_deadline_check": true,
        "pit_advance_deadline": {"due_weekday": 7, "due_is_public_holiday": false},
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.pit_advance_deadline_shifted == true
    result.pit_advance_shifted_due_day == 21
}

test_r04_deadline_holiday_shift if {
    result := advances.decide with input as {
        "pit_advance_deadline_check": true,
        "pit_advance_deadline": {"due_weekday": 3, "due_is_public_holiday": true},
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.pit_advance_deadline_shifted == true
    result.pit_advance_shifted_due_day == 21
}

test_r04_deadline_no_shift_weekday if {
    result := advances.decide with input as {
        "pit_advance_deadline_check": true,
        "pit_advance_deadline": {"due_weekday": 3, "due_is_public_holiday": false},
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.matched == false
}

# ── P2/T9: PIT-28 vs PIT-36L — wybór formy przez silnik ─────────────────────

test_r04_pit28_for_lump_sum if {
    result := advances.decide with input as {
        "jdg_entrepreneur": {"tax_form": "LUMP_SUM"}
    }
    result.pit_annual_return_type == "PIT-28"
    result.pit_annual_return_deadline == "02-28"
}

test_r04_pit36l_for_linear if {
    result := advances.decide with input as {
        "jdg_entrepreneur": {"tax_form": "LINEAR"}
    }
    result.pit_annual_return_type == "PIT-36L"
    result.pit_annual_return_deadline == "04-30"
}

test_r04_pit36_for_scale if {
    result := advances.decide with input as {
        "jdg_entrepreneur": {"tax_form": "PIT_SCALE"}
    }
    result.pit_annual_return_type == "PIT-36"
    result.pit_annual_return_deadline == "04-30"
}
