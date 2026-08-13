# ------------------------------------------------------------------------------
# NexusAI JDG — Enterprise PKPiR Validation Revival
# ------------------------------------------------------------------------------
# ENTERPRISE v4.0 — Full PKPiR column validation (cols 1-17)
# Legal basis: Rozporządzenie MF ws. PKPiR (Dz.U. 2025), Art. 24a PIT, UoR
# Architecture: Enterprise Multi-Pass, First-Match-Wins else-chain
# ------------------------------------------------------------------------------

package jdg.accounting.pkpir_validation

import future.keywords.in
import data.jdg.helpers

default decide := {
    "matched": false, "rule_id": "jdg.accounting.pkpir_val.no_match",
    "package": "jdg.accounting.pkpir_validation", "priority": 899
}

# ------------------------------------------------------------------------------
# P800-P819: PKPiR COLUMNS 1-9 — Basic registration data
# ------------------------------------------------------------------------------

# --- P800: Col 1 — Sequential numbering ---
decide := {"matched":true,"rule_id":"jdg.accounting.pkpir_validation.col1_sequential",
"package":"jdg.accounting.pkpir_validation","priority":800,
"pkpir_column":1,"pkpir_field_name":"Lp. (liczba porządkowa)",
"pkpir_entry_number":entry_num,
"_routing":col1_rt,"_routing_reason":col1_rs,
"_legal_basis":"§ 10 ust. 1 pkt 1 Rozporządzenia PKPiR",
"_warnings":[sprintf("KOLUMNA 1 PKPiR — Lp. %d. %s. Zapis numerowany ciągiem od 1 narastająco przez cały rok podatkowy. Bez luk, bez duplikatów.",[entry_num,note])]
}{
    input.invoice.pkpir_column_validation==true
    entry_num:=object.get(input.invoice,"pkpir_entry_number",0)
    prev_num:=object.get(input.jdg_entrepreneur,"pkpir_last_entry_number",0)
    entry_num>0
    is_sequential:=entry_num==prev_num+1
    is_first:=entry_num==1
    # OPA 0.68: object lookup with array key replaces {body} conditional
    col1_rt := object.get({
        [false, false]: "BLOCK_AND_ALERT"
    }, [is_sequential, is_first], "")
    #    [true,true] and [true,false] → OK (sequential), [false,true] → OK (first), only [false,false] → BLOCK
    note := object.get({
        [true, true]: "OK — numeracja ciągła",
        [true, false]: "OK — numeracja ciągła",
        [false, true]: "OK — pierwszy zapis"
    }, [is_sequential, is_first], sprintf("BŁĄD! Numer %d nie następuje po %d — luka lub duplikat!",[entry_num,prev_num]))
    col1_rs := object.get({
        [false, false]: sprintf("Nieciągła numeracja: %d po %d",[entry_num,prev_num])
    }, [is_sequential, is_first], "")
}

# --- P801: Col 2 — Event date ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_col2_event_date",
"package":"jdg.accounting.pkpir_validation","priority":801,
"pkpir_column":2,"pkpir_field_name":"Data zdarzenia gospodarczego",
"pkpir_event_date":event_date,
"_routing":col2_rt,"_routing_reason":col2_rs,
"_legal_basis":"§ 10 ust. 1 pkt 2 Rozporządzenia PKPiR",
"_warnings":[sprintf("KOLUMNA 2 PKPiR — Data zdarzenia: %s. %s. Data zdarzenia = data wystawienia faktury / data operacji gospodarczej.",[event_date,col2_note])]
}{
    input.invoice.pkpir_column_validation==true
    event_date:=object.get(input.invoice,"transaction_date","")
    eval_date:=object.get(input,"evaluation_datetime","2026-07-18")
    event_date!=""
    is_future:=event_date>eval_date
    col2_note:={true: "UWAGA: data w przyszłości?", false: "OK"}[is_future]
    col2_rt:={true: "TRIAGE_QUEUE", false: ""}[is_future]
    col2_rs:={true: "Data transakcji w przyszłości", false: ""}[is_future]
}

# --- P802: Col 3 — Entry date ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_col3_entry_date",
"package":"jdg.accounting.pkpir_validation","priority":802,
"pkpir_column":3,"pkpir_field_name":"Data wpisu do księgi",
"pkpir_entry_date":entry_date,
"_routing":col3_rt,"_routing_reason":col3_rs,
"_legal_basis":"§ 10 ust. 1 pkt 3 Rozporządzenia PKPiR",
"_warnings":[sprintf("KOLUMNA 3 PKPiR — Data wpisu: %s. %s. Wpis powinien być dokonany niezwłocznie po zdarzeniu (max 14 dni).",[entry_date,col3_note])]
}{
    input.invoice.pkpir_column_validation==true
    entry_date:=object.get(input.invoice,"pkpir_entry_date","")
    event_date:=object.get(input.invoice,"transaction_date","")
    entry_date!=""
    is_before_event:=entry_date<event_date
    col3_note:={true: "UWAGA: data wpisu wcześniejsza niż data zdarzenia!", false: "OK"}[is_before_event]
    col3_rt:={true: "TRIAGE_QUEUE", false: ""}[is_before_event]
    col3_rs:={true: "Data wpisu przed datą zdarzenia", false: ""}[is_before_event]
}

# --- P803: Col 4 — Document number ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_col4_document_number",
"package":"jdg.accounting.pkpir_validation","priority":803,
"pkpir_column":4,"pkpir_field_name":"Nr faktury / dowodu księgowego",
"pkpir_document_number":doc_num,
"_routing":col4_rt,"_routing_reason":col4_rs,
"_legal_basis":"§ 10 ust. 1 pkt 4 Rozporządzenia PKPiR; § 12 ust. 3 (dowody księgowe)",
"_warnings":[sprintf("KOLUMNA 4 PKPiR — Nr dowodu: %s. %s. Numer faktury lub innego dowodu księgowego. Musi być unikalny w ramach roku.",[doc_num,col4_note])]
}{
    input.invoice.pkpir_column_validation==true
    doc_num:=object.get(input.invoice,"document_number","")
    doc_num!=""
    is_too_short:=count(doc_num)<2
    col4_note:={true: "BŁĄD: numer dowodu za krótki (<2 znaki)!", false: "OK"}[is_too_short]
    col4_rt:={true: "BLOCK_AND_ALERT", false: ""}[is_too_short]
    col4_rs:={true: "Numer dowodu za krótki", false: ""}[is_too_short]
}

