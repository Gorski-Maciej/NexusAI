"""
Context Interpreter — formalny interpreter kontekstu faktury (Element 2).

Przekształca znormalizowane dane faktury (pochodzące z OCR i wzbogaceń)
w płaski słownik klucz-wartość do ewaluacji warunków SQL reguł.

Kluczowe cechy:
  - ALLOWED_KEYS — whitelista dozwolonych kluczy w kontekście
  - Automatyczne typowanie (date→ISO string, Decimal→string)
  - amount_net_grosze — konwersja netto na grosze
  - Walidacja wymaganych pól
  - Bezpieczny — tylko dozwolone klucze trafiają do kontekstu

Usage:
    interpreter = ContextInterpreter()
    ctx = interpreter.interpret(invoice_data)
    engine.decide(ctx)
"""

from __future__ import annotations

from datetime import date
from decimal import Decimal, ROUND_HALF_UP
from typing import Any


# ── Exception ─────────────────────────────────────────────────────

class ContextInterpreterError(ValueError):
    """Błąd interpretacji kontekstu — brak wymaganego pola lub nieprawidłowy typ."""
    pass


# ── Allowed keys whitelist ────────────────────────────────────────

ALLOWED_KEYS: frozenset[str] = frozenset({
    # Podstawowe
    "category_code",
    "transaction_date",
    "vendor_country",
    "company_tax_form",
    "vendor_nip",
    "amount_net",
    "amount_net_grosze",
    # Wzbogacone przez inne moduły
    "vendor_vat_status",
    "vendor_pkd",
    "vendor_account_on_whitelist",
    "expense_type",
    "confidence_vat_rate",
})

REQUIRED_KEYS: frozenset[str] = frozenset({
    "transaction_date",
})

COUNTRY_NORMALIZATION: dict[str, str] = {
    "polska": "PL",
    "poland": "PL",
    "deutschland": "DE",
    "germany": "DE",
    "niemcy": "DE",
    "usa": "US",
    "united states": "US",
    "stany zjednoczone": "US",
    "unia europejska": "EU",
    "european union": "EU",
}


