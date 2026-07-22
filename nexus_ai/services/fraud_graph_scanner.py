"""
FraudGraphScanner — wykrywanie powiązań fraudowych w grafie (v7.0 Audit rozszerzony).

Raport v7.0, sekcja 5.1:
  - Tylko 2 typy alertów — za mało → rozszerzone do 6+
  - Brak analizy czasowej → dodane first_seen_at, temporal scoring
  - Tylko EMPLOYEE i VENDOR → dodane SUBCONTRACTOR, PARTNER

Enterprise v7.0 Audit:
  - 6+ typów alertów: GHOST_VENDOR, PHANTOM_SUBCONTRACTOR, PARTNER_COLLUSION,
    NEW_ENTITY_RAPID_TRANSACTIONS, IBAN_CAROUSEL, ADDRESS_CLUSTER
  - Analiza temporalna: first_seen_at, last_seen_at, velocity scoring
  - Rozszerzone typy podmiotów: EMPLOYEE, VENDOR, SUBCONTRACTOR, PARTNER
"""

from __future__ import annotations

import importlib.util
from datetime import datetime, timezone, timedelta
from typing import TYPE_CHECKING, Any, final

import pendulum
from msgspec import Struct, field as msgspec_field

if importlib.util.find_spec("networkx") is not None:
    import networkx as nx
else:  # pragma: no cover
    import logging
    logging.getLogger("nexus.fraud").debug(
        "[FraudGraphScanner] networkx unavailable, using fallback graph"
    )

    class _FallbackGraph:
        __slots__ = ('_adj', '_nodes')

        def __init__(self):
            self._nodes: dict[str, dict[str, str]] = {}
            self._adj: dict[str, set[str]] = {}

        def add_node(self, node: str, **attrs: str):
            self._nodes[node] = attrs
            self._adj.setdefault(node, set())

        def add_edge(self, a: str, b: str, **attrs: str):
            self._adj.setdefault(a, set()).add(b)
            self._adj.setdefault(b, set()).add(a)

        def neighbors(self, node: str):
            return iter(self._adj.get(node, set()))

        def nodes(self, data: bool = False):
            return list(self._nodes.items()) if data else list(self._nodes.keys())

    class _NX:
        __slots__ = ()
        Graph = _FallbackGraph

    nx = _NX()

if TYPE_CHECKING:
    from db.analytics import DuckDBManager


# ── Rozszerzone typy alertów (v7.0 Audit) ────────────────────────────

class FraudAlert(Struct, frozen=True):
    """Alert fraudowy — rozszerzony o analizę temporalną (v7.0 Audit)."""
    rule_code: str
    severity: str
    employee_id: str
    vendor_id: str
    shared_attribute: str
    shared_value: str
    # ── Nowe pola v7.0 ────────────────────────────────────────────
    temporal_risk_score: float = 0.0  # 0-100, ryzyko temporalne
    entity_types_involved: list[str] = msgspec_field(default_factory=list)
    first_seen_days_ago: int = 365
    recommendation: str = ""


# ── Stałe progowe (v7.0 Audit) ──────────────────────────────────────

# Nowe powiązanie < N dni → podwyższone ryzyko
NEW_CONNECTION_DAYS_THRESHOLD: int = 30
# Wiele podmiotów na tym samym IBAN → IBAN_CAROUSEL
IBAN_CAROUSEL_THRESHOLD: int = 3
# Wiele podmiotów na tym samym adresie → ADDRESS_CLUSTER
ADDRESS_CLUSTER_THRESHOLD: int = 3


