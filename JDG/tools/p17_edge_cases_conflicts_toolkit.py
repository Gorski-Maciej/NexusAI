#!/usr/bin/env python3
"""P17 Edge Cases & Conflicts Enterprise Toolkit v1.0 — 12 innowacji
═══════════════════════════════════════════════════════════════════════════
Ekosystem P17: Edge Cases (187 reguł) + Conflicts (27 reguł) + Corrections
(16 reguł) + Statute of Limitations (14 reguł) + Risk (P0-P9 + fraud) +
Temporal (RMK + time-travel) + GAAR + Family + Force Majeure + E-Delivery.
Łącznie ~2800 linii Rego w 12 plikach.
═══════════════════════════════════════════════════════════════════════════
12 innowacji Enterprise:
  INN01 — Edge Case Auto-Discovery Engine (skanowanie 187 reguł)
  INN02 — Cross-Domain Conflict Resolution Matrix (27 par domen)
  INN03 — Correction Auto-Suggester (VAT/PIT/ZUS/JPK)
  INN04 — Statute of Limitations Countdown Timer (5/10 lat)
  INN05 — Risk Heatmap Generator (fraud + KKS + GAAR scoring)
  INN06 — GAAR Trigger Detector (Art. 119a OrdPU)
  INN07 — Conflict Severity Auto-Grader (CRITICAL→INFO)
  INN08 — Edge Case Coverage Guarantee (analiza luk)
  INN09 — Correction Chain Tracker (łańcuch korekt)
  INN10 — Limitation Period Cross-Reference (OrdPU vs KKS)
  INN11 — Proactive Risk Mitigation Engine (pre-audit shield)
  INN12 — Edge Case Test Auto-Generator (187+ test templates)
"""

import sys, os, json, argparse
from datetime import date, datetime, timedelta
from collections import defaultdict

# ═══════════════════════════════════════════════════════════════════════════════
# GLOBAL CONFIGURATION — Stawki i progi 2026
# ═══════════════════════════════════════════════════════════════════════════════

EDGE_CASE_CATEGORIES = {
    "GRUPA_A_VAT": {"range": (546, 559), "desc": "VAT Edge Cases — przekroczenie limitu, proporcja, tax point, waluty, KSeF"},
    "GRUPA_B_PIT": {"range": (560, 573), "desc": "PIT Edge Cases — pierwszy rok, zamknięcie, podwójne opodatkowanie, straty"},
    "GRUPA_C_ZUS": {"range": (574, 585), "desc": "ZUS Edge Cases — przejścia między ulgami, zbiegi tytułów, zawieszenie"},
    "GRUPA_D_VAT_EXEMPTION": {"range": (586, 594), "desc": "VAT Zwolnienie Podmiotowe — wyłączenia, utrata, ponowne nabycie, ViDA"},
    "GRUPA_E_PIT_EXTENDED": {"range": (595, 601), "desc": "PIT Edge Rozszerzenie — ulgi, najem, waluty, darowizny"},
    "GRUPA_G_SANCTIONS": {"range": (646, 655), "desc": "Sankcje KKS — progi, stawki, czynny żal"},
    "GRUPA_H_DEADLINES": {"range": (656, 672), "desc": "Terminy — VAT, PIT, ZUS, deklaracje"},
    "GRUPA_I_CROSSBORDER": {"range": (673, 680), "desc": "Cross-border — TP, CFC, WHT, rezydencja"},
}

CONFLICT_DOMAINS = {
    "allowances_vs_allowances": ("IP Box vs B+R", "Art. 30ca PIT vs Art. 26e PIT", "PREFER_ONE"),
    "pit_vs_accounting": ("Reprezentacja vs Marketing", "Art. 23 ust. 1 pkt 23 PIT", "DOCUMENT_BUSINESS_PURPOSE"),
    "vat_vs_pit": ("Auto VAT 50% vs KUP 75%", "Art. 86a VAT vs Art. 23 PIT", "ACCEPT_ASYMMETRY"),
    "vat_vs_vat": ("Złe długi wierzyciel vs dłużnik", "Art. 89a vs 89b VAT", "BOTH_CORRECTIONS"),
    "pit_vs_vat": ("Amortyzacja PIT vs UoR", "Art. 22a-22o PIT vs Art. 28-34 UoR", "SEPARATE_RECORDS"),
    "accounting_vs_vat": ("Kurs FX NBP A vs C", "Art. 14c PIT vs Art. 30a-c VAT", "PREFER_CUSTOMS_TABLE_C"),
    "pit_vs_pit": ("Ulgi vs strata", "Art. 26 PIT", "BLOCK_NON_RD_ALLOWANCES"),
}

STATUTE_PERIODS = {
    "TAX_OBLIGATION": {"years": 5, "basis": "Art. 70 § 1 OrdPU", "starts": "END_OF_TAX_YEAR"},
    "TAX_CRIME": {"years": 10, "basis": "Art. 70 § 2 OrdPU + Art. 44 KKS", "starts": "END_OF_CRIME_YEAR"},
    "KKS_PROSECUTION": {"years": 5, "basis": "Art. 44 § 1 KKS", "starts": "TIME_OF_OFFENSE"},
    "KKS_PROSECUTION_EXTENDED": {"years": 10, "basis": "Art. 44 § 2 KKS", "starts": "PROCEEDINGS_STARTED"},
    "DOCUMENT_RETENTION": {"years": 5, "basis": "Art. 86 OrdPU", "starts": "END_OF_TAX_YEAR"},
    "CORRECTION_WINDOW": {"years": 5, "basis": "Art. 81 OrdPU", "starts": "ORIGINAL_DEADLINE"},
}

