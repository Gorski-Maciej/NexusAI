"""
ContextEnricher — wzbogaca kontekst faktury o dane z zewnętrznych API.

SUPERMOCE:
- GUS BIR (SOAP API) — status VAT, REGON, PKD
- Biała Lista MF — weryfikacja rachunków bankowych
- Cache w NexusCache (TTL 30 dni)
- hishel + stamina dla odporności
- async close() dla czystego zamykania

Zgodnie z docs/tfgxzd.txt — Dynamiczny kontekst z GUS BIR i Białej Listy.
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

from nexus_ai.core.cache import get_cache
from nexus_ai.services.white_list_service import WhiteListService
from nexus_ai.services.gus_bir_client import GUSBIRClient

logger = get_logger("nexus.services.context_enricher")


class ContextEnricher:
    """Wzbogaca kontekst faktury o dane z GUS BIR i Białej Listy.

    Używa istniejących serwisów:
    - WhiteListService — weryfikacja rachunków VAT
    - GUSBIRClient — dane firm (REGON, NIP, status VAT)

    Cache: NexusCache (L1 RAM + L2 SQLite, TTL 30 dni)
    Resilience: stamina (retry + circuit breaker)
    """

    def __init__(
        self,
        white_list_service: WhiteListService | None = None,
        gus_client: GUSBIRClient | None = None,
    ) -> None:
        self._white_list = white_list_service or WhiteListService()
        self._gus = gus_client or GUSBIRClient()
        self._cache = get_cache()

    async def enrich(
        self,
        invoice_data: dict[str, Any],
    ) -> dict[str, Any]:
        """SUPERMOC: Wzbogać kontekst faktury o dane z API.

        1. Sprawdź NIP na Białej Liście MF (rachunek bankowy, status VAT)
        2. Pobierz dane firmy z GUS BIR (REGON, PKD, status)
        3. Zapisz w cache (TTL 30 dni)
        4. Zwróć wzbogacony kontekst

        Args:
            invoice_data: Dane faktury z OCR (wymagane: vendor_nip, vendor_account)

        Returns:
            Wzbogacony kontekst z polami:
            - vendor_vat_status: active/inactive/unknown
            - vendor_pkd: kod PKD (z GUS)
            - vendor_account_on_whitelist: bool
            - vendor_trust: high/medium/low
        """
        context: dict[str, Any] = {}
        nip = invoice_data.get("vendor_nip", "") or invoice_data.get("contractor_nip", "")
        account = invoice_data.get("vendor_account", "")

        if not nip:
            logger.warning("[CONTEXT-ENRICHER] No NIP in invoice data")
            return {"vendor_trust": "low", "vendor_vat_status": "unknown"}

        # Cache key dla NIP
        cache_key = f"enriched_context:{nip}"

        # Sprawdź cache
        cached = await self._cache.get(cache_key)
        if cached is not None:
            logger.debug("[CONTEXT-ENRICHER] Cache hit for NIP=%s", nip)
            return cached

        try:
            # 1. Biała Lista MF — weryfikacja rachunku i status VAT
            if account:
                whitelist_result = await self._white_list.verify_account(nip, account)
                context["vendor_account_on_whitelist"] = whitelist_result.get("is_valid", False)
                context["vendor_vat_status"] = whitelist_result.get("vat_status", "unknown")
            else:
                context["vendor_account_on_whitelist"] = False
                context["vendor_vat_status"] = "unknown"

            # 2. GUS BIR — dane firmy
            try:
                gus_data = await self._gus.get_company_data(nip)
                context["vendor_pkd"] = gus_data.get("pkd", "")
                context["vendor_regon"] = gus_data.get("regon", "")
                context["vendor_name"] = gus_data.get("name", "")
                if gus_data.get("vat_status"):
                    context["vendor_vat_status"] = gus_data["vat_status"]
            except Exception as exc:
                logger.warning("[CONTEXT-ENRICHER] GUS BIR failed for NIP=%s: %s", nip, exc)
                context["vendor_pkd"] = ""

            # 3. Określ poziom zaufania
            trust_levels = []
            if context.get("vendor_vat_status") == "active":
                trust_levels.append("high")
            if context.get("vendor_account_on_whitelist"):
                trust_levels.append("high")
            if context.get("vendor_pkd"):
                trust_levels.append("medium")

            context["vendor_trust"] = "high" if "high" in trust_levels else (
                "medium" if trust_levels else "low"
            )

            # Zapisz w cache na 30 dni
            await self._cache.set(cache_key, context, ttl=2592000)
            logger.info("[CONTEXT-ENRICHER] Enriched context for NIP=%s: trust=%s, vat_status=%s",
                        nip, context.get("vendor_trust"), context.get("vendor_vat_status"))

        except Exception as exc:
            logger.error("[CONTEXT-ENRICHER] Failed to enrich NIP=%s: %s", nip, exc)
            context = {
                "vendor_trust": "low",
                "vendor_vat_status": "unknown",
                "vendor_account_on_whitelist": False,
                "vendor_pkd": "",
            }

        return context

    async def close(self) -> None:
        """Zamknij połączenia HTTP."""
        try:
            await self._white_list.close()
        except Exception:
            pass
        try:
            await self._gus.close()
        except Exception:
            pass
