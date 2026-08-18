# Generated from Plan OPA 45 — Hyper Granularity rules
# 2026-07-13 18:15:03
# Rules: 21

package jdg.hyper.fx

default decide := {"matched":false,"rule_id":"jdg.hyper.fx.no_match","package":"jdg.hyper.fx","priority":99999}

# jdg.hyper.fx.edelivery.fiction.appeal_deadline_trigger — Fikcja
decide :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.fiction.appeal_deadline_trigger","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Data fikcji = data rozpoczęcia biegu 14 dni na odwołanie"]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.edelivery.monitoring.unread_messages — Monitoring
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.monitoring.unread_messages","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Codzienne sprawdzanie nieodebranych pism"]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.edelivery.monitoring.alert_7_days — Monitoring
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.monitoring.alert_7_days","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Alert 7 dni przed fikcją doręczenia"]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.edelivery.monitoring.alert_3_days — Monitoring
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.monitoring.alert_3_days","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.edelivery.monitoring.alert_1_day — Monitoring
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.edelivery.monitoring.alert_1_day","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":["Alert 1 dzień przed fikcją doręczenia"]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.required — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.required","_legal_basis":"ustawy z dnia 16 listopada 2016 r. o Krajowej Administracji Skarbowej (Dz.U. 2025 poz. 108, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.incoming_letters_check — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.incoming_letters_check","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.declarations_status — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.declarations_status","_legal_basis":"ustawy z dnia 16 listopada 2016 r. o Krajowej Administracji Skarbowej (Dz.U. 2025 poz. 108, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.payment_history — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.payment_history","_legal_basis":"Art. 51-56 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.mandates_management — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.mandates_management","_legal_basis":"Art. 138a-138o Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.eus.platform.certificates — e-US
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.eus.platform.certificates","_legal_basis":"Art. 306g Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.epuap.profile.required — ePUAP
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.epuap.profile.required","_legal_basis":"Art. 20a ustawy z dnia 17 lutego 2005 r. o informatyzacji działalności podmiotów realizujących zadania publiczne","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.epuap.signature.profile_zaufany — ePUAP
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.epuap.signature.profile_zaufany","_legal_basis":"Art. 20a ustawy z dnia 17 lutego 2005 r. o informatyzacji działalności podmiotów realizujących zadania publiczne","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.epuap.submission.confirmation_upo — ePUAP
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.epuap.submission.confirmation_upo","_legal_basis":"Art. 20d ustawy z dnia 17 lutego 2005 r. o informatyzacji działalności podmiotów realizujących zadania publiczne","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.epuap.submission.timestamp — ePUAP
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.epuap.submission.timestamp","_legal_basis":"Art. 20d ustawy z dnia 17 lutego 2005 r. o informatyzacji działalności podmiotów realizujących zadania publiczne","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.delivery.address.update_obligation — Aktualizacja
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.delivery.address.update_obligation","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.delivery.sanction.outdated_address — Sankcja
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.delivery.sanction.outdated_address","_legal_basis":"Art. 144b Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.communication.retention.5_years — Retencja
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.communication.retention.5_years","_legal_basis":"Art. 86 § 1 Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.communication.evidence_value — Dowody
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.communication.evidence_value","_legal_basis":"Art. 193a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.communication.encryption_requirements — Bezpieczeństwo
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.communication.encryption_requirements","_legal_basis":"Art. 193a Ordynacji podatkowej (Dz.U. 2025 poz. 234, ze zm.)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# jdg.hyper.fx.electronic.communication.data_breach_notification — Bezpieczeństwo
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.electronic.communication.data_breach_notification","_legal_basis":"Art. 33 rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)","_warnings":[]} {
    input.invoice.currency != "PLN"
}

# ══ L-FX-1 Fix: Currency Exchange Differences (P23 P1) — R1261-R1263 ══
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.currency.exchange.fifo_method","_legal_basis":"Art. 14b ust. 3 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Różnice kursowe — metoda podatkowa FIFO (pierwsze przyszło-pierwsze wyszło). Kurs NBP z ostatniego dnia roboczego poprzedzającego transakcję"]} {
    input.invoice.currency != "PLN"
}
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.currency.exchange.nbp_table_abc","_legal_basis":"Art. 14b ust. 4 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)","_warnings":["Kursy NBP: Tabela A (kurs średni — przychody), Tabela B (kurs kupna/sprzedaży — koszty). Aktualizacja dzienna o 08:00. API: api.nbp.pl"]} {
    object.get(input.jdg_entrepreneur, "fx_transactions_active", false) == true
}
else :=   {"matched":true,"rule_id":"jdg.hyper.fx.currency.exchange.jpk_v7_fx_mapping","_legal_basis":"Art. 109 ust. 3c ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)","_warnings":["Mapowanie różnic kursowych w JPK_V7: przychody wg kursu średniego NBP, koszty wg kursu kupna. Oznaczenie GTU_12 dla transakcji walutowych"]} {
    input.invoice.currency != "PLN"
    object.get(input.jdg_entrepreneur, "jpk_v7_due", false) == true
}
