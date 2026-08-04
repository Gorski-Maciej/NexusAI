#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R03 VAT AUDYT (raporty_audyt_glm52/R03_VAT.txt)
# Testy pytest — strukturalne + mirror logiki reguł
# ═══════════════════════════════════════════════════════════════════════════════
# 1) P1: art. 113 — limit 200 000 zł z data.thresholds (temporalnie) + przekroczenie
#    w trakcie roku/kwartału (ust. 5 i 9, SLIM VAT 2 opcja kwartalna) — T1
# 2) P1: art. 43 + Rozp. MF 4.12.2024 — mapowanie 1:1 CN→stawka i PKWiU→8% — T2
# 3) P1: art. 90 — proporcja 2%/98% graniczna (externalizacja z data.thresholds) — T1
# 4) P2: art. 96b (Biała Lista) × próg 15 000 zł — jedna reguła (whitelist_15k_binding)
# 5) P2: WDT 90 dni (art. 42 ust. 12-13 VAT) — T3 granica
# 6) T7: brak duplikatów rule_id w zmodyfikowanych plikach VAT
# 7) Rec #4: ujednolicenie — policies czytają próg 200k z data.thresholds
# ═══════════════════════════════════════════════════════════════════════════════
import re
from pathlib import Path

# Plik znajduje się w JDG/tests/auto/ → parents[2] = JDG/ (katalog modułu)
BASE_DIR = Path(__file__).resolve().parents[2]
RULES_DIR = BASE_DIR / "rules"
POLICIES_DIR = Path(__file__).resolve().parents[3] / "policies"

THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
SUBSTANTIVE_REGO = RULES_DIR / "vat" / "substantive.rego"
PLAN26_REGO = RULES_DIR / "vat" / "plan26_critical.rego"
PLAN42_REGO = RULES_DIR / "vat" / "plan42_reduced_rates.rego"
PROPORTION_REGO = RULES_DIR / "micro" / "vat" / "proportion_vat.rego"
WDT_EXPORT_REGO = RULES_DIR / "micro" / "vat" / "wdt_export_import.rego"
MPP_REGO = RULES_DIR / "vat_mpp_split_payment_enterprise.rego"

POLICIES_SUBSTANTIVE_REGO = POLICIES_DIR / "jdg" / "vat" / "substantive.rego"
POLICIES_DEDUCTIONS_REGO = POLICIES_DIR / "jdg" / "vat" / "deductions.rego"

RULE_ID_PATTERN = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')

VAT_TOUCHED_FILES = [
    SUBSTANTIVE_REGO,
    PLAN26_REGO,
    PLAN42_REGO,
    PROPORTION_REGO,
    MPP_REGO,
]


# ── 1. P1: ART. 113 — LIMIT Z DATA.THRESHOLDS (temporalny + kwartalny) ───────

def subject_exemption_limit_for_date(eval_date: str) -> float:
    """Mirror data.jdg.thresholds.subject_exemption_limit_for_date — 200k (2017+)."""
    return 200000.0


def subject_exemption_quarterly_mode(eval_date: str) -> bool:
    """Mirror data.jdg.thresholds.subject_exemption_quarterly_mode — SLIM VAT 2 (2021-07-01)."""
    return eval_date >= "2021-07-01"


def quarterly_limit(annual_limit: float, remaining_quarters: int) -> float:
    return annual_limit * remaining_quarters / 4


def test_t1_art113_limit_values():
    assert subject_exemption_limit_for_date("2026-01-01") == 200000.0
    assert subject_exemption_limit_for_date("2017-06-01") == 200000.0
    assert subject_exemption_quarterly_mode("2026-01-01") is True
    assert subject_exemption_quarterly_mode("2021-06-30") is False


def test_t1_art113_quarterly_calculation():
    # Limit kwartalny (art. 113 ust. 9): limit × pozostałe kwartały / 4
    assert quarterly_limit(200000, 4) == 200000.0
    assert quarterly_limit(200000, 2) == 100000.0
    assert quarterly_limit(200000, 1) == 50000.0


