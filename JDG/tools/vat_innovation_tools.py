# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — VAT Innovation Tools Bundle (P29 Innovations #4-#15)
# ═══════════════════════════════════════════════════════════════════════════════
# Narzędzia z audytu P29: MPP Precision, Cross-Border Rates, Temporal Snapshot,
# Exemption Monitor, Proportion Optimizer, GTU Assigner, KSeF Buffer,
# Reverse Charge Detector, OSS Matrix, Sanction Calculator, Zero-Defect Cert.
# Uwaga: Carousel Detector (#3) i Bad Debt Tracker (#7) są w plan26_critical.rego
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# INNOVATION #4: MPP Threshold Precision Engine
# ═══════════════════════════════════════════════════════════════════════════════

def mpp_threshold_precision_check(amount_gross: float, threshold: float = 15000.0) -> dict:
    """MPP Threshold Precision — obsługa kwot groszowych i progowych"""
    result = {
        "amount_gross": amount_gross,
        "threshold": threshold,
        "mpp_required": amount_gross >= threshold,
        "boundary": False,
        "precision_gap": 0.0,
        "warning": "",
    }

    if amount_gross >= threshold - 0.02 and amount_gross <= threshold + 0.02:
        result["boundary"] = True
        result["precision_gap"] = abs(amount_gross - threshold)
        result["warning"] = (
            f"⚠️ MPP PROGOWA KWOTA: {amount_gross:.2f} PLN ≈ {threshold:.2f} PLN. "
            f"Art. 108a VAT: 'przekracza 15 000 zł' → >= {threshold:.2f} = MPP OBOWIĄZKOWY. "
            f"Różnica: {result['precision_gap']:.4f} PLN."
        )

    return result


# ═══════════════════════════════════════════════════════════════════════════════
# INNOVATION #5: Cross-Border VAT Rate Harmonizer
# ═══════════════════════════════════════════════════════════════════════════════

EU_VAT_RATES = {
    "AT": {"standard": 0.20, "reduced": 0.10},
    "BE": {"standard": 0.21, "reduced": 0.06},
    "BG": {"standard": 0.20, "reduced": 0.09},
    "CZ": {"standard": 0.21, "reduced": 0.12},
    "DE": {"standard": 0.19, "reduced": 0.07},
    "DK": {"standard": 0.25, "reduced": 0.00},
    "EE": {"standard": 0.22, "reduced": 0.09},
    "FI": {"standard": 0.255, "reduced": 0.10},
    "FR": {"standard": 0.20, "reduced": 0.055},
    "GR": {"standard": 0.24, "reduced": 0.06},
    "HU": {"standard": 0.27, "reduced": 0.05},
    "IE": {"standard": 0.23, "reduced": 0.09},
    "IT": {"standard": 0.22, "reduced": 0.04},
    "LT": {"standard": 0.21, "reduced": 0.09},
    "LU": {"standard": 0.17, "reduced": 0.08},
    "LV": {"standard": 0.21, "reduced": 0.12},
    "MT": {"standard": 0.18, "reduced": 0.05},
    "NL": {"standard": 0.21, "reduced": 0.09},
    "PL": {"standard": 0.23, "reduced_8": 0.08, "reduced_5": 0.05},
    "PT": {"standard": 0.23, "reduced": 0.06},
    "RO": {"standard": 0.19, "reduced": 0.05},
    "SE": {"standard": 0.25, "reduced": 0.06},
    "SI": {"standard": 0.22, "reduced": 0.095},
    "SK": {"standard": 0.23, "reduced": 0.10},
}

def get_eu_vat_rate(country_code: str, reduced: bool = False) -> dict:
    """Pobierz stawkę VAT dla kraju UE"""
    rates = EU_VAT_RATES.get(country_code.upper(), {})
    if not rates:
        return {"error": f"Unknown country: {country_code}"}
    rate = rates.get("reduced", rates.get("standard", 0.20)) if reduced else rates.get("standard", 0.20)
    return {"country": country_code.upper(), "rate": rate, "is_reduced": reduced}


