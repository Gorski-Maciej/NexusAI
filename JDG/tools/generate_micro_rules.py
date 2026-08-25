#!/usr/bin/env python3
"""
NexusAI JDG — Micro Rule Generator
Generates ~6,000+ atomic Micro rules (jdg.<ustawa>.<art>.r<n>)
from the canonical taxonomy defined in Plan OPA/41_JDG_MEGA_MATRIX_7000_RULES.md.

Output: JDG/rules/micro/<package>/*.rego
"""

import os
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
RULES_DIR = PROJECT_ROOT / "JDG" / "rules" / "micro"

# ─── TAXONOMY DEFINITION ───────────────────────────────────────────────────

# Format: (article_id, article_name, num_rules, priority_start, legal_basis, template_type)
# template_type: 'standard' | 'tax_point' | 'deduction' | 'exemption' | 'sanction' | 'rate'

TAXONOMY = {
    "vat": {
        "description": "Ustawa o VAT — 85 artykułów → ~1105 reguł Micro",
        "articles": [
            ("a5", "Czynności opodatkowane", 10, 50005),
            ("a7", "Dostawa towarów", 12, 50017),
            ("a8", "Świadczenie usług", 12, 50029),
            ("a15", "Podatnicy VAT", 8, 50041),
            ("a17", "Reverse charge (odwrotne obciążenie)", 12, 50049),
            ("a19a", "Obowiązek podatkowy — zasada ogólna", 15, 50061),
            ("a20", "Obowiązek podatkowy — WNT", 10, 50076),
            ("a21", "Metoda kasowa VAT", 10, 50086),
            ("a28a", "Miejsce świadczenia usług", 10, 50096),
            ("a28b", "Miejsce świadczenia usług B2B", 8, 50106),
            ("a28c", "Miejsce świadczenia usług B2C", 8, 50114),
            ("a29a", "Podstawa opodatkowania", 15, 50122),
            ("a31", "Podstawa opodatkowania — usługi", 8, 50137),
            ("a32", "Podstawa opodatkowania — dostawa", 8, 50145),
            ("a41", "Stawki VAT — podstawowe", 15, 50153),
            ("a41b", "Stawki obniżone 8%", 12, 50168),
            ("a41c", "Stawki obniżone 5%", 10, 50180),
            ("a41d", "Stawki 0% i zwolnienia", 15, 50190),
            ("a42", "Stawka 0% — WDT", 12, 50205),
            ("a43", "Zwolnienia przedmiotowe", 40, 50217),
            ("a86", "Prawo do odliczenia VAT", 20, 50257),
            ("a86a", "VAT od samochodów", 12, 50277),
            ("a87", "Terminy zwrotu VAT", 12, 50289),
            ("a88", "Wyłączenia z odliczenia", 15, 50301),
            ("a89a", "Złe długi — wierzyciel", 12, 50316),
            ("a89b", "Złe długi — dłużnik", 12, 50328),
            ("a96", "Rejestracja VAT-R", 12, 50340),
            ("a96b", "Biała Lista VAT", 10, 50352),
            ("a97", "VAT-UE rejestracja", 10, 50362),
            ("a99", "Deklaracje VAT", 12, 50372),
            ("a100", "VAT-UE informacje podsumowujące", 8, 50384),
            ("a103", "Terminy płatności VAT", 8, 50392),
            ("a106a", "Faktury — wymogi formalne", 15, 50400),
            ("a106f", "Faktury korygujące", 12, 50415),
            ("a106na", "KSeF — obowiązek", 12, 50427),
            ("a106ne", "KSeF — tryb awaryjny", 8, 50439),
            ("a106nq", "KSeF — sankcje", 8, 50447),
            ("a108", "Split payment", 12, 50455),
            ("a108a", "MPP — sankcje", 8, 50467),
            ("a109", "Ewidencja VAT", 10, 50475),
            ("a113", "Zwolnienie podmiotowe 200k", 18, 50485),
            ("a119", "Faktury zaliczkowe", 8, 50503),
            ("a120", "Procedura marży", 15, 50511),
            ("a129", "Transakcje UE — WDT", 12, 50526),
            ("a135", "Transakcje UE — WNT", 12, 50538),
            ("a130", "OSS — One Stop Shop", 10, 50550),
            ("a131", "IOSS — Import OSS", 8, 50560),
            ("a138", "Transakcje trójstronne", 10, 50568),
        ],
    },
    "pit": {
        "description": "Ustawa o PIT — 70 artykułów → ~910 reguł Micro",
        "articles": [
            ("a6", "Wspólne rozliczenie małżonków", 10, 60006),
            ("a9", "Strata podatkowa", 10, 60016),
            ("a9a", "Wybór formy opodatkowania", 12, 60026),
            ("a10", "Źródła przychodów", 12, 60038),
            ("a14", "Przychody z działalności gospodarczej", 20, 60050),
            ("a14c", "Różnice kursowe", 12, 60070),
            ("a21", "Zwolnienia przedmiotowe PIT", 12, 60082),
            ("a22", "KUP — definicja ogólna", 15, 60094),
            ("a22a", "Amortyzacja — definicje", 10, 60109),
            ("a22d", "Amortyzacja — metody", 8, 60119),
            ("a22e", "Amortyzacja — jednorazowa", 6, 60127),
            ("a22f", "Amortyzacja — używane", 6, 60133),
            ("a22g", "Amortyzacja — stawki", 8, 60139),
            ("a22i", "Amortyzacja — moment", 6, 60147),
            ("a22j", "Amortyzacja — ulepszenie", 6, 60153),
            ("a22k", "Amortyzacja — sprzedaż", 6, 60159),
            ("a22l", "Amortyzacja — WNiP", 8, 60165),
            ("a22m", "Amortyzacja — auto prywatne", 8, 60173),
            ("a22p", "Limit płatności gotówkowych", 8, 60181),
            ("a23", "Wyłączenia z KUP", 30, 60189),
            ("a24", "Dochód i strata", 15, 60219),
            ("a24a", "Obowiązek PKPiR", 10, 60234),
            ("a26", "Ulgi odliczane od dochodu", 25, 60244),
            ("a26e", "Ulga B+R", 15, 60269),
            ("a26eb", "Ulga na prototyp", 6, 60284),
            ("a26ec", "Ulga na ekspansję", 6, 60290),
            ("a26gb", "Ulga na robotyzację", 8, 60296),
            ("a26h", "Ulga termomodernizacyjna", 8, 60304),
            ("a27", "Skala podatkowa 12%/32%", 15, 60312),
            ("a27f", "Ulga na dzieci", 12, 60327),
            ("a30", "Ryczałt od kapitałów", 12, 60339),
            ("a30a", "Dochody kapitałowe", 12, 60351),
            ("a30b", "Sprzedaż nieruchomości", 12, 60363),
            ("a30c", "Podatek liniowy 19%", 12, 60375),
            ("a30ca", "IP Box 5%", 12, 60387),
            ("a30da", "Exit Tax", 12, 60399),
            ("a30f", "CFC — zagraniczna spółka kontrolowana", 15, 60411),
            ("a31", "Zaliczki na podatek", 25, 60426),
            ("a44", "Zaliczki uproszczone", 12, 60451),
            ("a45", "Zeznania roczne", 15, 60463),
            ("a45a", "Informacje PIT-11, IFT", 15, 60478),
            ("a21b", "Ulga dla młodych PIT-0", 10, 60493),
            ("a21c", "Ulga na powrót", 8, 60503),
            ("a21d", "Ulga dla rodzin 4+", 8, 60511),
            ("a21e", "Ulga dla pracujących emerytów", 8, 60519),
        ],
    },
    "ord": {
        "description": "Ordynacja Podatkowa — 50 artykułów → ~650 reguł Micro",
        "articles": [
            ("a16", "Czynny żal", 6, 70016),
            ("a20", "Zaległość podatkowa", 5, 70022),
            ("a21", "Nadpłata", 5, 70027),
            ("a26", "Odpowiedzialność podatnika", 8, 70032),
            ("a27", "Odpowiedzialność małżonka", 6, 70040),
            ("a28", "Odpowiedzialność rozwiedzionego małżonka", 5, 70046),
            ("a29", "Podatnicy, płatnicy, inkasenci", 8, 70051),
            ("a32", "Obowiązek składania deklaracji", 5, 70059),
            ("a33", "Obowiązek zapłaty podatku", 8, 70064),
            ("a47", "Odsetki za zwłokę — stawka", 8, 70072),
            ("a48", "Odsetki — opłata prolongacyjna", 5, 70080),
            ("a51", "Umorzenie odsetek", 5, 70085),
            ("a52", "Kolejność zaliczania wpłat", 5, 70090),
            ("a53", "Odsetki — zasady ogólne", 5, 70095),
            ("a54", "Odsetki — minimalna kwota", 5, 70100),
            ("a56", "Odsetki — stawka podstawowa", 5, 70105),
            ("a56b", "Odsetki karne 150%", 5, 70110),
            ("a67a", "Ulgi w spłacie — rodzaje", 5, 70115),
            ("a67b", "Odroczenie / raty", 8, 70120),
            ("a67c", "Ulgi automatyczne", 5, 70128),
            ("a67d", "Zabezpieczenie przy ulgach", 5, 70133),
            ("a67e", "Odwołanie ulgi", 5, 70138),
            ("a70", "Przedawnienie zobowiązań", 15, 70143),
            ("a71", "Przerwanie i zawieszenie przedawnienia", 10, 70158),
            ("a72", "Nadpłata — definicja", 8, 70168),
            ("a73", "Nadpłata — zaliczenie", 5, 70176),
            ("a74", "Nadpłata — wniosek o zwrot", 5, 70181),
            ("a75", "Nadpłata po przedawnieniu", 5, 70186),
            ("a76", "Nadpłata — minimum 5 PLN", 5, 70191),
            ("a77", "Nadpłata — dziedziczenie", 5, 70196),
            ("a78", "Nadpłata — termin korekty", 5, 70201),
            ("a79", "Nadpłata — korekta przed/po kontroli", 5, 70206),
            ("a80", "Nadpłata — waluta obca", 5, 70211),
            ("a81", "Korekta deklaracji", 10, 70216),
            ("a81b", "Korekta w trakcie kontroli", 5, 70226),
            ("a86", "Przechowywanie dokumentów", 8, 70231),
            ("a87", "Zwrot nadpłaty — 45 dni", 5, 70239),
            ("a119a", "Klauzula GAAR", 10, 70244),
            ("a120", "Postępowanie — wszczęcie", 5, 70254),
            ("a121", "Postępowanie — strona", 5, 70259),
            ("a122", "Postępowanie — pełnomocnik", 5, 70264),
            ("a123", "Postępowanie — dowody", 5, 70269),
            ("a124", "Postępowanie — terminy", 5, 70274),
            ("a125", "Postępowanie — decyzja", 5, 70279),
            ("a126", "Postępowanie — odwołanie", 5, 70284),
            ("a127", "Postępowanie — skarga do WSA", 5, 70289),
            ("a138a", "Pełnomocnictwa podatkowe", 30, 70294),
            ("a193a", "JPK na żądanie", 10, 70324),
        ],
    },
    "kks": {
        "description": "KKS — Kodeks Karny Skarbowy — 40 artykułów → ~480 reguł Micro",
        "articles": [
            ("a16", "Czynny żal", 12, 80016),
            ("a20", "Przedawnienie karalności — przestępstwa", 8, 80028),
            ("a21", "Przedawnienie karalności — wykroczenia", 8, 80036),
            ("a54", "Uchylanie się od opodatkowania", 15, 80044),
            ("a55", "Oszustwo podatkowe", 12, 80059),
            ("a56", "Nierzetelne księgi / PKPiR", 15, 80071),
            ("a57", "Nierzetelna ewidencja VAT", 12, 80086),
            ("a58", "Oszustwo w zakresie faktur", 10, 80098),
            ("a59", "Fałszowanie dokumentów", 10, 80108),
            ("a60", "Przekroczenie uprawnień", 10, 80118),
            ("a61", "Narażenie na uszczuplenie", 10, 80128),
            ("a62", "Puste faktury / fałszerstwo faktur", 15, 80138),
            ("a63", "Niewystawienie faktury", 10, 80153),
            ("a64", "Niewłaściwa stawka VAT", 10, 80163),
            ("a65", "Zawyżenie zwrotu VAT", 10, 80173),
            ("a66", "Nierzetelne zeznanie", 10, 80183),
            ("a67", "Nieprowadzenie ksiąg", 10, 80193),
            ("a68", "Zniszczenie dokumentów", 10, 80203),
            ("a69", "Utrudnianie kontroli", 10, 80213),
            ("a70", "Nieskładanie deklaracji", 10, 80223),
            ("a71", "Naruszenie obowiązków płatniczych", 10, 80233),
            ("a72", "Niepobranie podatku", 10, 80243),
            ("a73", "Niewpłacenie podatku", 10, 80253),
            ("a74", "Naruszenie obowiązków ewidencyjnych", 10, 80263),
            ("a75", "Naruszenie KSeF", 10, 80273),
            ("a76", "Naruszenie JPK", 10, 80283),
            ("a77", "Niezłożenie deklaracji w terminie", 12, 80293),
            ("a78", "Nieprawidłowe dane w deklaracji", 10, 80305),
            ("a79", "Niezapłacenie podatku w terminie", 10, 80315),
            ("a80", "Sankcje — grzywny, kara", 12, 80325),
            ("a81", "Nadzwyczajne złagodzenie kary", 10, 80337),
            ("a82", "Odstąpienie od wymierzenia kary", 10, 80347),
            ("a83", "Przepadek przedmiotów / korzyści", 10, 80357),
            ("a85", "Karalność łączna — zbieg przestępstw", 8, 80367),
            ("a86", "Karalność łączna — zbieg wykroczeń", 8, 80375),
            ("a87", "Kary łączne", 8, 80383),
        ],
    },
    "sus": {
        "description": "Ustawa o SUS (ZUS) — 30 artykułów → ~390 reguł Micro",
        "articles": [
            ("a6", "Podmioty podlegające ubezpieczeniom", 8, 90006),
            ("a6b", "Zbieg tytułów ubezpieczenia", 6, 90014),
            ("a9", "Zbieg ubezpieczeń", 8, 90020),
            ("a11", "Dobrowolność ubezpieczeń", 8, 90028),
            ("a13", "Obowiązek ubezpieczenia", 8, 90036),
            ("a14", "Dobrowolne ubezpieczenie chorobowe", 8, 90044),
            ("a18", "Podstawy wymiaru składek", 10, 90052),
            ("a18a", "Ulga na start / preferencyjny ZUS", 10, 90062),
            ("a18c", "Mały ZUS Plus", 10, 90072),
            ("a19", "Składka na ubezpieczenie wypadkowe", 8, 90082),
            ("a22", "Stopy procentowe składek", 8, 90090),
            ("a24", "Przedawnienie składek", 6, 90098),
            ("a36", "Terminy płatności", 8, 90104),
            ("a40", "Zawieszenie działalności", 8, 90112),
            ("a47", "Obowiązek opłacania składek", 8, 90120),
        ],
    },
    "ryczalt": {
        "description": "Ustawa o ryczałcie — 25 artykułów → ~325 reguł Micro",
        "articles": [
            ("a4", "Definicja ryczałtu", 12, 100004),
            ("a6", "Limit przychodu 2 mln EUR", 10, 100016),
            ("a8", "Wyłączenia z ryczałtu", 15, 100026),
            ("a12", "Stawki per PKWiU", 18, 100041),
            ("a15", "Ewidencja ryczałtowa", 10, 100059),
            ("a21", "Karta podatkowa — stawki", 12, 100069),
            ("a27", "Karta podatkowa — warunki", 12, 100081),
            ("a30", "Utrata prawa do ryczałtu", 8, 100093),
        ],
    },
    "zdrowotna": {
        "description": "Ustawa o świadczeniach opieki zdrowotnej — 10 artykułów → ~130 reguł Micro",
        "articles": [
            ("a79", "Obowiązek składki zdrowotnej", 10, 110079),
            ("a81", "Podstawa wymiaru — skala", 10, 110089),
            ("a81b", "Podstawa wymiaru — liniowy", 10, 110099),
            ("a81c", "Podstawa wymiaru — ryczałt", 12, 110109),
            ("a81d", "Roczne rozliczenie zdrowotnej", 12, 110121),
            ("a82", "Zdrowotna przy zawieszeniu", 8, 110133),
        ],
    },
    "zasilkowa": {
        "description": "Ustawa zasiłkowa — 10 artykułów → ~100 reguł Micro",
        "articles": [
            ("a19", "Zasiłek chorobowy", 10, 120019),
            ("a29", "Zasiłek macierzyński", 10, 120029),
            ("a32", "Zasiłek opiekuńczy", 10, 120039),
            ("a33", "Zasiłek rehabilitacyjny", 8, 120049),
        ],
    },
    "pp": {
        "description": "Prawo Przedsiębiorców — 25 artykułów → ~250 reguł Micro",
        "articles": [
            ("a3", "Definicja przedsiębiorcy", 10, 130003),
            ("a4", "Definicja działalności gospodarczej", 10, 130013),
            ("a5", "Działalność nieewidencjonowana", 12, 130023),
            ("a14", "Prawa przedsiębiorcy", 8, 130035),
            ("a17", "Obowiązki przedsiębiorcy", 8, 130043),
            ("a22", "Zawieszenie działalności", 10, 130051),
            ("a23", "Zawieszenie — konsekwencje", 8, 130061),
            ("a25", "Wznowienie działalności", 8, 130069),
            ("a34", "CEIDG — zmiana wpisu", 10, 130077),
            ("a36", "Kontrola przedsiębiorcy", 8, 130087),
        ],
    },
    "ceidg": {
        "description": "Ustawa o CEIDG — 15 artykułów → ~150 reguł Micro",
        "articles": [
            ("a5", "Zgłoszenie do CEIDG", 8, 140005),
            ("a12", "Zmiany wpisu", 8, 140013),
            ("a15", "Zawieszenie w CEIDG", 6, 140021),
            ("a22", "Wykreślenie z CEIDG", 6, 140027),
            ("a25", "Wznowienie wpisu", 6, 140033),
        ],
    },
    "sukcesja": {
        "description": "Ustawa o zarządzie sukcesyjnym — 15 artykułów → ~150 reguł Micro",
        "articles": [
            ("a3", "Zarządca sukcesyjny", 8, 150003),
            ("a12", "Obowiązki zarządcy", 8, 150011),
            ("a14", "Kontynuacja działalności", 8, 150019),
            ("a21", "Zakończenie zarządu", 8, 150027),
            ("a24", "Odpowiedzialność zarządcy", 6, 150035),
        ],
    },
    "uor": {
        "description": "Ustawa o rachunkowości (dla JDG) — 30 artykułów → ~300 reguł Micro",
        "articles": [
            ("a4", "Zakres podmiotowy UoR", 8, 160004),
            ("a10", "Polityka rachunkowości", 10, 160012),
            ("a20", "Dowody księgowe", 10, 160022),
            ("a22", "Rzetelność ksiąg", 12, 160032),
            ("a24", "Zasada ostrożności", 10, 160044),
            ("a26", "Inwentaryzacja", 12, 160054),
            ("a28", "Wycena aktywów", 12, 160066),
            ("a32", "Różnice kursowe — UoR", 8, 160078),
            ("a35", "Sprawozdanie finansowe", 12, 160086),
            ("a39", "Rozliczenia międzyokresowe", 10, 160098),
            ("a45", "Badanie sprawozdań", 10, 160108),
            ("a74", "Przechowywanie dokumentów", 10, 160118),
        ],
    },
    "pcc": {
        "description": "PCC + podatki lokalne — 25 artykułów → ~250 reguł Micro",
        "articles": [
            ("a1", "Definicja PCC", 10, 170001),
            ("a2", "Zwolnienia PCC", 12, 170011),
            ("a3", "Transfer wierzytelności", 8, 170023),
            ("a4", "Umowa pożyczki", 10, 170031),
            ("a6", "Pojazdy", 8, 170041),
            ("a7", "Nieruchomości", 8, 170049),
            ("a5l", "Podatek od nieruchomości", 10, 170057),
            ("a9l", "Podatek od środków transportowych", 8, 170067),
            ("a13l", "Opłata targowa", 5, 170075),
            ("a14l", "Opłata miejscowa", 5, 170080),
            ("a16l", "Opłata reklamowa", 5, 170085),
        ],
    },
    "ksef": {
        "description": "KSeF — 30 artykułów → ~360 reguł Micro",
        "articles": [
            ("a106na", "KSeF — obowiązek", 15, 180001),
            ("a106nb", "KSeF — wystawianie", 12, 180016),
            ("a106nc", "KSeF — odbiór", 10, 180028),
            ("a106nd", "KSeF — przechowywanie", 10, 180038),
            ("a106ne", "KSeF — tryb awaryjny", 10, 180048),
            ("a106nf", "KSeF — UPO", 8, 180058),
            ("a106ng", "KSeF — QR kod", 6, 180066),
            ("a106nh", "KSeF — zgoda nabywcy", 8, 180072),
        ],
    },
    "jpk": {
        "description": "JPK — 30 artykułów → ~160 reguł Micro",
        "articles": [
            ("a99", "JPK_V7M — struktura", 15, 190099),
            ("a99b", "JPK_V7K — kwartalny", 10, 190114),
            ("a193a", "JPK na żądanie", 10, 190124),
        ],
    },
    "aml": {
        "description": "AML + Prawo dewizowe — 15 artykułów → ~150 reguł Micro",
        "articles": [
            ("a8", "Instytucje obowiązane", 10, 200008),
            ("a10", "Środki bezpieczeństwa finansowego", 10, 200018),
            ("a15", "Raportowanie SAR", 8, 200028),
            ("a18", "Transakcje >15k EUR", 8, 200036),
            ("a22", "Sankcje AML", 8, 200044),
        ],
    },
    "rodo": {
        "description": "RODO dla JDG — 10 artykułów → ~80 reguł Micro",
        "articles": [
            ("a6", "Podstawa prawna przetwarzania", 8, 210006),
            ("a13", "Obowiązek informacyjny", 8, 210014),
            ("a15", "Prawo dostępu do danych", 8, 210022),
            ("a32", "Bezpieczeństwo przetwarzania", 8, 210030),
            ("a33", "Zgłaszanie naruszeń", 8, 210038),
        ],
    },
    "srodowisko": {
        "description": "BDO, SUP, CBAM — 15 artykułów → ~150 reguł Micro",
        "articles": [
            ("a7", "BDO — rejestracja", 8, 220007),
            ("a10", "BDO — ewidencja odpadów", 10, 220015),
            ("a15", "BDO — sprawozdanie roczne", 8, 220025),
            ("a3s", "SUP — opakowania jednorazowe", 8, 220033),
            ("a5s", "SUP — opłata", 6, 220041),
            ("a8", "CBAM — raportowanie", 8, 220047),
        ],
    },
    "crossborder": {
        "description": "Cross-border — 20 artykułów → ~200 reguł Micro",
        "articles": [
            ("a23o", "Ceny transferowe — dokumentacja", 10, 230023),
            ("a23zf", "Ceny transferowe — progi", 8, 230033),
            ("a30da", "Exit Tax", 10, 230041),
            ("a30f", "CFC — definicja", 8, 230051),
            ("a30f2", "CFC — test dochodu pasywnego", 8, 230059),
            ("a29", "Podatek u źródła WHT", 10, 230067),
            ("a86r", "MDR — raportowanie schematów", 10, 230077),
            ("a20", "Konwencje MLI", 8, 230087),
        ],
    },
    "transport": {
        "description": "Transport drogowy — 20 artykułów → ~160 reguł Micro",
        "articles": [
            ("a4", "Licencja transportowa", 8, 240004),
            ("a8", "Zezwolenia", 8, 240012),
            ("a12", "Czas pracy kierowców", 8, 240020),
            ("a16", "Pakiet Mobilności — delegowanie", 8, 240028),
            ("a20", "Przewóz kabotażowy", 6, 240036),
            ("a24", "Sankcje transportowe", 6, 240042),
        ],
    },
    "akcyza": {
        "description": "Akcyza — 20 artykułów → ~160 reguł Micro",
        "articles": [
            ("a2", "Wyroby akcyzowe", 8, 250002),
            ("a26", "OBB — obowiązek dokumentowania", 8, 250010),
            ("a30", "Skład podatkowy", 8, 250018),
            ("a99", "Obrót wyrobami akcyzowymi", 8, 250026),
        ],
    },
}