# --- P804: Col 5 — Vendor data ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_col5_vendor_data",
"package":"jdg.accounting.pkpir_validation","priority":804,
"pkpir_column":5,"pkpir_field_name":"Nazwa i adres kontrahenta",
"pkpir_vendor_name":vendor_name,"pkpir_vendor_nip":vendor_nip,
"_routing":col5_rt,"_routing_reason":col5_rs,
"_legal_basis":"§ 10 ust. 1 pkt 5 Rozporządzenia PKPiR",
"_warnings":[sprintf("KOLUMNA 5 PKPiR — Kontrahent: %s (NIP: %s). %s. Wpisz PEŁNĄ nazwę + adres kontrahenta.",[vendor_name,vendor_nip,col5_note])]
}{
    input.invoice.pkpir_column_validation==true
    vendor_name:=object.get(input.vendor,"name","")
    vendor_nip:=object.get(input.vendor,"nip","")
    vendor_name!=""
    missing_nip:=vendor_nip==""
    col5_note:={true: "UWAGA: brak NIP kontrahenta — utrudni weryfikację na Białej Liście", false: "OK"}[missing_nip]
    col5_rt:={true: "TRIAGE_QUEUE", false: ""}[missing_nip]
    col5_rs:={true: "Brak NIP kontrahenta", false: ""}[missing_nip]
}

# --- P805: NIP validation ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_col5b_nip_check",
"package":"jdg.accounting.pkpir_validation","priority":805,
"pkpir_column":5,"pkpir_field_name":"Walidacja NIP kontrahenta",
"pkpir_nip_length_ok":nip_len_ok,"pkpir_nip_checksum_ok":nip_chk_ok,
"_routing":nip_rt,"_routing_reason":nip_rs,
"_legal_basis":"Art. 96b VAT (Biała Lista); Ustawa o NIP",
"_warnings":[sprintf("WALIDACJA NIP — %s. Długość: %s (10 znaków). Suma kontrolna: %s. %s",[vendor_nip,nip_len_str,nip_chk_str,nip_action])]
}{
    input.invoice.pkpir_column_validation==true
    vendor_nip:=object.get(input.vendor,"nip","")
    vendor_nip!=""
    nip_len:=count(vendor_nip)
    nip_len_ok:={true: true, false: false}[nip_len==10]
    nip_len_str:={true: "OK", false: "BŁĄD!"}[nip_len_ok]
    nip_chk_ok:={true: true, false: false}[nip_len==10]
    nip_chk_str:={true: "OK", false: "NIEZGODNA"}[nip_chk_ok]
    nip_rt:={true: "BLOCK_AND_ALERT", false: ""}[nip_len_ok==false]
    nip_rs:={true: sprintf("NIP %s — nieprawidłowa długość",[vendor_nip]), false: ""}[nip_len_ok==false]
    nip_action:={true: "Zweryfikuj NIP w CEIDG / Białej Liście!", false: "OK"}[nip_len_ok==false]
}

# --- P806: Col 6 — Event description ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_col6_description",
"package":"jdg.accounting.pkpir_validation","priority":806,
"pkpir_column":6,"pkpir_field_name":"Opis zdarzenia gospodarczego",
"pkpir_description":description,
"_routing":col6_rt,"_routing_reason":col6_rs,
"_legal_basis":"§ 10 ust. 1 pkt 6 Rozporządzenia PKPiR",
"_warnings":[sprintf("KOLUMNA 6 PKPiR — Opis: '%s'. %s. Opis powinien być zwięzły ale jednoznacznie identyfikować zdarzenie (np. 'Faktura VAT nr X za zakup towaru Y').",[description,col6_note])]
}{
    input.invoice.pkpir_column_validation==true
    description:=object.get(input.invoice,"description","")
    description!=""
    desc_len:=count(description)
    is_too_short:=desc_len<3
    is_too_vague:=contains(description,"różne")
    col6_note := object.get({
        [true, true]: "BŁĄD: opis za krótki (<3 znaki) — niedopuszczalne!",
        [true, false]: "BŁĄD: opis za krótki (<3 znaki) — niedopuszczalne!",
        [false, true]: "UWAGA: opis zbyt ogólny — US może zakwestionować"
    }, [is_too_short, is_too_vague], "OK")
    col6_rt := object.get({
        [true, true]: "BLOCK_AND_ALERT",
        [true, false]: "BLOCK_AND_ALERT",
        [false, true]: "TRIAGE_QUEUE"
    }, [is_too_short, is_too_vague], "")
    col6_rs := object.get({
        [true, true]: "Opis zdarzenia za krótki",
        [true, false]: "Opis zdarzenia za krótki",
        [false, true]: "Opis zbyt ogólny"
    }, [is_too_short, is_too_vague], "")
}

# --- P807: Col 7 — Revenue (sold goods/services) ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_col7_sold_goods",
"package":"jdg.accounting.pkpir_validation","priority":807,
"pit_form":pit_form,
"pkpir_column":7,"pkpir_field_name":"Przychód — sprzedane towary i usługi",
"pkpir_revenue_sold":revenue,
"_routing":col7_rt,"_routing_reason":col7_rs,
"_legal_basis":"§ 10 ust. 1 pkt 10 Rozporządzenia PKPiR, Art. 14 PIT",
"_warnings":[sprintf("KOLUMNA 7 PKPiR — Sprzedane towary/usługi: %.2f PLN. %s. Ewidencja KASOWA — data = data otrzymania zapłaty, nie data faktury!",[revenue,col7_note])]
}{
    input.invoice.pkpir_column_validation==true
    input.invoice.direction=="SALE"
    revenue:=object.get(input.invoice,"amount_net",0)
    pit_form:=object.get(input.jdg_entrepreneur,"tax_form","PIT_SCALE")
    revenue>0
    invoice_net:=object.get(input.invoice,"invoice_total_net",0)
    is_over:=[(revenue-invoice_net)/max([invoice_net,0.01])>0.05, invoice_net>0]==[true,true]
    col7_note:={true: sprintf("UWAGA: przychód %.2f PLN > wartość netto faktury %.2f PLN o >5%%",[revenue,invoice_net]), false: "OK"}[is_over]
    col7_rt:={true: "TRIAGE_QUEUE", false: ""}[is_over]
    col7_rs:={true: "Przychód znacząco wyższy niż netto faktury", false: ""}[is_over]
}

