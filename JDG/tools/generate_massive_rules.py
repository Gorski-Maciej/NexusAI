#!/usr/bin/env python3
"""
NexusAI JDG — Massive Rule Generator from Plan OPA specifications.
Parses multiple Plan OPA files and generates Rego rules systematically.
Handles: files 36 (pseudocode), 38a (10-field), 42 (Deep Gap), 43 (KKS), 44 (Advanced), 45 (Hyper)
"""
import re, os, sys
from collections import defaultdict
from datetime import datetime

DRY_RUN = "--dry-run" in sys.argv
FORCE = "--force" in sys.argv
BASE = "JDG/rules"

# ═══════════════════════════════════════════════════════════════════════════════
# STRUCTURED RULE SPECIFICATIONS (from Plan OPA files 42, 43, 44, 45)
# ═══════════════════════════════════════════════════════════════════════════════

# Each section: list of (rule_id, description, legal_basis, priority, routing, warnings)
# From Plan OPA 42 (Deep Gap Discovery) — 55 Macro rules
DEEP_GAP_RULES = {
    # PKPiR columns (P811-P818)
    "jdg.accounting.pkpir_col1_sequential": {
        "desc": "Walidacja ciągłości numeracji w kolumnie 1 (Lp.) PKPiR",
        "basis": "§ 9 ust. 1 Rozporządzenia MF ws. PKPiR",
        "priority": 811, "routing": "TRIAGE_QUEUE",
        "warnings": ["Luka w numeracji PKPiR — sprawdź ciągłość LP"]
    },
    "jdg.accounting.pkpir_col2_date_validation": {
        "desc": "Walidacja daty w kolumnie 2 — data zdarzenia ≤ data wpisu",
        "basis": "§ 12 ust. 1 Rozporządzenia ws. PKPiR",
        "priority": 812, "routing": "TRIAGE_QUEUE",
        "warnings": ["Data zdarzenia późniejsza niż data wpisu — skoryguj chronologię"]
    },
    "jdg.accounting.pkpir_col6_7_kup_validation": {
        "desc": "Poprawna klasyfikacja KUP na bezpośrednie (kol. 6) i pośrednie (kol. 7)",
        "basis": "Art. 22 ust. 5-5c PIT",
        "priority": 813, "routing": "TRIAGE_QUEUE",
        "warnings": ["Błędna klasyfikacja KUP — sprawdź czy koszt jest bezpośredni czy pośredni"]
    },
    "jdg.accounting.pkpir_col8_goods_purchase": {
        "desc": "Walidacja poprawności wyceny w kolumnie 8 (zakup towarów handlowych i materiałów)",
        "basis": "§ 3 pkt 8 Rozporządzenia ws. PKPiR",
        "priority": 814, "routing": "WARNING",
        "warnings": ["Sprawdź wycenę zakupu — VAT nieodliczalny doliczany do wartości"]
    },
    "jdg.accounting.pkpir_col14_notes_mandatory": {
        "desc": "Kolumna 14 (Uwagi) musi być wypełniona gdy wymagane wyjaśnienie",
        "basis": "§ 13 Rozporządzenia ws. PKPiR",
        "priority": 815, "routing": "WARNING",
        "warnings": ["Wymagane uwagi w kolumnie 14 — uzupełnij wyjaśnienie"]
    },
    "jdg.accounting.pkpir_remnant_consistency": {
        "desc": "Spis z natury — remanent końcowy = remanent początkowy następnego roku",
        "basis": "§ 27-28 Rozporządzenia ws. PKPiR",
        "priority": 816, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Niezgodność remanentu — koniec roku N ≠ początek roku N+1"]
    },
    "jdg.accounting.pkpir_retention_5years": {
        "desc": "Obowiązek przechowywania PKPiR przez 5 lat",
        "basis": "Art. 86 § 1 Ordynacji podatkowej",
        "priority": 817, "routing": "WARNING",
        "warnings": ["Dokumenty PKPiR — sprawdź okres przechowywania (5 lat)"]
    },
    "jdg.accounting.pkpir_income_calculation": {
        "desc": "Automatyczne wyliczenie dochodu z kolumn PKPiR",
        "basis": "Art. 24 ust. 1-2 PIT",
        "priority": 818, "routing": "",
        "warnings": []
    },
    # VAT reduced rates (P66-P72)
    "jdg.vat.reduced_rate_8pct_food": {
        "desc": "Walidacja stawki 8% VAT dla żywności",
        "basis": "Rozporządzenie MF z 4.12.2024 r. ws. obniżonych stawek VAT",
        "priority": 66, "routing": "TRIAGE_QUEUE",
        "warnings": ["Kod CN nie pasuje do stawki 8% — sprawdź klasyfikację"]
    },
    "jdg.vat.reduced_rate_5pct_books": {
        "desc": "Walidacja stawki 5% VAT dla książek/e-booków",
        "basis": "Rozporządzenie MF z 4.12.2024 r., Załącznik nr 2",
        "priority": 67, "routing": "TRIAGE_QUEUE",
        "warnings": ["Kod CN nie pasuje do stawki 5% dla książek"]
    },
    "jdg.vat.rate_8pct_construction": {
        "desc": "Stawka 8% VAT dla budownictwa mieszkaniowego",
        "basis": "Art. 41 ust. 12-12c VAT",
        "priority": 68, "routing": "TRIAGE_QUEUE",
        "warnings": ["Budynek nie spełnia kryteriów budownictwa mieszkaniowego dla stawki 8%"]
    },
    "jdg.vat.rate_8pct_medical": {
        "desc": "Stawka 8% VAT dla sprzętu medycznego",
        "basis": "Rozporządzenie MF z 4.12.2024 r., Załącznik nr 1",
        "priority": 70, "routing": "TRIAGE_QUEUE",
        "warnings": ["Sprzęt nie kwalifikuje się jako wyrób medyczny — stawka 23%"]
    },
    "jdg.vat.rate_5pct_baby": {
        "desc": "Stawka 5% VAT dla produktów dla niemowląt",
        "basis": "Rozporządzenie MF z 4.12.2024 r., Załącznik nr 2",
        "priority": 71, "routing": "WARNING",
        "warnings": ["Produkt spoza listy artykułów dziecięcych objętych stawką 5%"]
    },
    "jdg.vat.reduced_rate_cross_check": {
        "desc": "Cross-check wszystkich obniżonych stawek VAT",
        "basis": "Art. 64 KKS — procedury audytowe",
        "priority": 72, "routing": "WARNING",
        "warnings": ["Nietypowy udział obniżonych stawek VAT — zalecany audyt"]
    },
    # KKS detailed (P130-P141_b)
    "jdg.kks.unreliable_pkpir_art56": {
        "desc": "Nierzetelne prowadzenie PKPiR — Art. 56 KKS",
        "basis": "Art. 56 § 1-4 KKS",
        "priority": 130, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Ryzyko KKS Art. 56 — nierzetelne PKPiR! Kara grzywny do 720 stawek dziennych"]
    },
    "jdg.kks.unreliable_vat_evidence_art57": {
        "desc": "Nierzetelna ewidencja VAT — Art. 57 KKS",
        "basis": "Art. 57 § 1 KKS",
        "priority": 131, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Ryzyko KKS Art. 57 — nierzetelna ewidencja VAT!"]
    },
    "jdg.kks.empty_invoice_art62": {
        "desc": "Pusta faktura — Art. 62 § 2 KKS (kara do 8 lat pozbawienia wolności)",
        "basis": "Art. 62 § 2 KKS",
        "priority": 132, "routing": "BLOCK_AND_ALERT",
        "warnings": ["PUSTA FAKTURA! Czynność nie miała miejsca. Ryzyko KKS Art. 62 § 2 — do 8 lat pozbawienia wolności!"]
    },
    "jdg.kks.wrong_vat_rate_art64": {
        "desc": "Niewłaściwa stawka VAT — Art. 64 KKS",
        "basis": "Art. 64 KKS",
        "priority": 133, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Ryzyko KKS Art. 64 — niewłaściwa stawka VAT!"]
    },
    "jdg.kks.tax_return_non_filing_art77": {
        "desc": "Niezłożenie deklaracji w terminie — Art. 77 KKS",
        "basis": "Art. 77 § 1-3 KKS",
        "priority": 134, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Deklaracja niezłożona w terminie! Ryzyko KKS Art. 77"]
    },
    "jdg.kks.non_payment_of_tax_art79": {
        "desc": "Niezapłacenie podatku w terminie — Art. 79 KKS",
        "basis": "Art. 79 KKS",
        "priority": 135, "routing": "TRIAGE_QUEUE",
        "warnings": ["Zaległość podatkowa — ryzyko KKS Art. 79"]
    },
    "jdg.kks.destruction_of_documents_art68": {
        "desc": "Zniszczenie/ukrycie dokumentów — Art. 68 KKS",
        "basis": "Art. 68 KKS",
        "priority": 136, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Luki w dokumentacji podatkowej — ryzyko KKS Art. 68!"]
    },
    "jdg.kks.voluntary_disclosure_art16": {
        "desc": "Czynny żal — warunki uniknięcia kary KKS",
        "basis": "Art. 16 § 1-3 KKS",
        "priority": 137, "routing": "",
        "warnings": ["Czynny żal — złóż zawiadomienie przed wykryciem przez US"]
    },
    "jdg.kks.criminal_statute_art44": {
        "desc": "Przedawnienie karalności KKS — 5 lat (przestępstwo), 3 lata (wykroczenie)",
        "basis": "Art. 44 § 1-5 KKS",
        "priority": 138, "routing": "WARNING",
        "warnings": ["Zbliża się termin przedawnienia karalności"]
    },
    "jdg.kks.fiscal_penalty_calculation": {
        "desc": "Kalkulacja grzywny KKS — stawka dzienna × liczba stawek",
        "basis": "Art. 23 § 1-3 KKS",
        "priority": 139, "routing": "WARNING",
        "warnings": ["Szacowana grzywna KKS — zweryfikuj poprawność deklaracji"]
    },
    "jdg.kks.obstruction_of_audit_art69": {
        "desc": "Utrudnianie kontroli podatkowej — Art. 69 KKS",
        "basis": "Art. 69 § 1-3 KKS",
        "priority": 140, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Utrudnianie kontroli — ryzyko KKS Art. 69!"]
    },
    "jdg.kks.aggregate_risk_score": {
        "desc": "Agregacja wszystkich flag KKS w jeden wskaźnik ryzyka",
        "basis": "Całość KKS — reguła pomocnicza",
        "priority": 141, "routing": "",
        "warnings": ["Podwyższony profil ryzyka KKS — sprawdź szczegółowe alerty"]
    },
    # ZUS benefits (P1200zs-P1206zs)
    "jdg.zus.sickness_benefit_eligibility": {
        "desc": "Zasiłek chorobowy JDG — warunki (90 dni wyczekiwania)",
        "basis": "Art. 4 ust. 1, Art. 7, Art. 48-54 Ustawy zasiłkowej",
        "priority": 1200, "routing": "",
        "warnings": ["Sprawdź uprawnienia do zasiłku chorobowego — okres wyczekiwania 90 dni"]
    },
    "jdg.zus.sickness_benefit_amount": {
        "desc": "Wysokość zasiłku chorobowego — 80% podstawy",
        "basis": "Art. 36-45 Ustawy zasiłkowej",
        "priority": 1201, "routing": "",
        "warnings": []
    },
    "jdg.zus.maternity_benefit": {
        "desc": "Zasiłek macierzyński JDG — 20-37 tygodni",
        "basis": "Art. 29-31 Ustawy zasiłkowej",
        "priority": 1202, "routing": "",
        "warnings": ["Zasiłek macierzyński — wymagane dobrowolne ubezpieczenie chorobowe"]
    },
    "jdg.zus.care_benefit": {
        "desc": "Zasiłek opiekuńczy — max 60 dni/rok (dziecko), 14 dni (rodzina)",
        "basis": "Art. 32-35 Ustawy zasiłkowej",
        "priority": 1203, "routing": "",
        "warnings": []
    },
    "jdg.zus.rehabilitation_benefit": {
        "desc": "Świadczenie rehabilitacyjne po wyczerpaniu zasiłku chorobowego",
        "basis": "Art. 18-22 Ustawy zasiłkowej",
        "priority": 1204, "routing": "",
        "warnings": ["Wyczerpany zasiłek chorobowy — sprawdź świadczenie rehabilitacyjne"]
    },
    "jdg.zus.benefit_payment_deadline": {
        "desc": "Terminy wypłaty zasiłków — ZUS ma 30 dni",
        "basis": "Art. 61-64 Ustawy zasiłkowej",
        "priority": 1205, "routing": "WARNING",
        "warnings": ["ZUS nie wypłacił zasiłku w terminie 30 dni — należą się odsetki"]
    },
    "jdg.zus.benefit_overpayment_detection": {
        "desc": "Nienależnie pobrany zasiłek — praca podczas L4",
        "basis": "Art. 66-68 Ustawy zasiłkowej",
        "priority": 1206, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Aktywność biznesowa podczas zwolnienia — zasiłek nienależny!"]
    },
    # KŚT (P880-P884)
    "jdg.accounting.kst_group_classification": {
        "desc": "Klasyfikacja środka trwałego do grupy KŚT (1-10)",
        "basis": "Rozporządzenie RM ws. KŚT",
        "priority": 880, "routing": "",
        "warnings": []
    },
    "jdg.accounting.depreciation_rate_assignment": {
        "desc": "Automatyczne przypisanie stawki amortyzacyjnej wg grupy KŚT",
        "basis": "Wykaz stawek amortyzacyjnych (Załącznik nr 1 do ustawy o PIT)",
        "priority": 881, "routing": "",
        "warnings": []
    },
    "jdg.accounting.intangible_assets_classification": {
        "desc": "Klasyfikacja WNiP wg KŚT (licencje, patenty, software)",
        "basis": "Art. 22b PIT",
        "priority": 882, "routing": "",
        "warnings": []
    },
    "jdg.accounting.one_time_depreciation_eligibility": {
        "desc": "Jednorazowa amortyzacja — limit 10 000 PLN / 100 000 PLN",
        "basis": "Art. 22d ust. 1 PIT",
        "priority": 883, "routing": "",
        "warnings": []
    },
    "jdg.accounting.improvement_threshold_check": {
        "desc": "Ulepszenie środka trwałego — próg 10 000 PLN",
        "basis": "Art. 22g ust. 17 PIT",
        "priority": 884, "routing": "WARNING",
        "warnings": ["Ulepszenia przekroczyły 10 000 PLN — zwiększ wartość początkową"]
    },
    # RODO (P1610-P1613)
    "jdg.rodo.dpa_registration_check": {
        "desc": "Obowiązek rejestracji DPA w UODO",
        "basis": "Art. 30, 36 RODO",
        "priority": 1610, "routing": "TRIAGE_QUEUE",
        "warnings": ["JDG przetwarza dane osobowe — sprawdź obowiązek rejestracji w UODO"]
    },
    "jdg.rodo.data_breach_notification": {
        "desc": "Obowiązek zgłoszenia naruszenia danych w 72h",
        "basis": "Art. 33-34 RODO",
        "priority": 1611, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Naruszenie danych — obowiązek zgłoszenia do UODO w ciągu 72 godzin!"]
    },
    "jdg.rodo.data_retention_policy": {
        "desc": "Okresy retencji danych osobowych",
        "basis": "Art. 5 ust. 1 lit. e RODO",
        "priority": 1612, "routing": "WARNING",
        "warnings": ["Przekroczony okres przechowywania danych osobowych"]
    },
    "jdg.rodo.dpo_requirement": {
        "desc": "Sprawdzenie czy JDG musi wyznaczyć DPO",
        "basis": "Art. 37 RODO",
        "priority": 1613, "routing": "WARNING",
        "warnings": ["JDG może wymagać Inspektora Ochrony Danych (DPO)"]
    },
    # MPiPS (P770-P773)
    "jdg.zus.contribution_base_calculation": {
        "desc": "Podstawa wymiaru składek społecznych — 60% przeciętnego wynagrodzenia",
        "basis": "Art. 18 ust. 8 SUS",
        "priority": 770, "routing": "",
        "warnings": []
    },
    "jdg.zus.contribution_split_by_fund": {
        "desc": "Rozbicie składek ZUS na fundusze",
        "basis": "Art. 22 SUS",
        "priority": 771, "routing": "",
        "warnings": []
    },
    "jdg.zus.contribution_deadline": {
        "desc": "Terminy opłacania składek ZUS (10/15/20 dzień miesiąca)",
        "basis": "Art. 47 ust. 1-2 SUS",
        "priority": 772, "routing": "WARNING",
        "warnings": ["Składki ZUS po terminie — naliczane odsetki!"]
    },
    "jdg.zus.contribution_payment_verification": {
        "desc": "Weryfikacja czy wszystkie składki ZUS opłacone",
        "basis": "Art. 47 SUS",
        "priority": 773, "routing": "TRIAGE_QUEUE",
        "warnings": ["Niedopłata składek ZUS — ryzyko egzekucji!"]
    },
    # UoR (P875-P879)
    "jdg.uor.inventory_obligation": {
        "desc": "Inwentaryzacja — obowiązek w pełnej księgowości",
        "basis": "Art. 26 ust. 1-3 UoR",
        "priority": 875, "routing": "WARNING",
        "warnings": ["Inwentaryzacja zaległa — wymagana minimum raz na 2 lata"]
    },
    "jdg.uor.asset_valuation": {
        "desc": "Wycena aktywów i pasywów — zasada ostrożności",
        "basis": "Art. 28 ust. 1-7 UoR",
        "priority": 876, "routing": "WARNING",
        "warnings": ["Brak odpisu aktualizującego przy trwałej utracie wartości"]
    },
    "jdg.uor.accruals_deferrals": {
        "desc": "Rozliczenia międzyokresowe kosztów (RMK)",
        "basis": "Art. 39 UoR",
        "priority": 877, "routing": "WARNING",
        "warnings": ["Brak rozliczeń międzyokresowych — koszty w złym okresie"]
    },
    "jdg.uor.financial_statement": {
        "desc": "Sprawozdanie finansowe — termin 3 miesiące od dnia bilansowego",
        "basis": "Art. 45, 52 UoR",
        "priority": 878, "routing": "TRIAGE_QUEUE",
        "warnings": ["Sprawozdanie finansowe niezłożone w terminie!"]
    },
    "jdg.uor.document_storage": {
        "desc": "Przechowywanie dokumentacji księgowej 5 lat",
        "basis": "Art. 74 UoR",
        "priority": 879, "routing": "WARNING", 
        "warnings": ["Dokumenty księgowe — okres przechowywania 5 lat"]
    },
    # PCC (P1301-P1304)
    "jdg.pcc.loan_from_private_person": {
        "desc": "PCC od pożyczki od osoby prywatnej — 0.5%",
        "basis": "Art. 1 ust. 1 pkt 2, Art. 7 ust. 1 pkt 4 Ustawy o PCC",
        "priority": 1301, "routing": "WARNING",
        "warnings": ["Pożyczka od osoby prywatnej — PCC-3 w ciągu 14 dni!"]
    },
    "jdg.pcc.car_purchase_from_private": {
        "desc": "PCC od zakupu samochodu od osoby prywatnej — 2%",
        "basis": "Art. 1 ust. 1 pkt 1 lit. a Ustawy o PCC",
        "priority": 1302, "routing": "WARNING",
        "warnings": ["Zakup auta od osoby prywatnej — PCC-3 w ciągu 14 dni, stawka 2%"]
    },
    "jdg.pcc.real_estate_purchase": {
        "desc": "PCC od zakupu nieruchomości od osoby prywatnej — 2%",
        "basis": "Art. 1 ust. 1 pkt 1 lit. a Ustawy o PCC",
        "priority": 1303, "routing": "WARNING",
        "warnings": ["Zakup nieruchomości od osoby prywatnej — PCC 2%, notariusz pobiera"]
    },
    "jdg.pcc.aggregate_liability_check": {
        "desc": "Agregacja wszystkich zobowiązań PCC",
        "basis": "Ustawa o PCC",
        "priority": 1304, "routing": "WARNING",
        "warnings": ["Niezłożone deklaracje PCC-3 w roku podatkowym"]
    },
}

