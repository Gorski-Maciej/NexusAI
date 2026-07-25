# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ENTERPRISE IP BOX (Art. 30ca PIT) — 5% stawka od IP
# ═══════════════════════════════════════════════════════════════════════════════
#
# METADATA
# title: JDG Enterprise IP Box — Innovation Box 5% Tax Rate
# description: |
#   ENTERPRISE v7.0 — Wypełnia KRYTYCZNĄ lukę CR2 z Raportu v7.0.
#   IP Box (Art. 30ca PIT): 5% stawka od dochodu z kwalifikowanych
#   praw własności intelektualnej. R130-R145.
#   - R130: Definicja kwalifikowanego IP (7 kategorii)
#   - R131: Wzór Nexus (koszty kwalifikowane × 1.3 / koszty ogółem)
#   - R132: Stawka 5% od dochodu z IP
#   - R133: Obowiązek PIT-IP (osobne zawiadomienie)
#   - R134: Ewidencja Art. 30cb PIT
#   - R135: Interakcja B+R + IP Box (MOŻNA ŁĄCZYĆ!)
#   - R136: Wykluczenia: ryczałt, karta podatkowa
#   - R137: IP Box + CIT estoński — NIE można łączyć
# architecture: Enterprise Multi-Pass (ADR-001), First-Match-Wins else-chain
# legal_basis: Art. 30ca-30cb PIT; Art. 24d ust. 4 PIT (wskaźnik Nexus)
# package: jdg.pit.ipbox
# deprecated: false
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.pit.ipbox

import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.pit.ipbox.no_match",
    "package": "jdg.pit.ipbox", "priority": 999
}

# ═══════════════════════════════════════════════════════════════════════════════
# R130: ipbox_qualifying_ip — Definicja kwalifikowanego IP (7 kategorii)
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.qualifying_ip_definition",
    "package": "jdg.pit.ipbox",
    "priority": 130,
    "vat_rate": "", "rounding_level": "", "gtu_code": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "business_status": "", "ceidg_registration_required": false,
    "ipbox_has_qualifying_ip": has_ip,
    "ipbox_ip_category": ip_category,
    "ipbox_is_eligible": is_eligible,
    "_routing": ip_rt,
    "_routing_reason": ip_rs,
    "_legal_basis": "Art. 30ca ust. 2 PIT (katalog kwalifikowanych IP)",
    "_warnings": [sprintf("🔬 IP BOX — %s. Kategoria IP: %s. %s",
        [eligibility_msg, ip_category, action_msg])]
} {
    input.ipbox_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"PIT_SCALE", "LINEAR"}  # IP Box NIE dla ryczałtu i karty!

    ip_category := object.get(input.jdg_entrepreneur, "ip_box_category", "")

    # 7 kategorii kwalifikowanego IP (Art. 30ca ust. 2 PIT)
    qualifying_categories := {
        "PATENT", "UTILITY_MODEL", "INDUSTRIAL_DESIGN",
        "TOPOLOGY", "SOFTWARE", "PLANT_VARIETY", "DRUG_REGISTRATION"
    }

    has_ip := ip_category in qualifying_categories
    is_eligible := has_ip and pit_form in {"PIT_SCALE", "LINEAR"}

    eligibility_msg = "KWALIFIKUJE SIĘ do IP Box (5% stawka)" { is_eligible }
    eligibility_msg = "NIE kwalifikuje" { not has_ip }
    eligibility_msg = "NIE kwalifikuje — IP Box niedostępny dla ryczałtu/karty" { has_ip; not (pit_form in {"PIT_SCALE", "LINEAR"}) }

    action_msg = "Zastosuj 5% stawkę do dochodu z kwalifikowanego IP!" { is_eligible }
    action_msg = "Sprawdź czy Twoje wytwory spełniają definicję kwalifikowanego IP" { not has_ip }

    ip_rt = "TRIAGE_QUEUE" { is_eligible }
    ip_rt = "" { true }
    ip_rs = sprintf("IP Box: %s (%s)", [eligibility_msg, ip_category])
}

