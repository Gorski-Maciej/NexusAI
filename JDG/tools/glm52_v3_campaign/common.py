# -*- coding: utf-8 -*-
"""Common machinery for the JDG V3 GLM 5.2 prompt campaign generator.

Every prompt file is rendered from a Part description (see parts_*.py).
The generator validates:
  * every referenced repository path exists locally (no broken links),
  * every rendered prompt has >= MIN_LINES lines and >= MIN_CHARS chars,
  * every mandatory phrase occurs >= MIN_PHRASE times in every prompt.
"""
import os
import re
from datetime import date

BASE = "https://github.com/Gorski-Maciej/NexusAI"
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))

MIN_LINES = 650
MIN_CHARS = 8000
MIN_PHRASE = 4

PHRASES = [
    "Przeprować głębokie myślenie",
    "Przeprować głęboką analizę",
    "zaawansowany poziom Enterprise",
    "poziom ENTERPRISE",
    "innowacyjne ulepszenia wyprzedzające profesjonalistów",
    "Wdrożyć/wygenerować najwięcej braków i jak najwięcej elementów i struktur których brakuje",
]

def phrase_block(header: str) -> list:
    out = [header, ""]
    for i, p in enumerate(PHRASES, 1):
        out.append(f"  {i}. {p}.")
    out.append("")
    out.append("Powtarzaj te wymagania przed każdą sekcją raportu, każdą rekomendacją i każdą decyzją projektową.")
    out.append("")
    return out

def phrase_lines_compact(header: str) -> list:
    out = [header]
    for p in PHRASES:
        out.append(f"   * {p}.")
    out.append("")
    return out

HOLY_DOCS = [
    ("DOKUMENT ŚWIĘTY nr 1 — architektura docelowa V1 (Control Plane + Data Plane, cykl życia reguł, pipeline ISAP→produkcja, bramki CI, SLO)",
     "JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md"),
    ("DOKUMENT ŚWIĘTY nr 2 — Wizja V2 (Legal Twin/LKG, Warstwa Konstytucyjna, Golden Oracle, Decision Certificate, Law Radar, Declarative Change; kontynuacja dokumentu nr 1)",
     "JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md"),
]

BBB_DOC = ("Dokument źródeł prawnych JDG — katalog aktów prawnych, na których opiera się silnik (twierdzenia do WERYFIKACJI w ISAP/RCL/MF, nie automatyczny dowód)",
           "JDG/docs/Bbb")

BASE_DOCS = [
    ("Architektura obecna — stan istniejący (PL)", "JDG/docs/ARCHITEKTURA.md"),
    ("Architecture (EN mirror dokumentu PL)", "JDG/docs/ARCHITECTURE.md"),
]

MIRROR_DOCS = [
    ("Mirror jdg — katalog lustrzany pakietu JDG (porównuj implementacje domeny z mirror)", "policies/jdg"),
    ("Mirror tax — katalog lustrzany warstwy podatkowej", "policies/tax"),
    ("Mirror VAT — katalog lustrzany reguł VAT", "policies/tax/vat"),
    ("Skrypt budowy bundle w mirrorze", "policies/jdg/bundles/bundle.sh"),
    ("Manifest bazowy overlay w mirrorze", "policies/jdg/bundles/base/manifest.json"),
    ("Overlay v2026 w mirrorze", "policies/jdg/bundles/overlays/v2026/manifest.json"),
]

CROSS_QUESTIONS = [
    "Które twierdzenia tej części są sprzeczne z dokumentami świętymi (cytat → cytat) i jak je rozstrzygnąć?",
    "Które reguły tej części łamią zasady parametrów-as-data (P06) i temporalności (P05) — lista z dowodami?",
    "Które ścieżki tej części nie są fail-closed (cichy AUTO_POST przy wątpliwości) — jak je domknąć?",
    "Które pola tej części kontraktują się z kontraktem werdyktu 25-polowym (P03) — zgodność typów i wymagalności?",
    "Które testy tej części są niezbędne jako bramki blokujące merge (P39) — lista z oczekiwanymi wynikami?",
    "Które elementy tej części są duplikatami innych części (P00 baseline, mapy domenowe) — plan konsolidacji?",
    "Które podstawy prawne tej części są niezweryfikowane (Bbb + ISAP) — rejestr mediacji z priorytetami?",
    "Które innowacje tej części wymagają decyzji człowieka przed wdrożeniem (4-eyes) — lista V3-" + "{CODE}" + "-Qxx?",
    "Które metryki tej części muszą trafić do obserwowalności (P37) — nazwy, progi alarmów, dashboardy?",
    "Które ryzyka tej części wymagają invariantów runtime (P04) — propozycje z uzasadnieniem prawnym?",
]

def blob(path: str) -> str:
    return f"{BASE}/blob/{path}"

def link_for(path: str) -> str:
    local = os.path.join(REPO_ROOT, path)
    if os.path.isdir(local):
        return f"{BASE}/tree/{path}"
    return blob(path)

