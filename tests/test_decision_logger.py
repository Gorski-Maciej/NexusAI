"""
Testy dla Decision Logger — logowanie decyzji, trust score cache, korekty, statystyki.

Sprawdza:
  - Inicjalizację schematu (tworzenie tabel)
  - log_decision z pełnym kontekstem
  - record_user_correction
  - get_trust_score_trend
  - get_user_correction_stats
  - get_decisions_for_invoice
  - get_decision_summary
  - _compute_trend
"""

from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.append(str(ROOT))

from nexus_ai.services.decision_logger import DecisionLogger


# ---------------------------------------------------------------------------
# Mock DuckDB Manager
# ---------------------------------------------------------------------------

class FakeDuckDB:
    """Symuluje DuckDBManager dla testów DecisionLogger."""

    def __init__(self) -> None:
        self.executed: list[tuple[str, tuple | None]] = []
        self.tables: dict[str, list[dict]] = {
            "council_decisions": [],
            "trust_score_cache": [],
            "council_decisions_meta": [],
        }

    def execute(self, query: str, params: tuple | list | None = None) -> list:
        """Zapisuj executed queries i zwracaj odpowiednie dane."""
        self.executed.append((query, tuple(params) if params else None))

        # CREATE TABLE / INDEX
        if query.startswith("CREATE") or query.startswith("CREATE INDEX"):
            return []

        # INSERT
        if query.startswith("INSERT"):
            if "council_decisions" in query:
                self.tables["council_decisions"].append(params)
            elif "trust_score_cache" in query:
                self.tables["trust_score_cache"].append(params)
            elif "council_decisions_meta" in query:
                self.tables["council_decisions_meta"].append(params)
            return []

        # UPDATE
        if query.startswith("UPDATE"):
            return []

        # SELECT COUNT
        if "COUNT(*)" in query:
            if "user_correction IS NOT NULL" in query:
                corrected = sum(1 for d in self.tables["council_decisions"]
                                if d and len(d) > 10 and d[10] is not None)
                return [(corrected,)]
            if "decision_level" in query and "GROUP BY" in query:
                return []
            if "council_decisions" in query.lower():
                return [(len(self.tables["council_decisions"]),)]
            if "FROM trust_score_cache" in query and "AVG" not in query:
                return [(len(self.tables["trust_score_cache"]),)]
            return [(0,)]

        # SELECT AVG
        if "AVG(amount_gross)" in query:
            return [(0.0,)]

        # SELECT with WHERE invoice_id
        if "WHERE invoice_id" in query:
            invoice_id = params[0] if params else ""
            results = [
                d for d in self.tables["council_decisions"]
                if d and len(d) > 1 and d[1] == invoice_id
            ]
            return results or []

        # SELECT with WHERE contractor_nip
        if "WHERE contractor_nip" in query:
            # Symuluj dane trust score
            return [
                (0.85, 0.9, 0.8, 0.75, 0.7, "AUTO_POST", "2025-01-01"),
                (0.75, 0.8, 0.7, 0.7, 0.6, "SUGGEST", "2024-12-01"),
                (0.95, 0.95, 0.9, 0.85, 0.8, "AUTO_POST", "2024-11-01"),
            ]

        # SELECT with GROUP BY
        if "GROUP BY final_decision" in query and "user_correction" not in query:
            decs = [d[5] for d in self.tables["council_decisions"] if d]
            counts = {}
            for d in decs:
                counts[d] = counts.get(d, 0) + 1
            return [[k, v] for k, v in counts.items()]

        if "GROUP BY final_decision, user_correction" in query:
            corrected = [
                d for d in self.tables["council_decisions"]
                if d and len(d) > 10 and d[10] is not None
            ]
            return [[d[5], d[10], 1] for d in corrected]

        return []


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def fake_duckdb() -> FakeDuckDB:
    return FakeDuckDB()


@pytest.fixture
def logger(fake_duckdb: FakeDuckDB) -> DecisionLogger:
    return DecisionLogger(fake_duckdb)  # type: ignore[arg-type]


# ---------------------------------------------------------------------------
# Schema initialization
# ---------------------------------------------------------------------------

