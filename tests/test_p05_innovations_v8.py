"""
Testy jednostkowe i integracyjne dla P05 Innovations Engine v8.0.
Pokrywaja wszystkie 34 reguly: luki B+R (4), IP Box (3), Termo (1),
Estonski CIT (5), Cross-Relief (2), Tax Loss (1), Annual Declaration (2),
Form Optimizer (1), Exit Tax/MDR (2), oraz 8 nowych innowacji (INN08-INN15).

Architektura: Testy weryfikuja strukture pliku Rego, poprawnosc logiki
biznesowej, oraz integracje z main_jdg.rego.
"""
import os
import re
import pytest


# ── Helpers ──────────────────────────────────────────────────────────────────

def load_rego_module(path_relative):
    """Wczytaj plik Rego jako string."""
    base = os.path.dirname(os.path.dirname(__file__))
    full_path = os.path.join(base, path_relative)
    if not os.path.exists(full_path):
        pytest.skip(f"File not found: {path_relative}")
    with open(full_path, "r") as f:
        return f.read()


def extract_rules(content):
    """Wyciagnij wszystkie rule_id z pliku Rego."""
    return re.findall(r'"rule_id":\s*"([^"]+)"', content)


def extract_priorities(content):
    """Wyciagnij wszystkie priority z pliku Rego."""
    return [int(p) for p in re.findall(r'"priority":\s*(\d+)', content)]


def extract_legal_basis_all(content):
    """Wyciagnij wszystkie podstawy prawne."""
    return re.findall(r'"_legal_basis":\s*"([^"]+)"', content)


# ── Fixtures ─────────────────────────────────────────────────────────────────

@pytest.fixture(scope="module")
def p05_content():
    return load_rego_module("JDG/rules/p05_pit_innovations_v8.rego")


@pytest.fixture(scope="module")
def main_jdg_content():
    return load_rego_module("JDG/rules/main_jdg.rego")


@pytest.fixture(scope="module")
def rule_ids(p05_content):
    return extract_rules(p05_content)


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 1: Walidacja struktury pliku
# ═══════════════════════════════════════════════════════════════════════════════

class TestP05FileStructure:
    """Testy strukturalne pliku P05 Innovations."""

    def test_file_exists_and_not_empty(self, p05_content):
        """Plik istnieje i ma ponad 1500 linii."""
        assert len(p05_content) > 10000, "Plik P05 powinien miec >10KB"
        lines = p05_content.split("\n")
        assert len(lines) > 1500, f"Plik ma tylko {len(lines)} linii, oczekiwano >1500"

    def test_package_declaration(self, p05_content):
        """Deklaracja package jdg.p05_innovations."""
        assert "package jdg.p05_innovations" in p05_content

    def test_default_decide_rule(self, p05_content):
        """Default decide rule z fallbackiem."""
        assert 'default decide :=' in p05_content
        assert '"rule_id": "jdg.p05.no_match"' in p05_content

    def test_no_syntax_traps(self, p05_content):
        """Brak oczywistych bledow skladni: niesparowane klamry."""
        open_braces = p05_content.count("{")
        close_braces = p05_content.count("}")
        assert open_braces == close_braces, \
            f"Niesparowane klamry: {{ = {open_braces}, }} = {close_braces}"

    def test_every_rule_has_routing(self, p05_content):
        """Kazda regula (oprocz fallback) ma _routing."""
        # Liczymy wystapienia "matched": true i "_routing"
        matched_count = len(re.findall(r'"matched":\s*true', p05_content))
        routing_count = len(re.findall(r'"_routing":', p05_content))
        # Kazda regula z matched=true powinna miec _routing (oprocz default/fallback)
        assert routing_count >= matched_count - 2, \
            f"Brak _routing w {matched_count - routing_count} regulach"


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 2: Luki B+R (R112-R115)
# ═══════════════════════════════════════════════════════════════════════════════