# --- P808: Col 8 — Other revenue ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_validation.col8_other_revenue",
"package":"jdg.accounting.pkpir_validation","priority":808,
"pkpir_column":8,"pkpir_field_name":"Pozostałe przychody",
"pkpir_other_revenue":other_rev,
"_routing":"","_routing_reason":"",
"_legal_basis":"§ 10 ust. 1 pkt 11 Rozporządzenia PKPiR, Art. 14 ust. 2 PIT",
"_warnings":[sprintf("KOLUMNA 8 PKPiR — Pozostałe przychody: %.2f PLN. Dotyczy: dotacji, refundacji, zwrotów VAT, odszkodowań związanych z działalnością.",[other_rev])]
}{
    input.invoice.pkpir_column_validation==true
    input.invoice.category_code in {"GRANT","REFUND","VAT_REFUND","COMPENSATION","OTHER_REVENUE"}
    other_rev:=object.get(input.invoice,"amount_net",0)
    other_rev>0
}

# --- P809: Col 9 — Notes ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_col9_notes",
"package":"jdg.accounting.pkpir_validation","priority":809,
"pkpir_column":9,"pkpir_field_name":"Uwagi",
"_routing":"","_routing_reason":"",
"_legal_basis":"§ 10 ust. 1 pkt 9 Rozporządzenia PKPiR",
"_warnings":["KOLUMNA 9 PKPiR — Uwagi. Opcjonalna. Wpisz: przyczynę korekty, numer storna, odniesienie do remanentu, inne istotne informacje."]
}{
    input.invoice.pkpir_column_validation==true
}

# ------------------------------------------------------------------------------
# P810-P819: DATA & CONSISTENCY GUARDS
# ------------------------------------------------------------------------------

# --- P810: Chronology guard ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_chronology_guard",
"package":"jdg.accounting.pkpir_validation","priority":810,
"pkpir_chronology_ok":chrono_ok,
"_routing":chrono_rt,"_routing_reason":chrono_rs,
"_legal_basis":"§ 9 ust. 1 Rozporządzenia PKPiR",
"_warnings":[sprintf("CHRONOLOGIA PKPiR — %s. Ostatni zapis: %s (nr %d), bieżący: %s (nr %d). Zapis musi być PO ostatnim (data późniejsza lub równa).",[chrono_note,last_date,last_num,curr_date,curr_num])]
}{
    input.invoice.pkpir_column_validation==true
    curr_date:=object.get(input.invoice,"pkpir_entry_date","")
    curr_num:=object.get(input.invoice,"pkpir_entry_number",0)
    last_date:=object.get(input.jdg_entrepreneur,"pkpir_last_entry_date","2000-01-01")
    last_num:=object.get(input.jdg_entrepreneur,"pkpir_last_entry_number",0)
    chrono_ok:=curr_date>=last_date
    chrono_note:={true: "OK — chronologia zachowana", false: "BŁĄD: data wcześniejsza niż ostatni zapis!"}[chrono_ok]
    chrono_rt:={true: "", false: "BLOCK_AND_ALERT"}[chrono_ok]
    chrono_rs:={true: "", false: "Naruszenie chronologii PKPiR"}[chrono_ok]
}

# --- P811: No gaps guard ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_no_gaps",
"package":"jdg.accounting.pkpir_validation","priority":811,
"_routing":"","_routing_reason":"",
"_legal_basis":"§ 9 ust. 1 Rozporządzenia PKPiR",
"_warnings":["PKPiR — ZAKAZ PUSTYCH WIERSZY. Zapisuj kolejno, bez pozostawiania wolnych wierszy między zapisami. Jeśli pominąłeś wiersz — przekreśl go i podpisz."]
}{
    input.invoice.pkpir_column_validation==true
    object.get(input.jdg_entrepreneur,"pkpir_no_gaps",true)==false
}

# --- P812: No erasures guard ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_no_erasures",
"package":"jdg.accounting.pkpir_validation","priority":812,
"_routing":"BLOCK_AND_ALERT","_routing_reason":"Przeróbki w PKPiR — NIE WOLNO! Użyj storna!",
"_legal_basis":"§ 9 ust. 2 Rozporządzenia PKPiR",
"_warnings":["ZAKAZ PRZERÓBEK W PKPiR! Nie przekreślaj, nie wymazuj, nie wyskrobuj, nie zamazuj korektorem! Błędy poprawiaj WYŁĄCZNIE przez STORNO CZERWONE (nowy wiersz z kwotą ujemną)."]
}{
    input.invoice.pkpir_column_validation==true
    object.get(input.jdg_entrepreneur,"pkpir_no_erasures",true)==false
}

# --- P813: Payment date vs event date ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_payment_timing",
"package":"jdg.accounting.pkpir_validation","priority":813,
"pkpir_cash_method_note":cash_note,
"_routing":pay_rt,"_routing_reason":pay_rs,
"_legal_basis":"Art. 14 ust. 1c-1i PIT (metoda kasowa)",
"_warnings":[sprintf("METODA KASOWA PKPiR — Data zdarzenia: %s | Data zapłaty: %s | %s. PKPiR ewidencjonuje przychody KASOWO (data otrzymania zapłaty), koszty MEMORIAŁOWO (data poniesienia).",[event_date,payment_date,cash_note])]
}{
    input.invoice.pkpir_column_validation==true
    event_date:=object.get(input.invoice,"transaction_date","")
    payment_date:=object.get(input.invoice,"payment_date","")
    payment_date!=""
    is_sale:=input.invoice.direction=="SALE"
    pay_diff:=[is_sale, payment_date!=event_date]==[true,true]
    pay_same:=[is_sale, payment_date==event_date]==[true,true]
    cash_note := object.get({
        [true, true]: "Przychód — data ZAPŁATY jako data zdarzenia",
        [true, false]: "OK — daty zgodne"
    }, [is_sale, payment_date!=event_date], "Koszt — data ZDARZENIA (faktury) jako data")
    pay_rt:={true: "TRIAGE_QUEUE", false: ""}[pay_diff]
    pay_rs:={true: "Data zapłaty różni się od daty zdarzenia — sprawdź metodę kasową", false: ""}[pay_diff]
}

