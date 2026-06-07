from __future__ import annotations

from dataclasses import dataclass
import pendulum
from typing import TYPE_CHECKING, Any

try:
    import networkx as nx
except Exception:  # pragma: no cover - optional fallback when networkx is unavailable
    class _FallbackGraph:
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

    class _NX:  # minimal shim for APIs used by this scanner
        Graph = _FallbackGraph

    nx = _NX()

if TYPE_CHECKING:
    from db.analytics import DuckDBManager


@dataclass(frozen=True)
class FraudAlert:
    rule_code: str
    severity: str
    employee_id: str
    vendor_id: str
    shared_attribute: str
    shared_value: str


class FraudGraphScanner:
    def __init__(self, duckdb: DuckDBManager):
        self.duckdb = duckdb

    def _fetch_entities(self, months_back: int = 12) -> list[tuple[Any, ...]]:
        cutoff_date = pendulum.now().date() - pendulum.duration(days=months_back * 30)
        return self.duckdb.execute(
            """
            SELECT entity_type, entity_id, iban, physical_address
            FROM fraud_entity_registry
            WHERE is_active = TRUE
              AND (last_seen_at IS NULL OR last_seen_at >= ?)
            """,
            (cutoff_date,),
        )

    @staticmethod
    def _build_graph(rows: list[tuple[Any, ...]]):
        graph = nx.Graph()
        for entity_type, entity_id, iban, physical_address in rows:
            entity_node = f"{entity_type}:{entity_id}"
            graph.add_node(entity_node, node_type=entity_type)
            if iban:
                iban_node = f"IBAN:{str(iban).strip()}"
                graph.add_node(iban_node, node_type="IBAN")
                graph.add_edge(entity_node, iban_node, edge_type="Shares_IBAN")
            if physical_address:
                address_node = f"ADDR:{str(physical_address).strip().lower()}"
                graph.add_node(address_node, node_type="ADDRESS")
                graph.add_edge(entity_node, address_node, edge_type="Shares_Address")
        return graph

    def detect_shared_identity_links(self, months_back: int = 12) -> list[FraudAlert]:
        graph = self._build_graph(self._fetch_entities(months_back=months_back))
        employees = [n for n, d in graph.nodes(data=True) if d.get("node_type") == "EMPLOYEE"]
        vendors = [n for n, d in graph.nodes(data=True) if d.get("node_type") == "VENDOR"]
        alerts: list[FraudAlert] = []
        for employee in employees:
            for vendor in vendors:
                for shared in set(graph.neighbors(employee)).intersection(graph.neighbors(vendor)):
                    if shared.startswith("IBAN:"):
                        alerts.append(FraudAlert("GHOST_VENDOR_SHARED_IBAN", "CRITICAL", employee.split(':',1)[1], vendor.split(':',1)[1], "IBAN", shared.removeprefix("IBAN:")))
                    elif shared.startswith("ADDR:"):
                        alerts.append(FraudAlert("GHOST_VENDOR_SHARED_ADDRESS", "HIGH", employee.split(':',1)[1], vendor.split(':',1)[1], "ADDRESS", shared.removeprefix("ADDR:")))
        return alerts