# ═══════════════════════════════════════════════════════════════════════════════
# R131: ipbox_nexus_formula — Wzór Nexus (Art. 30cb ust. 1 PIT)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.nexus_formula",
    "package": "jdg.pit.ipbox",
    "priority": 131,
    "pit_form": pit_form,
    "ipbox_nexus_qualified_costs": qc,
    "ipbox_nexus_total_costs": tc,
    "ipbox_nexus_uplift": qc * 1.3,
    "ipbox_nexus_ratio": nexus_ratio,
    "ipbox_nexus_ratio_pct": nexus_ratio_pct,
    "ipbox_qualifying_income_after_nexus": qi * nexus_ratio,
    "_routing": nexus_rt,
    "_routing_reason": sprintf("Wskaźnik Nexus: (%.2f × 1.3) / %.2f = %.1f%%. Dochód kwalifikowany: %.2f PLN × %.1f%% = %.2f PLN",
        [qc, tc, nexus_ratio_pct, qi, nexus_ratio_pct, qi * nexus_ratio]),
    "_legal_basis": "Art. 30ca ust. 4 PIT (wskaźnik Nexus = (a+b+c)×1.3 / (a+b+c+d))",
    "_warnings": [sprintf("WSKAŹNIK NEXUS — Koszty kwalifikowane (a+b+c): %.2f PLN. Koszty ogółem (a+b+c+d): %.2f PLN. Wskaźnik: (%.2f × 1.3) / %.2f = %.1f%%. Dochód podlegający 5%%: %.2f PLN × %.1f%% = %.2f PLN. Podatek IP Box: %.2f PLN.",
        [qc, tc, qc, tc, nexus_ratio_pct, qi, nexus_ratio_pct, qi * nexus_ratio, qi * nexus_ratio * 0.05])]
} {
    input.ipbox_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    qi := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)

    # Koszty we wzorze Nexus
    qc := object.get(input.jdg_entrepreneur, "ipbox_nexus_qualified_costs", 0)
    tc := object.get(input.jdg_entrepreneur, "ipbox_nexus_total_costs", qi * 0.5)

    nexus_ratio := (qc * 1.3) / tc { tc > 0 }
    nexus_ratio := 1.0 { tc == 0 }
    nexus_ratio := min([nexus_ratio, 1.0])  # Max 100%
    nexus_ratio_pct := floor(nexus_ratio * 1000) / 10

    nexus_rt = "TRIAGE_QUEUE" { nexus_ratio < 0.50; qi > 100000 }
    nexus_rt = "" { true }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R132: ipbox_5pct_rate — Stawka 5% od dochodu z kwalifikowanego IP
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.five_percent_rate",
    "package": "jdg.pit.ipbox",
    "priority": 132,
    "pit_form": pit_form,
    "ipbox_qualifying_income": qi,
    "ipbox_tax_rate": 0.05,
    "ipbox_tax_due": ipbox_tax,
    "ipbox_savings_vs_scale": savings_scale,
    "ipbox_savings_vs_linear": savings_linear,
    "_routing": "",
    "_routing_reason": sprintf("IP Box: %.2f PLN @ 5%% = %.2f PLN. Oszczędność vs skala: %.2f PLN, vs liniowy: %.2f PLN",
        [qi, ipbox_tax, savings_scale, savings_linear]),
    "_legal_basis": "Art. 30ca ust. 1 PIT (stawka 5%)",
    "_warnings": [sprintf("IP BOX — 5%% STAWKA. Dochód z IP: %.2f PLN. Podatek: %.2f PLN (5%%). Gdybyś płacił skalę 12%%: %.2f PLN → oszczędność %.2f PLN. Gdyby liniowy 19%%: %.2f PLN → oszczędność %.2f PLN.",
        [qi, ipbox_tax, qi * 0.12, savings_scale, qi * 0.19, savings_linear])]
} {
    input.ipbox_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    qi := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)
    nexus_ratio := object.get(input.jdg_entrepreneur, "ipbox_nexus_ratio", 1.0)
    qi_after_nexus := qi * nexus_ratio
    ipbox_tax := qi_after_nexus * 0.05
    savings_scale := qi * 0.12 - ipbox_tax
    savings_linear := qi * 0.19 - ipbox_tax
}