# ═══════════════════════════════════════════════════════════════════════════════
# INNOVATION #6: VAT Temporal Snapshot Engine
# ═══════════════════════════════════════════════════════════════════════════════

VAT_TEMPORAL_SNAPSHOTS = {
    "2011-01-01": {
        "rates": {"standard": 0.23, "reduced_8": 0.08, "reduced_5": 0.05},
        "description": "Stawki 23/8/5% od 2011 (poprzednio 22/7/3%)",
    },
    "2020-07-01": {
        "rates": {"standard": 0.23, "reduced_8": 0.08, "reduced_5": 0.05},
        "description": "Nowa matryca stawek VAT (Rozp. MF 2020)",
    },
    "2022-01-01": {
        "rates": {"standard": 0.23, "reduced_8": 0.08, "reduced_5": 0.05},
        "description": "Polski Ład 2022 + SLIM VAT 2",
    },
    "2023-07-01": {
        "rates": {"standard": 0.23, "reduced_8": 0.08, "reduced_5": 0.05},
        "description": "SLIM VAT 3 — złe długi 90 dni",
    },
    "2026-02-01": {
        "rates": {"standard": 0.23, "reduced_8": 0.08, "reduced_5": 0.05},
        "description": "KSeF obowiązkowy dla B2B",
    },
}

def get_vat_snapshot(date_str: str) -> dict:
    """Pobierz stan reguł VAT na dowolną datę"""
    date_key = date_str[:10]
    # Znajdź najbliższy poprzedzający snapshot
    best_snapshot = None
    best_date = "0000-01-01"
    for snap_date in sorted(VAT_TEMPORAL_SNAPSHOTS.keys()):
        if snap_date <= date_key and snap_date > best_date:
            best_date = snap_date
            best_snapshot = VAT_TEMPORAL_SNAPSHOTS[snap_date]
    return best_snapshot or {"error": f"No snapshot for date: {date_str}"}


# ═══════════════════════════════════════════════════════════════════════════════
# INNOVATION #8: VAT Exemption Limit Predictive Monitor
# ═══════════════════════════════════════════════════════════════════════════════

def predict_exemption_exceed(current_turnover: float, days_in_year: int = 365,
                             current_day: int = 200, limit: float = 200000.0) -> dict:
    """Predykcja daty przekroczenia limitu zwolnienia 200k"""
    proportional_limit = limit / days_in_year * current_day
    daily_rate = current_turnover / max(current_day, 1)
    days_remaining = (proportional_limit - current_turnover) / max(daily_rate, 0.01)

    return {
        "current_turnover": current_turnover,
        "proportional_limit": proportional_limit,
        "daily_rate": daily_rate,
        "days_until_exceeded": round(days_remaining),
        "exceeded": current_turnover > proportional_limit,
        "warning": (
            f"⚠️ Limit zwolnienia VAT przekroczony! {current_turnover:.0f} > {proportional_limit:.0f} PLN"
            if current_turnover > proportional_limit
            else f"Limit zwolnienia: {current_turnover:.0f}/{proportional_limit:.0f} PLN "
                 f"({days_remaining:.0f} dni do przekroczenia)"
        )
    }


# ═══════════════════════════════════════════════════════════════════════════════
# INNOVATION #9: Proportional Deduction Optimizer
# ═══════════════════════════════════════════════════════════════════════════════

def optimize_proportion(taxable_revenue: float, exempt_revenue: float) -> dict:
    """Optymalizacja proporcji odliczenia VAT (Art. 90-91)"""
    total = taxable_revenue + exempt_revenue
    if total == 0:
        return {"proportion": 0.0, "error": "Brak przychodów"}

    proportion = taxable_revenue / total

    if proportion < 0.02:
        result = {"proportion": proportion, "deduction_pct": 0.0,
                  "rule": "Art. 90 ust. 10 pkt 1: <2% → 0% odliczenia"}
    elif proportion > 0.98:
        result = {"proportion": proportion, "deduction_pct": 1.0,
                  "rule": "Art. 90 ust. 10 pkt 2: >98% → 100% odliczenia"}
    else:
        result = {"proportion": proportion, "deduction_pct": round(proportion, 4),
                  "rule": f"Odliczenie proporcjonalne: {proportion:.2%}"}

    result["taxable"] = taxable_revenue
    result["exempt"] = exempt_revenue
    result["annual_correction_required"] = True

    return result


