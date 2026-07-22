"""
Unit tests for RiskController — zarządzanie progami ryzyka (Strażnik Ryzyka).

Testuje wszystkie 5 endpointów z ``nexus_ai/api/routes/risk.py``:

  Endpoint                                                    Metoda
  ──────────────────────────────────────────────────────────── ─────────────────────
  GET    /api/v2/admin/risk-thresholds                        list_thresholds
  POST   /api/v2/admin/risk-thresholds                        create_threshold
  DELETE /api/v2/admin/risk-thresholds/{rule_id}              deprecate_threshold
  GET    /api/v2/admin/risk-thresholds/evaluate               evaluate_threshold
  GET    /api/v2/admin/risk-thresholds/evaluate-batch         evaluate_batch

Strategia mockowania:
  - ``RiskController._with_guard`` jest patched, aby wywołać action z mockiem RiskGuard
  - ``config.AppConfig`` jest mockowane przed importem (brak nexus_ai/config.py)
  - Testujemy logikę kontrolera w izolacji — nie otwieramy DuckDB
"""

from __future__ import annotations

import sys
from unittest.mock import MagicMock, PropertyMock, patch

# Move msgspec import after docstring
from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads, msgspec_dumps_bytes
from unittest.mock import MagicMock, PropertyMock, patch

import pytest

# ── Mock config BEFORE importing RiskController ──────────────────────────────
# RiskController._with_guard używa `from config import AppConfig`, ale w projekcie
# nie ma `nexus_ai/config.py` — musimy zamockować moduł config przed importem.
_config_mock = MagicMock()
type(_config_mock.AppConfig.return_value).duckdb_path = PropertyMock(
    return_value=":memory:"
)
sys.modules["config"] = _config_mock

from litestar.exceptions import HTTPException
from litestar.response import Response

from nexus_ai.api.routes.risk import RiskController
from nexus_ai.services.risk_guard import RiskThreshold, RiskVerdict


# ── SUPERMOC: pytestmark — anyio na poziomie modułu zamiast per-function ───
pytestmark = pytest.mark.anyio


# ==============================================================================
# Fixtures
# ==============================================================================


@pytest.fixture
def controller() -> RiskController:
    """Czysta instancja RiskController bez połączenia do DuckDB."""
    return RiskController()


@pytest.fixture
def mock_guard() -> MagicMock:
    """RiskGuard z kontrolowanymi zwrotami dla każdego endpointu."""
    guard = MagicMock()

    # list_thresholds
    guard.list_thresholds.return_value = [
        {
            "rule_id": "abc-111",
            "condition": {"tax_form": "CIT_STANDARD", "field": "vat_rate"},
            "output": {
                "required_ml_confidence": 0.98,
                "action_if_below": "BLOCK_AND_ALERT",
            },
            "valid_from": "2024-01-01",
            "valid_to": None,
            "priority": 10,
            "created_at": "2026-01-01 00:00:00",
        },
        {
            "rule_id": "def-222",
            "condition": {"tax_form": "LINEAR"},
            "output": {
                "required_ml_confidence": 0.85,
                "action_if_below": "TRIAGE_QUEUE",
            },
            "valid_from": "2024-01-01",
            "valid_to": None,
            "priority": 20,
            "created_at": "2026-01-01 00:00:00",
        },
    ]

    # add_threshold — zwraca nowy rule_id
    guard.add_threshold.return_value = "new-uuid-789"

    # deprecate_threshold — domyślnie True (znaleziono i zdezaktywowano)
    guard.deprecate_threshold.return_value = True

    # get_threshold — standardowy próg CIT
    guard.get_threshold.return_value = RiskThreshold(
        required_ml_confidence=0.98,
        action_if_below="BLOCK_AND_ALERT",
    )

    # evaluate — domyślnie bezpieczny
    guard.evaluate.return_value = RiskVerdict(
        is_safe=True,
        action="AUTO_POST",
        reason="All fields meet thresholds",
        required_for_field={"vat_rate": 0.98, "total_net": 0.95},
    )

    return guard


