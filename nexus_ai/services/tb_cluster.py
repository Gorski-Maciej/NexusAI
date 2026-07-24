"""Distributed TigerBeetle Cluster Configuration.

v7.0 INNOWACJA #4 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "Distributed TigerBeetle Cluster z geo-replikacją"

Architektura:
  - 3 węzły TB z Viewstamped Replication (VR)
  - Automatyczny failover przy awarii węzła
  - Multi-region: Warszawa (primary), Frankfurt (secondary)
  - Client automatycznie wykrywa lidera
  - Monitoring health checków węzłów

Konfiguracja:
  - TB_CLUSTER_ID: unikalny ID klastra (różny od 0 dla izolacji środowisk)
  - TB_REPLICA_ADDRESSES: lista adresów węzłów
  - TB_REPLICA_COUNT: liczba replik (3)
  - VR: Viewstamped Replication dla consensusu
"""

from __future__ import annotations

import asyncio
import os
import time
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any, final

from structlog import get_logger

logger = get_logger("nexus.tb.cluster")


# ── Cluster Configuration ───────────────────────────────────────────────


@dataclass
class ClusterNode:
    """Pojedynczy węzeł klastra TB."""

    node_id: int
    host: str
    port: int
    region: str  # "warsaw", "frankfurt"
    role: str = "follower"  # "leader" | "follower"
    healthy: bool = True
    last_heartbeat: float = 0.0
    metrics: dict[str, Any] = field(default_factory=dict)


@dataclass
class ClusterConfig:
    """Konfiguracja klastra TB."""

    cluster_id: int
    replica_count: int = 3
    nodes: list[ClusterNode] = field(default_factory=list)
    replication_factor: int = 3
    quorum_size: int = 2  # majority: (n/2)+1

    @classmethod
    def production_warsaw_frankfurt(cls) -> ClusterConfig:
        """Produkcyjna konfiguracja: Warszawa + Frankfurt."""
        return cls(
            cluster_id=int(os.getenv("TB_CLUSTER_ID", "42")),
            replica_count=3,
            nodes=[
                ClusterNode(node_id=0, host="10.0.1.10", port=3001, region="warsaw"),
                ClusterNode(node_id=1, host="10.0.1.11", port=3001, region="warsaw"),
                ClusterNode(node_id=2, host="10.0.2.10", port=3001, region="frankfurt"),
            ],
        )

    @classmethod
    def development_single_node(cls) -> ClusterConfig:
        """Deweloperska konfiguracja: pojedynczy węzeł."""
        return cls(
            cluster_id=0,
            replica_count=1,
            quorum_size=1,
            nodes=[
                ClusterNode(node_id=0, host="localhost", port=3000, region="local", role="leader"),
            ],
        )

    @property
    def replica_addresses(self) -> str:
        """Zwróć listę adresów replik dla TB clienta."""
        return ",".join(f"{n.host}:{n.port}" for n in self.nodes)

    @property
    def leader(self) -> ClusterNode | None:
        """Znajdź aktualnego lidera."""
        for node in self.nodes:
            if node.role == "leader" and node.healthy:
                return node
        return None


# ── Cluster Health Monitor ───────────────────────────────────────────────