class TestSchema:
    """Testy inicjalizacji schematu bazy danych."""

    def test_ensure_schema_creates_tables(self, fake_duckdb: FakeDuckDB) -> None:
        DecisionLogger(fake_duckdb)  # type: ignore[arg-type]
        create_queries = [q for q, _ in fake_duckdb.executed if q.startswith("CREATE TABLE")]
        assert any("council_decisions" in q for q in create_queries)
        assert any("trust_score_cache" in q for q in create_queries)
        assert any("council_decisions_meta" in q for q in create_queries)

    def test_ensure_schema_creates_indexes(self, fake_duckdb: FakeDuckDB) -> None:
        DecisionLogger(fake_duckdb)  # type: ignore[arg-type]
        idx_queries = [q for q, _ in fake_duckdb.executed if q.startswith("CREATE INDEX")]
        assert len(idx_queries) >= 6  # 6 indeksów


# ---------------------------------------------------------------------------
# Logging decisions
# ---------------------------------------------------------------------------

class TestLogDecision:
    """Testy logowania decyzji."""

    SAMPLE_ALPHA = {"decision": "APPROVE", "confidence": 0.95, "reasoning": "OK"}
    SAMPLE_BETA = {"decision": "APPROVE", "confidence": 0.9, "reasoning": "OK"}
    SAMPLE_GAMMA = {"decision": "APPROVE", "confidence": 0.85, "reasoning": "OK"}
    SAMPLE_CONTEXT = {
        "invoice_id": "inv-001",
        "category": "usługi",
        "contractor_nip": "1234567890",
        "amount_gross": 1230.0,
    }

    @pytest.mark.anyio
    async def test_log_decision_inserts_record(
        self, logger: DecisionLogger, fake_duckdb: FakeDuckDB
    ) -> None:
        await logger.log_decision(
            invoice_id="inv-001",
            alpha_verdict=self.SAMPLE_ALPHA,
            beta_verdict=self.SAMPLE_BETA,
            gamma_verdict=self.SAMPLE_GAMMA,
            final_decision="AUTO_POST",
            trust_score=0.92,
            trust_components={"ai_confidence": 0.9, "vendor_reliability": 0.8},
            context=self.SAMPLE_CONTEXT,
            decision_level="LEVEL_1_AUTO",
            council_pattern="FULL_APPROVE",
            ple_stm_snapshot={"size": 5},
            ple_ltm_profile={"total_records": 10},
        )
        # Sprawdź że INSERT został wykonany
        inserts = [
            q for q, _ in fake_duckdb.executed
            if q.startswith("INSERT INTO council_decisions")
        ]
        assert len(inserts) == 1

    @pytest.mark.anyio
    async def test_log_decision_with_minimal_data(
        self, logger: DecisionLogger, fake_duckdb: FakeDuckDB
    ) -> None:
        """Logowanie decyzji bez opcjonalnych pól PLE."""
        await logger.log_decision(
            invoice_id="inv-002",
            alpha_verdict=self.SAMPLE_ALPHA,
            beta_verdict=self.SAMPLE_BETA,
            gamma_verdict=self.SAMPLE_GAMMA,
            final_decision="BLOCK",
            trust_score=0.3,
            trust_components={"ai_confidence": 0.3},
            context={"invoice_id": "inv-002"},
        )
        inserts = [
            q for q, _ in fake_duckdb.executed
            if q.startswith("INSERT INTO council_decisions")
        ]
        assert len(inserts) == 1


# ---------------------------------------------------------------------------
# User corrections
# ---------------------------------------------------------------------------

class TestUserCorrection:
    """Testy rejestrowania korekt użytkownika."""

    @pytest.mark.anyio
    async def test_record_correction(self, logger: DecisionLogger, fake_duckdb: FakeDuckDB) -> None:
        await logger.record_user_correction(
            invoice_id="inv-001",
            correction="APPROVED",
        )
        updates = [
            q for q, _ in fake_duckdb.executed
            if q.startswith("UPDATE")
        ]
        assert len(updates) == 2  # council_decisions + trust_score_cache


# ---------------------------------------------------------------------------
# Trust score trend
# ---------------------------------------------------------------------------

