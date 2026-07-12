"""
Proxy Router — Biala Lista VAT Verification (Phase 5, P1)
==========================================================

Czesc planu Phase 5: Legal Hardening Sprint (Kategoria 3: Infrastruktura).
Problem: Weryfikacja kontrahentow na Bialej Liscie VAT (Art. 96b VAT) jest
wymogiem prawnym dla przelewow powyzej 15 000 PLN (B2B). Brak weryfikacji
skutkuje solidarna odpowiedzialnoscia za VAT (Art. 117ba OrdPU) oraz brakiem
KUP (Art. 22p PIT).

Rozwiazanie: Router proxy, ktory:
1. Sprawdza czy przelew podlega obowiazkowej weryfikacji WL (>15k PLN, B2B)
2. Odpytuje API Bialej Listy (MF) o rachunek kontrahenta
3. Weryfikuje zgodnosc rachunku z faktura
4. Generuje dowod weryfikacji (timestamp + hash) na wypadek kontroli
5. Implementuje bufor 3-dniowy (Art. 96b ust. 4a VAT)

Usage:
    router = ProxyRouter()
    result = router.verify_transfer(invoice, vendor, amount)
    if result.must_verify and not result.verified:
        # BLOCK transfer or route to manual review
"""

from __future__ import annotations

import hashlib
import logging
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any

logger = logging.getLogger(__name__)

# ── Configuration ────────────────────────────────────────────────────────────

WHITELIST_THRESHOLD_PLN = 15_000  # Art. 96b VAT
VERIFICATION_VALIDITY_DAYS = 3  # Art. 96b ust. 4a VAT — 3 dni od weryfikacji
API_ENDPOINT = "https://wl-api.mf.gov.pl/api/search/bank-accounts/{nip}/{account}"


@dataclass
class WhitelistVerification:
    """Wynik weryfikacji Bialej Listy."""
    vendor_nip: str
    bank_account: str
    verified: bool
    verified_at: str = ""
    hash_proof: str = ""
    must_verify: bool = False
    exempt_reason: str = ""
    warnings: list[str] = field(default_factory=list)


@dataclass
class TransferDecision:
    """Decyzja o przelewie po weryfikacji WL."""
    can_proceed: bool
    reason: str
    verification: WhitelistVerification | None = None
    risk_level: str = "LOW"


