from __future__ import annotations

import anyio
from msgspec import Struct

from nexus_ai.core.cache import get_cache
from nexus_ai.db.analytics import DuckDBManager


class VendorMetric(Struct):
    nip: str
    vendor_name: str
    avg_payment_delay: float
    price_volatility_index: float
    total_volume_ytd: float
    reliability_score: float


class VendorAnalyst:
    """Background analytical engine for local-first vendor intelligence.

    Zgodnie z aa3fvcx.txt:
    - Używa NexusCache (L1 RAM + L2 SQLite) dla wyników vendor context.
    - Cache TTL: 3600s (1h) — dane kontrahentów zmieniają się powoli.
    """

    _CACHE_TTL = 3600  # 1h — dane kontrahentów zmieniają się powoli

    def __init__(self, duckdb: DuckDBManager, refresh_seconds: int = 3600) -> None:
        self.duckdb = duckdb
        self.refresh_seconds = refresh_seconds
        self._cache = get_cache()
        self._running = False

    async def run_forever(self) -> None:
        self._running = True
        while self._running:
            await self.refresh_vendor_intelligence()
            await anyio.sleep(self.refresh_seconds)

    def stop(self) -> None:
        self._running = False

    async def refresh_vendor_intelligence(self) -> None:
        await anyio.to_thread.run_sync(self._refresh_sync)

    def _refresh_sync(self) -> None:
        self.duckdb.execute("""
        CREATE TABLE IF NOT EXISTS vendor_intelligence (
            nip VARCHAR PRIMARY KEY,
            vendor_name VARCHAR,
            avg_payment_delay DOUBLE,
            price_volatility_index DOUBLE,
            total_volume_ytd DOUBLE,
            reliability_score DOUBLE,
            rating_stars INTEGER,
            smart_alerts VARCHAR,
            updated_at TIMESTAMP DEFAULT now()
        )
        """)

        self.duckdb.execute("""
        CREATE TABLE IF NOT EXISTS vendor_price_alerts (
            id UUID DEFAULT uuid(),
            nip VARCHAR,
            item_name VARCHAR,
            current_price DOUBLE,
            six_month_avg DOUBLE,
            increase_ratio DOUBLE,
            alert_type VARCHAR,
            detected_at TIMESTAMP DEFAULT now()
        )
        """)

        self.duckdb.execute("""
        INSERT OR REPLACE INTO vendor_intelligence
        WITH payment_match AS (
            SELECT
                i.contractor_nip AS nip,
                COALESCE(i.contractor_name, i.supplier_name, 'Unknown') AS vendor_name,
                AVG(date_diff('day', i.due_date, bt.transfer_timestamp::DATE)) AS avg_payment_delay,
                SUM(CASE WHEN year(i.issue_date) = year(current_date) THEN i.amount_gross ELSE 0 END) AS total_volume_ytd
            FROM invoices_replica i
            LEFT JOIN bank_transfers_cache bt
                ON i.contractor_nip = bt.counterparty_nip
                AND abs(i.amount_gross - bt.amount) < 0.01
            WHERE i.contractor_nip IS NOT NULL
            GROUP BY 1, 2
        ),
        price_changes AS (
            SELECT
                contractor_nip AS nip,
                AVG(abs((unit_price - lag(unit_price) OVER w) / nullif(lag(unit_price) OVER w, 0))) * 100 AS price_volatility_index
            FROM invoice_items
            WINDOW w AS (PARTITION BY contractor_nip, lower(item_name) ORDER BY issue_date)
            GROUP BY 1
        )
        SELECT
            pm.nip,
            pm.vendor_name,
            COALESCE(pm.avg_payment_delay, 0),
            COALESCE(pc.price_volatility_index, 0),
            COALESCE(pm.total_volume_ytd, 0),
            GREATEST(0.0, LEAST(5.0, 5.0 - (COALESCE(pm.avg_payment_delay, 0) / 6.0))) AS reliability_score,
            CAST(round(GREATEST(1.0, LEAST(5.0, 5.0 - (COALESCE(pm.avg_payment_delay, 0) / 6.0)))) AS INTEGER) AS rating_stars,
            CASE
                WHEN COALESCE(pm.avg_payment_delay, 0) > 10 THEN 'Always pays late'
                WHEN COALESCE(pc.price_volatility_index, 0) > 8 THEN 'Rapid price increase'
                ELSE 'Stable cooperation'
            END AS smart_alerts,
            now()
        FROM payment_match pm
        LEFT JOIN price_changes pc ON pm.nip = pc.nip
        """)

        self.duckdb.execute("""
        INSERT INTO vendor_price_alerts (nip, item_name, current_price, six_month_avg, increase_ratio, alert_type)
        WITH price_baseline AS (
            SELECT
                contractor_nip AS nip,
                lower(item_name) AS normalized_item,
                max_by(item_name, issue_date) AS item_name,
                max_by(unit_price, issue_date) AS current_price,
                AVG(unit_price) FILTER (WHERE issue_date >= current_date - INTERVAL 6 MONTH) AS six_month_avg
            FROM invoice_items
            WHERE issue_date >= current_date - INTERVAL 12 MONTH
            GROUP BY 1, 2
        )
        SELECT
            nip,
            item_name,
            current_price,
            six_month_avg,
            ((current_price - six_month_avg) / nullif(six_month_avg, 0)) * 100,
            'PRICE_ALERT'
        FROM price_baseline
        WHERE six_month_avg > 0 AND current_price > six_month_avg * 1.05
        """)

    def get_vendor_context(self, nip: str) -> str:
        """Pobierz kontekst kontrahenta z cache'em (NexusCache L1 RAM).

        Wynik jest cache'owany przez 1h w NexusCache RAM.
        Metoda pozostaje synchroniczna — używa get_sync/set_sync.
        """
        cache_key = f"vendor_context:{nip}"

        cached = self._cache.get_sync(cache_key)
        if cached is not None:
            return str(cached)

        rows = self.duckdb.execute(
            """
            SELECT nip, vendor_name, avg_payment_delay, price_volatility_index,
                   total_volume_ytd, reliability_score, rating_stars, smart_alerts
            FROM vendor_intelligence
            WHERE nip = ?
            """,
            (nip,),
        )
        if not rows:
            result = f"No local vendor intelligence found for NIP {nip}."
        else:
            v = rows[0]
            result = (
                f"Vendor {v[1]} (NIP: {v[0]}). "
                f"Average payment delay: {v[2]:.1f} days. "
                f"Price volatility index: {v[3]:.2f}%. "
                f"YTD volume: {v[4]:.2f}. "
                f"Reliability score: {v[5]:.2f}/5 ({v[6]} stars). "
                f"Smart alert: {v[7]}."
            )

        self._cache.set_sync(cache_key, result, ttl=self._CACHE_TTL)
        return result
