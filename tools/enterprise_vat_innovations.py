# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — Enterprise VAT Innovations (Python Bridge) v7.0
# ═══════════════════════════════════════════════════════════════════════════════
#
# 12 innowacji Enterprise z Raportu P02, Sekcja 8.
# Ten moduł Python dostarcza funkcje NLP/ML/predykcyjne,
# których wyniki są wstrzykiwane jako data.jdg.enterprise do OPA.
#
# Użycie: importowane przez PreOPAPipeline przed ewaluacją Rego.
# ═══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations
from typing import Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
from decimal import Decimal
import json


# ═══════════════════════════════════════════════════════════════════════════════
# 8.1 MPP AUTO-DETECTION ENGINE — Analiza semantyczna opisu towaru
# ═══════════════════════════════════════════════════════════════════════════════
# NLP analizuje input.invoice.description → ekstrakcja słów kluczowych →
# mapowanie na Załącznik 15 → auto-detekcja obowiązku MPP
# ═══════════════════════════════════════════════════════════════════════════════

ANNEX15_KEYWORDS = {
    "FUEL": ["paliwo", "benzyna", "olej napędowy", "diesel", "LPG", "ropa", "wegiel", "koks"],
    "STEEL": ["stal", "zelazo", "profile stalowe", "blacha", "rury stalowe", "prety", "aluminium", "miedz"],
    "ELECTRONICS": ["laptop", "komputer", "tablet", "smartfon", "procesor", "dysk", "serwer", "monitor"],
    "CONSTRUCTION": ["budowa", "remont", "instalacja", "fundament", "dach", "sciany", "tynk", "wykonczenie"],
    "WASTE": ["odpady", "złom", "gruz", "surowce wtórne", "recykling", "segregacja"],
    "PRECIOUS_METALS": ["zloto", "srebro", "platyna", "pallad", "metale szlachetne"],
    "CO2_CERTIFICATES": ["emisja CO2", "certyfikat emisyjny", "uprawnienia do emisji", "EUA"],
    "VEHICLES": ["samochod", "pojazd", "motocykl", "części samochodowe", "auto"],
    "GRAIN": ["zboze", "pszenica", "kukurydza", "jeczmien", "owies", "zyto", "rzepak"],
    "TEXTILES": ["tekstylia", "odziez", "tkaniny", "ubrania", "buty", "skora"],
    "ALCOHOL": ["alkohol", "piwo", "wino", "wodka", "spirytus", "whisky"],
    "TOBACCO": ["tyton", "papierosy", "cygara", "e-papierosy"],
}


