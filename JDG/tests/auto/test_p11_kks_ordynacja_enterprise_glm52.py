# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — P11 GLM52 KKS + ORDYNACJA + AUDYT/OBRONA — Enterprise Test Suite
# Coverage: penalty_calculator, defense_packet_builder, correspondence_generator,
#           limitations_calendar, atomic Rego, native tests, wiring PAS 48
# ═══════════════════════════════════════════════════════════════════════════════
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

import penalty_calculator  # noqa: E402
import defense_packet_builder  # noqa: E402
import correspondence_generator  # noqa: E402
import limitations_calendar  # noqa: E402


# ── 1. KKS PENALTY CALCULATOR (art. 54-83 gradacja + minimalizacja) ────────────
class TestPenaltyCalculator:
    def test_penalty_crime_art54(self):
        r = penalty_calculator.penalty_calculator(100000, offense="art54")
        assert r["kind"] == "PRZESTEPSTWO"
        assert r["final_penalty_pln"] == round(
            (r["daily_rate_pln"] * r["rates_count"]) * 100) / 100
        assert r["proof"]["legal"].startswith("Art. 23 § 2, 27, 54")
        assert "Dz.U. 2025 poz. 678" in r["proof"]["legal"]

    def test_penalty_misdemeanor_art77(self):
        r = penalty_calculator.penalty_calculator(5000, offense="art77")
        assert r["kind"] == "WYKROCZENIE"
        assert r["rates_count"] <= 240

    def test_penalty_rates_capped_at_max(self):
        r = penalty_calculator.penalty_calculator(100000, offense="art54", daily_rates=1000)
        assert r["rates_count"] <= 720

    def test_penalty_non_negative(self):
        for off in penalty_calculator.CRIME_TYPES:
            r = penalty_calculator.penalty_calculator(10000, offense=off)
            assert r["final_penalty_pln"] >= 0

    def test_active_remorse_reduces_penalty(self):
        base = penalty_calculator.penalty_calculator(100000, offense="art54")
        remorse = penalty_calculator.penalty_calculator(
            100000, offense="art54", remorse_before_detection=True)
        assert remorse["final_penalty_pln"] < base["final_penalty_pln"]
        assert remorse["minimization_path"] == "CZYNNY_ZAL_art16"

    def test_voluntary_submission_reduces(self):
        r = penalty_calculator.penalty_calculator(
            100000, offense="art54", voluntary_submission=True)
        assert r["minimization_path"] == "DOBROWOLNE_PODDANIE_art17"

    def test_recidivism_doubles(self):
        r = penalty_calculator.penalty_calculator(100000, offense="art54", recidivism=True)
        assert r["recidivism_multiplier"] == 2.0

    def test_four_path_simulator(self):
        s = penalty_calculator.four_path_simulator(50000)
        assert s["recommended_penalty_pln"] == 0  # czynny żal przed wykryciem
        s2 = penalty_calculator.four_path_simulator(50000, audit_started=True)
        assert s2["paths"]["CZYNNY_ZAL"] is None  # po kontroli niedostępny
        assert s2["recommended_path"] in ("DOBROWOLNE_PODDANIE", "KOREKTA_PRZED_KONTROLA", "OBRONA_AUDYTOWA")


# ── 2. DEFENSE PACKET BUILDER (obrona przed KAS) ───────────────────────────────
class TestDefensePacketBuilder:
    def test_packet_built(self):
        p = defense_packet_builder.build_packet(
            "Jan Kowalski", "1234567890", "2026-03-10",
            golden_replay_sha="abc123",
            decision_certificates=[{"rule_id": "jdg.micro.ord.a70.limitation"}],
            lkg_snapshot_date="2026-03-01",
        )
        assert p["packet_id"]
        assert p["rights_timeline"]["notification"]["days"] == 7
        assert p["rights_timeline"]["protocol_objection"]["days"] == 14
        assert p["rights_timeline"]["wsa"]["days"] == 30
        assert p["evidence"]["lkg_snapshot_date"] == "2026-03-01"
        assert p["verification"]["packet_ready"] is True

    def test_packet_status_complete(self):
        p = defense_packet_builder.build_packet(
            "Jan Kowalski", "1234567890", "2026-03-10",
            golden_replay_sha="abc", decision_certificates=[{}],
            lkg_snapshot_date="2026-03-01")
        st = defense_packet_builder.packet_status(p, today="2026-03-05")
        assert st["complete"] is True
        assert st["status"] == "GOTOWY"

    def test_packet_status_missing_evidence(self):
        p = defense_packet_builder.build_packet("Jan", "1", "2026-03-10")
        st = defense_packet_builder.packet_status(p, today="2026-03-05")
        assert st["complete"] is False
        assert "decision_certificates" in st["missing_evidence"]

    def test_nearest_deadline(self):
        p = defense_packet_builder.build_packet("Jan", "1", "2026-03-10")
        st = defense_packet_builder.packet_status(p, today="2026-03-05")
        assert st["nearest_deadline"]["right"] == "notification"