# From Plan OPA 44 (Advanced Gaps) — ~115 rules in 20 areas
ADVANCED_GAP_RULES = {
    # MDR/DAC6
    "jdg.mdr.reportable_scheme_detection": {
        "desc": "Wykrywanie schematów podatkowych MDR (DAC6)",
        "basis": "Art. 86a-86o Ordynacji podatkowej",
        "priority": 1800, "routing": "TRIAGE_QUEUE",
        "warnings": ["Transakcja nosi cechy schematu MDR — obowiązek zgłoszenia MDR-3 w 30 dni! Sankcja do 5M PLN!"]
    },
    "jdg.mdr.promoter_vs_user": {
        "desc": "Rola MDR: promotor vs korzystający",
        "basis": "Art. 86a § 1 Ordynacji podatkowej",
        "priority": 1801, "routing": "TRIAGE_QUEUE",
        "warnings": ["Ustalono rolę MDR — sprawdź obowiązki raportowania"]
    },
    "jdg.mdr.deadline_tracking": {
        "desc": "Śledzenie terminów MDR i kary za brak zgłoszenia",
        "basis": "Art. 86o Ordynacji podatkowej",
        "priority": 1802, "routing": "BLOCK_AND_ALERT",
        "warnings": ["MDR-3 niezłożony w terminie 30 dni! Kara administracyjna do 5M PLN + KKS!"]
    },
    # Solidarity levy
    "jdg.solidarity.threshold_detection": {
        "desc": "Danina solidarnościowa 4% — próg 1 000 000 PLN",
        "basis": "Art. 30h PIT",
        "priority": 1810, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Dochód przekroczył 1M PLN — danina solidarnościowa 4% od nadwyżki!"]
    },
    # WIS/WIA/WIT
    "jdg.wis.binding_rate_check": {
        "desc": "WIS — identyfikacja towarów wymagających WIS",
        "basis": "Art. 42a-42h VAT",
        "priority": 1820, "routing": "WARNING",
        "warnings": ["Towar o niejednoznacznej klasyfikacji — rozważ uzyskanie WIS"]
    },
    "jdg.wis.validity_monitoring": {
        "desc": "Monitorowanie ważności WIS (5 lat)",
        "basis": "Art. 42h VAT",
        "priority": 1821, "routing": "WARNING",
        "warnings": ["WIS wygasa — złóż wniosek o nową"]
    },
    # Tax audit procedures
    "jdg.audit.type_determination": {
        "desc": "Typ kontroli podatkowej — czynności sprawdzające / kontrola / postępowanie",
        "basis": "Art. 272-292 Ordynacji podatkowej",
        "priority": 1830, "routing": "",
        "warnings": []
    },
    "jdg.audit.rights_and_obligations": {
        "desc": "Prawa i obowiązki JDG podczas kontroli",
        "basis": "Art. 281-292 Ordynacji podatkowej",
        "priority": 1831, "routing": "",
        "warnings": []
    },
    "jdg.audit.protocol_objections": {
        "desc": "Zastrzeżenia do protokołu kontroli — 14 dni",
        "basis": "Art. 291 § 1-2 Ordynacji podatkowej",
        "priority": 1832, "routing": "WARNING",
        "warnings": ["Termin na zastrzeżenia do protokołu upływa — zostało X dni"]
    },
    "jdg.audit.statute_suspension": {
        "desc": "Zawieszenie przedawnienia na czas kontroli",
        "basis": "Art. 70 § 6 pkt 1 Ordynacji podatkowej",
        "priority": 1833, "routing": "",
        "warnings": ["Kontrola w toku — bieg przedawnienia zawieszony"]
    },
    # Force majeure
    "jdg.force_majeure.tax_relief": {
        "desc": "Ulgi podatkowe w przypadku siły wyższej",
        "basis": "Art. 67a-67e Ordynacji podatkowej",
        "priority": 1850, "routing": "",
        "warnings": ["Siła wyższa — sprawdź dostępne ulgi podatkowe"]
    },
    "jdg.force_majeure.zus_relief": {
        "desc": "Ulgi ZUS w przypadku siły wyższej",
        "basis": "Art. 28-29 SUS",
        "priority": 1851, "routing": "",
        "warnings": ["Siła wyższa — możliwe odroczenie/umorzenie składek ZUS"]
    },
    "jdg.force_majeure.documentation_loss": {
        "desc": "Utrata dokumentacji przez siłę wyższą — procedura odtworzenia",
        "basis": "Art. 86 § 2 Ordynacji podatkowej",
        "priority": 1852, "routing": "TRIAGE_QUEUE",
        "warnings": ["Utrata dokumentów — zgłoś do US w 7 dni!"]
    },
    # Family in JDG
    "jdg.family.spouse_employment_kup": {
        "desc": "Wynagrodzenie małżonka — warunki KUP",
        "basis": "Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 10 PIT",
        "priority": 1860, "routing": "TRIAGE_QUEUE",
        "warnings": ["Wynagrodzenie małżonka — upewnij się, że spełnia kryteria rynkowe"]
    },
    "jdg.family.child_employment_kup": {
        "desc": "Wynagrodzenie dziecka — ograniczenia KUP",
        "basis": "Art. 23 ust. 1 pkt 10 PIT",
        "priority": 1861, "routing": "TRIAGE_QUEUE",
        "warnings": ["Wynagrodzenie dziecka — podwyższone ryzyko kontroli US"]
    },
    # E-communication
    "jdg.edelivery.fiction_detection": {
        "desc": "Fikcja doręczenia e-Doręczeń po 14 dniach",
        "basis": "Ustawa o doręczeniach elektronicznych",
        "priority": 1870, "routing": "BLOCK_AND_ALERT",
        "warnings": ["PISMO UZNANE ZA DORĘCZONE PRZEZ FIKCJĘ! Sprawdź natychmiast e-US!"]
    },
    "jdg.edelivery.platform_monitoring": {
        "desc": "Monitorowanie konta e-US",
        "basis": "Art. 144b Ordynacji podatkowej",
        "priority": 1871, "routing": "WARNING",
        "warnings": ["Nowe pisma na e-US — sprawdź skrzynkę"]
    },
    # Public procurement
    "jdg.procurement.tax_clearance": {
        "desc": "Zaświadczenie o niezaleganiu dla zamówień publicznych",
        "basis": "Art. 306e Ordynacji podatkowej",
        "priority": 1880, "routing": "",
        "warnings": []
    },
    # FX rules
    "jdg.fx.vat_rate_determination": {
        "desc": "Kurs waluty dla celów VAT",
        "basis": "Art. 30a-31a VAT",
        "priority": 1890, "routing": "",
        "warnings": []
    },
    "jdg.fx.pit_rate_determination": {
        "desc": "Kurs waluty dla celów PIT",
        "basis": "Art. 14 ust. 1aa PIT",
        "priority": 1891, "routing": "",
        "warnings": []
    },
    "jdg.fx.differences_method": {
        "desc": "Metoda rozliczania różnic kursowych (podatkowa vs rachunkowa)",
        "basis": "Art. 14b PIT",
        "priority": 1892, "routing": "",
        "warnings": []
    },
    # TP (Transfer Pricing)
    "jdg.tp.related_party_detection": {
        "desc": "Wykrycie transakcji z podmiotami powiązanymi",
        "basis": "Art. 23m-23zf PIT",
        "priority": 1930, "routing": "TRIAGE_QUEUE",
        "warnings": ["Transakcja z podmiotem powiązanym — sprawdź obowiązki TP!"]
    },
    "jdg.tp.documentation_thresholds": {
        "desc": "Progi dokumentacyjne TP: 2M/1M/0.5M PLN",
        "basis": "Art. 23zf PIT",
        "priority": 1931, "routing": "WARNING",
        "warnings": ["Przekroczono próg dokumentacyjny TP — wymagany Local File"]
    },
    "jdg.tp.tpr_form_filing": {
        "desc": "TPR-C — obowiązek złożenia do 30 listopada",
        "basis": "Art. 23zh PIT",
        "priority": 1934, "routing": "TRIAGE_QUEUE",
        "warnings": ["TPR-C niezłożony — termin do 30 listopada!"]
    },
    "jdg.tp.documentation_penalty": {
        "desc": "Sankcje za brak dokumentacji TP — 10% doszacowanego dochodu",
        "basis": "Art. 56 KKS",
        "priority": 1938, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Brak dokumentacji TP — ryzyko 10% dodatkowego opodatkowania!"]
    },
    # Tax residency
    "jdg.residency.determination": {
        "desc": "Określenie rezydencji podatkowej — test 183 dni",
        "basis": "Art. 3 PIT",
        "priority": 1940, "routing": "",
        "warnings": []
    },
    "jdg.residency.exit_tax": {
        "desc": "Exit tax przy zmianie rezydencji — próg 4M PLN, stawka 19%",
        "basis": "Art. 30da PIT",
        "priority": 1944, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Zmiana rezydencji podatkowej — exit tax od aktywów >4M PLN!"]
    },
    # KKS conviction effects
    "jdg.kks.conviction_business_ban": {
        "desc": "Zakaz prowadzenia działalności po skazaniu KKS",
        "basis": "Art. 41 KK",
        "priority": 1960, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Skazanie KKS — zakaz prowadzenia działalności gospodarczej!"]
    },
    "jdg.kks.conviction_rehabilitation": {
        "desc": "Zatarcie skazania KKS — 3/5 lat",
        "basis": "Art. 21 KKS, Art. 106 KK",
        "priority": 1964, "routing": "",
        "warnings": []
    },
    # Non-standard payments
    "jdg.payments.crypto_as_payment": {
        "desc": "Przyjęcie krypto jako zapłaty — przychód wg kursu PLN",
        "basis": "Art. 14 ust. 1 PIT",
        "priority": 1990, "routing": "",
        "warnings": ["Zapłata w krypto — przelicz na PLN wg kursu z dnia transakcji"]
    },
    "jdg.payments.barter_transaction": {
        "desc": "Transakcje barterowe — dwustronna dostawa dla VAT",
        "basis": "Art. 7, 8 VAT",
        "priority": 1991, "routing": "WARNING",
        "warnings": ["Barter — każda strona wystawia fakturę VAT"]
    },
    "jdg.payments.offsetting_kompensata": {
        "desc": "Kompensata wzajemnych wierzytelności",
        "basis": "Art. 498 KC",
        "priority": 1992, "routing": "",
        "warnings": []
    },
    "jdg.payments.instalment_recognition": {
        "desc": "Sprzedaż na raty — przychód w dacie każdej raty",
        "basis": "Art. 14 PIT",
        "priority": 1993, "routing": "",
        "warnings": []
    },
    "jdg.payments.advance_vat_obligation": {
        "desc": "Zaliczka — obowiązek VAT w dacie otrzymania",
        "basis": "Art. 19a ust. 8 VAT",
        "priority": 1994, "routing": "WARNING",
        "warnings": ["Otrzymano zaliczkę — wystaw fakturę zaliczkową w 15 dni!"]
    },
    # Advertising KUP
    "jdg.advertising.vs_representation": {
        "desc": "Rozróżnienie reklama (KUP) vs reprezentacja (NKUP)",
        "basis": "Art. 23 ust. 1 pkt 23 PIT",
        "priority": 1999, "routing": "WARNING",
        "warnings": ["Wydatek może być reprezentacją (NKUP), nie reklamą — zweryfikuj"]
    },
    "jdg.advertising.gifts_limit_200": {
        "desc": "Prezenty dla kontrahentów — limit 200 PLN, tylko z logo",
        "basis": "Art. 23 ust. 1 pkt 23 PIT",
        "priority": 2002, "routing": "WARNING",
        "warnings": ["Prezent >200 PLN lub bez logo — NKUP jako reprezentacja"]
    },
    "jdg.advertising.sponsorship_kup": {
        "desc": "Sponsoring — KUP z kontrświadczeniem, darowizna bez",
        "basis": "Art. 22 PIT, Art. 26 PIT",
        "priority": 2003, "routing": "WARNING",
        "warnings": ["Sponsoring bez kontrświadczeń traktowany jak darowizna — limit 6%"]
    },
    "jdg.advertising.car_wrapping_vat26": {
        "desc": "Oklejenie auta reklamą — VAT-26 → 100% odliczenia",
        "basis": "Art. 86a VAT",
        "priority": 2006, "routing": "",
        "warnings": ["Oklejenie reklamowe — złóż VAT-26 dla 100% odliczenia VAT"]
    },
}

