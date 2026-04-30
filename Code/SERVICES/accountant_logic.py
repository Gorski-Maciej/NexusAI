from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from db.analytics import DuckDBManager


@dataclass(slots=True)
class AccountSuggestion:
    account_wn: str
    account_ma: str
    reason: str


class ZPKEngine:
    """Semantic Chart of Accounts engine backed by DuckDB."""

    def __init__(self, db: DuckDBManager):
        self.db = db
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        self.db.execute(
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
        self.db.execute(
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
        self.db.execute(
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

    def seed_default_accounts(self, rows: list[dict[str, Any]]) -> None:
        for row in rows:
            self.db.execute(
                """
                INSERT OR REPLACE INTO zpk_accounts (account_number, team_id, report_mapping, description, parent_account)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    row["account_number"],
                    int(row["team_id"]),
                    row["report_mapping"],
                    row["description"],
                    row.get("parent_account"),
                ),
            )

    def suggest_accounts(self, invoice_data: dict[str, Any], company_profile: dict[str, Any]) -> AccountSuggestion:
        keywords = [str(item.get("name", "")).lower().strip() for item in invoice_data.get("items", [])]
        vendor_nip = str(invoice_data.get("vendor_nip", "")).strip()
        keyword_hash = "|".join(sorted([k for k in keywords if k]))

        historical = self.db.execute(
            """
            SELECT account_wn, account_ma
            FROM zpk_mapping_history
            WHERE vendor_nip = ? AND keyword_hash = ?
            ORDER BY created_at DESC
            LIMIT 1
            """,
            (vendor_nip, keyword_hash),
        )
        if historical:
            return AccountSuggestion(account_wn=historical[0][0], account_ma=historical[0][1], reason="history")

        profile_kind = str(company_profile.get("business_kind", "")).lower()
        if any(word in keyword_hash for word in ["prąd", "energia", "electricity"]):
            return AccountSuggestion("401-1", "202", "semantic_energy")
        if any(word in keyword_hash for word in ["paliwo", "diesel", "benzyna"]):
            return AccountSuggestion("401-2", "202", "semantic_fuel")
        if "laptop" in keyword_hash and "it" in profile_kind:
            return AccountSuggestion("010", "202", "semantic_fixed_asset_it")

        return AccountSuggestion("409", "202", "fallback_other_costs")

    def learn_mapping(self, *, vendor_nip: str, keyword_hash: str, account_wn: str, account_ma: str, source: str = "owner") -> None:
        self.db.execute(
            """
            INSERT INTO zpk_mapping_history (vendor_nip, keyword_hash, account_wn, account_ma, source)
            VALUES (?, ?, ?, ?, ?)
            """,
            (vendor_nip, keyword_hash, account_wn, account_ma, source),
        )

    def ensure_vendor_subaccount(self, parent_account: str, vendor_nip: str, description: str) -> str:
        account_number = f"{parent_account}-{vendor_nip}"
        self.db.execute(
            """
            INSERT OR IGNORE INTO zpk_subaccounts (parent_account, vendor_nip, account_number, description)
            VALUES (?, ?, ?, ?)
            """,
            (parent_account, vendor_nip, account_number, description),
        )
        return account_number