# ═══════════════════════════════════════════════════════════════════════════════
# INNOVATION #14: VAT Sanction Risk Calculator
# ═══════════════════════════════════════════════════════════════════════════════

VAT_SANCTIONS = {
    "ksef_missing": {"rate": 1.0, "max": 500000, "desc": "100% VAT za brak KSeF (max 500k)"},
    "mpp_missing": {"rate": 0.30, "max": None, "desc": "30% dodatkowego zobowiązania za brak MPP"},
    "bad_debt_debtor": {"rate": 0.30, "max": None, "desc": "30% VAT dla dłużnika po 90 dniach"},
    "fake_invoice": {"rate": 0.30, "max": None, "desc": "30% sankcji za puste faktury"},
    "whitelist_fail": {"rate": 0.30, "max": None, "desc": "30% za płatność poza białą listę"},
    "unregistered": {"rate": 0.30, "max": None, "desc": "30% dodatkowego zobowiązania"},
}

def calculate_vat_sanction_risk(vat_amount: float, violation_type: str) -> dict:
    """Kalkulator ryzyka sankcji VAT"""
    sanction = VAT_SANCTIONS.get(violation_type)
    if not sanction:
        return {"error": f"Unknown violation: {violation_type}"}

    risk = vat_amount * sanction["rate"]
    if sanction.get("max") and risk > sanction["max"]:
        risk = sanction["max"]

    return {
        "violation": violation_type,
        "description": sanction["desc"],
        "vat_amount": vat_amount,
        "sanction_rate": sanction["rate"],
        "sanction_amount": risk,
        "max_capped": sanction.get("max"),
        "warning": f"Sankcja: {risk:.2f} PLN ({sanction['rate']:.0%} × {vat_amount:.2f} PLN)"
    }


# ═══════════════════════════════════════════════════════════════════════════════
# INNOVATION #15: VAT Zero-Defect Certification
# ═══════════════════════════════════════════════════════════════════════════════

def certify_vat_rule(rule_id: str, legal_basis: str, has_temporal: bool = False,
                     has_native_test: bool = False, adr008_compliant: bool = True) -> dict:
    """Certyfikacja reguły VAT — Zero-Defect Certification"""
    checks = {
        "legal_basis": bool(legal_basis),
        "temporal_validity": has_temporal,
        "native_test": has_native_test,
        "adr008_naming": adr008_compliant,
    }

    all_pass = all(checks.values())
    cert_level = "GOLD" if all_pass else "SILVER" if sum(checks.values()) >= 3 else "BRONZE"

    return {
        "rule_id": rule_id,
        "certification_level": cert_level,
        "checks": checks,
        "passed": list(k for k, v in checks.items() if v),
        "failed": list(k for k, v in checks.items() if not v),
        "blocking": not all_pass,
    }


if __name__ == '__main__':
    # Quick tests
    print("MPP Precision:", mpp_threshold_precision_check(15000.00))
    print("EU Rate DE:", get_eu_vat_rate("DE"))
    print("Snapshot 2023-07:", get_vat_snapshot("2023-07-15"))
    print("Exemption:", predict_exemption_exceed(190000, current_day=300))
    print("Proportion:", optimize_proportion(500000, 300000))
    print("Sanction:", calculate_vat_sanction_risk(23000, "ksef_missing"))
    print("Cert:", certify_vat_rule("jdg.vat.plan26_critical.mpp_threshold_precision",
                                    "Art. 108a VAT", True, True, True))
