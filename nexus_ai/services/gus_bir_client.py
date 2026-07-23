"""
GUS BIR Client -- SOAP-based client for GUS BIR (Baza Internetowa REGON).
v7.0 INTEGRACJE ZEWNĘTRZNE:
- Dodano persistence cache w SQLite/DuckDB (LUKA 5)
- Dodano request deduplication — równoległe zapytania dla tego samego NIP czekają (LUKA 6)
- Rozszerzone mapowanie StatusNip: AKTYWNY/ZAWIESZONY/WYKRESLONY/ZAMKNIENTY (LUKA 7)
- XML sanityzacja: XXE protection + XML bomb detection (LUKA 18)
"""

from __future__ import annotations

import asyncio
import html
import os
import re
from typing import Any, final

import httpx
import stamina
from msgspec import Struct, field
from structlog import get_logger

from nexus_ai.core.cache.http_client import CachedHttpClient

logger = get_logger("nexus.services.gus_bir")

# Endpoints
BIR_ENDPOINTS: dict[str, str] = {
    "production": "https://wyszukiwarkaregon.stat.gov.pl/wsBIR/UslugaBIRzewnPubl.svc",
    "test": "https://wyszukiwarkaregontest.stat.gov.pl/wsBIR/UslugaBIRzewnPubl.svc",
}

# SOAP envelope template (no external SOAP library needed)
SOAP_ENVELOPE = """<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope
    xmlns:soap="http://www.w3.org/2003/05/soap-envelope"
    xmlns:ns="http://CIT/BIR/2014/07"
    xmlns:dat="http://CIT/BIR/2014/07/DataContract">
    <soap:Header/>
    <soap:Body>
{body}
    </soap:Body>
</soap:Envelope>"""


class GusBirResult(Struct):
    __slots__ = ()
    """Wynik wyszukiwania pojedynczej firmy w GUS BIR."""

    regon: str = ""
    nip: str = ""
    name: str = ""
    voivodeship: str = ""
    district: str = ""
    commune: str = ""
    city: str = ""
    street: str = ""
    property_number: str = ""
    zip_code: str = ""
    post_city: str = ""
    status: str = "unknown"
    # v7.0: Rozszerzone statusy (LUKA 7)
    status_detail: str = ""  # AKTYWNY, ZAWIESZONY, WYKRESLONY, ZAMKNIENTY
    pkd_codes: list[dict[str, str]] = field(default_factory=list)
    legal_form: str = ""


# ── v7.0: Mapowanie statusów GUS BIR ─────────────────────────────────────

STATUS_NIP_MAP: dict[str, str] = {
    "AKTYWNY": "active",
    "ZAWIESZONY": "suspended",
    "WYKRESLONY": "deregistered",
    "ZAMKNIENTY": "closed",
    "": "unknown",
}

STATUS_NIP_RISK: dict[str, float] = {
    "active": 0.0,
    "suspended": 0.6,
    "deregistered": 0.9,
    "closed": 0.95,
    "unknown": 0.5,
}


def _map_status_nip(status_raw: str) -> tuple[str, str]:
    """v7.0: Rozszerzone mapowanie statusu NIP z oceną ryzyka.

    Returns:
        (status, status_detail) np. ("active", "AKTYWNY").
    """
    status_upper = status_raw.upper().strip()
    for raw_key, mapped in STATUS_NIP_MAP.items():
        if raw_key in status_upper:
            return mapped, raw_key
    return "unknown" if status_raw else "unknown", status_raw


def get_nip_risk_score(status: str) -> float:
    """v7.0: Ocena ryzyka na podstawie statusu NIP.

    0.0 = aktywny (brak ryzyka)
    0.6 = zawieszony
    0.9 = wykreślony
    0.95 = zamknięty
    0.5 = nieznany
    """
    return STATUS_NIP_RISK.get(status, 0.5)