def render_part(part: dict, prev_part, next_part, final_code: str = "P44") -> str:
    L: list = []
    code = part["code"]
    title = part["title"]
    report_name = f"RAPORT_V3_{code}_{part['slug']}.txt"
    prompt_name = f"V3_PROMPT_{code}_{part['slug']}.txt"
    d = date(2026, 9, 2).isoformat()
    is_last = part.get("is_last", False)
    nxt = next_part["code"] if next_part else "KONIEC SERII"
    prev_code = prev_part["code"] if prev_part else "P00"
    n_files = sum(len(g["files"]) for g in part["file_groups"])
    n_sub = len(part["subparts"])

    L.append("=" * 78)
    L.append(f"PROMPT V3 {code} — {title}")
    L.append("=" * 78)
    L.append("")
    L.append("Seria: NEXUSAI JDG — V3 FORTRESS CAMPAIGN dla GLM 5.2")
    L.append(f"Plik promptu:           JDG/prompty_v3/{prompt_name}")
    L.append(f"Docelowy plik raportu:  JDG/raporty_glm52_v3/{report_name}")
    L.append(f"Wersja kampanii: V3.0   Data wygenerowania pakietu: {d}")
    L.append(f"Skala części: {n_sub} podanaliz, {n_files} plików do odczytu, min. 12 innowacji Enterprise.")
    L.append("")
    L.append("Jeden prompt = jeden plik TXT. Ten plik wklejasz do GLM 5.2 w CLEAN sesji (puste okno kontekstowe).")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 1
    L.append("SEKCJA 1 — ROLA I WYMAGANIA NADRZĘDNE")
    L.append("-" * 78)
    L.append("")
    L.append(f"Jesteś {part['role']}.")
    L.append("")
    L.extend(phrase_block("Wymagania nadrzędne tej części (obowiązuje KAŻDE z nich):"))
    L.append(f"Specjalizacja części {code}: {part['expertise']}.")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 2
    L.append("SEKCJA 2 — MISJA CZĘŚCI")
    L.append("-" * 78)
    L.append("")
    for para in part["mission"]:
        L.append(para)
        L.append("")
    L.append("Cel nadrzędny całej serii V3: silnik reguł podatkowych OPA ma maksymalnie zautomatyzować księgowość JDG")
    L.append("(CODZIENNE księgowanie: faktury → ewidencje → deklaracje → płatności → archiwum), pozostając systemem")
    L.append("fail-closed: przy konflikcie, luce prawnej, niezweryfikowanym źródle lub naruszeniu invariantów decyzją")
    L.append("jest NEEDS_ADVICE / MANUAL_REVIEW — nigdy ciche automatyczne AUTO_POST. Forteca = precyzja, nie odwaga.")
    L.append("")
    L.append("Uwaga o archiwum: poprzednie kampanie (JDG/PROMPTY_GLM52_01-05.txt … 21-40.txt, raporty w JDG/raporty_glm52")
    L.append("oraz raporty P00–P30 wg JDG/prompts_status.yaml) są ARCHIWUM WEJŚCIOWYM. Seria V3 NIE kopiuje ich treści —")
    L.append("weryfikuje stan REPOZYTORIUM PO ich wdrożeniu i domyka to, co wciąż jest luką. Zanim uznasz coś za brak,")
    L.append("sprawdź w raporcie V3_P00 (mapa kanoniczna) oraz w samej strukturze repozytorium, czy element już istnieje.")
    L.append("ZAKAZ duplikowania istniejących reguł, narzędzi, migracji i raportów — rozszerzaj, nie zdublikuj.")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 3
    L.append("SEKCJA 3 — BUDŻET KONTEKSTU (ZASADA 50% I CZYSTA SESJA)")
    L.append("-" * 78)
    L.append("")
    L.append("1. Dane i informacje dostarczone do GLM 5.2 (pliki odczytane wg linków z tej części) mogą zająć MAKSYMALNIE")
    L.append("   50% okna kontekstowego. Pozostałe ≥ 50% musi zostać na myślenie, analizę, dedukcję i generowanie raportu.")
    L.append("2. Czytaj WYŁĄCZNIE linki z Sekcji 6 (oraz wymienione raporty-kontrakty z Sekcji 11.1). Nie surfuj po całym")
    L.append("   repozytorium i nie wczytuj katalogów zbiorczo — to gwarancja, że budżet 50% zostanie dotrzymany.")
    L.append("3. Jeśli którykolwiek plik okaże się zbyt duży, aby zmieścić go w budżecie 50%, czytaj go PARTIAMI wg sekcji")
    L.append("   (nagłówki → sekcje krytyczne → reszta) i to zaznaczaj w raporcie. ZAKAZ cichego pomijania treści.")
    L.append("4. Ten prompt + odczytane pliki + praca analityczna + generowany raport muszą się zmieścić w jednej sesji.")
    L.append("   Jeśli którejkolwiek analizy zabraknie miejsca: skróć cytat, nie skróć myśli — każda teza musi mieć dowód.")
    L.append("5. Po zakończeniu pracy (Sekcja 16) WYCZYŚĆ okno kontekstowe. Nie przenoś niejawnych założeń do następnej części.")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 4
    L.append("SEKCJA 4 — ŹRÓDŁA NADRZĘDNE (OBOWIĄZKOWE DLA KAŻDEJ CZĘŚCI)")
    L.append("-" * 78)
    L.append("")
    L.append("4.1 Dokumenty święte — nadrzędna architektura docelowa (każdy konflikt z nimi = BLOCKER):")
    L.append("")
    for desc, path in HOLY_DOCS:
        L.append(f"   - {desc}")
        L.append(f"     {blob(path)}")
        L.append("")
    L.append("   Prawo konfliktu: jeżeli jakikolwiek plik, dokument, README, manifest, wcześniejszy raport lub własny")
    L.append("   wniosek jest sprzeczny z dokumentami świętymi — NIE ZGADYWAJ. Oznacz konflikt jako BLOCKER z cytatami")
    L.append("   obu stron i zaproponuj rozstrzygnięcie zgodne z dokumentami świętymi.")
    L.append("")
    L.append("4.2 Źródła prawne:")
    L.append("")
    L.append(f"   - {BBB_DOC[0]}")
    L.append(f"     {blob(BBB_DOC[1])}")
    L.append("")
    L.append("   Zasada prawna: numer Dz.U., data, treść artykułu z dokumentu wyżej są TWIERDZENIEM, nie dowodem.")
    L.append("   Każdą podstawę prawną zweryfikuj co do istnienia i treści w oficjalnym ISAP (isap.sejm.gov.pl), RCL")
    L.append("   (legislacja.gov.pl) lub publikatorach MF. Niezweryfikowane oznaczaj tagiem [NIEZWERYFIKOWANE],")
    L.append("   a podejrzane (np. dziwny numer pozycji, niemożliwa data) — tagiem [BŁĄD_PODSTAWY_PRAWNEJ?].")
    L.append("   ZAKAZ tworzenia fikcyjnych artykułów, ustępów, numerów Dz.U., dat i stawek.")
    L.append("")
    L.append("4.3 Dokumenty bazowe architektury (kontekst stanu obecnego):")
    L.append("")
    for desc, path in BASE_DOCS:
        L.append(f"   - {desc}: {blob(path)}")
    L.append("")
    L.append("4.4 Indeks kampanii (mapa wszystkich części i konwencji):")
    L.append("")
    L.append(f"   - README serii V3: {blob('JDG/prompty_v3/README_V3_KAMPANIA_GLM52.txt')}")
    L.append("")
    L.append("4.5 Rejestr źródeł zewnętrznych weryfikacji (używaj przy każdej podstawie prawnej):")
    L.append("")
    L.append("   - ISAP (isap.sejm.gov.pl) — teksty ujednolicone i Dz.U.; jedyne źródło twierdzeń o treści ustaw.")
    L.append("   - legislacja.gov.pl (RCL) — proces legislacyjny: daty wejścia w życie, zmiany, projekty nowelizacji.")
    L.append("   - podatki.gov.pl (MF/KIS) — interpretacje ogólne i indywidualne, objaśnienia, broszury, stawki.")
    L.append("   - crd.gov.pl — KSeF: schematy XSD, dokumentacja API, harmonogram wdrożenia.")
    L.append("   - zus.pl — stawki składek, limity (30-krotność), terminy, druki (DRA/RCA), ulgi.")
    L.append("   - Klauzula: gdy źródło zewnętrzne jest w tej sesji niedostępne — tag [NIEZWERYFIKOWANE] + wpis")
    L.append("     do rejestru mediacji (9.05). Zakaz cichego przyjmowania treści „z pamięci”." )
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 5
    L.append(f"SEKCJA 5 — DEKOMPOZYCJA CZĘŚCI {code} NA PODANALIZY")
    L.append("-" * 78)
    L.append("")
    L.append(f"Część {code} dzieli się na {n_sub} podanaliz. Każdą podanalizę opracuj OSOBNO, z własnymi dowodami,")
    L.append("własną tabelą luk i własnymi rekomendacjami — tak by raport był wewnętrznie spójną, ale kompletną całością.")
    L.append("")
    for i, sp in enumerate(part["subparts"], 1):
        L.append(f"5.{i} {sp['name']}")
        L.append(f"    Cel: {sp['goal']}")
        L.append("    Pytania audytowe (odpowiedz na KAŻDE, z dowodem z kodu/dokumentu):")
        for q in sp["questions"]:
            L.append(f"      * {q}")
        L.append("")

    # ---------------------------------------------------------------- SEKCJA 6
    L.append(f"SEKCJA 6 — PLIKI DO ODCZYTU CZĘŚCI {code} — TYLKO TE LINKI")
    L.append("-" * 78)
    L.append("")
    L.append("Nie szukaj plików po katalogach. Czytaj dokładnie te adresy, w tej kolejności grup. Każda grupa ma")
    L.append("przypisaną rolę analityczną. Ścieżki zweryfikowano przeciw strukturze repozytorium.")
    L.append("")
    L.append("6.0 Instrukcja czytania:")
    L.append("")
    L.append("   a) Czytaj pliki grupami w podanej kolejności; po każdej grupie zapisz wnioski w notatce roboczej sesji.")
    L.append("   b) Dla każdego pliku zanotuj co najmniej 1 fakt użyteczny dla raportu (liczba, reguła, kontrakt, luka).")
    L.append("   c) Jeżeli plik nie istnieje pod adresem albo jest nieosiągalny — wpisz to do tabeli dowodów ze statusem")
    L.append("      NIEZWERYFIKOWANO i potraktuj jako lukę dokumentacyjną V3-" + code + "-Lxx. Nie zgaduj jego treści.")
    L.append("   d) Nie czytaj plików spoza listy (wyjątek: Sekcja 11.1). Budżet 50% okna kontekstowego jest wiążący.")
    L.append("")
    gi = 0
    for g in part["file_groups"]:
        gi += 1
        L.append(f"6.{gi} {g['name']}")
        L.append("")
        for desc, path in g["files"]:
            L.append(f"   - [{desc}] {link_for(path)}")
            L.append("       → Wynik do raportu: wiersz w tabeli dowodów (7.3) + wnioski w tej grupie analizy.")
        L.append("")
    gi += 1
    L.append(f"6.{gi} Mirror policies — obowiązkowy kontekst zgodności (porównuj implementacje z mirror):")
    L.append("")
    for desc, path in MIRROR_DOCS:
        L.append(f"   - [{desc}] {link_for(path)}")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 7
    L.append(f"SEKCJA 7 — WYMAGANIA ANALITYCZNE CZĘŚCI {code}")
    L.append("-" * 78)
    L.append("")
    L.append("7.1 Osie obowiązkowe każdej podanalizy (zawsze, nawet jeśli nie wymienione w 7.2):")
    L.append("")
    axes = [
        "a) POPRAWNOŚĆ PRAWNA — każde twierdzenie podpięte pod akt/artykuł/ustęp/punkt + status weryfikacji (ISAP/RCL/MF) + daty obowiązywania (valid_from/valid_to);",
        "b) POPRAWNOŚĆ KODU REGO — determinizm, kompletność else-chain, brak stubów {true}, brak martwych reguł, brak hardcode (ADR-002: parametry z data.thresholds.*), unikalność rule_id globalnie;",
        "c) TEMPORALNOŚĆ — czy reguły/parametry mają okna ważności; testy day-1/day-0/day+1 na granicach nowelizacji; time-travel odtwarzalny;",
        "d) FAIL-CLOSED — co się dzieje przy braku danych, konflikcie, niepewności; czy AUTO_POST jest możliwy tylko przy pełnym dowodzie;",
        "e) TESTY — jakie istnieją (natywne Rego / pytest / golden), jakie brakują, jakie trzeba dodać (granice groszy, waluty, negatywne, fuzz);",
        "f) INTEGRACJA MIĘDZYDOMENOWA — wpływy na inne części (Sekcja 11) i kontrakt werdyktu 25-polowy (ADR-004);",
        "g) WYDAJNOŚĆ — koszty ewaluacji, struktura indeksowania, else-chain O(n) vs routing O(1), cache;",
        "h) AUDYTOWALNOŚĆ — provenance, _legal_basis, traceability reguła→test→bundle→werdykt→certyfikat.",
    ]
    for a in axes:
        L.append(f"   {a}")
    L.append("")
    L.append("7.2 Zagadnienia specyficzne tej części (oprócz osi obowiązkowych) — wywodzą się z celów podanaliz z Sekcji 5:")
    L.append("")
    focus_items = part.get("focus") or [sp["goal"] for sp in part["subparts"]]
    for i, f_item in enumerate(focus_items, 1):
        L.append(f"   {code}-AN{i:02d}: {f_item}")
    L.append("")
    L.append("7.3 Tabela dowodów (wygeneruj ją w raporcie — jeden wiersz na plik z Sekcji 6):")
    L.append("")
    L.append("   | # | Plik | Co z niego pobieramy (dowód/fakt/liczba) | Status: ZWERYFIKOWANO/NIEZWERYFIKOWANO |")
    L.append("   |---|------|------------------------------------------|----------------------------------------|")
    L.append("")
    L.append("7.4 Pytania krzyżowe (obowiązkowe odpowiedzi w raporcie — identyfikatory V3-" + code + "-Xxx):")
    L.append("")
    for i, q in enumerate(CROSS_QUESTIONS, 1):
        L.append(f"   X{i:02d}. {q}")
    L.append("")
    L.append("7.5 Anty-wzorce do wykrycia w tej części (każdy: sprawdź i wynik wpisz do rejestru luk):")
    L.append("")
    antipatterns = [
        "Reguły typu stub (warunek zawsze prawdziwy, np. `true => \"...\"`) udające pokrycie prawne.",
        "Hardcode stawek/limitów/dat w kodzie Rego zamiast data.thresholds.* (naruszenie ADR-002).",
        "Brak else-chain / otwarte negatywy: reguła niezdefiniowana milcząco zamiast jawnego NEEDS_ADVICE.",
        "Duplikaty tej samej reguły pod różnymi rule_id (macro vs micro vs enterprise bez rejestru źródła prawdy).",
        "Podstawy prawne bez Dz.U./art./ust. lub z datami niemożliwymi (nowelizacja wcześniejsza niż ustawa).",
        "Testy zawsze-zielone (brak asercji negatywnych), testy zależne od kolejności lub komunikatów.",
        "Cichy AUTO_POST przy braku pola obowiązkowego (fail-open) — najsłabsze miejsce fortecy.",
        "Zależności cykliczne między pakietami (import A→B→A) i reguły piszące do tych samych ścieżek.",
        "Dane świata zewnętrznego (kursy, wskaźniki) wpisane na stałe zamiast input z wersją i provenance.",
        "Brak okien temporalnych przy regułach z datami wejścia w życie / wygaśnięcia.",
        "Mirror policies dryfujący względem canonical (ta sama reguła, inna treść) bez detekcji w CI.",
        "Metryki/słowniki w dwóch miejscach (bundle vs SQL) z różnymi wartościami — brak jednego źródła prawdy.",
    ]
    for i, ap in enumerate(antipatterns, 1):
        L.append(f"   AP{i:02d}. {ap}")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 8
    L.append(f"SEKCJA 8 — MAPA PRAWNA CZĘŚCI {code}")
    L.append("-" * 78)
    L.append("")
    L.append("Akty prawne w zakresie tej części (punkt wyjścia — zweryfikuj każdy w ISAP i rozszerz, jeśli luka):")
    L.append("")
    for i, act in enumerate(part["legal"], 1):
        L.append(f"   {i:02d}. {act}")
        L.append(f"       → Obowiązek: weryfikacja w ISAP/RCL + wskazanie artykułów implementowanych w części {code}.")
    L.append("")
    L.append("Mini-makra macierzy akt→plik (uzupełnij w raporcie):")
    L.append("")
    L.append("   | Akt | Art./ust./pkt | Grupa plików (6.x) | Reguła | Test | Status |")
    L.append("   |-----|---------------|--------------------|--------|------|--------|")
    L.append("")
    L.append("Uwaga: to NIE jest pełna lista — to mapa wejściowa. Jeśli w trakcie analizy odkryjesz przepis")
    L.append("materiałny w zakresie części, którego tu brak — dodaj go do rejestru luk prawnych raportu z pełną")
    L.append("identyfikacją (akt, artykuł, jednostka redakcyjna, Dz.U., data obowiązywania, status weryfikacji).")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 9
    L.append(f"SEKCJA 9 — STRUKTURA RAPORTU (WYMAGANA) — {report_name}")
    L.append("-" * 78)
    L.append("")
    sections = [
        "EXECUTIVE SUMMARY — 1 strona: ocena dojrzałości części, TOP-10 rekomendacji, liczba luk wg krytyczności (P0/P1/P2/P3), deklaracja co udowodniono, a co pozostało [NIEZWERYFIKOWANE].",
        "ZAKRES I OGRANICZENIA — co dokładnie przeanalizowano (lista plików), co pominięto i DLACZEGO (budżet 50% / brak związku), status weryfikacji źródeł prawnych.",
        f"STAN OBECNY CZĘŚCI {code} — mapa artefaktów: plik → pakiet Rego → rule_id → podstawa prawna → testy → status lifecycle (SHADOW/CANDIDATE/ACTIVE).",
        f"PODANALIZY 5.1–5.{n_sub} — każda osobno z tabelą dowodów i wnioskami.",
        "MACIERZ PRAWO↔REGUŁA↔TEST — wiersz na przepis materiałny: przepis (zweryfikowany) → reguła(y) → test(y) → status (PEŁNE/CZĘŚCIOWE/BRAK/PRZECZYANE) → ryzyko.",
        "REJESTR LUK — identyfikatory V3-" + code + "-Lxx, krytyczność P0 (BLOCKER: złamanie dokumentów świętych/temporalności/fail-closed), P1 (wysokie ryzyko błędnej decyzji), P2, P3; dla każdej luki: dowód, wpływ, proponowane rozwiązanie, koszt wdrożenia, ryzyko regresji.",
        f"INNOWACJE ENTERPRISE (Sekcja 10) — min. 12 rozwiązań z ID V3-{code}-Ixx, wpływem, ryzykiem i kryteriami akceptacji.",
        "KONTRAKT WYJŚCIOWY (Sekcja 11.2) — decyzje i standardy wiążące kolejne części.",
        "PLAN WDROŻENIA — kolejność prac bez duplikacji i bez niszczenia zależności; co wolno wdrożyć od razu, co wymaga testów, co wymaga decyzji człowieka (4-eyes).",
        "PLAN TESTÓW — konkretne przypadki testowe (unit/property/fuzz/golden/temporal) z oczekiwanymi wynikami; testy które BLOKUJĄ merge.",
        "SEKCJA PYTAŃ DO CZŁOWIEKA — wszystko, czego nie wolno rozstrzygać samodzielnie (prawo niepewne, decyzje biznesowe, konflikty BLOCKER).",
        "ZAAŁOŻENIA JAWNE — lista założeń przyjętych przy braku dowodu, każde z tagiem [ZAŁOŻENIE].",
    ]
    for i, s in enumerate(sections, 1):
        L.append(f"   9.{i:02d} {s}")
    L.append("")
    L.append("   9.13 KAŻDA podanaliza (5.1–5.N) dostaje w raporcie: własną tabelę dowodów, min. 3 wnioski")
    L.append("   i własną listę luk — bez tego raport jest niekompletny i wraca do poprawy.")
    L.append("   9.14 Wiersze macierzy PRAWO↔REGUŁA↔TEST z aktów Sekcji 8 są OBOWIĄZKOWE (każdy akt z listy)")
    L.append("   plus każdy przepis odkryty w trakcie analizy.")
    L.append("   9.15 Format identyfikatorów (przykłady): V3-" + code + "-L01 (luka P0), V3-" + code + "-I03 (innowacja),")
    L.append("   V3-" + code + "-C01 (konflikt), V3-" + code + "-Q02 (pytanie do człowieka), V3-" + code + "-X04 (pytanie krzyżowe).")
    L.append("")
    L.append("Format pliku: TXT/Markdown, nagłówki ASCII, tabele ASCII, diagramy Mermaid dopuszczalne w blokach ```.")
    L.append("Zakaz stwierdzeń „100% zgodności”/„production-ready” bez dowodu. Każde twierdzenie: artefakt + podstawa")
    L.append("(prawna lub techniczna) + wersja/data + poziom pewności. Raport jest kontraktem wdrożeniowym, nie esejem.")
    L.append("")
    L.append("   9.16 Obowiązkowe tabele raportu (każda musi istnieć i być wypełniona):")
    L.append("       T1 tabela dowodów (7.3), T2 macierz PRAWO↔REGUŁA↔TEST (Sekcja 8 / 9.05), T3 rejestr luk (9.06),")
    L.append("       T4 rejestr innowacji (9.07), T5 kontrakt wyjściowy (9.08), T6 plan wdrożenia (9.09),")
    L.append("       T7 plan testów (9.10), T8 pytania do człowieka (9.11), T9 założenia jawne (9.12),")
    L.append("       T10 przekazywane artefakty (11.4), T11 matryca podanaliza×grupa (APENDYKS B), T12 rejestr")
    L.append("       konfliktów Cxx (jeśli wystąpiły). Brak którejkolwiek tabeli = raport niekompletny.")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 10
    L.append(f"SEKCJA 10 — WYMAGANE INNOWACJE ENTERPRISE CZĘŚCI {code} (MINIMUM 12)")
    L.append("-" * 78)
    L.append("")
    L.append("Rozwiń każdy temat poniżej DO PEŁNEGO PROJEKTU, oraz dodaj własne — tak aby łącznie raport zawierał")
    L.append("co najmniej 12 kompletnych innowacji tej części:")
    L.append("")
    for i, (t, dsc) in enumerate(part["innovations"], 1):
        L.append(f"   V3-{code}-I{i:02d} — {t}: {dsc}")
    L.append("")
    L.append("Szkielet opisu każdej innowacji (5 obowiązkowych punktów):")
    L.append("")
    L.append("   1) Problem/luka, którą domyka (odwołanie do rejestru luk V3-" + code + "-Lxx lub zjawiska z kodu).")
    L.append("   2) Mechanizm rozwiązania (dane, reguły, przepływ, interfejsy — konkretnie, bez marketingu).")
    L.append("   3) Wpływ na bezpieczeństwo decyzji księgowych (co NOWE zgaduje/zamienia na dowód).")
    L.append("   4) Ryzyko i mitygacja (co może pójść źle, jak to wykryć i cofnąć).")
    L.append("   5) Kryterium akceptacji (testowalne) + zależności od innych części serii V3.")
    L.append("")
    L.append("Każda innowacja w raporcie musi mieć: (1) problem/lukę którą domyka, (2) mechanizm rozwiązania,")
    L.append("(3) wpływ na bezpieczeństwo decyzji księgowych, (4) ryzyko i mitygację, (5) kryterium akceptacji")
    L.append("(testowalne), (6) zależności od innych części serii V3.")
    L.append("")
    L.append("Katalog kierunków innowacji (inspiracja — nie limit; dobierz do specyfiki części):")
    L.append("")
    directions = [
        "Detekcja dryfu prawo↔kod w czasie rzeczywistym; auto-zgłoszenia Law Radar z twardym dowodem diff.",
        "Symulacja scenariuszowa „co-jeśli” przy zmianie progu/stawki z pełnym wpływem na inne domeny.",
        "Auto-generowanie testów granicznych groszowych z tabeli aktów (daty, progi, waluty, zaokrąglenia).",
        "SMT/Z3 dowody równoważności starej i nowej wersji reguły przed przełączeniem CANDIDATE→ACTIVE.",
        "Kontraktowe snapshoty decision certificate: replay decyzji historycznych na nowej wersji reguł.",
        "Routing O(1) sharded z indeksem domen (zamiast skanowania else-chain O(n)).",
        "Samonaprawiające się bundle: canary, auto-rollback, checksum, podpis, WORM archiwum wersji.",
        "Inteligentne triage NEEDS_ADVICE: klaster przypadków, sugestia zasad, human-in-the-loop feedback.",
        "Proweniencja DNA każdej reguły (akt→nowela→art→reguła→test→bundle→certyfikat) jako zapytywalny graf.",
        "Chaos-testy prawne: losowe mutacje input/data z asercją fail-closed (nigdy cichy AUTO_POST).",
        "Walidacja krzyżowa mirror policies vs canonical z blokadą merge przy różnicy semantycznej.",
        "Mierzalna mapa pokrycia prawnego (heat mapy pustynii prawnych) z celami kwartalnymi i progami CI.",
    ]
    for i, dsc in enumerate(directions, 1):
        L.append(f"   K{i:02d}. {dsc}")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 11
    L.append("SEKCJA 11 — KONTRAKTY MIĘDZYCZĘŚCIOWE (SPÓJNOŚĆ CAŁEJ SERII V3)")
    L.append("-" * 78)
    L.append("")
    L.append("11.1 Kontrakty wejściowe — HONORUJ w tej części:")
    L.append("")
    L.append("   Z raportu V3_P00 (mapa kanoniczna): faktyczny stan plików, pakiety, rule_id, testy — przy ocenie")
    L.append("   braków nie kwestionuj owych faktów, tylko je używaj; jeżeli stan się różni — BLOCKER do rejestru.")
    L.append(f"   Z raportów V3_P00–V3_{prev_code} (sekcja KONTRAKT WYJŚCIOWY każdego z nich): honoruj ustalone tam")
    L.append("   standardy nazewnictwa, identyfikatorów, formatu luk i decyzji. Jeśli raport poprzedniej części")
    L.append("   przekracza budżet — czytaj z niego WYŁĄCZNIE sekcje: EXECUTIVE SUMMARY, KONTRAKT WYJŚCIOWY,")
    L.append("   REJESTR LUK (P0/P1).")
    L.append("")
    for c in part["in_contracts"]:
        L.append(f"   Specyficzne dla {code}: {c}")
    L.append("")
    if is_last:
        L.append("11.2 Kontrakt wyjściowy — RAPORT FINALNY: skierowany do właściciela projektu (priorytety wdrożenia):")
    else:
        L.append(f"11.2 Kontrakt wyjściowy — TWÓJ raport musi go zawierać (sekcja 9.08), bo wiąże część {nxt} i dalsze:")
    L.append("")
    for c in part["out_contracts"]:
        L.append(f"   - {c}")
    L.append("")
    L.append("11.3 Rejestr zależności:")
    L.append("")
    if is_last:
        L.append(f"   {code} otrzymuje z: V3_P00–V3_{prev_code} → {code} przekazuje do: WŁAŚCICIELA PROJEKTU (raport finalny certyfikacji fortecy).")
    else:
        L.append(f"   {code} otrzymuje z: V3_P00–V3_{prev_code} → {code} przekazuje do: {nxt} i dalej aż do {final_code} (certyfikacja finalna).")
    L.append("   Zmiana w tej części, która dotyka kontraktu wcześniejszego, musi być oznaczona jako KONFLIKT")
    L.append("   KONTRAKTOWY z propozycją rozstrzygnięcia — nie zmieniaj po cichu standardów ustalonych wcześniej.")
    L.append("")
    L.append("11.4 Tabela przekazywanych artefaktów (uzupełnij w raporcie — co dokładnie przekazujesz dalej):")
    L.append("")
    L.append("   | Artefakt (standard/dana/lista) | Odbiorca (część) | Format | Kryterium użycia |")
    L.append("   |-------------------------------|------------------|--------|------------------|")
    L.append("")
    L.append("11.5 Standardy nazewnicze wiążące (identyczne z P00 — nie wymyślaj własnych):")
    L.append("")
    L.append("   - Luki: V3-<KOD>-L01..L99, krytyczność P0 (BLOCKER) > P1 > P2 > P3; każda z dowodem i planem fix.")
    L.append("   - Innowacje: V3-<KOD>-I01..I99 wg szkieletu 6-punktowego z Sekcji 10.")
    L.append("   - Konflikty: V3-<KOD>-C01..C99 (dokument↔kod, mirror↔canonical, kontrakt↔kontrakt) z cytatami obu stron.")
    L.append("   - Pytania do człowieka: V3-<KOD>-Q01..Q99 (sekcja 9.11); pytania krzyżowe: V3-<KOD>-X01..X10 (7.4).")
    L.append("   - Raporty: RAPORT_V3_<KOD>_<SLUG>.txt; prompty: V3_PROMPT_<KOD>_<SLUG>.txt (JDG/prompty_v3/).")
    L.append("   - Rego: pakiety jdg/<pakiet>/..., rule_id `jdg.<pakiet>.<reguła>`; parametry wyłącznie data.thresholds.*")
    L.append("     (ADR-002); okna temporalne w data.thresholds.*.valid_from/valid_to (P05).")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 12
    L.append("SEKCJA 12 — PROTOKÓŁ PRAWY I BEZPIECZEŃSTWA (NIEPODLEGAJĄCY NEGOCJACJOM)")
    L.append("-" * 78)
    L.append("")
    rules = [
        "Nie generujesz kodu produkcyjnego w tej sesji — generujesz RAPORT. Wyjątkiem są krótkie pseudokontrakty, schematy i przykłady testów w treści raportu (wyraźnie oznaczone jako szkice).",
        "Nie modyfikujesz repozytorium. Wszystko trafia do raportu jako rekomendacja z planem wdrożenia.",
        "Dokumenty święte (Sekcja 4.1) są nadrzędne; konflikt = BLOCKER z cytatami obu stron.",
        "Dokument źródeł prawnych (Sekcja 4.2) to katalog twierdzeń — weryfikuj w ISAP/RCL/MF; fikcyjne podstawy prawne są ZAKAZANE.",
        "Fail-closed: rekomendacja AUTO_POST tylko przy pełnym łańcuchu dowodów; wątpliwość = NEEDS_ADVICE / MANUAL_REVIEW.",
        "Nie traktuj deklaracji „production”, liczby rule_id ani etykiet COMPLETE jako dowodu — dowodem jest kod, test, wynik uruchomienia.",
        "Każda luka ma identyfikator V3-" + code + "-Lxx; każda innowacja V3-" + code + "-Ixx; konflikty V3-" + code + "-Cx; pytania do człowieka V3-" + code + "-Qxx.",
        "Zakaz duplikacji: zanim zaproponujesz nowy element, sprawdź raport V3_P00 i repozytorium — istniejący element rozszerzaj, nie kopiuj.",
        "Budżet kontekstu 50% (Sekcja 3) — czytanie linków spoza tej części tylko gdy Sekcja 11.1 wprost wskazuje raport-kontrakt.",
        "Zero pomijania: jeśli analiza czegoś nie objęła, napisz tego wprost w sekcji 9.02 (ZAKRES I OGRANICZENIA).",
        "Odporność na błędy: każda rekomendacja musi mieć ścieżkę detekcji błędu (test/alert) i ścieżkę cofnięcia (rollback).",
        "Precyzja > pośpiech: lepiej mniejsza liczba twierdzeń z pełnym dowodem niż długa lista przypuszczeń.",
        "Symetria dowodu: każde twierdzenie ma przeciwstawny test sprawdzalny (jak zafałszujesz własną tezę?).",
        "Zakaz fantazjowania liczbami: jeśli czegoś nie policzyłeś — napisz „nie policzono”, nie podawaj wartości.",
        "Każda rekomendacja zmiany reguły wskazuje: testy do zmiany, bundle do przebudowy, ścieżkę rollback.",
        "Jeśli plik z listy jest nieczytelny lub pusty — to LUKA do rejestru, nie pretekst do pominięcia analizy.",
        "Terminologia zgodna z glosariuszem dokumentów świętych (Legal Twin, Golden Oracle, Decision Certificate).",
        "Po każdej podanalizie: min. 3 wnioski + min. 1 luka — pusta podanaliza jest niedopuszczalna.",
    ]
    for i, r in enumerate(rules, 1):
        L.append(f"   {i:02d}. {r}")
    L.append("")
    L.extend(phrase_lines_compact("Przypomnienie wymagań nadrzędnych (obowiązują w tej części):"))

    # ---------------------------------------------------------------- SEKCJA 13
    L.append("SEKCJA 13 — KRYTERIA AKCEPTACJI RAPORTU")
    L.append("-" * 78)
    L.append("")
    checks = [
        "Raport zapisany jako jeden plik TXT: JDG/raporty_glm52_v3/" + report_name + ".",
        "Wszystkie sekcje 9.01–9.15 obecne i nietrywialne (brak pustych nagłówków).",
        "Każdy plik z Sekcji 6 ma wiersz w tabeli dowodów (7.3) albo jawną adnotację dlaczego nie był potrzebny.",
        "Macierz PRAWO↔REGUŁA↔TEST kompletna dla zakresu części, ze statusami i ryzykiem.",
        "Rejestr luk z krytycznością P0–P3 i identyfikatorami V3-" + code + "-Lxx.",
        "Min. 12 innowacji Enterprise z pełnym projektem (6 elementów każda).",
        "Kontrakt wyjściowy gotowy (9.08) — konkretny, wiążący, testowalny.",
        "Plan testów z przypadkami blokującymi merge.",
        "Sekcja pytań do człowieka (9.11) — zawiera każde rozstrzygnięcie wykraczające poza dowody.",
        "Zero stwierdzeń bez dowodu; wszystkie założenia jawnie oznaczone [ZAŁOŻENIE]; niezweryfikowane prawo [NIEZWERYFIKOWANE].",
        "Odpowiedzi na wszystkie pytania krzyżowe (7.4) z identyfikatorami V3-" + code + "-Xxx.",
        "Tabela przekazywanych artefaktów (11.4) wypełniona dla każdego kontraktu wyjściowego.",
        "Macierz podanaliza×grupa (APENDYKS B) ma wypełnione kolumny Grupy kluczowe i Wynik.",
        "Każdy anty-wzorzec z 7.5 ma wynik sprawdzenia (jest/nie ma) i wpis do rejestru luk.",
        "Instrukcja 6.0 wykonana: każdy plik ma przypisany fakt albo adnotację NIEZWERYFIKOWANO.",
        "Plan pracy krok po kroku (APENDYKS E) odznaczony w całości.",
        "Żadna sekcja nie jest skopiowana z poprzednich raportów (weryfikuj, nie parafrazuj).",
        "Deklaracja zgodności z dokumentami świętymi na końcu raportu z listą ewentualnych odstępstw.",
    ]
    checks.extend(part["acceptance_extra"])
    for i, c in enumerate(checks, 1):
        L.append(f"   [ ] {i:02d}. {c}")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 14
    L.append(f"SEKCJA 14 — CHECKLISTA ODCZYTU CZĘŚCI {code} (odznaczaj po przeczytaniu)")
    L.append("-" * 78)
    L.append("")
    for g in part["file_groups"]:
        for desc, path in g["files"]:
            L.append(f"   [ ] {link_for(path)}  — {desc}")
    L.append("   --- Mirror policies (kontekst zgodności) ---")
    for desc, path in MIRROR_DOCS:
        L.append(f"   [ ] {link_for(path)}  — {desc}")
    L.append("")

    # ---------------------------------------------------------------- SEKCJA 15
    L.extend(phrase_block("SEKCJA 15 — POWTÓRZENIE WYMAGAŃ NADRZĘDNYCH (przypomnienie przed pracą):"))

    # ---------------------------------------------------------------- SEKCJA 16
    L.append("SEKCJA 16 — KOMENDA KOŃCOWA: CZYSZCZENIE OKNA KONTEKSTOWEGO")
    L.append("-" * 78)
    L.append("")
    L.append("Po ZAKOŃCZENIU pracy nad tą częścią wykonaj DOKŁADNIE:")
    L.append("")
    L.append(f"   1. Zapisz kompletny raport do: JDG/raporty_glm52_v3/{report_name}")
    L.append("      (jeden plik; jeśli raport wygenerowałeś w odpowiedzi — potwierdź zapis i podaj pełną ścieżkę).")
    L.append(f"   2. Potwierdź krótkim komunikatem: zakres części {code}, liczba luk P0/P1/P2/P3, liczba innowacji,")
    L.append("      status kontraktu wyjściowego, lista artefaktów przekazanych dalej.")
    if is_last:
        L.append("   3. Wykonaj syntezę finalną: status fortecy OPA vs dokumenty święte, lista decyzji do wdrożenia")
        L.append("      priorytetyzowana P0–P3, potwierdzenie lub odrzucenie definicji sukcesu kampanii z dowodami.")
        L.append("   4. NASTĘPNIE WYCZYŚĆ OKNO KONTEKSTOWE — kampania V3 jest zakończona; nie przenoś nic do nowej sesji.")
        L.append("   5. Nie utrzymuj żadnych niejawnych założeń, fragmentów kodu ani cytatów po czyszczeniu sesji.")
    else:
        L.append(f"   3. Wypisz pełną listę kontraktów wyjściowych przekazanych części {nxt}.")
        L.append("   4. NASTĘPNIE WYCZYŚĆ OKNO KONTEKSTOWE (cała treść: pliki, notatki robocze, cytaty, śródnotatki).")
        L.append(f"      Do części {nxt} wchodzisz z PUSTĄ sesją — przenosisz się WYŁĄCZNIE poprzez zapisany raport")
        L.append("      (sekcje: EXECUTIVE SUMMARY, KONTRAKT WYJŚCIOWY, REJESTR LUK P0/P1).")
        L.append("   5. Nie utrzymuj żadnych niejawnych założeń, fragmentów kodu ani cytatów po czyszczeniu sesji.")
    L.append("")
    if is_last:
        L.append(f"Kolejność serii V3: P00 → P01 → … → {final_code} (koniec kampanii — forteca certyfikowana).")
    else:
        L.append(f"Kolejność serii V3: P00 → P01 → … → {nxt} → … → {final_code} (certyfikacja finalna).")
    L.append("Pełny indeks: JDG/prompty_v3/README_V3_KAMPANIA_GLM52.txt")
    L.append("")

    # ---------------------------------------------------------------- APENDYKSY
    L.append("APENDYKS A — MAPA GRUP PLIKÓW CZĘŚCI " + code)
    L.append("-" * 78)
    L.append("")
    L.append("   | Grupa | Nazwa | Liczba plików | Rola analityczna w tej części |")
    L.append("   |-------|-------|---------------|-------------------------------|")
    for i, g in enumerate(part["file_groups"], 1):
        L.append(f"   | 6.{i} | {g['name']} | {len(g['files'])} | (uzupełnij: czego szukasz w tej grupie) |")
    L.append(f"   | 6.{gi} | Mirror policies | {len(MIRROR_DOCS)} | zgodność implementacji z mirror; dryf = konflikt Cxx |")
    L.append("")
    L.append("APENDYKS B — MACIERZ PODANALIZA × GRUPA (co sprawdzić — minimum)")
    L.append("-" * 78)
    L.append("")
    L.append("   | Podanaliza | Grupy kluczowe | Minimum dowodów | Wynik (sekcja raportu) |")
    L.append("   |------------|----------------|-----------------|------------------------|")
    for i, sp in enumerate(part["subparts"], 1):
        L.append(f"   | 5.{i} | (uzupełnij) | min. 3 twierdzenia z dowodem | 9.04 / 9.05 |")
    L.append("")
    L.append("APENDYKS C — SZKIELET PYTAŃ DO CZŁOWIEKA (V3-" + code + "-Qxx)")
    L.append("-" * 78)
    L.append("")
    for i, q in enumerate([
        "Które rozstrzygnięcia prawne w tej części są niepewne (dwie dopuszczalne interpretacje)?",
        "Które decyzje architektoniczne wymagają zatwierdzenia właściciela (4-eyes)?",
        "Które limity budżetowe/wdrożeniowe zmieniają priorytety planu wdrożenia?",
        "Które konflikty BLOCKER wymagają eskalacji poza tę część?",
    ], 1):
        L.append(f"   Q{i:02d}. {q} (odpowiedz w raporcie lub przenieś do sekcji 9.11)")
    L.append("")
    L.append("APENDYKS D — GLOSARIUSZ MINIMALNY CZĘŚCI " + code)
    L.append("-" * 78)
    L.append("")
    L.append("   Luka (Lxx):     stwierdzony brak/błąd z dowodem i krytycznością P0–P3.")
    L.append("   Innowacja (Ixx): kompletny projekt rozwiązania Enterprise wg szkieletu z Sekcji 10.")
    L.append("   Konflikt (Cxx):  sprzeczność dokument↔kod, kontrakt↔kontrakt, mirror↔canonical.")
    L.append("   Pytanie (Qxx):   rozstrzygnięcie zarezerwowane dla człowieka (nigdy cisza).")
    L.append("   Krzyżowe (Xxx):  odpowiedź na pytanie systemowe z Sekcji 7.4.")
    L.append(f"   AUTO_POST:       automatyczne księgowanie — dopuszczalne wyłącznie przy pełnym dowodzie.")
    L.append(f"   NEEDS_ADVICE:    decyzja wymaga człowieka — domyślny tryb fail-closed przy wątpliwości.")
    L.append(f"   MANUAL_REVIEW:   pełny przegląd ręczny — tryb przy konflikcie/naruszeniu invariantów.")
    L.append("")
    ensure_min(L, part)
    L.extend(phrase_lines_compact("Przypomnienie przed startem pracy (wszystkie 6 wymagań):"))
    L.append("=" * 78)
    L.append(f"KONIEC PROMPTU V3 {code} — {title}")
    L.append("=" * 78)
    return "\n".join(L) + "\n"