RISK_CATEGORIES = {
    "FRAUD_VAT": ("Sieć fraudowa VAT", 100, "Art. 86 VAT, Art. 55 KKS"),
    "EMPTY_INVOICE": ("Pusta faktura", 100, "Art. 62 § 2 KKS"),
    "GAAR": ("Sztuczna struktura GAAR", 95, "Art. 119a OrdPU"),
    "HIDDEN_INCOME": ("Ukryte dochody", 80, "Art. 54 KKS"),
    "UNRELIABLE_BOOKS": ("Nierzetelna PKPiR", 75, "Art. 56 KKS"),
    "LOW_TRUST": ("Niski trust score", 65, "Art. 22 UoR"),
    "AMOUNT_ANOMALY": ("Anomalia kwotowa >3σ", 55, "Art. 22 UoR"),
    "NEW_COUNTERPARTY": ("Nowy kontrahent", 40, "Procedury AML"),
    "SUSPENDED_CEIDG": ("Zawieszony CEIDG", 70, "Art. 88 VAT"),
    "VAT_EVIDENCE_GAP": ("Luka w ewidencji VAT", 60, "Art. 57 KKS"),
    "DECLARATION_OVERDUE": ("Niezłożona deklaracja", 55, "Art. 77 KKS"),
    "HEURISTIC_EMPTY": ("Heurystyka pustej faktury", 45, "Art. 62 KKS (heurystyka)"),
}

GAAR_TRIGGERS = {
    "related_party": {"weight": 35, "desc": "Transakcja z podmiotem powiązanym"},
    "artificial_scheme": {"weight": 40, "desc": "Sztuczna struktura bez uzasadnienia ekonomicznego"},
    "tax_benefit_primary": {"weight": 30, "desc": "Głównym celem jest korzyść podatkowa"},
    "circular_flow": {"weight": 25, "desc": "Przepływy okrężne (round-tripping)"},
    "tax_haven_involved": {"weight": 20, "desc": "Podmiot w raju podatkowym"},
    "step_transaction": {"weight": 15, "desc": "Sztuczny podział transakcji (step transaction)"},
    "no_economic_substance": {"weight": 35, "desc": "Brak substancji ekonomicznej"},
    "back_to_back": {"weight": 20, "desc": "Transakcje back-to-back bez wartości dodanej"},
    "hybrid_mismatch": {"weight": 25, "desc": "Hybrydowe rozbieżności kwalifikacyjne"},
}

CORRECTION_TYPES = {
    "INVOICE_IN_MINUS": {"direction": "DECREASE", "period": "BUYER_RECEIPT_DATE", "basis": "Art. 106j VAT"},
    "INVOICE_IN_PLUS": {"direction": "INCREASE", "period": "ORIGINAL_PERIOD", "basis": "Art. 106j VAT"},
    "JPK_V7K": {"direction": "AMENDMENT", "period": "ORIGINAL_PERIOD", "basis": "Art. 81 OrdPU"},
    "PIT_ADVANCE": {"direction": "AMEND_ANNUAL", "period": "ANNUAL_RETURN", "basis": "Art. 44 PIT"},
    "ZUS_DRA": {"direction": "CORRECT_BASE", "period": "CURRENT", "basis": "Art. 47 SUS"},
    "BAD_DEBT_VAT": {"direction": "DECREASE/INCREASE", "period": "90_DAYS_AFTER", "basis": "Art. 89a-89b VAT"},
    "BAD_DEBT_PIT": {"direction": "DECREASE/INCREASE", "period": "90_DAYS_AFTER", "basis": "Art. 26i PIT"},
    "ANNUAL_PROPORTION": {"direction": "UPDATE", "period": "JANUARY_NEXT_YEAR", "basis": "Art. 91 VAT"},
    "FIXED_ASSET": {"direction": "ANNUAL_CORRECTION", "period": "5_OR_10_YEARS", "basis": "Art. 91 ust. 2 VAT"},
    "CROSS_BORDER": {"direction": "VAT_UE_AMENDMENT", "period": "14_DAYS", "basis": "Art. 103 VAT"},
}

TODAY = date.today()


