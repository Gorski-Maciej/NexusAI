#!/usr/bin/env python3
"""
NexusAI JDG — Predictive Audit Shield (Innovation #6, P28 Grand Finale)
Rozszerzenie judgment_predictor o dane historyczne — predyktor ryzyka kontroli KAS.
"""
import sys, os, json
from datetime import datetime

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

RISK_FACTORS = {
    "high_revenue_growth": {"weight": 0.10, "threshold_pct": 50},
    "cross_border_transactions": {"weight": 0.15, "description": "Transakcje transgraniczne"},
    "cash_transactions_over_limit": {"weight": 0.20, "threshold_pln": 15000},
    "frequent_corrections": {"weight": 0.10, "threshold_count": 5},
    "late_filings": {"weight": 0.10, "threshold_count": 2},
    "industry_high_risk": {"weight": 0.15, "description": "Branża wysokiego ryzyka"},
    "rapid_tax_form_changes": {"weight": 0.05, "threshold_changes": 3},
    "large_vat_refunds": {"weight": 0.10, "threshold_pln": 50000},
    "related_party_transactions": {"weight": 0.15, "description": "Transakcje z podmiotami powiązanymi"},
    "unexplained_losses": {"weight": 0.10, "description": "Niewyjaśnione straty"}
}

def calculate_risk_score(profile):
    """Oblicz score ryzyka kontroli."""
    score = 0.0
    factors_detected = []
    
    for factor, config in RISK_FACTORS.items():
        triggered = False
        
        if "revenue_growth" in factor:
            growth = profile.get("revenue_growth_pct", 0)
            triggered = growth > config.get("threshold_pct", 50)
        
        elif "cross_border" in factor:
            triggered = profile.get("has_cross_border", False)
        
        elif "cash" in factor:
            cash_count = profile.get("cash_transactions_over_limit", 0)
            triggered = cash_count > 0
        
        elif "corrections" in factor:
            corrections = profile.get("corrections_count", 0)
            triggered = corrections > config.get("threshold_count", 5)
        
        elif "late" in factor:
            late = profile.get("late_filings_count", 0)
            triggered = late > config.get("threshold_count", 2)
        
        elif "industry" in factor:
            triggered = profile.get("industry_risk", "LOW") == "HIGH"
        
        elif "tax_form" in factor:
            changes = profile.get("tax_form_changes_3y", 0)
            triggered = changes > config.get("threshold_changes", 3)
        
        elif "vat_refunds" in factor:
            refunds = profile.get("vat_refund_total", 0)
            triggered = refunds > config.get("threshold_pln", 50000)
        
        elif "related_party" in factor:
            triggered = profile.get("has_related_party_tx", False)
        
        elif "losses" in factor:
            triggered = profile.get("has_unexplained_losses", False)
        
        if isinstance(config.get("weight"), (int, float)) and triggered:
            score += config["weight"]
            factors_detected.append(factor)
    
    return min(score, 1.0), factors_detected

def generate_recommendations(score, factors):
    """Wygeneruj rekomendacje obronne."""
    recommendations = []
    
    if score > 0.6:
        recommendations.append({
            "priority": "CRITICAL",
            "action": "Przygotuj się na kontrolę KAS w ciągu 6 miesięcy",
            "steps": [
                "Sprawdź kompletność dokumentacji",
                "Zweryfikuj rozliczenia VAT za ostatnie 5 lat",
                "Przygotuj audit_defense (plan44/plan45)",
                "Skonsultuj się z doradcą podatkowym"
            ]
        })
    elif score > 0.3:
        recommendations.append({
            "priority": "HIGH",
            "action": "Zwiększona szansa kontroli — wzmocnij dokumentację",
            "steps": [
                "Upewnij się że wszystkie faktury są w KSeF",
                "Sprawdź Białą Listę VAT kontrahentów",
                "Zweryfikuj limity transakcji gotówkowych"
            ]
        })
    else:
        recommendations.append({
            "priority": "LOW",
            "action": "Standardowe ryzyko — monitoruj",
            "steps": ["Prowadź bieżącą ewidencję", "Aktualizuj politykę rachunkowości"]
        })
    
    return recommendations

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Predictive Audit Shield v1.0               ║")
    print("║  Innovation #6: KAS Control Risk Predictor (P28)         ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    # Domyślny profil
    profile = {
        "revenue_growth_pct": 35,
        "has_cross_border": True,
        "cash_transactions_over_limit": 3,
        "corrections_count": 2,
        "late_filings_count": 0,
        "industry_risk": "MEDIUM",
        "tax_form_changes_3y": 1,
        "vat_refund_total": 25000,
        "has_related_party_tx": False,
        "has_unexplained_losses": False
    }
    
    score, factors = calculate_risk_score(profile)
    recommendations = generate_recommendations(score, factors)
    
    print(f"\n📊 Audit Risk Assessment:")
    print(f"   Score ryzyka: {score:.1%}")
    print(f"   Poziom: {'🔴 WYSOKIE' if score > 0.5 else '🟡 ŚREDNIE' if score > 0.25 else '🟢 NISKIE'}")
    print(f"   Czynniki ryzyka ({len(factors)}):")
    for f in factors:
        print(f"     - {f}")
    
    print(f"\n🛡️ Rekomendacje:")
    for r in recommendations:
        print(f"   [{r['priority']}] {r['action']}")
        for s in r["steps"]:
            print(f"      → {s}")
    
    print(f"\n📋 KPI: Predykcyjna dokładność — cel: redukcja niespodziewanych kontroli o 50%")
    
    report_path = os.path.join(BASE, "reports", "audit_shield_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump({
            "score": score,
            "factors": factors,
            "recommendations": recommendations,
            "generated_at": datetime.now().isoformat()
        }, f, indent=2, ensure_ascii=False)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
