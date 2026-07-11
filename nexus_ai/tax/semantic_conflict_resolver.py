"""
Semantic Conflict Resolution (A3) — Deterministyczne rozstrzyganie konfliktów.
================================================================================

Część strategicznego planu 29_JDG_STRATEGIC_IMPROVEMENTS.md.
Wykrywa i rozwiązuje konflikty między passami OPA, zamiast cicho nadpisywać
klucze przez object.union().

Eliminuje błędy typu P914 (VAT błędnie zakładał brak zdrowotnej w zawieszeniu).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Callable

# ── Domain Authority ──────────────────────────────────────────────────────────


class Domain(Enum):
    """Domeny w architekturze Multi-Pass."""
    RISK = "risk"
    ROUTING = "routing"
    COMPLIANCE = "compliance"
    CROSSBORDER = "crossborder"
    VAT = "vat"
    PIT = "pit"
    ALLOWANCES = "allowances"
    ACCOUNTING = "accounting"
    ZUS = "zus"
    BUSINESS = "business"


# ── Conflict Severity ─────────────────────────────────────────────────────────


class Severity(Enum):
    """Severity konfliktu między domenami."""
    CRITICAL = "CRITICAL"   # Zatrzymaj przetwarzanie
    HIGH = "HIGH"           # Zastosuj regułę, ale loguj jako błąd
    WARNING = "WARNING"     # Zastosuj regułę, loguj jako warning
    INFO = "INFO"           # Zastosuj regułę, loguj jako info


# ── Conflict Rule ─────────────────────────────────────────────────────────────


@dataclass
class ConflictRule:
    """Pojedyncza reguła rozstrzygania konfliktu między domenami."""
    name: str
    domains: tuple[Domain, Domain]
    condition: Callable[[dict[str, Any], dict[str, Any]], bool]
    resolution: str  # "PREFER_DOMAIN_A", "PREFER_DOMAIN_B", "CAP_VALUE", "RAISE"
    severity: Severity
    message: str
    prefer_domain: Domain | None = None  # Która domena wygrywa
    field_authority: dict[str, Domain] = field(default_factory=dict)
    # Która domena jest autorytatywna dla których pól


# ── Semantic Conflict Resolver ────────────────────────────────────────────────


class VerdictConflictError(Exception):
    """Wyjątek rzucany gdy wystąpi krytyczny konflikt między passami."""
    def __init__(self, rule: ConflictRule, details: dict[str, Any]) -> None:
        self.rule = rule
        self.details = details
        super().__init__(f"CRITICAL conflict: {rule.message}")


class SemanticConflictResolver:
    """Wykrywa i rozwiązuje konflikty między werdyktami z różnych passów.

    Przed scaleniem werdyktów przez object.union(), sprawdza macierz
    konfliktów i stosuje deterministyczne reguły rozstrzygania.

    Example:
        >>> resolver = SemanticConflictResolver()
        >>> vat_verdict = {"zus_health_due": False, "zus_health_rate": "0.00"}
        >>> zus_verdict = {"zus_health_due": True, "zus_health_rate": "0.09"}
        >>> resolved = resolver.resolve({
        ...     "vat": vat_verdict,
        ...     "zus": zus_verdict
        ... })
        >>> # Konflikt wykryty: VAT błędnie zakłada brak zdrowotnej
        >>> # Resolution: PREFER_ZUS → zus_health_due: True
        >>> assert resolved["zus_health_due"] is True
    """

    def __init__(self) -> None:
        self._rules: list[ConflictRule] = self._build_default_rules()

    @staticmethod
    def _build_default_rules() -> list[ConflictRule]:
        """Buduje domyślną macierz konfliktów."""
        return [
            # ── VAT vs ZUS ──
            ConflictRule(
                name="vat_zus_health_due_conflict",
                domains=(Domain.VAT, Domain.ZUS),
                condition=lambda vat, zus: (
                    vat.get("zus_health_due") is False
                    and zus.get("zus_health_due") is True
                ),
                resolution="PREFER_DOMAIN_B",
                severity=Severity.CRITICAL,
                message="Konflikt VAT-ZUS: VAT błędnie zakłada brak zdrowotnej "
                        "(ZUS jest autorytatywny dla składek)",
                prefer_domain=Domain.ZUS,
            ),
            ConflictRule(
                name="vat_zus_health_rate_conflict",
                domains=(Domain.VAT, Domain.ZUS),
                condition=lambda vat, zus: (
                    vat.get("zus_health_rate", "") == "0.00"
                    and zus.get("zus_health_rate", "") not in ("", "0.00")
                ),
                resolution="PREFER_DOMAIN_B",
                severity=Severity.HIGH,
                message="Konflikt VAT-ZUS: VAT zeruje stawkę zdrowotną, "
                        "ZUS ustawia poprawną",
                prefer_domain=Domain.ZUS,
            ),

            # ── PIT vs Allowances ──
            ConflictRule(
                name="pit_allowances_income_cap",
                domains=(Domain.PIT, Domain.ALLOWANCES),
                condition=lambda pit, allowances: (
                    allowances.get("total_reliefs", 0)
                    > pit.get("taxable_income", 0)
                ),
                resolution="CAP_VALUE",
                severity=Severity.WARNING,
                message="Suma ulg przekracza dochód — ograniczono do wysokości dochodu",
            ),

            # ── Allowances vs ZUS ──
            ConflictRule(
                name="allowances_zus_health_deduction",
                domains=(Domain.ALLOWANCES, Domain.ZUS),
                condition=lambda allowances, zus: (
                    allowances.get("zus_health_deductible_override") is not None
                    and zus.get("zus_health_deductible_from_tax") is not None
                ),
                resolution="PREFER_DOMAIN_B",
                severity=Severity.HIGH,
                message="Konflikt Allowances-ZUS: ZUS jest autorytatywny "
                        "dla odliczeń składek",
                prefer_domain=Domain.ZUS,
            ),

            # ── Business vs ZUS ──
            ConflictRule(
                name="business_zus_suspension_conflict",
                domains=(Domain.BUSINESS, Domain.ZUS),
                condition=lambda business, zus: (
                    business.get("business_status") == "SUSPENDED"
                    and business.get("zus_social_due") is False
                    and zus.get("zus_social_due") is True
                ),
                resolution="PREFER_DOMAIN_A",
                severity=Severity.INFO,
                message="Business (P914) nadpisuje ZUS: zawieszenie → społeczne=0",
                prefer_domain=Domain.BUSINESS,
            ),
        ]

    def resolve(
        self, passes: dict[str, dict[str, Any]]
    ) -> tuple[dict[str, Any], list[dict[str, Any]]]:
        """Rozwiązuje konflikty między passami i zwraca scalony werdykt.

        Returns:
            Tuple of (merged_verdict, conflict_log).
        """
        conflicts_log: list[dict[str, Any]] = []

        # Sprawdź każdą parę domen pod kątem konfliktów
        for rule in self._rules:
            domain_a = rule.domains[0].value
            domain_b = rule.domains[1].value

            if domain_a not in passes or domain_b not in passes:
                continue

            if rule.condition(passes[domain_a], passes[domain_b]):
                conflict_entry = {
                    "rule": rule.name,
                    "severity": rule.severity.value,
                    "resolution": rule.resolution,
                    "message": rule.message,
                }

                if rule.severity == Severity.CRITICAL:
                    raise VerdictConflictError(rule, {
                        "domain_a": domain_a,
                        "domain_b": domain_b,
                        "verdict_a": passes[domain_a],
                        "verdict_b": passes[domain_b],
                    })

                # Zastosuj regułę rozstrzygania
                if rule.resolution == "PREFER_DOMAIN_A":
                    passes = self._apply_preference(passes, rule, domain_a, domain_b)
                elif rule.resolution == "PREFER_DOMAIN_B":
                    passes = self._apply_preference(passes, rule, domain_b, domain_a)
                elif rule.resolution == "CAP_VALUE":
                    passes = self._apply_cap(passes, domain_a, domain_b)

                conflicts_log.append(conflict_entry)

        # Scalanie: kolejność według priorytetu domen
        merge_order = [
            Domain.RISK, Domain.ROUTING, Domain.COMPLIANCE,
            Domain.CROSSBORDER, Domain.VAT, Domain.PIT,
            Domain.ALLOWANCES, Domain.ACCOUNTING, Domain.ZUS, Domain.BUSINESS,
        ]

        merged: dict[str, Any] = {}
        for domain in merge_order:
            if domain.value in passes:
                for key, value in passes[domain.value].items():
                    if key == "_warnings":
                        merged.setdefault(key, []).extend(
                            value if isinstance(value, list) else [value]
                        )
                    elif value not in ("", None):
                        merged[key] = value

        merged["_conflicts"] = conflicts_log
        return merged, conflicts_log

    @staticmethod
    def _apply_preference(
        passes: dict[str, dict[str, Any]],
        rule: ConflictRule,
        winner: str,
        loser: str,
    ) -> dict[str, dict[str, Any]]:
        """Preferuje wartości z domeny winner.
        
        Usuwa konfliktujące pola z przegrywającej domeny — wartości
        z wygrywającej zostaną użyte przy późniejszym mergowaniu.
        """
        # Pola, które domena ZUS kontroluje (nie powinny być nadpisywane przez inne)
        ZUS_AUTHORITY_FIELDS = {
            "zus_health_rate", "zus_health_due", "zus_social_due",
            "zus_social_base_type", "zus_social_base_percent",
            "zus_health_base", "zus_health_deductible_from_tax",
            "zus_health_limit_type", "zus_health_tier",
        }
        
        if winner == "zus" and loser in passes:
            # Usuń pola ZUS z przegrywającej domeny
            passes[loser] = {
                k: v for k, v in passes[loser].items()
                if k not in ZUS_AUTHORITY_FIELDS
            }
        
        return passes

    @staticmethod
    def _apply_cap(
        passes: dict[str, dict[str, Any]],
        domain_a: str,
        domain_b: str,
    ) -> dict[str, dict[str, Any]]:
        """Ogranicza wartość do limitu."""
        if "total_reliefs" in passes.get(domain_b, {}):
            income = passes.get(domain_a, {}).get("taxable_income", 0)
            passes[domain_b]["total_reliefs"] = min(
                passes[domain_b]["total_reliefs"], income
            )
        return passes
