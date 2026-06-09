"""Testy struktury promptów systemowych.

Automatycznie weryfikuje strukturę wszystkich promptów w systemie:
  - JambaStrategist (agent_orchestrator.py)
  - WorkflowPlanner (agent_orchestrator.py)
  - Rules SWAT L1–L4 (rules_agent.py)

Każdy test sprawdza:
  1. Obecność wszystkich wymaganych sekcji/nagłówków
  2. Kolejność sekcji (późniejsze sekcje występują po wcześniejszych)
  3. Obecność === DECYZJA === jako ostatniej sekcji
  4. Obecność "Return ONLY a valid JSON object. No other text." w końcowej części
"""

from __future__ import annotations

from unittest.mock import MagicMock

import pytest

from nexus_ai.services.agent_orchestrator import (
    JAMBA_SYSTEM_PROMPT,
    WORKFLOW_PLANNER_PROMPT,
    JambaStrategist,
    WorkflowPlanner,
)
from nexus_ai.services.rules_agent import (
    RULES_LEVEL_1_PROMPT,
    RULES_LEVEL_2_PROMPT,
    RULES_LEVEL_3_PROMPT,
    RULES_LEVEL_4_PROMPT,
    RulesSWATTeam,
)




# ===========================================================================
# Fixtures
# ===========================================================================

@pytest.fixture
def mock_model_manager() -> MagicMock:
    """Mock ModelManager — nie potrzebujemy prawdziwego llama_cpp do testów promptów."""
    return MagicMock()


@pytest.fixture
def sample_invoice() -> dict:
    """Standardowe dane faktury do testów promptów."""
    return {
        "invoice_id": "inv-001",
        "contractor_nip": "1234567890",
        "amount_net": 1000.00,
        "amount_gross": 1230.00,
        "vat": 230.00,
        "category": "usługi IT",
        "issue_date": "2026-06-01",
        "number": "FV/2026/001",
        "ocr_confidence": 0.95,
        "vendor_profile": {
            "name": "Firma XYZ",
            "known": True,
            "invoice_count": 15,
            "trust_score": 0.85,
        },
    }


@pytest.fixture
def sample_reports() -> dict:
    """Raporty agentów dla JambaStrategist."""
    return {
        "quality_report": {
            "decision": "APPROVE",
            "level": "STANDARD",
            "trust_score": 0.88,
        },
        "analytics_report": {
            "trends": [{"name": "seasonal_up", "strength": 0.7}],
            "anomalies": [],
            "summary": "Kwota typowa dla tego kontrahenta",
        },
        "extraction_report": {
            "extracted_fields": [
                {"name": "vendor_nip", "confidence": 0.98},
                {"name": "total_gross", "confidence": 0.95},
            ],
            "avg_confidence": 0.94,
        },
    }


@pytest.fixture
def sample_fact_sheet_text() -> str:
    """Przykładowy arkusz faktów (RAG)."""
    return (
        "=== ARKUSZ FAKTÓW (FactsAggregator) ===\n\n"
        "Źródła danych: SQLite=✓, DuckDB=✓, sqlite-vec=✓\n\n"
        "Faktura #inv-001\n"
        "  Kontrahent: Firma XYZ (NIP: 1234567890)\n"
        "  Kwota netto: 1000.00 PLN\n"
        "  Kwota brutto: 1230.00 PLN\n"
        "  Kategoria: usługi IT\n"
        "  Data wystawienia: 2026-06-01\n"
    )


@pytest.fixture
def sample_few_shot() -> str:
    """Przykładowe few-shot examples."""
    return (
        "=== PRZYKŁADY FEW-SHOT (historyczne decyzje) ===\n\n"
        "Przykład 1:\n"
        "[Historyczna faktura]\n"
        "  Kwota brutto: 1500.00 PLN\n"
        "  Kategoria: IT\n"
        "  Podjęta decyzja: AUTO_POST\n"
        "  Status: PAID\n"
    )


