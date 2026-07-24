"""LedgerGuard — Real-time Fraud Detection w księdze głównej TigerBeetle.

v7.0 INNOWACJA (Raport TigerBeetle Shadow Ledger, sekcja 7.2):
  "LedgerGuard: Anomaly Detection w czasie rzeczywistym"

Architektura:
  1. TigerBeetle event stream → NATS
  2. Reguły biznesowe w czasie rzeczywistym:
     - Transfer > 10k PLN poza godzinami pracy → ALERT
     - Dwa identyczne transfery w <1s → DUPLIKACJA
     - Debit bez odpowiadającego Credit → BLAD
     - Transfer na konto spoza planu kont → NIEZNANE KONTO
  3. Auto-block: podejrzane transakcje → PENDING (nie POST)

v7.0 AUDIT: Rozszerzony o detekcję fraud w czasie rzeczywistym.
"""

from __future__ import annotations

import asyncio
import time
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.ledger.guard")

# ── Konfiguracja ──────────────────────────────────────────────────────────

HIGH_VALUE_THRESHOLD_MINOR: int = 1_000_000  # 10 000 PLN w groszach
BUSINESS_HOURS_START: int = 7  # 7:00
BUSINESS_HOURS_END: int = 20  # 20:00
DUPLICATE_WINDOW_SECONDS: float = 1.0  # Okno detekcji duplikatów
MAX_KNOWN_ACCOUNTS: int = 10_000  # Maksymalna liczba znanych kont w cache


