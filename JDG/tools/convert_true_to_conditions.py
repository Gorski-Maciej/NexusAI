#!/usr/bin/env python3
"""
NexusAI JDG — True→Condition Converter for Micro and Hyper rules.
Replaces { true } body with realistic conditions derived from rule descriptions.
"""
import re, os, sys
from datetime import datetime

BASE = "JDG/rules"
DRY_RUN = "--dry-run" in sys.argv

# ═══════════════════════════════════════════════════════════════════════════════
# KEYWORD → CONDITION MAPPING
# ═══════════════════════════════════════════════════════════════════════════════

def build_condition(rule_id, routing_reason, comment_line, package):
    """Build a Rego condition body from rule metadata using keyword matching."""
    
    rid_lower = rule_id.lower()
    reason_lower = routing_reason.lower()
    comment_lower = (comment_line or "").lower()
    combined = f"{reason_lower} {comment_lower}"
    
    conditions = []
    
    # ─── VAT DOMAIN ───
    if "vat" in package or rule_id.startswith("jdg.vat"):
        # Exports/imports
        if any(kw in combined for kw in ["eksport", "export"]):
            if "towar" in combined or "goods" in combined:
                conditions.append('object.get(input.invoice, "procedure", "") == "EXPORT"')
                conditions.append('object.get(input.invoice, "type", "") == "GOODS"')
            else:
                conditions.append('object.get(input.invoice, "procedure", "") == "EXPORT"')
        elif any(kw in combined for kw in ["import towar", "import goods"]):
            conditions.append('object.get(input.invoice, "procedure", "") == "IMPORT"')
            conditions.append('object.get(input.invoice, "type", "") == "GOODS"')
        elif any(kw in combined for kw in ["import usług", "import service"]):
            conditions.append('object.get(input.invoice, "procedure", "") == "IMPORT_SERVICES"')
        elif "wnt" in combined and "wdt" not in combined:
            conditions.append('object.get(input.invoice, "procedure", "") == "WNT"')
        elif "wdt" in combined:
            conditions.append('object.get(input.invoice, "procedure", "") == "WDT"')
        elif "reverse charge" in combined or "odwrotne" in combined:
            conditions.append('object.get(input.invoice, "reverse_charge", false) == true')
        
        # Supply types
        if "dostawa towar" in combined or "delivery" in combined:
            conditions.append('object.get(input.invoice, "type", "") == "GOODS"')
        elif any(kw in combined for kw in ["świadczenie usług", "usługa wykonana", "service"]):
            conditions.append('object.get(input.invoice, "type", "") == "SERVICE"')
        
        # VAT rates
        if "stawka 23%" in combined or "23%" in combined or "standard" in combined:
            conditions.append('object.get(input.invoice, "vat_rate", 0.0) == 0.23')
        elif "stawka 8%" in combined or "8%" in combined:
            conditions.append('object.get(input.invoice, "vat_rate", 0.0) == 0.08')
        elif "stawka 5%" in combined or "5%" in combined:
            conditions.append('object.get(input.invoice, "vat_rate", 0.0) == 0.05')
        elif "stawka 0%" in combined or "0%" in combined or "zw" in combined.lower():
            conditions.append('object.get(input.invoice, "vat_rate", 0.0) == 0.0')
        
        # VAT exemptions
        if "zwolnienie podmiotowe" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "vat_status", "") == "EXEMPT_SUBJECT"')
        elif any(kw in combined for kw in ["zwolnienie przedmiotowe", "zwolniony"]):
            conditions.append('object.get(input.invoice, "vat_exemption", "") != ""')
        elif "edukac" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "EDUCATION"')
        elif any(kw in combined for kw in ["medyczn", "lekarz", "zdrowot"]):
            conditions.append('object.get(input.invoice, "category_code", "") == "HEALTHCARE"')
        elif "finansow" in combined or "ubezpiecz" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "FINANCIAL"')
        
        # Deductions
        if any(kw in combined for kw in ["odliczenie", "deduction", "odlicz"]):
            conditions.append('object.get(input.invoice, "direction", "") == "PURCHASE"')
            conditions.append('object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"')
        elif "zablokowan" in combined or "blocked" in combined or "wyłącz" in combined:
            conditions.append('object.get(input.invoice, "direction", "") == "PURCHASE"')
            conditions.append('object.get(input.invoice, "vat_deduction_blocked", false) == true')
        
        # Cars
        if "auto" in combined or "samoch" in combined or "car" in combined or "pojazd" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "CAR"')
        if "ewidencj" in combined or "kilometr" in combined or "przebieg" in combined:
            conditions.append('object.get(input.invoice, "mileage_log_present", false) == true')
        if "mieszan" in combined:
            conditions.append('object.get(input.invoice, "private_use_percent", 0) > 0')
        
        # Bad debt
        if "złe długi" in combined or "bad debt" in combined:
            if "wierzyciel" in combined or "creditor" in combined:
                conditions.append('object.get(input.invoice, "direction", "") == "SALE"')
                conditions.append('object.get(input.invoice, "is_paid", true) == false')
                conditions.append('object.get(input.invoice, "days_overdue", 0) > 0')
            else:
                conditions.append('object.get(input.invoice, "direction", "") == "PURCHASE"')
                conditions.append('object.get(input.invoice, "is_paid", true) == false')
                conditions.append('object.get(input.invoice, "days_overdue", 0) >= 90')
        
        # KSeF
        if "ksef" in combined:
            conditions.append('object.get(input.invoice, "ksef_required", false) == true')
        
        # Invoices
        if "faktura" in combined:
            conditions.append('object.get(input.invoice, "invoice_type", "") == "INVOICE"')
        if "paragon" in combined or "receipt" in combined:
            conditions.append('object.get(input.invoice, "invoice_type", "") == "RECEIPT"')
        
        # Tax point / obligation
        if any(kw in combined for kw in ["obowiązek podatkowy", "tax point"]):
            conditions.append('object.get(input.invoice, "vat_tax_point_date", "") != ""')
        
        # Continuous services
        if "ciągł" in combined or "continuous" in combined:
            conditions.append('object.get(input.invoice, "is_continuous_service", false) == true')
        
        # Construction
        if "budowlan" in combined or "construction" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "CONSTRUCTION"')
        
        # Registration
        if "vat-r" in combined or "rejestracj" in combined:
            conditions.append('input.jdg_entrepreneur.vat_status != "ACTIVE"')
        
        # VAT-UE
        if "vat-ue" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "is_vat_eu_registered", false) == true')
        
        # Cash accounting
        if "metoda kasowa" in combined or "cash accounting" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "vat_cash_accounting", false) == true')
        
        # Margin scheme
        if "marż" in combined or "margin" in combined:
            conditions.append('object.get(input.invoice, "procedure", "") == "MARGIN_SCHEME"')
        
        # Non-cash / barter
        if "barter" in combined:
            conditions.append('object.get(input.invoice, "payment_method", "") == "BARTER"')
        
        # Gratis / free transfer
        if "nieodpłatn" in combined or "gratis" in combined:
            conditions.append('object.get(input.invoice, "is_gratis_transfer", false) == true')
        
        # Pre-payment / advance
        if "zaliczka" in combined or "advance" in combined or "prepayment" in combined:
            conditions.append('object.get(input.invoice, "prepayment_received", false) == true')
        
        # Commission sale
        if "komis" in combined or "commission" in combined:
            conditions.append('object.get(input.invoice, "procedure", "") == "CONSIGNMENT"')
        
        # Energy
        if "energi" in combined or "energy" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "ENERGY"')
        
        # Proportional deduction
        if "proporcj" in combined or "proportion" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "has_mixed_vat_activity", false) == true')
        
        # Subsidies
        if "dotacj" in combined or "subsidi" in combined:
            conditions.append('object.get(input.invoice, "includes_subsidy", false) == true')
        
        # Related party
        if "podmiot powiązan" in combined or "related party" in combined:
            conditions.append('object.get(input.vendor, "is_related_party", false) == true')
        
        # Tax base
        if "podstawa opodatkowania" in combined or "tax base" in combined:
            conditions.append('object.get(input.invoice, "amount_net", 0) > 0')
        
        # Invoice mandatory fields
        if "pole obowiązkowe" in combined or "mandatory field" in combined:
            conditions.append('object.get(input.invoice, "invoice_type", "") == "INVOICE"')
        
        # Sanctions
        if "sankcj" in combined or "sanction" in combined:
            conditions.append('object.get(input.invoice, "compliance_violation", false) == true')
        
        # Corrections
        if "korekt" in combined or "correction" in combined:
            conditions.append('object.get(input.invoice, "is_correction", false) == true')
        
        # Storno
        if "storno" in combined or "anulow" in combined:
            conditions.append('object.get(input.invoice, "is_storno", false) == true')
        
        # Declaration
        if "deklaracj" in combined or "jpk" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"')
        
        # Default VAT condition if no specific one
        if not conditions:
            if "vat payer" in combined or "podatnik vat" in combined or "czynny" in combined:
                conditions.append('object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"')
            elif rule_id.startswith("jdg.vat"):
                conditions.append('object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"')
    
    # ─── PIT DOMAIN ───
    if "pit" in package or rule_id.startswith("jdg.pit"):
        # Tax forms
        if any(kw in combined for kw in ["skala", "scale", "pit-36"]) and "liniow" not in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "PIT_SCALE"')
        elif "liniow" in combined or "19%" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LINEAR"')
        elif "ryczałt" in combined or "lump" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LUMP_SUM"')
        elif "karta podatkowa" in combined or "tax card" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "TAX_CARD"')
        
        # Revenue/income
        if "przychód" in combined or "revenue" in combined:
            conditions.append('object.get(input.invoice, "direction", "") == "SALE"')
        elif "dochód" in combined or "income" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "tax_form", "") != ""')
        
        # KUP
        if "kup" in combined or "koszt" in combined:
            conditions.append('object.get(input.invoice, "direction", "") == "PURCHASE"')
        if "wyłączenie" in combined or "exclusion" in combined or "nkup" in combined or "blocked" in combined:
            conditions.append('object.get(input.invoice, "kus_qualification", "") == "NKUP"')
        
        # Specific KUP exclusions
        if "reprezentacj" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "REPRESENTATION"')
        if "własna praca" in combined or "own labor" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") == "OWN_LABOR"')
        if "małżon" in combined or "spouse" in combined:
            conditions.append('object.get(input.vendor, "relation_to_entrepreneur", "") == "SPOUSE"')
        if "dziec" in combined or "child" in combined:
            conditions.append('object.get(input.vendor, "relation_to_entrepreneur", "") == "CHILD"')
        
        # Loss
        if "strata" in combined or "loss" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "has_tax_loss", false) == true')
        
        # Tax brackets
        if "próg" in combined or "bracket" in combined or "120" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "PIT_SCALE"')
        
        # Tax-free amount
        if "kwota wolna" in combined or "tax free" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "PIT_SCALE"')
        
        # Joint filing
        if "wspóln" in combined or "joint" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "PIT_SCALE"')
            conditions.append('object.get(input.jdg_entrepreneur, "married", false) == true')
        
        # Advances
        if "zaliczka" in combined or "advance" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "tax_form", "") != ""')
            conditions.append('object.get(input.jdg_entrepreneur, "advance_required", true) == true')
        
        # Annual returns
        if "zeznanie roczn" in combined or "annual return" in combined or "pit-36" in combined or "pit-28" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "tax_form", "") != ""')
        
        # Reliefs / allowances
        if "ulga" in combined or "relief" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}')
        
        # R&D
        if "b+r" in combined or "rd" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "has_rd_status", false) == true')
        
        # IP Box
        if "ip box" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "has_qualified_ip", false) == true')
        
        # Donations
        if "darowizn" in combined or "donation" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") == "DONATION"')
        
        # Blood donation
        if "krew" in combined or "blood" in combined or "krwiodaw" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "blood_donated_liters", 0) > 0')
        
        # Former employer
        if "były pracodawca" in combined or "former employer" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LINEAR"')
        
        # Depreciation
        if "amortyzacj" in combined or "depreciation" in combined:
            conditions.append('object.get(input.invoice, "is_fixed_asset", false) == true')
        
        # Foreign currency / FX
        if "różnic kursow" in combined or "fx" in combined or "walut" in combined:
            conditions.append('input.invoice.currency != "PLN"')
        
        # Inventory / Remanent
        if "remanent" in combined or "inventory" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true')
        
        # Cars
        if "auto" in combined or "samochód" in combined or "car" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "CAR"')
        if "elektryczn" in combined or "electric" in combined or "ev" in combined:
            conditions.append('object.get(input.invoice, "car_fuel_type", "") == "ELECTRIC"')
        
        # Real estate
        if "nieruchomoś" in combined or "real estate" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "REAL_ESTATE"')
        
        # Intellectual property
        if "prawa autorsk" in combined or "copyright" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") == "COPYRIGHT"')
        
        # Capital gains
        if "kapitał" in combined or "capital" in combined:
            conditions.append('object.get(input.invoice, "income_source", "") == "CAPITAL_GAINS"')
        
        # Default PIT condition
        if not conditions and rule_id.startswith("jdg.pit"):
            conditions.append('object.get(input.jdg_entrepreneur, "tax_form", "") != ""')
    
    # ─── ORD (TAX ORDINANCE) DOMAIN ───
    if "ord" in package or "ord" in rule_id:
        # Statute of limitations
        if "przedawnien" in combined or "statute" in combined or "limitation" in combined:
            conditions.append('object.get(input.document, "years_since_due_year", 0) > 0')
        
        # Tax proceedings
        if "postępowan" in combined or "proceeding" in combined:
            conditions.append('object.get(input.document, "tax_proceedings_active", false) == true')
        
        # Enforcement
        if "egzekucj" in combined or "enforcement" in combined:
            conditions.append('object.get(input.document, "enforcement_measure_applied", false) == true')
        
        # Interest
        if "odsetk" in combined or "interest" in combined:
            conditions.append('object.get(input.invoice, "days_overdue", 0) > 0')
        
        # Overpayment
        if "nadpłat" in combined or "overpayment" in combined:
            conditions.append('object.get(input.document, "overpayment_detected", false) == true')
        
        # Deferral
        if "odroczen" in combined or "deferral" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "has_active_deferral", false) == true')
        
        # Remission
        if "umorzen" in combined or "remission" in combined:
            conditions.append('object.get(input.document, "tax_remission_granted", false) == true')
        
        # Tax arrears
        if "zaległoś" in combined or "arrears" in combined:
            conditions.append('object.get(input.document, "tax_arrears_detected", false) == true')
        
        # Voluntary disclosure (czynny żal)
        if "czynny żal" in combined or "voluntary" in combined:
            conditions.append('object.get(input.document, "voluntary_disclosure_filed", false) == true')
        
        # Audit / control
        if "kontrol" in combined or "audit" in combined:
            conditions.append('object.get(input.document, "audit_in_progress", false) == true')
        
        # GAAR
        if "gaar" in combined or "klauzul" in combined:
            conditions.append('object.get(input.invoice, "gaar_risk", false) == true')
        
        # Tax information exchange
        if "wymiana informacji" in combined or "exchange" in combined:
            conditions.append('object.get(input.vendor, "country", "") in {"NON_EU"}')
        
        # Tax liability
        if "odpowiedzialnoś" in combined or "liability" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        
        # Notice/service
        if "doręczen" in combined or "notice" in combined:
            conditions.append('object.get(input.document, "official_notice_received", false) == true')
        
        # Default ORD condition
        if not conditions:
            conditions.append('object.get(input.document, "tax_proceedings_active", false) == true')
    
    # ─── ZUS DOMAIN ───
    if "zus" in package or rule_id.startswith("jdg.zus"):
        # Active business
        conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        
        # Specific ZUS reliefs
        if "start" in combined and "relief" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "zus_relief_type", "") == "START"')
        elif "preferencyjn" in combined or "preferential" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "zus_relief_type", "") == "PREFERENTIAL"')
        elif "mały zus" in combined or "maly" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "zus_relief_type", "") == "MALY_ZUS_PLUS"')
        
        # Health insurance
        if "zdrowotn" in combined or "health" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        
        # Social insurance
        if "społeczn" in combined or "social" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        
        # Sickness
        if "chorobow" in combined or "sickness" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "zus_sickness_voluntary", false) == true')
        
        # Concurrent employment
        if "zbieg" in combined or "concurrent" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "has_employment_contract", false) == true')
        
        # Benefits
        if "zasiłek" in combined or "benefit" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "benefit_claim_filed", false) == true')
        
        # Deadlines
        if "termin" in combined or "deadline" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        
        # ZUS declarations
        if "dra" in combined or "deklaracj" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        
        # Cessation
        if "ustanie" in combined or "cessation" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "CLOSED"')
    
    # ─── HYPER DOMAINS ───
    # Check both package AND rule_id (for jdg.hyper.general/misc/audit packages)
    if "mdr" in package or "mdr" in rule_id:
        conditions.append('object.get(input.document, "mdr_scheme_detected", false) == true')
    if "solidarity" in package or "solidarity" in rule_id:
        conditions.append('object.get(input.jdg_entrepreneur, "annual_income", 0) > 1000000')
    if "wis" in package or "wis" in rule_id:
        conditions.append('object.get(input.invoice, "wis_required", false) == true')
    if "force_majeure" in package or "force_majeure" in rule_id:
        conditions.append('object.get(input.jdg_entrepreneur, "force_majeure_declared", false) == true')
    if "family" in package or "family" in rule_id:
        conditions.append('object.get(input.vendor, "relation_to_entrepreneur", "") != ""')
    if "edelivery" in package or "edelivery" in rule_id:
        conditions.append('object.get(input.document, "edelivery_notification", false) == true')
    if "procurement" in package or "procurement" in rule_id:
        conditions.append('object.get(input.document, "public_procurement_active", false) == true')
    if "fx" in package or "fx" in rule_id:
        conditions.append('input.invoice.currency != "PLN"')
    if "tp" in package or "tp" in rule_id:
        conditions.append('object.get(input.vendor, "is_related_party", false) == true')
    if "residency" in package or "residency" in rule_id:
        conditions.append('object.get(input.jdg_entrepreneur, "tax_residence", "") == "PL"')
    if "payments" in package or "payments" in rule_id:
        conditions.append('object.get(input.invoice, "amount_gross", 0) > 0')
    if "advertising" in package or "advertising" in rule_id:
        conditions.append('object.get(input.invoice, "expense_type", "") == "ADVERTISING"')
    if "kks" in package or "kks" in rule_id:
        conditions.append('object.get(input.invoice, "kks_risk_detected", false) == true')
    if "limits" in package or "limits" in rule_id:
        conditions.append('object.get(input.invoice, "amount_gross", 0) > 0')
    if "sanctions" in package or "sanctions" in rule_id:
        conditions.append('object.get(input.invoice, "compliance_violation", false) == true')
    if "deadlines" in package or "deadlines" in rule_id:
        conditions.append('object.get(input.invoice, "days_to_deadline", 999) < 30')
    
    # ─── LOCAL TAXES ───
    if "local_taxes" in package or "local_taxes" in rule_id:
        if "pcc" in combined:
            conditions.append('object.get(input.invoice, "direction", "") == "PURCHASE"')
            conditions.append('object.get(input.vendor, "is_company", true) == false')
        if "nieruchomoś" in combined or "real estate" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0')
        if "transport" in combined:
            conditions.append('object.get(input.invoice, "vehicle_weight_kg", 0) > 3500')
    
    # ─── ACCOUNTING ───
    if "accounting" in package or "accounting" in rule_id:
        if "pkpir" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true')
        if "leasing" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") in {"OPERATING_LEASE", "FINANCIAL_LEASE"}')
        if "fx" in combined or "kurs" in combined:
            conditions.append('input.invoice.currency != "PLN"')
    
    # ─── BUSINESS ───
    if "business" in package or "business" in rule_id:
        if "ceidg" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        if "zawieszen" in combined or "suspension" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"')
        if "sukcesj" in combined or "succession" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "IN_SUCCESSIO"')
        if "wznowien" in combined or "resumption" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
    
    # ─── RODO ───
    if "rodo" in package or "rodo" in rule_id:
        conditions.append('object.get(input.jdg_entrepreneur, "processes_personal_data", false) == true')
    
    # ─── CROSSBORDER ───
    if ("crossborder" in package or "crossborder" in rule_id) and not conditions:
        conditions.append('object.get(input.vendor, "country", "PL") != "PL"')
    
    # ─── RISK ───
    if "risk" in package or "risk" in rule_id:
        if "fraud" in combined or "empty" in combined:
            conditions.append('object.get(input.vendor, "fraud_flag", false) == true')
        elif "hidden" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "income_discrepancy_detected", false) == true')
        else:
            conditions.append('object.get(input.vendor, "risk_flag", false) == true')
    
    # ─── ALLOWANCES (Ulgi podatkowe) ───
    if "allowances" in package or "allowances" in rule_id:
        if "prototyp" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") == "PROTOTYPE"')
        elif "robotyzacj" in combined or "robot" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") == "ROBOTIZATION"')
        elif "ekspansy" in combined or "expansion" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") == "EXPANSION"')
        elif "badawcz" in combined or "rd" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "has_rd_status", false) == true')
        elif "termomodernizac" in combined or "thermo" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") == "THERMOMODERNIZATION"')
        else:
            conditions.append('object.get(input.jdg_entrepreneur, "tax_form", "") in {"PIT_SCALE", "LINEAR"}')
    
    # ─── STATUTE (Przedawnienia / terminy) ───
    if "statute" in package or "statute" in rule_id:
        if "zawieszenie" in combined or "suspension" in combined:
            conditions.append('object.get(input.document, "statute_suspended", false) == true')
        elif "przerwanie" in combined or "interruption" in combined:
            conditions.append('object.get(input.document, "statute_interrupted", false) == true')
        elif "wykrycie" in combined or "detected" in combined:
            conditions.append('object.get(input.document, "tax_arrears_detected", false) == true')
        else:
            conditions.append('object.get(input.document, "years_since_due_year", 0) > 0')
    
    # ─── UOR (Ustawa o Rachunkowości) ───
    if "uor" in package or "uor" in rule_id:
        if "inwentaryzacj" in combined or "inventory" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true')
        elif "wycena" in combined or "valuation" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true')
        elif "rozliczen" in combined or "accrual" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true')
        else:
            conditions.append('object.get(input.jdg_entrepreneur, "full_accounting_required", false) == true')
    
    # ─── PCC (Podatek od czynności cywilnoprawnych) ───
    if "pcc" in package or "pcc" in rule_id:
        conditions.append('object.get(input.invoice, "direction", "") == "PURCHASE"')
        if "pożyczk" in combined or "loan" in combined:
            conditions.append('object.get(input.invoice, "expense_type", "") == "LOAN"')
        elif "samochód" in combined or "car" in combined or "pojazd" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "CAR"')
        elif "nieruchomoś" in combined or "real estate" in combined:
            conditions.append('object.get(input.invoice, "category_code", "") == "REAL_ESTATE"')
        conditions.append('object.get(input.vendor, "is_company", true) == false')
    
    # ─── AUDIT (Kontrola podatkowa) ───
    if "audit" in package or "audit" in rule_id:
        conditions.append('object.get(input.document, "audit_in_progress", false) == true')
    
    # ─── REPRESENTATION (Pełnomocnictwa / prokura) ───
    if "representation" in package or "representation" in rule_id:
        conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
    
    # ─── NEW PLAN 33 DOMAINS ───
    # RYC (Ryczałt — lump sum taxation)
    if "ryc" in package or "ryc" in rule_id:
        if "stawka" in combined or "rate" in combined or "procent" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LUMP_SUM"')
        elif "wyłączen" in combined or "exclusion" in combined or "niedostępn" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form != "LUMP_SUM"')
        elif "pkd" in combined or "rodzaj" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LUMP_SUM"')
        elif "przychód" in combined or "revenue" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LUMP_SUM"')
        elif "zaliczka" in combined or "advance" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LUMP_SUM"')
        else:
            conditions.append('input.jdg_entrepreneur.tax_form == "LUMP_SUM"')
    
    # HEALTH (Składka zdrowotna — health insurance)
    if "health" in package or "health" in rule_id:
        if "skala" in combined or "scale" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "PIT_SCALE"')
        elif "liniow" in combined or "linear" in combined or "4.9%" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LINEAR"')
        elif "ryczałt" in combined or "lump" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "LUMP_SUM"')
        elif "karta" in combined or "tax card" in combined:
            conditions.append('input.jdg_entrepreneur.tax_form == "TAX_CARD"')
        elif "odliczen" in combined or "deduction" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        elif "roczne" in combined or "annual" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        else:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
    
    # KSEF (Krajowy System e-Faktur)
    if "ksef" in package or "ksef" in rule_id:
        if "offline" in combined or "awari" in combined:
            conditions.append('object.get(input.invoice, "ksef_status", "") == "OFFLINE"')
        elif "qr" in combined:
            conditions.append('object.get(input.invoice, "ksef_qr_present", false) == false')
        elif "sankcj" in combined or "sanction" in combined or "kara" in combined:
            conditions.append('object.get(input.invoice, "compliance_violation", false) == true')
        elif "upo" in combined or "potwierdzen" in combined:
            conditions.append('object.get(input.invoice, "ksef_upo_received", false) == true')
        else:
            conditions.append('object.get(input.invoice, "ksef_required", false) == true')
    
    # JPK (Jednolity Plik Kontrolny)
    if "jpk" in package or "jpk" in rule_id:
        if "v7" in combined or "vat" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"')
        elif "pkpir" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "uses_pkpir", false) == true')
        elif "żądani" in combined or "request" in combined or "wezwani" in combined:
            conditions.append('object.get(input.document, "jpk_request_received", false) == true')
        elif "termin" in combined or "deadline" in combined or "14 dni" in combined:
            conditions.append('object.get(input.document, "jpk_request_received", false) == true')
        else:
            conditions.append('object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"')
    
    # PROP (Podatek od nieruchomości — property tax)
    if "prop" in package or "prop" in rule_id:
        if "nieruchomoś" in combined or "budyn" in combined or "building" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0')
        elif "grunt" in combined or "land" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "land_owned_sqm", 0) > 0')
        elif "stawk" in combined or "rate" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0')
        elif "deklaracj" in combined or "dn-1" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0')
        else:
            conditions.append('object.get(input.jdg_entrepreneur, "home_office_area_sqm", 0) > 0')
    
    # PROP_TRANSPORT (Podatek od środków transportowych)
    if "prop_transport" in package or "prop_transport" in rule_id:
        conditions.append('object.get(input.invoice, "vehicle_weight_kg", 0) > 3500')
    
    # SUCC (Sukcesja — succession after death)
    if "succ" in package or "succ" in rule_id:
        conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "IN_SUCCESSIO"')
    
    # CEIDG (Centralna Ewidencja Działalności Gospodarczej)
    if "ceidg" in package or "ceidg" in rule_id:
        if "rejestracj" in combined or "registration" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        elif "zawieszen" in combined or "suspension" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "SUSPENDED"')
        elif "wznowien" in combined or "resumption" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        elif "zamknięc" in combined or "closure" in combined or "zaprzestan" in combined:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "CLOSED"')
        else:
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
    
    # CB (Cross-border — transakcje transgraniczne)
    if "cb" in package or "cb" in rule_id:
        if "wht" in combined or "podatek u źródła" in combined:
            conditions.append('object.get(input.vendor, "country", "PL") != "PL"')
            conditions.append('object.get(input.invoice, "withholding_tax_applicable", false) == true')
        elif "oss" in combined or "ioss" in combined:
            conditions.append('object.get(input.vendor, "country", "PL") != "PL"')
        elif "b2b" in combined:
            conditions.append('object.get(input.vendor, "country", "PL") != "PL"')
            conditions.append('object.get(input.vendor, "is_individual", true) == false')
        elif "b2c" in combined:
            conditions.append('object.get(input.vendor, "country", "PL") != "PL"')
            conditions.append('object.get(input.vendor, "is_individual", true) == true')
        elif "ue" in combined.lower() or "eu" in combined.lower():
            conditions.append('object.get(input.vendor, "country", "PL") != "PL"')
        else:
            conditions.append('object.get(input.vendor, "country", "PL") != "PL"')
    
    # EST (Estoński CIT dla JDG)
    if "est" in package or "est" in rule_id:
        conditions.append('input.jdg_entrepreneur.tax_form == "ESTONIAN_CIT"')
    
    # TAX_TRANS (Podatek od środków transportowych)
    if "tax_trans" in package or "tax_trans" in rule_id:
        conditions.append('object.get(input.invoice, "vehicle_weight_kg", 0) > 3500')
    
    # AGRICULTURAL_TAX (Podatek rolny)
    if "agricultural_tax" in package or "agricultural_tax" in rule_id:
        conditions.append('object.get(input.jdg_entrepreneur, "land_owned_sqm", 0) > 0')
    
    # ─── FALLBACK: derive from rule category ───
    if not conditions:
        # Try to derive from rule_id article number
        if rule_id.startswith("jdg.vat"):
            conditions.append('object.get(input.jdg_entrepreneur, "vat_status", "") == "ACTIVE"')
        elif rule_id.startswith("jdg.pit"):
            conditions.append('object.get(input.jdg_entrepreneur, "tax_form", "") != ""')
        elif rule_id.startswith("jdg.zus"):
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        elif rule_id.startswith("jdg.ord"):
            conditions.append('object.get(input.document, "tax_proceedings_active", false) == true')
        elif rule_id.startswith("jdg.hyper"):
            conditions.append('object.get(input.jdg_entrepreneur, "business_status", "") == "ACTIVE"')
        else:
            conditions.append('true')
    
    # Build the final condition string
    if len(conditions) == 1 and conditions[0] == 'true':
        return '    true'
    
    return '    ' + '; '.join(conditions)


