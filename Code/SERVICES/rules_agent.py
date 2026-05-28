"""
Rules SWAT Team — hierarchiczny przepływ agentów zgodności finansowej.

Architektura (4 poziomy):
  Level 1: LFM2.5-Thinking   → szybka ocena kontekstowa, decyzja: COMPLIANT / FLAG
  Level 2: Granite 4.0 1B    → walidacja reguł biznesowych, NIP, limity kwotowe
  Level 3: LittleLamb 0.3B   → ternary classification: COMPLIANT / FLAG / VIOLATION
  Level 4: Fin-RWKV-169M     → końcowa weryfikacja anomalii finansowych

Każdy kolejny poziom uruchamiany JEDYNIE jeśli poprzedni zwrócił FLAG / VIOLATION.
Jeśli poziom 1 (LFM) zwróci COMPLIANT z confidence ≥ 0.90 → fast-path: dalsze poziomy pominięte.
"""

from __future__ import annotations

import asyncio
import json
import re
from typing import Any

from core.config import AppConfig
from core.logger import get_logger
from services.council_agents import ModelManager

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------------

RULES_LEVEL_1_PROMPT = """Jesteś LFM2.5-Thinking — szybki analityk kontekstowy.
Oceń fakturę: czy jest typowa, czy wymaga dodatkowej weryfikacji.
Return ONLY a valid JSON object. No other text.
{
    "decision": "COMPLIANT" | "FLAG",
    "confidence": 0.0-1.0,
    "reasoning": "Krótkie uzasadnienie",
    "flags": []
}

Pole flags lista potencjalnych problemów:
[{"area": "nip" | "amount" | "vendor" | "category", "reason": "opis", "severity": "low" | "medium" | "high"}]
"""

RULES_LEVEL_2_PROMPT = """Jesteś Granite 4.0 1B Nano — agent walidacji reguł biznesowych.
Sprawdź fakturę pod kątem NIP, limitów kwotowych, polityki firmy.
Return ONLY a valid JSON object. No other text.
{
    "passed": true | false,
    "confidence": 0.0-1.0,
    "violations": [
        {"rule": "nip_validation" | "amount_limit" | "policy_compliance",
         "message": "opis", "severity": "warning" | "error"}
    ],
    "reasoning": "Krótkie uzasadnienie"
}
"""

RULES_LEVEL_3_PROMPT = """Jesteś LittleLamb 0.3B TC —Ternary Classifier.
Sklasyfikuj fakturę: COMPLIANT (zgodna), FLAG (oznaczona), VIOLATION (naruszenie).
Return ONLY a valid JSON object. No other text.
{
    "classification": "COMPLIANT" | "FLAG" | "VIOLATION",
    "confidence": 0.0-1.0,
    "risk_factors": [],
    "reasoning": "Krótkie uzasadnienie"
}

Pole risk_factors to lista czynników ryzyka:
[{"factor": "np. unknown_vendor", "weight": 0.0-1.0, "description": "opis"}]
"""

RULES_LEVEL_4_PROMPT = """Jesteś Fin-RWKV-169M — detektyw finansowy.
Zweryfikuj końcowo anomalię finansową. Oceń ryzyko: LOW / MEDIUM / HIGH.
Return ONLY a valid JSON object. No other text.
{
    "risk_level": "LOW" | "MEDIUM" | "HIGH",
    "confidence": 0.0-1.0,
    "anomaly_score": 0.0-1.0,
    "final_verdict": "COMPLIANT" | "FLAG",
    "reasoning": "Krótkie uzasadnienie",
    "recommended_action": "auto_post" | "review" | "block"
}
"""


# ---------------------------------------------------------------------------
# Rules SWAT Team
# ---------------------------------------------------------------------------

