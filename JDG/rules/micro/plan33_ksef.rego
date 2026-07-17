# Generated from Plan OPA 33 — Micro-rules for ksef
# 2026-07-13 14:58:41
# Rules: 74 (new, deduplicated)

package jdg.micro.ksef

default decide := {"matched":false,"rule_id":"jdg.micro.ksef.no_match","package":"jdg.micro.ksef","priority":99999}

# jdg.ksef.a106na.r10 — `ksef_vat_exempt_exception`: Podatnicy zwolnieni z VAT -> wyłączeni z KSeF → Wyjątek
decide :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r10","package":"jdg.micro.ksef","priority":5600,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatnicy zwolnieni z VAT -> wyłączeni z KSeF","_legal_basis":"Art. 106na ust. 3 VAT","_warnings":["[MICRO] Podatnicy zwolnieni z VAT -> wyłączeni z KSeF"]} {
    true
}

# jdg.ksef.a106na.r11 — `ksef_b2c_exception`: Faktury B2C (do konsumentów) -> wyłączone z KSeF (paragon z NIP nie wymaga KSeF) → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r11","package":"jdg.micro.ksef","priority":5601,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktury B2C (do konsumentów) -> wyłączone z KSeF (paragon z NIP nie wymaga KSeF)","_legal_basis":"Art. 106na ust. 4 VAT","_warnings":["[MICRO] Faktury B2C (do konsumentów) -> wyłączone z KSeF (paragon z NIP nie wymaga KSeF)"]} {
    true
}

# jdg.ksef.a106na.r12 — `ksef_self_invoicing_obligation`: Faktura wystawiona przez nabywcę (self-billing) -> również przez KSeF → Obowiązek
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r12","package":"jdg.micro.ksef","priority":5602,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura wystawiona przez nabywcę (self-billing) -> również przez KSeF","_legal_basis":"Art. 106na ust. 5 VAT","_warnings":["[MICRO] Faktura wystawiona przez nabywcę (self-billing) -> również przez KSeF"]} {
    true
}

# jdg.ksef.a106na.r13 — `ksef_fiscal_receipt_aggregate`: Zbiorcza faktura z paragonów -> nie wymaga KSeF (gdy wszystkie paragony z kasy fiskalnej) → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r13","package":"jdg.micro.ksef","priority":5603,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zbiorcza faktura z paragonów -> nie wymaga KSeF (gdy wszystkie paragony z kasy fiskalnej)","_legal_basis":"Art. 106na ust. 6 VAT","_warnings":["[MICRO] Zbiorcza faktura z paragonów -> nie wymaga KSeF (gdy wszystkie paragony z kasy fiskalnej)"]} {
    true
}

# jdg.ksef.a106na.r14 — `ksef_foreign_entity_invoice`: Faktura od podmiotu zagranicznego (nieposiadającego NIP PL) -> KSeF nie dotyczy → Wyjątek (kraj trzeciego)
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r14","package":"jdg.micro.ksef","priority":5604,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura od podmiotu zagranicznego (nieposiadającego NIP PL) -> KSeF nie dotyczy","_legal_basis":"Art. 106na ust. 7 VAT","_warnings":["[MICRO] Faktura od podmiotu zagranicznego (nieposiadającego NIP PL) -> KSeF nie dotyczy"]} {
    true
}

# jdg.ksef.a106na.r15 — `ksef_tax_exempt_entity_invoice`: Faktura od podmiotu zwolnionego podmiotowo z VAT -> KSeF nie dotyczy → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r15","package":"jdg.micro.ksef","priority":5605,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura od podmiotu zwolnionego podmiotowo z VAT -> KSeF nie dotyczy","_legal_basis":"Art. 106na ust. 8 VAT","_warnings":["[MICRO] Faktura od podmiotu zwolnionego podmiotowo z VAT -> KSeF nie dotyczy"]} {
    true
}

# jdg.ksef.a106na.r16 — `ksef_mandatory_fields_seller_nip`: NIP sprzedawcy (w fakturze ustrukturyzowanej) → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r16","package":"jdg.micro.ksef","priority":5606,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"NIP sprzedawcy (w fakturze ustrukturyzowanej)","_legal_basis":"Art. 106na ust. 9 pkt 1","_warnings":["[MICRO] NIP sprzedawcy (w fakturze ustrukturyzowanej)"]} {
    true
}

# jdg.ksef.a106na.r17 — `ksef_mandatory_fields_buyer_nip`: NIP nabywcy (w fakturze ustrukturyzowanej) → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r17","package":"jdg.micro.ksef","priority":5607,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"NIP nabywcy (w fakturze ustrukturyzowanej)","_legal_basis":"Art. 106na ust. 9 pkt 2","_warnings":["[MICRO] NIP nabywcy (w fakturze ustrukturyzowanej)"]} {
    true
}

