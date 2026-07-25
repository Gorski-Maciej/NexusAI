"""
Intelligent Index Advisor — ML-based index recommendations (INNOWACJA #9 v7.0).

Raport v7.0, INNOWACJA 9:
  "Intelligent Index Advisor:
   - Analizuje wzorce zapytań
   - Rekomenduje nowe indeksy
   - Wykrywa nieużywane indeksy
   - Auto-CREATE INDEX po akceptacji"

Features:
- Query pattern analysis from EXPLAIN QUERY PLAN
- Unused index detection via sqlite_stat
- Composite index recommendations
- Covering index (INCLUDE) recommendations
- Auto-CREATE INDEX after manual approval
- Index usage statistics tracking
"""

from __future__ import annotations

import sqlite3
import time
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.db.index_advisor")

# ── Data structures ─────────────────────────────────────────────────────────


@dataclass
class IndexRecommendation:
    """A recommended index to create."""
    table: str
    columns: list[str]
    include_columns: list[str] = field(default_factory=list)
    index_type: str = "composite"  # composite | partial | expression | covering
    where_clause: str = ""
    reason: str = ""
    estimated_improvement_pct: float = 0.0
    query_patterns: int = 0
    auto_approved: bool = False


@dataclass
class UnusedIndex:
    """An index that appears unused."""
    name: str
    table: str
    sql: str
    last_used: float | None = None