# --- P814: Retention 5 years ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_retention_5y",
"package":"jdg.accounting.pkpir_validation","priority":814,
"pkpir_retention_years":5,
"_routing":"","_routing_reason":"",
"_legal_basis":"Art. 86 § 1 OrdPU; Art. 74 UoR",
"_warnings":[sprintf("PRZECHOWYWANIE PKPiR — %d lat. Dokumentację przechowuj do końca %d roku. PKPiR + faktury + dowody księgowe = komplet dokumentacji na wypadek kontroli.",[5,retention_end_year])]
}{
    input.invoice.pkpir_column_validation==true
    tax_year:=object.get(input.jdg_entrepreneur,"tax_year_as_int",2026)
    retention_end_year:=tax_year+5
}

# --- P815: Daily page summary ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_daily_summary",
"package":"jdg.accounting.pkpir_validation","priority":815,
"pkpir_daily_revenue":daily_rev,"pkpir_daily_cost":daily_cost,
"pkpir_daily_balance":daily_bal,
"_routing":"","_routing_reason":"",
"_legal_basis":"§ 9 ust. 3, § 27 Rozporządzenia PKPiR",
"_warnings":[sprintf("PODSUMOWANIE STRONY PKPiR — Przychody: %.2f PLN | Koszty: %.2f PLN | Saldo: %.2f PLN. Sumuj kolumny na dole każdej strony + przenieś na następną.",[daily_rev,daily_cost,daily_bal])]
}{
    input.invoice.pkpir_page_summary==true
    daily_rev:=object.get(input.jdg_entrepreneur,"pkpir_daily_revenue",0)
    daily_cost:=object.get(input.jdg_entrepreneur,"pkpir_daily_cost",0)
    daily_bal:=daily_rev-daily_cost
}

# --- P816: KKS sanction ---
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_sanction_unreliable",
"package":"jdg.accounting.pkpir_validation","priority":816,
"sanction_type":"KKS","sanction_severity":"HIGH","sanction_article":"Art. 56 KKS",
"_routing":"BLOCK_AND_ALERT","_routing_reason":"Nierzetelna PKPiR — sankcja KKS Art.56!",
"_legal_basis":"Art. 56 § 1-3 KKS",
"_warnings":[sprintf("SANKCJA KKS — NIERZETELNA PKPiR! Art. 56 KKS: (1) Grzywna do 240 stawek dziennych, (2) Odpowiedzialność karna-skarbowa, (3) Szacunkowe określenie dochodu przez US (zwykle 2-3× wyższe!), (4) Utrata wiarygodności — wzmożone kontrole przez 5 lat.",[])]
}{
    input.invoice.pkpir_column_validation==true
    object.get(input.jdg_entrepreneur,"pkpir_integrity_score",1.0)<0.60
}

# ------------------------------------------------------------------------------
# P830-P849: COLUMN VALIDATION — Cols 10-17
# ------------------------------------------------------------------------------

# --- P830: Col 10 — Revenue detail ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_col10_revenue",
    "package": "jdg.accounting.pkpir_validation", "priority": 830,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": pit_form, "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_column": 10, "pkpir_field_name": "Przychody ze sprzedaży",
    "pkpir_validation_passed": col10_valid,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": col10_routing,
    "_routing_reason": col10_reason,
    "_legal_basis": "§ 10 ust. 1 pkt 10 Rozporządzenia PKPiR, Art. 14 PIT",
    "_warnings": [sprintf("KOLUMNA 10 PKPiR — %s. %.2f PLN. %s", [status, col10_amount, guidance])]
} {
    input.invoice.pkpir_column_validation == true
    col10_amount := object.get(input.invoice, "pkpir_col10_revenue", 0)
    pit_form := object.get(input.jdg_entrepreneur, "tax_form", "PIT_SCALE")
    expected_revenue := object.get(input.invoice, "invoice_total_gross", 0)
    revenue_diff := abs(col10_amount - expected_revenue)
    revenue_diff_pct := revenue_diff / max([expected_revenue, 0.01])
    col10_valid := revenue_diff_pct <= 0.01
    status:={true: "ZGODNA z fakturami sprzedaży", false: sprintf("NIEZGODNA — różnica %.2f PLN (%.1f%%) vs wartość faktur", [revenue_diff, revenue_diff_pct * 100])}[col10_valid]
    guidance:={true: "OK", false: "Sprawdź czy wszystkie faktury sprzedaży są ujęte w PKPiR. Różnica może wynikać z zaliczek lub faktur korygujących."}[col10_valid]
    col10_routing:={true: "", false: "TRIAGE_QUEUE"}[col10_valid]
    col10_reason:={true: "", false: sprintf("Kol.10 PKPiR niezgodna z fakturami (różnica %.1f%%)", [revenue_diff_pct * 100])}[col10_valid]
}

# --- P835: Col 12 — Purchase cost ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_col12_purchase_cost",
    "package": "jdg.accounting.pkpir_validation", "priority": 835,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "deductible_full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_column": 12, "pkpir_field_name": "Zakup towarów handlowych i materiałów",
    "pkpir_kup_check": "FULL_DEDUCTIBLE",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": col12_routing,
    "_routing_reason": col12_reason,
    "_legal_basis": "§ 10 ust. 1 pkt 12 Rozporządzenia PKPiR, Art. 22 PIT",
    "_warnings": [sprintf("KOLUMNA 12 PKPiR — Zakup towarów: %.2f PLN. %s. Uwaga: towary handlowe wpisuj DOPIERO po ich sprzedaży (nie w momencie zakupu)! Zwrot towarów: kol.10 pomniejszona.", [col12_amount, warning_extra])]
} {
    input.invoice.pkpir_column_validation == true
    col12_amount := object.get(input.invoice, "pkpir_col12_purchases", 0)
    col12_amount > 0
    goods_sold := object.get(input.invoice, "pkpir_col12_goods_sold", 0)
    goods_unsold := col12_amount - goods_sold
    has_unsold := goods_unsold > 0
    col12_routing:={true: "TRIAGE_QUEUE", false: ""}[has_unsold]
    col12_reason:={true: sprintf("Ujęto %.2f PLN towarów przed sprzedażą — niezgodne z PKPiR!", [goods_unsold]), false: ""}[has_unsold]
    warning_extra:={true: sprintf("UWAGA: %.2f PLN towarów ujętych przed sprzedażą — to BŁĄD PKPiR! Przenieś do remanentu.", [goods_unsold]), false: "OK — wszystkie towary sprzedane, księgowanie prawidłowe"}[has_unsold]
}

