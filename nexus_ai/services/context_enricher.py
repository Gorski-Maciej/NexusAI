"""
ContextEnricher -- wzbogaca kontekst faktury o dane z zewnętrznych API.
"""

from __future__ import annotations

from typing import Any, final

from structlog import get_logger

from nexus_ai.core.cache import get_cache
from nexus_ai.services.gus_bir_client import GUSBIRClient
from nexus_ai.services.white_list_service import WhiteListService

logger = get_logger("nexus.services.context_enricher")


@final
class ContextEnricher:
    """Wzbogaca kontekst faktury o dane z GUS BIR i Białej Listy.

    Używa istniejących serwisów:
    - WhiteListService -- weryfikacja rachunków VAT
    - GUSBIRClient -- dane firm (REGON, NIP, status VAT)

    Cache: NexusCache (L1 RAM + L2 SQLite, TTL 30 dni)
    Resilience: stamina (retry + circuit breaker)
    """
    __slots__ = ('_cache', '_gus', '_white_list')


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
        """Enrich invoice context with external data.

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
            # 1. Biała Lista MF -- weryfikacja rachunku i status VAT
            if account:
                whitelist_result = await self._white_list.verify_account(nip, account)
                context["vendor_account_on_whitelist"] = whitelist_result.get("is_valid", False)
                context["vendor_vat_status"] = whitelist_result.get("vat_status", "unknown")
            else:
                context["vendor_account_on_whitelist"] = False
                context["vendor_vat_status"] = "unknown"

            # 2. GUS BIR -- dane firmy
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

            # 3. v7.0: Walidacja PKD vs przedmiot faktury (S30)
            context["pkd_invoice_match"] = _validate_pkd_match(
                context.get("vendor_pkd", ""),
                invoice_data.get("category", ""),
                invoice_data.get("ocr_full_text", ""),
            )

            # 4. Określ poziom zaufania
            trust_levels = []
            if context.get("vendor_vat_status") == "active":
                trust_levels.append("high")
            if context.get("vendor_account_on_whitelist"):
                trust_levels.append("high")
            if context.get("vendor_pkd"):
                trust_levels.append("medium")
            # v7.0: PKD mismatch obniża zaufanie
            if context.get("pkd_invoice_match") == "mismatch":
                trust_levels = [t for t in trust_levels if t != "high"]
                trust_levels.append("suspicious")

            context["vendor_trust"] = (
                "high" if "high" in trust_levels else ("medium" if trust_levels else "low")
            )

            # Zapisz w cache na 30 dni
            await self._cache.set(cache_key, context, ttl=2592000)
            logger.info(
                "[CONTEXT-ENRICHER] Enriched context for NIP=%s: trust=%s, vat_status=%s",
                nip,
                context.get("vendor_trust"),
                context.get("vendor_vat_status"),
            )

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
        except Exception as exc:
            logger.warning("[ENRICHER] Failed to close white_list: %s", exc)
        try:
            await self._gus.close()
        except Exception as exc:
            logger.warning("[ENRICHER] Failed to close GUS client: %s", exc)


# ═══════════════════════════════════════════════════════════════════════════
# v7.0: PKD Validation (S30)
# ═══════════════════════════════════════════════════════════════════════════

# Mapowanie kategorii faktur na kody PKD
PKD_CATEGORY_MAP: dict[str, set[str]] = {
    "IT_SERVICES": {"62.01", "62.02", "62.03", "62.09", "63.11", "63.12"},
    "CONSTRUCTION": {"41.10", "41.20", "42.11", "43.11", "43.21", "43.31"},
    "CATERING": {"56.10", "56.21", "56.29", "56.30"},
    "TRANSPORT": {"49.41", "49.42", "52.10", "52.29"},
    "CONSULTING": {"70.21", "70.22", "69.10", "69.20"},
    "MANUFACTURING": {"10.00", "25.00", "28.00", "29.00", "31.00"},
    "RETAIL": {"47.11", "47.19", "47.41", "47.91"},
    "ACCOUNTING": {"69.20"},
    "LEGAL": {"69.10"},
    "MARKETING": {"73.11", "73.12"},
}


def _validate_pkd_match(vendor_pkd: str, category: str, ocr_text: str) -> str:
    """Sprawdź czy PKD kontrahenta pasuje do przedmiotu faktury (S30).

    Raport v7.0: "Brak weryfikacji, czy PKD kontrahenta jest zgodne
    z przedmiotem faktury (np. firma budowlana wystawiająca fakturę za catering)"

    Returns:
        'match' — PKD zgodne z kategorią
        'mismatch' — PKD niezgodne z kategorią (potencjalne ryzyko)
        'unknown' — brak danych do porównania
    """
    if not vendor_pkd or not category:
        return "unknown"

    pkd_prefix = vendor_pkd.strip()[:5]  # pierwsze 5 znaków (XX.XX)
    expected_pkds = PKD_CATEGORY_MAP.get(category.upper())

    if expected_pkds is None:
        # Kategoria nieznana — sprawdź tekst OCR dla słów kluczowych
        return _match_pkd_from_text(vendor_pkd, ocr_text)

    # Sprawdź czy PKD pasuje do oczekiwanych dla kategorii
    for expected in expected_pkds:
        if pkd_prefix.startswith(expected[:2]):  # dopasowanie na poziomie działu
            return "match"

    # Sprawdź pełne dopasowanie
    if pkd_prefix in expected_pkds:
        return "match"

    return "mismatch"


def _match_pkd_from_text(vendor_pkd: str, ocr_text: str) -> str:
    """Dopasuj PKD na podstawie tekstu OCR gdy kategoria jest nieznana."""
    if not ocr_text:
        return "unknown"

    text_lower = ocr_text.lower()

    # Słówka kluczowe sugerujące kategorię
    keywords_map = {
        "62.": ["it", "software", "programming", "informatyczny", "programowanie"],
        "41.": ["budowa", "construction", "remont", "budowlany"],
        "56.": ["catering", "restauracja", "gastronomia", "food"],
        "49.": ["transport", "przewóz", "spedycja", "logistics"],
        "69.": ["księgow", "prawn", "accounting", "legal", "doradztwo"],
    }

    pkd_prefix = vendor_pkd.strip()[:3]
    expected_keywords = keywords_map.get(pkd_prefix, [])

    if expected_keywords and any(kw in text_lower for kw in expected_keywords):
        return "match"

    return "unknown"
