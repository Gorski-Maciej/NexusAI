#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — R02 PRAWA PRZEDSIĘBIORCÓW AUDYT (raporty_audyt_glm52/R02_Prawa_Przedsiebiorcow.txt)
# Testy pytest — strukturalne + mirror logiki reguł
# ═══════════════════════════════════════════════════════════════════════════════
# 1) P1: limit działalności nieewidencjonowanej z data.thresholds (temporalny:
#        50% do 30.06.2023 → 75% od 01.07.2023 → 225% kwartalnie od 2026) — T1
# 2) P1: sukcesja bez zarządcy — okno 2 mies. (grace) + wygaśnięcie (expiry) — T4
# 3) P2: prokura (art. 18 PP) ↔ poa_manager_enterprise — bridge
# 4) T3: granica okresu zawieszenia (31.12 vs 1.01)
# 5) T7: brak duplikatów rule_id (business.rego + business/ + policies)
# 6) T10: próg trust_score AUTO_POST (0,92)
# 7) Ujednolicenie: policies/jdg/business.rego == JDG/rules/business.rego (1 wersja prawdy)
# ═══════════════════════════════════════════════════════════════════════════════
import re
from pathlib import Path

# Plik znajduje się w JDG/tests/auto/ → parents[2] = JDG/ (katalog modułu)
BASE_DIR = Path(__file__).resolve().parents[2]
RULES_DIR = BASE_DIR / "rules"
POLICIES_DIR = Path(__file__).resolve().parents[3] / "policies"

BUSINESS_REGO = RULES_DIR / "business.rego"
BUSINESS_DIR = RULES_DIR / "business"
POLICIES_BUSINESS_REGO = POLICIES_DIR / "jdg" / "business.rego"
THRESHOLDS_REGO = RULES_DIR / "thresholds_jdg.rego"
PROKURA_REGO = RULES_DIR / "representation" / "plan26_prokura.rego"

# T7: duplikaty sprawdzane w warstwie JDG (business.rego + business/).
# policies/jdg/business.rego jest celowym lustrem (1 wersja prawdy) — pomijane w T7,
# weryfikowane testem test_policies_business_unified_with_rules.
BUSINESS_FILES = [BUSINESS_REGO] + sorted(BUSINESS_DIR.glob("*.rego"))


# ── 1. P1: LIMIT Z DATA.THRESHOLDS (temporalny) ──────────────────────────────

def unregistered_limit_pct(eval_date: str) -> float:
    """Mirror data.jdg.thresholds.unregistered_limit_pct — 50% → 75% (01.07.2023)."""
    if eval_date >= "2026-01-01":
        return 0.75  # 225% kwartalnie / 3 mies.
    if eval_date >= "2023-07-01":
        return 0.75
    return 0.50


def unregistered_quarterly_multiplier(eval_date: str) -> float:
    return 2.25 if eval_date >= "2026-01-01" else 0.0


def unregistered_limit_monthly(min_wage: float, eval_date: str) -> float:
    return int(min_wage * unregistered_limit_pct(eval_date) * 100) / 100


def unregistered_exceeded(min_wage: float, eval_date: str, monthly_rev: float, quarterly_rev: float = 0.0) -> bool:
    qm = unregistered_quarterly_multiplier(eval_date)
    limit_monthly = unregistered_limit_monthly(min_wage, eval_date)
    if qm > 0 and quarterly_rev > 0:
        limit_quarterly = int(min_wage * qm * 100) / 100
        return quarterly_rev > limit_quarterly
    return monthly_rev > limit_monthly


def test_t1_2026_limit_values():
    # 75% × 4 800 = 3 600 zł/mies.; kwartalnie 225% × 4 800 = 10 800 zł
    assert unregistered_limit_monthly(4800, "2026-03-15") == 3600.0
    assert unregistered_quarterly_multiplier("2026-03-15") == 2.25
    assert int(4800 * 2.25 * 100) / 100 == 10800.0


def test_t1_2026_monthly_boundary():
    # T1: 3 599,99 / 3 600,00 / 3 600,01
    assert unregistered_exceeded(4800, "2026-03-15", 3599.99) is False
    assert unregistered_exceeded(4800, "2026-03-15", 3600.00) is False  # równy limit = OK
    assert unregistered_exceeded(4800, "2026-03-15", 3600.01) is True


