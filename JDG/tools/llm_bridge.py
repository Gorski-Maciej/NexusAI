#!/usr/bin/env python3
"""
═══════════════════════════════════════════════════════════════════════════════
NexusAI JDG — LLM Co-Pilot Reasoning Bridge (C2 Strategic Initiative) [EKSPERYMENTALNY]
═══════════════════════════════════════════════════════════════════════════════

STATUS v8.1 (P27 R12): EKSPERYMENTALNY — Wymaga kluczy API (ANTHROPIC_API_KEY,
OPENAI_API_KEY, GEMINI_API_KEY). Używaj z flagą --experimental.

Rego ↔ LLM bridge — tłumaczy techniczne werdykty OPA na język naturalny.

Koncept: OPA zwraca JSON → Bridge pakuje _provenance_tree do promptu →
LLM (Gemini Flash / Claude Haiku / GPT-4o-mini) tłumaczy na prosty,
doradczy komunikat dla przedsiębiorcy JDG.

Architektura:
  1. Prompt Engineering — 5 szablonów dla różnych typów werdyktów
  2. Context Compressor — optymalizacja tokenów dla LLM
  3. Streaming SSE — dla UX (natychmiastowe wyświetlanie)
  4. Disclaimer — każde tłumaczenie opatrzone klauzulą non-authoritative

Użycie:
    from JDG.tools.llm_bridge import LLMBridge
    bridge = LLMBridge()
    explanation = bridge.explain(verdict, provenance_tree)

Autor: NexusAI — Główny Architekt Systemów Reguł Podatkowych
Data: 2026-07-17
Wersja: 1.0.0
"""

import hashlib
import json
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Optional


# ── Typy ──────────────────────────────────────────────────────────────────────

class ExplanationStyle(str, Enum):
    """Styl wyjaśnienia."""
    ADVISOR = "advisor"           # Ton doradcy — "Panie Marku, masz prawo do..."
    COMPLIANCE = "compliance"     # Ton compliance — formalny, ale przystępny
    EDUCATIONAL = "educational"   # Ton edukacyjny — "Dlaczego? Bo ustawa mówi..."
    EXECUTIVE = "executive"       # Ton executives — krótko i na temat
    ELI5 = "eli5"                 # "Explain Like I'm 5" — najprościej jak się da


class VerdictType(str, Enum):
    """Typ werdyktu OPA."""
    BLOCK_AND_ALERT = "BLOCK_AND_ALERT"    # 🔴 Zablokowano — poważne ryzyko
    TRIAGE_QUEUE = "TRIAGE_QUEUE"           # 🟡 Do analizy — wymaga uwagi
    ALLOW = "ALLOW"                          # 🟢 Dozwolone — bezpieczne
    WARNING = "WARNING"                      # ⚠️ Ostrzeżenie — uwaga
    INFO = "INFO"                            # ℹ️ Informacyjne


@dataclass
class VerdictContext:
    """Kontekst werdyktu do tłumaczenia."""
    rule_id: str
    package: str
    routing: str
    legal_basis: str
    warnings: list[str] = field(default_factory=list)
    priority: int = 0
    matched: bool = True
    provenance_path: list[dict] = field(default_factory=list)

    @property
    def verdict_type(self) -> VerdictType:
        routing = self.routing.upper()
        if "BLOCK" in routing:
            return VerdictType.BLOCK_AND_ALERT
        if "TRIAGE" in routing:
            return VerdictType.TRIAGE_QUEUE
        if "WARNING" in routing:
            return VerdictType.WARNING
        return VerdictType.ALLOW


@dataclass
class Explanation:
    """Wynik tłumaczenia werdyktu."""
    verdict_id: str
    style: ExplanationStyle
    title: str
    summary: str             # Krótkie podsumowanie (1-2 zdania)
    body: str                # Pełne wyjaśnienie
    recommendation: str      # Co zrobić
    risk_level: str          # 🟢/🟡/🔴
    legal_disclaimer: str
    model_used: str
    token_count: int
    timestamp: str