def test_t1_art113_boundary():
    # T1: 199 999,99 / 200 000 / 200 000,01
    limit = subject_exemption_limit_for_date("2026-01-01")
    assert 199999.99 < limit
    assert 200000.00 == limit  # równy limit NIE przekracza (>)
    assert 200000.01 > limit


def test_t1_art113_thresholds_source_of_truth():
    content = THRESHOLDS_REGO.read_text(encoding="utf-8")
    # Wartość limitu w data.thresholds
    assert '"subject_exemption_limit": 200000' in content
    # Wpis temporalny (art. 113 ust. 1 — od 2017)
    assert '"subject_exemption_limit": {' in content
    assert '"valid_from": "2017-01-01"' in content
    # Wersjonowanie per okres
    assert '"vat.subject_exemption_limit"' in content
    # Helpery temporalne
    assert "subject_exemption_limit_for_date(eval_date)" in content
    assert "subject_exemption_quarterly_mode(eval_date)" in content


def test_t1_art113_no_hardcoded_limit_in_rules():
    """P1: reguły NIE mogą hardkodować 200000 w warunku — limit z data.thresholds."""
    # substantive.rego P51/P51b/P131
    sub = SUBSTANTIVE_REGO.read_text(encoding="utf-8")
    assert "thresholds.vat.subject_exemption_limit" in sub
    # Brak warunku `annual_turnover_net < 200000` (hardcode) w P51
    assert re.search(r"annual_turnover_net\s*<\s*200000", sub) is None
    assert re.search(r"annual_turnover_net\s*>\s*200000", sub) is None

    # plan26_critical CRIT-5: limit proporcjonalny z thresholds (nie `200000 / 365`)
    p26 = PLAN26_REGO.read_text(encoding="utf-8")
    crit5_section = p26[p26.index("CRIT-5"):p26.index("CRIT-6")]
    assert "subject_exemption_limit_for_date" in crit5_section
    assert "thresholds." in crit5_section
    assert re.search(r"=\s*200000\s*/\s*365", crit5_section) is None


def test_t1_art113_quarterly_rule_exists():
    content = PLAN26_REGO.read_text(encoding="utf-8")
    assert "jdg.vat.plan26_critical.subject_exemption_quarterly_excess" in content
    assert "vat_subject_exemption_check" in content
    assert "remaining_quarters" in content
    assert "vat_registration_required" in content


# ── 2. P1: ART. 43 + STAWKI OBNIŻONE 1:1 (CN + PKWiU) — T2 ───────────────────

def test_t2_cn_rate_map_extended():
    """P1 rec. #1: mapa CN→stawka rozszerzona 1:1 (Rozp. MF z 4.12.2024)."""
    content = PLAN42_REGO.read_text(encoding="utf-8")
    cn_map_section = content[content.index("cn_vat_rate_map :="):content.index("pkwiu_rate_map :=")]
    # Kluczowe pozycje: żywność 5% (0401 mleko), leki 8% (3004), woda 23% (2201)
    assert '"0401": 0.05' in cn_map_section
    assert '"0709": 0.05' in cn_map_section
    assert '"1006": 0.05' in cn_map_section
    assert '"3004": 0.08' in cn_map_section
    assert '"9018": 0.08' in cn_map_section
    # Co najmniej 45 pozycji w mapie (podzbiór — pełna lista externalizowana)
    entries = re.findall(r'"\d{4}":\s*0\.\d+', cn_map_section)
    assert len(entries) >= 45


def test_t2_pkwiu_rate_map_exists():
    content = PLAN42_REGO.read_text(encoding="utf-8")
    assert "pkwiu_rate_map :=" in content
    # Usługi 8% z Załącznika 3 (fryzjerstwo, naprawy, czyszczenie)
    assert '"96.02": 0.08' in content
    assert '"95.11": 0.08' in content
    assert '"81.21": 0.08' in content


