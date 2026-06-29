"""
GUS BIR Client — SOAP-based client for GUS BIR (Baza Internetowa REGON).
"""

from __future__ import annotations

import html
import os
import re
from msgspec import Struct, field
from typing import Any, final

import httpx
import stamina
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
    pkd_codes: list[dict[str, str]] = field(default_factory=list)
    legal_form: str = ""


@final
class GusBirClient:
    """SOAP client for GUS BIR (Baza Internetowa REGON)."""

    def __init__(
        self,
        api_key: str | None = None,
        environment: str = "production",
        timeout: int = 30,
    ) -> None:
        self._api_key = api_key or os.environ.get("GUS_BIR_API_KEY", "")
        self._endpoint = BIR_ENDPOINTS.get(environment, BIR_ENDPOINTS["production"])
        self._timeout = timeout
        self._sid: str = ""
        self._http = CachedHttpClient()

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
        await self._http.close()

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
        """Wyszukaj firmy po NIP.

        SUPERPOWERS: stamina.retry dla odpornej komunikacji z GUS BIR.
        """
        nip_clean = "".join(c for c in nip if c.isdigit())
        if len(nip_clean) != 10:
            raise ValueError(f"Invalid NIP: {nip}")
        if not self._sid:
            raise PermissionError("GUS BIR not authenticated. Call login() first.")

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
                    return results
                except Exception as exc:
                    logger.warning("[GUS-BIR] search_by_nip failed nip=%s: %s", nip_clean, exc)
                    raise
        return []

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
        """Kompletne wzbogacenie danych z GUS BIR dla NIP-u.

        SUPERPOWERS: stamina.retry dla calego przeplywu GUS BIR.
        """
        result: dict[str, Any] = {
            "vat_status": "unknown",
            "pkd": "",
            "company_name": "",
            "city": "",
            "street": "",
            "legal_form": "",
        }
        try:
            await self.login()
            search_results = await self.search_by_nip(nip)
            if search_results:
                sr = search_results[0]
                result["company_name"] = sr.name
                result["vat_status"] = sr.status
                if sr.regon:
                    full = await self.get_full_report(sr.regon)
                    if full:
                        result["pkd"] = full.pkd_codes[0]["code"] if full.pkd_codes else ""
                        result["city"] = full.city
                        result["street"] = full.street
                        result["legal_form"] = full.legal_form
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
        """Wykonaj wywolanie SOAP i zwroc surowy XML odpowiedzi."""
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

        return self._extract_result(response.text, method)

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
            r.status = "active" if "AKTYWNY" in status_raw.upper() else "inactive"
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
        result.status = "active" if "AKTYWNY" in status_raw.upper() else "inactive"

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
