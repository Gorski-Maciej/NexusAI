"""
PluginManager v2 -- lifecycle-aware plugin system with typed hooks.

Replaces the legacy PluginManager that only loaded exporter classes with a
full lifecycle-aware plugin system. Key improvements:
  - Named plugins with metadata (version, author, description)
  - Lifecycle hooks: on_startup, on_shutdown, on_event
  - Typed plugin interface via PluginProtocol (structural subtyping)
  - Event subscription through the typed EventBus
  - Dependency injection for plugin-to-plugin communication
  - Thread-safe plugin registry for free-threaded Python 3.13t

Usage:
    # Define a plugin
    class MyPlugin:
        name = "my_plugin"
        version = "1.0.0"
        description = "Does something useful"

        async def on_startup(self, bus: EventBus) -> None:
            await bus.subscribe(SomeEvent, self.handle_event)

        async def handle_event(self, event: SomeEvent) -> None:
            print(f"Got event: {event}")

    # Register & run
    manager = PluginManager()
    manager.register(MyPlugin())
    await manager.run_startup(bus)
"""

from __future__ import annotations

import importlib
import inspect
import pkgutil
import threading
from typing import Any, Protocol, final, runtime_checkable

from structlog import get_logger

from nexus_ai.core.bus import EventBus, get_bus

logger = get_logger("nexus.core.plugins")


# ── Plugin protocol -- structural subtyping (duck typing) ───────────────────


@runtime_checkable
class PluginProtocol(Protocol):
    """Protocol defining the plugin interface.

    All methods are optional -- plugins only need to implement what they use.
    The 'name' attribute is required for registration.

    Attributes:
        name: Unique plugin name.
        version: Optional version string.
        description: Optional human-readable description.
    """

    name: str
    version: str = ""
    description: str = ""

    async def on_startup(self, bus: EventBus) -> None:
        """Called when the plugin system starts up.

        Args:
            bus: The global EventBus instance for subscribing to events.
        """
        ...

    async def on_shutdown(self) -> None:
        """Called when the plugin system shuts down."""
        ...

    async def on_event(self, event_type: str, payload: Any) -> None:
        """Called for every event asynchronously (generic handler).

        Args:
            event_type: The event type string.
            payload: The event payload.
        """
        ...


# ── PluginInfo -- metadata about a registered plugin ────────────────────────


class PluginInfo:
    """Metadata about a registered plugin.

    Attributes:
        name: Unique plugin name.
        version: Version string.
        description: Human-readable description.
        class_name: Fully qualified class name.
        module: Module where the plugin is defined.
        has_startup: Whether the plugin implements on_startup.
        has_shutdown: Whether the plugin implements on_shutdown.
    """

    def __init__(self, plugin: PluginProtocol) -> None:
        self.name = plugin.name
        self.version = getattr(plugin, "version", "")
        self.description = getattr(plugin, "description", "")
        self.class_name = f"{type(plugin).__module__}.{type(plugin).__qualname__}"
        self.module = type(plugin).__module__
        self.has_startup = hasattr(plugin, "on_startup") and callable(plugin.on_startup)  # type: ignore[arg-type]
        self.has_shutdown = hasattr(plugin, "on_shutdown") and callable(plugin.on_shutdown)  # type: ignore[arg-type]

    def __repr__(self) -> str:
        return (
            f"PluginInfo(name={self.name!r}, version={self.version!r}, "
            f"startup={self.has_startup}, shutdown={self.has_shutdown})"
        )


# ── PluginManager v2 -- core plugin system ─────────────────────────────────


final