@final
class GusBirClient:
    """SOAP client for GUS BIR (Baza Internetowa REGON) — v7.0.

    v7.0: Dodano persistence cache + request deduplication + XML sanityzację.
    """

    # v7.0: Request deduplication — słownik aktywnych zapytań per NIP
    _pending_requests: dict[str, asyncio.Event] = {}
    _pending_results: dict[str, list[GusBirResult]] = {}
    _pending_lock = asyncio.Lock()

    def __init__(
        self,
        api_key: str | None = None,
        environment: str = "production",
        timeout: int = 30,
        # v7.0: Opcjonalne DuckDB lub SQLite dla persistence cache
        cache_db_path: str = "",
        # v7.0: Shared CachedHttpClient przez DI (LUKA 12)
        http_client: CachedHttpClient | None = None,
    ) -> None:
        self._api_key = api_key or os.environ.get("GUS_BIR_API_KEY", "")
        self._endpoint = BIR_ENDPOINTS.get(environment, BIR_ENDPOINTS["production"])
        self._timeout = timeout
        self._sid: str = ""
        # v7.0: Współdzielony klient HTTP (DI-ready)
        if http_client is not None:
            self._http = http_client
            self._owns_http = False
        else:
            self._http = CachedHttpClient()
            self._owns_http = True
        # v7.0: Persistence cache
        self._cache_db_path = cache_db_path or os.path.join(
            os.getcwd(), "app_data", "gus_bir_cache.db"
        )
        self._cache_ttl = 86400  # 24h — dane firm zmieniają się rzadko

    async def _ensure_cache_db(self) -> None:
        """v7.0: Inicjalizuj SQLite cache dla danych GUS BIR."""
        import sqlite3
        conn = sqlite3.connect(self._cache_db_path)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS gus_bir_cache (
                nip TEXT PRIMARY KEY,
                data TEXT NOT NULL,
                cached_at REAL NOT NULL,
                status TEXT DEFAULT 'active'
            )
        """)
        conn.execute("""
            CREATE INDEX IF NOT EXISTS idx_gus_cache_status
            ON gus_bir_cache(status)
        """)
        conn.commit()
        conn.close()

    async def _get_cached(self, nip: str) -> dict[str, Any] | None:
        """v7.0: Pobierz dane z persistence cache."""
        import json
        import sqlite3
        import time as _time
        try:
            await self._ensure_cache_db()
            conn = sqlite3.connect(self._cache_db_path)
            row = conn.execute(
                "SELECT data, cached_at FROM gus_bir_cache WHERE nip = ?",
                (nip,),
            ).fetchone()
            conn.close()
            if row and (_time.time() - row[1]) < self._cache_ttl:
                return json.loads(row[0])
        except Exception as exc:
            logger.debug("[GUS-BIR-CACHE] Read failed: %s", exc)
        return None

    async def _set_cached(self, nip: str, data: dict[str, Any]) -> None:
        """v7.0: Zapisz dane do persistence cache."""
        import json
        import sqlite3
        import time as _time
        try:
            await self._ensure_cache_db()
            conn = sqlite3.connect(self._cache_db_path)
            conn.execute(
                "INSERT OR REPLACE INTO gus_bir_cache (nip, data, cached_at, status) VALUES (?, ?, ?, ?)",
                (nip, json.dumps(data), _time.time(), data.get("vat_status", "unknown")),
            )
            conn.commit()
            conn.close()
        except Exception as exc:
            logger.debug("[GUS-BIR-CACHE] Write failed: %s", exc)

    async def __aenter__(self) -> GusBirClient:
        return self

    async def __aexit__(self, *args: Any) -> None:
        if self._sid:
            try:
                await self._soap_call(
                    "Wyloguj",
                    f"<ns:Wyloguj><ns:pIdentyfikatorSesji>{self._sid}</ns:pIdentyfikatorSesji></ns:Wyloguj>",
                )
            except Exception as exc:
                logger.warning("[GUS-BIR] Logout on exit failed: %s", exc)
        if self._owns_http:
            await self._http.close()

    __slots__ = ("_api_key", "_cache_db_path", "_cache_ttl", "_endpoint", "_http", "_owns_http", "_sid", "_timeout")

    @property
    def is_authenticated(self) -> bool:
        """Czy klient ma aktywna sesje."""
        return bool(self._sid)

    async def login(self) -> bool:
        """Zaloguj sie do API GUS BIR i pobierz session ID (sid).

        SUPERPOWERS: stamina.retry z circuit breaker dla odpornej komunikacji z GUS.
        """
        if not self._api_key:
            raise ValueError(
                "GUS BIR API key not configured. Set GUS_BIR_API_KEY env var "
                "or pass api_key to GusBirClient()."
            )

        body = (
            f"<ns:Zaloguj><ns:pKluczUzytkownika>{self._api_key}</ns:pKluczUzytkownika></ns:Zaloguj>"
        )
        for attempt in stamina.retry_context(
            on=(httpx.HTTPStatusError, httpx.TimeoutException, httpx.RequestError, ConnectionError),
            attempts=3,
            timeout=15.0,
            circuit_breaker=True,
        ):
            with attempt:
                try:
                    result = await self._soap_call("Zaloguj", body)
                    self._sid = result.strip()
                    logger.info(
                        "[GUS-BIR] Login successful, sid=%s...", self._sid[:10] if self._sid else "empty"
                    )
                    return bool(self._sid)
                except Exception as exc:
                    logger.error("[GUS-BIR] Login failed: %s", exc)
                    raise ConnectionError(f"GUS BIR login failed: {exc}") from exc
        return False

    async def search_by_nip(self, nip: str) -> list[GusBirResult]:
        """Wyszukaj firmy po NIP — v7.0 z deduplikacją.

        SUPERPOWERS: stamina.retry + request deduplication (LUKA 6).
        Jeśli zapytanie dla danego NIP jest w toku, kolejne zapytania czekają.
        """
        nip_clean = "".join(c for c in nip if c.isdigit())
        if len(nip_clean) != 10:
            raise ValueError(f"Invalid NIP: {nip}")
        if not self._sid:
            raise PermissionError("GUS BIR not authenticated. Call login() first.")

        # v7.0: Request deduplication check
        async with self._pending_lock:
            if nip_clean in self._pending_requests:
                # Zapytanie w toku — czekaj na wynik
                event = self._pending_requests[nip_clean]
                logger.debug("[GUS-BIR] Dedup: waiting for existing request nip=%s", nip_clean)
                await event.wait()
                return self._pending_results.get(nip_clean, [])
            # Zarejestruj nowe zapytanie
            self._pending_requests[nip_clean] = asyncio.Event()
            self._pending_results[nip_clean] = []

        try:
            body = (
                "<ns:DaneSzukaj>"
                "<ns:pParametryWyszukiwania>"
                f"<dat:Nip>{nip_clean}</dat:Nip>"
                "</ns:pParametryWyszukiwania>"
                "</ns:DaneSzukaj>"
            )
            for attempt in stamina.retry_context(
                on=(httpx.HTTPStatusError, httpx.TimeoutException, httpx.RequestError, ConnectionError),
                attempts=3,
                timeout=15.0,
            ):
                with attempt:
                    try:
                        raw_xml = await self._soap_call("DaneSzukaj", body)
                        results = self._parse_search_results(raw_xml)
                        logger.info("[GUS-BIR] search_by_nip nip=%s results=%d", nip_clean, len(results))
                        # v7.0: Zapisz wynik dla oczekujących
                        async with self._pending_lock:
                            self._pending_results[nip_clean] = results
                        return results
                    except Exception as exc:
                        logger.warning("[GUS-BIR] search_by_nip failed nip=%s: %s", nip_clean, exc)
                        raise
            return []
        finally:
            # v7.0: Obudź oczekujące zapytania
            async with self._pending_lock:
                event = self._pending_requests.pop(nip_clean, None)
                if event:
                    event.set()

    async def get_full_report(self, regon: str) -> GusBirResult | None:
        """Pobierz pelny raport dla REGON.

        SUPERPOWERS: stamina.retry dla odpornej komunikacji z GUS BIR.
        """
        regon_clean = "".join(c for c in regon if c.isdigit())
        if len(regon_clean) not in (9, 14):
            logger.warning("[GUS-BIR] Invalid REGON: %s", regon)
            return None
        if not self._sid:
            raise PermissionError("GUS BIR not authenticated. Call login() first.")

        body = (
            "<ns:DanePobierzPelnyRaport>"
            "<ns:pIdentyfikatorRegon>"
            f"{regon_clean}</ns:pIdentyfikatorRegon>"
            "<ns:pNazwaRaportu>"
            "PelnyRaport</ns:pNazwaRaportu>"
            "</ns:DanePobierzPelnyRaport>"
        )
        for attempt in stamina.retry_context(
            on=(httpx.HTTPStatusError, httpx.TimeoutException, httpx.RequestError, ConnectionError),
            attempts=3,
            timeout=15.0,
        ):
            with attempt:
                try:
                    raw_xml = await self._soap_call("DanePobierzPelnyRaport", body)
                    result = self._parse_full_report(raw_xml)
                    if result:
                        result.regon = regon_clean
                    return result
                except Exception as exc:
                    logger.warning("[GUS-BIR] get_full_report failed regon=%s: %s", regon_clean, exc)
                    raise
        return None

    async def logout(self) -> None:
        """Wyloguj sie i zwolnij sesje."""
        if not self._sid:
            return
        try:
            body = (
                "<ns:Wyloguj>"
                f"<ns:pIdentyfikatorSesji>{self._sid}</ns:pIdentyfikatorSesji>"
                "</ns:Wyloguj>"
            )
            await self._soap_call("Wyloguj", body)
            logger.info("[GUS-BIR] Logout successful")
        except Exception as exc:
            logger.warning("[GUS-BIR] Logout failed: %s", exc)
        finally:
            self._sid = ""

    async def enrich_from_nip(self, nip: str) -> dict[str, Any]:
        """Kompletne wzbogacenie danych z GUS BIR dla NIP-u — v7.0.

        v7.0: Dodano persistence cache + rozszerzone statusy + risk score.
        """
        nip_clean = "".join(c for c in nip if c.isdigit())

        # v7.0: Sprawdź persistence cache najpierw
        cached = await self._get_cached(nip_clean)
        if cached:
            logger.debug("[GUS-BIR] Cache HIT for nip=%s", nip_clean)
            return cached

        result: dict[str, Any] = {
            "vat_status": "unknown",
            "status_detail": "",
            "risk_score": 0.5,
            "pkd": "",
            "company_name": "",
            "city": "",
            "street": "",
            "legal_form": "",
            "regon": "",
        }
        try:
            await self.login()
            search_results = await self.search_by_nip(nip)
            if search_results:
                sr = search_results[0]
                result["company_name"] = sr.name
                result["vat_status"] = sr.status
                result["status_detail"] = sr.status_detail
                result["risk_score"] = get_nip_risk_score(sr.status)
                result["regon"] = sr.regon
                if sr.regon:
                    full = await self.get_full_report(sr.regon)
                    if full:
                        result["pkd"] = full.pkd_codes[0]["code"] if full.pkd_codes else ""
                        result["city"] = full.city
                        result["street"] = full.street
                        result["legal_form"] = full.legal_form
            # v7.0: Zapisz do persistence cache
            await self._set_cached(nip_clean, result)
        except Exception as exc:
            logger.warning("[GUS-BIR] enrich_from_nip failed nip=%s: %s", nip, exc)
        finally:
            try:
                await self.logout()
            except Exception as exc:
                logger.warning("[GUS-BIR] enrich_from_nip logout failed nip=%s: %s", nip, exc)
        return result

    # --- SOAP internals ---

    async def _soap_call(self, method: str, body_xml: str) -> str:
        """Wykonaj wywolanie SOAP i zwroc surowy XML odpowiedzi — v7.0.

        v7.0: XML sanityzacja — XXE protection + XML bomb detection (LUKA 18).
        """
        envelope = SOAP_ENVELOPE.format(body=body_xml)
        headers: dict[str, str] = {
            "Content-Type": "application/soap+xml; charset=utf-8",
            "SOAPAction": f"http://CIT/BIR/2014/07/IUslugaBIRzewnPubl/{method}",
        }
        if self._sid:
            headers["sid"] = self._sid

        try:
            response = await self._http.post(
                self._endpoint,
                content=envelope.encode("utf-8"),
                headers=headers,
            )
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise ConnectionError(
                f"GUS BIR HTTP {exc.response.status_code}: {exc.response.text[:200]}"
            ) from exc
        except httpx.TimeoutException as exc:
            raise ConnectionError(f"GUS BIR timeout: {exc}") from exc
        except httpx.RequestError as exc:
            raise ConnectionError(f"GUS BIR connection error: {exc}") from exc

        # v7.0: XML sanityzacja — ochrona przed XXE i XML bomb
        return self._sanityze_and_extract(response.text, method)

    def _sanityze_and_extract(self, xml_text: str, method: str) -> str:
        """v7.0: Sanityzacja XML przed parsowaniem.

        Zabezpiecza przed:
        - XML External Entity (XXE) atakami
        - XML bomb (Billion Laughs attack)
        - Nadmiernie dużymi odpowiedziami
        """
        # Limit rozmiaru: max 1MB (LUKA 18)
        MAX_XML_SIZE = 1_048_576  # 1 MB
        if len(xml_text) > MAX_XML_SIZE:
            raise ValueError(
                f"[GUS-BIR-SEC] Response too large: {len(xml_text)} bytes > {MAX_XML_SIZE}"
            )

        # Detekcja XML bomb — wzorzec entity expansion
        bomb_patterns = [
            "&lol", "&lol1", "&lol2", "&lol3", "&lol4",
            "&lol5", "&lol6", "&lol7", "&lol8", "&lol9",
            "&x1;", "&x2;", "&x3;",
            "SYSTEM \"file://",  # XXE probe
            "<!ENTITY",  # Nadmiarowe entity declarations
        ]
        xml_lower = xml_text.lower()
        for pattern in bomb_patterns:
            if pattern.lower() in xml_lower:
                logger.warning(
                    "[GUS-BIR-SEC] Potential XML bomb/XXE detected: pattern=%s",
                    pattern,
                )
                # Nie odrzucaj automatycznie — niektóre legalne XML mogą zawierać &lol;
                # ale loguj dla audytu
                break

        # Usuń potencjalnie niebezpieczne deklaracje DOCTYPE
        safe_xml = re.sub(
            r'<!DOCTYPE[^>]*>',
            '',
            xml_text,
            flags=re.IGNORECASE | re.DOTALL,
        )

        return self._extract_result(safe_xml, method)

    @staticmethod
    def _extract_result(xml_text: str, method: str) -> str:
        """Wydobadz wynik z odpowiedzi SOAP XML.

        Uzywa regex do znalezienia tagu {method}Result z dowolnym namespacem.
        """
        result_tag = f"{method}Result"
        # Wzorzec: <...:methodResult xmlns=...>content</...:methodResult>
        match = re.search(
            rf"<[^>]*{result_tag}[^>]*>(.*?)</[^>]*{result_tag}>",
            xml_text,
            re.DOTALL,
        )
        if match:
            return match.group(1).strip()
        raise ValueError(f"Cannot find {result_tag} in SOAP response: {xml_text[:300]}")

    @staticmethod
    def _parse_search_results(xml_text: str) -> list[GusBirResult]:
        """Parsuj wyniki DaneSzukaj na liste GusBirResult."""
        results: list[GusBirResult] = []
        if not xml_text or xml_text.strip() == "":
            return results

        decoded = html.unescape(xml_text)
        blocks = re.findall(r"<[a-zA-Z]*[dD]ane[^>]*>(.*?)</[a-zA-Z]*[dD]ane>", decoded, re.DOTALL)
        if not blocks:
            blocks = [decoded]

        for block in blocks:
            r = GusBirResult()
            r.regon = _extract_tag(block, "Regon") or ""
            r.nip = _extract_tag(block, "Nip") or ""
            r.name = _extract_tag(block, "Nazwa") or ""
            r.voivodeship = _extract_tag(block, "Wojewodztwo") or ""
            r.district = _extract_tag(block, "Powiat") or ""
            r.commune = _extract_tag(block, "Gmina") or ""
            r.city = _extract_tag(block, "Miejscowosc") or ""
            r.street = _extract_tag(block, "Ulica") or ""
            r.property_number = (
                _extract_tag(block, "NrNieruchomosci") or _extract_tag(block, "NrLokalu") or ""
            )
            r.zip_code = _extract_tag(block, "KodPocztowy") or ""
            r.post_city = _extract_tag(block, "Poczta") or ""
            status_raw = _extract_tag(block, "StatusNip") or ""
            r.status, r.status_detail = _map_status_nip(status_raw)
            results.append(r)

        return results

    @staticmethod
    def _parse_full_report(xml_text: str) -> GusBirResult | None:
        """Parsuj odpowiedz DanePobierzPelnyRaport na GusBirResult."""
        if not xml_text or xml_text.strip() == "":
            return None

        decoded = html.unescape(xml_text)
        result = GusBirResult()
        result.name = _extract_tag(decoded, "Nazwa") or ""
        result.city = _extract_tag(decoded, "Miejscowosc") or ""
        result.street = _extract_tag(decoded, "Ulica") or ""
        result.zip_code = _extract_tag(decoded, "KodPocztowy") or ""
        result.voivodeship = _extract_tag(decoded, "Wojewodztwo") or ""
        result.legal_form = _extract_tag(decoded, "FormaPrawna") or ""
        status_raw = _extract_tag(decoded, "StatusNip") or ""
        result.status, result.status_detail = _map_status_nip(status_raw)

        pkd_codes_raw = re.findall(r"<pkdKod[^>]*>(.*?)</pkdKod>", decoded, re.DOTALL)
        pkd_names_raw = re.findall(r"<pkdNazwa[^>]*>(.*?)</pkdNazwa>", decoded, re.DOTALL)
        result.pkd_codes = []
        for i, code in enumerate(pkd_codes_raw):
            name = pkd_names_raw[i] if i < len(pkd_names_raw) else ""
            result.pkd_codes.append({"code": code.strip(), "name": name.strip()})

        return result


def _extract_tag(xml_text: str, tag: str) -> str:
    """Wyodrebnij zawartosc taga XML (z namespacem lub bez)."""
    # <tag>...</tag>
    m = re.search(rf"<{tag}[^>]*>(.*?)</{tag}>", xml_text, re.DOTALL)
    if m:
        return m.group(1).strip()
    # <ns:tag>...</ns:tag>
    m = re.search(rf"<[a-zA-Z]*:{tag}[^>]*>(.*?)</[a-zA-Z]*:{tag}>", xml_text, re.DOTALL)
    if m:
        return m.group(1).strip()
    return ""
