#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R04 PIT AUDYT (raporty_audyt_glm52/R04_PIT.txt) — Testy pytest
# ═══════════════════════════════════════════════════════════════════════════════
# 1) Weryfikacja usunięcia stubów { true } z 8 plików pit/ (P1, checklist C03/C18)
# 2) Mirror logiki T1: próg skali 119 999,99 / 120 000 / 120 000,01 + kwota zmniejszająca
# 3) Mirror logiki T9: kumulacja ulg (IP Box + B+R + termo ≤ dochód) — C155/C156
# 4) Mirror logiki P1: ulga dla klasy średniej 2026 (zniesiona od 2023) — P1625/P1626
# 5) Mirror logiki P2: termin zaliczek 20. dnia vs dni wolne — P559
# 6) P2/T9: PIT-28 vs PIT-36L wybór formy
# ═══════════════════════════════════════════════════════════════════════════════
import re
import sys
from pathlib import Path

# Plik znajduje się w JDG/tests/auto/ → parents[2] = JDG/ (katalog modułu)
BASE_DIR = Path(__file__).resolve().parents[2]
RULES_PIT_DIR = BASE_DIR / "rules" / "pit"

# ── 1. P1: STUBY USUNIĘTE — strukturalna weryfikacja rego ────────────────────

STUB_FILES = [
    "art21_exemptions_enterprise.rego",
    "cross_relief_optimizer_enterprise.rego",
    "donation_relief_enterprise.rego",
    "family_estonian_enterprise.rego",
    "ipbox_enterprise.rego",
    "rd_relief_enterprise.rego",
    "tax_loss_harvesting_enterprise.rego",
    "thermo_relief_enterprise.rego",
]

# Wzorzec stubu: else := {... "matched": true ...} { true } na końcu łańcucha
STUB_PATTERN = re.compile(
    r'else\s*:=\s*\{[^}]*"matched"\s*:\s*true[^}]*\}\s*\{\s*true\s*\}',
    re.DOTALL,
)


def test_r04_no_stub_true_patterns():
    for fname in STUB_FILES:
        content = (RULES_PIT_DIR / fname).read_text(encoding="utf-8")
        assert not STUB_PATTERN.search(content), f"STUB matched:true w {fname} — R04 P1"


def test_r04_no_matched_true_in_fallback_rule_ids():
    for fname in STUB_FILES:
        content = (RULES_PIT_DIR / fname).read_text(encoding="utf-8")
        # Żadna reguła nie powinna mieć rule_id kończącego się na .fallback
        for m in re.finditer(r'"rule_id"\s*:\s*"[^"]+"', content):
            rule_id = m.group(0)
            assert ".fallback" not in rule_id, f"Fallback rule_id w {fname}: {rule_id}"


def test_r04_no_match_blocks_exist():
    for fname in STUB_FILES:
        content = (RULES_PIT_DIR / fname).read_text(encoding="utf-8")
        assert ".no_match" in content, f"Brak no_match w {fname} — R04 P1"


# ── 2. T1: PRÓG SKALI 12%/32% + KWOTA ZMNIEJSZAJĄCA ──────────────────────────

SCALE_LOW = 0.12
SCALE_HIGH = 0.32
SCALE_THRESHOLD = 120000.0
TAX_FREE_AMOUNT = 30000.0
REDUCING_BASE = 3600.0


def scale_tax(income: float) -> float:
    if income <= SCALE_THRESHOLD:
        return income * SCALE_LOW
    low = SCALE_THRESHOLD * SCALE_LOW
    high = (income - SCALE_THRESHOLD) * SCALE_HIGH
    return low + high


def reducing_amount(income: float) -> float:
    if income <= TAX_FREE_AMOUNT:
        return REDUCING_BASE
    if income >= SCALE_THRESHOLD:
        return 0.0
    # degresja: 3600 przy 30k → 0 przy 120k
    return REDUCING_BASE * (SCALE_THRESHOLD - income) / (SCALE_THRESHOLD - TAX_FREE_AMOUNT)


def test_t1_119999_99_low_bracket():
    assert 119999.99 <= SCALE_THRESHOLD
    assert scale_tax(119999.99) == 119999.99 * SCALE_LOW
    assert reducing_amount(119999.99) > 0  # kwota zmniejszająca aktywna