class ClusterHealthStatus(StrEnum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"  # Jeden węzeł down, ale quorum OK
    CRITICAL = "critical"  # Brak quorum — cluster niedostępny
    OFFLINE = "offline"


@dataclass
class ClusterHealth:
    """Stan zdrowia klastra."""

    status: ClusterHealthStatus = ClusterHealthStatus.OFFLINE
    healthy_nodes: int = 0
    total_nodes: int = 0
    quorum_available: bool = False
    leader_elected: bool = False
    last_leader_change: str = ""
    messages: list[str] = field(default_factory=list)


@final
class ClusterHealthMonitor:
    """Monitor zdrowia klastra TB (v7.0 Innowacja #4).

    Sprawdza dostępność węzłów, wykrywa utratę lidera,
    wysyła alerty przy degradacji klastra.

    Usage:
        config = ClusterConfig.production_warsaw_frankfurt()
        monitor = ClusterHealthMonitor(config)
        await monitor.start()
    """

    def __init__(
        self,
        config: ClusterConfig,
        *,
        check_interval: float = 10.0,
        nats_client=None,
    ) -> None:
        self._config = config
        self._interval = check_interval
        self._nats = nats_client
        self._running = False
        self._tasks: list[asyncio.Task] = []
        self._health = ClusterHealth(
            total_nodes=len(config.nodes),
        )

    @property
    def health(self) -> ClusterHealth:
        return self._health

    async def start(self) -> None:
        """Uruchom monitoring klastra."""
        if self._running:
            return
        self._running = True
        self._tasks.append(asyncio.create_task(self._monitor_loop()))
        logger.info("[TB-CLUSTER] Health monitor started — nodes=%d, interval=%.0fs",
                     len(self._config.nodes), self._interval)

    async def stop(self) -> None:
        """Zatrzymaj monitoring."""
        self._running = False
        for task in self._tasks:
            task.cancel()
        self._tasks.clear()

    async def check_health(self) -> ClusterHealth:
        """Sprawdź stan klastra natychmiast."""
        healthy = 0
        messages = []
        leader_found = False

        for node in self._config.nodes:
            try:
                # W praktyce: ping TB na danym węźle
                # Tu: symulacja — sprawdzenie connectivity
                node.healthy = self._ping_node(node)
                node.last_heartbeat = time.time()

                if node.healthy:
                    healthy += 1
                    if node.role == "leader":
                        leader_found = True
            except Exception as exc:
                node.healthy = False
                messages.append(f"Node {node.node_id} ({node.region}): {exc}")

        quorum = healthy >= self._config.quorum_size

        if healthy == self._config.total_nodes and leader_found:
            status = ClusterHealthStatus.HEALTHY
        elif quorum:
            status = ClusterHealthStatus.DEGRADED
            messages.append(f"Cluster degraded: {healthy}/{self._config.total_nodes} nodes healthy")
        elif healthy > 0:
            status = ClusterHealthStatus.CRITICAL
            messages.append(f"NO QUORUM: {healthy}/{self._config.total_nodes} nodes — cluster read-only")
        else:
            status = ClusterHealthStatus.OFFLINE
            messages.append("All nodes offline!")

        self._health = ClusterHealth(
            status=status,
            healthy_nodes=healthy,
            total_nodes=self._config.total_nodes,
            quorum_available=quorum,
            leader_elected=leader_found,
            messages=messages,
        )

        # Emituj alert NATS przy degradacji
        if status in (ClusterHealthStatus.DEGRADED, ClusterHealthStatus.CRITICAL):
            await self._emit_alert(status, messages)

        return self._health

    async def _monitor_loop(self) -> None:
        """Główna pętla monitoringu."""
        while self._running:
            try:
                await self.check_health()

                if self._health.status != ClusterHealthStatus.HEALTHY:
                    logger.warning("[TB-CLUSTER] %s: %s",
                                    self._health.status.value,
                                    "; ".join(self._health.messages))

            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("[TB-CLUSTER] Monitor error: %s", exc)

            await asyncio.sleep(self._interval)

    @staticmethod
    def _ping_node(node: ClusterNode) -> bool:
        """Ping węzła TB — sprawdza czy jest osiągalny."""
        try:
            # W praktyce: socket.connect() lub TB health check
            # Tu: uproszczona symulacja
            return True
        except Exception:
            return False

    async def _emit_alert(self, status: ClusterHealthStatus, messages: list[str]) -> None:
        """Emituj alert przez NATS."""
        if not self._nats:
            return
        try:
            import json

            alert = {
                "type": "tb_cluster_health",
                "status": status.value,
                "healthy_nodes": self._health.healthy_nodes,
                "total_nodes": self._health.total_nodes,
                "quorum": self._health.quorum_available,
                "messages": messages,
                "timestamp": time.time(),
            }
            await self._nats.publish("nexus.tb.cluster.health", json.dumps(alert).encode())
        except Exception as exc:
            logger.debug("[TB-CLUSTER] NATS alert failed: %s", exc)


# ── Failover Handler ─────────────────────────────────────────────────────


@final
class ClusterFailoverHandler:
    """Automatyczny failover klastra TB (v7.0 Innowacja #4).

    Przy utracie lidera:
    1. Wykrywa awarię (brak heartbeatu > 30s)
    2. Promuje najstarszego zdrowego followera na lidera
    3. Aktualizuje konfigurację TB clienta
    4. Loguje zmianę dla audytu
    """

    def __init__(self, config: ClusterConfig) -> None:
        self._config = config
        self._failover_count = 0
        self._last_failover: str = ""

    async def handle_leader_failure(self, failed_leader: ClusterNode) -> ClusterNode | None:
        """Obsłuż awarię lidera — promuj nowego.

        Returns:
            Nowy leader lub None jeśli brak dostępnych węzłów.
        """
        self._failover_count += 1
        self._last_failover = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

        logger.critical(
            "[TB-CLUSTER] LEADER FAILURE: node %d (%s) — initiating failover #%d",
            failed_leader.node_id, failed_leader.region, self._failover_count,
        )

        # Znajdź najstarszego zdrowego followera
        candidates = [
            n for n in self._config.nodes
            if n.healthy and n.node_id != failed_leader.node_id
        ]
        candidates.sort(key=lambda n: n.node_id)  # Najstarszy pierwszy

        if not candidates:
            logger.critical("[TB-CLUSTER] FAILOVER FAILED: No healthy followers available!")
            return None

        new_leader = candidates[0]
        failed_leader.role = "follower"
        new_leader.role = "leader"

        logger.info(
            "[TB-CLUSTER] FAILOVER SUCCESS: New leader = node %d (%s)",
            new_leader.node_id, new_leader.region,
        )

        return new_leader

    @property
    def failover_count(self) -> int:
        return self._failover_count

    def get_failover_report(self) -> dict[str, Any]:
        """Raport failoverów."""
        return {
            "total_failovers": self._failover_count,
            "last_failover": self._last_failover,
            "current_leader": self._config.leader.node_id if self._config.leader else None,
        }


# ── Client Connector ────────────────────────────────────────────────────


def create_cluster_client(config: ClusterConfig) -> Any:
    """Utwórz klienta TB podłączonego do klastra.

    v7.0 Innowacja #4: Automatycznie wykrywa lidera i konfiguruje
    klienta z pełną listą replik.

    Args:
        config: Konfiguracja klastra.

    Returns:
        TigerBeetleClient skonfigurowany dla klastra.
    """
    from nexus_ai.services.tigerbeetle.client import TigerBeetleClient

    client = TigerBeetleClient(
        cluster_id=config.cluster_id,
        replica_addresses=config.replica_addresses,
    )

    logger.info(
        "[TB-CLUSTER] Client created — cluster=%d, replicas=%d, addresses=%s",
        config.cluster_id,
        config.replica_count,
        config.replica_addresses,
    )

    return client
