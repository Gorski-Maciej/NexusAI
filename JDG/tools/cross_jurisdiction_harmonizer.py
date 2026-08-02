#!/usr/bin/env python3
"""
NexusAI JDG — Cross-Jurisdiction Rule Harmonizer (Innovation #10, P28 Grand Finale)
Mapowanie reguł PL na inne jurysdykcje (UPO), harmonizacja WHT/PE.
"""
import sys, os, json
from datetime import datetime

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Mapa UPO Polska ↔ inne kraje
UPO_MAPPING = {
    "DE": {
        "country": "Niemcy",
        "wht_dividends": 0.05,  # 5% przy udziale ≥10%
        "wht_interest": 0.05,   # 5%
        "wht_royalties": 0.05,  # 5%
        "pe_threshold_months": 12,
        "treaty_dz_u": "Dz.U. 2005 nr 12 poz. 90"
    },
    "GB": {
        "country": "Wielka Brytania",
        "wht_dividends": 0.10,
        "wht_interest": 0.05,
        "wht_royalties": 0.05,
        "pe_threshold_months": 12,
        "treaty_dz_u": "Dz.U. 2006 nr 250 poz. 1840"
    },
    "US": {
        "country": "USA",
        "wht_dividends": 0.15,
        "wht_interest": 0.00,
        "wht_royalties": 0.10,
        "pe_threshold_months": 12,
        "treaty_dz_u": "Dz.U. 1976 nr 31 poz. 178"
    },
    "UA": {
        "country": "Ukraina",
        "wht_dividends": 0.10,
        "wht_interest": 0.10,
        "wht_royalties": 0.10,
        "pe_threshold_months": 12,
        "treaty_dz_u": "Dz.U. 1994 nr 98 poz. 474"
    },
    "CZ": {
        "country": "Czechy",
        "wht_dividends": 0.10,
        "wht_interest": 0.05,
        "wht_royalties": 0.10,
        "pe_threshold_months": 12,
        "treaty_dz_u": "Dz.U. 2012 poz. 991"
    },
    "NL": {
        "country": "Holandia",
        "wht_dividends": 0.15,
        "wht_interest": 0.05,
        "wht_royalties": 0.05,
        "pe_threshold_months": 12,
        "treaty_dz_u": "Dz.U. 2003 nr 216 poz. 2120"
    }
}

def harmonize_wht(country_code, amount_pln, income_type):
    """Harmonizuj WHT między PL a krajem docelowym."""
    treaty = UPO_MAPPING.get(country_code, {})
    
    standard_rate = 0.20  # Standardowa stawka WHT w PL
    treaty_rate = None
    
    if income_type == "DIVIDENDS":
        treaty_rate = treaty.get("wht_dividends")
    elif income_type == "INTEREST":
        treaty_rate = treaty.get("wht_interest")
    elif income_type == "ROYALTIES":
        treaty_rate = treaty.get("wht_royalties")
    
    applied_rate = treaty_rate if treaty_rate and treaty_rate < standard_rate else standard_rate
    tax_amount = amount_pln * applied_rate
    tax_saved = amount_pln * (standard_rate - applied_rate) if treaty_rate else 0
    
    return {
        "country": treaty.get("country", "Unknown"),
        "income_type": income_type,
        "amount_pln": amount_pln,
        "standard_wht_rate": standard_rate,
        "treaty_rate": treaty_rate,
        "applied_rate": applied_rate,
        "tax_pln": round(tax_amount, 2),
        "tax_saved_pln": round(tax_saved, 2),
        "requires_certificate": applied_rate < standard_rate,
        "treaty_dz_u": treaty.get("treaty_dz_u", "Brak UPO — stawka 20%")
    }

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Cross-Jurisdiction Harmonizer v1.0         ║")
    print("║  Innovation #10: UPO Mapping & WHT/PE Harmonization      ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    print(f"\n📊 Dostępne jurysdykcje UPO: {len(UPO_MAPPING)}")
    for code, info in UPO_MAPPING.items():
        print(f"   {code}: {info['country']} — {info['treaty_dz_u'][:50]}...")
    
    # Przykład harmonizacji
    result = harmonize_wht("DE", 50000, "DIVIDENDS")
    print(f"\n📋 Przykład: Dywidenda 50k PLN → Niemcy")
    print(f"   Stawka standardowa: {result['standard_wht_rate']*100}%")
    print(f"   Stawka UPO: {result['treaty_rate']*100}%")
    print(f"   Podatek: {result['tax_pln']} PLN")
    print(f"   Oszczędność: {result['tax_saved_pln']} PLN")
    print(f"   Wymagany certyfikat: {'TAK' if result['requires_certificate'] else 'NIE'}")
    
    print(f"\n📋 KPI: Harmonizacja WHT dla {len(UPO_MAPPING)} jurysdykcji")
    
    report = {
        "generated_at": datetime.now().isoformat(),
        "jurisdictions": len(UPO_MAPPING),
        "example": result,
        "mapping": UPO_MAPPING
    }
    
    report_path = os.path.join(BASE, "reports", "cross_jurisdiction_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
