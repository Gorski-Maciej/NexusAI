"""
v7.0 VAT/MPP ORKIESTRATOR — OPA-MPP Bridge (QF-5).

Bridge między MPPAnnex15Engine (Python) a regułami OPA.
Przed ewaluacją OPA, sprawdza kody CN faktury przez
MPPAnnex15Engine i wstrzykuje wyniki jako input.invoice.mpp_annex15_items
do kontekstu OPA.

Raport v7.0 LUKA 5: MPP Engine odizolowany od OPA.
Ten bridge zamyka tę lukę.

3-warstwowa auto-detekcja MPP:
1. PRIMARY: Kod CN na fakturze → mapa Załącznika 15
2. SECONDARY: Analiza semantyczna opisu towaru
3. TERTIARY: Historyczna analiza kontrahenta
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.opa_mpp_bridge")


@dataclass
class OPAMPPContext:
    """Kontekst MPP do wstrzyknięcia do OPA."""

    mpp_items_matched: list[dict[str, Any]] = field(default_factory=list)
    mpp_mandatory: bool = False
    mpp_detection_method: str = ""  # cn_code, semantic, counterparty_history
    mpp_communication_required: bool = False
    mpp_sanction_warning: str = ""
    mpp_recommendations: list[str] = field(default_factory=list)
    solidarity_liability_risk: bool = False
    solidarity_warning: str = ""

    def to_opa_input(self) -> dict[str, Any]:
        """Konwertuj na format input.invoice.mpp_* dla OPA."""
        return {
            "mpp_annex15_items": [
                {
                    "position": item.get("position", 0),
                    "cn_codes": item.get("cn_codes", []),
                    "description": item.get("description", ""),
                    "category": item.get("category", ""),
                }
                for item in self.mpp_items_matched
            ],
            "mpp_annex15_match": len(self.mpp_items_matched) > 0,
            "mpp_annex15_count": len(self.mpp_items_matched),
            "mpp_detection_method": self.mpp_detection_method,
            "mpp_mandatory_detected": self.mpp_mandatory,
            "mpp_communication_required": self.mpp_communication_required,
            "mpp_sanction_warning": self.mpp_sanction_warning,
            "mpp_recommendations": self.mpp_recommendations,
            "solidarity_liability_risk": self.solidarity_liability_risk,
            "solidarity_warning": self.solidarity_warning,
        }


class OPAMPPBridge:
    """v7.0: Bridge MPPAnnex15Engine → OPA.

    Używany przed ewaluacją OPA do wstrzyknięcia wyników
    analizy MPP (Załącznik 15) do kontekstu OPA.

    Usage:
        bridge = OPAMPPBridge(mpp_engine)
        ctx = bridge.evaluate(invoice_data, cn_code, amount_gross, description)
        opa_input["invoice"].update(ctx.to_opa_input())
    """

    def __init__(self, mpp_engine: Any = None) -> None:
        """Inicjalizacja bridge'a.

        Args:
            mpp_engine: Instancja MPPAnnex15Engine (opcjonalnie).
        """
        self._engine = mpp_engine
        self._counterparty_history: dict[str, list[dict[str, Any]]] = {}

    def evaluate(
        self,
        invoice_data: dict[str, Any],
        cn_code: str = "",
        amount_gross: float = 0.0,
        is_split_payment_used: bool = False,
        description: str = "",
        contractor_nip: str = "",
    ) -> OPAMPPContext:
        """Wykonaj pre-OPA MPP evaluation.

        Sprawdza 3-warstwowo czy faktura podlega MPP:
        1. CN code matching
        2. Semantic description matching
        3. Counterparty history analysis

        Args:
            invoice_data: Pełne dane faktury.
            cn_code: Kod CN z faktury (np. "8471").
            amount_gross: Kwota brutto w PLN.
            is_split_payment_used: Czy użyto komunikatu MPP.
            description: Opis towaru/usługi.
            contractor_nip: NIP kontrahenta.

        Returns:
            OPAMPPContext gotowy do wstrzyknięcia do OPA.
        """
        ctx = OPAMPPContext()

        # Jeśli engine dostępny, użyj go
        if self._engine is not None:
            try:
                decision = self._engine.evaluate_mpp(
                    invoice_data=invoice_data,
                    cn_code=cn_code,
                    amount_gross=amount_gross,
                    is_split_payment_used=is_split_payment_used,
                    description=description,
                )
                ctx.mpp_items_matched = [
                    {
                        "position": item.position,
                        "cn_codes": item.cn_codes,
                        "description": item.description,
                        "category": item.category,
                    }
                    for item in decision.matched_items
                ]
                ctx.mpp_detection_method = decision.detection_method
                ctx.mpp_mandatory = decision.is_mpp_mandatory
                ctx.mpp_communication_required = decision.mpp_communication_required
                ctx.mpp_sanction_warning = decision.sanction_warning
                ctx.mpp_recommendations = decision.recommendations

                # Solidarity liability
                liability = self._engine.get_solidarity_liability_warning(invoice_data)
                if liability:
                    ctx.solidarity_liability_risk = True
                    ctx.solidarity_warning = liability
            except Exception as exc:
                logger.warning("[OPA-MPP] Engine evaluation failed: %s", exc)

        # Fallback: proste sprawdzenie bez engine
        if not ctx.mpp_items_matched and cn_code:
            ctx = self._fallback_check(
                cn_code, amount_gross, description, is_split_payment_used,
                ctx,
            )

        # TERTIARY: Counterparty history
        if not ctx.mpp_items_matched and contractor_nip:
            history = self._counterparty_history.get(contractor_nip, [])
            if history:
                mpp_ratio = sum(
                    1 for tx in history if tx.get("mpp_used")
                ) / max(len(history), 1)
                if mpp_ratio > 0.5 and amount_gross > 15000:
                    ctx.mpp_mandatory = True
                    ctx.mpp_detection_method = "counterparty_history"
                    ctx.mpp_recommendations.append(
                        f"MPP wymagany — {mpp_ratio:.0%} transakcji z {contractor_nip} używa MPP"
                    )

        logger.info(
            "[OPA-MPP] mandatory=%s items=%d method=%s",
            ctx.mpp_mandatory,
            len(ctx.mpp_items_matched),
            ctx.mpp_detection_method,
        )

        return ctx

    def _fallback_check(
        self,
        cn_code: str,
        amount_gross: float,
        description: str,
        is_split_payment_used: bool,
        ctx: OPAMPPContext,
    ) -> OPAMPPContext:
        """Fallback — proste sprawdzenie CN bez engine."""
        # Uproszczona mapa CN → kategoria (najczęstsze)
        cn_prefix_map = {
            "2701": ("Węgiel kamienny", "COAL"),
            "2702": ("Węgiel brunatny", "COAL"),
            "2704": ("Koks", "COAL"),
            "2710": ("Paliwa", "FUEL"),
            "2711": ("Gaz LPG/CNG", "FUEL"),
            "7207": ("Półprodukty stalowe", "STEEL"),
            "7208": ("Stal walcowana", "STEEL"),
            "7214": ("Pręty stalowe", "STEEL"),
            "7402": ("Miedź", "COPPER"),
            "7601": ("Aluminium", "ALUMINIUM"),
            "8471": ("Komputery/serwery", "ELECTRONICS"),
            "8517": ("Telefony/smartfony", "ELECTRONICS"),
            "8708": ("Części samochodowe", "AUTO_PARTS"),
            "3915": ("Odpady plastikowe", "WASTE"),
            "4707": ("Makulatura", "WASTE"),
            "7204": ("Złom stalowy", "SCRAP"),
            "1701": ("Cukier", "FOOD"),
            "1001": ("Zboża", "GRAIN"),
            "6101": ("Odzież", "TEXTILES"),
            "6401": ("Obuwie", "TEXTILES"),
        }

        matched = False
        for prefix, (desc, cat) in cn_prefix_map.items():
            if cn_code.startswith(prefix):
                ctx.mpp_items_matched.append({
                    "position": 0,
                    "cn_codes": [prefix],
                    "description": desc,
                    "category": cat,
                })
                matched = True
                ctx.mpp_detection_method = "cn_code_fallback"
                break

        if matched and amount_gross > 15000:
            ctx.mpp_mandatory = True
            if not is_split_payment_used:
                # Correct VAT calculation: extract VAT from gross (net = gross / 1.23, VAT = gross - net)
                amount_net = amount_gross / 1.23 if amount_gross > 0 else 0
                vat_amount = amount_gross - amount_net
                sanction = vat_amount * 0.30
                ctx.mpp_sanction_warning = (
                    f"UWAGA: CN {cn_code[:4]} z Załącznika 15! "
                    f"Kwota {amount_gross:.2f} PLN > 15 000 PLN. "
                    f"Sankcja 30% VAT: {sanction:.2f} PLN."
                )

        return ctx

    def add_contractor_history(
        self, nip: str, transactions: list[dict[str, Any]],
    ) -> None:
        """Dodaj historię transakcji kontrahenta do analizy."""
        self._counterparty_history[nip] = transactions

    def generate_mpp_communication(
        self, net_amount: float, vat_amount: float,
        seller_vat_account: str = "",
    ) -> dict[str, str]:
        """Wygeneruj komunikat przelewu MPP."""
        if self._engine:
            return self._engine.generate_mpp_communication(
                net_amount, vat_amount, seller_vat_account,
            )
        return {
            "title": f"MPP {net_amount + vat_amount:.2f} PLN",
            "split_payment": "true",
            "net_amount": f"{net_amount:.2f}",
            "vat_amount": f"{vat_amount:.2f}",
            "gross_amount": f"{net_amount + vat_amount:.2f}",
            "communication": f"/VAT/{vat_amount:.2f}/SPLIT_PAYMENT",
        }