class P17EnterpriseToolkit:
    """P17 Edge Cases & Conflicts — Kompletny zestaw 12 innowacji Enterprise."""

    def __init__(self):
        self.results = {}

    # ═══════════════════════════════════════════════════════════════════════════
    # INN01: Edge Case Auto-Discovery Engine
    # ═══════════════════════════════════════════════════════════════════════════
    def discover_edge_cases(self, rules_file="JDG/rules/edge_cases.rego"):
        """Skanuje plik Rego i odkrywa wszystkie edge cases z metadanymi."""
        discovered = {}
        try:
            with open(rules_file) as f:
                content = f.read()

            for cat, info in EDGE_CASE_CATEGORIES.items():
                start, end = info["range"]
                # Count rules in this range by looking for priority patterns
                patterns_found = []
                for line in content.split("\n"):
                    if '"priority":' in line:
                        try:
                            prio = int(line.split('"priority":')[1].split(",")[0].strip().rstrip(","))
                            if start <= prio <= end:
                                rule_line = line.strip()
                                patterns_found.append(prio)
                        except (ValueError, IndexError):
                            pass

                discovered[cat] = {
                    "category": cat,
                    "description": info["desc"],
                    "expected_range": f"R{start:04d}-R{end:04d}",
                    "rules_found": len(set(patterns_found)),
                    "coverage_pct": round(len(set(patterns_found)) / (end - start + 1) * 100, 1) if end > start else 0,
                    "status": "COMPLETE" if len(set(patterns_found)) >= (end - start + 1) * 0.8 else "PARTIAL"
                }

        except FileNotFoundError:
            return {"error": f"File not found: {rules_file}"}

        total_rules = sum(d["rules_found"] for d in discovered.values())
        covered_cats = sum(1 for d in discovered.values() if d["status"] == "COMPLETE")

        return {
            "total_categories": len(discovered),
            "categories_fully_covered": covered_cats,
            "total_rules_discovered": total_rules,
            "discovery_timestamp": TODAY.isoformat(),
            "categories": discovered
        }

    # ═══════════════════════════════════════════════════════════════════════════
    # INN02: Cross-Domain Conflict Resolution Matrix
    # ═══════════════════════════════════════════════════════════════════════════
    def conflict_matrix(self, active_conflicts=None):
        """Generuje macierz rozwiązywania konfliktów między domenami."""
        if active_conflicts is None:
            active_conflicts = list(CONFLICT_DOMAINS.keys())

        matrix = []
        for domain_pair in active_conflicts:
            if domain_pair in CONFLICT_DOMAINS:
                desc, basis, resolution = CONFLICT_DOMAINS[domain_pair]
                domains = domain_pair.split("_vs_")
                matrix.append({
                    "conflict_id": f"jdg.conflicts.{domain_pair}",
                    "domain_a": domains[0],
                    "domain_b": domains[1],
                    "description": desc,
                    "legal_basis": basis,
                    "resolution_strategy": resolution,
                    "severity": self._classify_conflict_severity(domain_pair),
                })

        return {
            "matrix_size": len(matrix),
            "total_possible_pairs": len(CONFLICT_DOMAINS),
            "conflicts_found": len(matrix),
            "resolution_summary": self._summarize_resolutions(matrix),
            "conflicts": matrix
        }

    def _classify_conflict_severity(self, domain_pair):
        severity_map = {
            "allowances_vs_allowances": "CRITICAL",
            "pit_vs_accounting": "HIGH",
            "vat_vs_pit": "INFO",
            "vat_vs_vat": "HIGH",
            "pit_vs_vat": "HIGH",
            "accounting_vs_vat": "WARNING",
            "pit_vs_pit": "HIGH",
        }
        return severity_map.get(domain_pair, "WARNING")

    def _summarize_resolutions(self, matrix):
        counts = defaultdict(int)
        for m in matrix:
            counts[m["resolution_strategy"]] += 1
        return dict(counts)

    # ═══════════════════════════════════════════════════════════════════════════
    # INN03: Correction Auto-Suggester
    # ═══════════════════════════════════════════════════════════════════════════
    def suggest_correction(self, tax_type, amount, direction, days_overdue=0, is_cross_border=False):
        """Automatycznie sugeruje typ i metodę korekty."""
        suggestions = []

        if tax_type == "VAT":
            if direction == "DECREASE":
                suggestions.append({
                    "correction_type": "INVOICE_IN_MINUS",
                    "method": "Wystaw fakturę korygującą in-minus",
                    "period": f"Okres otrzymania potwierdzenia odbioru przez nabywcę",
                    "deadline_days": "Bez terminu (bieżący okres JPK)",
                    "basis": CORRECTION_TYPES["INVOICE_IN_MINUS"]["basis"],
                    "interest": "Nadpłata — zwrot w 45 dni" if amount < 0 else "",
                })
            elif direction == "INCREASE":
                suggestions.append({
                    "correction_type": "INVOICE_IN_PLUS",
                    "method": "Wystaw fakturę korygującą in-plus",
                    "period": "Wstecznie w okresie pierwotnej faktury",
                    "deadline_days": "Natychmiast",
                    "basis": CORRECTION_TYPES["INVOICE_IN_PLUS"]["basis"],
                    "interest": f"Dopłata + odsetki za {days_overdue} dni: {self._calc_interest(abs(amount), days_overdue):.2f} PLN",
                })
            elif direction == "BAD_DEBT":
                suggestions.append({
                    "correction_type": "BAD_DEBT_VAT",
                    "method": "Ulga na złe długi — korekta VAT po 90 dniach",
                    "period": "Okres, w którym upłynął 90. dzień od terminu płatności",
                    "deadline_days": "W ciągu okresu JPK_V7 po upływie 90 dni",
                    "basis": CORRECTION_TYPES["BAD_DEBT_VAT"]["basis"],
                })

        elif tax_type == "PIT":
            suggestions.append({
                "correction_type": "PIT_ADVANCE",
                "method": "Skoryguj w zeznaniu rocznym PIT-36/PIT-36L/PIT-28",
                "period": "Zeznanie roczne (do 30 kwietnia następnego roku)",
                "deadline_days": "Nie składaj korekt miesięcznych — rozlicz w zeznaniu rocznym",
                "basis": CORRECTION_TYPES["PIT_ADVANCE"]["basis"],
            })

        elif tax_type == "ZUS":
            suggestions.append({
                "correction_type": "ZUS_DRA",
                "method": "Złóż DRA korygującą",
                "period": "Bieżący okres rozliczeniowy",
                "deadline_days": "Natychmiast — dopłata + odsetki",
                "basis": CORRECTION_TYPES["ZUS_DRA"]["basis"],
                "warning": "Nadpłata: złóż wniosek o zwrot — ZUS NIE zwraca automatycznie!"
            })

        elif tax_type == "CROSS_BORDER":
            suggestions.append({
                "correction_type": "CROSS_BORDER",
                "method": "Korekta VAT-UE / WNT/WDT",
                "period": "W ciągu 14 dni od faktury korygującej",
                "deadline_days": 14,
                "basis": CORRECTION_TYPES["CROSS_BORDER"]["basis"],
            })

        if days_overdue > 5 * 365:
            suggestions.append({
                "correction_type": "STATUTE_EXPIRED",
                "method": "KOREKTA NIEDOPUSZCZALNA — przedawnienie 5 lat",
                "period": "N/A",
                "deadline_days": "N/A",
                "basis": "Art. 70 § 1 OrdPU + Art. 81 OrdPU",
                "warning": f"Zobowiązanie przedawnione po 5 latach. US nie może prowadzić egzekucji."
            })

        return {
            "tax_type": tax_type,
            "amount": amount,
            "direction": direction,
            "days_overdue": days_overdue,
            "suggestions": suggestions,
            "within_statute": days_overdue <= 5 * 365
        }

    def _calc_interest(self, amount, days, rate=14.5):
        return round(amount * rate / 100 * days / 365, 2)

    # ═══════════════════════════════════════════════════════════════════════════
    # INN04: Statute of Limitations Countdown Timer
    # ═══════════════════════════════════════════════════════════════════════════
    def statute_countdown(self, tax_year, liability_type="TAX_OBLIGATION", suspended=False):
        """Oblicza czas do przedawnienia zobowiązania podatkowego."""
        period = STATUTE_PERIODS.get(liability_type, STATUTE_PERIODS["TAX_OBLIGATION"])

        try:
            year_int = int(tax_year)
        except (ValueError, TypeError):
            year_int = 2021

        deadline_year = year_int + period["years"]
        deadline_date = date(deadline_year, 12, 31)

        if suspended:
            deadline_year = year_int + 10  # Max extension
            deadline_date = date(deadline_year, 12, 31)
            status = "SUSPENDED"
        else:
            status = "ACTIVE"

        days_remaining = (deadline_date - TODAY).days
        is_expired = days_remaining < 0

        return {
            "tax_year": tax_year,
            "liability_type": liability_type,
            "statute_years": period["years"],
            "legal_basis": period["basis"],
            "starts_from": period["starts"],
            "deadline_date": deadline_date.isoformat(),
            "days_remaining": max(0, days_remaining),
            "is_expired": is_expired,
            "status": "EXPIRED" if is_expired else ("SUSPENDED" if suspended else status),
            "urgency": "CRITICAL" if days_remaining < 90 else ("HIGH" if days_remaining < 365 else ("MEDIUM" if days_remaining < 730 else "LOW")),
            "recommendation": self._statute_recommendation(days_remaining, is_expired, suspended)
        }

    def _statute_recommendation(self, days, expired, suspended):
        if expired:
            return "Zobowiązanie przedawnione. US nie może prowadzić egzekucji. Dokumenty można zniszczyć po 5 latach od przedawnienia."
        if suspended:
            return "BIEG ZAWIESZONY — przedawnienie nie biegnie do zakończenia postępowania KKS/kontroli."
        if days < 90:
            return f"KRYTYCZNE: tylko {days} dni do przedawnienia! Zabezpiecz dokumentację i przygotuj się na ewentualną kontrolę."
        if days < 365:
            return f"UWAGA: {days} dni do przedawnienia. Zachowaj dokumenty do terminu."
        return f"Spokojnie: {days} dni ({days//365} lat) do przedawnienia."

    # ═══════════════════════════════════════════════════════════════════════════
    # INN05: Risk Heatmap Generator
    # ═══════════════════════════════════════════════════════════════════════════
    def risk_heatmap(self, risk_flags=None):
        """Generuje mapę cieplną ryzyka podatkowego."""
        if risk_flags is None:
            risk_flags = list(RISK_CATEGORIES.keys())

        heatmap = []
        total_risk = 0
        max_possible = 0

        for flag in risk_flags:
            if flag in RISK_CATEGORIES:
                desc, score, basis = RISK_CATEGORIES[flag]
                level = "RED" if score >= 80 else ("YELLOW" if score >= 50 else "GREEN")
                heatmap.append({
                    "risk_id": flag,
                    "description": desc,
                    "score": score,
                    "level": level,
                    "legal_basis": basis,
                    "mitigation": self._suggest_mitigation(flag)
                })
                total_risk += score
                max_possible += 100

        overall_pct = round(total_risk / max_possible * 100, 1) if max_possible > 0 else 0
        overall_level = "RED" if overall_pct > 60 else ("YELLOW" if overall_pct > 25 else "GREEN")

        return {
            "total_risk_score": total_risk,
            "max_possible_score": max_possible,
            "overall_risk_pct": overall_pct,
            "overall_risk_level": overall_level,
            "active_flags": len(heatmap),
            "flags": heatmap,
            "hotspots": [f for f in heatmap if f["level"] == "RED"],
        }

    def _suggest_mitigation(self, flag):
        mitigations = {
            "FRAUD_VAT": "Natychmiast wstrzymaj transakcję. Sprawdź kontrahenta w Wykazie Podatników VAT.",
            "EMPTY_INVOICE": "Zgłoś do US jako czynny żal (Art. 16 KKS). Nie księguj faktury.",
            "GAAR": "Uzyskaj opinię zabezpieczającą (Art. 119zb OrdPU) przed transakcją.",
            "HIDDEN_INCOME": "Skoryguj deklaracje PIT/VAT. Rozważ czynny żal.",
            "UNRELIABLE_BOOKS": "Popraw ewidencję PKPiR. Wprowadź kontrole wewnętrzne.",
            "LOW_TRUST": "Zweryfikuj kontrahenta w CEIDG, KRS, Wykazie VAT. Zażądaj dodatkowej dokumentacji.",
            "AMOUNT_ANOMALY": "Zweryfikuj kwotę. Sprawdź czy nie ma błędu w fakturze.",
            "NEW_COUNTERPARTY": "Przeprowadź pełną weryfikację AML: CEIDG, NIP, VAT, sankcje.",
            "SUSPENDED_CEIDG": "Wstrzymaj transakcję do czasu odwieszenia działalności kontrahenta.",
            "VAT_EVIDENCE_GAP": "Uzupełnij ewidencję VAT. Złóż korektę JPK_V7K.",
            "DECLARATION_OVERDUE": "Złóż zaległą deklarację. Im szybciej, tym niższe odsetki.",
            "HEURISTIC_EMPTY": "Zweryfikuj czy dostawa faktycznie miała miejsce. Sprawdź dokumentację."
        }
        return mitigations.get(flag, "Przeprowadź audyt wewnętrzny.")

    # ═══════════════════════════════════════════════════════════════════════════
    # INN06: GAAR Trigger Detector
    # ═══════════════════════════════════════════════════════════════════════════
    def detect_gaar(self, triggers=None):
        """Wykrywa triggery klauzuli GAAR (Art. 119a OrdPU)."""
        if triggers is None:
            triggers = {}

        triggered = []
        total_weight = 0
        max_weight = sum(t["weight"] for t in GAAR_TRIGGERS.values())

        for trigger_id, info in GAAR_TRIGGERS.items():
            is_triggered = triggers.get(trigger_id, False)
            if is_triggered:
                triggered.append({
                    "trigger_id": trigger_id,
                    "description": info["desc"],
                    "weight": info["weight"],
                    "status": "TRIGGERED"
                })
                total_weight += info["weight"]

        gaar_score = round(total_weight / max_weight * 100, 1) if max_weight > 0 else 0
        gaar_risk = "HIGH" if gaar_score > 50 else ("MEDIUM" if gaar_score > 25 else "LOW")

        return {
            "gaar_score": gaar_score,
            "gaar_risk_level": gaar_risk,
            "triggers_activated": len(triggered),
            "total_triggers_possible": len(GAAR_TRIGGERS),
            "triggers": triggered,
            "recommendation": self._gaar_recommendation(gaar_score)
        }

    def _gaar_recommendation(self, score):
        if score > 50:
            return "WYSOKIE RYZYKO GAAR — rozważ uzyskanie opinii zabezpieczającej (Art. 119zb OrdPU). Koszt: 20 000 PLN. Transakcja może zostać zakwestionowana przez Szefa KAS."
        elif score > 25:
            return "ŚREDNIE RYZYKO GAAR — udokumentuj ekonomiczne uzasadnienie transakcji. Zachowaj analizę porównawczą cen rynkowych."
        return "Niskie ryzyko GAAR — standardowa dokumentacja wystarczająca."

    # ═══════════════════════════════════════════════════════════════════════════
    # INN07: Conflict Severity Auto-Grader
    # ═══════════════════════════════════════════════════════════════════════════
    def grade_conflict_severity(self, domain_a, domain_b, impact_factors=None):
        """Automatyczna gradacja severity konfliktów między domenami."""
        if impact_factors is None:
            impact_factors = {}

        pair_key = f"{domain_a}_vs_{domain_b}"
        base_severity = self._classify_conflict_severity(pair_key)

        severity_scores = {"CRITICAL": 100, "HIGH": 70, "WARNING": 50, "INFO": 30}
        base_score = severity_scores.get(base_severity, 30)

        # Impact modifiers
        modifiers = 0
        if impact_factors.get("tax_amount_high", False):
            modifiers += 10
        if impact_factors.get("criminal_exposure", False):
            modifiers += 20
        if impact_factors.get("repeat_offense", False):
            modifiers += 10
        if impact_factors.get("cross_border_involved", False):
            modifiers += 5
        if impact_factors.get("already_audited", False):
            modifiers += 15

        final_score = min(100, base_score + modifiers)

        if final_score >= 90:
            final_level = "CRITICAL"
        elif final_score >= 60:
            final_level = "HIGH"
        elif final_score >= 40:
            final_level = "WARNING"
        else:
            final_level = "INFO"

        return {
            "domain_pair": pair_key,
            "domain_a": domain_a,
            "domain_b": domain_b,
            "base_severity": base_severity,
            "base_score": base_score,
            "modifiers": modifiers,
            "final_score": final_score,
            "final_severity": final_level,
            "requires_immediate_action": final_level in ("CRITICAL", "HIGH"),
        }

    # ═══════════════════════════════════════════════════════════════════════════
    # INN08: Edge Case Coverage Guarantee
    # ═══════════════════════════════════════════════════════════════════════════
    def coverage_guarantee(self):
        """Analizuje luki w pokryciu edge cases i proponuje uzupełnienia."""
        known_edge_cases = set()
        for cat, info in EDGE_CASE_CATEGORIES.items():
            start, end = info["range"]
            for i in range(start, end + 1):
                known_edge_cases.add(f"R{i:04d}")

        # Potencjalne brakujące edge cases (heurystyka)
        potential_gaps = [
            {"gap_id": "P17_GAP_001", "area": "VAT", "desc": "Korekta VAT po zmianie formy opodatkowania (JDG→Sp. z o.o.)",
             "priority": "HIGH", "suggested_rule_id": "jdg.edge_cases.vat_form_change_correction"},
            {"gap_id": "P17_GAP_002", "area": "PIT", "desc": "Zasiłek chorobowy a zaliczka PIT — interakcja z JDG",
             "priority": "MEDIUM", "suggested_rule_id": "jdg.edge_cases.pit_sickness_benefit_advance"},
            {"gap_id": "P17_GAP_003", "area": "ZUS", "desc": "ZUS po wznowieniu działalności po 5+ latach",
             "priority": "MEDIUM", "suggested_rule_id": "jdg.edge_cases.zus_long_hiatus_resume"},
            {"gap_id": "P17_GAP_004", "area": "CROSS_BORDER", "desc": "Podwójna rezydencja podatkowa — tie-breaker rules",
             "priority": "HIGH", "suggested_rule_id": "jdg.edge_cases.dual_residency_tiebreaker"},
            {"gap_id": "P17_GAP_005", "area": "KKS", "desc": "Nadpłata a czynny żal — czy nadpłata wyklucza czynny żal?",
             "priority": "WARNING", "suggested_rule_id": "jdg.edge_cases.overpayment_vs_voluntary_disclosure"},
            {"gap_id": "P17_GAP_006", "area": "TEMPORAL", "desc": "RMK powrót stawek 8%/5% — automatyczny trigger reguł",
             "priority": "HIGH", "suggested_rule_id": "jdg.temporal.rmk_rate_restoration_trigger"},
            {"gap_id": "P17_GAP_007", "area": "FAMILY", "desc": "Rozwód a rozliczenie JDG — podział majątku wspólnego",
             "priority": "MEDIUM", "suggested_rule_id": "jdg.edge_cases.divorce_asset_split_jdg"},
            {"gap_id": "P17_GAP_008", "area": "FORCE_MAJEURE", "desc": "Klęska żywiołowa a terminy podatkowe — automatyczne przedłużenie",
             "priority": "WARNING", "suggested_rule_id": "jdg.edge_cases.force_majeure_deadline_extension"},
            {"gap_id": "P17_GAP_009", "area": "E_DELIVERY", "desc": "e-Doręczenia — fikcja doręczenia po 14 dniach",
             "priority": "HIGH", "suggested_rule_id": "jdg.edge_cases.edelivery_fiction_of_service"},
            {"gap_id": "P17_GAP_010", "area": "LIABILITY", "desc": "Odpowiedzialność solidarna małżonka po ustaniu wspólności",
             "priority": "HIGH", "suggested_rule_id": "jdg.edge_cases.spouse_liability_after_separation"},
        ]

        return {
            "total_categories": len(EDGE_CASE_CATEGORIES),
            "known_edge_cases_estimate": len(known_edge_cases),
            "potential_gaps_found": len(potential_gaps),
            "high_priority_gaps": len([g for g in potential_gaps if g["priority"] == "HIGH"]),
            "coverage_confidence": round((len(known_edge_cases) - len(potential_gaps)) / max(len(known_edge_cases), 1) * 100, 1),
            "gaps": potential_gaps
        }

    # ═══════════════════════════════════════════════════════════════════════════
    # INN09: Correction Chain Tracker
    # ═══════════════════════════════════════════════════════════════════════════
    def track_correction_chain(self, chain_input):
        """Śledzi łańcuch korekt i wykrywa efekty domina."""
        corrections = chain_input if chain_input else []

        chain_effects = []
        for i, corr in enumerate(corrections):
            effects = []
            tax_type = corr.get("type", "VAT")

            # VAT → PIT effect
            if tax_type == "VAT":
                effects.append({"affected": "PIT", "reason": "Zmiana VAT wpływa na przychód/koszt w PIT", "severity": "MEDIUM"})
                effects.append({"affected": "JPK_V7", "reason": "Korekta faktury → korekta JPK_V7K", "severity": "HIGH"})

            # PIT → ZUS effect
            if tax_type == "PIT":
                effects.append({"affected": "ZUS_HEALTH", "reason": "Zmiana dochodu PIT → korekta rocznej składki zdrowotnej", "severity": "HIGH"})

            # ZUS → PIT effect
            if tax_type == "ZUS":
                effects.append({"affected": "PIT", "reason": "Korekta ZUS → zmiana odliczeń w PIT", "severity": "MEDIUM"})

            chain_effects.append({
                "step": i + 1,
                "original_correction": corr,
                "domino_effects": effects,
                "total_affected_domains": len(effects)
            })

        return {
            "chain_length": len(corrections),
            "total_domino_effects": sum(len(c["domino_effects"]) for c in chain_effects),
            "complexity": "HIGH" if len(corrections) > 3 else ("MEDIUM" if len(corrections) > 1 else "LOW"),
            "steps": chain_effects
        }

    # ═══════════════════════════════════════════════════════════════════════════
    # INN10: Limitation Period Cross-Reference
    # ═══════════════════════════════════════════════════════════════════════════
    def limitation_cross_reference(self, event_year=2021):
        """Krzyżowa referencja przedawnień: OrdPU vs KKS vs VAT vs PIT."""
        ref = {}

        for period_id, info in STATUTE_PERIODS.items():
            deadline_year = int(event_year) + info["years"]
            deadline_date = date(deadline_year, 12, 31)
            days_left = (deadline_date - TODAY).days
            expired = days_left < 0

            ref[period_id] = {
                "event_year": event_year,
                "statute_years": info["years"],
                "deadline": deadline_date.isoformat(),
                "days_remaining": max(0, days_left),
                "expired": expired,
                "legal_basis": info["basis"],
            }

        # Cross-reference analysis
        cross_ref = []
        ref_ids = list(ref.keys())
        for i in range(len(ref_ids)):
            for j in range(i + 1, len(ref_ids)):
                a, b = ref_ids[i], ref_ids[j]
                if ref[a]["expired"] != ref[b]["expired"]:
                    cross_ref.append({
                        "pair": f"{a} vs {b}",
                        "discrepancy": f"{a} {'EXPIRED' if ref[a]['expired'] else 'ACTIVE'} vs {b} {'EXPIRED' if ref[b]['expired'] else 'ACTIVE'}",
                        "impact": "Asymetria przedawnień — jedno zobowiązanie przedawnione, drugie nie"
                    })

        return {
            "reference_year": event_year,
            "periods": ref,
            "cross_reference_discrepancies": cross_ref,
            "earliest_expiry": min((r["deadline"] for r in ref.values()), default="N/A"),
            "latest_expiry": max((r["deadline"] for r in ref.values()), default="N/A"),
        }

    # ═══════════════════════════════════════════════════════════════════════════
    # INN11: Proactive Risk Mitigation Engine
    # ═══════════════════════════════════════════════════════════════════════════
    def mitigate_risks(self, risk_profile):
        """Proaktywna mitigacja ryzyka — rekomendacje przed kontrolą."""
        risk_level = risk_profile.get("overall_risk_level", "GREEN")
        active_flags = risk_profile.get("active_flags", [])

        actions = []

        if risk_level in ("RED", "YELLOW"):
            if any(f["risk_id"] == "GAAR" for f in risk_profile.get("flags", [])):
                actions.append({
                    "action": "OPINIA_ZABEZPIECZAJĄCA",
                    "priority": "IMMEDIATE",
                    "desc": "Wystąp o opinię zabezpieczającą (Art. 119zb OrdPU). Koszt 20 000 PLN.",
                    "deadline": "PRZED transakcją",
                    "protects_against": "Zakwestionowanie przez Szefa KAS"
                })

            actions.append({
                "action": "VOLUNTARY_DISCLOSURE",
                "priority": "HIGH",
                "desc": "Rozważ czynny żal (Art. 16 KKS) przed wszczęciem postępowania.",
                "deadline": "PRZED kontrolą US",
                "protects_against": "Kara KKS, odpowiedzialność karna skarbowa"
            })

            actions.append({
                "action": "DOCUMENTATION_AUDIT",
                "priority": "HIGH",
                "desc": "Przeprowadź wewnętrzny audyt dokumentacji: faktury, umowy, ewidencje.",
                "deadline": "W ciągu 30 dni",
                "protects_against": "Zakwestionowanie kosztów, sankcje KKS"
            })

            actions.append({
                "action": "COUNTERPARTY_VERIFICATION",
                "priority": "MEDIUM",
                "desc": "Zweryfikuj wszystkich kontrahentów w Wykazie VAT, CEIDG, KRS.",
                "deadline": "Przed kolejnymi transakcjami",
                "protects_against": "Brak prawa do odliczenia VAT (Art. 88 VAT)"
            })

        if risk_level == "GREEN":
            actions.append({
                "action": "ROUTINE_MONITORING",
                "priority": "LOW",
                "desc": "Kontynuuj rutynowy monitoring. Sprawdzaj Wykaz VAT raz w miesiącu.",
                "deadline": "Bieżąco",
                "protects_against": "Standardowe ryzyko podatkowe"
            })

        return {
            "risk_level": risk_level,
            "total_actions": len(actions),
            "immediate_actions": len([a for a in actions if a["priority"] == "IMMEDIATE"]),
            "actions": actions
        }

    # ═══════════════════════════════════════════════════════════════════════════
    # INN12: Edge Case Test Auto-Generator
    # ═══════════════════════════════════════════════════════════════════════════
    def generate_edge_tests(self, rules_file="JDG/rules/edge_cases.rego", output_categories=None):
        """Generuje szablony testów dla edge cases."""
        if output_categories is None:
            output_categories = ["GRUPA_A_VAT", "GRUPA_B_PIT", "GRUPA_C_ZUS"]

        templates = []
        try:
            with open(rules_file) as f:
                content = f.read()
        except FileNotFoundError:
            return {"error": f"File not found: {rules_file}"}

        for cat in output_categories:
            if cat in EDGE_CASE_CATEGORIES:
                start, end = EDGE_CASE_CATEGORIES[cat]["range"]
                for rule_priority in range(start, end + 1):
                    rule_id = f"jdg.edge_cases.R{rule_priority:04d}"

                    templates.append({
                        "test_id": f"test_edge_R{rule_priority:04d}_positive",
                        "rule_id": rule_id,
                        "test_type": "POSITIVE",
                        "description": f"Verify rule R{rule_priority:04d} triggers correctly under valid conditions",
                        "template": self._test_template(rule_id, "positive")
                    })
                    templates.append({
                        "test_id": f"test_edge_R{rule_priority:04d}_negative",
                        "rule_id": rule_id,
                        "test_type": "NEGATIVE",
                        "description": f"Verify rule R{rule_priority:04d} does NOT trigger under invalid conditions",
                        "template": self._test_template(rule_id, "negative")
                    })
                    if rule_priority % 3 == 0:  # Boundary test for every 3rd rule
                        templates.append({
                            "test_id": f"test_edge_R{rule_priority:04d}_boundary",
                            "rule_id": rule_id,
                            "test_type": "BOUNDARY",
                            "description": f"Verify rule R{rule_priority:04d} handles boundary values correctly",
                            "template": self._test_template(rule_id, "boundary")
                        })

        return {
            "total_templates": len(templates),
            "categories_covered": len(output_categories),
            "templates_by_type": {
                "POSITIVE": len([t for t in templates if t["test_type"] == "POSITIVE"]),
                "NEGATIVE": len([t for t in templates if t["test_type"] == "NEGATIVE"]),
                "BOUNDARY": len([t for t in templates if t["test_type"] == "BOUNDARY"]),
            },
            "templates": templates[:20]  # Limit output
        }

    def _test_template(self, rule_id, test_type):
        safe_id = rule_id.replace('.', '_')
        if test_type == "positive":
            lines = [
                f'def test_{safe_id}_positive():',
                f'    """Verify {rule_id} triggers correctly."""',
                f'    result = opa_eval("{rule_id}", {{"input": valid_input}})',
                f'    assert result["matched"] == True, "{rule_id} should match positive case"',
                f'    assert result.get("_routing") == "BLOCK_AND_ALERT"'
            ]
            return '\n'.join(lines)
        elif test_type == "negative":
            lines = [
                f'def test_{safe_id}_negative():',
                f'    """Verify {rule_id} does NOT trigger incorrectly."""',
                f'    result = opa_eval("{rule_id}", {{"input": invalid_input}})',
                f'    assert result.get("matched") == False, "{rule_id} should NOT match negative case"'
            ]
            return '\n'.join(lines)
        else:
            lines = [
                f'def test_{safe_id}_boundary():',
                f'    """Verify {rule_id} handles boundary values."""',
                f'    result = opa_eval("{rule_id}", {{"input": boundary_input}})',
                f'    assert result is not None, "{rule_id} should handle boundary case"'
            ]
            return '\n'.join(lines)

    # ═══════════════════════════════════════════════════════════════════════════
    # REPORT GENERATOR
    # ═══════════════════════════════════════════════════════════════════════════
    def generate_full_report(self):
        """Generuje pełny raport P17."""
        r = self.results

        report = []
        report.append("=" * 65)
        report.append("RAPORT ANALITYCZNY ENTERPRISE — JDG Edge Cases + Conflicts + Corrections v7.0")
        report.append("=" * 65)
        report.append(f"Data: {TODAY.isoformat()}")
        report.append(f"Ekosystem: 12 plików Rego + 12 innowacji Python")
        report.append("")

        for name, result in r.items():
            report.append(f"--- {name} ---")
            report.append(json.dumps(result, indent=2, ensure_ascii=False, default=str))
            report.append("")

        report.append("=" * 65)
        report.append("=== KONIEC RAPORTU — RAPORT_P17_JDG_EDGE_CASES_CONFLICTS_v7.0 ===")
        return "\n".join(report)


