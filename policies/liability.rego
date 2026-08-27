# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Liability: Przedawnienia, odpowiedzialność, odsetki (P1150-P1174)
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.liability
#
# METADATA
# title: JDG Package — liability
# description: Supporting package for JDG Multi-Pass evaluation (ADR-001).
# architecture: Multi-Pass (ADR-001)
# package: jdg.liability
# deprecated: false
#
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.liability.no_match","package":"jdg.liability","priority":1184}

# ═══════════════════════════════════════════════════════════════════════════════
# OP.01 (Doc 50): Art. 16 § 1-4 OrdPU — Powstanie obowiązku podatkowego
# Obowiązek podatkowy powstaje z dniem zaistnienia zdarzenia, z którym ustawa
# podatkowa wiąże powstanie takiego obowiązku. Dla JDG: moment wystawienia
# faktury, otrzymania zapłaty lub wykonania usługi (zależnie od podatku).
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched":true,"rule_id":"jdg.liability.tax_obligation_arises_art16",
    "package":"jdg.liability","priority":1101,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "tax_obligation_event":obligation_event,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 16 § 1-4 OrdPU",
    "_warnings":[sprintf("OBOWIĄZEK PODATKOWY — powstał w momencie: %s. Od tego dnia biegną terminy płatności, deklaracji i przedawnienia.",[obligation_event])]
} {
    input.invoice.amount_net > 0
    is_sale := input.invoice.direction == "SALE"
    is_paid := object.get(input.invoice, "is_paid", false)
    is_invoiced := object.get(input.invoice, "invoice_issued", false)
    obligation_event = "WYKONANIE_USLUGI" { is_sale == true; not is_invoiced }
    obligation_event = "WYSTAWIENIE_FAKTURY" { is_invoiced == true }
    obligation_event = "OTRZYMANIE_ZAPLATY" { is_paid == true; not is_invoiced }
}

# OP.02 (Doc 50): Art. 16a OrdPU — Dodatkowe zobowiązanie podatkowe
# Organ podatkowy może ustalić dodatkowe zobowiązanie podatkowe (sankcję)
# w wysokości do 30% zaniżonego zobowiązania. Dotyczy: rażące zaniżenie,
# nieujawnienie podstawy opodatkowania, brak deklaracji mimo obowiązku.
else := {
    "matched":true,"rule_id":"jdg.liability.additional_tax_obligation_art16a",
    "package":"jdg.liability","priority":1102,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "additional_tax_rate_pct":30,"additional_tax_amount":floor(tax_gap*0.30),
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Dodatkowe zobowiązanie 30% — rażące zaniżenie podatku",
    "_legal_basis":"Art. 16a OrdPU",
    "_warnings":[sprintf("DODATKOWE ZOBOWIĄZANIE 30%% — %.2f PLN (30%% od %.2f PLN zaniżenia). Zapłata w 14 dni od doręczenia decyzji.",[floor(tax_gap*0.30), tax_gap])]
} {
    tax_gap := object.get(input.jdg_entrepreneur, "tax_understatement_amount", 0)
    tax_gap > 0
    object.get(input.jdg_entrepreneur, "gross_understatement", false) == true
}

# OP.02b: wariant B — nieujawniona podstawa opodatkowania
else := {
    "matched":true,"rule_id":"jdg.liability.additional_tax_obligation_art16a_unreported",
    "package":"jdg.liability","priority":1102,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "additional_tax_rate_pct":30,"additional_tax_amount":floor(tax_gap*0.30),
    "_routing":"BLOCK_AND_ALERT","_routing_reason":"Dodatkowe zobowiązanie 30% — nieujawniona podstawa",
    "_legal_basis":"Art. 16a OrdPU",
    "_warnings":[sprintf("DODATKOWE ZOBOWIĄZANIE 30%% — %.2f PLN (30%% od %.2f PLN nieujawnionej podstawy). Zapłata w 14 dni od doręczenia decyzji.",[floor(tax_gap*0.30), tax_gap])]
} {
    tax_gap := object.get(input.jdg_entrepreneur, "tax_understatement_amount", 0)
    tax_gap > 0
    object.get(input.jdg_entrepreneur, "undisclosed_tax_base", false) == true
}