# ─── REGO TEMPLATES ─────────────────────────────────────────────────────────

HEADER_TEMPLATE = """# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: {package_desc}
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.{package}
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.{package}

import data.jdg.helpers

default decide := {{
    "matched": false,
    "rule_id": "jdg.micro.{package}.no_match",
    "package": "jdg.micro.{package}",    "priority": 999999,
}}"""

ARTICLE_HEADER = """
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  {package}.{art_id} — {art_name} ({num_rules} reguł)                                    ║
# ║  Legal basis: {legal_bases}                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
"""

RULE_TEMPLATES = {
    "standard": """# {rule_id_full}: {rule_name}
{rule_type} := {{
    "matched": true,
    "rule_id": "{rule_id_full}",
    "package": "{package_name}",
    "priority": {priority},
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "{legal_basis}",
    "_warnings": ["{warning_text}"]
}} {{
    {condition}
}}""",
    "sanction": """# {rule_id_full}: {rule_name} [SANKCJA]
{rule_type} := {{
    "matched": true,
    "rule_id": "{rule_id_full}",
    "package": "{package_name}",
    "priority": {priority},
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "",
    "pit_rate": "",
    "pit_bracket": "",
    "pit_annual_return_type": "",
    "kus_qualification": "",
    "kus_percent": 0,
    "zus_social_base_type": "",
    "zus_health_rate": "",
    "business_status": "",
    "ceidg_registration_required": false,
    "micro_rule_active": true,
    "sanction_type": "KKS",
    "sanction_severity": "{severity}",
    "sanction_base_amount_pln": {amount},
    "_routing": "BLOCK_AND_ALERT",
    "_routing_reason": "{routing_reason}",
    "_legal_basis": "{legal_basis}",
    "_warnings": ["{warning_text}"]
}} {{
    {condition}
}}""",
}

