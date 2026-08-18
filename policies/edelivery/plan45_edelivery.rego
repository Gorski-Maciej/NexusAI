# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — jdg.edelivery hyper (Doc 45: R1235-R1269)
# Atom rules: e-komunikacja — fiction, monitoring, e-US, ePUAP, cross-border
# Rules: 35 atom
# ═══════════════════════════════════════════════════════════════════════════════
package jdg.edelivery.hyper
import data.jdg.helpers

default decide := {"matched":false,"rule_id":"jdg.edelivery.hyper.no_match","package":"jdg.edelivery.hyper","priority":99999}

decide := {"matched":true,"rule_id":"jdg.edelivery.hyper.registration_mandatory","package":"jdg.edelivery.hyper","priority":1235,"_routing":"WARNING","_routing_reason":"Rejestracja BAE — obowiązkowa","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["Rejestracja adresu e-Doręczeń w BAE — obowiązek od 2025 (dla JDG: obecnie dobrowolne, obowiązek dla podmiotów publicznych i spółek KRS)"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.registration_deadline","package":"jdg.edelivery.hyper","priority":1236,"_routing":"WARNING","_routing_reason":"Termin rejestracji BAE","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["Termin rejestracji e-Doręczeń zależny od typu podmiotu"]} {
    object.get(input.document, "bae_not_registered", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.fiction_14days","package":"jdg.edelivery.hyper","priority":1237,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Fikcja doręczenia po 14 dniach","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["PISMO UZNANE ZA DORĘCZONE PO 14 DNIACH! Sprawdź natychmiast!"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.fiction_consequences","package":"jdg.edelivery.hyper","priority":1238,"_routing":"TRIAGE_QUEUE","_routing_reason":"Konsekwencje fikcji","_legal_basis":"OP","_warnings":["Fikcja — bieg terminów odwoławczych od daty fikcji"]} {
    object.get(input.document, "edelivery_fiction_triggered", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.fiction_critical_alert","package":"jdg.edelivery.hyper","priority":1239,"_routing":"BLOCK_AND_ALERT","_routing_reason":"CRITICAL: zbliżająca się fikcja","_legal_basis":"OP","_warnings":["Alert CRITICAL — zbliżająca się fikcja doręczenia!"]} {
    object.get(input.document, "fiction_days_remaining", 99) <= 3
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.fiction_appeal_trigger","package":"jdg.edelivery.hyper","priority":1240,"_routing":"TRIAGE_QUEUE","_routing_reason":"Fikcja = start 14 dni na odwołanie","_legal_basis":"OP","_warnings":["Data fikcji = data rozpoczęcia 14 dni na odwołanie"]} {
    object.get(input.document, "edelivery_fiction_triggered", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.monitoring_unread","package":"jdg.edelivery.hyper","priority":1241,"_routing":"WARNING","_routing_reason":"Nieodebrane pisma","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["Codziennie sprawdzaj nieodebrane pisma w e-US"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.alert_7days","package":"jdg.edelivery.hyper","priority":1242,"_routing":"WARNING","_routing_reason":"7 dni do fikcji","_legal_basis":"OP","_warnings":["7 dni przed fikcją doręczenia — sprawdź skrzynkę!"]} {
    object.get(input.document, "fiction_days_remaining", 99) <= 7
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.alert_3days","package":"jdg.edelivery.hyper","priority":1243,"_routing":"WARNING","_routing_reason":"3 dni do fikcji","_legal_basis":"OP","_warnings":["3 dni przed fikcją — NATYCHMIAST odbierz!"]} {
    object.get(input.document, "fiction_days_remaining", 99) <= 3
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.alert_1day","package":"jdg.edelivery.hyper","priority":1244,"_routing":"BLOCK_AND_ALERT","_routing_reason":"OSTATNI DZIEŃ przed fikcją","_legal_basis":"OP","_warnings":["OSTATNI DZIEŃ przed fikcją doręczenia!"]} {
    object.get(input.document, "fiction_days_remaining", 99) <= 1
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.eus_required","package":"jdg.edelivery.hyper","priority":1245,"_routing":"WARNING","_routing_reason":"Konto e-US obowiązkowe","_legal_basis":"Ordynacja podatkowa","_warnings":["Obowiązek posiadania konta e-US"]} {
    object.get(input.document, "eus_account_active", false) == false
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.eus_incoming_letters","package":"jdg.edelivery.hyper","priority":1246,"_routing":"","_routing_reason":"Monitoruj pisma na e-US","_legal_basis":"OP","_warnings":["Nowe pisma na e-US — sprawdź skrzynkę"]} {
    object.get(input.document, "eus_account_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.eus_declarations_status","package":"jdg.edelivery.hyper","priority":1247,"_routing":"","_routing_reason":"Status deklaracji (UPO)","_legal_basis":"OP","_warnings":["Status złożonych deklaracji w e-US"]} {
    object.get(input.document, "eus_account_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.eus_payment_history","package":"jdg.edelivery.hyper","priority":1248,"_routing":"","_routing_reason":"Historia wpłat i zaległości","_legal_basis":"OP","_warnings":["Sprawdź historię wpłat i zaległości w e-US"]} {
    object.get(input.document, "eus_account_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.eus_mandates","package":"jdg.edelivery.hyper","priority":1249,"_routing":"","_routing_reason":"Zarządzanie pełnomocnictwami","_legal_basis":"OP","_warnings":["Zarządzaj pełnomocnictwami PPS-1/UPL-1 w e-US"]} {
    object.get(input.document, "eus_account_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.eus_certificates","package":"jdg.edelivery.hyper","priority":1250,"_routing":"","_routing_reason":"Zaświadczenia o niezaleganiu","_legal_basis":"OP","_warnings":["Zaświadczenia o niezaleganiu dostępne w e-US"]} {
    object.get(input.document, "eus_account_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.epuap_profile_required","package":"jdg.edelivery.hyper","priority":1251,"_routing":"WARNING","_routing_reason":"Profil zaufany ePUAP","_legal_basis":"OP","_warnings":["Obowiązek profilu zaufanego ePUAP"]} {
    object.get(input.document, "epuap_profile_active", false) == false
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.epuap_signature","package":"jdg.edelivery.hyper","priority":1252,"_routing":"","_routing_reason":"Profil zaufany jako podpis","_legal_basis":"OP","_warnings":["Profil zaufany = podstawowa forma podpisu"]} {
    object.get(input.document, "epuap_profile_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.epuap_submission_upo","package":"jdg.edelivery.hyper","priority":1253,"_routing":"","_routing_reason":"UPO dla każdego pisma","_legal_basis":"OP","_warnings":["Urzędowe Poświadczenie Odbioru dla każdego pisma"]} {
    object.get(input.document, "epuap_profile_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.epuap_timestamp","package":"jdg.edelivery.hyper","priority":1254,"_routing":"","_routing_reason":"Znacznik czasowy","_legal_basis":"OP","_warnings":["Znacznik czasowy UPO = data skutecznego złożenia"]} {
    object.get(input.document, "epuap_profile_active", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.address_update_obligation","package":"jdg.edelivery.hyper","priority":1255,"_routing":"WARNING","_routing_reason":"Aktualizuj adres e-Doręczeń","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["Obowiązek aktualizacji adresu e-Doręczeń"]} {
    object.get(input.document, "edelivery_address_outdated", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.sanction_outdated_address","package":"jdg.edelivery.hyper","priority":1256,"_routing":"BLOCK_AND_ALERT","_routing_reason":"Nieaktualny adres → fikcja","_legal_basis":"Ustawa o doręczeniach el.","_warnings":["Nieaktualny adres → fikcja doręczenia na stary adres!"]} {
    object.get(input.document, "edelivery_address_outdated", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.retention_5years","package":"jdg.edelivery.hyper","priority":1257,"_routing":"","_routing_reason":"Retencja korespondencji 5 lat","_legal_basis":"Art. 86 OP","_warnings":["Przechowuj korespondencję 5 lat"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.evidence_value","package":"jdg.edelivery.hyper","priority":1258,"_routing":"","_routing_reason":"Moc dowodowa e-dokumentów","_legal_basis":"Art. 180a OP","_warnings":["E-dokumenty mają moc dowodową przy autentyczności"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.encryption","package":"jdg.edelivery.hyper","priority":1259,"_routing":"","_routing_reason":"Szyfrowanie komunikacji","_legal_basis":"eIDAS","_warnings":["Wymogi szyfrowania komunikacji z US"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.data_breach","package":"jdg.edelivery.hyper","priority":1260,"_routing":"TRIAGE_QUEUE","_routing_reason":"Naruszenie danych","_legal_basis":"RODO","_warnings":["Obowiązek zgłoszenia naruszenia danych"]} {
    object.get(input.document, "data_breach_detected", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.cross_border_eidas","package":"jdg.edelivery.hyper","priority":1261,"_routing":"","_routing_reason":"Uznawanie podpisów eIDAS","_legal_basis":"eIDAS","_warnings":["Podpisy elektroniczne z UE uznawane przez eIDAS"]} {
    object.get(input.document, "cross_border_e_comm", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.cross_border_crs_fatca","package":"jdg.edelivery.hyper","priority":1262,"_routing":"","_routing_reason":"CRS/FATCA reporting","_legal_basis":"CRS/FATCA","_warnings":["Automatyczna wymiana informacji CRS/FATCA"]} {
    object.get(input.document, "crs_fatca_reporting", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.cross_border_dac","package":"jdg.edelivery.hyper","priority":1263,"_routing":"","_routing_reason":"Dyrektywy DAC","_legal_basis":"DAC","_warnings":["Zgodność z dyrektywami DAC (DAC1-DAC8)"]} {
    object.get(input.document, "cross_border_e_comm", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.calendar_deadlines_integration","package":"jdg.edelivery.hyper","priority":1264,"_routing":"","_routing_reason":"Integracja z kalendarzem","_legal_basis":"OP","_warnings":["Integracja terminów komunikacyjnych z kalendarzem płatności"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.offline_backup","package":"jdg.edelivery.hyper","priority":1265,"_routing":"","_routing_reason":"Procedura awaryjna","_legal_basis":"OP","_warnings":["Procedura na wypadek awarii systemów e-US"]} {
    object.get(input.document, "eus_outage", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.offline_paper_allowed","package":"jdg.edelivery.hyper","priority":1266,"_routing":"","_routing_reason":"Kiedy dozwolona forma papierowa","_legal_basis":"OP","_warnings":["Forma papierowa tylko przy awarii systemów"]} {
    object.get(input.document, "eus_outage", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.language_polish","package":"jdg.edelivery.hyper","priority":1267,"_routing":"","_routing_reason":"Komunikacja w języku polskim","_legal_basis":"OP","_warnings":["Obowiązek komunikacji w języku polskim"]} {
    object.get(input.document, "edelivery_notification", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.language_foreign_translation","package":"jdg.edelivery.hyper","priority":1268,"_routing":"","_routing_reason":"Tłumaczenie przysięgłe","_legal_basis":"OP","_warnings":["Dokumenty obcojęzyczne → tłumaczenie przysięgłe"]} {
    object.get(input.document, "foreign_language_documents", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.aggregate_dashboard","package":"jdg.edelivery.hyper","priority":1269,"_routing":"","_routing_reason":"Dashboard komunikacji","_legal_basis":"OP","_warnings":["Dashboard statusu komunikacji z organami"]} {
    object.get(input.document, "edelivery_notification", false) == true
}

# ══ R1270-R1275: Outgoing Mail Dispatcher (L6 Fix) — warstwa wysyłkowa e-Doręczeń ══
# NOTE: R1270 (deadline check) fires before R1271 (dispatcher) — specific condition first
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.outbox_filing_deadline_check","package":"jdg.edelivery.hyper","priority":1270,"_routing":"BLOCK_AND_ALERT","_routing_reason":"e-Delivery: sprawdź termin złożenia","_legal_basis":"Art. 12 OrdPU","_warnings":["Przed wysyłką sprawdź termin ustawowy złożenia pisma! Data nadania przez e-Doręczenia = data złożenia. Nie przegap deadlinów"]} {
    object.get(input.document, "filing_deadline_approaching", false) == true
    object.get(input.document, "outbox_dispatch_ready", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.outbox_auto_dispatcher","package":"jdg.edelivery.hyper","priority":1271,"_routing":"TRIAGE_QUEUE","_routing_reason":"e-Delivery: auto-wysyłka pism do US","_legal_basis":"Ustawa o doręczeniach el. + Art. 168 OrdPU","_warnings":["Automatyczna wysyłka pism przez e-Doręczenia: odwołania, wnioski, deklaracje, wyjaśnienia. Podpisz kwalifikowanym lub profilem zaufanym"]} {
    object.get(input.document, "outbox_dispatch_ready", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.outbox_upo_tracker","package":"jdg.edelivery.hyper","priority":1272,"_routing":"WARNING","_routing_reason":"e-Delivery: tracker UPO wysyłki","_legal_basis":"Art. 168 OrdPU","_warnings":["Śledzenie UPO (Urzędowe Poświadczenie Odbioru) dla każdego wysłanego pisma. Zachowaj UPO jako dowód złożenia — wartość dowodowa"]} {
    object.get(input.document, "outbox_document_sent", false) == true
    object.get(input.document, "upo_received", false) == false
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.outbox_attachment_validator","package":"jdg.edelivery.hyper","priority":1273,"_routing":"","_routing_reason":"e-Delivery: walidacja załączników","_legal_basis":"OP","_warnings":["Sprawdź kompletność załączników przed wysyłką: PIT-36, PIT/O, PIT/B, JPK_V7, pełnomocnictwa. Maks. rozmiar: 10 MB (ePUAP)"]} {
    object.get(input.document, "outbox_attachments_ready", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.outbox_encryption_enforced","package":"jdg.edelivery.hyper","priority":1274,"_routing":"WARNING","_routing_reason":"e-Delivery: szyfrowanie wysyłki","_legal_basis":"RODO + KPA","_warnings":["Szyfruj dane wrażliwe przy wysyłce: PESEL, NIP, dane osobowe. e-Doręczenia domyślnie szyfrowane, ale weryfikuj certyfikat BAE"]} {
    object.get(input.document, "outbox_contains_personal_data", false) == true
}
else := {"matched":true,"rule_id":"jdg.edelivery.hyper.outbox_history_5years_retention","package":"jdg.edelivery.hyper","priority":1275,"_routing":"","_routing_reason":"e-Delivery: retencja korespondencji 5 lat","_legal_basis":"Art. 86 OrdPU","_warnings":["Archiwizuj kopie wysłanych pism + UPO przez 5 lat. Obowiązek dowodowy w razie sporu z US"]} {
    object.get(input.document, "outbox_archive_check_due", false) == true
}