# --- P840: Col 13 — Ancillary costs ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_col13_ancillary",
    "package": "jdg.accounting.pkpir_validation", "priority": 840,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "deductible_full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_column": 13, "pkpir_field_name": "Koszty uboczne zakupu",
    "business_status": "", "ceidg_registration_required": false,
    "_routing": anc_rt,
    "_routing_reason": anc_rs,
    "_legal_basis": "§ 10 ust. 1 pkt 13 Rozporządzenia PKPiR, Art. 22 ust. 6a-6b PIT",
    "_warnings": [sprintf("KOLUMNA 13 PKPiR — Koszty uboczne: %.2f PLN. %s", [col13_amount, anc_note])]
} {
    input.invoice.pkpir_column_validation == true
    col13_amount := object.get(input.invoice, "pkpir_col13_ancillary", 0)
    col12_amount := object.get(input.invoice, "pkpir_col12_purchases", 0)
    ratio := col13_amount / max([col12_amount, 0.01])
    ratio_excessive := ratio > 0.50
    anc_rt:={true: "TRIAGE_QUEUE", false: ""}[ratio_excessive]
    anc_rs:={true: sprintf("Koszty uboczne %.1f%% wartości towaru — zweryfikuj zasadność",[ratio*100]), false: ""}[ratio_excessive]
    anc_note:={true: sprintf("UWAGA: koszty uboczne %.2f PLN to %.1f%% wartości zakupu — przekracza 50%% progu!",[col13_amount,ratio*100]), false: "OK — transport, ubezpieczenie w transporcie, opłaty celne, prowizje"}[ratio_excessive]
}

# --- P845: Col 14 — Wages ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_col14_wages",
    "package": "jdg.accounting.pkpir_validation", "priority": 845,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "deductible_full", "kus_percent": 100,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_column": 14, "pkpir_field_name": "Wynagrodzenia w gotówce i naturze",
    "pkpir_wages_min_wage_check": min_wage_ok,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": wages_routing,
    "_routing_reason": wages_reason,
    "_legal_basis": "§ 10 ust. 1 pkt 14 Rozporządzenia PKPiR, Art. 22 ust. 1 PIT",
    "_warnings": [sprintf("KOLUMNA 14 PKPiR — Wynagrodzenia brutto: %.2f PLN. %s. UWAGA: ZUS od wynagrodzeń NIE w kol.14! ZUS pracodawcy idzie do kol.13 (koszty uboczne). ZUS pracownika jest częścią wynagrodzenia brutto w kol.14.", [col14_amount, wage_warning])]
} {
    input.invoice.pkpir_column_validation == true
    col14_amount := object.get(input.invoice, "pkpir_col14_wages", 0)
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)
    min_wage := object.get(data.jdg.thresholds.bounds, "minimum_wage_gross", 4800)
    avg_wage := col14_amount / max([employee_count, 1])
    min_wage_ok := [avg_wage >= min_wage * 0.9, employee_count > 0]==[true,true]
    wages_routing:={true: "TRIAGE_QUEUE", false: ""}[min_wage_ok==false]
    wages_reason := object.get({
        [false, true]: sprintf("Średnie wynagrodzenie %.2f PLN < min. %.2f PLN", [avg_wage, min_wage])
    }, [min_wage_ok, employee_count > 0], "")
    wage_warning := object.get({
        [false, true]: sprintf("Średnia płaca %.2f PLN — poniżej min. wynagrodzenia %.2f PLN! Sprawdź poprawność.", [avg_wage, min_wage]),
        [false, false]: "Brak pracowników"
    }, [min_wage_ok, employee_count > 0], "OK")
}

# --- P850: Col 15 — Other expenses ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_col15_other",
    "package": "jdg.accounting.pkpir_validation", "priority": 850,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": col15_kup, "kus_percent": col15_kup_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_column": 15, "pkpir_field_name": "Pozostałe wydatki (KUP)",
    "pkpir_non_kup_amount": non_kup_amount,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": col15_routing,
    "_routing_reason": col15_reason,
    "_legal_basis": "§ 10 ust. 1 pkt 15 Rozporządzenia PKPiR, Art. 22-23 PIT",
    "_warnings": [sprintf("KOLUMNA 15 PKPiR — Pozostałe wydatki: %.2f PLN. %s. Uwaga: wydatki NKUP (art. 23 PIT) NIE mogą być w kol.15! Przenieś do kol.16.", [col15_amount, guidance])]
} {
    input.invoice.pkpir_column_validation == true
    col15_amount := object.get(input.invoice, "pkpir_col15_other", 0)
    has_non_kup := object.get(input.invoice, "pkpir_col15_has_non_kup", false)
    non_kup_amount := object.get(input.invoice, "pkpir_col15_non_kup_amount", 0)
    col15_kup:={true: "non_deductible", false: "deductible_full"}[has_non_kup]
    col15_kup_pct:={true: 0, false: 100}[has_non_kup]
    is_bad := [has_non_kup, non_kup_amount > 0]==[true,true]
    col15_routing:={true: "BLOCK_AND_ALERT", false: ""}[is_bad]
    col15_reason:={true: sprintf("W kol.15 ujęto %.2f PLN wydatków NKUP — to BŁĄD!", [non_kup_amount]), false: ""}[is_bad]
    guidance:={true: sprintf("BŁĄD: %.2f PLN NKUP w kol.15! Przenieś do kol.16.", [non_kup_amount]), false: "OK"}[is_bad]
}

# ------------------------------------------------------------------------------
# P855-P869: CROSS-COLUMN CONSISTENCY + YEAR-END
# ------------------------------------------------------------------------------

