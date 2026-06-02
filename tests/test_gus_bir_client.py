"""
Tests for GusBirClient — GUS BIR SOAP API client.

Uses mocking of _soap_call to avoid httpx.MockTransport compatibility issues.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest

from services.gus_bir_client import (
    GusBirClient,
    GusBirResult,
    _extract_tag,
)


# Sample SOAP response snippets (inner content, not full envelopes)
SAMPLE_LOGIN_RESULT = "abc123session456def"
SAMPLE_SEARCH_RESULT = """<dane>
    <Regon>123456789</Regon>
    <Nip>1234567890</Nip>
    <Nazwa>ACME Sp. z o.o.</Nazwa>
    <Wojewodztwo>MAZOWIECKIE</Wojewodztwo>
    <Powiat>m.st. Warszawa</Powiat>
    <Gmina>Warszawa-Srodmiescie</Gmina>
    <Miejscowosc>Warszawa</Miejscowosc>
    <Ulica>Marszalkowska</Ulica>
    <NrNieruchomosci>100</NrNieruchomosci>
    <KodPocztowy>00-001</KodPocztowy>
    <Poczta>Warszawa</Poczta>
    <StatusNip>AKTYWNY</StatusNip>
</dane>"""

SAMPLE_FULL_REPORT_RESULT = """<root>
    <Nazwa>ACME Sp. z o.o.</Nazwa>
    <Miejscowosc>Warszawa</Miejscowosc>
    <Ulica>Marszalkowska 100</Ulica>
    <KodPocztowy>00-001</KodPocztowy>
    <Wojewodztwo>MAZOWIECKIE</Wojewodztwo>
    <FormaPrawna>Spolka z ograniczona odpowiedzialnoscia</FormaPrawna>
    <StatusNip>AKTYWNY</StatusNip>
    <pkdKod>62.01.Z</pkdKod>
    <pkdNazwa>Dzialalnosc zwiazana z oprogramowaniem</pkdNazwa>
    <pkdKod>62.02.Z</pkdKod>
    <pkdNazwa>Dzialalnosc zwiazana z doradztwem w zakresie informatyki</pkdNazwa>
