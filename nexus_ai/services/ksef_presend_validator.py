"""
v7.0 INNOWACJA 1: KSeF Pre-Send Validator + INNOWACJA 2: Cross-Source Vendor Verification.

KSeF Pre-Send Validator:
Przed wysłaniem faktury do KSeF, system automatycznie sprawdza:
- Czy wszystkie pola obowiązkowe są wypełnione
- Czy NIP kontrahenta istnieje w GUS BIR
- Czy rachunek bankowy jest na Białej Liście MF
- Czy stawka VAT jest prawidłowa dla kategorii
- Czy GTU jest poprawne dla rodzaju towaru/usługi

Cross-Source Vendor Verification (Trójkąt Weryfikacji):
Łączy dane z TRZECH niezależnych źródeł:
- GUS BIR: dane rejestrowe, PKD, status
- Biała Lista MF: status VAT, rachunki bankowe
- Vendor Intelligence (lokalny): historia płatności, zmienność cen

Poziomy zaufania:
- HIGH_TRUST: wszystkie 3 źródła zgodne
- MEDIUM_TRUST: jedno źródło niezgodne → alert
- LOW_TRUST: dwa źródła niezgodne → blokada transakcji
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

# v7.0 FIX: Importuj mapy kategorii z ksef_generator zamiast duplikować
from nexus_ai.services.ksef_generator import CATEGORY_GTU_MAP

logger = get_logger("nexus.services.ksef_validator")


# ── Trust levels ─────────────────────────────────────────────────────────────

@dataclass
class VendorTrustResult:
    """Wynik weryfikacji krzyżowej kontrahenta."""
    nip: str
    trust_level: str  # HIGH_TRUST, MEDIUM_TRUST, LOW_TRUST
    sources_checked: int
    sources_agreed: int
    gus_status: str = "unknown"
    whitelist_status: str = "unknown"
    vendor_score: float = 0.0  # 0-5
    alerts: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)


@dataclass
class PreSendResult:
    """Wynik walidacji przed wysyłką do KSeF."""
    is_valid: bool
    invoice_id: str
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    vendor_trust: VendorTrustResult | None = None
    mandatory_fields_ok: bool = False
    nip_valid: bool = False
    gtu_valid: bool = False
    vat_rate_valid: bool = False
    bank_account_verified: bool = False


# ── VAT rates per category ──────────────────────────────────────────────────

CATEGORY_VAT_RATES: dict[str, list[int]] = {
    "FOOD": [5, 8],
    "BOOKS": [5, 8],
    "HEALTHCARE": [0, 8],
    "EDUCATION": [0, 8],
    "CONSTRUCTION": [8, 23],
    "IT_OFFICE": [23],
    "ELECTRONICS": [23],
    "TRANSPORT": [8, 23],
    "RENT": [23],
    "ADVERTISING": [23],
    "FUEL": [23],
    "PHARMA": [8],
    "WASTE": [8, 23],
    "METAL": [23],
    "GAMBLING": [23],
}

# GTU codes per category — v7.0 FIX: derived from CATEGORY_GTU_MAP zamiast duplikacji
CATEGORY_GTU: dict[str, list[str]] = {}
for _cat, _data in CATEGORY_GTU_MAP.items():
    _gtu = _data.get("gtu_code")
    if _gtu:
        CATEGORY_GTU[_cat] = [_gtu]

MANDATORY_KSEF_FIELDS = [
    "invoice_number",
    "transaction_date",
    "amount_net_grosze",
    "amount_vat_grosze",
    "vendor.nip",
    "vendor.name",
    "buyer.nip",
    "buyer.name",
    "vat_rate",
]


class KsefPreSendValidator:
    """v7.0: KSeF Pre-Send Validator — walidacja przed wysyłką do KSeF."""

    def __init__(
        self,
        gus_client: Any = None,
        white_list: Any = None,
        vendor_analyst: Any = None,
    ) -> None:
        self._gus = gus_client
        self._white_list = white_list
        self._vendor = vendor_analyst

    async def validate(
        self,
        invoice_data: dict[str, Any],
    ) -> PreSendResult:
        """Pełna walidacja przed wysyłką do KSeF.

        Sprawdza:
        1. Pola obowiązkowe
        2. Walidacja NIP (format + GUS BIR)
        3. Walidacja GTU dla kategorii
        4. Walidacja stawki VAT
        5. Biała Lista MF (rachunek bankowy)
        6. Cross-Source Vendor Verification
        """
        inv_id = invoice_data.get("invoice_id", "unknown")
        errors: list[str] = []
        warnings: list[str] = []

        # 1. Pola obowiązkowe
        mandatory_ok = self._check_mandatory_fields(invoice_data, errors)

        # 2. NIP kontrahenta
        nip_ok = True
        buyer_nip = self._get_nested(invoice_data, "buyer.nip", "")
        if buyer_nip:
            nip_clean = "".join(c for c in buyer_nip if c.isdigit())
            if len(nip_clean) != 10:
                errors.append(f"NIP nabywcy '{buyer_nip}' ma nieprawidłową długość")
                nip_ok = False
        else:
            errors.append("Brak NIP-u nabywcy")
            nip_ok = False

        # 3. GTU dla kategorii
        gtu_ok = self._check_gtu(invoice_data, errors, warnings)

        # 4. Stawka VAT
        vat_ok = self._check_vat_rate(invoice_data, errors, warnings)

        # 5. Biała Lista MF
        bank_ok = await self._check_whitelist(invoice_data, errors, warnings)

        # 6. Cross-Source Vendor Verification
        vendor_trust = None
        if buyer_nip and self._gus:
            vendor_trust = await self._cross_source_verify(buyer_nip, invoice_data)

            if vendor_trust.trust_level == "LOW_TRUST":
                errors.append(
                    f"Kontrahent {buyer_nip} ma niski poziom zaufania "
                    f"({vendor_trust.sources_agreed}/{vendor_trust.sources_checked} źródeł zgodnych). "
                    "Transakcja zablokowana."
                )
            elif vendor_trust.trust_level == "MEDIUM_TRUST":
                warnings.append(
                    f"Kontrahent {buyer_nip} ma średni poziom zaufania — "
                    f"zalecana ręczna weryfikacja."
                )

        is_valid = len(errors) == 0
        result = PreSendResult(
            is_valid=is_valid,
            invoice_id=inv_id,
            errors=errors,
            warnings=warnings,
            vendor_trust=vendor_trust,
            mandatory_fields_ok=mandatory_ok,
            nip_valid=nip_ok,
            gtu_valid=gtu_ok,
            vat_rate_valid=vat_ok,
            bank_account_verified=bank_ok,
        )

        if not is_valid:
            logger.warning(
                "[PRESEND] Validation failed for %s: %d errors, %d warnings",
                inv_id, len(errors), len(warnings),
            )
        else:
            logger.info("[PRESEND] Validation passed for %s", inv_id)

        return result

    def _check_mandatory_fields(
        self, invoice_data: dict[str, Any], errors: list[str],
    ) -> bool:
        """Sprawdź pola obowiązkowe KSeF."""
        all_ok = True
        for field in MANDATORY_KSEF_FIELDS:
            value = self._get_nested(invoice_data, field, None)
            if value is None or value == "" or value == 0:
                errors.append(f"Brak pola obowiązkowego: {field}")
                all_ok = False
        return all_ok

    def _check_gtu(
        self, invoice_data: dict[str, Any],
        errors: list[str], warnings: list[str],
    ) -> bool:
        """Sprawdź poprawność GTU dla kategorii."""
        category = invoice_data.get("category_code", "")
        gtu_code = invoice_data.get("gtu_code", "")

        if not category or not gtu_code:
            return True  # Brak obowiązku GTU

        expected_gtus = CATEGORY_GTU.get(category, [])
        if expected_gtus and gtu_code not in expected_gtus:
            warnings.append(
                f"GTU '{gtu_code}' może być nieprawidłowe dla kategorii '{category}'. "
                f"Oczekiwane: {expected_gtus}"
            )
            return False
        return True

    def _check_vat_rate(
        self, invoice_data: dict[str, Any],
        errors: list[str], warnings: list[str],
    ) -> bool:
        """Sprawdź stawkę VAT dla kategorii."""
        category = invoice_data.get("category_code", "")
        vat_rate = invoice_data.get("vat_rate", 0)

        if not category:
            return True

        expected_rates = CATEGORY_VAT_RATES.get(category, [])
        if expected_rates and vat_rate not in expected_rates:
            warnings.append(
                f"Stawka VAT {vat_rate}% może być nieprawidłowa dla kategorii '{category}'. "
                f"Oczekiwane stawki: {expected_rates}"
            )
            return False
        return True

    async def _check_whitelist(
        self, invoice_data: dict[str, Any],
        errors: list[str], warnings: list[str],
    ) -> bool:
        """Sprawdź rachunek bankowy w Białej Liście MF."""
        if not self._white_list:
            return True  # Serwis niedostępny — nie blokuj

        buyer_nip = self._get_nested(invoice_data, "buyer.nip", "")
        bank_account = self._get_nested(invoice_data, "buyer.bank_account", "")

        if not buyer_nip or not bank_account:
            return True

        try:
            is_verified = await self._white_list.verify_bank_account(
                buyer_nip, bank_account,
            )
            if not is_verified:
                warnings.append(
                    f"Rachunek bankowy {bank_account[:6]}... nie znajduje się "
                    f"na Białej Liście MF. Ryzyko sankcji VAT."
                )
                return False
            return True
        except Exception as exc:
            logger.warning("[PRESEND] WhiteList check failed: %s", exc)
            return True  # Nie blokuj przy błędzie API

    async def _cross_source_verify(
        self, nip: str, invoice_data: dict[str, Any],
    ) -> VendorTrustResult:
        """v7.0 INNOWACJA 2: Trójkąt Weryfikacji — cross-source vendor check."""
        sources_checked = 0
        sources_agreed = 0
        alerts: list[str] = []
        recommendations: list[str] = []

        # Źródło 1: GUS BIR
        gus_status = "unknown"
        if self._gus:
            try:
                gus_data = await self._gus.enrich_from_nip(nip)
                gus_status = gus_data.get("vat_status", "unknown")
                sources_checked += 1
                if gus_status == "active":
                    sources_agreed += 1
                else:
                    alerts.append(f"GUS BIR status: {gus_status} (risk={gus_data.get('risk_score', 0.5):.2f})")
            except Exception as exc:
                logger.warning("[CROSS] GUS check failed: %s", exc)

        # Źródło 2: Biała Lista MF
        whitelist_status = "unknown"
        if self._white_list:
            try:
                wl_data = await self._white_list.check_nip(nip)
                whitelist_status = "active" if wl_data else "not_found"
                sources_checked += 1
                if whitelist_status == "active":
                    sources_agreed += 1
                else:
                    alerts.append(f"Biała Lista MF: NIP nieaktywny")
                    recommendations.append("Zweryfikuj status VAT kontrahenta przed płatnością")
            except Exception as exc:
                logger.warning("[CROSS] WhiteList check failed: %s", exc)

        # Źródło 3: Vendor Intelligence (lokalny)
        vendor_score = 0.0
        if self._vendor:
            try:
                context = self._vendor.get_vendor_context(nip)
                # Wyciągnij reliability_score z kontekstu
                import re
                m = re.search(r"Reliability score: ([\\d.]+)", context)
                if m:
                    vendor_score = float(m.group(1))
                sources_checked += 1
                if vendor_score >= 3.0:
                    sources_agreed += 1
                else:
                    alerts.append(f"Vendor score niski: {vendor_score:.1f}/5 — {context}")
                    recommendations.append("Rozważ reduced payment terms dla tego kontrahenta")
            except Exception as exc:
                logger.warning("[CROSS] Vendor check failed: %s", exc)

        # Określ poziom zaufania
        if sources_checked >= 2:
            if sources_agreed >= sources_checked:
                trust_level = "HIGH_TRUST"
            elif sources_agreed >= sources_checked - 1:
                trust_level = "MEDIUM_TRUST"
            else:
                trust_level = "LOW_TRUST"
        else:
            trust_level = "MEDIUM_TRUST" if sources_agreed > 0 else "LOW_TRUST"

        return VendorTrustResult(
            nip=nip,
            trust_level=trust_level,
            sources_checked=sources_checked,
            sources_agreed=sources_agreed,
            gus_status=gus_status,
            whitelist_status=whitelist_status,
            vendor_score=vendor_score,
            alerts=alerts,
            recommendations=recommendations,
        )

    @staticmethod
    def _get_nested(data: dict[str, Any], path: str, default: Any = None) -> Any:
        """Pobierz zagnieżdżoną wartość po ścieżce 'a.b.c'."""
        keys = path.split(".")
        current = data
        for key in keys:
            if isinstance(current, dict):
                current = current.get(key, default)
            else:
                return default
        return current
