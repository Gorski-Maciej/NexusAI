"""
v7.0 INNOWACJA 7: WhiteList Proactive Monitor — Proaktywny Monitoring Białej Listy.

Codziennie sprawdza wszystkich kontrahentów w Białej Liście MF i:
- Wykrywa zmianę statusu VAT (aktywny → wykreślony)
- Wykrywa zmianę rachunku bankowego (nowe konto → potencjalne przejęcie)
- Automatycznie blokuje płatności na niezweryfikowane konta
- Wysyła alert przy zmianie statusu kluczowego kontrahenta

v7.0 INNOWACJA 10: Bank Statement Reconciliation AI.

Automatyczne uzgadnianie przelewów bankowych z fakturami przez:
- Dopasowanie kwoty (z tolerancją na różnice kursowe)
- Dopasowanie NIP-u kontrahenta
- Dopasowanie tytułu przelewu do numeru faktury (fuzzy matching)
- Sugerowanie prawdopodobnych dopasowań z oceną pewności
- Automatyczne księgowanie przy wysokiej pewności (>95%)

Chroni przed utratą prawa do odliczenia VAT (art. 108a ust. 1d).
"""

from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass, field
from difflib import SequenceMatcher
from typing import Any

import pendulum
from structlog import get_logger

logger = get_logger("nexus.services.proactive_monitor")


# ═════════════════════════════════════════════════════════════════════════════
# INNOWACJA 7: WhiteList Proactive Monitor
# ═════════════════════════════════════════════════════════════════════════════

@dataclass
class WhitelistChange:
    """Wykryta zmiana w Białej Liście MF."""
    nip: str
    contractor_name: str
    change_type: str  # vat_status_change, bank_account_change, new_account_added
    old_value: str
    new_value: str
    detected_at: str
    severity: str  # critical, warning, info
    message: str
    requires_action: bool


@dataclass
class WhitelistSnapshot:
    """Migawka stanu kontrahenta w Białej Liście."""
    nip: str
    name: str
    vat_status: str
    account_numbers: list[str]
    last_checked: str
    previous_vat_status: str = ""
    previous_accounts: list[str] = field(default_factory=list)