# jdg.ksef.a106na.r18 — `ksef_mandatory_fields_invoice_number`: Numer faktury (unikalny w ramach KSeF) → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r18","package":"jdg.micro.ksef","priority":5608,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Numer faktury (unikalny w ramach KSeF)","_legal_basis":"Art. 106na ust. 9 pkt 3","_warnings":["[MICRO] Numer faktury (unikalny w ramach KSeF)"]} {
    true
}

# jdg.ksef.a106na.r19 — `ksef_mandatory_fields_date_of_issue`: Data wystawienia faktury → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r19","package":"jdg.micro.ksef","priority":5609,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Data wystawienia faktury","_legal_basis":"Art. 106na ust. 9 pkt 4","_warnings":["[MICRO] Data wystawienia faktury"]} {
    true
}

# jdg.ksef.a106na.r20 — `ksef_mandatory_fields_date_of_sale`: Data dokonania sprzedaży (dostawy lub wykonania usługi) → Pole obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r20","package":"jdg.micro.ksef","priority":5610,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Data dokonania sprzedaży (dostawy lub wykonania usługi)","_legal_basis":"Art. 106na ust. 9 pkt 5","_warnings":["[MICRO] Data dokonania sprzedaży (dostawy lub wykonania usługi)"]} {
    true
}

# jdg.ksef.a106na.r21 — `ksef_mandatory_fields_amount_net`: Kwota netto, stawka VAT, kwota VAT, kwota brutto → Pola obowiązkowe
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r21","package":"jdg.micro.ksef","priority":5611,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kwota netto, stawka VAT, kwota VAT, kwota brutto","_legal_basis":"Art. 106na ust. 9 pkt 6-8","_warnings":["[MICRO] Kwota netto, stawka VAT, kwota VAT, kwota brutto"]} {
    true
}

# jdg.ksef.a106na.r22 — `ksef_mandatory_gtu_code`: Oznaczenie GTU (jeśli towar/usługa wymaga) → Pole warunkowe
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r22","package":"jdg.micro.ksef","priority":5612,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Oznaczenie GTU (jeśli towar/usługa wymaga)","_legal_basis":"Art. 106na ust. 9 pkt 9","_warnings":["[MICRO] Oznaczenie GTU (jeśli towar/usługa wymaga)"]} {
    true
}

# jdg.ksef.a106na.r8 — `ksef_mandatory_all_factures_2026`: Wszystkie faktury sprzedaży (B2B) od 1 lutego 2026 r. → Obowiązek przez KSeF
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r8","package":"jdg.micro.ksef","priority":5613,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wszystkie faktury sprzedaży (B2B) od 1 lutego 2026 r.","_legal_basis":"Art. 106na ust. 1 VAT","_warnings":["[MICRO] Wszystkie faktury sprzedaży (B2B) od 1 lutego 2026 r."]} {
    true
}

# jdg.ksef.a106na.r9 — `ksef_active_vat_only`: Obowiązek KSeF dotyczy tylko czynnych podatników VAT → Zakres podmiotowy
else :=   {"matched":true,"rule_id":"jdg.ksef.a106na.r9","package":"jdg.micro.ksef","priority":5614,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Obowiązek KSeF dotyczy tylko czynnych podatników VAT","_legal_basis":"Art. 106na ust. 2 VAT","_warnings":["[MICRO] Obowiązek KSeF dotyczy tylko czynnych podatników VAT"]} {
    true
}

# jdg.ksef.a106nb.r1 — `ksef_deadline_issue_plus_send`: Faktura wystawiona i wysłana do KSeF w dacie sprzedaży (lub niezwłocznie) → Wysyłka w dacie sprzedaży
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nb.r1","package":"jdg.micro.ksef","priority":5615,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura wystawiona i wysłana do KSeF w dacie sprzedaży (lub niezwłocznie)","_legal_basis":"Art. 106nb ust. 1 VAT","_warnings":["[MICRO] Faktura wystawiona i wysłana do KSeF w dacie sprzedaży (lub niezwłocznie)"]} {
    true
}

# jdg.ksef.a106nb.r2 — `ksef_deadline_post_sale_24h`: Dopuszczalne przesunięcie: do 24h od sprzedaży (w uzasadnionych przypadkach) → 24h
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nb.r2","package":"jdg.micro.ksef","priority":5616,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dopuszczalne przesunięcie: do 24h od sprzedaży (w uzasadnionych przypadkach)","_legal_basis":"Art. 106nb ust. 2 VAT","_warnings":["[MICRO] Dopuszczalne przesunięcie: do 24h od sprzedaży (w uzasadnionych przypadkach)"]} {
    true
}

