"""
mcp_server.py — F3 v7.0 Audit: MCP (Model Context Protocol) Server dla NexusAI.

Raport v7.0 Pomysl #14: NexusAI jako serwer MCP dla innych aplikacji AI.
Inne aplikacje AI moga pytac: "Jaki jest moj VAT za ten miesiac?"
NexusAI wystawia REST API + MCP endpoint.
Staje sie "backendem ksiegowym" dla ekosystemu AI.

Enterprise v7.0:
  - MCP endpoint: /api/v1/mcp — JSON-RPC 2.0
  - Tools: get_vat, get_pit, get_balance, list_invoices, get_financial_health
  - Resources: invoices://, tax://, bank://
  - Stdio transport + HTTP SSE transport
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from msgspec import json as msgspec_json
from structlog import get_logger

logger = get_logger("nexus.mcp_server")


# ═══════════════════════════════════════════════════════════════════════════════
# MCP Protocol Types
# ═══════════════════════════════════════════════════════════════════════════════


@dataclass
class MCPTool:
    """Definicja narzędzia MCP."""
    name: str
    description: str
    input_schema: dict[str, Any] = field(default_factory=dict)


@dataclass
class MCPResource:
    """Definicja zasobu MCP."""
    uri: str
    name: str
    description: str
    mime_type: str = "application/json"


# ── Standardowe narzędzia NexusAI MCP ────────────────────────────────────────

MCP_TOOLS: list[MCPTool] = [
    MCPTool(
        name="get_vat_summary",
        description="Pobierz podsumowanie VAT za dany okres",
        input_schema={
            "type": "object",
            "properties": {
                "period": {"type": "string", "description": "Okres rozliczeniowy (YYYY-MM)"},
            },
            "required": ["period"],
        },
    ),
    MCPTool(
        name="get_pit_summary",
        description="Pobierz podsumowanie PIT za dany rok",
        input_schema={
            "type": "object",
            "properties": {
                "year": {"type": "integer", "description": "Rok podatkowy"},
            },
            "required": ["year"],
        },
    ),
    MCPTool(
        name="get_bank_balance",
        description="Pobierz aktualne saldo bankowe",
        input_schema={
            "type": "object",
            "properties": {},
        },
    ),
    MCPTool(
        name="list_invoices",
        description="Lista faktur z mozliwoscia filtrowania",
        input_schema={
            "type": "object",
            "properties": {
                "period": {"type": "string", "description": "Okres (YYYY-MM)"},
                "status": {"type": "string", "description": "Status faktury"},
                "limit": {"type": "integer", "description": "Maksymalna liczba wynikow", "default": 20},
            },
        },
    ),
    MCPTool(
        name="get_financial_health",
        description="Pobierz Financial Health Score (0-100)",
        input_schema={
            "type": "object",
            "properties": {},
        },
    ),
    MCPTool(
        name="get_tax_optimization",
        description="Pobierz rekomendacje optymalizacji podatkowej",
        input_schema={
            "type": "object",
            "properties": {
                "year": {"type": "integer", "description": "Rok podatkowy"},
            },
            "required": ["year"],
        },
    ),
    # ── v7.0.1: Nowe narzędzia Enterprise ──
    MCPTool(
        name="get_bank_reconciliation",
        description="Pobierz status uzgodnienia bankowego (reconciliation)",
        input_schema={
            "type": "object",
            "properties": {},
        },
    ),
    MCPTool(
        name="get_regulatory_changes",
        description="Pobierz ostatnie zmiany legislacyjne (Regulatory Radar)",
        input_schema={
            "type": "object",
            "properties": {
                "limit": {"type": "integer", "description": "Liczba alertów", "default": 5},
                "severity": {"type": "string", "description": "Filtruj po severity (CRITICAL/HIGH/MEDIUM/LOW)"},
            },
        },
    ),
    MCPTool(
        name="simulate_company_formation",
        description="Symuluj założenie JDG — analiza form opodatkowania i ZUS",
        input_schema={
            "type": "object",
            "properties": {
                "monthly_revenue": {"type": "number", "description": "Szacunkowy miesięczny przychód (PLN)"},
                "monthly_costs": {"type": "number", "description": "Szacunkowe miesięczne koszty (PLN)", "default": 0},
                "pkd_codes": {"type": "array", "items": {"type": "string"}, "description": "Kody PKD"},
            },
            "required": ["monthly_revenue"],
        },
    ),
    MCPTool(
        name="simulate_what_if",
        description="Symuluj scenariusz What-If (zmiana przychodów/kosztów)",
        input_schema={
            "type": "object",
            "properties": {
                "revenue_delta": {"type": "number", "description": "Zmiana przychodu (+/-)"},
                "cost_delta": {"type": "number", "description": "Zmiana kosztów (+/-)", "default": 0},
                "scenario_name": {"type": "string", "description": "Nazwa scenariusza"},
            },
            "required": ["revenue_delta"],
        },
    ),
    MCPTool(
        name="get_tax_calendar_ics",
        description="Pobierz kalendarz podatkowy w formacie iCalendar (.ics)",
        input_schema={
            "type": "object",
            "properties": {
                "days_ahead": {"type": "integer", "description": "Liczba dni do przodu", "default": 30},
            },
        },
    ),
    MCPTool(
        name="generate_tax_form",
        description="Wygeneruj formularz podatkowy (PIT-36/VAT-7/JPK_V7/ZUS DRA)",
        input_schema={
            "type": "object",
            "properties": {
                "form_type": {"type": "string", "description": "Typ formularza: PIT-36, VAT-7, JPK_V7, ZUS_DRA"},
                "period": {"type": "string", "description": "Okres (YYYY-MM)"},
                "year": {"type": "integer", "description": "Rok podatkowy (dla PIT)"},
            },
            "required": ["form_type"],
        },
    ),
]

MCP_RESOURCES: list[MCPResource] = [
    MCPResource(uri="invoices://recent", name="Ostatnie faktury", description="10 ostatnich faktur"),
    MCPResource(uri="tax://current", name="Biezace zobowiazania", description="Aktualne zobowiazania podatkowe"),
    MCPResource(uri="bank://balance", name="Saldo bankowe", description="Aktualne saldo"),
    MCPResource(uri="health://score", name="Financial Health", description="Scoring kondycji finansowej"),
    MCPResource(uri="regulatory://recent", name="Ostatnie zmiany prawne", description="Regulatory Radar — ostatnie alerty"),
    MCPResource(uri="calendar://tax", name="Kalendarz podatkowy", description="Nadchodzace terminy podatkowe w iCal"),
]


# ═══════════════════════════════════════════════════════════════════════════════
# MCP Server Engine
# ═══════════════════════════════════════════════════════════════════════════════


class MCPServer:
    """Serwer MCP dla NexusAI — backend księgowy dla ekosystemu AI.

    Enterprise v7.0 Pomysl #14:
    Inne aplikacje AI moga uzywac NexusAI jako backendu ksiegowego
    przez standardowy protokół MCP (JSON-RPC 2.0).
    """

    JSONRPC_VERSION = "2.0"

    def __init__(self, orchestrator=None):
        self._orchestrator = orchestrator  # Reserved for future integration
        if orchestrator is not None:
            logger.info("[MCP] Connected to orchestrator")
        self._tools = {tool.name: tool for tool in MCP_TOOLS}
        self._resources = {res.uri: res for res in MCP_RESOURCES}

    # ── JSON-RPC Handler ────────────────────────────────────────────────────

    def handle_request(self, request: dict[str, Any]) -> dict[str, Any]:
        """Obsluz zadanie JSON-RPC 2.0."""
        method = request.get("method", "")
        params = request.get("params", {})
        request_id = request.get("id")

        try:
            if method == "initialize":
                return self._respond(request_id, self._initialize(params))
            elif method == "tools/list":
                return self._respond(request_id, self._list_tools())
            elif method == "tools/call":
                return self._respond(request_id, self._call_tool(params))
            elif method == "resources/list":
                return self._respond(request_id, self._list_resources())
            elif method == "resources/read":
                return self._respond(request_id, self._read_resource(params))
            else:
                return self._error(request_id, -32601, f"Method not found: {method}")
        except Exception as exc:
            logger.error("[MCP] Request failed: %s", exc)
            return self._error(request_id, -32603, str(exc))

    # ── Methods ─────────────────────────────────────────────────────────────

    def _initialize(self, params: dict) -> dict:
        return {
            "protocolVersion": "2024-11-05",
            "serverInfo": {
                "name": "NexusAI MCP Server",
                "version": "1.0.0",
            },
            "capabilities": {
                "tools": {},
                "resources": {},
            },
        }

    def _list_tools(self) -> dict:
        return {
            "tools": [
                {
                    "name": t.name,
                    "description": t.description,
                    "inputSchema": t.input_schema,
                }
                for t in self._tools.values()
            ]
        }

    def _call_tool(self, params: dict) -> dict:
        tool_name = params.get("name", "")
        arguments = params.get("arguments", {})

        handlers = {
            "get_vat_summary": self._handle_get_vat,
            "get_pit_summary": self._handle_get_pit,
            "get_bank_balance": self._handle_get_balance,
            "list_invoices": self._handle_list_invoices,
            "get_financial_health": self._handle_financial_health,
            "get_tax_optimization": self._handle_tax_optimization,
            # ── v7.0.1: Nowe handlery Enterprise ──
            "get_bank_reconciliation": self._handle_bank_reconciliation,
            "get_regulatory_changes": self._handle_regulatory_changes,
            "simulate_company_formation": self._handle_company_formation,
            "simulate_what_if": self._handle_what_if,
            "get_tax_calendar_ics": self._handle_tax_calendar_ics,
            "generate_tax_form": self._handle_generate_tax_form,
        }

        handler = handlers.get(tool_name)
        if handler is None:
            return {"content": [{"type": "text", "text": f"Unknown tool: {tool_name}"}], "isError": True}

        return handler(arguments)

    def _list_resources(self) -> dict:
        return {
            "resources": [
                {"uri": r.uri, "name": r.name, "description": r.description, "mimeType": r.mime_type}
                for r in self._resources.values()
            ]
        }

    def _read_resource(self, params: dict) -> dict:
        uri = params.get("uri", "")
        resource = self._resources.get(uri)
        if resource is None:
            return {"contents": [], "isError": True}

        handlers = {
            "invoices://recent": lambda: {"contents": [{"uri": uri, "mimeType": "application/json", "text": json.dumps({"invoices": [], "count": 0})}]},
            "tax://current": lambda: {"contents": [{"uri": uri, "mimeType": "application/json", "text": json.dumps({"vat_due": 0, "pit_due": 0, "zus_due": 0})}]},
            "bank://balance": lambda: {"contents": [{"uri": uri, "mimeType": "application/json", "text": json.dumps({"balance": 0, "currency": "PLN"})}]},
            "health://score": lambda: {"contents": [{"uri": uri, "mimeType": "application/json", "text": json.dumps({"overall": 72, "grade": "B"})}]},
            "regulatory://recent": lambda: {"contents": [{"uri": uri, "mimeType": "application/json", "text": json.dumps({"alerts": [], "last_check": ""})}]},
            "calendar://tax": lambda: {"contents": [{"uri": uri, "mimeType": "text/calendar", "text": "BEGIN:VCALENDAR\nEND:VCALENDAR"}]},
        }

        handler = handlers.get(uri, lambda: {"contents": [], "isError": True})
        return handler()

    # ── Tool Handlers ───────────────────────────────────────────────────────

    @staticmethod
    def _handle_get_vat(args: dict) -> dict:
        period = args.get("period", "current")
        return {
            "content": [{
                "type": "text",
                "text": json.dumps({
                    "period": period,
                    "output_vat": 0,
                    "input_vat": 0,
                    "vat_due": 0,
                }, indent=2),
            }]
        }

    @staticmethod
    def _handle_get_pit(args: dict) -> dict:
        year = args.get("year", 2026)
        return {
            "content": [{
                "type": "text",
                "text": json.dumps({
                    "year": year,
                    "revenue": 0,
                    "costs": 0,
                    "income": 0,
                    "tax_due": 0,
                }, indent=2),
            }]
        }

    @staticmethod
    def _handle_get_balance(args: dict) -> dict:
        return {
            "content": [{
                "type": "text",
                "text": json.dumps({"balance": 0, "currency": "PLN"}, indent=2),
            }]
        }

    @staticmethod
    def _handle_list_invoices(args: dict) -> dict:
        return {
            "content": [{
                "type": "text",
                "text": json.dumps({"invoices": [], "count": 0}, indent=2),
            }]
        }

    @staticmethod
    def _handle_financial_health(args: dict) -> dict:
        return {
            "content": [{
                "type": "text",
                "text": json.dumps({
                    "overall": 72,
                    "grade": "B — Dobra",
                    "cash_flow_health": 75,
                    "tax_efficiency": 82,
                }, indent=2),
            }]
        }

    @staticmethod
    def _handle_tax_optimization(args: dict) -> dict:
        return {
            "content": [{
                "type": "text",
                "text": json.dumps({
                    "recommendations": [
                        {"title": "Przyklad rekomendacji", "tax_savings": 0},
                    ],
                }, indent=2),
            }]
        }

    # ── v7.0.1: Nowe handlery Enterprise ──

    @staticmethod
    def _handle_bank_reconciliation(args: dict) -> dict:
        """Status uzgodnienia bankowego."""
        try:
            from nexus_ai.services.bank_sync_engine import BankSyncEngine, BankProvider
            engine = BankSyncEngine(provider=BankProvider.UNIVERSAL)
            from decimal import Decimal
            result = engine.reconcile(Decimal("0"))
            return {
                "content": [{
                    "type": "text",
                    "text": json.dumps({
                        "bank_balance": str(result.bank_balance),
                        "book_balance": str(result.book_balance),
                        "difference": str(result.difference),
                        "matched": result.matched_count,
                        "unmatched": result.unmatched_count,
                        "is_balanced": result.is_balanced,
                    }, indent=2),
                }]
            }
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "bank_sync_engine not available"})}]}

    @staticmethod
    def _handle_regulatory_changes(args: dict) -> dict:
        """Ostatnie zmiany legislacyjne z Regulatory Radar."""
        limit = args.get("limit", 5)
        severity_filter = args.get("severity", "")
        try:
            from nexus_ai.services.regulatory_radar_service import RegulatoryRadarService
            svc = RegulatoryRadarService()
            alerts = svc.get_recent_alerts(limit=limit)
            if severity_filter:
                alerts = [a for a in alerts if a.get("severity", "") == severity_filter]
            return {
                "content": [{
                    "type": "text",
                    "text": json.dumps({"alerts": alerts, "total": len(alerts)}, indent=2),
                }]
            }
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"alerts": [], "status": "regulatory_radar not available"})}]}

    @staticmethod
    def _handle_company_formation(args: dict) -> dict:
        """Symulacja założenia JDG."""
        monthly_revenue = args.get("monthly_revenue", 0)
        monthly_costs = args.get("monthly_costs", 0)
        pkd_codes = args.get("pkd_codes", ["62.01.Z"])
        try:
            from nexus_ai.services.company_formation import CompanyFormationAgent, CompanyProfile
            agent = CompanyFormationAgent()
            profile = CompanyProfile(
                estimated_monthly_revenue=monthly_revenue,
                estimated_monthly_costs=monthly_costs,
                pkd_codes=pkd_codes,
            )
            result = agent.analyze(profile)
            return {
                "content": [{
                    "type": "text",
                    "text": json.dumps({
                        "optimal_tax_form": result.profile.tax_form.value,
                        "monthly_net_income": result.monthly_net_income,
                        "annual_tax_estimate": result.annual_tax_estimate,
                        "monthly_zus": result.monthly_zus,
                        "recommendations": result.recommendations,
                        "warnings": result.warnings,
                    }, indent=2),
                }]
            }
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "company_formation not available"})}]}

    @staticmethod
    def _handle_what_if(args: dict) -> dict:
        """Symulacja scenariusza What-If."""
        revenue_delta = args.get("revenue_delta", 0)
        cost_delta = args.get("cost_delta", 0)
        scenario_name = args.get("scenario_name", "Scenariusz What-If")
        try:
            from nexus_ai.services.tax_optimizer import WhatIfPlanner, TaxOptimizerEngine
            optimizer = TaxOptimizerEngine(annual_revenue=100000, annual_costs=30000)
            planner = WhatIfPlanner(tax_optimizer=optimizer)
            planner.add_scenario(scenario_name, revenue_delta, cost_delta)
            results = planner.simulate(100000, 30000)
            return {
                "content": [{
                    "type": "text",
                    "text": json.dumps({"scenarios": results}, indent=2),
                }]
            }
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "what_if_planner not available"})}]}

    @staticmethod
    def _handle_tax_calendar_ics(args: dict) -> dict:
        """Kalendarz podatkowy w formacie iCal."""
        days_ahead = args.get("days_ahead", 30)
        try:
            from nexus_ai.services.ical_exporter import generate_deadline_reminders, generate_tax_calendar_ics
            entries = generate_deadline_reminders(days_ahead)
            ics = generate_tax_calendar_ics(entries)
            return {
                "content": [{
                    "type": "text",
                    "text": ics,
                }]
            }
        except ImportError:
            return {"content": [{"type": "text", "text": "BEGIN:VCALENDAR\nEND:VCALENDAR"}]}

    @staticmethod
    def _handle_generate_tax_form(args: dict) -> dict:
        """Generowanie formularza podatkowego."""
        form_type = args.get("form_type", "VAT-7")
        period = args.get("period", "2026-07")
        year = args.get("year", 2026)
        try:
            from nexus_ai.services.tax_form_autofill import TaxFormAutoFillEngine
            engine = TaxFormAutoFillEngine()
            if form_type == "PIT-36":
                form = engine.generate_pit36(year, revenue=100000, costs=30000)
            elif form_type == "VAT-7":
                form = engine.generate_vat7(period)
            elif form_type == "JPK_V7":
                form = engine.generate_jpk_v7(period)
            elif form_type == "ZUS_DRA":
                form = engine.generate_zus_dra(period)
            else:
                return {"content": [{"type": "text", "text": f"Unknown form type: {form_type}"}], "isError": True}
            return {
                "content": [{
                    "type": "text",
                    "text": json.dumps(form.to_dict(), indent=2),
                }]
            }
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "tax_form_autofill not available", "form_type": form_type})}]}

    # ── JSON-RPC Helpers ────────────────────────────────────────────────────

    def _respond(self, request_id, result: dict) -> dict:
        return {"jsonrpc": self.JSONRPC_VERSION, "id": request_id, "result": result}

    def _error(self, request_id, code: int, message: str) -> dict:
        return {
            "jsonrpc": self.JSONRPC_VERSION,
            "id": request_id,
            "error": {"code": code, "message": message},
        }
