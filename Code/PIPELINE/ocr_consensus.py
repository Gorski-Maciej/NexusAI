from __future__ import annotations

from dataclasses import dataclass

from services.currency_converter import Money


@dataclass(slots=True)
class OCRAmountResult:
    amount_gross: Money | None
    source: str


@dataclass(slots=True)
class OCRConsensusDecision:
    accepted: OCRAmountResult | None
    confidence_conflict: bool


def decide_amount_consensus(
    primary: OCRAmountResult | None,
    secondary: OCRAmountResult | None,
    *,
    tolerance: float = 0.01,
) -> OCRConsensusDecision:
    if not primary and not secondary:
        return OCRConsensusDecision(accepted=None, confidence_conflict=False)
    if primary and not secondary:
        return OCRConsensusDecision(accepted=primary, confidence_conflict=False)
    if secondary and not primary:
        return OCRConsensusDecision(accepted=secondary, confidence_conflict=False)

    assert primary and secondary
    if primary.amount_gross is None or secondary.amount_gross is None:
        return OCRConsensusDecision(accepted=primary, confidence_conflict=True)

    # Compare amounts using Money arithmetic (both should be same currency)
    diff = abs(primary.amount_gross.amount - secondary.amount_gross.amount)
    if float(diff) > tolerance:
        return OCRConsensusDecision(accepted=primary, confidence_conflict=True)

    return OCRConsensusDecision(accepted=primary, confidence_conflict=False)