# jdg.ksef.a106nb.r3 — `ksef_deadline_advance_invoice_30`: Faktura zaliczkowa -> w terminie 30 dni od otrzymania zaliczki → 30 dni od zaliczki
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nb.r3","package":"jdg.micro.ksef","priority":5617,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura zaliczkowa -> w terminie 30 dni od otrzymania zaliczki","_legal_basis":"Art. 106nb ust. 3 VAT","_warnings":["[MICRO] Faktura zaliczkowa -> w terminie 30 dni od otrzymania zaliczki"]} {
    true
}

# jdg.ksef.a106nb.r4 — `ksef_deadline_batch_invoice`: Faktury zbiorcze -> w terminie 30 dni od końca miesiąca sprzedaży → 30 dni od końca miesiąca
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nb.r4","package":"jdg.micro.ksef","priority":5618,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktury zbiorcze -> w terminie 30 dni od końca miesiąca sprzedaży","_legal_basis":"Art. 106nb ust. 4 VAT","_warnings":["[MICRO] Faktury zbiorcze -> w terminie 30 dni od końca miesiąca sprzedaży"]} {
    true
}

# jdg.ksef.a106nb.r5 — `ksef_deadline_mandate_7_days`: Faktura za umowę zlecenia -> 7 dni od wykonania usługi → 7 dni
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nb.r5","package":"jdg.micro.ksef","priority":5619,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura za umowę zlecenia -> 7 dni od wykonania usługi","_legal_basis":"Art. 106nb ust. 5 VAT","_warnings":["[MICRO] Faktura za umowę zlecenia -> 7 dni od wykonania usługi"]} {
    true
}

# jdg.ksef.a106nc.r1 — `ksef_upo_receipt_storage`: UPO (Urzędowe Poświadczenie Odbioru) — przechowywać 5 lat → Retencja UPO
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nc.r1","package":"jdg.micro.ksef","priority":5620,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"UPO (Urzędowe Poświadczenie Odbioru) — przechowywać 5 lat","_legal_basis":"Art. 106nc ust. 1 VAT","_warnings":["[MICRO] UPO (Urzędowe Poświadczenie Odbioru) — przechowywać 5 lat"]} {
    true
}

# jdg.ksef.a106nc.r2 — `ksef_upo_download_auto`: KSeF generuje UPO automatycznie po poprawnej wysyłce → Automatyczne UPO
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nc.r2","package":"jdg.micro.ksef","priority":5621,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"KSeF generuje UPO automatycznie po poprawnej wysyłce","_legal_basis":"Art. 106nc ust. 2 VAT","_warnings":["[MICRO] KSeF generuje UPO automatycznie po poprawnej wysyłce"]} {
    true
}

# jdg.ksef.a106nc.r3 — `ksef_upo_mandatory_for_deduction`: UPO wymagane do odliczenia VAT (bez UPO -> brak prawa do odliczenia) → UPO warunkiem odliczenia
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nc.r3","package":"jdg.micro.ksef","priority":5622,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"UPO wymagane do odliczenia VAT (bez UPO -> brak prawa do odliczenia)","_legal_basis":"Art. 106nc ust. 3 VAT","_warnings":["[MICRO] UPO wymagane do odliczenia VAT (bez UPO -> brak prawa do odliczenia)"]} {
    true
}

# jdg.ksef.a106nc.r4 — `ksef_upo_verification_api`: Możliwość weryfikacji UPO przez API KSeF → API weryfikacji
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nc.r4","package":"jdg.micro.ksef","priority":5623,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Możliwość weryfikacji UPO przez API KSeF","_legal_basis":"Art. 106nc ust. 4 VAT","_warnings":["[MICRO] Możliwość weryfikacji UPO przez API KSeF"]} {
    true
}

# jdg.ksef.a106nd.r1 — `ksef_archive_10_years`: Faktury w KSeF przechowywane 10 lat (system przechowuje) → 10 lat
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nd.r1","package":"jdg.micro.ksef","priority":5624,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktury w KSeF przechowywane 10 lat (system przechowuje)","_legal_basis":"Art. 106nd ust. 1 VAT","_warnings":["[MICRO] Faktury w KSeF przechowywane 10 lat (system przechowuje)"]} {
    true
}

# jdg.ksef.a106nd.r2 — `ksef_archive_export_right`: Podatnik ma prawo do eksportu faktur z KSeF w każdej chwili → Eksport danych
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nd.r2","package":"jdg.micro.ksef","priority":5625,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatnik ma prawo do eksportu faktur z KSeF w każdej chwili","_legal_basis":"Art. 106nd ust. 2 VAT","_warnings":["[MICRO] Podatnik ma prawo do eksportu faktur z KSeF w każdej chwili"]} {
    true
}