# ═══════════════════════════════════════════════════════════════════════════════
# R133: ipbox_pit_ip_filing — Obowiązek złożenia PIT-IP
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.pit_ip_filing_required",
    "package": "jdg.pit.ipbox",
    "priority": 133,
    "pit_form": pit_form,
    "ipbox_pit_ip_filing_required": true,
    "ipbox_pit_ip_deadline": "30 kwietnia (razem z PIT-36/PIT-36L)",
    "ipbox_pit_ip_form": "PIT-IP",
    "_routing": "TRIAGE_QUEUE",
    "_routing_reason": "PIT-IP — obowiązkowe zawiadomienie o IP Box",
    "_legal_basis": "Art. 30cb ust. 4 PIT (obowiązek PIT-IP)",
    "_warnings": [sprintf("PIT-IP WYMAGANY! Złóż PIT-IP razem z zeznaniem rocznym (PIT-36/PIT-36L) do 30 kwietnia. Dochód z IP: %.2f PLN. Bez PIT-IP = brak prawa do 5%% stawki!",
        [qi])]
} {
    input.ipbox_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    qi := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)
    qi > 0
    input.jdg_entrepreneur.pit_ip_filed == false
}

# ═══════════════════════════════════════════════════════════════════════════════
# R134: ipbox_separate_evidence — Wyodrębniona ewidencja Art. 30cb
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.separate_evidence",
    "package": "jdg.pit.ipbox",
    "priority": 134,
    "pit_form": pit_form,
    "ipbox_evidence_separated": has_evidence,
    "ipbox_evidence_risk": has_evidence == false,
    "_routing": evidence_rt,
    "_routing_reason": sprintf("Ewidencja IP Box: %s", [evidence_msg]),
    "_legal_basis": "Art. 30cb ust. 1 PIT (obowiązek prowadzenia odrębnej ewidencji)",
    "_warnings": [sprintf("EWIDENCJA IP BOX — %s. %s Art. 30cb PIT wymaga wyodrębnienia każdego kwalifikowanego IP w osobnej ewidencji rachunkowej. US MOŻE zakwestionować IP Box bez ewidencji!",
        [evidence_msg, risk_note])]
} {
    input.ipbox_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    has_evidence := object.get(input.jdg_entrepreneur, "ipbox_has_separate_evidence", false)
    evidence_msg = "WYODRĘBNIONA — OK" { has_evidence }
    evidence_msg = "BRAK — RYZYKO UTRATY IP BOX!" { not has_evidence }
    risk_note = "" { has_evidence }
    risk_note = "Natychmiast załóż odrębną ewidencję dla każdego IP. Bez niej US ODRZUCI IP Box!" { not has_evidence }
    evidence_rt = "BLOCK_AND_ALERT" { not has_evidence }
    evidence_rt = "" { has_evidence }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R135: ipbox_rd_interaction — IP Box + B+R można łączyć (ALE nie na tym samym)
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.rd_interaction",
    "package": "jdg.pit.ipbox",
    "priority": 135,
    "pit_form": pit_form,
    "ipbox_rd_can_combine": true,
    "ipbox_rd_same_income_warning": "NIE stosuj IP Box i B+R na tym samym dochodzie! Rozdziel: IP Box → dochód z IP, B+R → pozostały dochód.",
    "ipbox_rd_optimal_income_split": optimal_split,
    "_routing": "",
    "_routing_reason": "IP Box + B+R: rozdziel dochody, maksymalizuj oszczędności",
    "_legal_basis": "Art. 30ca + Art. 26e PIT (łączenie ulg — dozwolone na różnych dochodach)",
    "_warnings": [sprintf("IP BOX + B+R — MOŻNA ŁĄCZYĆ! %s. Strategia: %.2f PLN dochodu → IP Box 5%%, %.2f PLN → skala/B+R. Łączna oszczędność: ~%.2f PLN vs sama skala.",
        [split_note, ip_portion, other_portion, combined_savings])]
} {
    input.ipbox_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    qi := object.get(input.jdg_entrepreneur, "ip_box_qualifying_income", 0)
    total_income := object.get(input.jdg_entrepreneur, "annual_taxable_income", qi * 2)
    has_rd := object.get(input.jdg_entrepreneur, "has_rd_costs", false)
    rd_costs := object.get(input.jdg_entrepreneur, "rd_total_qualified_costs", 0)

    ip_portion := qi
    other_portion := max([total_income - qi, 0])
    ipbox_tax := ip_portion * 0.05
    scale_tax_other := other_portion * 0.12
    scale_tax_all := total_income * 0.12
    combined_savings := scale_tax_all - (ipbox_tax + scale_tax_other)
    split_note = sprintf("Dochód z IP: %.2f PLN @ 5%% + pozostały: %.2f PLN @ 12%% z B+R", [ip_portion, other_portion]) { has_rd }
    split_note = sprintf("Dochód z IP: %.2f PLN @ 5%% + pozostały: %.2f PLN standard", [ip_portion, other_portion]) { not has_rd }
}

