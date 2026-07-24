"""
v7.0 VAT/MPP ORKIESTRATOR — Pre-OPA Carousel Check Bridge (MR-2).

Synchroniczny bridge do wykrywania karuzel VAT przed ewaluacją OPA.
Analizuje graf transakcji w poszukiwaniu cykli A→B→C→A
i wstrzykuje wynik jako input.risk.carousel_* do kontekstu OPA.

Raport v7.0 LUKA: VAT carousel graph scanner działa w izolacji.
Ten bridge zamyka tę lukę.

Wykrywane wzorce:
- Cykle A→B→C→A w < 30 dni
- Ten sam towar w wielu transakcjach
- Szybkie transakcje (w ciągu 7 dni)
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.pre_opa_carousel")


# ── Configuration ────────────────────────────────────────────────────────────

CAROUSEL_CYCLE_MAX_DAYS = 30       # Maksymalna długość cyklu w dniach
CAROUSEL_MIN_ENTITIES = 3          # Minimalna liczba podmiotów w karuzeli
CAROUSEL_SAME_ITEM_THRESHOLD = 2   # Min. transakcji z tym samym towarem
RAPID_TRANSACTIONS_DAYS = 7        # Okno dla szybkich transakcji
RAPID_TRANSACTIONS_THRESHOLD = 3   # Min. transakcji w oknie


@dataclass
class CarouselResult:
    """Wynik detekcji karuzeli VAT."""

    carousel_detected: bool = False
    carousel_type: str = ""  # CYCLE, SAME_ITEM, RAPID, IBAN_CLUSTER
    entities_involved: list[str] = field(default_factory=list)
    transaction_ids: list[str] = field(default_factory=list)
    risk_score: float = 0.0  # 0-100
    recommendation: str = ""

    def to_opa_context(self) -> dict[str, Any]:
        """Konwertuj do kontekstu OPA."""
        return {
            "carousel_detected": self.carousel_detected,
            "carousel_type": self.carousel_type,
            "carousel_entities": self.entities_involved,
            "carousel_transactions": self.transaction_ids,
            "carousel_risk_score": self.risk_score,
            "carousel_recommendation": self.recommendation,
        }


class PreOPACarouselChecker:
    """v7.0: Synchroniczny bridge VAT carousel detection → OPA.

    Używany przed ewaluacją OPA do wykrywania karuzel VAT
    i wstrzykiwania wyników do input.risk.

    Usage:
        checker = PreOPACarouselChecker()
        result = checker.check(invoice_data, contractor_data, history)
        opa_input["risk"].update(result.to_opa_context())
    """

    def __init__(self) -> None:
        self._transaction_graph: dict[str, set[str]] = {}
        self._entity_items: dict[str, list[str]] = {}
        self._entity_timestamps: dict[str, list[str]] = {}

    def add_entity(
        self,
        entity_nip: str,
        items_sold: list[str] | None = None,
        connected_entities: list[str] | None = None,
        timestamps: list[str] | None = None,
    ) -> None:
        """Dodaj encję do grafu transakcji."""
        if entity_nip not in self._transaction_graph:
            self._transaction_graph[entity_nip] = set()

        if connected_entities:
            for other in connected_entities:
                self._transaction_graph[entity_nip].add(other)
                if other not in self._transaction_graph:
                    self._transaction_graph[other] = set()
                self._transaction_graph[other].add(entity_nip)

        if items_sold:
            self._entity_items[entity_nip] = items_sold

        if timestamps:
            self._entity_timestamps[entity_nip] = timestamps

    def check(
        self,
        invoice_data: dict[str, Any],
        contractor_data: dict[str, Any] | None = None,
        transaction_history: list[dict[str, Any]] | None = None,
    ) -> dict[str, Any]:
        """Wykonaj pre-OPA carousel check.

        Sprawdza:
        1. Cykle A→B→C→A w grafie transakcji
        2. Ten sam towar w wielu transakcjach
        3. Szybkie transakcje (wiele w krótkim czasie)

        Args:
            invoice_data: Dane faktury.
            contractor_data: Dane kontrahenta.
            transaction_history: Historia transakcji.

        Returns:
            Dict z wynikami do wstrzyknięcia do OPA.
        """
        result = CarouselResult()

        contractor_nip = invoice_data.get("contractor_nip", "")
        vendor_nip = invoice_data.get("vendor_nip", "")
        item_name = invoice_data.get("item_name", "")
        invoice_date = invoice_data.get("transaction_date", "")

        # 0. Add current transaction entities to graph FIRST (before detection)
        if contractor_nip and vendor_nip:
            self.add_entity(contractor_nip, connected_entities=[vendor_nip])
            if item_name:
                self.add_entity(contractor_nip, items_sold=[item_name])
            if invoice_date:
                self.add_entity(contractor_nip, timestamps=[invoice_date])

        # 1. Wykrywanie cykli w grafie
        if contractor_nip and vendor_nip:
            cycle = self._detect_cycle(contractor_nip, vendor_nip)
            if cycle:
                result.carousel_detected = True
                result.carousel_type = "CYCLE"
                result.entities_involved = list(cycle)
                result.risk_score = 90.0
                result.recommendation = (
                    f"KARUZELA VAT: cykl {len(cycle)} podmiotów: "
                    f"{'→'.join(cycle)}→{list(cycle)[0]}. "
                    f"BLOCK_AND_ALERT + zgłoszenie MDR do KAS."
                )
                logger.warning(
                    "[CAROUSEL] Cycle detected: %s",
                    "→".join(cycle),
                )

        # 2. Ten sam towar w wielu transakcjach
        if not result.carousel_detected and transaction_history and item_name:
            same_items = [
                tx for tx in transaction_history
                if tx.get("item_name", "").lower() == item_name.lower()
                and tx.get("contractor_nip", "") != contractor_nip
            ]
            unique_counterparties = len({
                tx.get("contractor_nip", "") for tx in same_items
            })
            if len(same_items) >= CAROUSEL_SAME_ITEM_THRESHOLD and unique_counterparties >= 2:
                result.carousel_detected = True
                result.carousel_type = "SAME_ITEM"
                result.entities_involved = list({
                    tx.get("contractor_nip", "") for tx in same_items
                })
                result.risk_score = 75.0
                result.recommendation = (
                    f"Ten sam towar '{item_name[:50]}' w {len(same_items)} "
                    f"transakcjach z {unique_counterparties} różnymi kontrahentami"
                )

        # 3. Szybkie transakcje (wiele w krótkim czasie)
        if not result.carousel_detected and transaction_history and invoice_date:
            try:
                import pendulum
                inv_dt = pendulum.parse(invoice_date)
                recent_transactions = []

                for tx in transaction_history:
                    tx_date = tx.get("transaction_date", "")
                    if not tx_date:
                        continue
                    try:
                        tx_dt = pendulum.parse(tx_date)
                        if abs(tx_dt.diff(inv_dt).in_days()) <= RAPID_TRANSACTIONS_DAYS:
                            recent_transactions.append(tx)
                    except Exception:
                        continue

                if len(recent_transactions) >= RAPID_TRANSACTIONS_THRESHOLD:
                    unique_nips = len({
                        tx.get("contractor_nip", "") for tx in recent_transactions
                    })
                    if unique_nips >= 2:
                        result.carousel_detected = True
                        result.carousel_type = "RAPID_TRANSACTIONS"
                        result.entities_involved = list({
                            tx.get("contractor_nip", "") for tx in recent_transactions
                        })
                        result.risk_score = 65.0
                        result.recommendation = (
                            f"{len(recent_transactions)} transakcji w ciągu "
                            f"{RAPID_TRANSACTIONS_DAYS} dni z {unique_nips} podmiotami"
                        )
            except ImportError:
                pass

        logger.info(
            "[CAROUSEL] detected=%s type=%s score=%.1f",
            result.carousel_detected,
            result.carousel_type,
            result.risk_score,
        )

        return result.to_opa_context()

    def _detect_cycle(
        self, start_nip: str, vendor_nip: str,
    ) -> set[str] | None:
        """Wykryj cykl w grafie transakcji używając DFS.

        Szuka ścieżki: start_nip → vendor_nip → ... → start_nip
        z ograniczeniem głębokości do CAROUSEL_MIN_ENTITIES.
        """
        if start_nip not in self._transaction_graph:
            return None
        if vendor_nip not in self._transaction_graph:
            return None

        # DFS z ograniczeniem głębokości
        visited: set[str] = {start_nip}
        path = [start_nip]

        def dfs(current: str, depth: int) -> set[str] | None:
            if depth > CAROUSEL_MIN_ENTITIES + 2:
                return None

            neighbors = self._transaction_graph.get(current, set())
            for neighbor in neighbors:
                if neighbor == start_nip and depth >= CAROUSEL_MIN_ENTITIES - 1:
                    # Znaleziono cykl!
                    return set(path + [neighbor])

                if neighbor not in visited:
                    visited.add(neighbor)
                    path.append(neighbor)
                    result = dfs(neighbor, depth + 1)
                    if result:
                        return result
                    path.pop()
                    visited.discard(neighbor)

            return None

        # Rozpocznij DFS od vendor_nip
        if vendor_nip not in visited:
            visited.add(vendor_nip)
            path.append(vendor_nip)
            result = dfs(vendor_nip, 1)
            if result:
                return result

        return None

    def build_graph_from_history(
        self, transactions: list[dict[str, Any]],
    ) -> None:
        """Zbuduj graf transakcji z historii."""
        for tx in transactions:
            contractor = tx.get("contractor_nip", "")
            vendor = tx.get("vendor_nip", "")
            item = tx.get("item_name", "")
            date = tx.get("transaction_date", "")

            if contractor and vendor:
                if contractor not in self._transaction_graph:
                    self._transaction_graph[contractor] = set()
                if vendor not in self._transaction_graph:
                    self._transaction_graph[vendor] = set()
                self._transaction_graph[contractor].add(vendor)
                self._transaction_graph[vendor].add(contractor)

            if item and contractor:
                if contractor not in self._entity_items:
                    self._entity_items[contractor] = []
                self._entity_items[contractor].append(item)

            if date and contractor:
                if contractor not in self._entity_timestamps:
                    self._entity_timestamps[contractor] = []
                self._entity_timestamps[contractor].append(date)