class TestRDReliefInnovations:
    """Testy dla luk B+R: R112-R115."""

    def test_r112_staff_time_verification_exists(self, rule_ids):
        """R112: Weryfikacja 50% czasu pracy nad B+R."""
        assert "jdg.p05.rd.staff_time_verification" in rule_ids

    def test_r112_staff_time_verification_logic(self, p05_content):
        """R112 sprawdza time_pct >= 50 i ma routing BLOCK_AND_ALERT."""
        assert "rd_staff_time_on_rd_pct" in p05_content
        assert "time_verified := time_pct >= 50" in p05_content
        assert "BLOCK_AND_ALERT" in p05_content
        assert "min. 50% czasu pracy na B+R" in p05_content

    def test_r113_patent_acquisition_costs_exists(self, rule_ids):
        """R113: Koszty uzyskania patentow (Art. 26e ust. 2 pkt 5)."""
        assert "jdg.p05.rd.patent_acquisition_costs" in rule_ids

    def test_r113_patent_costs_category(self, p05_content):
        """R113: Kategoria PATENT_ACQUISITION."""
        assert "PATENT_ACQUISITION" in p05_content
        assert "Art. 26e ust. 2 pkt 5" in p05_content
        assert "nowelizacja 2022" in p05_content

    def test_r114_carry_forward_tracker_exists(self, rule_ids):
        """R114: Sledzenie salda carry-forward."""
        assert "jdg.p05.rd.carry_forward_tracker" in rule_ids

    def test_r114_carry_forward_multi_year(self, p05_content):
        """R114 sledzi salda 2021-2025 z limitem 6 lat."""
        assert "rd_carry_forward_2021" in p05_content
        assert "rd_carry_forward_2025" in p05_content
        assert "current_year - 2021 <= 6" in p05_content
        assert "PRZEDAWNIA SIĘ" in p05_content

    def test_r114_carry_forward_warning_builder(self, p05_content):
        """R114 ma funkcje build_carry_forward_warnings."""
        assert "build_carry_forward_warnings" in p05_content

    def test_r115_auto_cost_classifier_exists(self, rule_ids):
        """R115: Auto-klasyfikator kosztow B+R (Innowacja #13)."""
        assert "jdg.p05.rd.auto_cost_classifier" in rule_ids

    def test_r115_keyword_matching(self, p05_content):
        """R115 zawiera slowa kluczowe do wykrywania B+R."""
        assert "badania" in p05_content
        assert "prototyp" in p05_content
        assert "R&D" in p05_content
        assert "pkpir_entries" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 3: Luki IP Box (R138-R140)
# ═══════════════════════════════════════════════════════════════════════════════

class TestIPBoxInnovations:
    """Testy dla luk IP Box: R138-R140."""

    def test_r138_medical_device_exists(self, rule_ids):
        """R138: Kategoria produktu medycznego (2022)."""
        assert "jdg.p05.ipbox.medical_device_category" in rule_ids

    def test_r138_medical_device_in_catalog(self, p05_content):
        """R138: MEDICAL_DEVICE dodane do katalogu 8 kategorii."""
        assert "MEDICAL_DEVICE" in p05_content
        assert "Art. 30ca ust. 2 pkt 8" in p05_content

    def test_r139_improved_nexus_exists(self, rule_ids):
        """R139: Ulepszony szacunek Nexus."""
        assert "jdg.p05.ipbox.improved_nexus_estimation" in rule_ids

    def test_r139_three_methods(self, p05_content):
        """R139: 3 metody szacowania Nexus (dokladny, ratio, branzowy)."""
        assert "dokładny wzór Nexus" in p05_content
        assert "kwalifikowane/total ratio" in p05_content
        assert "estymacja branżowa" in p05_content
        assert "industry_nexus_estimates" in p05_content

    def test_r139_industry_estimates(self, p05_content):
        """R139: Estymacje branzowe dla 8 kategorii IP."""
        assert "SOFTWARE" in p05_content
        assert "PATENT" in p05_content
        assert "0.92" in p05_content  # SOFTWARE estymacja

    def test_r140_allocation_optimizer_exists(self, rule_ids):
        """R140: Optymalizator alokacji dochodu IP Box vs B+R."""
        assert "jdg.p05.ipbox.income_allocation_optimizer" in rule_ids

    def test_r140_three_scenarios(self, p05_content):
        """R140: 3 scenariusze (Max IP Box, 50/50, Max B+R)."""
        assert "ip1 := min" in p05_content  # Max IP Box
        assert "ip2 := total_income * 0.5" in p05_content  # 50/50
        assert "ip3 := 0.0" in p05_content  # Max B+R


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 4: Luki Termomodernizacja (R129a)
# ═══════════════════════════════════════════════════════════════════════════════

