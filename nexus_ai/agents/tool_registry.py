"""Agentic RAG with Tool Use — Agenci używają narzędzi.

GENIALNY POMYSŁ #8 z Raportu v7.0:
Agenty mogą używać NARZĘDZI:
- search_invoices(nip) — przeszukaj DuckDB
- fetch_gus(nip) — pobierz dane z GUS BIR
- check_whitelist(nip) — sprawdź Białą Listę MF
- calculate_vat(amount, rate) — oblicz VAT
Zamiast polegać tylko na danych z promptu, agent AKTYWNIE pobiera dodatkowe informacje.
"""

from __future__ import annotations

import asyncio
from typing import Any, Callable, Coroutine

from structlog import get_logger

logger = get_logger("nexus.agents.tools")


# ── Tool Definition ────────────────────────────────────────────────────


class Tool:
    """Definicja narzędzia dla agenta z funkcją do wykonania."""

    def __init__(
        self,
        name: str,
        description: str,
        func: Callable[..., Coroutine[Any, Any, Any]],
        parameters: dict[str, Any] | None = None,
    ) -> None:
        self.name = name
        self.description = description
        self.func = func
        self.parameters = parameters or {}
        self.call_count: int = 0

    async def execute(self, **kwargs: Any) -> Any:
        """Wykonaj narzędzie."""
        self.call_count += 1
        logger.debug("[TOOLS] Executing: %s(%s)", self.name, kwargs)
        try:
            return await self.func(**kwargs)
        except Exception as exc:
            logger.error("[TOOLS] Tool %s failed: %s", self.name, exc)
            raise

    def __repr__(self) -> str:
        return f"Tool({self.name})"


class ToolRegistry:
    """Rejestr narzędzi dla agentów — Agentic RAG.

    GENIALNY POMYSŁ #8:
    - search_invoices(nip) — przeszukaj DuckDB
    - fetch_gus(nip) — pobierz dane z GUS BIR
    - check_whitelist(nip) — sprawdź Białą Listę MF
    - calculate_vat(amount, rate) — oblicz VAT
    - check_ksef_status(invoice_id) — sprawdź status KSeF
    - get_vendor_history(nip) — pobierz historię kontrahenta
    - analyze_cash_flow(days) — przeanalizuj przepływy
    """

    def __init__(self) -> None:
        self._tools: dict[str, Tool] = {}
        self._usage_stats: dict[str, int] = {}

    # ── Registration ────────────────────────────────────────────────

    def register(
        self,
        name: str,
        description: str,
        func: Callable[..., Coroutine[Any, Any, Any]],
        parameters: dict[str, Any] | None = None,
    ) -> Tool:
        """Zarejestruj nowe narzędzie."""
        tool = Tool(name=name, description=description, func=func, parameters=parameters)
        self._tools[name] = tool
        logger.info("[TOOLS] Registered: %s", name)
        return tool

    def unregister(self, name: str) -> None:
        self._tools.pop(name, None)

    # ── Execution ───────────────────────────────────────────────────

    async def execute(
        self, tool_name: str, **kwargs: Any
    ) -> Any:
        """Wykonaj narzędzie po nazwie."""
        tool = self._tools.get(tool_name)
        if not tool:
            raise ValueError(f"Unknown tool: {tool_name}")

        self._usage_stats[tool_name] = self._usage_stats.get(tool_name, 0) + 1
        return await tool.execute(**kwargs)

    async def execute_parallel(
        self, calls: list[dict[str, Any]]
    ) -> list[Any]:
        """Wykonaj wiele narzędzi równolegle."""
        tasks = []
        for call in calls:
            tool_name = call["tool"]
            kwargs = call.get("params", {})
            tasks.append(self.execute(tool_name, **kwargs))
        return await asyncio.gather(*tasks, return_exceptions=True)

    def get_tool_descriptions(self) -> str:
        """Generuj opis narzędzi dla promptu agenta."""
        if not self._tools:
            return ""

        parts = ["\nDostępne narzędzia:"]
        for name, tool in self._tools.items():
            parts.append(f"- {name}: {tool.description}")
            if tool.parameters:
                params_str = ", ".join(
                    f"{k}: {v}" for k, v in tool.parameters.items()
                )
                parts.append(f"  Parametry: {params_str}")
        return "\n".join(parts)

    # ── Stats ───────────────────────────────────────────────────────

    @property
    def tools(self) -> list[str]:
        return list(self._tools.keys())

    @property
    def tool_count(self) -> int:
        return len(self._tools)

    def get_stats(self) -> dict[str, Any]:
        return {
            "tools_registered": len(self._tools),
            "tool_names": list(self._tools.keys()),
            "usage_stats": dict(self._usage_stats),
            "total_calls": sum(self._usage_stats.values()),
        }


# ── Predefiniowane factory dla narzędzi agentowych ────────────────────


