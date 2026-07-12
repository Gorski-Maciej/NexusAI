"""
Autonomous Tax Ruling Drafter (C2) — Generator wniosków KIS/WIS.
=================================================================

Część strategicznego planu 48_JDG_STRATEGIC_IMPROVEMENTS_V2.md.
Gdy Multi-Pass OPA nie znajduje pasującej reguły (NO_MATCH) lub wykrywa
konflikt, system automatycznie generuje draft wniosku o wydanie
Indywidualnej Interpretacji Podatkowej (KIS/WIS).

Wykorzystuje LLM (GPT-4/Claude) do generowania tekstu prawnego,
lub szablony statyczne jako fallback.

Status: Stub — wymaga LLM API key lub integracji z lokalnym modelem.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


# ── Szablon wniosku KIS ──────────────────────────────────────────────────────

KIS_TEMPLATE = """Naczelnik Krajowej Informacji Skarbowej
ul. Teodora Sixta 17, 43-300 Bielsko-Biała

WNIOSEK O WYDANIE INTERPRETACJI INDYWIDUALNEJ
na podstawie art. 14b § 1 Ordynacji podatkowej

I. DANE WNIOSKODAWCY
{nip_line}

II. OPIS STANU FAKTYCZNEGO
{stan_faktyczny}

III. OPIS PROBLEMU PRAWNEGO
{problem_prawny}

IV. STANOWISKO WNIOSKODAWCY
{stanowisko}

V. PYTANIE
{pytanie}

VI. OŚWIADCZENIE
Oświadczam, że elementy stanu faktycznego objęte wnioskiem o wydanie
interpretacji w dniu złożenia wniosku nie są przedmiotem toczącego się
postępowania podatkowego, kontroli podatkowej, kontroli celno-skarbowej
ani postępowania przed sądem administracyjnym.

{podpis}

---
Wygenerowano automatycznie przez NexusAI Tax Ruling Drafter
Data: {data_generacji}
⚠️ WYMAGA WERYFIKACJI PRZEZ KSIĘGOWEGO PRZED ZŁOŻENIEM
"""


@dataclass
class DraftedRuling:
    """Wygenerowany draft wniosku KIS/WIS."""
    content: str
    invoice_id: str
    conflict_rules: list[str] = field(default_factory=list)
    missing_rules: list[str] = field(default_factory=list)
    generated_at: str = ""
    model_used: str = "template"


class TaxRulingDrafter:
    """Generuje drafty wniosków o interpretację podatkową (KIS/WIS).

    Wykorzystuje LLM (jeśli dostępny) lub szablony statyczne jako fallback.
    Każdy draft wymaga weryfikacji przez księgowego przed złożeniem.
    """

    def __init__(self, llm_client: Any = None) -> None:
        self._llm = llm_client  # OpenAI / Anthropic / llama-cpp client

    def draft_ruling_request(
        self,
        verdict: dict[str, Any],
        opa_trace: dict[str, Any] | None = None,
        entrepreneur_data: dict[str, Any] | None = None,
    ) -> DraftedRuling:
        """Generuje draft wniosku KIS na podstawie werdyktu OPA.

        Args:
            verdict: Werdykt OPA z NO_MATCH lub konfliktem.
            opa_trace: Opcjonalny ślad ewaluacji OPA.
            entrepreneur_data: Dane przedsiębiorcy JDG.

        Returns:
            DraftedRuling z treścią wniosku.
        """
        import datetime as dt

        # Ekstrakcja danych
        invoice_id = verdict.get("invoice_id", "?")
        conflicting = verdict.get("_conflicts", [])
        warnings = verdict.get("_warnings", [])
        routing = verdict.get("_routing", "")

        # Budowa opisu stanu faktycznego
        stan_faktyczny = self._build_factual_description(verdict, entrepreneur_data)

        # Budowa opisu problemu prawnego
        problem_prawny = self._build_legal_problem(verdict, conflicting, warnings)

        # Budowa stanowiska i pytania
        stanowisko, pytanie = self._build_position_and_question(verdict)

        # Generowanie treści
        nip = entrepreneur_data.get("nip", "") if entrepreneur_data else ""
        nip_line = f"NIP: {nip}" if nip else "(do uzupełnienia)"

        if self._llm is not None:
            content = self._draft_with_llm(
                stan_faktyczny, problem_prawny, stanowisko, pytanie, nip_line,
            )
            model_used = "llm"
        else:
            content = KIS_TEMPLATE.format(
                nip_line=nip_line,
                stan_faktyczny=stan_faktyczny,
                problem_prawny=problem_prawny,
                stanowisko=stanowisko,
                pytanie=pytanie,
                podpis="_________________________",
                data_generacji=dt.datetime.now().strftime("%Y-%m-%d %H:%M"),
            )
            model_used = "template"

        return DraftedRuling(
            content=content,
            invoice_id=str(invoice_id),
            conflict_rules=[
                c.get("rule", "") if isinstance(c, dict) else str(c)
                for c in conflicting
            ],
            missing_rules=[
                verdict.get("rule_id", "unknown")
            ] if routing == "NO_MATCH" else [],
            generated_at=dt.datetime.now().isoformat(),
            model_used=model_used,
        )

    def _draft_with_llm(
        self,
        stan_faktyczny: str,
        problem_prawny: str,
        stanowisko: str,
        pytanie: str,
        nip_line: str,
    ) -> str:
        """Generuje treść wniosku przez LLM."""
        prompt = f"""Jesteś doradcą podatkowym. Wygeneruj wniosek o interpretację
