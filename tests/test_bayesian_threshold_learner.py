"""
Testy jednostkowe dla BayesianThresholdLearner — Bayesowskiego Systemu Adaptacyjnych Progów.

Testuje:
  1. BetaPosterior — podstawowe właściwości rozkładu
  2. BetaPosterior.threshold_for() — adaptacyjne progi
  3. BetaPosterior.update() — aktualizacja po decyzji
  4. BayesianThresholdLearner — pełny workflow
  5. Hierarchia progów (NIP+kategoria, NIP+global, prior)
  6. Persistence SQLite
  7. _normal_ppf — aproksymacja kwantyla normalnego
  8. Integracja z AgentOrchestrator (mock)
"""

from __future__ import annotations

import math
import os
import tempfile
from pathlib import Path
from typing import Any

import pytest

from nexus_ai.services.bayesian_threshold_learner import (
    BetaPosterior,
    BayesianThresholdLearner,
    _normal_ppf,
)


# =========================================================================
# Fixtures
# =========================================================================

@pytest.fixture
def tmp_db() -> Path:
    """Tymczasowa ścieżka bazy SQLite."""
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        path = Path(f.name)
    yield path
    if path.exists():
        path.unlink()


@pytest.fixture
def learner(tmp_db: Path) -> BayesianThresholdLearner:
    """BayesianThresholdLearner z tymczasową bazą."""
    return BayesianThresholdLearner(db_path=tmp_db)


# =========================================================================
# 1. BetaPosterior — podstawowe właściwości
# =========================================================================

class TestBetaPosterior:
    """Testy podstawowych właściwości BetaPosterior."""

    def test_default_prior(self):
        """Domyślny prior Beta(2,2)."""
        bp = BetaPosterior()
        assert bp.alpha == 2.0
        assert bp.beta == 2.0
        assert bp.n == 4.0
        assert bp.mean == 0.5  # 2/(2+2)

    def test_mean_after_approvals(self):
        """Po 8 zatwierdzeniach mean → 0.8."""
        bp = BetaPosterior(alpha=8.0, beta=2.0)
        assert bp.mean == pytest.approx(0.8, abs=1e-6)

    def test_mean_after_rejections(self):
        """Po 8 odrzuceniach mean → 0.2."""
        bp = BetaPosterior(alpha=2.0, beta=8.0)
        assert bp.mean == pytest.approx(0.2, abs=1e-6)

    def test_uncertainty_decreases_with_data(self):
        """Niepewność maleje ze wzrostem liczby obserwacji."""
        low_data = BetaPosterior(alpha=3.0, beta=3.0)  # n=6
        high_data = BetaPosterior(alpha=30.0, beta=30.0)  # n=60
        assert high_data.uncertainty < low_data.uncertainty

    def test_uncertainty_zero(self):
        """Uncertainty nigdy nie jest ujemne."""
        bp = BetaPosterior(alpha=100.0, beta=100.0)
        assert bp.uncertainty >= 0.0

    def test_to_dict(self):
        """Serializacja do dict."""
        bp = BetaPosterior(alpha=5.0, beta=3.0)
        d = bp.to_dict()
        assert d["alpha"] == 5.0
        assert d["beta"] == 3.0
        assert d["mean"] == pytest.approx(5.0 / 8.0)
        assert d["n"] == 8.0

    def test_from_dict(self):
        """Deserializacja z dict."""
        bp = BetaPosterior.from_dict({"alpha": 7.0, "beta": 4.0})
        assert bp.alpha == 7.0
        assert bp.beta == 4.0
        assert bp.mean == pytest.approx(7.0 / 11.0)


# =========================================================================
# 2. BetaPosterior.threshold_for() — adaptacyjne progi
# =========================================================================

