"""NATS Utilities — shared connection, publish, and RPC helpers for nats-py."""

from __future__ import annotations

from collections.abc import AsyncIterator
from pathlib import Path
from typing import Any, final

import anyio
import pendulum
from structlog import get_logger

from nexus_ai.core.config import AppConfig
from nexus_ai.core.msgspec_utils import msgspec_dumps_bytes
from nexus_ai.core.msgspec_utils import msgspec_loads as _msgspec_loads

logger = get_logger("nexus.nats.utils")


# ── nats-py error types ─────────────────────────────────────────────────


class NatsErrors:
    """Container for nats-py error types with graceful fallback."""
    __slots__ = ()
    TimeoutError: type[BaseException] = TimeoutError
    ConnectionClosedError: type[BaseException] = ConnectionError
    NoRespondersError: type[BaseException] = ConnectionError

    @classmethod
    def init(cls) -> None:
        try:
            import nats.errors as ne
            cls.TimeoutError = ne.TimeoutError
            cls.ConnectionClosedError = ne.ConnectionClosedError
            cls.NoRespondersError = ne.NoRespondersError
        except Exception as exc:
            logger.debug("[NATS] Error types import failed: %s", exc)


# ── Connection helpers ────────────────────────────────────────────────────


async def get_connection(
    nats_url: str | list[str] | None = None,
    name: str = "nexus-nats",
    connect_timeout: float = 10.0,
    enable_callbacks: bool = True,
) -> Any | None:
    """Connect to NATS with full configuration and lifecycle callbacks."""
    import nats as nats_module
    NatsErrors.init()
    if nats_url is None:
        config = AppConfig()
        nats_url = config.nats_url
    servers = [nats_url] if isinstance(nats_url, str) else list(nats_url)
    callbacks: dict[str, Any] = {}
    if enable_callbacks:
        async def _on_disconnect() -> None: logger.warning("[NATS:CALLBACK] Disconnected from %s", servers)
        async def _on_reconnect() -> None: logger.info("[NATS:CALLBACK] Reconnected to %s", servers)
        async def _on_close() -> None: logger.info("[NATS:CALLBACK] Connection closed to %s", servers)
        async def _on_error(err: Any) -> None: logger.error("[NATS:CALLBACK] Error: %s", err)
        callbacks = {"disconnected_cb": _on_disconnect, "reconnected_cb": _on_reconnect, "closed_cb": _on_close, "error_cb": _on_error}
    try:
        nc = await nats_module.connect(servers=servers, name=name, connect_timeout=connect_timeout,
                                        max_reconnect_attempts=-1, reconnect_time_wait=2.0, **callbacks)
        return nc
    except NatsErrors.TimeoutError:
        return None
    except NatsErrors.ConnectionClosedError:
        return None
    except Exception as exc:
        logger.warning("[NATS] Failed to connect to %s: %s", servers, exc)
        return None


async def safe_close(nc: Any | None, flush: bool = True) -> None:
    """Safely close NATS connection with optional flush."""
    if nc is None:
        return
    try:
        if flush:
            try: await nc.flush()
            except Exception:
                logger.debug("[NATS] Flush failed during close")
                pass
        await nc.drain()
    except Exception:
        try: await nc.close()
        except Exception:
            logger.debug("[NATS] Close failed during drain fallback")
            pass


# ── One-off publish ──────────────────────────────────────────────────────


async def publish_event(subject: str, data: Any, nats_url: str | list[str] | None = None) -> bool:
    """Publish event through NATS with auto connect/disconnect."""
    NatsErrors.init()
    nc = await get_connection(nats_url=nats_url, name="nexus-publisher")
    if nc is None:
        return False
    try:
        payload: bytes = data.encode("utf-8") if isinstance(data, str) else (data if isinstance(data, bytes) else msgspec_dumps_bytes(data))
        await nc.publish(subject, payload)
        await nc.flush()
        return True
    except NatsErrors.ConnectionClosedError:
        return False
    except Exception as exc:
        logger.warning("[NATS:PUBLISH] Failed to publish to %s: %s", subject, exc)
        return False
    finally:
        await safe_close(nc, flush=False)