indywidualną (KIS) na podstawie poniższych danych.

{nip_line}

STAN FAKTYCZNY:
{stan_faktyczny}

PROBLEM PRAWNY:
{problem_prawny}

STANOWISKO WNIOSKODAWCY:
{stanowisko}

PYTANIE:
{pytanie}

Format: oficjalny wniosek KIS zgodny z art. 14b § 1 Ordynacji podatkowej.
Język: polski, formalny, prawniczy.
"""

        try:
            response = self._llm.complete(prompt, max_tokens=2000)
            return response
        except Exception:
            return KIS_TEMPLATE.format(
                nip_line=nip_line,
                stan_faktyczny=stan_faktyczny,
                problem_prawny=problem_prawny,
                stanowisko=stanowisko,
                pytanie=pytanie,
                podpis="_________________________",
                data_generacji="(wygenerowano z szablonu)",
            )

    @staticmethod
    def _build_factual_description(
        verdict: dict[str, Any],
        entrepreneur_data: dict[str, Any] | None,
    ) -> str:
        """Buduje opis stanu faktycznego."""
        parts = []
        if entrepreneur_data:
            parts.append(
                f"Wnioskodawca prowadzi jednoosobową działalność gospodarczą "
                f"(PKD: {entrepreneur_data.get('pkd_main', '?')}), "
                f"opodatkowaną w formie {entrepreneur_data.get('tax_form', '?')}."
            )
        parts.append(
            f"W ramach działalności wnioskodawca otrzymał fakturę "
            f"nr {verdict.get('invoice_number', '?')} "
            f"na kwotę {verdict.get('amount_net', '?')} PLN netto "
            f"za {verdict.get('category_code', 'usługi')}."
        )
        return " ".join(parts)

    @staticmethod
    def _build_legal_problem(
        verdict: dict[str, Any],
        conflicting: list[Any],
        warnings: list[Any],
    ) -> str:
        """Buduje opis problemu prawnego."""
        if conflicting:
            conflict_desc = "; ".join(
                c.get("message", str(c)) if isinstance(c, dict) else str(c)
                for c in conflicting
            )
            return (
                f"W systemie księgowym wystąpił konflikt reguł podatkowych: "
                f"{conflict_desc}. Wnioskodawca ma wątpliwość co do prawidłowego "
                f"sposobu rozliczenia tej transakcji."
            )
        if warnings:
            return (
                f"System księgowy zgłosił ostrzeżenia: "
                f"{'; '.join(str(w) for w in warnings)}. "
                f"Wnioskodawca potrzebuje potwierdzenia prawidłowości rozliczenia."
            )
        return (
            "System księgowy nie odnalazł jednoznacznej reguły podatkowej dla "
            "tej transakcji. Wnioskodawca ma wątpliwość co do prawidłowego "
            "sposobu opodatkowania."
        )

    @staticmethod
    def _build_position_and_question(
        verdict: dict[str, Any],
    ) -> tuple[str, str]:
        """Buduje stanowisko wnioskodawcy i pytanie."""
        rule_id = verdict.get("rule_id", "brak reguły")
        routing = verdict.get("_routing", "")

        if routing == "NO_MATCH":
            stanowisko = (
                "W ocenie wnioskodawcy, transakcja powinna być opodatkowana "
                "według stawki podstawowej VAT 23% i stanowić koszt uzyskania "
                "przychodu w 100%."
            )
            pytanie = (
                "Czy prawidłowe jest stanowisko wnioskodawcy, że transakcja "
                "podlega opodatkowaniu VAT 23% i stanowi koszt uzyskania "
                "przychodu?"
            )
        else:
            stanowisko = (
                f"W ocenie wnioskodawcy, transakcja powinna być rozliczona "
                f"zgodnie z regułą {rule_id}, a ostrzeżenia systemu nie mają "
                f"zastosowania w tym stanie faktycznym."
            )
            pytanie = (
                "Czy prawidłowe jest stanowisko wnioskodawcy, że "
                "transakcja powinna być rozliczona w sposób opisany powyżej?"
            )

        return stanowisko, pytanie


def draft_ruling_for_triage(
    verdict: dict[str, Any],
    entrepreneur_data: dict[str, Any] | None = None,
) -> DraftedRuling:
    """Skrócona funkcja pomocnicza."""
    drafter = TaxRulingDrafter()
    return drafter.draft_ruling_request(verdict, entrepreneur_data=entrepreneur_data)