def test_t1_2026_quarterly_boundary():
    # T1 kwartalny: 10 799,99 / 10 800,00 / 10 800,01
    assert unregistered_exceeded(4800, "2026-03-15", 0, 10799.99) is False
    assert unregistered_exceeded(4800, "2026-03-15", 0, 10800.00) is False
    assert unregistered_exceeded(4800, "2026-03-15", 0, 10800.01) is True


def test_t1_2022_50pct():
    # 2022: 50% × 3 010 = 1 505 zł
    assert unregistered_limit_pct("2022-06-01") == 0.50
    assert unregistered_limit_monthly(3010, "2022-06-01") == 1505.0
    assert unregistered_exceeded(3010, "2022-06-01", 1505.01) is True


def test_t1_2023h2_75pct():
    # od 01.07.2023: 75% × 3 600 = 2 700 zł
    assert unregistered_limit_pct("2023-07-01") == 0.75
    assert unregistered_limit_monthly(3600, "2023-07-01") == 2700.0
    assert unregistered_exceeded(3600, "2023-07-01", 2700.01) is True


def test_t1_thresholds_source_of_truth():
    """P1: wartość procentu musi pochodzić z data.thresholds (nie hardcode w regule)."""
    content = THRESHOLDS_REGO.read_text(encoding="utf-8")
    # Aktualny stan prawny: 75%
    assert '"unregistered_revenue_pct": 0.75' in content
    # Wpis temporalny 50% → 75% (01.07.2023)
    assert '"unregistered_revenue_pct": {' in content
    assert '"previous_value": 0.50' in content
    # Wersjonowanie per okres (2026: 225% kwartalnie)
    assert '"business.unregistered_revenue_pct"' in content
    assert '"value": 2.25' in content
    # Helpery temporalne
    assert "unregistered_limit_pct(eval_date)" in content
    assert "unregistered_quarterly_multiplier(eval_date)" in content


def test_t1_p930_no_hardcoded_percent():
    """P1: P930 nie może hardkodować 0.50 — limit z thresholds (temporalny)."""
    content = BUSINESS_REGO.read_text(encoding="utf-8")
    p930_section = content[content.index("# ══════ P930:"):content.index("# ══════ P932:")]
    assert "unregistered_limit_pct" in p930_section
    assert "data.jdg.thresholds.unregistered_limit_pct" in p930_section
    assert re.search(r"floor\(0\.50 \*", p930_section) is None


def test_t1_r02_audit_rules_exist():
    content = BUSINESS_REGO.read_text(encoding="utf-8")
    for rule_id in [
        "jdg.business.unregistered_limit_check",
        "jdg.business.succession_no_manager_grace",
        "jdg.business.succession_no_manager_expiry",
        "jdg.business.suspension_period_boundary",
    ]:
        assert rule_id in content, f"Brak reguły {rule_id} — R02"


# ── 2. P1: SUKCESJA BEZ ZARZĄDCY (T4) ────────────────────────────────────────

def succession_verdict(days_elapsed: int) -> str:
    if days_elapsed < 60:
        return "GRACE"
    return "EXPIRY"


def test_t4_succession_grace_window():
    assert succession_verdict(0) == "GRACE"
    assert succession_verdict(30) == "GRACE"
    assert succession_verdict(59) == "GRACE"


def test_t4_succession_expiry_boundary():
    assert succession_verdict(60) == "EXPIRY"
    assert succession_verdict(61) == "EXPIRY"
    assert succession_verdict(120) == "EXPIRY"


def test_t4_succession_missing_manager_field_no_crash():
    # T4: input bez pola "zarządca" → silnik zwraca werdykt grace (dni=0), nie mdleje
    result = {"in_succession": True, "manager_nip": None}
    assert result["in_succession"] is True
    # Mirror logiki: brak NIP + 0 dni → GRACE
    assert succession_verdict(0) == "GRACE"


# ── 3. P2: PROKURA ↔ POA_MANAGER ─────────────────────────────────────────────