# From Plan OPA 43 (KKS Massive Decomposition) — 230 Macro rules  
KKS_DECOMPOSITION_RULES = {
    # Art. 16 KKS — Czynny żal (P200-P209)
    "jdg.kks.vd_conditions_art16_p1": {
        "desc": "Czynny żal — warunki formalne (zawiadomienie przed wykryciem)",
        "basis": "Art. 16 § 1 KKS",
        "priority": 200, "routing": "",
        "warnings": ["Czynny żal — złóż zawiadomienie przed wszczęciem kontroli"]
    },
    "jdg.kks.vd_payment_obligation_art16_p2": {
        "desc": "Czynny żal — obowiązek wpłaty w 7 dni",
        "basis": "Art. 16 § 2 KKS",
        "priority": 201, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Czynny żal — nie wpłacono należności w terminie 7 dni!"]
    },
    "jdg.kks.vd_incomplete_notification_art16_p3": {
        "desc": "Czynny żal — kompletność zawiadomienia",
        "basis": "Art. 16 § 3 KKS",
        "priority": 202, "routing": "TRIAGE_QUEUE",
        "warnings": ["Czynny żal — zawiadomienie niekompletne"]
    },
    "jdg.kks.vd_effect_no_penalty_art16_p8": {
        "desc": "Czynny żal — skutek: brak kary",
        "basis": "Art. 16 § 8 KKS",
        "priority": 207, "routing": "",
        "warnings": []
    },
    # Art. 20-21 KKS — Przedawnienie (P220-P224)
    "jdg.kks.statute_crime_5y_art20_p1": {
        "desc": "Przedawnienie przestępstw KKS — 5 lat",
        "basis": "Art. 20 § 1 KKS",
        "priority": 220, "routing": "",
        "warnings": []
    },
    "jdg.kks.statute_misdemeanor_3y_art20_p2": {
        "desc": "Przedawnienie wykroczeń KKS — 3 lata",
        "basis": "Art. 20 § 2 KKS",
        "priority": 221, "routing": "",
        "warnings": []
    },
    "jdg.kks.statute_extension_5y_art20_p3": {
        "desc": "Przedłużenie przedawnienia o 5 lat",
        "basis": "Art. 20 § 3 KKS",
        "priority": 222, "routing": "",
        "warnings": ["Przedawnienie wydłużone o 5 lat — wszczęto postępowanie"]
    },
    "jdg.kks.statute_interruption_art21_p1": {
        "desc": "Przerwanie biegu przedawnienia KKS",
        "basis": "Art. 21 § 1 KKS",
        "priority": 223, "routing": "",
        "warnings": ["Bieg przedawnienia przerwany — nowy termin"]
    },
    # Art. 54 KKS — Uchylanie się od opodatkowania (P240-P254)
    "jdg.kks.tax_evasion_elements_art54_p1": {
        "desc": "Znamiona uchylania się od opodatkowania",
        "basis": "Art. 54 § 1 KKS",
        "priority": 240, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Wykryto znamiona uchylania się od opodatkowania! Ryzyko KKS Art. 54!"]
    },
    "jdg.kks.tax_evasion_significant_art54_p2": {
        "desc": "Kwalifikowana forma uchylania — duża wartość",
        "basis": "Art. 54 § 2 KKS",
        "priority": 241, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Uszczuplenie dużej wartości — zaostrzona odpowiedzialność KKS!"]
    },
    "jdg.kks.tax_evasion_concealed_business_art54_p3": {
        "desc": "Całkowicie ukryta działalność gospodarcza",
        "basis": "Art. 54 § 3 KKS",
        "priority": 242, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Działalność bez rejestracji CEIDG — ryzyko KKS Art. 54!"]
    },
    # Art. 56 KKS — Nierzetelne PKPiR (P255-P269)
    "jdg.kks.unreliable_pkpir_systematic_art56_p2": {
        "desc": "Systematyczne nierzetelne PKPiR",
        "basis": "Art. 56 § 2 KKS",
        "priority": 256, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Systematyczna nierzetelność PKPiR — zaostrzona odpowiedzialność!"]
    },
    "jdg.kks.pkpir_fictitious_entries_art56_p3": {
        "desc": "Fikcyjne wpisy w PKPiR",
        "basis": "Art. 56 § 3 KKS",
        "priority": 257, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Fikcyjne wpisy w PKPiR — ryzyko KKS Art. 56 § 3!"]
    },
    # Art. 62 KKS — Puste faktury (P300-P319)
    "jdg.kks.empty_invoice_carousel_art62_p3": {
        "desc": "Karuzela VAT — łańcuch pustych faktur",
        "basis": "Art. 62 § 2 KKS",
        "priority": 302, "routing": "BLOCK_AND_ALERT",
        "warnings": ["KARUZELA VAT! Łańcuch pustych faktur — ryzyko do 15 lat pozbawienia wolności!"]
    },
    "jdg.kks.invoice_falsification_art62_p4": {
        "desc": "Podrobienie/przerobienie faktury",
        "basis": "Art. 62 § 1 KKS",
        "priority": 303, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Faktura podrobiona/przerobiona — ryzyko KKS Art. 62!"]
    },
    # Art. 77-83 KKS — Wykroczenia (P400-P429)
    "jdg.kks.declaration_non_filing_art77_p1": {
        "desc": "Niezłożenie deklaracji w terminie — wykroczenie",
        "basis": "Art. 77 § 1 KKS",
        "priority": 400, "routing": "WARNING",
        "warnings": ["Deklaracja niezłożona w terminie — wykroczenie skarbowe, grzywna do 180 stawek"]
    },
    "jdg.kks.declaration_persistent_art77_p2": {
        "desc": "Uporczywe niezłożenie deklaracji — przestępstwo",
        "basis": "Art. 77 § 2 KKS",
        "priority": 401, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Uporczywe niezłożenie deklaracji — przestępstwo skarbowe!"]
    },
    "jdg.kks.tax_non_payment_art79_p1": {
        "desc": "Niezapłacenie podatku w terminie — wykroczenie",
        "basis": "Art. 79 KKS",
        "priority": 411, "routing": "WARNING",
        "warnings": ["Podatek niezapłacony w terminie — ryzyko KKS Art. 79"]
    },
    # Aggregacja i sankcje (P430-P499)
    "jdg.kks.fine_daily_rate_art23": {
        "desc": "Stawka dzienna grzywny KKS",
        "basis": "Art. 23 § 1-3 KKS",
        "priority": 490, "routing": "",
        "warnings": []
    },
    "jdg.kks.fine_amount_range_art23_p4": {
        "desc": "Zakres kar grzywny — 10-720 stawek dziennych",
        "basis": "Art. 23 § 4 KKS",
        "priority": 491, "routing": "",
        "warnings": []
    },
    "jdg.kks.imprisonment_substitute_art25": {
        "desc": "Kara zastępcza pozbawienia wolności za nieuiszczoną grzywnę",
        "basis": "Art. 25 KKS",
        "priority": 492, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Grzywna nieuiszczona — ryzyko zastępczej kary pozbawienia wolności!"]
    },
}


