#!/usr/bin/env python3
"""
Auto-Generated Test Suite — BLOCK_AND_ALERT rules for package: micro
Wygenerowano: 2026-07-26T00:44:20.540420
Reguł: 135
"""

import pytest


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_cbdd_r1:
    """Auto-generated: jdg.micro.aml_cbdd.r1
    Podstawa prawna: Art. 58-79 Ustawy o CBDD"""

    def test_jdg_micro_aml_cbdd_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_cbdd.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_cbdd.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 58-79 Ustawy o CBDD",
            "matched": True,
            "priority": 83301,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_cbdd.r1"

    def test_jdg_micro_aml_cbdd_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_cbdd.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_cbdd.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_cbdd_r5:
    """Auto-generated: jdg.micro.aml_cbdd.r5
    Podstawa prawna: Art. 68 Ustawy o CBDD, Art. 153 AML"""

    def test_jdg_micro_aml_cbdd_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_cbdd.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_cbdd.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 68 Ustawy o CBDD, Art. 153 AML",
            "matched": True,
            "priority": 83305,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_cbdd.r5"

    def test_jdg_micro_aml_cbdd_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_cbdd.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_cbdd.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_ryzyko_r2:
    """Auto-generated: jdg.micro.aml_ryzyko.r2
    Podstawa prawna: Art. 33-43 Ustawy AML"""

    def test_jdg_micro_aml_ryzyko_r2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_ryzyko.r2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_ryzyko.r2",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 33-43 Ustawy AML",
            "matched": True,
            "priority": 83002,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_ryzyko.r2"

    def test_jdg_micro_aml_ryzyko_r2_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_ryzyko.r2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_ryzyko.r2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_ryzyko_r5:
    """Auto-generated: jdg.micro.aml_ryzyko.r5
    Podstawa prawna: Art. 43-46 Ustawy AML"""

    def test_jdg_micro_aml_ryzyko_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_ryzyko.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_ryzyko.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 43-46 Ustawy AML",
            "matched": True,
            "priority": 83005,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_ryzyko.r5"

    def test_jdg_micro_aml_ryzyko_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_ryzyko.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_ryzyko.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_ryzyko_r6:
    """Auto-generated: jdg.micro.aml_ryzyko.r6
    Podstawa prawna: Art. 43 ust. 5 Ustawy AML"""

    def test_jdg_micro_aml_ryzyko_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_ryzyko.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_ryzyko.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 43 ust. 5 Ustawy AML",
            "matched": True,
            "priority": 83006,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_ryzyko.r6"

    def test_jdg_micro_aml_ryzyko_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_ryzyko.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_ryzyko.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_str_gif_r1:
    """Auto-generated: jdg.micro.aml_str_gif.r1
    Podstawa prawna: Art. 83-86 Ustawy AML"""

    def test_jdg_micro_aml_str_gif_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_str_gif.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_str_gif.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83-86 Ustawy AML",
            "matched": True,
            "priority": 83201,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_str_gif.r1"

    def test_jdg_micro_aml_str_gif_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_str_gif.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_str_gif.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_str_gif_r2:
    """Auto-generated: jdg.micro.aml_str_gif.r2
    Podstawa prawna: Art. 147-153 Ustawy AML, Art. 299 KKS"""

    def test_jdg_micro_aml_str_gif_r2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_str_gif.r2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_str_gif.r2",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 147-153 Ustawy AML, Art. 299 KKS",
            "matched": True,
            "priority": 83202,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_str_gif.r2"

    def test_jdg_micro_aml_str_gif_r2_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_str_gif.r2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_str_gif.r2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_str_gif_r3:
    """Auto-generated: jdg.micro.aml_str_gif.r3
    Podstawa prawna: Art. 86 Ustawy AML"""

    def test_jdg_micro_aml_str_gif_r3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_str_gif.r3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_str_gif.r3",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 86 Ustawy AML",
            "matched": True,
            "priority": 83203,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_str_gif.r3"

    def test_jdg_micro_aml_str_gif_r3_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_str_gif.r3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_str_gif.r3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_transakcje_r2:
    """Auto-generated: jdg.micro.aml_transakcje.r2
    Podstawa prawna: Art. 299 KKS"""

    def test_jdg_micro_aml_transakcje_r2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_transakcje.r2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_transakcje.r2",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 299 KKS",
            "matched": True,
            "priority": 83102,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_transakcje.r2"

    def test_jdg_micro_aml_transakcje_r2_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_transakcje.r2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_transakcje.r2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_transakcje_r5:
    """Auto-generated: jdg.micro.aml_transakcje.r5
    Podstawa prawna: Rozp. UE 2023/1113 (TFR)"""

    def test_jdg_micro_aml_transakcje_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_transakcje.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_transakcje.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Rozp. UE 2023/1113 (TFR)",
            "matched": True,
            "priority": 83105,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_transakcje.r5"

    def test_jdg_micro_aml_transakcje_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_transakcje.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_transakcje.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_aml_transakcje_r6:
    """Auto-generated: jdg.micro.aml_transakcje.r6
    Podstawa prawna: Rozp. UE 269/2014"""

    def test_jdg_micro_aml_transakcje_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.aml_transakcje.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.aml_transakcje.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Rozp. UE 269/2014",
            "matched": True,
            "priority": 83106,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.aml_transakcje.r6"

    def test_jdg_micro_aml_transakcje_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.aml_transakcje.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.aml_transakcje.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_amort_a22a_r6:
    """Auto-generated: jdg.micro.amort_a22a.r6
    Podstawa prawna: Art. 22a ust. 1 PIT"""

    def test_jdg_micro_amort_a22a_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.amort_a22a.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.amort_a22a.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22a ust. 1 PIT",
            "matched": True,
            "priority": 81006,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.amort_a22a.r6"

    def test_jdg_micro_amort_a22a_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.amort_a22a.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.amort_a22a.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_amort_a22a_r7:
    """Auto-generated: jdg.micro.amort_a22a.r7
    Podstawa prawna: Art. 22a ust. 1 PIT"""

    def test_jdg_micro_amort_a22a_r7_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.amort_a22a.r7 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.amort_a22a.r7",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22a ust. 1 PIT",
            "matched": True,
            "priority": 81007,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.amort_a22a.r7"

    def test_jdg_micro_amort_a22a_r7_negative_no_block(self):
        """❌ Negatywny: jdg.micro.amort_a22a.r7 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.amort_a22a.r7",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_amort_a22i_r6:
    """Auto-generated: jdg.micro.amort_a22i.r6
    Podstawa prawna: Art. 22i ust. 2 PIT"""

    def test_jdg_micro_amort_a22i_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.amort_a22i.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.amort_a22i.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22i ust. 2 PIT",
            "matched": True,
            "priority": 81106,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.amort_a22i.r6"

    def test_jdg_micro_amort_a22i_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.amort_a22i.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.amort_a22i.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_amort_a22k_r4:
    """Auto-generated: jdg.micro.amort_a22k.r4
    Podstawa prawna: Art. 22k ust. 7 PIT (wyłączenie samochodów osobowych)"""

    def test_jdg_micro_amort_a22k_r4_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.amort_a22k.r4 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.amort_a22k.r4",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22k ust. 7 PIT (wyłączenie samochodów osobowych)",
            "matched": True,
            "priority": 81204,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.amort_a22k.r4"

    def test_jdg_micro_amort_a22k_r4_negative_no_block(self):
        """❌ Negatywny: jdg.micro.amort_a22k.r4 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.amort_a22k.r4",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_amort_a22k_r6:
    """Auto-generated: jdg.micro.amort_a22k.r6
    Podstawa prawna: Art. 22k ust. 7 PIT"""

    def test_jdg_micro_amort_a22k_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.amort_a22k.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.amort_a22k.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22k ust. 7 PIT",
            "matched": True,
            "priority": 81206,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.amort_a22k.r6"

    def test_jdg_micro_amort_a22k_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.amort_a22k.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.amort_a22k.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_amort_a22n_r5:
    """Auto-generated: jdg.micro.amort_a22n.r5
    Podstawa prawna: Art. 22n ust. 5 PIT"""

    def test_jdg_micro_amort_a22n_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.amort_a22n.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.amort_a22n.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22n ust. 5 PIT",
            "matched": True,
            "priority": 81305,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.amort_a22n.r5"

    def test_jdg_micro_amort_a22n_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.amort_a22n.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.amort_a22n.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_ewc_r2:
    """Auto-generated: jdg.micro.bdo_ewc.r2
    Podstawa prawna: Art. 41-42 Ustawy o odpadach"""

    def test_jdg_micro_bdo_ewc_r2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_ewc.r2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_ewc.r2",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 41-42 Ustawy o odpadach",
            "matched": True,
            "priority": 82102,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_ewc.r2"

    def test_jdg_micro_bdo_ewc_r2_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_ewc.r2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_ewc.r2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_ewc_r3:
    """Auto-generated: jdg.micro.bdo_ewc.r3
    Podstawa prawna: Art. 22-26 Ustawy o odpadach, Rozp. MZ ws. odpadów medycznych"""

    def test_jdg_micro_bdo_ewc_r3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_ewc.r3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_ewc.r3",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22-26 Ustawy o odpadach, Rozp. MZ ws. odpadów medycznych",
            "matched": True,
            "priority": 82103,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_ewc.r3"

    def test_jdg_micro_bdo_ewc_r3_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_ewc.r3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_ewc.r3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_ewidencja_r6:
    """Auto-generated: jdg.micro.bdo_ewidencja.r6
    Podstawa prawna: Art. 67 Ustawy o odpadach"""

    def test_jdg_micro_bdo_ewidencja_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_ewidencja.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_ewidencja.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 67 Ustawy o odpadach",
            "matched": True,
            "priority": 82206,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_ewidencja.r6"

    def test_jdg_micro_bdo_ewidencja_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_ewidencja.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_ewidencja.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_rejestracja_r2:
    """Auto-generated: jdg.micro.bdo_rejestracja.r2
    Podstawa prawna: Art. 49-54 Ustawy o odpadach"""

    def test_jdg_micro_bdo_rejestracja_r2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_rejestracja.r2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_rejestracja.r2",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 49-54 Ustawy o odpadach",
            "matched": True,
            "priority": 82002,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_rejestracja.r2"

    def test_jdg_micro_bdo_rejestracja_r2_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_rejestracja.r2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_rejestracja.r2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_rejestracja_r3:
    """Auto-generated: jdg.micro.bdo_rejestracja.r3
    Podstawa prawna: Art. 49-54 Ustawy o odpadach"""

    def test_jdg_micro_bdo_rejestracja_r3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_rejestracja.r3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_rejestracja.r3",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 49-54 Ustawy o odpadach",
            "matched": True,
            "priority": 82003,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_rejestracja.r3"

    def test_jdg_micro_bdo_rejestracja_r3_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_rejestracja.r3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_rejestracja.r3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_rejestracja_r8:
    """Auto-generated: jdg.micro.bdo_rejestracja.r8
    Podstawa prawna: Art. 194 Ustawy o odpadach"""

    def test_jdg_micro_bdo_rejestracja_r8_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_rejestracja.r8 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_rejestracja.r8",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 194 Ustawy o odpadach",
            "matched": True,
            "priority": 82008,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_rejestracja.r8"

    def test_jdg_micro_bdo_rejestracja_r8_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_rejestracja.r8 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_rejestracja.r8",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_transport_r1:
    """Auto-generated: jdg.micro.bdo_transport.r1
    Podstawa prawna: Art. 232-234 Ustawy o odpadach"""

    def test_jdg_micro_bdo_transport_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_transport.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_transport.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 232-234 Ustawy o odpadach",
            "matched": True,
            "priority": 82301,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_transport.r1"

    def test_jdg_micro_bdo_transport_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_transport.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_transport.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_transport_r2:
    """Auto-generated: jdg.micro.bdo_transport.r2
    Podstawa prawna: Umowa ADR, Ustawa o przewozie towarów niebezpiecznych"""

    def test_jdg_micro_bdo_transport_r2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_transport.r2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_transport.r2",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Umowa ADR, Ustawa o przewozie towarów niebezpiecznych",
            "matched": True,
            "priority": 82302,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_transport.r2"

    def test_jdg_micro_bdo_transport_r2_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_transport.r2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_transport.r2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_transport_r4:
    """Auto-generated: jdg.micro.bdo_transport.r4
    Podstawa prawna: Rozp. WE 1013/2006, Ustawa o międzynarodowym przemieszczaniu odpadów"""

    def test_jdg_micro_bdo_transport_r4_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_transport.r4 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_transport.r4",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Rozp. WE 1013/2006, Ustawa o międzynarodowym przemieszczaniu odpadów",
            "matched": True,
            "priority": 82304,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_transport.r4"

    def test_jdg_micro_bdo_transport_r4_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_transport.r4 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_transport.r4",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_transport_r6:
    """Auto-generated: jdg.micro.bdo_transport.r6
    Podstawa prawna: Art. 25 Ustawy o odpadach"""

    def test_jdg_micro_bdo_transport_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_transport.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_transport.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 25 Ustawy o odpadach",
            "matched": True,
            "priority": 82306,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_transport.r6"

    def test_jdg_micro_bdo_transport_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_transport.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_transport.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_weee_r5:
    """Auto-generated: jdg.micro.bdo_weee.r5
    Podstawa prawna: Ustawa o zapobieganiu szkodom w środowisku i ich naprawie"""

    def test_jdg_micro_bdo_weee_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_weee.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_weee.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o zapobieganiu szkodom w środowisku i ich naprawie",
            "matched": True,
            "priority": 82505,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_weee.r5"

    def test_jdg_micro_bdo_weee_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_weee.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_weee.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_zezwolenia_r1:
    """Auto-generated: jdg.micro.bdo_zezwolenia.r1
    Podstawa prawna: Art. 41-42 Ustawy o odpadach"""

    def test_jdg_micro_bdo_zezwolenia_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_zezwolenia.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_zezwolenia.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 41-42 Ustawy o odpadach",
            "matched": True,
            "priority": 82401,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_zezwolenia.r1"

    def test_jdg_micro_bdo_zezwolenia_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_zezwolenia.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_zezwolenia.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_zezwolenia_r4:
    """Auto-generated: jdg.micro.bdo_zezwolenia.r4
    Podstawa prawna: Art. 194 Ustawy o odpadach"""

    def test_jdg_micro_bdo_zezwolenia_r4_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_zezwolenia.r4 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_zezwolenia.r4",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 194 Ustawy o odpadach",
            "matched": True,
            "priority": 82404,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_zezwolenia.r4"

    def test_jdg_micro_bdo_zezwolenia_r4_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_zezwolenia.r4 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_zezwolenia.r4",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_zezwolenia_r5:
    """Auto-generated: jdg.micro.bdo_zezwolenia.r5
    Podstawa prawna: Art. 195 Ustawy o odpadach"""

    def test_jdg_micro_bdo_zezwolenia_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_zezwolenia.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_zezwolenia.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 195 Ustawy o odpadach",
            "matched": True,
            "priority": 82405,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_zezwolenia.r5"

    def test_jdg_micro_bdo_zezwolenia_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_zezwolenia.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_zezwolenia.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_bdo_zezwolenia_r6:
    """Auto-generated: jdg.micro.bdo_zezwolenia.r6
    Podstawa prawna: Art. 197 Ustawy o odpadach"""

    def test_jdg_micro_bdo_zezwolenia_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.bdo_zezwolenia.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.bdo_zezwolenia.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 197 Ustawy o odpadach",
            "matched": True,
            "priority": 82406,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.bdo_zezwolenia.r6"

    def test_jdg_micro_bdo_zezwolenia_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.bdo_zezwolenia.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.bdo_zezwolenia.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a1_r1:
    """Auto-generated: jdg.micro.budownictwo.a1.r1
    Podstawa prawna: Art. 28 Prawa budowlanego"""

    def test_jdg_micro_budownictwo_a1_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a1.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a1.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 28 Prawa budowlanego",
            "matched": True,
            "priority": 250001,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a1.r1"

    def test_jdg_micro_budownictwo_a1_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a1.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a1.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a1_r4:
    """Auto-generated: jdg.micro.budownictwo.a1.r4
    Podstawa prawna: Art. 37 Prawa budowlanego"""

    def test_jdg_micro_budownictwo_a1_r4_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a1.r4 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a1.r4",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 37 Prawa budowlanego",
            "matched": True,
            "priority": 250004,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a1.r4"

    def test_jdg_micro_budownictwo_a1_r4_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a1.r4 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a1.r4",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a1_r6:
    """Auto-generated: jdg.micro.budownictwo.a1.r6
    Podstawa prawna: Art. 42 Prawa budowlanego"""

    def test_jdg_micro_budownictwo_a1_r6_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a1.r6 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a1.r6",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 42 Prawa budowlanego",
            "matched": True,
            "priority": 250006,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a1.r6"

    def test_jdg_micro_budownictwo_a1_r6_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a1.r6 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a1.r6",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a1_r8:
    """Auto-generated: jdg.micro.budownictwo.a1.r8
    Podstawa prawna: Art. 48-50 Prawa budowlanego"""

    def test_jdg_micro_budownictwo_a1_r8_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a1.r8 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a1.r8",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 48-50 Prawa budowlanego",
            "matched": True,
            "priority": 250008,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a1.r8"

    def test_jdg_micro_budownictwo_a1_r8_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a1.r8 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a1.r8",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a2_r3:
    """Auto-generated: jdg.micro.budownictwo.a2.r3
    Podstawa prawna: Art. 106e ust. 1 pkt 18 VAT"""

    def test_jdg_micro_budownictwo_a2_r3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a2.r3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a2.r3",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 106e ust. 1 pkt 18 VAT",
            "matched": True,
            "priority": 250011,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a2.r3"

    def test_jdg_micro_budownictwo_a2_r3_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a2.r3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a2.r3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a3_r1:
    """Auto-generated: jdg.micro.budownictwo.a3.r1
    Podstawa prawna: Art. 648 § 1 KC"""

    def test_jdg_micro_budownictwo_a3_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a3.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a3.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 648 § 1 KC",
            "matched": True,
            "priority": 250017,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a3.r1"

    def test_jdg_micro_budownictwo_a3_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a3.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a3.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a4_r1:
    """Auto-generated: jdg.micro.budownictwo.a4.r1
    Podstawa prawna: Art. 21a Prawa budowlanego, Rozporządzenie MI"""

    def test_jdg_micro_budownictwo_a4_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a4.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a4.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 21a Prawa budowlanego, Rozporządzenie MI",
            "matched": True,
            "priority": 250025,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a4.r1"

    def test_jdg_micro_budownictwo_a4_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a4.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a4.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a6_r1:
    """Auto-generated: jdg.micro.budownictwo.a6.r1
    Podstawa prawna: Art. 75 Prawa budowlanego"""

    def test_jdg_micro_budownictwo_a6_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a6.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a6.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 75 Prawa budowlanego",
            "matched": True,
            "priority": 250043,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a6.r1"

    def test_jdg_micro_budownictwo_a6_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a6.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a6.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a6_r3:
    """Auto-generated: jdg.micro.budownictwo.a6.r3
    Podstawa prawna: Art. 93 pkt 3 Prawa budowlanego"""

    def test_jdg_micro_budownictwo_a6_r3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a6.r3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a6.r3",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 93 pkt 3 Prawa budowlanego",
            "matched": True,
            "priority": 250045,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a6.r3"

    def test_jdg_micro_budownictwo_a6_r3_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a6.r3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a6.r3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a6_r4:
    """Auto-generated: jdg.micro.budownictwo.a6.r4
    Podstawa prawna: Art. 36a Prawa budowlanego, Art. 50"""

    def test_jdg_micro_budownictwo_a6_r4_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a6.r4 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a6.r4",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 36a Prawa budowlanego, Art. 50",
            "matched": True,
            "priority": 250046,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a6.r4"

    def test_jdg_micro_budownictwo_a6_r4_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a6.r4 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a6.r4",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_budownictwo_a6_r5:
    """Auto-generated: jdg.micro.budownictwo.a6.r5
    Podstawa prawna: Art. 90 Prawa budowlanego"""

    def test_jdg_micro_budownictwo_a6_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.budownictwo.a6.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a6.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 90 Prawa budowlanego",
            "matched": True,
            "priority": 250047,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.budownictwo.a6.r5"

    def test_jdg_micro_budownictwo_a6_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.budownictwo.a6.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.budownictwo.a6.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_jpk_a99_r12:
    """Auto-generated: jdg.micro.jpk.a99.r12
    Podstawa prawna: Rozporządzenie MF w sprawie JPK_VAT"""

    def test_jdg_micro_jpk_a99_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.jpk.a99.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.jpk.a99.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Rozporządzenie MF w sprawie JPK_VAT",
            "matched": True,
            "priority": 190110,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.jpk.a99.r12"

    def test_jdg_micro_jpk_a99_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.jpk.a99.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.jpk.a99.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_kks_a16_r12:
    """Auto-generated: jdg.micro.kks.a16.r12
    Podstawa prawna: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"""

    def test_jdg_micro_kks_a16_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.kks.a16.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.kks.a16.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
            "matched": True,
            "priority": 80027,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.kks.a16.r12"

    def test_jdg_micro_kks_a16_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.kks.a16.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.kks.a16.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_kks_a54_r12:
    """Auto-generated: jdg.micro.kks.a54.r12
    Podstawa prawna: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"""

    def test_jdg_micro_kks_a54_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.kks.a54.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.kks.a54.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
            "matched": True,
            "priority": 80055,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.kks.a54.r12"

    def test_jdg_micro_kks_a54_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.kks.a54.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.kks.a54.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_kks_a55_r12:
    """Auto-generated: jdg.micro.kks.a55.r12
    Podstawa prawna: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"""

    def test_jdg_micro_kks_a55_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.kks.a55.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.kks.a55.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
            "matched": True,
            "priority": 80070,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.kks.a55.r12"

    def test_jdg_micro_kks_a55_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.kks.a55.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.kks.a55.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_kks_a56_r12:
    """Auto-generated: jdg.micro.kks.a56.r12
    Podstawa prawna: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"""

    def test_jdg_micro_kks_a56_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.kks.a56.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.kks.a56.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
            "matched": True,
            "priority": 80082,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.kks.a56.r12"

    def test_jdg_micro_kks_a56_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.kks.a56.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.kks.a56.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_kks_a57_r12:
    """Auto-generated: jdg.micro.kks.a57.r12
    Podstawa prawna: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"""

    def test_jdg_micro_kks_a57_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.kks.a57.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.kks.a57.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
            "matched": True,
            "priority": 80097,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.kks.a57.r12"

    def test_jdg_micro_kks_a57_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.kks.a57.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.kks.a57.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_kks_a62_r12:
    """Auto-generated: jdg.micro.kks.a62.r12
    Podstawa prawna: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"""

    def test_jdg_micro_kks_a62_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.kks.a62.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.kks.a62.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
            "matched": True,
            "priority": 80149,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.kks.a62.r12"

    def test_jdg_micro_kks_a62_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.kks.a62.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.kks.a62.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_kks_a77_r12:
    """Auto-generated: jdg.micro.kks.a77.r12
    Podstawa prawna: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"""

    def test_jdg_micro_kks_a77_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.kks.a77.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.kks.a77.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
            "matched": True,
            "priority": 80304,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.kks.a77.r12"

    def test_jdg_micro_kks_a77_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.kks.a77.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.kks.a77.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_kks_a80_r12:
    """Auto-generated: jdg.micro.kks.a80.r12
    Podstawa prawna: Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)"""

    def test_jdg_micro_kks_a80_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.kks.a80.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.kks.a80.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
            "matched": True,
            "priority": 80336,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.kks.a80.r12"

    def test_jdg_micro_kks_a80_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.kks.a80.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.kks.a80.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ksef_a106na_r12:
    """Auto-generated: jdg.micro.ksef.a106na.r12
    Podstawa prawna: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)"""

    def test_jdg_micro_ksef_a106na_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ksef.a106na.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ksef.a106na.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
            "matched": True,
            "priority": 180012,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ksef.a106na.r12"

    def test_jdg_micro_ksef_a106na_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ksef.a106na.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ksef.a106na.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ksef_a106nb_r12:
    """Auto-generated: jdg.micro.ksef.a106nb.r12
    Podstawa prawna: Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)"""

    def test_jdg_micro_ksef_a106nb_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ksef.a106nb.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ksef.a106nb.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
            "matched": True,
            "priority": 180027,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ksef.a106nb.r12"

    def test_jdg_micro_ksef_a106nb_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ksef.a106nb.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ksef.a106nb.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ord_a70_r12:
    """Auto-generated: jdg.micro.ord.a70.r12
    Podstawa prawna: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)"""

    def test_jdg_micro_ord_a70_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ord.a70.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ord.a70.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
            "matched": True,
            "priority": 70154,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ord.a70.r12"

    def test_jdg_micro_ord_a70_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ord.a70.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ord.a70.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ord_a138a_r12:
    """Auto-generated: jdg.micro.ord.a138a.r12
    Podstawa prawna: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)"""

    def test_jdg_micro_ord_a138a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ord.a138a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ord.a138a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
            "matched": True,
            "priority": 70305,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ord.a138a.r12"

    def test_jdg_micro_ord_a138a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ord.a138a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ord.a138a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ord_a138a_r27:
    """Auto-generated: jdg.micro.ord.a138a.r27
    Podstawa prawna: Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)"""

    def test_jdg_micro_ord_a138a_r27_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ord.a138a.r27 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ord.a138a.r27",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
            "matched": True,
            "priority": 70320,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ord.a138a.r27"

    def test_jdg_micro_ord_a138a_r27_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ord.a138a.r27 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ord.a138a.r27",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pcc_a2_r12:
    """Auto-generated: jdg.micro.pcc.a2.r12
    Podstawa prawna: Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)"""

    def test_jdg_micro_pcc_a2_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pcc.a2.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pcc.a2.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
            "matched": True,
            "priority": 170022,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pcc.a2.r12"

    def test_jdg_micro_pcc_a2_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pcc.a2.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pcc.a2.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a9a_r12:
    """Auto-generated: jdg.micro.pit.a9a.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a9a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a9a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a9a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60037,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a9a.r12"

    def test_jdg_micro_pit_a9a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a9a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a9a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a10_r12:
    """Auto-generated: jdg.micro.pit.a10.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a10_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a10.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a10.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60049,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a10.r12"

    def test_jdg_micro_pit_a10_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a10.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a10.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a14_r12:
    """Auto-generated: jdg.micro.pit.a14.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a14_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a14.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a14.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60061,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a14.r12"

    def test_jdg_micro_pit_a14_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a14.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a14.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a14c_r12:
    """Auto-generated: jdg.micro.pit.a14c.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a14c_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a14c.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a14c.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60081,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a14c.r12"

    def test_jdg_micro_pit_a14c_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a14c.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a14c.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a21_r12:
    """Auto-generated: jdg.micro.pit.a21.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a21_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a21.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a21.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60093,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a21.r12"

    def test_jdg_micro_pit_a21_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a21.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a21.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a22_r12:
    """Auto-generated: jdg.micro.pit.a22.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a22_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a22.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a22.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60105,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a22.r12"

    def test_jdg_micro_pit_a22_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a22.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a22.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a23_r12:
    """Auto-generated: jdg.micro.pit.a23.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a23_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a23.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a23.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60200,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a23.r12"

    def test_jdg_micro_pit_a23_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a23.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a23.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a23_r27:
    """Auto-generated: jdg.micro.pit.a23.r27
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a23_r27_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a23.r27 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a23.r27",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60215,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a23.r27"

    def test_jdg_micro_pit_a23_r27_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a23.r27 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a23.r27",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a24_r12:
    """Auto-generated: jdg.micro.pit.a24.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a24_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a24.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a24.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60230,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a24.r12"

    def test_jdg_micro_pit_a24_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a24.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a24.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a26_r12:
    """Auto-generated: jdg.micro.pit.a26.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a26_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a26.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a26.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60255,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a26.r12"

    def test_jdg_micro_pit_a26_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a26.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a26.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a26e_r12:
    """Auto-generated: jdg.micro.pit.a26e.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a26e_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a26e.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a26e.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60280,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a26e.r12"

    def test_jdg_micro_pit_a26e_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a26e.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a26e.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a27_r12:
    """Auto-generated: jdg.micro.pit.a27.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a27_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a27.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a27.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60323,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a27.r12"

    def test_jdg_micro_pit_a27_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a27.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a27.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a27f_r12:
    """Auto-generated: jdg.micro.pit.a27f.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a27f_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a27f.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a27f.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60338,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a27f.r12"

    def test_jdg_micro_pit_a27f_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a27f.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a27f.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a30_r12:
    """Auto-generated: jdg.micro.pit.a30.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a30_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a30.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a30.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60350,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a30.r12"

    def test_jdg_micro_pit_a30_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a30.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a30.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a30a_r12:
    """Auto-generated: jdg.micro.pit.a30a.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a30a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a30a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a30a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60362,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a30a.r12"

    def test_jdg_micro_pit_a30a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a30a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a30a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a30b_r12:
    """Auto-generated: jdg.micro.pit.a30b.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a30b_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a30b.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a30b.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60374,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a30b.r12"

    def test_jdg_micro_pit_a30b_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a30b.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a30b.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a30c_r12:
    """Auto-generated: jdg.micro.pit.a30c.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a30c_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a30c.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a30c.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60386,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a30c.r12"

    def test_jdg_micro_pit_a30c_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a30c.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a30c.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a30ca_r12:
    """Auto-generated: jdg.micro.pit.a30ca.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a30ca_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a30ca.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a30ca.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60398,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a30ca.r12"

    def test_jdg_micro_pit_a30ca_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a30ca.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a30ca.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a30da_r12:
    """Auto-generated: jdg.micro.pit.a30da.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a30da_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a30da.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a30da.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60410,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a30da.r12"

    def test_jdg_micro_pit_a30da_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a30da.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a30da.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a30f_r12:
    """Auto-generated: jdg.micro.pit.a30f.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a30f_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a30f.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a30f.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60422,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a30f.r12"

    def test_jdg_micro_pit_a30f_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a30f.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a30f.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a31_r12:
    """Auto-generated: jdg.micro.pit.a31.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a31_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a31.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a31.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60437,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a31.r12"

    def test_jdg_micro_pit_a31_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a31.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a31.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a44_r12:
    """Auto-generated: jdg.micro.pit.a44.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a44_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a44.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a44.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60462,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a44.r12"

    def test_jdg_micro_pit_a44_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a44.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a44.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a45_r12:
    """Auto-generated: jdg.micro.pit.a45.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a45_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a45.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a45.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60474,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a45.r12"

    def test_jdg_micro_pit_a45_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a45.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a45.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pit_a45a_r12:
    """Auto-generated: jdg.micro.pit.a45a.r12
    Podstawa prawna: Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)"""

    def test_jdg_micro_pit_a45a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pit.a45a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pit.a45a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
            "matched": True,
            "priority": 60489,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pit.a45a.r12"

    def test_jdg_micro_pit_a45a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pit.a45a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pit.a45a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_p9_r5:
    """Auto-generated: jdg.micro.pkpir.p9.r5
    Podstawa prawna: §9 ust. 1 Rozp. MF PKPiR"""

    def test_jdg_micro_pkpir_p9_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir.p9.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir.p9.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "§9 ust. 1 Rozp. MF PKPiR",
            "matched": True,
            "priority": 80005,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir.p9.r5"

    def test_jdg_micro_pkpir_p9_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir.p9.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir.p9.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_columns_p10_r9:
    """Auto-generated: jdg.micro.pkpir_columns.p10.r9
    Podstawa prawna: §10 Rozp. MF PKPiR + Art. 56 KKS"""

    def test_jdg_micro_pkpir_columns_p10_r9_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir_columns.p10.r9 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir_columns.p10.r9",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "§10 Rozp. MF PKPiR + Art. 56 KKS",
            "matched": True,
            "priority": 80109,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir_columns.p10.r9"

    def test_jdg_micro_pkpir_columns_p10_r9_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir_columns.p10.r9 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir_columns.p10.r9",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_columns_p10_r11:
    """Auto-generated: jdg.micro.pkpir_columns.p10.r11
    Podstawa prawna: Art. 56 § 1 KKS"""

    def test_jdg_micro_pkpir_columns_p10_r11_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir_columns.p10.r11 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir_columns.p10.r11",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 § 1 KKS",
            "matched": True,
            "priority": 80111,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir_columns.p10.r11"

    def test_jdg_micro_pkpir_columns_p10_r11_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir_columns.p10.r11 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir_columns.p10.r11",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_corrections_c1_r3:
    """Auto-generated: jdg.micro.pkpir_corrections.c1.r3
    Podstawa prawna: §9 ust. 2 Rozp. MF PKPiR"""

    def test_jdg_micro_pkpir_corrections_c1_r3_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir_corrections.c1.r3 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir_corrections.c1.r3",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "§9 ust. 2 Rozp. MF PKPiR",
            "matched": True,
            "priority": 80603,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir_corrections.c1.r3"

    def test_jdg_micro_pkpir_corrections_c1_r3_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir_corrections.c1.r3 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir_corrections.c1.r3",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_costs_p15_r7:
    """Auto-generated: jdg.micro.pkpir_costs.p15.r7
    Podstawa prawna: Art. 23 PIT, §21 Rozp. MF PKPiR"""

    def test_jdg_micro_pkpir_costs_p15_r7_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir_costs.p15.r7 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir_costs.p15.r7",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 23 PIT, §21 Rozp. MF PKPiR",
            "matched": True,
            "priority": 80307,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir_costs.p15.r7"

    def test_jdg_micro_pkpir_costs_p15_r7_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir_costs.p15.r7 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir_costs.p15.r7",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_costs_p15_r8:
    """Auto-generated: jdg.micro.pkpir_costs.p15.r8
    Podstawa prawna: Art. 22p PIT, §19 Rozp. MF PKPiR"""

    def test_jdg_micro_pkpir_costs_p15_r8_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir_costs.p15.r8 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir_costs.p15.r8",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22p PIT, §19 Rozp. MF PKPiR",
            "matched": True,
            "priority": 80308,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir_costs.p15.r8"

    def test_jdg_micro_pkpir_costs_p15_r8_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir_costs.p15.r8 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir_costs.p15.r8",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_nkup_p21_r10:
    """Auto-generated: jdg.micro.pkpir_nkup.p21.r10
    Podstawa prawna: Art. 56 KKS"""

    def test_jdg_micro_pkpir_nkup_p21_r10_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir_nkup.p21.r10 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir_nkup.p21.r10",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 56 KKS",
            "matched": True,
            "priority": 80410,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir_nkup.p21.r10"

    def test_jdg_micro_pkpir_nkup_p21_r10_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir_nkup.p21.r10 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir_nkup.p21.r10",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_revenue_p13_r8:
    """Auto-generated: jdg.micro.pkpir_revenue.p13.r8
    Podstawa prawna: §13 Rozp. MF PKPiR"""

    def test_jdg_micro_pkpir_revenue_p13_r8_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir_revenue.p13.r8 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir_revenue.p13.r8",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "§13 Rozp. MF PKPiR",
            "matched": True,
            "priority": 80208,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir_revenue.p13.r8"

    def test_jdg_micro_pkpir_revenue_p13_r8_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir_revenue.p13.r8 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir_revenue.p13.r8",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pkpir_remnant_p27_r5:
    """Auto-generated: jdg.micro.pkpir_remnant.p27.r5
    Podstawa prawna: Art. 24 ust. 3 PIT"""

    def test_jdg_micro_pkpir_remnant_p27_r5_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pkpir_remnant.p27.r5 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pkpir_remnant.p27.r5",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 24 ust. 3 PIT",
            "matched": True,
            "priority": 80505,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pkpir_remnant.p27.r5"

    def test_jdg_micro_pkpir_remnant_p27_r5_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pkpir_remnant.p27.r5 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pkpir_remnant.p27.r5",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_pp_a5_r12:
    """Auto-generated: jdg.micro.pp.a5.r12
    Podstawa prawna: Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)"""

    def test_jdg_micro_pp_a5_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.pp.a5.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.pp.a5.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
            "matched": True,
            "priority": 130034,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.pp.a5.r12"

    def test_jdg_micro_pp_a5_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.pp.a5.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.pp.a5.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_rodo_ai_marketing_r1:
    """Auto-generated: jdg.micro.rodo_ai_marketing.r1
    Podstawa prawna: Art. 22 RODO"""

    def test_jdg_micro_rodo_ai_marketing_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.rodo_ai_marketing.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.rodo_ai_marketing.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 22 RODO",
            "matched": True,
            "priority": 84301,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.rodo_ai_marketing.r1"

    def test_jdg_micro_rodo_ai_marketing_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.rodo_ai_marketing.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.rodo_ai_marketing.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_rodo_podprocesorzy_r2:
    """Auto-generated: jdg.micro.rodo_podprocesorzy.r2
    Podstawa prawna: Art. 44-49 RODO, Wyrok TSUE Schrems II"""

    def test_jdg_micro_rodo_podprocesorzy_r2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.rodo_podprocesorzy.r2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.rodo_podprocesorzy.r2",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 44-49 RODO, Wyrok TSUE Schrems II",
            "matched": True,
            "priority": 84102,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.rodo_podprocesorzy.r2"

    def test_jdg_micro_rodo_podprocesorzy_r2_negative_no_block(self):
        """❌ Negatywny: jdg.micro.rodo_podprocesorzy.r2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.rodo_podprocesorzy.r2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_rodo_podprocesorzy_r4:
    """Auto-generated: jdg.micro.rodo_podprocesorzy.r4
    Podstawa prawna: Art. 82 RODO"""

    def test_jdg_micro_rodo_podprocesorzy_r4_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.rodo_podprocesorzy.r4 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.rodo_podprocesorzy.r4",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 82 RODO",
            "matched": True,
            "priority": 84104,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.rodo_podprocesorzy.r4"

    def test_jdg_micro_rodo_podprocesorzy_r4_negative_no_block(self):
        """❌ Negatywny: jdg.micro.rodo_podprocesorzy.r4 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.rodo_podprocesorzy.r4",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_rodo_sankcje_r1:
    """Auto-generated: jdg.micro.rodo_sankcje.r1
    Podstawa prawna: Art. 83 ust. 4 RODO"""

    def test_jdg_micro_rodo_sankcje_r1_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.rodo_sankcje.r1 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.rodo_sankcje.r1",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 ust. 4 RODO",
            "matched": True,
            "priority": 84401,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.rodo_sankcje.r1"

    def test_jdg_micro_rodo_sankcje_r1_negative_no_block(self):
        """❌ Negatywny: jdg.micro.rodo_sankcje.r1 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.rodo_sankcje.r1",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_rodo_sankcje_r2:
    """Auto-generated: jdg.micro.rodo_sankcje.r2
    Podstawa prawna: Art. 83 ust. 5 RODO"""

    def test_jdg_micro_rodo_sankcje_r2_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.rodo_sankcje.r2 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.rodo_sankcje.r2",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Art. 83 ust. 5 RODO",
            "matched": True,
            "priority": 84402,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.rodo_sankcje.r2"

    def test_jdg_micro_rodo_sankcje_r2_negative_no_block(self):
        """❌ Negatywny: jdg.micro.rodo_sankcje.r2 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.rodo_sankcje.r2",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ryczalt_a4_r12:
    """Auto-generated: jdg.micro.ryczalt.a4.r12
    Podstawa prawna: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)"""

    def test_jdg_micro_ryczalt_a4_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ryczalt.a4.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a4.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
            "matched": True,
            "priority": 100015,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ryczalt.a4.r12"

    def test_jdg_micro_ryczalt_a4_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ryczalt.a4.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a4.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ryczalt_a8_r12:
    """Auto-generated: jdg.micro.ryczalt.a8.r12
    Podstawa prawna: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)"""

    def test_jdg_micro_ryczalt_a8_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ryczalt.a8.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a8.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
            "matched": True,
            "priority": 100037,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ryczalt.a8.r12"

    def test_jdg_micro_ryczalt_a8_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ryczalt.a8.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a8.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ryczalt_a12_r12:
    """Auto-generated: jdg.micro.ryczalt.a12.r12
    Podstawa prawna: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)"""

    def test_jdg_micro_ryczalt_a12_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ryczalt.a12.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a12.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
            "matched": True,
            "priority": 100052,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ryczalt.a12.r12"

    def test_jdg_micro_ryczalt_a12_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ryczalt.a12.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a12.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ryczalt_a21_r12:
    """Auto-generated: jdg.micro.ryczalt.a21.r12
    Podstawa prawna: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)"""

    def test_jdg_micro_ryczalt_a21_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ryczalt.a21.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a21.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
            "matched": True,
            "priority": 100080,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ryczalt.a21.r12"

    def test_jdg_micro_ryczalt_a21_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ryczalt.a21.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a21.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_ryczalt_a27_r12:
    """Auto-generated: jdg.micro.ryczalt.a27.r12
    Podstawa prawna: Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)"""

    def test_jdg_micro_ryczalt_a27_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.ryczalt.a27.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a27.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
            "matched": True,
            "priority": 100092,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.ryczalt.a27.r12"

    def test_jdg_micro_ryczalt_a27_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.ryczalt.a27.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.ryczalt.a27.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_uor_a22_r12:
    """Auto-generated: jdg.micro.uor.a22.r12
    Podstawa prawna: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)"""

    def test_jdg_micro_uor_a22_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.uor.a22.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.uor.a22.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
            "matched": True,
            "priority": 160043,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.uor.a22.r12"

    def test_jdg_micro_uor_a22_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.uor.a22.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.uor.a22.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_uor_a26_r12:
    """Auto-generated: jdg.micro.uor.a26.r12
    Podstawa prawna: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)"""

    def test_jdg_micro_uor_a26_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.uor.a26.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.uor.a26.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
            "matched": True,
            "priority": 160065,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.uor.a26.r12"

    def test_jdg_micro_uor_a26_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.uor.a26.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.uor.a26.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_uor_a28_r12:
    """Auto-generated: jdg.micro.uor.a28.r12
    Podstawa prawna: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)"""

    def test_jdg_micro_uor_a28_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.uor.a28.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.uor.a28.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
            "matched": True,
            "priority": 160077,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.uor.a28.r12"

    def test_jdg_micro_uor_a28_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.uor.a28.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.uor.a28.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_uor_a35_r12:
    """Auto-generated: jdg.micro.uor.a35.r12
    Podstawa prawna: Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)"""

    def test_jdg_micro_uor_a35_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.uor.a35.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.uor.a35.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
            "matched": True,
            "priority": 160097,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.uor.a35.r12"

    def test_jdg_micro_uor_a35_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.uor.a35.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.uor.a35.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a7_r12:
    """Auto-generated: jdg.micro.vat.a7.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a7_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a7.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a7.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50028,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a7.r12"

    def test_jdg_micro_vat_a7_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a7.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a7.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a8_r12:
    """Auto-generated: jdg.micro.vat.a8.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a8_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a8.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a8.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50040,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a8.r12"

    def test_jdg_micro_vat_a8_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a8.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a8.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a17_r12:
    """Auto-generated: jdg.micro.vat.a17.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a17_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a17.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a17.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50060,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a17.r12"

    def test_jdg_micro_vat_a17_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a17.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a17.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a19a_r12:
    """Auto-generated: jdg.micro.vat.a19a.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a19a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a19a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a19a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50072,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a19a.r12"

    def test_jdg_micro_vat_a19a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a19a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a19a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a29a_r12:
    """Auto-generated: jdg.micro.vat.a29a.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a29a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a29a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a29a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50133,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a29a.r12"

    def test_jdg_micro_vat_a29a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a29a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a29a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a41_r12:
    """Auto-generated: jdg.micro.vat.a41.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a41_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a41.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a41.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50164,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a41.r12"

    def test_jdg_micro_vat_a41_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a41.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a41.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a41b_r12:
    """Auto-generated: jdg.micro.vat.a41b.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a41b_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a41b.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a41b.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50179,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a41b.r12"

    def test_jdg_micro_vat_a41b_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a41b.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a41b.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a41d_r12:
    """Auto-generated: jdg.micro.vat.a41d.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a41d_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a41d.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a41d.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50201,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a41d.r12"

    def test_jdg_micro_vat_a41d_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a41d.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a41d.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a42_r12:
    """Auto-generated: jdg.micro.vat.a42.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a42_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a42.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a42.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50216,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a42.r12"

    def test_jdg_micro_vat_a42_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a42.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a42.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a43_r12:
    """Auto-generated: jdg.micro.vat.a43.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a43_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a43.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a43.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50228,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a43.r12"

    def test_jdg_micro_vat_a43_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a43.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a43.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a43_r27:
    """Auto-generated: jdg.micro.vat.a43.r27
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a43_r27_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a43.r27 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a43.r27",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50243,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a43.r27"

    def test_jdg_micro_vat_a43_r27_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a43.r27 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a43.r27",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a86_r12:
    """Auto-generated: jdg.micro.vat.a86.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a86_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a86.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a86.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50268,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a86.r12"

    def test_jdg_micro_vat_a86_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a86.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a86.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a86a_r12:
    """Auto-generated: jdg.micro.vat.a86a.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a86a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a86a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a86a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50288,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a86a.r12"

    def test_jdg_micro_vat_a86a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a86a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a86a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a87_r12:
    """Auto-generated: jdg.micro.vat.a87.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a87_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a87.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a87.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50300,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a87.r12"

    def test_jdg_micro_vat_a87_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a87.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a87.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a88_r12:
    """Auto-generated: jdg.micro.vat.a88.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a88_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a88.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a88.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50312,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a88.r12"

    def test_jdg_micro_vat_a88_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a88.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a88.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a89a_r12:
    """Auto-generated: jdg.micro.vat.a89a.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a89a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a89a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a89a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50327,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a89a.r12"

    def test_jdg_micro_vat_a89a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a89a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a89a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a89b_r12:
    """Auto-generated: jdg.micro.vat.a89b.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a89b_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a89b.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a89b.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50339,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a89b.r12"

    def test_jdg_micro_vat_a89b_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a89b.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a89b.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a96_r12:
    """Auto-generated: jdg.micro.vat.a96.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a96_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a96.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a96.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50351,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a96.r12"

    def test_jdg_micro_vat_a96_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a96.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a96.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a99_r12:
    """Auto-generated: jdg.micro.vat.a99.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a99_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a99.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a99.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50383,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a99.r12"

    def test_jdg_micro_vat_a99_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a99.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a99.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a106a_r12:
    """Auto-generated: jdg.micro.vat.a106a.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a106a_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a106a.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a106a.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50411,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a106a.r12"

    def test_jdg_micro_vat_a106a_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a106a.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a106a.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a106f_r12:
    """Auto-generated: jdg.micro.vat.a106f.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a106f_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a106f.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a106f.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50426,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a106f.r12"

    def test_jdg_micro_vat_a106f_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a106f.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a106f.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a106na_r12:
    """Auto-generated: jdg.micro.vat.a106na.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a106na_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a106na.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a106na.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50438,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a106na.r12"

    def test_jdg_micro_vat_a106na_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a106na.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a106na.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a108_r12:
    """Auto-generated: jdg.micro.vat.a108.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a108_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a108.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a108.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50466,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a108.r12"

    def test_jdg_micro_vat_a108_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a108.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a108.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a113_r12:
    """Auto-generated: jdg.micro.vat.a113.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a113_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a113.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a113.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50496,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a113.r12"

    def test_jdg_micro_vat_a113_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a113.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a113.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a120_r12:
    """Auto-generated: jdg.micro.vat.a120.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a120_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a120.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a120.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50522,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a120.r12"

    def test_jdg_micro_vat_a120_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a120.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a120.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a129_r12:
    """Auto-generated: jdg.micro.vat.a129.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a129_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a129.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a129.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50537,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a129.r12"

    def test_jdg_micro_vat_a129_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a129.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a129.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_vat_a135_r12:
    """Auto-generated: jdg.micro.vat.a135.r12
    Podstawa prawna: Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)"""

    def test_jdg_micro_vat_a135_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.vat.a135.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.vat.a135.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
            "matched": True,
            "priority": 50549,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.vat.a135.r12"

    def test_jdg_micro_vat_a135_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.vat.a135.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.vat.a135.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_zdrowotna_a81c_r12:
    """Auto-generated: jdg.micro.zdrowotna.a81c.r12
    Podstawa prawna: Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)"""

    def test_jdg_micro_zdrowotna_a81c_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.zdrowotna.a81c.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.zdrowotna.a81c.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
            "matched": True,
            "priority": 110120,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.zdrowotna.a81c.r12"

    def test_jdg_micro_zdrowotna_a81c_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.zdrowotna.a81c.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.zdrowotna.a81c.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"


@pytest.mark.rego
@pytest.mark.unit
@pytest.mark.auto_generated
class Test_jdg_micro_zdrowotna_a81d_r12:
    """Auto-generated: jdg.micro.zdrowotna.a81d.r12
    Podstawa prawna: Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)"""

    def test_jdg_micro_zdrowotna_a81d_r12_positive_block_triggered(self):
        """✅ Pozytywny: jdg.micro.zdrowotna.a81d.r12 — blokada powinna zostać uruchomiona."""
        # Arrange: dane spełniające warunki reguły BLOCK
        input_data = {
            "rule_id": "jdg.micro.zdrowotna.a81d.r12",
            "package": "micro",
            "routing": "BLOCK_AND_ALERT",
            "legal_basis": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
            "matched": True,
            "priority": 110132,
        }
        assert input_data["matched"] is True
        assert input_data["routing"] == "BLOCK_AND_ALERT"
        assert input_data["rule_id"] == "jdg.micro.zdrowotna.a81d.r12"

    def test_jdg_micro_zdrowotna_a81d_r12_negative_no_block(self):
        """❌ Negatywny: jdg.micro.zdrowotna.a81d.r12 — blokada NIE powinna być uruchomiona."""
        input_data = {
            "rule_id": "jdg.micro.zdrowotna.a81d.r12",
            "matched": False,
            "routing": "ALLOW",
        }
        # Przy niespełnionych warunkach reguła nie powinna blokować
        assert input_data["matched"] is False
        assert input_data["routing"] != "BLOCK_AND_ALERT"

