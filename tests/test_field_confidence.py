"""
Tests for FieldConfidence module — per-field OCR confidence metadata.

Testuje:
  - Tworzenie FieldConfidence z walidacją
  - field_confidence_from_dict / field_confidence_to_dict
  - minimum_confidence / fields_below_threshold
  - Integrację z ContextInterpreter
  - Integrację z pipeline (mock)
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any

import pytest

from core.field_confidence import (
    FieldConfidence,
    FieldConfidenceDict,
    field_confidence_from_dict,
    field_confidence_to_dict,
    minimum_confidence,
    fields_below_threshold,
)
from core.context_interpreter import ContextInterpreter


# ═══════════════════════════════════════════════════════════════════════════════
# FieldConfidence — podstawowe testy
# ═══════════════════════════════════════════════════════════════════════════════


class TestFieldConfidence:
    """Testy jednostkowe dla dataclass FieldConfidence."""

    def test_create_valid(self) -> None:
        """Utworzenie FieldConfidence z poprawnymi wartościami."""
        fc = FieldConfidence(value=1230.00, confidence=0.88, source="surya_ocr")
        assert fc.value == 1230.00
        assert fc.confidence == 0.88
        assert fc.source == "surya_ocr"

    def test_create_min_confidence(self) -> None:
        """Confidence = 0.0 jest dozwolone."""
        fc = FieldConfidence(value="test", confidence=0.0)
        assert fc.confidence == 0.0

    def test_create_max_confidence(self) -> None:
        """Confidence = 1.0 jest dozwolone."""
        fc = FieldConfidence(value="test", confidence=1.0)
        assert fc.confidence == 1.0

    def test_create_invalid_confidence_negative(self) -> None:
        """Confidence < 0.0 powinno rzucić ValueError."""
        with pytest.raises(ValueError, match="Confidence must be in"):
            FieldConfidence(value=100, confidence=-0.1)

    def test_create_invalid_confidence_over_one(self) -> None:
        """Confidence > 1.0 powinno rzucić ValueError."""
        with pytest.raises(ValueError, match="Confidence must be in"):
            FieldConfidence(value=100, confidence=1.5)

    def test_is_reliable_above_threshold(self) -> None:
        """is_reliable() zwraca True dla confidence >= threshold."""
        fc = FieldConfidence(value=100, confidence=0.90)
        assert fc.is_reliable(threshold=0.85) is True

    def test_is_reliable_below_threshold(self) -> None:
        """is_reliable() zwraca False dla confidence < threshold."""
        fc = FieldConfidence(value=100, confidence=0.80)
        assert fc.is_reliable(threshold=0.85) is False

    def test_is_reliable_default_threshold(self) -> None:
        """Domyślny próg is_reliable() to 0.85."""
        fc = FieldConfidence(value=100, confidence=0.85)
        assert fc.is_reliable() is True
        fc2 = FieldConfidence(value=100, confidence=0.84)
        assert fc2.is_reliable() is False

    def test_to_dict(self) -> None:
        """to_dict() zwraca poprawny słownik."""
        fc = FieldConfidence(value=Decimal("1230.00"), confidence=0.88, source="ocr")
        d = fc.to_dict()
        assert d["value"] == "1230.00"  # Decimal → str
        assert d["confidence"] == 0.88
        assert d["source"] == "ocr"

    def test_to_dict_plain_value(self) -> None:
        """Wartości niebędące Decimal są zachowane."""
        fc = FieldConfidence(value="1234567890", confidence=0.95)
        d = fc.to_dict()
        assert d["value"] == "1234567890"

    def test_repr(self) -> None:
        """Repr zawiera kluczowe informacje."""
        fc = FieldConfidence(value=1230.00, confidence=0.88)
        r = repr(fc)
        assert "FieldConfidence" in r
        assert "0.88" in r
        assert "1230.0" in r


# ═══════════════════════════════════════════════════════════════════════════════
# field_confidence_from_dict / field_confidence_to_dict
# ═══════════════════════════════════════════════════════════════════════════════


class TestFieldConfidenceDict:
    """Testy dla factory functions."""

    SAMPLE_DATA: dict[str, dict[str, Any]] = {
        "total_gross": {"value": 1230.00, "confidence": 0.88, "source": "surya_ocr"},
        "vat_rate": {"value": 0.23, "confidence": 0.99},
        "vendor_nip": {"value": "1234567890", "confidence": 0.95},
    }

    def test_from_dict_valid(self) -> None:
        """field_confidence_from_dict tworzy poprawny słownik FieldConfidence."""
        result = field_confidence_from_dict(self.SAMPLE_DATA)
        assert len(result) == 3
        assert isinstance(result["total_gross"], FieldConfidence)
        assert result["total_gross"].confidence == 0.88
        assert result["vat_rate"].confidence == 0.99
        assert result["vendor_nip"].value == "1234567890"

    def test_from_dict_missing_value(self) -> None:
        """field_confidence_from_dict rzuca ValueError gdy brak 'value'."""
        with pytest.raises(ValueError, match="Missing 'value'"):
            field_confidence_from_dict({"test": {"confidence": 0.5}})

    def test_from_dict_missing_confidence(self) -> None:
        """field_confidence_from_dict rzuca ValueError gdy brak 'confidence'."""
        with pytest.raises(ValueError, match="Missing 'confidence'"):
            field_confidence_from_dict({"test": {"value": 100}})

    def test_from_dict_invalid_type(self) -> None:
        """field_confidence_from_dict rzuca ValueError gdy entry nie jest dict."""
        with pytest.raises(ValueError, match="Invalid field_confidence entry"):
            field_confidence_from_dict({"test": "not_a_dict"})

    def test_round_trip(self) -> None:
        """field_confidence_to_dict(field_confidence_from_dict(x)) == x."""
        fc = field_confidence_from_dict(self.SAMPLE_DATA)
        back = field_confidence_to_dict(fc)
        for key in self.SAMPLE_DATA:
            assert key in back
            assert back[key]["value"] == self.SAMPLE_DATA[key]["value"]
            assert back[key]["confidence"] == self.SAMPLE_DATA[key]["confidence"]

    def test_empty_dict(self) -> None:
        """field_confidence_from_dict({}) zwraca {}."""
        assert field_confidence_from_dict({}) == {}

    def test_field_confidence_to_dict_empty(self) -> None:
        """field_confidence_to_dict({}) zwraca {}."""
        assert field_confidence_to_dict({}) == {}


# ═══════════════════════════════════════════════════════════════════════════════
# minimum_confidence / fields_below_threshold
# ═══════════════════════════════════════════════════════════════════════════════


class TestHelpers:
    """Testy dla funkcji pomocniczych."""

    def test_minimum_confidence(self) -> None:
        """minimum_confidence zwraca najmniejsze confidence."""
        fc = field_confidence_from_dict({
            "a": {"value": 1, "confidence": 0.95},
            "b": {"value": 2, "confidence": 0.70},
            "c": {"value": 3, "confidence": 0.88},
        })
        assert minimum_confidence(fc) == 0.70

    def test_minimum_confidence_empty(self) -> None:
        """minimum_confidence({}) zwraca 1.0."""
        assert minimum_confidence({}) == 1.0

    def test_fields_below_threshold(self) -> None:
        """fields_below_threshold zwraca pola poniżej progu."""
        fc = field_confidence_from_dict({
            "a": {"value": 1, "confidence": 0.95},
            "b": {"value": 2, "confidence": 0.70},
            "c": {"value": 3, "confidence": 0.50},
        })
        below = fields_below_threshold(fc, threshold=0.85)
        assert len(below) == 2
        names = {name for name, _ in below}
        assert "b" in names
        assert "c" in names
        assert "a" not in names

    def test_fields_below_threshold_empty(self) -> None:
        """fields_below_threshold({}) zwraca []."""
        assert fields_below_threshold({}) == []

    def test_fields_below_threshold_all_above(self) -> None:
        """fields_below_threshold zwraca [] gdy wszystkie powyżej progu."""
        fc = field_confidence_from_dict({
            "a": {"value": 1, "confidence": 0.95},
            "b": {"value": 2, "confidence": 0.90},
        })
        assert fields_below_threshold(fc) == []


# ═══════════════════════════════════════════════════════════════════════════════
# Integracja z ContextInterpreter
# ═══════════════════════════════════════════════════════════════════════════════


class TestContextInterpreterIntegration:
    """Testy integracji field_confidence z ContextInterpreter."""

    def test_field_confidence_in_context(self) -> None:
        """field_confidence jest mapowany na fc_* klucze w kontekście."""
        invoice_data = {
            "transaction_date": "2024-06-15",
            "field_confidence": {
                "total_gross": {"value": 1230.00, "confidence": 0.88, "source": "ocr"},
                "vat_rate": {"value": 0.23, "confidence": 0.99, "source": "llm"},
                "vendor_nip": {"value": "1234567890", "confidence": 0.95},
            },
        }
        ctx = ContextInterpreter.interpret(invoice_data)
        assert "fc_total_gross" in ctx
        assert ctx["fc_total_gross"] == "0.88"
        assert "fc_vat_rate" in ctx
        assert ctx["fc_vat_rate"] == "0.99"
        assert "fc_vendor_nip" in ctx
        assert ctx["fc_vendor_nip"] == "0.95"
        assert "fc_minimum" in ctx
        assert ctx["fc_minimum"] == "0.88"  # minimum z 0.88, 0.99, 0.95

    def test_field_confidence_values_in_context(self) -> None:
        """fc_*_value klucze są również dostępne w kontekście."""
        invoice_data = {
            "transaction_date": "2024-06-15",
            "field_confidence": {
                "total_gross": {"value": 1230.00, "confidence": 0.88},
            },
        }
        ctx = ContextInterpreter.interpret(invoice_data)
        assert "fc_total_gross_value" in ctx
        assert ctx["fc_total_gross_value"] == "1230.0"

    def test_field_confidence_missing(self) -> None:
        """Brak field_confidence nie powoduje błędu."""
        invoice_data = {
            "transaction_date": "2024-06-15",
            "category_code": "FUEL",
        }
        ctx = ContextInterpreter.interpret(invoice_data)
        # Pola fc_* nie powinny być w kontekście
        assert "fc_total_gross" not in ctx or ctx.get("fc_total_gross") == ""

    def test_field_confidence_empty(self) -> None:
        """Puste field_confidence ({}) nie powoduje błędu."""
        invoice_data = {
            "transaction_date": "2024-06-15",
            "field_confidence": {},
        }
        ctx = ContextInterpreter.interpret(invoice_data)
        assert "fc_minimum" not in ctx or ctx.get("fc_minimum") == ""

    def test_field_confidence_fc_alias(self) -> None:
        """Alias 'fc' (krótki) też działa."""
        invoice_data = {
            "transaction_date": "2024-06-15",
            "fc": {
                "total_gross": {"value": 100.00, "confidence": 0.90},
            },
        }
        ctx = ContextInterpreter.interpret(invoice_data)
        assert ctx.get("fc_total_gross") == "0.9"

    def test_context_interpreter_with_confidence_vat_rate(self) -> None:
        """confidence_vat_rate nadal działa (backward compatibility)."""
        invoice_data = {
            "transaction_date": "2024-06-15",
            "confidence_vat_rate": 0.95,
        }
        ctx = ContextInterpreter.interpret(invoice_data)
        assert ctx.get("confidence_vat_rate") == "0.95"