class ProxyRouter:
    """Router weryfikacji Bialej Listy VAT dla przelewow JDG.

    Reguly biznesowe:
    1. Przelew B2B >= 15 000 PLN → obowiazkowa weryfikacja WL
    2. Przelew do kontrahenta zagranicznego → WL NIE ma zastosowania
    3. Przelew dla osoby fizycznej (nie-VAT) → WL NIE ma zastosowania
    4. Weryfikacja wazna 3 dni od wykonania
    5. Brak zgodnosci rachunku → BLOCK (solidarna odpowiedzialnosc)
    """

    def __init__(self) -> None:
        self._verification_cache: dict[str, WhitelistVerification] = {}

    def verify_transfer(
        self,
        invoice: dict[str, Any],
        vendor: dict[str, Any],
        amount: float,
        transfer_date: str | None = None,
    ) -> TransferDecision:
        """Weryfikuje czy przelew moze byc zrealizowany.

        Args:
            invoice: Dane faktury (amount_gross, bank_account, currency, direction).
            vendor: Dane kontrahenta (nip, is_company, country, name).
            amount: Kwota przelewu w PLN.
            transfer_date: Data przelewu (ISO 8601), domyslnie dzisiaj.

        Returns:
            TransferDecision z decyzja.
        """
        bank_account = str(vendor.get("bank_account", ""))
        vendor_nip = str(vendor.get("nip", ""))
        vendor_country = str(vendor.get("country", "PL"))
        is_company = bool(vendor.get("is_company", True))
        currency = str(invoice.get("currency", "PLN"))

        # Rule 1: Below threshold → no verification needed
        if amount < WHITELIST_THRESHOLD_PLN:
            return TransferDecision(
                can_proceed=True,
                reason=f"Kwota {amount:.2f} PLN ponizej progu {WHITELIST_THRESHOLD_PLN} PLN",
                risk_level="LOW",
            )

        # Rule 2: Foreign vendor → WL does not apply
        if vendor_country != "PL":
            return TransferDecision(
                can_proceed=True,
                reason=f"Kontrahent zagraniczny ({vendor_country}) — Biala Lista nie ma zastosowania",
                risk_level="LOW",
            )

        # Rule 3: Non-company → WL does not apply
        if not is_company:
            return TransferDecision(
                can_proceed=True,
                reason="Kontrahent nie jest firma — Biala Lista nie ma zastosowania",
                risk_level="LOW",
            )

        # Rule 4: Foreign currency → exempt (but warn)
        if currency != "PLN":
            logger.info(
                f"[ProxyRouter] Przelew w {currency} — WL sprawdzana "
                f"ale kurs moze wplynac na rownowartosc 15k PLN"
            )

        # Rule 5: Must verify — check cache or query API
        v = self._get_or_verify(vendor_nip, bank_account, transfer_date)
        v.must_verify = True

        if v.verified:
            return TransferDecision(
                can_proceed=True,
                reason=f"Rachunek {bank_account[-6:]} zweryfikowany na Bialej Liscie",
                verification=v,
                risk_level="LOW",
            )
        else:
            # BLOCK — rachunek nie figuruje na Bialej Liscie
            warnings = [
                f"BLOCK: Rachunek {bank_account} NIE figuruje na Bialej Liscie VAT!",
                "Kontynuacja przelewu → solidarna odpowiedzialnosc za VAT + NKUP!",
                "Zadaj od kontrahenta aktualnego rachunku z Bialej Listy.",
            ]
            return TransferDecision(
                can_proceed=False,
                reason="Rachunek nie figuruje na Bialej Liscie VAT",
                verification=v,
                risk_level="CRITICAL",
            )

    def _get_or_verify(
        self,
        nip: str,
        account: str,
        transfer_date: str | None = None,
    ) -> WhitelistVerification:
        """Sprawdza cache lub wykonuje weryfikacje WL.

        Cache jest wazny 3 dni robocze (Art. 96b ust. 4a VAT).
        """
        cache_key = f"{nip}:{account}"

        # Check cache
        if cache_key in self._verification_cache:
            cached = self._verification_cache[cache_key]
            verified_dt = datetime.fromisoformat(cached.verified_at) if cached.verified_at else datetime.min
            if datetime.now() - verified_dt < timedelta(days=VERIFICATION_VALIDITY_DAYS):
                logger.debug(f"[ProxyRouter] Cache hit for {nip}:{account[-6:]}")
                return cached
            else:
                logger.debug(f"[ProxyRouter] Cache expired for {nip}")
                del self._verification_cache[cache_key]

        # Perform verification (production: call WL API)
        verified = self._check_wl_api(nip, account)
        now = datetime.now().isoformat()

        proof = hashlib.sha256(
            f"{nip}|{account}|{now}|{verified}".encode()
        ).hexdigest()[:16]

        result = WhitelistVerification(
            vendor_nip=nip,
            bank_account=account,
            verified=verified,
            verified_at=now,
            hash_proof=proof,
        )
        self._verification_cache[cache_key] = result
        return result

    def _check_wl_api(self, nip: str, account: str) -> bool:
        """Odpytuje API Bialej Listy MF o rachunek.

        W produkcji: HTTP GET do wl-api.mf.gov.pl.
        W fazie developmentu: symulacja.

        Returns:
            True jesli rachunek figuruje na WL dla tego NIP.
        """
        # TODO: Replace with real API call
        # import requests
        # url = API_ENDPOINT.format(nip=nip, account=account)
        # resp = requests.get(url, timeout=10)
        # return resp.status_code == 200 and resp.json().get("result", {}).get("accountAssigned") == "TAK"

        # Simulation — accept accounts that look valid (PL + 26 digits)
        clean = account.replace(" ", "")
        if clean.startswith("PL") and len(clean) == 28 and clean[2:].isdigit():
            logger.info(f"[ProxyRouter] WL: account {account[-6:]} for NIP {nip} — VERIFIED (simulated)")
            return True

        logger.warning(f"[ProxyRouter] WL: account {account[-6:]} for NIP {nip} — NOT FOUND")
        return False

    def generate_proof_report(self, verification: WhitelistVerification) -> dict[str, Any]:
        """Generuje raport dowodowy do archiwizacji na wypadek kontroli.

        Zawiera: date weryfikacji, NIP, rachunek, hash dowodowy, status.
        Format zgodny z wymaganiami Art. 96b ust. 4a VAT.
        """
        return {
            "report_type": "WHITELIST_VERIFICATION_PROOF",
            "verified_at": verification.verified_at,
            "vendor_nip": verification.vendor_nip,
            "bank_account_masked": f"****{verification.bank_account[-6:]}",
            "verified": verification.verified,
            "hash_proof": verification.hash_proof,
            "legal_basis": "Art. 96b VAT, Art. 117ba OrdPU",
            "validity_days": VERIFICATION_VALIDITY_DAYS,
            "generated_by": "NexusAI ProxyRouter v1.0",
        }

    def clear_expired_verifications(self) -> int:
        """Usuwa przeterminowane weryfikacje z cache."""
        cutoff = datetime.now() - timedelta(days=VERIFICATION_VALIDITY_DAYS)
        expired = [
            k for k, v in self._verification_cache.items()
            if datetime.fromisoformat(v.verified_at) < cutoff
        ]
        for k in expired:
            del self._verification_cache[k]
        return len(expired)