# ── Request-Reply (RPC) ──────────────────────────────────────────────────


@final
class NatsRpcClient:
    """NATS Request-Reply client with auto-reconnect."""
    __slots__ = ()

    def __init__(self, nats_url: str | list[str] | None = None, name: str = "nexus-rpc-client", request_timeout: float = 5.0) -> None:
        NatsErrors.init()
        self._nats_url, self._name, self._request_timeout, self._nc = nats_url, name, request_timeout, None

    async def _ensure_connected(self) -> bool:
        if self._nc is not None and not self._nc.is_closed:
            try: await self._nc.ping(); return True
            except Exception:
                logger.debug("[NATS:RPC] Ping failed, reconnecting")
                pass
        self._nc = await get_connection(nats_url=self._nats_url, name=self._name)
        return self._nc is not None

    async def request(self, subject: str, data: Any, timeout: float | None = None) -> Any:
        """Send RPC request and wait for response."""
        if not await self._ensure_connected():
            raise NatsErrors.NoRespondersError(f"No NATS connection for {subject}")
        timeout = timeout or self._request_timeout
        payload: bytes = data if isinstance(data, bytes) else (data.encode("utf-8") if isinstance(data, str) else msgspec_dumps_bytes(data))
        try:
            msg = await self._nc.request(subject, payload, timeout=timeout)
            try: return msgspec.json.decode(msg.data)
            except Exception:
                logger.debug("[NATS:RPC] msgspec.json.decode failed, trying fallback")
                pass
                try: return _msgspec_loads(msg.data)
                except Exception:
                    logger.debug("[NATS:RPC] Both decoders failed, returning raw data")
                    return msg.data
        except NatsErrors.NoRespondersError:
            raise
        except NatsErrors.TimeoutError:
            raise
        except Exception as exc:
            logger.error("[NATS:RPC] Error for %s: %s", subject, exc)
            raise

    async def close(self) -> None:
        await safe_close(self._nc)
        self._nc = None


# ── Async Iterator Subscription ──────────────────────────────────────────


@final
class NatsSubscription:
    """NATS subscription with async iterator."""
    __slots__ = ()

    def __init__(self, subject: str, queue: str = "", nats_url: str | list[str] | None = None, name: str = "nexus-subscriber") -> None:
        NatsErrors.init()
        self._subject, self._queue, self._nats_url, self._name = subject, queue, nats_url, name
        self._nc: Any = None
        self._sub: Any = None

    async def __aenter__(self) -> NatsSubscription:
        await self._connect(); return self

    async def __aexit__(self, *args: Any) -> None:
        await self._disconnect()

    async def _connect(self) -> None:
        self._nc = await get_connection(nats_url=self._nats_url, name=self._name)
        if self._nc is not None:
            self._sub = await self._nc.subscribe(self._subject, queue=self._queue or None)

    async def _disconnect(self) -> None:
        if self._sub is not None:
            try: await self._sub.unsubscribe()
            except Exception:
                logger.debug("[NATS:SUB] Unsubscribe failed")
                pass
            self._sub = None
        await safe_close(self._nc); self._nc = None

    async def __aiter__(self) -> AsyncIterator[Any]:
        if self._sub is None:
            return
        try:
            async for msg in self._sub.messages:
                yield msg
        except Exception as exc:
            logger.warning("[NATS:SUB] Subscription error on %s: %s", self._subject, exc)

    async def get_metadata(self, msg: Any) -> dict[str, Any]:
        try:
            meta = msg.metadata()
            if meta is not None:
                seq = meta.sequence if hasattr(meta, "sequence") else None
                return {"timestamp": meta.timestamp, "stream_seq": getattr(seq, "stream", 0), "consumer_seq": getattr(seq, "consumer_seq", 0),
                        "stream": getattr(meta, "stream", ""), "subject": msg.subject}
        except Exception:
            pass
        return {"timestamp": pendulum.now("UTC").timestamp(), "subject": msg.subject}


# ═══════════════════════════════════════════════════════════════════════════════
# Key-Value Store (z nats_kv_store.py)
# ═══════════════════════════════════════════════════════════════════════════════

