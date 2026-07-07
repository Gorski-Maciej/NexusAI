"""Domain Aggregates -- DDD Aggregate Roots for NexusAI.

Zgodnie z Enterprise DDD:
- Każdy Aggregate Root egzekwuje niezmienniki biznesowe
- Stan zmienia się tylko przez metody agregatu (nie settery)
- Zdarzenia domenowe rejestrowane jako msgspec.Struct (immutable facts)
- Każda operacja biznesowa = jedna transakcja na jednym agregacie

Aggregates:
    InvoiceAggregate     -- faktura jako root (status machine, decyzje, ścieżka audytu)
    ContractorAggregate  -- kontrahent z fakturami i historią płatności
    TaxDecisionAggregate -- decyzja podatkowa z regułami i zaufaniem
"""

from __future__ import annotations

import time
import uuid
from dataclasses import dataclass, field
from datetime import datetime  # noqa: F401  # kept for reconstitute compatibility
from typing import ClassVar

import msgspec
import pendulum

from nexus_ai.db.models import InvoiceStatus
from nexus_ai.domain.values import AccountCode, Money, MoneyNet, NIP, TaxPeriod, VatRate, DomainError


# ═══════════════════════════════════════════════════════════════════════════
# UUIDv7 generator -- sortowalne, chronologiczne ID (lepsze niż uuid4)
# ═══════════════════════════════════════════════════════════════════════════


def uuid7() -> uuid.UUID:
    """Generate a UUIDv7 (timestamp-based, sortable) for Python 3.13.

    Uses uuid4() as entropy source, overwriting the timestamp and
    version/variant nibbles — preserves all 122 random bits.

    Format:
        |unix_ts_ms (48b)|ver 0x7 (4b)|rand_a (12b)|var 0x8 (2b)|rand_b (62b)|
    """
    timestamp_ms = int(time.time() * 1000)
    b = bytearray(uuid.uuid4().bytes)
    # 48-bit timestamp (big-endian)
    for i in range(6):
        b[i] = (timestamp_ms >> (40 - i * 8)) & 0xFF
    b[6] = (b[6] & 0x0F) | 0x70  # version 7 (preserve lower nibble rand_a)
    b[8] = (b[8] & 0x3F) | 0x80  # variant 10xx (preserve lower 6 bits rand_b)
    return uuid.UUID(bytes=bytes(b))


# ═══════════════════════════════════════════════════════════════════════════
# Domain Events -- immutable facts as msgspec.Struct (faster, lighter)
# ═══════════════════════════════════════════════════════════════════════════


class DomainEvent(msgspec.Struct, frozen=True, tag=True):
    """Base domain event -- niezmienny fakt biznesowy."""
    event_id: str
    timestamp: str  # ISO 8601 UTC
    aggregate_id: str = ""


class InvoiceCreated(DomainEvent):
    """Faktura utworzona w systemie."""
    invoice_number: str | None = None
    contractor_nip: str | None = None
    amount_net_minor: int | None = None


class InvoiceApproved(DomainEvent):
    """Faktura zatwierdzona przez autopilota lub księgowego."""
    decision_id: str = ""
    auto_approved: bool = False
    confidence: float = 0.0


class InvoiceRejected(DomainEvent):
    """Faktura odrzucona."""
    reason: str = ""
    rejected_by: str = "system"


class InvoiceMarkedPaid(DomainEvent):
    """Faktura oznaczona jako opłacona."""
    payment_date: str = ""  # ISO 8601 UTC
    payment_amount_minor: int | None = None


class InvoiceSentToReview(DomainEvent):
    """Faktura przekazana do manualnej weryfikacji."""
    reason: str = ""
    confidence: float = 0.0


class InvoiceBlocked(DomainEvent):
    """Faktura zablokowana (np. fraud suspicion)."""
    reason: str = ""
    fraud_score: float = 0.0


# ═══════════════════════════════════════════════════════════════════════════
# InvoiceAggregate -- Aggregate Root dla faktur
# ═══════════════════════════════════════════════════════════════════════════