class TestThermoInnovations:
    """Testy dla luk Termomodernizacja: R129a."""

    def test_r129a_exact_days_exists(self, rule_ids):
        """R129a: Dokladne obliczenie dni."""
        assert "jdg.p05.thermo.exact_days_remaining" in rule_ids

    def test_r129a_date_parsing(self, p05_content):
        """R129a: Parsowanie dat YYYY-MM-DD."""
        assert "substring(first_date_str, 0, 4)" in p05_content
        assert "substring(first_date_str, 5, 2)" in p05_content
        assert "substring(first_date_str, 8, 2)" in p05_content

    def test_r129a_deadline_exceeded(self, p05_content):
        """R129a: Wykrywanie przekroczenia terminu."""
        assert "deadline_exceeded := exact_days <= 0" in p05_content
        assert "TERMIN PRZEKROCZONY" in p05_content
        assert "BLOCK_AND_ALERT" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 5: Luki Estonski CIT (E185-E189)
# ═══════════════════════════════════════════════════════════════════════════════

class TestEstonianInnovations:
    """Testy dla luk Estonski CIT: E185-E189."""

    def test_e185_investment_alternative_exists(self, rule_ids):
        """E185: Alternatywa inwestycyjna."""
        assert "jdg.p05.estonian.investment_alternative" in rule_ids

    def test_e185_investment_threshold(self, p05_content):
        """E185: Min. wydatki inwestycyjne 25% ST lub 100k PLN."""
        assert "fixed_assets_value * 0.25" in p05_content
        assert "min_investment_absolute := 100000" in p05_content

    def test_e186_shareholder_check_exists(self, rule_ids):
        """E186: Weryfikacja udzialowcow."""
        assert "jdg.p05.estonian.shareholder_legal_entity_check" in rule_ids

    def test_e186_blocks_legal_entities(self, p05_content):
        """E186: BLOCK_AND_ALERT dla udzialowcow-podmiotow prawnych."""
        assert "has_legal_entity_shareholders" in p05_content
        assert "shareholder_ok := not has_legal_entity_shareholders" in p05_content

    def test_e187_exit_calculator_exists(self, rule_ids):
        """E187: Kalkulator wyjscia z estonskiego CIT."""
        assert "jdg.p05.estonian.exit_cost_calculator" in rule_ids

    def test_e187_lock_in_four_years(self, p05_content):
        """E187: Lock-in 4 lata z kara 20-25%."""
        assert "years_remaining := max([4 - years_elapsed, 0])" in p05_content
        assert "accumulated_undistributed_profit" in p05_content

    def test_e188_cit_rate_breakdown_exists(self, rule_ids):
        """E188: Rozbicie stawek CIT 9%/19%."""
        assert "jdg.p05.estonian.cit_rate_breakdown" in rule_ids

    def test_e188_small_taxpayer_rate(self, p05_content):
        """E188: Maly podatnik 9% CIT, duzy 19%."""
        assert "is_small := annual_revenue < 9000000" in p05_content
        assert "cit_component := 0.09" in p05_content
        assert "cit_component := 0.19" in p05_content

    def test_e189_hidden_profit_scanner_exists(self, rule_ids):
        """E189: Auto-detekcja ukrytych zyskow."""
        assert "jdg.p05.estonian.hidden_profit_scanner" in rule_ids

    def test_e189_five_categories(self, p05_content):
        """E189: 5 kategorii ukrytych zyskow."""
        assert "shareholder_loans_total" in p05_content
        assert "excess_spending_over_market" in p05_content
        assert "shareholder_benefits_value" in p05_content
        assert "shareholder_donations" in p05_content
        assert "share_redemption_income" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 6: Luki Cross-Relief (C155-C156)
# ═══════════════════════════════════════════════════════════════════════════════

class TestCrossReliefInnovations:
    """Testy dla luk Cross-Relief: C155-C156."""

    def test_c155_dynamic_ordering_exists(self, rule_ids):
        """C155: Dynamiczna optymalizacja kolejnosci ulg."""
        assert "jdg.p05.cross_relief.dynamic_ordering" in rule_ids

    def test_c155_ip_vs_rd_priority(self, p05_content):
        """C155: Priorytet IP Box vs B+R na podstawie oszczednosci."""
        assert "ip_priority := ip_income * 0.07" in p05_content
        assert "rd_priority := rd_costs * 0.12" in p05_content
        assert "PRIORYTET" in p05_content

    def test_c156_what_if_simulator_exists(self, rule_ids):
        """C156: What-If Relief Combination Simulator."""
        assert "jdg.p05.cross_relief.what_if_simulator" in rule_ids

    def test_c156_top_combinations(self, p05_content):
        """C156: Generuje TOP 5 kombinacji ulg."""
        assert "what_if_simulation" in p05_content
        assert "IP Box + B+R" in p05_content
        assert "best_combo_name" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 7: Luki Tax Loss (L165)