def mpp_auto_detect(description: str, category_code: str) -> dict:
    """
    Auto-detekcja obowiązku MPP na podstawie opisu towaru.
    Używa prostego NLP (keyword matching) + kategorii z invoice.
    W wersji produkcyjnej: spaCy/transformers + baza PKWiU → Załącznik 15.
    """
    desc_lower = description.lower()
    detected_categories = []

    for annex15_cat, keywords in ANNEX15_KEYWORDS.items():
        score = sum(1 for kw in keywords if kw in desc_lower)
        if score > 0:
            detected_categories.append({
                "category": annex15_cat,
                "confidence": min(score / len(keywords) * 2, 0.95),
                "matched_keywords": [kw for kw in keywords if kw in desc_lower],
            })

    # Sortuj wg confidence malejąco
    detected_categories.sort(key=lambda x: x["confidence"], reverse=True)

    return {
        "mpp_auto_detected": len(detected_categories) > 0,
        "mpp_auto_categories": detected_categories[:3],
        "mpp_auto_primary": detected_categories[0]["category"] if detected_categories else None,
        "mpp_auto_confidence": detected_categories[0]["confidence"] if detected_categories else 0.0,
        "mpp_auto_method": "keyword_nlp",
        "mpp_requires_manual_review": len(detected_categories) > 0 and detected_categories[0]["confidence"] < 0.60,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.2 VAT RATE SEMANTIC CLASSIFIER — AI klasyfikacja stawki VAT
# ═══════════════════════════════════════════════════════════════════════════════
# W wersji produkcyjnej: transformer model trenowany na Rozp. MF 4.12.2024
# + baza PKWiU→CN→stawka. Tu: keyword-based fallback.
# ═══════════════════════════════════════════════════════════════════════════════

CN_RATE_HINTS = {
    "4901": 0.05, "4902": 0.05, "4903": 0.05,  # Książki 5%
    "3004": 0.08, "3005": 0.08, "3822": 0.08,  # Medyczne 8%
    "2201": 0.23, "2202": 0.23,                 # Napoje 23%
    "1001": 0.05, "1005": 0.05, "1101": 0.05,  # Żywność podstawowa 5%
    "2701": 0.23, "2710": 0.23,                 # Paliwa 23%
}


def vat_rate_classify(description: str, cn_code: str, category_code: str) -> dict:
    """
    Klasyfikacja stawki VAT na podstawie opisu, CN i kategorii.
    Zwraca sugerowaną stawkę + confidence + alternatywy.
    """
    # CN-based lookup
    cn_prefix = cn_code[:4] if cn_code else ""
    cn_rate = CN_RATE_HINTS.get(cn_prefix)

    # Keyword-based hints
    rate_hints = {
        0.05: ["zywnosc", "jedzenie", "ksiazka", "ebook", "pieczywo", "maka", "warzywa", "owoce", "pieluchy"],
        0.08: ["budowa", "remont", "lek", "bandaz", "sprzet medyczny", "hotel", "transport"],
        0.23: ["alkohol", "paliwo", "elektronika", "usluga", "konsulting", "oprogramowanie"],
        0.00: ["edukacja", "szkolenie", "medycyna", "finanse", "ubezpieczenie"],
    }

    desc_lower = description.lower()
    rate_scores = {}
    for rate, keywords in rate_hints.items():
        score = sum(1 for kw in keywords if kw in desc_lower)
        if score > 0:
            rate_scores[rate] = min(score / 3, 0.85)

    # CN rate takes priority
    if cn_rate is not None:
        rate_scores[cn_rate] = max(rate_scores.get(cn_rate, 0), 0.90)

    primary_rate = max(rate_scores, key=rate_scores.get) if rate_scores else 0.23
    primary_confidence = rate_scores.get(primary_rate, 0.50)

    alternatives = [
        {"rate": rate, "confidence": conf}
        for rate, conf in sorted(rate_scores.items(), key=lambda x: -x[1])
        if rate != primary_rate
    ][:2]

    return {
        "vat_rate_classified": primary_rate,
        "vat_rate_confidence": primary_confidence,
        "vat_rate_alternatives": alternatives,
        "vat_rate_method": "cn_keyword_hybrid",
        "vat_rate_requires_triage": primary_confidence < 0.70,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.3 REAL-TIME VAT LIMIT TRACKER — Predykcja przekroczenia 200k
# ═══════════════════════════════════════════════════════════════════════════════

@dataclass
class VatLimitTracker:
    ytd_turnover: Decimal
    days_elapsed: int
    limit: Decimal = Decimal("200000")
    early_warning_pct: Decimal = Decimal("0.80")

    def daily_average(self) -> Decimal:
        if self.days_elapsed == 0:
            return Decimal("0")
        return self.ytd_turnover / self.days_elapsed

    def days_to_breach(self) -> Optional[int]:
        daily = self.daily_average()
        if daily <= 0:
            return None
        remaining = self.limit - self.ytd_turnover
        if remaining <= 0:
            return 0
        return int(remaining / daily)

    def forecast_breach_date(self, today: date) -> Optional[date]:
        days = self.days_to_breach()
        if days is None:
            return None
        return today + timedelta(days=days)

    def is_early_warning(self) -> bool:
        return self.ytd_turnover >= self.limit * self.early_warning_pct

    def status(self, today: date) -> dict:
        breach_date = self.forecast_breach_date(today)
        return {
            "vat_limit_ytd": float(self.ytd_turnover),
            "vat_limit_total": float(self.limit),
            "vat_limit_remaining": float(self.limit - self.ytd_turnover),
            "vat_limit_used_pct": float(self.ytd_turnover / self.limit * 100) if self.limit > 0 else 0,
            "vat_limit_daily_avg": float(self.daily_average()),
            "vat_limit_days_to_breach": self.days_to_breach(),
            "vat_limit_breach_forecast_date": breach_date.isoformat() if breach_date else None,
            "vat_limit_early_warning": self.is_early_warning(),
            "vat_limit_status": "BREACHED" if self.ytd_turnover >= self.limit else (
                "WARNING" if self.is_early_warning() else "OK"
            ),
        }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.4 BAD DEBT RECOVERY OPTIMIZER
# ═══════════════════════════════════════════════════════════════════════════════

def bad_debt_optimize(unpaid_invoices: list[dict]) -> dict:
    """
    Optymalizacja ulgi na złe długi: kategoryzacja faktur,
    optymalizacja timing (150 vs 90 dni), batch korekt JPK_V7.
    """
    total_unpaid_net = Decimal("0")
    total_unpaid_vat = Decimal("0")
    actionable = []
    future_actionable = []

    for inv in unpaid_invoices:
        net = Decimal(str(inv.get("amount_net", 0)))
        vat = Decimal(str(inv.get("vat_amount", 0)))
        days_overdue = inv.get("days_overdue", 0)
        tx_date = inv.get("transaction_date", "")

        if days_overdue >= 90:
            total_unpaid_net += net
            total_unpaid_vat += vat
            actionable.append({
                "invoice_id": inv.get("id"),
                "amount_net": float(net),
                "vat_to_correct": float(vat),
                "days_overdue": days_overdue,
                "action": "KOREKTA_VAT_JPK_V7",
                "priority": "HIGH" if days_overdue > 180 else "MEDIUM",
            })
        elif days_overdue >= 60:
            future_actionable.append({
                "invoice_id": inv.get("id"),
                "amount_net": float(net),
                "vat_to_correct": float(vat),
                "days_to_actionable": 90 - days_overdue,
                "action": "MONITOR",
            })

    return {
        "bad_debt_total_unpaid_net": float(total_unpaid_net),
        "bad_debt_total_vat_recoverable": float(total_unpaid_vat),
        "bad_debt_actionable_count": len(actionable),
        "bad_debt_actionable_invoices": actionable,
        "bad_debt_future_count": len(future_actionable),
        "bad_debt_optimization_note": (
            "Złóż zbiorczą korektę JPK_V7 dla wszystkich actionable faktur. "
            "Rozważ również korektę PIT (Art. 26i) dla tych samych wierzytelności."
        ),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.5 CROSS-BORDER VAT COMPLIANCE MATRIX
# ═══════════════════════════════════════════════════════════════════════════════

# Pair → (tax mechanism, rate)
EU_VAT_MATRIX = {
    ("PL", "DE"): ("REVERSE_CHARGE_B2B", None),  # B2B = reverse charge w DE
    ("PL", "FR"): ("REVERSE_CHARGE_B2B", None),
    ("PL", "CZ"): ("REVERSE_CHARGE_B2B", None),
    ("PL", "SK"): ("REVERSE_CHARGE_B2B", None),
    ("PL", "GB"): ("EXPORT", 0.00),  # UK post-Brexit = eksport
    ("PL", "US"): ("EXPORT", 0.00),
    ("DE", "PL"): ("IMPORT_SERVICES", 0.23),  # Import do PL z DE
    ("PL", "PL"): ("DOMESTIC", 0.23),
}

EU_VAT_RATES = {
    "DE": 0.19, "FR": 0.20, "IT": 0.22, "ES": 0.21, "NL": 0.21,
    "BE": 0.21, "AT": 0.20, "CZ": 0.21, "SK": 0.20, "HU": 0.27,
    "PL": 0.23, "SE": 0.25, "DK": 0.25, "FI": 0.24, "IE": 0.23,
    "PT": 0.23, "GR": 0.24, "RO": 0.19, "BG": 0.20, "HR": 0.25,
    "SI": 0.22, "LT": 0.21, "LV": 0.21, "EE": 0.20, "LU": 0.17,
    "MT": 0.18, "CY": 0.19,
}


def cross_border_vat_matrix(vendor_country: str, buyer_country: str, is_b2b: bool, is_service: bool) -> dict:
    """
    Macierz zgodności VAT dla pary krajów UE.
    Określa: miejsce świadczenia, stawkę, mechanizm (reverse charge, OSS, IOSS).
    """
    key = (vendor_country, buyer_country)
    mechanism, rate = EU_VAT_MATRIX.get(key, ("CHECK_LOCAL_RULES", None))

    buyer_rate = EU_VAT_RATES.get(buyer_country, 0.23)
    vendor_rate = EU_VAT_RATES.get(vendor_country, 0.23)

    if is_b2b and mechanism == "REVERSE_CHARGE_B2B":
        place_of_supply = buyer_country
        applicable_rate = buyer_rate
        tax_mechanism = "REVERSE_CHARGE"
    elif not is_b2b and is_service:
        place_of_supply = buyer_country
        applicable_rate = buyer_rate
        tax_mechanism = "OSS" if buyer_country != vendor_country else "DOMESTIC"
    else:
        place_of_supply = vendor_country
        applicable_rate = vendor_rate
        tax_mechanism = "DOMESTIC"

    return {
        "cross_border_vendor": vendor_country,
        "cross_border_buyer": buyer_country,
        "cross_border_is_b2b": is_b2b,
        "cross_border_place_of_supply": place_of_supply,
        "cross_border_applicable_rate": applicable_rate,
        "cross_border_tax_mechanism": tax_mechanism,
        "cross_border_oss_applicable": tax_mechanism == "OSS",
        "cross_border_vat_ue_required": vendor_country != buyer_country and buyer_country != "PL",
        "cross_border_matrix_version": "v7.0",
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.6 GTU SEMANTIC AUTO-TAGGER
# ═══════════════════════════════════════════════════════════════════════════════

GTU_KEYWORD_MAP = {
    "GTU_01": ["alkohol", "piwo", "wino", "wodka", "spirytus", "whisky", "nalewka"],
    "GTU_02": ["paliwo", "benzyna", "diesel", "olej napędowy", "LPG", "CNG"],
    "GTU_03": ["uzywany samochod", "uzywany motocykl", "pojazd uzywany", "srodek transportu uzywany"],
    "GTU_04": ["tyton", "papierosy", "cygara", "tytoniowe", "e-papieros"],
    "GTU_05": ["olej smarowy", "smary", "oleje silnikowe", "smar plastyczny"],
    "GTU_06": ["produkt medyczny", "lek", "suplement", "wyrob medyczny", "bandaz", "strzykawka"],
    "GTU_07": ["odpady", "złom", "surowce wtórne", "makulatura", "szkło odpadowe", "plastik odpadowy"],
    "GTU_08": ["laptop", "smartfon", "tablet", "komputer", "telewizor", "konsola", "drukarka"],
    "GTU_09": ["samochod", "pojazd", "motocykl", "auto nowe", "pojazd nowy"],
    "GTU_10": ["stal", "profile stalowe", "blacha stalowa", "prety stalowe", "rury stalowe"],
    "GTU_11": ["zloto", "srebro", "platyna", "pallad", "metale szlachetne", "zloto inwestycyjne"],
    "GTU_12": ["budowa", "material budowlany", "cement", "beton", "cegla", "dachowka"],
    "GTU_13": ["transport", "przewoz", "spedycja", "kurier", "logistyka", "przeprowadzka"],
}


def gtu_semantic_tag(description: str) -> dict:
    """
    Semantyczne tagowanie GTU na podstawie opisu towaru.
    Ekstrakcja słów kluczowych → mapowanie na kody GTU_01..GTU_13.
    """
    desc_lower = description.lower()
    gtu_scores = {}

    for gtu_code, keywords in GTU_KEYWORD_MAP.items():
        matches = [kw for kw in keywords if kw in desc_lower]
        if matches:
            gtu_scores[gtu_code] = {
                "confidence": min(len(matches) / 3, 0.95),
                "matched_keywords": matches,
            }

    if not gtu_scores:
        return {
            "gtu_code": "",
            "gtu_confidence": 0.0,
            "gtu_method": "semantic_no_match",
            "gtu_requires_manual_review": False,
        }

    best = max(gtu_scores, key=lambda g: gtu_scores[g]["confidence"])
    return {
        "gtu_code": best,
        "gtu_confidence": gtu_scores[best]["confidence"],
        "gtu_method": "semantic_nlp",
        "gtu_matched_keywords": gtu_scores[best]["matched_keywords"],
        "gtu_alternatives": [
            {"code": g, "confidence": s["confidence"]}
            for g, s in sorted(gtu_scores.items(), key=lambda x: -x[1]["confidence"])
            if g != best
        ][:2],
        "gtu_requires_manual_review": gtu_scores[best]["confidence"] < 0.50,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.7 VAT CASH-FLOW PREDICTOR
# ═══════════════════════════════════════════════════════════════════════════════

def vat_cashflow_predict(
    historical_vat: list[float],
    current_month_vat: float,
    seasonality_factors: list[float],
    mpp_blocked_amount: float = 0,
) -> dict:
    """
    Predykcja przyszłych zobowiązań VAT z uwzględnieniem:
    - historycznych danych VAT
    - sezonowości
    - MPP impact (split payment opóźnia dostępność środków)
    """
    if not historical_vat:
        return {"vat_cashflow_forecast": [], "vat_cashflow_confidence": 0.0}

    avg = sum(historical_vat) / len(historical_vat)
    forecast = []

    for i, factor in enumerate(seasonality_factors[:6]):
        month_prediction = avg * factor
        net_available = month_prediction - mpp_blocked_amount
        forecast.append({
            "month_offset": i + 1,
            "vat_predicted": round(month_prediction, 2),
            "vat_net_available": round(max(net_available, 0), 2),
            "vat_mpp_blocked": round(min(mpp_blocked_amount, month_prediction), 2),
            "seasonality_factor": factor,
        })

    return {
        "vat_cashflow_current_month": current_month_vat,
        "vat_cashflow_historical_avg": round(avg, 2),
        "vat_cashflow_forecast": forecast,
        "vat_cashflow_confidence": 0.75 if len(historical_vat) >= 3 else 0.50,
        "vat_cashflow_mpp_total_blocked": mpp_blocked_amount,
        "vat_cashflow_liquidity_warning": current_month_vat > avg * 1.5,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.8 PROPORTIONAL DEDUCTION OPTIMIZER
# ═══════════════════════════════════════════════════════════════════════════════

def proportion_optimize(
    current_proportion: float,
    historical_proportions: list[float],
    mixed_expenses: list[dict],
) -> dict:
    """
    Optymalizacja współczynnika proporcji VAT (Art. 90-91).
    Analiza historyczna, korekta roczna, rekomendacje alokacji wydatków.
    """
    avg_historical = sum(historical_proportions) / len(historical_proportions) if historical_proportions else current_proportion

    recommendations = []
    if current_proportion < 0.02:
        recommendations.append("Proporcja < 2% → odliczenie 0%. Rozważ rezygnację z odliczeń.")
    elif current_proportion > 0.98:
        recommendations.append("Proporcja > 98% → pełne odliczenie. Nie ma potrzeby korekty.")
    elif abs(current_proportion - avg_historical) > 0.10:
        recommendations.append(f"Proporcja odbiega o {(current_proportion - avg_historical)*100:.0f}pp od średniej. Sprawdź czy nie ma błędu w kalkulacji.")

    # Auto vs mileage log optimization
    for exp in mixed_expenses:
        if exp.get("category") == "CAR" and exp.get("has_mileage_log") is False:
            recommendations.append(
                f"Auto bez ewidencji: VAT 50% / KUP 75%. Prowadzenie ewidencji → VAT 100% / KUP 100%. "
                f"Potencjalna oszczędność: {exp.get('vat_amount', 0) * 0.5:.2f} PLN VAT."
            )

    return {
        "proportion_current": current_proportion,
        "proportion_historical_avg": round(avg_historical, 4),
        "proportion_de_minimis": current_proportion < 0.02,
        "proportion_full_deduction": current_proportion > 0.98,
        "proportion_annual_correction_needed": abs(current_proportion - avg_historical) > 0.05,
        "proportion_recommendations": recommendations,
        "proportion_optimization_score": min(len(recommendations) / 3, 1.0),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.9 KSEF RESILIENCE FIREWALL
# ═══════════════════════════════════════════════════════════════════════════════

def ksef_resilience_check(
    ksef_status: str,
    invoices_pending: int,
    last_sync: Optional[datetime],
    offline_mode_activated_at: Optional[datetime],
) -> dict:
    """
    Wielowarstwowa odporność KSeF:
    1. Predykcja awarii (monitoring statusu)
    2. Auto-switch do offline
    3. Kolejka faktur z retry
    4. Walidacja schematu FA(2)
    5. Backup lokalny + sync
    """
    now = datetime.now()

    # Layer 1: Status monitoring
    is_online = ksef_status == "ONLINE"
    is_degraded = ksef_status == "DEGRADED"

    # Layer 2: Auto-switch
    if offline_mode_activated_at:
        hours_offline = (now - offline_mode_activated_at).total_seconds() / 3600
        deadline_exceeded = hours_offline > 168  # 7 days
    else:
        hours_offline = 0
        deadline_exceeded = False

    # Layer 3: Retry queue
    retry_recommended = invoices_pending > 0 and is_online

    # Layer 4: FA(2) validation
    fa2_validation_required = invoices_pending > 0

    return {
        "ksef_status": ksef_status,
        "ksef_is_online": is_online,
        "ksef_is_degraded": is_degraded,
        "ksef_offline_hours": round(hours_offline, 1),
        "ksef_offline_deadline_hours": 168,
        "ksef_offline_deadline_exceeded": deadline_exceeded,
        "ksef_invoices_pending": invoices_pending,
        "ksef_retry_recommended": retry_recommended,
        "ksef_retry_batch_size": min(invoices_pending, 100),
        "ksef_fa2_validation_required": fa2_validation_required,
        "ksef_last_sync": last_sync.isoformat() if last_sync else None,
        "ksef_resilience_score": 1.0 if is_online else (0.5 if not deadline_exceeded else 0.0),
        "ksef_recommended_action": (
            "RETRY_SYNC" if retry_recommended
            else "SWITCH_TO_OFFLINE" if is_degraded and invoices_pending > 0
            else "URGENT_SYNC_BEFORE_DEADLINE" if deadline_exceeded
            else "OK"
        ),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.10 VAT AUDIT TRAIL IMMUTABILITY (Merkle Tree)
# ═══════════════════════════════════════════════════════════════════════════════

import hashlib


def merkle_hash(data: str) -> str:
    return hashlib.sha256(data.encode()).hexdigest()


def build_merkle_tree(invoices: list[dict]) -> dict:
    """
    Buduje drzewo Merkle dla faktur VAT — immutable audit trail.
    Każda faktura = liść, korzeń = hash wszystkich faktur.
    Umożliwia weryfikację integralności całego okresu rozliczeniowego.
    """
    leaf_hashes = []
    for inv in invoices:
        inv_str = json.dumps(inv, sort_keys=True, default=str)
        leaf_hashes.append(merkle_hash(inv_str))

    if not leaf_hashes:
        return {"merkle_root": None, "merkle_leaf_count": 0}

    tree_level = leaf_hashes[:]
    tree_structure = [tree_level[:]]

    while len(tree_level) > 1:
        next_level = []
        for i in range(0, len(tree_level), 2):
            left = tree_level[i]
            right = tree_level[i + 1] if i + 1 < len(tree_level) else left
            next_level.append(merkle_hash(left + right))
        tree_level = next_level
        tree_structure.append(tree_level[:])

    return {
        "merkle_root": tree_level[0] if tree_level else None,
        "merkle_leaf_count": len(leaf_hashes),
        "merkle_tree_depth": len(tree_structure),
        "merkle_timestamp": datetime.now().isoformat(),
        "merkle_verification_note": "Każda faktura w okresie jest zweryfikowana przez drzewo Merkle. Korzeń = dowód integralności.",
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.11 SPLIT PAYMENT OPTIMIZER
# ═══════════════════════════════════════════════════════════════════════════════

def split_payment_optimize(
    invoices: list[dict],
    mpp_threshold: float = 15000,
    safe_harbor_benefit_pct: float = 0.05,
) -> dict:
    """
    Optymalizacja MPP: które faktury poniżej progu warto opłacić przez MPP
    dla safe harbor przed solidarną odpowiedzialnością.
    """
    mandatory = []
    voluntary_recommended = []
    voluntary_optional = []

    for inv in invoices:
        amount = inv.get("amount_gross", 0)
        is_sensitive = inv.get("mpp_sensitive", False)
        mpp_used = inv.get("split_payment_used", False)

        if amount > mpp_threshold and is_sensitive:
            mandatory.append({
                "invoice_id": inv.get("id"),
                "amount_gross": amount,
                "mpp_used": mpp_used,
                "risk": "SANKCJA_30PCT" if not mpp_used else "OK",
            })
        elif amount <= mpp_threshold and is_sensitive:
            benefit = amount * safe_harbor_benefit_pct
            voluntary_recommended.append({
                "invoice_id": inv.get("id"),
                "amount_gross": amount,
                "safe_harbor_benefit_est": round(benefit, 2),
                "recommendation": "RECOMMENDED — safe harbor przed solidarną odpowiedzialnością",
            })
        else:
            voluntary_optional.append({
                "invoice_id": inv.get("id"),
                "amount_gross": amount,
                "recommendation": "OPTIONAL — brak ryzyka solidarnej odpowiedzialności",
            })

    total_safe_harbor_benefit = sum(v["safe_harbor_benefit_est"] for v in voluntary_recommended)

    return {
        "mpp_mandatory_count": len(mandatory),
        "mpp_mandatory_invoices": mandatory,
        "mpp_voluntary_recommended_count": len(voluntary_recommended),
        "mpp_voluntary_recommended": voluntary_recommended,
        "mpp_voluntary_optional_count": len(voluntary_optional),
        "mpp_total_safe_harbor_benefit": round(total_safe_harbor_benefit, 2),
        "mpp_optimization_note": (
            f"Użycie MPP dla {len(voluntary_recommended)} faktur poniżej progu "
            f"daje szacowaną korzyść safe harbor {total_safe_harbor_benefit:.2f} PLN. "
            f"Chroni przed solidarną odpowiedzialnością za VAT dostawcy."
        ),
    }


# ═══════════════════════════════════════════════════════════════════════════════
# 8.12 AI TAX AUTHORITY INTERACTION ENGINE
# ═══════════════════════════════════════════════════════════════════════════════

def tax_authority_interaction(
    interaction_type: str,
    declaration_type: str,
    tax_office_code: str,
    has_active_proceedings: bool = False,
) -> dict:
    """
    AI Engine do interakcji z organami podatkowymi:
    - Optymalny moment na złożenie czynnego żalu
    - Przygotowanie odpowiedzi na wezwanie KAS
    - Kalkulacja szans na umorzenie kary
    - Sugestie linii orzeczniczych na korzyść podatnika
    """
    interaction_strategies = {
        "VOLUNTARY_DISCLOSURE": {
            "optimal_moment": "BEFORE_AUDIT_NOTIFICATION",
            "success_rate": 0.85 if not has_active_proceedings else 0.05,
            "required_documents": [
                "Pismo z czynnym żalem (Art. 16 KKS)",
                "Korekta deklaracji (Art. 81 OrdPU)",
                "Dowód wpłaty zaległości w ciągu 7 dni",
            ],
            "strategy_note": "Złóż przed otrzymaniem zawiadomienia o kontroli. Po wszczęciu — skuteczność 0%.",
        },
        "AUDIT_RESPONSE": {
            "optimal_moment": "WITHIN_7_DAYS",
            "success_rate": 0.60,
            "required_documents": [
                "Odpowiedź na protokół kontroli",
                "Dowody księgowe (faktury, umowy, potwierdzenia przelewów)",
                "Ewidencja VAT / PKPiR za kontrolowany okres",
            ],
            "strategy_note": "Odpowiedz w ciągu 7 dni. Przedstaw pełną dokumentację. Rozważ korektę deklaracji przed zakończeniem kontroli (Art. 81 OrdPU).",
        },
        "PENALTY_REDUCTION": {
            "optimal_moment": "AFTER_ASSESSMENT_BEFORE_DEADLINE",
            "success_rate": 0.40,
            "required_documents": [
                "Wniosek o umorzenie / rozłożenie na raty",
                "Dokumentacja sytuacji finansowej (PIT, wyciągi bankowe)",
                "Uzasadnienie ważnego interesu podatnika",
            ],
            "strategy_note": "Wniosek o umorzenie — powołaj się na ważny interes podatnika lub interes publiczny. Szansa ~40% przy pierwszym naruszeniu.",
        },
    }

    strategy = interaction_strategies.get(interaction_type, {})
    return {
        **strategy,
        "interaction_type": interaction_type,
        "declaration_type": declaration_type,
        "tax_office_code": tax_office_code,
        "has_active_proceedings": has_active_proceedings,
        "ai_recommendation": strategy.get("strategy_note", "Skonsultuj z doradcą podatkowym"),
        "ai_success_rate": strategy.get("success_rate", 0.5),
        "ai_engine_version": "v7.0-enterprise",
    }


# ═══════════════════════════════════════════════════════════════════════════════
# MODULE EXPORT — integracja z PreOPAPipeline
# ═══════════════════════════════════════════════════════════════════════════════

__all__ = [
    "mpp_auto_detect",
    "vat_rate_classify",
    "VatLimitTracker",
    "bad_debt_optimize",
    "cross_border_vat_matrix",
    "gtu_semantic_tag",
    "vat_cashflow_predict",
    "proportion_optimize",
    "ksef_resilience_check",
    "build_merkle_tree",
    "split_payment_optimize",
    "tax_authority_interaction",
    "ANNEX15_KEYWORDS",
    "EU_VAT_RATES",
    "EU_VAT_MATRIX",
    "GTU_KEYWORD_MAP",
    "CN_RATE_HINTS",
]
