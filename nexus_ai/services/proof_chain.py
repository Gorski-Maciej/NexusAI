"""
Kryptograficzny Łańcuch Audytowy (Proof Chain) -- SHA-256 hash chain.

- Append-only decision_traces z SHA-256 hash chain
- previous_hash + current_hash dla nieprzerwanego łańcucha dowodowego
- Integrity Verifier -- cykliczne przeliczanie łańcucha
- Explainer API -- GET /api/v2/audit/tax-decision/{transaction_id}

Zgodnie z docs/tfgxzd.txt -- Kryptograficzny Ślad Audytowy Decyzji.
"""

from __future__ import annotations

import hashlib
import uuid
from datetime import UTC, datetime
from typing import Any

import duckdb
from structlog import get_logger

from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads

logger = get_logger("nexus.audit.proof_chain")


class ProofChain:
    """Kryptograficzny łańcuch audytowy dla decyzji podatkowych.

    Każda decyzja jest zapisywana w tabeli tax_decision_audits z:
    - previous_hash: SHA-256 poprzedniego wpisu
    - current_hash: SHA-256(previous_hash + payload + timestamp)
    - context_snapshot: zamrożony kontekst z dnia decyzji
    """
    __slots__ = ('_conn',)


    def __init__(self, conn: duckdb.DuckDBPyConnection) -> None:
        self._conn = conn
        self._ensure_schema()

    def _ensure_schema(self) -> None:
        """Utwórz tabelę tax_decision_audits jeśli nie istnieje."""
        self._conn.execute("""
            CREATE TABLE IF NOT EXISTS tax_decision_audits (
                audit_id           VARCHAR PRIMARY KEY,
                transaction_id     VARCHAR NOT NULL,
                trace_json         VARCHAR NOT NULL,
                context_snapshot   VARCHAR NOT NULL,
                previous_hash      VARCHAR(64) NOT NULL DEFAULT '',
                current_hash       VARCHAR(64) NOT NULL,
                created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """)
        self._conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_tax_decision_audits_tx
            ON tax_decision_audits(transaction_id)
        """)
        self._conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_tax_decision_audits_hash
            ON tax_decision_audits(current_hash)
        """)

    def log_decision(
        self,
        transaction_id: str,
        trace: dict[str, Any],
        context: dict[str, Any],
    ) -> str:

        """Log a decision to the proof chain.

        Args:
            transaction_id: ID transakcji (faktury).
            trace: Pełny ślad decyzyjny (evaluated_rules, verdict).
            context: Zrzut kontekstu z dnia transakcji.

        Returns:
            audit_id utworzonego wpisu.
        """
        audit_id = uuid.uuid4().hex

        # Pobierz ostatni hash do łańcucha
        last_row = self._conn.execute(
            "SELECT current_hash FROM tax_decision_audits ORDER BY created_at DESC LIMIT 1"
        ).fetchone()
        previous_hash = str(last_row[0]) if last_row else "0" * 64

        # Serializuj payload
        payload = msgspec_dumps(
            {"trace": trace, "context": context},
            ensure_ascii=False,
            sort_keys=True,
        )

        # Oblicz SHA-256 hash
        raw = (previous_hash + payload + datetime.now(UTC).isoformat()).encode("utf-8")
        current_hash = hashlib.sha256(raw).hexdigest()

        # Zapisz w bazie (append-only)
        self._conn.execute(
            """INSERT INTO tax_decision_audits
               (audit_id, transaction_id, trace_json, context_snapshot,
                previous_hash, current_hash)
               VALUES (?, ?, ?, ?, ?, ?)""",
            (
                audit_id,
                transaction_id,
                payload,
                msgspec_dumps(context, ensure_ascii=False),
                previous_hash,
                current_hash,
            ),
        )

        logger.info(
            "[PROOF-CHAIN] Logged decision %s for tx=%s (hash=%s...)",
            audit_id,
            transaction_id,
            current_hash[:16],
        )
        return audit_id

    def get_decision(self, transaction_id: str) -> dict[str, Any] | None:
        """Pobierz decyzję dla transakcji.

        Args:
            transaction_id: ID transakcji.

        Returns:
            Dict z pełną decyzją lub None.
        """
        row = self._conn.execute(
            "SELECT audit_id, trace_json, context_snapshot, current_hash, created_at "
            "FROM tax_decision_audits WHERE transaction_id = ? "
            "ORDER BY created_at DESC LIMIT 1",
            (transaction_id,),
        ).fetchone()

        if not row:
            return None

        return {
            "audit_id": str(row[0]),
            "trace": msgspec_loads(str(row[1])),
            "context_snapshot": msgspec_loads(str(row[2])),
            "current_hash": str(row[3]),
            "created_at": str(row[4]),
            "hash_valid": self._verify_hash(str(row[0])),
        }

    def _verify_hash(self, audit_id: str) -> bool:

        """Przelicza hash dla wpisu i porównuje z zapisanym.
        """
        row = self._conn.execute(
            "SELECT previous_hash, trace_json, current_hash, created_at "
            "FROM tax_decision_audits WHERE audit_id = ?",
            (audit_id,),
        ).fetchone()
        if not row:
            return False

        raw = (str(row[0]) + str(row[1]) + str(row[3])).encode("utf-8")
        expected = hashlib.sha256(raw).hexdigest()
        return expected == str(row[2])

    def verify_chain(self) -> dict[str, Any]:
        """Verify the proof chain integrity.

        Returns:
            Dict z wynikiem weryfikacji.
        """
        rows = self._conn.execute(
            "SELECT audit_id, previous_hash, current_hash, created_at "
            "FROM tax_decision_audits ORDER BY created_at ASC"
        ).fetchall()

        if not rows:
            return {"valid": True, "total_decisions": 0, "message": "Empty chain"}

        prev_hash = "0" * 64
        invalid_count = 0

        for r in rows:
            if str(r[1]) != prev_hash:
                invalid_count += 1
            prev_hash = str(r[2])

        return {
            "valid": invalid_count == 0,
            "total_decisions": len(rows),
            "invalid_links": invalid_count,
            "message": "Chain is intact"
            if invalid_count == 0
            else f"Broken at {invalid_count} link(s)",
        }

    def explain_decision(self, transaction_id: str) -> dict[str, Any]:
        """Explain a decision for a transaction.

        Args:
            transaction_id: ID transakcji.

        Returns:
            Dict z czytelnym wyjaśnieniem decyzji.
        """
        decision = self.get_decision(transaction_id)
        if not decision:
            return {"error": f"No decision found for transaction {transaction_id}"}

        trace = decision.get("trace", {})
        verdict = trace.get("verdict", {})
        context = decision.get("context_snapshot", {})

        return {
            "transaction_id": transaction_id,
            "audit_id": decision["audit_id"],
            "timestamp": decision["created_at"],
            "hash_valid": decision["hash_valid"],
            "decision": {
                "rule_id": verdict.get("_rule_id", "unknown"),
                "vat_rate": verdict.get("vat_rate", "unknown"),
                "rounding_level": verdict.get("rounding_level", "unknown"),
                "income_tax_qualification": verdict.get("income_tax_qualification", "unknown"),
                "action": verdict.get("action", "AUTO_POST"),
            },
            "context": {
                "category_code": context.get("category_code", "unknown"),
                "company_tax_form": context.get("company_tax_form", "unknown"),
                "vendor_country": context.get("vendor_country", "unknown"),
            },
            "chain_integrity": "INTACT" if decision["hash_valid"] else "COMPROMISED",
        }