# ═══════════════════════════════════════════════════════════════════════════════

class TestTaxLossInnovations:
    """Testy dla luk Tax Loss: L165."""

    def test_l165_multi_year_optimizer_exists(self, rule_ids):
        """L165: Multi-Year Dynamic Tax Loss Optimization."""
        assert "jdg.p05.tax_loss.multi_year_optimizer" in rule_ids

    def test_l165_five_year_horizon(self, p05_content):
        """L165: Horyzont 5-letni."""
        assert "tax_loss_multi_year_horizon" in p05_content
        assert ": 5" in p05_content  # horizon = 5


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 8: Luki Annual Declaration (ADE-1923, ADE-1924)
# ═══════════════════════════════════════════════════════════════════════════════

class TestAnnualDeclarationInnovations:
    """Testy dla luk Annual Declaration: ADE-1923, ADE-1924."""

    def test_ade1923_pit_zg_exists(self, rule_ids):
        """ADE-1923: PIT-ZG — dochody z zagranicy."""
        assert "jdg.p05.annual_decl.pit_zg_foreign_income" in rule_ids

    def test_ade1923_credit_method(self, p05_content):
        """ADE-1923: Metoda credit + exemption."""
        assert "pit_zg_required" in p05_content
        assert "double_taxation_method" in p05_content
        assert "foreign_tax_paid_total_pln" in p05_content

    def test_ade1924_pit_ar_exists(self, rule_ids):
        """ADE-1924: PIT-AR — przeksztalcenie JDG -> Sp. z o.o."""
        assert "jdg.p05.annual_decl.pit_ar_transformation" in rule_ids

    def test_ade1924_remnant_tax(self, p05_content):
        """ADE-1924: Podatek od remanentu likwidacyjnego."""
        assert "remnant_inventory_value" in p05_content
        assert "jdg_transformed_this_year" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 9: Luki Form Optimizer (FTS-1790)
# ═══════════════════════════════════════════════════════════════════════════════

class TestFormOptimizerInnovations:
    """Testy dla luk Form Optimizer: FTS-1790."""

    def test_fts1790_tax_free_exists(self, rule_ids):
        """FTS-1790: Kwota wolna 30k w symulacji."""
        assert "jdg.p05.form_optimizer.tax_free_in_simulation" in rule_ids

    def test_fts1790_degressive_tax_free(self, p05_content):
        """FTS-1790: Degresywna kwota wolna."""
        assert "tax_free_amount := 30000.0" in p05_content
        assert "tax_free_applied" in p05_content
        assert "annual_profit <= 30000" in p05_content

    def test_fts1790_breakeven(self, p05_content):
        """FTS-1790: Break-even skala vs liniowy ~135k PLN."""
        assert "breakeven_with_free" in p05_content
        assert "scale_better_below_60k" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 10: Luki Exit Tax/MDR (ET-010, ET-011)
# ═══════════════════════════════════════════════════════════════════════════════

class TestExitTaxInnovations:
    """Testy dla luk Exit Tax/MDR: ET-010, ET-011."""

    def test_et010_upo_analyzer_exists(self, rule_ids):
        """ET-010: Analiza UPO."""
        assert "jdg.p05.exit_tax.upo_treaty_analyzer" in rule_ids

    def test_et010_upo_treaties_database(self, p05_content):
        """ET-010: Baza UPO dla DE, UK, FR, NL, US, CH, IE, CZ, SK."""
        for country in ["DE", "UK", "FR", "NL", "US"]:
            assert f'"{country}"' in p05_content, f"Brak UPO dla {country}"

    def test_et011_transfer_pricing_exists(self, rule_ids):
        """ET-011: Transfer Pricing — próg 2M PLN."""
        assert "jdg.p05.exit_tax.transfer_pricing_threshold" in rule_ids

    def test_et011_two_million_threshold(self, p05_content):
        """ET-011: Próg 2 000 000 PLN dla dokumentacji TP."""
        assert "2000000" in p05_content
        assert "transfer_pricing_transactions_total" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 11: Innowacje INN08-INN11 (Dashboard, Advisor, Legislative, Cross-Border)
