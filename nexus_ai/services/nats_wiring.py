"""NATS wiring — connects all v7.0 AUDIT services together.

This module provides the wiring/startup code that connects:
- TigerBeetleClient → NATS Event Bridge
- NATS Event Bridge → ShadowReconciliation, LedgerGuard, ContinuousAudit
- AutoHealingLedger → 3-layer consistency checks
- PendingTimeoutManager → TB pending voiding
- IntegrityHealthChecker → automated proof chain verification

Usage (in app startup):
    from nexus_ai.services.nats_wiring import wire_all_services
    await wire_all_services(tb_client, duckdb_conn, nats_client)
"""

from __future__ import annotations

import asyncio
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.nats.wiring")


async def wire_all_services(
    tb_client,
    duckdb_conn,
    *,
    nats_client=None,
    sqlite_session=None,
    signing_key: bytes | None = None,
    auto_start: bool = True,
) -> dict[str, Any]:
    """Podłącz wszystkie serwisy v7.0 AUDIT do NATS i uruchom je.

    Tworzy kompletny event-driven pipeline:
      TB transfer → NATS → [ShadowReconciler, LedgerGuard, ContinuousAudit, ...]

    Args:
        tb_client: TigerBeetleClient instance.
        duckdb_conn: DuckDB connection.
        nats_client: NATS client (optional — services work in log-only mode without it).
        sqlite_session: SQLModel session (optional).
        signing_key: HMAC signing key for proof chains.
        auto_start: Whether to auto-start all services.

    Returns:
        Dict with references to all wired services.
    """
    from nexus_ai.services.nats_event_bridge import NATSEventBridge, get_nats_bridge
    from nexus_ai.services.shadow_reconciliation import ShadowReconciliationEngine
    from nexus_ai.services.ledger_guard import LedgerGuard
    from nexus_ai.services.continuous_audit import ContinuousAuditEngine
    from nexus_ai.services.auto_healing_ledger import AutoHealingLedger
    from nexus_ai.services.pending_timeout_manager import PendingTimeoutManager
    from nexus_ai.services.integrity_health_check import IntegrityHealthChecker
    from nexus_ai.services.tb_transfer_proof_chain import TBTransferProofChain
    from nexus_ai.services.proof_chain import ProofChain

    services = {}

    # 1. NATS Event Bridge
    bridge = get_nats_bridge(nats_client)
    services["nats_bridge"] = bridge

    # 2. Podłącz TB Client do bridge'a
    if hasattr(tb_client, 'set_nats_client') and nats_client:
        tb_client.set_nats_client(nats_client)
        logger.info("[NATS-WIRING] TB client connected to NATS")

    # 3. Shadow Reconciliation Engine
    reconciler = ShadowReconciliationEngine(
        tb_client, duckdb_conn,
        nats_client=nats_client,
        auto_heal=True,
    )
    services["shadow_reconciler"] = reconciler

    # 4. LedgerGuard — Real-time fraud detection
    guard = LedgerGuard(nats_client=nats_client, auto_block=True)
    services["ledger_guard"] = guard

    # 5. Continuous Audit Engine
    proof_chain = ProofChain(duckdb_conn, signing_key=signing_key)
    auditor = ContinuousAuditEngine(
        nats_client=nats_client,
        proof_chain=proof_chain,
        auto_block=True,
    )
    services["continuous_audit"] = auditor

    # 6. Auto-Healing Ledger
    healer = AutoHealingLedger(
        tb_client, sqlite_session, duckdb_conn,
        auto_heal=True,
    )
    services["auto_healer"] = healer

    # 7. Pending Timeout Manager
    timeout_mgr = PendingTimeoutManager(tb_client, duckdb_conn)
    services["pending_timeout"] = timeout_mgr

    # 8. Integrity Health Checker
    from nexus_ai.services.integrity_verifier import IntegrityVerifier
    verifier = IntegrityVerifier(duckdb_conn)
    health_checker = IntegrityHealthChecker(verifier, nats_client=nats_client)
    services["integrity_health"] = health_checker

    # 9. TB Transfer Proof Chain
    tb_proof_chain = TBTransferProofChain(duckdb_conn, signing_key=signing_key)
    services["tb_proof_chain"] = tb_proof_chain

    # 10. Subscribe bridge to all event types
    if nats_client:
        # Wire NATS subscriptions
        async def on_transfer_posted(event):
            # LedgerGuard: real-time fraud check (public API)
            guard.check_transfer({
                "transfer_id": event.transfer_id,
                "debit_account": event.debit_account,
                "credit_account": event.credit_account,
                "amount_minor": event.amount_minor,
                "timestamp_ns": event.timestamp_ns,
            })
            # ContinuousAudit: audit every transfer
            auditor.audit_transfer({
                "transfer_id": event.transfer_id,
                "debit_account": event.debit_account,
                "credit_account": event.credit_account,
                "amount_minor": event.amount_minor,
                "ledger": event.ledger,
                "code": event.code,
            })
            # TB Proof Chain: log transfer
            tb_proof_chain.log_transfer({
                "transfer_id": event.transfer_id,
                "debit_account": event.debit_account,
                "credit_account": event.credit_account,
                "amount_minor": event.amount_minor,
            })

        bridge.subscribe("*", on_transfer_posted)
        logger.info("[NATS-WIRING] Wildcard subscriber registered for all TB events")

    # 11. Auto-start all services
    if auto_start:
        start_tasks = []
        if nats_client:
            start_tasks.append(bridge.start())
            start_tasks.append(reconciler.start())
            start_tasks.append(guard.start())
            start_tasks.append(auditor.start())
        start_tasks.append(healer.start())
        start_tasks.append(timeout_mgr.start())
        start_tasks.append(health_checker.start())

        results = await asyncio.gather(*start_tasks, return_exceptions=True)
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                logger.warning("[NATS-WIRING] Service %d failed to start: %s", i, result)
        logger.info("[NATS-WIRING] All %d services started", len(services))

    return services


async def shutdown_all_services(services: dict[str, Any]) -> None:
    """Zatrzymaj wszystkie serwisy v7.0 AUDIT."""
    for name, service in services.items():
        try:
            if hasattr(service, 'stop'):
                await service.stop()
                logger.info("[NATS-WIRING] Stopped: %s", name)
        except Exception as exc:
            logger.warning("[NATS-WIRING] Error stopping %s: %s", name, exc)
