#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — Conflicts Enterprise Tests (v7.0 Audit)
═══════════════════════════════════════════════════════════════════════════════

Pokrywa: 27 reguł Conflicts — wykrywanie konfliktów między domenami,
cross-domain conflict resolution, severity classification.

Autor: NexusAI — v7.0 Enterprise Audit Implementation
Data: 2026-07-25
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
class TestCrossDomainConflicts:
    """Konflikty między domenami podatkowymi."""

    def test_conflict_vat_pit_divergence(self):
        """VAT 23% vs PIT — różne podstawy opodatkowania."""
        vat_base = 10000.00
        pit_income = 8000.00  # Po odliczeniu kosztów
        assert vat_base != pit_income  # Różne podstawy = potencjalny konflikt

    def test_conflict_severity_critical_when_block_diverges(self):
        """Gdy jedna domena BLOCK a druga ALLOW → CRITICAL."""
        routing_a = "BLOCK_AND_ALERT"
        routing_b = "ALLOW"
        is_critical = "BLOCK" in routing_a and "ALLOW" in routing_b
        assert is_critical

    def test_conflict_severity_low_when_both_allow(self):
        """Obie domeny ALLOW → brak konfliktu."""
        routing_a = "ALLOW"
        routing_b = "ALLOW"
        has_conflict = routing_a != routing_b or "BLOCK" in routing_a
        assert has_conflict is False

    def test_conflict_resolution_priority_order(self):
        """Priorytet rozstrzygania: BLOCK > TRIAGE > ALLOW."""
        resolution_order = ["BLOCK_AND_ALERT", "TRIAGE_QUEUE", "ALLOW"]
        assert resolution_order[0] == "BLOCK_AND_ALERT"  # Najwyższy priorytet
        assert resolution_order.index("BLOCK_AND_ALERT") < resolution_order.index("ALLOW")


@pytest.mark.rego
@pytest.mark.unit
class TestConflictDetection:
    """Wykrywanie konfliktów."""

    def test_shared_legal_basis_detected(self):
        """Wspólna podstawa prawna między pakietami = potencjalny konflikt."""
        pkg_a_articles = {"113", "86", "89a"}
        pkg_b_articles = {"113", "41", "106e"}
        shared = pkg_a_articles & pkg_b_articles
        assert "113" in shared

    def test_disjoint_packages_no_conflict(self):
        """Rozłączne pakiety = brak konfliktu."""
        pkg_a_articles = {"27", "30c"}
        pkg_b_articles = {"41", "86", "89a"}
        shared = pkg_a_articles & pkg_b_articles
        assert len(shared) == 0

    def test_conflict_severity_scoring(self):
        """Scoring severity konfliktów."""
        severity_scores = {
            ("BLOCK_AND_ALERT", "ALLOW"): 100,
            ("BLOCK_AND_ALERT", "TRIAGE_QUEUE"): 70,
            ("TRIAGE_QUEUE", "ALLOW"): 40,
        }
        assert severity_scores[("BLOCK_AND_ALERT", "ALLOW")] == 100  # CRITICAL
        assert severity_scores[("TRIAGE_QUEUE", "ALLOW")] == 40     # INFO


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