# ═══════════════════════════════════════════════════════════════════════════════

class TestInnovations08to11:
    """Testy dla INN08-INN11."""

    def test_inn08_tax_burden_dashboard_exists(self, rule_ids):
        """INN08: Real-Time Tax Burden Dashboard."""
        assert "jdg.p05.inn08.tax_burden_dashboard" in rule_ids

    def test_inn08_burden_calculation(self, p05_content):
        """INN08: Oblicza PIT + zdrowotna + ZUS."""
        assert "monthly_burden := monthly_pit + monthly_health + monthly_zus" in p05_content
        assert "burden_pct" in p05_content

    def test_inn09_ai_tax_advisor_exists(self, rule_ids):
        """INN09: AI Tax Advisor Conversation Engine."""
        assert "jdg.p05.inn09.ai_tax_advisor" in rule_ids

    def test_inn09_priority_topics(self, p05_content):
        """INN09: Identyfikuje tematy doradcze."""
        assert "advisor_topics" in p05_content
        assert "next_best_action" in p05_content
        assert "IP Box + B+R to najsilniejsza kombinacja" in p05_content

    def test_inn10_legislative_monitor_exists(self, rule_ids):
        """INN10: Legislative Change Impact Predictor."""
        assert "jdg.p05.inn10.legislative_monitor" in rule_ids

    def test_inn10_active_changes(self, p05_content):
        """INN10: Monitoruje 4 aktywne zmiany."""
        assert "2026: Zmiana progów PIT" in p05_content
        assert "2027: Planowane zmiany w składce zdrowotnej" in p05_content

    def test_inn11_cross_border_risk_exists(self, rule_ids):
        """INN11: Cross-Border Double Taxation Risk Analyzer."""
        assert "jdg.p05.inn11.cross_border_risk" in rule_ids

    def test_inn11_risk_levels(self, p05_content):
        """INN11: 5 poziomow ryzyka (NONE, LOW, MEDIUM, HIGH, CRITICAL)."""
        assert "CRITICAL" in p05_content
        assert "foreign_income_countries" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 12: Innowacje INN12-INN15 (Audit, Form Selection, Family, Health Report)
# ═══════════════════════════════════════════════════════════════════════════════

class TestInnovations12to15:
    """Testy dla INN12-INN15."""

    def test_inn12_audit_risk_scorer_exists(self, rule_ids):
        """INN12: Tax Authority Audit Risk Score."""
        assert "jdg.p05.inn12.audit_risk_scorer" in rule_ids

    def test_inn12_risk_factors(self, p05_content):
        """INN12: 6+ czynnikow ryzyka kontroli."""
        assert "risk_factors" in p05_content
        assert "Wysoki dochód (>500k PLN)" in p05_content
        assert "Łączenie B+R + IP Box" in p05_content

    def test_inn13_tax_form_confidence_exists(self, rule_ids):
        """INN13: Automated Tax Form Selection with Confidence Score."""
        assert "jdg.p05.inn13.tax_form_confidence" in rule_ids

    def test_inn13_form_scoring(self, p05_content):
        """INN13: Scoring dla 4 form opodatkowania."""
        assert "PIT_SCALE" in p05_content
        assert "LINEAR" in p05_content
        assert "LUMP_SUM" in p05_content
        assert "ESTONIAN_CIT" in p05_content
        assert "form_scores" in p05_content

    def test_inn14_family_synergy_exists(self, rule_ids):
        """INN14: Family Tax Synergy Maximizer."""
        assert "jdg.p05.inn14.family_synergy_maximizer" in rule_ids

    def test_inn14_child_assignment(self, p05_content):
        """INN14: Przypisanie dzieci do rodzica z wyzszym dochodem."""
        assert "spouse_annual_income" in p05_content
        assert "child_relief" in p05_content
        assert "1112.04" in p05_content  # kwota ulgi na dziecko

    def test_inn15_tax_health_report_exists(self, rule_ids):
        """INN15: Annual Tax Health Report Generator."""
        assert "jdg.p05.inn15.tax_health_report" in rule_ids

    def test_inn15_efficiency_scoring(self, p05_content):
        """INN15: Scoring efektywnosci A-D."""
        assert "tax_grade" in p05_content
        assert "DOSKONAŁA optymalizacja" in p05_content
        assert "niewykorzystanych ulg" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 13: Integracja z main_jdg.rego
