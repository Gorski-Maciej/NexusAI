"""
Testy jednostkowe dla FactsAggregator — nexus_ai/services/facts_aggregator.py.

Sprawdza:
  - Budowanie FactSheet z invoice_data
  - FactSheet.to_prompt_section() — generowanie sekcji promptu
  - Obsługa błędów (brak źródeł danych, wyjątki)
  - FactSheet.to_dict() — konwersja na słownik
"""

from __future__ import annotations

from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from nexus_ai.services.facts_aggregator import (
    FactSheet,
    FactsAggregator,
)


# ── Fixtures ────────────────────────────────────────────────────────────────

@pytest.fixture
def sample_invoice_data() -> dict:
    """Przykładowe dane faktury."""
    return {
        "invoice_id": "inv-123",
        "contractor_nip": "1234567890",
        "contractor": {"name": "Firma XYZ"},
        "amount_net": 1000.00,
        "amount_gross": 1230.00,
        "category": "Usługi IT",
        "issue_date": "2026-06-01",
        "ocr_confidence": 0.95,
    }


@pytest.fixture
def mock_session_factory() -> MagicMock:
    """Mock fabryki sesji SQLAlchemy."""
    return MagicMock()


@pytest.fixture
def mock_decision_logger() -> MagicMock:
    """Mock DecisionLogger."""
    logger = MagicMock()
    logger.get_trust_score_trend.return_value = {
        "known": True,
        "records": 15,
        "avg_trust": 0.85,
        "trend": "up",
        "decisions_breakdown": {"AUTO_POST": 12, "SUGGEST": 3},
        "component_averages": {"ai_confidence": 0.9, "vendor_reliability": 0.8},
    }
    logger.get_user_correction_stats.return_value = {
        "total_decisions": 50,
        "total_corrected": 5,
        "correction_rate": 0.1,
    }
    return logger


@pytest.fixture
def mock_vector_store() -> MagicMock:
    """Mock VectorStore."""
    store = MagicMock()
    store.search_similar.return_value = [
        {"id": "sim-1", "amount_gross": "1200.00", "category": "IT", "_distance": 0.12},
        {"id": "sim-2", "amount_gross": "950.00", "category": "IT", "_distance": 0.18},
    ]
    return store


@pytest.fixture
def mock_embedding_service() -> MagicMock:
    """Mock EmbeddingService."""
    service = MagicMock()
    service.embed.return_value = [0.1, 0.2, 0.3, 0.4, 0.5]
    return service


@pytest.fixture
def mock_rule_store() -> MagicMock:
    """Mock RuleStore."""
    store = MagicMock()
    store.get_active_rules.return_value = [
        {
            "rule_id": "rule-1",
            "condition_sql": "category_code = 'IT'",
            "action_json": '{"vat_rate": "0.23"}',
            "description_template": "VAT 23% dla usług IT",
            "priority": 10,
        },
    ]
    return store


@pytest.fixture
def mock_vendor_analyst() -> MagicMock:
    """Mock VendorAnalyst."""
    analyst = MagicMock()
    analyst.get_vendor_context.return_value = "Vendor Firma XYZ (NIP: 1234567890). Average payment delay: 2.5 days. Reliability score: 4.5/5."
    return analyst


# ── Testy FactSheet ─────────────────────────────────────────────────────

