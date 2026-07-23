"""
v7.0 KSeF/JPK — JPK_V7 Extended Fields Generator.

Rozszerza podstawową strukturę JPK_V7M o:
- Pełne pola sprzedaży K_15-K_36 (rozbicie na stawki VAT)
- Pełne pola zakupów P_40-P_52 (rozbicie na rodzaje zakupów)
- Oznaczenia: MPP, TP, FP, SW, EE, TP_WEW, WSTO_EE, IED
- Obsługa WDT (K_21-K_24), eksportu (K_19-K_20)
- Reverse charge, import VAT, OSS/IOSS
- Cross-check z KSeF (liczba faktur, kwoty)
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.jpk_v7")


# ── VAT Rate Mapping ─────────────────────────────────────────────────────────

# Mapowanie stawek VAT na pola JPK_V7M
VAT_RATE_TO_SALES_FIELDS: dict[int, dict[str, str]] = {
    23: {"netto": "K_15", "vat": "K_16"},
    22: {"netto": "K_17", "vat": "K_18"},
    8: {"netto": "K_21", "vat": "K_22"},   # WDT stawka 8%
    5: {"netto": "K_23", "vat": "K_24"},   # WDT stawka 5%
    0: {"netto": "K_19", "vat": "K_20"},   # Eksport 0%
    # Stawki specjalne
    -1: {"netto": "K_25", "vat": "K_26"},  # NP (niepodlegające)
    -2: {"netto": "K_27", "vat": "K_28"},  # ZW (zwolnione)
}

VAT_RATE_TO_PURCHASE_FIELDS: dict[int, dict[str, str]] = {
    23: {"netto": "P_40", "vat": "P_41"},
    8: {"netto": "P_42", "vat": "P_43"},
    5: {"netto": "P_44", "vat": "P_45"},
    0: {"netto": "P_46", "vat": "P_47"},
    -1: {"netto": "P_48", "vat": "P_49"},  # NP
}

# Oznaczenia JPK_V7
JPK_MARKINGS: dict[str, str] = {
    "MPP": "Mechanizm Podzielonej Płatności",
    "TP": "Transakcje powiązane (transfer pricing)",
    "FP": "Faktura do paragonu",
    "SW": "Świadczenie usług",
    "EE": "E-handel (elektroniczne)",
    "TP_WEW": "Transakcje wewnątrzzakładowe",
    "WSTO_EE": "Wewnątrzwspólnotowa sprzedaż na odległość",
    "IED": "Import e-commerce",
}


@dataclass
class JPKV7SalesRegister:
    """Rejestr sprzedaży VAT — pełne pola JPK_V7M."""
    # Podstawowe
    total_invoices: int = 0
    total_credit_notes: int = 0

    # K_10-K_14: Sumy ogólne
    K_10_netto: float = 0.0   # Dostawa towarów i świadczenie usług - netto
    K_11_vat: float = 0.0     # Dostawa towarów i świadczenie usług - VAT

    # K_15-K_36: Rozbicie na stawki VAT
    K_15_netto_23: float = 0.0
    K_16_vat_23: float = 0.0
    K_17_netto_22: float = 0.0
    K_18_vat_22: float = 0.0
    K_19_netto_export: float = 0.0    # Eksport 0%
    K_20_vat_export: float = 0.0
    K_21_netto_wdt_8: float = 0.0     # WDT 8%
    K_22_vat_wdt_8: float = 0.0
    K_23_netto_wdt_5: float = 0.0     # WDT 5%
    K_24_vat_wdt_5: float = 0.0
    K_25_netto_np: float = 0.0        # NP
    K_26_vat_np: float = 0.0
    K_27_netto_zw: float = 0.0        # ZW
    K_28_vat_zw: float = 0.0

    # K_29-K_36: OSS/IOSS, import, reverse charge
    K_29_netto_import: float = 0.0
    K_30_vat_import: float = 0.0
    K_31_netto_reverse: float = 0.0   # Reverse charge
    K_32_vat_reverse: float = 0.0
    K_33_netto_oss: float = 0.0       # OSS
    K_34_vat_oss: float = 0.0
    K_35_netto_ioss: float = 0.0      # IOSS
    K_36_vat_ioss: float = 0.0

    # Oznaczenia
    markings: set[str] = field(default_factory=set)


@dataclass
class JPKV7PurchaseRegister:
    """Rejestr zakupów VAT — pełne pola JPK_V7M."""
    # Podstawowe
    total_invoices: int = 0

    # P_38-P_39: Sumy ogólne
    P_38_netto: float = 0.0
    P_39_vat_do_odliczenia: float = 0.0

    # P_40-P_52: Rozbicie
    P_40_netto_23: float = 0.0
    P_41_vat_23: float = 0.0
    P_42_netto_8: float = 0.0
    P_43_vat_8: float = 0.0
    P_44_netto_5: float = 0.0
    P_45_vat_5: float = 0.0
    P_46_netto_0: float = 0.0
    P_47_vat_0: float = 0.0
    P_48_netto_np: float = 0.0
    P_49_vat_np: float = 0.0
    P_50_netto_wnt: float = 0.0       # Wewnątrzwspólnotowe nabycie
    P_51_vat_wnt: float = 0.0
    P_52_netto_import: float = 0.0    # Import
    P_53_vat_import: float = 0.0


@dataclass
class JPKV7Declaration:
    """Deklaracja VAT-7 z pełnymi polami."""
    sales: JPKV7SalesRegister
    purchases: JPKV7PurchaseRegister
    vat_due: float  # VAT należny
    vat_deductible: float  # VAT do odliczenia
    vat_to_pay: float  # Do zapłaty (>0) lub do zwrotu (<0)
    carry_forward: float  # Przeniesienie z poprzedniego okresu
    period_start: str
    period_end: str
    deadline: str  # 25. dnia następnego miesiąca
    markings: set[str] = field(default_factory=set)


class JPKV7Generator:
    """v7.0: Generator JPK_V7M z pełnymi polami."""

    def __init__(self, duckdb: Any = None) -> None:
        self._duckdb = duckdb

    def generate_sales_register(
        self,
        invoices: list[dict[str, Any]],
        period_start: str,
        period_end: str,
    ) -> JPKV7SalesRegister:
        """Generuj rejestr sprzedaży VAT z pełnym rozbiciem.

        Args:
            invoices: Lista faktur sprzedaży z polami:
                amount_net, amount_vat, vat_rate, is_export, is_wdt,
                is_oss, is_ioss, is_reverse_charge, markings.
            period_start: Początek okresu (YYYY-MM-DD).
            period_end: Koniec okresu (YYYY-MM-DD).
        """
        reg = JPKV7SalesRegister()

        for inv in invoices:
            date = inv.get("transaction_date", inv.get("date", ""))
            if date < period_start or date > period_end:
                continue

            net = self._parse_amount(inv, "amount_net", "amount_net_grosze")
            vat = self._parse_amount(inv, "amount_vat", "amount_vat_grosze")
            rate = inv.get("vat_rate", 23)
            is_credit = inv.get("is_credit_note", False)

            # Sumy ogólne
            if is_credit:
                reg.total_credit_notes += 1
                reg.K_10_netto -= net
                reg.K_11_vat -= vat
            else:
                reg.total_invoices += 1
                reg.K_10_netto += net
                reg.K_11_vat += vat

            # Rozbicie na stawki
            is_export = inv.get("is_export", False)
            is_wdt = inv.get("is_wdt", False)
            is_oss = inv.get("is_oss", False)
            is_ioss = inv.get("is_ioss", False)
            is_reverse = inv.get("is_reverse_charge", False)
            is_import = inv.get("is_import", False)

            sign = -1 if is_credit else 1

            if is_ioss:
                reg.K_35_netto_ioss += net * sign
                reg.K_36_vat_ioss += vat * sign
            elif is_oss:
                reg.K_33_netto_oss += net * sign
                reg.K_34_vat_oss += vat * sign
            elif is_import:
                reg.K_29_netto_import += net * sign
                reg.K_30_vat_import += vat * sign
            elif is_reverse:
                reg.K_31_netto_reverse += net * sign
                reg.K_32_vat_reverse += vat * sign
            elif is_export:
                reg.K_19_netto_export += net * sign
                reg.K_20_vat_export += vat * sign
            elif is_wdt:
                if rate == 8:
                    reg.K_21_netto_wdt_8 += net * sign
                    reg.K_22_vat_wdt_8 += vat * sign
                elif rate == 5:
                    reg.K_23_netto_wdt_5 += net * sign
                    reg.K_24_vat_wdt_5 += vat * sign
            elif rate == 23:
                reg.K_15_netto_23 += net * sign
                reg.K_16_vat_23 += vat * sign
            elif rate == 22:
                reg.K_17_netto_22 += net * sign
                reg.K_18_vat_22 += vat * sign
            elif rate == 0:
                reg.K_19_netto_export += net * sign
            elif rate == -1:
                reg.K_25_netto_np += net * sign
                reg.K_26_vat_np += vat * sign
            elif rate == -2:
                reg.K_27_netto_zw += net * sign
                reg.K_28_vat_zw += vat * sign

            # Oznaczenia
            for marking in inv.get("markings", []):
                if marking in JPK_MARKINGS:
                    reg.markings.add(marking)

        return reg

    def generate_purchase_register(
        self,
        invoices: list[dict[str, Any]],
        period_start: str,
        period_end: str,
    ) -> JPKV7PurchaseRegister:
        """Generuj rejestr zakupów VAT."""
        reg = JPKV7PurchaseRegister()

        for inv in invoices:
            date = inv.get("transaction_date", inv.get("date", ""))
            if date < period_start or date > period_end:
                continue

            net = float(inv.get("amount_net", 0))
            vat = float(inv.get("amount_vat", 0))
            rate = inv.get("vat_rate", 23)
            is_deductible = inv.get("vat_deductible", True)

            reg.total_invoices += 1
            reg.P_38_netto += net
            if is_deductible:
                reg.P_39_vat_do_odliczenia += vat

            is_wnt = inv.get("is_wnt", False)
            is_import = inv.get("is_import", False)

            if is_wnt:
                reg.P_50_netto_wnt += net
                reg.P_51_vat_wnt += vat
            elif is_import:
                reg.P_52_netto_import += net
                reg.P_53_vat_import += vat
            elif rate == 23:
                reg.P_40_netto_23 += net
                reg.P_41_vat_23 += vat
            elif rate == 8:
                reg.P_42_netto_8 += net
                reg.P_43_vat_8 += vat
            elif rate == 5:
                reg.P_44_netto_5 += net
                reg.P_45_vat_5 += vat
            elif rate == 0:
                reg.P_46_netto_0 += net
            elif rate == -1:
                reg.P_48_netto_np += net
                reg.P_49_vat_np += vat

        return reg

    def generate_declaration(
        self,
        sales: JPKV7SalesRegister,
        purchases: JPKV7PurchaseRegister,
        carry_forward: float = 0.0,
        period_start: str = "",
        period_end: str = "",
    ) -> JPKV7Declaration:
        """Generuj deklarację VAT-7."""
        vat_due = sales.K_11_vat
        vat_deductible = purchases.P_39_vat_do_odliczenia + carry_forward
        vat_to_pay = vat_due - vat_deductible

        import pendulum
        deadline = ""
        if period_end:
            try:
                d = pendulum.from_format(period_end, "YYYY-MM-DD")
                deadline = d.add(months=1).set(day=25).to_date_string()
            except Exception:
                deadline = "25 dnia następnego miesiąca"

        return JPKV7Declaration(
            sales=sales,
            purchases=purchases,
            vat_due=round(vat_due, 2),
            vat_deductible=round(vat_deductible, 2),
            vat_to_pay=round(vat_to_pay, 2),
            carry_forward=carry_forward,
            period_start=period_start,
            period_end=period_end,
            deadline=deadline,
            markings=sales.markings,  # v7.0 FIX: tylko sales ma markings
        )

    @staticmethod
    def _parse_amount(inv: dict[str, Any], key_pln: str, key_grosze: str) -> float:
        """v7.0 FIX: Niezawodna detekcja groszy — sprawdza klucze, nie stringi."""
        # Jeśli jest klucz z groszami, użyj go i podziel przez 100
        if key_grosze in inv and inv[key_grosze] is not None:
            return float(inv[key_grosze]) / 100.0
        # W przeciwnym razie użyj kwoty w PLN
        if key_pln in inv and inv[key_pln] is not None:
            return float(inv[key_pln])
        return 0.0

    def cross_check_with_ksef(
        self,
        sales: JPKV7SalesRegister,
        ksef_invoice_count: int,
        ksef_total_netto: float,
        ksef_total_vat: float,
    ) -> dict[str, Any]:
        """Cross-check JPK_V7 z danymi KSeF (JV7-1945).

        Returns:
            Dict z rozbieżnościami: count_diff, netto_diff, vat_diff, status.
        """
        count_diff = abs(sales.total_invoices - ksef_invoice_count)
        netto_diff = abs(sales.K_10_netto - ksef_total_netto)
        vat_diff = abs(sales.K_11_vat - ksef_total_vat)

        status = "ZGODNE"
        if count_diff >= 3 or netto_diff > 100 or vat_diff > 50:
            status = "NIEZGODNOSCI"
        elif count_diff > 0 or netto_diff > 0:
            status = "DROBNE_ROZBIEZNOSCI"

        return {
            "status": status,
            "count_diff": count_diff,
            "netto_diff": round(netto_diff, 2),
            "vat_diff": round(vat_diff, 2),
            "jpk_invoice_count": sales.total_invoices,
            "ksef_invoice_count": ksef_invoice_count,
            "jpk_total_netto": round(sales.K_10_netto, 2),
            "ksef_total_netto": round(ksef_total_netto, 2),
            "jpk_total_vat": round(sales.K_11_vat, 2),
            "ksef_total_vat": round(ksef_total_vat, 2),
        }