@pytest.fixture
def rules_levels_data() -> tuple[dict, dict, dict]:
    """Wyniki poprzednich poziomów Rules SWAT."""
    level1 = {
        "decision": "FLAG",
        "confidence": 0.65,
        "reasoning": "Kwota powyżej typowej dla tego kontrahenta",
        "flags": [{"area": "amount", "reason": "Higher than average", "severity": "medium"}],
    }
    level2 = {
        "passed": False,
        "confidence": 0.70,
        "violations": [{"rule": "amount_limit", "message": "Przekroczony limit", "severity": "warning"}],
        "reasoning": "Kwota przekracza limit dla tej kategorii",
    }
    level3 = {
        "classification": "VIOLATION",
        "confidence": 0.60,
        "risk_factors": [{"factor": "amount_anomaly", "weight": 0.8, "description": "Kwota 3× powyżej średniej"}],
        "reasoning": "Znacząca anomalia kwotowa",
    }
    return level1, level2, level3


# ===========================================================================
# Helper: find section positions
# ===========================================================================

def _section_positions(prompt: str, sections: list[str]) -> dict[str, int]:
    """Znajdź pozycje (indeksy) sekcji w promptcie.

    Args:
        prompt: Tekst promptu.
        sections: Lista nazw sekcji do znalezienia.

    Returns:
        Słownik {nazwa_sekcji: pozycja}. Sekcje niewystępujące mają pozycję -1.
    """
    positions: dict[str, int] = {}
    for section in sections:
        idx = prompt.find(f"=== {section} ===")
        positions[section] = idx if idx >= 0 else -1
    return positions


def _verify_section_order(prompt: str, expected_order: list[str]) -> None:
    """Sprawdź, że sekcje występują w oczekiwanej kolejności.

    Args:
        prompt: Tekst promptu.
        expected_order: Lista nazw sekcji w oczekiwanej kolejności.
    """
    positions = _section_positions(prompt, expected_order)
    prev_pos = -1
    for section in expected_order:
        pos = positions[section]
        assert pos >= 0, f"Sekcja === {section} === nie znaleziona w promptcie"
        assert pos > prev_pos, (
            f"Sekcja === {section} === jest przed === {expected_order[expected_order.index(section)-1]} === "
            f"(oczekiwano odwrotnej kolejności)"
        )
        prev_pos = pos


# ===========================================================================
# Testy JambaStrategist
# ===========================================================================