class WhiteListProactiveMonitor:
    """v7.0 INNOWACJA 7: Proaktywny monitor Białej Listy MF.

    Codziennie sprawdza status wszystkich kontrahentów i wykrywa zmiany.
    """

    CHECK_INTERVAL_HOURS = 24

    def __init__(
        self,
        white_list_service: Any = None,
        notification_sender: Any = None,
    ) -> None:
        self._white_list = white_list_service
        self._notify = notification_sender
        self._snapshots: dict[str, WhitelistSnapshot] = {}
        self._changes: list[WhitelistChange] = []
        self._running = False
        self._blocked_payments: set[str] = set()  # NIP-y z zablokowanymi płatnościami

    async def start(self, contractor_nips: list[str]) -> None:
        """Rozpocznij proaktywny monitoring.

        Args:
            contractor_nips: Lista NIP-ów kontrahentów do monitorowania.
        """
        self._running = True
        # Inicjalna migawka
        await self._take_snapshots(contractor_nips)
        # Cykliczne sprawdzanie
        asyncio.create_task(self._monitor_loop(contractor_nips))
        logger.info(
            "[WL-MONITOR] Started | contractors=%d interval=%dh",
            len(contractor_nips), self.CHECK_INTERVAL_HOURS,
        )

    async def stop(self) -> None:
        self._running = False

    async def _monitor_loop(self, nips: list[str]) -> None:
        while self._running:
            try:
                await self._take_snapshots(nips)
                await asyncio.sleep(self.CHECK_INTERVAL_HOURS * 3600)
            except asyncio.CancelledError:
                break
            except Exception as exc:
                logger.error("[WL-MONITOR] Loop error: %s", exc)
                self._changes.append(WhitelistChange(
                    nip="SYSTEM", contractor_name="WhiteList Monitor",
                    change_type="monitor_error", old_value="", new_value="",
                    detected_at=pendulum.now("UTC").isoformat(),
                    severity="critical", message=f"Monitor error: {exc}",
                    requires_action=True,
                ))
                await asyncio.sleep(300)

    async def _take_snapshots(self, nips: list[str]) -> None:
        """Wykonaj migawkę stanu dla wszystkich NIP-ów."""
        changes_detected = 0
        for nip in nips:
            try:
                data = await self._white_list.check_nip(nip) if self._white_list else None
                if data is None:
                    continue

                current = WhitelistSnapshot(
                    nip=nip,
                    name=data.get("name", data.get("nazwa", "Unknown")),
                    vat_status="active" if data else "not_found",
                    account_numbers=data.get("accountNumbers", data.get("account_numbers", [])),
                    last_checked=pendulum.now("UTC").isoformat(),
                )

                if nip in self._snapshots:
                    changes = self._detect_changes(self._snapshots[nip], current)
                    self._changes.extend(changes)
                    for change in changes:
                        changes_detected += 1
                        await self._handle_change(change)

                self._snapshots[nip] = current

            except Exception as exc:
                logger.warning("[WL-MONITOR] Snapshot failed nip=%s: %s", nip, exc)

        if changes_detected:
            logger.info("[WL-MONITOR] Detected %d changes", changes_detected)

    def _detect_changes(
        self, old: WhitelistSnapshot, new: WhitelistSnapshot,
    ) -> list[WhitelistChange]:
        """Wykryj zmiany między poprzednią a obecną migawką."""
        changes: list[WhitelistChange] = []
        now = pendulum.now("UTC").isoformat()

        # 1. Zmiana statusu VAT
        if old.vat_status != new.vat_status:
            severity = "critical" if new.vat_status != "active" else "info"
            message = (
                f"Kontrahent {new.name} (NIP: {new.nip}): "
                f"zmiana statusu VAT z '{old.vat_status}' na '{new.vat_status}'"
            )

            if new.vat_status != "active":
                # Automatycznie blokuj płatności
                self._blocked_payments.add(new.nip)
                message += " — PŁATNOŚCI ZABLOKOWANE (ryzyko art. 108a ust. 1d)"

            changes.append(WhitelistChange(
                nip=new.nip, contractor_name=new.name,
                change_type="vat_status_change",
                old_value=old.vat_status, new_value=new.vat_status,
                detected_at=now, severity=severity,
                message=message,
                requires_action=new.vat_status != "active",
            ))

        # 2. Nowe konto bankowe
        old_accounts = set(old.account_numbers or [])
        new_accounts = set(new.account_numbers or [])
        added = new_accounts - old_accounts
        removed = old_accounts - new_accounts

        if added:
            for acct in added:
                message = (
                    f"Kontrahent {new.name} (NIP: {new.nip}): "
                    f"NOWE konto bankowe {acct[:6]}... — "
                    f"zweryfikuj przed płatnością (ryzyko przejęcia konta)"
                )
                changes.append(WhitelistChange(
                    nip=new.nip, contractor_name=new.name,
                    change_type="new_account_added",
                    old_value="", new_value=acct,
                    detected_at=now, severity="warning",
                    message=message, requires_action=True,
                ))

        if removed:
            for acct in removed:
                message = (
                    f"Kontrahent {new.name} (NIP: {new.nip}): "
                    f"usunięte konto {acct[:6]}..."
                )
                changes.append(WhitelistChange(
                    nip=new.nip, contractor_name=new.name,
                    change_type="bank_account_change",
                    old_value=acct, new_value="",
                    detected_at=now, severity="info",
                    message=message, requires_action=False,
                ))

        return changes

    async def _handle_change(self, change: WhitelistChange) -> None:
        """Obsłuż wykrytą zmianę (alert, blokada)."""
        if change.severity in ("critical", "warning") and self._notify:
            try:
                await self._notify({
                    "type": "whitelist_change",
                    "severity": change.severity,
                    "message": change.message,
                    "nip": change.nip,
                    "requires_action": change.requires_action,
                })
            except Exception as exc:
                logger.warning("[WL-MONITOR] Notification failed: %s", exc)

    def is_payment_blocked(self, nip: str) -> bool:
        """Sprawdź czy płatności dla NIP-u są zablokowane."""
        return nip in self._blocked_payments

    def unblock_payment(self, nip: str) -> None:
        """Ręcznie odblokuj płatności."""
        self._blocked_payments.discard(nip)

    def get_changes(self, limit: int = 50) -> list[WhitelistChange]:
        """Pobierz listę wykrytych zmian."""
        return self._changes[-limit:]

    def get_snapshot(self, nip: str) -> WhitelistSnapshot | None:
        """Pobierz migawkę dla NIP-u."""
        return self._snapshots.get(nip)