# ══════ P1150: tax_statute_of_limitations_5y — Przedawnienie 5 lat ══════
else := {
    "matched":true,"rule_id":"jdg.liability.statute_5_years",
    "package":"jdg.liability","priority":1150,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "statute_of_limitations_years":5,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 70 § 1 Ordynacji podatkowej",
    "_warnings":["Zobowiązanie podatkowe przedawnia się po 5 latach od końca roku kalendarzowego"]
} {
    days_since_fye := object.get(input.document,"months_since_fye",0)
    days_since_fye >= 60  # 5 years * 12 months
}

# ══════ P1158: entrepreneur_personal_liability — Pełna odpowiedzialność osobista ══════
else := {
    "matched":true,"rule_id":"jdg.liability.personal_liability",
    "package":"jdg.liability","priority":1158,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "liability_type":"UNLIMITED_PERSONAL",
    "liability_scope":"ALL_ASSETS_PERSONAL_AND_BUSINESS",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 33 Ordynacji podatkowej, Art. 415 KC",
    "_warnings":["JDG — PEŁNA odpowiedzialność osobista całym majątkiem (osobistym i firmowym)!"]
} {
    input.jdg_entrepreneur.tax_form != ""  # is JDG
}

# ══════ P1164: late_payment_interest_calculation — Odsetki za zwłokę ══════
else := {
    "matched":true,"rule_id":"jdg.liability.late_payment_interest",
    "package":"jdg.liability","priority":1164,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "interest_rate_annual":"0.145","interest_calculation":"DAILY",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 47-52 Ordynacji podatkowej",
    "_warnings":["Odsetki za zwłokę — stawka 14.5% w skali roku, naliczane dziennie"]
} {
    input.invoice.days_overdue > 0
    input.invoice.is_paid == false
}

# ══════ P1167: tax_arrears_detection — Zaległość podatkowa ══════
else := {
    "matched":true,"rule_id":"jdg.liability.tax_arrears_detection",
    "package":"jdg.liability","priority":1167,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "tax_arrears_detected":true,"arrears_amount":tax_due,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Zaległość podatkowa wykryta",
    "_legal_basis":"Art. 20-21 Ordynacji podatkowej",
    "_warnings":[sprintf("ZALEGŁOŚĆ PODATKOWA — %.2f PLN. Zapłać natychmiast + odsetki. Ryzyko egzekucji!",[tax_due])]
} {
    tax_due:=object.get(input.invoice,"tax_unpaid_amount",0)
    tax_due>0
    input.invoice.is_paid==false
}

# ══════ P1168: voluntary_disclosure_active — Czynny żal ══════
else := {
    "matched":true,"rule_id":"jdg.liability.voluntary_disclosure",
    "package":"jdg.liability","priority":1168,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "voluntary_disclosure_active":true,"kks_immunity":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 16-16b KKS",
    "_warnings":["Czynny żal — złożony przed wszczęciem kontroli. Brak kary KKS!"]
} {
    input.document.tax_status == "VOLUNTARY_DISCLOSURE"
}

# ══════ P1169: overpayment_detection — Nadpłata podatku ══════
else := {
    "matched":true,"rule_id":"jdg.liability.overpayment_detection",
    "package":"jdg.liability","priority":1169,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "overpayment_detected":true,"refund_deadline_days":45,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 72-80 Ordynacji podatkowej",
    "_warnings":["Nadpłata podatku — zwrot w terminie 45 dni"]
} {
    input.document.tax_status == "OVERPAYMENT"
}