# jdg.ksef.a106nd.r3 — `ksef_archive_no_own_storage`: Faktury w KSeF nie wymagają własnego przechowywania (KSeF przechowuje) → Brak obowiązku przechowywania
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nd.r3","package":"jdg.micro.ksef","priority":5626,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktury w KSeF nie wymagają własnego przechowywania (KSeF przechowuje)","_legal_basis":"Art. 106nd ust. 3 VAT","_warnings":["[MICRO] Faktury w KSeF nie wymagają własnego przechowywania (KSeF przechowuje)"]} {
    true
}

# jdg.ksef.a106nd.r4 — `ksef_archive_own_storage_option`: Podatnik może nadal przechowywać faktury we własnym zakresie (opcjonalnie) → Opcjonalnie
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nd.r4","package":"jdg.micro.ksef","priority":5627,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatnik może nadal przechowywać faktury we własnym zakresie (opcjonalnie)","_legal_basis":"Art. 106nd ust. 4 VAT","_warnings":["[MICRO] Podatnik może nadal przechowywać faktury we własnym zakresie (opcjonalnie)"]} {
    true
}

# jdg.ksef.a106nd.r5 — `ksef_archive_format_change`: Zmiana formatu faktury (np. na PDF) przez KSeF nie wpływa na jej ważność → Zachowanie ważności
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nd.r5","package":"jdg.micro.ksef","priority":5628,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Zmiana formatu faktury (np. na PDF) przez KSeF nie wpływa na jej ważność","_legal_basis":"Art. 106nd ust. 5 VAT","_warnings":["[MICRO] Zmiana formatu faktury (np. na PDF) przez KSeF nie wpływa na jej ważność"]} {
    true
}

# jdg.ksef.a106ne.r10 — `ksef_offline_backup_channel`: Dostępność kanału awaryjnego (offline) dla JDG bez dostępu do internetu → Kanał awaryjny
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ne.r10","package":"jdg.micro.ksef","priority":5629,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dostępność kanału awaryjnego (offline) dla JDG bez dostępu do internetu","_legal_basis":"Art. 106ne ust. 7 VAT","_warnings":["[MICRO] Dostępność kanału awaryjnego (offline) dla JDG bez dostępu do internetu"]} {
    true
}

# jdg.ksef.a106ne.r4 — `ksef_offline_activation_7_days`: Awaria KSeF -> 7 dni na wysłanie faktur po przywróceniu systemu → 7 dni
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ne.r4","package":"jdg.micro.ksef","priority":5630,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Awaria KSeF -> 7 dni na wysłanie faktur po przywróceniu systemu","_legal_basis":"Art. 106ne ust. 1 VAT","_warnings":["[MICRO] Awaria KSeF -> 7 dni na wysłanie faktur po przywróceniu systemu"]} {
    true
}

# jdg.ksef.a106ne.r5 — `ksef_offline_numbering_convention`: Faktura OFFLINE: numer z sufiksem /OFFLINE (w kolejności chronologicznej) → Sufiks /OFFLINE
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ne.r5","package":"jdg.micro.ksef","priority":5631,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura OFFLINE: numer z sufiksem /OFFLINE (w kolejności chronologicznej)","_legal_basis":"Art. 106ne ust. 2 VAT","_warnings":["[MICRO] Faktura OFFLINE: numer z sufiksem /OFFLINE (w kolejności chronologicznej)"]} {
    true
}

# jdg.ksef.a106ne.r6 — `ksef_offline_batch_after_restore`: Przywrócenie KSeF -> wysyłka zbiorcza wszystkich faktur z okresu awarii → Wysyłka zbiorcza
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ne.r6","package":"jdg.micro.ksef","priority":5632,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Przywrócenie KSeF -> wysyłka zbiorcza wszystkich faktur z okresu awarii","_legal_basis":"Art. 106ne ust. 3 VAT","_warnings":["[MICRO] Przywrócenie KSeF -> wysyłka zbiorcza wszystkich faktur z okresu awarii"]} {
    true
}

# jdg.ksef.a106ne.r7 — `ksef_offline_single_file_export`: Faktury z trybu offline wysyłane jako jeden plik → Jeden plik
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ne.r7","package":"jdg.micro.ksef","priority":5633,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktury z trybu offline wysyłane jako jeden plik","_legal_basis":"Art. 106ne ust. 4 VAT","_warnings":["[MICRO] Faktury z trybu offline wysyłane jako jeden plik"]} {
    true
}

# jdg.ksef.a106ne.r8 — `ksef_offline_no_sanctions`: Wysyłka w terminie 7 dni -> brak sankcji za opóźnienie → Brak sankcji
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ne.r8","package":"jdg.micro.ksef","priority":5634,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wysyłka w terminie 7 dni -> brak sankcji za opóźnienie","_legal_basis":"Art. 106ne ust. 5 VAT","_warnings":["[MICRO] Wysyłka w terminie 7 dni -> brak sankcji za opóźnienie"]} {
    true
}

