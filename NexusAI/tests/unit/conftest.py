"""
conftest.py — Shared fixtures and mocks for unit tests.

SUPERMOCE pytest:
  - Reużywalne mock fixtures dla najczęstszych zależności
  - monkeypatch zamiast unittest.mock.patch dla czystszego mockowania
  - pytestmark = pytest.mark.anyio dla async testów (modułowo)

Użycie:
  from tests.unit.conftest import mock_decision_logger, mock_vector_store
"""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest


# ═══════════════════════════════════════════════════════════════════════════════
# Reużywalne mock fixtures — zamiast powtarzać w każdym pliku testowym
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
def mock_decision_logger() -> MagicMock:
    """SUPERMOC: Reużywalny mock DecisionLogger dla testów FactsAggregator.

    Zastępuje: 6 linii kodu powtarzane w każdym pliku testowym.
    """
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
    """SUPERMOC: Reużywalny mock VectorStore z przykładowymi wynikami."""
    store = MagicMock()
    store.search_similar.return_value = [
        {"id": "sim-1", "amount_gross": "1200.00", "category": "IT", "_distance": 0.12},
        {"id": "sim-2", "amount_gross": "950.00", "category": "IT", "_distance": 0.18},
    ]
    return store


@pytest.fixture
def mock_embedding_service() -> MagicMock:
    """SUPERMOC: Reużywalny mock EmbeddingService."""
    service = MagicMock()
    service.embed.return_value = [0.1, 0.2, 0.3, 0.4, 0.5]
    return service


@pytest.fixture
def mock_rule_store() -> MagicMock:
    """SUPERMOC: Reużywalny mock RuleStore z aktywnymi regułami."""
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
    """SUPERMOC: Reużywalny mock VendorAnalyst."""
    analyst = MagicMock()
    analyst.get_vendor_context.return_value = (
        "Vendor Test (NIP: 1234567890). Average payment delay: 2.5 days. "
        "Reliability score: 4.5/5."
    )
    return analyst


@pytest.fixture
def mock_session_factory() -> MagicMock:
    """SUPERMOC: Reużywalny mock fabryki sesji SQLAlchemy."""
    return MagicMock()


@pytest.fixture
def mock_risk_guard() -> MagicMock:
    """SUPERMOC: Reużywalny mock RiskGuard z kontrolowanymi zwrotami."""
    guard = MagicMock()

    # list_thresholds
    guard.list_thresholds.return_value = [
        {
            "rule_id": "abc-111",
            "condition": {"tax_form": "CIT_STANDARD", "field": "vat_rate"},
            "output": {"required_ml_confidence": 0.98, "action_if_below": "BLOCK_AND_ALERT"},
            "valid_from": "2024-01-01",
            "valid_to": None,
            "priority": 10,
            "created_at": "2026-01-01 00:00:00",
        },
    ]

    # add_threshold
    guard.add_threshold.return_value = "new-uuid-789"

    # deprecate_threshold
    guard.deprecate_threshold.return_value = True

    # evaluate
    from nexus_ai.services.risk_guard import RiskThreshold, RiskVerdict

    guard.get_threshold.return_value = RiskThreshold(
        required_ml_confidence=0.98,
        action_if_below="BLOCK_AND_ALERT",
    )
    guard.evaluate.return_value = RiskVerdict(
        is_safe=True,
        action="AUTO_POST",
        reason="All fields meet thresholds",
        required_for_field={"vat_rate": 0.98, "total_net": 0.95},
    )

    return guard


@pytest.fixture
def mock_tb_client() -> MagicMock:
    """SUPERMOC: Reużywalny mock TigerBeetleClient."""
    client = MagicMock()
    client.get_account_credits_posted.return_value = 50000  # 500 PLN w groszach
    return client


# ═══════════════════════════════════════════════════════════════════════════════
# Sample data fixtures
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
def sample_invoice_data() -> dict:
    """SUPERMOC: Przykładowe dane faktury — współdzielone między testami."""
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
def sample_soap_responses() -> dict[str, str]:
    """SUPERMOC: Przykładowe odpowiedzi SOAP dla testów GUS BIR."""
    return {
        "login": "abc123session456def",
        "search": """<dane>
            <Regon>123456789</Regon>
            <Nip>1234567890</Nip>
            <Nazwa>ACME Sp. z o.o.</Nazwa>
            <Wojewodztwo>MAZOWIECKIE</Wojewodztwo>
            <Miejscowosc>Warszawa</Miejscowosc>
            <StatusNip>AKTYWNY</StatusNip>
        </dane>""",
        "report": """<root>
            <Nazwa>ACME Sp. z o.o.</Nazwa>
            <Miejscowosc>Warszawa</Miejscowosc>
            <FormaPrawna>Spolka z ograniczona odpowiedzialnoscia</FormaPrawna>
            <StatusNip>AKTYWNY</StatusNip>
            <pkdKod>62.01.Z</pkdKod>
            <pkdNazwa>Dzialalnosc zwiazana z oprogramowaniem</pkdNazwa>
        </root>""",
        "logout": "true",
    }
