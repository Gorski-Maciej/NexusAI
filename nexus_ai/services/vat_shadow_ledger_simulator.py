"""
v7.0 INNOWACJA 10: VAT Shadow Ledger What-If Simulator (DT-4).

Symuluje wpływ decyzji VAT na księgę główną przed faktycznym
zaksięgowaniem w TigerBeetle. Wykorzystuje DuckDB Shadow Ledger
do analizy what-if.

Symuluje:
- Wpływ na bilans (aktywa/pasywa)
- Wpływ na rachunek zysków i strat
- Wpływ na cash flow
- Wpływ na zobowiązania podatkowe
- Timeout 5s na symulację

Raport v7.0 REKOMENDACJA: Shadow Ledger z 5-sekundowym timeoutem.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.vat_shadow_simulator")


# ── Configuration ────────────────────────────────────────────────────────────

SIMULATION_TIMEOUT_SECONDS = 5.0


@dataclass
class VATBookingEntry:
    """Pojedynczy zapis księgowy VAT."""

    account: str  # Konto księgowe
    account_name: str
    debit: float = 0.0  # Wn
    credit: float = 0.0  # Ma
    description: str = ""
    vat_procedure: str = ""


@dataclass
class VATShadowResult:
    """Wynik symulacji Shadow Ledger."""

    vat_output_amount: float = 0.0  # VAT należny
    vat_input_amount: float = 0.0   # VAT naliczony
    vat_to_pay: float = 0.0         # Do zapłaty
    vat_to_refund: float = 0.0      # Do zwrotu
    net_effect_on_cash: float = 0.0
    net_effect_on_pl: float = 0.0
    balance_sheet_impact: float = 0.0
    bookings: list[VATBookingEntry] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)
    simulation_time_ms: float = 0.0
    timed_out: bool = False


# ── TigerBeetle Account Mapping for VAT ──────────────────────────────────────

VAT_ACCOUNT_MAP: dict[str, dict[str, str]] = {
    "SALE_23": {"account": "22-1", "name": "VAT należny 23%"},
    "SALE_8": {"account": "22-2", "name": "VAT należny 8%"},
    "SALE_5": {"account": "22-3", "name": "VAT należny 5%"},
    "SALE_0": {"account": "22-4", "name": "VAT należny 0%"},
    "SALE_EXEMPT": {"account": "22-5", "name": "VAT zwolniony"},
    "SALE_NP": {"account": "22-6", "name": "VAT NP (nie podlega)"},
    "PURCHASE_23": {"account": "22-7", "name": "VAT naliczony 23%"},
    "PURCHASE_8": {"account": "22-8", "name": "VAT naliczony 8%"},
    "PURCHASE_5": {"account": "22-9", "name": "VAT naliczony 5%"},
    "WNT": {"account": "22-10", "name": "VAT WNT"},
    "IMPORT_SERVICES": {"account": "22-11", "name": "VAT import usług"},
    "IMPORT_GOODS": {"account": "22-12", "name": "VAT import towarów"},
    "REVERSE_CHARGE": {"account": "22-13", "name": "VAT odwrotne obciążenie"},
    "MPP_RECEIVABLE": {"account": "22-20", "name": "VAT MPP — należności"},
    "MPP_PAYABLE": {"account": "22-21", "name": "VAT MPP — zobowiązania"},
    "BAD_DEBT_CREDITOR": {"account": "22-30", "name": "VAT — ulga złe długi (wierzyciel)"},
    "BAD_DEBT_DEBTOR": {"account": "22-31", "name": "VAT — korekta dłużnika"},
    "CORRECTION_IN_PLUS": {"account": "22-40", "name": "VAT — korekta in plus"},
    "CORRECTION_IN_MINUS": {"account": "22-41", "name": "VAT — korekta in minus"},
    "ANNUAL_CORRECTION": {"account": "22-50", "name": "VAT — korekta roczna"},
}


class VATShadowLedgerSimulator:
    """v7.0 DT-4: Symulator Shadow Ledger dla VAT.

    Przed faktycznym zaksięgowaniem w TigerBeetle, symuluje
    wpływ decyzji VAT na księgowość.

    Usage:
        sim = VATShadowLedgerSimulator()
        result = sim.simulate(invoice_data, vat_decision)
        if result.vat_to_pay > result.available_on_vat_account:
            print("UWAGA: Brak środków na rachunku VAT!")
    """

    def __init__(self) -> None:
        self._vat_account_balance: float = 0.0
        self._current_vat_payable: float = 0.0
        self._current_vat_receivable: float = 0.0

    def set_vat_account_balance(self, balance: float) -> None:
        """Ustaw saldo rachunku VAT."""
        self._vat_account_balance = balance

    def simulate(
        self,
        invoice_data: dict[str, Any],
        vat_decision: dict[str, Any] | None = None,
        current_vat_balance: float = 0.0,
        simulate_correction: bool = False,
    ) -> VATShadowResult:
        """Zasymuluj wpływ decyzji VAT na Shadow Ledger.

        Args:
            invoice_data: Dane faktury.
            vat_decision: Werdykt OPA (opcjonalnie).
            current_vat_balance: Bieżące saldo rachunku VAT.
            simulate_correction: Czy to korekta.

        Returns:
            VATShadowResult z bookingami i analizą wpływu.
        """
        import time
        start_time = time.monotonic()

        result = VATShadowResult()
        bookings: list[VATBookingEntry] = []

        direction = invoice_data.get("direction", "SALE")
        amount_net = float(invoice_data.get("amount_net", 0))
        amount_gross = float(invoice_data.get("amount_gross", 0))
        vat_amount = amount_gross - amount_net if amount_gross > amount_net else 0.0

        # Jeśli mamy werdykt OPA, użyj go
        if vat_decision:
            vat_rate_str = vat_decision.get("vat_rate", "")
            procedure = vat_decision.get("procedure", "")
            vat_exemption = vat_decision.get("vat_exemption", "")

            if vat_rate_str:
                try:
                    vat_rate = float(vat_rate_str)
                    vat_amount = amount_net * vat_rate
                except (ValueError, TypeError):
                    pass
        else:
            procedure = invoice_data.get("procedure", "")
            vat_exemption = invoice_data.get("vat_exemption", "")

        # Sprawdź timeout
        if time.monotonic() - start_time > SIMULATION_TIMEOUT_SECONDS:
            result.timed_out = True
            result.warnings.append("Symulacja przekroczyła timeout 5s")
            return result

        # ── Generuj bookingi ─────────────────────────────────────────
        if direction == "SALE":
            if vat_exemption in ("SUBJECT", "OBJECT"):
                # VAT zwolniony
                bookings.append(VATBookingEntry(
                    account="22-5", account_name="VAT zwolniony",
                    debit=0.0, credit=0.0,
                    description=f"Sprzedaż zwolniona VAT: {amount_net:.2f} PLN",
                    vat_procedure="EXEMPT",
                ))
                result.vat_output_amount = 0.0
            elif procedure == "NP" or vat_amount == 0.0:
                bookings.append(VATBookingEntry(
                    account="22-6", account_name="VAT NP",
                    debit=0.0, credit=0.0,
                    description=f"Transakcja poza VAT: {amount_net:.2f} PLN",
                    vat_procedure="NP",
                ))
            else:
                # VAT należny
                acct = VAT_ACCOUNT_MAP.get(f"SALE_{int(vat_amount/amount_net*100)}", VAT_ACCOUNT_MAP["SALE_23"])
                bookings.append(VATBookingEntry(
                    account=acct["account"], account_name=acct["name"],
                    debit=0.0, credit=vat_amount,
                    description=f"VAT należny od sprzedaży: {vat_amount:.2f} PLN",
                    vat_procedure="SALE",
                ))
                result.vat_output_amount = vat_amount

        elif direction == "PURCHASE":
            if procedure == "WNT":
                # WNT: VAT należny + VAT naliczony
                acct = VAT_ACCOUNT_MAP["WNT"]
                bookings.append(VATBookingEntry(
                    account=acct["account"], account_name=acct["name"],
                    debit=vat_amount, credit=vat_amount,
                    description=f"WNT: {vat_amount:.2f} PLN",
                    vat_procedure="WNT",
                ))
                result.vat_output_amount = vat_amount
                result.vat_input_amount = vat_amount
            elif procedure and procedure.startswith("REVERSE_CHARGE"):
                acct = VAT_ACCOUNT_MAP["REVERSE_CHARGE"]
                bookings.append(VATBookingEntry(
                    account=acct["account"], account_name=acct["name"],
                    debit=vat_amount, credit=vat_amount,
                    description=f"Odwrotne obciążenie: {vat_amount:.2f} PLN",
                    vat_procedure="REVERSE_CHARGE",
                ))
                result.vat_output_amount = vat_amount
                result.vat_input_amount = vat_amount
            elif procedure and "IMPORT" in procedure:
                acct = VAT_ACCOUNT_MAP.get("IMPORT_SERVICES", VAT_ACCOUNT_MAP["IMPORT_GOODS"])
                bookings.append(VATBookingEntry(
                    account=acct["account"], account_name=acct["name"],
                    debit=vat_amount, credit=0.0,
                    description=f"Import: VAT naliczony {vat_amount:.2f} PLN",
                    vat_procedure="IMPORT",
                ))
                result.vat_input_amount = vat_amount
            elif vat_exemption in ("SUBJECT", "OBJECT"):
                bookings.append(VATBookingEntry(
                    account="22-5", account_name="VAT zwolniony",
                    debit=0.0, credit=0.0,
                    description=f"Zakup zwolniony VAT: {amount_net:.2f} PLN",
                    vat_procedure="EXEMPT",
                ))
            else:
                # Standardowy zakup — VAT naliczony
                vat_rate_pct = int(vat_amount / max(amount_net, 0.01) * 100) if amount_net > 0 else 23
                purchase_key = f"PURCHASE_{vat_rate_pct}" if vat_rate_pct in (23, 8, 5) else "PURCHASE_23"
                bookings.append(VATBookingEntry(
                    account=acct["account"], account_name=acct["name"],
                    debit=vat_amount, credit=0.0,
                    description=f"VAT naliczony od zakupu: {vat_amount:.2f} PLN",
                    vat_procedure="PURCHASE",
                ))
                result.vat_input_amount = vat_amount

        # Procedury specjalne
        if procedure == "SPLIT_PAYMENT_MANDATORY" or procedure == "SPLIT_PAYMENT_VOLUNTARY":
            bookings.append(VATBookingEntry(
                account="22-20", account_name="VAT MPP — należności",
                debit=0.0, credit=vat_amount,
                description=f"MPP: {vat_amount:.2f} PLN",
                vat_procedure="MPP",
            ))

        if procedure and "BAD_DEBT" in procedure:
            acct = VAT_ACCOUNT_MAP.get("BAD_DEBT_CREDITOR", VAT_ACCOUNT_MAP["BAD_DEBT_DEBTOR"])
            bookings.append(VATBookingEntry(
                account=acct["account"], account_name=acct["name"],
                debit=0.0 if "CREDITOR" in procedure else vat_amount,
                credit=vat_amount if "CREDITOR" in procedure else 0.0,
                description=f"Złe długi: {vat_amount:.2f} PLN",
                vat_procedure="BAD_DEBT",
            ))

        # ── Oblicz wpływ netto ──────────────────────────────────────
        result.bookings = bookings
        result.vat_to_pay = result.vat_output_amount - result.vat_input_amount
        result.vat_to_refund = max(0.0, -result.vat_to_pay)
        result.vat_to_pay = max(0.0, result.vat_to_pay)
        result.net_effect_on_cash = -(result.vat_to_pay) + result.vat_to_refund
        result.net_effect_on_pl = 0.0  # VAT jest neutralny dla P&L (bilansowy)

        # Bilans: VAT należny = zobowiązanie (pasywa), VAT naliczony = należność (aktywa)
        result.balance_sheet_impact = result.vat_input_amount - result.vat_output_amount

        # ── Ostrzeżenia ──────────────────────────────────────────────
        if current_vat_balance < result.vat_to_pay and result.vat_to_pay > 0:
            shortage = result.vat_to_pay - current_vat_balance
            result.warnings.append(
                f"BRAK ŚRODKÓW: VAT do zapłaty {result.vat_to_pay:.2f} PLN > "
                f"saldo rachunku VAT {current_vat_balance:.2f} PLN. "
                f"Brakuje {shortage:.2f} PLN."
            )
            result.recommendations.append(
                "Zabezpiecz środki na rachunku VAT przed terminem płatności."
            )

        if result.vat_to_pay > 0:
            result.recommendations.append(
                f"VAT do zapłaty: {result.vat_to_pay:.2f} PLN. "
                f"Termin: 25. dzień następnego miesiąca."
            )

        if result.vat_to_refund > 0:
            result.recommendations.append(
                f"VAT do zwrotu: {result.vat_to_refund:.2f} PLN. "
                f"Standardowy termin zwrotu: 60 dni."
            )

        result.simulation_time_ms = (time.monotonic() - start_time) * 1000

        logger.info(
            "[SHADOW-VAT] output=%.2f input=%.2f to_pay=%.2f bookings=%d time=%.1fms",
            result.vat_output_amount,
            result.vat_input_amount,
            result.vat_to_pay,
            len(bookings),
            result.simulation_time_ms,
        )

        return result

    def simulate_batch(
        self,
        invoices: list[dict[str, Any]],
        decisions: list[dict[str, Any]] | None = None,
        current_vat_balance: float = 0.0,
    ) -> VATShadowResult:
        """Zasymuluj wpływ wielu faktur jednocześnie.

        Args:
            invoices: Lista faktur.
            decisions: Lista werdyktów OPA (opcjonalnie).
            current_vat_balance: Bieżące saldo rachunku VAT.

        Returns:
            Skonsolidowany VATShadowResult.
        """
        import time
        start_time = time.monotonic()

        consolidated = VATShadowResult()
        all_bookings: list[VATBookingEntry] = []

        for i, invoice in enumerate(invoices):
            # Sprawdź timeout
            if time.monotonic() - start_time > SIMULATION_TIMEOUT_SECONDS:
                consolidated.timed_out = True
                consolidated.warnings.append(
                    f"Symulacja batch przekroczyła timeout po {i}/{len(invoices)} fakturach"
                )
                break

            decision = decisions[i] if decisions and i < len(decisions) else None
            single_result = self.simulate(
                invoice, decision, current_vat_balance,
            )
            consolidated.vat_output_amount += single_result.vat_output_amount
            consolidated.vat_input_amount += single_result.vat_input_amount
            all_bookings.extend(single_result.bookings)
            consolidated.warnings.extend(single_result.warnings)

        consolidated.bookings = all_bookings
        consolidated.vat_to_pay = max(0.0,
            consolidated.vat_output_amount - consolidated.vat_input_amount,
        )
        consolidated.vat_to_refund = max(0.0,
            consolidated.vat_input_amount - consolidated.vat_output_amount,
        )
        consolidated.net_effect_on_cash = -consolidated.vat_to_pay
        consolidated.simulation_time_ms = (time.monotonic() - start_time) * 1000

        logger.info(
            "[SHADOW-VAT-BATCH] invoices=%d output=%.2f input=%.2f to_pay=%.2f time=%.1fms",
            len(invoices),
            consolidated.vat_output_amount,
            consolidated.vat_input_amount,
            consolidated.vat_to_pay,
            consolidated.simulation_time_ms,
        )

        return consolidated