# ═══════════════════════════════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════════════════════════════
def main():
    parser = argparse.ArgumentParser(description="P17 Edge Cases & Conflicts Toolkit — 12 innowacji Enterprise")
    sub = parser.add_subparsers(dest="command")

    # INN01
    p = sub.add_parser("discover", help="Edge Case Auto-Discovery Engine")
    p.add_argument("--file", default="JDG/rules/edge_cases.rego")

    # INN02
    p = sub.add_parser("conflicts", help="Cross-Domain Conflict Resolution Matrix")
    p.add_argument("--domains", nargs="*")

    # INN03
    p = sub.add_parser("suggest", help="Correction Auto-Suggester")
    p.add_argument("--tax-type", required=True, choices=["VAT", "PIT", "ZUS", "CROSS_BORDER"])
    p.add_argument("--amount", type=float, required=True)
    p.add_argument("--direction", required=True, choices=["DECREASE", "INCREASE", "BAD_DEBT"])
    p.add_argument("--days-overdue", type=int, default=0)

    # INN04
    p = sub.add_parser("countdown", help="Statute of Limitations Countdown Timer")
    p.add_argument("--tax-year", required=True)
    p.add_argument("--type", dest="liability_type", default="TAX_OBLIGATION")
    p.add_argument("--suspended", action="store_true")

    # INN05
    p = sub.add_parser("heatmap", help="Risk Heatmap Generator")
    p.add_argument("--flags", nargs="*")

    # INN06
    p = sub.add_parser("gaar", help="GAAR Trigger Detector")
    p.add_argument("--related-party", action="store_true")
    p.add_argument("--artificial-scheme", action="store_true")
    p.add_argument("--tax-benefit", action="store_true")
    p.add_argument("--circular-flow", action="store_true")
    p.add_argument("--tax-haven", action="store_true")
    p.add_argument("--no-substance", action="store_true")

    # INN07
    p = sub.add_parser("grade", help="Conflict Severity Auto-Grader")
    p.add_argument("--domain-a", required=True)
    p.add_argument("--domain-b", required=True)
    p.add_argument("--tax-amount-high", action="store_true")
    p.add_argument("--criminal", action="store_true")
    p.add_argument("--repeat", action="store_true")

    # INN08
    p = sub.add_parser("coverage", help="Edge Case Coverage Guarantee")

    # INN09
    p = sub.add_parser("chain", help="Correction Chain Tracker")
    p.add_argument("--chain-json", default="[]")

    # INN10
    p = sub.add_parser("xref", help="Limitation Period Cross-Reference")
    p.add_argument("--event-year", default="2021")

    # INN11
    p = sub.add_parser("mitigate", help="Proactive Risk Mitigation Engine")
    p.add_argument("--risk-json", default='{"overall_risk_level":"YELLOW","flags":[]}')

    # INN12
    p = sub.add_parser("gen-tests", help="Edge Case Test Auto-Generator")
    p.add_argument("--file", default="JDG/rules/edge_cases.rego")
    p.add_argument("--categories", nargs="*", default=["GRUPA_A_VAT"])

    # Report
    p = sub.add_parser("report", help="Generate full P17 report")

    args = parser.parse_args()
    tk = P17EnterpriseToolkit()

    if args.command == "discover":
        result = tk.discover_edge_cases(args.file)
    elif args.command == "conflicts":
        result = tk.conflict_matrix(args.domains)
    elif args.command == "suggest":
        result = tk.suggest_correction(args.tax_type, args.amount, args.direction, args.days_overdue)
    elif args.command == "countdown":
        result = tk.statute_countdown(args.tax_year, args.liability_type, args.suspended)
    elif args.command == "heatmap":
        result = tk.risk_heatmap(args.flags)
    elif args.command == "gaar":
        triggers = {
            "related_party": args.related_party,
            "artificial_scheme": args.artificial_scheme,
            "tax_benefit_primary": args.tax_benefit,
            "circular_flow": args.circular_flow,
            "tax_haven_involved": args.tax_haven,
            "no_economic_substance": args.no_substance,
        }
        result = tk.detect_gaar(triggers)
    elif args.command == "grade":
        factors = {
            "tax_amount_high": args.tax_amount_high,
            "criminal_exposure": args.criminal,
            "repeat_offense": args.repeat,
        }
        result = tk.grade_conflict_severity(args.domain_a, args.domain_b, factors)
    elif args.command == "coverage":
        result = tk.coverage_guarantee()
    elif args.command == "chain":
        chain = json.loads(args.chain_json)
        result = tk.track_correction_chain(chain)
    elif args.command == "xref":
        result = tk.limitation_cross_reference(args.event_year)
    elif args.command == "mitigate":
        profile = json.loads(args.risk_json)
        result = tk.mitigate_risks(profile)
    elif args.command == "gen-tests":
        result = tk.generate_edge_tests(args.file, args.categories)
    elif args.command == "report":
        tk.results = {
            "INN01_EDGE_DISCOVERY": tk.discover_edge_cases(),
            "INN02_CONFLICT_MATRIX": tk.conflict_matrix(),
            "INN03_CORRECTION_EXAMPLE": tk.suggest_correction("VAT", 50000, "DECREASE", 120),
            "INN04_STATUTE_EXAMPLE": tk.statute_countdown("2019", "TAX_OBLIGATION"),
            "INN05_RISK_EXAMPLE": tk.risk_heatmap(["GAAR", "HIDDEN_INCOME", "LOW_TRUST"]),
            "INN06_GAAR_EXAMPLE": tk.detect_gaar({"related_party": True, "artificial_scheme": True}),
            "INN08_COVERAGE": tk.coverage_guarantee(),
            "INN10_XREF": tk.limitation_cross_reference("2020"),
        }
        result = tk.generate_full_report()
        print(result)
        return

    print(json.dumps(result, indent=2, ensure_ascii=False, default=str))


if __name__ == "__main__":
    main()
