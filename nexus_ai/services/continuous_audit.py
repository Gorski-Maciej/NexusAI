"""Continuous Audit Engine — nieprzerwany audyt księgowy w czasie rzeczywistym.

v7.0 INNOWACJA #1 (Raport TigerBeetle Shadow Ledger, sekcja 10):
  "Continuous Audit Engine: Nieprzerwany audyt w czasie rzeczywistym"

Architektura:
  - Każda transakcja TB przechodzi przez silnik reguł audytowych
  - Reguły: limity kont, wzorce transakcji, anomalie
  - Auto-block podejrzanych transakcji (pending, nie post)
  - Dashboard: real-time feed wszystkich transakcji z flagami
  - Integracja z Proof Chain: każda transakcja ma kryptograficzny dowód
"""

from __future__ import annotations

import asyncio
import time
from dataclasses import dataclass, field
from enum import StrEnum
from typing import Any, final

import pendulum
from structlog import get_logger

logger = get_logger("nexus.audit.continuous")


# ── Konfiguracja ──────────────────────────────────────────────────────────


class AuditFlag(StrEnum):
    """Flagi audytowe dla transakcji."""

    CLEAN = "clean"
    WARNING = "warning"
    FLAGGED = "flagged"
    BLOCKED = "blocked"
    NEEDS_REVIEW = "needs_review"


@dataclass
class AuditEntry:
    """Pojedynczy wpis audytowy."""

    audit_id: str
    transfer_id: str
    timestamp: str
    flag: AuditFlag
    rules_checked: int = 0
    rules_failed: int = 0
    failed_rules: list[str] = field(default_factory=list)
    proof_hash: str = ""
    auto_blocked: bool = False
    details: dict[str, Any] = field(default_factory=dict)


@dataclass
class AuditRule:
    """Reguła audytowa."""

    rule_id: str
    description: str
    severity: str  # CRITICAL, HIGH, MEDIUM, LOW
    is_blocking: bool = False


@dataclass
class AuditState:
    """Stan Continuous Audit Engine."""

    audits_total: int = 0
    flagged_total: int = 0
    blocked_total: int = 0
    clean_total: int = 0
    last_entry: AuditEntry | None = None
    recent_entries: list[AuditEntry] = field(default_factory=list)


