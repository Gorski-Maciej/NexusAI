"""
Risk Guard API — zarządzanie dynamicznymi progami ryzyka (Strażnik Ryzyka).

Endpointy administracyjne dla RiskGuard — zintegrowane z DecisionEngine
(DuckDB/SQL) i NexusCache z event-based invalidation.

Endpointy:
  GET    /api/v2/admin/risk-thresholds           — lista reguł
  POST   /api/v2/admin/risk-thresholds           — dodaj nową regułę progu ryzyka
  DELETE /api/v2/admin/risk-thresholds/{rule_id} — dezaktywuj regułę (append-only)
  GET    /api/v2/admin/risk-thresholds/evaluate  — ewaluacja progu dla zadanych parametrów
  GET    /api/v2/admin/risk-thresholds/evaluate-batch — ewaluacja wielu pól

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
from nexus_ai.api.dto import GenericDictDTO, TAG_RISK
from nexus_ai.api.rbac import requires_permission
from nexus_ai.core.msgspec_utils import DecodeError, msgspec_loads
from nexus_ai.services.risk_guard import (
    RiskGuard,
    ensure_schema,
)

logger = get_logger("nexus.api.risk")


class RiskController(Controller):
    """Zarządzanie progami ryzyka dla RiskGuard."""

    path = "/api/v2/admin/risk-thresholds"
    tags = [TAG_RISK]

    # ── Helpers ───────────────────────────────────────────────────────────

    @staticmethod
    def _with_guard(action):
        """Uruchom akcję z RiskGuard i zamknij połączenie DuckDB.

        Tworzy tymczasowe połączenie z DuckDB, zapewnia schemat,
        przekazuje RiskGuard do akcji i zamyka połączenie w finally.
        """
        conn = duckdb.connect(str(AppConfig().duckdb_path))
        try:
            ensure_schema(conn)
            guard = RiskGuard(conn)
            return action(guard)
        finally:
            conn.close()

    # ── LIST ──────────────────────────────────────────────────────────────

    @get(guards=[requires_permission("admin:risk")])
    async def list_thresholds(self) -> Response[list[dict[str, Any]]]:
        """Lista wszystkich reguł progów ryzyka.

        Tabela risk_thresholds jest append-only — każda reguła pojawia się
        raz z polem ``valid_to`` (NULL = wciąż aktywna).
        """
        try:

            def _list(guard: RiskGuard) -> Response[list[dict[str, Any]]]:
                rules = guard.list_thresholds()
                return Response(rules)

            return self._with_guard(_list)
        except Exception as exc:
            logger.error("[RISK-API] list_thresholds failed: %s", exc)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to list risk thresholds: {exc}",
            ) from exc

    # ── CREATE ────────────────────────────────────────────────────────────

    @post(guards=[requires_permission("admin:risk")])
    async def create_threshold(
        self,
        data: dict[str, Any],
    ) -> Response[dict[str, Any]]:
        """Dodaj nową regułę progu ryzyka (append-only).

        Request body (JSON):
            condition: dict — warunki reguły (np. {"tax_form": "CIT_STANDARD", "field": "vat_rate"}).
            output: dict — wynik reguły (np. {"required_ml_confidence": 0.98, "action_if_below": "BLOCK_AND_ALERT"}).
            valid_from: str (opcjonalnie) — data rozpoczęcia, domyślnie dzisiaj.
            valid_to: str | null (opcjonalnie) — data zakończenia, domyślnie null (bezterminowo).
            priority: int (opcjonalnie) — priorytet, domyślnie 100.
            created_by: str (opcjonalnie) — identyfikator twórcy, domyślnie "admin".
        """
        condition = data.get("condition")
        output = data.get("output")

        if not condition or not isinstance(condition, dict):
            raise HTTPException(
                status_code=422,
                detail="Missing or invalid 'condition' field — must be a dict",
            )
        if not output or not isinstance(output, dict):
            raise HTTPException(
                status_code=422,
                detail="Missing or invalid 'output' field — must be a dict",
            )

        valid_from = data.get("valid_from", pendulum.now().date().isoformat())
        valid_to = data.get("valid_to")
        priority = int(data.get("priority", 100))
        created_by = str(data.get("created_by", "admin"))

        try:

            def _create(guard: RiskGuard) -> Response[dict[str, Any]]:
                rule_id = guard.add_threshold(
                    condition=condition,
                    output=output,
                    valid_from=valid_from,
                    valid_to=valid_to,
                    priority=priority,
                    created_by=created_by,
                )
                logger.info(
                    "[RISK-API] Created threshold rule_id=%s condition=%s output=%s by=%s",
                    rule_id, condition, output, created_by,
                )
                return Response({
                    "rule_id": rule_id,
                    "message": "Risk threshold rule created",
                })

            return self._with_guard(_create)
        except HTTPException:
            raise
        except Exception as exc:
            logger.error("[RISK-API] create_threshold failed: %s", exc)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create risk threshold: {exc}",
            ) from exc

    # ── DELETE (DEPRECATE) ────────────────────────────────────────────────

    @delete("/{rule_id:str}", guards=[requires_permission("admin:risk")])
    async def deprecate_threshold(
        self,
        rule_id: str,
    ) -> Response[dict[str, Any]]:
        """Dezaktywuj regułę progu ryzyka (append-only — ustawia valid_to = dzisiaj).

        Args:
            rule_id: UUID reguły do dezaktywacji.
        """
        try:

            def _deprecate(guard: RiskGuard) -> Response[dict[str, Any]]:
                success = guard.deprecate_threshold(rule_id, created_by="admin")
                if not success:
                    raise HTTPException(
                        status_code=404,
                        detail=f"Risk threshold not found or already inactive: {rule_id}",
                    )
                logger.info("[RISK-API] Deprecated threshold rule_id=%s", rule_id)
                return Response({
                    "rule_id": rule_id,
                    "message": "Risk threshold rule deprecated (valid_to set to today)",
                })

            return self._with_guard(_deprecate)
        except HTTPException:
            raise
        except Exception as exc:
            logger.error("[RISK-API] deprecate_threshold failed rule_id=%s: %s", rule_id, exc)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to deprecate risk threshold: {exc}",
            ) from exc

    # ── EVALUATE (single field) ───────────────────────────────────────────

    @get("/evaluate", guards=[requires_permission("admin:risk")])
    async def evaluate_threshold(
        self,
        tax_form: str = "",
        expense_type: str = "",
        field: str = "",
    ) -> Response[dict[str, Any]]:
        """Zwróć próg ryzyka dla zadanego kontekstu (symulacja / podgląd).

        Query params:
            tax_form: Forma opodatkowania (np. CIT_STANDARD, LUMP_SUM).
            expense_type: Typ wydatku (np. mixed_auto, representation).
            field: Konkretne pole faktury (np. vat_rate, total_net, vendor_nip).
        """
        try:

            def _evaluate(guard: RiskGuard) -> Response[dict[str, Any]]:
                threshold = guard.get_threshold(
                    tax_form=tax_form,
                    expense_type=expense_type,
                    field=field,
                )
                return Response({
                    "required_ml_confidence": threshold.required_ml_confidence,
                    "action_if_below": threshold.action_if_below,
                    "params": {
                        "tax_form": tax_form or "any",
                        "expense_type": expense_type or "any",
                        "field": field or "any",
                    },
                })

            return self._with_guard(_evaluate)
        except Exception as exc:
            logger.error("[RISK-API] evaluate_threshold failed: %s", exc)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to evaluate risk threshold: {exc}",
            ) from exc

    # ── EVALUATE BATCH (multiple fields) ──────────────────────────────────

    @get("/evaluate-batch", guards=[requires_permission("admin:risk")])
    async def evaluate_batch(
        self,
        tax_form: str = "",
        expense_type: str = "",
        fields_json: str = "",
    ) -> Response[dict[str, Any]]:
        """Ewaluacja wielu pól faktury względem progów ryzyka.

        Query params:
            tax_form: Forma opodatkowania.
            expense_type: Typ wydatku.
            fields_json: JSON string z mapą {nazwa_pola: confidence}.
                Np. ``{"vat_rate": 0.70, "total_net": 0.95, "vendor_nip": 0.88}``
        """
        if not fields_json:
            raise HTTPException(
                status_code=422,
                detail="Missing required query param 'fields_json' — JSON dict of {field: confidence}",
            )

        try:
            fields_with_confidence = msgspec_loads(fields_json)
        except (DecodeError, TypeError) as exc:
            raise HTTPException(
                status_code=422,
                detail=f"Invalid 'fields_json': {exc}",
            ) from exc

        if not isinstance(fields_with_confidence, dict):
            raise HTTPException(
                status_code=422,
                detail="'fields_json' must be a JSON object (dict)",
            )

        try:

            def _eval_batch(guard: RiskGuard) -> Response[dict[str, Any]]:
                verdict = guard.evaluate(
                    fields_with_confidence=fields_with_confidence,
                    tax_form=tax_form,
                    expense_type=expense_type,
                )
                return Response({
                    "is_safe": verdict.is_safe,
                    "action": verdict.action,
                    "reason": verdict.reason,
                    "required_for_field": verdict.required_for_field,
                })

            return self._with_guard(_eval_batch)
        except Exception as exc:
            logger.error("[RISK-API] evaluate_batch failed: %s", exc)
            raise HTTPException(
                status_code=500,
                detail=f"Failed to evaluate batch risk: {exc}",
            ) from exc