class RulesSWATTeam:
    """Hierarchiczny zespół agentów zgodności (SWAT Team).

    Przepływ:
      Level 1 (LFM2.5) → jeśli COMPLIANT + conf ≥ 0.90 → fast-path (zwróć wynik)
      Level 2 (Granite) → jeśli FLAG → uruchom Level 2
      Level 3 (LittleLamb) → jeśli violations → uruchom Level 3 (ternary classification)
      Level 4 (Fin-RWKV) → jeśli VIOLATION → uruchom Level 4 (końcowa weryfikacja)

    Każdy poziom używa ModelManager do mutual exclusion na RAM.
    """

    def __init__(
        self,
        lfm_model_name: str,
        lfm_model_path: str,
        granite_model_name: str,
        granite_model_path: str,
        littlelamb_model_name: str,
        littlelamb_model_path: str,
        fin_rwkv_model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
    ) -> None:
        self._lfm_name = lfm_model_name
        self._lfm_path = lfm_model_path
        self._granite_name = granite_model_name
        self._granite_path = granite_model_path
        self._ll_name = littlelamb_model_name
        self._ll_path = littlelamb_model_path
        self._fin_path = fin_rwkv_model_path
        self._model_manager = model_manager
        self._config = config or AppConfig()
        self._timeout = self._config.autopilot_agent_timeout_seconds

    async def evaluate(self, invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Pełna hierarchiczna ewaluacja.

        Returns dict z:
          - passed (bool): ostateczna decyzja
          - violations (list): lista naruszeń ze wszystkich poziomów
          - confidence (float): końcowe confidence
          - reasoning (str): pełne uzasadnienie
          - levels_used (list): jakie poziomy zostały użyte
          - level_results (dict): wyniki każdego poziomu
        """
        levels_used: list[str] = []
        all_violations: list[dict[str, Any]] = []
        combined_reasoning: list[str] = []

        # ---- Level 1: LFM2.5-Thinking (szybka ocena kontekstowa) ----
        logger.info("[RulesSWAT] Level 1: LFM2.5-Thinking starting")
        level1 = await self._run_level_1(invoice_data)
        levels_used.append("lfm25")
        combined_reasoning.append(f"Level1 (LFM): {level1.get('reasoning', '')}")

        if level1.get("decision") == "COMPLIANT" and level1.get("confidence", 0) >= 0.90:
            # Fast-path
            logger.info("[RulesSWAT] Level 1 fast-path: COMPLIANT with confidence %.4f", level1["confidence"])
            return self._build_result(
                passed=True,
                violations=[],
                confidence=level1["confidence"],
                reasoning=" | ".join(combined_reasoning),
                levels_used=levels_used,
                level_results={"level1_lfm25": level1},
            )

        # Przekaż flagi z Level 1
        for flag in level1.get("flags", []):
            all_violations.append({
                "rule": flag.get("area", "unknown"),
                "message": flag.get("reason", ""),
                "severity": flag.get("severity", "low"),
                "source": "level1_lfm25",
            })

        # ---- Level 2: Granite 4.0 1B (reguły biznesowe) ----
        logger.info("[RulesSWAT] Level 2: Granite 4.0 starting")
        level2 = await self._run_level_2(invoice_data)
        levels_used.append("granite")
        combined_reasoning.append(f"Level2 (Granite): {level2.get('reasoning', '')}")

        for v in level2.get("violations", []):
            all_violations.append({
                "rule": v.get("rule", "unknown"),
                "message": v.get("message", ""),
                "severity": v.get("severity", "warning"),
                "source": "level2_granite",
            })

        if level2.get("passed", True) and not all_violations:
            # Granite approve — bezpiecznie zwróć SUGGEST
            logger.info("[RulesSWAT] Level 2 passed — no violations")
            return self._build_result(
                passed=True,
                violations=[],
                confidence=level2.get("confidence", 0.7),
                reasoning=" | ".join(combined_reasoning),
                levels_used=levels_used,
                level_results={"level1_lfm25": level1, "level2_granite": level2},
            )

        # ---- Level 3: LittleLamb 0.3B (ternary classification) ----
        logger.info("[RulesSWAT] Level 3: LittleLamb starting")
        level3 = await self._run_level_3(invoice_data, level1, level2)
        levels_used.append("littlelamb")
        combined_reasoning.append(f"Level3 (LittleLamb): {level3.get('reasoning', '')}")

        for rf in level3.get("risk_factors", []):
            all_violations.append({
                "rule": rf.get("factor", "unknown"),
                "message": rf.get("description", ""),
                "severity": "error" if rf.get("weight", 0) > 0.7 else "warning",
                "source": "level3_littlelamb",
            })

        if level3.get("classification") == "COMPLIANT":
            logger.info("[RulesSWAT] Level 3: COMPLIANT — returning positive result")
            return self._build_result(
                passed=True,
                violations=all_violations,
                confidence=level3.get("confidence", 0.7),
                reasoning=" | ".join(combined_reasoning),
                levels_used=levels_used,
                level_results={
                    "level1_lfm25": level1,
                    "level2_granite": level2,
                    "level3_littlelamb": level3,
                },
            )

        # ---- Level 4: Fin-RWKV (końcowa weryfikacja) ----
        if level3.get("classification") in ("VIOLATION", "FLAG"):
            logger.info("[RulesSWAT] Level 4: Fin-RWKV starting")
            level4 = await self._run_level_4(invoice_data, level1, level2, level3)
            levels_used.append("fin_rwkv")
            combined_reasoning.append(f"Level4 (Fin-RWKV): {level4.get('reasoning', '')}")

            final_verdict = level4.get("final_verdict", "FLAG")
            passed = final_verdict == "COMPLIANT"

            return self._build_result(
                passed=passed,
                violations=all_violations,
                confidence=level4.get("confidence", 0.5),
                reasoning=" | ".join(combined_reasoning),
                levels_used=levels_used,
                level_results={
                    "level1_lfm25": level1,
                    "level2_granite": level2,
                    "level3_littlelamb": level3,
                    "level4_fin_rwkv": level4,
                },
            )

        # Fallback: jeśli Level 3 zwrócił FLAG, ale nie uruchomiono Level 4
        return self._build_result(
            passed=False,
            violations=all_violations,
            confidence=0.4,
            reasoning=" | ".join(combined_reasoning),
            levels_used=levels_used,
            level_results={
                "level1_lfm25": level1,
                "level2_granite": level2,
                "level3_littlelamb": level3,
            },
        )

    async def _run_level_1(self, invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Level 1: LFM2.5-Thinking — szybka ocena kontekstowa."""
        try:
            model = await self._model_manager.acquire(self._lfm_name, self._lfm_path)
            prompt = self._build_level_1_prompt(invoice_data)
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=512,
                    temperature=0.1,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            return self._parse_level_1(raw)
        except asyncio.TimeoutError:
            logger.error("[RulesSWAT L1] timeout")
            return {"decision": "FLAG", "confidence": 0.0, "reasoning": "Timeout", "flags": []}
        except Exception as exc:
            logger.error("[RulesSWAT L1] error: %s", exc)
            return {"decision": "FLAG", "confidence": 0.0, "reasoning": str(exc), "flags": []}
        finally:
            await self._model_manager.release()

    async def _run_level_2(self, invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Level 2: Granite 4.0 1B — reguły biznesowe."""
        try:
            model = await self._model_manager.acquire(self._granite_name, self._granite_path)
            prompt = self._build_level_2_prompt(invoice_data)
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=512,
                    temperature=0.1,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            return self._parse_level_2(raw)
        except asyncio.TimeoutError:
            logger.error("[RulesSWAT L2] timeout")
            return {"passed": False, "confidence": 0.0, "violations": [], "reasoning": "Timeout"}
        except Exception as exc:
            logger.error("[RulesSWAT L2] error: %s", exc)
            return {"passed": False, "confidence": 0.0, "violations": [], "reasoning": str(exc)}
        finally:
            await self._model_manager.release()

    async def _run_level_3(
        self,
        invoice_data: dict[str, Any],
        level1: dict[str, Any],
        level2: dict[str, Any],
    ) -> dict[str, Any]:
        """Level 3: LittleLamb 0.3B — ternary classification."""
        try:
            model = await self._model_manager.acquire(self._ll_name, self._ll_path)
            prompt = self._build_level_3_prompt(invoice_data, level1, level2)
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=512,
                    temperature=0.1,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            return self._parse_level_3(raw)
        except asyncio.TimeoutError:
            logger.error("[RulesSWAT L3] timeout")
            return {"classification": "FLAG", "confidence": 0.0, "risk_factors": [], "reasoning": "Timeout"}
        except Exception as exc:
            logger.error("[RulesSWAT L3] error: %s", exc)
            return {"classification": "FLAG", "confidence": 0.0, "risk_factors": [], "reasoning": str(exc)}
        finally:
            await self._model_manager.release()

    async def _run_level_4(
        self,
        invoice_data: dict[str, Any],
        level1: dict[str, Any],
        level2: dict[str, Any],
        level3: dict[str, Any],
    ) -> dict[str, Any]:
        """Level 4: Fin-RWKV-169M — końcowa weryfikacja."""
        try:
            model = await self._model_manager.acquire("fin_rwkv", self._fin_path)
            prompt = self._build_level_4_prompt(invoice_data, level1, level2, level3)
            response = await asyncio.wait_for(
                asyncio.to_thread(
                    model.create_chat_completion,
                    messages=[{"role": "user", "content": prompt}],
                    max_tokens=512,
                    temperature=0.1,
                    stop=None,
                ),
                timeout=self._timeout,
            )
            raw = response.get("choices", [{}])[0].get("message", {}).get("content", "")
            return self._parse_level_4(raw)
        except asyncio.TimeoutError:
            logger.error("[RulesSWAT L4] timeout")
            return {
                "risk_level": "HIGH", "confidence": 0.0, "anomaly_score": 0.5,
                "final_verdict": "FLAG", "reasoning": "Timeout",
                "recommended_action": "block",
            }
        except Exception as exc:
            logger.error("[RulesSWAT L4] error: %s", exc)
            return {
                "risk_level": "HIGH", "confidence": 0.0, "anomaly_score": 0.5,
                "final_verdict": "FLAG", "reasoning": str(exc),
                "recommended_action": "block",
            }
        finally:
            await self._model_manager.release()

    # ------------------------------------------------------------------
    # Prompts
    # ------------------------------------------------------------------

    def _build_level_1_prompt(self, invoice_data: dict[str, Any]) -> str:
        return f"""{RULES_LEVEL_1_PROMPT}

Kontekst faktury:
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota netto: {invoice_data.get('amount_net', '?')} PLN
- VAT: {invoice_data.get('vat', '?')} PLN
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}
- Kontrahent: {(invoice_data.get('vendor_profile') or {}).get('name', 'nieznany')}
- Czy kontrahent znany: {'tak' if (invoice_data.get('vendor_profile') or {}).get('known', False) else 'nie'}
- Liczba faktur od kontrahenta: {(invoice_data.get('vendor_profile') or {}).get('invoice_count', 0)}

Oceń szybko czy faktura wymaga dodatkowej weryfikacji."""

    def _build_level_2_prompt(self, invoice_data: dict[str, Any]) -> str:
        config = self._config
        max_amount = config.rules_max_invoice_amount
        return f"""{RULES_LEVEL_2_PROMPT}

Dane faktury:
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}
- Numer faktury: {invoice_data.get('number', 'brak')}