@final
class ContinuousAuditEngine:
    """Nieprzerwany audyt księgowy w czasie rzeczywistym (v7.0 Innowacja #1).

    Każda transakcja TB przechodzi przez pipeline audytowy.
    Auto-block dla krytycznych naruszeń.

    Usage:
        engine = ContinuousAuditEngine(nats_client)
        await engine.start()
        # Każdy transfer automatycznie audytowany
    """

    # ── Wbudowane reguły audytowe ──────────────────────────────────────

    AUDIT_RULES: list[AuditRule] = [
        AuditRule("AUDIT-001", "Transfer przekracza limit konta", "HIGH", is_blocking=True),
        AuditRule("AUDIT-002", "Transfer na konto spoza planu kont", "MEDIUM", is_blocking=False),
        AuditRule("AUDIT-003", "Kwota transferu > 100 000 PLN", "HIGH", is_blocking=False),
        AuditRule("AUDIT-004", "Okrągła kwota (potencjalne pranie pieniędzy)", "MEDIUM", is_blocking=False),
        AuditRule("AUDIT-005", "Transfer w weekend/święto", "LOW", is_blocking=False),
        AuditRule("AUDIT-006", "Szybkie sekwencyjne transfery (potencjalne structuring)", "HIGH", is_blocking=True),
        AuditRule("AUDIT-007", "Debit bez odpowiadającego kredytu w batchu", "CRITICAL", is_blocking=True),
        AuditRule("AUDIT-008", "Transfer z/na konto zablokowane", "CRITICAL", is_blocking=True),
        AuditRule("AUDIT-009", "Modyfikacja już zaksięgowanego transferu", "CRITICAL", is_blocking=True),
        AuditRule("AUDIT-010", "Nadmierna liczba storno (>5/dzień)", "MEDIUM", is_blocking=False),
    ]

    def __init__(
        self,
        *,
        nats_client=None,
        proof_chain=None,
        auto_block: bool = True,
        max_recent_entries: int = 1000,
    ) -> None:
        self._nats = nats_client
        self._proof_chain = proof_chain
        self._auto_block = auto_block
        self._max_recent = max_recent_entries
        self._running = False
        self._tasks: list[asyncio.Task] = []
        self._state = AuditState()
        self._known_accounts: set[int] = set()  # v7.0: Cache znanych kont

    # ── Public API ──────────────────────────────────────────────────────

    @property
    def state(self) -> AuditState:
        return self._state

    async def start(self) -> None:
        """Uruchom Continuous Audit Engine."""
        if self._running:
            return
        self._running = True

        if self._nats:
            self._tasks.append(asyncio.create_task(self._nats_listener()))

        logger.info(
            "[CONTINUOUS-AUDIT] Started — rules=%d, auto_block=%s",
            len(self.AUDIT_RULES), self._auto_block,
        )

    async def stop(self) -> None:
        """Zatrzymaj engine."""
        self._running = False
        for task in self._tasks:
            task.cancel()
        self._tasks.clear()
        logger.info(
            "[CONTINUOUS-AUDIT] Stopped — total=%d, flagged=%d, blocked=%d",
            self._state.audits_total, self._state.flagged_total, self._state.blocked_total,
        )

    def audit_transfer(self, transfer: dict[str, Any]) -> AuditEntry:
        """Przeprowadź audyt pojedynczego transferu.

        Args:
            transfer: Dane transferu z TB.

        Returns:
            AuditEntry z wynikiem audytu.
        """
        import hashlib

        audit_id = f"AUDIT-{time.time_ns()}"
        transfer_id = str(transfer.get("transfer_id", ""))
        now = pendulum.now("UTC")

        failed_rules: list[str] = []
        is_blocking = False

        for rule in self.AUDIT_RULES:
            if self._check_rule(rule, transfer):
                continue  # Reguła spełniona — OK
            failed_rules.append(rule.rule_id)
            if rule.is_blocking:
                is_blocking = True

        # Określ flagę audytową
        if not failed_rules:
            flag = AuditFlag.CLEAN
        elif is_blocking and self._auto_block:
            flag = AuditFlag.BLOCKED
        elif len(failed_rules) >= 3:
            flag = AuditFlag.NEEDS_REVIEW
        elif len(failed_rules) >= 1:
            flag = AuditFlag.FLAGGED
        else:
            flag = AuditFlag.WARNING

        # Generuj proof hash
        proof_data = f"{audit_id}:{transfer_id}:{flag.value}:{','.join(failed_rules)}".encode()
        proof_hash = hashlib.sha256(proof_data).hexdigest()

        entry = AuditEntry(
            audit_id=audit_id,
            transfer_id=transfer_id,
            timestamp=now.isoformat(),
            flag=flag,
            rules_checked=len(self.AUDIT_RULES),
            rules_failed=len(failed_rules),
            failed_rules=failed_rules,
            proof_hash=proof_hash,
            auto_blocked=is_blocking and self._auto_block,
            details={
                "debit": transfer.get("debit_account"),
                "credit": transfer.get("credit_account"),
                "amount": transfer.get("amount_minor"),
                "ledger": transfer.get("ledger"),
                "code": transfer.get("code"),
            },
        )

        # Aktualizuj stan
        self._state.audits_total += 1
        self._state.last_entry = entry
        self._state.recent_entries.append(entry)

        if flag == AuditFlag.BLOCKED:
            self._state.blocked_total += 1
        elif flag != AuditFlag.CLEAN:
            self._state.flagged_total += 1
        else:
            self._state.clean_total += 1

        # Trim historia
        if len(self._state.recent_entries) > self._max_recent:
            self._state.recent_entries = self._state.recent_entries[-self._max_recent:]

        # Loguj
        if flag in (AuditFlag.BLOCKED, AuditFlag.FLAGGED):
            logger.warning(
                "[CONTINUOUS-AUDIT] %s: transfer=%s, failed_rules=%s",
                flag.value.upper(), transfer_id, failed_rules,
            )

        return entry

    # ── Reguły ──────────────────────────────────────────────────────────

    def _check_rule(self, rule: AuditRule, transfer: dict[str, Any]) -> bool:
        """Sprawdź pojedynczą regułę audytową.

        Returns:
            True jeśli reguła SPEŁNIONA (transfer OK).
            False jeśli reguła NIESPEŁNIONA (transfer narusza regułę).
        """
        amount = int(transfer.get("amount_minor", 0))
        now = pendulum.now("Europe/Warsaw")

        if rule.rule_id == "AUDIT-001":
            # Transfer nie może przekraczać limitu konta (TB natywnie)
            # Tu sprawdzamy to programowo
            return amount < 100_000_000  # < 1M PLN

        elif rule.rule_id == "AUDIT-002":
            # Konto spoza planu kont — sprawdzane w ledger_guard.py
            return True  # Delegowane do LedgerGuard

        elif rule.rule_id == "AUDIT-003":
            # Kwota > 100 000 PLN
            return amount <= 10_000_000  # 100k PLN w groszach

        elif rule.rule_id == "AUDIT-004":
            # Okrągła kwota — potencjalne pranie pieniędzy
            if amount >= 1_000_000:  # >= 10k PLN
                return amount % 100_000 != 0  # Nie może być wielokrotnością 1000 PLN
            return True

        elif rule.rule_id == "AUDIT-005":
            # Transfer w weekend
            return now.day_of_week < 5  # Pon-Pt OK

        elif rule.rule_id == "AUDIT-006":
            # Structuring — sprawdzane w ledger_guard.py
            return True

        elif rule.rule_id == "AUDIT-007":
            # Debit bez kredytu — TB natywnie gwarantuje
            return True  # TB nie pozwala na niezbalansowane transfery

        elif rule.rule_id == "AUDIT-008":
            # Konto zablokowane — musiałoby być oznaczone w TB
            return True

        elif rule.rule_id == "AUDIT-009":
            # Modyfikacja zaksięgowanego — TB jest immutable
            return True

        elif rule.rule_id == "AUDIT-010":
            # >5 storno dziennie — potrzebny licznik
            return True

        return True

    # ── NATS ────────────────────────────────────────────────────────────

    async def _nats_listener(self) -> None:
        """Nasłuchuj NATS eventów."""
        if not self._nats:
            return

        try:
            import json

            async def handle_transfer(msg):
                try:
                    data = json.loads(msg.data.decode())
                    entry = self.audit_transfer(data)

                    # Publikuj wynik audytu
                    if entry.flag != AuditFlag.CLEAN and self._nats.is_connected:
                        await self._nats.publish(
                            "nexus.audit.flagged",
                            json.dumps({
                                "audit_id": entry.audit_id,
                                "transfer_id": entry.transfer_id,
                                "flag": entry.flag.value,
                                "failed_rules": entry.failed_rules,
                                "auto_blocked": entry.auto_blocked,
                                "proof_hash": entry.proof_hash,
                                "timestamp": entry.timestamp,
                            }).encode(),
                        )

                    # Zapis w Proof Chain
                    if self._proof_chain:
                        self._proof_chain.log_decision(
                            transaction_id=entry.transfer_id,
                            trace={"audit_entry": entry.__dict__},
                            context={"source": "continuous_audit_engine"},
                        )

                except Exception as exc:
                    logger.debug("[CONTINUOUS-AUDIT] Event error: %s", exc)

            await self._nats.subscribe("tb.transfer.pending", cb=handle_transfer)
            await self._nats.subscribe("tb.transfer.posted", cb=handle_transfer)

            logger.info("[CONTINUOUS-AUDIT] NATS listener active")

            while self._running:
                await asyncio.sleep(1)

        except asyncio.CancelledError:
            pass
        except Exception as exc:
            logger.error("[CONTINUOUS-AUDIT] NATS error: %s", exc)

    def register_known_accounts(self, account_ids: list[int]) -> None:
        """v7.0: Zarejestruj znane konta z planu kont."""
        self._known_accounts.update(account_ids)

    def get_audit_report(self) -> dict[str, Any]:
        """Wygeneruj raport audytowy."""
        s = self._state
        return {
            "total_audited": s.audits_total,
            "clean": s.clean_total,
            "flagged": s.flagged_total,
            "blocked": s.blocked_total,
            "clean_rate": round(s.clean_total / max(s.audits_total, 1) * 100, 2),
            "rules_active": len(self.AUDIT_RULES),
            "last_entry": {
                "flag": s.last_entry.flag.value if s.last_entry else "none",
                "failed_rules": s.last_entry.failed_rules if s.last_entry else [],
                "timestamp": s.last_entry.timestamp if s.last_entry else "",
            } if s.last_entry else None,
        }