</root>"""

SAMPLE_LOGOUT_RESULT = "true"


@pytest.fixture
def api_key() -> str:
    return "test_api_key_12345"


@pytest.fixture
def client(api_key: str) -> GusBirClient:
    return GusBirClient(api_key=api_key, environment="test")


# ═══════════════════════════════════════════════════════════════════════════════
# Testy jednostkowe — _extract_tag
# ═══════════════════════════════════════════════════════════════════════════════


class TestExtractTag:
    def test_simple_tag(self) -> None:
        assert _extract_tag("<root><Nazwa>Test</Nazwa></root>", "Nazwa") == "Test"

    def test_tag_with_namespace(self) -> None:
        assert _extract_tag("<root><ns:Nazwa>Test</ns:Nazwa></root>", "Nazwa") == "Test"

    def test_missing_tag(self) -> None:
        assert _extract_tag("<root><Other>val</Other></root>", "Nazwa") == ""

    def test_empty_content(self) -> None:
        assert _extract_tag("<root><Nazwa></Nazwa></root>", "Nazwa") == ""

    def test_nested_tags(self) -> None:
        assert _extract_tag("<root><dane><Nazwa>Deep</Nazwa></dane></root>", "Nazwa") == "Deep"


# ═══════════════════════════════════════════════════════════════════════════════
# Testy — GusBirResult
# ═══════════════════════════════════════════════════════════════════════════════


class TestGusBirResult:
    def test_create_empty(self) -> None:
        r = GusBirResult()
        assert r.regon == ""
        assert r.nip == ""
        assert r.pkd_codes == []

    def test_create_with_values(self) -> None:
        r = GusBirResult(
            regon="123456789", nip="1234567890", name="ACME",
            status="active", pkd_codes=[{"code": "62.01.Z", "name": "IT"}],
        )
        assert r.regon == "123456789"
        assert r.name == "ACME"
        assert r.status == "active"
        assert r.pkd_codes[0]["code"] == "62.01.Z"


# ═══════════════════════════════════════════════════════════════════════════════
# Testy — GusBirClient (z mockowaniem _soap_call)
# ═══════════════════════════════════════════════════════════════════════════════


class TestGusBirClientLogin:
    """Testy logowania."""

    @pytest.mark.asyncio
    async def test_login_success(self, client: GusBirClient) -> None:
        """Login udany — _soap_call zwraca sid."""
        with patch.object(client, "_soap_call", new=AsyncMock(return_value=SAMPLE_LOGIN_RESULT)):
            result = await client.login()
            assert result is True
            assert client._sid == "abc123session456def"
            client._soap_call.assert_awaited_once()  # type: ignore

    @pytest.mark.asyncio
    async def test_login_no_api_key(self) -> None:
        """Login bez klucza API -> ValueError."""
        c = GusBirClient(api_key="")
        with pytest.raises(ValueError, match="API key not configured"):
            await c.login()

    @pytest.mark.asyncio
    async def test_login_http_error(self, client: GusBirClient) -> None:
        """Blad HTTP -> ConnectionError."""
        with patch.object(client, "_soap_call", new=AsyncMock(side_effect=ConnectionError("HTTP 500"))):
            with pytest.raises(ConnectionError, match="GUS BIR login failed"):
                await client.login()


class TestGusBirClientSearch:
    """Testy wyszukiwania."""

    @pytest.mark.asyncio
    async def test_search_by_nip_success(self, client: GusBirClient) -> None:
        """Wyszukiwanie po NIP zwraca wyniki."""
        client._sid = "test_sid"
        with patch.object(client, "_soap_call", new=AsyncMock(return_value=SAMPLE_SEARCH_RESULT)):
            results = await client.search_by_nip("1234567890")
            assert len(results) == 1
            r = results[0]
            assert r.nip == "1234567890"
            assert r.regon == "123456789"
            assert r.name == "ACME Sp. z o.o."
            assert r.city == "Warszawa"
            assert r.street == "Marszalkowska"
            assert r.status == "active"

    @pytest.mark.asyncio
    async def test_search_by_nip_not_authenticated(self, client: GusBirClient) -> None:
        """Brak autoryzacji -> PermissionError."""
        with pytest.raises(PermissionError, match="not authenticated"):
            await client.search_by_nip("1234567890")

    @pytest.mark.asyncio
    async def test_search_by_nip_invalid(self, client: GusBirClient) -> None:
        """Nieprawidlowy NIP -> ValueError."""
        with pytest.raises(ValueError, match="Invalid NIP"):
            await client.search_by_nip("123")

    @pytest.mark.asyncio
    async def test_search_by_nip_no_results(self, client: GusBirClient) -> None:
        """Brak wynikow -> pusta lista."""
        client._sid = "test_sid"
        with patch.object(client, "_soap_call", new=AsyncMock(return_value="")):
            results = await client.search_by_nip("1234567890")
            assert results == []

    @pytest.mark.asyncio
    async def test_search_by_nip_api_error(self, client: GusBirClient) -> None:
        """Blad API -> pusta lista (graceful)."""
        client._sid = "test_sid"
        with patch.object(client, "_soap_call", new=AsyncMock(side_effect=ConnectionError("API error"))):
            results = await client.search_by_nip("1234567890")
            assert results == []


class TestGusBirClientFullReport:
    """Testy pelnego raportu."""

    @pytest.mark.asyncio
    async def test_get_full_report_success(self, client: GusBirClient) -> None:
        """Pelny raport zwraca dane firmy."""
        client._sid = "test_sid"
        with patch.object(client, "_soap_call", new=AsyncMock(return_value=SAMPLE_FULL_REPORT_RESULT)):
            result = await client.get_full_report("123456789")
            assert result is not None
            assert result.name == "ACME Sp. z o.o."
            assert result.city == "Warszawa"
            assert result.street == "Marszalkowska 100"
            assert result.legal_form == "Spolka z ograniczona odpowiedzialnoscia"
            assert result.status == "active"
            assert len(result.pkd_codes) == 2
            assert result.pkd_codes[0]["code"] == "62.01.Z"

    @pytest.mark.asyncio
    async def test_get_full_report_invalid_regon(self, client: GusBirClient) -> None:
        """Nieprawidlowy REGON -> None."""
        result = await client.get_full_report("123")
        assert result is None

    @pytest.mark.asyncio
    async def test_get_full_report_not_authenticated(self, client: GusBirClient) -> None:
        """Brak autoryzacji -> PermissionError."""
        with pytest.raises(PermissionError, match="not authenticated"):
            await client.get_full_report("123456789")

    @pytest.mark.asyncio
    async def test_get_full_report_api_error(self, client: GusBirClient) -> None:
        """Blad API -> None (graceful)."""
        client._sid = "test_sid"
        with patch.object(client, "_soap_call", new=AsyncMock(side_effect=ConnectionError("API error"))):
            result = await client.get_full_report("123456789")
            assert result is None


class TestGusBirClientLogout:
    """Testy wylogowania."""

    @pytest.mark.asyncio
    async def test_logout_success(self, client: GusBirClient) -> None:
        """Logout usuwa sid."""
        client._sid = "test_sid"
        with patch.object(client, "_soap_call", new=AsyncMock(return_value="true")):
            await client.logout()
            assert client._sid == ""

    @pytest.mark.asyncio
    async def test_logout_no_session(self, client: GusBirClient) -> None:
        """Logout bez sesji nic nie robi."""
        await client.logout()
        assert client._sid == ""

    @pytest.mark.asyncio
    async def test_logout_api_error_still_clears_sid(self, client: GusBirClient) -> None:
        """Blad API przy logoutie nadal usuwa sid."""
        client._sid = "test_sid"
        with patch.object(client, "_soap_call", new=AsyncMock(side_effect=ConnectionError("API error"))):
            await client.logout()
            assert client._sid == ""  # Sid zawsze czyszczony w finally


class TestGusBirClientEnrich:
    """Testy enrich_from_nip."""

    @pytest.mark.asyncio
    async def test_enrich_from_nip_success(self, client: GusBirClient) -> None:
        """enrich_from_nip zwraca kompletny slownik."""
        # _soap_call bedzie wywolany 3 razy: login, search, report
        call_count = 0

        async def mock_soap_call(method: str, body: str) -> str:
            nonlocal call_count
            call_count += 1
            if method == "Zaloguj":
                return SAMPLE_LOGIN_RESULT
            if method == "DaneSzukaj":
                return SAMPLE_SEARCH_RESULT
            if method == "DanePobierzPelnyRaport":
                return SAMPLE_FULL_REPORT_RESULT
            if method == "Wyloguj":
                return "true"
            return ""

        with patch.object(client, "_soap_call", new=mock_soap_call):
            result = await client.enrich_from_nip("1234567890")
            assert result["company_name"] == "ACME Sp. z o.o."
            assert result["vat_status"] == "active"
            assert result["pkd"] == "62.01.Z"
            assert result["city"] == "Warszawa"
            assert result["street"] == "Marszalkowska 100"
            assert result["legal_form"] == "Spolka z ograniczona odpowiedzialnoscia"

    @pytest.mark.asyncio
    async def test_enrich_from_nip_login_fails(self, client: GusBirClient) -> None:
        """Jesli login fail, enrich zwraca domyslne wartosci."""
        # _soap_call rzuca blad przy loginie
        with patch.object(client, "_soap_call", new=AsyncMock(side_effect=ConnectionError("API unavailable"))):
            result = await client.enrich_from_nip("1234567890")
            assert result["company_name"] == ""
            assert result["vat_status"] == "unknown"

    @pytest.mark.asyncio
    async def test_enrich_from_nip_no_results(self, client: GusBirClient) -> None:
        """Jesli search zwroci 0 wynikow, zwraca podstawowe dane."""
        async def mock_soap_call(method: str, body: str) -> str:
            if method == "Zaloguj":
                return SAMPLE_LOGIN_RESULT
            if method == "DaneSzukaj":
                return ""
            if method == "Wyloguj":
                return "true"
            return ""

        with patch.object(client, "_soap_call", new=mock_soap_call):
            result = await client.enrich_from_nip("1234567890")
            assert result["company_name"] == ""
            assert result["vat_status"] == "unknown"  # nie znaleziono


# ═══════════════════════════════════════════════════════════════════════════════
# Testy — Parsowanie odpowiedzi SOAP
# ═══════════════════════════════════════════════════════════════════════════════


class TestSoapParsing:
    """Testy statycznych metod parsujacych SOAP."""

    def test_extract_result_standard(self) -> None:
        """Standardowy tag Result."""
        xml = "<soap:Body><ZalogujResult>abc123</ZalogujResult></soap:Body>"
        result = GusBirClient._extract_result(xml, "Zaloguj")
        assert result == "abc123"

    def test_extract_result_with_namespace(self) -> None:
        """Tag Result z xmlns atrybutem."""
        xml = '<soap:Body><ns:ZalogujResult xmlns:ns="x">abc123</ns:ZalogujResult></soap:Body>'
        result = GusBirClient._extract_result(xml, "Zaloguj")
        assert result == "abc123"

    def test_extract_result_not_found(self) -> None:
        """Brak taga -> ValueError."""
        xml = "<soap:Body><Other>val</Other></soap:Body>"
        with pytest.raises(ValueError, match="Cannot find"):
            GusBirClient._extract_result(xml, "Zaloguj")

    def test_parse_search_results_single(self) -> None:
        """Pojedynczy wynik wyszukiwania."""
        results = GusBirClient._parse_search_results(SAMPLE_SEARCH_RESULT)
        assert len(results) == 1
        assert results[0].name == "ACME Sp. z o.o."
        assert results[0].status == "active"

    def test_parse_search_results_inactive(self) -> None:
        """Nieaktywny NIP."""
        xml = SAMPLE_SEARCH_RESULT.replace("AKTYWNY", "ZAWIESZONY")
        results = GusBirClient._parse_search_results(xml)
        assert len(results) == 1
        assert results[0].status == "inactive"

    def test_parse_search_results_empty(self) -> None:
        """Pusty wynik."""
        results = GusBirClient._parse_search_results("")
        assert results == []

    def test_parse_full_report(self) -> None:
        """Parsowanie pelnego raportu."""
        result = GusBirClient._parse_full_report(SAMPLE_FULL_REPORT_RESULT)
        assert result is not None
        assert result.name == "ACME Sp. z o.o."
        assert result.legal_form == "Spolka z ograniczona odpowiedzialnoscia"
        assert result.status == "active"
        assert len(result.pkd_codes) == 2
        assert result.pkd_codes[0]["code"] == "62.01.Z"

    def test_parse_full_report_empty(self) -> None:
        """Pusty raport -> None."""
        result = GusBirClient._parse_full_report("")
        assert result is None

    def test_extract_result_with_sid_header(self) -> None:
        """Sprawdza ze _extract_result dziala gdy tag ma atrybuty."""
        # Symulacja odpowiedzi z sid w naglowku i namespace w taga Result
        xml = (
            '<soap:Envelope><soap:Body>'
            '<DaneSzukajResult xmlns:xsd="http://www.w3.org/2001/XMLSchema">'
            '<dane><Nazwa>Test</Nazwa></dane>'
            '</DaneSzukajResult>'
            '</soap:Body></soap:Envelope>'
        )
        result = GusBirClient._extract_result(xml, "DaneSzukaj")
        assert "<dane>" in result