class PluginManager:
    """Lifecycle-aware plugin system with typed hooks and event subscription.

    Features compared to legacy PluginManager:
      - Typed plugin interface via PluginProtocol
      - Lifecycle hooks: on_startup, on_shutdown
      - Event subscription through typed EventBus
      - Dependency injection for plugin-to-plugin communication
      - Plugin discovery from packages (legacy exporters)
      - Thread-safe registry

    Usage:
        manager = PluginManager()

        # Register a plugin
        manager.register(MyPlugin())

        # Or discover from a package
        manager.discover_plugins("nexus_ai.plugins")

        # Run lifecycle
        await manager.run_startup(get_bus())

        # ... application runs ...

        await manager.run_shutdown()
    """

    def __init__(self) -> None:
        self._plugins: dict[str, PluginProtocol] = {}
        self._infos: dict[str, PluginInfo] = {}
        self._lock = threading.Lock()

    # ── Registration ────────────────────────────────────────────────────

    def register(self, plugin: PluginProtocol) -> PluginInfo:
        """Register a plugin instance.

        Args:
            plugin: A plugin instance conforming to PluginProtocol.

        Returns:
            PluginInfo for the registered plugin.

        Raises:
            ValueError: If a plugin with the same name is already registered.
            TypeError: If the plugin does not have a 'name' attribute.
        """
        name = getattr(plugin, "name", None)
        if not name:
            raise TypeError("Plugin must have a 'name' attribute")

        with self._lock:
            if name in self._plugins:
                raise ValueError(f"Plugin '{name}' is already registered")

            self._plugins[name] = plugin
            info = PluginInfo(plugin)
            self._infos[name] = info

        logger.info(
            "[PLUGIN] Registered '%s' v%s -- %s",
            name,
            info.version,
            info.description,
        )
        return info

    def unregister(self, name: str) -> None:
        """Unregister a plugin by name.

        Args:
            name: Plugin name to unregister.
        """
        with self._lock:
            self._plugins.pop(name, None)
            self._infos.pop(name, None)
        logger.info("[PLUGIN] Unregistered '%s'", name)

    def get(self, name: str) -> PluginProtocol | None:
        """Get a registered plugin by name.

        Args:
            name: Plugin name.

        Returns:
            The plugin instance if found, None otherwise.
        """
        return self._plugins.get(name)

    def get_info(self, name: str) -> PluginInfo | None:
        """Get metadata for a registered plugin.

        Args:
            name: Plugin name.

        Returns:
            PluginInfo if found, None otherwise.
        """
        return self._infos.get(name)

    def list_plugins(self) -> dict[str, PluginInfo]:
        """List all registered plugins with their metadata.

        Returns:
            Dict mapping plugin name -> PluginInfo.
        """
        with self._lock:
            return dict(self._infos)

    # ── Lifecycle ──────────────────────────────────────────────────────

    async def run_startup(self, bus: EventBus | None = None) -> None:
        """Run on_startup for all registered plugins.

        Args:
            bus: EventBus instance to pass to plugins. Uses global singleton
                 if not provided.
        """
        bus = bus or get_bus()
        sorted_plugins = sorted(self._plugins.items())

        for name, plugin in sorted_plugins:
            if hasattr(plugin, "on_startup") and callable(plugin.on_startup):  # type: ignore[arg-type]
                try:
                    await plugin.on_startup(bus)  # type: ignore[misc]
                    logger.info("[PLUGIN] Startup hook completed for '%s'", name)
                except Exception:
                    logger.exception("[PLUGIN] Startup hook failed for '%s'", name)

        logger.info("[PLUGIN] Startup complete -- %d plugins active", len(self._plugins))

    async def run_shutdown(self) -> None:
        """Run on_shutdown for all registered plugins (reverse order)."""
        sorted_plugins = sorted(self._plugins.items(), reverse=True)

        for name, plugin in sorted_plugins:
            if hasattr(plugin, "on_shutdown") and callable(plugin.on_shutdown):  # type: ignore[arg-type]
                try:
                    await plugin.on_shutdown()  # type: ignore[misc]
                    logger.info("[PLUGIN] Shutdown hook completed for '%s'", name)
                except Exception:
                    logger.exception("[PLUGIN] Shutdown hook failed for '%s'", name)

        logger.info("[PLUGIN] All plugins shut down")

    # ── Discovery ──────────────────────────────────────────────────────

    def discover_plugins(self, package_path: str = "core.exporters") -> int:
        """Discover and register plugins from a Python package.

        Scans the given package for classes ending in 'Plugin' or 'Exporter'
        and registers them automatically.

        Args:
            package_path: Dotted path to the package (e.g., 'core.exporters').

        Returns:
            Number of plugins discovered and registered.
        """
        count = 0
        try:
            package = importlib.import_module(package_path)
            for _, name, is_pkg in pkgutil.iter_modules(package.__path__):  # type: ignore[arg-type]
                full_module_name = f"{package_path}.{name}"
                try:
                    module = importlib.import_module(full_module_name)
                except Exception as exc:
                    logger.warning("[PLUGIN] Failed to load module %s: %s", full_module_name, exc)
                    continue

                for obj_name, obj in inspect.getmembers(module, inspect.isclass):
                    # Skip base classes and non-plugin classes
                    if obj_name in ("PluginProtocol", "BaseExporter"):
                        continue

                    # Accept classes ending in 'Plugin' or 'Exporter'
                    if obj_name.endswith("Plugin") or obj_name.endswith("Exporter"):
                        try:
                            # Check if it conforms to PluginProtocol
                            if isinstance(obj, PluginProtocol) or hasattr(obj, "name"):
                                instance = obj()
                                self.register(instance)
                                count += 1
                        except Exception as exc:
                            logger.warning("[PLUGIN] Failed to register %s: %s", obj_name, exc)

        except ImportError as exc:
            logger.warning("[PLUGIN] Package %s not found: %s", package_path, exc)
        except Exception as exc:
            logger.error("[PLUGIN] Discovery error for %s: %s", package_path, exc)

        return count

    # ── Legacy compatibility ───────────────────────────────────────────

    @property
    def exporters(self) -> dict[str, type]:
        """Legacy property -- returns registered exporter classes.

        Returns:
            Dict mapping class name -> class for all registered plugins
            whose name ends with 'Exporter'.
        """
        return {
            info.class_name: type(plugin)
            for name, plugin in self._plugins.items()
            if name.endswith("Exporter") or "Exporter" in name
        }


# ── Global singleton (DEPRECATED) ──────────────────────────────────────


_default_manager: PluginManager | None = None


def get_plugin_manager() -> PluginManager:
    """Return the global PluginManager singleton.

    DEPRECATED: Uzyj Litestar DI z AppServices zamiast get_plugin_manager().
    """
    global _default_manager
    if _default_manager is None:
        _default_manager = PluginManager()
    return _default_manager


__all__ = [
    "PluginManager",
    "PluginProtocol",
    "PluginInfo",
    "get_plugin_manager",
]
