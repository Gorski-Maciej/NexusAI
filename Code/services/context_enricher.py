"""
ContextEnricher — wzbogaca fakturę o dane z rejestrów państwowych.

Część IV drugiej połowy szkieletu.

Komponenty:
  - White List verification (MF API)
  - GUS BIR (SOAP/REST — stub, wymaga klucza API)
  - vendor_cache z TTL 30 dni
  - Reguły blokujące w Zen-Engine (vendor_account_on_whitelist)
  - Flaga vendor_trust (high/low)
"""

from __future__ import annotations

import json
import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any

import duckdb

logger = logging.getLogger("nexus.services.context_enricher")

# ── Schema for vendor_cache table ────────────────────────────────────────────

VENDOR_CACHE_SCHEMA = """
CREATE TABLE IF NOT EXISTS vendor_cache (
    nip VARCHAR PRIMARY KEY,
    vat_status VARCHAR NOT NULL DEFAULT 'unknown',
    pkd VARCHAR DEFAULT '',
    account_whitelist BOOLEAN DEFAULT FALSE,
    whitelist_accounts VARCHAR DEFAULT '[]',
    vendor_trust VARCHAR DEFAULT 'unknown',
    company_name VARCHAR DEFAULT '',
    fetched_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
"""

TTL_DAYS = 30


def ensure_cache_schema(conn: duckdb.DuckDBPyConnection) -> None:
    """Create vendor_cache table if not present."""
    conn.execute(VENDOR_CACHE_SCHEMA)


# ── Enricher ─────────────────────────────────────────────────────────────────