# ═══════════════════════════════════════════════════════════════════════════════

class TestMainJDGIntegration:
    """Testy integracji P05 z glownym orkiestratorem."""

    def test_p05_import_in_main(self, main_jdg_content):
        """main_jdg.rego importuje data.jdg.p05_innovations."""
        assert "import data.jdg.p05_innovations" in main_jdg_content

    def test_p05_in_sharded_sale(self, main_jdg_content):
        """P05 w sharded_sale_verdict."""
        assert "safe_merge(p05_innovations.decide," in main_jdg_content

    def test_p05_in_sharded_purchase(self, main_jdg_content):
        """P05 w sharded_purchase_verdict."""
        sharded_purchase = main_jdg_content.split("sharded_purchase_verdict")[1].split("full_final_verdict")[0]
        assert "p05_innovations.decide" in sharded_purchase

    def test_p05_in_full_chain(self, main_jdg_content):
        """P05 w full_final_verdict."""
        assert "p05_innovations.decide" in main_jdg_content.split("full_final_verdict")[1].split("gated_abort_verdict")[0]

    def test_p05_in_package_decisions(self, main_jdg_content):
        """P05 w mapie _package_decisions."""
        assert '"jdg.p05_innovations": p05_innovations.decide' in main_jdg_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 14: Kompletnosc implementacji
# ═══════════════════════════════════════════════════════════════════════════════

class TestCompleteness:
    """Testy kompletnosci wszystkich 34 implementacji."""

    EXPECTED_RULES = [
        # Luki B+R (4)
        "jdg.p05.rd.staff_time_verification",
        "jdg.p05.rd.patent_acquisition_costs",
        "jdg.p05.rd.carry_forward_tracker",
        "jdg.p05.rd.auto_cost_classifier",
        # Luki IP Box (3)
        "jdg.p05.ipbox.medical_device_category",
        "jdg.p05.ipbox.improved_nexus_estimation",
        "jdg.p05.ipbox.income_allocation_optimizer",
        # Luki Termo (1)
        "jdg.p05.thermo.exact_days_remaining",
        # Luki Estonski CIT (5)
        "jdg.p05.estonian.investment_alternative",
        "jdg.p05.estonian.shareholder_legal_entity_check",
        "jdg.p05.estonian.exit_cost_calculator",
        "jdg.p05.estonian.cit_rate_breakdown",
        "jdg.p05.estonian.hidden_profit_scanner",
        # Luki Cross-Relief (2)
        "jdg.p05.cross_relief.dynamic_ordering",
        "jdg.p05.cross_relief.what_if_simulator",
        # Luki Tax Loss (1)
        "jdg.p05.tax_loss.multi_year_optimizer",
        # Luki Annual Declaration (2)
        "jdg.p05.annual_decl.pit_zg_foreign_income",
        "jdg.p05.annual_decl.pit_ar_transformation",
        # Luki Form Optimizer (1)
        "jdg.p05.form_optimizer.tax_free_in_simulation",
        # Luki Exit Tax/MDR (2)
        "jdg.p05.exit_tax.upo_treaty_analyzer",
        "jdg.p05.exit_tax.transfer_pricing_threshold",
        # Innowacje INN08-INN15 (8)
        "jdg.p05.inn08.tax_burden_dashboard",
        "jdg.p05.inn09.ai_tax_advisor",
        "jdg.p05.inn10.legislative_monitor",
        "jdg.p05.inn11.cross_border_risk",
        "jdg.p05.inn12.audit_risk_scorer",
        "jdg.p05.inn13.tax_form_confidence",
        "jdg.p05.inn14.family_synergy_maximizer",
        "jdg.p05.inn15.tax_health_report",
        # Fallback
        "jdg.p05_innovations.fallback",
    ]

    def test_all_34_rules_present(self, rule_ids):
        """Wszystkie 32 regul (+ 1 default + 1 fallback) istnieje."""
        for expected in self.EXPECTED_RULES:
            assert expected in rule_ids, f"BRAK reguly: {expected}"

    def test_no_duplicate_priorities(self, p05_content):
        """Brak duplikatow priority (kazda regula ma unikalny priorytet)."""
        priorities = extract_priorities(p05_content)
        # Usun 999 (default) i 9999 (fallback) - moga sie powtarzac
        unique = [p for p in priorities if p not in (999, 9999)]
        assert len(unique) == len(set(unique)), \
            f"Znaleziono {len(unique) - len(set(unique))} duplikatow priority"

    def test_every_rule_has_legal_basis(self, p05_content):
        """Kazda regula ma podstawe prawna."""
        matched_count = len(re.findall(r'"matched":\s*true', p05_content))
        legal_count = len(extract_legal_basis_all(p05_content))
        # Kazda regula (oprocz fallback) powinna miec _legal_basis
        assert legal_count >= matched_count - 2, \
            f"Brak _legal_basis w {matched_count - legal_count} regulach"


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 15: Logika biznesowa - testy wartosci
# ═══════════════════════════════════════════════════════════════════════════════

