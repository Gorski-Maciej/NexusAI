#!/usr/bin/env python3
"""
NexusAI JDG — Fix Hyper Tier Legal Basis
Replaces empty "" and R-XXXX placeholders with real legal basis articles
in all JDG/rules/jdg/hyper/*/plan45.rego files.
"""
import re, os, sys

DRY_RUN = "--dry-run" in sys.argv
BASE = "JDG/rules/jdg/hyper"

# ═══════════════════════════════════════════════════════════════════════════════
# MAPPING: rule_id_pattern → (legal_basis, warnings)
# Based on Polish tax law 2026
# ═══════════════════════════════════════════════════════════════════════════════

BASIS_MAP = {
    # ── SOLIDARITY LEVY (danina solidarnościowa) ──
    "solidarity.levy.base": ("Art. 30h ust. 2 PIT", ["Podstawa daniny = suma dochodów - 1 000 000 PLN"]),
    "solidarity.levy.rate": ("Art. 30h ust. 1 PIT", ["Stawka daniny solidarnościowej = 4% od nadwyżki ponad 1M PLN"]),
    "solidarity.levy.minimum": ("Art. 30h ust. 2 PIT", ["Danina nie może być ujemna — minimum 0 PLN"]),
    "solidarity.levy.income.scale": ("Art. 30h ust. 2 PIT", ["Dochód opodatkowany skalą (12%/32%) wlicza się do podstawy daniny"]),
    "solidarity.levy.income.linear": ("Art. 30h ust. 2 PIT", ["Dochód opodatkowany liniowo 19% wlicza się do podstawy daniny"]),
    "solidarity.levy.income.lump_sum": ("Art. 30h ust. 2 PIT", ["Przychód z ryczałtu wlicza się do podstawy daniny (po odliczeniu składek)"]),
    "solidarity.levy.income.capital_gains": ("Art. 30h ust. 2 PIT", ["Dochody kapitałowe (19%) wlicza się do podstawy daniny"]),
    "solidarity.levy.income.ip_box": ("Art. 30h ust. 2 PIT, Art. 30ca PIT", ["Dochód z IP Box (5%) wlicza się do podstawy daniny"]),
    "solidarity.levy.income.foreign": ("Art. 30h ust. 2 PIT, Art. 27 ust. 8 PIT", ["Dochody zagraniczne wlicza się do podstawy daniny"]),
    "solidarity.levy.zus.social": ("Art. 30h ust. 2 PIT", ["Składki ZUS społeczne pomniejszają dochód dla celów daniny"]),
    "solidarity.levy.exemption": ("Art. 30h ust. 3 PIT", ["Dochody zwolnione metodą wyłączenia z progresją nie wlicza się"]),
    "solidarity.levy.spouse": ("Art. 30h ust. 5 PIT", ["Każdy małżonek oblicza daninę osobno"]),
    "solidarity.levy.payment.deadline": ("Art. 30h ust. 6 PIT", ["Zapłata daniny do 30 kwietnia następnego roku"]),
    "solidarity.levy.payment.method": ("Art. 30h ust. 6 PIT, Art. 61b OP", ["Obowiązek przelewu na mikrorachunek podatkowy"]),
    "solidarity.levy.sanction.late_payment": ("Art. 56 OP", ["Odsetki za zwłokę od niezapłaconej daniny solidarnościowej"]),
    "solidarity.levy.sanction.underpayment": ("Art. 54 KKS, Art. 56 KKS", ["Sankcja KKS przy celowym zaniżeniu podstawy daniny"]),
    "solidarity.levy.interaction.pit_free": ("Art. 30h ust. 2 PIT", ["Kwota wolna 30k nie wpływa na obliczenie daniny"]),
    "solidarity.levy.interaction.tax_scale": ("Art. 30h ust. 4 PIT", ["Danina nie wpływa na próg podatkowy 120k w skali"]),
    "solidarity.levy.edge.first_year": ("Art. 30h ust. 2 PIT", ["Pierwszy rok z dochodem >1M — pełna danina od nadwyżki"]),
    "solidarity.levy.edge.loss": ("Art. 30h ust. 2 PIT, Art. 9 ust. 3 PIT", ["Strata z JDG pomniejsza dochód łączny dla celów daniny"]),
    "solidarity.levy.edge.one_time": ("Art. 30h ust. 2 PIT", ["Jednorazowy dochód (np. sprzedaż nieruchomości firmowej) wlicza się"]),
    "solidarity.levy.aggregate": ("Art. 30h PIT", ["Prognoza daniny na podstawie dochodów narastających"]),
    "solidarity.levy.aggregate.alert": ("Art. 30h ust. 2 PIT", ["Alert: dochód przekroczył 900k PLN — zbliżanie do progu 1M"]),

    # ── WIS (Wiążąca Informacja Stawkowa) ──
    "wis.eligibility.cn_code": ("Art. 42b ust. 1 VAT", ["Kod CN niejednoznaczny — zalecenie uzyskania WIS"]),
    "wis.eligibility.composite": ("Art. 42b ust. 1 VAT", ["Produkt złożony — niejednoznaczna klasyfikacja → WIS"]),
    "wis.eligibility.new_product": ("Art. 42b ust. 1 VAT", ["Nowy produkt na rynku bez utrwalonej klasyfikacji → WIS"]),
    "wis.eligibility.import_first": ("Art. 42b ust. 1 VAT", ["Pierwszy import towaru spoza UE → zalecenie WIS"]),
    "wis.eligibility.contradictory": ("Art. 42b ust. 1 VAT", ["Sprzeczne interpretacje KIS → zalecenie WIS"]),
    "wis.eligibility.food": ("Art. 42b ust. 1 VAT", ["Suplementy diety na granicy żywność/farmaceutyk → WIS"]),
    "wis.eligibility.software": ("Art. 42b ust. 1 VAT", ["Oprogramowanie vs usługa — niejednoznaczność → WIS"]),
    "wis.eligibility.annual": ("Art. 42b ust. 1 VAT", ["Roczny obrót towarem >50k PLN → próg istotności dla WIS"]),
    "wis.application.cost": ("Art. 42g ust. 1 VAT", ["Opłata za wniosek WIS = 40 PLN za każdy towar/usługę"]),
    "wis.application.form": ("Art. 42g ust. 2 VAT", ["Wniosek WIS-W tylko elektronicznie przez e-US"]),
    "wis.application.required": ("Art. 42g ust. 1-3 VAT", ["Opis towaru, kod CN, proponowana stawka, uzasadnienie"]),
    "wis.application.sample": ("Art. 42g ust. 4 VAT", ["Dyrektor KIS może zażądać próbki towaru"]),
    "wis.validity.5_years": ("Art. 42h ust. 1 VAT", ["WIS ważna 5 lat od daty wydania"]),
    "wis.validity.early_expiry.regulation": ("Art. 42h ust. 2 pkt 1 VAT", ["Zmiana przepisów → WIS traci moc z dniem zmiany"]),
    "wis.validity.early_expiry.cjeu": ("Art. 42h ust. 2 pkt 2 VAT", ["Wyrok TSUE zmieniający klasyfikację → WIS traci moc"]),
    "wis.binding_effect.not_against": ("Art. 42h ust. 1 VAT", ["WIS nie chroni przed zmianą przepisów ustawowych"]),
    "wis.binding_effect.covers": ("Art. 42h ust. 1 VAT", ["WIS obejmuje transakcje od dnia wydania"]),
    "wis.binding_effect.dyrektor": ("Art. 42h ust. 1 VAT", ["WIS wiąże Dyrektora KIS i organy podatkowe"]),
    "wis.gtu.mapping": ("Art. 42h ust. 1 VAT, Rozp. JPK_VAT", ["WIS determinuje kod GTU w JPK_V7"]),
    "wis.sanction.incorrect": ("Art. 64 KKS, Art. 42b VAT", ["Bez WIS przy niejednoznacznym CN → ryzyko KKS Art. 64"]),
    "wis.interaction.tax_audit": ("Art. 42h ust. 1 VAT", ["Posiadanie WIS = ochrona przed zakwestionowaniem stawki"]),
    "wis.interaction.individual": ("Art. 42h ust. 1 VAT", ["WIS ma pierwszeństwo przed interpretacją indywidualną w zakresie CN"]),
    "wis.monitoring.expiry": ("Art. 42h ust. 1 VAT", ["Monitoruj termin wygaśnięcia WIS — złóż wniosek o nową"]),

    # ── MDR (DAC6) ──
    "mdr.hallmark.a4": ("Art. 86a § 1 pkt 4 OP", ["MDR A4 — nabycie spółki ze stratą dla korzyści podatkowej"]),
    "mdr.hallmark.a5": ("Art. 86a § 1 pkt 5 OP", ["MDR A5 — konwersja dochodu do kategorii niżej opodatkowanej"]),
    "mdr.hallmark.a6": ("Art. 86a § 1 pkt 6 OP", ["MDR A6 — transakcje okrężne bez treści ekonomicznej"]),
    "mdr.hallmark.a7": ("Art. 86a § 1 pkt 7 OP", ["MDR A7 — ten sam koszt odliczany w dwóch jurysdykcjach"]),
    "mdr.hallmark.a8": ("Art. 86a § 1 pkt 8 OP", ["MDR A8 — ten sam składnik amortyzowany w dwóch krajach"]),
    "mdr.hallmark.a9": ("Art. 86a § 1 pkt 9 OP", ["MDR A9 — podwójne zwolnienie podatkowe dla tego samego dochodu"]),
    "mdr.hallmark.a10": ("Art. 86a § 1 pkt 10 OP", ["MDR A10 — Test głównej korzyści (Main Benefit Test)"]),
    "mdr.hallmark.b1": ("Art. 86a § 1 pkt 11 OP", ["MDR B1 — wykorzystanie straty w grupie"]),
    "mdr.hallmark.b2": ("Art. 86a § 1 pkt 12 OP", ["MDR B2 — konwersja dochodu bieżącego w kapitałowy"]),
    "mdr.hallmark.b3": ("Art. 86a § 1 pkt 13 OP", ["MDR B3 — transgraniczne przesunięcie odliczenia"]),
    "mdr.hallmark.b4": ("Art. 86a § 1 pkt 14 OP", ["MDR B4 — transfer aktywów do/z raju podatkowego"]),
    "mdr.hallmark.b5": ("Art. 86a § 1 pkt 15 OP", ["MDR B5 — płatności nierynkowe"]),
    "mdr.hallmark.b6": ("Art. 86a § 1 pkt 16 OP", ["MDR B6 — odliczenie tej samej płatności w dwóch krajach"]),
    "mdr.hallmark.b7": ("Art. 86a § 1 pkt 17 OP", ["MDR B7 — roszczenie o nieopodatkowanie w żadnej jurysdykcji"]),
    "mdr.hallmark.b8": ("Art. 86a § 1 pkt 18 OP", ["MDR B8 — rozbieżność kwalifikacji prawnej (hybryda)"]),
    "mdr.hallmark.c1": ("Art. 86a § 1 pkt 19 OP", ["MDR C1 — nabycie podmiotu ze stratą >50% wartości"]),
    "mdr.hallmark.c2": ("Art. 86a § 1 pkt 20 OP", ["MDR C2 — zmiana klasyfikacji dochodu dla niższego WHT"]),
    "mdr.hallmark.c3": ("Art. 86a § 1 pkt 21 OP", ["MDR C3 — transakcja okrężna z podmiotem pośredniczącym"]),
    "mdr.hallmark.c4": ("Art. 86a § 1 pkt 22 OP", ["MDR C4 — transgraniczne odliczenie z podmiotem powiązanym"]),
    "mdr.hallmark.c5": ("Art. 86a § 1 pkt 23 OP", ["MDR C5 — wykorzystanie różnic w metodologii TP"]),
    "mdr.hallmark.c6": ("Art. 86a § 1 pkt 24 OP", ["MDR C6 — transfer trudnych do wyceny wartości niematerialnych"]),
    "mdr.hallmark.c7": ("Art. 86a § 1 pkt 25 OP", ["MDR C7 — restrukturyzacja biznesu transgranicznie"]),
    "mdr.hallmark.c8": ("Art. 86a § 1 pkt 26 OP", ["MDR C8 — sztuczne spełnienie warunków safe harbour"]),
    "mdr.hallmark.d1": ("Art. 86a § 1 pkt 27 OP", ["MDR D1 — transgraniczny transfer IP bez wynagrodzenia"]),
    "mdr.hallmark.d2": ("Art. 86a § 1 pkt 28 OP", ["MDR D2 — transfer funkcji/ryzyk/aktywów >50% EBIT"]),
    "mdr.hallmark.e1": ("Art. 86a § 1 pkt 29 OP", ["MDR E1 — obchodzenie automatycznej wymiany informacji"]),
    "mdr.hallmark.e2": ("Art. 86a § 1 pkt 30 OP", ["MDR E2 — ukrywanie rzeczywistego beneficjenta"]),
    "mdr.hallmark.e3": ("Art. 86a § 1 pkt 31 OP", ["MDR E3 — wykorzystanie trustów/fundacji w jurysdykcjach nieprzejrzystych"]),
    "mdr.hallmark.e4": ("Art. 86a § 1 pkt 32 OP", ["MDR E4 — wykorzystanie podstawionych dyrektorów"]),
    "mdr.obligation.user": ("Art. 86b OP", ["Korzystający → MDR-3 w 30 dni od pierwszej czynności"]),
    "mdr.obligation.legal": ("Art. 86c OP", ["Adwokat/radca → zwolnienie; obowiązek przeniesiony na korzystającego"]),
    "mdr.obligation.quarterly": ("Art. 86f OP", ["MDR-4 — kwartalne zestawienie schematów"]),
    "mdr.deadline.30_days_from_scheme": ("Art. 86b § 1 OP", ["30 dni od udostępnienia schematu"]),
    "mdr.deadline.30_days_from_first": ("Art. 86b § 2 OP", ["30 dni od pierwszej czynności wykonawczej"]),
    "mdr.sanction.administrative": ("Art. 86o OP", ["Kara administracyjna do 5 000 000 PLN za brak MDR"]),
    "mdr.sanction.kks": ("Art. 54-56 KKS", ["Odpowiedzialność KKS za niezgłoszenie schematu MDR"]),
    "mdr.retention": ("Art. 86m OP", ["Przechowywanie dokumentacji MDR przez 6 lat"]),
    "mdr.aggregate": ("Art. 86a-86o OP", ["Skumulowany wskaźnik ryzyka MDR — wszystkie hallmarki"]),

    # ── AUDIT / KONTROLA ──
    "audit.trigger.return": ("Art. 274 OP", ["Wezwanie do korekty deklaracji"]),
    "audit.trigger.inspection": ("Art. 282 OP", ["Kontrola na podstawie imiennego upoważnienia"]),
    "audit.trigger.external": ("Art. 282 OP", ["Informacja od innego organu → wszczęcie kontroli"]),
    "audit.trigger.cross_checking": ("Art. 272-274 OP", ["Weryfikacja krzyżowa deklaracji → czynności sprawdzające"]),
    "audit.right.notification_7": ("Art. 282b OP", ["Zawiadomienie o kontroli min. 7 dni przed"]),
    "audit.right.no_notification": ("Art. 282b § 2 OP", ["Wyjątki od 7-dniowego zawiadomienia: przestępstwo, KAS"]),
    "audit.right.presence": ("Art. 285 OP", ["Prawo do obecności przy wszystkich czynnościach kontrolnych"]),
    "audit.right.exclusion": ("Art. 130 OP", ["Wniosek o wyłączenie kontrolera"]),
    "audit.right.refuse": ("Art. 199 OP", ["Odmowa odpowiedzi grożącej odpowiedzialnością KKS"]),
    "audit.right.object_to": ("Art. 291 OP", ["Zastrzeżenia do protokołu w ciągu 14 dni"]),
    "audit.right.break": ("Art. 286 OP", ["Przerwa w kontroli — max 3 dni robocze"]),
    "audit.right.correction_in": ("Art. 81b OP", ["Korekta na korzyść blokowana podczas kontroli"]),
    "audit.right.right_to": ("Art. 200 OP", ["Prawo do wypowiedzenia przed decyzją"]),
    "audit.document.electronic": ("Art. 193a OP", ["Dowody elektroniczne: autentyczność + integralność"]),
    "audit.document.foreign": ("Art. 180a OP", ["Dokumenty obcojęzyczne → tłumaczenie przysięgłe na żądanie"]),
    "audit.protocol.deadline_14": ("Art. 291 OP", ["Protokół sporządzany w ciągu 14 dni od zakończenia kontroli"]),
    "audit.protocol.required": ("Art. 291 § 3 OP", ["Data, oznaczenie organu, podstawa, ustalenia, pouczenie"]),
    "audit.protocol.objections_period": ("Art. 291 § 1 OP", ["14 dni na zastrzeżenia od podpisania protokołu"]),
    "audit.protocol.objections_to": ("Art. 291 § 2 OP", ["Zastrzeżenia rozpatruje bezpośredni przełożony kontrolera"]),
    "audit.protocol.electronic": ("Art. 144b OP", ["Protokół doręczany przez e-US z UPO"]),
    "audit.representation.poa_pps1": ("Art. 138a-138o OP", ["Pełnomocnik ogólny PPS-1 może reprezentować podczas kontroli"]),
    "audit.representation.poa_upl1": ("Art. 138a-138o OP", ["Pełnomocnik szczególny UPL-1 tylko do wskazanej sprawy"]),
    "audit.representation.access": ("Art. 178 OP", ["Prawo wglądu w akta sprawy"]),
    "audit.representation.participation": ("Art. 138e OP", ["Udział we wszystkich czynnościach kontrolnych"]),
    "audit.type.verification": ("Art. 272-280 OP", ["Czynności sprawdzające — max 7 dni"]),
    "audit.type.tax_audit": ("Art. 281-292 OP", ["Kontrola podatkowa — max 30 dni"]),
    "audit.type.tax_proceeding": ("Art. 120-129 OP", ["Postępowanie podatkowe — bez limitu"]),
    "audit.type.customs": ("Art. 54-93 KAS", ["Kontrola celno-skarbowa — max 3 mies."]),
    "audit.cross_border.mutual": ("Art. 86-87 OP, DAC", ["Współpraca z organami innych krajów UE"]),
    "audit.cross_border.simultaneous": ("Art. 86-87 OP", ["Kontrola jednoczesna w kilku krajach UE"]),
    "audit.cross_border.presence": ("Art. 87 OP", ["Udział zagranicznych kontrolerów w kontroli w PL"]),
    "audit.closure.decision_issuance": ("Art. 207-208 OP", ["Decyzja wymiarowa po zakończeniu kontroli"]),
    "audit.closure.decision_deadline": ("Art. 208 OP", ["Decyzja wydawana bez zbędnej zwłoki"]),
    "audit.closure.correction": ("Art. 81 OP", ["Możliwość korekty po zakończeniu kontroli"]),
    "audit.follow_up.recommendations": ("Art. 291-292 OP", ["Zalecenia pokontrolne do wdrożenia"]),
    "audit.follow_up.deadline": ("Art. 292 OP", ["Monitoring terminów wdrożenia zaleceń"]),
    "audit.aggregate": ("Art. 119b OP", ["Aktualizacja profilu ryzyka po zakończeniu kontroli"]),
    "audit.binding_info.cost": ("Art. 42g VAT, Art. 42b VAT", ["Kalkulacja: koszt WIS (40 PLN) vs ryzyko błędnej stawki"]),
    "audit.binding_info.renewal": ("Art. 42h VAT", ["Automatyczna rekomendacja odnowienia przed wygaśnięciem"]),
    "audit.binding_info.portfolio": ("Art. 42b-42d VAT", ["Zarządzanie portfelem WIS/WIT/WIA — monitoruj daty wygaśnięcia"]),

    # ── WIT (Wiążąca Informacja Taryfowa) ──
    "audit.wit.eligibility": ("UKC, Art. 33 Rozp. 952/2013", ["Import spoza UE → zalecenie WIT dla ceł"]),
    "audit.wit.validity": ("UKC, Art. 33 Rozp. 952/2013", ["WIT ważna 3 lata (krócej niż WIS)"]),
    "audit.wit.cost": ("UKC", ["WIT jest bezpłatna"]),
    "audit.wit.binding": ("UKC, Art. 33 Rozp. 952/2013", ["WIT wiąże organy celne wszystkich krajów UE"]),

    # ── WIA (Wiążąca Informacja Akcyzowa) ──
    "audit.wia.eligibility": ("Ustawa o podatku akcyzowym", ["Handel alkoholem, tytoniem, energią → zalecenie WIA"]),
    "audit.wia.validity": ("Ustawa o podatku akcyzowym", ["WIA ważna 3 lata"]),
    "audit.wia.cost": ("Ustawa o podatku akcyzowym", ["Opłata za WIA: 250 PLN"]),

    # ── FORCE MAJEURE ──
    "force_majeure.event.detection": ("Art. 67a OP", ["Identyfikacja zdarzenia siły wyższej: powódź, pożar, pandemia, wojna"]),
    "force_majeure.event.flood": ("Art. 67a OP", ["Powódź → katalog ulg podatkowych i ZUS"]),
    "force_majeure.event.fire": ("Art. 67a OP", ["Pożar → katalog ulg podatkowych"]),
    "force_majeure.event.pandemic": ("Art. 67a OP", ["Pandemia/epidemia → katalog ulg"]),
    "force_majeure.event.war": ("Art. 67a OP", ["Skutki działań wojennych → katalog ulg"]),
    "force_majeure.event.natural": ("Art. 67a OP", ["Inna klęska żywiołowa → katalog ulg"]),
    "force_majeure.relief.deadline": ("Art. 67a § 1 OP", ["Przedłużenie terminu złożenia deklaracji"]),
    "force_majeure.relief.application": ("Art. 67b OP", ["Wniosek składany niezwłocznie po zdarzeniu"]),
    "force_majeure.relief.interest": ("Art. 67a § 1 OP", ["Zawieszenie naliczania odsetek na czas rozpatrywania wniosku"]),
    "force_majeure.relief.tax_deferral": ("Art. 67a § 1 pkt 1 OP", ["Odroczenie terminu płatności podatku"]),
    "force_majeure.relief.tax_installments": ("Art. 67a § 1 pkt 2 OP", ["Rozłożenie na raty"]),
    "force_majeure.relief.tax_remission": ("Art. 67a § 1 pkt 3 OP", ["Umorzenie zaległości w całości lub części"]),
    "force_majeure.relief.tax_suspension": ("Art. 67a § 1 OP", ["Zaniechanie poboru podatku na podstawie rozporządzenia MF"]),
    "force_majeure.relief.zus_deferral": ("Art. 28 SUS", ["Odroczenie terminu płatności składek ZUS"]),
    "force_majeure.relief.zus_installments": ("Art. 29 SUS", ["Układ ratalny w ZUS"]),
    "force_majeure.relief.zus_remission": ("Art. 29 SUS", ["Umorzenie składek ZUS (szczególne przypadki)"]),
    "force_majeure.relief.zus_contribution": ("Art. 18a SUS", ["Zawieszenie obowiązku opłacania składek na czas zdarzenia"]),
    "force_majeure.documents.loss": ("Art. 86 § 2 OP", ["Obowiązek zgłoszenia utraty dokumentów w 7 dni"]),
    "force_majeure.documents.reconstruction": ("Art. 86 § 2 OP", ["Procedura odtworzenia zniszczonej dokumentacji"]),
    "force_majeure.documents.backup": ("Art. 86 OP", ["Obowiązek posiadania backupu cyfrowego dokumentacji"]),
    "force_majeure.insurance.cover": ("Art. 14 PIT, KC", ["Sprawdzenie zakresu ubezpieczenia business interruption"]),
    "force_majeure.insurance.payout": ("Art. 14 ust. 1 PIT", ["Odszkodowanie jako przychód podatkowy"]),

    # ── FAMILY / RODZINA ──
    "family.spouse.contract_type.b2b": ("Art. 23 ust. 1 pkt 10 PIT", ["Umowa B2B z małżonkiem → osobna JDG, ZUS własny"]),
    "family.spouse.contract_type.mandate": ("Art. 23 ust. 1 pkt 10 PIT", ["Umowa zlecenie z małżonkiem → ZUS od zlecenia"]),
    "family.spouse.contract_type.employment": ("Art. 22 ust. 1 PIT, KP", ["Umowa o pracę z małżonkiem → pełny ZUS, PIT-4R"]),
    "family.children.employment.under": ("Art. 23 ust. 1 pkt 10 PIT", ["Zatrudnienie dziecka <26 lat → podwyższone ryzyko kontroli"]),
    "family.children.work_evidence": ("Art. 22 ust. 1 PIT", ["Rzeczywiste wykonywanie pracy przez dziecko — dokumentuj"]),
    "family.children.salary_arm": ("Art. 22 ust. 1 PIT, Art. 23zf PIT", ["Wynagrodzenie rynkowe (nie zawyżone) — zasada ceny rynkowej"]),
    "family.children.pit_ulga": ("Art. 21 ust. 1 pkt 148 PIT", ["Interakcja: pensja dziecka + ulga dla młodych (do 85 528 PLN)"]),
    "family.children.university": ("Art. 22 ust. 1 PIT", ["Praca musi być kompatybilna ze studiami"]),
    "family.cooperation.zus_person": ("Art. 8 ust. 2 SUS", ["Osoba współpracująca → składki ZUS jak za przedsiębiorcę"]),
    "family.cooperation.zus_health": ("Art. 81 ustawy zdrowotnej", ["Osoba współpracująca → składka zdrowotna 9%"]),
    "family.cooperation.notification": ("Art. 36 ust. 14 SUS", ["Zgłoszenie osoby współpracującej w 7 dni"]),
    "family.car.usage.mixed": ("Art. 23 ust. 1 pkt 46 PIT", ["Auto używane przez rodzinę → 75% KUP"]),
    "family.car.usage.vat": ("Art. 86a VAT", ["VAT od auta rodzinnego → 50%"]),
    "family.asset.transfer.gift": ("Ustawa o SD, Art. 4a", ["Darowizna dla dzieci → grupa 0, SD-Z2 w 6 mies."]),
    "family.asset.transfer.vat": ("Art. 7 VAT", ["Sprzedaż majątku firmowego rodzinie → VAT naliczony"]),
    "family.succession.sd_z2": ("Ustawa o SD, Art. 4a", ["Zgłoszenie SD-Z2 w ciągu 6 miesięcy od śmierci/nabycia"]),
    "family.succession.business": ("Art. 12-13 ustawy o zarządzie sukcesyjnym", ["Ciągłość JDG po śmierci: zarządca sukcesyjny"]),
    "family.multi_generation": ("Art. 22-23 PIT", ["Optymalizacja podatkowa poprzez zatrudnienie w różnych pokoleniach"]),
    "family.aggregate": ("Art. 119b OP", ["Łączna ocena ryzyka podatkowego transakcji rodzinnych"]),

    # ── E-DELIVERY / E-DORĘCZENIA ──
    "edelivery.registration.mandatory": ("Ustawa o doręczeniach elektronicznych, Art. 5", ["Rejestracja adresu e-Doręczeń w BAE (od 2025 dla JDG)"]),
    "edelivery.registration.deadline": ("Ustawa o doręczeniach elektronicznych", ["Termin rejestracji zależny od typu podmiotu"]),
    "edelivery.fiction.delivery_14": ("Art. 144b OP", ["Pismo nieodebrane → uznane za doręczone po 14 dniach"]),
    "edelivery.fiction.consequences": ("Art. 144b OP", ["Konsekwencje: bieg terminów odwoławczych od daty fikcji"]),
    "edelivery.fiction.critical": ("Art. 144b OP", ["Alert CRITICAL przy zbliżającej się fikcji doręczenia"]),
    "edelivery.fiction.appeal": ("Art. 144b OP", ["Data fikcji = data rozpoczęcia biegu 14 dni na odwołanie"]),
    "edelivery.monitoring.alert_7": ("Art. 144b OP", ["Alert 7 dni przed fikcją doręczenia"]),
    "edelivery.monitoring.alert_1": ("Art. 144b OP", ["Alert 1 dzień przed fikcją doręczenia"]),
    "edelivery.monitoring.unread": ("Art. 144b OP", ["Codzienne sprawdzanie nieodebranych pism"]),

    # ── CROSS-BORDER ──
    "cross_border.eidas": ("Rozp. eIDAS 910/2014", ["Uznawanie podpisów elektronicznych z UE (eIDAS)"]),
    "cross_border.crs.fatca": ("Ustawa o wymianie informacji podatkowych", ["Automatyczna wymiana informacji CRS/FATCA"]),
    "cross_border.dac": ("Dyrektywy DAC1-DAC8", ["Zgodność z dyrektywami DAC"]),

    # ── COMMUNICATION ──
    "communication.calendar": ("Art. 144b OP", ["Integracja terminów komunikacyjnych z kalendarzem płatności"]),
    "communication.offline.backup": ("Art. 144b OP", ["Procedura na wypadek awarii systemów e-US"]),
    "communication.offline.paper": ("Art. 144 OP", ["Kiedy dozwolona forma papierowa"]),
    "communication.language.polish": ("Art. 4 ustawy o języku polskim", ["Obowiązek komunikacji w języku polskim"]),
    "communication.language.foreign": ("Art. 180a OP", ["Tłumaczenie przysięgłe dokumentów obcojęzycznych"]),
    "communication.aggregate": ("Art. 138e-138i OP", ["Dashboard statusu komunikacji z organami"]),

    # ── KKS CONVICTION ──
    "kks.conviction.extended": ("Art. 83 Prawa przedsiębiorców", ["Przedłużony okres kontroli po skazaniu KKS"]),
    "kks.conviction.business": ("Art. 105a VAT", ["Utrata zaufania kontrahentów po skazaniu KKS"]),
    "kks.conviction.joint_vat": ("Art. 105a VAT", ["Solidarna odpowiedzialność za VAT kontrahenta"]),
    "kks.conviction.isolation": ("Art. 105a VAT", ["Izolacja od sieci biznesowych po skazaniu"]),
    "kks.conviction.bank": ("Art. 56 Prawa bankowego + AML", ["Bank może wypowiedzieć umowę rachunku"]),
    "kks.conviction.credit": ("BIK, praktyka bankowa", ["Wpływ na zdolność kredytową"]),
    "kks.conviction.enhanced_aml": ("Art. 43 AML", ["Wzmocniona weryfikacja AML/KYC"]),
    "kks.conviction.fintech": ("Polityki fintechów", ["Ograniczenia w dostępie do fintechów"]),
    "kks.conviction.cash": ("GIIF", ["Monitoring transakcji gotówkowych"]),
    "kks.conviction.tax_office": ("Praktyka US", ["Zaostrzony nadzór US po skazaniu"]),
    "kks.conviction.risk_profile": ("Art. 119b OP", ["Przeklasyfikowanie profilu ryzyka na HIGH"]),
    "kks.conviction.public_warning": ("Art. 119b OP", ["Wpis na listę ostrzeżeń publicznych MF"]),
    "kks.conviction.statute": ("Art. 70 § 4 OP", ["Przerwanie biegu przedawnienia przez skazanie"]),

    # ── REGULATED PROFESSIONS ──
    "regulated.cross_border.eu": ("Dyrektywa 2005/36/WE", ["Uznawanie kwalifikacji UE w PL"]),
    "regulated.cross_border.non_eu": ("Ustawy branżowe", ["Uznawanie kwalifikacji spoza UE — procedura nostryfikacji"]),
    "regulated.cross_border.temporary": ("Dyrektywa 2005/36/WE", ["Tymczasowe świadczenie usług w UE — uznanie kwalifikacji"]),
    "regulated.cross_border.double_taxation": ("Umowy UPO", ["Podwójne opodatkowanie specjalisty transgranicznego"]),
    "regulated.cross_border.vat": ("Art. 28k VAT, OSS", ["Obowiązek rejestracji VAT za granicą przy usługach B2C"]),
    "regulated.aggregate.profession": ("Ustawy branżowe", ["Profil ryzyka specyficzny dla zawodu regulowanego"]),
    "regulated.aggregate.annual": ("Ustawy branżowe", ["Checklista roczna dla zawodu regulowanego"]),

    # ── INSURANCE ──
    "insurance.mandatory.detection_legal": ("Rozp. MS ws. OC adwokatów/radców", ["OC prawników — obowiązkowe"]),
    "insurance.mandatory.detection_medical": ("Ustawa o zawodzie lekarza", ["OC lekarzy — obowiązkowe"]),

    # ── PAYMENTS ──
    "payment.installments.pit": ("Art. 14 PIT", ["Sprzedaż na raty — przychód PIT w dacie każdej raty"]),
    "payment.installments.vat_accrual": ("Art. 19a VAT", ["VAT memoriałowy — obowiązek od całości w dacie dostawy"]),
    "payment.installments.vat_cash": ("Art. 21 VAT", ["VAT kasowy — obowiązek w dacie każdej raty"]),
    "payment.installments.late": ("Art. 56 OP", ["Opóźnienie raty → odsetki od zaległości"]),
    "payment.installments.contract": ("Art. 106j VAT", ["Zerwanie umowy ratalnej — skutki podatkowe"]),
    "payment.advance.vat_obligation": ("Art. 19a ust. 8 VAT", ["Zaliczka — obowiązek VAT w dacie otrzymania"]),
    "payment.advance.vat_invoice": ("Art. 106i VAT", ["Faktura zaliczkowa w ciągu 15 dni od otrzymania zaliczki"]),
    "payment.advance.pit": ("Art. 14 PIT", ["Zaliczka — przychód PIT w dacie otrzymania"]),
    "payment.advance.advance_not": ("Art. 14 PIT", ["Niezwrócona zaliczka przy zerwaniu umowy — opodatkowana"]),

    # ── DEADLINES ──
    "deadlines.": ("Art. 47 SUS, Art. 103 VAT, Art. 44 PIT", ["Kalendarz terminów: ZUS 10/15/20, VAT 25, PIT 20"]),

    # ── LIMITS ──
    "limits.": ("Art. 113 VAT, Art. 26 PIT", ["Limity: zwolnienie VAT 200k, ulgi, darowizny 6%"]),
}