class TestTrustScoreTrend:
    """Testy analizy trendu trust score."""

    @pytest.mark.anyio
    async def test_get_trend_for_known_vendor(self, logger: DecisionLogger) -> None:
        trend = await logger.get_trust_score_trend("1234567890", days=30)
        assert trend["known"] is True
        assert trend["records"] == 3
        assert trend["avg_trust"] > 0
        assert "trend" in trend
        assert "component_averages" in trend
        assert "ai_confidence" in trend["component_averages"]

    @pytest.mark.anyio
    async def test_get_trend_for_unknown_vendor(self, logger: DecisionLogger) -> None:
        """Nieznany kontrahent → puste wyniki."""
        trend = await logger.get_trust_score_trend("0000000000", days=30)
        assert trend["known"] is False
        assert trend["records"] == 0


# ---------------------------------------------------------------------------
# Correction stats
# ---------------------------------------------------------------------------

class TestCorrectionStats:
    """Testy statystyk korekt użytkownika."""

    @pytest.mark.anyio
    async def test_get_stats_no_corrections(self, logger: DecisionLogger) -> None:
        stats = await logger.get_user_correction_stats()
        assert stats["total_decisions"] == 0
        assert stats["total_corrected"] == 0
        assert stats["correction_rate"] == 0.0

    @pytest.mark.anyio
    async def test_decision_breakdown(self, logger: DecisionLogger, fake_duckdb: FakeDuckDB) -> None:
        """Po dodaniu decyzji, breakdown powinien je uwzględniać."""
        # Symuluj dodanie decyzji
        fake_duckdb.tables["council_decisions"] = [
            (None, "inv-1", None, None, None, "AUTO_POST", None, None, None, None, None, None, None, None, None),
            (None, "inv-2", None, None, None, "BLOCK", None, None, None, None, None, None, None, None, None),
        ]
        stats = await logger.get_user_correction_stats()
        assert stats["total_decisions"] == 2
        assert "AUTO_POST" in stats["decision_breakdown"]


# ---------------------------------------------------------------------------
# Decision queries
# ---------------------------------------------------------------------------

class TestDecisionQueries:
    """Testy wyszukiwania decyzji."""

    @pytest.mark.anyio
    async def test_get_decisions_for_invoice_empty(self, logger: DecisionLogger) -> None:
        decisions = await logger.get_decisions_for_invoice("inv-nonexistent")
        assert decisions == []

    @pytest.mark.anyio
    async def test_get_decision_summary_empty(self, logger: DecisionLogger) -> None:
        summary = await logger.get_decision_summary(limit=10)
        assert summary == []


# ---------------------------------------------------------------------------
# Utility methods
# ---------------------------------------------------------------------------

class TestUtility:
    """Testy metod pomocniczych."""

    def test_compute_trend_up(self) -> None:
        """Trend wzrostowy — ostatnie 3 > starsze 3.

        scores[0] = most recent (DESC order from DB).
        _compute_trend: recent = scores[:3], older = scores[-3:].
        So recent=[0.9,0.85,0.8], older=[0.5,0.5,0.5] → diff=+0.35 → "up".
        """
        scores = [0.9, 0.85, 0.8, 0.5, 0.5, 0.5]
        trend = DecisionLogger._compute_trend(scores)
        assert trend == "up"

    def test_compute_trend_down(self) -> None:
        """Trend spadkowy.

        scores[0] = most recent (DESC order from DB).
        _compute_trend: recent = scores[:3], older = scores[-3:].
        So recent=[0.5,0.5,0.5], older=[0.8,0.85,0.9] → diff=-0.35 → "down".
        """
        scores = [0.5, 0.5, 0.5, 0.8, 0.85, 0.9]
        trend = DecisionLogger._compute_trend(scores)
        assert trend == "down"

    def test_compute_trend_stable(self) -> None:
        """Trend stabilny."""
        scores = [0.7, 0.71, 0.69, 0.7, 0.72, 0.7]
        trend = DecisionLogger._compute_trend(scores)
        assert trend == "stable"

    def test_compute_trend_insufficient_data(self) -> None:
        """Mniej niż 3 punkty → stable."""
        assert DecisionLogger._compute_trend([0.9]) == "stable"
        assert DecisionLogger._compute_trend([0.9, 0.8]) == "stable"