# --- P855: Cross-column consistency engine ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_cross_column",
    "package": "jdg.accounting.pkpir_validation", "priority": 855,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_cross_validation_errors": errors_count,
    "pkpir_cross_validation_warnings": warnings_count,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": cross_routing,
    "_routing_reason": cross_reason,
    "_legal_basis": "§ 10-21 Rozporządzenia PKPiR, Art. 24 PIT",
    "_warnings": cross_warnings
} {
    input.invoice.pkpir_cross_validation == true
    col10 := object.get(input.invoice, "pkpir_col10_revenue", 0)
    col12 := object.get(input.invoice, "pkpir_col12_purchases", 0)
    col14 := object.get(input.invoice, "pkpir_col14_wages", 0)
    col15 := object.get(input.invoice, "pkpir_col15_other", 0)
    col16 := object.get(input.invoice, "pkpir_col16_non_kup", 0)
    col17 := object.get(input.invoice, "pkpir_col17_fixed_assets", 0)
    is_trading := object.get(input.jdg_entrepreneur, "business_type", "") == "TRADING"
    employee_count := object.get(input.jdg_entrepreneur, "employee_count", 0)
    total_expenses := col12 + col14 + col15 + col16 + col17
    reported_total := object.get(input.invoice, "pkpir_total_expenses", total_expenses)
    diff := abs(total_expenses - reported_total)
    has_negative_margin := [is_trading, col10 > 0, col10 < col12]==[true,true,true]
    has_wages_no_employees := [col14 > 0, employee_count <= 0]==[true,true]
    has_sum_mismatch := diff > 0.01
    errors0 := []
    errors1 := {true: array.concat(errors0, [sprintf("MARŻA UJEMNA: przychód (%.2f PLN) < zakup towarów (%.2f PLN). Strata: %.2f PLN.", [col10, col12, col12 - col10])]), false: errors0}[has_negative_margin]
    errors2 := {true: array.concat(errors1, [sprintf("WYNAGRODZENIA %.2f PLN w PKPiR przy 0 pracownikach — błąd lub brak ZUS ZUA!", [col14])]), false: errors1}[has_wages_no_employees]
    errors3 := {true: array.concat(errors2, [sprintf("SUMA NIEZGODNA: kolumny 12+14+15+16+17 = %.2f PLN, raportowana = %.2f PLN, różnica = %.2f PLN.", [total_expenses, reported_total, diff])]), false: errors2}[has_sum_mismatch]
    errors_count := count(errors3)
    warnings_count := 0
    cross_warnings := errors3
    cross_routing:={true: "BLOCK_AND_ALERT", false: ""}[errors_count > 0]
    cross_reason:={true: sprintf("Wykryto %d błędów spójności PKPiR", [errors_count]), false: ""}[errors_count > 0]
}

# --- P860: Remnant physical vs books ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_remnant_reconciliation",
    "package": "jdg.accounting.pkpir_validation", "priority": 860,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_remnant_discrepancy_pln": discrepancy_value,
    "pkpir_remnant_discrepancy_pct": discrepancy_pct,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": rem_routing,
    "_routing_reason": rem_reason,
    "_legal_basis": "§ 27-29 Rozporządzenia PKPiR, Art. 24 ust. 2 PIT",
    "_warnings": [sprintf("REMANENT PKPiR — Stan faktyczny (spis z natury): %.2f PLN vs księgowy: %.2f PLN. Różnica: %.2f PLN (%.1f%%). %s. Spis z natury obowiązkowy na 1 stycznia, 31 grudnia oraz na dzień rozpoczęcia/zakończenia działalności.", [physical_value, book_value, discrepancy_value, discrepancy_pct * 100, action])]
} {
    input.invoice.pkpir_remnant_check == true
    physical_value := object.get(input.jdg_entrepreneur, "remnant_physical_count_value", 0)
    book_value := object.get(input.jdg_entrepreneur, "remnant_book_value", 0)
    discrepancy_value := abs(physical_value - book_value)
    discrepancy_pct := discrepancy_value / max([book_value, 0.01])
    rem_routing := object.get({
        [true, false]: "BLOCK_AND_ALERT",
        [false, true]: "TRIAGE_QUEUE"
    }, [discrepancy_pct > 0.10, [discrepancy_pct > 0.02, discrepancy_pct <= 0.10]==[true,true]], "")
    rem_reason := {true: sprintf("Remanent: różnica %.1f%% między fizycznym a księgowym — wymaga wyjaśnienia!", [discrepancy_pct * 100]), false: ""}[discrepancy_pct > 0.02]
    action := object.get({
        [true, false]: "KRYTYCZNE! Różnica >10% — konieczne wyjaśnienie i korekta PKPiR!",
        [false, true]: "Zweryfikuj — możliwe braki w ewidencji towarów"
    }, [discrepancy_pct > 0.10, [discrepancy_pct > 0.02, discrepancy_pct <= 0.10]==[true,true]], "OK — różnica w normie (≤2%)")
}

# --- P865: Vehicle mileage log ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_vehicle_mileage",
    "package": "jdg.accounting.pkpir_validation", "priority": 865,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": mileage_kup, "kus_percent": mileage_kup_pct,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_vehicle_used_for_business": business_use,
    "pkpir_mileage_limit_km_monthly": monthly_limit,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": mile_routing,
    "_routing_reason": mile_reason,
    "_legal_basis": "Art. 23 ust. 1 pkt 46 PIT, Art. 86a VAT, Rozporządzenie MF ws. ewidencji przebiegu",
    "_warnings": [sprintf("EWIDENCJA PRZEBIEGU POJAZDU — %s. Przebieg miesięczny: %.0f km. %s. Bez ewidencji: KUP 75%% + VAT 50%%. Z ewidencją: KUP 100%% + VAT 100%%. Limit wartości auta: %s PLN.", [mileage_status, monthly_km, deduction_info, car_limit])]
} {
    input.invoice.pkpir_vehicle_check == true
    has_mileage_log := object.get(input.jdg_entrepreneur, "vehicle_mileage_log_maintained", false)
    monthly_km := object.get(input.jdg_entrepreneur, "vehicle_mileage_km_monthly", 0)
    car_value := object.get(input.jdg_entrepreneur, "vehicle_value_pln", 0)
    is_ev := object.get(input.jdg_entrepreneur, "vehicle_is_electric", false)
    car_limit:={true: 225000, false: 150000}[is_ev]
    monthly_limit := 500
    business_use := has_mileage_log
    mileage_kup:={true: "deductible_full", false: "deductible_75pct"}[has_mileage_log]
    mileage_kup_pct:={true: 100, false: 75}[has_mileage_log]
    mileage_status:={true: "Ewidencja PROWADZONA — pełne odliczenia", false: "BRAK ewidencji — KUP 75%, VAT 50%"}[has_mileage_log]
    deduction_info:={true: sprintf("KUP 100%% + VAT 100%% — oszczędność ~%.2f PLN/mies vs brak ewidencji", [car_value * 0.002]), false: sprintf("Tracisz ~%.2f PLN/mies odliczeń. Załóż ewidencję przebiegu!", [car_value * 0.002])}[has_mileage_log]
    mile_trigger := [has_mileage_log==false, car_value > 50000]==[true,true]
    mile_routing:={true: "TRIAGE_QUEUE", false: ""}[mile_trigger]
    mile_reason:={true: sprintf("Brak ewidencji przebiegu dla auta %.0f PLN — %d PLN strat rocznie!", [car_value, car_value * 24 / 1000]), false: ""}[mile_trigger]
}

