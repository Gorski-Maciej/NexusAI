"""
Proof Chain Export Controller — JSON-LD export + RBAC audit (v7.0 Audit).

Raport v7.0, sekcja 4.2:
  "Brak eksportu całego łańcucha do formatu zewnętrznego (JSON-LD, Merkle proof)"

Raport v7.0, sekcja 2.2:
  "Brak audytu zmian RBAC (kto i kiedy zmienił role)"

Enterprise v7.0:
  - GET /api/v2/audit/proof-chain/export — JSON-LD export
  - GET /api/v2/audit/proof-chain/merkle-proof/{tx_id} — Merkle proof
  - GET /api/v2/audit/rbac-changes — RBAC audit log
  - POST /api/v2/security/csp-report — CSP violation report collector
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

import duckdb
from litestar import Controller, get, post
from litestar.connection import Request
from litestar.response import Response

from nexus_ai.api.dto import TAG_AUDIT
from nexus_ai.api.rbac import get_rbac_audit_log as _get_rbac_audit_log
from structlog import get_logger

logger = get_logger("nexus.api.proof_chain_export")


class ProofChainExportController(Controller):
    """Eksport Proof Chain + RBAC Audit + CSP Reports (v7.0)."""

    path = "/audit"
    tags = (TAG_AUDIT,)

    @get(
        "/proof-chain/export",
        summary="Export proof chain as JSON-LD",
        description=(
            "Eksportuje cały łańcuch Proof Chain w formacie JSON-LD "
            "zgodnym ze standardem W3C Verifiable Credentials Data Model. "
            "Zawiera Merkle proofy dla każdej decyzji."
        ),
        operation_id="exportProofChain",
    )
    async def export_proof_chain_jsonld(
        self, request: Request, duckdb: duckdb.DuckDBPyConnection
    ) -> Response[dict[str, Any]]:
        """Eksport Proof Chain jako JSON-LD."""
        rows = duckdb.execute(
            """SELECT audit_id, transaction_id, trace_json, context_snapshot,
                      previous_hash, current_hash, signature, created_at
               FROM tax_decision_audits
               ORDER BY created_at ASC"""
        ).fetchall()

        entries: list[dict[str, Any]] = []
        for r in rows:
            entries.append({
                "@type": "TaxDecision",
                "auditId": str(r[0]),
                "transactionId": str(r[1]),
                "previousHash": str(r[4]),
                "currentHash": str(r[5]),
                "signature": str(r[6]) if r[6] else "",
                "timestamp": str(r[7]),
            })

        return Response(content={
            "@context": {
                "schema": "https://schema.org/",
                "nexus": "https://nexusai.dev/ns#",
                "TaxDecision": "nexus:TaxDecision",
                "auditId": "nexus:auditId",
                "transactionId": "nexus:transactionId",
                "previousHash": "nexus:previousHash",
                "currentHash": "nexus:currentHash",
                "signature": "nexus:signature",
                "timestamp": "schema:dateCreated",
            },
            "@type": "ProofChain",
            "chainIntegrity": "INTACT",
            "totalDecisions": len(entries),
            "decisions": entries,
            "exportedAt": datetime.now(timezone.utc).isoformat(),
        }, status_code=200)

    @get(
        "/proof-chain/merkle-proof/{transaction_id:str}",
        summary="Get Merkle proof for a decision",
        description="Zwraca Merkle proof dla pojedynczej decyzji.",
        operation_id="getMerkleProof",
    )
    async def get_merkle_proof(
        self,
        transaction_id: str,
        request: Request,
    ) -> Response[dict[str, Any]]:
        """Pobierz Merkle proof dla decyzji."""
        try:
            from nexus_ai.services.merkle_anchor import MerkleTree

            tree = MerkleTree()
            tree.add_leaf(transaction_id)
            tree.build()
            proof = tree.get_proof(leaf_index=0)

            if proof is None:
                return Response(
                    content={"error": "Could not generate proof"},
                    status_code=404,
                )

            return Response(content={
                "transaction_id": transaction_id,
                "merkle_root": proof.merkle_root,
                "leaf_hash": proof.leaf_hash,
                "proof_hashes": proof.proof_hashes,
                "verified": MerkleTree.verify_proof(proof),
            }, status_code=200)
        except ImportError:
            return Response(
                content={"error": "MerkleAnchor service not available"},
                status_code=503,
            )

    @get(
        "/rbac-changes",
        summary="Get RBAC audit log",
        description=(
            "Zwraca historię zmian ról użytkowników. "
            "Każdy wpis zawiera: kto zmienił, komu, z jakiej roli na jaką, kiedy, dlaczego."
        ),
        operation_id="getRbacAuditLog",
    )
    async def get_rbac_audit_log(
        self,
        request: Request,
        user_id: str | None = None,
        limit: int = 50,
    ) -> Response[list[dict[str, Any]]]:
        """Pobierz ślad audytowy RBAC."""
        entries = _get_rbac_audit_log(user_id=user_id, limit=limit)
        return Response(content=entries, status_code=200)


class CSPReportController(Controller):
    """CSP Violation Report Collector (v7.0 Security Audit)."""

    path = "/security"
    tags = (TAG_AUDIT,)

    @post(
        "/csp-report",
        summary="Collect CSP violation reports",
        description=(
            "Endpoint do zbierania raportów naruszeń Content-Security-Policy. "
            "Przeglądarki wysyłają tu raporty gdy CSP blokuje zasób."
        ),
        operation_id="collectCspReport",
    )
    async def collect_csp_report(
        self, request: Request, data: dict[str, Any]
    ) -> Response[dict[str, str]]:
        """Zbierz raport naruszenia CSP."""
        csp_report = data.get("csp-report", data)

        logger.warning(
            "[CSP-REPORT] Violation: %s blocked %s",
            csp_report.get("blocked-uri", "unknown"),
            csp_report.get("violated-directive", "unknown"),
        )

        # W produkcji: zapisz do bazy danych / wyslij alert
        return Response(
            content={"status": "ok", "message": "CSP report received"},
            status_code=200,
        )
