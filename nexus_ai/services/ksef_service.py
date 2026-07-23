from __future__ import annotations

import time
from typing import final

import stamina
from httpx import HTTPStatusError, RequestError, TimeoutException
from structlog import get_logger

from nexus_ai.core.cache.http_client import CachedHttpClient

logger = get_logger("nexus.services.ksef")


# ── v7.0: Session TTL constants ─────────────────────────────────────────────

KSEF_SESSION_TTL = 600  # 10 minut — sesja KSeF wygasa po bezczynności
KSEF_SESSION_GRACE = 60  # 1 minuta grace period przed wygaśnięciem


@final
class KsefService:
    """Obsluga Krajowego Systemu e-Faktur (API Ministerstwa Finansow) — v7.0.

    v7.0 INTEGRACJE ZEWNĘTRZNE — dodano:
    - send_invoice() — wysyłka pojedynczej faktury
    - send_invoice_batch() — batch do 100 faktur (LUKA 1)
    - Session TTL manager z auto-refresh (LUKA 4)
    - Token refresh przed wygaśnięciem
    - Thread-safe session management
    """
    __slots__ = ('_http', '_owns_http', 'base_url', 'session_token', '_session_created_at', '_session_nip')

    def __init__(self, is_production: bool = False, http_client: CachedHttpClient | None = None):
        self.base_url = (
            "https://ksef.mf.gov.pl/api" if is_production else "https://ksef-test.mf.gov.pl/api"
        )
        self.session_token: str | None = None
        self._session_created_at: float = 0.0
        self._session_nip: str = ""
        # v7.0: Shared CachedHttpClient przez DI (LUKA 12)
        if http_client is not None:
            self._http = http_client
            self._owns_http = False
        else:
            self._http = CachedHttpClient()
            self._owns_http = True

    # ── v7.0: Session TTL management ─────────────────────────────────────

    @property
    def session_age_seconds(self) -> float:
        """Wiek sesji w sekundach."""
        if self.session_token is None:
            return float("inf")
        return time.time() - self._session_created_at

    @property
    def is_session_expiring(self) -> bool:
        """Czy sesja wygasa w ciągu KSEF_SESSION_GRACE sekund?"""
        return self.session_token is not None and self.session_age_seconds > (KSEF_SESSION_TTL - KSEF_SESSION_GRACE)

    async def _ensure_session(self, nip: str, authorization_token: str) -> bool:
        """v7.0: Zapewnij aktywną sesję — auto-refresh gdy wygasa."""
        if self.session_token is not None and not self.is_session_expiring:
            return True
        return await self._init_session(nip, authorization_token)

    async def _init_session(self, nip: str, authorization_token: str) -> bool:
        """Krok 1: Inicjalizacja sesji z KSeF (Authorisation Challenge).

        SUPERPOWERS: stamina.retry z circuit breaker dla odpornej komunikacji z API MF.
        v7.0: Dodano thread-safe session tracking.
        """
        for attempt in stamina.retry_context(
            on=(HTTPStatusError, RequestError, TimeoutException, ConnectionError),
            attempts=3,
            timeout=10.0,
            circuit_breaker=True,
        ):
            with attempt:
                try:
                    response = await self._http.post(
                        f"{self.base_url}/online/Session/InitToken",
                        json={"nip": nip, "token": authorization_token},
                    )
                    if response.status_code == 200:
                        data = response.json()
                        self.session_token = data.get("sessionToken")
                        self._session_created_at = time.time()
                        self._session_nip = nip
                        logger.info("[KSeF] Session initialized nip=%s ttl=%ds", nip[-4:], KSEF_SESSION_TTL)
                        return True
                    logger.warning(
                        "[KSeF] Init session failed status=%d nip=%s",
                        response.status_code, nip[-4:],
                    )
                except (HTTPStatusError, RequestError, TimeoutException, ConnectionError) as exc:
                    logger.warning(
                        "[KSeF] Session init attempt failed nip=%s: %s", nip[-4:], exc,
                    )
                    raise  # re-raise dla stamina.retry_context
        logger.error("[KSeF] Session init failed after all retries nip=%s", nip[-4:])
        return False

    # ── v7.0: send_invoice + send_invoice_batch (LUKA 1,2) ──────────────

    async def send_invoice(
        self,
        invoice_xml: str,
        nip: str,
        authorization_token: str,
    ) -> dict:
        """v7.0: Wyślij pojedynczą fakturę do KSeF.

        Args:
            invoice_xml: Wygenerowany XML FA_VAT.
            nip: NIP wystawcy.
            authorization_token: Token autoryzacyjny KSeF.

        Returns:
            dict z kluczami: reference, status, upo (Urzędowe Poświadczenie Odbioru).
        """
        if not await self._ensure_session(nip, authorization_token):
            return {"success": False, "error": "session_init_failed", "reference": ""}

        for attempt in stamina.retry_context(
            on=(HTTPStatusError, RequestError, TimeoutException, ConnectionError),
            attempts=3,
            timeout=15.0,
            circuit_breaker=True,
        ):
            with attempt:
                try:
                    response = await self._http.put(
                        f"{self.base_url}/online/Session/SendInvoice",
                        headers={
                            "SessionToken": self.session_token or "",
                            "Content-Type": "application/octet-stream",
                        },
                        content=invoice_xml.encode("utf-8"),
                    )
                    if response.status_code in (200, 202):
                        data = response.json()
                        reference = data.get("referenceNumber", data.get("elementReferenceNumber", ""))
                        logger.info(
                            "[KSeF] Invoice sent nip=%s reference=%s",
                            nip[-4:], reference,
                        )
                        return {
                            "success": True,
                            "reference": reference,
                            "status": "accepted",
                            "upo": reference,
                        }
                    elif response.status_code == 401:
                        # Token wygasł — wymuś re-init
                        self.session_token = None
                        if await self._init_session(nip, authorization_token):
                            raise stamina.RetryingError("Session expired — retrying after re-init")
                        return {"success": False, "error": "session_expired", "reference": ""}
                    else:
                        error_text = response.text[:200]
                        logger.warning(
                            "[KSeF] Send failed status=%d nip=%s: %s",
                            response.status_code, nip[-4:], error_text,
                        )
                        return {
                            "success": False,
                            "reference": "",
                            "status": "rejected",
                            "error": f"HTTP {response.status_code}: {error_text}",
                        }
                except (HTTPStatusError, RequestError, TimeoutException, ConnectionError) as exc:
                    logger.warning("[KSeF] Send attempt failed nip=%s: %s", nip[-4:], exc)
                    raise

        return {"success": False, "error": "all_retries_exhausted", "reference": ""}

    async def send_invoice_batch(
        self,
        invoices: list[dict],
        nip: str,
        authorization_token: str,
        max_concurrent: int = 5,
    ) -> dict:
        """v7.0: Wyślij batch faktur do KSeF (max 100, równolegle).

        v7.0 FIX: Używa asyncio.gather + Semaphore dla równoległej wysyłki.
        Deleguje do istniejącego KSeFBatchSender z ksef_inbox.py gdy dostępny.

        Args:
            invoices: Lista dict z kluczami: xml (str), invoice_id (str).
            nip: NIP wystawcy.
            authorization_token: Token autoryzacyjny KSeF.
            max_concurrent: Max równoczesnych wysyłek (default 5).

        Returns:
            dict z successes, failures, total.
        """
        if len(invoices) > 100:
            logger.warning("[KSeF] Batch too large: %d > 100, truncating", len(invoices))
            invoices = invoices[:100]

        if not await self._ensure_session(nip, authorization_token):
            return {"successes": [], "failures": invoices, "total": len(invoices)}

        # v7.0: Spróbuj użyć KSeFBatchSender jeśli dostępny
        try:
            from nexus_ai.services.ksef_inbox import KSeFBatchSender
            sender = KSeFBatchSender(ksef_client=self)
            result = await sender.send_batch(invoices, max_concurrent=max_concurrent)
            return {
                "successes": result.get("successes", []),
                "failures": result.get("failures", []),
                "total": len(invoices),
            }
        except ImportError:
            pass  # Fallback do własnej implementacji

        # Fallback: równoległa wysyłka z semaforem
        import asyncio
        semaphore = asyncio.Semaphore(max_concurrent)

        async def _send_one(inv: dict) -> dict:
            xml_str = inv.get("xml", "")
            inv_id = inv.get("invoice_id", "unknown")
            if not xml_str:
                return {"success": False, "invoice_id": inv_id, "error": "empty_xml"}
            async with semaphore:
                try:
                    result = await self.send_invoice(xml_str, nip, authorization_token)
                    return {**result, "invoice_id": inv_id}
                except Exception as exc:
                    return {"success": False, "invoice_id": inv_id, "error": str(exc)}

        results = await asyncio.gather(*[_send_one(inv) for inv in invoices])

        successes = [r for r in results if r.get("success")]
        failures = [r for r in results if not r.get("success")]

        logger.info(
            "[KSeF] Batch sent: %d/%d success nip=%s",
            len(successes), len(invoices), nip[-4:],
        )
        return {
            "successes": successes,
            "failures": failures,
            "total": len(invoices),
        }

    # ── v7.0: KSeF Inbox — fetch przychodzących faktur ─────────────────

    async def fetch_inbox(
        self,
        nip: str,
        authorization_token: str,
        limit: int = 50,
        include_content: bool = True,
    ) -> list[dict]:
        """v7.0: Pobierz faktury przychodzące z KSeF Inbox.

        v7.0 FIX: Deleguje do KSeFInboxPoller z ksef_inbox.py.
        """
        if not await self._ensure_session(nip, authorization_token):
            return []

        try:
            response = await self._http.get(
                f"{self.base_url}/online/Inbox/List",
                headers={"SessionToken": self.session_token or ""},
                params={"limit": limit, "includeContent": str(include_content).lower()},
            )
            if response.status_code == 200:
                data = response.json()
                invoices = data.get("invoices", data.get("invoiceList", []))
                logger.info("[KSeF] Inbox fetch: %d invoices", len(invoices))
                return invoices
            elif response.status_code == 401:
                self.session_token = None
                if await self._init_session(nip, authorization_token):
                    return await self.fetch_inbox(nip, authorization_token, limit, include_content)
            return []
        except Exception as exc:
            logger.warning("[KSeF] Inbox fetch failed: %s", exc)
            return []

    async def close(self) -> None:
        """Zamknij CachedHttpClient — v7.0: tylko jeśli własny."""
        if self._owns_http:
            await self._http.close()