class TestJambaStrategistPrompt:
    """Struktura promptu JambaStrategist — największy i najbardziej złożony prompt
    w systemie (Jamba 3B). Zawiera 8 sekcji, w tym few-shot ×2.
    """

    def test_system_prompt_has_json_format(self) -> None:
        """JAMBA_SYSTEM_PROMPT zawiera specyfikację formatu JSON."""
        assert "AUTO_POST" in JAMBA_SYSTEM_PROMPT
        assert "SUGGEST" in JAMBA_SYSTEM_PROMPT
        assert "ESCALATE" in JAMBA_SYSTEM_PROMPT
        assert "confidence" in JAMBA_SYSTEM_PROMPT
        assert "reasoning" in JAMBA_SYSTEM_PROMPT
        assert "strategy_summary" in JAMBA_SYSTEM_PROMPT
        assert "Return ONLY a valid JSON object" in JAMBA_SYSTEM_PROMPT

    def test_build_prompt_structure(self, sample_invoice: dict, sample_reports: dict,
                                    sample_fact_sheet_text: str, sample_few_shot: str) -> None:
        """Sprawdź kompletną strukturę promptu JambaStrategist."""
        strategist = JambaStrategist(
            model_name="jamba-test",
            model_path="/fake/jamba.gguf",
            model_manager=MagicMock(),
        )

        prompt = strategist._build_prompt(
            invoice_data=sample_invoice,
            quality_report=sample_reports["quality_report"],
            analytics_report=sample_reports["analytics_report"],
            extraction_report=sample_reports["extraction_report"],
            fact_sheet_text=sample_fact_sheet_text,
            few_shot_examples=sample_few_shot,
        )

        # Wszystkie sekcje powinny być obecne
        assert "=== DANE FAKTURY ===" in prompt
        assert "=== ARKUSZ FAKTÓW (FactsAggregator) ===" in prompt  # RAG
        assert "=== PRZYKŁADY FEW-SHOT (historyczne decyzje) ===" in prompt
        assert "=== RAPORT WALIDATORA JAKOŚCI ===" in prompt
        assert "=== RAPORT ANALITYCZNY ===" in prompt
        assert "=== RAPORT EKSTRAKCJI DANYCH ===" in prompt
        assert "=== DECYZJA ===" in prompt

        # Dane faktury
        assert "inv-001" in prompt
        assert "1234567890" in prompt
        assert "1230.00" in prompt
        assert "usługi IT" in prompt

        # Raporty
        assert "APPROVE" in prompt
        assert "STANDARD" in prompt
        assert "seasonal_up" in prompt
        assert "0.94" in prompt  # avg_confidence

        # RAG
        assert "Firma XYZ" in prompt

        # Few-shot — pojawia się DWUKROTNIE
        assert prompt.count("=== PRZYKŁADY FEW-SHOT (historyczne decyzje) ===") == 2

    @pytest.mark.parametrize("with_fact_sheet,with_few_shot", [
        (True, True),   # pełne dane
        (True, False),  # bez few-shot
        (False, True),  # bez RAG
        (False, False), # tylko dane faktury + raporty
    ])
    def test_build_prompt_with_various_inputs(
        self, sample_invoice: dict, sample_reports: dict,
        sample_fact_sheet_text: str, sample_few_shot: str,
        with_fact_sheet: bool, with_few_shot: bool,
    ) -> None:
        """Sprawdź prompt z różnymi kombinacjami danych opcjonalnych."""
        strategist = JambaStrategist(
            model_name="jamba-test",
            model_path="/fake/jamba.gguf",
            model_manager=MagicMock(),
        )

        prompt = strategist._build_prompt(
            invoice_data=sample_invoice,
            quality_report=sample_reports["quality_report"],
            analytics_report=sample_reports["analytics_report"],
            extraction_report=sample_reports["extraction_report"],
            fact_sheet_text=sample_fact_sheet_text if with_fact_sheet else None,
            few_shot_examples=sample_few_shot if with_few_shot else None,
        )

        # Zawsze obecne
        assert "=== DANE FAKTURY ===" in prompt
        assert "=== RAPORT WALIDATORA JAKOŚCI ===" in prompt
        assert "=== RAPORT ANALITYCZNY ===" in prompt
        assert "=== RAPORT EKSTRAKCJI DANYCH ===" in prompt
        assert "=== DECYZJA ===" in prompt

        # Warunkowe
        assert ("=== ARKUSZ FAKTÓW" in prompt) == with_fact_sheet
        assert ("=== PRZYKŁADY FEW-SHOT" in prompt) == with_few_shot

        # === DECYZJA === zawsze na końcu
        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")

    def test_build_prompt_section_order(self, sample_invoice: dict, sample_reports: dict,
                                         sample_fact_sheet_text: str, sample_few_shot: str) -> None:
        """Sprawdź kolejność sekcji w promptcie JambaStrategist."""
        strategist = JambaStrategist(
            model_name="jamba-test",
            model_path="/fake/jamba.gguf",
            model_manager=MagicMock(),
        )

        prompt = strategist._build_prompt(
            invoice_data=sample_invoice,
            quality_report=sample_reports["quality_report"],
            analytics_report=sample_reports["analytics_report"],
            extraction_report=sample_reports["extraction_report"],
            fact_sheet_text=sample_fact_sheet_text,
            few_shot_examples=sample_few_shot,
        )

        _verify_section_order(prompt, [
            "DANE FAKTURY",
            "ARKUSZ FAKTÓW (FactsAggregator)",
            "PRZYKŁADY FEW-SHOT (historyczne decyzje)",  # pierwszy raz (kontekst)
            "RAPORT WALIDATORA JAKOŚCI",
            "RAPORT ANALITYCZNY",
            "RAPORT EKSTRAKCJI DANYCH",
            "PRZYKŁADY FEW-SHOT (historyczne decyzje)",  # drugi raz (reminder)
            "DECYZJA",
        ])

    def test_build_prompt_empty_reports(self, sample_invoice: dict) -> None:
        """Sprawdź prompt z pustymi raportami (graceful degradation)."""
        strategist = JambaStrategist(
            model_name="jamba-test",
            model_path="/fake/jamba.gguf",
            model_manager=MagicMock(),
        )

        prompt = strategist._build_prompt(
            invoice_data=sample_invoice,
            quality_report=None,
            analytics_report=None,
            extraction_report=None,
            fact_sheet_text=None,
            few_shot_examples=None,
        )

        # Powinna być sekcja === DECYZJA === na końcu
        assert "=== DECYZJA ===" in prompt
        assert "N/A" in prompt  # brak raportów → N/A
        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")

    def test_build_prompt_few_shot_appears_twice(self, sample_invoice: dict, sample_reports: dict,
                                                   sample_few_shot: str) -> None:
        """Sprawdź, że few-shot pojawia się dokładnie 2 razy (kontekst + reminder)."""
        strategist = JambaStrategist(
            model_name="jamba-test",
            model_path="/fake/jamba.gguf",
            model_manager=MagicMock(),
        )

        prompt = strategist._build_prompt(
            invoice_data=sample_invoice,
            quality_report=sample_reports["quality_report"],
            analytics_report=sample_reports["analytics_report"],
            extraction_report=sample_reports["extraction_report"],
            fact_sheet_text=None,
            few_shot_examples=sample_few_shot,
        )

        # Dokładnie 2 wystąpienia nagłówka few-shot
        assert prompt.count("=== PRZYKŁADY FEW-SHOT (historyczne decyzje) ===") == 2

        # Pierwsze wystąpienie przed raportami
        first_few_shot = prompt.find("=== PRZYKŁADY FEW-SHOT (historyczne decyzje) ===")
        after_first = prompt.find("=== PRZYKŁADY FEW-SHOT (historyczne decyzje) ===", first_few_shot + 1)
        assert after_first > first_few_shot

        # Drugie wystąpienie po raportach i przed === DECYZJA ===
        dec_position = prompt.find("=== DECYZJA ===")
        assert after_first < dec_position, "Drugie wystąpienie few-shot powinno być przed === DECYZJA ==="