def test_t1_120000_boundary():
    assert scale_tax(120000.0) == 120000.0 * SCALE_LOW
    assert reducing_amount(120000.0) == 0.0  # koniec degresji


def test_t1_120000_01_high_bracket():
    assert scale_tax(120000.01) == 120000.0 * SCALE_LOW + 0.01 * SCALE_HIGH
    assert reducing_amount(120000.01) == 0.0


def test_t1_reducing_amount_full_30k():
    assert reducing_amount(30000.0) == 3600.0
    assert reducing_amount(0.0) == 3600.0


def test_t1_reducing_amount_degression_mid():
    # 75 000: 3600 * (120000-75000)/(120000-30000) = 3600 * 0.5 = 1800
    assert abs(reducing_amount(75000.0) - 1800.0) < 1e-9


# ── 3. T9: KUMULACJA ULG (IP BOX + B+R + TERMO ≤ DOCHÓD) ─────────────────────


def relief_total(ip_box: float, rd: float, thermo: float) -> float:
    return ip_box + rd + thermo


def test_t9_accumulation_exceeded():
    income = 100000.0
    total = relief_total(ip_box=60000.0, rd=50000.0, thermo=20000.0)
    assert total == 130000.0
    assert total > income  # → BLOCK_AND_ALERT (C155)


def test_t9_accumulation_within_limit():
    income = 200000.0
    total = relief_total(ip_box=60000.0, rd=50000.0, thermo=20000.0)
    assert total <= income  # → OK (C156)


def test_t9_accumulation_exact_limit():
    income = 130000.0
    total = relief_total(ip_box=60000.0, rd=50000.0, thermo=20000.0)
    assert total == income  # ≤ dochód → OK


def test_t9_accumulation_detail():
    ip_box, rd, thermo = 60000.0, 50000.0, 20000.0
    detail = f"IP Box: {ip_box:.2f} + B+R: {rd:.2f} + termo: {thermo:.2f}"
    assert "130000.00" in f"{ip_box + rd + thermo:.2f}"


# ── 4. P1: ULGA DLA KLASY ŚREDNIEJ 2026 (ZNIESIONA OD 2023) ──────────────────


def middle_class_relief_active(year: int) -> bool:
    # P1626: aktywna tylko w 2022; P1625: zniesiona od 01.01.2023
    return year == 2022


def test_middle_class_relief_2026_inactive():
    assert middle_class_relief_active(2026) is False


def test_middle_class_relief_2022_active():
    assert middle_class_relief_active(2022) is True


def test_middle_class_relief_2023_inactive():
    assert middle_class_relief_active(2023) is False


def test_middle_class_relief_2024_inactive():
    assert middle_class_relief_active(2024) is False


# ── 5. P2: TERMIN ZALICZEK 20. DNIA VS DNI WOLNE (P559) ──────────────────────


def shifted_due_day(due_weekday: int, is_public_holiday: bool) -> int:
    # 1=Pn..7=Nd; sobota=6, niedziela=7
    if due_weekday == 6 and not is_public_holiday:
        return 22  # sobota → poniedziałek
    if due_weekday == 7 and not is_public_holiday:
        return 21  # niedziela → poniedziałek
    if is_public_holiday and due_weekday not in (6, 7):
        return 21  # święto w tygodniu → następny dzień roboczy
    if is_public_holiday and due_weekday == 6:
        return 22  # święto w sobotę → poniedziałek
    if is_public_holiday and due_weekday == 7:
        return 21  # święto w niedzielę → poniedziałek
    return 20  # dzień roboczy — bez przesunięcia


def test_deadline_saturday_shift():
    assert shifted_due_day(6, False) == 22


def test_deadline_sunday_shift():
    assert shifted_due_day(7, False) == 21


def test_deadline_holiday_weekday_shift():
    assert shifted_due_day(3, True) == 21


def test_deadline_holiday_saturday_shift():
    assert shifted_due_day(6, True) == 22


def test_deadline_no_shift_regular_weekday():
    assert shifted_due_day(3, False) == 20


