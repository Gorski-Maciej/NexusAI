"""System operational endpoints -- consolidated from 8 files.

Zawiera:
  - /system/i18n         -- I18nOpsController
  - /system/security     -- SecurityPostureController
  - /system/circuit-breakers -- CircuitBreakerController
  - /system/telemetry    -- TelemetryOpsController
  - /system/finops       -- FinOpsController
  - /system/privacy      -- PrivacyController
  - /system/kore         -- KoreAuditController
  - /version             -- VersionController
"""

from __future__ import annotations

import os
import resource
from pathlib import Path
from typing import Any

from litestar import Controller, get, post
from sqlmodel import text

from nexus_ai.api.dto import (
    TAG_AUDIT,
    TAG_FINANCE,
    TAG_I18N,
    TAG_PRIVACY,
    TAG_SECURITY,
    TAG_SYSTEM,
    CircuitBreakerStatusDTO,
    FinOpsDTO,
    GenericDictDTO,
    I18nStatusDTO,
    KoreAuditDTO,
    PiiScanDTO,
    SecurityPostureDTO,
    TelemetryFallbackStatusDTO,
    VersionInfoDTO,
)
from nexus_ai.api.rbac import owner_only_guard
from nexus_ai.core.config import AppConfig
from nexus_ai.core.msgspec_utils import msgspec_loads
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.database import create_oltp_engine, create_session_factory
from nexus_ai.services.finops_meter import estimate_runtime_cost
from nexus_ai.services.log_pii_monitor import notify_dpo, scan_logs_for_pii
from nexus_ai.services.otel_fallback import FileSpanBuffer
from nexus_ai.services.telemetry import flush_fallback_spans


# ── /system/i18n ────────────────────────────────────────────────────────
class I18nOpsController(Controller):
    path = "/system/i18n"
    guards = (owner_only_guard,)
    tags = (TAG_I18N,)

    @get("/status", return_dto=I18nStatusDTO, summary="Get i18n status", description="Returns available API and prompt language translations.", operation_id="getI18nStatus")
    async def status(self) -> dict:
        api_locales = Path(__file__).resolve().parent.parent / "locales"
        core_prompts = api_locales.parent / "core" / "prompts"
        return {
            "api_languages": sorted([p.stem for p in api_locales.glob("*.json")]) if api_locales.exists() else [],
            "prompt_languages": sorted([p.stem for p in core_prompts.glob("*.json")]) if core_prompts.exists() else [],
            "api_locale_dir": str(api_locales),
            "prompt_dir": str(core_prompts),
        }


# ── /system/security ────────────────────────────────────────────────────
class SecurityPostureController(Controller):
    path = "/system/security"
    guards = (owner_only_guard,)
    tags = (TAG_SECURITY,)

    @get("/summary", return_dto=SecurityPostureDTO, summary="Get security posture summary", description="Returns the security scan summary including ZAP baseline and full scan results.", operation_id="getSecurityPosture")
    async def summary(self) -> dict:
        reports = Path("reports")
        summary_file = reports / "security_scan_summary.json"
        payload: dict = {
            "summary_available": summary_file.exists(),
            "zap_baseline_available": (reports / "zap_baseline.json").exists(),
            "zap_full_available": (reports / "zap_full.json").exists(),
        }
        if summary_file.exists():
            payload["scan_summary"] = msgspec_loads(summary_file.read_bytes())
        return payload


# ── /system/circuit-breakers ────────────────────────────────────────────
class CircuitBreakerController(Controller):
    path = "/system/circuit-breakers"
    tags = (TAG_SYSTEM,)

    @get("/", return_dto=CircuitBreakerStatusDTO, summary="List circuit breakers", description="Returns resilience status managed by stamina (async-native, anyio).", operation_id="listCircuitBreakers")
    async def list_breakers(self) -> dict[str, Any]:
        return {
            "provider": "stamina",
            "status": "active",
            "details": "Retry + circuit breaker managed by stamina decorators",
            "note": "stamina does not expose a central breaker registry. Each @stamina.retry decorator manages its own state internally.",
        }


# ── /system/telemetry ───────────────────────────────────────────────────
class TelemetryOpsController(Controller):
    path = "/system/telemetry"
    guards = (owner_only_guard,)
    tags = (TAG_SYSTEM,)

    @get("/fallback-status", return_dto=TelemetryFallbackStatusDTO, summary="Get telemetry fallback status", description="Returns the status of the OpenTelemetry fallback buffer.", operation_id="getTelemetryFallbackStatus")
    async def fallback_status(self) -> dict:
        config = AppConfig()
        buffer = FileSpanBuffer(max_records=50000)
        records = buffer.read_all()
        return {"buffer_file": str(buffer.file_path), "buffer_exists": buffer.file_path.exists(), "queued_spans": len(records), "duckdb_path": str(config.duckdb_path)}

    @post("/fallback-replay", return_dto=GenericDictDTO, summary="Replay telemetry fallback spans", description="Flushes queued fallback spans to the primary telemetry backend.", operation_id="replayTelemetryFallback")
    async def fallback_replay(self) -> dict:
        config = AppConfig()
        return await flush_fallback_spans(lambda: DuckDBManager(db_path=config.duckdb_path, sqlite_path=config.sqlite_path, read_only=False), retries=3, base_delay=0.5)