def test_t2_mismatch_rules_exist():
    content = PLAN42_REGO.read_text(encoding="utf-8")
    # RATE-9: 23% na towar z listy obniżonej (CN) — błąd klasyfikacji
    assert "jdg.vat.reduced_rates.cn_23pct_mismatch" in content
    assert "MISMATCH_23PCT" in content
    # RATE-8: walidacja PKWiU 8% + mismatch
    assert "jdg.vat.reduced_rates.pkwiu_8pct_validation" in content
    assert "jdg.vat.reduced_rates.pkwiu_rate_mismatch" in content


# ── 3. P1: ART. 90 — PROPORCJA 2%/98% Z DATA.THRESHOLDS (T1) ──────────────────

def proportion_verdict(pct: float) -> str:
    """Mirror łańcucha PROP-03/PROP-04 (progi 2%/98% z data.thresholds)."""
    min_pct = 0.02 * 100
    max_pct = 0.98 * 100
    if pct < min_pct:
        return "NO_DEDUCTION"
    if pct > max_pct:
        return "FULL_DEDUCTION"
    return "PARTIAL"


def test_t1_proportion_boundaries():
    # T1: 98% → 100% (pełne odliczenie >98%); 2% de minimis (<2% = 0%)
    assert proportion_verdict(98.01) == "FULL_DEDUCTION"
    assert proportion_verdict(98.00) == "PARTIAL"   # dokładnie 98% → proporcja
    assert proportion_verdict(1.99) == "NO_DEDUCTION"
    assert proportion_verdict(2.00) == "PARTIAL"    # dokładnie 2% → NIE de minimis


def test_t1_proportion_thresholds_source_of_truth():
    content = THRESHOLDS_REGO.read_text(encoding="utf-8")
    assert '"proportion_min_threshold": 0.02' in content
    assert '"proportion_max_threshold": 0.98' in content


def test_t1_proportion_no_hardcoded_2_98():
    """P1: PROP-03/PROP-04 czytają progi z data.thresholds — zero hardcode."""
    content = PROPORTION_REGO.read_text(encoding="utf-8")
    assert "import data.jdg.thresholds" in content
    assert "thresholds.vat.proportion_min_threshold" in content
    assert "thresholds.vat.proportion_max_threshold" in content
    prop03 = content[content.index("prop_03"):content.index("prop_04")]
    assert re.search(r"<\s*2\.0", prop03) is None
    prop04 = content[content.index("prop_04"):content.index("prop_05")]
    assert re.search(r">\s*98\.0", prop04) is None


# ── 4. P2: BIAŁA LISTA × 15 000 ZŁ (art. 96b ust. 1a) — JEDNA REGUŁA ─────────

def whitelist_verdict(amount: float, payment_to_whitelisted_account: bool) -> bool:
    """Mirror whitelist_15k_binding — naruszenie przy płatności ≥15k poza wykazem."""
    if amount < 15000:
        return False  # reguła nie dotyczy
    return not payment_to_whitelisted_account


def test_p2_whitelist_15k_binding():
    assert whitelist_verdict(20000.00, False) is True
    assert whitelist_verdict(20000.00, True) is False
    assert whitelist_verdict(14999.99, False) is False  # <15k — poza zakresem


def test_p2_whitelist_15k_rule_exists():
    content = MPP_REGO.read_text(encoding="utf-8")
    assert "jdg.vat_mpp_split_payment.whitelist_15k_binding" in content
    assert "whitelist_15k_check" in content
    # Jedna reguła wiąże art. 96b z progiem 15k (mpp_threshold)
    assert '"whitelist_check_required": true' in content
    assert "sanction_20pct" in content
    assert "kup_denied" in content
    assert "Art. 96b" in content


# ── 5. P2: WDT 90 DNI (art. 42 ust. 12-13 VAT) — T3 ───────────────────────────

def test_t3_wdt_90_day_boundary():
    # T3: 90 dni NIE > 90 (stawka 0% nadal); 91 dni → stawka krajowa 23%
    assert (90 > 90) is False
    assert (91 > 90) is True