class TestBetaPosteriorThreshold:
    """Testy adaptacyjnych progów decyzyjnych."""

    def test_new_vendor_high_threshold(self):
        """Nowy kontrahent → wysoki próg auto_post (>0.90)."""
        bp = BetaPosterior()  # prior: α=2, β=2
        threshold = bp.threshold_for(0.95)
        assert threshold >= 0.85  # ostrożny próg dla nowego

    def test_trusted_vendor_lower_threshold(self):
        """Zaufany kontrahent → niższy próg auto_post."""
        new_bp = BetaPosterior(alpha=2.0, beta=2.0)
        trusted_bp = BetaPosterior(alpha=50.0, beta=2.0)

        new_threshold = new_bp.threshold_for(0.95)
        trusted_threshold = trusted_bp.threshold_for(0.95)

        assert trusted_threshold < new_threshold, (
            f"Trusted vendor should have LOWER threshold. "
            f"new={new_threshold}, trusted={trusted_threshold}"
        )

    def test_problematic_vendor_higher_threshold(self):
        """Kontrahent z odrzuceniami → wyższy próg."""
        clean_bp = BetaPosterior(alpha=50.0, beta=2.0)
        problematic_bp = BetaPosterior(alpha=30.0, beta=22.0)

        clean_ta = clean_bp.threshold_for(0.95)
        prob_ta = problematic_bp.threshold_for(0.95)

        assert prob_ta > clean_ta, (
            f"Problematic vendor should have HIGHER threshold. "
            f"clean={clean_ta}, problematic={prob_ta}"
        )

    def test_threshold_bounds(self):
        """Próg zawsze w zakresie [0.50, 0.98]."""
        bp = BetaPosterior(alpha=2.0, beta=2.0)
        for pctl in [0.50, 0.75, 0.95]:
            t = bp.threshold_for(pctl)
            assert 0.50 <= t <= 0.98, f"Threshold {t} out of bounds for pctl={pctl}"

    def test_different_percentiles(self):
        """Różne percentyle → różne progi."""
        bp = BetaPosterior(alpha=10.0, beta=5.0)
        t95 = bp.threshold_for(0.95)
        t75 = bp.threshold_for(0.75)
        t50 = bp.threshold_for(0.50)
        assert t95 >= t75 >= t50, (
            f"Higher percentile should give higher threshold. "
            f"t95={t95}, t75={t75}, t50={t50}"
        )

    def test_very_high_trust(self):
        """Bardzo wysoki trust → niski próg (~0.65)."""
        bp = BetaPosterior(alpha=100.0, beta=2.0)  # 98 zatwierdzeń + prior
        threshold = bp.threshold_for(0.95)
        assert threshold <= 0.80, (
            f"High trust vendor should have low threshold, got {threshold}"
        )


# =========================================================================
# 3. BetaPosterior.update() — aktualizacja
# =========================================================================

class TestBetaPosteriorUpdate:
    """Testy aktualizacji posteriora."""

    def test_update_approved(self):
        """Zatwierdzenie → alpha wzrasta."""
        bp = BetaPosterior(alpha=5.0, beta=3.0)
        bp.update(approved=True)
        assert bp.alpha == 6.0
        assert bp.beta == 3.0

    def test_update_rejected(self):
        """Odrzucenie → beta wzrasta."""
        bp = BetaPosterior(alpha=5.0, beta=3.0)
        bp.update(approved=False)
        assert bp.alpha == 5.0
        assert bp.beta == 4.0

    def test_update_with_weight(self):
        """Ważona aktualizacja."""
        bp = BetaPosterior(alpha=5.0, beta=3.0)
        bp.update(approved=True, weight=2.0)
        assert bp.alpha == 7.0
        assert bp.beta == 3.0

    def test_sequential_updates(self):
        """Sekwencyjne aktualizacje."""
        bp = BetaPosterior()
        # 3 zatwierdzenia, 1 odrzucenie
        for _ in range(3):
            bp.update(approved=True)
        bp.update(approved=False)
        assert bp.alpha == 5.0  # 2 + 3
        assert bp.beta == 3.0  # 2 + 1
        assert bp.mean == pytest.approx(5.0 / 8.0)


# =========================================================================
# 4. BayesianThresholdLearner — pełny workflow
# =========================================================================