def create_default_tool_registry(
    duckdb_manager: Any = None,
    gus_client: Any = None,
    white_list_service: Any = None,
) -> ToolRegistry:
    """Utwórz rejestr z domyślnymi narzędziami agentowymi.

    GENIALNY POMYSŁ #8:
    Predefiniowane narzędzia dla agentów NexusAI.
    """

    registry = ToolRegistry()

    # Tool 1: search_invoices
    async def _search_invoices(nip: str = "", limit: int = 10) -> dict[str, Any]:
        """Przeszukaj faktury w DuckDB po NIP."""
        if duckdb_manager and hasattr(duckdb_manager, 'execute'):
            try:
                rows = duckdb_manager.execute(
                    "SELECT invoice_id, amount_gross, date, category FROM invoices "
                    "WHERE nip = ? LIMIT ?",
                    (nip, limit),
                ).fetchall()
                return {"count": len(rows), "invoices": [
                    {"id": r[0], "amount": r[1], "date": r[2], "category": r[3]}
                    for r in rows
                ]}
            except Exception as exc:
                logger.debug("[TOOLS] search_invoices failed: %s", exc)
        return {"count": 0, "invoices": []}

    registry.register(
        "search_invoices",
        "Przeszukaj faktury w DuckDB po NIP kontrahenta. Zwraca listę faktur.",
        _search_invoices,
        {"nip": "str", "limit": "int=10"},
    )

    # Tool 2: fetch_gus
    async def _fetch_gus(nip: str = "") -> dict[str, Any]:
        """Pobierz dane z GUS BIR."""
        if gus_client and hasattr(gus_client, 'fetch'):
            try:
                return await gus_client.fetch(nip)
            except Exception as exc:
                logger.debug("[TOOLS] fetch_gus failed: %s", exc)
        return {"nip": nip, "status": "gus_unavailable", "data": {}}

    registry.register(
        "fetch_gus",
        "Pobierz dane o firmie z GUS BIR (NIP, REGON, status).",
        _fetch_gus,
        {"nip": "str"},
    )

    # Tool 3: check_whitelist
    async def _check_whitelist(
        nip: str = "", bank_account: str = ""
    ) -> dict[str, Any]:
        """Sprawdź Białą Listę MF."""
        if white_list_service and hasattr(white_list_service, 'check'):
            try:
                return await white_list_service.check(nip, bank_account)
            except Exception as exc:
                logger.debug("[TOOLS] check_whitelist failed: %s", exc)
        return {"nip": nip, "on_whitelist": False, "status": "unavailable"}

    registry.register(
        "check_whitelist",
        "Sprawdź czy NIP i konto bankowe są na Białej Liście MF.",
        _check_whitelist,
        {"nip": "str", "bank_account": "str=''"},
    )

    # Tool 4: calculate_vat
    async def _calculate_vat(
        amount: float = 0.0, rate: float = 0.23
    ) -> dict[str, Any]:
        """Oblicz VAT."""
        vat = amount * rate
        net = amount / (1 + rate)
        return {"amount_gross": amount, "rate": rate, "vat": round(vat, 2), "net": round(net, 2)}

    registry.register(
        "calculate_vat",
        "Oblicz VAT od kwoty brutto. rate to stawka VAT (0.23, 0.08, 0.05, 0.00).",
        _calculate_vat,
        {"amount": "float", "rate": "float=0.23"},
    )

    # Tool 5: get_vendor_history
    async def _get_vendor_history(nip: str = "", days: int = 90) -> dict[str, Any]:
        """Pobierz historię kontrahenta."""
        if duckdb_manager and hasattr(duckdb_manager, 'execute'):
            try:
                rows = duckdb_manager.execute(
                    "SELECT COUNT(*), AVG(amount_gross), SUM(amount_gross) "
                    "FROM invoices WHERE nip = ?",
                    (nip,),
                ).fetchone()
                if rows:
                    return {
                        "nip": nip,
                        "total_invoices": int(rows[0]) if rows[0] else 0,
                        "avg_amount": round(float(rows[1]), 2) if rows[1] else 0,
                        "total_amount": round(float(rows[2]), 2) if rows[2] else 0,
                    }
            except Exception as exc:
                logger.debug("[TOOLS] get_vendor_history failed: %s", exc)
        return {"nip": nip, "total_invoices": 0}

    registry.register(
        "get_vendor_history",
        "Pobierz historię faktur od kontrahenta — ile faktur, średnia kwota, suma.",
        _get_vendor_history,
        {"nip": "str", "days": "int=90"},
    )

    # Tool 6: analyze_cash_flow
    async def _analyze_cash_flow(days: int = 30) -> dict[str, Any]:
        """Analiza cash flow."""
        if duckdb_manager and hasattr(duckdb_manager, 'execute'):
            try:
                rows = duckdb_manager.execute(
                    "SELECT date, SUM(amount_gross) FROM cash_flow "
                    "WHERE date >= CURRENT_DATE - INTERVAL ? DAYS GROUP BY date ORDER BY date",
                    (days,),
                ).fetchall()
                return {"days": days, "daily_balances": [
                    {"date": r[0], "amount": r[1]} for r in rows
                ]}
            except Exception as exc:
                logger.debug("[TOOLS] analyze_cash_flow failed: %s", exc)
        return {"days": days, "daily_balances": []}

    registry.register(
        "analyze_cash_flow",
        "Analizuj przepływy pieniężne — codzienne saldo.",
        _analyze_cash_flow,
        {"days": "int=30"},
    )

    logger.info("[TOOLS] Default registry created with %d tools", registry.tool_count)
    return registry
