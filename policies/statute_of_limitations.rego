# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Statute of Limitations: Przedawnienia (R0436-R0449)
# Doc 28a Enterprise — 14 reguł kanonicznych
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.limitations
import data.jdg.helpers
default decide := {"matched":false,"rule_id":"jdg.limitations.no_match","package":"jdg.limitations","priority":449}

# ═══════════════════════════════════════════════════════════════════════════════
# OP.03 (Doc 50): Art. 20 § 1 OrdPU — Bieg terminu przedawnienia
# Zobowiązanie podatkowe przedawnia się z upływem 5 lat, licząc od końca roku
# kalendarzowego, w którym upłynął termin płatności podatku. Dzień rozpoczęcia
# biegu = 1 stycznia roku następującego po roku, w którym powstał obowiązek.
# ═══════════════════════════════════════════════════════════════════════════════
decide := {
    "matched":true,"rule_id":"jdg.limitations.statute_period_begins_art20",
    "package":"jdg.limitations","priority":420,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"",
    "statute_years":5,"statute_starts_from":"END_OF_TAX_YEAR","statute_deadline_year":deadline_yr,
    "_routing":"","_routing_reason":"",
    "_legal_basis":"Art. 20 § 1 OrdPU, Art. 70 § 1 OrdPU",
    "_warnings":[sprintf("BIEG PRZEDAWNIENIA — 5 lat od końca roku podatkowego %s. Przedawnienie nastąpi 31.12.%s. Po terminie: obowiązek wygasa, egzekucja niedopuszczalna.",[tax_year, deadline_yr])]
} {
    tax_year := object.get(input.invoice, "tax_year", "")
    tax_year != ""
    tax_yr_num := to_number(tax_year)
    deadline_yr := sprintf("%d", [tax_yr_num + 5])
}

# OP.04a (Doc 50): Art. 21 § 1 pkt 1 OrdPU — Zawieszenie: postępowanie KKS
# Bieg terminu przedawnienia ulega zawieszeniu w przypadku wszczęcia
# postępowania karnego skarbowego — do dnia prawomocnego zakończenia.
else := {
    "matched":true,"rule_id":"jdg.limitations.suspension_of_limitation_art21",
    "package":"jdg.limitations","priority":421,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"",
    "statute_suspended":true,"suspension_reason":"Postępowanie KKS wszczęte","max_extension_years":10,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Zawieszenie przedawnienia — KKS w toku",
    "_legal_basis":"Art. 21 § 1 pkt 1 OrdPU, Art. 70 § 4 OrdPU",
    "_warnings":["ZAWIESZENIE PRZEDAWNIENIA — postępowanie KKS wszczęte. Bieg NIE PŁYNIE do czasu prawomocnego zakończenia. Maksymalny okres przedawnienia: 10 lat."]
} {
    object.get(input.jdg_entrepreneur, "kks_proceedings_active", false) == true
}

# OP.04b (Doc 50): Zawieszenie: kontrola podatkowa
else := {
    "matched":true,"rule_id":"jdg.limitations.suspension_of_limitation_art21_tax_audit",
    "package":"jdg.limitations","priority":421,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"",
    "statute_suspended":true,"suspension_reason":"Kontrola podatkowa w toku","max_extension_years":10,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Zawieszenie przedawnienia — kontrola podatkowa",
    "_legal_basis":"Art. 21 § 1 pkt 1 OrdPU, Art. 70 § 4 OrdPU",
    "_warnings":["ZAWIESZENIE PRZEDAWNIENIA — kontrola podatkowa w toku. Bieg NIE PŁYNIE do dnia zakończenia kontroli. Maksymalny okres przedawnienia: 10 lat."]
} {
    object.get(input.jdg_entrepreneur, "tax_audit_active", false) == true
}