class TestBayesianThresholdLearner:
    """Testy integracyjne BayesianThresholdLearner."""

    def test_get_thresholds_new_vendor(self, learner):
        """Nowy kontrahent → progi z priora."""
        thresholds = learner.get_thresholds(
            contractor_nip="1234567890",
            category="media",
        )
        assert "auto_post" in thresholds
        assert "suggest" in thresholds
        assert "ask_user" in thresholds
        assert thresholds["auto_post"] >= thresholds["suggest"]
        assert thresholds["suggest"] >= thresholds["ask_user"]

    def test_record_and_get(self, learner):
        """Po zatwierdzeniach → niższe progi."""
        # 10 zatwierdzeń dla tego kontrahenta
        for _ in range(10):
            learner.record_decision(
                contractor_nip="1112223344",
                category="czynsz",
                approved=True,
                amount_gross=2000.0,
            )

        thresholds = learner.get_thresholds(
            contractor_nip="1112223344",
            category="czynsz",
        )
        assert thresholds["auto_post"] < 0.90, (
            f"After 10 approvals, auto_post should be <0.90, got {thresholds['auto_post']}"
        )

    def test_rejected_vendor_higher_threshold(self, learner):
        """Odrzucenia → wyższe progi niż dla zatwierdzonego."""
        # 10 zatwierdzeń dla kontrahenta A
        for _ in range(10):
            learner.record_decision(
                contractor_nip="APPROVED_NIP",
                category="media",
                approved=True,
            )

        # 5 zatwierdzeń + 5 odrzuceń dla kontrahenta B
        for _ in range(5):
            learner.record_decision(
                contractor_nip="MIXED_NIP",
                category="media",
                approved=True,
            )
            learner.record_decision(
                contractor_nip="MIXED_NIP",
                category="media",
                approved=False,
            )

        t_approved = learner.get_thresholds(
            contractor_nip="APPROVED_NIP", category="media",
        )
        t_mixed = learner.get_thresholds(
            contractor_nip="MIXED_NIP", category="media",
        )

        assert t_approved["auto_post"] < t_mixed["auto_post"], (
            f"Approved vendor should have LOWER auto_post. "
            f"approved={t_approved['auto_post']}, mixed={t_mixed['auto_post']}"
        )

    def test_hierarchy_specific_over_global(self, learner):
        """Konkretna kategoria → inne progi niż globalne."""
        # 10 zatwierdzeń dla konkretnej kategorii
        for _ in range(10):
            learner.record_decision(
                contractor_nip="NIP_123",
                category="paliwo",
                approved=True,
            )

        # 0 zatwierdzeń dla globalnego tego samego NIP
        specific = learner.get_thresholds(
            contractor_nip="NIP_123", category="paliwo",
        )
        global_t = learner.get_thresholds(
            contractor_nip="NIP_123", category="__global__",
        )

        # Specific ma dane, globalny nie → specific powinien mieć niższy próg
        assert specific["auto_post"] <= global_t["auto_post"] + 0.01, (
            "Category-specific with data should have ≈ same or lower threshold"
        )

    def test_amount_adjustment(self, learner):
        """Wyższa kwota → wyższy próg."""
        low_amount = learner.get_thresholds(
            contractor_nip="TEST_NIP",
            category="media",
            amount_gross=100.0,
        )
        high_amount = learner.get_thresholds(
            contractor_nip="TEST_NIP",
            category="media",
            amount_gross=100000.0,
        )
        assert high_amount["auto_post"] >= low_amount["auto_post"]

    def test_get_vendor_summary_new(self, learner):
        """Nieznany kontrahent → known=False."""
        summary = learner.get_vendor_summary("UNKNOWN_NIP")
        assert summary["known"] is False

    def test_get_vendor_summary_known(self, learner):
        """Znany kontrahent → poprawne statystyki."""
        for _ in range(5):
            learner.record_decision(
                contractor_nip="KNOWN_NIP",
                category="media",
                approved=True,
            )

        summary = learner.get_vendor_summary("KNOWN_NIP")
        assert summary["known"] is True
        assert summary["total_decisions"] >= 5
        assert summary["approval_rate"] > 0.5
        assert "thresholds" in summary
        assert "category_breakdown" in summary

    def test_get_all_vendors_summary(self, learner):
        """Lista wszystkich kontrahentów."""
        learner.record_decision(contractor_nip="NIP_A", approved=True)
        learner.record_decision(contractor_nip="NIP_B", approved=False)

        vendors = learner.get_all_vendors_summary(min_decisions=1)
        nips = [v["contractor_nip"] for v in vendors]
        assert "NIP_A" in nips
        assert "NIP_B" in nips

    def test_get_stats(self, learner):
        """Globalne statystyki."""
        learner.record_decision(contractor_nip="NIP_X", approved=True)
        stats = learner.get_stats()
        assert stats["total_vendors"] >= 1
        assert stats["learner_type"] == "Bayesian Beta Posterior"

    def test_record_auto_decision(self, learner):
        """Auto-decyzje mają wpływ, ale mniejszy."""
        # 10 auto-zatwierdzeń
        for _ in range(10):
            learner.record_auto_decision(
                contractor_nip="AUTO_NIP",
                approved=True,
            )

        # 10 user-zatwierdzeń (te same dane)
        for _ in range(10):
            learner.record_decision(
                contractor_nip="USER_NIP",
                approved=True,
            )

        # User ma więcej "wagi" na decyzję
        auto_threshold = learner.get_thresholds(
            contractor_nip="AUTO_NIP", amount_gross=0,
        )["auto_post"]
        user_threshold = learner.get_thresholds(
            contractor_nip="USER_NIP", amount_gross=0,
        )["auto_post"]

        # User ma niższy próg (więcej wagi)
        assert user_threshold <= auto_threshold + 0.05