# ── Prompt Templates ───────────────────────────────────────────────────────────

class PromptTemplates:
    """
    Szablony promptów dla LLM.

    Każdy szablon jest zoptymalizowany pod kątem:
    - Niskiej liczby tokenów (Gemini Flash: 1M context window)
    - Języka polskiego (polski system prawny)
    - Tonu doradczego, nie urzędowego
    """

    SYSTEM_PROMPT = (
        "Jesteś Asystentem Podatkowym NexusAI dla polskich przedsiębiorców "
        "(JDG — jednoosobowa działalność gospodarcza). Twoim zadaniem jest "
        "tłumaczenie technicznych werdyktów silnika reguł OPA/Rego na "
        "prosty, zrozumiały język polski.\n\n"
        "ZASADY:\n"
        "1. Mów do przedsiębiorcy per 'Ty' lub używaj zwrotów grzecznościowych\n"
        "2. ZAWSZE cytuj podstawę prawną (artykuł + ustawa)\n"
        "3. Wyjaśnij DLACZEGO taka decyzja (łańcuch przyczynowy z provenance)\n"
        "4. Podaj KONKRETNE działanie do wykonania (korekta, zgłoszenie, termin)\n"
        "5. Oszacuj RYZYKO finansowe jeśli dotyczy\n"
        "6. Bądź EMPATYCZNY — przedsiębiorca nie jest prawnikiem\n"
        "7. NIE UŻYWAJ żargonu technicznego (OPA, Rego, WASM)\n"
        "8. KAŻDA odpowiedź musi kończyć się DISCLAIMEREM"
    )

    # Szablon dla BLOCK_AND_ALERT (poważne ryzyko)
    BLOCK_ALERT_TEMPLATE = (
        "⚠️ ALERT PODATKOWY — {title}\n\n"
        "{body}\n\n"
        "📋 PODSTAWA PRAWNA: {legal_basis}\n\n"
        "{warnings_section}"
        "💡 REKOMENDACJA: {recommendation}\n\n"
        "⏰ TERMIN: {deadline}\n\n"
        "⚠️ KONSEKWENCJE BRAKU DZIAŁANIA: {consequences}\n\n"
        "{disclaimer}"
    )

    # Szablon dla TRIAGE_QUEUE (do analizy)
    TRIAGE_TEMPLATE = (
        "🟡 WYMAGA TWOJEJ UWAGI — {title}\n\n"
        "{body}\n\n"
        "📋 PODSTAWA PRAWNA: {legal_basis}\n\n"
        "{warnings_section}"
        "💡 SUGEROWANE DZIAŁANIE: {recommendation}\n\n"
        "📊 SZACOWANE RYZYKO: {risk_estimate}\n\n"
        "{disclaimer}"
    )

    # Szablon dla ALLOW / INFO (bezpieczne)
    ALLOW_TEMPLATE = (
        "✅ {title}\n\n"
        "{body}\n\n"
        "📋 PODSTAWA PRAWNA: {legal_basis}\n\n"
        "💡 DOBRA PRAKTYKA: {recommendation}\n\n"
        "{disclaimer}"
    )

    # Szablon dla symulacji (Judgment Predictor)
    SIMULATION_TEMPLATE = (
        "🔮 SYMULACJA RYZYKA — {title}\n\n"
        "{body}\n\n"
        "📋 PODSTAWA PRAWNA: {legal_basis}\n\n"
        "{warnings_section}"
        "💡 REKOMENDACJA PRZED DZIAŁANIEM: {recommendation}\n\n"
        "💰 POTENCJALNE KARY: {potential_fines}\n"
        "📊 PRAWDOPODOBIEŃSTWO: {probability}\n\n"
        "{disclaimer}"
    )

    DISCLAIMER = (
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        "⚖️ DISCLAIMER PRAWNY: Niniejsza analiza została wygenerowana "
        "automatycznie przez system NexusAI na podstawie silnika reguł "
        "OPA/Rego i modelu językowego AI. NIE stanowi ona oficjalnej "
        "porady prawnej ani podatkowej w rozumieniu ustawy o doradztwie "
        "podatkowym. W przypadku wątpliwości skonsultuj się z "
        "licencjonowanym doradcą podatkowym lub radcą prawnym.\n"
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    )


