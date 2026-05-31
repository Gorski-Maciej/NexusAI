# core/alerting.py
"""
Alerting rules and health check functions for Prometheus Alertmanager.

This module defines the production alert rules that should be loaded
by Prometheus Alertmanager and provides programmatic health-check
functions that can be used by the application itself.

Usage:
    from core.alerting import check_high_error_rate, check_disk_space

    # Programmatic checks (e.g., in a health endpoint or scheduled task)
    errors = check_high_error_rate(error_count, total_count)
    disk = check_disk_space()
"""
from __future__ import annotations

import os
import shutil
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


# ── Alert rule definitions ────────────────────────────────────────────────────

@dataclass
class PrometheusAlertRule:
    """A single Prometheus alerting rule."""

    name: str
    expr: str
    duration: str
    severity: str  # "critical", "warning", "info"
    summary: str
    description: str
    annotations: dict[str, str] = field(default_factory=dict)
    labels: dict[str, str] = field(default_factory=dict)

    def to_yaml_dict(self) -> dict[str, Any]:
        """Return a dict suitable for YAML serialization."""
        return {
            "alert": self.name,
            "expr": self.expr,
            "for": self.duration,
            "labels": {"severity": self.severity, **self.labels},
            "annotations": {
                "summary": self.summary,
                "description": self.description,
                **self.annotations,
            },
        }


# ── Built-in alert rules ─────────────────────────────────────────────────────

ALERT_RULES: list[PrometheusAlertRule] = [
    PrometheusAlertRule(
        name="HighErrorRate",
        expr=(
            "rate(http_requests_total{status=~'5..'}[5m]) "
            "/ rate(http_requests_total[5m]) > 0.01"
        ),
        duration="5m",
        severity="critical",
        summary="High HTTP error rate",
        description=(
            "More than 1% of HTTP requests are returning 5xx errors "
            "in the last 5 minutes."
        ),
    ),
    PrometheusAlertRule(
        name="NATSQueueDepth",
        expr="nats_events_queued_total - nats_events_processed_total > 1000",
        duration="2m",
        severity="warning",
        summary="NATS queue depth exceeds threshold",
        description=(
            "The NATS event queue has more than 1,000 unprocessed messages. "
            "Worker may be overloaded or unavailable."
        ),
    ),
    PrometheusAlertRule(
        name="ModelInferenceSlow",
        expr="ai_inference_duration_seconds{quantile='0.95'} > 30",
        duration="5m",
        severity="warning",
        summary="AI model inference is slow",
        description=(
            "P95 AI inference duration exceeds 30 seconds. "
            "Check GPU/CPU utilization and model loading."
        ),
    ),
    PrometheusAlertRule(
        name="LowDiskSpace",
        expr="node_filesystem_avail_bytes{mountpoint='/'} / node_filesystem_size_bytes{mountpoint='/'} < 0.1",
        duration="5m",
        severity="critical",
        summary="Low disk space",
        description=(
            "Less than 10% disk space remaining. "
            "Backup and cleanup required immediately."
        ),
    ),
    PrometheusAlertRule(
        name="NATSDown",
        expr="nats_up == 0",
        duration="1m",
        severity="critical",
        summary="NATS server is down",
        description="NATS server is not reachable. Task processing is disabled.",
    ),
    PrometheusAlertRule(
        name="WorkerDown",
        expr="worker_up == 0",
        duration="2m",
        severity="critical",
        summary="Taskiq worker is down",
        description="No active worker processing tasks. OCR and AI tasks will queue up.",
    ),
]


def generate_alert_rules_yaml() -> str:
    """Generate Prometheus alert rules YAML content.

    Returns a complete YAML string ready to be written to a file
    (e.g., ``deploy/prometheus/alert_rules.yml``).
    """
    lines = ["groups:", "  - name: nexus_alerts", "    interval: 30s", "    rules:"]
    for rule in ALERT_RULES:
        d = rule.to_yaml_dict()
        lines.append(f"      - alert: {d['alert']}")
        lines.append(f"        expr: {d['expr']}")
        lines.append(f"        for: {d['duration']}")
        lines.append(f"        labels:")
        for k, v in d["labels"].items():
            lines.append(f"          {k}: {v}")
        lines.append(f"        annotations:")
        for k, v in d["annotations"].items():
            lines.append(f"          {k}: {v}")
    return "\n".join(lines)


# ── Programmatic health check functions ──────────────────────────────────────


def check_high_error_rate(
    error_count_5xx: int,
    total_request_count: int,
    threshold_pct: float = 1.0,
) -> dict[str, Any]:
    """Check if the 5xx error rate exceeds the threshold.

    Args:
        error_count_5xx: Number of 5xx errors in the window.
        total_request_count: Total requests in the window.
        threshold_pct: Error rate threshold as percentage (default 1.0%).

    Returns:
        A dict with ``status`` (ok/warning/critical), ``error_rate_pct``,
        and ``threshold_pct``.
    """
    if total_request_count == 0:
        return {"status": "ok", "error_rate_pct": 0.0, "threshold_pct": threshold_pct}

    error_rate = (error_count_5xx / total_request_count) * 100.0
    if error_rate > threshold_pct:
        return {
            "status": "critical",
            "error_rate_pct": round(error_rate, 2),
            "threshold_pct": threshold_pct,
        }
    return {
        "status": "ok",
        "error_rate_pct": round(error_rate, 2),
        "threshold_pct": threshold_pct,
    }


def check_disk_space(path: str | Path = "/", threshold_gb: float = 1.0) -> dict[str, Any]:
    """Check available disk space.

    Args:
        path: Mount point or directory to check.
        threshold_gb: Minimum free space in GB before warning.

    Returns:
        A dict with ``status``, ``free_gb``, ``total_gb``, ``free_pct``.
    """
    try:
        usage = shutil.disk_usage(path)
        free_gb = usage.free / (1024**3)
        total_gb = usage.total / (1024**3)
        free_pct = (usage.free / usage.total) * 100.0

        if free_gb < threshold_gb:
            return {
                "status": "critical",
                "free_gb": round(free_gb, 1),
                "total_gb": round(total_gb, 1),
                "free_pct": round(free_pct, 1),
            }
        return {
            "status": "ok",
            "free_gb": round(free_gb, 1),
            "total_gb": round(total_gb, 1),
            "free_pct": round(free_pct, 1),
        }
    except Exception as exc:
        return {"status": "error", "error": str(exc)}