DEFAULT_KV_BUCKETS: dict[str, str] = {"nexus-config": "Global configuration store", "nexus-rules": "Tax and risk rules",
                                       "nexus-features": "Feature flags", "nexus-workers": "Worker status and heartbeats",
                                       "nexus-cache": "API response cache"}


@final
class NatsConfigStore:
    """Key-Value Store on NATS JetStream with local fallback cache."""
    __slots__ = ('_buckets', '_connected', '_js', '_local_fallback', '_nats_servers', '_nc')

    def __init__(self, nats_servers: list[str] | str | None = None, buckets: dict[str, str] | None = None, local_fallback: bool = True) -> None:
        from nexus_ai.core.config import AppConfig
        config = AppConfig()
        self._nats_servers = nats_servers or [config.nats_url]
        self._buckets = buckets or dict(DEFAULT_KV_BUCKETS)
        self._local_fallback = local_fallback
        self._nc = self._js = None
        self._kv_stores: dict[str, Any] = {}
        self._connected = False
        self._local_cache: dict[str, dict[str, Any]] = {b: {} for b in self._buckets}

    async def start(self) -> None:
        try:
            import nats as nats_module
            self._nc = await nats_module.connect(servers=self._nats_servers, name="nexus-kv-store")
            self._js = self._nc.jetstream()
            self._connected = True
            for name, desc in self._buckets.items():
                try:
                    self._kv_stores[name] = await self._js.create_key_value(bucket=name, description=desc, history=5, max_value_size=1024*1024)
                except Exception:
                    logger.debug("[KV] Create bucket '%s' failed", name)
                    pass
        except Exception as exc:
            logger.warning("[KV] NATS unavailable at %s: %s", self._nats_servers, exc)
            self._connected = False

    async def stop(self) -> None:
        if self._nc is not None:
            try: await self._nc.drain()
            except Exception:
                logger.debug("[KV] Drain failed during stop")
                pass
            self._nc = self._js = None; self._kv_stores.clear(); self._connected = False

    async def put(self, key: str, value: Any, bucket: str = "nexus-config") -> bool:
        if (kv := self._kv_stores.get(bucket)) is not None:
            try: await kv.put(key, msgspec_dumps_bytes(value)); return True
            except Exception:
                logger.debug("[KV] Put '%s' failed", key)
                pass
        if self._local_fallback:
            self._local_cache[bucket][key] = value; return True
        return False

    async def get(self, key: str, default: Any = None, bucket: str = "nexus-config") -> Any:
        if (kv := self._kv_stores.get(bucket)) is not None:
            try:
                if (entry := await kv.get(key)) is not None:
                    return _msgspec_loads(entry.value)
            except Exception:
                logger.debug("[KV] Get '%s' failed", key)
                pass
        return self._local_cache[bucket].get(key, default) if self._local_fallback else default

    async def delete(self, key: str, bucket: str = "nexus-config") -> bool:
        if (kv := self._kv_stores.get(bucket)) is not None:
            try: await kv.delete(key); return True
            except Exception:
                logger.debug("[KV] Delete '%s' failed", key)
                pass
        if self._local_fallback:
            self._local_cache[bucket].pop(key, None); return True
        return False

    async def watch(self, bucket: str = "nexus-config") -> AsyncIterator[Any]:
        if (kv := self._kv_stores.get(bucket)) is None:
            return
        watcher = await kv.watch_all()
        try:
            async for update in watcher:
                yield update
        finally:
            await watcher.stop()

    def is_connected(self) -> bool: return self._connected
    def get_status(self) -> dict[str, Any]:
        return {"connected": self._connected, "buckets": list(self._kv_stores.keys()), "local_fallback": self._local_fallback}


_default_config_store: NatsConfigStore | None = None


def get_config_store(nats_servers: list[str] | str | None = None) -> NatsConfigStore:
    global _default_config_store
    if _default_config_store is None:
        _default_config_store = NatsConfigStore(nats_servers=nats_servers)
    return _default_config_store


# ═══════════════════════════════════════════════════════════════════════════════
# Object / File Store (z nats_object_store.py)
# ═══════════════════════════════════════════════════════════════════════════════