# ── Context Compressor ─────────────────────────────────────────────────────────

class ContextCompressor:
    """
    Optymalizuje _provenance_tree do minimalnej liczby tokenów dla LLM.

    Z pełnego provenance tree wyciąga tylko kluczowe informacje:
    - rule_id + legal_basis
    - threshold_refs
    - routing decision
    - warnings
    """

    @staticmethod
    def compress(provenance_tree: dict, max_tokens: int = 2000) -> str:
        """
        Kompresuje provenance tree do formatu tekstowego zoptymalizowanego
        dla promptu LLM.
        """
        if not provenance_tree:
            return ""

        path = provenance_tree.get("path", [])

        lines = []
        lines.append("=== ŚCIEŻKA DECYZYJNA ===")

        for step in path:
            rule_id = step.get("rule_id", "?")
            legal_basis = step.get("legal_basis", "")
            routing = step.get("routing", "")
            warnings = step.get("warnings", [])
            threshold_refs = step.get("threshold_refs", [])

            step_line = f"• {rule_id}"
            if routing:
                step_line += f" → {routing}"
            if legal_basis:
                step_line += f" ({legal_basis})"

            lines.append(step_line)

            # Thresholds
            if threshold_refs:
                for ref in threshold_refs[:5]:  # max 5 thresholdów
                    lines.append(f"  - {ref.get('key', '?')}: {ref.get('value', '?')}")

            # Warnings (skrócone)
            if warnings:
                for w in warnings[:2]:  # max 2 ostrzeżenia
                    lines.append(f"  ⚠️ {w[:150]}")

        # Ograniczenie długości
        compressed = "\n".join(lines)
        if len(compressed) > max_tokens * 4:  # ~4 znaki/token
            compressed = compressed[:max_tokens * 4] + "\n... (ścieżka skrócona)"

        return compressed


# ── LLM Bridge ─────────────────────────────────────────────────────────────────