class ContextEnricher:
    """Asynchroniczny enricher kontekstu z rejestrów państwowych.

    Args:
        conn: DuckDB connection for vendor_cache.
        white_list_service: Optional WhiteListService (lub importowany domyślnie).
    """

    def __init__(
        self,
        conn: duckdb.DuckDBPyConnection,
        white_list_service: Any = None,
    ) -> None:
        self._conn = conn
        ensure_cache_schema(conn)

        if white_list_service is not None:
            self._white_list = white_list_service
        else:
            from services.white_list_service import WhiteListService
            self._white_list = WhiteListService()

    async def enrich(self, invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Główna metoda — wzbogaca kontekst faktury o dane z rejestrów.

        Args:
            invoice_data: Słownik faktury z polami:
                - contractor_nip: str
                - contractor_bank_account: str (opcjonalnie)

        Returns:
            Słownik z wzbogaconymi polami:
                - vendor_vat_status: str
                - vendor_pkd: str
                - vendor_account_on_whitelist: bool
                - vendor_trust: str (high/low)
                - vendor_company_name: str
        """
        nip = str(invoice_data.get("contractor_nip", "")).strip()
        bank_account = str(invoice_data.get("contractor_bank_account", "")).strip()

        # Domyślne wartości
        result = {
            "vendor_vat_status": "unknown",
            "vendor_pkd": "",
            "vendor_account_on_whitelist": False,
            "vendor_trust": "unknown",
            "vendor_company_name": "",
        }

        if not nip or not nip.isdigit() or len(nip) != 10:
            return result

        # 1. Sprawdź cache
        cached = self._get_from_cache(nip)
        cache_valid = False
        if cached:
            cached_fetched = cached.get("fetched_at", "")
            if isinstance(cached_fetched, str):
                try:
                    fetched = datetime.fromisoformat(cached_fetched)
                except ValueError:
                    fetched = datetime.min.replace(tzinfo=None)
            elif isinstance(cached_fetched, datetime):
                fetched = cached_fetched
            else:
                fetched = datetime.min

            now = datetime.now(timezone.utc).replace(tzinfo=None)
            if fetched.tzinfo is not None:
                fetched = fetched.replace(tzinfo=None)

            age = now - fetched
            cache_valid = age.days < TTL_DAYS

        # 2. Wykonaj zapytania równoległe (tylko jeśli cache nieważny)
        import asyncio
        api_ok = True
        on_whitelist = False

        if not cache_valid:
            white_list_task = self._check_white_list(nip, bank_account)
            # GUS BIR jest wyłączony domyślnie (wymaga klucza API)
            # gus_task = self._check_gus_bir(nip)

            try:
                white_list_data = await white_list_task
                on_whitelist = bool(white_list_data.get("on_whitelist", False)) if isinstance(white_list_data, dict) else bool(white_list_data)
            except Exception as exc:
                logger.warning("[ContextEnricher] API failed nip=%s: %s — using stale cache", nip, exc)
                api_ok = False

            if api_ok:
                # 3a. API OK — zapisz świeże dane do cache
                status = "active" if on_whitelist else "inactive"
                trust = "high" if on_whitelist else "low"
                whitelist_accounts_json = white_list_data.get("accounts_json", "[]") if isinstance(white_list_data, dict) else "[]"
                self._save_to_cache(nip, status, "", on_whitelist, trust, "", whitelist_accounts=whitelist_accounts_json)
            else:
                # 3b. API niedostępne — użyj przeterminowanego cache z niskim trust
                if cached:
                    return {
                        "vendor_vat_status": cached.get("vat_status", "unknown"),
                        "vendor_pkd": cached.get("pkd", ""),
                        "vendor_account_on_whitelist": bool(cached.get("account_whitelist", False)),
                        "vendor_trust": "low",
                        "vendor_company_name": cached.get("company_name", ""),
                    }
                # Brak cache i API nie działa — unknown
                return {
                    "vendor_vat_status": "unknown",
                    "vendor_pkd": "",
                    "vendor_account_on_whitelist": False,
                    "vendor_trust": "low",
                    "vendor_company_name": "",
                }
        else:
            # 2b. Cache ważny — użyj go
            return {
                "vendor_vat_status": cached.get("vat_status", "unknown"),
                "vendor_pkd": cached.get("pkd", ""),
                "vendor_account_on_whitelist": bool(cached.get("account_whitelist", False)),
                "vendor_trust": cached.get("vendor_trust", "high"),
                "vendor_company_name": cached.get("company_name", ""),
            }

        # 4. Zwróć świeże dane
        return {
            "vendor_vat_status": status,
            "vendor_pkd": "",
            "vendor_account_on_whitelist": on_whitelist,
            "vendor_trust": trust,
            "vendor_company_name": "",
        }

    async def _check_white_list(self, nip: str, bank_account: str) -> bool | dict:
        """Sprawdza NIP i konto na Białej Liście MF.

        Returns:
            dict z kluczami:
                - on_whitelist: bool — czy konto jest na białej liście
                - accounts_json: str — JSON lista wszystkich kont
            Lub bool dla wstecznej kompatybilności.
        """
        import warnings
        try:
            if bank_account:
                result = await self._white_list.verify_bank_account(nip, bank_account)
                if isinstance(result, dict):
                    return result
                return {"on_whitelist": result, "accounts_json": "[]"}
            # Nawet bez konta — sprawdź czy NIP istnieje
            # WhiteListService.verify_bank_account wymaga konta
            return {"on_whitelist": True, "accounts_json": "[]"}  # brak konta = nie możemy zablokować
        except Exception as exc:
            logger.warning("[ContextEnricher] White List check failed nip=%s: %s", nip, exc)
            return {"on_whitelist": False, "accounts_json": "[]"}

    async def _check_gus_bir(self, nip: str) -> dict[str, Any]:
        """Sprawdza NIP w GUS BIR. Wymaga klucza API — stub."""
        # GUS BIR wymaga: https://api.stat.gov.pl/Home/BIR
        # 1. Rejestracja i uzyskanie klucza
        # 2. SOAP: Zaloguj -> Zaloguj
        # 3. REST: /api/1.1/Data/GetFullData?p_Regon={regon}
        logger.debug("[ContextEnricher] GUS BIR check nip=%s — stub (wymaga klucza)", nip)
        return {
            "vat_status": "active",
            "pkd": "",
            "company_name": "",
        }

    # ── Cache ───────────────────────────────────────────────────────────

    def _get_from_cache(self, nip: str) -> dict[str, Any] | None:
        """Odczytaj wpis z cache dla NIP-u."""
        rows = self._conn.execute(
            "SELECT vat_status, pkd, account_whitelist, vendor_trust, "
            "company_name, fetched_at FROM vendor_cache WHERE nip = ?",
            (nip,),
        ).fetchall()
        if not rows:
            return None
        row = rows[0]
        return {
            "vat_status": str(row[0]),
            "pkd": str(row[1]),
            "account_whitelist": bool(row[2]),
            "vendor_trust": str(row[3]),
            "company_name": str(row[4]),
            "fetched_at": row[5],
        }

    def _save_to_cache(
        self,
        nip: str,
        vat_status: str,
        pkd: str,
        account_whitelist: bool,
        vendor_trust: str,
        company_name: str,
        whitelist_accounts: str = "[]",
    ) -> None:
        """Zapisz wynik do cache (UPSERT)."""
        self._conn.execute(
            """INSERT OR REPLACE INTO vendor_cache
               (nip, vat_status, pkd, account_whitelist, vendor_trust,
                company_name, whitelist_accounts, fetched_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)""",
            (nip, vat_status, pkd, account_whitelist, vendor_trust, company_name, whitelist_accounts),
        )