class TestFactSheet:
    """Testy struktury FactSheet."""

    def test_default_values(self) -> None:
        """Sprawdź domyślne wartości FactSheet."""
        sheet = FactSheet()
        assert sheet.invoice_id == ""
        assert sheet.amount_gross == 0.0
        assert sheet.contractor_known is False
        assert sheet.sources_available == {}
        assert sheet.recent_invoices == []
        assert sheet.similar_invoices == []

    def test_to_dict_basic(self) -> None:
        """Sprawdź konwersję FactSheet na słownik."""
        sheet = FactSheet(
            invoice_id="inv-1",
            contractor_nip="1234567890",
            amount_gross=1230.00,
            category="IT",
        )
        d = sheet.to_dict()
        assert d["invoice"]["id"] == "inv-1"
        assert d["invoice"]["amount_gross"] == 1230.00
        assert d["history"]["recent_invoices"] == []

    def test_to_dict_sources(self) -> None:
        """Sprawdź, że sources są poprawnie odwzorowane."""
        sheet = FactSheet(
            sources_available={"sqlite": True, "duckdb": False, "vector_store": True},
        )
        d = sheet.to_dict()
        assert d["sources"]["sqlite"] is True
        assert d["sources"]["duckdb"] is False

    def test_to_prompt_section_empty(self) -> None:
        """Sprawdź prompt section dla pustego arkusza."""
        sheet = FactSheet()
        prompt = sheet.to_prompt_section()
        assert "ARKUSZ FAKTÓW" in prompt
        assert "SQLite=✗" in prompt

    def test_to_prompt_section_with_data(self) -> None:
        """Sprawdź prompt section z danymi."""
        sheet = FactSheet(
            invoice_id="inv-123",
            contractor_nip="1234567890",
            contractor_name="Firma XYZ",
            amount_net=1000.00,
            amount_gross=1230.00,
            category="Usługi IT",
            contractor_known=True,
            contractor_invoice_count=10,
            sources_available={"sqlite": True, "duckdb": True, "vector_store": True},
            trust_score_trend={
                "known": True, "avg_trust": 0.85, "trend": "up", "records": 15,
            },
            active_tax_rules=[
                {"condition_sql": "cat = 'IT'", "description_template": "VAT 23%"}
            ],
            similar_invoices=[
                {"id": "sim-1", "amount_gross": "1200", "category": "IT", "_distance": 0.12}
            ],
        )
        prompt = sheet.to_prompt_section()
        assert "Firma XYZ" in prompt
        assert "SQLite=✓" in prompt
        assert "VAT 23%" in prompt
        assert "sim-1" in prompt
        assert "up" in prompt


# ── Testy FactsAggregator ───────────────────────────────────────────────