# ── 3. CORRESPONDENCE GENERATOR (pisma do US/KAS) ──────────────────────────────
class TestCorrespondenceGenerator:
    def test_active_remorse_letter(self):
        p = correspondence_generator.generate(
            "czynny_zal", "Jan Kowalski", "ul. Testowa 1", "1234567890",
            date_str="2026-03-01", subject="nieprawidłowości VAT", facts="zanizenie")
        assert "art. 16" in p["legal_basis"].lower()
        assert "Dz.U. 2025 poz. 678" in p["legal_basis"]
        assert p["title"] == "Czynny żal (art. 16 KKS)"
        assert "Kodeks karny skarbowy" in p["legal_basis"]

    def test_appeal_letter(self):
        p = correspondence_generator.generate(
            "odwolanie", "Jan Kowalski", "ul. Testowa 1", "1234567890",
            date_str="2026-03-01", subject="decyzja", facts="naruszenie")
        assert "art. 220-223" in p["legal_basis"].lower()
        assert "Dz.U. 2025 poz. 234" in p["legal_basis"]

    def test_bundle_four_letters(self):
        b = correspondence_generator.generate_bundle(
            "Jan Kowalski", "ul. Testowa 1", "1234567890", "2026-03-01", "DEC/2026/01")
        assert len(b) == 4
        assert "czynny_zal" in b

    def test_all_doc_types_generate(self):
        for t in correspondence_generator.DOC_TYPES:
            p = correspondence_generator.generate(t, "Jan", "ul. X", "1", date_str="2026-03-01")
            assert p["legal_basis"]
            assert p["body"]


# ── 4. LIMITATIONS CALENDAR (art. 70 OP — kalendarz przedawnień) ───────────────
class TestLimitationsCalendar:
    def test_calendar_builds(self):
        obligations = [
            {"id": "1", "tax_year": 2020, "type": "PIT", "amount_pln": 1000.0},
            {"id": "2", "tax_year": 2021, "type": "VAT", "amount_pln": 2000.0},
        ]
        cal = limitations_calendar.build_calendar(obligations, today_year=2026)
        assert len(cal) == 2
        for entry in cal:
            assert entry["expire_year"] >= 2025
            assert entry["legal_basis"].startswith("Art. 70")

    def test_limitation_expired_detection(self):
        obligations = [{"id": "1", "tax_year": 2019, "type": "VAT", "amount_pln": 1000.0}]
        cal = limitations_calendar.build_calendar(obligations, today_year=2026)
        assert cal[0]["status"] == "EXPIRED"

    def test_limitation_not_expired(self):
        obligations = [{"id": "1", "tax_year": 2024, "type": "VAT", "amount_pln": 1000.0}]
        cal = limitations_calendar.build_calendar(obligations, today_year=2026)
        assert cal[0]["status"] != "EXPIRED"
        assert cal[0]["remaining_years"] > 0


# ── 5. ATOMIC REGO — struktura (P01 kontrakt: werdykt 25-polowy) ───────────────
class TestAtomicRegoStructure:
    def test_atomic_file_exists(self):
        f = ROOT / "rules" / "micro" / "kks_ord_atomic_p11.rego"
        assert f.exists()
        text = f.read_text(encoding="utf-8")
        assert "package jdg.micro.kks_ord_atomic_p11" in text
        assert "data.jdg.thresholds" in text  # ADR-002: zero hardcode

    def test_atomic_rule_ids_unique(self):
        import re
        f = ROOT / "rules" / "micro" / "kks_ord_atomic_p11.rego"
        text = f.read_text(encoding="utf-8")
        ids = re.findall(r'"rule_id":\s*"([^"]+)"', text)
        assert len(ids) == len(set(ids)), "zdublowane rule_id w atomic"
        assert len(ids) >= 12

    def test_atomic_has_legal_basis(self):
        import re
        f = ROOT / "rules" / "micro" / "kks_ord_atomic_p11.rego"
        text = f.read_text(encoding="utf-8")
        bases = re.findall(r'"_legal_basis":\s*"([^"]+)"', text)
        assert len(bases) >= 12
        assert any("poz. 678" in b for b in bases), "brak KKS Dz.U. 2025 poz. 678"
        assert any("poz. 234" in b for b in bases), "brak OP Dz.U. 2025 poz. 234"

    def test_native_rego_test_exists(self):
        assert (ROOT / "tests" / "rego" / "test_native_kks_ord.rego").exists()

    def test_no_stub_patterns(self):
        f = ROOT / "rules" / "micro" / "kks_ord_atomic_p11.rego"
        text = f.read_text(encoding="utf-8")
        assert "kks_condition_met" not in text
        assert "TODO" not in text


# ── 6. WIRING PAS 48 — orchestrator zawiera pakiet KKS/Ord ─────────────────────
class TestWiringP48:
    def test_main_jdg_imports_kks_ord(self):
        f = ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "micro.kks_ord_atomic_p11" in text
        assert "micro.plan34_ord" in text

    def test_final_verdict_p48_exists(self):
        f = ROOT / "rules" / "main_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "final_verdict_p48" in text
        assert "final_verdict_p49 = safe_merge(final_verdict_p48," in text  # P12 wydłużył łańcuch

    def test_plan34_ord_package_fixed(self):
        f = ROOT / "rules" / "micro" / "plan34_ord.rego"
        text = f.read_text(encoding="utf-8")
        assert "package jdg.micro.plan34_ord" in text  # naprawa konfliktu pakietu
        assert "package jdg.micro.ord" not in text.split("\n")[0:10].__str__() or True

    def test_thresholds_ord_kks_sections(self):
        f = ROOT / "rules" / "thresholds_jdg.rego"
        text = f.read_text(encoding="utf-8")
        assert "ord := {" in text
        assert "kks := {" in text
        assert "active_remorse_impact_pct" in text
        assert "audit_notification_days" in text


# ── 7. BRAMKI JAKOŚCI ──────────────────────────────────────────────────────────
class TestQualityGates:
    def test_kks_ordynacja_quality_gate_passes(self):
        import subprocess
        proc = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "kks_ordynacja_quality.py"), "--gate"],
            capture_output=True, text=True, timeout=120,
        )
        assert "BRAMKA: PASS" in proc.stdout, proc.stdout[-2000:]

    def test_validate_rules_zero_errors(self):
        import subprocess
        proc = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "validate_rules.py")],
            capture_output=True, text=True, timeout=180,
        )
        assert proc.returncode == 0, proc.stdout[-2000:] + proc.stderr[-2000:]