# ===========================================================================
# Testy WorkflowPlanner
# ===========================================================================

class TestWorkflowPlannerPrompt:
    """Struktura promptu WorkflowPlanner — klasyfikator simple/complex (LittleLamb 0.3B)."""

    def test_system_prompt_has_json_format(self) -> None:
        """WORKFLOW_PLANNER_PROMPT zawiera specyfikację formatu JSON."""
        assert "EKSTRAKCJA" in WORKFLOW_PLANNER_PROMPT
        assert "WALIDACJA" in WORKFLOW_PLANNER_PROMPT
        assert "ANALITYKA" in WORKFLOW_PLANNER_PROMPT
        assert "DECYZJA" in WORKFLOW_PLANNER_PROMPT
        assert "agents" in WORKFLOW_PLANNER_PROMPT
        assert "reasoning" in WORKFLOW_PLANNER_PROMPT
        assert "Return ONLY a valid JSON object" in WORKFLOW_PLANNER_PROMPT

    def test_build_prompt_structure(self, sample_invoice: dict, sample_fact_sheet_text: str) -> None:
        """Sprawdź strukturę promptu WorkflowPlanner z RAG."""
        planner = WorkflowPlanner(
            model_name="wp-test",
            model_path="/fake/littlelamb.gguf",
            model_manager=MagicMock(),
        )

        prompt = planner._build_prompt(
            invoice_data=sample_invoice,
            vendor_profile=sample_invoice.get("vendor_profile"),
            fact_sheet_text=sample_fact_sheet_text,
        )

        # Wszystkie sekcje
        assert "=== DANE FAKTURY ===" in prompt
        assert "=== PROFIL KONTRAHENTA ===" in prompt
        assert "=== ARKUSZ FAKTÓW (RAG) ===" in prompt
        assert "=== DECYZJA ===" in prompt

        # Dane faktury
        assert "1234567890" in prompt  # NIP
        assert "1000.00" in prompt or "1000" in prompt  # netto
        assert "1230.00" in prompt or "1230" in prompt  # brutto
        assert "usługi IT" in prompt
        assert "0.95" in prompt  # OCR confidence

        # Profil kontrahenta
        assert "tak" in prompt  # znany
        assert "15" in prompt  # invoice_count
        assert "0.85" in prompt  # trust score

        # RAG
        assert "Firma XYZ" in prompt

    def test_build_prompt_without_rag(self, sample_invoice: dict) -> None:
        """Sprawdź prompt bez RAG (opcjonalne)."""
        planner = WorkflowPlanner(
            model_name="wp-test",
            model_path="/fake/littlelamb.gguf",
            model_manager=MagicMock(),
        )

        prompt = planner._build_prompt(
            invoice_data=sample_invoice,
            vendor_profile=sample_invoice.get("vendor_profile"),
            fact_sheet_text=None,
        )

        # Podstawowe sekcje
        assert "=== DANE FAKTURY ===" in prompt
        assert "=== PROFIL KONTRAHENTA ===" in prompt
        assert "=== DECYZJA ===" in prompt

        # Brak RAG
        assert "=== ARKUSZ FAKTÓW (RAG) ===" not in prompt

        # Reguły klasyfikacji
        assert "5000 PLN" in prompt
        assert "invoice_count ≥ 3" in prompt
        assert "OCR confidence ≥ 0.85" in prompt

    def test_build_prompt_section_order(self, sample_invoice: dict, sample_fact_sheet_text: str) -> None:
        """Sprawdź kolejność sekcji w promptcie WorkflowPlanner."""
        planner = WorkflowPlanner(
            model_name="wp-test",
            model_path="/fake/littlelamb.gguf",
            model_manager=MagicMock(),
        )

        prompt = planner._build_prompt(
            invoice_data=sample_invoice,
            vendor_profile=sample_invoice.get("vendor_profile"),
            fact_sheet_text=sample_fact_sheet_text,
        )

        _verify_section_order(prompt, [
            "DANE FAKTURY",
            "PROFIL KONTRAHENTA",
            "ARKUSZ FAKTÓW (RAG)",
            "DECYZJA",
        ])

    def test_build_prompt_decisions_at_end(self, sample_invoice: dict, sample_fact_sheet_text: str) -> None:
        """Sprawdź, że === DECYZJA === jest ostatnią sekcją z przypomnieniem JSON."""
        planner = WorkflowPlanner(
            model_name="wp-test",
            model_path="/fake/littlelamb.gguf",
            model_manager=MagicMock(),
        )

        prompt = planner._build_prompt(
            invoice_data=sample_invoice,
            vendor_profile=sample_invoice.get("vendor_profile"),
            fact_sheet_text=sample_fact_sheet_text,
        )

        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")

    def test_build_prompt_empty_vendor_profile(self) -> None:
        """Sprawdź prompt z pustym profilem kontrahenta."""
        planner = WorkflowPlanner(
            model_name="wp-test",
            model_path="/fake/littlelamb.gguf",
            model_manager=MagicMock(),
        )

        prompt = planner._build_prompt(
            invoice_data={"contractor_nip": "1234567890", "amount_gross": 1000.0},
            vendor_profile=None,
            fact_sheet_text=None,
        )

        assert "=== DANE FAKTURY ===" in prompt
        assert "=== PROFIL KONTRAHENTA ===" in prompt
        assert "=== DECYZJA ===" in prompt
        assert "nie" in prompt  # unknown vendor → nie
        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")