Reguły:
1. Maksymalna kwota: {max_amount} PLN
2. Wymagana walidacja NIP: tak
3. Sprawdź kategorię wydatku

Zweryfikuj zgodność z regułami."""

    def _build_level_3_prompt(
        self,
        invoice_data: dict[str, Any],
        level1: dict[str, Any],
        level2: dict[str, Any],
    ) -> str:
        return f"""{RULES_LEVEL_3_PROMPT}

Dane faktury:
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}

Wynik Level 1 (LFM2.5): {json.dumps(level1, ensure_ascii=False)}
Wynik Level 2 (Granite): {json.dumps(level2, ensure_ascii=False)}

Sklasyfikuj fakturę na podstawie powyższych wyników."""

    def _build_level_4_prompt(
        self,
        invoice_data: dict[str, Any],
        level1: dict[str, Any],
        level2: dict[str, Any],
        level3: dict[str, Any],
    ) -> str:
        return f"""{RULES_LEVEL_4_PROMPT}

Dane faktury:
- NIP: {invoice_data.get('contractor_nip', 'brak')}
- Kwota brutto: {invoice_data.get('amount_gross', '?')} PLN
- Kategoria: {invoice_data.get('category', 'brak')}

Level 1 (LFM): {json.dumps(level1, ensure_ascii=False)}
Level 2 (Granite): {json.dumps(level2, ensure_ascii=False)}
Level 3 (LittleLamb): {json.dumps(level3, ensure_ascii=False)}

