from __future__ import annotations

from db.analytics import DuckDBManager


def ensure_zpk_schema(duck_mgr: DuckDBManager) -> None:
    duck_mgr.execute(
        """
        CREATE TABLE IF NOT EXISTS zpk_accounts (
            account_number VARCHAR PRIMARY KEY,
            team_id INTEGER NOT NULL,
            report_mapping VARCHAR NOT NULL,
            description VARCHAR NOT NULL,
            parent_account VARCHAR
        )
        """
    )
    duck_mgr.execute("CREATE INDEX IF NOT EXISTS idx_zpk_team ON zpk_accounts(team_id)")
    duck_mgr.execute(
        """
        CREATE TABLE IF NOT EXISTS zpk_mapping_history (
            vendor_nip VARCHAR,
            keyword_hash VARCHAR,
            account_wn VARCHAR NOT NULL,
            account_ma VARCHAR NOT NULL,
            source VARCHAR NOT NULL,
            created_at TIMESTAMP DEFAULT now()
        )
        """
    )
    duck_mgr.execute(
        """
        CREATE TABLE IF NOT EXISTS zpk_subaccounts (
            parent_account VARCHAR NOT NULL,
            vendor_nip VARCHAR NOT NULL,
            account_number VARCHAR PRIMARY KEY,
            description VARCHAR NOT NULL,
            created_at TIMESTAMP DEFAULT now()
        )
        """
    )