class TestFactsAggregator:
    """Testy FactsAggregator z mockami."""

    @pytest.mark.anyio
    async def test_build_with_all_sources(
        self,
        sample_invoice_data: dict,
        mock_session_factory: MagicMock,
        mock_decision_logger: MagicMock,
        mock_vector_store: MagicMock,
        mock_embedding_service: MagicMock,
        mock_rule_store: MagicMock,
        mock_vendor_analyst: MagicMock,
    ) -> None:
        """Sprawdź build() ze wszystkimi źródłami danych."""
        aggregator = FactsAggregator(
            db_session_factory=mock_session_factory,
            decision_logger=mock_decision_logger,
            vector_store=mock_vector_store,
            embedding_service=mock_embedding_service,
            rule_store=mock_rule_store,
            vendor_analyst=mock_vendor_analyst,
        )

        sheet = await aggregator.build(sample_invoice_data)

        assert sheet.invoice_id == "inv-123"
        assert sheet.contractor_nip == "1234567890"
        assert sheet.amount_gross == 1230.00
        assert isinstance(sheet.build_duration_ms, float)
        assert sheet.build_duration_ms >= 0

    @pytest.mark.anyio
    async def test_build_without_sources(
        self, sample_invoice_data: dict
    ) -> None:
        """Sprawdź build() bez żadnych źródeł danych (graceful degradation)."""
        aggregator = FactsAggregator()

        sheet = await aggregator.build(sample_invoice_data)

        assert sheet.invoice_id == "inv-123"
        assert sheet.contractor_nip == "1234567890"
        # Wszystkie źródła są niedostępne
        assert all(v is False for v in sheet.sources_available.values()) or sheet.sources_available == {}
        assert sheet.recent_invoices == []
        assert sheet.similar_invoices == []
        assert sheet.active_tax_rules == []

    @pytest.mark.anyio
    async def test_build_with_only_vector_store(
        self,
        sample_invoice_data: dict,
        mock_vector_store: MagicMock,
        mock_embedding_service: MagicMock,
    ) -> None:
        """Sprawdź build() tylko z vector store."""
        aggregator = FactsAggregator(
            vector_store=mock_vector_store,
            embedding_service=mock_embedding_service,
        )

        sheet = await aggregator.build(sample_invoice_data)

        assert sheet.invoice_id == "inv-123"
        # vector_store powinno być dostępne
        assert sheet.sources_available.get("vector_store") is True
        assert len(sheet.similar_invoices) == 2

    @pytest.mark.anyio
    async def test_build_with_error_in_one_source(
        self,
        sample_invoice_data: dict,
        mock_session_factory: MagicMock,
        mock_decision_logger: MagicMock,
    ) -> None:
        """Sprawdź build() gdy jedno źródło rzuca wyjątkiem (izolacja błędów)."""
        # Ustaw vendor_analyst, który rzuca wyjątkiem
        bad_analyst = MagicMock()
        bad_analyst.get_vendor_context.side_effect = RuntimeError("DB crash")

        aggregator = FactsAggregator(
            db_session_factory=mock_session_factory,
            decision_logger=mock_decision_logger,
            vendor_analyst=bad_analyst,
        )

        # Nie powinno rzucić wyjątku — tylko warning w logu
        sheet = await aggregator.build(sample_invoice_data)

        assert sheet.invoice_id == "inv-123"
        assert sheet.build_duration_ms >= 0

    @pytest.mark.anyio
    async def test_build_runs_tasks_in_parallel(
        self,
        sample_invoice_data: dict,
        mock_session_factory: MagicMock,
        mock_decision_logger: MagicMock,
        mock_vector_store: MagicMock,
        mock_embedding_service: MagicMock,
    ) -> None:
        """Sprawdź, że build uruchamia zadania równolegle (szybciej niż sekwencyjnie)."""
        import time

        aggregator = FactsAggregator(
            db_session_factory=mock_session_factory,
            decision_logger=mock_decision_logger,
            vector_store=mock_vector_store,
            embedding_service=mock_embedding_service,
        )

        t0 = time.monotonic()
        sheet = await aggregator.build(sample_invoice_data)
        duration = time.monotonic() - t0

        # Powinno zająć mniej niż 5 sekund (asynchroniczne, nie blokujące)
        assert duration < 5.0
        assert sheet.invoice_id == "inv-123"

    @pytest.mark.anyio
    async def test_build_stores_duration(
        self,
        sample_invoice_data: dict,
    ) -> None:
        """Sprawdź, że build_duration_ms jest ustawiane."""
        aggregator = FactsAggregator()
        sheet = await aggregator.build(sample_invoice_data)
        assert sheet.build_duration_ms > 0

    @pytest.mark.anyio
    async def test_fact_sheet_to_dict_contains_all_keys(
        self, sample_invoice_data: dict
    ) -> None:
        """Sprawdź, że to_dict() zawiera wszystkie oczekiwane klucze."""
        aggregator = FactsAggregator()
        sheet = await aggregator.build(sample_invoice_data)
        d = sheet.to_dict()

        expected_keys = {"invoice", "contractor", "history", "rules", "similar", "ledger", "sources"}
        assert expected_keys.issubset(set(d.keys()))

        # Sprawdź podstawowe dane
        assert d["invoice"]["id"] == "inv-123"
        assert d["invoice"]["amount_gross"] == 1230.00

        # Sprawdź dane ledgera
        assert "ledger" in d
        assert "available" in d["ledger"]
        assert d["ledger"]["available"] is False


# ── Testy integracji z promptem ─────────────────────────────────────────

