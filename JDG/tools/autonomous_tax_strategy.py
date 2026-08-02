#!/usr/bin/env python3
"""
NexusAI JDG — Autonomous Tax Strategy AI (Innovation #9, P28 Grand Finale)
AI doradzająca strategię podatkową (forma, ulgi, moment transakcji).
Bazuje na decision_scoring_enterprise + cashflow_tax_predictor_enterprise.
"""
import sys, os, json
from datetime import datetime

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

STRATEGIES = {
    "tax_form_selection": {
        "title": "Wybór formy opodatkowania",
        "factors": ["annual_revenue", "annual_costs", "has_employees", "industry_type", "has_assets"],
        "options": ["SCALE", "LINEAR", "LUMP_SUM"]
    },
    "relief_optimization": {
        "title": "Optymalizacja ulg podatkowych",
        "factors": ["has_rd_activity", "has_children", "has_donations", "uses_ip", "has_thermo"],
        "options": ["RD_RELIEF", "CHILD_RELIEF", "DONATION_RELIEF", "IP_BOX", "THERMO_RELIEF"]
    },
    "zus_strategy": {
        "title": "Strategia ZUS",
        "factors": ["months_in_business", "annual_revenue", "is_new_business"],
        "options": ["START_RELIEF", "PREFERENTIAL", "MALY_ZUS_PLUS", "STANDARD"]
    },
    "investment_timing": {
        "title": "Timing inwestycji",
        "factors": ["current_tax_form", "expected_profit", "investment_amount"],
        "options": ["THIS_YEAR", "NEXT_YEAR", "SPLIT"]
    }
}

def analyze_tax_form(profile):
    """Analizuj optymalną formę opodatkowania."""
    revenue = profile.get("annual_revenue", 120000)
    costs = profile.get("annual_costs", 40000)
    profit = revenue - costs
    
    results = {}
    
    # Skala 12%/32%
    scale_tax = 0
    if profit <= 30000:
        scale_tax = 0
    elif profit <= 120000:
        scale_tax = max(0, (profit - 30000) * 0.12)
    else:
        scale_tax = 10800 + (profit - 120000) * 0.32
    results["SCALE"] = {"tax": scale_tax, "health": profit * 0.09, "net": profit - scale_tax - profit * 0.09}
    
    # Liniowy 19%
    linear_tax = profit * 0.19
    linear_health = min(profit * 0.049, 14100)
    results["LINEAR"] = {"tax": linear_tax, "health": linear_health, "net": profit - linear_tax - linear_health}
    
    # Ryczałt (zakładamy 8.5%)
    lump_tax = revenue * 0.085
    lump_health = 819 * 12
    results["LUMP_SUM"] = {"tax": lump_tax, "health": lump_health, "net": profit - lump_tax - lump_health}
    
    best = max(results.items(), key=lambda x: x[1]["net"])
    
    return {
        "profile": {"revenue": revenue, "costs": costs, "profit": profit},
        "results": {k: {kk: round(vv, 2) for kk, vv in v.items()} for k, v in results.items()},
        "recommendation": best[0],
        "annual_saving_vs_worst": round(best[1]["net"] - min(results.values(), key=lambda x: x["net"])["net"], 2)
    }

def analyze_reliefs(profile):
    """Analizuj dostępne ulgi."""
    available = []
    
    if profile.get("has_rd_activity"):
        available.append({"relief": "RD_RELIEF", "description": "Ulga B+R — 100% lub 200% kosztów kwalifikowanych", "potential_saving": "200% × koszty B+R"})
    if profile.get("uses_ip"):
        available.append({"relief": "IP_BOX", "description": "IP Box — 5% od dochodu z kwalifikowanego IP", "potential_saving": "14% vs 19% liniowy"})
    if profile.get("has_children"):
        available.append({"relief": "CHILD_RELIEF", "description": "Ulga na dziecko — do 1112 PLN/mies. na dziecko", "potential_saving": "1112 PLN × 12 × liczba dzieci"})
    if profile.get("has_thermo"):
        available.append({"relief": "THERMO_RELIEF", "description": "Ulga termomodernizacyjna — do 53 000 PLN", "potential_saving": "do 53 000 PLN od dochodu"})
    
    return available

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Autonomous Tax Strategy AI v1.0             ║")
    print("║  Innovation #9: Tax Optimization Advisor (P28)            ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    # Przykład: JDG usługowa
    profile = {
        "annual_revenue": 180000,
        "annual_costs": 50000,
        "has_employees": False,
        "industry_type": "IT_SERVICES",
        "has_assets": True,
        "has_rd_activity": True,
        "uses_ip": True,
        "has_children": True,
        "has_donations": False,
        "has_thermo": False,
        "months_in_business": 30,
        "is_new_business": False
    }
    
    print(f"\n📊 Profil JDG: przychód={profile['annual_revenue']:,} PLN, koszty={profile['annual_costs']:,} PLN, branża={profile['industry_type']}")
    
    # Analiza formy
    form_analysis = analyze_tax_form(profile)
    print(f"\n📋 Forma opodatkowania:")
    for form, data in form_analysis["results"].items():
        marker = " ⭐" if form == form_analysis["recommendation"] else ""
        print(f"   {form}: podatek={data['tax']:,.0f}, zdrowotna={data['health']:,.0f}, netto={data['net']:,.0f}{marker}")
    print(f"\n   → Rekomendacja: {form_analysis['recommendation']} (oszczędność {form_analysis['annual_saving_vs_worst']:,.0f} PLN/rok)")
    
    # Analiza ulg
    reliefs = analyze_reliefs(profile)
    print(f"\n📋 Dostępne ulgi ({len(reliefs)}):")
    for r in reliefs:
        print(f"   [{r['relief']}] {r['description']} — {r['potential_saving']}")
    
    # Strategia ZUS
    print(f"\n📋 Strategia ZUS ({profile['months_in_business']} mies. działalności):")
    if profile["months_in_business"] < 6:
        print("   → Ulga na start (0 PLN społeczne, tylko zdrowotna)")
    elif profile["months_in_business"] < 30:
        print("   → Preferencyjny ZUS (~620 PLN społeczne)")
    elif profile["annual_revenue"] < 120000:
        print("   → Mały ZUS Plus (składki liczone od dochodu)")
    else:
        print("   → Standardowy ZUS (~1600 PLN/mies.)")
    
    print(f"\n📋 KPI: Optymalizacja podatkowa — cel: redukcja obciążenia o ≥15%")
    
    report_path = os.path.join(BASE, "reports", "tax_strategy_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump({
            "profile": profile,
            "recommended_form": form_analysis["recommendation"],
            "available_reliefs": reliefs,
            "generated_at": datetime.now().isoformat()
        }, f, indent=2, ensure_ascii=False)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