# jdg.ksef.a106ne.r9 — `ksef_offline_system_status_check`: Sprawdzenie statusu systemu KSeF przed wystawieniem faktury (ONLINE/OFFLINE) → Weryfikacja statusu
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ne.r9","package":"jdg.micro.ksef","priority":5635,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprawdzenie statusu systemu KSeF przed wystawieniem faktury (ONLINE/OFFLINE)","_legal_basis":"Art. 106ne ust. 6 VAT","_warnings":["[MICRO] Sprawdzenie statusu systemu KSeF przed wystawieniem faktury (ONLINE/OFFLINE)"]} {
    true
}

# jdg.ksef.a106nf.r1 — `ksef_correction_obligation_via_ksef`: Korekta faktury -> przez KSeF (jako faktura korygująca) → Korekta w KSeF
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nf.r1","package":"jdg.micro.ksef","priority":5636,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekta faktury -> przez KSeF (jako faktura korygująca)","_legal_basis":"Art. 106nf ust. 1 VAT","_warnings":["[MICRO] Korekta faktury -> przez KSeF (jako faktura korygująca)"]} {
    true
}

# jdg.ksef.a106nf.r2 — `ksef_correction_reference`: Faktura korygująca: obowiązkowe odwołanie do faktury pierwotnej (numer KSeF) → Referencja
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nf.r2","package":"jdg.micro.ksef","priority":5637,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura korygująca: obowiązkowe odwołanie do faktury pierwotnej (numer KSeF)","_legal_basis":"Art. 106nf ust. 2 VAT","_warnings":["[MICRO] Faktura korygująca: obowiązkowe odwołanie do faktury pierwotnej (numer KSeF)"]} {
    true
}

# jdg.ksef.a106nf.r3 — `ksef_correction_sequence`: Korekty w KSeF w kolejności chronologicznej → Kolejność
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nf.r3","package":"jdg.micro.ksef","priority":5638,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Korekty w KSeF w kolejności chronologicznej","_legal_basis":"Art. 106nf ust. 3 VAT","_warnings":["[MICRO] Korekty w KSeF w kolejności chronologicznej"]} {
    true
}

# jdg.ksef.a106nf.r4 — `ksef_annul_invoice_procedure`: Anulowanie faktury (gdy nie doszło do transakcji) -> przez KSeF z adnotacją ANULOWANA → Anulowanie
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nf.r4","package":"jdg.micro.ksef","priority":5639,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Anulowanie faktury (gdy nie doszło do transakcji) -> przez KSeF z adnotacją ANULOWANA","_legal_basis":"Art. 106nf ust. 4 VAT","_warnings":["[MICRO] Anulowanie faktury (gdy nie doszło do transakcji) -> przez KSeF z adnotacją ANULOWANA"]} {
    true
}

# jdg.ksef.a106ng.r3 — `ksef_authorization_api_token`: Autoryzacja do API KSeF: token autoryzacyjny (podpisany kwalifikowany) → Token
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ng.r3","package":"jdg.micro.ksef","priority":5640,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Autoryzacja do API KSeF: token autoryzacyjny (podpisany kwalifikowany)","_legal_basis":"Art. 106ng ust. 1 VAT","_warnings":["[MICRO] Autoryzacja do API KSeF: token autoryzacyjny (podpisany kwalifikowany)"]} {
    true
}

# jdg.ksef.a106ng.r4 — `ksef_authorization_employee_delegation`: Możliwość nadania uprawnień do KSeF pracownikowi/księgowej → Delegacja
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ng.r4","package":"jdg.micro.ksef","priority":5641,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Możliwość nadania uprawnień do KSeF pracownikowi/księgowej","_legal_basis":"Art. 106ng ust. 2 VAT","_warnings":["[MICRO] Możliwość nadania uprawnień do KSeF pracownikowi/księgowej"]} {
    true
}

# jdg.ksef.a106ng.r5 — `ksef_authorization_withdrawal`: Cofnięcie uprawnień do KSeF w każdej chwili → Odwołanie
else :=   {"matched":true,"rule_id":"jdg.ksef.a106ng.r5","package":"jdg.micro.ksef","priority":5642,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Cofnięcie uprawnień do KSeF w każdej chwili","_legal_basis":"Art. 106ng ust. 3 VAT","_warnings":["[MICRO] Cofnięcie uprawnień do KSeF w każdej chwili"]} {
    true
}

# jdg.ksef.a106nh.r3 — `ksef_qr_code_format`: Kod QR na fakturze wizualnej: format zgodny ze specyfikacją MF → Format QR
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nh.r3","package":"jdg.micro.ksef","priority":5643,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod QR na fakturze wizualnej: format zgodny ze specyfikacją MF","_legal_basis":"Art. 106nh ust. 1 VAT","_warnings":["[MICRO] Kod QR na fakturze wizualnej: format zgodny ze specyfikacją MF"]} {
    true
}

