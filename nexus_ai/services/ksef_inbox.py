"""KSeF Inbox + Batch Send — rozszerzenie AgentDataExtraction.

Dodaje funkcjonalności zidentyfikowane w Raporcie v7.0:
- KSeF Inbox: odbieranie faktur przychodzących z KSeF API
- Batch Send: wysyłka do 100 faktur jednocześnie
- Idempotentność przez invoice_id + hash danych
"""

from __future__ import annotations

import asyncio
import hashlib
import json
import pendulum
from typing import Any

from msgspec import json as msgspec_json
from structlog import get_logger

logger = get_logger("nexus.services.ksef_inbox")


# ═════════════════════════════════════════════════════════════════════════
# KSeF Inbox — Odbieranie faktur przychodzących
# ═════════════════════════════════════════════════════════════════════════


class KSeFInboxPoller:
    """Poller KSeF Inbox — cyklicznie sprawdza skrzynkę KSeF.

    GENIALNY POMYSŁ — pełna automatyzacja KSeF:
    - Automatyczne pobieranie faktur przychodzących
    - Deduplikacja przez invoice_id + hash
    - Wysyłka przez NATS do pipeline'u agentów
    """

    # Konfiguracja
    POLL_INTERVAL_SECONDS = 3600  # 1 godzina
    MAX_INVOICES_PER_POLL = 50
    BATCH_SIZE = 10  # Przetwarzanie w batchach po 10

    def __init__(
        self,
        ksef_client: Any = None,
        nats_publisher: Any = None,
        orchestrator: Any = None,
        config: dict[str, Any] | None = None,
    ) -> None:
        self._client = ksef_client
        self._nats = nats_publisher
        self._orchestrator = orchestrator
        self._config = config or {}
        self._running = False
        self._processed_ids: set[str] = set()
        self._stats: dict[str, int] = {
            "total_polled": 0,
            "total_downloaded": 0,
            "total_processed": 0,
            "duplicates": 0,
            "errors": 0,
        }

    async def start(self) -> None:
        """Uruchom poller KSeF Inbox."""
        self._running = True
        asyncio.create_task(self._poll_loop())
        logger.info("[KSEF-INBOX] Poller started | interval=%ds", self.POLL_INTERVAL_SECONDS)

    async def stop(self) -> None:
        self._running = False

    async def _poll_loop(self) -> None:
        """Główna pętla — co godzinę sprawdza KSeF Inbox."""
        while self._running:
            try:
                await self._poll_inbox()
                await asyncio.sleep(self.POLL_INTERVAL_SECONDS)
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("[KSEF-INBOX] Poll error: %s", exc)
                self._stats["errors"] += 1
                await asyncio.sleep(60)  # Retry za minutę

    async def _poll_inbox(self) -> list[dict[str, Any]]:
        """Sprawdź KSeF Inbox — pobierz listę nowych faktur."""
        self._stats["total_polled"] += 1

        if not self._client or not hasattr(self._client, 'fetch_inbox'):
            logger.debug("[KSEF-INBOX] No KSeF client available")
            return []

        try:
            invoices = await self._client.fetch_inbox(
                limit=self.MAX_INVOICES_PER_POLL,
                include_content=True,
            )
            logger.info("[KSEF-INBOX] Found %d invoices", len(invoices))

            new_invoices = []
            for inv in invoices:
                inv_id = inv.get("invoice_id", "")
                inv_hash = self._hash_invoice(inv)

                # Deduplikacja
                if f"{inv_id}:{inv_hash}" in self._processed_ids:
                    self._stats["duplicates"] += 1
                    continue

                self._processed_ids.add(f"{inv_id}:{inv_hash}")
                new_invoices.append(inv)

            self._stats["total_downloaded"] += len(new_invoices)

            # Przetwarzaj w batchach
            for i in range(0, len(new_invoices), self.BATCH_SIZE):
                batch = new_invoices[i:i + self.BATCH_SIZE]
                await self._process_batch(batch)

            return new_invoices

        except Exception as exc:
            logger.error("[KSEF-INBOX] Fetch failed: %s", exc)
            self._stats["errors"] += 1
            return []

    async def _process_batch(self, invoices: list[dict[str, Any]]) -> None:
        """Przetwórz batch faktur — wyślij do pipeline'u agentów."""
        tasks = []
        for inv in invoices:
            if self._orchestrator and hasattr(self._orchestrator, 'process_invoice'):
                tasks.append(self._orchestrator.process_invoice({
                    "invoice_id": inv.get("invoice_id", "unknown"),
                    "file_type": "xml",
                    "source": "ksef_inbox",
                    **inv.get("extracted_data", {}),
                }))
            elif self._nats and hasattr(self._nats, 'publish'):
                tasks.append(self._nats.publish(
                    "agent.invoice.received",
                    msgspec_json.encode(inv).decode(),
                ))

        if tasks:
            results = await asyncio.gather(*tasks, return_exceptions=True)
            for r in results:
                if isinstance(r, Exception):
                    self._stats["errors"] += 1
                    logger.debug("[KSEF-INBOX] Process error: %s", r)
                else:
                    self._stats["total_processed"] += 1

    @staticmethod
    def _hash_invoice(invoice: dict[str, Any]) -> str:
        """Wygeneruj hash faktury do deduplikacji."""
        data = json.dumps({
            "invoice_id": invoice.get("invoice_id", ""),
            "nip": invoice.get("nip", ""),
            "amount_gross": invoice.get("amount_gross", 0),
            "date": invoice.get("date", ""),
        }, sort_keys=True)
        return hashlib.sha256(data.encode()).hexdigest()[:16]

    def is_idempotent(self, invoice_id: str, invoice_hash: str) -> bool:
        """Sprawdź czy faktura była już przetworzona."""
        return f"{invoice_id}:{invoice_hash}" in self._processed_ids

    # Stats
    def get_stats(self) -> dict[str, Any]:
        return dict(self._stats)


