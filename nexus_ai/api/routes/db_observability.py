"""
DB Observability API endpoint — exposes database health metrics (v7.0 INNOWACJA #10).

Exposes:
- GET /api/v2/db/observability — Full database health dashboard
- GET /api/v2/db/firewall/stats — DatabaseFirewall statistics
- GET /api/v2/db/index-advisor — IndexAdvisor recommendations
- GET /api/v2/db/wal-archive/stats — WAL archiver status
- GET /api/v2/db/tenant-mesh/stats — Tenant mesh stats
"""

from __future__ import annotations

from typing import Any

from litestar import Controller, get
from litestar.exceptions import ServiceUnavailableException
from structlog import get_logger

logger = get_logger("nexus.api.db_observability")


class DBObservabilityController(Controller):
    """Database observability endpoints — v7.0 INNOWACJA #10."""

    path = "/api/v2/db"
    tags = ["Database"]

    # ── Observability ─────────────────────────────────────────────────

    @get("/observability")
    async def get_db_stats(self) -> dict[str, Any]:
        """Get comprehensive database observability stats.

        Returns latency histograms, pool metrics, index stats,
        WAL size, slow queries, and more.
        """
        try:
            from nexus_ai.services.db_observability import get_observability
            obs = get_observability()
            return obs.get_stats()
        except Exception as exc:
            logger.error("[DB-OBS-API] Failed to get stats: %s", exc)
            raise ServiceUnavailableException(
                detail=f"Database observability unavailable: {exc}"
            )

    # ── Firewall ──────────────────────────────────────────────────────

    @get("/firewall/stats")
    async def get_firewall_stats(self) -> dict[str, Any]:
        """Get DatabaseFirewall statistics.

        Returns allowed/blocked counts, block reasons,
        rate limit status, and query type distribution.
        """
        try:
            from nexus_ai.db.firewall import get_firewall
            fw = get_firewall()
            return fw.get_stats()
        except Exception as exc:
            logger.error("[DB-FW-API] Failed to get stats: %s", exc)
            raise ServiceUnavailableException(
                detail=f"Database firewall unavailable: {exc}"
            )

    # ── Index Advisor ─────────────────────────────────────────────────

    @get("/index-advisor")
    async def get_index_recommendations(self) -> dict[str, Any]:
        """Get Intelligent Index Advisor recommendations.

        Returns recommended indexes with estimated improvement percentages.
        """
        try:
            from pathlib import Path
            from nexus_ai.db.index_advisor import IndexAdvisor

            db_path = Path("app_data/oltp.db")
            if not db_path.exists():
                return {"status": "no_database", "recommendations": []}

            advisor = IndexAdvisor(db_path=str(db_path))
            recommendations = advisor.analyze()
            return {
                "status": "ok",
                "recommendation_count": len(recommendations),
                "recommendations": [
                    {
                        "table": r.table,
                        "columns": r.columns,
                        "include_columns": r.include_columns,
                        "index_type": r.index_type,
                        "reason": r.reason,
                        "estimated_improvement_pct": r.estimated_improvement_pct,
                        "auto_approved": r.auto_approved,
                    }
                    for r in recommendations
                ],
                "unused_indexes": [
                    {"name": u.name, "table": u.table}
                    for u in advisor.find_unused_indexes()
                ],
                "advisor_stats": advisor.get_stats(),
            }
        except Exception as exc:
            logger.error("[DB-IA-API] Failed: %s", exc)
            raise ServiceUnavailableException(
                detail=f"Index advisor unavailable: {exc}"
            )

    # ── WAL Archive ───────────────────────────────────────────────────

    @get("/wal-archive/stats")
    async def get_wal_archive_stats(self) -> dict[str, Any]:
        """Get WAL Archiver statistics.

        Returns archive status, recovery points, WAL size, and more.
        """
        try:
            from pathlib import Path
            from nexus_ai.db.wal_archiver import WALArchiver

            db_path = Path("app_data/oltp.db")
            archiver = WALArchiver(db_path=db_path)
            return archiver.get_stats()
        except Exception as exc:
            logger.error("[DB-WAL-API] Failed: %s", exc)
            raise ServiceUnavailableException(
                detail=f"WAL archiver unavailable: {exc}"
            )

    # ── Tenant Mesh ───────────────────────────────────────────────────

    @get("/tenant-mesh/stats")
    async def get_tenant_mesh_stats(self) -> dict[str, Any]:
        """Get Tenant Database Mesh statistics.

        Returns tenant count, total size, per-tenant details.
        """
        try:
            from nexus_ai.db.tenant_mesh import TenantDatabaseMesh, TenantSaltKMS

            kms = TenantSaltKMS(
                master_key_env="NEXUS_MASTER_SQLCIPHER_KEY"
            )
            mesh = TenantDatabaseMesh(kms)
            stats = mesh.get_stats()
            stats["tenants"] = mesh.list_tenants()
            return stats
        except Exception as exc:
            logger.error("[DB-TM-API] Failed: %s", exc)
            raise ServiceUnavailableException(
                detail=f"Tenant mesh unavailable: {exc}"
            )
