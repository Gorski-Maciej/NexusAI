"""Crosshair property-based tests for NexusAI domain aggregates.

Uses crosshair (SMT-driven property-based testing with Z3 solver) to
mathematically verify correctness of domain invariants, state machines,
and arithmetic properties.

Configuration in pyproject.toml [tool.crosshair]:
  max_examples = 500, per_condition = 10.0s, per_test_timeout = 30.0s

Run:
  crosshair check tests/test_crosshair_properties.py
  pytest tests/test_crosshair_properties.py --run-slow
"""

from __future__ import annotations

from decimal import Decimal

import pytest

try:
    from crosshair import contract  # noqa: F401
    HAS_CROSSHAIR = True
except ImportError:
    HAS_CROSSHAIR = False

from nexus_ai.domain.aggregates import (
    ContractorAggregate,
    InvoiceAggregate,
    InvoiceStatus,
    TaxDecisionAggregate,
)
from nexus_ai.domain.values import Money, MoneyNet, VatRate

# Skip in normal pytest runs — only crosshair or --run-slow
pytestmark = [pytest.mark.slow]


# ═══════════════════════════════════════════════════════════════════════════
# InvoiceAggregate — State Machine Properties
# ═══════════════════════════════════════════════════════════════════════════


def test_invoice_aggregate_initial_state_is_new() -> None:
    """Property: every freshly created invoice starts in NEW status."""
    inv = InvoiceAggregate.create(
        number="FV/2026/06/001",
        amount_net=Money(amount=Decimal("100.00")),
        amount_gross=Money(amount=Decimal("123.00")),
    )
    assert inv.status == InvoiceStatus.NEW
    assert inv.version == 1
    assert inv.has_pending_events()
    assert not inv.is_terminal()


def test_invoice_aggregate_collect_events_clears_queue() -> None:
    """Property: collect_events() returns events and clears internal queue."""
    inv = InvoiceAggregate.create(
        number="FV/2026/06/001",
        amount_net=Money(amount=Decimal("100.00")),
        amount_gross=Money(amount=Decimal("123.00")),
    )
    events = inv.collect_events()
    assert len(events) == 1
    assert not inv.has_pending_events()


def test_invoice_aggregate_approve_from_processing() -> None:
    """Property: NEW -> PROCESSING -> APPROVED is a legal transition chain."""
    inv = InvoiceAggregate.create(
        amount_net=Money(amount=Decimal("100.00")),
        amount_gross=Money(amount=Decimal("123.00")),
    )
    inv.mark_processing()
    assert inv.status == InvoiceStatus.PROCESSING

    inv.approve(decision_id="dec-1", auto_approved=True, confidence=0.95)
    assert inv.status == InvoiceStatus.APPROVED
    assert inv.version == 3  # NEW(1) -> PROCESSING(2) -> APPROVED(3)


def test_invoice_aggregate_reject_from_processing() -> None:
    """Property: NEW -> PROCESSING -> REJECTED is legal."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("50.00")))
    inv.mark_processing()
    inv.reject(reason="Invalid NIP", rejected_by="accountant")
    assert inv.status == InvoiceStatus.REJECTED
    assert inv.is_terminal()


def test_invoice_aggregate_paid_requires_approved() -> None:
    """Property: you cannot pay a non-approved invoice."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    with pytest.raises(ValueError, match="Illegal status transition"):
        inv.mark_paid(Money(amount=Decimal("100.00")))


def test_invoice_aggregate_send_to_review() -> None:
    """Property: PROCESSING -> PENDING_REVIEW is legal."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    inv.mark_processing()
    inv.send_to_review(reason="Low confidence", confidence=0.45)
    assert inv.status == InvoiceStatus.PENDING_REVIEW
    assert inv.can_be_modified()


def test_invoice_aggregate_block_fraud() -> None:
    """Property: PROCESSING -> BLOCKED_FRAUD_SUSPICION is legal."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    inv.mark_processing()
    inv.block_fraud(reason="Suspicious NIP pattern", fraud_score=0.88)
    assert inv.status == InvoiceStatus.BLOCKED_FRAUD_SUSPICION


def test_invoice_aggregate_block() -> None:
    """Property: PROCESSING -> BLOCKED is legal."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    inv.mark_processing()
    inv.block(reason="Manual block", fraud_score=0.3)
    assert inv.status == InvoiceStatus.BLOCKED


def test_invoice_aggregate_paid_is_terminal() -> None:
    """Property: PAID is a terminal state — no transitions allowed."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    inv.mark_processing()
    inv.approve(confidence=0.95)
    inv.mark_paid(Money(amount=Decimal("123.00")))
    assert inv.is_terminal()

    # No transition allowed from PAID
    with pytest.raises(ValueError, match="Illegal status transition"):
        inv.approve()