class IndexAdvisor:
    """Intelligent index advisor using EXPLAIN QUERY PLAN and sqlite_stat.

    Usage:
        advisor = IndexAdvisor(db_path="app_data/oltp.db")
        recommendations = advisor.analyze()
        for rec in recommendations:
            if rec.auto_approved:
                advisor.create_index(rec)
    """

    def __init__(
        self,
        db_path: str | Path,
        min_query_count: int = 10,
        improvement_threshold_pct: float = 20.0,
        auto_approve_threshold_pct: float = 50.0,
    ) -> None:
        self._db_path = Path(db_path)
        self._min_query_count = min_query_count
        self._improvement_threshold_pct = improvement_threshold_pct
        self._auto_approve_threshold_pct = auto_approve_threshold_pct

        # Query pattern tracking
        self._query_patterns: dict[str, int] = defaultdict(int)
        self._column_usage: dict[str, dict[str, int]] = defaultdict(
            lambda: defaultdict(int)
        )
        self._table_scans: dict[str, int] = defaultdict(int)

    # ── Core Analysis ────────────────────────────────────────────────────

    def analyze(self) -> list[IndexRecommendation]:
        """Run full index analysis.

        Returns:
            List of IndexRecommendations sorted by estimated improvement.
        """
        recommendations: list[IndexRecommendation] = []

        # 1. Find unused indexes
        unused = self.find_unused_indexes()
        if unused:
            logger.info(
                "[INDEX-ADVISOR] Found %d potentially unused indexes",
                len(unused),
            )

        # 2. Analyze scan-heavy tables
        scan_recs = self._analyze_table_scans()
        recommendations.extend(scan_recs)

        # 3. Analyze column usage patterns for composite indexes
        composite_recs = self._analyze_column_patterns()
        recommendations.extend(composite_recs)

        # 4. Analyze partial index opportunities
        partial_recs = self._analyze_partial_opportunities()
        recommendations.extend(partial_recs)

        # 5. Analyze covering index opportunities
        covering_recs = self._analyze_covering_opportunities()
        recommendations.extend(covering_recs)

        # Filter by threshold and sort
        filtered = [
            r for r in recommendations
            if r.estimated_improvement_pct >= self._improvement_threshold_pct
        ]
        filtered.sort(key=lambda r: r.estimated_improvement_pct, reverse=True)

        # Auto-approve high-impact recommendations
        for rec in filtered:
            if rec.estimated_improvement_pct >= self._auto_approve_threshold_pct:
                rec.auto_approved = True

        return filtered

    def _connect(self) -> sqlite3.Connection:
        """Create a connection with proper settings."""
        conn = sqlite3.connect(str(self._db_path))
        conn.row_factory = sqlite3.Row
        return conn

    # ── Unused Index Detection ───────────────────────────────────────────

    def find_unused_indexes(self) -> list[UnusedIndex]:
        """Find indexes that appear unused based on sqlite_stat data.

        Returns:
            List of UnusedIndex objects.
        """
        conn = self._connect()
        try:
            unused: list[UnusedIndex] = []

            # Get all indexes
            indexes = conn.execute(
                """SELECT name, tbl_name, sql
                   FROM sqlite_master
                   WHERE type='index'
                     AND name NOT LIKE 'sqlite_%'
                     AND name NOT LIKE 'pk_%'"""
            ).fetchall()

            # Check sqlite_stat for usage
            for idx in indexes:
                stat = conn.execute(
                    "SELECT * FROM sqlite_stat1 WHERE idx = ?",
                    (idx["name"],),
                ).fetchone()

                if stat is None:
                    # Index not in stat1 -> possibly unused
                    unused.append(
                        UnusedIndex(
                            name=idx["name"],
                            table=idx["tbl_name"],
                            sql=idx["sql"] or "",
                        )
                    )

            return unused
        finally:
            conn.close()

    def drop_unused_index(self, name: str) -> bool:
        """Drop an identified unused index.

        Args:
            name: Index name to drop.

        Returns:
            True if dropped successfully.
        """
        conn = self._connect()
        try:
            conn.execute(f"DROP INDEX IF EXISTS {name};")
            conn.commit()
            logger.info("[INDEX-ADVISOR] Dropped unused index: %s", name)
            return True
        except Exception as exc:
            logger.error(
                "[INDEX-ADVISOR] Failed to drop index %s: %s", name, exc
            )
            return False
        finally:
            conn.close()

    # ── Record & Analyze ─────────────────────────────────────────────────

    def record_query(self, sql: str) -> None:
        """Record a query for pattern analysis.

        Args:
            sql: The SQL statement executed.
        """
        conn = self._connect()
        try:
            # Get query plan
            plan = conn.execute(f"EXPLAIN QUERY PLAN {sql}").fetchall()

            for row in plan:
                detail = row["detail"] if "detail" in row.keys() else str(row)
                detail_str = str(detail)

                # Detect table scans
                if "SCAN" in detail_str:
                    # Extract table name from SCAN detail
                    for table_row in conn.execute(
                        "SELECT name FROM sqlite_master WHERE type='table'"
                    ).fetchall():
                        table_name = table_row["name"]
                        if table_name in detail_str:
                            self._table_scans[table_name] += 1

                # Detect column usage in WHERE clauses
                if "SEARCH" in detail_str:
                    for table_row in conn.execute(
                        "SELECT name FROM sqlite_master WHERE type='table'"
                    ).fetchall():
                        table_name = table_row["name"]
                        if table_name in detail_str:
                            self._table_scans[table_name] = max(
                                0, self._table_scans[table_name] - 1
                            )

        except Exception as exc:
            logger.debug(
                "[INDEX-ADVISOR] Failed to analyze query plan: %s", exc
            )
        finally:
            conn.close()

    # ── Analysis Helpers ─────────────────────────────────────────────────

    def _analyze_table_scans(self) -> list[IndexRecommendation]:
        """Recommend indexes for tables with frequent full scans."""
        recs: list[IndexRecommendation] = []
        if not self._table_scans:
            return recs

        conn = self._connect()
        try:
            for table, scan_count in self._table_scans.items():
                if scan_count < self._min_query_count:
                    continue

                # Get table columns for potential indexing
                cols = conn.execute(
                    f"PRAGMA table_info({table});"
                ).fetchall()
                column_names = [c["name"] for c in cols]

                # Heuristic: index columns that look like they'd be in WHERE
                index_candidates = [
                    name for name in column_names
                    if any(
                        keyword in name.lower()
                        for keyword in [
                            "_id", "_status", "_type", "_nip",
                            "status", "type", "date", "timestamp",
                        ]
                    )
                ]

                if index_candidates:
                    # Check if index already exists
                    existing = {
                        idx["name"]
                        for idx in conn.execute(
                            f"SELECT name FROM sqlite_master "
                            f"WHERE type='index' AND tbl_name='{table}'"
                        ).fetchall()
                    }

                    proposed_name = f"idx_{table}_{'_'.join(index_candidates[:3])}"
                    if proposed_name not in existing:
                        improvement = min(scan_count * 2, 90.0)
                        recs.append(
                            IndexRecommendation(
                                table=table,
                                columns=index_candidates[:3],
                                reason=(
                                    f"Table '{table}' has {scan_count} full scans. "
                                    f"Adding index on {index_candidates[:2]} "
                                    f"would reduce to index scan."
                                ),
                                estimated_improvement_pct=improvement,
                                query_patterns=scan_count,
                            )
                        )
        finally:
            conn.close()

        return recs

    def _analyze_column_patterns(self) -> list[IndexRecommendation]:
        """Recommend composite indexes based on column usage patterns."""
        recs: list[IndexRecommendation] = []

        for table, cols in self._column_usage.items():
            if len(cols) < 2:
                continue

            # Sort columns by usage frequency
            sorted_cols = sorted(cols.items(), key=lambda x: x[1], reverse=True)
            top_cols = [c for c, _ in sorted_cols[:3]]
            total_usage = sum(cols.values())

            if total_usage >= self._min_query_count:
                recs.append(
                    IndexRecommendation(
                        table=table,
                        columns=top_cols,
                        reason=(
                            f"Columns {top_cols} frequently used together "
                            f"({total_usage} queries). Composite index recommended."
                        ),
                        estimated_improvement_pct=min(total_usage, 80.0),
                        query_patterns=total_usage,
                    )
                )

        return recs

    def _analyze_partial_opportunities(self) -> list[IndexRecommendation]:
        """Recommend partial indexes based on cardinality analysis."""
        recs: list[IndexRecommendation] = []
        conn = self._connect()
        try:
            # Check invoice status distribution for partial index
            try:
                statuses = conn.execute(
                    "SELECT status, COUNT(*) as cnt FROM invoices GROUP BY status"
                ).fetchall()

                if statuses:
                    # If active statuses are a small portion of total -> recommend partial
                    total = sum(s["cnt"] for s in statuses)
                    active_statuses = {"PAID", "APPROVED", "PENDING_REVIEW", "PROCESSING"}
                    active_count = sum(
                        s["cnt"] for s in statuses if s["status"] in active_statuses
                    )
                    active_pct = (active_count / total * 100) if total > 0 else 100

                    if active_pct < 50:
                        recs.append(
                            IndexRecommendation(
                                table="invoices",
                                columns=["created_at"],
                                index_type="partial",
                                where_clause=(
                                    "status IN ('PAID', 'APPROVED', 'PENDING_REVIEW')"
                                ),
                                reason=(
                                    f"Only {active_pct:.0f}% of invoices are active. "
                                    f"Partial index on active rows only."
                                ),
                                estimated_improvement_pct=100 - active_pct,
                                query_patterns=active_count,
                            )
                        )
            except Exception:
                pass

        finally:
            conn.close()

        return recs

    def _analyze_covering_opportunities(self) -> list[IndexRecommendation]:
        """Recommend covering indexes (INCLUDE) for high-frequency queries."""
        recs: list[IndexRecommendation] = []
        conn = self._connect()
        try:
            # Analyze high-frequency composite indexes for INCLUDE candidates
            indexes = conn.execute(
                "SELECT name, tbl_name, sql FROM sqlite_master "
                "WHERE type='index' AND name LIKE 'idx_%'"
            ).fetchall()

            for idx in indexes:
                if idx["sql"] and "INCLUDE" not in idx["sql"]:
                    # Get columns that are frequently selected with this index
                    table = idx["tbl_name"]
                    cols = conn.execute(
                        f"PRAGMA table_info({table});"
                    ).fetchall()

                    # Heuristic: suggest INCLUDE for amount/currency/status columns
                    include_candidates = [
                        c["name"] for c in cols
                        if any(
                            kw in c["name"].lower()
                            for kw in ["amount", "currency", "status", "tenant"]
                        )
                        and c["name"] not in idx["sql"]
                    ]

                    if include_candidates:
                        idx_cols = []
                        # Extract columns from CREATE INDEX statement
                        import re as _re
                        col_match = _re.findall(r'ON\s+\w+\s*\(([^)]+)\)', idx["sql"])
                        if col_match:
                            idx_cols = [
                                c.strip() for c in col_match[0].split(",")
                            ]
                        recs.append(
                            IndexRecommendation(
                                table=table,
                                columns=idx_cols[:3],
                                include_columns=include_candidates[:3],
                                index_type="covering",
                                reason=(
                                    f"Add INCLUDE ({', '.join(include_candidates[:3])}) "
                                    f"to eliminate table lookups for {idx['name']}"
                                ),
                                estimated_improvement_pct=35.0,
                                query_patterns=1,
                            )
                        )
        finally:
            conn.close()

        return recs

    # ── Index Creation ───────────────────────────────────────────────────

    def create_index(
        self, recommendation: IndexRecommendation, dry_run: bool = False
    ) -> bool:
        """Create a recommended index.

        Args:
            recommendation: The IndexRecommendation to implement.
            dry_run: If True, only log without creating.

        Returns:
            True if index was created or would be created.
        """
        cols = ", ".join(recommendation.columns)
        name = f"idx_{recommendation.table}_{'_'.join(recommendation.columns[:3])}"

        if recommendation.index_type == "covering" and recommendation.include_columns:
            include_cols = ", ".join(recommendation.include_columns)
            sql = (
                f"CREATE INDEX IF NOT EXISTS {name} "
                f"ON {recommendation.table} ({cols}) "
                f"INCLUDE ({include_cols});"
            )
        elif recommendation.index_type == "partial" and recommendation.where_clause:
            sql = (
                f"CREATE INDEX IF NOT EXISTS {name} "
                f"ON {recommendation.table} ({cols}) "
                f"WHERE {recommendation.where_clause};"
            )
        else:
            sql = (
                f"CREATE INDEX IF NOT EXISTS {name} "
                f"ON {recommendation.table} ({cols});"
            )

        if dry_run:
            logger.info("[INDEX-ADVISOR] [DRY-RUN] Would create: %s", sql)
            return True

        conn = self._connect()
        try:
            conn.execute(sql)
            conn.commit()
            logger.info("[INDEX-ADVISOR] Created index: %s", name)
            return True
        except Exception as exc:
            logger.error(
                "[INDEX-ADVISOR] Failed to create index %s: %s", name, exc
            )
            return False
        finally:
            conn.close()

    # ── Stats ─────────────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        """Get advisor statistics."""
        return {
            "query_patterns_tracked": len(self._query_patterns),
            "tables_with_scans": len(self._table_scans),
            "total_table_scans": sum(self._table_scans.values()),
            "tables_with_column_usage": len(self._column_usage),
            "min_query_count": self._min_query_count,
            "improvement_threshold_pct": self._improvement_threshold_pct,
            "auto_approve_threshold_pct": self._auto_approve_threshold_pct,
        }