# ===========================================================================
# Testy Rules SWAT
# ===========================================================================

class TestRulesSWATLevel1Prompt:
    """Struktura promptu Rules SWAT Level 1 (LFM2.5 1.2B)."""

    def test_system_prompt_has_json_format(self) -> None:
        """RULES_LEVEL_1_PROMPT zawiera specyfikację formatu JSON."""
        assert "COMPLIANT" in RULES_LEVEL_1_PROMPT
        assert "FLAG" in RULES_LEVEL_1_PROMPT
        assert "decision" in RULES_LEVEL_1_PROMPT
        assert "confidence" in RULES_LEVEL_1_PROMPT
        assert "flags" in RULES_LEVEL_1_PROMPT
        assert "Return ONLY a valid JSON object" in RULES_LEVEL_1_PROMPT

    def test_build_prompt_structure(self, sample_invoice: dict) -> None:
        """Sprawdź strukturę promptu Level 1."""
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_1_prompt(sample_invoice)

        assert "Kontekst faktury" in prompt
        assert "=== DECYZJA ===" in prompt
        assert "1234567890" in prompt  # NIP
        assert "1000.00" in prompt  # netto
        assert "230.00" in prompt  # VAT
        assert "usługi IT" in prompt
        assert "Firma XYZ" in prompt
        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")

    def test_build_prompt_decisions_at_end(self, sample_invoice: dict) -> None:
        """Sprawdź, że === DECYZJA === jest ostatnią sekcją."""
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_1_prompt(sample_invoice)

        # === DECYZJA === po kontekście faktury
        ctx_pos = prompt.find("Kontekst faktury")
        dec_pos = prompt.find("=== DECYZJA ===")
        assert dec_pos > ctx_pos
        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")


