from __future__ import annotations

from dataclasses import dataclass, field

from .models import LegalForm, TaxForm
from .strategies import InvalidTaxPolicyError, StrategyContext, StrategyRegistry


@dataclass(slots=True)
class DecisionNode:
    key: str
    value: str
    children: list[DecisionNode] = field(default_factory=list)

    def add_child(self, node: DecisionNode) -> None:
        self.children.append(node)

    def to_dict(self) -> dict:
        return {
            "key": self.key,
            "value": self.value,
            "children": [child.to_dict() for child in self.children],
        }


class CompanyDecisionTree:
    def __init__(self, legal_form: LegalForm, tax_form: TaxForm, *, ksef_active: bool, vat_proportion: float) -> None:
        self.legal_form = legal_form
        self.tax_form = tax_form
        self.context = StrategyContext(legal_form=legal_form, ksef_active=ksef_active, vat_proportion=vat_proportion)
        self.registry = StrategyRegistry()

    def validate_and_build(self) -> tuple[dict, dict]:
        strategy = self.registry.select(self.tax_form)
        policy = strategy.policy_payload(self.context)
        if not self.context.ksef_active:
            raise InvalidTaxPolicyError("KSeF musi być aktywny dla procesu konfiguracji.")

        root = DecisionNode("legal_form", self.legal_form)
        root.add_child(DecisionNode("tax_form", self.tax_form))
        root.add_child(DecisionNode("ksef_active", str(self.context.ksef_active).lower()))
        root.add_child(DecisionNode("vat_proportion", str(self.context.vat_proportion)))
        return root.to_dict(), policy
