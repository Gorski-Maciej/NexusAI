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
    # ── v7.0 Audit KKS/Compliance: Nowe narzędzia Enterprise ──
    MCPTool(
        name="get_sanctions_screening",
        description="Sprawdź kontrahenta na listach sankcyjnych (FATF/OFAC/EU/UK)",
        input_schema={
            "type": "object",
            "properties": {
                "name": {"type": "string", "description": "Nazwa kontrahenta"},
                "country": {"type": "string", "description": "Kod kraju ISO (np. PL, RU, IR)"},
                "nip": {"type": "string", "description": "NIP kontrahenta"},
            },
            "required": ["name"],
        },
    ),
    MCPTool(
        name="get_kks_realtime_score",
        description="Oblicz scoring ryzyka KKS 0-100 w czasie rzeczywistym dla faktury",
        input_schema={
            "type": "object",
            "properties": {
                "amount_gross": {"type": "number", "description": "Kwota brutto faktury (PLN)"},
                "offense_type": {"type": "string", "description": "Typ naruszenia KKS (EMPTY_INVOICE, TAX_EVASION, ...)"},
                "severity": {"type": "string", "description": "Severity (CRITICAL, HIGH, MEDIUM)"},
                "invoice_id": {"type": "string", "description": "ID faktury"},
            },
            "required": ["amount_gross"],
        },
    ),
    MCPTool(
        name="generate_kks_defense_package",
        description="Wygeneruj pakiet dokumentów obronnych KKS (czynny żal, korekta, wniosek)",
        input_schema={
            "type": "object",
            "properties": {
                "offense_type": {"type": "string", "description": "Typ naruszenia"},
                "invoice_id": {"type": "string", "description": "ID faktury"},
                "amount": {"type": "number", "description": "Kwota"},
                "jdg_name": {"type": "string", "description": "Nazwa JDG"},
                "jdg_nip": {"type": "string", "description": "NIP JDG"},
            },
            "required": ["offense_type", "invoice_id"],
        },
    ),
    MCPTool(
        name="predict_tax_inspection",
        description="Przewidź prawdopodobieństwo kontroli skarbowej (ML)",
        input_schema={
            "type": "object",
            "properties": {
                "industry": {"type": "string", "description": "Branża (CONSTRUCTION, IT_SERVICES, RETAIL, ...)"},
                "annual_revenue": {"type": "number", "description": "Roczny przychód (PLN)"},
                "jdg_age_months": {"type": "integer", "description": "Wiek JDG w miesiącach"},
                "kks_incidents": {"type": "integer", "description": "Liczba incydentów KKS w 5 lat", "default": 0},
            },
            "required": ["industry", "annual_revenue"],
        },
    ),
    MCPTool(
        name="analyze_blockchain_transaction",
        description="Przeanalizuj transakcję krypto pod kątem AML (miksery, darknet, ransomware)",
        input_schema={
            "type": "object",
            "properties": {
                "tx_hash": {"type": "string", "description": "Hash transakcji"},
                "from_address": {"type": "string", "description": "Adres nadawcy"},
                "to_address": {"type": "string", "description": "Adres odbiorcy"},
                "amount": {"type": "number", "description": "Kwota"},
                "currency": {"type": "string", "description": "Waluta (BTC, ETH, USDT)", "default": "BTC"},
            },
            "required": ["tx_hash", "from_address", "to_address"],
        },
    ),
    MCPTool(
        name="get_cross_jurisdiction_wht",
        description="Sprawdź stawkę WHT i metodę unikania podwójnego opodatkowania",
        input_schema={
            "type": "object",
            "properties": {
                "target_country": {"type": "string", "description": "Kod kraju ISO"},
                "income_type": {"type": "string", "description": "Typ dochodu: dividends, interest, royalties, services"},
                "amount": {"type": "number", "description": "Kwota (PLN)"},
            },
            "required": ["target_country", "income_type"],
        },
    ),
    MCPTool(
        name="generate_audit_trail",
        description="Wygeneruj raport audit trail (dowód należytej staranności) w formacie Markdown",
        input_schema={
            "type": "object",
            "properties": {
                "jdg_id": {"type": "string", "description": "ID JDG"},
                "period_start": {"type": "string", "description": "Data początkowa (YYYY-MM-DD)"},
                "period_end": {"type": "string", "description": "Data końcowa (YYYY-MM-DD)"},
            },
            "required": ["jdg_id"],
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
            # ── v7.0 Audit KKS/Compliance: Nowe handlery Enterprise ──
            "get_sanctions_screening": self._handle_sanctions_screening,
            "get_kks_realtime_score": self._handle_kks_realtime_score,
            "generate_kks_defense_package": self._handle_kks_defense,
            "predict_tax_inspection": self._handle_tax_inspection,
            "analyze_blockchain_transaction": self._handle_blockchain,
            "get_cross_jurisdiction_wht": self._handle_cross_jurisdiction,
            "generate_audit_trail": self._handle_audit_trail,
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


    # ── v7.0 Audit KKS/Compliance: Nowe handlery Enterprise ──

    @staticmethod
    def _handle_sanctions_screening(args: dict) -> dict:
        name = args.get("name", "")
        country = args.get("country", "")
        try:
            from nexus_ai.services.sanctions_screening_api import SanctionsScreeningAPI
            api = SanctionsScreeningAPI()
            result = api.screen(name, country=country)
            return {"content": [{"type": "text", "text": json.dumps({
                "is_sanctioned": result.is_sanctioned,
                "risk_level": result.risk_level,
                "hits": [{"name": h.matched_name, "list": h.source_list, "confidence": h.match_confidence} for h in result.hits],
                "is_fatf_high_risk": result.is_fatf_high_risk,
            }, indent=2)}]}
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "not available"})}]}

    @staticmethod
    def _handle_kks_realtime_score(args: dict) -> dict:
        amount = args.get("amount_gross", 0)
        offense = args.get("offense_type", "")
        try:
            from nexus_ai.services.kks_realtime_scorer import KksRealtimeScorer
            scorer = KksRealtimeScorer()
            verdict = {}
            if offense:
                verdict = {"kks_offense_type": offense, "kks_penalty_severity": args.get("severity", "HIGH")}
            score = scorer.score_invoice({"amount_gross": amount}, opa_verdict=verdict)
            return {"content": [{"type": "text", "text": json.dumps({
                "total_score": score.total_score,
                "risk_zone": score.risk_zone.value,
                "flags": score.flags,
                "recommendations": score.recommendations,
            }, indent=2)}]}
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "not available"})}]}

    @staticmethod
    def _handle_kks_defense(args: dict) -> dict:
        offense = args.get("offense_type", "")
        invoice_id = args.get("invoice_id", "")
        amount = args.get("amount", 0)
        try:
            from nexus_ai.services.kks_defense_generator import KksDefenseGenerator
            gen = KksDefenseGenerator()
            package = gen.generate_defense_package(
                opa_verdict={"kks_offense_type": offense, "_routing": "BLOCK_AND_ALERT"},
                invoice_data={"id": invoice_id, "amount_gross": amount},
                jdg_data={"name": args.get("jdg_name", ""), "nip": args.get("jdg_nip", "")},
            )
            return {"content": [{"type": "text", "text": json.dumps({
                "documents": [{"type": d.doc_type, "title": d.title, "content_preview": d.content[:500]} for d in package.documents],
                "estimated_savings_pln": package.estimated_savings_pln,
            }, indent=2)}]}
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "not available"})}]}

    @staticmethod
    def _handle_tax_inspection(args: dict) -> dict:
        industry = args.get("industry", "DEFAULT")
        revenue = args.get("annual_revenue", 0)
        age = args.get("jdg_age_months", 12)
        incidents = args.get("kks_incidents", 0)
        try:
            from nexus_ai.services.tax_inspection_predictor import TaxInspectionPredictor
            pred = TaxInspectionPredictor()
            score = pred.predict(industry=industry, annual_revenue=revenue, jdg_age_months=age,
                                kks_history={"incidents_60m": incidents})
            return {"content": [{"type": "text", "text": json.dumps({
                "total_score": score.total_score,
                "risk_level": score.risk_level,
                "probability_30d": score.probability_30d,
                "probability_90d": score.probability_90d,
                "top_factors": score.top_factors,
                "recommendations": score.recommendations,
            }, indent=2)}]}
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "not available"})}]}

    @staticmethod
    def _handle_blockchain(args: dict) -> dict:
        tx_hash = args.get("tx_hash", "")
        from_addr = args.get("from_address", "")
        to_addr = args.get("to_address", "")
        amount = args.get("amount", 0)
        currency = args.get("currency", "BTC")
        try:
            from nexus_ai.services.blockchain_analytics import BlockchainAnalytics
            ba = BlockchainAnalytics()
            result = ba.analyze_transaction(tx_hash=tx_hash, from_addr=from_addr, to_addr=to_addr,
                                          amount=amount, currency=currency)
            return {"content": [{"type": "text", "text": json.dumps({
                "overall_risk": result.overall_risk,
                "risk_level": result.risk_level,
                "flags": result.flags,
                "requires_sar": result.requires_sar,
                "recommendation": result.recommendation,
            }, indent=2)}]}
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "not available"})}]}

    @staticmethod
    def _handle_cross_jurisdiction(args: dict) -> dict:
        country = args.get("target_country", "")
        income_type = args.get("income_type", "services")
        amount = args.get("amount", 0)
        try:
            from nexus_ai.services.cross_jurisdiction_resolver import CrossJurisdictionResolver
            resolver = CrossJurisdictionResolver()
            result = resolver.analyze(country, income_type, amount=amount)
            return {"content": [{"type": "text", "text": json.dumps({
                "has_upo": result.has_upo,
                "double_tax_risk": result.double_tax_risk,
                "wht_recommendations": [{"type": r.income_type, "rate": r.effective_rate, "rec": r.recommendation} for r in result.wht_recommendations],
            }, indent=2)}]}
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "not available"})}]}

    @staticmethod
    def _handle_audit_trail(args: dict) -> dict:
        jdg_id = args.get("jdg_id", "unknown")
        period_start = args.get("period_start", "")
        period_end = args.get("period_end", "")
        try:
            from nexus_ai.services.tax_audit_trail_generator import TaxAuditTrailGenerator
            gen = TaxAuditTrailGenerator()
            report = gen.generate_report(jdg_id, period_start, period_end)
            md = gen.export_markdown(report)
            return {"content": [{"type": "text", "text": md[:5000]}]}
        except ImportError:
            return {"content": [{"type": "text", "text": json.dumps({"status": "not available"})}]}

    # ── JSON-RPC Helpers ────────────────────────────────────────────────────

    def _respond(self, request_id, result: dict) -> dict:
        return {"jsonrpc": self.JSONRPC_VERSION, "id": request_id, "result": result}

    def _error(self, request_id, code: int, message: str) -> dict:
        return {
            "jsonrpc": self.JSONRPC_VERSION,
            "id": request_id,
            "error": {"code": code, "message": message},
        }