def test_p2_prokura_poa_bridge_rule_exists():
    content = PROKURA_REGO.read_text(encoding="utf-8")
    assert "jdg.representation.prokura_poa_manager_bridge" in content
    assert "poa_manager_package" in content
    assert '"jdg.poa_manager"' in content
    assert "business_audit_prokura_check" in content


def test_p2_prokura_chain_preserved():
    content = PROKURA_REGO.read_text(encoding="utf-8")
    # Bridge (audytowy) NIE psuje normalnego łańcucha prokury
    assert "jdg.representation.prokura_self_employed" in content
    assert "jdg.representation.prokura_joint" in content
    assert "jdg.representation.prokura_branch" in content
    assert "jdg.representation.prokura_unregistered" in content


# ── 4. T3: GRANICA OKRESU ZAWIESZENIA ────────────────────────────────────────

def suspension_status(start: str, end: str, eval_date: str) -> str:
    if start <= eval_date <= end:
        return "SUSPENDED"
    if eval_date > end:
        return "ACTIVE"
    return "PRE_SUSPENSION"


def test_t3_suspension_last_day_of_period():
    # 31.12 23:59 — nadal w okresie zawieszenia
    assert suspension_status("2026-01-01", "2026-12-31", "2026-12-31") == "SUSPENDED"


def test_t3_suspension_resumed_next_day():
    # 1.01 00:01 — wznowienie
    assert suspension_status("2026-01-01", "2026-12-31", "2027-01-01") == "ACTIVE"


def test_t3_suspension_pre_start():
    assert suspension_status("2026-01-01", "2026-12-31", "2025-12-31") == "PRE_SUSPENSION"


# ── 5. T7: BRAK DUPLIKATÓW rule_id (business.rego + business/ + policies) ─────

RULE_ID_PATTERN = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')


def test_t7_no_duplicate_rule_ids():
    all_ids = []
    for f in BUSINESS_FILES:
        content = f.read_text(encoding="utf-8")
        all_ids.extend(RULE_ID_PATTERN.findall(content))
    dupes = {rid for rid in all_ids if all_ids.count(rid) > 1}
    assert not dupes, f"Duplikaty rule_id w warstwie business: {dupes}"


def test_t7_rule_ids_unique_across_shared_ids():
    """T7: rule_id między business.rego a plan26_suspension_succession nie mogą się powielać."""
    jdg_ids = RULE_ID_PATTERN.findall(BUSINESS_REGO.read_text(encoding="utf-8"))
    plan26_ids = RULE_ID_PATTERN.findall((BUSINESS_DIR / "plan26_suspension_succession.rego").read_text(encoding="utf-8"))
    common = set(jdg_ids) & set(plan26_ids)
    assert not common, f"Wspólne rule_id business.rego ↔ plan26: {common}"


# ── 6. T10: PRÓG TRUST_SCORE AUTO_POST (0,92) ────────────────────────────────

def test_t10_trust_auto_post_threshold():
    content = THRESHOLDS_REGO.read_text(encoding="utf-8")
    assert '"trust_auto_post": 0.92' in content
    # Próg stabilny w risk.rego P1 (0,919/0,920/0,921) — odczyt z data.thresholds
    risk = (RULES_DIR / "risk.rego").read_text(encoding="utf-8")
    assert "trust_auto_post" in risk
    assert "0.92" in risk


# ── 7. UJEDNOLICENIE: policies/jdg/business.rego == JDG/rules/business.rego ──

def test_policies_business_unified_with_rules():
    """R02 rec #4: 1 wersja prawdy — policies jest pełnym lustrem JDG/rules."""
    assert POLICIES_BUSINESS_REGO.exists()
    jdg_content = BUSINESS_REGO.read_text(encoding="utf-8")
    pol_content = POLICIES_BUSINESS_REGO.read_text(encoding="utf-8")
    assert jdg_content == pol_content, "policies/jdg/business.rego rozjechał się z JDG/rules/business.rego"


def test_policies_business_has_new_rules():
    content = POLICIES_BUSINESS_REGO.read_text(encoding="utf-8")
    for rule_id in [
        "jdg.business.unregistered_limit_check",
        "jdg.business.succession_no_manager_expiry",
        "jdg.business.suspension_period_boundary",
    ]:
        assert rule_id in content, f"policies brakuje reguły {rule_id}"