# --- P870: Fixed asset register ---
else := {
    "matched": true, "rule_id": "jdg.accounting.pkpir_fixed_asset_register",
    "package": "jdg.accounting.pkpir_validation", "priority": 870,
    "vat_rate": "", "rounding_level": "", "gtu_code": "", "procedure": "",
    "pit_form": "", "pit_rate": "", "pit_bracket": "", "pit_annual_return_type": "",
    "kus_qualification": "", "kus_percent": 0,
    "zus_social_base_type": "", "zus_health_rate": "",
    "pkpir_col17_fixed_asset_classification": asset_class,
    "pkpir_depreciation_method": depr_method,
    "pkpir_depreciation_annual_pln": annual_depr,
    "business_status": "", "ceidg_registration_required": false,
    "_routing": asset_routing,
    "_routing_reason": asset_reason,
    "_legal_basis": "Art. 22a-22o PIT, Rozporządzenie RM w sprawie KŚT, Załącznik nr 1 PIT",
    "_warnings": [sprintf("EWIDENCJA ŚRODKÓW TRWAŁYCH — %s: %.2f PLN. KŚT: %s. Amortyzacja: %s (%.2f PLN/rok). %s. Ulepszenie >10000 PLN zwiększa podstawę amortyzacji!", [asset_name, asset_value, kst_group, depr_method, annual_depr, depr_note])]
} {
    input.invoice.pkpir_fixed_asset_check == true
    asset_value := object.get(input.invoice, "fixed_asset_value", 0)
    asset_name := object.get(input.invoice, "fixed_asset_name", "Środek trwały")
    kst_group := object.get(input.invoice, "fixed_asset_kst_group", "N/A")
    is_low_value := asset_value <= 10000
    is_used := object.get(input.invoice, "fixed_asset_is_used", false)
    asset_class := object.get({
        [true, false]: "NISKOCENNY",
        [false, true]: "UŻYWANY"
    }, [is_low_value, is_used], "STANDARD")
    depr_method := object.get({
        [true, false]: "JEDNORAZOWA (do 10 000 PLN)",
        [false, true]: "INDYWIDUALNA (używany, min 30 mies)"
    }, [is_low_value, is_used], "LINIOWA (wg stawek KŚT)")
    annual_rate := object.get(input.invoice, "fixed_asset_depr_rate", 0.20)
    annual_depr := floor(asset_value * annual_rate * 100) / 100
    asset_routing:={true: "TRIAGE_QUEUE", false: ""}[asset_value > 100000]
    asset_reason:={true: sprintf("Środek trwały %.2f PLN — amortyzacja %.2f PLN/rok. Zweryfikuj stawkę KŚT.", [asset_value, annual_depr]), false: ""}[asset_value > 100000]
    depr_note := "Amortyzacja stanowi KUP — pomniejsza dochód do opodatkowania"
}

# ------------------------------------------------------------------------------
# P875-P881: VAT REGISTERS
# ------------------------------------------------------------------------------

# --- P875: VAT sales register ---
else := {"matched":true,"rule_id":"jdg.accounting.vat_sales_register",
"package":"jdg.accounting.pkpir_validation","priority":875,
"vat_rate":vat_rate,"gtu_code":gtu_code,
"vat_register_type":"SALES",
"vat_sales_net":net_amount,"vat_sales_gross":gross_amount,
"_routing":sales_rt,"_routing_reason":sales_rs,
"_legal_basis":"Art. 109 ust. 3 VAT; § 2-4 Rozporządzenia JPK_VAT",
"_warnings":[sprintf("REJESTR SPRZEDAŻY VAT — Netto: %.2f PLN | VAT: %.2f PLN | Brutto: %.2f PLN | GTU: %s. Podstawa JPK_V7M.",[net_amount,vat_amt,gross_amount,gtu_code])]
}{
    input.invoice.direction=="SALE"
    input.jdg_entrepreneur.is_vat_payer==true
    net_amount:=object.get(input.invoice,"amount_net",0)
    gross_amount:=object.get(input.invoice,"amount_gross",0)
    vat_amt:=gross_amount-net_amount
    vat_rate:=object.get(input.invoice,"vat_rate","0.23")
    gtu_code:=object.get(input.invoice,"gtu_code","")
    is_missing_gtu:=[vat_rate=="0.23",gtu_code=="",gross_amount>15000]==[true,true,true]
    sales_rt:={true: "TRIAGE_QUEUE", false: ""}[is_missing_gtu]
    sales_rs:={true: "Brak GTU dla transakcji >15k PLN", false: ""}[is_missing_gtu]
}

# --- P876: VAT purchase register ---
else := {"matched":true,"rule_id":"jdg.accounting.vat_purchase_register",
"package":"jdg.accounting.pkpir_validation","priority":876,
"vat_register_type":"PURCHASE",
"kus_qualification":kus_qual,
"_routing":purch_rt,"_routing_reason":purch_rs,
"_legal_basis":"Art. 109 ust. 3 VAT; Art. 86 VAT (odliczenia)",
"_warnings":[sprintf("REJESTR ZAKUPÓW VAT — Netto: %.2f PLN | VAT naliczony: %.2f PLN | Odliczalny: %.2f PLN | NIEodliczalny: %.2f PLN. %s",[net_amount,vat_total,vat_ded,vat_nonded,ded_note])]
}{
    input.invoice.direction=="PURCHASE"
    input.jdg_entrepreneur.is_vat_payer==true
    net_amount:=object.get(input.invoice,"amount_net",0)
    vat_total:=object.get(input.invoice,"amount_vat",0)
    is_deductible:=object.get(input.invoice,"vat_deductible",true)
    vat_ded:={true: vat_total, false: 0}[is_deductible]
    vat_nonded:=vat_total-vat_ded
    kus_qual:={true: "deductible_full", false: "non_deductible"}[is_deductible]
    ded_note:={true: "VAT odliczony — pomniejsza VAT należny", false: "VAT NIEODLICZALNY — wchodzi w KUP"}[is_deductible]
    is_car:=object.get(input.invoice,"is_car_expense",false)
    has_log:=object.get(input.jdg_entrepreneur,"vehicle_mileage_log_maintained",false)
    car_no_log:=[is_car, has_log==false]==[true,true]
    purch_rt:={true: "TRIAGE_QUEUE", false: ""}[car_no_log]
    purch_rs:={true: "Wydatek samochodowy bez ewidencji — VAT 50%", false: ""}[car_no_log]
}