@dataclass(slots=True)
class InvoiceAggregate:
    """Aggregate Root: Faktura.

    Egzekwuje:
    - Maszynę stanów (legalne tranzycje)
    - Niezmienniki: kwoty >= 0, waluta ISO 4217
    - Zdarzenia domenowe dla każdej zmiany stanu
    - Optymistyczną kontrolę współbieżności przez version

    Usage:
        inv = InvoiceAggregate.create(
            number="FV/2026/06/001",
            contractor_nip="1234567890",
            amount_net=Decimal("1000.00"),
            amount_gross=Decimal("1230.00"),
        )
        inv.approve(decision_id="dec-1", auto_approved=True, confidence=0.95)
        inv.mark_paid(Decimal("1230.00"))
        events = inv.collect_events()
    """

    # ── Stan ──────────────────────────────────────────────────────────
    id: str
    number: str | None
    contractor_nip: str | None
    amount_net: Money | None
    amount_gross: Money | None
    currency: str
    status: InvoiceStatus
    version: int
    created_at: pendulum.DateTime
    updated_at: pendulum.DateTime

    # ── Internal ──────────────────────────────────────────────────────
    _events: list[DomainEvent] = field(default_factory=list, repr=False)
    _original_status: InvoiceStatus | None = field(default=None, repr=False)

    # ── Legalne tranzycje stanów ──────────────────────────────────────
    _ALLOWED_TRANSITIONS: ClassVar[dict[InvoiceStatus, frozenset[InvoiceStatus]]] = {
        InvoiceStatus.NEW: frozenset({InvoiceStatus.PROCESSING, InvoiceStatus.FAILED}),
        InvoiceStatus.PROCESSING: frozenset({
            InvoiceStatus.PENDING_REVIEW,
            InvoiceStatus.APPROVED,
            InvoiceStatus.REJECTED,
            InvoiceStatus.BLOCKED,
            InvoiceStatus.MANUAL_REVIEW,
            InvoiceStatus.BLOCKED_FRAUD_SUSPICION,
            InvoiceStatus.FAILED,
        }),
        InvoiceStatus.PENDING_REVIEW: frozenset({
            InvoiceStatus.APPROVED,
            InvoiceStatus.REJECTED,
            InvoiceStatus.BLOCKED,
            InvoiceStatus.MANUAL_REVIEW,
        }),
        InvoiceStatus.APPROVED: frozenset({InvoiceStatus.PAID, InvoiceStatus.REJECTED}),
        InvoiceStatus.REJECTED: frozenset({InvoiceStatus.NEW}),
        InvoiceStatus.BLOCKED: frozenset({InvoiceStatus.PROCESSING, InvoiceStatus.REJECTED}),
        InvoiceStatus.BLOCKED_FRAUD_SUSPICION: frozenset({InvoiceStatus.MANUAL_REVIEW, InvoiceStatus.REJECTED}),
        InvoiceStatus.MANUAL_REVIEW: frozenset({InvoiceStatus.APPROVED, InvoiceStatus.REJECTED}),
        InvoiceStatus.PAID: frozenset(),
        InvoiceStatus.FAILED: frozenset({InvoiceStatus.NEW, InvoiceStatus.PROCESSING}),
    }

    # ── Factory ───────────────────────────────────────────────────────

    @classmethod
    def create(
        cls,
        number: str | None = None,
        contractor_nip: str | None = None,
        amount_net: Money | None = None,
        amount_gross: Money | None = None,
        currency: str = "PLN",
    ) -> InvoiceAggregate:
        """Factory: utwórz nową fakturę w stanie NEW."""
        if amount_net is not None and not amount_net.is_positive and not amount_net.is_zero:
            raise ValueError(f"amount_net cannot be negative: {amount_net}")
        if amount_gross is not None and not amount_gross.is_positive and not amount_gross.is_zero:
            raise ValueError(f"amount_gross cannot be negative: {amount_gross}")
        if amount_net is not None and amount_gross is not None and amount_net.amount > amount_gross.amount:
            raise ValueError(
                f"amount_net ({amount_net}) cannot exceed amount_gross ({amount_gross})"
            )
        if len(currency) != 3 or not currency.isalpha():
            raise ValueError(f"Currency must be ISO 4217 (3 letters): {currency}")

        now = pendulum.now("UTC")
        now_iso = now.isoformat()
        agg = cls(
            id=uuid7().hex,
            number=number,
            contractor_nip=contractor_nip,
            amount_net=amount_net,
            amount_gross=amount_gross,
            currency=currency.upper(),
            status=InvoiceStatus.NEW,
            version=1,
            created_at=now,
            updated_at=now,
        )
        agg._events.append(InvoiceCreated(
            event_id=uuid7().hex,
            timestamp=now_iso,
            aggregate_id=agg.id,
            invoice_number=number,
            contractor_nip=contractor_nip,
            amount_net_minor=amount_net.to_minor() if amount_net is not None else None,
        ))
        return agg

    @classmethod
    def reconstitute(
        cls,
        id: str,
        number: str | None,
        contractor_nip: str | None,
        amount_net: Money | None,
        amount_gross: Money | None,
        currency: str,
        status: str,
        version: int,
        created_at: datetime,
        updated_at: datetime,
    ) -> InvoiceAggregate:
        """Reconstitute: odtwórz agregat z bazy danych."""
        agg = cls(
            id=id,
            number=number,
            contractor_nip=contractor_nip,
            amount_net=amount_net,
            amount_gross=amount_gross,
            currency=currency,
            status=InvoiceStatus(status),
            version=version,
            created_at=created_at,
            updated_at=updated_at,
        )
        agg._original_status = agg.status
        return agg

    # ── State transitions ─────────────────────────────────────────────

    def _transition(self, new_status: InvoiceStatus) -> None:
        """Egzekwuj maszynę stanów."""
        allowed = self._ALLOWED_TRANSITIONS.get(self.status, frozenset())
        if new_status not in allowed:
            raise ValueError(
                f"Illegal status transition: {self.status.value} -> {new_status.value}. "
                f"Allowed: {[s.value for s in allowed]}"
            )
        self.status = new_status
        self.version += 1
        self.updated_at = pendulum.now("UTC")

    def _emit(self, event_cls: type[DomainEvent], status: InvoiceStatus, **kwargs) -> None:
        """Helper: wykonaj transition + dodaj event."""
        self._transition(status)
        self._events.append(event_cls(
            event_id=uuid7().hex,
            timestamp=pendulum.now("UTC").isoformat(),
            aggregate_id=self.id,
            **kwargs,
        ))

    def approve(self, decision_id: str = "", auto_approved: bool = False, confidence: float = 0.0) -> None:
        self._emit(InvoiceApproved, InvoiceStatus.APPROVED, decision_id=decision_id, auto_approved=auto_approved, confidence=confidence)

    def reject(self, reason: str = "", rejected_by: str = "system") -> None:
        self._emit(InvoiceRejected, InvoiceStatus.REJECTED, reason=reason, rejected_by=rejected_by)

    def send_to_review(self, reason: str = "", confidence: float = 0.0) -> None:
        self._emit(InvoiceSentToReview, InvoiceStatus.PENDING_REVIEW, reason=reason, confidence=confidence)

    def mark_paid(self, payment_amount: Money | None = None) -> None:
        self._emit(InvoiceMarkedPaid, InvoiceStatus.PAID, payment_date=pendulum.now("UTC").isoformat(),
                   payment_amount_minor=payment_amount.to_minor() if payment_amount is not None else None)

    def block(self, reason: str = "", fraud_score: float = 0.0) -> None:
        self._emit(InvoiceBlocked, InvoiceStatus.BLOCKED, reason=reason, fraud_score=fraud_score)

    def block_fraud(self, reason: str = "", fraud_score: float = 0.0) -> None:
        self._emit(InvoiceBlocked, InvoiceStatus.BLOCKED_FRAUD_SUSPICION, reason=reason, fraud_score=fraud_score)

    def mark_processing(self) -> None:
        self._transition(InvoiceStatus.PROCESSING)

    def mark_failed(self) -> None:
        self._transition(InvoiceStatus.FAILED)

    # ── Queries ───────────────────────────────────────────────────────

    def can_be_modified(self) -> bool:
        """Czy faktura może być modyfikowana?"""
        return self.status in {InvoiceStatus.NEW, InvoiceStatus.PENDING_REVIEW}

    def can_be_auto_approved(self) -> bool:
        """Czy faktura kwalifikuje się do auto-zatwierdzenia?"""
        return self.status in {InvoiceStatus.PROCESSING, InvoiceStatus.PENDING_REVIEW}

    def is_terminal(self) -> bool:
        """Czy faktura jest w stanie końcowym?"""
        return self.status in {InvoiceStatus.PAID, InvoiceStatus.REJECTED}

    @property
    def amount_vat(self) -> Money | None:
        """VAT = amount_gross - amount_net."""
        if self.amount_gross is not None and self.amount_net is not None:
            return self.amount_gross - self.amount_net
        return None

    # ── Event sourcing ────────────────────────────────────────────────

    def collect_events(self) -> list[DomainEvent]:
        """Zbierz i wyczyść pending events."""
        events = self._events.copy()
        self._events.clear()
        self._original_status = self.status
        return events

    def has_pending_events(self) -> bool:
        """Czy są nieopublikowane zdarzenia?"""
        return len(self._events) > 0