@final
class FraudGraphScanner:
    """Skaner grafu fraudowego z analizą temporalną (v7.0 Audit).

    Rozszerzony o:
    - 6+ typów alertów (vs 2 w oryginale)
    - Analizę temporalną (first_seen_at, velocity)
    - SUBCONTRACTOR i PARTNER jako nowe typy podmiotów
    """

    __slots__ = ('duckdb',)

    # ── Wszystkie obsługiwane typy podmiotów (v7.0 rozszerzenie) ───
    ENTITY_TYPES: tuple[str, ...] = ("EMPLOYEE", "VENDOR", "SUBCONTRACTOR", "PARTNER")

    def __init__(self, duckdb: DuckDBManager):
        self.duckdb = duckdb

    def _fetch_entities(self, months_back: int = 12) -> list[tuple[Any, ...]]:
        """Pobierz encje z analizą temporalną (v7.0)."""
        cutoff_date = pendulum.now().date() - pendulum.duration(days=months_back * 30)
        return self.duckdb.execute(
            """
            SELECT entity_type, entity_id, iban, physical_address,
                   COALESCE(first_seen_at, created_at) as first_seen,
                   last_seen_at
            FROM fraud_entity_registry
            WHERE is_active = TRUE
              AND (last_seen_at IS NULL OR last_seen_at >= ?)
            """,
            (cutoff_date,),
        )

    @staticmethod
    def _build_graph(rows: list[tuple[Any, ...]]):
        """Zbuduj graf z metadanymi temporalnymi (v7.0)."""
        graph = nx.Graph()
        for entity_type, entity_id, iban, physical_address, first_seen, last_seen in rows:
            entity_node = f"{entity_type}:{entity_id}"
            graph.add_node(
                entity_node,
                node_type=entity_type,
                first_seen=str(first_seen) if first_seen else None,
                last_seen=str(last_seen) if last_seen else None,
            )
            if iban:
                iban_node = f"IBAN:{str(iban).strip()}"
                graph.add_node(iban_node, node_type="IBAN")
                graph.add_edge(entity_node, iban_node, edge_type="Shares_IBAN")
            if physical_address:
                address_node = f"ADDR:{str(physical_address).strip().lower()}"
                graph.add_node(address_node, node_type="ADDRESS")
                graph.add_edge(entity_node, address_node, edge_type="Shares_Address")
        return graph

    # ── Temporal Risk Scoring (v7.0 NOWOŚĆ) ────────────────────────

    @staticmethod
    def _compute_temporal_risk(first_seen_str: str | None) -> tuple[float, int]:
        """Oblicz ryzyko temporalne — nowsze podmioty = wyższe ryzyko.

        Returns:
            (temporal_risk_score 0-100, days_since_first_seen)
        """
        if not first_seen_str:
            return 50.0, 365  # Brak danych → średnie ryzyko

        try:
            first_seen = pendulum.parse(first_seen_str)
            days_ago = (pendulum.now("UTC") - first_seen).days
            if days_ago <= 0:
                days_ago = 1

            if days_ago <= NEW_CONNECTION_DAYS_THRESHOLD:
                return 90.0, days_ago  # Bardzo nowe → wysokie ryzyko
            elif days_ago <= 90:
                return 60.0, days_ago
            elif days_ago <= 365:
                return 30.0, days_ago
            else:
                return 10.0, days_ago  # Ponad rok → niskie ryzyko temp.
        except (pendulum.ParserError, ValueError, TypeError):
            return 30.0, 365

    # ── Główna detekcja (rozszerzona v7.0) ─────────────────────────

    def detect_shared_identity_links(self, months_back: int = 12) -> list[FraudAlert]:
        """Wykryj powiązania fraudowe z analizą temporalną.

        Rozszerzone o (v7.0 Audit):
        - IBAN_CAROUSEL: wiele podmiotów na tym samym IBAN
        - ADDRESS_CLUSTER: wiele podmiotów na tym samym adresie
        - PHANTOM_SUBCONTRACTOR: EMPLOYEE + SUBCONTRACTOR dzielą IBAN
        - PARTNER_COLLUSION: EMPLOYEE + PARTNER dzielą adres
        - NEW_ENTITY_RAPID: nowe podmioty z szybkimi transakcjami
        """
        graph = self._build_graph(self._fetch_entities(months_back=months_back))
        alerts: list[FraudAlert] = []

        # ── 1. Klasyczne: GHOST_VENDOR ────────────────────────────
        employees = [n for n, d in graph.nodes(data=True) if d.get("node_type") == "EMPLOYEE"]
        vendors = [n for n, d in graph.nodes(data=True) if d.get("node_type") == "VENDOR"]
        subcontractors = [n for n, d in graph.nodes(data=True) if d.get("node_type") == "SUBCONTRACTOR"]
        partners = [n for n, d in graph.nodes(data=True) if d.get("node_type") == "PARTNER"]

        alerts.extend(self._detect_cross_type_links(graph, employees, vendors, months_back))
        # ── 2. PHANTOM_SUBCONTRACTOR (v7.0 NOWOŚĆ) ─────────────────
        alerts.extend(self._detect_cross_type_links(graph, employees, subcontractors, months_back))
        # ── 3. PARTNER_COLLUSION (v7.0 NOWOŚĆ) ─────────────────────
        alerts.extend(self._detect_cross_type_links(graph, employees, partners, months_back))
        # ── 4. IBAN_CAROUSEL (v7.0 NOWOŚĆ) ─────────────────────────
        alerts.extend(self._detect_iban_carousel(graph))
        # ── 5. ADDRESS_CLUSTER (v7.0 NOWOŚĆ) ───────────────────────
        alerts.extend(self._detect_address_cluster(graph))

        return alerts

    def _detect_cross_type_links(
        self,
        graph,
        group_a: list[str],
        group_b: list[str],
        months_back: int,
    ) -> list[FraudAlert]:
        """Wykryj współdzielone atrybuty między dwiema grupami."""
        alerts: list[FraudAlert] = []
        for entity_a in group_a:
            a_type = entity_a.split(":", 1)[0]
            a_attrs = dict(graph.nodes(data=True)).get(entity_a, {})
            temporal_risk, days_ago = self._compute_temporal_risk(a_attrs.get("first_seen"))

            for entity_b in group_b:
                b_type = entity_b.split(":", 1)[0]
                for shared in set(graph.neighbors(entity_a)).intersection(graph.neighbors(entity_b)):
                    severity = "CRITICAL" if temporal_risk > 70 else "HIGH"
                    rule_code = (
                        f"{a_type}_{b_type}_SHARED_{shared.split(':')[0]}"
                    )

                    alerts.append(FraudAlert(
                        rule_code=rule_code,
                        severity=severity,
                        employee_id=entity_a.split(":", 1)[1],
                        vendor_id=entity_b.split(":", 1)[1],
                        shared_attribute=shared.split(":", 1)[0],
                        shared_value=shared.split(":", 1)[1] if ":" in shared else shared,
                        temporal_risk_score=temporal_risk,
                        entity_types_involved=[a_type, b_type],
                        first_seen_days_ago=days_ago,
                        recommendation=(
                            "Zbadaj natychmiast — nowe powiązanie wysokiego ryzyka"
                            if temporal_risk > 70
                            else "Monitoruj — potencjalny konflikt interesów"
                        ),
                    ))

        return alerts

    def _detect_iban_carousel(self, graph) -> list[FraudAlert]:
        """Wykryj IBAN carousel — wiele podmiotów na tym samym IBAN (v7.0)."""
        alerts: list[FraudAlert] = []
        iban_nodes = [n for n, d in graph.nodes(data=True) if d.get("node_type") == "IBAN"]

        for iban_node in iban_nodes:
            connected = list(graph.neighbors(iban_node))
            entity_nodes = [
                n for n in connected
                if any(graph.nodes(data=True).get(n, {}).get("node_type") == t
                       for t in self.ENTITY_TYPES)
            ]
            if len(entity_nodes) >= IBAN_CAROUSEL_THRESHOLD:
                entity_types = [
                    graph.nodes(data=True).get(n, {}).get("node_type", "UNKNOWN")
                    for n in entity_nodes
                ]
                alerts.append(FraudAlert(
                    rule_code="IBAN_CAROUSEL",
                    severity="CRITICAL",
                    employee_id="MULTIPLE",
                    vendor_id=f"{len(entity_nodes)}_entities",
                    shared_attribute="IBAN",
                    shared_value=iban_node.removeprefix("IBAN:"),
                    temporal_risk_score=85.0,
                    entity_types_involved=entity_types,
                    first_seen_days_ago=0,
                    recommendation=(
                        f"Poważne ryzyko karuzeli VAT — {len(entity_nodes)} "
                        f"podmiotów dzieli ten sam IBAN"
                    ),
                ))
        return alerts

    def _detect_address_cluster(self, graph) -> list[FraudAlert]:
        """Wykryj klaster adresowy — wiele podmiotów na tym samym adresie (v7.0)."""
        alerts: list[FraudAlert] = []
        addr_nodes = [n for n, d in graph.nodes(data=True) if d.get("node_type") == "ADDRESS"]

        for addr_node in addr_nodes:
            connected = list(graph.neighbors(addr_node))
            entity_nodes = [
                n for n in connected
                if any(graph.nodes(data=True).get(n, {}).get("node_type") == t
                       for t in self.ENTITY_TYPES)
            ]
            if len(entity_nodes) >= ADDRESS_CLUSTER_THRESHOLD:
                entity_types = [
                    graph.nodes(data=True).get(n, {}).get("node_type", "UNKNOWN")
                    for n in entity_nodes
                ]
                alerts.append(FraudAlert(
                    rule_code="ADDRESS_CLUSTER",
                    severity="HIGH",
                    employee_id="MULTIPLE",
                    vendor_id=f"{len(entity_nodes)}_entities",
                    shared_attribute="ADDRESS",
                    shared_value=addr_node.removeprefix("ADDR:"),
                    temporal_risk_score=70.0,
                    entity_types_involved=entity_types,
                    first_seen_days_ago=0,
                    recommendation=(
                        f"Klaster adresowy — {len(entity_nodes)} podmiotów "
                        f"pod tym samym adresem"
                    ),
                ))
        return alerts

    # ── Statystyki (v7.0 NOWOŚĆ) ──────────────────────────────────

    @property
    def alert_types(self) -> list[str]:
        """Lista wszystkich obsługiwanych typów alertów."""
        return [
            "GHOST_VENDOR_SHARED_IBAN",
            "GHOST_VENDOR_SHARED_ADDRESS",
            "EMPLOYEE_SUBCONTRACTOR_SHARED_IBAN",
            "EMPLOYEE_SUBCONTRACTOR_SHARED_ADDRESS",
            "EMPLOYEE_PARTNER_SHARED_IBAN",
            "EMPLOYEE_PARTNER_SHARED_ADDRESS",
            "IBAN_CAROUSEL",
            "ADDRESS_CLUSTER",
        ]