# ═══════════════════════════════════════════════════════════════════════════════
# FILE PROCESSOR
# ═══════════════════════════════════════════════════════════════════════════════

def process_file(filepath):
    """Replace { true } bodies with derived conditions in a .rego file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    package_match = re.search(r'^package\s+(\S+)', content, re.MULTILINE)
    package = package_match.group(1) if package_match else ""
    
    lines = content.split('\n')
    output = []
    i = 0
    modified = 0
    
    while i < len(lines):
        line = lines[i]
        
        # 1. Detect single-line verdict format: (decide|else) :=   {...} {
        #    The verdict's closing } and the body's { are on the SAME line
        m = re.match(r'^(decide|else)\s*:=\s*(\{.*?\})\s*\{\s*$', line)
        
        if m:
            # 2. Split at } { — verdict_text is group(2), body opens with the trailing {
            verdict_text = m.group(2)
            
            # Extract rule_id from verdict
            rid_match = re.search(r'"rule_id"\s*:\s*"([^"]+)"', verdict_text)
            rule_id = rid_match.group(1) if rid_match else ""
            
            # Extract routing_reason
            reason_match = re.search(r'"_routing_reason"\s*:\s*"([^"]*)"', verdict_text)
            routing_reason = reason_match.group(1) if reason_match else ""
            
            # Look at previous lines for comment (rule description)
            comment_line = ""
            k = i - 1
            while k >= 0 and (lines[k].strip().startswith('#') or lines[k].strip() == ''):
                if lines[k].strip().startswith('#'):
                    comment_line = lines[k].strip()
                    break
                k -= 1
            
            # Build condition
            condition = build_condition(rule_id, routing_reason, comment_line, package)
            
            # 3. Check next 2 lines for `true` (indented) and `}`
            if i + 2 < len(lines) and lines[i+1].strip() == 'true' and lines[i+2].strip() == '}':
                output.append(line)
                output.append(condition)
                output.append('}')
                i += 3
                modified += 1
            elif i + 1 < len(lines) and lines[i+1].strip() == 'true }':
                # Compact single-line body: true }
                output.append(line)
                output.append(condition)
                output.append('}')
                i += 2
                modified += 1
            else:
                output.append(line)
                i += 1
        
        # Fallback: multi-line verdict (no } { on same line)
        elif re.match(r'^(decide|else)\s*:=\s*\{', line):
            verdict_lines = [line]
            j = i + 1
            brace_count = line.count('{') - line.count('}')
            while j < len(lines) and brace_count > 0:
                verdict_lines.append(lines[j])
                brace_count += lines[j].count('{') - lines[j].count('}')
                if "} {" in lines[j]:
                    break
                j += 1
            
            verdict_text = '\n'.join(verdict_lines)
            
            rid_match = re.search(r'"rule_id"\s*:\s*"([^"]+)"', verdict_text)
            rule_id = rid_match.group(1) if rid_match else ""
            
            reason_match = re.search(r'"_routing_reason"\s*:\s*"([^"]*)"', verdict_text)
            routing_reason = reason_match.group(1) if reason_match else ""
            
            comment_line = ""
            k = i - 1
            while k >= 0 and (lines[k].strip().startswith('#') or lines[k].strip() == ''):
                if lines[k].strip().startswith('#'):
                    comment_line = lines[k].strip()
                    break
                k -= 1
            
            condition = build_condition(rule_id, routing_reason, comment_line, package)
            
            if j < len(lines) and lines[j].strip() == '{' and j + 1 < len(lines) and lines[j+1].strip() == 'true':
                output.extend(verdict_lines)
                output.append('{')
                output.append(condition)
                output.append('}')
                i = j + 2
                modified += 1
            elif j < len(lines) and '{' in lines[j] and 'true' in lines[j]:
                output.extend(verdict_lines)
                output.append(f'{{ {condition.strip()} }}')
                i = j + 1
                modified += 1
            else:
                output.extend(verdict_lines)
                if j < len(lines):
                    body_text = ' '.join(lines[j:j+3]).strip()
                    if body_text == '{ true }':
                        output.append(f'{{ {condition.strip()} }}')
                        i = j + 3
                        modified += 1
                        continue
                    elif body_text.startswith('{ true'):
                        output.append(f'{{ {condition.strip()} }}')
                        i = j + 2
                        modified += 1
                        continue
                i = j
        else:
            output.append(line)
            i += 1
    
    if modified > 0 and not DRY_RUN:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(output))
    
    return modified


def main():
    print("=" * 70)
    print("NexusAI JDG — True→Condition Converter")
    print("=" * 70)
    
    # Find all target files
    target_patterns = [
        "JDG/rules/micro/plan33_*.rego",
        "JDG/rules/micro/plan34_*.rego",
        "JDG/rules/jdg/hyper/*/plan45.rego",
        "JDG/rules/*/plan23_*.rego",
        "JDG/rules/*/plan26_*.rego",
        "JDG/rules/*/plan42_*.rego",
        "JDG/rules/*/plan43_*.rego",
        "JDG/rules/*/plan44_*.rego",
    ]
    
    import glob
    files = []
    for pattern in target_patterns:
        files.extend(glob.glob(pattern))
    
    print(f"\nTarget files: {len(files)}")
    
    total_modified = 0
    for filepath in sorted(files):
        modified = process_file(filepath)
        if DRY_RUN:
            print(f"  [DRY RUN] {filepath}: {modified} rules would be modified")
        else:
            print(f"  ✅ {filepath}: {modified} rules converted")
        total_modified += modified
    
    print(f"\n{'=' * 70}")
    print(f"SUMMARY")
    print(f"  Total rules converted: {total_modified}")
    print(f"  Files processed: {len(files)}")
    
    if DRY_RUN:
        print(f"\n  ⚠️ DRY RUN — use without --dry-run to apply changes.")
    
    print(f"{'=' * 70}")


if __name__ == "__main__":
    main()