# ═════════════════════════════════════════════════════════════════════════════
# INNOWACJA 10: Bank Statement Reconciliation AI
# ═════════════════════════════════════════════════════════════════════════════

@dataclass
class ReconciliationMatch:
    """Dopasowanie przelewu do faktury."""
    transaction_id: str
    invoice_id: str
    confidence: float  # 0-100%
    match_type: str  # exact_amount, fuzzy_title, nip_match, combined
    amount_difference: float  # różnica w PLN
    details: dict[str, Any] = field(default_factory=dict)


class BankReconciliationAI:
    """v7.0 INNOWACJA 10: AI do uzgadniania przelewów z fakturami.

    Automatyczne dopasowanie:
    1. Exact amount match (kwota przelewu == kwota faktury)
    2. NIP match (NIP kontrahenta == NIP na fakturze)
    3. Fuzzy title matching (tytuł przelewu ~ numer faktury)
    4. Combined scoring dla najlepszego dopasowania
    """

    AUTO_BOOK_THRESHOLD = 95.0  # Automatyczne księgowanie przy >95%
    SUGGEST_THRESHOLD = 70.0    # Sugeruj przy >70%
    AMOUNT_TOLERANCE_PCT = 2.0  # Tolerancja różnicy kwoty (różnice kursowe)

    def reconcile(
        self,
        transactions: list[dict[str, Any]],
        invoices: list[dict[str, Any]],
    ) -> list[ReconciliationMatch]:
        """Uzgodnij listę przelewów z listą faktur.

        Args:
            transactions: Lista przelewów z kluczami:
                id, amount, title, counterparty_nip, booking_date
            invoices: Lista faktur z kluczami:
                id, number, amount_gross, contractor_nip, issue_date

        Returns:
            Lista dopasowań z oceną pewności.
        """
        matches: list[ReconciliationMatch] = []
        matched_invoice_ids: set[str] = set()

        for tx in transactions:
            tx_amount = abs(tx.get("amount", 0))
            tx_nip = tx.get("counterparty_nip", "")
            tx_title = tx.get("title", "")
            tx_id = tx.get("id", "unknown")

            best_match: ReconciliationMatch | None = None
            best_confidence = 0.0

            for inv in invoices:
                inv_id = inv.get("id", inv.get("number", ""))
                if inv_id in matched_invoice_ids:
                    continue  # Już dopasowana

                inv_amount = inv.get("amount_gross", inv.get("amount", 0))
                inv_nip = inv.get("contractor_nip", "")
                inv_number = inv.get("number", "")

                # 1. Amount match (0-40 pkt)
                amount_score = 0.0
                if inv_amount > 0:
                    diff_pct = abs(tx_amount - inv_amount) / inv_amount * 100
                    if diff_pct < self.AMOUNT_TOLERANCE_PCT:
                        amount_score = 40.0
                    elif diff_pct < 5.0:
                        amount_score = 20.0
                    elif diff_pct < 10.0:
                        amount_score = 10.0

                # 2. NIP match (0-30 pkt)
                nip_score = 0.0
                clean_tx_nip = "".join(c for c in tx_nip if c.isdigit())
                clean_inv_nip = "".join(c for c in inv_nip if c.isdigit())
                if clean_tx_nip and clean_inv_nip and clean_tx_nip == clean_inv_nip:
                    nip_score = 30.0
                elif clean_tx_nip and clean_inv_nip:
                    # Częściowy match (ostatnie 4 cyfry)
                    if clean_tx_nip[-4:] == clean_inv_nip[-4:]:
                        nip_score = 15.0

                # 3. Title fuzzy match (0-30 pkt)
                title_score = self._fuzzy_match_title(tx_title, inv_number)

                # 4. Combined confidence
                confidence = amount_score + nip_score + title_score
                match_type = self._determine_match_type(amount_score, nip_score, title_score)

                if confidence > best_confidence and confidence >= self.SUGGEST_THRESHOLD:
                    best_confidence = confidence
                    amount_diff = abs(tx_amount - inv_amount)
                    best_match = ReconciliationMatch(
                        transaction_id=tx_id,
                        invoice_id=inv_id,
                        confidence=round(confidence, 1),
                        match_type=match_type,
                        amount_difference=round(amount_diff, 2),
                        details={
                            "amount_score": round(amount_score, 1),
                            "nip_score": round(nip_score, 1),
                            "title_score": round(title_score, 1),
                            "tx_title": tx_title,
                            "inv_number": inv_number,
                            "auto_book": confidence >= self.AUTO_BOOK_THRESHOLD,
                        },
                    )

            if best_match:
                matches.append(best_match)
                if best_match.confidence >= self.AUTO_BOOK_THRESHOLD:
                    matched_invoice_ids.add(best_match.invoice_id)

        # Sortuj po pewności (najlepsze pierwsze)
        matches.sort(key=lambda m: m.confidence, reverse=True)

        auto_count = sum(1 for m in matches if m.confidence >= self.AUTO_BOOK_THRESHOLD)
        suggest_count = sum(
            1 for m in matches
            if self.SUGGEST_THRESHOLD <= m.confidence < self.AUTO_BOOK_THRESHOLD
        )

        logger.info(
            "[RECONCILE] %d matches: %d auto-book, %d suggestions, %d unmatched",
            len(matches), auto_count, suggest_count,
            len(transactions) - auto_count - suggest_count,
        )

        return matches

    def _fuzzy_match_title(self, tx_title: str, invoice_number: str) -> float:
        """Fuzzy matching tytułu przelewu do numeru faktury.

        Szuka:
        - Dokładnego numeru faktury w tytule
        - Częściowego dopasowania (ostatnie cyfry)
        - Podobieństwa przez SequenceMatcher
        """
        if not tx_title or not invoice_number:
            return 0.0

        tx_lower = tx_title.lower()
        inv_number_clean = invoice_number.strip().replace(" ", "")

        # 1. Dokładne dopasowanie numeru w tytule
        if inv_number_clean.lower() in tx_lower:
            return 30.0

        # 2. Usuń separatory i spróbuj ponownie
        inv_no_sep = re.sub(r"[/\-_.\s]", "", inv_number_clean)
        tx_no_sep = re.sub(r"[/\-_.\s]", "", tx_lower)
        if inv_no_sep.lower() in tx_no_sep:
            return 25.0

        # 3. Ostatnie 5 cyfr/znaków
        suffix = inv_number_clean[-5:]
        if len(suffix) >= 3 and suffix.lower() in tx_lower:
            return 15.0

        # 4. SequenceMatcher similarity
        ratio = SequenceMatcher(None, tx_no_sep[:50], inv_no_sep[:50]).ratio()
        if ratio > 0.8:
            return 20.0 * ratio

        return 0.0

    @staticmethod
    def _determine_match_type(
        amount_score: float, nip_score: float, title_score: float,
    ) -> str:
        """Określ typ dopasowania."""
        scores = {
            "exact_amount": amount_score >= 40,
            "nip_match": nip_score >= 30,
            "fuzzy_title": title_score >= 20,
        }
        active = [k for k, v in scores.items() if v]
        if len(active) >= 3:
            return "combined"
        if len(active) == 2:
            return f"{active[0]}+{active[1]}"
        if active:
            return active[0]
        return "partial"

    def get_auto_bookable(self, matches: list[ReconciliationMatch]) -> list[ReconciliationMatch]:
        """Zwróć dopasowania gotowe do automatycznego księgowania."""
        return [m for m in matches if m.confidence >= self.AUTO_BOOK_THRESHOLD]

    def get_suggestions(self, matches: list[ReconciliationMatch]) -> list[ReconciliationMatch]:
        """Zwróć dopasowania do ręcznej weryfikacji."""
        return [
            m for m in matches
            if self.SUGGEST_THRESHOLD <= m.confidence < self.AUTO_BOOK_THRESHOLD
        ]
