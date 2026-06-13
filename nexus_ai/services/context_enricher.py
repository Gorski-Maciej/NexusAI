"""
ContextEnricher — wzbogaca fakturę o dane z rejestrów państwowych.

Zintegrowany z DecisionEngine (DuckDB/SQL) i ProtocolExecutor.

Komponenty:
  - White List verification (MF API) przez WhiteListService + CachedHttpClient
  - GUS BIR (SOAP — wymaga GUS_BIR_API_KEY)
  - vendor_cache w DuckDB z konfigurowalnym TTL (dom. 30 dni) z protocols.toml
  - Flaga vendor_trust (high/low) ustalana na podstawie Białej Listy
  - Hot-reload konfiguracji przez ProtocolExecutor.subscribe_on_change()
"""

from __future__ import annotations

from typing import Any, final

import anyio
import duckdb
import pendulum
from structlog import get_logger

from nexus_ai.core.protocol_executor import ProtocolExecutor, get_protocol_executor

logger = get_logger("nexus.services.context_enricher")

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
    city VARCHAR DEFAULT '',
    street VARCHAR DEFAULT '',
    legal_form VARCHAR DEFAULT '',
    gus_verified BOOLEAN DEFAULT FALSE,
    fetched_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
"""

TTL_DAYS = 30


def ensure_cache_schema(conn: duckdb.DuckDBPyConnection) -> None:
    """Create vendor_cache table if not present."""
    conn.execute(VENDOR_CACHE_SCHEMA)


# ── Enricher ─────────────────────────────────────────────────────────────────


@final
class ContextEnricher:
    """Asynchroniczny enricher kontekstu z rejestrów państwowych.

    Args:
        conn: DuckDB connection for vendor_cache.
        white_list_service: Optional WhiteListService (lub importowany domyślnie).
        gus_bir_client: Optional GusBirClient (lub tworzony domyślnie).
    """

    def __init__(
        self,
        conn: duckdb.DuckDBPyConnection,
        white_list_service: Any = None,
        gus_bir_client: Any = None,
        protocol_executor: ProtocolExecutor | None = None,
    ) -> None:
        self._conn = conn
        ensure_cache_schema(conn)

        if white_list_service is not None:
            self._white_list = white_list_service
        else:
            from services.white_list_service import WhiteListService

            self._white_list = WhiteListService()

        self._gus_bir = gus_bir_client
        self._protocol_executor = protocol_executor or get_protocol_executor()

        # Subskrybuj hot-reload protokołów
        self._protocol_executor.subscribe_on_change(self._on_protocols_changed)

    async def close(self) -> None:
        """Zamknij zasoby — WhiteListService (CachedHttpClient) i DuckDB connection.

        Zgodnie z clean-up lifecycle:
        1. await self._white_list.close() → CachedHttpClient → httpx.AsyncClient.aclose()
        2. self._conn.close() → DuckDBPyConnection.close()
        """
        await self._white_list.close()
        self._conn.close()

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
                - vendor_city: str
                - vendor_street: str
                - vendor_legal_form: str
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
            "vendor_city": "",
            "vendor_street": "",
            "vendor_legal_form": "",
        }

        if not nip or not nip.isdigit() or len(nip) != 10:
            return result

        # 1. Sprawdź cache
        cached = self._get_from_cache(nip)
        cache_valid = False
        if cached:
            cache_valid = self._is_cache_valid(cached)

        # 2. Wykonaj zapytania równoległe (tylko jeśli cache nieważny)
        api_ok = True
        on_whitelist = False
        gus_data: dict[str, Any] = {}

        if not cache_valid:
            # Uruchom zapytania równoległe: Biała Lista + GUS BIR
            white_list_task = self._check_white_list(nip, bank_account)
            gus_task = self._check_gus_bir(nip)

            async def _safe_white_list() -> tuple[Any, bool]:
                try:
                    result = await self._check_white_list(nip, bank_account)
                    return result, True
                except Exception as e:
                    logger.warning("[ContextEnricher] White List API failed nip=%s: %s", nip, e)
                    return {"on_whitelist": False, "accounts_json": "[]"}, False

            async def _safe_gus_bir() -> tuple[dict[str, Any], bool]:
                try:
                    result = await self._check_gus_bir(nip)
                    return result, True
                except Exception as e:
                    logger.warning(
                        "[ContextEnricher] GUS BIR failed nip=%s: %s — continuing without GUS data",
                        nip,
                        e,
                    )
                    return {}, False

            white_list_result, wl_ok = await _safe_white_list()
            gus_data, gus_ok = await _safe_gus_bir()

            on_whitelist = (
                bool(white_list_result.get("on_whitelist", False))
                if isinstance(white_list_result, dict)
                else bool(white_list_result)
            )
            if not wl_ok:
                api_ok = False

            if api_ok:
                # 3a. API OK — zapisz świeże dane do cache
                status = gus_data.get("vat_status", "active" if on_whitelist else "inactive")
                pkd = gus_data.get("pkd", "")
                company_name = gus_data.get("company_name", "")
                city = gus_data.get("city", "")
                street = gus_data.get("street", "")
                legal_form = gus_data.get("legal_form", "")

                # trust = high jeśli Biała Lista OK, low jeśli nie
                trust = "high" if on_whitelist else "low"

                whitelist_accounts_json = (
                    white_list_data.get("accounts_json", "[]")
                    if isinstance(white_list_data, dict)
                    else "[]"
                )

                self._save_to_cache(
                    nip,
                    vat_status=status,
                    pkd=pkd,
                    account_whitelist=on_whitelist,
                    vendor_trust=trust,
                    company_name=company_name,
                    city=city,
                    street=street,
                    legal_form=legal_form,
                    gus_verified=bool(gus_data),
                    whitelist_accounts=whitelist_accounts_json,
                )

                return {
                    "vendor_vat_status": status,
                    "vendor_pkd": pkd,
                    "vendor_account_on_whitelist": on_whitelist,
                    "vendor_trust": trust,
                    "vendor_company_name": company_name,
                    "vendor_city": city,
                    "vendor_street": street,
                    "vendor_legal_form": legal_form,
                }
            else:
                # 3b. API niedostępne — użyj przeterminowanego cache z niskim trust
                if cached:
                    return {
                        "vendor_vat_status": cached.get("vat_status", "unknown"),
                        "vendor_pkd": cached.get("pkd", ""),
                        "vendor_account_on_whitelist": bool(cached.get("account_whitelist", False)),
                        "vendor_trust": "low",
                        "vendor_company_name": cached.get("company_name", ""),
                        "vendor_city": cached.get("city", ""),
                        "vendor_street": cached.get("street", ""),
                        "vendor_legal_form": cached.get("legal_form", ""),
                    }
                # Brak cache i API nie działa — unknown
                return {
                    "vendor_vat_status": "unknown",
                    "vendor_pkd": "",
                    "vendor_account_on_whitelist": False,
                    "vendor_trust": "low",
                    "vendor_company_name": "",
                    "vendor_city": "",
                    "vendor_street": "",
                    "vendor_legal_form": "",
                }
        else:
            # 2b. Cache ważny — użyj go
            return {
                "vendor_vat_status": cached.get("vat_status", "unknown"),
                "vendor_pkd": cached.get("pkd", ""),
                "vendor_account_on_whitelist": bool(cached.get("account_whitelist", False)),
                "vendor_trust": cached.get("vendor_trust", "high"),
                "vendor_company_name": cached.get("company_name", ""),
                "vendor_city": cached.get("city", ""),
                "vendor_street": cached.get("street", ""),
                "vendor_legal_form": cached.get("legal_form", ""),
            }

    async def _check_white_list(self, nip: str, bank_account: str) -> bool | dict:
        """Sprawdza NIP i konto na Białej Liście MF.

        Returns:
            dict z kluczami:
                - on_whitelist: bool — czy konto jest na białej liście
                - accounts_json: str — JSON lista wszystkich kont
            Lub bool dla wstecznej kompatybilności.
        """
        try:
            if bank_account:
                result = await self._white_list.verify_bank_account(nip, bank_account)
                if isinstance(result, dict):
                    return result
                return {"on_whitelist": result, "accounts_json": "[]"}
            # Nawet bez konta — sprawdź czy NIP istnieje
            # WhiteListService.verify_bank_account wymaga konta
            return {
                "on_whitelist": True,
                "accounts_json": "[]",
            }  # brak konta = nie możemy zablokować
        except Exception as exc:
            logger.warning("[ContextEnricher] White List check failed nip=%s: %s", nip, exc)
            return {"on_whitelist": False, "accounts_json": "[]"}

    async def _check_gus_bir(self, nip: str) -> dict[str, Any]:
        """Sprawdza NIP w GUS BIR (Baza Internetowa REGON).

        Używa GusBirClient (SOAP) do wyszukania firmy po NIP.
        Jeśli klucz API GUS_BIR_API_KEY nie jest skonfigurowany,
        zwraca pusty słownik (bez błędów).

        Args:
            nip: 10-cyfrowy NIP.

        Returns:
            Słownik z danymi firmy z GUS (lub pusty).
        """
        import os

        api_key = os.environ.get("GUS_BIR_API_KEY", "")
        if not api_key:
            logger.debug(
                "[ContextEnricher] GUS BIR check nip=%s skipped — GUS_BIR_API_KEY not configured",
                nip,
            )
            return {}

        # Leniwe tworzenie klienta GUS BIR
        if self._gus_bir is None:
            from services.gus_bir_client import GusBirClient

            self._gus_bir = GusBirClient(api_key=api_key)

        try:
            result = await self._gus_bir.enrich_from_nip(nip)
            logger.info(
                "[ContextEnricher] GUS BIR check nip=%s name=%s status=%s pkd=%s",
                nip,
                result.get("company_name", "?"),
                result.get("vat_status", "?"),
                result.get("pkd", "?"),
            )
            return result
        except Exception as exc:
            logger.warning(
                "[ContextEnricher] GUS BIR check failed nip=%s: %s",
                nip,
                exc,
            )
            return {}

    def _on_protocols_changed(self, version: str | None) -> None:
        """Callback wywoływany gdy protocols.toml zmieni się na dysku."""
        if version:
            logger.info(
                "[ContextEnricher] Protocols reloaded: version=%s — config updated",
                version,
            )
        else:
            logger.info("[ContextEnricher] Protocols reloaded — config updated")

    def _get_protocol_ttl_days(self) -> int:
        """Pobierz TTL cache z protocols.toml, fallback do TTL_DAYS=30."""
        try:
            white_list = self._protocol_executor._loader.get_protocol("context_enricher.white_list")
            return int(white_list.get("cache_ttl_days", TTL_DAYS))
        except Exception:
            return TTL_DAYS

    # ── Cache helpers ────────────────────────────────────────────────────

    def _is_cache_valid(self, cached: dict[str, Any]) -> bool:
        """Sprawdź czy wpis w cache jest wciąż ważny (TTL z protocols.toml).

        Args:
            cached: Słownik z cache (musi zawierać ``fetched_at``).

        Returns:
            True jeśli cache jest wciąż ważny.
        """
        cached_fetched = cached.get("fetched_at", "")
        if isinstance(cached_fetched, str):
            try:
                fetched = pendulum.parse(cached_fetched)
            except ValueError:
                fetched = pendulum.DateTime.min.replace(tzinfo=None)
        elif isinstance(cached_fetched, pendulum.DateTime):
            fetched = cached_fetched
        else:
            return False

        now = pendulum.now("UTC").replace(tzinfo=None)
        if fetched.tzinfo is not None:
            fetched = fetched.replace(tzinfo=None)

        age = now - fetched
        ttl = self._get_protocol_ttl_days()
        return age.days < ttl

    def _get_from_cache(self, nip: str) -> dict[str, Any] | None:
        """Odczytaj wpis z cache dla NIP-u."""
        rows = self._conn.execute(
            "SELECT vat_status, pkd, account_whitelist, vendor_trust, "
            "company_name, city, street, legal_form, gus_verified, fetched_at "
            "FROM vendor_cache WHERE nip = ?",
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
            "city": str(row[5]) if row[5] else "",
            "street": str(row[6]) if row[6] else "",
            "legal_form": str(row[7]) if row[7] else "",
            "gus_verified": bool(row[8]) if row[8] else False,
            "fetched_at": row[9],
        }

    def _save_to_cache(
        self,
        nip: str,
        vat_status: str,
        pkd: str,
        account_whitelist: bool,
        vendor_trust: str,
        company_name: str,
        city: str = "",
        street: str = "",
        legal_form: str = "",
        gus_verified: bool = False,
        whitelist_accounts: str = "[]",
    ) -> None:
        """Zapisz wynik do cache (UPSERT)."""
        self._conn.execute(
            """INSERT OR REPLACE INTO vendor_cache
               (nip, vat_status, pkd, account_whitelist, vendor_trust,
                company_name, city, street, legal_form, gus_verified,
                whitelist_accounts, fetched_at)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)""",
            (
                nip,
                vat_status,
                pkd,
                account_whitelist,
                vendor_trust,
                company_name,
                city,
                street,
                legal_form,
                gus_verified,
                whitelist_accounts,
            ),
        )
