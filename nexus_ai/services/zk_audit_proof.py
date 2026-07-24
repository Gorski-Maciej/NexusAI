"""Zero-Knowledge Audit Proof — kryptograficzne dowody audytowe bez ujawniania danych.

v7.0 INNOWACJA #8 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "Zero-Knowledge Audit Proof: Dowód audytowy bez ujawniania danych"

Architektura:
  - Merkle Proof zamiast pełnych danych księgowych
  - Audytor weryfikuje root hash + Merkle Proof
  - Nie potrzebuje dostępu do wszystkich transakcji
  - Zgodność z RODO — minimalizacja danych
  - Idealne dla audytów zewnętrznych

Math:
  Merkle Tree z wszystkich transferów w okresie.
  Root hash = H(H(H(A)+H(B)) + H(H(C)+H(D)))
  Merkle Proof dla transferu A = [H(B), H(H(C)+H(D))]
"""

from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass, field
from typing import Any, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.zk.audit")


@dataclass
class MerkleNode:
    """Węzeł drzewa Merkle."""

    hash: str
    left: MerkleNode | None = None
    right: MerkleNode | None = None
    data: Any = None  # Oryginalne dane (tylko dla liści)


@dataclass
class MerkleProof:
    """Dowód Merkle dla pojedynczego elementu."""

    leaf_hash: str
    leaf_index: int
    proof_hashes: list[str]  # Hashe potrzebne do weryfikacji
    proof_directions: list[str]  # "left" lub "right" dla każdego poziomu
    root_hash: str
    total_leaves: int


@dataclass
class ZKAuditReport:
    """Raport audytowy Zero-Knowledge."""

    report_id: str
    period_start: str
    period_end: str
    root_hash: str
    total_transfers: int
    merkle_proofs: list[MerkleProof] = field(default_factory=list)
    generated_at: str = field(default_factory=lambda: pendulum.now("UTC").isoformat())
    verifier_instructions: str = ""