# ═══════════════════════════════════════════════════════════════════════════
# ContractorAggregate -- Aggregate Root dla kontrahentów
# ═══════════════════════════════════════════════════════════════════════════


@dataclass(slots=True)
class ContractorAggregate:
    """Aggregate Root: Kontrahent.

    Egzekwuje:
    - Walidację NIP przy tworzeniu
    - Historię faktur (przez ID referencje, nie całe agregaty)
    - Sprawdzanie statusu VAT (biała lista)
    """

    id: str
    nip: str
    name: str | None
    vat_status: str | None
    created_at: pendulum.DateTime
    updated_at: pendulum.DateTime

    # Referencje do faktur (tylko ID, nie całe agregaty!)
    _invoice_ids: set[str] = field(default_factory=set, repr=False)
    _events: list[DomainEvent] = field(default_factory=list, repr=False)

    @classmethod
    def create(cls, nip: str, name: str | None = None) -> ContractorAggregate:
        """Factory: utwórz nowego kontrahenta."""
        # Walidacja NIP przez Value Object
        validated_nip = NIP(value=nip)
        now = pendulum.now("UTC")
        return cls(
            id=uuid.uuid4().hex,
            nip=validated_nip.value,
            name=name,
            vat_status=None,
            created_at=now,
            updated_at=now,
        )

    def link_invoice(self, invoice_id: str) -> None:
        """Powiąż fakturę z kontrahentem."""
        self._invoice_ids.add(invoice_id)
        self.updated_at = pendulum.now("UTC")

    def unlink_invoice(self, invoice_id: str) -> None:
        """Usuń powiązanie faktury."""
        self._invoice_ids.discard(invoice_id)

    @property
    def invoice_count(self) -> int:
        """Liczba powiązanych faktur."""
        return len(self._invoice_ids)

    @property
    def formatted_nip(self) -> str:
        """NIP w formacie XXX-XXX-XX-XX."""
        try:
            return NIP(value=self.nip).formatted
        except DomainError:
            return self.nip

    def update_vat_status(self, status: str | None) -> None:
        """Aktualizuj status VAT (z białej listy MF)."""
        self.vat_status = status
        self.updated_at = pendulum.now("UTC")

    def collect_events(self) -> list[DomainEvent]:
        events = self._events.copy()
        self._events.clear()
        return events


