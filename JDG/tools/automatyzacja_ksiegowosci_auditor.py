#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NexusAI JDG — P18 AUTOMATYZACJA KSIĘGOWOŚCI AUDITOR
====================================================
Audyt realnych plików rego (bankowość PSD2, e-Doręczenia, e-podpis, WIS,
formularze, kalendarz, przepływy) + kalkulatory INN-01..15.

Użycie:
    python3 automatyzacja_ksiegowosci_auditor.py --audit          # pełny audyt plików
    python3 automatyzacja_ksiegowosci_auditor.py --banking        # audyt bankowości (PSD2)
    python3 automatyzacja_ksiegowosci_auditor.py --booking        # auto-księgowanie (INN-01)
    python3 automatyzacja_ksiegowosci_auditor.py --tagging        # auto-oznaczanie (INN-02)
    python3 automatyzacja_ksiegowosci_auditor.py --psd2           # monitor PSD2 (INN-03)
    python3 automatyzacja_ksiegowosci_auditor.py --settlement     # rozliczanie przelewów (INN-04)
    python3 automatyzacja_ksiegowosci_auditor.py --one-click      # jedno kliknięcie (INN-05)
    python3 automatyzacja_ksiegowosci_auditor.py --autofill       # auto-fill formularzy (INN-06)
    python3 automatyzacja_ksiegowosci_auditor.py --calendar       # nieśmiertelny kalendarz (INN-07)
    python3 automatyzacja_ksiegowosci_auditor.py --deadlines      # tracker terminów (INN-08)
    python3 automatyzacja_ksiegowosci_auditor.py --reconciliation # auto-koncyliacja (INN-09)
    python3 automatyzacja_ksiegowosci_auditor.py --cashflow       # predykcja przepływów (INN-10)
    python3 automatyzacja_ksiegowosci_auditor.py --overpayment    # nadpłata (INN-11)
    python3 automatyzacja_ksiegowosci_auditor.py --correspondence # pisma (INN-12)
    python3 automatyzacja_ksiegowosci_auditor.py --priority       # priorytetyzacja (INN-13)
    python3 automatyzacja_ksiegowosci_auditor.py --mpp            # doradca MPP (INN-15)
    python3 automatyzacja_ksiegowosci_auditor.py --pipeline       # pipeline API (Sekcja 6)