@final
class ZKAuditProver:
    """Generator dowodów Zero-Knowledge dla audytów zewnętrznych (v7.0 Innowacja #8).

    Tworzy Merkle Tree z transferów i generuje Merkle Proofs,
    które audytor może zweryfikować bez dostępu do pełnych danych.

    Usage:
        prover = ZKAuditProver()
        tree = prover.build_merkle_tree(transfers)
        proof = prover.generate_proof(tree, transfer_index=42)
        # Wyślij auditorowi: root_hash + proof
        # Audytor weryfikuje: verify_proof(root_hash, proof) == True
    """

    def __init__(self) -> None:
        self._trees: dict[str, MerkleNode] = {}

    # ── Merkle Tree ────────────────────────────────────────────────────

    def build_merkle_tree(self, items: list[Any]) -> MerkleNode:
        """Zbuduj drzewo Merkle z listy elementów.

        Args:
            items: Lista elementów (transferów) do włączenia w drzewo.

        Returns:
            Korzeń drzewa Merkle.
        """
        if not items:
            empty_hash = hashlib.sha256(b"EMPTY_TREE").hexdigest()
            return MerkleNode(hash=empty_hash)

        # Krok 1: Utwórz liście
        leaves = []
        for i, item in enumerate(items):
            item_hash = self._hash_item(item, i)
            leaf = MerkleNode(hash=item_hash, data=item)
            leaves.append(leaf)

        # Krok 2: Buduj drzewo od dołu
        current_level = leaves
        while len(current_level) > 1:
            next_level = []
            for i in range(0, len(current_level), 2):
                left = current_level[i]
                right = current_level[i + 1] if i + 1 < len(current_level) else left

                combined = (left.hash + right.hash).encode("utf-8")
                parent_hash = hashlib.sha256(combined).hexdigest()

                parent = MerkleNode(hash=parent_hash, left=left, right=right)
                next_level.append(parent)
            current_level = next_level

        root = current_level[0]
        logger.info("[ZK-AUDIT] Built Merkle tree: %d leaves, root=%s",
                     len(leaves), root.hash[:16])
        return root

    def generate_proof(
        self,
        root: MerkleNode,
        item_index: int,
        total_items: int,
    ) -> MerkleProof:
        """Wygeneruj Merkle Proof dla elementu o podanym indeksie.

        Args:
            root: Korzeń drzewa Merkle.
            item_index: Indeks elementu w oryginalnej liście.
            total_items: Całkowita liczba elementów.

        Returns:
            MerkleProof do weryfikacji.
        """
        # Znajdź ścieżkę od liścia do korzenia
        path = self._find_proof_path(root, item_index, total_items)

        leaf = path[0]
        proof_hashes = []
        proof_directions = []

        for i in range(1, len(path)):
            node = path[i]
            # Określ, czy nasz element jest w lewym czy prawym poddrzewie
            current_index = item_index >> (len(path) - i - 1)
            if current_index % 2 == 0:
                # Jesteśmy w lewym poddrzewie — potrzebny prawy sąsiad
                if node.right:
                    proof_hashes.append(node.right.hash)
                    proof_directions.append("right")
            else:
                # Jesteśmy w prawym poddrzewie — potrzebny lewy sąsiad
                if node.left:
                    proof_hashes.append(node.left.hash)
                    proof_directions.append("left")

        proof = MerkleProof(
            leaf_hash=leaf.hash,
            leaf_index=item_index,
            proof_hashes=proof_hashes,
            proof_directions=proof_directions,
            root_hash=root.hash,
            total_leaves=total_items,
        )

        logger.info("[ZK-AUDIT] Generated proof for leaf %d/%d (root=%s)",
                     item_index, total_items, root.hash[:16])
        return proof

    @staticmethod
    def verify_proof(proof: MerkleProof) -> bool:
        """Zweryfikuj Merkle Proof.

        Audytor używa tej metody do weryfikacji, czy dany element
        należy do drzewa o podanym root hash. Nie potrzebuje
        pełnych danych — tylko root_hash + proof.

        Args:
            proof: MerkleProof do zweryfikowania.

        Returns:
            True jeśli proof jest poprawny.
        """
        current_hash = proof.leaf_hash

        for i, (sibling_hash, direction) in enumerate(
            zip(proof.proof_hashes, proof.proof_directions)
        ):
            if direction == "left":
                combined = (sibling_hash + current_hash).encode("utf-8")
            else:
                combined = (current_hash + sibling_hash).encode("utf-8")
            current_hash = hashlib.sha256(combined).hexdigest()

        return current_hash == proof.root_hash

    # ── High-level API ─────────────────────────────────────────────────

    def generate_audit_report(
        self,
        transfers: list[dict[str, Any]],
        *,
        period_start: str = "",
        period_end: str = "",
        sample_size: int | None = None,
    ) -> ZKAuditReport:
        """Wygeneruj pełny raport audytowy ZK.

        Args:
            transfers: Lista transferów do objęcia audytem.
            period_start: Początek okresu audytowego.
            period_end: Koniec okresu audytowego.
            sample_size: Liczba próbek do wygenerowania proofów
                        (None = wszystkie).

        Returns:
            ZKAuditReport gotowy do wysłania audytorowi.
        """
        tree = self.build_merkle_tree(transfers)
        report_id = f"ZK-AUDIT-{uuid.uuid4().hex[:12]}"

        # Wygeneruj proofy dla wybranych elementów
        proofs = []
        items_to_prove = list(range(len(transfers)))
        if sample_size and sample_size < len(items_to_prove):
            import random
            items_to_prove = random.sample(items_to_prove, sample_size)
            items_to_prove.sort()

        for idx in items_to_prove:
            proof = self.generate_proof(tree, idx, len(transfers))
            proofs.append(proof)

        return ZKAuditReport(
            report_id=report_id,
            period_start=period_start,
            period_end=period_end,
            root_hash=tree.hash,
            total_transfers=len(transfers),
            merkle_proofs=proofs,
            verifier_instructions=(
                f"Aby zweryfikować ten audyt:\n"
                f"1. Root hash: {tree.hash}\n"
                f"2. Dla każdego Merkle Proof: verify_proof(proof) == True\n"
                f"3. Jeśli wszystkie proofy są poprawne, dane są autentyczne.\n"
                f"4. Nie potrzebujesz dostępu do wszystkich {len(transfers)} transakcji."
            ),
        )

    # ── Internal ────────────────────────────────────────────────────────

    @staticmethod
    def _hash_item(item: Any, index: int) -> str:
        """Zhashuj pojedynczy element (liść drzewa)."""
        import json

        if isinstance(item, dict):
            raw = json.dumps(item, sort_keys=True, default=str).encode("utf-8")
        else:
            raw = str(item).encode("utf-8")

        # Dodaj indeks do hasha dla unikalności
        indexed = raw + str(index).encode("utf-8")
        return hashlib.sha256(indexed).hexdigest()

    def _find_proof_path(
        self,
        root: MerkleNode,
        item_index: int,
        total_items: int,
    ) -> list[MerkleNode]:
        """Znajdź ścieżkę od liścia do korzenia."""
        # Znajdź liść
        leaf = self._find_leaf_at_index(root, item_index, 0, total_items)
        if not leaf:
            raise ValueError(f"Leaf not found at index {item_index}")

        # Zbuduj ścieżkę (leaf → root)
        path = [leaf]
        current = leaf
        while current != root:
            parent = self._find_parent(root, current)
            if parent:
                path.append(parent)
                current = parent
            else:
                break

        return path

    def _find_leaf_at_index(
        self, node: MerkleNode, target: int, start: int, end: int
    ) -> MerkleNode | None:
        """Znajdź liść o podanym indeksie w drzewie."""
        if node.left is None and node.right is None:
            return node if start == target else None

        mid = (start + end) // 2
        if target < mid and node.left:
            return self._find_leaf_at_index(node.left, target, start, mid)
        elif node.right:
            return self._find_leaf_at_index(node.right, target, mid, end)

        return None

    def _find_parent(
        self, root: MerkleNode, child: MerkleNode
    ) -> MerkleNode | None:
        """Znajdź rodzica węzła w drzewie."""
        if root.left is child or root.right is child:
            return root
        if root.left:
            result = self._find_parent(root.left, child)
            if result:
                return result
        if root.right:
            result = self._find_parent(root.right, child)
            if result:
                return result
        return None
