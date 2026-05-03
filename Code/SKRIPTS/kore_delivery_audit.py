from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

Check = dict[str, object]

REQUIREMENTS: dict[str, tuple[Check, ...]] = {
    "1_jwt_rbac_login": (
        {"file": "Code/API/app.py", "contains": ("on_app_init=[jwt_auth.on_app_init]",)},
        {"file": "Code/API/rbac.py", "contains": ("getattr(connection, \"user\"",), "not_contains": ("X-Nexus-Role",)},
        {"file": "Code/API/routes/auth.py", "contains": ("jwt_auth.login",)},
        {"file": "Code/API/security.py", "contains": ("retrieve_user_handler", "SELECT id, username, role")},
    ),
    "2_zero_etl_outbox_analytics": (
        {"file": "Code/DB/analytics.py", "contains": ("ATTACH '", "TYPE SQLITE", "SET memory_limit", "SET threads")},
        {"file": "Code/API/tasks.py", "contains": ("relay_outbox_events", "replay_dead_letter_outbox_task")},
        {"file": "Code/API/controllers/analytics.py", "contains": ("read_only=True", "SUM(total_gross) OVER", "cumulative_gross", "ASOF LEFT JOIN", "report_currency")},
        {"file": "Code/API/state.py", "contains": ("CREATE TABLE IF NOT EXISTS fx_rates", "idx_fx_rates_currency_effective")},
        {"file": "Code/SERVICES/replication.py", "contains": ("setup_zero_etl",), "not_contains": ("INSERT OR REPLACE INTO invoices_replica",)},
    ),
    "3_storage_streaming": (
        {"file": "Code/SERVICES/storage.py", "contains": ("stream",)},
        {"file": "Code/API/middleware.py", "contains": ("UploadSizeGuardMiddleware", "/invoices/upload-large")},
        {"file": "Code/API/shared_image_buffer.py", "contains": ("SharedImageBuffer",)},
    ),
    "4_11_enterprise_hardening": (
        {"file": "Code/SKRIPTS/performance_engineering.py"},
        {"file": "Code/SKRIPTS/security_scan.py"},
        {"file": "Code/SKRIPTS/log_pii_scanner.py"},
        {"file": "Code/SKRIPTS/migration_sanity_check.py"},
        {"file": "Code/SKRIPTS/otel_buffer_replayer.py"},
        {"file": "Code/SKRIPTS/model_retention_runner.py"},
        {"file": "Code/SERVICES/finops_meter.py"},
        {"file": "Code/API/i18n.py"},
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
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report["overall_ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
