#!/usr/bin/env python3
"""F4 Decision Certificate generator for lifecycle events."""
from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from typing import Any
from uuid import UUID, uuid4

EVENTS = {"REGISTRATION", "SUSPENSION", "RESUMPTION", "SUCCESSION", "TAX_FORM_CHANGE", "LIQUIDATION"}


def create_certificate(
    event_type: str,
    business_data: dict[str, Any],
    bundle_version: str,
    legal_basis: list[str] | None = None,
    rule_version: str = "p13-2026.08",
    decision_id: str | None = None,
    timestamp: str | None = None,
) -> dict[str, Any]:
    """Create a reproducible hash over all certificate fields except the hash."""
    event = event_type.upper()
    if event not in EVENTS:
        raise ValueError(f"unsupported event_type: {event_type}")
    if not bundle_version.strip():
        raise ValueError("bundle_version is required")
    identifier = str(UUID(decision_id)) if decision_id else str(uuid4())
    issued_at = timestamp or datetime.now(timezone.utc).isoformat()
    payload: dict[str, Any] = {
        "certificate_version": "F4-1.0",
        "decision_id": identifier,
        "event_type": event,
        "issued_at": issued_at,
        "business_data": business_data,
        "legal_basis": legal_basis or [],
        "bundle_version": bundle_version,
        "rule_version": rule_version,
    }
    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return {**payload, "sha256": hashlib.sha256(canonical.encode("utf-8")).hexdigest()}


def verify_certificate(certificate: dict[str, Any]) -> bool:
    """Verify the certificate hash without mutating the input."""
    expected = certificate.get("sha256")
    payload = {key: value for key, value in certificate.items() if key != "sha256"}
    canonical = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return isinstance(expected, str) and expected == hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("event", choices=sorted(EVENTS), default="REGISTRATION", nargs="?")
    parser.add_argument("--bundle", default="jdg-p13-2026.08")
    args = parser.parse_args()
    print(json.dumps(create_certificate(args.event, {}, args.bundle), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