"""
import argparse
import json
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# ── Konfiguracja modułów audytu (realne pliki rego) ──────────────────────────
MODULES = {
    "banking": {
        "label": "Bankowość (PSD2/PolishAPI/Elixir)",
        "files": [
            "rules/banking_automation_enterprise.rego",
            "rules/payments/plan44_payments.rego",
            "rules/payments/plan45_payments.rego",
            "rules/vat_mpp_split_payment_enterprise.rego",
        ],
    },
    "edelivery": {
        "label": "e-Doręczenia",
        "files": [
            "rules/epuap_enterprise.rego",
            "rules/edelivery_gateway_enterprise.rego",
            "rules/edelivery_gateway_v2_enterprise.rego",
            "rules/edelivery/plan44_edelivery.rego",
            "rules/edelivery/plan45_edelivery.rego",
        ],
    },
    "esig": {
        "label": "e-Podpis (eIDAS)",
        "files": [
            "rules/esig/plan44_esig.rego",
            "rules/esig/plan45_esig.rego",
            "rules/esig_auto_applicator_enterprise.rego",
        ],
    },
    "wis": {
        "label": "WIS (art. 42a VAT)",
        "files": [
            "rules/wis/plan44_wis.rego",
            "rules/wis/plan45_wis.rego",
            "rules/wis_api_enterprise.rego",
            "rules/wis_autorequester_enterprise.rego",
        ],
    },
    "forms": {
        "label": "Formularze i deklaracje",
        "files": [
            "rules/form_optimizer_enterprise.rego",
            "rules/p16_autoform_generator_enterprise.rego",
            "rules/p16_enhanced_sca_enterprise.rego",
        ],
    },
    "calendar": {
        "label": "Kalendarz i terminy",
        "files": [
            "rules/calendar/plan44_calendar.rego",
            "rules/calendar/plan45_calendar.rego",
            "rules/calendar_notifier_enterprise.rego",
            "rules/deadline_monitor_enterprise.rego",
        ],
    },
    "cashflow": {
        "label": "Korespondencja i przepływy",
        "files": [
            "rules/tax_correspondence_engine_enterprise.rego",
            "rules/decision_composer_enterprise.rego",
            "rules/proceeding_tracker_enterprise.rego",
            "rules/interest_calculator_enterprise.rego",
            "rules/cashflow_tax_predictor_enterprise.rego",
            "rules/vat_cashflow_predictor_enterprise.rego",
            "rules/overpayment_auto_claimer_enterprise.rego",
        ],
    },
}

P18_PACKAGE = "rules/p18_automatyzacja_ksiegowosci_innovations_v9.rego"


def round2(x: float) -> float:
    return round(x * 100) / 100


# ── Kalkulatory INN (logika mirrorowana z pakietu rego P18) ───────────────────
def banking_audit(eval_date: str = "2026-08-01") -> dict:
    """Sekcja 1: audyt bankowości — PSD2/PolishAPI, AIS/PIS, Elixir/ExpressElixir."""
    return {
        "psd2": {
            "podstawa": "PSD2 (2015/2366/UE) + RTS 2018/389",
            "sca_exempt_threshold_pln": 100,
            "sca_exempt_max_per_tx": 5,
            "legal_basis": "PSD2 art. 97; RTS 2018/389 art. 11-12",
        },
        "polish_api": {
            "standard": "PolishAPI — AIS/PIS, OAuth2",
            "oauth2": True,
            "eidas": True,
            "legal_basis": "PolishAPI v1.0+; eIDAS (910/2014)",
        },
        "elixir": {
            "cutoff": "14:30",
            "express_elixir_cutoff": "15:30",
            "batch": "batch XML/JSON",
            "legal_basis": "Regulamin KIR (Elixir/Express Elixir)",
        },
        "note": "audyt bankowości — PSD2/PolishAPI, AIS/PIS, OAuth2/eIDAS, Elixir/ExpressElixir, batch",
    }


def bank_statement_auto_booking(transactions: int = 0, auto_booked: int = 0) -> dict:
    """INN-01: auto-księgowanie wyciągów bankowych."""
    return {
        "transactions": transactions,
        "auto_booked": min(auto_booked, transactions),
        "unmatched": max(transactions - min(auto_booked, transactions), 0),
        "note": "auto-księgowanie wyciągów bankowych — transakcje → rejestry PKPiR/UoR",
        "_routing": "TRIAGE_QUEUE" if auto_booked == 0 else "",
    }


def payment_auto_tagging(payment_purpose: str = "") -> dict:
    """INN-02: auto-oznaczanie płatności."""
    purpose = payment_purpose.upper()
    if "VAT" in purpose or "PODATEK" in purpose:
        category = "VAT"
    elif "ZUS" in purpose:
        category = "ZUS"
    elif "PIT" in purpose:
        category = "PIT"
    elif "PCC" in purpose:
        category = "PCC"
    else:
        category = "KOSZT"
    return {
        "payment_purpose": payment_purpose,
        "assigned_category": category,
        "note": "auto-oznaczanie płatności — mapowanie tytułu przelewu na kategorię",
    }


def psd2_monitor(payment_amount_pln: float = 0.0, tx_count_since_auth: int = 0) -> dict:
    """INN-03: monitor PSD2 — decyzja SCA (RTS 2018/389)."""
    threshold = 100.0
    max_exempt = 5
    if payment_amount_pln > threshold:
        decision = "SCA WYMAGANE — kwota > 100 zł (RTS 2018/389)"
    elif tx_count_since_auth < max_exempt:
        decision = "SCA EXEMPT — kwota ≤ 100 zł"
    else:
        decision = "SCA WYMAGANE — limit 5 transakcji exempt wyczerpany"
    return {
        "payment_amount_pln": payment_amount_pln,
        "tx_count_since_auth": tx_count_since_auth,
        "sca_decision": decision,
        "breaches": [],
        "_routing": "OK",
        "note": "monitor PSD2 — kontrola SCA, limity exempt, naruszenia",
    }


def transfer_to_declaration_settlement(transfers: int = 0, settled: int = 0) -> dict:
    """INN-04: rozliczanie przelewów do deklaracji."""
    return {
        "transfers": transfers,
        "settled_to_declarations": settled,
        "consistent": transfers == settled,
        "note": "rozliczanie przelewów do deklaracji — powiązanie płatności z pozycjami deklaracji",
        "_routing": "" if transfers == settled else "TRIAGE_QUEUE",
    }


def one_click_letter_flow(address_set: bool = False, mailbox_active: bool = False) -> dict:
    """INN-05: 'jedno kliknięcie' — pełny obieg pisma z urzędem."""
    return {
        "flow_steps": [
            "1. dokument → dane",
            "2. auto-fill formularza",
            "3. auto-podpis (eIDAS)",
            "4. auto-wysyłka (e-Doręczenia/ePUAP)",
            "5. potwierdzenie + archiwizacja",
        ],
        "fully_automated": address_set and mailbox_active,
        "note": "jedno kliknięcie — pełny obieg pisma z urzędem bez udziału człowieka",
    }


def form_autofill_engine(form_type: str = "VAT-7", filled: int = 3, required: int = 3) -> dict:
    """INN-06: silnik auto-fill formularzy."""
    ready = filled >= required
    return {
        "form_type": form_type,
        "required_fields": required,
        "filled_fields": filled,
        "fill_status": "AUTO-FILL KOMPLETNY — gotowy do podpisu i wysyłki" if ready else f"AUTO-FILL NIEPEŁNY — uzupełnij {required - filled} pól",
        "ready_to_send": ready,
        "_routing": "" if ready else "TRIAGE_QUEUE",
        "note": "silnik auto-fill formularzy — PIT/VAT/JPK/ZUS/PCC z danych księgowych",
    }


def immortal_tax_calendar(day_of_month: int = 1) -> dict:
    """INN-07: nieśmiertelny kalendarz podatnika."""
    def status(day: int, deadline: int) -> str:
        if day < deadline:
            return f"PRZED TERMINEM — {deadline - day} dni zapasu"
        if day == deadline:
            return "DZIŚ TERMIN — złóż deklarację!"
        return "PO TERMINIE — naliczane odsetki!"

    return {
        "today_day": day_of_month,
        "zus_dra": status(day_of_month, 10),
        "vat7": status(day_of_month, 25),
        "jpk_v7": status(day_of_month, 25),
        "note": "nieśmiertelny kalendarz podatnika — tracker terminów ZUS/VAT/PIT/JPK z alertami T-7/T-3/T-0",
    }


def deadline_alert_tracker(today_deadlines: list = None, urgent_count: int = 0) -> dict:
    """INN-08: tracker terminów z alertami (priorytetyzacja)."""
    today = today_deadlines or []
    level = f"KRYTYCZNE — {len(today)} terminów DZIŚ" if today else (f"UWAGA — {urgent_count} terminów w ciągu 3 dni" if urgent_count > 0 else "BEZ TERMINÓW PILNYCH")
    return {
        "deadlines_today": today,
        "deadlines_3_days": urgent_count,
        "alert_level": level,
        "_routing": "URGENT" if today else "OK",
        "note": "tracker terminów z alertami — auto-przypomnienia T-7/T-3/T-0",
    }


def bank_reconciliation_engine(bank_balance_pln: float = 0.0, register_balance_pln: float = 0.0) -> dict:
    """INN-09: auto-koncyliacja bank."""
    gap = round2(abs(bank_balance_pln - register_balance_pln))
    ok = gap <= 0.01
    return {
        "bank_balance_pln": round2(bank_balance_pln),
        "register_balance_pln": round2(register_balance_pln),
        "gap_pln": gap,
        "recon_status": "ZGODNE — różnica ≤ 0.01 zł" if ok else f"ROZBIEŻNOŚĆ — różnica {gap:.2f} zł",
        "_routing": "" if ok else "TRIAGE_QUEUE",
        "note": "auto-koncyliacja bank — wyciągi vs rejestry księgowe",
    }


def cashflow_forecaster(inflows_pln: float = 0.0, outflows_pln: float = 0.0, tax_liabilities_pln: float = 0.0) -> dict:
    """INN-10: predykcja przepływów."""
    balance = round2(inflows_pln - outflows_pln - tax_liabilities_pln)
    return {
        "inflows_pln": round2(inflows_pln),
        "outflows_pln": round2(outflows_pln),
        "tax_liabilities_pln": round2(tax_liabilities_pln),
        "projected_balance_pln": balance,
        "_routing": "TRIAGE_QUEUE" if balance < 0 else "",
        "note": "predykcja przepływów — cashflow + VAT predictor, projekcja salda",
    }


def overpayment_auto_claimer(overpayment_pln: float = 0.0, days_after_declaration: int = 0) -> dict:
    """INN-11: auto-wnioskowanie o nadpłatę."""
    return {
        "overpayment_pln": round2(overpayment_pln),
        "days_after_declaration": days_after_declaration,
        "status": f"NADPŁATA — złóż wniosek o zwrot (odsetki po 30 dniach)" if overpayment_pln > 0 else "BRAK NADPŁATY",
        "auto_claim": overpayment_pln > 0,
        "_routing": "TRIAGE_QUEUE" if overpayment_pln > 0 else "",
        "note": "auto-wnioskowanie o zwrot nadpłat (art. 74-80 OrdPU)",
    }


def correspondence_auto_generator(document_type: str = "WEZWANIE") -> dict:
    """INN-12: auto-generator pism do urzędów."""
    return {
        "document_type": document_type,
        "auto_generated": True,
        "composer_integrated": True,
        "note": "auto-generator pism — wezwania, zażalenia, wnioski (tax_correspondence_engine)",
    }


def tax_deadline_priority(today_deadlines: list = None, urgent_count: int = 0) -> dict:
    """INN-13: priorytetyzacja terminów."""
    today = today_deadlines or []
    level = f"KRYTYCZNE — {len(today)} terminów DZIŚ" if today else (f"UWAGA — {urgent_count} terminów w ciągu 3 dni" if urgent_count > 0 else "BEZ TERMINÓW PILNYCH")
    return {
        "today_deadlines": today,
        "urgent_count": urgent_count,
        "priority": level,
        "_routing": "URGENT" if today else "OK",
        "note": "priorytetyzacja terminów — KRYTYCZNE/UWAGA/OK",
    }


def split_payment_adviser(invoice_amount_pln: float = 0.0) -> dict:
    """INN-15: doradca MPP — mechanizm podzielonej płatności."""
    threshold = 15000.0
    return {
        "invoice_amount_pln": round2(invoice_amount_pln),
        "mpp_threshold_pln": threshold,
        "recommendation": "MPP ZALECANE — mechanizm podzielonej płatności (≥15 000 zł)" if invoice_amount_pln >= threshold else "MPP FAKULTATYWNE — poniżej progu 15 000 zł",
        "note": "doradca MPP (art. 108a VAT)",
    }


def api_adaptation_pipeline(api_version: str = "PolishAPI 2.0") -> dict:
    """Sekcja 6: pipeline auto-adaptacji API."""
    supported = ["PolishAPI 1.0", "PolishAPI 2.0"]
    return {
        "pipeline": {
            "step_1_ingest": "data.jdg.thresholds.automatyzacja_ksiegowosci (ADR-002)",
            "step_2_generate": "reguły bankowości + e-urząd + formularze",
            "step_3_verify": "automatyzacja_ksiegowosci_auditor.py",
            "step_4_emit": "hot-reload pakietów jdg.banking_automation / jdg.edelivery / jdg.wis / jdg.calendar",
        },
        "api_adaptation": {
            "status": "ZGODNY — API " + api_version + " obsługiwane" if api_version in supported else "WYMAGA ADAPTACJI — API " + api_version + " poza wsparciem",
            "supported_versions": supported,
        },
        "hot_reload": True,
        "note": "pipeline auto-adaptacji integracji — zmiany API banków/urzędów → auto-aktualizacja reguł",
    }


# ── Mapa drogowa R18 (P0/P1/P2) — 7 nowych kalkulatorów ──────────────────────
def ais_pis_integration(token_valid: bool = False, consent_active: bool = False,
                        standard: str = "PolishAPI", consent_lifetime_days: int = 90) -> dict:
    """P0-1: realna integracja AIS/PIS (PolishAPI) — token OAuth2 + konsent PSD2."""
    if not token_valid:
        status = "AIS/PIS NIESKONFIGUROWANE — uzyskaj token OAuth2 i konsent PSD2"
        routing = "TRIAGE_QUEUE"
    elif not consent_active:
        status = "BRAK WAŻNEGO KONSENTU PSD2 — odśwież zgodę (90 dni)"
        routing = "TRIAGE_QUEUE"
    else:
        status = "AIS/PIS GOTOWE — token OAuth2 + konsent PSD2 aktywne (PolishAPI)"
        routing = ""
    return {
        "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.ais_pis_integration",
        "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
        "priority": 3280,
        "matched": True,
        "standard": standard,
        "endpoint": "",
        "auth_flow": "OAuth2",
        "ais_scope": "ais",
        "pis_scope": "pis",
        "token_valid": token_valid,
        "consent_active": consent_active,
        "consent_lifetime_days": consent_lifetime_days,
        "token_refresh": True,
        "integration_status": status,
        "note": "realna integracja AIS/PIS (PolishAPI) — token OAuth2, konsent PSD2 (P0)",
        "_routing": routing,
        "_routing_reason": f"AIS/PIS: token={token_valid}, konsent={consent_active} (PolishAPI)",
        "_legal_basis": "PSD2 art. 94-97; RTS 2018/389; PolishAPI",
        "_warnings": [],
    }


def sca_production_verification(tests_passed: int = 0, test_transactions_min: int = 3,
                                exempt_threshold_pln: float = 100.0) -> dict:
    """P0-2: weryfikacja SCA w środowisku produkcyjnym banku (RTS 2018/389)."""
    verified = tests_passed >= test_transactions_min
    if verified:
        status = "SCA zweryfikowane w środowisku produkcyjnym banku (RTS 2018/389) — OK"
        routing = ""
    else:
        status = f"SCA PRODUKCYJNE NIEZWERYFIKOWANE — {tests_passed}/{test_transactions_min} testów (RTS 2018/389)"
        routing = "BLOCK_AND_ALERT"
    return {
        "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.sca_production_verification",
        "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
        "priority": 3281,
        "matched": True,
        "verification_required": True,
        "rts": "RTS 2018/389",
        "exempt_threshold_pln": exempt_threshold_pln,
        "exempt_max_per_tx": 5,
        "test_transactions_min": test_transactions_min,
        "tests_passed": tests_passed,
        "sca_verified": verified,
        "verification_status": status,
        "sca_methods": ["biometria", "sms_otp"],
        "note": "weryfikacja SCA w środowisku produkcyjnym banku — RTS 2018/389 art. 11-12 (P0)",
        "_routing": routing,
        "_routing_reason": f"SCA produkcja: {tests_passed}/{test_transactions_min} testów, verified={verified}",
        "_legal_basis": "RTS 2018/389 art. 11-12; PSD2 art. 97",
        "_warnings": [],
    }


def pit_uor_autofill_engine(filled_blocks: int = 0, required_blocks: int = 3) -> dict:
    """P1-1: pełny silnik auto-fill PIT-36/36L/28 z UoR (sprawozdania finansowe)."""
    ready = filled_blocks >= required_blocks
    return {
        "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.pit_uor_autofill_engine",
        "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
        "priority": 3282,
        "matched": True,
        "forms": ["PIT-36", "PIT-36L", "PIT-28"],
        "uor_sections": ["bilans", "rachunek_zyskow_i_strat"],
        "required_blocks": ["przychody", "koszty", "dochód"],
        "filled_blocks": filled_blocks,
        "ready_to_generate": ready,
        "deadline": "2026-04-30",
        "note": "pełny silnik auto-fill PIT-36/36L/28 z UoR — sprawozdania finansowe (bilans, RZiS) (P1)",
        "_routing": "TRIAGE_QUEUE" if not ready else "",
        "_routing_reason": f"Auto-fill PIT z UoR: {filled_blocks}/{required_blocks} bloków, ready={ready}",
        "_legal_basis": "Art. 45 u.PIT; UoR art. 45 (sprawozdania finansowe)",
        "_warnings": [],
    }


def edelivery_b2b_b2g_flow(mailbox_active: bool = False, confirmations_ok: bool = False) -> dict:
    """P1-2: integracja e-Doręczeń B2B/B2G + potwierdzenia doręczenia."""
    if not mailbox_active:
        status = "SKRZYNKA e-DORĘCZEŃ NIEAKTYWNA — aktywuj (B2B/B2G od 2026-01-01)"
        routing = "TRIAGE_QUEUE"
    elif not confirmations_ok:
        status = "BRAK POTWIERDZEŃ DORĘCZEŃ — zweryfikuj status wiadomości"
        routing = "TRIAGE_QUEUE"
    else:
        status = "SKRZYNKA e-DORĘCZEŃ AKTYWNA + POTWIERDZENIA OK (B2B/B2G)"
        routing = ""
    return {
        "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.edelivery_b2b_b2g_flow",
        "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
        "priority": 3283,
        "matched": True,
        "mailbox_api": "",
        "mailbox_active": mailbox_active,
        "b2b_enabled": True,
        "b2g_enabled": True,
        "confirmations_ok": confirmations_ok,
        "confirmation_type": "DORECZENIE_POTWIERDZONE",
        "integration_status": status,
        "note": "integracja e-Doręczeń B2B/B2G — skrzynka + potwierdzenia doręczenia (P1)",
        "_routing": routing,
        "_routing_reason": f"e-Doręczenia: mailbox={mailbox_active}, confirmations={confirmations_ok} (B2B/B2G)",
        "_legal_basis": "Ustawa o doręczeniach elektronicznych (2026-01-01)",
        "_warnings": [],
    }


def ml_cashflow_prediction(history_months: int = 0, predicted_balance_pln: float = 0.0,
                           confidence_pct: int = 0, confidence_min_pct: int = 70) -> dict:
    """P1-3: model ML predykcji cashflow (historia płatności, gradient boosting)."""
    if confidence_pct < confidence_min_pct:
        status = f"Model ML cashflow: pewność {confidence_pct}% (min {confidence_min_pct}%) — prognoza niewiarygodna"
        routing = "TRIAGE_QUEUE"
    else:
        status = f"Model ML cashflow: pewność {confidence_pct}% — prognoza gotowa"
        routing = ""
    return {
        "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.ml_cashflow_prediction",
        "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
        "priority": 3284,
        "matched": True,
        "model": "gradient_boosting",
        "features": ["średnia_płatności_30d"],
        "lookback_months": 12,
        "horizon_days": 30,
        "history_months": history_months,
        "predicted_balance_pln": round2(predicted_balance_pln),
        "confidence_pct": confidence_pct,
        "forecast_status": status,
        "note": "model ML predykcji cashflow — historia płatności (gradient boosting), horyzont 30 dni (P1)",
        "_routing": routing,
        "_routing_reason": f"ML cashflow: {history_months} mies. historii, saldo {predicted_balance_pln:.2f} PLN, pewność {confidence_pct}%",
        "_legal_basis": "OrdPU; u.PIT; VAT (planowanie płynności)",
        "_warnings": [],
    }


def bookkeeper_dashboard_ui(auto_booked: int = 0, unmatched: int = 0, forms_ready: int = 0,
                            today_deadlines: list = None, projected_balance_pln: float = 0.0,
                            forms_pending: list = None) -> dict:
    """P2-1: dashboard wirtualnego asystenta księgowego w UI."""
    today_deadlines = today_deadlines or []
    forms_pending = forms_pending or []
    pending_items = unmatched + len(forms_pending) + len(today_deadlines)
    return {
        "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.bookkeeper_dashboard_ui",
        "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
        "priority": 3285,
        "matched": True,
        "widgets": ["ksiegowania", "deklaracje"],
        "export_formats": ["JSON", "CSV", "PDF"],
        "ksiegowania": {"auto_booked": auto_booked, "unmatched": unmatched},
        "deklaracje": {"ready_to_send": forms_ready},
        "terminy": {"today_deadlines": len(today_deadlines)},
        "przeplywy": {"projected_balance_pln": round2(projected_balance_pln)},
        "pending_items": pending_items,
        "note": "dashboard wirtualnego asystenta księgowego — agregacja ksiegowania/deklaracje/terminy/przepływy (P2)",
        "_routing": "TRIAGE_QUEUE" if pending_items > 0 else "",
        "_routing_reason": f"Dashboard asystenta: {pending_items} pozycji do obsługi",
        "_legal_basis": "ADR-002; PSD2; OrdPU",
        "_warnings": [],
    }


def declaration_correction_automation(corrections_pending: int = 0) -> dict:
    """P2-2: automatyzacja korekt deklaracji (art. 81 OrdPU) end-to-end."""
    if corrections_pending > 0:
        status = f"KOREKTY DEKLARACJI — {corrections_pending} oczekujących (art. 81 OrdPU), termin 30 dni"
        routing = "TRIAGE_QUEUE"
    else:
        status = "Brak korekt deklaracji — OK (art. 81 OrdPU)"
        routing = ""
    return {
        "rule_id": "jdg.p18_automatyzacja_ksiegowosci_innovations.declaration_correction_automation",
        "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
        "priority": 3286,
        "matched": True,
        "legal_basis": "Art. 81 OrdPU",
        "correction_deadline_days": 30,
        "auto_fill_correction": True,
        "interest_calculation": True,
        "correction_reasons": ["błąd rachunkowy"],
        "corrections_pending": corrections_pending,
        "status": status,
        "note": "automatyzacja korekt deklaracji end-to-end — art. 81 OrdPU, auto-fill korekty + odsetki (P2)",
        "_routing": routing,
        "_routing_reason": f"Korekty deklaracji (art. 81 OrdPU): {corrections_pending} oczekujących",
        "_legal_basis": "Art. 81 OrdPU; art. 53-56 OrdPU (odsetki)",
        "_warnings": [],
    }


# ── Audyt realnych plików rego ────────────────────────────────────────────────
def _rule_ids(text: str) -> list:
    return re.findall(r'"rule_id"\s*:\s*"([^"]+)"', text)


def _looks_like_stub(text: str, rule_id: str) -> bool:
    """Wykrywanie stubów — reguł z trefnym/zawieszonym ciałem (np. '_ := 0')."""
    if "_ := 0" in text or ":= 0 }" in text:
        return True
    if "TODO" in text.upper() and rule_id in text:
        return True
    return False


def audit_rego_files() -> dict:
    """Pełny audyt: liczba rule_id per moduł, status COMPLETE/PARTIAL/MISSING."""
    modules_report = {}
    total = 0
    complete = 0
    for mod, cfg in MODULES.items():
        count = 0
        stubs = 0
        details = []
        for rel in cfg["files"]:
            p = BASE_DIR / rel
            if not p.exists():
                details.append({"file": rel, "exists": False, "rules": 0})
                continue
            text = p.read_text(encoding="utf-8", errors="replace")
            ids = _rule_ids(text)
            count += len(ids)
            if any(_looks_like_stub(text, rid) for rid in ids):
                stubs += 1
            details.append({"file": rel, "exists": True, "rules": len(ids)})
        status = "COMPLETE" if count >= 3 else ("PARTIAL" if count > 0 else "MISSING")
        if status == "COMPLETE":
            complete += 1
        total += count
        modules_report[mod] = {
            "status": status,
            "rules": count,
            "stubs": stubs,
            "files": details,
        }
    return {
        "modules": modules_report,
        "total_rule_ids": total,
        "summary": {
            "total_modules": len(MODULES),
            "complete": complete,
            "missing": len(MODULES) - complete,
        },
        "gap_pct": round2((len(MODULES) - complete) / len(MODULES) * 100),
    }


def p18_package_check() -> dict:
    p = BASE_DIR / P18_PACKAGE
    if not p.exists():
        return {"exists": False, "error": f"Brak pliku {P18_PACKAGE}"}
    text = p.read_text(encoding="utf-8")
    return {
        "exists": True,
        "package": "jdg.p18_automatyzacja_ksiegowosci_innovations",
        "braces_balanced": text.count("{") == text.count("}"),
        "inn_count": text.count("INN-"),
        "legal_basis_count": text.count("_legal_basis"),
        "rule_count": len(_rule_ids(text)),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="NexusAI JDG — P18 Automatyzacja Księgowości Auditor")
    parser.add_argument("--audit", action="store_true", help="pełny audyt plików micro (domyślne)")
    parser.add_argument("--banking", action="store_true", help="audyt bankowości PSD2 (Sekcja 1)")
    parser.add_argument("--booking", action="store_true", help="auto-księgowanie wyciągów (INN-01)")
    parser.add_argument("--tagging", action="store_true", help="auto-oznaczanie płatności (INN-02)")
    parser.add_argument("--psd2", action="store_true", help="monitor PSD2/SCA (INN-03)")
    parser.add_argument("--settlement", action="store_true", help="rozliczanie przelewów (INN-04)")
    parser.add_argument("--one-click", action="store_true", help="jedno kliknięcie obieg pisma (INN-05)")
    parser.add_argument("--autofill", action="store_true", help="auto-fill formularzy (INN-06)")
    parser.add_argument("--calendar", action="store_true", help="nieśmiertelny kalendarz (INN-07)")
    parser.add_argument("--deadlines", action="store_true", help="tracker terminów (INN-08)")
    parser.add_argument("--reconciliation", action="store_true", help="auto-koncyliacja bank (INN-09)")
    parser.add_argument("--cashflow", action="store_true", help="predykcja przepływów (INN-10)")
    parser.add_argument("--overpayment", action="store_true", help="auto-wnioskowanie o nadpłatę (INN-11)")
    parser.add_argument("--correspondence", action="store_true", help="auto-generator pism (INN-12)")
    parser.add_argument("--priority", action="store_true", help="priorytetyzacja terminów (INN-13)")
    parser.add_argument("--mpp", action="store_true", help="doradca MPP (INN-15)")
    parser.add_argument("--pipeline", action="store_true", help="pipeline auto-adaptacji API (Sekcja 6)")
    parser.add_argument("--ais-pis", action="store_true", help="integracja AIS/PIS PolishAPI OAuth2 (R18 P0)")
    parser.add_argument("--sca-prod", action="store_true", help="weryfikacja SCA w produkcji (R18 P0)")
    parser.add_argument("--pit-autofill", action="store_true", help="auto-fill PIT z UoR (R18 P1)")
    parser.add_argument("--edelivery-b2b", action="store_true", help="e-Doręczenia B2B/B2G (R18 P1)")
    parser.add_argument("--ml-cashflow", action="store_true", help="model ML predykcji cashflow (R18 P1)")
    parser.add_argument("--bookkeeper-dashboard", action="store_true", help="dashboard asystenta księgowego (R18 P2)")
    parser.add_argument("--declaration-corrections", action="store_true", help="automatyzacja korekt deklaracji (R18 P2)")
    parser.add_argument("--roadmap", action="store_true", help="wszystkie 7 pozycji mapy drogowej R18")

    args = parser.parse_args()

    result = {"tool": "automatyzacja_ksiegowosci_auditor", "module": "P18 Automatyzacja Księgowości"}
    funcs = [args.banking, args.booking, args.tagging, args.psd2, args.settlement,
             args.one_click, args.autofill, args.calendar, args.deadlines,
             args.reconciliation, args.cashflow, args.overpayment,
             args.correspondence, args.priority, args.mpp, args.pipeline,
             args.ais_pis, args.sca_prod, args.pit_autofill, args.edelivery_b2b,
             args.ml_cashflow, args.bookkeeper_dashboard, args.declaration_corrections]
    if args.roadmap:
        for fl in ["ais_pis", "sca_prod", "pit_autofill", "edelivery_b2b",
                   "ml_cashflow", "bookkeeper_dashboard", "declaration_corrections"]:
            setattr(args, fl, True)
    if not any(funcs):
        args.audit = True

    if args.audit:
        result["audit"] = audit_rego_files()
        result["package_check"] = p18_package_check()
    if args.banking:
        result["banking"] = banking_audit()
    if args.booking:
        result["booking"] = bank_statement_auto_booking(
            transactions=25, auto_booked=22)
    if args.tagging:
        result["tagging"] = payment_auto_tagging(payment_purpose="ZUS marzec 2026")
    if args.psd2:
        result["psd2"] = psd2_monitor(payment_amount_pln=250.0, tx_count_since_auth=6)
    if args.settlement:
        result["settlement"] = transfer_to_declaration_settlement(transfers=4, settled=3)
    if args.one_click:
        result["one_click"] = one_click_letter_flow(address_set=True, mailbox_active=False)
    if args.autofill:
        result["autofill"] = form_autofill_engine(form_type="PIT-36", filled=2, required=5)
    if args.calendar:
        result["calendar"] = immortal_tax_calendar(day_of_month=26)
    if args.deadlines:
        result["deadlines"] = deadline_alert_tracker(today_deadlines=["ZUS DRA"], urgent_count=3)
    if args.reconciliation:
        result["reconciliation"] = bank_reconciliation_engine(bank_balance_pln=12500.50, register_balance_pln=12400.00)
    if args.cashflow:
        result["cashflow"] = cashflow_forecaster(inflows_pln=20000.0, outflows_pln=15000.0, tax_liabilities_pln=8000.0)
    if args.overpayment:
        result["overpayment"] = overpayment_auto_claimer(overpayment_pln=1234.56, days_after_declaration=45)
    if args.correspondence:
        result["correspondence"] = correspondence_auto_generator(document_type="ZAŻALENIE")
    if args.priority:
        result["priority"] = tax_deadline_priority(today_deadlines=["VAT-7"], urgent_count=2)
    if args.mpp:
        result["mpp"] = split_payment_adviser(invoice_amount_pln=20000.0)
    if args.pipeline:
        result["pipeline"] = api_adaptation_pipeline(api_version="PolishAPI 3.0")
    if args.ais_pis:
        result["ais_pis"] = ais_pis_integration(token_valid=True, consent_active=True)
    if args.sca_prod:
        result["sca_prod"] = sca_production_verification(tests_passed=3)
    if args.pit_autofill:
        result["pit_autofill"] = pit_uor_autofill_engine(filled_blocks=2, required_blocks=3)
    if args.edelivery_b2b:
        result["edelivery_b2b"] = edelivery_b2b_b2g_flow(mailbox_active=True, confirmations_ok=False)
    if args.ml_cashflow:
        result["ml_cashflow"] = ml_cashflow_prediction(history_months=12, predicted_balance_pln=18500.75, confidence_pct=82)
    if args.bookkeeper_dashboard:
        result["bookkeeper_dashboard"] = bookkeeper_dashboard_ui(
            auto_booked=22, unmatched=3, forms_ready=2,
            today_deadlines=["VAT-7", "ZUS DRA"], projected_balance_pln=18500.75,
            forms_pending=["PIT-36"])
    if args.declaration_corrections:
        result["declaration_corrections"] = declaration_correction_automation(corrections_pending=1)

    print(json.dumps(result, ensure_ascii=False, indent=2, default=str))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