# Rule type descriptions per position in the decomposition scheme
RULE_TYPES = [
    ("eligibility", "Czy artykuł/przepis ma zastosowanie do JDG?", "standard"),
    ("positive_1", "Pierwszy warunek pozytywny — kiedy TAK", "standard"),
    ("positive_2", "Drugi warunek pozytywny", "standard"),
    ("positive_3", "Trzeci warunek pozytywny", "standard"),
    ("negative_1", "Pierwsze wyłączenie — kiedy NIE", "standard"),
    ("negative_2", "Drugie wyłączenie", "standard"),
    ("exception_1", "Wyjątek od wyłączenia", "standard"),
    ("exception_2", "Drugi wyjątek", "standard"),
    ("interaction_1", "Interakcja z innymi przepisami", "standard"),
    ("interaction_2", "Druga interakcja", "standard"),
    ("deadline", "Termin / procedura", "standard"),
    ("sanction", "Sankcja za naruszenie", "sanction"),
    ("edge_1", "Edge case — nietypowa sytuacja", "standard"),
    ("edge_2", "Drugi edge case", "standard"),
    ("validation", "Walidacja formalna", "standard"),
]

LEGAL_BASES = {
    "vat": "Ustawa o VAT z 11.03.2004 (Dz.U. 2004 nr 54 poz. 535)",
    "pit": "Ustawa o PIT z 26.07.1991 (Dz.U. 1991 nr 80 poz. 350)",
    "ord": "Ordynacja Podatkowa z 29.08.1997 (Dz.U. 1997 nr 137 poz. 926)",
    "kks": "Kodeks Karny Skarbowy z 10.09.1999 (Dz.U. 1999 nr 83 poz. 930)",
    "sus": "Ustawa o SUS z 13.10.1998 (Dz.U. 1998 nr 137 poz. 887)",
    "ryczalt": "Ustawa o ryczałcie z 20.11.1998 (Dz.U. 1998 nr 144 poz. 930)",
    "zdrowotna": "Ustawa o świad. opieki zdrow. z 27.08.2004 (Dz.U. 2004 nr 210 poz. 2135)",
    "zasilkowa": "Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)",
    "pp": "Prawo Przedsiębiorców z 06.03.2018 (Dz.U. 2018 poz. 646)",
    "ceidg": "Ustawa o CEIDG z 06.03.2018 (Dz.U. 2018 poz. 647)",
    "sukcesja": "Ustawa o zarządzie sukcesyjnym z 05.07.2018 (Dz.U. 2018 poz. 1629)",
    "uor": "Ustawa o rachunkowości z 29.09.1994 (Dz.U. 1994 nr 121 poz. 591)",
    "pcc": "Ustawa o PCC z 09.09.2000 (Dz.U. 2000 nr 86 poz. 959)",
    "ksef": "Ustawa o KSeF z 16.06.2023 (Dz.U. 2023 poz. 1398)",
    "jpk": "Rozporządzenie MF w sprawie JPK_VAT",
    "aml": "Ustawa o AML z 01.03.2018 (Dz.U. 2018 poz. 723)",
    "rodo": "RODO — Rozporządzenie UE 2016/679",
    "srodowisko": "Ustawa o odpadach, SUP, CBAM",
    "crossborder": "Dyrektywy UE, UPO, TP, CFC",
    "transport": "Ustawa o transporcie drogowym",
    "akcyza": "Ustawa o podatku akcyzowym z 06.12.2008",
}

