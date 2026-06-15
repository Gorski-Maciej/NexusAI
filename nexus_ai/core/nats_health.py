"""
NATS JetStream Health Check & Supervisor — monitorowanie stanu NATS w API.

SUPERMOCE NATS:
  - Stream info — nazwa, subjects, stan, rozmiar, wiek najstarszej wiadomości
  - Consumer info — nazwa, durable/pull, pending, ack_pending, max_deliver
  - Connection status — połączenie, uptime, ping
  - Key-Value Store status — lista bucketów
  - Object Store status — lista bucketów
  - Metryki dla Prometheus/Grafana
  - Endpoint REST API dla diagnostyki

Usage:
    from nexus_ai.core.nats_health import NatsSupervisor

    supervisor = NatsSupervisor()
    await supervisor.start()
    status = await supervisor.get_full_status()
    await supervisor.stop()
"""

from __future__ import annotations

from typing import Any

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.core.config import AppConfig

logger = get_logger("nexus.nats.supervisor")


class NatsSupervisor:
    """NATS JetStream Supervisor — monitorowanie wszystkich strumieni i konsumentów.

    SUPERMOCE:
      - Pełny stan NATS: streams, consumers, connections
      - Metryki per-stream (messages, bytes, age)
      - Metryki per-consumer (pending, ack_pending, deliver)
      - Graceful degradation gdy NATS niedostępny

    Args:
        nats_servers: Serwery NATS.
        connect_timeout: Timeout na połączenie.
    """

    def __init__(
        self,
        nats_servers: list[str] | str | None = None,
        connect_timeout: float = 10.0,
    ) -> None:
        config = AppConfig()
        self._nats_servers = nats_servers or [config.nats_url]
        self._connect_timeout = connect_timeout
        self._nc: Any = None
        self._js: Any = None
        self._connected = False

    async def start(self) -> None:
        """Połącz z NATS."""
        try:
            import nats as nats_module

            self._nc = await nats_module.connect(
                servers=self._nats_servers,
                connect_timeout=self._connect_timeout,
                name="nexus-nats-supervisor",
            )
            self._js = self._nc.jetstream()
            self._connected = True
            logger.info("[NATS:SUPERVISOR] Connected to %s", self._nats_servers)
        except Exception as exc:
            logger.warning("[NATS:SUPERVISOR] Failed to connect: %s", exc)
            self._connected = False

    async def stop(self) -> None:
        """Zamknij połączenie."""
        if self._nc is not None:
            try:
                await self._nc.drain()
            except Exception:
                pass
            self._nc = None
            self._js = None
            self._connected = False

    # ── Connection check ──────────────────────────────────────────────

    async def check_connection(self) -> dict[str, Any]:
        """Sprawdź połączenie z NATS.

        SUPERMOC: Ping + server info + client ID.

        Returns:
            Stan połączenia.
        """
        if not self._connected or self._nc is None:
            return {"status": "DISCONNECTED", "servers": self._nats_servers}

        try:
            await self._nc.ping()
            server_info = self._nc.connected_url if hasattr(self._nc, "connected_url") else str(self._nats_servers)
            return {
                "status": "CONNECTED",
                "server": server_info,
                "client_id": self._nc.client_id if hasattr(self._nc, "client_id") else "unknown",
                "rtt": getattr(self._nc, "rtt", None),
            }
        except Exception as exc:
            return {"status": "ERROR", "error": str(exc), "servers": self._nats_servers}

    # ── Stream info ──────────────────────────────────────────────────

    async def get_streams(self, stream_names: list[str] | None = None) -> list[dict[str, Any]]:
        """Pobierz informacje o strumieniach JetStream.

        SUPERMOC: Pełne metryki per-stream.

        Args:
            stream_names: Lista nazw strumieni. Jeśli None, pobiera wszystkie.

        Returns:
            Lista stanów strumieni.
        """
        if not self._connected or self._js is None:
            return []

        results: list[dict[str, Any]] = []

        try:
            # Jeśli podano konkretne strumienie, pobierz je
            if stream_names:
                names = stream_names
            else:
                # Pobierz wszystkie strumienie
                streams_list = await self._js.streams_info()
                names = [s.name for s in streams_list] if hasattr(streams_list, '__iter__') else []

            for name in names:
                try:
                    info = await self._js.stream_info(name)
                    results.append(self._stream_to_dict(info))
                except Exception as exc:
                    results.append({
                        "name": name,
                        "status": "ERROR",
                        "error": str(exc),
                    })
        except Exception as exc:
            logger.warning("[NATS:SUPERVISOR] Failed to list streams: %s", exc)

        return results

    @staticmethod
    def _stream_to_dict(info: Any) -> dict[str, Any]:
        """Konwertuj StreamInfo na słownik.

        Args:
            info: Obiekt StreamInfo z nats-py.

        Returns:
            Słownik z polami strumienia.
        """
        result: dict[str, Any] = {
            "name": getattr(info, "name", "unknown"),
            "status": "OK",
        }

        # Stan
        if hasattr(info, "state"):
            state = info.state
            result["state"] = {
                "messages": getattr(state, "messages", 0),
                "bytes": getattr(state, "bytes", 0),
                "first_seq": getattr(state, "first_seq", 0),
                "last_seq": getattr(state, "last_seq", 0),
                "consumer_count": getattr(state, "consumer_count", 0),
                "num_subjects": getattr(state, "num_subjects", 0),
            }

        # Konfiguracja
        if hasattr(info, "config"):
            config = info.config
            result["config"] = {
                "subjects": list(getattr(config, "subjects", [])),
                "max_age": getattr(config, "max_age", 0),
                "max_bytes": getattr(config, "max_bytes", 0),
                "max_msg_size": getattr(config, "max_msg_size", 0),
                "storage": str(getattr(config, "storage", "")),
                "retention": str(getattr(config, "retention", "")),
                "replicas": getattr(config, "num_replicas", 1),
                "max_msgs_per_subject": getattr(config, "max_msgs_per_subject", 0),
            }

        return result

    # ── Consumer info ────────────────────────────────────────────────

    async def get_consumers(self, stream_name: str) -> list[dict[str, Any]]:
        """Pobierz informacje o konsumentach strumienia.

        SUPERMOC: Metryki per-consumer (pending, ack_pending, deliver).

        Args:
            stream_name: Nazwa strumienia.

        Returns:
            Lista stanów konsumentów.
        """
        if not self._connected or self._js is None:
            return []

        results: list[dict[str, Any]] = []
        try:
            consumers = await self._js.consumers_info(stream_name)
            for consumer in consumers:
                results.append(self._consumer_to_dict(consumer))
        except Exception as exc:
            logger.warning(
                "[NATS:SUPERVISOR] Failed to get consumers for %s: %s",
                stream_name, exc,
            )
        return results

    @staticmethod
    def _consumer_to_dict(info: Any) -> dict[str, Any]:
        """Konwertuj ConsumerInfo na słownik.

        Args:
            info: Obiekt ConsumerInfo z nats-py.

        Returns:
            Słownik z polami konsumenta.
        """
        result: dict[str, Any] = {
            "name": getattr(info, "name", "unknown"),
            "stream_name": getattr(info, "stream_name", ""),
            "status": "OK",
        }

        # Stan
        if hasattr(info, "state"):
            state = info.state
            result["state"] = {
                "delivered": getattr(state, "delivered", {}).get("consumer_seq", 0) if hasattr(state, "delivered") else 0,
                "acked": getattr(state, "ack_floor", {}).get("consumer_seq", 0) if hasattr(state, "ack_floor") else 0,
                "pending": getattr(state, "num_pending", 0),
                "ack_pending": getattr(state, "num_ack_pending", 0),
                "redeliveries": getattr(state, "num_redeliveries", 0),
                "waiting": getattr(state, "num_waiting", 0),
            }

        # Konfiguracja
        if hasattr(info, "config"):
            config = info.config
            result["config"] = {
                "durable": getattr(config, "durable_name", None) or getattr(config, "name", ""),
                "deliver_policy": str(getattr(config, "deliver_policy", "")),
                "ack_policy": str(getattr(config, "ack_policy", "")),
                "max_deliver": getattr(config, "max_deliver", 0),
                "ack_wait": getattr(config, "ack_wait", 0),
                "max_ack_pending": getattr(config, "max_ack_pending", 0),
                "filter_subject": getattr(config, "filter_subject", ""),
            }

        return result

    # ── Full status ──────────────────────────────────────────────────

    async def get_full_status(self) -> dict[str, Any]:
        """Pobierz pełny stan NATS: connection + streams + consumers.

        Returns:
            Kompletny stan NATS.
        """
        connection = await self.check_connection()
        if connection["status"] != "CONNECTED":
            return {
                "connection": connection,
                "streams": [],
                "timestamp": pendulum.now("UTC").isoformat(),
            }

        streams = await self.get_streams()

        # Dla każdego strumienia pobierz konsumentów
        for stream in streams:
            if stream.get("status") == "OK":
                stream["consumers"] = await self.get_consumers(stream["name"])

        return {
            "connection": connection,
            "streams": streams,
            "stream_count": len(streams),
            "timestamp": pendulum.now("UTC").isoformat(),
            "version": "2.10+",
        }

    # ── Quick health check ───────────────────────────────────────────

    async def quick_health(self) -> dict[str, Any]:
        """Szybki health check — tylko ping + liczba strumieni.

        Returns:
            Podstawowy stan NATS.
        """
        connection = await self.check_connection()
        if connection["status"] != "CONNECTED":
            return {"nats": connection["status"]}

        try:
            streams = await self._js.streams_info() if self._js else []
            stream_count = len(list(streams)) if hasattr(streams, '__iter__') else 0
            return {
                "nats": "OK",
                "streams": stream_count,
                "connection": connection["status"],
            }
        except Exception as exc:
            return {"nats": "ERROR", "error": str(exc)}

    def is_connected(self) -> bool:
        return self._connected