Dokonaj końcowej weryfikacji i oceń ryzyko."""

    # ------------------------------------------------------------------
    # Parsers
    # ------------------------------------------------------------------

    @staticmethod
    def _parse_level_1(raw: str) -> dict[str, Any]:
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = json.loads(match.group(0))
                except json.JSONDecodeError:
                    return {"decision": "FLAG", "confidence": 0.0, "reasoning": "Parse error", "flags": []}
            else:
                return {"decision": "FLAG", "confidence": 0.0, "reasoning": "No JSON", "flags": []}
        return {
            "decision": str(parsed.get("decision", "FLAG")),
            "confidence": float(parsed.get("confidence", 0.0)),
            "reasoning": str(parsed.get("reasoning", "")),
            "flags": parsed.get("flags", []),
            "raw_response": raw,
        }

    @staticmethod
    def _parse_level_2(raw: str) -> dict[str, Any]:
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = json.loads(match.group(0))
                except json.JSONDecodeError:
                    return {"passed": False, "confidence": 0.0, "violations": [], "reasoning": "Parse error"}
            else:
                return {"passed": False, "confidence": 0.0, "violations": [], "reasoning": "No JSON"}
        violations = parsed.get("violations", [])
        if not isinstance(violations, list):
            violations = []
        return {
            "passed": bool(parsed.get("passed", False)),
            "confidence": float(parsed.get("confidence", 0.0)),
            "violations": violations,
            "reasoning": str(parsed.get("reasoning", "")),
            "raw_response": raw,
        }

    @staticmethod
    def _parse_level_3(raw: str) -> dict[str, Any]:
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = json.loads(match.group(0))
                except json.JSONDecodeError:
                    return {"classification": "FLAG", "confidence": 0.0, "risk_factors": [], "reasoning": "Parse error"}
            else:
                return {"classification": "FLAG", "confidence": 0.0, "risk_factors": [], "reasoning": "No JSON"}
        risk_factors = parsed.get("risk_factors", [])
        if not isinstance(risk_factors, list):
            risk_factors = []
        return {
            "classification": str(parsed.get("classification", "FLAG")),
            "confidence": float(parsed.get("confidence", 0.0)),
            "risk_factors": risk_factors,
            "reasoning": str(parsed.get("reasoning", "")),
            "raw_response": raw,
        }

    @staticmethod
    def _parse_level_4(raw: str) -> dict[str, Any]:
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            match = re.search(r"\{.*\}", raw, re.DOTALL)
            if match:
                try:
                    parsed = json.loads(match.group(0))
                except json.JSONDecodeError:
                    return {
                        "risk_level": "HIGH", "confidence": 0.0, "anomaly_score": 0.5,
                        "final_verdict": "FLAG", "reasoning": "Parse error",
                        "recommended_action": "block",
                    }
            else:
                return {
                    "risk_level": "HIGH", "confidence": 0.0, "anomaly_score": 0.5,
                    "final_verdict": "FLAG", "reasoning": "No JSON",
                    "recommended_action": "block",
                }
        return {
            "risk_level": str(parsed.get("risk_level", "HIGH")),
            "confidence": float(parsed.get("confidence", 0.0)),
            "anomaly_score": float(parsed.get("anomaly_score", 0.5)),
            "final_verdict": str(parsed.get("final_verdict", "FLAG")),
            "reasoning": str(parsed.get("reasoning", "")),
            "recommended_action": str(parsed.get("recommended_action", "review")),
            "raw_response": raw,
        }

# ---------------------------------------------------------------------------
# Legacy RulesAgent wrapper (backward compat)
# ---------------------------------------------------------------------------

class RulesAgent:
    """
    Legacy wrapper dla RulesSWATTeam zachowujący kompatybilność z tasks.py.
    
    Stary interfejs:
      RulesAgent(model_name, model_path, model_manager, config)
      await agent.evaluate(invoice_data) -> dict
    
    Nowy interfejs (wrapped):
      RulesSWATTeam(lfm_model_name, lfm_model_path, granite_model_name, granite_model_path,
                    littlelamb_model_name, littlelamb_model_path, fin_rwkv_model_path,
                    model_manager, config)
      await team.evaluate(invoice_data) -> dict
    """

    def __init__(
        self,
        model_name: str,
        model_path: str,
        model_manager: ModelManager,
        config: AppConfig | None = None,
    ) -> None:
        self._cfg = config or AppConfig()
        self._team = RulesSWATTeam(
            lfm_model_name=model_name,
            lfm_model_path=model_path,
            granite_model_name="granite",
            granite_model_path=self._cfg.rules_model_path,
            littlelamb_model_name="littlelamb",
            littlelamb_model_path=self._cfg.orchestrator_model_path,
            fin_rwkv_model_path=self._cfg.fin_detective_model_path,
            model_manager=model_manager,
            config=self._cfg,
        )

    async def evaluate(self, invoice_data: dict[str, Any]) -> dict[str, Any]:
        """Delegate to RulesSWATTeam.evaluate()."""
        return await self._team.evaluate(invoice_data)


    @staticmethod
    def _build_result(
        passed: bool,
        violations: list[dict[str, Any]],
        confidence: float,
        reasoning: str,
        levels_used: list[str],
        level_results: dict[str, Any],
    ) -> dict[str, Any]:
        return {
            "passed": passed,
            "violations": violations,
            "confidence": round(confidence, 4),
            "reasoning": reasoning,
            "levels_used": levels_used,
            "level_results": level_results,
        }
