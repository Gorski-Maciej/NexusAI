"""
Priority Engine — deterministyczny wybór reguły first-match-wins.

Element 1 z dokumentu: rozstrzyganie konfliktów między regułami
oraz sortowanie według priorytetu.

Zasady:
  - Niższa wartość priority = wyższy priorytet (0 = najwyższy)
  - First-match-wins — pierwsza pasująca reguła wygrywa
  - Dla równego priorytetu: stabilne sortowanie (rule_id ASC)
  - W przypadku remisu (ten sam priorytet, obie pasują) — wygrywa ta
    z mniejszym rule_id (determinizm)

Stateless: nie wymaga DuckDB, może być używany w każdym silniku reguł.
"""

from __future__ import annotations

from collections.abc import Callable
from msgspec import Struct, field
from typing import Any

from nexus_ai.core.msgspec_utils import msgspec_loads

class PrioritizedRule(Struct, frozen=True):
    """Reguła z priorytetem, gotowa do ewaluacji.

    Attributes:
        rule_id: UUID reguły.
        condition_sql: SQL WHERE expression do ewaluacji.
        action_json: Surowy JSON action do zwrócenia przy dopasowaniu.
        priority: Niższa liczba = wyższy priorytet.
    """
    rule_id: str
    condition_sql: str
    action_json: str
    priority: int

class MatchResult(Struct):
    """Wynik dopasowania reguły.

    Attributes:
        matched: True jeśli znaleziono pasującą regułę.
        verdict: Słownik werdyktu (deserializowany action_json + _rule_id, _priority).
        rule_id: UUID wygranej reguły.
        priority: Priorytet wygranej reguły.
    """
    matched: bool = False
    verdict: dict[str, Any] = field(default_factory=dict)
    rule_id: str = ""
    priority: int = 0

class PriorityEngine:
    """Priority Engine — ewaluacja reguł first-match-wins z priorytetami.

    Pure stateless utility — no database dependency.

    Usage:
        rules = [PrioritizedRule(...), ...]
        result = PriorityEngine.resolve(rules, evaluate_condition_fn)
        if result.matched:
            return result.verdict
    """

    @staticmethod
    def resolve(
        rules: list[PrioritizedRule],
        evaluate_condition: Callable[[str], bool],
        _tracker: list[dict[str, Any]] | None = None,
    ) -> MatchResult:
        """Znajdź pierwszą pasującą regułę (first-match-wins).

        Reguły muszą być już posortowane według priorytetu (użyj sort_rules()).
        Iteruje w podanej kolejności i zwraca werdykt pierwszej,
        której warunek SQL zwróci TRUE.

        Args:
            rules: Lista reguł posortowana według priorytetu.
            evaluate_condition: Funkcja przyjmująca condition_sql i zwracająca bool.
            _tracker: Opcjonalna lista do zbierania szczegółów ewaluacji
                każdej reguły (rule_id, condition_sql, result, selected).

        Returns:
            MatchResult z werdyktem pierwszej pasującej reguły.
        """
        for rule in rules:
            try:
                result = evaluate_condition(rule.condition_sql)

                # Record evaluation if tracker provided
                if _tracker is not None:
                    _tracker.append({
                        "rule_id": rule.rule_id,
                        "condition_sql": rule.condition_sql,
                        "result": result,
                        "selected": False,  # Will be updated if this rule wins
                    })

                if result:
                    verdict = msgspec_loads(rule.action_json)
                    verdict["_rule_id"] = rule.rule_id
                    verdict["_priority"] = rule.priority

                    # Mark as selected in tracker
                    if _tracker is not None:
                        _tracker[-1]["selected"] = True

                    return MatchResult(
                        matched=True,
                        verdict=verdict,
                        rule_id=rule.rule_id,
                        priority=rule.priority,
                    )
            except Exception:
                # Log and skip malformed conditions — record failure if tracking
                if _tracker is not None:
                    _tracker.append({
                        "rule_id": rule.rule_id,
                        "condition_sql": rule.condition_sql,
                        "result": False,
                        "selected": False,
                        "error": "Malformed condition"
                    })
                continue

        return MatchResult(matched=False)

    @staticmethod
    def sort_rules(rules: list[PrioritizedRule]) -> list[PrioritizedRule]:
        """Sortuj reguły według priorytetu (deterministycznie).

        Kolejność sortowania:
          1. priority ASC (niższy = wyższy priorytet)
          2. rule_id ASC (stabilny tie-breaker)

        Args:
            rules: Lista reguł do posortowania.

        Returns:
            Nowa, posortowana lista.
        """
        return sorted(rules, key=lambda r: (r.priority, r.rule_id))

    @staticmethod
    def validate_priorities(rules: list[PrioritizedRule]) -> list[dict[str, Any]]:
        """Sprawdź, czy reguły nie mają konfliktów priorytetów.

        Wykrywa reguły o tym samym condition_sql i tym samym priorytecie,
        które mogą powodować niedeterministyczny wybór.

        Args:
            rules: Lista reguł do sprawdzenia.

        Returns:
            Lista ostrzeżeń (pusta = brak konfliktów).
        """
        warnings: list[dict[str, Any]] = []
        groups: dict[tuple[str, int], list[str]] = {}
        for rule in rules:
            key = (rule.condition_sql, rule.priority)
            groups.setdefault(key, []).append(rule.rule_id)

        for (condition, priority), rule_ids in groups.items():
            if len(rule_ids) > 1:
                warnings.append({
                    "condition_sql": condition,
                    "priority": priority,
                    "rule_ids": rule_ids,
                    "warning": (
                        f"Rule conflict: {len(rule_ids)} rules with same "
                        f"condition and priority={priority}."
                    ),
                })
        return warnings