# =========================================================================
# 5. Hierarchia progów
# =========================================================================

class TestThresholdHierarchy:
    """Testy hierarchii: konkretny > globalny > prior."""

    def test_specific_category_inherits_from_global(self, learner):
        """Jeśli nie ma danych dla kategorii, użyj globalnego rozkładu."""
        # Dodaj globalne dane dla kontrahenta
        for _ in range(5):
            learner.record_decision(
                contractor_nip="HIERARCHY_NIP",
                category="__global__",
                approved=True,
            )

        # Zapytaj o kategorię bez danych → powinna użyć globalnego
        thresholds = learner.get_thresholds(
            contractor_nip="HIERARCHY_NIP",
            category="new_category",
        )

        global_t = learner.get_thresholds(
            contractor_nip="HIERARCHY_NIP",
            category="__global__",
        )

        assert thresholds["auto_post"] == global_t["auto_post"], (
            "Should use global thresholds when category has no data"
        )

    def test_clear_all(self, learner):
        """Wyczyść wszystko."""
        learner.record_decision(contractor_nip="NIP", approved=True)
        assert learner.get_stats()["total_vendors"] >= 1
        learner.clear_all()
        assert learner.get_stats()["total_vendors"] == 0


# =========================================================================
# 6. _normal_ppf — aproksymacja kwantyla normalnego
# =========================================================================

class TestNormalPPF:
    """Testy aproksymacji odwrotności CDF rozkładu normalnego."""

    def test_median(self):
        """p=0.5 → z≈0."""
        z = _normal_ppf(0.5)
        assert abs(z) < 0.01, f"Median should be near 0, got {z}"

    def test_95_percentile(self):
        """p=0.95 → z≈1.645."""
        z = _normal_ppf(0.95)
        assert abs(z - 1.644854) < 0.001, f"95th percentile should be ~1.645, got {z}"

    def test_75_percentile(self):
        """p=0.75 → z≈0.675."""
        z = _normal_ppf(0.75)
        assert abs(z - 0.674490) < 0.001, f"75th percentile should be ~0.674, got {z}"

    def test_symmetry(self):
        """p i 1-p dają przeciwne wartości."""
        z1 = _normal_ppf(0.10)
        z2 = _normal_ppf(0.90)
        assert abs(z1 + z2) < 0.01, f"Should be symmetric: {z1} vs {-z2}"

    def test_1_percentile(self):
        """p=0.01 → z≈-2.33."""
        z = _normal_ppf(0.01)
        assert z < 0 and z > -3.0, f"1st percentile should be negative, got {z}"

    def test_99_percentile(self):
        """p=0.99 → z≈2.33."""
        z = _normal_ppf(0.99)
        assert z > 2.0, f"99th percentile should be >2, got {z}"

    def test_invalid_p(self):
        """p poza zakresem → błąd."""
        with pytest.raises(ValueError):
            _normal_ppf(0.0)
        with pytest.raises(ValueError):
            _normal_ppf(1.0)
        with pytest.raises(ValueError):
            _normal_ppf(-0.1)
        with pytest.raises(ValueError):
            _normal_ppf(1.1)


# =========================================================================
# 7. Integracja z AgentOrchestrator (test mockowany)
# =========================================================================