DEFAULT_OBJECT_BUCKETS: dict[str, str] = {"nexus-files": "Invoice PDFs and attachments", "nexus-backups": "Database backups",
                                           "nexus-ocr": "OCR images and results", "nexus-reports": "Generated reports"}


class NatsFileStore:
    """Object Store on NATS JetStream for files with local cache fallback."""
    __slots__ = ('_buckets', '_cache_dir', '_connected', '_js', '_nats_servers', '_nc')

    def __init__(self, nats_servers: list[str] | str | None = None, buckets: dict[str, str] | None = None,
                 local_cache_dir: str | Path | None = None) -> None:
        from nexus_ai.core.config import AppConfig
        config = AppConfig()
        self._nats_servers = nats_servers or [config.nats_url]
        self._buckets = buckets or dict(DEFAULT_OBJECT_BUCKETS)
        self._nc = self._js = None
        self._object_stores: dict[str, Any] = {}
        self._connected = False
        self._cache_dir = Path(local_cache_dir) if local_cache_dir else config.base_dir / "app_data" / "nats_cache"
        self._cache_dir.mkdir(parents=True, exist_ok=True)

    async def start(self) -> None:
        try:
            import nats as nats_module
            self._nc = await nats_module.connect(servers=self._nats_servers, name="nexus-object-store")
            self._js = self._nc.jetstream()
            self._connected = True
            for name, desc in self._buckets.items():
                try: self._object_stores[name] = await self._js.create_object_store(bucket=name, description=desc, max_age=365*86400, storage="file")
                except Exception:
                    logger.debug("[OBJECT] Create bucket '%s' failed", name)
                    pass
        except Exception as exc:
            logger.warning("[OBJECT] NATS unavailable: %s", exc); self._connected = False

    async def stop(self) -> None:
        if self._nc is not None:
            try: await self._nc.drain()
            except Exception:
                logger.debug("[KV] Drain failed during stop")
                pass
            self._nc = self._js = None; self._object_stores.clear(); self._connected = False

    async def put(self, key: str, data: bytes, bucket: str = "nexus-files", **kw) -> dict[str, Any] | None:
        if (obj := self._object_stores.get(bucket)) is not None:
            try:
                import io; await obj.put(key, io.BytesIO(data))
                return {"name": key, "size": len(data), "bucket": bucket}
            except Exception:
                logger.debug("[OBJECT] Put '%s' failed", key)
                pass
        cache_path = self._cache_dir / bucket / key; cache_path.parent.mkdir(parents=True, exist_ok=True)
        async with await anyio.open_file(cache_path, "wb") as f: await f.write(data)
        return {"name": key, "size": len(data), "bucket": bucket, "cached": True}

    async def get(self, key: str, bucket: str = "nexus-files") -> tuple[bytes | None, dict[str, Any] | None]:
        if (obj := self._object_stores.get(bucket)) is not None:
            try:
                result = await obj.get(key)
                if result is not None:
                    data = result.data if hasattr(result, "data") else result
                    return (data if isinstance(data, bytes) else data.read()), {"name": key, "bucket": bucket}
            except Exception:
                logger.debug("[OBJECT] Get '%s' failed", key)
                pass
        cache_path = self._cache_dir / bucket / key
        if cache_path.exists():
            async with await anyio.open_file(cache_path, "rb") as f:
                return await f.read(), {"name": key, "bucket": bucket, "cached": True}
        return None, None

    async def delete(self, key: str, bucket: str = "nexus-files") -> bool:
        if (obj := self._object_stores.get(bucket)) is not None:
            try: await obj.delete(key); return True
            except Exception:
                logger.debug("[OBJECT] Delete '%s' failed", key)
                pass
        cache_path = self._cache_dir / bucket / key
        if cache_path.exists(): cache_path.unlink(); return True
        return False

    async def list(self, prefix: str = "", bucket: str = "nexus-files") -> AsyncIterator[dict[str, Any]]:
        if (obj := self._object_stores.get(bucket)) is not None:
            try:
                async for entry in obj.list():
                    name = getattr(entry, "name", "")
                    if not prefix or name.startswith(prefix):
                        yield {"name": name, "size": getattr(entry, "size", 0), "bucket": bucket}
            except Exception:
                logger.debug("[NATS:SUPERVISOR] get_streams failed")
            pass

    def is_connected(self) -> bool: return self._connected
    def get_status(self) -> dict[str, Any]:
        return {"connected": self._connected, "buckets": list(self._object_stores.keys()), "cache_dir": str(self._cache_dir)}


