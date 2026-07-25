"""
OCRSupervisor — Nadzorca AI rozstrzygający spory między silnikami OCR.

Wdrożenie rekomendacji z Raportu Analitycznego Enterprise Pipeline OCR v7.0:
- Sekcja 1.4: "Zaimplementować dedykowany OCRSupervisor korzystający z InferenceService"
- Sekcja 8.2: "Auto-naprawa błędów OCR przez LLM"
- Sekcja 8.5: "Semantic-Aware OCR — kontekstowe rozpoznawanie"

v7.0 Audit — kluczowy brakujący komponent.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.pipeline.ocr_supervisor")

# ── Prompty dla Nadzorcy AI ──────────────────────────────────────────

OCR_DISPUTE_PROMPT = """Jesteś ekspertem OCR dla polskich faktur VAT. Otrzymujesz wyniki z 4 niezależnych silników OCR (Tesseract, PaddleOCR, docTR, EasyOCR), które zwróciły rozbieżne wartości dla pola faktury.

Dane faktury (OCR full text):
{document_context}

Wyniki wszystkich silników (wartość → confidence → engine):
{engine_results}

Dla pola **{field_name}** silniki zwróciły rozbieżne wartości:
{conflicting_values}

Twoje zadanie:
1. Oceń, która wartość jest najbardziej prawdopodobna na podstawie KONTEKSTU dokumentu
2. Sprawdź poprawność FORMATU (np. NIP: 10 cyfr, kwota: XX.XX format, IBAN: PL + 26 cyfr)
3. Sprawdź SPÓJNOŚĆ z innymi polami (np. kwota netto < kwota brutto)
4. Użyj słownika miast/kodów pocztowych jeśli to pole adresowe

Zwróć TYLKO JSON (bez markdown):
{{
    "resolved_value": "...",
    "confidence": 0.XX,
    "reasoning": "krótkie uzasadnienie",
    "engine_trusted": "nazwa silnika któremu ufasz najbardziej"
}}"""


OCR_FIELD_VALIDATION_PROMPT = """Jesteś walidatorem pól faktur. Otrzymujesz pole **{field_name}** o wartości **{field_value}** z confidence **{confidence}**.

Zweryfikuj poprawność:
1. FORMAT: czy wartość pasuje do oczekiwanego formatu pola?
2. KONTEKST: czy wartość jest sensowna w kontekście dokumentu?
3. ZAKRES: czy wartość mieści się w realistycznym zakresie?

Kontekst dokumentu (pierwsze 500 znaków):
{document_context}