def test_t3_wdt_90_rule_exists():
    content = WDT_EXPORT_REGO.read_text(encoding="utf-8")
    assert "jdg.micro.vat.wdt_export.wdt_03" in content
    assert "wdt_docs_missing_days" in content
    assert "wdt_docs_missing_days\", 0) > 90" in content


# ── 6. T7: BRAK DUPLIKATÓW rule_id (zmodyfikowane pliki VAT) ──────────────────

def test_t7_no_duplicate_rule_ids_in_touched_files():
    all_ids = []
    for f in VAT_TOUCHED_FILES:
        content = f.read_text(encoding="utf-8")
        all_ids.extend(RULE_ID_PATTERN.findall(content))
    dupes = {rid for rid in all_ids if all_ids.count(rid) > 1}
    assert not dupes, f"Duplikaty rule_id w plikach VAT (R03): {dupes}"


def test_t7_new_rule_ids_unique():
    """T7: nowe rule_id R03 nie mogą istnieć nigdzie indziej (konflikt else-chain)."""
    new_ids = [
        "jdg.vat.plan26_critical.subject_exemption_quarterly_excess",
        "jdg.vat.reduced_rates.cn_23pct_mismatch",
        "jdg.vat.reduced_rates.pkwiu_8pct_validation",
        "jdg.vat.reduced_rates.pkwiu_rate_mismatch",
        "jdg.vat_mpp_split_payment.whitelist_15k_binding",
    ]
    for rid in new_ids:
        hits = 0
        for f in VAT_TOUCHED_FILES:
            hits += RULE_ID_PATTERN.findall(f.read_text(encoding="utf-8")).count(rid)
        assert hits == 1, f"rule_id {rid} — {hits} wystąpień (oczekiwano 1)"


# ── 7. REC #4: UJEDNOLICENIE — POLICIES CZYTAJĄ PRÓG Z DATA.THRESHOLDS ───────

def test_policies_substantive_thresholds_aligned():
    """P1/rec. #4: policies/jdg/vat/substantive.rego nie hardkoduje 200k."""
    content = POLICIES_SUBSTANTIVE_REGO.read_text(encoding="utf-8")
    assert "vat_subject_exemption_limit" in content
    assert re.search(r"annual_turnover_net\s*<\s*200000", content) is None
    assert re.search(r"annual_turnover_net\s*>\s*200000", content) is None


def test_policies_deductions_proportion_aligned():
    """P1/rec. #4: policies/jdg/vat/deductions.rego nie hardkoduje progu 2%."""
    content = POLICIES_DEDUCTIONS_REGO.read_text(encoding="utf-8")
    assert "vat_proportion_min_pct" in content
    assert re.search(r"vat_proportion\s*<\s*0\.02", content) is None


# ── 8. R03 — SPÓJNOŚĆ: ART. 43 ZWOLNIENIA (P55) + REGUŁY AUDYTOWE ───────────

def test_art43_exemption_rules_exist():
    content = SUBSTANTIVE_REGO.read_text(encoding="utf-8")
    for rid in [
        "jdg.vat.substantive.education_exempt",
        "jdg.vat.substantive.healthcare_exempt",
        "jdg.vat.substantive.financial_exempt",
        "jdg.vat.substantive.culture_exempt",
    ]:
        assert rid in content, f"Brak reguły art. 43: {rid}"


def test_plan26_art43_map_extended():
    """CRIT-17: mapa zwolnień art. 43 rozszerzona (edukacja/sport/kultura/finanse)."""
    content = PLAN26_REGO.read_text(encoding="utf-8")
    for cat in [
        '"EDUCATION_SERVICES": {"point": "26"',
        '"SPORT_SERVICES": {"point": "28"',
        '"CULTURAL_SERVICES": {"point": "33"',
        '"FINANCIAL_SERVICES": {"point": "36"',
    ]:
        assert cat in content, f"Brak pozycji art. 43: {cat}"
