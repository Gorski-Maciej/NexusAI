"""Risk Guard API — zarządzanie dynamicznymi progami ryzyka (Strażnik Ryzyka).

Endpointy:
  GET    /api/v2/admin/risk-thresholds           — lista reguł
  POST   /api/v2/admin/risk-thresholds           — dodaj nową regułę
  DELETE /api/v2/admin/risk-thresholds/{rule_id} — dezaktywuj regułę
  GET    /api/v2/admin/risk-thresholds/evaluate  — ewaluacja progu
  GET    /api/v2/admin/risk-thresholds/evaluate-batch — ewaluacja batch

Wszystkie endpointy wymagają uprawnienia ``admin:risk``.
"""
from __future__ import annotations

from typing import Any

import duckdb
import pendulum
from litestar import Controller, delete, get, post
from litestar.exceptions import HTTPException
from litestar.response import Response
from structlog import get_logger

from config import AppConfig
from nexus_ai.api.base_route import route_handler as _rh
from nexus_ai.api.dto import TAG_RISK
from nexus_ai.api.rbac import requires_permission
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads
from nexus_ai.services.risk_guard import (
    RiskGuard,
    ensure_schema,
)


def route_handler(**kw: Any) -> Any:
    """Domyślny route_handler dla risk api z [RISK-API] prefixem logowania."""
    return _rh(logger=get_logger("nexus.api.risk"), error_message="Risk operation failed", **kw)


class RiskController(Controller):
    """Zarządzanie progami ryzyka dla RiskGuard."""

    path = "/admin/risk-thresholds"
    tags = (TAG_RISK,)

    @staticmethod
    def _with_guard(action):
        """Uruchom akcję z RiskGuard i zamknij połączenie DuckDB."""
        conn = duckdb.connect(str(AppConfig().duckdb_path))
        try:
            ensure_schema(conn)
            guard = RiskGuard(conn)
            return action(guard)
        finally:
            conn.close()

    @get(guards=[requires_permission("admin:risk")])
    @route_handler()
    async def list_thresholds(self) -> Response[list[dict[str, Any]]]:
        """Lista wszystkich reguł progów ryzyka (append-only)."""
        def _list(guard: RiskGuard) -> Response[list[dict[str, Any]]]:
            return Response(guard.list_thresholds())
        return self._with_guard(_list)

    @post(guards=[requires_permission("admin:risk")])
    @route_handler()
    async def create_threshold(self, data: dict[str, Any]) -> Response[dict[str, Any]]:
        """Dodaj nową regułę progu ryzyka (append-only)."""
        condition = data.get("condition")
        output = data.get("output")
        if not condition or not isinstance(condition, dict):
            raise HTTPException(status_code=422, detail="Missing or invalid 'condition' — must be a dict")
        if not output or not isinstance(output, dict):
            raise HTTPException(status_code=422, detail="Missing or invalid 'output' — must be a dict")

        valid_from = data.get("valid_from", pendulum.now().date().isoformat())
        valid_to = data.get("valid_to")
        priority = int(data.get("priority", 100))
        created_by = str(data.get("created_by", "admin"))

        def _create(guard: RiskGuard) -> Response[dict[str, Any]]:
            rule_id = guard.add_threshold(
                condition=condition, output=output,
                valid_from=valid_from, valid_to=valid_to,
                priority=priority, created_by=created_by,
            )
            return Response({"rule_id": rule_id, "message": "Risk threshold rule created"})

        return self._with_guard(_create)

    @delete("/{rule_id:str}", guards=[requires_permission("admin:risk")])
    @route_handler()
    async def deprecate_threshold(self, rule_id: str) -> Response[dict[str, Any]]:
        """Dezaktywuj regułę progu ryzyka (append-only — ustawia valid_to = dzisiaj)."""
        def _deprecate(guard: RiskGuard) -> Response[dict[str, Any]]:
            success = guard.deprecate_threshold(rule_id, created_by="admin")
            if not success:
                raise HTTPException(status_code=404, detail=f"Risk threshold not found or inactive: {rule_id}")
            return Response({"rule_id": rule_id, "message": "Risk threshold rule deprecated"})
        return self._with_guard(_deprecate)

    @get("/evaluate", guards=[requires_permission("admin:risk")])
    @route_handler()
    async def evaluate_threshold(
        self, tax_form: str = "", expense_type: str = "", field: str = "",
    ) -> Response[dict[str, Any]]:
        """Zwróć próg ryzyka dla zadanego kontekstu (symulacja / podgląd)."""
        def _evaluate(guard: RiskGuard) -> Response[dict[str, Any]]:
            threshold = guard.get_threshold(tax_form=tax_form, expense_type=expense_type, field=field)
            return Response({
                "required_ml_confidence": threshold.required_ml_confidence,
                "action_if_below": threshold.action_if_below,
                "params": {"tax_form": tax_form or "any", "expense_type": expense_type or "any", "field": field or "any"},
            })
        return self._with_guard(_evaluate)

    @get("/evaluate-batch", guards=[requires_permission("admin:risk")])
    @route_handler()
    async def evaluate_batch(
        self, tax_form: str = "", expense_type: str = "", fields_json: str = "",
    ) -> Response[dict[str, Any]]:
        """Ewaluacja wielu pól faktury względem progów ryzyka."""
        if not fields_json:
            raise HTTPException(status_code=422, detail="Missing 'fields_json' — JSON dict of {field: confidence}")

        try:
            fields_with_confidence = msgspec_loads(fields_json)
        except (DecodeError, TypeError) as exc:
            raise HTTPException(status_code=422, detail=f"Invalid 'fields_json': {exc}") from exc

        if not isinstance(fields_with_confidence, dict):
            raise HTTPException(status_code=422, detail="'fields_json' must be a JSON object (dict)")

        def _eval_batch(guard: RiskGuard) -> Response[dict[str, Any]]:
            verdict = guard.evaluate(fields_with_confidence=fields_with_confidence, tax_form=tax_form, expense_type=expense_type)
            return Response({"is_safe": verdict.is_safe, "action": verdict.action, "reason": verdict.reason, "required_for_field": verdict.required_for_field})

        return self._with_guard(_eval_batch)