_default_file_store: NatsFileStore | None = None


def get_file_store(nats_servers: list[str] | str | None = None) -> NatsFileStore:
    global _default_file_store
    if _default_file_store is None:
        _default_file_store = NatsFileStore(nats_servers=nats_servers)
    return _default_file_store


# ═══════════════════════════════════════════════════════════════════════════════
# Health / Supervisor
# ═══════════════════════════════════════════════════════════════════════════════


class NatsSupervisor:
    """Monitor NATS JetStream streams and consumers."""
    __slots__ = ('_connect_timeout', '_connected', '_js', '_nats_servers', '_nc')

    def __init__(self, nats_servers: list[str] | str | None = None, connect_timeout: float = 10.0) -> None:
        from nexus_ai.core.config import AppConfig
        config = AppConfig()
        self._nats_servers = nats_servers or [config.nats_url]
        self._connect_timeout = connect_timeout
        self._nc = self._js = None
        self._connected = False

    async def start(self) -> None:
        try:
            import nats as nats_module
            self._nc = await nats_module.connect(servers=self._nats_servers, connect_timeout=self._connect_timeout, name="nexus-nats-supervisor")
            self._js = self._nc.jetstream()
            self._connected = True
        except Exception as exc:
            logger.warning("[NATS:SUPERVISOR] Failed: %s", exc)

    async def stop(self) -> None:
        if self._nc is not None:
            try: await self._nc.drain()
            except Exception:
                logger.debug("[KV] Drain failed during stop")
                pass
            self._nc = self._js = None; self._connected = False

    async def check_connection(self) -> dict[str, Any]:
        if not self._connected or self._nc is None:
            return {"status": "DISCONNECTED", "servers": self._nats_servers}
        try: await self._nc.ping(); return {"status": "CONNECTED", "server": getattr(self._nc, "connected_url", str(self._nats_servers))}
        except Exception as exc: return {"status": "ERROR", "error": str(exc)}

    async def get_streams(self, stream_names: list[str] | None = None) -> list[dict[str, Any]]:
        if not self._connected or self._js is None: return []
        results: list[dict[str, Any]] = []
        try:
            names = stream_names or [s.name for s in (await self._js.streams_info())]
            for name in names:
                try:
                    info = await self._js.stream_info(name)
                    d: dict[str, Any] = {"name": name, "status": "OK"}
                    if hasattr(info, "state"):
                        s = info.state; d["state"] = {"messages": getattr(s, "messages", 0), "bytes": getattr(s, "bytes", 0)}
                    if hasattr(info, "config"):
                        d["config"] = {"subjects": list(getattr(info.config, "subjects", [])), "storage": str(getattr(info.config, "storage", ""))}
                    results.append(d)
                except Exception as exc: results.append({"name": name, "status": "ERROR", "error": str(exc)})
        except Exception:
            logger.debug("[NATS:SUPERVISOR] get_streams failed")
            pass
        return results

    async def get_full_status(self) -> dict[str, Any]:
        import pendulum
        conn = await self.check_connection()
        streams = await self.get_streams() if conn["status"] == "CONNECTED" else []
        return {"connection": conn, "streams": streams, "stream_count": len(streams), "timestamp": pendulum.now("UTC").isoformat()}

    async def quick_health(self) -> dict[str, Any]:
        conn = await self.check_connection()
        if conn["status"] != "CONNECTED": return {"nats": conn["status"]}
        try:
            streams = await self._js.streams_info() if self._js else []; return {"nats": "OK", "streams": len(list(streams))}
        except Exception as exc: return {"nats": "ERROR", "error": str(exc)}

    def is_connected(self) -> bool: return self._connected


# ── Module init ──────────────────────────────────────────────────────────

NatsErrors.init()