class TestRulesSWATLevel2Prompt:
    """Struktura promptu Rules SWAT Level 2 (Granite 4.0 1B Nano)."""

    def test_system_prompt_has_json_format(self) -> None:
        """RULES_LEVEL_2_PROMPT zawiera specyfikację formatu JSON."""
        assert "passed" in RULES_LEVEL_2_PROMPT
        assert "violations" in RULES_LEVEL_2_PROMPT
        assert "confidence" in RULES_LEVEL_2_PROMPT
        assert "nip_validation" in RULES_LEVEL_2_PROMPT
        assert "amount_limit" in RULES_LEVEL_2_PROMPT
        assert "Return ONLY a valid JSON object" in RULES_LEVEL_2_PROMPT

    def test_build_prompt_structure(self, sample_invoice: dict) -> None:
        """Sprawdź strukturę promptu Level 2 z regułami."""
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_2_prompt(sample_invoice)

        assert "Dane faktury" in prompt
        assert "Reguły" in prompt
        assert "=== DECYZJA ===" in prompt
        assert "1234567890" in prompt  # NIP
        assert "usługi IT" in prompt
        assert "FV/2026/001" in prompt  # numer faktury
        assert "Maksymalna kwota" in prompt
        assert "Wymagana walidacja NIP" in prompt
        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")

    def test_build_prompt_section_order(self, sample_invoice: dict) -> None:
        """Sprawdź kolejność sekcji w promptcie Level 2."""
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_2_prompt(sample_invoice)

        # Kolejność: Kontekst → Reguły → DECYZJA
        dane_pos = prompt.find("Dane faktury")
        rules_pos = prompt.find("Reguły")
        dec_pos = prompt.find("=== DECYZJA ===")
        assert dane_pos < rules_pos < dec_pos

    def test_build_prompt_decisions_at_end(self, sample_invoice: dict) -> None:
        """Sprawdź, że === DECYZJA === jest ostatnią sekcją."""
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_2_prompt(sample_invoice)

        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")