# ── /system/finops ──────────────────────────────────────────────────────
class FinOpsController(Controller):
    path = "/system/finops"
    guards = (owner_only_guard,)
    tags = (TAG_FINANCE,)

    @get("/cost-per-invoice", return_dto=FinOpsDTO, summary="Get cost per invoice", description="Returns FinOps metrics: hourly cost, invoice count, and cost per invoice in USD.", operation_id="getCostPerInvoice")
    async def cost_per_invoice(self) -> dict:
        config = AppConfig()
        engine = create_oltp_engine(config)
        session_factory = create_session_factory(engine)
        cpu_cores = float(os.cpu_count() or 1)
        ram_gb = max((resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024 / 1024), 0.1)
        hourly_cost = estimate_runtime_cost(cpu_cores=cpu_cores, ram_gb=ram_gb, runtime_hours=1.0)
        try:
            async with session_factory() as session:
                total_invoices = int((await session.execute(text("SELECT COUNT(*) FROM invoices"))).scalar_one())
        finally:
            await engine.dispose()
        return {"hourly_cost_usd": float(hourly_cost), "invoice_count": total_invoices, "cost_per_invoice_usd": float(hourly_cost) / max(total_invoices, 1), "cpu_cores": cpu_cores, "ram_gb": float(ram_gb)}


# ── /system/privacy ─────────────────────────────────────────────────────
class PrivacyController(Controller):
    path = "/system/privacy"
    guards = (owner_only_guard,)
    tags = (TAG_PRIVACY,)

    @get("/pii-scan", return_dto=PiiScanDTO, summary="Scan logs for PII", description="Scans application logs for potential PII leaks and notifies the DPO if findings are detected.", operation_id="scanPiiLogs")
    async def scan_pii_logs(self) -> dict:
        config = AppConfig()
        findings = scan_logs_for_pii(config.base_dir / "app_data" / "logs")
        total = int(sum(findings.values()))
        notified = notify_dpo(config.dpo_alert_webhook, findings) if total > 0 else False
        return {"status": "ok", "findings": findings, "total_matches": total, "dpo_notified": bool(notified)}


# ── /system/kore ────────────────────────────────────────────────────────
class KoreAuditController(Controller):
    path = "/system/kore"
    guards = (owner_only_guard,)
    tags = (TAG_AUDIT,)

    @get("/audit", return_dto=KoreAuditDTO, summary="Get KORE audit report", description="Returns KORE 1-11 compliance audit report from Integrity Verifier.", operation_id="getKoreAudit")
    async def get_kore_audit(self) -> dict:
        return {"status": "ok", "kore_version": "legacy_removed", "detail": "kore_delivery_audit.py removed -- replaced by Integrity Verifier"}


# ── /.well-known/security.txt ────────────────────────────────────────────
# SUPERMOC v7.0 Security Audit: security.txt (RFC 9116) dla OWASP compliance
class SecurityTxtController(Controller):
    """RFC 9116 security.txt endpoint -- vulnerability disclosure."""

    path = "/.well-known"
    tags = (TAG_SECURITY,)

    @get(
        "/security.txt",
        media_type="text/plain",
        summary="security.txt (RFC 9116)",
        description="Standard vulnerability disclosure endpoint per RFC 9116.",
        operation_id="getSecurityTxt",
        cache=86400,
    )
    async def security_txt(self) -> str:
        return (
            "Contact: mailto:security@nexusai.app\n"
            "Expires: 2027-12-31T23:59:59Z\n"
            "Preferred-Languages: pl, en\n"
            "Canonical: https://nexusai.app/.well-known/security.txt\n"
            "Policy: https://nexusai.app/security-policy\n"
            "Acknowledgments: https://nexusai.app/security/hall-of-fame\n"
        )


# ── /version ────────────────────────────────────────────────────────────
class VersionController(Controller):
    """API version information endpoint."""

    path = "/version"
    tags = (TAG_SYSTEM,)

    @get(
        "/",
        return_dto=VersionInfoDTO,
        summary="Get API version info",
        description="Returns current API version, deprecated versions, and migration paths.",
        operation_id="getApiVersion",
        cache=3600,
    )
    async def get_version(self) -> dict[str, Any]:
        """Return current API version and deprecation info."""
        return {
            "current_version": "v2",
            "current_version_path": "/api/v2",
            "deprecated_versions": [
                {
                    "version": "v1",
                    "path": "/api/v1",
                    "deprecated": True,
                    "sunset": "2026-12-31T23:59:59Z",
                    "migration_url": "/api/v2",
                }
            ],
            "unversioned_endpoints": [
                {
                    "path": "/api/triage",
                    "migrated_to": "/api/v2/triage",
                    "deprecated": True,
                    "sunset": "2026-12-31T23:59:59Z",
                },
                {
                    "path": "/api/analytics",
                    "migrated_to": "/api/v2/analytics",
                    "deprecated": True,
                    "sunset": "2026-12-31T23:59:59Z",
                },
            ],
            "supported_versions": {
                "v1": {
                    "status": "deprecated",
                    "sunset": "2026-12-31T23:59:59Z",
                    "successor": "/api/v2",
                },
                "v2": {
                    "status": "current",
                    "sunset": None,
                    "successor": None,
                },
            },
        }