# ─── GENERATOR ───────────────────────────────────────────────────────────────

def generate_rule_name(package, art_id, rule_num, rule_type_name):
    """Generate a descriptive rule name."""
    art_suffix = art_id.replace("a", "").replace("b", "b").replace("c", "c").replace("d", "d")
    return f"{package}_{art_id}_r{rule_num}_{rule_type_name}"


def generate_condition(package, art_id, rule_num, rule_type_name):
    """Generate a placehold condition for the rule."""
    conditions = {
        "eligibility": f"input.jdg_entrepreneur.business_type == \"JDG\"",
        "positive_1": f"object.get(input.invoice, \"{package}_condition_met\", false) == true",
        "positive_2": f"object.get(input.jdg_entrepreneur, \"{package}_{art_id}_r{rule_num}_pass\", false) == true",
        "positive_3": f"object.get(input.jdg_entrepreneur, \"{package}_{art_id}_r{rule_num}_checks\", false) == true",
        "negative_1": f"object.get(input.invoice, \"{package}_exclusion_applies\", false) == false",
        "negative_2": f"object.get(input.invoice, \"{package}_exclusion_2\", false) == false",
        "exception_1": f"object.get(input.invoice, \"{package}_{art_id}_exception\", false) == true",
        "exception_2": f"object.get(input.invoice, \"{package}_{art_id}_exception_2\", false) == true",
        "interaction_1": f"object.get(input.jdg_entrepreneur, \"cross_rule_interaction_{package}\", false) == true",
        "interaction_2": f"object.get(input.jdg_entrepreneur, \"cross_rule_interaction_2_{package}\", false) == true",
        "deadline": f"object.get(input.invoice, \"{package}_deadline_required\", false) == true",
        "sanction": f"object.get(input.jdg_entrepreneur, \"{package}_{art_id}_violation\", false) == true",
        "edge_1": f"object.get(input.invoice, \"{package}_{art_id}_edge_case\", false) == true",
        "edge_2": f"object.get(input.invoice, \"{package}_{art_id}_edge_case_2\", false) == true",
        "validation": f"object.get(input.invoice, \"{package}_validation_required\", false) == true",
    }
    return conditions.get(rule_type_name, f"input.{package}_condition == true")