class TestAgentOrchestratorIntegration:
    """Testy integracji BayesianThresholdLearner z AgentOrchestrator."""

    def test_mock_integration(self):
        """Symulacja przepływu: nagraj decyzje, pobierz progi."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db_path = Path(f.name)

        try:
            learner = BayesianThresholdLearner(db_path=db_path)

            # Symuluj 15 zatwierdzonych faktur dla kontrahenta
            for _ in range(15):
                learner.record_decision(
                    contractor_nip="REGULAR_NIP",
                    category="media",
                    approved=True,
                    amount_gross=500.0,
                )

            # Symuluj 3 zatwierdzenia + 2 odrzucenia dla innego
            for _ in range(3):
                learner.record_decision(
                    contractor_nip="RISKY_NIP",
                    category="it_services",
                    approved=True,
                    amount_gross=15000.0,
                )
            for _ in range(2):
                learner.record_decision(
                    contractor_nip="RISKY_NIP",
                    category="it_services",
                    approved=False,
                    amount_gross=15000.0,
                )

            # Pobierz progi
            regular = learner.get_thresholds(
                contractor_nip="REGULAR_NIP",
                category="media",
                amount_gross=500.0,
            )
            risky = learner.get_thresholds(
                contractor_nip="RISKY_NIP",
                category="it_services",
                amount_gross=15000.0,
            )

            # Regular should have much lower threshold (bezpieczny)
            # Risky should have higher threshold (ryzykowny + wysoka kwota)
            assert regular["auto_post"] < risky["auto_post"], (
                f"Regular vendor should have LOWER auto_post threshold. "
                f"regular={regular['auto_post']}, risky={risky['auto_post']}"
            )

            # Sprawdź że auto_post >= suggest >= ask_user
            for t in [regular, risky]:
                assert t["auto_post"] >= t["suggest"]
                assert t["suggest"] >= t["ask_user"]

        finally:
            if db_path.exists():
                db_path.unlink()

    def test_real_world_scenario(self):
        """Realistyczny scenariusz z życia."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
            db_path = Path(f.name)

        try:
            learner = BayesianThresholdLearner(db_path=db_path)

            # Kontrahent A: stały dostawca paliwa, 30 faktur, 1 odrzucenie
            for _ in range(29):
                learner.record_decision(
                    contractor_nip="STATION_NIP",
                    category="paliwo",
                    approved=True,
                    amount_gross=800.0,
                )
            learner.record_decision(
                contractor_nip="STATION_NIP",
                category="paliwo",
                approved=False,
                amount_gross=800.0,
            )

            # Kontrahent B: nowy dostawca IT, 2 faktury, 1 odrzucenie
            learner.record_decision(
                contractor_nip="NEW_IT_NIP",
                category="it_services",
                approved=True,
                amount_gross=25000.0,
            )
            learner.record_decision(
                contractor_nip="NEW_IT_NIP",
                category="it_services",
                approved=False,
                amount_gross=25000.0,
            )

            # Kontrahent C: nowy, niska kwota
            learner.record_decision(
                contractor_nip="NEW_SMALL_NIP",
                category="materialy",
                approved=True,
                amount_gross=150.0,
            )

            # Pobierz progi
            station = learner.get_thresholds(
                contractor_nip="STATION_NIP",
                category="paliwo",
                amount_gross=800.0,
            )
            new_it = learner.get_thresholds(
                contractor_nip="NEW_IT_NIP",
                category="it_services",
                amount_gross=25000.0,
            )
            new_small = learner.get_thresholds(
                contractor_nip="NEW_SMALL_NIP",
                category="materialy",
                amount_gross=150.0,
            )

            # Weryfikacja oczekiwań:
            # Stacja paliw → niski próg auto_post (zaufany, powtarzalny)
            # Nowy IT → wysoki próg (ryzykowna kategoria, mało danych, wysoka kwota)
            # Nowy mały → średni próg (mało danych, ale niska kwota)

            assert station["auto_post"] < 0.85, (
                f"Trusted station should have auto_post < 0.85, got {station['auto_post']}"
            )

            assert new_it["auto_post"] > station["auto_post"], (
                f"New IT should have HIGHER auto_post than trusted station. "
                f"station={station['auto_post']}, new_it={new_it['auto_post']}"
            )

            # new_small powinien mieć niższy próg niż new_it (kwota!)
            assert new_small["auto_post"] <= new_it["auto_post"] + 0.01, (
                "Small amount vendor should have approximately same or lower threshold"
            )

            # Statystyki
            stats = learner.get_stats()
            assert stats["total_vendors"] == 3
            assert stats["total_decisions"] == 34

        finally:
            if db_path.exists():
                db_path.unlink()
