"""MeshService — shared integration layer between agents and KnowledgeMesh.

GENIALNY POMYSŁ v5.4:
Eliminates the duplicated `_publish_mesh_events()` logic that existed in every agent
(extraction.py, analytics.py, quality_validator.py, orchestrator.py).

Cross-Agent rules (defined once here):
  - quality.tax_error        → Extraction HIGH_SCRUTINY, Orchestrator LOWER_THRESHOLD
  - quality.fraud_detected   → ALL agents HIGH ALERT
  - extraction.low_consensus → QualityValidator INCREASE_SCRUTINY
  - orchestrator.decision_corrected → Extraction + Analytics LEARN
  - analytics.anomaly_detected → QualityValidator TRIGGER_DEEP_CHECK, Orchestrator LOWER_THRESHOLD
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.mesh")


class MeshService:
    """Shared service for agent ↔ KnowledgeMesh integration.

    Usage:
        # In any agent:
        if self.mesh_ready:
            await self.mesh.publish_event(
                event_type="quality.tax_error",
                source_agent=self.name,
                vendor_nip=vendor_nip,
                category=category,
                amount=amount,
                severity="high",
                details={"reason": "..."},
                adjust_trust=True,
                trust_correct=False,
            )
    """

    __slots__ = ()

    # Severity → automatically determines cross-agent actions
    SEVERITY_TRUST_MAP: dict[str, bool | None] = {
        "critical": False,   # always reduce trust
        "high": False,       # always reduce trust
        "medium": None,      # don't adjust trust by default
        "low": True,         # increase trust (all clear)
        "info": True,        # increase trust (all clear)
    }

    @staticmethod
    async def publish_event(
        mesh: Any,
        *,
        event_type: str,
        source_agent: str,
        vendor_nip: str,
        category: str = "",
        amount: float = 0.0,
        severity: str = "info",
        details: dict[str, Any] | None = None,
        adjust_trust: bool = True,
        trust_correct: bool | None = None,
    ) -> None:
        """Publish a mesh event with consistent trust adjustment.

        Args:
            mesh: KnowledgeMesh instance (from self.mesh).
            event_type: Type of event (e.g. 'quality.tax_error').
            source_agent: Name of the agent publishing.
            vendor_nip: NIP of the vendor related to this event.
            category: Invoice category.
            amount: Invoice amount.
            severity: 'critical' | 'high' | 'medium' | 'low' | 'info'.
            details: Optional extra details for the experience replay.
            adjust_trust: Whether to adjust trust score.
            trust_correct: Override trust correction (True=good, False=bad).
        """
        if mesh is None or not getattr(mesh, 'is_initialized', False):
            return

        # Determine trust correction from severity if not overridden
        if trust_correct is None and adjust_trust:
            trust_correct = MeshService.SEVERITY_TRUST_MAP.get(severity)

        # Update Bayesian Trust Field
        if adjust_trust and trust_correct is not None:
            try:
                await mesh.update_trust(
                    vendor_nip=vendor_nip,
                    correct=trust_correct,
                    agent_name=source_agent,
                    category=category,
                    amount=amount,
                )
            except Exception as exc:
                logger.warning("[MESH] Trust update failed for NIP=%s: %s", vendor_nip[:8], exc)

        # Share experience only for critical/high/medium events
        if severity in ("critical", "high", "medium") and details is not None:
            try:
                await mesh.share_experience(
                    event_type=event_type,
                    source_agent=source_agent,
                    vendor_nip=vendor_nip,
                    category=category,
                    amount=amount,
                    details=details,
                )
                logger.info(
                    "[MESH] 📡 %s → Cross-Agent rules | NIP=%s | severity=%s",
                    event_type, vendor_nip[:8], severity,
                )
            except Exception as exc:
                logger.warning("[MESH] share_experience failed: %s", exc)

    @staticmethod
    async def boost_trust(
        mesh: Any,
        *,
        vendor_nip: str,
        source_agent: str,
        category: str = "",
        amount: float = 0.0,
    ) -> None:
        """Quick helper to boost trust for a vendor (all checks passed)."""
        await MeshService.publish_event(
            mesh=mesh,
            event_type="mesh.trust_boost",
            source_agent=source_agent,
            vendor_nip=vendor_nip,
            category=category,
            amount=amount,
            severity="low",
            adjust_trust=True,
            trust_correct=True,
        )

    @staticmethod
    async def reduce_trust(
        mesh: Any,
        *,
        vendor_nip: str,
        source_agent: str,
        category: str = "",
        amount: float = 0.0,
        event_type: str = "mesh.trust_reduced",
        reason: str = "",
    ) -> None:
        """Quick helper to reduce trust for a vendor (issue detected)."""
        await MeshService.publish_event(
            mesh=mesh,
            event_type=event_type,
            source_agent=source_agent,
            vendor_nip=vendor_nip,
            category=category,
            amount=amount,
            severity="high",
            adjust_trust=True,
            trust_correct=False,
            details={"reason": reason},
        )
