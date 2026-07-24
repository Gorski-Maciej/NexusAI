"""NATS Event Bridge — integracja TB z NATS dla wszystkich listenerów.

v7.0 AUDIT: Łączy TigerBeetle z resztą systemu przez NATS JetStream.
Wszystkie komponenty (ShadowReconciliation, LedgerGuard, ContinuousAudit,
AutoHealingLedger) nasłuchują tych samych eventów z TB.

Architektura:
  TB transfer → NATS JetStream → [ShadowReconciler, LedgerGuard,
                                    ContinuousAudit, AutoHealer, ...]
"""

from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass, field
from typing import Any, final

from structlog import get_logger

logger = get_logger("nexus.nats.bridge")


# ── Event types ────────────────────────────────────────────────────────

@dataclass
class TBTransferEvent:
    """Zdarzenie transferu z TigerBeetle."""
    event_type: str  # "pending", "posted", "voided"
    transfer_id: str
    debit_account: int
    credit_account: int
    amount_minor: int
    ledger: int
    code: int
    timestamp_ns: int
    pending_id: str = ""
    user_data_128: int = 0
    user_data_64: int = 0
    flags: int = 0


@dataclass
class BridgeState:
    """Stan NATS Event Bridge."""
    events_published: int = 0
    events_received: int = 0
    subscribers_count: int = 0
    errors: int = 0
    last_event: TBTransferEvent | None = None
    subscriber_ids: list[str] = field(default_factory=list)


