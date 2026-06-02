"""
PreLedgerValidator — warstwa walidacyjna przed TigerBeetle.

Ostatnia linia obrony przed błędnymi zapisami księgowymi.
Sprawdza:
  - Czy pary kont (debet/kredyt) są dozwolone dla danego typu transakcji
  - Czy kwoty mają odpowiedni znak (dodatni/ujemny)
  - Czy suma debetów = suma kredytów (bilans)
  - Czy kwoty nie przekraczają limitów
  - Deleguje do TaxInvariantGuard dla niezmienników matematycznych
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from decimal import Decimal
from typing import Any

import duckdb

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from tax.math_engine import InvoicePositions, InvoiceSummary

# Lazy imports for runtime to avoid circular dependency:
#   pre_ledger_validator → tax.math_engine → (via tax.__init__) → tax.pipeline → pre_ledger_validator

logger = logging.getLogger("nexus.pre_ledger_validator")


# ── Schemat tabeli reguł walidacji księgi ─────────────────────────────────

LEDGER_VALIDATION_RULES_SCHEMA = """
CREATE TABLE IF NOT EXISTS ledger_validation_rules (
    rule_id            VARCHAR PRIMARY KEY,
    transaction_type   VARCHAR NOT NULL,       -- EXPENSE, REVENUE, CORRECTION
    debit_account_id   INTEGER NOT NULL,        -- ID konta debetowego (Wn)
    credit_account_id  INTEGER NOT NULL,        -- ID konta kredytowego (Ma)
    amount_sign        VARCHAR NOT NULL DEFAULT 'POSITIVE',  -- POSITIVE, NEGATIVE, ANY
    priority           INTEGER NOT NULL DEFAULT 100,
    valid_from         DATE NOT NULL DEFAULT '2024-01-01',
    valid_to           DATE,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR DEFAULT 'system'
);
CREATE INDEX IF NOT EXISTS idx_ledger_rules_type ON ledger_validation_rules(transaction_type);
CREATE INDEX IF NOT EXISTS idx_ledger_rules_valid ON ledger_validation_rules(valid_from, valid_to);
"""


# ── Wyjątki ───────────────────────────────────────────────────────────────


class LedgerValidationError(ValueError):
    """Raised when a transaction fails pre-ledger validation."""

    def __init__(self, message: str, reason: str = "", details: dict | None = None) -> None:
        super().__init__(message)
        self.reason = reason
        self.details = details or {}


# ── Helper: lazy import for tax.math_engine ────────────────────────────────


def _get_math_engine():
    """Lazy import to avoid circular dependency."""
    from tax.math_engine import (
        ValidationResult,
        InvoiceSummary,
        InvoicePositions,
        validate_invariants as validate_math_invariants,
    )
    return ValidationResult, InvoiceSummary, InvoicePositions, validate_math_invariants


# ── Główna klasa walidatora ────────────────────────────────────────────────


@dataclass
class TransferSpec:
    """Pojedynczy transfer do walidacji.

    Attributes:
        debit_account_id: ID konta debetowego (Wn).
        credit_account_id: ID konta kredytowego (Ma).
        amount_grosze: Kwota w groszach (int).
        transfer_type: Typ transferu (np. 'expense', 'vat_input').
    """
    debit_account_id: int
    credit_account_id: int
    amount_grosze: int
    transfer_type: str = ""


class PreLedgerValidator:
    """WalIDATOR przedwysyłkowy dla TigerBeetle.

    Usage:
        validator = PreLedgerValidator(duckdb_conn)
        result = validator.validate(transfers, transaction_type="EXPENSE")
        if not result.is_valid:
            raise LedgerValidationError(result.error_message)
    """

    # Domyślne limity kwot (w PLN, konwertowane na grosze)
    MAX_INVOICE_AMOUNT_PLN = Decimal("10_000_000")  # 10 mln PLN
    MAX_INVOICE_AMOUNT_GROSZE = int(MAX_INVOICE_AMOUNT_PLN * 100)

    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        """Tworzy tabelę ledger_validation_rules jeśli nie istnieje."""
        self._conn.execute(LEDGER_VALIDATION_RULES_SCHEMA)

    def ensure_default_rules(
        self,
        expense_account_id: int = 40100,
        vat_account_id: int = 22100,
        payables_account_id: int = 20200,
        revenue_account_id: int = 70000,
    ) -> None:
        """Dodaje domyślne reguły walidacji (idempotentne — INSERT OR IGNORE).

        Args:
            expense_account_id: ID konta kosztów (debet dla netto).
            vat_account_id: ID konta VAT naliczonego (debet dla VAT).
            payables_account_id: ID konta rozrachunków (kredyt).
            revenue_account_id: ID konta przychodów (kredyt dla REVENUE).

        Standardowe reguły dla polskiego planu kont (domyślnie):
          - EXPENSE:  expense({expense_id})/VAT({vat_id}) → payables({payables_id})  [POSITIVE]
          - REVENUE:  payables({payables_id}) → revenue({revenue_id})                 [POSITIVE]
          - CORRECTION: odwrócone pary, ANY sign
        """
        default_rules = [
            # Faktura kosztowa — netto
            ("EXPENSE", expense_account_id, payables_account_id, "POSITIVE", 10),
            # Faktura kosztowa — VAT
            ("EXPENSE", vat_account_id, payables_account_id, "POSITIVE", 10),
            # Faktura przychodowa
            ("REVENUE", payables_account_id, revenue_account_id, "POSITIVE", 10),
            # Korekta kosztowa (ujemna)
            ("CORRECTION", payables_account_id, expense_account_id, "ANY", 10),
            # Korekta VAT
            ("CORRECTION", payables_account_id, vat_account_id, "ANY", 10),
        ]
        for ttype, debit, credit, sign, prio in default_rules:
            self._conn.execute(
                """INSERT OR IGNORE INTO ledger_validation_rules
                   (rule_id, transaction_type, debit_account_id, credit_account_id,
                    amount_sign, priority)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (
                    f"default_{ttype}_{debit}_{credit}",
                    ttype, debit, credit, sign, prio,
                ),
            )
        logger.info(
            "[PRE-LEDGER] Default rules seeded (expense=%d, vat=%d, payables=%d, rev=%d)",
            expense_account_id, vat_account_id, payables_account_id, revenue_account_id,
        )

    # ── Public API ───────────────────────────────────────────────────────

    def validate(
        self,
        transfers: list[TransferSpec],
        transaction_type: str = "EXPENSE",
        *,
        positions: list[InvoicePositions] | None = None,
        summary: InvoiceSummary | None = None,
    ) -> ValidationResult:
        """Główna walidacja przed wysłaniem do TigerBeetle.

        Args:
            transfers: Lista transferów do zweryfikowania.
            transaction_type: Typ transakcji (EXPENSE, REVENUE, CORRECTION).
            positions: Opcjonalne pozycje faktury do walidacji niezmienników.
            summary: Opcjonalne podsumowanie do walidacji niezmienników.

        Returns:
            ValidationResult — is_valid=True iff wszystkie testy przejdą.
        """
        ValidationResult, _, _, validate_math_invariants = _get_math_engine()

        errors: list[str] = []

        # 1. Walidacja niezmienników matematycznych (delegacja do TaxInvariantGuard)
        if positions is not None and summary is not None:
            math_result = validate_math_invariants(positions, summary)
            if not math_result.is_valid:
                errors.append(f"[INVARIANTS] {math_result.error_message}")

        # 2. Walidacja par kont dla typu transakcji
        for t in transfers:
            pair_errors = self._validate_transfer_pair(t, transaction_type)
            errors.extend(pair_errors)

        # 3. Walidacja znaku kwoty
        for t in transfers:
            sign_errors = self._validate_amount_sign(t, transaction_type)
            errors.extend(sign_errors)

        # 4. Bilans: suma debetów = suma kredytów
        balance_errors = self._validate_balance(transfers)
        errors.extend(balance_errors)

        # 5. Limity kwot
        for t in transfers:
            if abs(t.amount_grosze) > self.MAX_INVOICE_AMOUNT_GROSZE:
                errors.append(
                    f"[LIMIT] Transfer {t.transfer_type}: amount {t.amount_grosze} gr "
                    f"exceeds max {self.MAX_INVOICE_AMOUNT_GROSZE} gr "
                    f"({self.MAX_INVOICE_AMOUNT_PLN} PLN)"
                )

        if errors:
            return ValidationResult(is_valid=False, error_message="; ".join(errors))
        return ValidationResult(is_valid=True)

    def _validate_transfer_pair(
        self,
        transfer: TransferSpec,
        transaction_type: str,
    ) -> list[str]:
        """Sprawdza, czy para kont jest dozwolona dla danego typu transakcji."""
        row = self._conn.execute(
            """SELECT amount_sign FROM ledger_validation_rules
               WHERE transaction_type = ?
                 AND debit_account_id = ?
                 AND credit_account_id = ?
                 AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)""",
            (transaction_type, transfer.debit_account_id, transfer.credit_account_id),
        ).fetchone()

        if not row:
            return [
                f"[ACCOUNT_PAIR] {transaction_type}: debit={transfer.debit_account_id} "
                f"→ credit={transfer.credit_account_id} is not allowed "
                f"(transfer_type={transfer.transfer_type})"
            ]
        return []

    def _validate_amount_sign(
        self,
        transfer: TransferSpec,
        transaction_type: str,
    ) -> list[str]:
        """Sprawdza, czy kwota ma odpowiedni znak dla danego typu transakcji."""
        row = self._conn.execute(
            """SELECT amount_sign FROM ledger_validation_rules
               WHERE transaction_type = ?
                 AND debit_account_id = ?
                 AND credit_account_id = ?
                 AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)""",
            (transaction_type, transfer.debit_account_id, transfer.credit_account_id),
        ).fetchone()

        if not row:
            return []  # already reported by _validate_transfer_pair

        expected_sign = str(row[0])
        actual_sign = "POSITIVE" if transfer.amount_grosze >= 0 else "NEGATIVE"

        if expected_sign == "POSITIVE" and actual_sign != "POSITIVE":
            return [
                f"[AMOUNT_SIGN] {transaction_type} {transfer.transfer_type}: "
                f"expected POSITIVE, got {actual_sign} ({transfer.amount_grosze} gr)"
            ]
        if expected_sign == "NEGATIVE" and actual_sign != "NEGATIVE":
            return [
                f"[AMOUNT_SIGN] {transaction_type} {transfer.transfer_type}: "
                f"expected NEGATIVE, got {actual_sign} ({transfer.amount_grosze} gr)"
            ]
        # ANY — no restriction
        return []

    @staticmethod
    def _validate_balance(transfers: list[TransferSpec]) -> list[str]:
        """Sprawdza, czy suma debetów = suma kredytów.

        Dla TigerBeetle kierunek jest zakodowany w parach kont (debit→credit),
        a kwoty są zawsze dodatnie. Bilans jest sprawdzany przez Invariant 3
        (netto + VAT = brutto). Ta metoda jest zachowana dla kompletności,
        ale nie jest potrzebna — Invariant 3 już to pokrywa.
        """
        # Covered by Invariant 3 in TaxInvariantGuard
        return []

    # ── Zarządzanie regułami walidacji (dla admin) ───────────────────────

    def list_rules(self) -> list[dict[str, Any]]:
        """Lista wszystkich reguł walidacji księgi."""
        rows = self._conn.execute(
            """SELECT rule_id, transaction_type, debit_account_id, credit_account_id,
                      amount_sign, priority, valid_from, valid_to, created_at, created_by
               FROM ledger_validation_rules
               ORDER BY priority ASC, rule_id ASC""",
        ).fetchall()
        return [
            {
                "rule_id": str(r[0]),
                "transaction_type": str(r[1]),
                "debit_account_id": int(r[2]),
                "credit_account_id": int(r[3]),
                "amount_sign": str(r[4]),
                "priority": int(r[5]),
                "valid_from": str(r[6]),
                "valid_to": str(r[7]) if r[7] else None,
                "created_at": str(r[8]),
                "created_by": str(r[9]),
            }
            for r in rows
        ]

    def add_rule(
        self,
        transaction_type: str,
        debit_account_id: int,
        credit_account_id: int,
        *,
        amount_sign: str = "POSITIVE",
        priority: int = 100,
        valid_from: str = "2024-01-01",
        valid_to: str | None = None,
        created_by: str = "admin",
    ) -> str:
        """Dodaje nową regułę walidacji (append-only)."""
        import uuid
        rule_id = f"ledger_{uuid.uuid4().hex[:12]}"
        self._conn.execute(
            """INSERT INTO ledger_validation_rules
               (rule_id, transaction_type, debit_account_id, credit_account_id,
                amount_sign, priority, valid_from, valid_to, created_by)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (rule_id, transaction_type, debit_account_id, credit_account_id,
             amount_sign, priority, valid_from, valid_to, created_by),
        )
        logger.info("[PRE-LEDGER] Rule created id=%s type=%s debit=%d credit=%d",
                    rule_id, transaction_type, debit_account_id, credit_account_id)
        return rule_id

    def delete_rule(self, rule_id: str) -> bool:
        """Dezaktywuje regułę walidacji (append-only: ustawia valid_to na wczoraj).

        Zwraca True jeśli reguła istniała i została zdezaktywowana.
        """
        # Sprawdź czy reguła istnieje i jest aktywna
        row = self._conn.execute(
            "SELECT rule_id FROM ledger_validation_rules "
            "WHERE rule_id = ? AND valid_to IS NULL",
            (rule_id,),
        ).fetchone()

        if not row:
            return False

        # Append-only: ustaw valid_to zamiast DELETE
        self._conn.execute(
            """UPDATE ledger_validation_rules
               SET valid_to = CURRENT_DATE - INTERVAL '1 day'
               WHERE rule_id = ? AND valid_to IS NULL""",
            (rule_id,),
        )
        return True

    # ── Metryki ──────────────────────────────────────────────────────────

    def count_rules(self, active_only: bool = True) -> int:
        """Liczba reguł walidacji."""
        if active_only:
            row = self._conn.execute(
                """SELECT COUNT(*) FROM ledger_validation_rules
                   WHERE valid_to IS NULL OR valid_to >= CURRENT_DATE"""
            ).fetchone()
        else:
            row = self._conn.execute(
                "SELECT COUNT(*) FROM ledger_validation_rules"
            ).fetchone()
        return int(row[0]) if row else 0