@pytest.fixture(autouse=True)
def _patch_guard(mock_guard: MagicMock) -> None:
    """Automatycznie patchuje _with_guard dla każdego testu.

    Zamiast otwierać DuckDB, wywołuje action bezpośrednio z mockiem RiskGuard.
    """
    with patch.object(
        RiskController,
        "_with_guard",
        lambda self, action: action(mock_guard),
    ):
        yield


# ==============================================================================
# GET /api/v2/admin/risk-thresholds — list_thresholds
# ==============================================================================


class TestListThresholds:
    """GET /api/v2/admin/risk-thresholds — lista reguł."""

    async def test_list_returns_all_rules(
        self,
        controller: RiskController,
    ) -> None:
        """Zwraca listę reguł — content to lista dictów, status 200."""
        result = await controller.list_thresholds()

        assert isinstance(result, Response)
        assert result.status_code == 200
        assert isinstance(result.content, list)
        assert len(result.content) == 2

        first = result.content[0]
        assert first["rule_id"] == "abc-111"
        assert first["condition"]["tax_form"] == "CIT_STANDARD"

    async def test_list_contains_expected_fields(
        self,
        controller: RiskController,
    ) -> None:
        """Każda reguła zawiera wszystkie wymagane pola."""
        result = await controller.list_thresholds()

        for rule in result.content:
            assert "rule_id" in rule
            assert "condition" in rule
            assert "output" in rule
            assert "valid_from" in rule
            assert "valid_to" in rule
            assert "priority" in rule
            assert "created_at" in rule

    async def test_list_wraps_exception_in_500(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Gdy guard.list_thresholds rzuca wyjątkiem → HTTPException 500."""
        mock_guard.list_thresholds.side_effect = RuntimeError("DB connection lost")

        with pytest.raises(HTTPException) as exc_info:
            await controller.list_thresholds()

        assert exc_info.value.status_code == 500
        assert "Failed to list risk thresholds" in str(exc_info.value.detail)


# ==============================================================================
# POST /api/v2/admin/risk-thresholds — create_threshold
# ==============================================================================


class TestCreateThreshold:
    """POST /api/v2/admin/risk-thresholds — dodawanie reguły."""

    async def test_create_with_valid_data(
        self,
        controller: RiskController,
    ) -> None:
        """Poprawne dane → zwraca rule_id i message."""
        result = await controller.create_threshold(
            data={
                "condition": {"tax_form": "CIT_STANDARD", "field": "total_net"},
                "output": {
                    "required_ml_confidence": 0.95,
                    "action_if_below": "BLOCK_AND_ALERT",
                },
                "valid_from": "2025-01-01",
                "priority": 15,
                "created_by": "test-user",
            }
        )

        assert isinstance(result, Response)
        assert result.status_code == 200
        assert result.content["rule_id"] == "new-uuid-789"
        assert result.content["message"] == "Risk threshold rule created"

    async def test_create_with_defaults(
        self,
        controller: RiskController,
    ) -> None:
        """Minimalne dane — valid_from = dzisiaj, priority = 100, created_by = admin."""
        result = await controller.create_threshold(
            data={
                "condition": {"tax_form": "LUMP_SUM"},
                "output": {"required_ml_confidence": 0.85},
            }
        )

        assert result.status_code == 200
        assert result.content["rule_id"] == "new-uuid-789"

    async def test_create_missing_condition_returns_422(
        self,
        controller: RiskController,
    ) -> None:
        """Brak 'condition' → HTTPException 422."""
        with pytest.raises(HTTPException) as exc_info:
            await controller.create_threshold(
                data={"output": {"required_ml_confidence": 0.95}}
            )

        assert exc_info.value.status_code == 422
        assert "condition" in str(exc_info.value.detail).lower()

    @pytest.mark.anyio
    async def test_create_missing_output_returns_422(
        self,
        controller: RiskController,
    ) -> None:
        """Brak 'output' → HTTPException 422."""
        with pytest.raises(HTTPException) as exc_info:
            await controller.create_threshold(
                data={"condition": {"tax_form": "CIT_STANDARD"}}
            )

        assert exc_info.value.status_code == 422
        assert "output" in str(exc_info.value.detail).lower()

    async def test_create_non_dict_condition_returns_422(
        self,
        controller: RiskController,
    ) -> None:
        """'condition' nie jest dictem → HTTPException 422."""
        with pytest.raises(HTTPException) as exc_info:
            await controller.create_threshold(
                data={"condition": "not-a-dict", "output": {"confidence": 0.9}}
            )

        assert exc_info.value.status_code == 422

    async def test_create_non_dict_output_returns_422(
        self,
        controller: RiskController,
    ) -> None:
        """'output' nie jest dictem → HTTPException 422."""
        with pytest.raises(HTTPException) as exc_info:
            await controller.create_threshold(
                data={
                    "condition": {"tax_form": "CIT_STANDARD"},
                    "output": "not-a-dict",
                }
            )

        assert exc_info.value.status_code == 422

    async def test_create_wraps_exception_in_500(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Guard.add_threshold rzuca wyjątkiem → HTTPException 500."""
        mock_guard.add_threshold.side_effect = ValueError("Invalid priority")

        with pytest.raises(HTTPException) as exc_info:
            await controller.create_threshold(
                data={
                    "condition": {"tax_form": "CIT_STANDARD"},
                    "output": {"required_ml_confidence": 0.95},
                }
            )

        assert exc_info.value.status_code == 500
        assert "Failed to create risk threshold" in str(exc_info.value.detail)


# ==============================================================================
# DELETE /api/v2/admin/risk-thresholds/{rule_id} — deprecate_threshold
# ==============================================================================


class TestDeprecateThreshold:
    """DELETE /api/v2/admin/risk-thresholds/{rule_id} — dezaktywacja reguły."""

    async def test_deprecate_existing_rule(
        self,
        controller: RiskController,
    ) -> None:
        """Istniejąca aktywna reguła → 200, message potwierdza dezaktywację."""
        result = await controller.deprecate_threshold(rule_id="abc-111")

        assert isinstance(result, Response)
        assert result.status_code == 200
        assert result.content["rule_id"] == "abc-111"
        assert "deprecated" in result.content["message"].lower()

    async def test_deprecate_nonexistent_rule_returns_404(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Nieznaleziona reguła → HTTPException 404."""
        mock_guard.deprecate_threshold.return_value = False

        with pytest.raises(HTTPException) as exc_info:
            await controller.deprecate_threshold(rule_id="nonexistent-id")

        assert exc_info.value.status_code == 404
        assert "not found" in str(exc_info.value.detail).lower()
        assert "nonexistent-id" in str(exc_info.value.detail)

    async def test_deprecate_wraps_exception_in_500(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Guard.deprecate_threshold rzuca wyjątkiem → HTTPException 500."""
        mock_guard.deprecate_threshold.side_effect = RuntimeError("DB error")

        with pytest.raises(HTTPException) as exc_info:
            await controller.deprecate_threshold(rule_id="abc-111")

        assert exc_info.value.status_code == 500
        assert "Failed to deprecate risk threshold" in str(exc_info.value.detail)


# ==============================================================================
# GET /api/v2/admin/risk-thresholds/evaluate — evaluate_threshold
# ==============================================================================


class TestEvaluateThreshold:
    """GET /api/v2/admin/risk-thresholds/evaluate — ewaluacja pojedynczego pola."""

    async def test_evaluate_with_all_params(
        self,
        controller: RiskController,
    ) -> None:
        """Wszystkie parametry query → zwraca próg z params."""
        result = await controller.evaluate_threshold(
            tax_form="CIT_STANDARD",
            expense_type="mixed_auto",
            field="vat_rate",
        )

        assert isinstance(result, Response)
        assert result.status_code == 200
        assert result.content["required_ml_confidence"] == 0.98
        assert result.content["action_if_below"] == "BLOCK_AND_ALERT"
        assert result.content["params"]["tax_form"] == "CIT_STANDARD"
        assert result.content["params"]["expense_type"] == "mixed_auto"
        assert result.content["params"]["field"] == "vat_rate"

    async def test_evaluate_with_defaults(
        self,
        controller: RiskController,
    ) -> None:
        """Brak parametrów → domyślnie puste stringi, params pokazuje 'any'."""
        result = await controller.evaluate_threshold()

        assert result.status_code == 200
        assert result.content["params"]["tax_form"] == "any"
        assert result.content["params"]["expense_type"] == "any"
        assert result.content["params"]["field"] == "any"

    async def test_evaluate_empty_strings_treated_as_any(
        self,
        controller: RiskController,
    ) -> None:
        """Puste stringi w query → params pokazuje 'any'."""
        result = await controller.evaluate_threshold(tax_form="", field="")

        assert result.content["params"]["tax_form"] == "any"
        assert result.content["params"]["field"] == "any"

    async def test_evaluate_wraps_exception_in_500(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Guard.get_threshold rzuca wyjątkiem → HTTPException 500."""
        mock_guard.get_threshold.side_effect = RuntimeError("DB error")

        with pytest.raises(HTTPException) as exc_info:
            await controller.evaluate_threshold(tax_form="CIT_STANDARD")

        assert exc_info.value.status_code == 500
        assert "Failed to evaluate risk threshold" in str(exc_info.value.detail)


# ==============================================================================
# GET /api/v2/admin/risk-thresholds/evaluate-batch — evaluate_batch
# ==============================================================================


class TestEvaluateBatch:
    """GET /api/v2/admin/risk-thresholds/evaluate-batch — ewaluacja wielu pól."""

    async def test_evaluate_batch_valid_fields(
        self,
        controller: RiskController,
    ) -> None:
        """Poprawne fields_json → zwraca RiskVerdict."""
        fields = msgspec_dumps({"vat_rate": 0.70, "total_net": 0.95})
        result = await controller.evaluate_batch(
            tax_form="CIT_STANDARD",
            expense_type="",
            fields_json=fields,
        )

        assert isinstance(result, Response)
        assert result.status_code == 200
        assert result.content["is_safe"] is True
        assert result.content["action"] == "AUTO_POST"
        assert result.content["reason"] is not None
        assert result.content["required_for_field"]["vat_rate"] == 0.98

    async def test_evaluate_batch_without_expense_type(
        self,
        controller: RiskController,
    ) -> None:
        """Brak expense_type → domyślnie pusty, ewaluacja po formie podatkowej."""
        fields = msgspec_dumps({"vat_rate": 0.99})
        result = await controller.evaluate_batch(
            tax_form="LINEAR",
            fields_json=fields,
        )

        assert result.status_code == 200
        assert "is_safe" in result.content

    async def test_evaluate_batch_missing_fields_json_returns_422(
        self,
        controller: RiskController,
    ) -> None:
        """Brak fields_json → HTTPException 422."""
        with pytest.raises(HTTPException) as exc_info:
            await controller.evaluate_batch(
                tax_form="CIT_STANDARD",
                fields_json="",
            )

        assert exc_info.value.status_code == 422
        assert "Missing required" in str(exc_info.value.detail)

    async def test_evaluate_batch_invalid_json_returns_422(
        self,
        controller: RiskController,
    ) -> None:
        """Niepoprawny JSON → HTTPException 422."""
        with pytest.raises(HTTPException) as exc_info:
            await controller.evaluate_batch(
                tax_form="CIT_STANDARD",
                fields_json="not-valid-json{{{",
            )

        assert exc_info.value.status_code == 422
        assert "Invalid" in str(exc_info.value.detail)

    async def test_evaluate_batch_non_dict_json_returns_422(
        self,
        controller: RiskController,
    ) -> None:
        """JSON nie jest dictem → HTTPException 422."""
        with pytest.raises(HTTPException) as exc_info:
            await controller.evaluate_batch(
                tax_form="CIT_STANDARD",
                fields_json=msgspec_dumps([1, 2, 3]),
            )

        assert exc_info.value.status_code == 422
        assert "must be a JSON object" in str(exc_info.value.detail).lower()

    async def test_evaluate_batch_wraps_exception_in_500(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Guard.evaluate rzuca wyjątkiem → HTTPException 500."""
        mock_guard.evaluate.side_effect = RuntimeError("DB error")

        fields = msgspec_dumps({"vat_rate": 0.90})
        with pytest.raises(HTTPException) as exc_info:
            await controller.evaluate_batch(
                tax_form="CIT_STANDARD",
                fields_json=fields,
            )

        assert exc_info.value.status_code == 500
        assert "Failed to evaluate batch risk" in str(exc_info.value.detail)

    async def test_evaluate_batch_passes_fields_to_guard(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Sprawdza, że guard.evaluate otrzymuje poprawnie sparsowane fields."""
        fields = msgspec_dumps({"vat_rate": 0.70, "total_net": 0.95})
        await controller.evaluate_batch(
            tax_form="CIT_STANDARD",
            expense_type="representation",
            fields_json=fields,
        )

        mock_guard.evaluate.assert_called_once_with(
            fields_with_confidence={"vat_rate": 0.70, "total_net": 0.95},
            tax_form="CIT_STANDARD",
            expense_type="representation",
        )


# ==============================================================================
# Edge cases — puste listy, nieoczekiwane błędy
# ==============================================================================


class TestEdgeCases:
    """Scenariusze brzegowe dla wszystkich endpointów."""

    async def test_list_empty_returns_empty_list(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Brak reguł → pusta lista, nie błąd."""
        mock_guard.list_thresholds.return_value = []
        result = await controller.list_thresholds()

        assert result.status_code == 200
        assert result.content == []

    async def test_deprecate_already_inactive_returns_false(
        self,
        controller: RiskController,
        mock_guard: MagicMock,
    ) -> None:
        """Próba dezaktywacji nieaktywnej reguły → 404."""
        mock_guard.deprecate_threshold.return_value = False

        with pytest.raises(HTTPException) as exc_info:
            await controller.deprecate_threshold(rule_id="already-inactive")

        assert exc_info.value.status_code == 404

    async def test_evaluate_batch_very_large_fields_json(
        self,
        controller: RiskController,
    ) -> None:
        """Duża liczba pól → poprawna deserializacja JSON."""
        many_fields = {f"field_{i}": 0.5 + (i * 0.01) for i in range(100)}
        fields = msgspec_dumps(many_fields)

        result = await controller.evaluate_batch(
            tax_form="CIT_STANDARD",
            fields_json=fields,
        )

        assert result.status_code == 200


# ==============================================================================
# Smoke — sprawdza poprawność importu i podstawową strukturę kontrolera
# ==============================================================================


class TestControllerStructure:
    """Testy strukturalne — sprawdzają konfigurację kontrolera."""

    def test_controller_path(self) -> None:
        """Ścieżka kontrolera to '/api/v2/admin/risk-thresholds'."""
        assert RiskController.path == "/api/v2/admin/risk-thresholds"

    def test_controller_has_all_endpoints(self) -> None:
        """Kontroler ma metody dla wszystkich 5 endpointów."""
        assert hasattr(RiskController, "list_thresholds")
        assert hasattr(RiskController, "create_threshold")
        assert hasattr(RiskController, "deprecate_threshold")
        assert hasattr(RiskController, "evaluate_threshold")
        assert hasattr(RiskController, "evaluate_batch")

    def test_with_guard_is_static_method(self) -> None:
        """_with_guard jest statyczny — można wywołać bez instancji."""
        assert isinstance(RiskController.__dict__["_with_guard"], staticmethod)