# ═══════════════════════════════════════════════════════════════════════════════
# From Plan OPA 23 (Expansion Supplement) and 26 (Comprehensive Expansion) — ~92 rules
# ═══════════════════════════════════════════════════════════════════════════════

PLAN23_26_RULES = {
    # === CROSSBORDER (Doc 23: P43-P49, P190-P191, P232) ===
    "jdg.crossborder.vat_ue_registration_mandatory": {
        "desc": "Blokada transakcji wewnątrzwspólnotowych bez VAT-UE",
        "basis": "Art. 97 ust. 1-3 VAT", "priority": 43, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Brak rejestracji VAT-UE — wymagany VAT-R przed transakcją"]
    },
    "jdg.crossborder.vat_r_ue_filing_deadline": {
        "desc": "VAT-R UE — złóż przed pierwszą transakcją WNT/WDT",
        "basis": "Art. 97 ust. 1-3 VAT", "priority": 44, "routing": "TRIAGE_QUEUE",
        "warnings": ["Zarejestruj VAT-UE przed pierwszą transakcją wewnątrzwspólnotową"]
    },
    "jdg.crossborder.intra_community_acquisition_detailed": {
        "desc": "WNT — naliczenie VAT należnego wg stawki krajowej + odliczenie",
        "basis": "Art. 9, Art. 11, Art. 20 ust. 5 VAT", "priority": 46, "routing": "",
        "warnings": []
    },
    "jdg.crossborder.import_services_non_eu": {
        "desc": "Import usług spoza UE — reverse charge",
        "basis": "Art. 28b, Art. 17 ust. 1 pkt 4 VAT", "priority": 47, "routing": "",
        "warnings": ["Import usług spoza UE — rozlicz VAT należny i naliczony"]
    },
    "jdg.crossborder.triangular_transaction_rules": {
        "desc": "Transakcja trójstronna UE — procedura uproszczona",
        "basis": "Art. 135-138 VAT", "priority": 49, "routing": "",
        "warnings": ["Transakcja trójstronna — procedura uproszczona, brak rejestracji w kraju dostawy"]
    },
    "jdg.crossborder.wnt_intra_community_detailed": {
        "desc": "WNT — obowiązek podatkowy 15. dnia nast. miesiąca lub data faktury",
        "basis": "Art. 20 ust. 5 VAT", "priority": 190, "routing": "",
        "warnings": []
    },
    "jdg.crossborder.import_vat_deduction_timing": {
        "desc": "Odliczenie VAT od importu — w okresie otrzymania dokumentu celnego",
        "basis": "Art. 86 ust. 2 pkt 2, Art. 86 ust. 10b pkt 3 VAT", "priority": 191, "routing": "",
        "warnings": ["VAT od importu — odliczenie w okresie otrzymania dokumentu celnego"]
    },
    "jdg.crossborder.vat_ue_quarterly_summary": {
        "desc": "VAT-UE — informacja podsumowująca kwartalna",
        "basis": "Art. 100 ust. 1 i 3 VAT", "priority": 232, "routing": "TRIAGE_QUEUE",
        "warnings": ["VAT-UE — złóż informację podsumowującą do 25. dnia po kwartale"]
    },
    
    # === ALLOWANCES (Doc 23: P601-P609) ===
    "jdg.allowances.prototype_relief": {
        "desc": "Ulga na prototyp — 30% kosztów produkcji próbnej",
        "basis": "Art. 26eb PIT", "priority": 601, "routing": "",
        "warnings": []
    },
    "jdg.allowances.robotization_relief": {
        "desc": "Ulga na robotyzację — 50% kosztów robotów",
        "basis": "Art. 26gb PIT", "priority": 602, "routing": "",
        "warnings": []
    },
    "jdg.allowances.expansion_relief": {
        "desc": "Ulga ekspansyjna — max 1M PLN rocznie",
        "basis": "Art. 26ec PIT", "priority": 603, "routing": "",
        "warnings": []
    },
    "jdg.allowances.rehabilitation_relief": {
        "desc": "Ulga rehabilitacyjna dla JDG z niepełnosprawnością",
        "basis": "Art. 26 ust. 1 pkt 6 PIT", "priority": 604, "routing": "",
        "warnings": []
    },
    "jdg.allowances.internet_relief": {
        "desc": "Ulga internetowa — max 760 PLN/rok przez 2 lata",
        "basis": "Art. 26 ust. 1 pkt 6a PIT", "priority": 605, "routing": "",
        "warnings": []
    },
    "jdg.allowances.donation_ngo_relief": {
        "desc": "Darowizna OPP — limit 6% dochodu",
        "basis": "Art. 26 ust. 1 pkt 9 lit. a PIT", "priority": 606, "routing": "WARNING",
        "warnings": ["Darowizna OPP — sprawdź limit 6% dochodu"]
    },
    "jdg.allowances.donation_blood_relief": {
        "desc": "Ulga krwiodawcza — 130 PLN/litr",
        "basis": "Art. 26 ust. 1 pkt 9 lit. c PIT", "priority": 607, "routing": "",
        "warnings": []
    },
    "jdg.allowances.donation_church_relief": {
        "desc": "Darowizna na cele kultu religijnego — limit 6%",
        "basis": "Art. 26 ust. 1 pkt 9 lit. b PIT", "priority": 608, "routing": "",
        "warnings": []
    },
    "jdg.allowances.abolition_relief": {
        "desc": "Ulga abolicyjna dla dochodów zagranicznych",
        "basis": "Art. 27g PIT", "priority": 609, "routing": "",
        "warnings": []
    },
    
    # === TAX FORM CHANGE (Doc 23: P590-P596) ===
    "jdg.pit.tax_form_change.scale_to_linear": {
        "desc": "Przejście ze skali na liniowy — tylko od 1 stycznia",
        "basis": "Art. 9a ust. 2 PIT", "priority": 590, "routing": "WARNING",
        "warnings": ["Przejście na liniowy — brak kwoty wolnej, brak ulg osobistych"]
    },
    "jdg.pit.tax_form_change.linear_to_lump_sum": {
        "desc": "Przejście z liniowego na ryczałt",
        "basis": "Art. 9 ustawy o ryczałcie", "priority": 591, "routing": "WARNING",
        "warnings": ["Przejście na ryczałt — koniec amortyzacji, nowa ewidencja"]
    },
    "jdg.pit.tax_form_change.lump_sum_to_scale": {
        "desc": "Powrót z ryczałtu na skalę — remanent początkowy",
        "basis": "Art. 24a PIT", "priority": 592, "routing": "WARNING",
        "warnings": ["Powrót na skalę — załóż PKPiR i sporządź remanent początkowy"]
    },
    "jdg.pit.tax_form_change.mid_year_restriction": {
        "desc": "Blokada zmiany formy opodatkowania w trakcie roku",
        "basis": "Art. 9a ust. 2 PIT", "priority": 593, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Niedozwolona zmiana formy opodatkowania w trakcie roku!"]
    },
    "jdg.pit.tax_form_change.consequences_multiple_returns": {
        "desc": "Utrata ryczałtu w trakcie roku → dwa zeznania roczne",
        "basis": "Art. 22 ustawy o ryczałcie", "priority": 594, "routing": "WARNING",
        "warnings": ["Utrata ryczałtu — złóż PIT-28 + PIT-36"]
    },
    "jdg.pit.tax_form_change.inventory_remeasurement": {
        "desc": "Remanent przy zmianie formy ryczałt↔skala/liniowy",
        "basis": "§ 24 Rozporządzenia ws. PKPiR", "priority": 595, "routing": "",
        "warnings": ["Zmiana formy — wymagany remanent na 1 stycznia"]
    },
    "jdg.pit.tax_form_change.zus_health_recalculation": {
        "desc": "Przeliczenie składki zdrowotnej po zmianie formy",
        "basis": "Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych", "priority": 596, "routing": "WARNING",
        "warnings": ["Zmiana formy — zaktualizuj deklarację ZUS DRA"]
    },
    
    # === LEASING (Doc 23: P860-P868) ===
    "jdg.accounting.operating_lease_kup": {
        "desc": "Leasing operacyjny — cała rata KUP",
        "basis": "Art. 23b PIT", "priority": 860, "routing": "",
        "warnings": []
    },
    "jdg.accounting.financial_lease_interest_kup": {
        "desc": "Leasing finansowy — KUP tylko odsetki",
        "basis": "Art. 23f PIT", "priority": 862, "routing": "",
        "warnings": ["Leasing finansowy — KUP tylko odsetki, kapitał przez amortyzację"]
    },
    "jdg.accounting.car_lease_limit_150k": {
        "desc": "Limit 150k PLN dla KUP z leasingu aut osobowych",
        "basis": "Art. 23a pkt 47a PIT", "priority": 864, "routing": "WARNING",
        "warnings": ["Auto >150k — KUP z rat leasingowych limitowany proporcjonalnie"]
    },
    "jdg.accounting.consumer_lease_kup": {
        "desc": "Leasing konsumencki — limit 20% KUP bez kilometrówki",
        "basis": "Art. 23 ust. 1 pkt 46 PIT", "priority": 866, "routing": "WARNING",
        "warnings": ["Leasing konsumencki — KUP limitowany do 20% bez ewidencji przebiegu"]
    },
    "jdg.accounting.lease_classification_test": {
        "desc": "Test klasyfikacji leasingu — 40% normatywnego okresu",
        "basis": "Art. 23b ust. 1 PIT", "priority": 868, "routing": "TRIAGE_QUEUE",
        "warnings": ["Umowa <40% okresu — klasyfikuj jako leasing finansowy"]
    },
    
    # === ZUS INTERACTIONS (Doc 23: P730, P732, P736) ===
    "jdg.zus.health_contribution_rate_matrix": {
        "desc": "Macierz mapowania forma→składka zdrowotna",
        "basis": "Art. 81 ustawy o świadczeniach zdrowotnych", "priority": 730, "routing": "",
        "warnings": []
    },
    "jdg.zus.form_change_contribution_trigger": {
        "desc": "Alert o przeliczeniu ZUS DRA po zmianie formy",
        "basis": "Art. 81 ust. 2 ustawy o świadczeniach zdrowotnych", "priority": 732, "routing": "WARNING",
        "warnings": ["Zmiana formy — zaktualizuj ZUS DRA od nowego roku"]
    },
    "jdg.zus.tax_card_health_fixed": {
        "desc": "Karta podatkowa — składka zdrowotna 9% min. wynagrodzenia",
        "basis": "Art. 81 ust. 2za ustawy o świadczeniach zdrowotnych", "priority": 736, "routing": "",
        "warnings": []
    },
    
    # === VAT DETAILED (Doc 23: P185-P189) ===
    "jdg.vat.pre_proportion_mixed": {
        "desc": "Pre-współczynnik VAT dla sprzedaży mieszanej",
        "basis": "Art. 90 VAT", "priority": 185, "routing": "",
        "warnings": ["Sprzedaż mieszana — VAT odliczany proporcjonalnie"]
    },
    "jdg.vat.vehicle_50_deduction": {
        "desc": "Ograniczenie odliczenia VAT do 50% dla aut mieszanych",
        "basis": "Art. 86a VAT", "priority": 186, "routing": "WARNING",
        "warnings": ["Samochód mieszany — odliczenie VAT tylko 50%"]
    },
    "jdg.vat.annual_correction_assets": {
        "desc": "Korekta roczna VAT — 1/5 (ruchomości) lub 1/10 (nieruchomości)",
        "basis": "Art. 91 VAT", "priority": 187, "routing": "",
        "warnings": []
    },
    "jdg.vat.deduction_deadline_3m": {
        "desc": "Odliczenie VAT w ciągu 3 okresów miesięcznych",
        "basis": "Art. 86 ust. 11 VAT", "priority": 188, "routing": "WARNING",
        "warnings": ["Odliczenie VAT — max 3 miesiące od otrzymania faktury"]
    },
    "jdg.vat.bad_debt_relief_creditor": {
        "desc": "Ulga na złe długi — wierzyciel po 90 dniach",
        "basis": "Art. 89a VAT", "priority": 189, "routing": "WARNING",
        "warnings": ["Ulga na złe długi — korekta in minus po 90 dniach braku płatności"]
    },
    
    # === VAT EXEMPTIONS (Doc 23: P59, P61-P63) ===
    "jdg.vat.subject_exemption_startup_proportion": {
        "desc": "Limit zwolnienia proporcjonalny dla JDG w trakcie roku",
        "basis": "Art. 113 ust. 9 VAT", "priority": 59, "routing": "",
        "warnings": ["Zwolnienie proporcjonalne — limit = (dni/365) × 200k"]
    },
    "jdg.vat.object_exemption_pkd": {
        "desc": "Zwolnienie przedmiotowe VAT wg PKD",
        "basis": "Art. 43 VAT", "priority": 61, "routing": "",
        "warnings": ["Zwolnienie przedmiotowe VAT — usługa zwolniona na podstawie PKD"]
    },
    "jdg.vat.exemption_financial": {
        "desc": "Zwolnienie VAT dla usług finansowych",
        "basis": "Art. 43 ust. 1 pkt 37-41 VAT", "priority": 62, "routing": "",
        "warnings": ["Usługa finansowa zwolniona z VAT — wyjątek: doradztwo, factoring"]
    },
    "jdg.vat.exemption_insurance": {
        "desc": "Zwolnienie VAT dla usług ubezpieczeniowych",
        "basis": "Art. 43 ust. 1 pkt 37 VAT", "priority": 63, "routing": "",
        "warnings": ["Usługa ubezpieczeniowa zwolniona z VAT"]
    },
    
    # === PIT EXEMPTIONS (Doc 23: P588) ===
    "jdg.pit.exemption_interactions_shared_limit": {
        "desc": "Zwolnienia PIT — wspólny limit 85 528 PLN",
        "basis": "Art. 21 ust. 1 pkt 148, 152, 153, 154 PIT", "priority": 588, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Zwolnienia PIT współdzielą limit 85 528 PLN — nie sumują się"]
    },
    
    # === KKS/GAAR (Doc 26: P0_b, P4, P6, P6_b, P7, P9) ===
    "jdg.risk.kks_empty_invoice_fraud": {
        "desc": "Pusta faktura — Art. 62 § 2 KKS (do 25 lat)",
        "basis": "Art. 62 § 2 KKS", "priority": 1, "routing": "BLOCK_AND_ALERT",
        "warnings": ["PUSTA FAKTURA! Ryzyko Art. 62 § 2 KKS — do 25 lat pozbawienia wolności!"]
    },
    "jdg.risk.kks_hidden_income_flag": {
        "desc": "Ukryty dochód — rozbieżność wpływów bankowych vs deklaracji",
        "basis": "Art. 54 KKS", "priority": 4, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Rozbieżność wpływów vs przychodów — ryzyko Art. 54 KKS!"]
    },
    "jdg.risk.kks_unreliable_books": {
        "desc": "Nierzetelna PKPiR — Art. 56 KKS",
        "basis": "Art. 56 KKS", "priority": 6, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Nierzetelna PKPiR — ryzyko Art. 56 KKS, grzywna do 720 stawek!"]
    },
    "jdg.risk.kks_declaration_overdue": {
        "desc": "Niezłożona deklaracja — Art. 77 KKS",
        "basis": "Art. 77 KKS", "priority": 8, "routing": "TRIAGE_QUEUE",
        "warnings": ["Deklaracja niezłożona w terminie — ryzyko Art. 77 KKS"]
    },
    "jdg.risk.kks_vat_evidence_gap": {
        "desc": "Niekompletna ewidencja VAT — Art. 57 KKS",
        "basis": "Art. 57 KKS", "priority": 7, "routing": "TRIAGE_QUEUE",
        "warnings": ["Niekompletna ewidencja VAT — ryzyko Art. 57 KKS"]
    },
    "jdg.risk.gaar_artificial_scheme": {
        "desc": "Klauzula GAAR — sztuczna transakcja bez uzasadnienia ekonomicznego",
        "basis": "Art. 119a OP", "priority": 9, "routing": "BLOCK_AND_ALERT",
        "warnings": ["GAAR! Transakcja może być uznana za sztuczną — 40% stawka sankcyjna!"]
    },
    
    # === VAT CRITICAL (Doc 26: P36, P39, P183, P184, P192, P233, P234) ===
    "jdg.vat.simplified_receipt_deduction": {
        "desc": "Paragon z NIP do 450 PLN jako faktura uproszczona",
        "basis": "Art. 106e ust. 5 pkt 3 VAT", "priority": 36, "routing": "",
        "warnings": ["Paragon z NIP — odliczenie VAT do 450 PLN brutto"]
    },
    "jdg.vat.registration_status_block": {
        "desc": "Blokada faktur VAT bez rejestracji VAT-R",
        "basis": "Art. 96 ust. 1, 4-5 VAT", "priority": 39, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Brak VAT-R — nie możesz wystawiać faktur z VAT!"]
    },
    "jdg.vat.blocked_categories_no_deduction": {
        "desc": "Blokada odliczenia VAT — hotele, restauracje (poza cateringiem)",
        "basis": "Art. 88 VAT", "priority": 183, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Wydatek z kategorii wyłączonej z odliczenia VAT — Art. 88 VAT"]
    },
    "jdg.vat.bad_debt_debtor_mandatory_correction": {
        "desc": "OBOWIĄZEK korekty VAT przez dłużnika po 90 dniach",
        "basis": "Art. 89b VAT", "priority": 184, "routing": "BLOCK_AND_ALERT",
        "warnings": ["OBOWIĄZKOWA korekta VAT! Niezapłacona faktura >90 dni — zwróć odliczony VAT!"]
    },
    "jdg.vat.refund_timing_and_interest": {
        "desc": "Terminy zwrotu VAT: 25/60/180 dni + odsetki",
        "basis": "Art. 87 ust. 2-7 VAT", "priority": 192, "routing": "WARNING",
        "warnings": ["Zwrot VAT przeterminowany — należą się odsetki"]
    },
    "jdg.vat.deregistration_vat_z": {
        "desc": "VAT-Z — obowiązek przy zaprzestaniu lub zwolnieniu",
        "basis": "Art. 96 ust. 6-8 VAT", "priority": 233, "routing": "TRIAGE_QUEUE",
        "warnings": ["Obowiązek VAT-Z — 7 dni od zaprzestania działalności"]
    },
    "jdg.vat.payment_deadline_and_interest": {
        "desc": "Termin płatności VAT do 25. + odsetki",
        "basis": "Art. 103 ust. 1 VAT", "priority": 234, "routing": "WARNING",
        "warnings": ["VAT niezapłacony do 25. — naliczono odsetki"]
    },
    
    # === PIT DETAILED (Doc 26: P508-P509, P512, P524-P526, P532-P533, P572, P574, P615) ===
    "jdg.pit.revenue_exclusions_detail": {
        "desc": "Wyłączenia z przychodu — zwrot VAT, nadpłata ZUS, odszkodowania",
        "basis": "Art. 14 ust. 3 PIT", "priority": 508, "routing": "",
        "warnings": []
    },
    "jdg.pit.income_with_inventory_calculation": {
        "desc": "Dochód = przychód - KUP + (remanent końcowy - początkowy)",
        "basis": "Art. 24 ust. 1-1b PIT", "priority": 509, "routing": "",
        "warnings": []
    },
    "jdg.pit.linear_former_employer_block": {
        "desc": "Były pracodawca — NIE można liniowego przez 3 lata",
        "basis": "Art. 30c ust. 2 pkt 1 PIT, Art. 9a ust. 3 PIT", "priority": 512, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Usługi dla byłego pracodawcy — NIE możesz rozliczać liniowo!"]
    },
    "jdg.pit.lump_sum_statutory_exclusions": {
        "desc": "Wyłączenia z ryczałtu — apteki, kantory, części samochodowe",
        "basis": "Art. 8 ust. 1-2 ustawy o ryczałcie", "priority": 524, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Branża wyłączona z ryczałtu — wymagana skala lub liniowy"]
    },
    "jdg.pit.lump_sum_loss_of_right_midyear": {
        "desc": "Utrata ryczałtu >2M EUR lub zmiana PKD",
        "basis": "Art. 20 ustawy o ryczałcie", "priority": 525, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Utrata prawa do ryczałtu — od dnia X przechodzisz na skalę"]
    },
    "jdg.pit.lump_sum_election_deadline_check": {
        "desc": "Termin oświadczenia o ryczałcie — 20. dzień po pierwszym przychodzie",
        "basis": "Art. 9 ust. 1-4 ustawy o ryczałcie", "priority": 526, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Oświadczenie o ryczałcie niezłożone w terminie!"]
    },
    "jdg.pit.tax_card_rate_table_dynamic": {
        "desc": "Stawka karty podatkowej wg rodzaju działalności i gminy",
        "basis": "Art. 23 ustawy o ryczałcie", "priority": 532, "routing": "",
        "warnings": []
    },
    "jdg.pit.tax_card_loss_events_detection": {
        "desc": "Utrata karty podatkowej — zatrudnienie, zmiana PKD, podwykonawstwo",
        "basis": "Art. 27 ustawy o ryczałcie", "priority": 533, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Utrata prawa do karty podatkowej!"]
    },
    "jdg.pit.kup_direct_vs_indirect_timing": {
        "desc": "KUP bezpośrednie (rok przychodu) vs pośrednie (data faktury)",
        "basis": "Art. 22 ust. 5-5c PIT", "priority": 572, "routing": "",
        "warnings": ["KUP bezpośredni — potrącenie w roku osiągnięcia przychodu"]
    },
    "jdg.pit.kup_detailed_exclusions_catalog": {
        "desc": "Szczegółowe NKUP — kary, straty, ubezpieczenie aut >150k",
        "basis": "Art. 23 PIT", "priority": 574, "routing": "WARNING",
        "warnings": ["Wydatek może być NKUP — sprawdź Art. 23 PIT"]
    },
    "jdg.pit.loss_carry_forward_5years_5m": {
        "desc": "Strata — max 50% rocznie przez 5 lat lub 5M PLN jednorazowo",
        "basis": "Art. 9 ust. 3 PIT", "priority": 615, "routing": "",
        "warnings": ["Strata do rozliczenia — max 50% rocznie lub 5M PLN"]
    },
    
    # === ZUS CRITICAL (Doc 26: P739, P743, P744, P745, P746, P748) ===
    "jdg.zus.concurrent_employment_exemption": {
        "desc": "Zbieg etat+JDG — tylko składka zdrowotna z JDG",
        "basis": "Art. 9 ust. 1a-2 SUS", "priority": 743, "routing": "",
        "warnings": ["Zbieg etat+JDG — z JDG płacisz tylko składkę zdrowotną"]
    },
    "jdg.zus.insurance_cessation_dates": {
        "desc": "Ustanie ubezpieczeń — zamknięcie JDG / brak chorobowej 30 dni",
        "basis": "Art. 8-9, Art. 14 SUS", "priority": 744, "routing": "WARNING",
        "warnings": ["Dobrowolne chorobowe wygasło — brak składki >30 dni"]
    },
    "jdg.zus.payment_deadline_per_entity_type": {
        "desc": "Termin ZUS: 10/15/20 dzień wg typu JDG",
        "basis": "Art. 47 SUS", "priority": 745, "routing": "WARNING",
        "warnings": ["Składki ZUS po terminie!"]
    },
    "jdg.zus.dra_filing_deadline_check": {
        "desc": "Deklaracja DRA — do 15. (z pracownikami) lub 20.",
        "basis": "Art. 16-17 SUS", "priority": 746, "routing": "WARNING",
        "warnings": ["ZUS DRA niezłożona w terminie!"]
    },
    "jdg.zus.health_payment_deadline_check": {
        "desc": "Składka zdrowotna — ten sam termin co społeczne",
        "basis": "Art. 82 ustawy o świadczeniach zdrowotnych", "priority": 748, "routing": "WARNING",
        "warnings": ["Składka zdrowotna po terminie!"]
    },
    "jdg.zus.health_insurance_obligation": {
        "desc": "Obowiązek ubezpieczenia zdrowotnego — każda aktywna JDG",
        "basis": "Art. 66 ust. 1 pkt 1c ustawy o świadczeniach zdrowotnych", "priority": 739, "routing": "",
        "warnings": []
    },
    
    # === FX DIFFERENCES (Doc 26: P870) ===
    "jdg.accounting.fx_differences_recognition": {
        "desc": "Różnice kursowe — dodatnie=przychód, ujemne=KUP",
        "basis": "Art. 14 ust. 2c, Art. 24c PIT", "priority": 870, "routing": "",
        "warnings": []
    },
    
    # === SUSPENSION/SUCCESSION (Doc 26: P916, P918, P925-P927) ===
    "jdg.business.resumption_procedure_valid": {
        "desc": "Wznowienie JDG — zgłoszenie CEIDG + obowiązki",
        "basis": "Art. 22-25 Prawa przedsiębiorców", "priority": 916, "routing": "TRIAGE_QUEUE",
        "warnings": ["Wznowienie bez zgłoszenia CEIDG — zgłoś natychmiast"]
    },
    "jdg.business.maximum_suspension_period_check": {
        "desc": "Maks. 6 mies. ciągłego zawieszenia",
        "basis": "Art. 22 Prawa przedsiębiorców", "priority": 918, "routing": "WARNING",
        "warnings": ["Zawieszenie >6 mies. — rozważ wznowienie lub zamknięcie"]
    },
    "jdg.business.succession_manager_appointment": {
        "desc": "Powołanie zarządcy sukcesyjnego — za życia lub 2 mies. po śmierci",
        "basis": "Art. 3-7 ustawy o zarządzie sukcesyjnym", "priority": 925, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Zarządca powołany niezgodnie z procedurą — zarząd nieskuteczny"]
    },
    "jdg.business.succession_time_limit_expiry": {
        "desc": "Zarząd sukcesyjny — max 2 lata (5 lat z przedłużeniem)",
        "basis": "Art. 12-13 ustawy o zarządzie sukcesyjnym", "priority": 926, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Zarząd sukcesyjny wygasł — NIP nieaktywny"]
    },
    "jdg.business.succession_termination_events": {
        "desc": "Wygaśnięcie zarządu — śmierć, rezygnacja, upadłość",
        "basis": "Art. 14-15 ustawy o zarządzie sukcesyjnym", "priority": 927, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Zarząd sukcesyjny wygasł"]
    },
    
    # === JPK (Doc 26: P972) ===
    "jdg.jpk.filing_deadlines_detailed": {
        "desc": "JPK_V7 — miesięczny do 25., kwartalny do 25. po kwartale",
        "basis": "Art. 99 ust. 1-3 VAT", "priority": 972, "routing": "WARNING",
        "warnings": ["JPK_V7 niezłożony w terminie — ryzyko Art. 77 KKS"]
    },
    
    # === STATUTE/LIABILITY (Doc 26: P1153, P1157, P1167-P1174) ===
    "jdg.statute.zus_suspension_during_proceedings": {
        "desc": "Zawieszenie przedawnienia ZUS — egzekucja/KKS",
        "basis": "Art. 24 ust. 5b-5d SUS", "priority": 1153, "routing": "",
        "warnings": ["Bieg przedawnienia ZUS zawieszony"]
    },
    "jdg.statute.interruption_detailed_events": {
        "desc": "Przerwanie przedawnienia — uznanie długu, KKS, upadłość",
        "basis": "Art. 71 OP", "priority": 1157, "routing": "",
        "warnings": ["Bieg przedawnienia przerwany — nowy 5-letni termin"]
    },
    "jdg.statute.tax_arrears_detection": {
        "desc": "Wykrycie zaległości podatkowej — VAT/PIT/ZUS",
        "basis": "Art. 20-21 OP", "priority": 1167, "routing": "TRIAGE_QUEUE",
        "warnings": ["Zaległość podatkowa — kwota X, dni Y"]
    },
    "jdg.statute.voluntary_disclosure_protection": {
        "desc": "Czynny żal PRZED korektą — ochrona przed KKS",
        "basis": "Art. 16 § 1-4 KKS, Art. 16a KKS", "priority": 1168, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Brak czynnego żalu przed korektą! Ryzyko KKS!"]
    },
    "jdg.statute.overpayment_detection_and_refund": {
        "desc": "Nadpłata podatku — zwrot 45 dni (VAT) / 3 mies. (PIT)",
        "basis": "Art. 72-80 OP", "priority": 1169, "routing": "",
        "warnings": ["Nadpłata — złóż wniosek o zwrot"]
    },
    "jdg.statute.deferral_active_interest_suspended": {
        "desc": "Odroczenie/raty — odsetki zawieszone, opłata prolongacyjna",
        "basis": "Art. 48, Art. 67a-67e OP", "priority": 1170, "routing": "",
        "warnings": ["Odroczenie aktywne — przestrzegaj terminów rat"]
    },
    "jdg.statute.tax_remission_liability_extinguished": {
        "desc": "Umorzenie zaległości — zobowiązanie wygasa",
        "basis": "Art. 51 OP", "priority": 1171, "routing": "",
        "warnings": ["Zaległość umorzona — zobowiązanie wygasło"]
    },
    "jdg.statute.overpayment_offset_auto": {
        "desc": "Zaliczenie nadpłaty na przyszłe zobowiązania",
        "basis": "Art. 72-80, Art. 87 OP", "priority": 1172, "routing": "",
        "warnings": []
    },
    "jdg.statute.tax_proceedings_deadlines_alert": {
        "desc": "Terminy proceduralne — 7/14/30/60 dni",
        "basis": "Art. 120-129 OP", "priority": 1174, "routing": "WARNING",
        "warnings": ["Termin procesowy — zostało X dni"]
    },
    
    # === LOCAL TAXES (Doc 26: P1300, P1302, P1304, P1310, P1312, P1320) ===
    "jdg.local_taxes.pcc_purchase_from_private": {
        "desc": "PCC 2% od zakupu od osoby prywatnej >1000 PLN",
        "basis": "Ustawa o PCC, Art. 1-2, Art. 7", "priority": 1300, "routing": "WARNING",
        "warnings": ["Zakup od osoby prywatnej — PCC-3 w 14 dni, stawka 2%"]
    },
    "jdg.local_taxes.pcc_loan_from_private": {
        "desc": "PCC 0.5% od pożyczki od osoby prywatnej",
        "basis": "Ustawa o PCC, Art. 7 ust. 1 pkt 4", "priority": 1302, "routing": "WARNING",
        "warnings": ["Pożyczka od osoby prywatnej — PCC-3 w 14 dni, 0.5%"]
    },
    "jdg.local_taxes.pcc_company_exempt_info": {
        "desc": "JDG nie podlega PCC od wkładów kapitałowych",
        "basis": "Ustawa o PCC", "priority": 1304, "routing": "",
        "warnings": []
    },
    "jdg.local_taxes.real_estate_commercial_rate": {
        "desc": "Podatek od nieruchomości — wyższa stawka dla powierzchni firmowej",
        "basis": "Ustawa o podatkach i opłatach lokalnych, Art. 2-7", "priority": 1310, "routing": "WARNING",
        "warnings": ["Home office — wyższa stawka podatku od nieruchomości. Złóż DN-1"]
    },
    "jdg.local_taxes.real_estate_dn1_filing": {
        "desc": "DN-1 — deklaracja na podatek od nieruchomości, 14 dni",
        "basis": "Ustawa o podatkach i opłatach lokalnych", "priority": 1312, "routing": "TRIAGE_QUEUE",
        "warnings": ["DN-1 niezłożona w terminie 14 dni!"]
    },
    "jdg.local_taxes.transport_tax_applicable": {
        "desc": "Podatek od środków transportowych — pojazdy >3.5t",
        "basis": "Ustawa o podatkach i opłatach lokalnych, Rozdział 3", "priority": 1320, "routing": "WARNING",
        "warnings": ["Pojazd >3.5t — obowiązek podatku od środków transportowych"]
    },
    
    # === REPRESENTATION (Doc 26: P1205) ===
    "jdg.representation.prokura_types_detailed": {
        "desc": "Typy prokury — samoistna, łączna, oddziałowa",
        "basis": "Art. 109¹-109⁸ KC", "priority": 1205, "routing": "BLOCK_AND_ALERT",
        "warnings": ["Prokura niewpisana w CEIDG — nieskuteczna!"]
    },
}
# ═══════════════════════════════════════════════════════════════════════════════
# REGO FILE GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