# jdg.ksef.a106nh.r4 — `ksef_qr_scan_for_verification`: Skanowanie kodu QR do weryfikacji autentyczności faktury → Weryfikacja
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nh.r4","package":"jdg.micro.ksef","priority":5644,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Skanowanie kodu QR do weryfikacji autentyczności faktury","_legal_basis":"Art. 106nh ust. 2 VAT","_warnings":["[MICRO] Skanowanie kodu QR do weryfikacji autentyczności faktury"]} {
    true
}

# jdg.ksef.a106nh.r5 — `ksef_qr_data_signature`: Dane w kodzie QR podpisane cyfrowo przez KSeF (zabezpieczenie przed fałszerstwem) → Podpis cyfrowy
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nh.r5","package":"jdg.micro.ksef","priority":5645,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Dane w kodzie QR podpisane cyfrowo przez KSeF (zabezpieczenie przed fałszerstwem)","_legal_basis":"Art. 106nh ust. 3 VAT","_warnings":["[MICRO] Dane w kodzie QR podpisane cyfrowo przez KSeF (zabezpieczenie przed fałszerstwem)"]} {
    true
}

# jdg.ksef.a106nq.r2 — `ksef_sanction_100pct_additional_tax`: Sankcja: dodatkowe zobowiązanie 100% VAT (za brak KSeF) → 100% VAT (max 500k PLN)
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nq.r2","package":"jdg.micro.ksef","priority":5646,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja: dodatkowe zobowiązanie 100% VAT (za brak KSeF)","_legal_basis":"Art. 106nq ust. 1 VAT","_warnings":["[MICRO] Sankcja: dodatkowe zobowiązanie 100% VAT (za brak KSeF)"]} {
    true
}

# jdg.ksef.a106nq.r3 — `ksef_sanction_reduced_for_first`: Sankcja dla pierwszego naruszenia: 50% VAT (maks. 250k PLN) → 50%
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nq.r3","package":"jdg.micro.ksef","priority":5647,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja dla pierwszego naruszenia: 50% VAT (maks. 250k PLN)","_legal_basis":"Art. 106nq ust. 2 VAT","_warnings":["[MICRO] Sankcja dla pierwszego naruszenia: 50% VAT (maks. 250k PLN)"]} {
    true
}

# jdg.ksef.a106nq.r4 — `ksef_sanction_offline_exception`: Brak sankcji za faktury w trybie awaryjnym (wysłane w 7 dni) → Wyjątek
else :=   {"matched":true,"rule_id":"jdg.ksef.a106nq.r4","package":"jdg.micro.ksef","priority":5648,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Brak sankcji za faktury w trybie awaryjnym (wysłane w 7 dni)","_legal_basis":"Art. 106nq ust. 3 VAT","_warnings":["[MICRO] Brak sankcji za faktury w trybie awaryjnym (wysłane w 7 dni)"]} {
    true
}

# jdg.ksef.r1 — `ksef_obligation_active_vat_from_2026`: Czynny podatnik VAT -> faktury przez KSeF od 1 lutego 2026 → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ksef.r1","package":"jdg.micro.ksef","priority":5649,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Czynny podatnik VAT -> faktury przez KSeF od 1 lutego 2026","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Czynny podatnik VAT -> faktury przez KSeF od 1 lutego 2026"]} {
    true
}

# jdg.ksef.r10 — `ksef_upo_confirmation_after_send`: UPO (Urzedowe Poświadczenie Odbioru) - otrzymawane po wyslaniu → Potwierdzenie
else :=   {"matched":true,"rule_id":"jdg.ksef.r10","package":"jdg.micro.ksef","priority":5650,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"UPO (Urzedowe Poświadczenie Odbioru) - otrzymawane po wyslaniu","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] UPO (Urzedowe Poświadczenie Odbioru) - otrzymawane po wyslaniu"]} {
    true
}

# jdg.ksef.r11 — `ksef_upo_verification_signature`: UPO zawiera podpis elektroniczny (weryfikacja autentycznosci) → Autentycznosc
else :=   {"matched":true,"rule_id":"jdg.ksef.r11","package":"jdg.micro.ksef","priority":5651,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"UPO zawiera podpis elektroniczny (weryfikacja autentycznosci)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] UPO zawiera podpis elektroniczny (weryfikacja autentycznosci)"]} {
    true
}

# jdg.ksef.r12 — `ksef_upo_storage_5_years`: UPO przechowywane 5 lat → Retencja
else :=   {"matched":true,"rule_id":"jdg.ksef.r12","package":"jdg.micro.ksef","priority":5652,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"UPO przechowywane 5 lat","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] UPO przechowywane 5 lat"]} {
    true
}