class LLMBridge:
    """
    Główny most Rego ↔ LLM.

    Obsługuje tłumaczenie werdyktów OPA na język naturalny
    z wykorzystaniem szablonów promptowych i kompresji kontekstu.
    """

    # Konfiguracja modeli
    MODELS = {
        "gemini-flash": {
            "name": "Gemini 2.0 Flash",
            "provider": "Google",
            "max_tokens": 1_000_000,
            "cost_per_1k_input": 0.00002,
            "cost_per_1k_output": 0.00008,
            "latency_ms": 200,
            "recommended_for": "default",
        },
        "claude-haiku": {
            "name": "Claude 3.5 Haiku",
            "provider": "Anthropic",
            "max_tokens": 200_000,
            "cost_per_1k_input": 0.0008,
            "cost_per_1k_output": 0.004,
            "latency_ms": 300,
            "recommended_for": "complex_legal",
        },
        "gpt-4o-mini": {
            "name": "GPT-4o Mini",
            "provider": "OpenAI",
            "max_tokens": 128_000,
            "cost_per_1k_input": 0.00015,
            "cost_per_1k_output": 0.0006,
            "latency_ms": 400,
            "recommended_for": "educational",
        },
    }

    def __init__(self, model: str = "gemini-flash", style: ExplanationStyle = ExplanationStyle.ADVISOR):
        self.model = model
        self.style = style
        self.compressor = ContextCompressor()
        self.templates = PromptTemplates()

        if model not in self.MODELS:
            raise ValueError(f"Unknown model: {model}. Available: {list(self.MODELS.keys())}")

        self.model_config = self.MODELS[model]

    def explain(
        self,
        verdict: dict,
        provenance_tree: Optional[dict] = None,
        style: Optional[ExplanationStyle] = None,
    ) -> Explanation:
        """
        Główna metoda — tłumaczy werdykt OPA na język naturalny.

        Args:
            verdict: Werdykt OPA (JSON)
            provenance_tree: Opcjonalne drzewo proweniencji z A1
            style: Styl wyjaśnienia (domyślnie z konstruktora)

        Returns:
            Explanation z pełnym tłumaczeniem
        """
        if style is None:
            style = self.style

        # Wyciągnij kontekst
        ctx = self._extract_context(verdict, provenance_tree)

        # Wybierz odpowiedni szablon
        template = self._select_template(ctx)

        # Skompresuj provenance tree
        compressed_context = ""
        if provenance_tree:
            compressed_context = self.compressor.compress(provenance_tree)

        # Zbuduj prompt
        prompt = self._build_prompt(template, ctx, compressed_context)

        # Symulacja odpowiedzi LLM (w produkcji: wywołanie API)
        explanation = self._simulate_llm_response(ctx, style, template, prompt)

        return explanation

    def simulate(
        self,
        prediction_result: dict,
        style: Optional[ExplanationStyle] = None,
    ) -> Explanation:
        """
        Tłumaczy wynik Judgment Predictora (C1) na język naturalny.
        """
        if style is None:
            style = self.style

        # Mapuj prediction result na verdict context
        risk_summary = prediction_result.get("risk_summary", {})
        findings = prediction_result.get("findings", [])

        ctx = VerdictContext(
            rule_id="jdg.predictor.simulation",
            package="jdg.predictor",
            routing="TRIAGE_QUEUE" if findings else "ALLOW",
            legal_basis="KKS + OP + VAT + PIT",
            warnings=[f["description"] for f in findings],
        )

        template = self.templates.SIMULATION_TEMPLATE

        # Zbuduj body
        body_parts = []
        for f in findings:
            body_parts.append(
                f"• {f['severity']} | {f['description']}\n"
                f"  Ryzyko: {f.get('probability_percent', 0):.0f}%\n"
                f"  Potencjalna kara: {f.get('potential_fine_pln', 0):,.0f} PLN"
            )

        body = "\n\n".join(body_parts) if body_parts else "Brak wykrytych zagrożeń."

        explanation = Explanation(
            verdict_id="simulation",
            style=style,
            title="Symulacja ryzyka podatkowego",
            summary=risk_summary.get("summary", ""),
            body=body,
            recommendation="Przeanalizuj wykryte zagrożenia przed finalizacją transakcji.",
            risk_level=risk_summary.get("risk_level", "NISKIE"),
            legal_disclaimer=self.templates.DISCLAIMER,
            model_used=self.model_config["name"],
            token_count=len(body) // 4,
            timestamp="",  # Ustawiane w produkcji
        )

        return explanation

    def _extract_context(
        self, verdict: dict, provenance_tree: Optional[dict]
    ) -> VerdictContext:
        """Wyciągnij kontekst z werdyktu OPA."""
        path = provenance_tree.get("path", []) if provenance_tree else []

        return VerdictContext(
            rule_id=verdict.get("rule_id", "unknown"),
            package=verdict.get("package", ""),
            routing=verdict.get("_routing", ""),
            legal_basis=verdict.get("_legal_basis", ""),
            warnings=verdict.get("_warnings", []),
            priority=verdict.get("priority", 0),
            matched=verdict.get("matched", False),
            provenance_path=path,
        )

    def _select_template(self, ctx: VerdictContext) -> str:
        """Wybierz odpowiedni szablon w zależności od typu werdyktu."""
        if ctx.verdict_type == VerdictType.BLOCK_AND_ALERT:
            return self.templates.BLOCK_ALERT_TEMPLATE
        elif ctx.verdict_type == VerdictType.TRIAGE_QUEUE:
            return self.templates.TRIAGE_TEMPLATE
        else:
            return self.templates.ALLOW_TEMPLATE

    def _build_prompt(
        self, template: str, ctx: VerdictContext, compressed_context: str
    ) -> str:
        """Zbuduj pełny prompt dla LLM."""
        # Sekcja ostrzeżeń
        warnings_section = ""
        if ctx.warnings:
            warnings_section = "⚠️ OSTRZEŻENIA:\n"
            for w in ctx.warnings[:3]:
                warnings_section += f"  • {w}\n"
            warnings_section += "\n"

        # Dla BLOCK_AND_ALERT
        if ctx.verdict_type == VerdictType.BLOCK_AND_ALERT:
            return template.format(
                title=f"Wykryto poważne ryzyko: {ctx.rule_id}",
                body=compressed_context or f"Reguła {ctx.rule_id} zablokowała transakcję.",
                legal_basis=ctx.legal_basis or "KKS + Ordynacja podatkowa",
                warnings_section=warnings_section,
                recommendation="Skontaktuj się z doradcą podatkowym przed kontynuacją.",
                deadline="NATYCHMIAST",
                consequences="Kara grzywny, pozbawienie wolności, utrata KUP, "
                              "solidarna odpowiedzialność za VAT.",
                disclaimer=self.templates.DISCLAIMER,
            )

        # Dla TRIAGE_QUEUE
        if ctx.verdict_type == VerdictType.TRIAGE_QUEUE:
            return template.format(
                title=f"Sprawa wymaga analizy: {ctx.rule_id}",
                body=compressed_context or f"Reguła {ctx.rule_id} wymaga ręcznej weryfikacji.",
                legal_basis=ctx.legal_basis or "Ordynacja podatkowa",
                warnings_section=warnings_section,
                recommendation="Przeanalizuj dokumentację i skonsultuj z księgową.",
                risk_estimate="Średnie — potencjalna korekta deklaracji.",
                disclaimer=self.templates.DISCLAIMER,
            )

        # Dla ALLOW
        return template.format(
            title=f"Transakcja zgodna z prawem: {ctx.rule_id}",
            body=compressed_context or "Wszystkie reguły przeszły pomyślnie.",
            legal_basis=ctx.legal_basis or "VAT + PIT",
            recommendation="Zachowaj dokumentację na wypadek kontroli (5 lat).",
            disclaimer=self.templates.DISCLAIMER,
        )

    def _simulate_llm_response(
        self, ctx: VerdictContext, style: ExplanationStyle, template: str, prompt: str
    ) -> Explanation:
        """
        Odpowiedź LLM — próbuje realnego API, fallback do symulacji.
        """
        # Próbuj realnego API (Gemini / Claude / GPT)
        try:
            real_response = self._call_real_api(ctx, prompt)
            if real_response:
                return real_response
        except Exception:
            pass  # Fallback do symulacji

        return self._build_simulated_explanation(ctx, style, prompt)

    def _call_real_api(self, ctx: VerdictContext, prompt: str) -> Explanation | None:
        """
        Wywołuje rzeczywiste API modelu LLM.
        Obsługuje Gemini, Claude Haiku, GPT-4o-mini.
        """
        if "gemini" in self.model:
            return self._call_gemini_api(ctx, prompt)
        elif "claude" in self.model:
            return self._call_claude_api(ctx, prompt)
        elif "gpt" in self.model:
            return self._call_openai_api(ctx, prompt)
        return None

    def _call_gemini_api(self, ctx: VerdictContext, prompt: str) -> Explanation | None:
        """Wywołuje Google Gemini API."""
        import os
        api_key = os.environ.get("GEMINI_API_KEY", "")
        if not api_key:
            return None
        try:
            import google.generativeai as genai
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel(
                "gemini-2.0-flash",
                system_instruction=self.templates.SYSTEM_PROMPT,
            )
            response = model.generate_content(
                prompt,
                generation_config={"temperature": 0.2, "max_output_tokens": 1000},
            )
            body = response.text if response.text else ""
            return Explanation(
                verdict_id=ctx.rule_id,
                style=ExplanationStyle.ADVISOR,
                title=f"Analiza: {ctx.rule_id}",
                summary=body[:200] + "..." if len(body) > 200 else body,
                body=body,
                recommendation=self._extract_recommendation(body),
                risk_level=self._classify_risk_from_response(body),
                legal_disclaimer=self.templates.DISCLAIMER,
                model_used=f"{self.model_config['name']} (Gemini API)",
                token_count=len(prompt) // 4,
                timestamp="",
            )
        except ImportError:
            return None
        except Exception:
            return None

    def _call_claude_api(self, ctx: VerdictContext, prompt: str) -> Explanation | None:
        """Wywołuje Anthropic Claude API."""
        import os
        api_key = os.environ.get("ANTHROPIC_API_KEY", "")
        if not api_key:
            return None
        try:
            import anthropic
            client = anthropic.Anthropic(api_key=api_key)
            response = client.messages.create(
                model="claude-3-5-haiku-latest",
                max_tokens=1000,
                system=self.templates.SYSTEM_PROMPT,
                messages=[{"role": "user", "content": prompt}],
            )
            body = response.content[0].text if response.content else ""
            return Explanation(
                verdict_id=ctx.rule_id,
                style=ExplanationStyle.COMPLIANCE,
                title=f"Analiza prawna: {ctx.rule_id}",
                summary=body[:200] + "..." if len(body) > 200 else body,
                body=body,
                recommendation=self._extract_recommendation(body),
                risk_level=self._classify_risk_from_response(body),
                legal_disclaimer=self.templates.DISCLAIMER,
                model_used=f"{self.model_config['name']} (Claude API)",
                token_count=len(prompt) // 4,
                timestamp="",
            )
        except ImportError:
            return None
        except Exception:
            return None

    def _call_openai_api(self, ctx: VerdictContext, prompt: str) -> Explanation | None:
        """Wywołuje OpenAI API."""
        import os
        api_key = os.environ.get("OPENAI_API_KEY", "")
        if not api_key:
            return None
        try:
            import openai
            client = openai.OpenAI(api_key=api_key)
            response = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": self.templates.SYSTEM_PROMPT},
                    {"role": "user", "content": prompt},
                ],
                max_tokens=1000,
                temperature=0.2,
            )
            body = response.choices[0].message.content if response.choices else ""
            return Explanation(
                verdict_id=ctx.rule_id,
                style=ExplanationStyle.EDUCATIONAL,
                title=f"Wyjaśnienie: {ctx.rule_id}",
                summary=body[:200] + "..." if len(body) > 200 else body,
                body=body,
                recommendation=self._extract_recommendation(body),
                risk_level=self._classify_risk_from_response(body),
                legal_disclaimer=self.templates.DISCLAIMER,
                model_used=f"{self.model_config['name']} (OpenAI API)",
                token_count=len(prompt) // 4,
                timestamp="",
            )
        except ImportError:
            return None
        except Exception:
            return None

    def _extract_recommendation(self, text: str) -> str:
        """Próbuje wyciągnąć rekomendację z odpowiedzi LLM."""
        import re
        match = re.search(r'(?:Rekomendacj|Zalecam|Sugeruj)[^.]*\.', text, re.IGNORECASE)
        return match.group(0) if match else "Skonsultuj się z doradcą podatkowym."

    def _classify_risk_from_response(self, text: str) -> str:
        """Klasyfikuje poziom ryzyka na podstawie odpowiedzi."""
        text_lower = text.lower()
        if any(w in text_lower for w in ["krytyczne", "poważne", "przestępstwo", "pozbawienie"]):
            return "🔴 KRYTYCZNE"
        if any(w in text_lower for w in ["wysokie", "znaczne", "grzywna", "kara"]):
            return "🟠 WYSOKIE"
        if any(w in text_lower for w in ["średnie", "umiarkowane", "korekta", "weryfikacj"]):
            return "🟡 ŚREDNIE"
        return "🟢 NISKIE"

    def _build_simulated_explanation(
        self, ctx: VerdictContext, style: ExplanationStyle, prompt: str
    ) -> Explanation:
        # Wybierz tytuł i body w zależności od typu
        if ctx.verdict_type == VerdictType.BLOCK_AND_ALERT:
            title = f"🚫 ALERT: {ctx.rule_id}"
            body = (
                f"Drogi Przedsiębiorco,\n\n"
                f"System NexusAI wykrył poważne ryzyko podatkowe w Twojej transakcji. "
                f"Reguła {ctx.rule_id} została uruchomiona, co oznacza, że "
                f"kontynuacja tej operacji może narazić Cię na odpowiedzialność "
                f"karno-skarbową.\n\n"
                f"Podstawa prawna: {ctx.legal_basis}\n\n"
                f"Ryzyko obejmuje potencjalne kary grzywny, a w skrajnych przypadkach "
                f"nawet pozbawienie wolności. Zdecydowanie zalecamy wstrzymanie "
                f"transakcji i konsultację z doradcą podatkowym."
            )
            summary = f"Poważne ryzyko KKS — {ctx.rule_id}"
            recommendation = "Wstrzymaj transakcję. Skontaktuj się z doradcą podatkowym."
            risk_level = "🔴 KRYTYCZNE"

        elif ctx.verdict_type == VerdictType.TRIAGE_QUEUE:
            title = f"🟡 Do weryfikacji: {ctx.rule_id}"
            body = (
                f"Drogi Przedsiębiorco,\n\n"
                f"Reguła {ctx.rule_id} wymaga Twojej uwagi. System nie może "
                f"automatycznie rozstrzygnąć tej kwestii — potrzebna jest "
                f"ręczna weryfikacja dokumentacji.\n\n"
                f"Podstawa prawna: {ctx.legal_basis}\n\n"
                f"Zalecamy przejrzenie odpowiednich dokumentów i konsultację "
                f"z księgową przed kontynuacją."
            )
            summary = f"Wymaga ręcznej weryfikacji — {ctx.rule_id}"
            recommendation = "Przejrzyj dokumentację i skonsultuj z księgową."
            risk_level = "🟡 ŚREDNIE"

        else:
            title = f"✅ Bezpieczna transakcja"
            body = (
                f"Drogi Przedsiębiorco,\n\n"
                f"System NexusAI nie wykrył żadnych niezgodności podatkowych "
                f"w analizowanej transakcji. Wszystkie reguły zostały "
                f"zweryfikowane pozytywnie.\n\n"
                f"Pamiętaj o przechowywaniu dokumentacji przez 5 lat "
                f"(Art. 86 Ordynacji podatkowej)."
            )
            summary = "Transakcja zgodna z przepisami"
            recommendation = "Zachowaj dokumentację (5 lat)."
            risk_level = "🟢 NISKIE"

        return Explanation(
            verdict_id=ctx.rule_id,
            style=style,
            title=title,
            summary=summary,
            body=body,
            recommendation=recommendation,
            risk_level=risk_level,
            legal_disclaimer=self.templates.DISCLAIMER,
            model_used=f"{self.model_config['name']} (simulated)",
            token_count=len(prompt) // 4,
            timestamp="",
        )