# OP.04c (Doc 50): Zawieszenie: postępowanie podatkowe
else := {
    "matched":true,"rule_id":"jdg.limitations.suspension_of_limitation_art21_tax_proceedings",
    "package":"jdg.limitations","priority":421,
    "vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"",
    "statute_suspended":true,"suspension_reason":"Postępowanie podatkowe wszczęte","max_extension_years":10,
    "_routing":"TRIAGE_QUEUE","_routing_reason":"Zawieszenie przedawnienia — postępowanie podatkowe",
    "_legal_basis":"Art. 21 § 1 pkt 1 OrdPU, Art. 70 § 4 OrdPU",
    "_warnings":["ZAWIESZENIE PRZEDAWNIENIA — postępowanie podatkowe wszczęte. Bieg NIE PŁYNIE do dnia wydania decyzji ostatecznej. Maksymalny okres przedawnienia: 10 lat."]
} {
    object.get(input.jdg_entrepreneur, "tax_proceedings_started", false) == true
}

# R0436: statute_5_years — Przedawnienie 5 lat
else := {"matched":true,"rule_id":"jdg.limitations.statute_5_years","package":"jdg.limitations","priority":436,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","statute_of_limitations_years":5,"statute_deadline":deadline,"_routing":"","_routing_reason":"","_legal_basis":"Art. 70 § 1 OrdPU","_warnings":[sprintf("PRZEDAWNIENIE 5 LAT — zobowiązanie z %s przedawnia się 31.12.%s. Po terminie US nie może prowadzić egzekucji.",[tax_year,deadline])]} { tax_year:=object.get(input.invoice,"tax_year","");tax_year!="";deadline:=sprintf("%d",[to_number(tax_year)+5]) }

# R0437: statute_10_years — Przedawnienie 10 lat (zawieszenie/ przerwanie)
else := {"matched":true,"rule_id":"jdg.limitations.statute_10_years","package":"jdg.limitations","priority":437,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","statute_of_limitations_years":10,"statute_reason":"SUSPENDED_OR_INTERRUPTED","_routing":"TRIAGE_QUEUE","_routing_reason":"Przedawnienie wydłużone do 10 lat","_legal_basis":"Art. 70 § 4-6 OrdPU","_warnings":["PRZEDAWNIENIE 10 LAT — bieg przedawnienia został zawieszony lub przerwany. Wydłużenie do max 10 lat od końca roku kalendarzowego."]} { object.get(input.jdg_entrepreneur,"statute_suspended_or_interrupted",false)==true }

# R0438: statute_suspension_event — Zdarzenie zawieszające bieg przedawnienia
else := {"matched":true,"rule_id":"jdg.limitations.suspension_event","package":"jdg.limitations","priority":438,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","suspension_event":suspension_reason,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Zawieszenie przedawnienia — NIE ignoruj!","_legal_basis":"Art. 70 § 4 OrdPU","_warnings":[sprintf("ZAWIESZENIE PRZEDAWNIENIA — %s. Bieg przedawnienia NIE ROZPOCZYNA SIĘ / ULEGA ZAWIESZENIU do czasu ustania przyczyny.",[suspension_reason])]} { suspension_reason:=object.get(input.jdg_entrepreneur,"suspension_reason","");suspension_reason!="" }

# R0439: statute_interruption_event — Przerwanie biegu przedawnienia
else := {"matched":true,"rule_id":"jdg.limitations.interruption_event","package":"jdg.limitations","priority":439,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","interruption_event":interruption_reason,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Przerwanie przedawnienia — bieg rozpoczyna się od nowa!","_legal_basis":"Art. 70 § 5 OrdPU","_warnings":[sprintf("PRZERWANIE PRZEDAWNIENIA — %s. 5-letni termin biegnie OD NOWA od końca roku, w którym nastąpiło przerwanie.",[interruption_reason])]} { interruption_reason:=object.get(input.jdg_entrepreneur,"interruption_reason","");interruption_reason!="" }

# R0440: statute_kks_criminal — Przedawnienie karalności KKS
else := {"matched":true,"rule_id":"jdg.limitations.kks_criminal","package":"jdg.limitations","priority":440,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","kks_limitation_years":5,"kks_limitation_extended":10,"_routing":"TRIAGE_QUEUE","_routing_reason":"Przedawnienie karalności KKS — 5/10 lat","_legal_basis":"Art. 44 KKS","_warnings":[sprintf("PRZEDAWNIENIE KARALNOŚCI KKS — %d lat od popełnienia czynu (przestępstwo skarbowe). %d lat jeśli wszczęto postępowanie. Po terminie: NIE można ukarać.",[5,10])]} { object.get(input.jdg_entrepreneur,"kks_violation_detected",false)==true }

# R0441: statute_document_retention — Obowiązek przechowywania dokumentów
else := {"matched":true,"rule_id":"jdg.limitations.document_retention","package":"jdg.limitations","priority":441,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","retention_years":5,"retention_deadline":deadline,"_routing":"TRIAGE_QUEUE","_routing_reason":"Przechowywanie dokumentów — 5 lat od końca roku","_legal_basis":"Art. 86 OrdPU","_warnings":[sprintf("OBOWIĄZEK PRZECHOWYWANIA — dokumenty za %s przechowuj do 31.12.%s. Zniszczenie przed terminem = wykroczenie skarbowe + kara.",[tax_year,deadline])]} { input.invoice.is_year_end==true;tax_year:=object.get(input.invoice,"tax_year","");tax_year!="";deadline:=sprintf("%d",[to_number(tax_year)+5]) }

# R0442: personal_liability_jdg — Odpowiedzialność osobista JDG
else := {"matched":true,"rule_id":"jdg.limitations.personal_liability","package":"jdg.limitations","priority":442,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","personal_liability":true,"liability_scope":"ALL_PERSONAL_ASSETS","_routing":"BLOCK_AND_ALERT","_routing_reason":"Odpowiedzialność CAŁYM MAJĄTKIEM","_legal_basis":"Art. 26 OrdPU, Art. 108 OrdPU (osoby trzecie)","_warnings":["ODPOWIEDZIALNOŚĆ OSOBISTA JDG — jako przedsiębiorca JDG odpowiadasz za zobowiązania podatkowe CAŁYM SWOIM MAJĄTKIEM (osobistym i firmowym). Brak ochrony majątku prywatnego!"]} { input.jdg_entrepreneur.business_type=="JDG";object.get(input.jdg_entrepreneur,"tax_liability_outstanding",0)>0 }

# R0443: third_party_liability — Odpowiedzialność osób trzecich
else := {"matched":true,"rule_id":"jdg.limitations.third_party_liability","package":"jdg.limitations","priority":443,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","third_party_liable":true,"liable_party":liable_party,"_routing":"TRIAGE_QUEUE","_routing_reason":"Odpowiedzialność osoby trzeciej","_legal_basis":"Art. 107-112 OrdPU","_warnings":[sprintf("ODPOWIEDZIALNOŚĆ OSOBY TRZECIEJ — %s. Małżonek, rozwiedziony małżonek, członek rodziny może odpowiadać za zaległości JDG (majątek wspólny).",[liable_party])]} { third_party_claim:=object.get(input.jdg_entrepreneur,"third_party_liability_claim",false);third_party_claim==true;liable_party:=object.get(input.jdg_entrepreneur,"third_party_type","małżonek") }

# R0444: late_payment_interest — Odsetki za zwłokę
else := {"matched":true,"rule_id":"jdg.limitations.late_payment_interest","package":"jdg.limitations","priority":444,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","interest_rate_pct":interest_pct,"interest_amount_pln":floor(tax_amount*interest_pct/100*days_late/365*100)/100,"_routing":"","_routing_reason":"","_legal_basis":"Art. 53-56 OrdPU","_warnings":[sprintf("ODSETKI ZA ZWŁOKĘ — %.2f PLN × %.1f%% × %d dni / 365 = %.2f PLN. Stawka: %.1f%% (podstawowa) lub %.1f%% (obniżona po korekcie).",[tax_amount,interest_pct,days_late,floor(tax_amount*interest_pct/100*days_late/365*100)/100,interest_pct,interest_pct/2])]} { tax_amount:=object.get(input.jdg_entrepreneur,"outstanding_tax",0);days_late:=object.get(input.jdg_entrepreneur,"days_overdue_tax",0);interest_pct:=object.get(object.get(object.get(data.thresholds,"jdg",{}),"bounds",{}),"tax_interest_rate",14.5);tax_amount>0;days_late>0 }

# R0445: voluntary_disclosure_active — Czynny żal — przedawnienie karalności
else := {"matched":true,"rule_id":"jdg.limitations.voluntary_disclosure","package":"jdg.limitations","priority":445,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","voluntary_disclosure":true,"immunity_granted":before_proceedings,"_routing":"","_routing_reason":"","_legal_basis":"Art. 16 KKS, Art. 16a KKS","_warnings":[sprintf("CZYNNY ŻAL — %s. Złożenie czynnego żalu PRZED wszczęciem postępowania = NIEPODLEGANIE KARZE. Po wszczęciu: nadzwyczajne złagodzenie.",[immunity_info])]} { object.get(input.jdg_entrepreneur,"voluntary_disclosure_filed",false)==true;before_proceedings:=object.get(input.jdg_entrepreneur,"proceedings_not_started",true);immunity_info="Pełna ochrona — NIE podlega karze"{before_proceedings==true};immunity_info="Nadzwyczajne złagodzenie kary"{before_proceedings==false} }

# R0446: tax_audit_procedures — Procedury kontroli podatkowej
else := {"matched":true,"rule_id":"jdg.limitations.tax_audit_procedures","package":"jdg.limitations","priority":446,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","audit_in_progress":true,"audit_max_duration_days":max_duration,"_routing":"TRIAGE_QUEUE","_routing_reason":"Kontrola podatkowa — terminy i prawa","_legal_basis":"Art. 281-292 OrdPU","_warnings":[sprintf("KONTROLA PODATKOWA — max %d dni (przedłużalne). Przysługuje: sprzeciw, korekta deklaracji w 14 dni od protokołu, wyłączenie kontrolera (art. 291).",[max_duration])]} { object.get(input.jdg_entrepreneur,"tax_audit_active",false)==true;max_duration:=object.get(object.get(object.get(data.thresholds,"jdg",{}),"bounds",{}),"tax_audit_max_days",30) }

# R0447: statute_interruption_tax_proceedings — Wszczęcie postępowania przerywa bieg
else := {"matched":true,"rule_id":"jdg.limitations.interruption_proceedings","package":"jdg.limitations","priority":447,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","proceedings_interruption":true,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Wszczęcie postępowania — przedawnienie przerwane!","_legal_basis":"Art. 70 § 5 OrdPU","_warnings":["WSZCZĘCIE POSTĘPOWANIA — bieg przedawnienia ZOSTAŁ PRZERWANY! Nowy 5-letni termin od końca roku wszczęcia."]} { object.get(input.jdg_entrepreneur,"tax_proceedings_started",false)==true }

# R0448: liability_succession — Sukcesja odpowiedzialności podatkowej
else := {"matched":true,"rule_id":"jdg.limitations.liability_succession","package":"jdg.limitations","priority":448,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","liability_succession":true,"successor_type":successor,"_routing":"TRIAGE_QUEUE","_routing_reason":"Sukcesja podatkowa — odpowiedzialność następcy","_legal_basis":"Art. 100-112 OrdPU","_warnings":[sprintf("SUKCESJA PODATKOWA — %s. Następca prawny przejmuje zaległości podatkowe. Odpowiedzialność do wartości nabytego majątku.",[successor])]} { object.get(input.jdg_entrepreneur,"succession_triggered",false)==true;successor:=object.get(input.jdg_entrepreneur,"successor_type","spadkobierca") }

# R0449: tax_audit_extended_inspection — Przedłużona kontrola (30→60 dni)
else := {"matched":true,"rule_id":"jdg.limitations.audit_extended","package":"jdg.limitations","priority":449,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","audit_extended":true,"audit_extension_days":60,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Kontrola przedłużona do 60 dni","_legal_basis":"Art. 83 ust. 1 OrdPU","_warnings":["KONTROLA PRZEDŁUŻONA — standardowe 30 dni wydłużone do 60. Przyczyny: skomplikowana sprawa, wiele okresów, transakcje transgraniczne."]} { object.get(input.jdg_entrepreneur,"tax_audit_extended",false)==true }