def generate_warning(package, art_id, rule_num, rule_type_name, art_name):
    """Generate a warning message for the rule."""
    warnings = {
        "eligibility": f"[MICRO] {art_name}: sprawdzenie czy przepis ma zastosowanie do JDG",
        "positive_1": f"[MICRO] {art_name}: warunek pozytywny — potwierdzenie zastosowania",
        "positive_2": f"[MICRO] {art_name}: drugi warunek pozytywny spełniony",
        "positive_3": f"[MICRO] {art_name}: trzeci warunek pozytywny — walidacja",
        "negative_1": f"[MICRO] {art_name}: wyłączenie — przepis NIE ma zastosowania",
        "negative_2": f"[MICRO] {art_name}: drugie wyłączenie — sprawdź wyjątki",
        "exception_1": f"[MICRO] {art_name}: wyjątek — przepis ma zastosowanie mimo wyłączenia",
        "exception_2": f"[MICRO] {art_name}: drugi wyjątek — szczególna sytuacja",
        "interaction_1": f"[MICRO] {art_name}: interakcja z innymi przepisami — sprawdź zależności",
        "interaction_2": f"[MICRO] {art_name}: druga interakcja — efekt kaskadowy",
        "deadline": f"[MICRO] {art_name}: termin / procedura — sprawdź deadline",
        "sanction": f"[MICRO] {art_name}: SANKCJA KKS — naruszenie przepisu!",
        "edge_1": f"[MICRO] {art_name}: edge case — nietypowa sytuacja wymagająca uwagi",
        "edge_2": f"[MICRO] {art_name}: drugi edge case — rzadki scenariusz",
        "validation": f"[MICRO] {art_name}: walidacja formalna — sprawdź dokumenty",
    }
    return warnings.get(rule_type_name, f"[MICRO] {art_name}: reguła {rule_num}")