# ═══════════════════════════════════════════════════════════════════════════
# TaxDecisionAggregate -- Aggregate Root dla decyzji podatkowych
# ═══════════════════════════════════════════════════════════════════════════


@dataclass(slots=True)
class TaxDecisionAggregate:
    """Aggregate Root: Decyzja podatkowa.

    Egzekwuje:
    - Idempotentność (jedna decyzja na fakturę w danym okresie)
    - Ścieżkę audytu (hash chain)
    - Trzy poziomy zaufania: auto-post, suggest, ask
    """

    id: str
    invoice_id: str
    tax_period: TaxPeriod | None
    vat_rate: VatRate | None
    account_code: AccountCode | None
    amount_net: Money | None
    amount_vat: Money | None
    confidence: float
    auto_posted: bool
    needs_review: bool
    created_at: pendulum.DateTime
    _events: list[DomainEvent] = field(default_factory=list, repr=False)

    # Progi decyzyjne
    AUTO_POST_THRESHOLD: ClassVar[float] = 0.92
    SUGGEST_THRESHOLD: ClassVar[float] = 0.75
    ASK_THRESHOLD: ClassVar[float] = 0.50

    @classmethod
    def create(
        cls,
        invoice_id: str,
        confidence: float,
        tax_period: TaxPeriod | None = None,
        vat_rate: VatRate | None = None,
        account_code: AccountCode | None = None,
        amount_net: Money | None = None,
        amount_vat: Money | None = None,
    ) -> TaxDecisionAggregate:
        """Factory: utwórz decyzję podatkową."""
        if not 0.0 <= confidence <= 1.0:
            raise ValueError(f"Confidence must be 0.0-1.0: {confidence}")

        auto_posted = confidence >= cls.AUTO_POST_THRESHOLD
        needs_review = confidence < cls.SUGGEST_THRESHOLD

        return cls(
            id=uuid7().hex,
            invoice_id=invoice_id,
            tax_period=tax_period,
            vat_rate=vat_rate,
            account_code=account_code,
            amount_net=amount_net,
            amount_vat=amount_vat,
            confidence=confidence,
            auto_posted=auto_posted,
            needs_review=needs_review,
            created_at=pendulum.now("UTC"),
        )

    @property
    def decision_level(self) -> str:
        """Poziom decyzji: auto-post, suggest, or ask."""
        if self.confidence >= self.AUTO_POST_THRESHOLD:
            return "auto_post"
        if self.confidence >= self.SUGGEST_THRESHOLD:
            return "suggest"
        return "ask"

    def requires_human(self) -> bool:
        """Czy decyzja wymaga akceptacji człowieka?"""
        return self.decision_level == "ask"

    def collect_events(self) -> list[DomainEvent]:
        events = self._events.copy()
        self._events.clear()
        return events
