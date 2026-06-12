from __future__ import annotations

from msgspec import Struct
from decimal import Decimal
from enum import StrEnum
from typing import TYPE_CHECKING, Any, Literal

if TYPE_CHECKING:
    from db.analytics import DuckDBManager


class AccountNature(StrEnum):
    DEBIT = "DEBIT"
    CREDIT = "CREDIT"


TransactionType = Literal["INVOICE_SALE", "BAD_DEBT_PROVISION", "DIVIDEND_PAYOUT"]


class LedgerEntryPacket(Struct, frozen=True):
    transaction_type: TransactionType
    debit_account_code: str
    credit_account_code: str
    tax_impact_code: str
    amount_minor: int
    currency: str
    metadata_tags: dict[str, Any]


def ensure_compliance_analytics_schema(duckdb: DuckDBManager) -> None:
    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS gl_accounts (
            account_code VARCHAR PRIMARY KEY,
            account_name VARCHAR NOT NULL,
            account_nature VARCHAR NOT NULL CHECK (account_nature IN ('DEBIT', 'CREDIT')),
            account_class VARCHAR NOT NULL,
            parent_account_code VARCHAR,
            is_active BOOLEAN NOT NULL DEFAULT TRUE
        )
        """
    )

    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS transaction_rules (
            transaction_type VARCHAR PRIMARY KEY,
            debit_account_code VARCHAR NOT NULL,
            credit_account_code VARCHAR NOT NULL,
            tax_impact_code VARCHAR NOT NULL,
            description VARCHAR
        )
        """
    )

    duckdb.execute(
        """
        CREATE TABLE IF NOT EXISTS tb_ledger_transfers (
            transfer_id UUID PRIMARY KEY,
            occurred_at TIMESTAMP NOT NULL,
            debit_account_code VARCHAR NOT NULL,
            credit_account_code VARCHAR NOT NULL,
            amount_minor BIGINT NOT NULL,
            currency VARCHAR NOT NULL,
            semantic_tags JSON,
            audit_log_id UUID
        )
        """
    )

    duckdb.execute(
        """
        INSERT OR IGNORE INTO gl_accounts (account_code, account_name, account_nature, account_class, parent_account_code)
        VALUES
            ('1000', 'Assets', 'DEBIT', 'ASSET', NULL),
            ('1100', 'Assets:Cash', 'DEBIT', 'ASSET', '1000'),
            ('2000', 'Liabilities', 'CREDIT', 'LIABILITY', NULL),
            ('2100', 'Liabilities:Payables', 'CREDIT', 'LIABILITY', '2000'),
            ('3000', 'Equity', 'CREDIT', 'EQUITY', NULL),
            ('4000', 'Revenue', 'CREDIT', 'REVENUE', NULL),
            ('4100', 'Revenue:Sales', 'CREDIT', 'REVENUE', '4000'),
            ('5000', 'Expenses', 'DEBIT', 'EXPENSE', NULL),
            ('5100', 'Expenses:BadDebt', 'DEBIT', 'EXPENSE', '5000')
        """
    )

    duckdb.execute(
        """
        INSERT OR IGNORE INTO transaction_rules (transaction_type, debit_account_code, credit_account_code, tax_impact_code, description)
        VALUES
            ('INVOICE_SALE', '1100', '4100', 'VAT_OUTPUT', 'Standard sales invoice'),
            ('BAD_DEBT_PROVISION', '5100', '2100', 'NO_VAT', 'Provision for bad debt'),
            ('DIVIDEND_PAYOUT', '3000', '1100', 'NO_VAT', 'Dividend payout to shareholders')
        """
    )

    duckdb.execute(
        """
        CREATE OR REPLACE VIEW v_account_balances AS
        WITH base AS (
            SELECT debit_account_code AS account_code, amount_minor AS delta_minor, currency, occurred_at, semantic_tags
            FROM tb_ledger_transfers
            UNION ALL
            SELECT credit_account_code AS account_code, -amount_minor AS delta_minor, currency, occurred_at, semantic_tags
            FROM tb_ledger_transfers
        ),
        recursive_rollup AS (
            SELECT
                a.account_code,
                a.parent_account_code,
                b.delta_minor,
                b.currency,
                b.occurred_at,
                b.semantic_tags
            FROM gl_accounts a
            LEFT JOIN base b ON b.account_code = a.account_code

            UNION ALL

            SELECT
                p.account_code,
                p.parent_account_code,
                rr.delta_minor,
                rr.currency,
                rr.occurred_at,
                rr.semantic_tags
            FROM recursive_rollup rr
            JOIN gl_accounts p ON rr.parent_account_code = p.account_code
        )
        SELECT
            account_code,
            currency,
            SUM(COALESCE(delta_minor, 0)) AS balance_minor,
            MAX(occurred_at) AS as_of_ts,
            semantic_tags
        FROM recursive_rollup
        GROUP BY 1,2,5
        """
    )


def infer_ledger_entries(
    duckdb: DuckDBManager, transaction_data: dict[str, Any]
) -> LedgerEntryPacket:
    transaction_type = str(transaction_data["transaction_type"])
    amount = Decimal(str(transaction_data["amount"]))
    currency = str(transaction_data.get("currency", "PLN"))
    if len(currency) != 3:
        raise ValueError("Currency must follow ISO 4217 (3-letter code)")

    rows = duckdb.execute(
        """
        SELECT debit_account_code, credit_account_code, tax_impact_code
        FROM transaction_rules
        WHERE transaction_type = ?
        LIMIT 1
        """,
        (transaction_type,),
    )
    if not rows:
        raise ValueError(f"No rule for transaction_type={transaction_type}")

    debit_account, credit_account, tax_impact_code = rows[0]

    return LedgerEntryPacket(
        transaction_type=transaction_type,  # type: ignore[arg-type]
        debit_account_code=str(debit_account),
        credit_account_code=str(credit_account),
        tax_impact_code=str(tax_impact_code),
        amount_minor=int(amount * 100),
        currency=currency.upper(),
        metadata_tags=transaction_data.get("metadata_tags", {}),
    )


def query_account_balances_by_tag(
    duckdb: DuckDBManager,
    *,
    tag_key: str,
    tag_value: str,
) -> list[tuple[Any, ...]]:
    """BQL-like helper for JSON tag filtering over v_account_balances."""
    return duckdb.execute(
        """
        SELECT account_code, currency, balance_minor
        FROM v_account_balances
        WHERE json_extract_string(semantic_tags, CONCAT('$.', ?)) = ?
        ORDER BY account_code
        """,
        (tag_key, tag_value),
    )