def find_basis(rule_id, description):
    """Find matching legal basis by rule_id pattern."""
    for pattern, (basis, warnings) in BASIS_MAP.items():
        if pattern in rule_id:
            return basis, warnings
    # Fallback: try to extract from description
    if "Art." in description or "art." in description.lower():
        return description, []
    return None, None

def extract_basis_from_routing(routing_reason):
    """Try to extract legal basis from routing_reason text."""
    m = re.search(r'Art\.\s+[\d]+[a-z]*(?:\s*[-–]\s*[\d]+[a-z]*)?(?:\s+ust\.\s+\d+)?\s+\w+', routing_reason)
    if m:
        return m.group(0)
    m = re.search(r'Art\.\s+[\d]+[a-z]*\s*(?:§\s*\d+)?', routing_reason)
    if m:
        return m.group(0)
    return None

def fix_file(filepath):
    """Fix a single hyper plan45.rego file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    fixed_count = 0
    
    # Find all rule blocks
    # Pattern: rule_id appears in both the comment and the verdict JSON
    lines = content.split('\n')
    new_lines = []
    
    for i, line in enumerate(lines):
        new_line = line
        
        # Check if this line contains a verdict with _legal_basis
        legal_match = re.search(r'"_legal_basis":"([^"]*)"', line)
        if legal_match:
            current_basis = legal_match.group(1)
            # Fix if empty "" or starts with R- (e.g., R1045, R-ID, R1234)
            is_empty = (current_basis == "" or current_basis.startswith("R-") or (current_basis.startswith("R") and current_basis[1:].isdigit()))
            
            if is_empty:
                # Find rule_id from this line
                rule_match = re.search(r'"rule_id":"([^"]+)"', line)
                if rule_match:
                    rule_id = rule_match.group(1)
                    
                    # Find description from routing_reason or comment
                    routing_match = re.search(r'"_routing_reason":"([^"]*)"', line)
                    desc = routing_match.group(1) if routing_match else ""
                    
                    # Try to find basis from description
                    basis, warnings = find_basis(rule_id, desc)
                    
                    if not basis:
                        # Try extracting from routing_reason
                        basis = extract_basis_from_routing(desc)
                        warnings = [desc[:200]] if desc else []
                    
                    if basis:
                        # Replace legal_basis
                        new_line = re.sub(
                            r'"_legal_basis":"[^"]*"',
                            f'"_legal_basis":"{basis}"',
                            new_line
                        )
                        
                        # Also fix empty warnings if they're []
                        if '"_warnings":[]' in new_line:
                            w = '", "'.join(warnings[:3])
                            new_line = new_line.replace(
                                '"_warnings":[]',
                                f'"_warnings":["{w}"]' if w else '"_warnings":[]'
                            )
                        
                        fixed_count += 1
        
        # Also fix empty _routing with meaningful routing_reason
        if '"_routing":"","_routing_reason":"' in line and '"_routing_reason":""' not in line:
            # Already has routing_reason but empty routing - set to WARNING for non-trivial reasons
            routing_reason = re.search(r'"_routing_reason":"([^"]+)"', line)
            if routing_reason and len(routing_reason.group(1)) > 20:
                new_line = new_line.replace('"_routing":"","_routing_reason"', '"_routing":"WARNING","_routing_reason"')
        
        new_lines.append(new_line)
    
    result = '\n'.join(new_lines)
    
    if result != original and not DRY_RUN:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(result)
    
    return fixed_count

def main():
    print("=" * 70)
    print("NexusAI JDG — Fix Hyper Tier Legal Basis")
    print("=" * 70)
    
    if DRY_RUN:
        print("\n⚠️  DRY RUN MODE — no files will be modified\n")
    
    total_fixed = 0
    files_modified = 0
    
    for root, dirs, files in os.walk(BASE):
        for f in sorted(files):
            if f.endswith('.rego'):
                filepath = os.path.join(root, f)
                fixed = fix_file(filepath)
                if fixed > 0:
                    relpath = os.path.relpath(filepath)
                    if DRY_RUN:
                        print(f"  [DRY RUN] {relpath}: {fixed} rules would be fixed")
                    else:
                        print(f"  ✅ {relpath}: {fixed} rules fixed")
                    total_fixed += fixed
                    files_modified += 1
    
    print(f"\n{'=' * 70}")
    print(f"SUMMARY")
    print(f"  Rules fixed: {total_fixed}")
    print(f"  Files modified: {files_modified}")
    if DRY_RUN:
        print(f"\n  ⚠️  DRY RUN — use without --dry-run to apply fixes.")
    print(f"{'=' * 70}")

if __name__ == "__main__":
    main()