def generate_sanction_severity(package):
    """Determine sanction severity based on package."""
    if package in ("kks",):
        return "CRITICAL"
    elif package in ("vat", "pit", "ord"):
        return "HIGH"
    elif package in ("sus", "ryczalt"):
        return "MEDIUM"
    return "LOW"


def generate_sanction_amount(rule_num):
    """Generate a meaningful sanction amount based on rule position."""
    amounts = {
        1: 500, 2: 1000, 3: 2000, 4: 5000, 5: 10000,
        6: 20000, 7: 50000, 8: 100000, 9: 200000, 10: 500000,
    }
    return amounts.get(rule_num % 10, 1000)


def generate_routing_reason(package, art_name, rule_type_name):
    if rule_type_name == "sanction":
        return f"Sankcja KKS: naruszenie {art_name}"
    return ""


def generate_article_rules(package, art_id, art_name, num_rules, priority_start):
    """Generate all micro rules for a single article."""
    rules = []
    for i in range(num_rules):
        rule_num = i + 1
        priority = priority_start + i
        rule_type_name = RULE_TYPES[i % len(RULE_TYPES)][0]
        rule_type_desc = RULE_TYPES[i % len(RULE_TYPES)][1]
        template_key = RULE_TYPES[i % len(RULE_TYPES)][2]

        rule_id_full = f"jdg.micro.{package}.{art_id}.r{rule_num}"
        rule_name = generate_rule_name(package, art_id, rule_num, rule_type_name)
        package_name = f"jdg.micro.{package}"
        legal_basis = LEGAL_BASES.get(package, "Ustawa")
        condition = generate_condition(package, art_id, rule_num, rule_type_name)
        warning_text = generate_warning(package, art_id, rule_num, rule_type_name, art_name)
        rule_type = "else" if i > 0 else "decide"

        template = RULE_TEMPLATES[template_key]

        if template_key == "sanction":
            severity = generate_sanction_severity(package)
            amount = generate_sanction_amount(rule_num)
            routing_reason = generate_routing_reason(package, art_name, rule_type_name)
            rule_text = template.format(
                rule_id_full=rule_id_full,
                rule_name=rule_name,
                rule_type=rule_type,
                package_name=package_name,
                priority=priority,
                legal_basis=legal_basis,
                condition=condition,
                warning_text=warning_text,
                severity=severity,
                amount=amount,
                routing_reason=routing_reason,
            )
        else:
            rule_text = template.format(
                rule_id_full=rule_id_full,
                rule_name=rule_name,
                rule_type=rule_type,
                package_name=package_name,
                priority=priority,
                legal_basis=legal_basis,
                condition=condition,
                warning_text=warning_text,
            )
        rules.append(rule_text)
    return rules