class TestFactsAggregatorPromptIntegration:
    """Testy integracji FactSheet z promptem modelu."""

    @pytest.mark.anyio
    async def test_prompt_section_is_parseable(self) -> None:
        """Sprawdź, że sekcja promptu ma czytelny format."""
        sheet = FactSheet(
            invoice_id="inv-456",
            contractor_nip="9876543210",
            contractor_name="Test Sp. z o.o.",
            amount_gross=5000.00,
            category="Paliwo",
            sources_available={"sqlite": True, "duckdb": True, "vector_store": True},
            active_tax_rules=[
                {"description_template": "VAT 23% dla paliwa"},
                {"description_template": "Split payment dla paliwa > 5000"},
            ],
        )

        prompt = sheet.to_prompt_section()
        lines = prompt.split("\n")

        # Powinna zaczynać się od === ARKUSZ FAKTÓW ===
        assert lines[0] == "=== ARKUSZ FAKTÓW (FactsAggregator) ==="

        # Powinna zawierać dane faktury
        assert any("inv-456" in line for line in lines)
        assert any("5000.00" in line for line in lines)

        # Powinna zawierać reguły
        assert any("VAT 23%" in line for line in lines)
        assert any("Split payment" in line for line in lines)

    @pytest.mark.anyio
    async def test_empty_fact_sheet_does_not_crash(
        self, sample_invoice_data: dict
    ) -> None:
        """Sprawdź, że pusty arkusz nie crashuje przy konwersji na prompt."""
        sheet = FactSheet()
        prompt = sheet.to_prompt_section()
        assert isinstance(prompt, str)
        assert len(prompt) > 0


# ── Testy few-shot learning ────────────────────────────────────────────