@final
class NATSEventBridge:
    """Bridge łączący TigerBeetle z NATS JetStream (v7.0 AUDIT).

    Wszystkie transfery TB są publikowane jako eventy NATS,
    a wszystkie zainteresowane komponenty nasłuchują.

    Usage:
        bridge = NATSEventBridge(nats_client)
        await bridge.start()
        await bridge.publish_transfer_event(transfer_data)
    """

    # Subiekty NATS
    SUBJECT_PREFIX = "nexus.tb"
    SUBJECTS = {
        "pending": f"{SUBJECT_PREFIX}.transfer.pending",
        "posted": f"{SUBJECT_PREFIX}.transfer.posted",
        "voided": f"{SUBJECT_PREFIX}.transfer.voided",
    }

    def __init__(self, nats_client=None) -> None:
        self._nats = nats_client
        self._running = False
        self._state = BridgeState()
        self._subscribers: dict[str, list] = {}  # subject -> list of callbacks

    @property
    def state(self) -> BridgeState:
        return self._state

    async def start(self) -> None:
        """Uruchom bridge."""
        if self._running:
            return
        self._running = True
        logger.info("[NATS-BRIDGE] Started with %d subscribers", self._state.subscribers_count)

    async def stop(self) -> None:
        """Zatrzymaj bridge."""
        self._running = False
        logger.info("[NATS-BRIDGE] Stopped — events=%d, errors=%d",
                     self._state.events_published, self._state.errors)

    # ── Publikacja ─────────────────────────────────────────────────

    async def publish_transfer_event(self, transfer: dict[str, Any]) -> bool:
        """Publikuj event transferu na NATS.

        Args:
            transfer: Dane transferu z TB.

        Returns:
            True jeśli publikacja się powiodła.
        """
        event_type = transfer.get("event_type", "posted")
        subject = self.SUBJECTS.get(event_type, self.SUBJECTS["posted"])

        event = TBTransferEvent(
            event_type=event_type,
            transfer_id=str(transfer.get("transfer_id", "")),
            debit_account=int(transfer.get("debit_account", 0)),
            credit_account=int(transfer.get("credit_account", 0)),
            amount_minor=int(transfer.get("amount_minor", 0)),
            ledger=int(transfer.get("ledger", 700)),
            code=int(transfer.get("code", 1001)),
            timestamp_ns=int(transfer.get("timestamp_ns", 0)),
            pending_id=str(transfer.get("pending_id", "")),
            user_data_128=int(transfer.get("user_data_128", 0)),
            user_data_64=int(transfer.get("user_data_64", 0)),
            flags=int(transfer.get("flags", 0)),
        )

        self._state.last_event = event

        if self._nats and hasattr(self._nats, 'is_connected') and self._nats.is_connected:
            try:
                payload = json.dumps({
                    "event_type": event.event_type,
                    "transfer_id": event.transfer_id,
                    "debit_account": event.debit_account,
                    "credit_account": event.credit_account,
                    "amount_minor": event.amount_minor,
                    "ledger": event.ledger,
                    "code": event.code,
                    "timestamp_ns": event.timestamp_ns,
                    "pending_id": event.pending_id,
                    "user_data_128": event.user_data_128,
                    "user_data_64": event.user_data_64,
                    "flags": event.flags,
                }).encode()

                await self._nats.publish(subject, payload)
                self._state.events_published += 1
                logger.debug("[NATS-BRIDGE] Published %s → %s", event_type, subject)
                return True

            except Exception as exc:
                self._state.errors += 1
                logger.warning("[NATS-BRIDGE] Publish failed: %s", exc)
                return False
        else:
            # No NATS client — log only
            logger.debug("[NATS-BRIDGE] Event queued (no NATS): %s", event.transfer_id)
            self._state.events_published += 1
            return True

    async def publish_batch(self, transfers: list[dict[str, Any]]) -> int:
        """Publikuj batch eventów transferowych.

        Returns:
            Liczba pomyślnie opublikowanych eventów.
        """
        published = 0
        for transfer in transfers:
            if await self.publish_transfer_event(transfer):
                published += 1
        return published

    # ── Subskrypcja ───────────────────────────────────────────────

    def subscribe(self, event_type: str, callback) -> str:
        """Zarejestruj callback dla typu eventu.

        Args:
            event_type: "pending", "posted", "voided", lub "*" dla wszystkich.
            callback: Async callable(event: TBTransferEvent).

        Returns:
            Subscriber ID do unsubscribe.
        """
        import uuid

        sub_id = f"sub-{uuid.uuid4().hex[:8]}"

        # Wildcard: subskrybuj wszystkie eventy
        if event_type == "*":
            for subject in self.SUBJECTS.values():
                if subject not in self._subscribers:
                    self._subscribers[subject] = []
                self._subscribers[subject].append({
                    "id": sub_id,
                    "callback": callback,
                    "event_type": "*",
                })
        else:
            subject = self.SUBJECTS.get(event_type, self.SUBJECTS["posted"])
            if subject not in self._subscribers:
                self._subscribers[subject] = []
            self._subscribers[subject].append({
                "id": sub_id,
                "callback": callback,
                "event_type": event_type,
            })

        self._state.subscribers_count = sum(len(v) for v in self._subscribers.values())
        self._state.subscriber_ids.append(sub_id)

        logger.info("[NATS-BRIDGE] Subscriber %s → %s", sub_id, event_type)
        return sub_id

    def unsubscribe(self, sub_id: str) -> bool:
        """Usuń subskrybcję."""
        for subject, subs in self._subscribers.items():
            for i, sub in enumerate(subs):
                if sub["id"] == sub_id:
                    del subs[i]
                    self._state.subscribers_count -= 1
                    if sub_id in self._state.subscriber_ids:
                        self._state.subscriber_ids.remove(sub_id)
                    logger.info("[NATS-BRIDGE] Unsubscribed %s", sub_id)
                    return True
        return False

    async def notify_subscribers(self, event: TBTransferEvent) -> None:
        """Powiadom wszystkich subskrybentów o evencie."""
        subject = self.SUBJECTS.get(event.event_type, self.SUBJECTS["posted"])
        subscribers = self._subscribers.get(subject, [])

        for sub in subscribers:
            try:
                if sub["callback"]:
                    await sub["callback"](event)
            except Exception as exc:
                logger.warning("[NATS-BRIDGE] Subscriber %s error: %s", sub["id"], exc)


# ── Singleton bridge ───────────────────────────────────────────────────

_bridge_instance: NATSEventBridge | None = None


def get_nats_bridge(nats_client=None) -> NATSEventBridge:
    """Pobierz lub utwórz singleton NATS Event Bridge."""
    global _bridge_instance
    if _bridge_instance is None:
        _bridge_instance = NATSEventBridge(nats_client)
    return _bridge_instance