# ═════════════════════════════════════════════════════════════════════════
# KSeF Batch Send — Wysyłka do 100 faktur jednocześnie
# ═════════════════════════════════════════════════════════════════════════


class KSeFBatchSender:
    """Wysyłka batchowa faktur do KSeF — do 100 faktur jednocześnie.

    RAPORT v7.0 Rekomendacja:
    AgentDataExtraction potrzebuje batch send (do 100 faktur jednocześnie).
    """

    MAX_BATCH_SIZE = 100
    CONCURRENT_SENDS = 5  # Max 5 równoczesnych wysyłek

    def __init__(self, ksef_client: Any = None) -> None:
        self._client = ksef_client
        self._stats: dict[str, int] = {
            "total_sent": 0,
            "successful": 0,
            "failed": 0,
            "batches_processed": 0,
        }
        self._failed_invoices: list[dict[str, Any]] = []

    async def send_batch(
        self,
        invoices: list[dict[str, Any]],
        max_concurrent: int = CONCURRENT_SENDS,
    ) -> dict[str, Any]:
        """Wyślij batch faktur do KSeF.

        Args:
            invoices: Lista faktur do wysłania (max 100).
            max_concurrent: Maksymalna liczba równoczesnych wysyłek.

        Returns:
            Wynik wysyłki z listą successes i failures.
        """
        if len(invoices) > self.MAX_BATCH_SIZE:
            logger.warning(
                "[KSEF-BATCH] Batch too large: %d > %d, truncating",
                len(invoices), self.MAX_BATCH_SIZE,
            )
            invoices = invoices[:self.MAX_BATCH_SIZE]

        self._stats["batches_processed"] += 1
        self._stats["total_sent"] += len(invoices)

        semaphore = asyncio.Semaphore(max_concurrent)

        async def send_one(invoice: dict[str, Any]) -> dict[str, Any]:
            async with semaphore:
                return await self._send_single(invoice)

        tasks = [send_one(inv) for inv in invoices]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        successes: list[dict[str, Any]] = []
        failures: list[dict[str, Any]] = []

        for i, result in enumerate(results):
            if isinstance(result, Exception):
                failures.append({
                    "index": i,
                    "invoice_id": invoices[i].get("invoice_id", "unknown"),
                    "error": str(result),
                })
                self._stats["failed"] += 1
            elif result.get("success"):
                successes.append(result)
                self._stats["successful"] += 1
            else:
                failures.append(result)
                self._stats["failed"] += 1

        if failures:
            self._failed_invoices.extend(failures)
            logger.warning(
                "[KSEF-BATCH] Batch sent: %d/%d success (batch #%d)",
                len(successes), len(invoices), self._stats["batches_processed"],
            )
        else:
            logger.info(
                "[KSEF-BATCH] Batch sent: %d/%d all success (batch #%d)",
                len(successes), len(invoices), self._stats["batches_processed"],
            )

        return {
            "success_count": len(successes),
            "failure_count": len(failures),
            "successes": successes,
            "failures": failures[:10],  # Max 10 w odpowiedzi
        }

    async def _send_single(self, invoice: dict[str, Any]) -> dict[str, Any]:
        """Wyślij pojedynczą fakturę do KSeF z retry."""
        max_retries = 3
        for attempt in range(max_retries):
            try:
                if self._client and hasattr(self._client, 'send_invoice'):
                    result = await self._client.send_invoice(invoice)
                    return {
                        "success": True,
                        "invoice_id": invoice.get("invoice_id", ""),
                        "ksef_reference": result.get("reference", ""),
                        "attempt": attempt + 1,
                    }
                else:
                    return {
                        "success": False,
                        "invoice_id": invoice.get("invoice_id", ""),
                        "error": "no_ksef_client",
                    }
            except Exception as exc:
                if attempt < max_retries - 1:
                    await asyncio.sleep(2 ** attempt)  # Exponential backoff
                else:
                    return {
                        "success": False,
                        "invoice_id": invoice.get("invoice_id", ""),
                        "error": str(exc),
                        "attempts": max_retries,
                    }

    def retry_failed(self) -> dict[str, Any]:
        """Pobierz listę nieudanych wysyłek do ponowienia."""
        failed = list(self._failed_invoices)
        self._failed_invoices.clear()
        return {"failed_count": len(failed), "invoices": failed}

    def get_stats(self) -> dict[str, Any]:
        return {
            **self._stats,
            "pending_retries": len(self._failed_invoices),
            "success_rate_pct": round(
                self._stats["successful"] / max(self._stats["total_sent"], 1) * 100, 1
            ),
        }