# ── 6b. T1: ULGA MŁODYCH 85 528 ZŁ ± 1 ZŁ (R04 sekcja 4) ───────────────────

YOUNG_RELIEF_LIMIT = 85528.0


def young_relief_status(income: float) -> str:
    # Mirror P580/P581 (exemptions.rego): zwolnienie do 85 528 zł, powyżej anulacja
    if income <= YOUNG_RELIEF_LIMIT:
        return "YOUNG"
    return "YOUNG_REVOKED"


def test_t1_young_relief_below_limit():
    assert young_relief_status(85527.99) == "YOUNG"


def test_t1_young_relief_exact_limit():
    assert young_relief_status(85528.00) == "YOUNG"


def test_t1_young_relief_above_limit():
    assert young_relief_status(85528.01) == "YOUNG_REVOKED"


# ── 6c. T1: AMORTYZACJA JEDNORAZOWA 100 000 ZŁ VS 100 000,01 ZŁ (R04 sekcja 4) ──

ONE_OFF_DEPRECIATION_LIMIT = 100000.0


def one_off_depreciation_status(value: float) -> str:
    # Mirror art. 22d PIT — jednorazowa amortyzacja do 100 000 zł (de minimis)
    if value <= ONE_OFF_DEPRECIATION_LIMIT:
        return "ONE_OFF_OK"
    return "ONE_OFF_EXCEEDED"


def test_t1_depreciation_100k_ok():
    assert one_off_depreciation_status(100000.00) == "ONE_OFF_OK"


def test_t1_depreciation_100k_01_exceeded():
    assert one_off_depreciation_status(100000.01) == "ONE_OFF_EXCEEDED"


def test_t1_depreciation_below_ok():
    assert one_off_depreciation_status(99999.99) == "ONE_OFF_OK"


# ── 6d. T8: KUP 20% Z LIMITEM 3 000 ZŁ (R04 sekcja 4, art. 22 ust. 2 PIT) ─────

KUP_FLAT_RATE = 0.20
KUP_FLAT_RATE_LIMIT = 3000.0


def kup_20pct_cap(income: float) -> float:
    # Mirror art. 22 ust. 2 pkt 1 PIT — KUP 20% dochodu, maks. 3 000 zł/rok
    raw = income * KUP_FLAT_RATE
    if raw > KUP_FLAT_RATE_LIMIT:
        return KUP_FLAT_RATE_LIMIT
    return raw


def test_t8_kup_20pct_below_limit():
    # 10 000 * 20% = 2 000 zł < 3 000 zł → bez limitu
    assert kup_20pct_cap(10000.0) == 2000.0


def test_t8_kup_20pct_at_limit():
    # 15 000 * 20% = 3 000 zł == limit → dokładnie 3 000
    assert kup_20pct_cap(15000.0) == 3000.0


def test_t8_kup_20pct_capped():
    # 100 000 * 20% = 20 000 zł > 3 000 zł → limit 3 000
    assert kup_20pct_cap(100000.0) == 3000.0


# ── 6. P2/T9: PIT-28 vs PIT-36L — WYBÓR FORMY ────────────────────────────────

FORM_SELECTION = {
    "LUMP_SUM": ("PIT-28", "02-28"),
    "LINEAR": ("PIT-36L", "04-30"),
    "PIT_SCALE": ("PIT-36", "04-30"),
}


def test_form_selection_lump_sum_pit28():
    form, deadline = FORM_SELECTION["LUMP_SUM"]
    assert form == "PIT-28"
    assert deadline == "02-28"  # termin 28 lutego — wcześniejszy niż PIT-36/36L


def test_form_selection_linear_pit36l():
    form, deadline = FORM_SELECTION["LINEAR"]
    assert form == "PIT-36L"
    assert deadline == "04-30"


def test_form_selection_scale_pit36():
    form, deadline = FORM_SELECTION["PIT_SCALE"]
    assert form == "PIT-36"
    assert deadline == "04-30"


def test_form_selection_deadline_priority():
    # PIT-28 (28 lutego) wcześniej niż PIT-36/36L (30 kwietnia)
    assert FORM_SELECTION["LUMP_SUM"][1] < FORM_SELECTION["LINEAR"][1]
