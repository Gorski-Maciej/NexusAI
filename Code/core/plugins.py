# core/plugins.py
import importlib
import inspect
import pkgutil

from core.logger import logger


class PluginManager:
    """Dynamicznie ładuje klasy eksporterów z katalogu core/exporters/."""

    def __init__(self, package_path: str = "core.exporters"):
        self.package_path = package_path
        self.exporters: dict[str, type] = {}

    def discover_exporters(self):
        """Skanuje folder i rejestruje wszystkie klasy eksporterów."""
        try:
            package = importlib.import_module(self.package_path)
            for _, name, is_pkg in pkgutil.iter_modules(package.__path__):
                full_module_name = f"{self.package_path}.{name}"
                module = importlib.import_module(full_module_name)

                for _, obj in inspect.getmembers(module):
                    # Szukamy klas kończących się na 'Exporter'
                    if inspect.isclass(obj) and obj.__name__.endswith("Exporter") and obj.__name__ != "BaseExporter":
                        self.exporters[obj.__name__] = obj
                        logger.info(f"Zarejestrowano eksporter: {obj.__name__}")
        except Exception as e:
            logger.error(f"Błąd ładowania pluginów: {e}")