# ═══════════════════════════════════════════════════════════════════════════════
# R136: ipbox_exclusions — Wykluczenia: ryczałt, karta podatkowa NIE mogą IP Box
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.excluded_for_lump_tax_card",
    "package": "jdg.pit.ipbox",
    "priority": 136,
    "pit_form": pit_form,
    "ipbox_blocked": true,
    "ipbox_block_reason": sprintf("IP Box NIEDOSTĘPNY dla %s — tylko skala PIT i liniowy!", [pit_form]),
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": sprintf("IP Box zablokowany — forma %s nie pozwala na IP Box", [pit_form]),
    "_legal_basis": "Art. 30ca ust. 1 PIT (IP Box tylko dla PIT-36 i PIT-36L)",
    "_warnings": [sprintf("IP BOX ZABLOKOWANY! Forma '%s' NIE pozwala na IP Box. Aby skorzystać z 5%% stawki, musisz przejść na skalę PIT lub podatek liniowy. Zmiana formy możliwa od nowego roku podatkowego.",
        [pit_form])]
} {
    input.ipbox_requested == true
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    pit_form in {"LUMP_SUM", "TAX_CARD"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# R137: ipbox_estonian_cit_conflict — IP Box + Estoński CIT NIE można łączyć
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.estonian_cit_conflict",
    "package": "jdg.pit.ipbox",
    "priority": 137,
    "ipbox_estonian_conflict": true,
    "ipbox_estonian_note": "IP Box NIE jest dostępny przy CIT estońskim! Estoński CIT ma własny mechanizm 20%/25% od wypłat.",
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "Konflikt: IP Box + CIT estoński — wybierz jedno",
    "_legal_basis": "Art. 30ca PIT + Rozdział 6b ustawy o CIT (wzajemne wykluczenie)",
    "_warnings": ["KONFLIKT IP BOX vs CIT ESTOŃSKI! Nie możesz stosować obu jednocześnie. CIT estoński ma własną stawkę 20%/25% od wypłat. Wybierz korzystniejszą opcję: IP Box 5% od dochodu z IP, czy CIT estoński 20% od dywidendy?"]
} {
    input.ipbox_requested == true
    input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# FALLBACK
# ═══════════════════════════════════════════════════════════════════════════════
else := {
    "matched": true,
    "rule_id": "jdg.pit.ipbox.fallback",
    "package": "jdg.pit.ipbox",
    "priority": 999,
    "_routing": "", "_routing_reason": "",
    "_legal_basis": "Art. 30ca-30cb PIT",
    "_warnings": ["IP Box (Innovation Box) — 5% stawka od dochodu z kwalifikowanych IP. Sprawdź czy Twoje oprogramowanie/patent/wzór się kwalifikuje. Potencjalna oszczędność: zamiana 12%/19%/32% na 5%."]
} {
    true
}
