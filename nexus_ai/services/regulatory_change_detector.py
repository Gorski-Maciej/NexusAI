"""
v7.0 INNOWACJA 11: Regulatory Change Detector — Detektor Zmian Przepisów.

Monitoruje zmiany w API zewnętrznych:
- Nowe wersje XSD KSeF (FA_VAT v2, v3)
- Nowe endpointy GUS BIR
- Nowe wymagania Białej Listy MF
- Zmiany w API NBP

Automatycznie:
- Pobiera nowe XSD i porównuje ze starym
- Generuje diff struktury
- Oznacza endpointy wymagające aktualizacji
- Szacuje czas potrzebny na dostosowanie

To zapewnia ZGODNOŚĆ regulacyjną bez ręcznego śledzenia zmian.
"""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.services.regulatory")


# ── Data Models ──────────────────────────────────────────────────────────────

@dataclass
class RegulatoryChange:
    """Wykryta zmiana regulacyjna."""
    id: str
    integration: str  # ksef, gus_bir, white_list, nbp
    change_type: str  # xsd_schema, new_endpoint, endpoint_deprecated, field_added, field_removed
    description: str
    severity: str  # critical, high, medium, low
    detected_at: str
    source_url: str
    old_signature: str = ""
    new_signature: str = ""
    estimated_effort_hours: float = 0.0
    affected_endpoints: list[str] = field(default_factory=list)
    action_required: str = ""  # update_schema, update_code, monitor_only


@dataclass
class SchemaDiff:
    """Różnica między dwiema wersjami XSD."""
    added_elements: list[str]
    removed_elements: list[str]
    changed_elements: list[dict[str, str]]  # {name: old_type → new_type}
    added_attributes: list[str]
    removed_attributes: list[str]


# ── Regulatory Monitor ───────────────────────────────────────────────────────