# ═════════════════════════════════════════════════════════════════════════
# Process Invoice Idempotency — Hash-based deduplication
# ═════════════════════════════════════════════════════════════════════════


class InvoiceIdempotencyGuard:
    """Strażnik idempotentności process_invoice().

    RAPORT v7.0 Rekomendacja #4:
    Dodaj idempotentność na poziomie process_invoice()
    przez invoice_id + hash danych faktury.
    """

    def __init__(self, max_cache_size: int = 10000) -> None:
        self._processed: dict[str, dict[str, Any]] = {}
        self._max_size = max_cache_size

    def is_duplicate(self, invoice_id: str, invoice_data: dict[str, Any]) -> bool:
        """Sprawdź czy faktura była już przetworzona."""
        data_hash = self._hash_data(invoice_data)
        key = f"{invoice_id}:{data_hash}"
        return key in self._processed

    def mark_processed(
        self,
        invoice_id: str,
        invoice_data: dict[str, Any],
        decision: Any,
    ) -> None:
        """Oznacz fakturę jako przetworzoną z wynikiem decyzji."""
        data_hash = self._hash_data(invoice_data)
        key = f"{invoice_id}:{data_hash}"
        self._processed[key] = {
            "decision_id": getattr(decision, 'decision_id', 'unknown'),
            "status": getattr(decision.verdict, 'status', 'unknown') if hasattr(decision, 'verdict') else 'unknown',
            "processed_at": pendulum.now("UTC").isoformat(),
        }

        # Ogranicz rozmiar cache
        if len(self._processed) > self._max_size:
            # Usuń najstarsze wpisy
            excess = len(self._processed) - self._max_size
            for key in list(self._processed.keys())[:excess]:
                del self._processed[key]

    def get_cached_decision(self, invoice_id: str, invoice_data: dict[str, Any]) -> dict[str, Any] | None:
        """Pobierz zcache'owaną decyzję."""
        data_hash = self._hash_data(invoice_data)
        key = f"{invoice_id}:{data_hash}"
        return self._processed.get(key)

    @staticmethod
    def _hash_data(data: dict[str, Any]) -> str:
        """Wygeneruj hash danych faktury."""
        canonical = json.dumps({
            k: data.get(k)
            for k in sorted(data.keys())
            if k not in ("timestamp", "request_id", "trace_id")
        }, sort_keys=True, default=str)
        return hashlib.sha256(canonical.encode()).hexdigest()[:16]

    @property
    def processed_count(self) -> int:
        return len(self._processed)