class TestRulesSWATLevel3Prompt:
    """Struktura promptu Rules SWAT Level 3 (LittleLamb 0.3B TC)."""

    def test_system_prompt_has_json_format(self) -> None:
        """RULES_LEVEL_3_PROMPT zawiera specyfikację formatu JSON."""
        assert "COMPLIANT" in RULES_LEVEL_3_PROMPT
        assert "FLAG" in RULES_LEVEL_3_PROMPT
        assert "VIOLATION" in RULES_LEVEL_3_PROMPT
        assert "classification" in RULES_LEVEL_3_PROMPT
        assert "risk_factors" in RULES_LEVEL_3_PROMPT
        assert "Return ONLY a valid JSON object" in RULES_LEVEL_3_PROMPT

    def test_build_prompt_structure(self, sample_invoice: dict, rules_levels_data: tuple) -> None:
        """Sprawdź strukturę promptu Level 3 z wynikami L1 i L2."""
        level1, level2, _ = rules_levels_data
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_3_prompt(sample_invoice, level1, level2)

        assert "Dane faktury" in prompt
        assert "Wynik Level 1 (LFM2.5)" in prompt
        assert "Wynik Level 2 (Granite)" in prompt
        assert "=== DECYZJA ===" in prompt
        assert "1234567890" in prompt
        assert "FLAG" in prompt  # z level1
        assert "amount_limit" in prompt  # z level2
        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")

    def test_build_prompt_section_order(self, sample_invoice: dict, rules_levels_data: tuple) -> None:
        """Sprawdź kolejność sekcji w promptcie Level 3."""
        level1, level2, _ = rules_levels_data
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_3_prompt(sample_invoice, level1, level2)

        # Ręczna weryfikacja kolejności (L3 nie ma sekcji === ... ===, tylko tekst)
        dane_pos = prompt.find("Dane faktury")
        l1_pos = prompt.find("Wynik Level 1")
        l2_pos = prompt.find("Wynik Level 2")
        dec_pos = prompt.find("=== DECYZJA ===")
        assert dane_pos < l1_pos < l2_pos < dec_pos

    def test_build_prompt_decisions_at_end(self, sample_invoice: dict, rules_levels_data: tuple) -> None:
        """Sprawdź, że === DECYZJA === jest ostatnią sekcją."""
        level1, level2, _ = rules_levels_data
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_3_prompt(sample_invoice, level1, level2)

        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")


class TestRulesSWATLevel4Prompt:
    """Struktura promptu Rules SWAT Level 4 (Fin-RWKV-169M)."""

    def test_system_prompt_has_json_format(self) -> None:
        """RULES_LEVEL_4_PROMPT zawiera specyfikację formatu JSON."""
        assert "risk_level" in RULES_LEVEL_4_PROMPT
        assert "LOW" in RULES_LEVEL_4_PROMPT
        assert "MEDIUM" in RULES_LEVEL_4_PROMPT
        assert "HIGH" in RULES_LEVEL_4_PROMPT
        assert "anomaly_score" in RULES_LEVEL_4_PROMPT
        assert "final_verdict" in RULES_LEVEL_4_PROMPT
        assert "recommended_action" in RULES_LEVEL_4_PROMPT
        assert "Return ONLY a valid JSON object" in RULES_LEVEL_4_PROMPT

    def test_build_prompt_structure(self, sample_invoice: dict, rules_levels_data: tuple) -> None:
        """Sprawdź strukturę promptu Level 4 z wynikami L1–L3."""
        level1, level2, level3 = rules_levels_data
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_4_prompt(sample_invoice, level1, level2, level3)

        assert "Dane faktury" in prompt
        assert "Level 1 (LFM)" in prompt
        assert "Level 2 (Granite)" in prompt
        assert "Level 3 (LittleLamb)" in prompt
        assert "=== DECYZJA ===" in prompt
        assert "1234567890" in prompt
        assert "FLAG" in prompt  # z level1
        assert "amount_limit" in prompt  # z level2
        assert "VIOLATION" in prompt  # z level3
        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")

    def test_build_prompt_section_order(self, sample_invoice: dict, rules_levels_data: tuple) -> None:
        """Sprawdź kolejność sekcji w promptcie Level 4."""
        level1, level2, level3 = rules_levels_data
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_4_prompt(sample_invoice, level1, level2, level3)

        dane_pos = prompt.find("Dane faktury")
        l1_pos = prompt.find("Level 1 (LFM)")
        l2_pos = prompt.find("Level 2 (Granite)")
        l3_pos = prompt.find("Level 3 (LittleLamb)")
        dec_pos = prompt.find("=== DECYZJA ===")
        assert dane_pos < l1_pos < l2_pos < l3_pos < dec_pos

    def test_build_prompt_decisions_at_end(self, sample_invoice: dict, rules_levels_data: tuple) -> None:
        """Sprawdź, że === DECYZJA === jest ostatnią sekcją."""
        level1, level2, level3 = rules_levels_data
        swat = RulesSWATTeam(
            lfm_model_name="lfm-test", lfm_model_path="/fake/lfm.gguf",
            granite_model_name="granite-test", granite_model_path="/fake/granite.gguf",
            littlelamb_model_name="ll-test", littlelamb_model_path="/fake/ll.gguf",
            fin_rwkv_model_path="/fake/fin.gguf",
            model_manager=MagicMock(),
        )

        prompt = swat._build_level_4_prompt(sample_invoice, level1, level2, level3)

        assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text.")