Zwróć TYLKO JSON:
{{
    "is_valid": true/false,
    "confidence_adjustment": ±0.XX (korekta confidence),
    "corrected_value": "..." (lub null jeśli nie wymaga korekty),
    "reasoning": "krótkie uzasadnienie"
}}"""


class OCRSupervisor:
    """Nadzorca AI dla pipeline OCR.

    Integruje InferenceService (Granite 3.2 Vision) z pipeline OCR.
    Rozstrzyga spory między silnikami, waliduje pola, auto-naprawia błędy.

    Usage:
        supervisor = OCRSupervisor(model_manager)
        resolved = await supervisor.resolve_conflict(
            field_name="vendor_nip",
            consensus=consensus,
            all_results={"tesseract": {...}, "paddle": {...}},
            full_text=ocr_text,
        )
    """

    __slots__ = ('_model_manager', '_model_path', '_use_supervisor')

    # Walidatory formatów pól faktur (działają bez LLM — szybka ścieżka)
    FIELD_VALIDATORS: dict[str, str] = {
        "vendor_nip": r"^\d{10}$",
        "invoice_number": r"^.{3,50}$",
        "iban": r"^PL\d{26}$",
        "amount_gross": r"^\d+\.\d{2}$",
        "amount_net": r"^\d+\.\d{2}$",
        "issue_date": r"^\d{4}-\d{2}-\d{2}$",
        "postal_code": r"^\d{2}-\d{3}$",
    }

    def __init__(
        self,
        model_manager: Any = None,
        model_path: str = "granite-3.2-vision.Q4_K_M.gguf",
        use_supervisor: bool = True,
    ) -> None:
        self._model_manager = model_manager
        self._model_path = model_path
        self._use_supervisor = use_supervisor

    async def resolve_conflict(
        self,
        field_name: str,
        consensus: Any,  # OCRConsensusDecision
        all_engine_results: dict[str, dict[str, Any]],
        full_text: str = "",
        field_format: str | None = None,
    ) -> dict[str, Any]:
        """Rozstrzyga konflikt OCR używając AI.

        Args:
            field_name: Nazwa pola (np. "vendor_nip", "amount_gross").
            consensus: OCRConsensusDecision z flagą confidence_conflict=True.
            all_engine_results: Wyniki wszystkich silników {engine_name: {text, confidence}}.
            full_text: Pełny tekst OCR z dokumentu.
            field_format: Opcjonalny regex do walidacji formatu.

        Returns:
            Słownik z resolved_value, confidence, ai_resolved, reasoning.
        """
        if not consensus.confidence_conflict:
            return {
                "resolved_value": consensus.accepted.value if consensus.accepted else None,
                "confidence": consensus.accepted.confidence if consensus.accepted else 0.0,
                "ai_resolved": False,
                "reasoning": "no conflict",
            }

        # Szybka ścieżka: walidacja formatu bez LLM
        quick_result = self._quick_format_validation(field_name, consensus, field_format)
        if quick_result is not None:
            return quick_result

        # Ścieżka AI: użyj LLM do rozstrzygnięcia
        if self._use_supervisor and self._model_manager is not None:
            return await self._ai_resolve(field_name, consensus, all_engine_results, full_text)

        # Fallback: zwróć wartość z najwyższym confidence
        return self._fallback_resolve(consensus)

    def _quick_format_validation(
        self,
        field_name: str,
        consensus: Any,
        field_format: str | None = None,
    ) -> dict[str, Any] | None:
        """Szybka walidacja formatu pola bez użycia LLM.

        Returns:
            Rozwiązanie lub None jeśli nie można rozstrzygnąć szybką ścieżką.
        """
        pattern = field_format or self.FIELD_VALIDATORS.get(field_name)
        if pattern is None:
            return None

        regex = re.compile(pattern)

        # Sprawdź, która wartość pasuje do formatu
        valid_votes = []
        for vote in consensus.votes:
            if vote.value is not None:
                cleaned = self._clean_field_value(field_name, vote.value)
                if regex.match(cleaned):
                    valid_votes.append(vote)

        if len(valid_votes) == 1:
            return {
                "resolved_value": self._clean_field_value(field_name, valid_votes[0].value or ""),
                "confidence": valid_votes[0].confidence,
                "ai_resolved": False,
                "reasoning": f"format validation: only '{valid_votes[0].source}' matches {field_name} pattern",
            }

        # Dodatkowa walidacja dla NIP — suma kontrolna
        if field_name == "vendor_nip":
            return self._validate_nip_checksum(consensus)

        return None

    def _validate_nip_checksum(self, consensus: Any) -> dict[str, Any] | None:
        """Walidacja NIP przez sumę kontrolną."""
        nip_weights = [6, 5, 7, 2, 3, 4, 5, 6, 7]

        for vote in consensus.votes:
            if vote.value is not None:
                cleaned = re.sub(r"\D", "", vote.value)
                if len(cleaned) == 10:
                    try:
                        digits = [int(d) for d in cleaned]
                        checksum = sum(d * w for d, w in zip(digits[:9], nip_weights)) % 11
                        if checksum == digits[9]:
                            return {
                                "resolved_value": cleaned,
                                "confidence": max(vote.confidence, 0.90),
                                "ai_resolved": False,
                                "reasoning": f"NIP checksum validation passed for '{vote.source}'",
                            }
                    except (ValueError, IndexError):
                        continue
        return None

    async def _ai_resolve(
        self,
        field_name: str,
        consensus: Any,
        all_engine_results: dict[str, dict[str, Any]],
        full_text: str,
    ) -> dict[str, Any]:
        """Rozstrzyganie sporu przez AI (Granite 3.2 Vision)."""
        try:
            conflicting = []
            for vote in consensus.votes:
                if vote.value is not None:
                    conflicting.append({
                        "value": vote.value,
                        "confidence": vote.confidence,
                        "engine": vote.source,
                    })

            prompt = OCR_DISPUTE_PROMPT.format(
                field_name=field_name,
                document_context=full_text[:2000],
                engine_results=json.dumps(all_engine_results, indent=2, default=str)[:3000],
                conflicting_values=json.dumps(conflicting, indent=2),
            )

            result = await self._model_manager.chat(
                self._model_path,
                [{"role": "user", "content": prompt}],
                max_tokens=256,
                temperature=0.1,
            )

            # Parsuj JSON z odpowiedzi (może być opakowany w markdown)
            result_clean = result.strip()
            if "```json" in result_clean:
                result_clean = result_clean.split("```json")[1].split("```")[0]
            elif "```" in result_clean:
                result_clean = result_clean.split("```")[1].split("```")[0]

            data = json.loads(result_clean)
            return {
                "resolved_value": data.get("resolved_value"),
                "confidence": float(data.get("confidence", 0.7)),
                "ai_resolved": True,
                "reasoning": data.get("reasoning", "AI resolution"),
                "engine_trusted": data.get("engine_trusted", "unknown"),
            }

        except Exception as exc:
            logger.warning("[SUPERVISOR] AI resolution failed: %s", exc)
            return self._fallback_resolve(consensus)

    def _fallback_resolve(self, consensus: Any) -> dict[str, Any]:
        """Fallback: wybierz wartość z najwyższym confidence."""
        if consensus.accepted is not None:
            return {
                "resolved_value": consensus.accepted.value,
                "confidence": consensus.accepted.confidence,
                "ai_resolved": False,
                "reasoning": "fallback: highest confidence",
            }
        return {
            "resolved_value": None,
            "confidence": 0.0,
            "ai_resolved": False,
            "reasoning": "fallback: no valid result",
        }

    @staticmethod
    def _clean_field_value(field_name: str, value: str) -> str:
        """Wyczyść wartość pola (usuń spacje, myślniki dla NIP itp.)."""
        if field_name in ("vendor_nip",):
            return re.sub(r"[-\s]", "", value.strip())
        if field_name in ("iban",):
            return re.sub(r"\s", "", value.strip().upper())
        if field_name in ("amount_gross", "amount_net"):
            return value.strip().replace(",", ".").replace(" ", "")
        return value.strip()

    async def validate_field(
        self,
        field_name: str,
        field_value: str,
        confidence: float,
        document_context: str = "",
    ) -> dict[str, Any]:
        """Walidacja pojedynczego pola faktury z korektą confidence.

        Używa AI do weryfikacji poprawności pola w kontekście dokumentu.
        """
        if not self._use_supervisor or self._model_manager is None:
            return {"is_valid": True, "confidence_adjustment": 0.0, "corrected_value": None}

        # Szybka ścieżka: walidacja formatu
        pattern = self.FIELD_VALIDATORS.get(field_name)
        if pattern and not re.match(pattern, self._clean_field_value(field_name, field_value)):
            return {
                "is_valid": False,
                "confidence_adjustment": -0.3,
                "corrected_value": None,
                "reasoning": f"Failed format validation: {pattern}",
            }

        try:
            prompt = OCR_FIELD_VALIDATION_PROMPT.format(
                field_name=field_name,
                field_value=field_value,
                confidence=confidence,
                document_context=document_context[:500],
            )

            result = await self._model_manager.chat(
                self._model_path,
                [{"role": "user", "content": prompt}],
                max_tokens=128,
                temperature=0.1,
            )

            result_clean = result.strip()
            if "```" in result_clean:
                result_clean = result_clean.split("```")[1].split("```")[0].replace("json", "")

            data = json.loads(result_clean)
            return {
                "is_valid": data.get("is_valid", True),
                "confidence_adjustment": float(data.get("confidence_adjustment", 0.0)),
                "corrected_value": data.get("corrected_value"),
                "reasoning": data.get("reasoning", ""),
            }
        except Exception as exc:
            logger.warning("[SUPERVISOR] Field validation failed: %s", exc)
            return {"is_valid": True, "confidence_adjustment": 0.0, "corrected_value": None}

    async def auto_correct_ocr_errors(
        self,
        field_name: str,
        ocr_value: str,
        full_text: str = "",
    ) -> str | None:
        """Auto-naprawa typowych błędów OCR (0↔O, 1↔l, 5↔S, 8↔B).

        Raport v7.0, Innowacja 6: "LLM może wykrywać błędy OCR wynikające
        z podobieństwa znaków. Kontekst językowy pomaga."
        """
        if not self._use_supervisor or self._model_manager is None:
            return None

        # Szybka ścieżka: tylko jeśli wartość zawiera podejrzane znaki
        suspicious_chars = set("O0l1S5B8")
        if not any(c in ocr_value for c in suspicious_chars):
            return None

        try:
            prompt = f"""Popraw błędy OCR w wartości '{ocr_value}' dla pola '{field_name}'.
Typowe błędy: 0↔O, 1↔l, 5↔S, 8↔B.
Kontekst dokumentu: {full_text[:300]}

Zwróć TYLKO poprawioną wartość lub 'NO_CORRECTION':"""

            result = await self._model_manager.chat(
                self._model_path,
                [{"role": "user", "content": prompt}],
                max_tokens=32,
                temperature=0.0,
            )

            corrected = result.strip().strip("'\"")
            if corrected and corrected != "NO_CORRECTION" and corrected != ocr_value:
                logger.info("[SUPERVISOR] Auto-corrected '%s' → '%s'", ocr_value, corrected)
                return corrected
            return None
        except Exception as exc:
            logger.warning("[SUPERVISOR] Auto-correct failed: %s", exc)
            return None


__all__ = [
    "OCRSupervisor",
    "OCR_DISPUTE_PROMPT",
    "OCR_FIELD_VALIDATION_PROMPT",
]