class ContextInterpreter:
    """Interpreter Kontekstu — mapuje surowe dane faktury na płaski słownik.

    Wynikowy słownik zawiera tylko dozwolone klucze (ALLOWED_KEYS),
    wszystkie wartości są stringami dla bezpiecznej ewaluacji SQL.

    Usage:
        ctx = ContextInterpreter.interpret({
            "category_code": "FUEL",
            "transaction_date": "2024-06-15",
            "vendor": {"country": "PL", "nip": "1234567890"},
            "amount_net": Decimal("1000.00"),
        })
    """

    @staticmethod
    def build(invoice_data: dict[str, Any]) -> dict[str, str]:
        """Alias dla :meth:`interpret` — zachowuje zgodność z istniejącym kodem."""
        return ContextInterpreter.interpret(invoice_data)

    @staticmethod
    def interpret(invoice_data: dict[str, Any]) -> dict[str, str]:
        """Przekształć dane faktury w płaski kontekst dla silnika reguł.

        Args:
            invoice_data: Słownik z danymi faktury. Może zawierać:
                - category_code / category: str
                - transaction_date / invoice_date: str (YYYY-MM-DD) lub date
                - company_tax_form: str
                - vendor_country / vendor.country: str
                - vendor_nip / vendor.nip: str
                - amount_net / total_net: Decimal | str | float | int
                - vendor_vat_status: str
                - vendor_pkd: str
                - vendor_account_on_whitelist: bool
                - expense_type: str
                - confidence_vat_rate: float

        Returns:
            Słownik kontekstu z wartościami jako stringi.

        Raises:
            ContextInterpreterError: Jeśli brakuje wymaganego pola
                (transaction_date).
        """
        ctx: dict[str, str] = {}

        # ── category_code ──────────────────────────────────────────
        raw_cat = invoice_data.get("category_code") or invoice_data.get("category")
        ctx["category_code"] = str(raw_cat).upper() if raw_cat else "UNKNOWN"

        # ── transaction_date (wymagane) ────────────────────────────
        raw_date = (
            invoice_data.get("transaction_date")
            or invoice_data.get("invoice_date")
            or invoice_data.get("date")
        )
        if raw_date is None:
            raise ContextInterpreterError(
                "Missing required field: transaction_date"
            )
        if isinstance(raw_date, date):
            ctx["transaction_date"] = raw_date.isoformat()
        else:
            ctx["transaction_date"] = str(raw_date)

        # ── vendor_country ─────────────────────────────────────────
        vendor = invoice_data.get("vendor", {})
        raw_country = (
            invoice_data.get("vendor_country")
            or (vendor.get("country") if isinstance(vendor, dict) else None)
        )
        if raw_country:
            normalized = COUNTRY_NORMALIZATION.get(str(raw_country).lower().strip())
            ctx["vendor_country"] = normalized or str(raw_country).upper()
        else:
            ctx["vendor_country"] = "PL"

        # ── company_tax_form ───────────────────────────────────────
        ctx["company_tax_form"] = str(
            invoice_data.get("company_tax_form", "CIT_STANDARD")
        )

        # ── vendor_nip ─────────────────────────────────────────────
        raw_nip = (
            invoice_data.get("vendor_nip")
            or (vendor.get("nip") if isinstance(vendor, dict) else None)
            or invoice_data.get("contractor_nip")
        )
        if raw_nip:
            # Oczyść NIP: tylko cyfry
            clean_nip = "".join(c for c in str(raw_nip) if c.isdigit())
            ctx["vendor_nip"] = clean_nip
        else:
            ctx["vendor_nip"] = ""

        # ── amount_net ─────────────────────────────────────────────
        raw_net = (
            invoice_data.get("amount_net")
            or invoice_data.get("total_net")
            or Decimal("0")
        )
        if isinstance(raw_net, Decimal):
            net_decimal = raw_net
        elif isinstance(raw_net, (int, float)):
            net_decimal = Decimal(str(raw_net))
        elif isinstance(raw_net, str):
            try:
                net_decimal = Decimal(raw_net)
            except Exception:
                net_decimal = Decimal("0")
        else:
            net_decimal = Decimal("0")

        ctx["amount_net"] = str(net_decimal)

        # ── amount_net_grosze ──────────────────────────────────────
        grossze = int(
            (net_decimal * Decimal("100")).to_integral_value(rounding=ROUND_HALF_UP)
        )
        ctx["amount_net_grosze"] = str(grossze)

        # ── vendor_vat_status ──────────────────────────────────────
        ctx["vendor_vat_status"] = str(
            invoice_data.get("vendor_vat_status", "unknown")
        )

        # ── vendor_pkd ─────────────────────────────────────────────
        ctx["vendor_pkd"] = str(
            invoice_data.get("vendor_pkd", "")
            or (vendor.get("pkd") if isinstance(vendor, dict) else "")
        )

        # ── vendor_account_on_whitelist ────────────────────────────
        raw_wl = invoice_data.get("vendor_account_on_whitelist")
        if raw_wl is not None:
            ctx["vendor_account_on_whitelist"] = "true" if raw_wl else "false"
        else:
            ctx["vendor_account_on_whitelist"] = "unknown"

        # ── expense_type ───────────────────────────────────────────
        ctx["expense_type"] = str(
            invoice_data.get("expense_type", invoice_data.get("expense_category", ""))
        )

        # ── confidence_vat_rate ────────────────────────────────────
        raw_conf = invoice_data.get("confidence_vat_rate")
        if raw_conf is not None:
            ctx["confidence_vat_rate"] = str(float(raw_conf))
        else:
            ctx["confidence_vat_rate"] = ""

        # ── ALLOWED_KEYS guard ────────────────────────────────────
        # Zwróć tylko dozwolone klucze (na wszelki wypadek)
        return {k: v for k, v in ctx.items() if k in ALLOWED_KEYS}

    @staticmethod
    def validate(context: dict[str, str]) -> list[str]:
        """Waliduj kontekst — sprawdź czy wszystkie wymagane pola są obecne.

        Args:
            context: Słownik kontekstu (z interpret()).

        Returns:
            Lista błędów (pusta = kontekst poprawny).
        """
        errors: list[str] = []
        for key in REQUIRED_KEYS:
            if key not in context or not context[key]:
                errors.append(f"Missing required context key: {key}")
        return errors

    @staticmethod
    def get_allowed_keys() -> list[str]:
        """Zwróć listę dozwolonych kluczy (dla panelu admin)."""
        return sorted(ALLOWED_KEYS)