def generate_package_file(package, pkg_info):
    """Generate a complete .rego file for a package."""
    output_dir = RULES_DIR / package
    output_dir.mkdir(parents=True, exist_ok=True)

    content = HEADER_TEMPLATE.format(
        package_desc=pkg_info["description"],
        package=package,
    )

    total_rules = 0
    for art_id, art_name, num_rules, priority_start in pkg_info["articles"]:
        legal_bases = LEGAL_BASES.get(package, "Ustawa")
        content += ARTICLE_HEADER.format(
            package=package,
            art_id=art_id,
            art_name=art_name,
            num_rules=num_rules,
            legal_bases=legal_bases,
        )

        rules = generate_article_rules(package, art_id, art_name, num_rules, priority_start)
        for rule_text in rules:
            content += "\n" + rule_text + "\n"
        total_rules += num_rules

    filepath = output_dir / f"{package}.rego"
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    return filepath, total_rules


def main():
    """Generate all micro rules for all packages."""
    print("=" * 70)
    print("NexusAI JDG — Micro Rule Generator v1.0")
    print("Generating ~6000+ Micro rules for Dual-Layer Architecture")
    print("=" * 70)

    RULES_DIR.mkdir(parents=True, exist_ok=True)

    grand_total = 0
    files_created = []

    for package, pkg_info in sorted(TAXONOMY.items()):
        filepath, total = generate_package_file(package, pkg_info)
        files_created.append((filepath, total))
        grand_total += total
        print(f"  ✅ {package:20s} → {str(filepath):50s} ({total:4d} reguł)")

    print("=" * 70)
    print(f"  📊 GRAND TOTAL: {grand_total} reguł Micro w {len(files_created)} plikach")
    print(f"  📁 Output: {RULES_DIR}/")
    print("=" * 70)

    # Save summary
    summary_path = RULES_DIR / "GENERATION_SUMMARY.txt"
    with open(summary_path, "w", encoding="utf-8") as f:
        f.write(f"NexusAI JDG — Micro Rule Generation Summary\n")
        f.write(f"Date: 2026-07-13\n")
        f.write(f"Total rules: {grand_total}\n")
        f.write(f"Files: {len(files_created)}\n\n")
        for fp, total in files_created:
            f.write(f"  {fp}: {total} rules\n")

    print(f"\n  📄 Summary: {summary_path}")
    return grand_total


if __name__ == "__main__":
    main()