# jdg.ksef.r13 — `ksef_qr_code_on_visual_invoice`: Kod QR na fakturze wizualnej (PDF) do weryfikacji → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ksef.r13","package":"jdg.micro.ksef","priority":5653,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod QR na fakturze wizualnej (PDF) do weryfikacji","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Kod QR na fakturze wizualnej (PDF) do weryfikacji"]} {
    true
}

# jdg.ksef.r14 — `ksef_qr_code_generation`: Kod QR generowany przez KSeF (lub przez system JDG) → Generator
else :=   {"matched":true,"rule_id":"jdg.ksef.r14","package":"jdg.micro.ksef","priority":5654,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod QR generowany przez KSeF (lub przez system JDG)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Kod QR generowany przez KSeF (lub przez system JDG)"]} {
    true
}

# jdg.ksef.r15 — `ksef_qr_code_validation_url`: Kod QR zawiera URL do weryfikacji faktury w KSeF → URL
else :=   {"matched":true,"rule_id":"jdg.ksef.r15","package":"jdg.micro.ksef","priority":5655,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Kod QR zawiera URL do weryfikacji faktury w KSeF","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Kod QR zawiera URL do weryfikacji faktury w KSeF"]} {
    true
}

# jdg.ksef.r16 — `ksef_sanction_100pct_vat`: Sankcja za brak KSeF: 100% VAT z faktury (max 500k PLN) → Sankcja
else :=   {"matched":true,"rule_id":"jdg.ksef.r16","package":"jdg.micro.ksef","priority":5656,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja za brak KSeF: 100% VAT z faktury (max 500k PLN)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Sankcja za brak KSeF: 100% VAT z faktury (max 500k PLN)"]} {
    true
}

# jdg.ksef.r17 — `ksef_sanction_70pct_for_offline`: Sankcja za opoznienie > 24h: 70% VAT (max 300k PLN) → Sankcja
else :=   {"matched":true,"rule_id":"jdg.ksef.r17","package":"jdg.micro.ksef","priority":5657,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja za opoznienie > 24h: 70% VAT (max 300k PLN)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Sankcja za opoznienie > 24h: 70% VAT (max 300k PLN)"]} {
    true
}

# jdg.ksef.r18 — `ksef_sanction_15pct_minor`: Sankcja za bledy w fakturze: 15% VAT (max 100k PLN) → Sankcja
else :=   {"matched":true,"rule_id":"jdg.ksef.r18","package":"jdg.micro.ksef","priority":5658,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcja za bledy w fakturze: 15% VAT (max 100k PLN)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Sankcja za bledy w fakturze: 15% VAT (max 100k PLN)"]} {
    true
}

# jdg.ksef.r19 — `ksef_sanction_not_for_receipts`: Sankcje KSeF nie dotycza paragonow B2C → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ksef.r19","package":"jdg.micro.ksef","priority":5659,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sankcje KSeF nie dotycza paragonow B2C","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Sankcje KSeF nie dotycza paragonow B2C"]} {
    true
}

# jdg.ksef.r2 — `ksef_obligation_vat_exempt_exception`: Podatnik zwolniony z VAT -> wyjatek z KSeF → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ksef.r2","package":"jdg.micro.ksef","priority":5660,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Podatnik zwolniony z VAT -> wyjatek z KSeF","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Podatnik zwolniony z VAT -> wyjatek z KSeF"]} {
    true
}

# jdg.ksef.r20 — `ksef_self_invoicing_by_buyer`: Faktura wystawiona przez nabywce (self-billing) -> tez przez KSeF → Obowiazek
else :=   {"matched":true,"rule_id":"jdg.ksef.r20","package":"jdg.micro.ksef","priority":5661,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura wystawiona przez nabywce (self-billing) -> tez przez KSeF","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Faktura wystawiona przez nabywce (self-billing) -> tez przez KSeF"]} {
    true
}

# jdg.ksef.r21 — `ksef_api_authentication_token`: Autoryzacja do API KSeF: token (NIP + klucz API) → Autoryzacja
else :=   {"matched":true,"rule_id":"jdg.ksef.r21","package":"jdg.micro.ksef","priority":5662,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Autoryzacja do API KSeF: token (NIP + klucz API)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Autoryzacja do API KSeF: token (NIP + klucz API)"]} {
    true
}

# jdg.ksef.r22 — `ksef_api_environment_test_prod`: Srodowiska: TEST i PRODUKCJA → Srodowiska
else :=   {"matched":true,"rule_id":"jdg.ksef.r22","package":"jdg.micro.ksef","priority":5663,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Srodowiska: TEST i PRODUKCJA","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Srodowiska: TEST i PRODUKCJA"]} {
    true
}

# jdg.ksef.r23 — `ksef_api_invoice_limit_per_request`: Limit faktur w jednym zadaniu: 1 faktura (standard) lub 100 (batch) → Limity
else :=   {"matched":true,"rule_id":"jdg.ksef.r23","package":"jdg.micro.ksef","priority":5664,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Limit faktur w jednym zadaniu: 1 faktura (standard) lub 100 (batch)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Limit faktur w jednym zadaniu: 1 faktura (standard) lub 100 (batch)"]} {
    true
}

