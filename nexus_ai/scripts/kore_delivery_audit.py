from __future__ import annotations

from pathlib import Path

from nexus_ai.core.msgspec_utils import msgspec_dumps

ROOT = Path(__file__).resolve().parents[2]

Check = dict[str, object]

REQUIREMENTS: dict[str, tuple[Check, ...]] = {
    "5_performance_engineering": (
        {"file": "nexus_ai/scripts/performance_engineering.py", "contains": ("k6", "p95")},
    ),
    "6_workspace_nuitka": (
        {
            "file": "nexus_ai/scripts/build_workspace_flatten.py",
            "contains": ("workspace", "flatten"),
        },
    ),
    "7_dast_sast": ({"file": "nexus_ai/scripts/security_scan.py", "contains": ("zap", "semgrep")},),
    "8_i18n": (
        {"file": "nexus_ai/api/i18n.py", "contains": ("locales",)},
        {"file": "nexus_ai/api/locales/pl.json"},
        {"file": "nexus_ai/api/locales/en.json"},
    ),
    "9_large_file_limits": (
        {"file": "nexus_ai/api/middleware.py", "contains": ("UploadSizeGuardMiddleware", "413")},
        {"file": "nexus_ai/api/routes/invoices.py", "contains": ("upload-large", "max_bytes")},
    ),
    "10_offline_secrets": (
        {"file": "nexus_ai/core/secrets.py", "contains": ("ttl_hours", "cache", "offline")},
    ),
    "10_ui_state_hydration": (
        {
            "file": "nexus_ai/api/routes/ui_state.py",
            "contains": ("/api/v1/ui", "ui_drafts", "save_draft", "get_draft"),
        },
        {"file": "nexus_ai/api/state.py", "contains": ("CREATE TABLE IF NOT EXISTS ui_drafts",)},
    ),
    "11_advanced_controls": (
        {
            "file": "nexus_ai/api/routes/kore_closure.py",
            "contains": ("/closure", "runtime_counters", "kore_delivery_audit.py"),
        },
        {"file": "nexus_ai/scripts/migration_sanity_check.py"},
        {"file": "nexus_ai/scripts/log_pii_scanner.py"},
        {"file": "nexus_ai/services/otel_fallback.py"},
        {"file": "nexus_ai/services/finops_meter.py"},
    ),
    "1_jwt_rbac_login": (
        {"file": "nexus_ai/api/app.py", "contains": ("on_app_init=[jwt_auth.on_app_init]",)},
        {
            "file": "nexus_ai/api/rbac.py",
            "contains": ('getattr(connection, "user"',),
            "not_contains": ("X-Nexus-Role",),
        },
        {"file": "nexus_ai/api/routes/auth.py", "contains": ("jwt_auth.login",)},
        {
            "file": "nexus_ai/api/security.py",
            "contains": ("retrieve_user_handler", "SELECT id, username, role"),
        },
    ),
    "2_zero_etl_outbox_analytics": (
        {
            "file": "nexus_ai/db/analytics.py",
            "contains": ("ATTACH '", "TYPE SQLITE", "SET memory_limit", "SET threads"),
        },
        {
            "file": "nexus_ai/api/tasks.py",
            "contains": ("relay_outbox_events", "replay_dead_letter_outbox_task"),
        },
        {
            "file": "nexus_ai/api/routes/system_integrity.py",
            "contains": ("/ui-drafts/cleanup", "cleanup_stale_ui_drafts"),
        },
        {
            "file": "nexus_ai/api/controllers/analytics.py",
            "contains": (
                "read_only=True",
                "SUM(total_gross) OVER",
                "cumulative_gross",
                "ASOF LEFT JOIN",
                "report_currency",
            ),
        },
        {
            "file": "nexus_ai/api/state.py",
            "contains": ("CREATE TABLE IF NOT EXISTS fx_rates", "idx_fx_rates_currency_effective"),
        },
        {
            "file": "nexus_ai/services/replication.py",
            "contains": ("setup_zero_etl",),
            "not_contains": ("INSERT OR REPLACE INTO invoices_replica",),
        },
    ),
    "3_storage_streaming": (
        {"file": "nexus_ai/services/storage.py", "contains": ("stream",)},
        {
            "file": "nexus_ai/api/middleware.py",
            "contains": ("UploadSizeGuardMiddleware", "/invoices/upload-large"),
        },
        {"file": "nexus_ai/api/shared_image_buffer.py", "contains": ("SharedImageBuffer",)},
    ),
    "4_11_enterprise_hardening": (
        {"file": "nexus_ai/scripts/performance_engineering.py"},
        {"file": "nexus_ai/scripts/security_scan.py"},
        {"file": "nexus_ai/scripts/log_pii_scanner.py"},
        {"file": "nexus_ai/scripts/migration_sanity_check.py"},
        {"file": "nexus_ai/scripts/otel_buffer_replayer.py"},
        {"file": "nexus_ai/services/finops_meter.py"},
        {"file": "nexus_ai/api/i18n.py"},
    ),
}


def _validate_check(check: Check) -> tuple[bool, list[str]]:
    file_path = str(check["file"])
    path = ROOT / file_path
    if not path.exists():
        return False, ["missing_file"]

    text = path.read_text(encoding="utf-8")
    violations: list[str] = []
    for needle in tuple(check.get("contains", ())):
        if str(needle) not in text:
            violations.append(f"missing:{needle}")
    for needle in tuple(check.get("not_contains", ())):
        if str(needle) in text:
            violations.append(f"forbidden:{needle}")
    return len(violations) == 0, violations


def build_report() -> dict:
    report: dict[str, dict[str, object]] = {}
    all_ok = True
    for section, checks in REQUIREMENTS.items():
        passed: list[str] = []
        failed: dict[str, list[str]] = {}
        for check in checks:
            file_path = str(check["file"])
            ok, violations = _validate_check(check)
            if ok:
                passed.append(file_path)
            else:
                failed[file_path] = violations
                all_ok = False
        report[section] = {"passed": passed, "failed": failed, "ok": not failed}
    report["overall_ok"] = all_ok
    return report


def main() -> int:
    report = build_report()
    print(msgspec_dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["overall_ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
