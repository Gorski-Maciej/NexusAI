"""
opa_marketplace.py — F3.5 v7.0 Audit: Marketplace OPA — Ekosystem Regul Podatkowych.

Raport v7.0 Pomysl #1: Platforma gdzie ksiegowi i doradcy podatkowi moga tworzyc
i sprzedawac wlasne reguly OPA. Revenue share 70/30.
To przeksztalca NexusAI z produktu w PLATFORME.

Enterprise v7.0:
  - Rule publishing: tworzenie regul Rego → publikacja
  - Revenue share: 70% dla twórcy, 30% dla platformy
  - Rating & reviews: spolecznosc ocenia reguly
  - Bundles: pakiety regul tematycznych (VAT, PIT, ZUS)
  - Versioning: kazda regula ma historie wersji
  - CI/CD: automatyczne testowanie regul przed publikacja
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.opa_marketplace")


# ═══════════════════════════════════════════════════════════════════════════════
# Data Types
# ═══════════════════════════════════════════════════════════════════════════════


class RuleCategory(str, Enum):
    VAT = "vat"
    PIT = "pit"
    CIT = "cit"
    ZUS = "zus"
    KSEF = "ksef"
    JPK = "jpk"
    COMPLIANCE = "compliance"
    CROSSBORDER = "crossborder"
    SPECIALIZED = "specialized"  # Branzowe
    CUSTOM = "custom"


class RuleStatus(str, Enum):
    DRAFT = "draft"
    IN_REVIEW = "in_review"
    PUBLISHED = "published"
    DEPRECATED = "deprecated"
    REJECTED = "rejected"


class PricingModel(str, Enum):
    FREE = "free"
    ONE_TIME = "one_time"
    SUBSCRIPTION_MONTHLY = "subscription_monthly"
    SUBSCRIPTION_ANNUAL = "subscription_annual"


@dataclass
class MarketplaceRule:
    """Pojedyncza regula w Marketplace OPA."""
    rule_id: str = field(default_factory=lambda: uuid.uuid4().hex[:12])
    name: str = ""
    description: str = ""
    category: RuleCategory = RuleCategory.CUSTOM
    author_id: str = ""
    author_name: str = ""
    version: str = "1.0.0"
    rego_content: str = ""
    test_content: str = ""
    documentation: str = ""
    status: RuleStatus = RuleStatus.DRAFT
    pricing: PricingModel = PricingModel.FREE
    price_pln: float = 0.0
    revenue_share_pct: float = 70.0  # 70% dla twórcy
    rating: float = 0.0
    reviews_count: int = 0
    downloads: int = 0
    tags: list[str] = field(default_factory=list)
    created_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    updated_at: str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    legal_basis: str = ""  # Podstawa prawna: "Art. 26h PIT"
    effective_from: str = ""
    effective_to: str | None = None


@dataclass
class RuleBundle:
    """Pakiet regul tematycznych."""
    bundle_id: str = field(default_factory=lambda: uuid.uuid4().hex[:8])
    name: str = ""
    description: str = ""
    category: RuleCategory = RuleCategory.CUSTOM
    rule_ids: list[str] = field(default_factory=list)
    pricing: PricingModel = PricingModel.FREE
    price_pln: float = 0.0
    author_name: str = ""


@dataclass
class RevenueReport:
    """Raport przychodow dla twórcy."""
    author_id: str = ""
    period: str = ""  # "2026-07"
    total_rules: int = 0
    total_downloads: int = 0
    gross_revenue: float = 0.0
    creator_share: float = 0.0  # 70%
    platform_share: float = 0.0  # 30%


# ═══════════════════════════════════════════════════════════════════════════════
# OPA Marketplace Engine
# ═══════════════════════════════════════════════════════════════════════════════


class OPAMarketplace:
    """Platforma Marketplace dla regul OPA.

    Enterprise v7.0 Pomysl #1:
    Ksiegowi i doradcy podatkowi tworza i sprzedaja wlasne reguly OPA.
    Revenue share 70/30 — twórca dostaje 70% przychodu.
    """

    def __init__(self):
        self._rules: dict[str, MarketplaceRule] = {}
        self._bundles: dict[str, RuleBundle] = {}
        self._revenue: dict[str, list[dict]] = {}  # author_id → transactions

    # ── Rule Management ────────────────────────────────────────────────────

    def publish_rule(self, rule: MarketplaceRule) -> str:
        """Opublikuj nowa regule w marketplace."""
        rule.status = RuleStatus.PUBLISHED
        rule.created_at = datetime.now(timezone.utc).isoformat()
        self._rules[rule.rule_id] = rule
        logger.info("[MARKETPLACE] Rule published: %s by %s", rule.name, rule.author_name)
        return rule.rule_id

    def get_rule(self, rule_id: str) -> MarketplaceRule | None:
        """Pobierz regule po ID."""
        return self._rules.get(rule_id)

    def search_rules(
        self,
        category: RuleCategory | None = None,
        query: str = "",
        tags: list[str] | None = None,
        max_price: float | None = None,
        min_rating: float = 0.0,
        sort_by: str = "rating",
        limit: int = 20,
    ) -> list[MarketplaceRule]:
        """Wyszukaj reguly w marketplace."""
        results = list(self._rules.values())

        if category:
            results = [r for r in results if r.category == category]
        if query:
            q = query.lower()
            results = [r for r in results if q in r.name.lower() or q in r.description.lower()]
        if tags:
            results = [r for r in results if any(t in r.tags for t in tags)]
        if max_price is not None:
            results = [r for r in results if r.price_pln <= max_price]
        if min_rating > 0:
            results = [r for r in results if r.rating >= min_rating]

        # Sort
        if sort_by == "rating":
            results.sort(key=lambda r: r.rating, reverse=True)
        elif sort_by == "downloads":
            results.sort(key=lambda r: r.downloads, reverse=True)
        elif sort_by == "price":
            results.sort(key=lambda r: r.price_pln)
        elif sort_by == "newest":
            results.sort(key=lambda r: r.created_at, reverse=True)

        return results[:limit]

    def purchase_rule(self, rule_id: str, buyer_id: str) -> bool:
        """Zakup regule — rejestruj transakcje i oblicz revenue share."""
        rule = self._rules.get(rule_id)
        if not rule or rule.status != RuleStatus.PUBLISHED:
            return False

        price = rule.price_pln
        creator_share = price * (rule.revenue_share_pct / 100)
        platform_share = price - creator_share

        # Record transaction
        transaction = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "rule_id": rule_id,
            "buyer_id": buyer_id,
            "rule_price": price,
            "creator_share": creator_share,
            "platform_share": platform_share,
        }
        if rule.author_id not in self._revenue:
            self._revenue[rule.author_id] = []
        self._revenue[rule.author_id].append(transaction)

        rule.downloads += 1
        logger.info("[MARKETPLACE] Rule purchased: %s by %s (%.2f PLN)", rule.name, buyer_id, price)
        return True

    def get_creator_revenue(self, author_id: str, period: str | None = None) -> RevenueReport:
        """Pobierz raport przychodow dla twórcy."""
        transactions = self._revenue.get(author_id, [])

        if period:
            transactions = [t for t in transactions if t["timestamp"].startswith(period)]

        gross = sum(t["rule_price"] for t in transactions)
        creator = sum(t["creator_share"] for t in transactions)
        platform = sum(t["platform_share"] for t in transactions)

        unique_rules = len(set(t["rule_id"] for t in transactions))

        return RevenueReport(
            author_id=author_id,
            period=period or "all",
            total_rules=unique_rules,
            total_downloads=len(transactions),
            gross_revenue=gross,
            creator_share=creator,
            platform_share=platform,
        )

    # ── Bundles ────────────────────────────────────────────────────────────

    def create_bundle(self, bundle: RuleBundle) -> str:
        """Stworz pakiet regul tematycznych."""
        self._bundles[bundle.bundle_id] = bundle
        logger.info("[MARKETPLACE] Bundle created: %s (%d rules)", bundle.name, len(bundle.rule_ids))
        return bundle.bundle_id

    def get_bundle(self, bundle_id: str) -> RuleBundle | None:
        """Pobierz pakiet po ID."""
        return self._bundles.get(bundle_id)

    # ── Rating ─────────────────────────────────────────────────────────────

    def rate_rule(self, rule_id: str, rating: float, review: str = "") -> bool:
        """Ocen regule (1-5 gwiazdek)."""
        rule = self._rules.get(rule_id)
        if not rule or not (1.0 <= rating <= 5.0):
            return False

        # Update rolling average
        total = rule.rating * rule.reviews_count + rating
        rule.reviews_count += 1
        rule.rating = round(total / rule.reviews_count, 1)

        logger.info("[MARKETPLACE] Rule rated: %s → %.1f stars (%d reviews)",
                    rule.name, rule.rating, rule.reviews_count)
        return True