class RegulatoryChangeDetector:
    """v7.0 INNOWACJA 11: Detektor zmian w API zewnętrznych.

    Monitoruje:
    - XSD KSeF (FA_VAT)
    - API GUS BIR (WSDL)
    - API Białej Listy MF
    - API NBP
    """

    # Konfiguracja monitorowanych zasobów
    MONITORED_RESOURCES: dict[str, list[dict[str, str]]] = {
        "ksef": [
            {
                "name": "FA_VAT XSD",
                "url": "https://ksef-test.mf.gov.pl/api/schemas/FA_VAT.xsd",
                "check_interval_days": 7,
                "content_type": "xsd",
            },
        ],
        "gus_bir": [
            {
                "name": "GUS BIR WSDL",
                "url": "https://wyszukiwarkaregon.stat.gov.pl/wsBIR/UslugaBIRzewnPubl.svc?wsdl",
                "check_interval_days": 14,
                "content_type": "wsdl",
            },
        ],
        "nbp": [
            {
                "name": "NBP API Docs",
                "url": "https://api.nbp.pl/swagger.json",
                "check_interval_days": 30,
                "content_type": "openapi",
            },
        ],
    }

    def __init__(self, http_client: Any = None) -> None:
        self._http = http_client
        self._snapshots: dict[str, str] = {}  # v7.0 FIX: resource_id → hash (tylko string)
        # v7.0 FIX: Osobny słownik na sety elementów XSD
        self._element_snapshots: dict[str, set[str]] = {}
        self._changes: list[RegulatoryChange] = []
        self._last_check: dict[str, float] = {}

    async def check_all(self) -> list[RegulatoryChange]:
        """Sprawdź wszystkie monitorowane zasoby."""
        import time
        changes: list[RegulatoryChange] = []

        for integration, resources in self.MONITORED_RESOURCES.items():
            for resource in resources:
                resource_id = f"{integration}:{resource['name']}"
                last = self._last_check.get(resource_id, 0)
                interval = resource["check_interval_days"] * 86400

                if time.time() - last < interval:
                    continue  # Za wcześnie na sprawdzenie

                try:
                    change = await self._check_resource(integration, resource)
                    if change:
                        changes.append(change)
                    self._last_check[resource_id] = time.time()
                except Exception as exc:
                    logger.warning(
                        "[REGULATORY] Check failed for %s: %s",
                        resource_id, exc,
                    )

        if changes:
            self._changes.extend(changes)
            logger.info("[REGULATORY] Detected %d changes", len(changes))

        return changes

    async def _check_resource(
        self, integration: str, resource: dict[str, str],
    ) -> RegulatoryChange | None:
        """Sprawdź pojedynczy zasób pod kątem zmian."""
        resource_id = f"{integration}:{resource['name']}"

        try:
            if self._http:
                response = await self._http.get(resource["url"])
                content = response.text
            else:
                # Fallback: użyj httpx
                import httpx
                async with httpx.AsyncClient(timeout=30.0) as client:
                    response = await client.get(resource["url"])
                    content = response.text
        except Exception as exc:
            logger.warning("[REGULATORY] Cannot fetch %s: %s", resource["url"], exc)
            return None

        if not content:
            return None

        new_hash = hashlib.sha256(content.encode()).hexdigest()
        old_hash = self._snapshots.get(resource_id, "")

        if old_hash and old_hash != new_hash:
            # Wykryto zmianę!
            logger.info("[REGULATORY] Change detected: %s", resource_id)

            diff = None
            if resource["content_type"] == "xsd":
                diff = self._diff_xsd(content, resource_id)

            severity = self._assess_severity(integration, resource["name"], diff)
            effort = self._estimate_effort(integration, diff)

            return RegulatoryChange(
                id=hashlib.sha256(f"{resource_id}:{new_hash}".encode()).hexdigest()[:16],
                integration=integration,
                change_type=self._classify_change(diff),
                description=f"Zmiana w {resource['name']} ({integration})",
                severity=severity,
                detected_at=pendulum.now("UTC").isoformat(),
                source_url=resource["url"],
                old_signature=old_hash[:16],
                new_signature=new_hash[:16],
                estimated_effort_hours=effort,
                affected_endpoints=self._get_affected_endpoints(integration, resource),
                action_required=self._determine_action(severity),
            )

        # Zapisz nową migawkę
        self._snapshots[resource_id] = new_hash
        return None

    def _diff_xsd(self, content: str, resource_id: str) -> SchemaDiff | None:
        """Porównaj nową wersję XSD ze starą."""
        try:
            import xml.etree.ElementTree as ET

            root = ET.fromstring(content)
            ns = {"xs": "http://www.w3.org/2001/XMLSchema"}

            # Wyciągnij wszystkie elementy
            elements = set()
            for elem in root.findall(".//xs:element", ns):
                name = elem.get("name", "")
                if name:
                    elements.add(name)

            # Wyciągnij atrybuty
            attributes = set()
            for attr in root.findall(".//xs:attribute", ns):
                name = attr.get("name", "")
                if name:
                    attributes.add(name)

            # v7.0 FIX: Porównaj z element_snapshots zamiast _snapshots
            prev_elements = self._element_snapshots.get(f"{resource_id}:elements", set())
            prev_attributes = self._element_snapshots.get(f"{resource_id}:attributes", set())

            added = list(elements - prev_elements)
            removed = list(prev_elements - elements)
            added_attrs = list(attributes - prev_attributes)
            removed_attrs = list(prev_attributes - attributes)

            # Zapisz nowe elementy
            self._element_snapshots[f"{resource_id}:elements"] = elements
            self._element_snapshots[f"{resource_id}:attributes"] = attributes

            return SchemaDiff(
                added_elements=added,
                removed_elements=removed,
                changed_elements=[],  # Pełna detekcja zmian typów wymaga głębszej analizy
                added_attributes=added_attrs,
                removed_attributes=removed_attrs,
            )
        except Exception as exc:
            logger.warning("[REGULATORY] XSD diff failed: %s", exc)
            return None

    @staticmethod
    def _assess_severity(
        integration: str, resource_name: str, diff: SchemaDiff | None,
    ) -> str:
        """Oceń wagę zmiany."""
        if diff is None:
            return "medium"

        # Krytyczne: nowe wymagane pola w KSeF
        if integration == "ksef" and diff.added_elements:
            return "critical"

        # Wysokie: zmiany w GUS BIR WSDL
        if integration == "gus_bir" and (diff.removed_elements or diff.added_elements):
            return "high"

        # Średnie: zmiany w NBP
        if integration == "nbp" and diff.added_elements:
            return "medium"

        return "low"

    @staticmethod
    def _estimate_effort(integration: str, diff: SchemaDiff | None) -> float:
        """Szacuj nakład pracy potrzebny do dostosowania."""
        if diff is None:
            return 0.5  # Pół godziny na sprawdzenie

        # Szacuj: 1h na każdy dodany element, 0.5h na usunięty
        hours = len(diff.added_elements) * 1.0 + len(diff.removed_elements) * 0.5
        hours += len(diff.added_attributes) * 0.25

        # KSeF jest bardziej skomplikowany
        if integration == "ksef":
            hours *= 2.0

        return max(0.5, round(hours, 1))

    @staticmethod
    def _classify_change(diff: SchemaDiff | None) -> str:
        """Klasyfikuj typ zmiany."""
        if diff is None:
            return "content_changed"
        if diff.added_elements:
            return "field_added"
        if diff.removed_elements:
            return "field_removed"
        return "schema_modified"

    @staticmethod
    def _get_affected_endpoints(
        integration: str, resource: dict[str, str],
    ) -> list[str]:
        """Zwróć listę endpointów, których dotyczy zmiana."""
        if integration == "ksef":
            return ["/api/v1/ksef/send", "/api/v1/ksef/inbox"]
        if integration == "gus_bir":
            return ["/api/v1/gus/enrich"]
        if integration == "nbp":
            return ["/api/v1/fx/rate", "/api/v1/fx/convert"]
        return [resource["name"]]

    @staticmethod
    def _determine_action(severity: str) -> str:
        """Określ wymagane działanie."""
        if severity == "critical":
            return "update_schema"
        if severity == "high":
            return "update_code"
        return "monitor_only"

    def get_changes(self, limit: int = 50) -> list[RegulatoryChange]:
        """Pobierz listę wykrytych zmian."""
        return self._changes[-limit:]

    def get_pending_actions(self) -> list[RegulatoryChange]:
        """Pobierz zmiany wymagające działania."""
        return [c for c in self._changes if c.action_required != "monitor_only"]