# ===========================================================================
# Testy między-agentowe
# ===========================================================================

class TestCrossAgentConsistency:
    """Spójność struktury promptów między różnymi agentami."""

    def test_all_prompts_have_decision_section(self, sample_invoice: dict, sample_reports: dict,
                                                sample_fact_sheet_text: str, sample_few_shot: str,
                                                rules_levels_data: tuple) -> None:
        """Wszystkie prompty mają === DECYZJA === jako ostatnią sekcję z przypomnieniem JSON."""
        mm = MagicMock()

        # JambaStrategist
        strategist = JambaStrategist("jamba", "/fake/jamba.gguf", mm)
        jamba_prompt = strategist._build_prompt(
            sample_invoice, sample_reports["quality_report"],
            sample_reports["analytics_report"], sample_reports["extraction_report"],
            sample_fact_sheet_text, sample_few_shot,
        )

        # WorkflowPlanner
        planner = WorkflowPlanner("wp", "/fake/wp.gguf", mm)
        wp_prompt = planner._build_prompt(sample_invoice, sample_invoice.get("vendor_profile"), sample_fact_sheet_text)

        # Rules SWAT
        swat = RulesSWATTeam(
            "lfm", "/fake/lfm.gguf", "granite", "/fake/granite.gguf",
            "ll", "/fake/ll.gguf", "/fake/fin.gguf", mm,
        )
        l1 = swat._build_level_1_prompt(sample_invoice)
        l2 = swat._build_level_2_prompt(sample_invoice)
        l3 = swat._build_level_3_prompt(sample_invoice, rules_levels_data[0], rules_levels_data[1])
        l4 = swat._build_level_4_prompt(sample_invoice, rules_levels_data[0], rules_levels_data[1], rules_levels_data[2])

        prompts = {
            "JambaStrategist": jamba_prompt,
            "WorkflowPlanner": wp_prompt,
            "Rules L1": l1,
            "Rules L2": l2,
            "Rules L3": l3,
            "Rules L4": l4,
        }

        for name, prompt in prompts.items():
            assert "=== DECYZJA ===" in prompt, f"{name}: brak sekcji === DECYZJA ==="
            assert prompt.strip().endswith("Return ONLY a valid JSON object. No other text."), (
                f"{name}: === DECYZJA === nie kończy się przypomnieniem JSON"
            )

    def test_all_system_prompts_have_json_format(self) -> None:
        """Wszystkie stałe system prompt zawierają specyfikację JSON."""
        prompts = {
            "JAMBA_SYSTEM_PROMPT": JAMBA_SYSTEM_PROMPT,
            "WORKFLOW_PLANNER_PROMPT": WORKFLOW_PLANNER_PROMPT,
            "RULES_LEVEL_1_PROMPT": RULES_LEVEL_1_PROMPT,
            "RULES_LEVEL_2_PROMPT": RULES_LEVEL_2_PROMPT,
            "RULES_LEVEL_3_PROMPT": RULES_LEVEL_3_PROMPT,
            "RULES_LEVEL_4_PROMPT": RULES_LEVEL_4_PROMPT,
        }
        for name, prompt in prompts.items():
            assert "Return ONLY a valid JSON object" in prompt, (
                f"{name}: brak 'Return ONLY a valid JSON object'"
            )
