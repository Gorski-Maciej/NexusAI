# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Enterprise — Innovation 9.3: Tax Ruling Auto-Drafter
# v7.0 — BP-3: Auto-generation of ORD-IN, WIS-W, WIT requests
# Package: jdg.enterprise.tax_ruling_autodraft
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.enterprise.tax_ruling_autodraft

import data.jdg.helpers

# ─────────────────────────────────────────────────────────────────────────────
# TRA-2600: Ruling Type Selector — wybiera typ wniosku
# ─────────────────────────────────────────────────────────────────────────────
tra_select_ruling_type(input) = ruling_type {
    inquiry_scope := object.get(input, "scope", "GENERAL")
    types := {
        "VAT": "WIS-W",       # Wiążąca Informacja Stawkowa
        "CUSTOMS": "WIT",     # Wiążąca Informacja Taryfowa
        "EXCISE": "WIA",      # Wiążąca Informacja Akcyzowa
        "GENERAL": "ORD-IN",  # Interpretacja indywidualna (art. 14b OrdPU)
        "PIT": "ORD-IN",
        "CIT": "ORD-IN",
    }
    ruling_type := types[inquiry_scope]
} else := "ORD-IN"

# ─────────────────────────────────────────────────────────────────────────────
# TRA-2610: ORD-IN Auto-Drafter — szkic wniosku o interpretację indywidualną
# ─────────────────────────────────────────────────────────────────────────────
tra_draft_ord_in(input) = draft {
    taxpayer_nip := object.get(input, "nip", "BRAK")
    taxpayer_name := object.get(input, "name", "BRAK")
    question_scope := object.get(input, "scope_description", "")
    legal_articles := object.get(input, "articles", [])
    fee_pln := 40   # Opłata za interpretację indywidualną 2026

    # Generowanie treści
    articles_list := concat(", ", [sprintf("art. %s", [a]) | a := legal_articles[_]])

    draft := {
        "form_type": "ORD-IN",
        "recipient": "Dyrektor Krajowej Informacji Skarbowej",
        "taxpayer": {"nip": taxpayer_nip, "name": taxpayer_name},
        "fee_pln": fee_pln,
        "sections": {
            "A": {"label": "Dane wnioskodawcy", "content": sprintf("NIP: %s, Nazwa: %s", [taxpayer_nip, taxpayer_name])},
            "B": {"label": "Przedmiot wniosku", "content": question_scope},
            "C": {"label": "Stan faktyczny / zdarzenie przyszłe", "content": object.get(input, "facts", "[DO UZUPEŁNIENIA]")},
            "D": {"label": "Własne stanowisko", "content": object.get(input, "taxpayer_position", "[DO UZUPEŁNIENIA]")},
            "E": {"label": "Przepisy prawa podatkowego", "content": sprintf("Artykuły: %s", [articles_list])},
        },
        "legal_basis": "Art. 14b § 1 Ordynacji Podatkowej",
        "deadline_ks": "3 miesiące (art. 14d OrdPU)",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# TRA-2620: WIS-W Auto-Drafter — wniosek o Wiążącą Informację Stawkową
# ─────────────────────────────────────────────────────────────────────────────
tra_draft_wis_w(input) = draft {
    product_description := object.get(input, "product_description", "")
    cn_code := object.get(input, "cn_code", "")
    suggested_vat := object.get(input, "suggested_vat_rate", "")

    draft := {
        "form_type": "WIS-W",
        "recipient": "Dyrektor Krajowej Informacji Skarbowej",
        "product": {
            "description": product_description,
            "cn_code": cn_code,
            "suggested_vat": suggested_vat,
        },
        "fee_pln": 40,
        "legal_basis": "Art. 42b ust. 4 ustawy o VAT",
        "deadline_ks": "3 miesiące",
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# TRA-2630: Ruling Fee Calculator
# ─────────────────────────────────────────────────────────────────────────────
tra_fee_calculator(ruling_type, extra_events) = fee {
    base_fees := {"ORD-IN": 40, "WIS-W": 40, "WIT": 0, "WIA": 0}
    extra_fee := 40 * count(extra_events)  # 40 PLN per dodatkowe zdarzenie
    fee := object.get(base_fees, ruling_type, 40) + extra_fee
}

# ─────────────────────────────────────────────────────────────────────────────
# TRA-2640: Ruling eligibility checker
# ─────────────────────────────────────────────────────────────────────────────
tra_eligibility_check(input) = eligibility {
    has_active_control := object.get(input, "active_tax_control", false)
    has_active_proceeding := object.get(input, "active_tax_proceeding", false)
    same_matter := object.get(input, "same_matter_pending", false)

    blocked := has_active_control or has_active_proceeding or same_matter

    eligibility := {
        "eligible": false,
        "blockers": {
            "active_control": has_active_control,
            "active_proceeding": has_active_proceeding,
            "same_matter_pending": same_matter,
        },
        "routing": "BLOCK",
        "routing_reason": "Art. 14b § 5 OrdPU: interpretacja niedopuszczalna gdy toczy się kontrola/postępowanie w tej samej sprawie",
    } { blocked }

    eligibility := {
        "eligible": true,
        "blockers": {},
        "routing": "ALLOW",
        "routing_reason": "Brak przeszkód do złożenia wniosku o interpretację",
    } { not blocked }
}

# ─────────────────────────────────────────────────────────────────────────────
# TRA-2650: Ruling Protective Effect (art. 14e) — ochrona podatnika
# ─────────────────────────────────────────────────────────────────────────────
tra_protective_effect(input) = protection {
    ruling_issued := object.get(input, "ruling_issued", false)
    ruling_favorable := object.get(input, "ruling_favorable", false)
    applied_consistently := object.get(input, "applied_consistently", false)
    is_jdg := object.get(input, "business_type", "") == "JDG"

    protection := {
        "protected": true,
        "scope": "Art. 14k-14m OrdPU: ochrona przed odpowiedzialnością karną-skarbową",
        "condition": "Zastosowanie się do interpretacji indywidualnej",
    } { ruling_issued; ruling_favorable; applied_consistently; is_jdg }

    protection := {
        "protected": false,
        "reason": "Interpretacja nie wydana lub niekorzystna lub nie zastosowano się",
    } { not ruling_issued or not ruling_favorable or not applied_consistently }
}

# ─────────────────────────────────────────────────────────────────────────────
# TRA-2660: Build ruling warnings
# ─────────────────────────────────────────────────────────────────────────────
build_tra_warnings(eligibility, draft, fee, protection) = warnings {
    is_eligible := object.get(eligibility, "eligible", false)
    ruling_type := object.get(draft, "form_type", "ORD-IN")
    fee_amount := fee

    base := [sprintf("📋 TAX RULING AUTO-DRAFTER — %s", [ruling_type])]

    elig_warn := array.concat(base, [
        "   🚫 NIEDOPUSZCZALNE: aktywna kontrola/postępowanie w tej samej sprawie!",
        sprintf("   Podstawa: %s", [object.get(eligibility, "routing_reason", "")]),
    ]) { not is_eligible }

    elig_warn := array.concat(base, [
        sprintf("   ✅ Wniosek dopuszczalny. Opłata: %d PLN", [fee_amount]),
    ]) { is_eligible }

    base2 := elig_warn

    prot_warn := array.concat(base2, [
        "   🛡️ Ochrona art. 14k-14m OrdPU: ZASTOSOWANIE SIĘ DO INTERPRETACJI = BRAK ODPOWIEDZIALNOŚCI KKS",
    ]) { object.get(protection, "protected", false) }

    prot_warn := base2 { not object.get(protection, "protected", false) }

    warnings := prot_warn
}