# jdg.ksef.r24 — `ksef_api_invoice_status_check`: Sprawdzanie statusu faktury w KSeF (czy odebrana, czy bledna) → Status
else :=   {"matched":true,"rule_id":"jdg.ksef.r24","package":"jdg.micro.ksef","priority":5665,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Sprawdzanie statusu faktury w KSeF (czy odebrana, czy bledna)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Sprawdzanie statusu faktury w KSeF (czy odebrana, czy bledna)"]} {
    true
}

# jdg.ksef.r25 — `ksef_api_batch_mode_for_corrections`: Tryb batch: wysylka wielu faktur naraz (do 100) -> szybszy → Batch
else :=   {"matched":true,"rule_id":"jdg.ksef.r25","package":"jdg.micro.ksef","priority":5666,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Tryb batch: wysylka wielu faktur naraz (do 100) -> szybszy","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Tryb batch: wysylka wielu faktur naraz (do 100) -> szybszy"]} {
    true
}

# jdg.ksef.r3 — `ksef_obligation_b2c_receipts_exception`: Paragony, rachunki B2C -> nie wymagaja KSeF → Wylaczenie
else :=   {"matched":true,"rule_id":"jdg.ksef.r3","package":"jdg.micro.ksef","priority":5667,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Paragony, rachunki B2C -> nie wymagaja KSeF","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Paragony, rachunki B2C -> nie wymagaja KSeF"]} {
    true
}

# jdg.ksef.r4 — `ksef_structured_invoice_schema`: Faktura w formacie XML wg schemy FA(1) → Format
else :=   {"matched":true,"rule_id":"jdg.ksef.r4","package":"jdg.micro.ksef","priority":5668,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura w formacie XML wg schemy FA(1)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Faktura w formacie XML wg schemy FA(1)"]} {
    true
}

# jdg.ksef.r5 — `ksef_structured_invoice_required_fields`: Wymagane pola: NIP nabywcy, kwota, stawka, data, numer → Wymogi
else :=   {"matched":true,"rule_id":"jdg.ksef.r5","package":"jdg.micro.ksef","priority":5669,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Wymagane pola: NIP nabywcy, kwota, stawka, data, numer","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Wymagane pola: NIP nabywcy, kwota, stawka, data, numer"]} {
    true
}

# jdg.ksef.r6 — `ksef_structured_invoice_optional_fields`: Opcjonalne pola: adnotacje, faktura korygujaca, zaliczka → Opcjonalne
else :=   {"matched":true,"rule_id":"jdg.ksef.r6","package":"jdg.micro.ksef","priority":5670,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Opcjonalne pola: adnotacje, faktura korygujaca, zaliczka","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Opcjonalne pola: adnotacje, faktura korygujaca, zaliczka"]} {
    true
}

# jdg.ksef.r7 — `ksef_send_real_time_or_24h`: Faktura wyslana do KSeF w momencie sprzedazy (lub do 24h) → Termin
else :=   {"matched":true,"rule_id":"jdg.ksef.r7","package":"jdg.micro.ksef","priority":5671,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Faktura wyslana do KSeF w momencie sprzedazy (lub do 24h)","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Faktura wyslana do KSeF w momencie sprzedazy (lub do 24h)"]} {
    true
}

# jdg.ksef.r8 — `ksef_offline_mode_on_breakdown`: Tryb offline: awaria KSeF -> faktury offline z sufiksem /OFFLINE → Tryb awaryjny
else :=   {"matched":true,"rule_id":"jdg.ksef.r8","package":"jdg.micro.ksef","priority":5672,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Tryb offline: awaria KSeF -> faktury offline z sufiksem /OFFLINE","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Tryb offline: awaria KSeF -> faktury offline z sufiksem /OFFLINE"]} {
    true
}

# jdg.ksef.r9 — `ksef_offline_recovery_7_days`: Po przywroceniu KSeF: 7 dni na wyslanie faktur offline → Termn
else :=   {"matched":true,"rule_id":"jdg.ksef.r9","package":"jdg.micro.ksef","priority":5673,"vat_rate":"","rounding_level":"","gtu_code":"","pit_form":"","pit_rate":"","pit_bracket":"","pit_annual_return_type":"","kus_qualification":"","kus_percent":0,"zus_social_base_type":"","zus_health_rate":"","business_status":"","_routing":"","_routing_reason":"Po przywroceniu KSeF: 7 dni na wyslanie faktur offline","_legal_basis":"Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)","_warnings":["[MICRO] Po przywroceniu KSeF: 7 dni na wyslanie faktur offline"]} {
    true
}