# ── API Response Builder ───────────────────────────────────────────────────────

def build_explanation_response(
    bridge: LLMBridge,
    verdict: dict,
    provenance_tree: Optional[dict] = None,
    style: Optional[ExplanationStyle] = None,
) -> dict:
    """
    Buduje odpowiedź API dla endpointu /jdg/explain.

    Zwraca pełne wyjaśnienie w formacie JSON gotowym do użycia w UI.
    """
    explanation = bridge.explain(verdict, provenance_tree, style)

    return {
        "status": "ok",
        "explanation": {
            "title": explanation.title,
            "summary": explanation.summary,
            "body": explanation.body,
            "recommendation": explanation.recommendation,
            "risk_level": explanation.risk_level,
            "style": explanation.style.value,
            "model_used": explanation.model_used,
            "legal_disclaimer": explanation.legal_disclaimer,
        },
        "source_verdict": {
            "rule_id": verdict.get("rule_id", ""),
            "routing": verdict.get("_routing", ""),
            "legal_basis": verdict.get("_legal_basis", ""),
        },
    }


# ── CLI ────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="NexusAI JDG — LLM Co-Pilot Reasoning Bridge (C2)"
    )
    parser.add_argument("--verdict", type=str, help="Path to verdict JSON file")
    parser.add_argument("--provenance", type=str, help="Path to provenance tree JSON")
    parser.add_argument("--style", type=str, default="advisor",
                        choices=["advisor", "compliance", "educational", "executive", "eli5"])
    parser.add_argument("--model", type=str, default="gemini-flash",
                        choices=["gemini-flash", "claude-haiku", "gpt-4o-mini"])
    parser.add_argument("--demo", action="store_true", help="Run demo explanation")

    args = parser.parse_args()

    bridge = LLMBridge(model=args.model, style=ExplanationStyle(args.style))

    if args.demo:
        demo_verdict = {
            "matched": True,
            "rule_id": "jdg.compliance.whitelist_missing_over_limit",
            "package": "jdg.compliance",
            "priority": 20,
            "_routing": "BLOCK_AND_ALERT",
            "_routing_reason": "Przelew >15k PLN na rachunek spoza Białej Listy",
            "_legal_basis": "Art. 117ba Ordynacji podatkowej + Art. 22 ust. 4aa PIT",
            "_warnings": [
                "Przelew na rachunek spoza Białej Listy VAT — "
                "koszt nie będzie stanowił KUP!",
                "Ryzyko solidarnej odpowiedzialności za VAT kontrahenta."
            ],
        }

        demo_provenance = {
            "path": [
                {
                    "step": 1, "package": "jdg.main",
                    "rule_id": "jdg.main.router",
                    "legal_basis": "",
                    "routing": "SHARD: compliance"
                },
                {
                    "step": 2, "package": "jdg.compliance",
                    "rule_id": "jdg.compliance.whitelist_missing_over_limit",
                    "legal_basis": "Art. 96b VAT + Art. 117ba OrdPU",
                    "routing": "BLOCK_AND_ALERT",
                    "warnings": [
                        "Przelew >15k PLN na rachunek spoza Białej Listy"
                    ]
                }
            ],
            "root_hash": "sha256:demo",
            "evaluation_ms": 4
        }

        print("═" * 78)
        print("  NexusAI JDG — LLM Co-Pilot Reasoning Bridge DEMO")
        print(f"  Model: {bridge.model_config['name']}")
        print(f"  Styl: {args.style}")
        print("═" * 78)
        print()

        response = build_explanation_response(
            bridge, demo_verdict, demo_provenance, ExplanationStyle(args.style)
        )

        print(json.dumps(response, indent=2, ensure_ascii=False))

    elif args.verdict:
        with open(args.verdict, encoding="utf-8") as f:
            verdict = json.load(f)

        provenance = None
        if args.provenance:
            with open(args.provenance, encoding="utf-8") as f:
                provenance = json.load(f)

        response = build_explanation_response(
            bridge, verdict, provenance, ExplanationStyle(args.style)
        )

        print(json.dumps(response, indent=2, ensure_ascii=False))

    else:
        parser.print_help()