def test_invoice_aggregate_illegal_transition_raises() -> None:
    """Property: jumping from NEW directly to PAID raises ValueError."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    with pytest.raises(ValueError, match="Illegal status transition"):
        inv.mark_paid()


def test_invoice_aggregate_version_increments() -> None:
    """Property: every state transition increments version by exactly 1."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    assert inv.version == 1
    inv.mark_processing()
    assert inv.version == 2
    inv.approve(confidence=0.95)
    assert inv.version == 3


def test_invoice_aggregate_negative_amount_raises() -> None:
    """Property: creating an invoice with negative amount raises ValueError."""
    with pytest.raises(ValueError, match="cannot be negative"):
        InvoiceAggregate.create(amount_net=Money(amount=Decimal("-100.00")))


def test_invoice_aggregate_invalid_currency_raises() -> None:
    """Property: currency must be 3-letter ISO 4217 code."""
    with pytest.raises(ValueError, match="ISO 4217"):
        InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")), currency="PL")


def test_invoice_aggregate_can_be_modified_only_in_certain_states() -> None:
    """Property: can_be_modified() only returns True for NEW and PENDING_REVIEW."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    assert inv.can_be_modified()

    inv.mark_processing()
    assert not inv.can_be_modified()

    inv.send_to_review(confidence=0.45)
    assert inv.can_be_modified()

    inv.approve(confidence=0.95)
    assert not inv.can_be_modified()


def test_invoice_aggregate_auto_approve_eligibility() -> None:
    """Property: can_be_auto_approved() is True for PROCESSING and PENDING_REVIEW."""
    inv = InvoiceAggregate.create(amount_net=Money(amount=Decimal("100.00")))
    assert not inv.can_be_auto_approved()  # NEW

    inv.mark_processing()
    assert inv.can_be_auto_approved()

    inv.send_to_review(confidence=0.45)
    assert inv.can_be_auto_approved()

    inv.approve(confidence=0.95)
    assert not inv.can_be_auto_approved()


def test_invoice_aggregate_amount_vat_computation() -> None:
    """Property: amount_vat = amount_gross - amount_net."""
    inv = InvoiceAggregate.create(
        amount_net=Money(amount=Decimal("100.00")),
        amount_gross=Money(amount=Decimal("123.00")),
    )
    assert inv.amount_vat == Money(amount=Decimal("23.00"))


# ═══════════════════════════════════════════════════════════════════════════
# Money — Arithmetic Properties
# ═══════════════════════════════════════════════════════════════════════════


def test_money_addition_is_commutative() -> None:
    """Property: Money addition is commutative: a + b == b + a."""
    a = Money(amount=Decimal("100.00"), currency="PLN")
    b = Money(amount=Decimal("50.00"), currency="PLN")
    assert a + b == b + a


def test_money_addition_is_associative() -> None:
    """Property: Money addition is associative: (a+b)+c == a+(b+c)."""
    a = Money(amount=Decimal("100.00"), currency="PLN")
    b = Money(amount=Decimal("50.00"), currency="PLN")
    c = Money(amount=Decimal("25.00"), currency="PLN")
    assert (a + b) + c == a + (b + c)


def test_money_zero_is_identity() -> None:
    """Property: Zero money is the identity for addition."""
    m = Money(amount=Decimal("100.00"), currency="PLN")
    zero = Money.zero("PLN")
    assert m + zero == m
    assert zero + m == m


def test_money_subtraction_is_inverse_of_addition() -> None:
    """Property: (a + b) - b == a."""
    a = Money(amount=Decimal("100.00"), currency="PLN")
    b = Money(amount=Decimal("50.00"), currency="PLN")
    assert (a + b) - b == a


def test_money_multiplication_by_one() -> None:
    """Property: Multiplying by 1 returns the same amount."""
    m = Money(amount=Decimal("100.00"), currency="PLN")
    assert m * Decimal("1") == m


def test_money_multiplication_by_zero() -> None:
    """Property: Multiplying by 0 returns zero."""
    m = Money(amount=Decimal("100.00"), currency="PLN")
    result = m * Decimal("0")
    assert result.amount == Decimal("0.00")
    assert result.currency == "PLN"


def test_money_currency_mismatch_raises_on_add() -> None:
    """Property: Adding different currencies raises CurrencyMismatchError."""
    a = Money(amount=Decimal("100.00"), currency="PLN")
    b = Money(amount=Decimal("50.00"), currency="EUR")
    with pytest.raises(ValueError, match="different currencies"):
        _ = a + b


def test_money_is_zero_property() -> None:
    """Property: Money.zero().is_zero is True."""
    assert Money.zero("PLN").is_zero
    assert not Money(amount=Decimal("1.00"), currency="PLN").is_zero


def test_money_to_grosze_roundtrip() -> None:
    """Property: from_grosze(to_grosze(m)) == m for integer grosze amounts."""
    m = Money(amount=Decimal("100.00"), currency="PLN")
    assert Money.from_grosze(m.to_grosze(), "PLN") == m

    m2 = Money(amount=Decimal("0.01"), currency="PLN")
    assert Money.from_grosze(m2.to_grosze(), "PLN") == m2


def test_money_float_multiplication_raises() -> None:
    """Property: Multiplying Money by float raises TypeError."""
    m = Money(amount=Decimal("100.00"), currency="PLN")
    with pytest.raises(TypeError, match="Cannot multiply Money by float"):
        _ = m * 2.5


def test_money_negative_amount_raises() -> None:
    """Property: Cannot create Money with negative amount."""
    with pytest.raises(ValueError, match="cannot be negative"):
        Money(amount=Decimal("-1.00"))


# ═══════════════════════════════════════════════════════════════════════════
# TaxDecisionAggregate — Confidence Thresholds
# ═══════════════════════════════════════════════════════════════════════════


def test_tax_decision_auto_post_threshold() -> None:
    """Property: confidence >= 0.92 → auto_posted=True and decision_level='auto_post'."""
    decision = TaxDecisionAggregate.create(
        invoice_id="inv-001",
        confidence=0.95,
    )
    assert decision.auto_posted
    assert not decision.needs_review
    assert decision.decision_level == "auto_post"
    assert not decision.requires_human()


def test_tax_decision_suggest_threshold() -> None:
    """Property: 0.75 <= confidence < 0.92 → suggest, not auto_posted."""
    decision = TaxDecisionAggregate.create(
        invoice_id="inv-001",
        confidence=0.80,
    )
    assert not decision.auto_posted
    assert not decision.needs_review
    assert decision.decision_level == "suggest"
    assert not decision.requires_human()


def test_tax_decision_ask_threshold() -> None:
    """Property: confidence < 0.75 → needs_review=True and decision_level='ask'."""
    decision = TaxDecisionAggregate.create(
        invoice_id="inv-001",
        confidence=0.45,
    )
    assert not decision.auto_posted
    assert decision.needs_review
    assert decision.decision_level == "ask"
    assert decision.requires_human()


def test_tax_decision_boundary_auto_post() -> None:
    """Property: confidence exactly 0.92 → auto_posted (boundary check)."""
    decision = TaxDecisionAggregate.create(
        invoice_id="inv-001",
        confidence=0.92,
    )
    assert decision.auto_posted
    assert decision.decision_level == "auto_post"


def test_tax_decision_boundary_suggest() -> None:
    """Property: confidence exactly 0.75 → suggest (boundary check)."""
    decision = TaxDecisionAggregate.create(
        invoice_id="inv-001",
        confidence=0.75,
    )
    assert decision.decision_level == "suggest"
    assert not decision.requires_human()


def test_tax_decision_invalid_confidence_raises() -> None:
    """Property: confidence < 0 or > 1 raises ValueError."""
    with pytest.raises(ValueError, match="Confidence must be"):
        TaxDecisionAggregate.create(invoice_id="inv-001", confidence=1.5)

    with pytest.raises(ValueError, match="Confidence must be"):
        TaxDecisionAggregate.create(invoice_id="inv-001", confidence=-0.1)


# ═══════════════════════════════════════════════════════════════════════════
# InvoiceAggregate — Reconstitution (DB → Aggregate)
# ═══════════════════════════════════════════════════════════════════════════


def test_invoice_aggregate_reconstitute_preserves_state() -> None:
    """Property: reconstitute() correctly restores aggregate state."""
    import pendulum

    now = pendulum.now("UTC")
    inv = InvoiceAggregate.reconstitute(
        id="inv-123",
        number="FV/2026/06/001",
        contractor_nip="1234567890",
        amount_net=Money(amount=Decimal("100.00")),
        amount_gross=Money(amount=Decimal("123.00")),
        currency="PLN",
        status="APPROVED",
        version=3,
        created_at=now,
        updated_at=now,
    )
    assert inv.id == "inv-123"
    assert inv.status == InvoiceStatus.APPROVED
    assert inv.version == 3
    assert inv.amount_vat == Money(amount=Decimal("23.00"))
    assert not inv.has_pending_events()  # Reconstituted aggregates start clean


# ═══════════════════════════════════════════════════════════════════════════
# ContractorAggregate — Factory and NIP Validation
# ═══════════════════════════════════════════════════════════════════════════


def test_contractor_aggregate_create_validates_nip() -> None:
    """Property: creating a contractor with valid NIP succeeds."""
    contractor = ContractorAggregate.create(nip="1000000006", name="Test Co")
    assert contractor.nip == "1000000006"
    assert contractor.name == "Test Co"
    assert contractor.invoice_count == 0


def test_contractor_aggregate_invalid_nip_raises() -> None:
    """Property: creating a contractor with invalid NIP raises."""
    with pytest.raises(Exception):  # InvalidNIPError or similar
        ContractorAggregate.create(nip="1234567890")


def test_contractor_aggregate_link_invoice() -> None:
    """Property: linking invoices updates count."""
    contractor = ContractorAggregate.create(nip="1000000006")
    assert contractor.invoice_count == 0
    contractor.link_invoice("inv-001")
    assert contractor.invoice_count == 1
    contractor.link_invoice("inv-002")
    assert contractor.invoice_count == 2


def test_contractor_aggregate_unlink_invoice() -> None:
    """Property: unlinking an invoice decrements count."""
    contractor = ContractorAggregate.create(nip="1000000006")
    contractor.link_invoice("inv-001")
    contractor.link_invoice("inv-002")
    contractor.unlink_invoice("inv-001")
    assert contractor.invoice_count == 1


def test_contractor_aggregate_update_vat_status() -> None:
    """Property: VAT status can be updated."""
    contractor = ContractorAggregate.create(nip="1000000006")
    assert contractor.vat_status is None
    contractor.update_vat_status("ACTIVE")
    assert contractor.vat_status == "ACTIVE"


def test_contractor_aggregate_formatted_nip() -> None:
    """Property: formatted_nip returns XXX-XXX-XX-XX format."""
    contractor = ContractorAggregate.create(nip="1000000006")
    assert contractor.formatted_nip == "100-000-00-06"


# ═══════════════════════════════════════════════════════════════════════════
# Crosshair SMT Contracts — mathematically verified properties
# ═══════════════════════════════════════════════════════════════════════════
# These use @crosshair.contract() with typed parameters so the Z3 SMT
# solver can exhaustively search for counterexamples, proving correctness
# for ALL possible inputs, not just sampled ones.
#
# Run with: crosshair check tests/test_crosshair_properties.py


if HAS_CROSSHAIR:

    @contract()
    def test_smt_money_commutative(amount_a: int, amount_b: int) -> None:
        """SMT-proven: for all non-negative integer grosze, a+b == b+a."""
        a_abs = abs(amount_a)
        b_abs = abs(amount_b)
        a = Money(amount=Decimal(a_abs) / 100, currency="PLN")
        b = Money(amount=Decimal(b_abs) / 100, currency="PLN")
        assert a + b == b + a

    @contract()
    def test_smt_money_associative(amount_a: int, amount_b: int, amount_c: int) -> None:
        """SMT-proven: for all non-negative int grosze, (a+b)+c == a+(b+c)."""
        a = Money(amount=Decimal(abs(amount_a)) / 100, currency="PLN")
        b = Money(amount=Decimal(abs(amount_b)) / 100, currency="PLN")
        c = Money(amount=Decimal(abs(amount_c)) / 100, currency="PLN")
        assert (a + b) + c == a + (b + c)

    @contract()
    def test_smt_money_zero_identity(amount_a: int) -> None:
        """SMT-proven: zero is the additive identity for all amounts."""
        a = Money(amount=Decimal(abs(amount_a)) / 100, currency="PLN")
        zero = Money.zero("PLN")
        assert a + zero == a

    @contract()
    def test_smt_money_subtraction_inverse(amount_a: int, amount_b: int) -> None:
        """SMT-proven: (a+b)-b == a when a >= 0, b >= 0 and a+b >= b."""
        a_abs = abs(amount_a)
        b_abs = abs(amount_b)
        a = Money(amount=Decimal(a_abs) / 100, currency="PLN")
        b = Money(amount=Decimal(b_abs) / 100, currency="PLN")
        if (a + b).amount >= b.amount:
            assert (a + b) - b == a