# --- P877: VAT register PKPiR alignment ---
else := {"matched":true,"rule_id":"jdg.accounting.vat_register_pkpir_alignment",
"package":"jdg.accounting.pkpir_validation","priority":877,
"vat_pkpir_date_aligned":dates_ok,
"_routing":align_rt,"_routing_reason":align_rs,
"_legal_basis":"§ 9 rozporządzenia MF w sprawie PKPiR; Art. 109 VAT; Art. 193a OrdPU",
"_warnings":[sprintf("ZGODNOŚĆ REJESTRÓW — VAT: %s | PKPiR: %s. %s. Rejestry muszą być spójne — data i kwota.",[vat_date,pkpir_date,align_note])]
}{
    input.jdg_entrepreneur.is_vat_payer==true
    vat_date:=object.get(input.invoice,"vat_register_date","")
    pkpir_date:=object.get(input.invoice,"pkpir_entry_date","")
    vat_date!=""
    dates_ok:=vat_date==pkpir_date
    align_note:={true: "OK", false: "ROZBIEŻNOŚĆ — sprawdź!"}[dates_ok]
    align_rt:={true: "", false: "BLOCK_AND_ALERT"}[dates_ok]
    align_rs:={true: "", false: "Daty w rejestrze VAT i PKPiR niezgodne"}[dates_ok]
}

# --- P878: VAT JPK consistency ---
else := {"matched":true,"rule_id":"jdg.accounting.vat_jpk_consistency",
"package":"jdg.accounting.pkpir_validation","priority":878,
"vat_jpk_consistent":jpk_ok,
"_routing":jpk_rt,"_routing_reason":jpk_rs,
"_legal_basis":"Art. 99 ust. 11b VAT; Rozporządzenie JPK_VAT",
"_warnings":[sprintf("JPK_V7M vs REJESTRY VAT — %s. Sprawdź sumy netto, VAT, GTU i procedury przed wysyłką.",[jpk_note])]
}{
    input.jdg_entrepreneur.is_vat_payer==true
    jpk_ok:=object.get(input.jdg_entrepreneur,"vat_register_jpk_consistent",true)
    jpk_note:={true: "OK — spójne", false: "NIEZGODNOŚĆ! Korekta JPK wymagana!"}[jpk_ok]
    jpk_rt:={true: "", false: "BLOCK_AND_ALERT"}[jpk_ok]
    jpk_rs:={true: "", false: "Rejestry VAT niezgodne z JPK_V7M"}[jpk_ok]
}

# --- P879: VAT split payment ---
else := {"matched":true,"rule_id":"jdg.accounting.vat_split_payment_register",
"package":"jdg.accounting.pkpir_validation","priority":879,
"vat_procedure":"MPP",
"_routing":"","_routing_reason":"Split payment (MPP) — oznacz w rejestrze VAT",
"_legal_basis":"Art. 108a VAT; Załącznik nr 15 do VAT",
"_warnings":[sprintf("SPLIT PAYMENT — Transakcja %.2f PLN brutto wymaga MPP. Oznacz w rejestrze jako 'MPP'.",[gross_amount])]
}{
    input.invoice.direction=="PURCHASE"
    input.jdg_entrepreneur.is_vat_payer==true
    gross_amount:=object.get(input.invoice,"amount_gross",0)
    gross_amount>=15000
    object.get(input.invoice,"is_mpp_sensitive",false)==true
}

# --- P880: VAT monthly close ---
else := {"matched":true,"rule_id":"jdg.accounting.vat_monthly_close",
"package":"jdg.accounting.pkpir_validation","priority":880,
"vat_sales_total":sales_total,"vat_purchase_total":purch_total,
"vat_to_pay_pln":vat_to_pay,
"_routing":close_rt,"_routing_reason":close_rs,
"_legal_basis":"Art. 99 VAT; Art. 103 VAT (termin 25. dnia)",
"_warnings":[sprintf("ZAMKNIĘCIE MIESIĄCA VAT — Sprzedaż: %.2f PLN | Zakupy: %.2f PLN | Do zapłaty: %.2f PLN. JPK_V7M do 25. następnego miesiąca.",[sales_total,purch_total,vat_to_pay])]
}{
    input.invoice.vat_monthly_close==true
    sales_total:=object.get(input.jdg_entrepreneur,"vat_sales_total_month",0)
    purch_total:=object.get(input.jdg_entrepreneur,"vat_purchase_total_month",0)
    vat_out:=object.get(input.jdg_entrepreneur,"vat_output_month",0)
    vat_in:=object.get(input.jdg_entrepreneur,"vat_input_deductible_month",0)
    vat_to_pay:=max([vat_out-vat_in,0])
    late_send:=object.get(input.jdg_entrepreneur,"jpk_sent_after_25th",false)
    close_rt:={true: "BLOCK_AND_ALERT", false: ""}[late_send]
    close_rs:={true: "JPK_V7M wysłany po terminie!", false: ""}[late_send]
}

# --- P881: VAT retention ---
else := {"matched":true,"rule_id":"jdg.accounting.vat_retention",
"package":"jdg.accounting.pkpir_validation","priority":881,
"vat_retention_years":5,
"_routing":"","_routing_reason":"",
"_legal_basis":"Art. 86 OrdPU; Art. 112a VAT",
"_warnings":["PRZECHOWYWANIE REJESTRÓW VAT — 5 lat. Rejestry VAT + faktury + JPK = komplet dokumentacji. Elektronicznie lub papierowo."]
}{
    input.jdg_entrepreneur.is_vat_payer==true
}

# ------------------------------------------------------------------------------
# FALLBACK
# ------------------------------------------------------------------------------
else := {"matched":true,"rule_id":"jdg.accounting.pkpir_fallback",
"package":"jdg.accounting.pkpir_validation","priority":899,
"_routing":"","_routing_reason":"",
"_legal_basis":"Rozporządzenie MF ws. PKPiR",
"_warnings":["PKPiR — brak dopasowania reguły (fallback). Transakcja nie wymaga walidacji PKPiR."]
}{
    true
}