def generate_verdict(rule_id, package, priority, routing, desc, basis, warnings, is_first=False):
    """Generate a Rego verdict object."""
    kw = "decide" if is_first else "else"
    
    verdict = f'  {{"matched":true,'
    verdict += f'"rule_id":"{rule_id}",'
    verdict += f'"package":"{package}",'
    verdict += f'"priority":{priority},'
    verdict += f'"vat_rate":"",'
    verdict += f'"rounding_level":"",'
    verdict += f'"gtu_code":"",'
    verdict += f'"pit_form":"",'
    verdict += f'"pit_rate":"",'
    verdict += f'"pit_bracket":"",'
    verdict += f'"pit_annual_return_type":"",'
    verdict += f'"kus_qualification":"",'
    verdict += f'"kus_percent":0,'
    verdict += f'"zus_social_base_type":"",'
    verdict += f'"zus_health_rate":"",'
    verdict += f'"business_status":"",'
    verdict += f'"_routing":"{routing}",'
    verdict += f'"_routing_reason":"{desc[:150]}",'
    verdict += f'"_legal_basis":"{basis[:150]}"'
    
    if warnings:
        w = '", "'.join(w[:100] for w in warnings[:3])
        verdict += f',"_warnings":["{w}"]'
    else:
        verdict += ',"_warnings":[]'
    
    verdict += '}'
    return kw, verdict