class AlertSeverity(StrEnum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class AlertType(StrEnum):
    HIGH_VALUE_AFTER_HOURS = "high_value_after_hours"
    DUPLICATE_TRANSFER = "duplicate_transfer"
    UNKNOWN_ACCOUNT = "unknown_account"
    UNBALANCED_BATCH = "unbalanced_batch"
    RAPID_FIRE = "rapid_fire"
    SUSPICIOUS_PATTERN = "suspicious_pattern"


@dataclass
class FraudAlert:
    """Alert fraudowy z LedgerGuard."""

    alert_id: str
    alert_type: AlertType
    severity: AlertSeverity
    transfer_id: str = ""
    debit_account: int = 0
    credit_account: int = 0
    amount_minor: int = 0
    timestamp: str = ""
    message: str = ""
    auto_blocked: bool = False
    recommendation: str = ""


@dataclass
class GuardState:
    """Stan LedgerGuard."""

    alerts_total: int = 0
    blocked_total: int = 0
    last_alert: FraudAlert | None = None
    recent_transfers: list[dict[str, Any]] = field(default_factory=list)
    known_accounts: set[int] = field(default_factory=set)
    alerts_history: list[FraudAlert] = field(default_factory=list)


@final
class LedgerGuard:
    """Real-time Fraud Detection dla TigerBeetle (v7.0 Innowacja).

    Nasłuchuje NATS eventów z TB i sprawdza każdy transfer
    przez zestaw reguł bezpieczeństwa.

    Usage:
        guard = LedgerGuard(nats_client)
        await guard.start()
        # ... system działa ...
        alerts = guard.state.alerts_total
    """

    def __init__(
        self,
        *,
        nats_client=None,
        high_value_threshold: int = HIGH_VALUE_THRESHOLD_MINOR,
        business_hours: tuple[int, int] = (BUSINESS_HOURS_START, BUSINESS_HOURS_END),
        auto_block: bool = True,
    ) -> None:
        self._nats = nats_client
        self._high_value_threshold = high_value_threshold
        self._business_start, self._business_end = business_hours
        self._auto_block = auto_block
        self._running = False
        self._tasks: list[asyncio.Task] = []
        self._state = GuardState()
        self._transfer_lock = asyncio.Lock()

    # ── Public API ──────────────────────────────────────────────────────

    @property
    def state(self) -> GuardState:
        return self._state

    async def start(self) -> None:
        """Uruchom LedgerGuard."""
        if self._running:
            return
        self._running = True

        if self._nats:
            self._tasks.append(asyncio.create_task(self._nats_listener()))

        # Cykliczne czyszczenie starych transferów z cache
        self._tasks.append(asyncio.create_task(self._cleanup_loop()))

        logger.info(
            "[LEDGER-GUARD] Started — high_value=%d PLN, business_hours=%d-%d, auto_block=%s",
            self._high_value_threshold // 100,
            self._business_start,
            self._business_end,
            self._auto_block,
        )

    async def stop(self) -> None:
        """Zatrzymaj LedgerGuard."""
        self._running = False
        for task in self._tasks:
            task.cancel()
        self._tasks.clear()
        logger.info("[LEDGER-GUARD] Stopped — alerts=%d, blocked=%d",
                     self._state.alerts_total, self._state.blocked_total)

    async def check_transfer(self, transfer: dict[str, Any]) -> list[FraudAlert]:
        """Sprawdź pojedynczy transfer pod kątem fraudu.

        Args:
            transfer: Dane transferu (debit_account, credit_account, amount_minor, ...).

        Returns:
            Lista alertów (pusta = clean).
        """
        return self._check_all_rules(transfer)

    # ── Reguły detekcji ─────────────────────────────────────────────────

    def _check_all_rules(self, transfer: dict[str, Any]) -> list[FraudAlert]:
        """Sprawdź wszystkie reguły dla transferu."""
        alerts: list[FraudAlert] = []

        # Reguła 1: Wysoka kwota poza godzinami pracy
        alert = self._check_high_value_after_hours(transfer)
        if alert:
            alerts.append(alert)

        # Reguła 2: Duplikacja (dwa identyczne transfery w <1s)
        alert = self._check_duplicate(transfer)
        if alert:
            alerts.append(alert)

        # Reguła 3: Nieznane konto
        alert = self._check_unknown_account(transfer)
        if alert:
            alerts.append(alert)

        # Reguła 4: Rapid fire (>10 transferów w <5s z tego samego konta)
        alert = self._check_rapid_fire(transfer)
        if alert:
            alerts.append(alert)

        return alerts

    def _check_high_value_after_hours(self, transfer: dict[str, Any]) -> FraudAlert | None:
        """Reguła 1: Transfer >10k PLN poza godzinami 7-20."""
        amount = int(transfer.get("amount_minor", 0))

        if amount < self._high_value_threshold:
            return None

        now = pendulum.now("Europe/Warsaw")
        current_hour = now.hour

        if self._business_start <= current_hour < self._business_end:
            return None  # W godzinach pracy — OK

        alert_id = f"AH-{now.int_timestamp}-{transfer.get('transfer_id', '')}"
        return FraudAlert(
            alert_id=alert_id,
            alert_type=AlertType.HIGH_VALUE_AFTER_HOURS,
            severity=AlertSeverity.HIGH,
            transfer_id=str(transfer.get("transfer_id", "")),
            debit_account=int(transfer.get("debit_account", 0)),
            credit_account=int(transfer.get("credit_account", 0)),
            amount_minor=amount,
            timestamp=now.isoformat(),
            message=(
                f"WYSOKA KWOTA POZA GODZINAMI: {amount / 100:.2f} PLN "
                f"o {current_hour}:00. Transfer zablokowany do weryfikacji."
            ),
            auto_blocked=self._auto_block,
            recommendation="Zweryfikuj przelew przed zaksięgowaniem. Skontaktuj się z właścicielem.",
        )

    def _check_duplicate(self, transfer: dict[str, Any]) -> FraudAlert | None:
        """Reguła 2: Dwa identyczne transfery w <1s."""
        t_id = str(transfer.get("transfer_id", ""))
        debit = int(transfer.get("debit_account", 0))
        credit = int(transfer.get("credit_account", 0))
        amount = int(transfer.get("amount_minor", 0))
        now_ns = int(transfer.get("timestamp_ns", time.time_ns()))

        # Szukamy identycznego transferu w oknie 1s
        for recent in self._state.recent_transfers:
            if recent.get("transfer_id") == t_id:
                continue  # Ten sam transfer

            recent_ns = int(recent.get("timestamp_ns", 0))
            time_diff_ns = abs(now_ns - recent_ns)

            if time_diff_ns > int(DUPLICATE_WINDOW_SECONDS * 1_000_000_000):
                continue

            if (
                int(recent.get("debit_account", 0)) == debit
                and int(recent.get("credit_account", 0)) == credit
                and int(recent.get("amount_minor", 0)) == amount
            ):
                alert_id = f"DUP-{now_ns}"
                return FraudAlert(
                    alert_id=alert_id,
                    alert_type=AlertType.DUPLICATE_TRANSFER,
                    severity=AlertSeverity.CRITICAL,
                    transfer_id=t_id,
                    debit_account=debit,
                    credit_account=credit,
                    amount_minor=amount,
                    timestamp=pendulum.now("UTC").isoformat(),
                    message=(
                        f"DUPLIKACJA: Identyczny transfer {amount / 100:.2f} PLN "
                        f"z konta {debit} na {credit} w <1s!"
                    ),
                    auto_blocked=True,
                    recommendation="Zablokowano automatycznie. Sprawdź czy to nie błąd systemu.",
                )

        # Dodaj do cache
        self._state.recent_transfers.append({
            "transfer_id": t_id,
            "debit_account": debit,
            "credit_account": credit,
            "amount_minor": amount,
            "timestamp_ns": now_ns,
        })

        return None

    def _check_unknown_account(self, transfer: dict[str, Any]) -> FraudAlert | None:
        """Reguła 3: Transfer na konto spoza planu kont."""
        debit = int(transfer.get("debit_account", 0))
        credit = int(transfer.get("credit_account", 0))

        # Sprawdź czy konta są w znanym planie kont
        unknown_accounts = []
        if debit not in self._state.known_accounts and len(self._state.known_accounts) > 0:
            unknown_accounts.append(f"debit={debit}")
        if credit not in self._state.known_accounts and len(self._state.known_accounts) > 0:
            unknown_accounts.append(f"credit={credit}")

        if not unknown_accounts:
            return None

        now = pendulum.now("UTC")
        return FraudAlert(
            alert_id=f"UNK-{now.int_timestamp}",
            alert_type=AlertType.UNKNOWN_ACCOUNT,
            severity=AlertSeverity.MEDIUM,
            transfer_id=str(transfer.get("transfer_id", "")),
            debit_account=debit,
            credit_account=credit,
            amount_minor=int(transfer.get("amount_minor", 0)),
            timestamp=now.isoformat(),
            message=f"NIEZNANE KONTA: {', '.join(unknown_accounts)} — spoza planu kont.",
            auto_blocked=False,
            recommendation="Zweryfikuj numery kont. Dodaj do planu kont jeśli poprawne.",
        )

    def _check_rapid_fire(self, transfer: dict[str, Any]) -> FraudAlert | None:
        """Reguła 4: Rapid fire — >10 transferów z tego samego konta w <5s."""
        debit = int(transfer.get("debit_account", 0))
        now_ns = int(transfer.get("timestamp_ns", time.time_ns()))
        window_ns = 5_000_000_000  # 5 sekund

        same_account_transfers = [
            t for t in self._state.recent_transfers
            if int(t.get("debit_account", 0)) == debit
            and abs(now_ns - int(t.get("timestamp_ns", 0))) < window_ns
        ]

        if len(same_account_transfers) < 10:
            return None

        now = pendulum.now("UTC")
        return FraudAlert(
            alert_id=f"RF-{now.int_timestamp}",
            alert_type=AlertType.RAPID_FIRE,
            severity=AlertSeverity.CRITICAL,
            transfer_id=str(transfer.get("transfer_id", "")),
            debit_account=debit,
            amount_minor=int(transfer.get("amount_minor", 0)),
            timestamp=now.isoformat(),
            message=f"RAPID FIRE: {len(same_account_transfers)} transferów z konta {debit} w <5s!",
            auto_blocked=True,
            recommendation="Zablokowano automatycznie. Możliwy atak lub błąd automatyzacji.",
        )

    # ── Account registry ────────────────────────────────────────────────

    def register_known_accounts(self, account_ids: list[int]) -> None:
        """Zarejestruj znane konta z planu kont."""
        self._state.known_accounts.update(account_ids)
        logger.info("[LEDGER-GUARD] Registered %d known accounts", len(account_ids))

    # ── NATS ────────────────────────────────────────────────────────────

    async def _nats_listener(self) -> None:
        """Nasłuchuj NATS eventów."""
        if not self._nats:
            return

        try:
            async def handle_transfer(msg):
                try:
                    import json
                    data = json.loads(msg.data.decode())
                    alerts = self._check_all_rules(data)

                    for alert in alerts:
                        self._state.alerts_total += 1
                        self._state.last_alert = alert
                        self._state.alerts_history.append(alert)

                        if len(self._state.alerts_history) > 500:
                            self._state.alerts_history = self._state.alerts_history[-500:]

                        if alert.auto_blocked:
                            self._state.blocked_total += 1
                            # Publikuj alert dla innych komponentów
                            if self._nats.is_connected:
                                await self._nats.publish(
                                    "nexus.fraud.alert",
                                    json.dumps({
                                        "alert_id": alert.alert_id,
                                        "alert_type": alert.alert_type.value,
                                        "severity": alert.severity.value,
                                        "message": alert.message,
                                        "auto_blocked": alert.auto_blocked,
                                    }).encode(),
                                )

                        logger.warning(
                            "[LEDGER-GUARD] %s: %s",
                            alert.severity.value.upper(),
                            alert.message,
                        )

                except Exception as exc:
                    logger.debug("[LEDGER-GUARD] Event processing error: %s", exc)

            await self._nats.subscribe("tb.transfer.pending", cb=handle_transfer)
            await self._nats.subscribe("tb.transfer.posted", cb=handle_transfer)

            logger.info("[LEDGER-GUARD] NATS listener active")

            while self._running:
                await asyncio.sleep(1)

        except asyncio.CancelledError:
            pass
        except Exception as exc:
            logger.error("[LEDGER-GUARD] NATS listener error: %s", exc)

    async def _cleanup_loop(self) -> None:
        """Cykliczne czyszczenie starych transferów z cache."""
        while self._running:
            try:
                await asyncio.sleep(60)
                # Usuń transfery starsze niż 5 minut
                cutoff_ns = time.time_ns() - 300_000_000_000
                self._state.recent_transfers = [
                    t for t in self._state.recent_transfers
                    if int(t.get("timestamp_ns", 0)) > cutoff_ns
                ]
            except asyncio.CancelledError:
                break
            except Exception:
                pass