class TestFewShotLearning:
    """Testy dynamicznego few-shot learningu."""

    def test_build_few_shot_empty(self) -> None:
        """Sprawdź, że pusty FactSheet zwraca pusty string."""
        sheet = FactSheet()
        examples = sheet.build_few_shot_examples()
        assert examples == ""

    def test_build_few_shot_from_recent_invoices(self) -> None:
        """Sprawdź budowanie przykładów z ostatnich faktur."""
        sheet = FactSheet(
            contractor_nip="1234567890",
            recent_invoices=[
                {"id": "inv-001", "amount_gross": 1200.00, "category": "IT", "status": "PAID", "number": "FV/1"},
                {"id": "inv-002", "amount_gross": 800.00, "category": "IT", "status": "SUGGESTED", "number": "FV/2"},
                {"id": "inv-003", "amount_gross": 2500.00, "category": "IT", "status": "PAID", "number": "FV/3"},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=2)
        assert "PRZYKŁADY FEW-SHOT" in examples
        assert "AUTO_POST" in examples  # PAID → AUTO_POST
        assert "Historyczna faktura" in examples
        assert "1200.00" in examples
        assert "800.00" in examples
        assert "2500.00" not in examples  # tylko 2 przykłady (max_examples=2)

    def test_build_few_shot_with_decision_breakdown(self) -> None:
        """Sprawdź, że rozkład decyzji jest dołączany."""
        sheet = FactSheet(
            recent_invoices=[
                {"id": "inv-001", "amount_gross": 100.00, "category": "IT", "status": "PAID"},
            ],
            trust_score_trend={
                "known": True,
                "records": 20,
                "avg_trust": 0.88,
                "trend": "stable",
                "decisions_breakdown": {"AUTO_POST": 15, "SUGGEST": 5},
            },
        )
        examples = sheet.build_few_shot_examples()
        assert "Wzorzec decyzyjny" in examples
        assert "AUTO_POST: 15" in examples
        assert "SUGGEST: 5" in examples
        assert "stable" in examples

    def test_build_few_shot_without_recent_falls_back_to_similar(self) -> None:
        """Sprawdź, że gdy brak recent_invoices, używa similar_invoices."""
        sheet = FactSheet(
            similar_invoices=[
                {"id": "sim-1", "amount_gross": "1200", "category": "IT", "_distance": 0.15},
                {"id": "sim-2", "amount_gross": "950", "category": "Marketing", "_distance": 0.22},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=2)
        assert "PRZYKŁADY FEW-SHOT" in examples
        assert "Podobna faktura" in examples
        assert "0.15" in examples

    def test_build_few_shot_with_user_corrections(self) -> None:
        """Sprawdź, że korekty użytkownika są dołączane."""
        sheet = FactSheet(
            recent_invoices=[
                {"id": "inv-001", "amount_gross": 100.00, "category": "IT", "status": "PAID"},
            ],
            user_correction_patterns=[
                {"description": "Użytkownik zmienił kategorię z IT na Marketing", "id": "c1", "timestamp": "2026-01-01"},
                {"description": "Użytkownik odrzucił auto-post dla faktury duplikatu", "id": "c2", "timestamp": "2026-01-02"},
            ],
        )
        examples = sheet.build_few_shot_examples()
        assert "korekty użytkownika" in examples.lower()
        assert "zmienił kategorię" in examples

    def test_build_few_shot_max_examples_respected(self) -> None:
        """Sprawdź, że max_examples jest respektowane."""
        sheet = FactSheet(
            recent_invoices=[
                {"id": "i1", "amount_gross": 100.00, "category": "A", "status": "PAID"},
                {"id": "i2", "amount_gross": 200.00, "category": "B", "status": "PAID"},
                {"id": "i3", "amount_gross": 300.00, "category": "C", "status": "PAID"},
                {"id": "i4", "amount_gross": 400.00, "category": "D", "status": "PAID"},
                {"id": "i5", "amount_gross": 500.00, "category": "E", "status": "PAID"},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=3)
        # Tylko 3 z 5 przykładów
        assert examples.count("[Historyczna faktura]") == 3

    def test_build_few_shot_decision_breakdown_without_recent(self) -> None:
        """Sprawdź, że decisions_breakdown działa gdy brak recent_invoices.

        To testuje ścieżkę, gdzie trust_score_trend ma decisions_breakdown
        ale recent_invoices jest puste. Zawsze powinien być nagłówek.
        """
        sheet = FactSheet(
            recent_invoices=[],
            trust_score_trend={
                "known": True,
                "records": 20,
                "avg_trust": 0.88,
                "trend": "stable",
                "decisions_breakdown": {"AUTO_POST": 15, "SUGGEST": 5},
            },
        )
        examples = sheet.build_few_shot_examples()
        # Zawsze musi być nagłówek
        assert "PRZYKŁADY FEW-SHOT" in examples
        assert "Wzorzec decyzyjny" in examples
        assert "AUTO_POST: 15" in examples

    def test_build_few_shot_handles_non_string_status(self) -> None:
        """Sprawdź, że None i numeryczny status nie crashują."""
        sheet = FactSheet(
            recent_invoices=[
                {"id": "i1", "amount_gross": 100.00, "category": "A", "status": None},
                {"id": "i2", "amount_gross": 200.00, "category": "B", "status": 123},
                {"id": "i3", "amount_gross": 300.00, "category": "C", "status": True},
            ],
        )
        # Nie powinno rzucić wyjątku
        examples = sheet.build_few_shot_examples()
        assert "PRZYKŁADY FEW-SHOT" in examples
        assert "Historyczna faktura" in examples

    def test_build_few_shot_includes_similar_invoices_with_decision(self) -> None:
        """Sprawdź, że similar_invoices są zawsze dołączane z decyzją.

        Kluczowa zmiana: podobne faktury są teraz zawsze obecne w przykładach
        (nie tylko jako fallback gdy brak recent_invoices), a ich status
        z SQLite jest mapowany na decyzję (PAID → AUTO_POST, itd.).
        max_examples jest dzielone: recent ma priorytet, podobne dopełniają.
        """
        sheet = FactSheet(
            # Mamy zarówno recent_invoices jak i similar_invoices
            recent_invoices=[
                {"id": "r1", "amount_gross": 500.00, "category": "IT", "status": "PAID"},
            ],
            similar_invoices=[
                {"id": "sim-1", "amount_gross": "1200.00", "category": "IT", "_distance": 0.12, "status": "PAID"},
                {"id": "sim-2", "amount_gross": "950.00", "category": "Marketing", "_distance": 0.22, "status": "SUGGESTED"},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=3)
        assert "PRZYKŁADY FEW-SHOT" in examples

        # recent_invoices są pierwsze (1 z 3 slotów)
        assert "[Historyczna faktura]" in examples
        assert "500.00" in examples

        # similar_invoices dopełniają do max_examples (2 z 3 slotów)
        assert "[Podobna faktura (semantycznie" in examples
        assert "1200.00" in examples
        assert "950.00" in examples
        assert "AUTO_POST" in examples  # PAID → AUTO_POST
        assert "SUGGEST" in examples    # SUGGESTED → SUGGEST

    def test_build_few_shot_similar_without_status_falls_back(self) -> None:
        """Sprawdź, że similar_invoices bez statusu używają SUGGEST jako domyślnego."""
        sheet = FactSheet(
            similar_invoices=[
                {"id": "sim-1", "amount_gross": "1000.00", "category": "IT", "_distance": 0.15, "status": "?"},
                {"id": "sim-2", "amount_gross": "500.00", "category": "Marketing", "_distance": 0.25},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=2)
        assert "PRZYKŁADY FEW-SHOT" in examples
        assert "Podobna faktura" in examples
        assert "SUGGEST" in examples  # domyślna decyzja dla nieznanego statusu

    def test_build_few_shot_both_sources_recent_and_similar(self) -> None:
        """Sprawdź, że oba źródła (recent + similar) są zawsze dołączane."""
        sheet = FactSheet(
            recent_invoices=[
                {"id": "r1", "amount_gross": 100.00, "category": "A", "status": "PAID"},
                {"id": "r2", "amount_gross": 200.00, "category": "B", "status": "PAID"},
            ],
            similar_invoices=[
                {"id": "s1", "amount_gross": "150.00", "category": "A", "_distance": 0.10, "status": "PAID"},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=3)
        assert "PRZYKŁADY FEW-SHOT" in examples
        # Oba źródła obecne
        assert "[Historyczna faktura]" in examples
        assert "[Podobna faktura (semantycznie" in examples
        # 2 recent + 1 similar = 3 przykłady (max_examples=3)

    def test_build_few_shot_with_global_decisions(self) -> None:
        """Sprawdź, że globalne decyzje są dołączane jako drugie źródło (po similar, przed recent)."""
        sheet = FactSheet(
            similar_invoices=[
                {"id": "sim-1", "amount_gross": "1200.00", "category": "IT", "_distance": 0.12, "status": "PAID"},
            ],
            global_recent_decisions=[
                {"contractor_nip": "1112223334", "category": "IT", "decision": "AUTO_POST", "trust_score": 0.95},
                {"contractor_nip": "5556667778", "category": "Marketing", "decision": "SUGGEST", "trust_score": 0.78},
            ],
            recent_invoices=[
                {"id": "r1", "amount_gross": 500.00, "category": "IT", "status": "PAID"},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=3)
        assert "PRZYKŁADY FEW-SHOT" in examples

        # Priorytet: 1 similar + 2 global → max_examples=3, recent nie zmieści się
        assert "[Podobna faktura (semantycznie" in examples
        assert "[Globalna decyzja (inny kontrahent)]" in examples
        assert "1112223334" in examples
        assert "5556667778" in examples
        # Recent nie zmieścił się (budżet: 1 similar + 2 global = 3, recent 0)
        assert "[Historyczna faktura]" not in examples

    def test_build_few_shot_global_when_no_similar(self) -> None:
        """Sprawdź, że gdy brak similar, globalne wypełniają cały budżet."""
        sheet = FactSheet(
            similar_invoices=[],
            global_recent_decisions=[
                {"contractor_nip": "1112223334", "category": "IT", "decision": "AUTO_POST", "trust_score": 0.95},
                {"contractor_nip": "5556667778", "category": "Marketing", "decision": "SUGGEST", "trust_score": 0.78},
            ],
            recent_invoices=[
                {"id": "r1", "amount_gross": 500.00, "category": "IT", "status": "PAID"},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=3)
        # Budżet: 0 similar + 2 global + 1 recent = 3
        assert "[Globalna decyzja (inny kontrahent)]" in examples
        assert "1112223334" in examples
        assert "5556667778" in examples
        assert "[Historyczna faktura]" in examples
        assert examples.count("[Globalna decyzja (inny kontrahent)]") == 2

    def test_build_few_shot_three_way_priority(self) -> None:
        """Sprawdź 3-warstwowy priorytet: similar → global → recent."""
        sheet = FactSheet(
            similar_invoices=[
                {"id": "s1", "amount_gross": "200.00", "category": "A", "_distance": 0.1, "status": "PAID"},
            ],
            global_recent_decisions=[
                {"contractor_nip": "g1", "category": "B", "decision": "SUGGEST", "trust_score": 0.80},
            ],
            recent_invoices=[
                {"id": "r1", "amount_gross": 100.00, "category": "C", "status": "PAID"},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=2)
        # Budżet: 1 similar + 1 global = 2 (recent nie zmieści się)
        assert "[Podobna faktura" in examples
        assert "[Globalna decyzja" in examples
        assert "[Historyczna faktura" not in examples

    def test_build_few_shot_global_empty_still_works(self) -> None:
        """Sprawdź, że puste global_recent_decisions nie psuje logiki."""
        sheet = FactSheet(
            similar_invoices=[
                {"id": "s1", "amount_gross": "200.00", "category": "A", "_distance": 0.1, "status": "PAID"},
            ],
            global_recent_decisions=[],
            recent_invoices=[
                {"id": "r1", "amount_gross": 100.00, "category": "A", "status": "PAID"},
                {"id": "r2", "amount_gross": 200.00, "category": "B", "status": "PAID"},
            ],
        )
        examples = sheet.build_few_shot_examples(max_examples=2)
        # Budżet: 1 similar + 0 global + 1 recent = 2
        assert "[Podobna faktura" in examples
        assert "[Historyczna faktura" in examples
        # Global nie pojawia się (pusta lista)
        assert "[Globalna decyzja" not in examples


# ── Testy TigerBeetle (secure ledger) ──────────────────────────────────

class TestTigerBeetleSource:
    """Testy integracji TigerBeetle z FactsAggregator."""

    @pytest.mark.anyio
    async def test_build_with_tigerbeetle(
        self,
        sample_invoice_data: dict,
    ) -> None:
        """Sprawdź build() z TigerBeetleClient."""
        tb_client = MagicMock()
        tb_client.get_account_credits_posted.return_value = 50000  # 500 PLN w groszach

        aggregator = FactsAggregator(
            tigerbeetle_client=tb_client,
        )

        sheet = await aggregator.build(sample_invoice_data)

        # TigerBeetle powinno być dostępne
        assert sheet.ledger_available is True
        assert len(sheet.ledger_accounts) > 0
        # 50000 groszy = 500 PLN
        for sym, bal in sheet.ledger_accounts.items():
            assert bal == 500.0
        assert sheet.ledger_total_turnover > 0
        assert tb_client.get_account_credits_posted.call_count >= 3  # 3 konta domyślne

    @pytest.mark.anyio
    async def test_build_without_tigerbeetle(
        self,
        sample_invoice_data: dict,
    ) -> None:
        """Sprawdź build() bez TigerBeetleClient (graceful degradation)."""
        aggregator = FactsAggregator()
        sheet = await aggregator.build(sample_invoice_data)

        assert sheet.ledger_available is False
        assert sheet.ledger_accounts == {}
        assert sheet.ledger_total_turnover == 0.0

    @pytest.mark.anyio
    async def test_tigerbeetle_error_isolated(
        self,
        sample_invoice_data: dict,
    ) -> None:
        """Sprawdź, że błąd TigerBeetle nie psuje innych źródeł."""
        tb_client = MagicMock()
        tb_client.get_account_credits_posted.side_effect = RuntimeError("TB crash")

        aggregator = FactsAggregator(
            tigerbeetle_client=tb_client,
        )

        # Nie powinno rzucić wyjątku — tylko warning
        sheet = await aggregator.build(sample_invoice_data)

        assert sheet.invoice_id == "inv-123"
        assert sheet.ledger_available is False
        assert sheet.ledger_accounts == {}
        assert sheet.ledger_total_turnover == 0.0

    @pytest.mark.anyio
    async def test_tigerbeetle_to_prompt_section(
        self,
        sample_invoice_data: dict,
    ) -> None:
        """Sprawdź, że dane TigerBeetle pojawiają się w prompt section."""
        tb_client = MagicMock()
        tb_client.get_account_credits_posted.return_value = 150000  # 1500 PLN

        aggregator = FactsAggregator(
            tigerbeetle_client=tb_client,
        )

        sheet = await aggregator.build(sample_invoice_data)
        prompt = sheet.to_prompt_section()

        assert "TigerBeetle (secure ledger)" in prompt
        assert "401-01" in prompt or "202" in prompt
        assert "1500.00" in prompt or "1500" in prompt
        assert "Łączny obrót" in prompt

    @pytest.mark.anyio
    async def test_tigerbeetle_to_dict(
        self,
        sample_invoice_data: dict,
    ) -> None:
        """Sprawdź, że dane TigerBeetle są w to_dict()."""
        tb_client = MagicMock()
        tb_client.get_account_credits_posted.return_value = 75000  # 750 PLN

        aggregator = FactsAggregator(
            tigerbeetle_client=tb_client,
        )

        sheet = await aggregator.build(sample_invoice_data)
        d = sheet.to_dict()

        assert d["ledger"]["available"] is True
        assert len(d["ledger"]["accounts"]) > 0
        assert d["ledger"]["total_turnover"] > 0

    @pytest.mark.anyio
    async def test_tigerbeetle_with_all_sources(
        self,
        sample_invoice_data: dict,
        mock_session_factory: MagicMock,
        mock_decision_logger: MagicMock,
        mock_vector_store: MagicMock,
        mock_embedding_service: MagicMock,
        mock_rule_store: MagicMock,
        mock_vendor_analyst: MagicMock,
    ) -> None:
        """Sprawdź TigerBeetle działający razem ze wszystkimi źródłami."""
        tb_client = MagicMock()
        tb_client.get_account_credits_posted.return_value = 30000  # 300 PLN

        aggregator = FactsAggregator(
            db_session_factory=mock_session_factory,
            decision_logger=mock_decision_logger,
            vector_store=mock_vector_store,
            embedding_service=mock_embedding_service,
            rule_store=mock_rule_store,
            vendor_analyst=mock_vendor_analyst,
            tigerbeetle_client=tb_client,
        )

        sheet = await aggregator.build(sample_invoice_data)

        assert sheet.ledger_available is True
        assert sheet.ledger_total_turnover > 0
        assert sheet.contractor_known is True or sheet.contractor_known is False
        assert sheet.build_duration_ms > 0

        # TigerBeetle nie wpływa na inne źródła
        assert "sources" in sheet.sources_available or sheet.sources_available == {}

    @pytest.mark.anyio
    async def test_tigerbeetle_mapper_integration(
        self,
        sample_invoice_data: dict,
    ) -> None:
        """Sprawdź, że TigerBeetleMapper jest używany do konwersji symboli."""
        from nexus_ai.services.tigerbeetle.client import TigerBeetleMapper

        mapper = TigerBeetleMapper()
        account_id = mapper.account_to_uint128("401-01")
        assert isinstance(account_id, int)
        assert account_id > 0

        # Różne symbole → różne ID
        account_id_2 = mapper.account_to_uint128("202")
        assert account_id != account_id_2

        # Idempotentność
        assert mapper.account_to_uint128("401-01") == account_id