# ══════ P1170: deferral_active — Aktywne odroczenie płatności ══════
else := {
    "matched":true,"rule_id":"jdg.liability.deferral_active",
    "package":"jdg.liability","priority":1170,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "deferral_active":true,"interest_suspended":true,"enforcement_suspended":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 48, Art. 67a-67e Ordynacji podatkowej",
    "_warnings":["Aktywne odroczenie/raty — odsetki i egzekucja zawieszone do czasu decyzji"]
} {
    object.get(input.jdg_entrepreneur,"has_active_deferral_decision",false)==true
}

# ══════ P1171: tax_remission_active — Umorzenie zaległości ══════
else := {
    "matched":true,"rule_id":"jdg.liability.tax_remission_active",
    "package":"jdg.liability","priority":1171,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "tax_remission_granted":true,"tax_liability_extinguished":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 51 Ordynacji podatkowej",
    "_warnings":["Umorzenie zaległości — zobowiązanie wygasło decyzją organu"]
} {
    object.get(input.document,"tax_remission_granted",false)==true
}

# ══════ P1172: overpayment_offset — Zaliczenie nadpłaty na przyszłe zobowiązania ══════
else := {
    "matched":true,"rule_id":"jdg.liability.overpayment_offset",
    "package":"jdg.liability","priority":1172,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "overpayment_offset_active":true,"overpayment_interest_after_45d":true,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 76-80 Ordynacji podatkowej",
    "_warnings":[sprintf("Nadpłata %.2f PLN — zaliczona na przyszłe zobowiązania. Po 45 dniach zwrotu: odsetki!",[overpayment])]
} {
    overpayment:=object.get(input.invoice,"overpayment_amount",0)
    overpayment>0
    object.get(input.document,"overpayment_offset_requested",false)==true
}

# ══════ P1174: tax_proceeding_deadlines — Terminy proceduralne ══════
else := {
    "matched":true,"rule_id":"jdg.liability.tax_proceeding_deadlines",
    "package":"jdg.liability","priority":1174,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "proceeding_notification_days":7,"response_deadline_days":14,"decision_deadline_days":30,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 120-129 Ordynacji podatkowej",
    "_warnings":["Terminy proceduralne: 7 dni zawiadomienie, 14 dni odpowiedź, 30 dni decyzja"]
} {
    object.get(input.document,"tax_proceeding_active",false)==true
}

# ══════ P1162: statute_interruption_execution — Przerwanie biegu przedawnienia (Doc 35) ══════
else := {
    "matched":true,"rule_id":"jdg.liability.statute_interruption_execution",
    "package":"jdg.liability","priority":1162,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "statute_interrupted":true,"new_statute_deadline_years":5,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Bieg przedawnienia przerwany — nowy 5-letni termin",
    "_legal_basis":"Art. 70 § 4 Ordynacji podatkowej",
    "_warnings":["Zastosowanie środka egzekucyjnego → przerwanie biegu przedawnienia. Nowy 5-letni termin od końca roku, w którym zastosowano środek."]
} {
    object.get(input.document,"enforcement_action_applied",false)==true
}

# ══════ P1164: spousal_solidary_liability — Odpowiedzialność solidarna małżonka (Doc 35) ══════
else := {
    "matched":true,"rule_id":"jdg.liability.spousal_solidary",
    "package":"jdg.liability","priority":1164,
    "vat_rate":"","rounding_level":"","gtu_code":"",
    "pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"",
    "kus_qualification":"","kus_percent":0,
    "zus_social_base_type":"","zus_health_rate":"",
    "business_status":"",
    "spousal_liability":true,"liability_scope":"JOINT_MARITAL_PROPERTY",
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 29 Ordynacji podatkowej",
    "_warnings":["Współmałżonek odpowiada solidarnie za zaległości JDG — egzekucja z majątku wspólnego. Odpowiedzialność do wartości udziału w majątku wspólnym."]
} {
    object.get(input.jdg_entrepreneur,"has_spouse",false)==true
    object.get(input.jdg_entrepreneur,"has_tax_arrears",false)==true
    object.get(input.jdg_entrepreneur,"marital_property_regime","")=="JOINT"
}