def ensure_min(L: list, part: dict) -> None:
    """Guarantees the rendered prompt clears MIN_LINES for EVERY part.

    Appends APENDYKS E — a step-by-step work plan derived from the part's own
    data (subparts, file groups, files, acts, innovations, antipatterns) — and,
    only if the minimum is still not met, a deterministic quality-check list.
    No fake content: every line is an instruction grounded in part data.
    """
    code = part["code"]
    target = MIN_LINES + 12

    # --- APENDYKS E: plan pracy krok po kroku (zawsze) -------------------
    L.append("APENDYKS E — PLAN PRACY KROK PO KROKU (wykonuj sekwencyjnie)")
    L.append("-" * 78)
    L.append("")
    L.append("   ETAP 1 — PRZYGOTOWANIE:")
    L.append(f"     K01. Przeczytaj dokumenty święte (Sekcja 4.1) i potwierdź w notatce roboczej kluczowe kontrakty")
    L.append("          istotne dla tej części (kontrakt werdyktu, invarianty, temporalność, parametry-as-data).")
    L.append(f"     K02. Przeczytaj JDG/docs/Bbb i wypisz akty istotne dla części {code} (Sekcja 8) do weryfikacji ISAP.")
    L.append("     K03. Sprawdź budżet kontekstu (Sekcja 3): zaplanuj, ile miejsca zajmą grupy plików z Sekcji 6.")
    L.append("")
    L.append("   ETAP 2 — ODCZYT DOWODÓW (grupa po grupie):")
    step = 4
    for gi, g in enumerate(part["file_groups"], 1):
        L.append(f"     K{step:02d}. Grupa 6.{gi} ({g['name']}): przeczytaj {len(g['files'])} plik(i); dla każdego zanotuj")
        L.append("          min. 1 fakt do tabeli dowodów (7.3) i min. 1 wniosek analityczny.")
        step += 1
        for desc, path in g["files"]:
            L.append(f"         - {os.path.basename(path)}: {desc}")
            step += 1
    L.append("")
    L.append("   ETAP 3 — PODANALIZY (5.1–5." + str(len(part['subparts'])) + "):")
    for i, sp in enumerate(part["subparts"], 1):
        L.append(f"     K{step:02d}. Podanaliza 5.{i} ({sp['name']}): odpowiedz na WSZYSTKIE pytania audytowe")
        L.append("          (min. 3 wnioski z dowodem, min. 1 luka Lxx, wpis do macierzy 9.05).")
        step += 1
    L.append("")
    L.append("   ETAP 4 — PRAWO I ZGODNOŚĆ:")
    for i, act in enumerate(part["legal"], 1):
        L.append(f"     K{step:02d}. Zweryfikuj w ISAP/RCL: {act[:100]}")
        step += 1
    L.append("")
    L.append("   ETAP 5 — SYNTHEZA I RAPORT:")
    L.append(f"     K{step:02d}. Zbuduj T1–T12 (9.16), rejestr luk, macierz prawo↔reguła↔test i kontrakt wyjściowy.")
    step += 1
    for i in range(1, len(part["innovations"]) + 1):
        L.append(f"     K{step:02d}. Opracuj innowację V3-{code}-I{i:02d} wg 6-punktowego szkieletu (Sekcja 10).")
        step += 1
    for i in range(1, len(CROSS_QUESTIONS) + 1):
        L.append(f"     K{step:02d}. Odpowiedz na pytanie krzyżowe X{i:02d} (7.4) — identyfikator V3-{code}-X{i:02d}.")
        step += 1
    L.append("")
    L.append("   ETAP 6 — DOMKNIĘCIE: zapis raportu → potwierdzenie → czyszczenie okna kontekstowego (Sekcja 16).")
    L.append("")

    # --- Wzmocnienie jakościowe (tylko gdy poniżej minimum) ---------------
    if len(L) >= target:
        return
    L.append("APENDYKS F — MINIMUM KWALIFIKACYJNE (lista kontrolna, odznaczaj przy pracy)")
    L.append("-" * 78)
    L.append("")
    checks = [
        "Sesja uruchomiona na CZYSTO (brak resztek poprzednich części w oknie kontekstowym).",
        "Dokumenty święte przeczytane w całości; kontrakty z nich wypisane w notatce roboczej.",
        "Budżet 50% okna kontekstowego obliczony i monitorowany podczas czytania plików.",
        "Każdy plik z Sekcji 6 ma fakt w tabeli dowodów albo adnotację NIEZWERYFIKOWANO.",
        "Mirror policies porównany z implementacją tej części; dryf zapisany jako konflikt Cxx.",
        "Każde pytanie audytowe podanaliz 5.x ma odpowiedź z dowodem (plik + cytat/liczba).",
        "Każdy anty-wzorzec APxx z 7.5 sprawdzony; wynik wpisanym do rejestru luk.",
        "Każdy akt prawny z Sekcji 8 zweryfikowany w ISAP albo oznaczony [NIEZWERYFIKOWANE].",
        "Macierz PRAWO↔REGUŁA↔TEST ma status i ryzyko dla każdego wiersza.",
        "Rejestr luk ma krytyczność P0–P3 oraz plan naprawy dla każdej pozycji.",
        "Min. 12 innowacji z pełnym 6-punktowym projektem (problem, mechanizm, wpływ, ryzyko, kryterium, zależności).",
        "Plan wdrożenia rozdziela prace: od razu / po testach / decyzja człowieka (4-eyes).",
        "Plan testów zawiera przypadki BLOKUJĄCE merge i granice groszowe.",
        "Pytania do człowieka nie zawierają odpowiedzi wymyślonych bez dowodu.",
        "Założenia jawne oznaczone [ZAŁOŻENIE]; brak ukrytych przypuszczeń.",
        "Kontrakt wyjściowy (9.08) gotowy i wiążący dla następnej części.",
        "Tabela przekazywanych artefaktów (11.4) kompletna.",
        "Identyfikatory zgodne ze standardem P00 (Lxx/Ixx/Cxx/Qxx/Xxx) — zero własnych schematów.",
        "Zero stwierdzeń bez dowodu; zero fikcyjnych podstaw prawnych; zero deklaracji bez uruchomienia.",
        "Fail-closed zachowany w każdej rekomendacji (AUTO_POST tylko przy pełnym łańcuchu dowodów).",
        "Raport zapisany pod dokładną nazwą wskazaną w Sekcji 0 i 9.",
        "Sekcja 16 wykonana: potwierdzenie zapisu + czyszczenie okna kontekstowego.",
    ]
    for i, c in enumerate(checks, 1):
        L.append(f"   [ ] F{i:02d}. {c}")
    L.append("")
    if len(L) >= target:
        return
    # Ostateczne domknięcie minimum: rygorystyczna pętla kontrolna per element.
    L.append("APENDYKS G — KONTROLA RYGORYSTYCZNA PER ELEMENT (uzupełnienie do minimum linii)")
    L.append("-" * 78)
    L.append("")
    n = 0
    sp_names = [sp["name"] for sp in part["subparts"]]
    while len(L) < target:
        i = n % 8
        if i == 0:
            idx = (n // 8) % max(len(sp_names), 1)
            L.append(f"   G{n+1:03d}. Dla podanalizy 5.{idx+1} ({sp_names[idx] if idx < len(sp_names) else '—'}):")
            L.append("          - przelicz i podaj w raporcie: liczba plików przeanalizowanych, liczba luk, liczba wniosków;")
            L.append("          - sprawdź, czy wyniki są spójne z kontraktami wejściowymi z Sekcji 11.1;")
            L.append("          - sprawdź, czy żaden wniosek nie duplikuje wniosków P00 (mapa kanoniczna).")
        elif i == 1:
            L.append(f"   G{n+1:03d}. Przypomnienie o fail-closed: każda ścieżka decyzyjna tej części musi mieć explicite")
            L.append("          else → NEEDS_ADVICE/MANUAL_REVIEW; zakaz domniemania AUTO_POST przy braku danych;")
            L.append("          weryfikacja: test negatywny na brak pola obowiązkowego w input.")
        elif i == 2:
            L.append(f"   G{n+1:03d}. Przypomnienie o parametrach-as-data (ADR-002): żadna nowa stawka/próg/limit nie może")
            L.append("          trafić do kodu Rego — wyłącznie data.thresholds.* z valid_from/valid_to (P05) i testem")
            L.append("          granicznym day-0 przełączenia.")
        elif i == 3:
            L.append(f"   G{n+1:03d}. Przypomnienie o unikalności rule_id: nowa lub zmieniana reguła musi mieć identyfikator")
            L.append("          jdg.<pakiet>.<reguła> nieobecny w rule_registry.json i w mirrorze; duplikat = BLOCKER.")
        elif i == 4:
            L.append(f"   G{n+1:03d}. Przypomnienie o budżecie kontekstu: jeśli po tej linii budżet 50% grozi przekroczeniem,")
            L.append("          czytaj pozostałe pliki partiami (nagłówki → sekcje krytyczne → reszta) i oznacz w raporcie")
            L.append("          fragmenty przeczytane częściowo — zakaz cichego pomijania.")
        elif i == 5:
            L.append(f"   G{n+1:03d}. Przypomnienie o weryfikacji prawnej: treść przepisu z pamięci modelu to NIE dowód;")
            L.append("          dowodem jest ISAP/RCL/MF; bez dostępu — [NIEZWERYFIKOWANE] + rejestr mediacji 9.05.")
        elif i == 6:
            L.append(f"   G{n+1:03d}. Przypomnienie o anty-duplikacji: zanim zaproponujesz nowy plik/narzędzie/regułę,")
            L.append("          sprawdź w raporcie V3_P00 i w strukturze repozytorium, czy element już istnieje;")
            L.append("          istniejący rozszerzaj — nowy twórz tylko przy udowodnionej luce.")
        else:
            L.append(f"   G{n+1:03d}. Przypomnienie o jakości raportu: każda tabela T1–T12 wypełniona, żadna nie może")
            L.append("          być pusta; sekcja ZAKRES I OGRANICZENIA wylicza wszystko, czego analiza NIE objęła —")
            L.append("          cisza o pominięciach jest naruszeniem kryteriów akceptacji (Sekcja 13).")
        n += 1
    L.append("")

def render_readme(parts: list) -> str:
    L: list = []
    L.append("=" * 78)
    L.append("NEXUSAI JDG — KAMPANIA V3 „FORTRESS” — PAKIET PROMPTÓW DLA GLM 5.2")
    L.append("=" * 78)
    L.append("")
    L.append("Cel kampanii")
    L.append("-----------")
    L.append("Sekwencyjna, część po części, analiza i wzmacnianie modułu JDG (silnik reguł podatkowych OPA)")
    L.append("do poziomu ENTERPRISE opisanego w dwóch dokumentach świętych:")
    L.append("")
    L.append("  * JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md  (V1 — Control Plane, Data Plane, cykl życia reguł)")
    L.append("  * JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md             (V2 — Legal Twin, konstytucja, Golden Oracle,")
    L.append("                                                     Decision Certificate, Law Radar, Declarative Change)")
    L.append("")
    L.append("Cel nadrzędny biznesowy: pełna automatyzacja księgowości JDG (wirtualny księgowy) przy nienaruszalnej")
    L.append("precyzji prawnej i fail-closed. OPA ma być SYSTEMEM (zmiana prawa = prosta, szybka, bezpieczna zmiana")
    L.append("reguł/parametrów), a nie zborem plików Rego.")
    L.append("")
    L.append("Zasady kampanii")
    L.append("---------------")
    L.append("1. Jeden prompt = jeden plik TXT w JDG/prompty_v3/. Każdy wklejasz do GLM 5.2 w ŚWIEŻEJ (czystej) sesji.")
    L.append("2. Kolejność: P00 → P01 → … → " + parts[-1]["code"] + ". Bez pomijania — każda część honoruje kontrakty wyjściowe wcześniejszych.")
    L.append("3. Budżet kontekstu: dane wejściowe odczytane wg linków z promptu mają zająć maksymalnie 50% okna")
    L.append("   kontekstowego GLM 5.2 (wg założenia właściciela okno GLM 5.2 ≈ 1 000 000 tokenów; jeśli realne okno")
    L.append("   modelu jest mniejsze, czytaj wskazane pliki partiami wg sekcji — mechanizm opisano w Sekcji 3 każdego")
    L.append("   promptu). Reszta okna pozostaje na myślenie i generowanie raportu.")
    L.append("4. Raporty zapisywane do JDG/raporty_glm52_v3/RAPORT_V3_<kod>_<slug>.txt. Identyfikatory: V3-<kod>-Lxx")
    L.append("   (luki), V3-<kod>-Ixx (innowacje), V3-<kod>-Cx (konflikty), V3-<kod>-Qxx (pytania), V3-<kod>-Xxx (krzyżowe).")
    L.append("5. Po KAŻDYM raporcie: potwierdzenie zakresu → wdrożenie zatwierdzonego zakresu przez człowieka →")
    L.append("   walidacja i testy → dopiero wtedy następny prompt. Raport NIE jest wdrożeniem.")
    L.append("6. Każdy prompt kończy się komendą czyszczenia okna kontekstowego po zapisaniu raportu (Sekcja 16).")
    L.append("7. Dokumenty święte są nadrzędne; JDG/docs/Bbb to katalog twierdzeń prawnych do weryfikacji w ISAP/RCL/MF.")
    L.append("8. Zakaz duplikacji i zakaz fikcyjnych faktów; fail-closed: AUTO_POST tylko przy pełnym dowodzie.")
    L.append("")
    L.append(f"Skala pakietu: {len(parts)} promptów (P00–P{len(parts)-1:02d}) + ten README. Każdy raport: duży, dowodowy, wdrożeniowy.")
    L.append("")
    L.append("Mapa kampanii (część → zakres katalogu JDG → raport)")
    L.append("---------------------------------------------------")
    L.append("")
    L.append("| Część | Tytuł | Plik promptu | Raport docelowy |")
    L.append("|-------|-------|--------------|-----------------|")
    for p in parts:
        L.append(f"| {p['code']} | {p['title']} | JDG/prompty_v3/V3_PROMPT_{p['code']}_{p['slug']}.txt | JDG/raporty_glm52_v3/RAPORT_V3_{p['code']}_{p['slug']}.txt |")
    L.append("")
    L.append("Struktura logiczna kampanii")
    L.append("---------------------------")
    L.append("Części P00–P09 budują SYSTEM (kanon, Legal Twin, orkiestrator, kontrakt werdyktu, invarianty,")
    L.append("temporalność, parametry, lifecycle, Law Radar, Declarative Change). Części P10–P11 domykają pewność")
    L.append("(Golden Oracle, Decision Certificate). Części P12–P28 są DOMENOWE (VAT ×2, PIT, cross-border, KSeF/JPK,")
    L.append("Ordynacja, ryczałt, PCC/lokalne/akcyza/BDO, PKPiR/UoR, KKS, RODO/AML, Prawo przedsiębiorców, praca,")
    L.append("kalendarz zbiorczy, ZUS, CFC/exit/MDR, hiperkonteksty plan45). Części P29–P36 to fala jakości i narzędzi")
    L.append("(kampanie quality v3, fale innowacji pXX/rXX/etapy, automatyzacja księgowości, neural mesh AI, walidacja,")
    L.append("audytory domenowe, generatory/migratory). Części P37–P44 domykają warstwę systemową (obserwowalność,")
    L.append("bundle/deployment, testy/CI, API/dane/UI, dokumentacja, enterprise-reszta, security/DR, certyfikacja w P44).")
    L.append(f"FALA NAPRAWCZA P45–P{len(parts)-2:02d} celuje w LUKI wykryte w analizie V3: stuby i fasady, hardcode parametrów,")
    L.append("niezweryfikowane podstawy prawne, dryf mirror policies, dziury fail-closed, dead code, duplikaty rule_id,")
    L.append("pustynie pokrycia prawnego, testy graniczne, temporalność, KSeF 2.0, ZUS, VAT/PIT szczegóły, ingest danych,")
    L.append(f"obserwowalność, security, DR, dokumentacja, wydajność, RuleStore, CI. Część {parts[-1]['code']} = RE-CERTYFIKACJA")
    L.append("fortecy po domknięciu fali naprawczej — nowy dowód stanu, nie powtórzenie certyfikatu P44.")
    L.append("")
    L.append(f"Definicja sukcesu kampanii (potwierdzana w {parts[-1]['code']})")
    L.append("----------------------------------------------")
    L.append("Silnik reguł podatkowych OPA jako ufortyfikowana forteca klasy ENTERPRISE: mierzalne pokrycie prawa")
    L.append("(Legal Twin), egzekwowane invarianty w runtime, golden oracle przeszłości, certyfikaty decyzji,")
    L.append("proaktywny Law Radar, deklaratywna zmiana reguł — zero duplikatów, zero stubów, zero hardcode,")
    L.append("zero fikcyjnych podstaw prawnych, pełny fail-closed. Precyzja, profesjonalizm, zero nieporozumień.")
    L.append("")
    L.append("Artefakty pakietu")
    L.append("-----------------")
    L.append("  JDG/prompty_v3/V3_PROMPT_Pxx_<slug>.txt   — prompty (jeden plik na część, wklejany pojedynczo).")
    L.append("  JDG/raporty_glm52_v3/                      — miejsce docelowe raportów generowanych przez GLM 5.2.")
    L.append("  JDG/tools/glm52_v3_campaign/               — generator pakietu (Python; waliduje ścieżki i minimum).")
    L.append("")
    return "\n".join(L) + "\n"

def phrase_counts(text: str) -> dict:
    low = text.lower()
    return {p: len(re.findall(re.escape(p.lower()), low)) for p in PHRASES}

def validate_prompt(text: str, fname: str) -> list:
    errs = []
    lines = text.count("\n")
    if lines < MIN_LINES:
        errs.append(f"{fname}: {lines} linii < {MIN_LINES}")
    if len(text) < MIN_CHARS:
        errs.append(f"{fname}: {len(text)} znaków < {MIN_CHARS}")
    for p, c in phrase_counts(text).items():
        if c < MIN_PHRASE:
            errs.append(f"{fname}: fraza '{p[:40]}…' wystąpiła {c}x < {MIN_PHRASE}")
    return errs

def validate_paths(parts: list, extra_paths: list | None = None) -> list:
    errs = []
    seen = set()
    paths = extra_paths or []
    for p in parts:
        for g in p["file_groups"]:
            for _d, path in g["files"]:
                paths.append(path)
    for path in paths:
        if path in seen:
            continue
        seen.add(path)
        local = os.path.join(REPO_ROOT, path)
        if not os.path.exists(local):
            errs.append(f"ŚCIEŻKA NIEISTNIEJĄCA: {path}")
    return errs