def generate_rego_file(package_name, file_path, rules_spec, existing_ids):
    """Generate a complete .rego file from a rules specification."""
    
    # Filter out existing rules
    new_rules = []
    for rule_id, spec in rules_spec.items():
        if rule_id not in existing_ids:
            new_rules.append((rule_id, spec))
    
    if not new_rules:
        return 0
    
    # Sort by priority
    new_rules.sort(key=lambda x: x[1].get("priority", 9999))
    
    # Determine base package
    base_pkg = package_name
    
    # Build content
    lines = []
    lines.append(f'# ═══════════════════════════════════════════════════════════════════════════════')
    lines.append(f'# NexusAI JDG Policies — {base_pkg}')
    lines.append(f'# Generated from Plan OPA specifications: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
    lines.append(f'# Rules: {len(new_rules)}')
    lines.append(f'# ═══════════════════════════════════════════════════════════════════════════════')
    lines.append(f'package {base_pkg}')
    
    # Add helpers import if applicable
    if base_pkg.startswith("jdg."):
        lines.append('import data.jdg.helpers')
    
    lines.append('')
    lines.append(f'default decide := {{"matched":false,"rule_id":"{base_pkg}.no_match","package":"{base_pkg}","priority":99999}}')
    lines.append('')
    
    # Generate rules
    for i, (rule_id, spec) in enumerate(new_rules):
        is_first = (i == 0)
        desc = spec.get("desc", "")
        basis = spec.get("basis", "")
        priority = spec.get("priority", 50000 + i)
        routing = spec.get("routing", "")
        warnings = spec.get("warnings", [])
        
        kw, verdict = generate_verdict(rule_id, base_pkg, priority, routing, desc, basis, warnings, is_first)
        
        lines.append(f'# {rule_id} — {desc[:120]}')
        lines.append(f'{kw} := {verdict} {{')
        lines.append(f'    true')
        lines.append(f'}}')
        lines.append('')
    
    content = '\n'.join(lines)
    
    # Create directory if needed
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    if not DRY_RUN:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
    
    return len(new_rules)


# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def main():
    print("=" * 70)
    print("NexusAI JDG — Massive Rule Generator from Plan OPA")
    print("=" * 70)
    
    # Collect existing rule_ids
    print("\n[1] Collecting existing rule_ids...")
    existing_ids = set()
    for root, dirs, files in os.walk(BASE):
        for f in files:
            if f.endswith(".rego"):
                try:
                    with open(os.path.join(root, f)) as fh:
                        ids = re.findall(r'"rule_id"\s*:\s*"([^"]+)"', fh.read())
                        existing_ids.update(ids)
                except:
                    pass
    print(f"    Existing unique rule_ids: {len(existing_ids)}")
    
    # Define output files and their rule sets
    outputs = [
        # From Plan OPA 42: PKPiR, VAT rates, KKS detailed, ZUS benefits, KŚT, RODO, MPiPS, UoR, PCC
        ("jdg.accounting", f"{BASE}/accounting/plan42_pkpir.rego", 
         {k:v for k,v in DEEP_GAP_RULES.items() if k.startswith("jdg.accounting.")}),
        ("jdg.vat.reduced_rates", f"{BASE}/vat/plan42_reduced_rates.rego",
         {k:v for k,v in DEEP_GAP_RULES.items() if k.startswith("jdg.vat.")}),
        ("jdg.kks", f"{BASE}/kks/plan42_detailed.rego",
         {k:v for k,v in DEEP_GAP_RULES.items() if k.startswith("jdg.kks.")}),
        ("jdg.zus", f"{BASE}/zus/plan42_benefits.rego",
         {k:v for k,v in DEEP_GAP_RULES.items() if k.startswith("jdg.zus.")}),
        ("jdg.rodo", f"{BASE}/rodo/plan42_rodo.rego",
         {k:v for k,v in DEEP_GAP_RULES.items() if k.startswith("jdg.rodo.")}),
        ("jdg.uor", f"{BASE}/uor/plan42_uor.rego",
         {k:v for k,v in DEEP_GAP_RULES.items() if k.startswith("jdg.uor.")}),
        ("jdg.pcc", f"{BASE}/pcc/plan42_pcc.rego",
         {k:v for k,v in DEEP_GAP_RULES.items() if k.startswith("jdg.pcc.")}),
        
        # From Plan OPA 44: MDR, solidarity, WIS, audit, force majeure, family, edelivery, procurement, FX, TP, residency, payments, advertising
        ("jdg.mdr", f"{BASE}/mdr/plan44_mdr.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.mdr.")}),
        ("jdg.solidarity", f"{BASE}/solidarity/plan44_solidarity.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.solidarity.")}),
        ("jdg.wis", f"{BASE}/wis/plan44_wis.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.wis.")}),
        ("jdg.audit", f"{BASE}/audit/plan44_audit.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.audit.")}),
        ("jdg.force_majeure", f"{BASE}/force_majeure/plan44_force_majeure.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.force_majeure.")}),
        ("jdg.family", f"{BASE}/family/plan44_family.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.family.")}),
        ("jdg.edelivery", f"{BASE}/edelivery/plan44_edelivery.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.edelivery.")}),
        ("jdg.procurement", f"{BASE}/procurement/plan44_procurement.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.procurement.")}),
        ("jdg.fx", f"{BASE}/fx/plan44_fx.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.fx.")}),
        ("jdg.tp", f"{BASE}/tp/plan44_tp.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.tp.")}),
        ("jdg.residency", f"{BASE}/residency/plan44_residency.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.residency.")}),
        ("jdg.payments", f"{BASE}/payments/plan44_payments.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.payments.")}),
        ("jdg.advertising", f"{BASE}/advertising/plan44_advertising.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.advertising.")}),
        ("jdg.kks", f"{BASE}/kks/plan44_kks_conviction.rego",
         {k:v for k,v in ADVANCED_GAP_RULES.items() if k.startswith("jdg.kks.")}),
        
        # From Plan OPA 43: KKS Massive Decomposition
        # From Plan OPA 23: Crossborder, Allowances, Tax Form Change, Leasing, ZUS Interactions, VAT Detailed, VAT Exemptions, PIT Exemptions
        ("jdg.crossborder", f"{BASE}/crossborder/plan23_ue.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.crossborder.")}),
        ("jdg.allowances", f"{BASE}/allowances/plan23_reliefs.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.allowances.")}),
        ("jdg.pit.tax_form_change", f"{BASE}/pit/plan23_tax_form_change.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.pit.tax_form_change.")}),
        ("jdg.accounting", f"{BASE}/accounting/plan23_leasing.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.accounting.")}),
        ("jdg.zus", f"{BASE}/zus/plan23_interactions.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.zus.")}),
        ("jdg.vat", f"{BASE}/vat/plan23_detailed.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.vat.")}),
        ("jdg.pit", f"{BASE}/pit/plan23_exemptions.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.pit.exemption")}),
        
        # From Plan OPA 26: KKS/GAAR, VAT Critical, PIT Detailed, ZUS Critical, FX, Business, JPK, Statute, Local Taxes, Representation
        ("jdg.risk", f"{BASE}/risk/plan26_kks_gaar.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.risk.")}),
        ("jdg.vat", f"{BASE}/vat/plan26_critical.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.vat.") and "plan23" not in k}),
        ("jdg.pit", f"{BASE}/pit/plan26_detailed.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.pit.") and "tax_form_change" not in k and "exemption" not in k}),
        ("jdg.business", f"{BASE}/business/plan26_suspension_succession.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.business.")}),
        ("jdg.jpk", f"{BASE}/jpk/plan26_deadlines.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.jpk.")}),
        ("jdg.statute", f"{BASE}/statute/plan26_detailed.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.statute.")}),
        ("jdg.local_taxes", f"{BASE}/local_taxes/plan26_local.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.local_taxes.")}),
        ("jdg.representation", f"{BASE}/representation/plan26_prokura.rego",
         {k:v for k,v in PLAN23_26_RULES.items() if k.startswith("jdg.representation.")}),
        
        # From Plan OPA 43: KKS Massive Decomposition
        ("jdg.kks", f"{BASE}/kks/plan43_decomposition.rego",
         KKS_DECOMPOSITION_RULES),
    ]
    
    # Generate each output file
    print("\n[2] Generating Rego rules...")
    total = 0
    files_created = 0
    
    for pkg, path, rules in outputs:
        if not rules:
            continue
        count = generate_rego_file(pkg, path, rules, existing_ids)
        if count > 0:
            if DRY_RUN:
                print(f"    [DRY RUN] {path}: {count} rules")
            else:
                print(f"    ✅ {path}: {count} rules")
            total += count
            files_created += 1
        else:
            print(f"    ⏭️  {path}: all rules already exist — skipped")
    
    print(f"\n{'=' * 70}")
    print(f"SUMMARY")
    print(f"  Total rules generated: {total}")
    print(f"  Files created: {files_created}")
    print(f"  Existing rules (not duplicated): {len(existing_ids)}")
    
    if DRY_RUN:
        print(f"\n  ⚠️ DRY RUN — use without --dry-run to generate files.")
    
    print(f"{'=' * 70}")


if __name__ == "__main__":
    main()