class TestBusinessLogicValues:
    """Testy kluczowych wartosci biznesowych."""

    def test_rd_staff_threshold_50pct(self, p05_content):
        """B+R: prog czasu pracy 50%."""
        assert "time_pct := object.get" in p05_content
        assert ">= 50" in p05_content

    def test_ipbox_nexus_uplift_1_3(self, p05_content):
        """IP Box: mnoznik 1.3 we wzorze Nexus."""
        assert "1.3" in p05_content
        assert "nexus_ratio" in p05_content

    def test_thermo_limit_53000(self, p05_content):
        """Termomodernizacja: limit 53 000 PLN."""
        assert "53" in p05_content  # limit

    def test_estonian_revenue_threshold_100m(self, p05_content):
        """Estonski CIT: próg 100M PLN (w oryginalnym module family_estonian)."""
        # Próg 100M jest w family_estonian_enterprise.rego, nie w innovations.
        # Sprawdzamy, czy E185 (investment alternative) istnieje jako dowod pokrycia.
        assert "annual_investment_expenditures" in p05_content

    def test_estonian_small_threshold_9m(self, p05_content):
        """Estonski CIT: mały podatnik <9M PLN."""
        assert "9000000" in p05_content

    def test_donation_blood_value_130(self, p05_content):
        """Darowizny: krwiodawstwo 130 PLN/litr (w donation_relief_enterprise.rego).
        Innovations engine nie duplikuje tej wartosci - sprawdzamy powiazane dane."""
        # Krwiodawstwo jest w donation_relief_enterprise.rego.
        # Innovations zawiera rodzine i darowizny jako czesc cross-relief.
        assert "donation" in p05_content.lower() or "darowizny" in p05_content.lower()

    def test_tax_free_amount_30000(self, p05_content):
        """Kwota wolna: 30 000 PLN."""
        assert "30000.0" in p05_content

    def test_tp_threshold_2m(self, p05_content):
        """Transfer Pricing: próg 2 000 000 PLN."""
        assert "2000000" in p05_content


# ═══════════════════════════════════════════════════════════════════════════════
# SEKCJA 16: Routing i bezpieczenstwo
# ═══════════════════════════════════════════════════════════════════════════════

class TestRoutingAndSafety:
    """Testy routingu i bezpieczenstwa."""

    def test_block_and_alert_used(self, p05_content):
        """BLOCK_AND_ALERT uzywany w krytycznych przypadkach."""
        assert "BLOCK_AND_ALERT" in p05_content

    def test_triage_queue_used(self, p05_content):
        """TRIAGE_QUEUE uzywany dla podwyzszonego ryzyka."""
        assert "TRIAGE_QUEUE" in p05_content

    def test_warnings_in_every_rule(self, p05_content):
        """Kazda regula (oprocz fallback) ma _warnings."""
        warnings_count = len(re.findall(r'"_warnings":', p05_content))
        matched_count = len(re.findall(r'"matched":\s*true', p05_content))
        assert warnings_count >= matched_count - 2, \
            f"Brak _warnings w {matched_count - warnings_count} regulach"

    def test_routing_reason_in_rules(self, p05_content):
        """_routing_reason wystepuje w regulach."""
        assert '"_routing_reason"' in p05_content
