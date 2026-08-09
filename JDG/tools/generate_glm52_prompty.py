#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GENERATOR SERII 25 PROMPTÓW GLM 5.2 — NEXUSAI JDG ENTERPRISE
================================================================
Cel: wygenerowanie plików .txt (jeden Prompt = jeden plik txt) do katalogu
  JDG/prompty_glm52/  — każdy Prompt kieruje model GLM 5.2 do przeanalizowania
  JEDNEJ części katalogu JDG i wygenerowania OGROMNEGO RAPORTU ENTERPRISE
  (bez generowania kodu!), zapisywanego w JDG/raporty_glm52/.

Reguły projektowe (wg wymagań użytkownika):
  1. GLM 5.2 ma okno 1M tokenów -> dane wejściowe (pliki do przeczytania)
     mogą zająć maksymalnie 50% okna (~500k tokenów). Każda część jest
     skalibrowana poniżej tego limitu; duże pliki JSON są oznaczone jako
     "czytaj selektywnie".
  2. Każdy Prompt zawiera linki do plików (GitHub) — GLM NIE szuka plików.
  3. NIE GENERUJ KODU — tylko raporty .txt.
  4. Obowiązkowe frazy (każda >= 4x w każdym prompcie):
     - "Przeprowadź głębokie myślenie"
     - "przeprowadź głęboką analizę"
     - "zaawansowany poziom Enterprise"
     - "poziom ENTERPRISE"
     - "innowacyjne ulepszenia wyprzedzające profesjonalistów"
  5. OPA jako SYSTEM — szybka, prosta, niezawodna adaptacja do zmian prawa.
  6. Spójność między częściami: każda część czyta raporty poprzednich części
     (JDG/raporty_glm52/) i wymienia kontrakty/rule_id z częściami sąsiednimi.
  7. Na końcu każdego Promptu — instrukcja WYCZYSZCZENIA OKNA KONTEKSTOWEGO,
     aby płynnie przejść do następnego Promptu.

Uruchomienie:  python3 JDG/tools/generate_glm52_prompty.py
Wyjście:       JDG/prompty_glm52/ (25 plików prompt + README_PROMTY_GLM52.txt)
"""

import os
import re
import sys

# ---------------------------------------------------------------------------
# ŚCIEŻKI I LINKI
# ---------------------------------------------------------------------------
REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(REPO_ROOT, "JDG", "prompty_glm52")
RAPORT_DIR = os.path.join(REPO_ROOT, "JDG", "raporty_glm52")

BASE = "https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/"
POL_BASE = "https://github.com/Gorski-Maciej/NexusAI/blob/main/"


def link(path: str) -> str:
    """GitHub link do pliku/katalogu JDG."""
    return BASE + path


def nazwa_pliku(num: int, tytul: str) -> str:
    """Zwięzła, bezpieczna i unikalna nazwa pliku promptu na podstawie tytułu."""
    parts = tytul.split(" — ")
    czesc = parts[0]
    if len(parts) > 1:
        drugi = parts[1].split(" (")[0].split(" /")[0]
        czesc = (czesc + "_" + drugi).strip("_ ")
    czesc = re.sub(r"[^A-Za-z0-9ĄĆĘŁŃÓŚŹŻąćęłńóśźż_.-]", "_", czesc)
    czesc = re.sub(r"_+", "_", czesc).strip("_")
    return f"{num:02d}_{czesc[:44]}.txt"


def links(paths):
    """Zamienia ścieżki na linki GitHub, rozpoznając realną lokalizację pliku.

    Priorytet rozpoznania (dla ścieżek bez prefiksu, jak "main_jdg.rego"):
      1. JDG/rules/<p>       (plik reguł w katalogu głównym rules/)
      2. JDG/<p>             (plik w katalogu głównym JDG: README, MANIFEST...)
      3. JDG/docs/<p>, JDG/bundles/<p>, JDG/tests/<p> (spadki dla starych list)
    """
    out = []
    for p in paths:
        if p.startswith("root:"):
            out.append("- " + POL_BASE + p[len("root:"):])
            continue
        # ścieżki z prefiksem katalogu — bez zmian
        if p.startswith(("rules/", "docs/", "bundles/", "tests/", "migrations/", "api/")):
            out.append("- " + link(p))
            continue
        # plik w podkatalogu JDG (rozpoznanie po istnieniu pliku)
        znaleziono = False
        for pod in ("rules", "tools", "tests", "docs", "bundles", "migrations", "api"):
            if os.path.isfile(os.path.join(REPO_ROOT, "JDG", pod, p)):
                out.append("- " + link(pod + "/" + p))
                znaleziono = True
                break
        if znaleziono:
            continue
        if os.path.isfile(os.path.join(REPO_ROOT, "JDG", p)):
            out.append("- " + link(p))
            continue
        # fallback: nie znaleziono — zostaw oryginalną ścieżkę z ostrzeżeniem
        print(f"[UWAGA] nie rozpoznano ścieżki: {p}")
        out.append("- " + link(p))
    return "\n".join(out)


# ---------------------------------------------------------------------------
# KOMBINACJE PRZEKROJOWE — mapa domena -> testy (pytest + natywne Rego)
# Automatycznie znajduje pliki testowe pasujące do domeny części, dzięki czemu
# każdy prompt zawiera KOMBINACJĘ odnośników: reguły + testy + prawo + bundle.
# ---------------------------------------------------------------------------
TESTS_DIR = os.path.join(REPO_ROOT, "JDG", "tests")

TEST_KEYWORDS = {
    0: ["p01_control_plane", "p02_legal", "strategic", "phase5"],
    1: ["p03_orchestrator", "risk_guard", "priority_engine", "semantic_guard",
        "facts_aggregator", "temporal_manager", "edge_cases", "conflicts",
        "payment_priority"],
    2: ["vat_enterprise", "p04_vat", "p05_vat", "fraud_graph", "ksef", "tax_rules"],
    3: ["p05_vat", "vat"],
    4: ["p06_pit", "p07_pit", "tax_rules", "pit"],
    5: ["p06_pit", "p16_v8", "annual"],
    6: ["p08_zus", "zus", "benefits"],
    7: ["kks", "tax_audit"],
    8: ["temporal_validity", "tax_audit", "ord", "defense"],
    9: ["pkpir", "uor", "tax_pipeline", "accounting"],
    10: ["crossborder", "mdr", "cfc", "fx", "tp"],
    11: ["pcc", "excise", "local"],
    12: ["phase5", "strategic", "business", "ryczalt"],
    13: ["hyper_plan45", "phase5", "strategic", "conflicts", "edge_cases"],
    14: ["rodo", "aml", "bdo", "privacy"],
    15: ["ksef", "jpk", "edelivery", "wis", "gtu", "invoice"],
    16: ["p01_control_plane", "p02_legal", "p16_v8", "phase5", "strategic"],
    17: ["p16_v8", "strategic", "cross_domain", "banking"],
    18: ["tax_pipeline", "tax_rules", "risk_guard", "semantic_guard", "priority"],
    19: ["ksef_generator", "fraud_graph", "tax_audit", "tax_pipeline", "pcc"],
    20: ["ALL_PY"],
    21: ["ALL_REGO"],
    22: ["tax_pipeline", "risk_api", "p01", "migrations", "bundle"],
    23: ["docs", "coverage", "contract", "config", "i18n"],
    24: ["native", "jpk", "pcc", "ord", "uor", "seasonal", "security", "fx",
         "esig", "advertising", "force_majeure", "taxfree"],
}


def znajdz_testy(num: int):
    """Zwraca listę ścieżek JDG/tests/ (łącznie z podkatalogiem rego/) pasujących do domeny części (max 12)."""
    if not os.path.isdir(TESTS_DIR):
        return []
    kw = TEST_KEYWORDS.get(num, [])
    pasujace = []
    for katalog, pod, pliki in os.walk(TESTS_DIR):
        if ".benchmarks" in katalog or ".hypothesis" in katalog or "__pycache__" in katalog:
            continue
        for nazwa in sorted(pliki):
            if not (nazwa.endswith(".py") or nazwa.endswith(".rego")):
                continue
            pelna = os.path.join(katalog, nazwa)
            wzgl = os.path.relpath(pelna, TESTS_DIR)
            sciezka = os.path.join("tests", wzgl)
            n = nazwa.lower()
            if "ALL_PY" in kw and n.endswith(".py"):
                pasujace.append(sciezka)
                continue
            if "ALL_REGO" in kw and n.endswith(".rego"):
                pasujace.append(sciezka)
                continue
            for k in kw:
                if k in n:
                    pasujace.append(sciezka)
                    break
    return pasujace[:12]


def kombinacje_przekrojowe(num: int):
    """Sekcja łącząca reguły domeny z testami domenowymi i wieloaspektową analizą."""
    testy = znajdz_testy(num)
    out = [
        "## 🔀 KOMBINACJE PRZEKROJOWE — ANALIZUJ Z KAŻDEJ STRONY OPA (WYMÓG):",
        "Nie analizuj reguł w izolacji. Dla KAŻDEGO pliku reguł z tej części wykonaj **przeprowadź głęboką analizę** "
        "z każdej z następujących stron, tworząc pełną sieć zależności (transparentność i niezawodność):",
        "1. **Strona PRAWA** — zgodność z aktami z docs/Bbb (artykuł/ustęp), kanoniczna podstawa `_legal_basis`.",
        "2. **Strona REGUŁY** — logika, else-chain, priorytety, First-Match-Wins, safe_merge, brak duplikatów rule_id.",
        "3. **Strona TESTÓW** — czy istnieją testy (pytest i natywne Rego) dowodzące zachowania; które przypadki brakują.",
        "4. **Strona SYSTEMU** — cykl życia reguły (SHADOW→CANDIDATE→ACTIVE→ROLLED_BACK), kanary, auto-rollback.",
        "5. **Strona DANYCH** — czy wartości (stawki, progi, limity, terminy) pochodzą z bundles (legal_reference_canon).",
        "6. **Strona WERDYKTU** — determinizm, czas wykonania, pełny dowód (Decision Certificate), provenance.",
        "Każdą lukę zgłoś łącznie: artykuł ustawy → brakująca reguła → brakujący test → wpływ na werdykt. "
        "To jest **zaawansowany poziom Enterprise**: super-inteligentna sieć zależności już od jednej reguły.",
    ]
    if testy:
        out.append("")
        out.append("### 🧪 TESTY DOMENOWE — PRZECZYTAJ JE RÓWNIEŻ (kombinacja reguły ↔ testy):")
        out.append("- „Dowód działania\" to nie tylko reguła, ale i test, który ją potwierdza. Przeanalizuj, czy testy "
                   "pokrywają wszystkie przypadki z reguł; wskaż brakujące testy dla każdej luki.")
        out.append(links(testy))
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------------------
# PLIKI ŚWIĘTE (obecne w KAŻDYM prompcie)
# ---------------------------------------------------------------------------
HOLY_FILES = [
    "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
    "docs/WIZJA_OPA_ENTERPRISE_V2.md",
    "docs/Bbb",
    "docs/LEGAL_REFERENCE_ACTS.md",
    "docs/LEGAL_COVERAGE.md",
]
HOLY_LINKS = links(HOLY_FILES)

BB_AKTY = """1) Prawo przedsiębiorców (Dz.U. 2025 poz. 123) + CEIDG (Dz.U. 2025 poz. 456) + zarząd sukcesyjny (Dz.U. 2025 poz. 1234)
2) Ustawa o VAT (Dz.U. 2025 poz. 456) + rozporządzenie MF o obniżonych stawkach VAT (2024-12-04)
3) Ustawa o PIT (Dz.U. 2025 poz. 789) + rozporządzenie MF w sprawie wzorów zeznań PIT (2025-12-30)
4) Ustawa o zryczałtowanym podatku dochodowym (Dz.U. 2025 poz. 234) — ryczałt + karta podatkowa
5) Ordynacja podatkowa (Dz.U. 2025 poz. 234)
6) Ustawa o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345) + rozporządzenie MPiPS ws. podstawy wymiaru składek (2025-12-30)
7) Ustawa o świadczeniach opieki zdrowotnej (Dz.U. 2025 poz. 890) — składka zdrowotna
8) Ustawa o rachunkowości (Dz.U. 2025 poz. 567) + rozporządzenie MF ws. PKPiR (2025-11-15)
9) JPK_VAT z deklaracją (rozporządzenie MF 2025-07-15) + ustawa KSeF (Dz.U. 2023 poz. 1598) + wzór faktury ustrukturyzowanej (2025-10-05)
10) Akty pomocnicze: interpretacje KIS, interpretacje ogólne MF, projekty RCL, ISAP
11) Dodatkowo w module: KKS (Kodeks karny skarbowy), ustawa o PCC, ustawa o podatku akcyzowym,
    ustawa o podatkach i opłatach lokalnych, RODO, AML/CBDD, BDO, Prawo budowlane, ustawa o rehabilitacji zawodowej"""


def frazy_minimum():
    return (
        "## 🧠 FRAZY OBOWIĄZKOWE W TWOJEJ PRACY (każda użyj MINIMUM 4 razy w trakcie analizy):\n"
        "- „Przeprowadź głębokie myślenie\" — 4+ razy (np. przed każdą sekcją analityczną)\n"
        "- „przeprowadź głęboką analizę\" — 4+ razy (przed każdym audytem)\n"
        "- „zaawansowany poziom Enterprise\" — 4+ razy\n"
        "- „poziom ENTERPRISE\" — 4+ razy\n"
        "- „innowacyjne ulepszenia wyprzedzające profesjonalistów\" — 4+ razy\n"
    )


def naglowek(num, total, tytul):
    return (
        "=" * 78 + "\n"
        + "🚨 INSTRUKCJA DLA MODELU GLM 5.2\n"
        + f"PROMPT {num:02d}/{total:02d} — {tytul}\n"
        + "=" * 78 + "\n"
    )


def krytyczne_zasady(raport_nazwa):
    return (
        "## ⚠️ KRYTYCZNE ZASADY (przeczytaj, zrozum i ZAPAMIĘTAJ):\n"
        "1. **NIE GENERUJ KODU** — Twoim zadaniem jest wyłącznie analiza i wygenerowanie "
        "**OGROMNEGO, ROZBUDOWANEGO RAPORTU ANALITYCZNEGO** w formacie plain text (.txt).\n"
        "2. **NIE MODYFIKUJ PLIKÓW** — analizujesz istniejący kod/dokumentację, nie tworzysz nowego.\n"
        f"3. Raport zapisz jako plik: `JDG/raporty_glm52/{raport_nazwa}` (plain text .txt, kodowanie UTF-8).\n"
        "4. **BUDŻET KONTEKSTU (WAŻNE):** Twoje okno kontekstowe ma 1 000 000 tokenów. "
        "Dane i informacje, które przeczytasz i zapamiętasz z plików, mogą zająć **maksymalnie 50% okna "
        "(~500 000 tokenów)**. Pozostałą część okna ZAREZERWUJ na: głębokie myślenie, głęboką analizę, "
        "wyprowadzanie wniosków, projektowanie rozwiązań i generowanie raportu. "
        "Jeśli zestaw plików jest duży — czytaj selektywnie (nagłówki, kluczowe reguły, statystyki), "
        "zachowując budżet 50%.\n"
        "5. Pracuj WYŁĄCZNIE na plikach wskazanych poniżej — linki są podane wprost, "
        "nie szukaj plików po omacku. Jeśli brakuje kontekstu, odwołaj się do PLIKÓW ŚWIĘTYCH.\n"
        "6. Cel Twojej pracy: osiągnąć **zaawansowany poziom Enterprise** w każdym wymiarze. Pracuj na "
        "**zaawansowanym poziomie Enterprise**, a każda rekomendacja ma reprezentować **poziom ENTERPRISE**, "
        "którego nie powstydziłby się najlepszy ekspert branżowy.\n"
    )


def swiete():
    return (
        "## 🏛️ PLIKI ŚWIĘTE (czytaj ZAWSZE — to fundament, ostateczna struktura docelowa modułu JDG):\n"
        + HOLY_LINKS
        + "\n\n"
        "> „ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md\" (cel V1: Control Plane + Data Plane, cykl życia reguły, "
        "pipeline adaptacji do zmian prawa) oraz „WIZJA_OPA_ENTERPRISE_V2.md\" (V2: Legal Twin / LKG, runtime "
        "invariants, weryfikacja formalna, Decision Certificate, Law Radar, Declarative Change) to **dwa "
        "NAJWAŻNIEJSZE pliki** — moduł JDG ma się rozwijać zgodnie z nimi (ADR-016…ADR-021). "
        "„docs/Bbb\" zawiera akty prawne (rok 2026), z którymi reguły OPA MUSZĄ być zgodne. "
        "Każdą rekomendację odnieś do tych plików. Rozwijaj moduł na **zaawansowanym poziomie Enterprise**, "
        "osiągając **poziom ENTERPRISE** w każdym aspekcie: regułach, systemie, testach i dokumentacji.\n"
    )


def zrodla_prawa():
    return (
        "## 📜 ŹRÓDŁA PRAWA — AKTY, KTÓRYM MUSZĄ ODPOWIADAĆ REGUŁY (szczegóły w docs/Bbb):\n"
        + BB_AKTY
        + "\n\n"
        "Dla każdej reguły w swojej części sprawdź: (a) czy istnieje węzeł prawa dla podstawy `_legal_basis`, "
        "(b) czy wartości liczbowe (stawki, progi, limity, terminy) są zgodne z aktami powyżej i z "
        "`bundles/legal_reference_canon.json`, (c) czy temporalność `valid_from`/`valid_to` pokrywa nowelizacje.\n"
    )


def powiazane(related):
    out = ["## 🔗 CZĘŚCI POWIĄZANE (SPÓJNOŚĆ MIĘDZY CZĘŚCIAMI — BARDZO WAŻNE):"]
    out.append(
        "- ZANIM zaczniesz: przeczytaj raport master **00_FUNDAMENT** oraz raporty części wskazanych poniżej "
        "z katalogu `JDG/raporty_glm52/` (jeśli istnieją). Twoje rekomendacje MUSZĄ być spójne z nimi: "
        "wspólne `rule_id` (`jdg.<domena>.<kategoria>`), wspólne nazwy pakietów Rego, wspólny słownik "
        "(werdykt 25-polowy, First-Match-Wins, safe_merge), zero konfliktów nazw i zero duplikatów."
    )
    out.append("- Części powiązane (numery promptów): " + ", ".join(related) + ".")
    out.append(
        "- W raporcie umieść sekcję **„KONTRAKTY Z INNYMI CZĘŚCIAMI\"**: lista rule_id/pakietów, które "
        "Twój raport tworzy, zmienia lub na których polega — aby inne części (następne prompty) mogły "
        "bez konfliktów wdrożyć swoje zmiany. **Zmiany z jednego raportu muszą być spójnie połączone "
        "z innymi częściami** — to łańcuch, nie zbiór niezależnych analiz."
    )
    return "\n".join(out) + "\n"


def metodologia():
    return (
        "## 🧠 JAK ANALIZOWAĆ (metodologia obowiązkowa):\n"
        "1. **Przeprowadź głębokie myślenie** nad architekturą części — zanim cokolwiek ocenisz.\n"
        "2. **przeprowadź głęboką analizę** każdego pliku: role, rule_id, warunki, podstawy prawne, progi.\n"
        "3. Oceń wszystko na **zaawansowanym poziomie Enterprise** — to ma być system klasy **poziom ENTERPRISE**.\n"
        "4. Dla każdej luki podaj: konkretny artykuł/ustęp aktu prawnego, brakującą regułę (opis, nie kod), "
        "proponowany `rule_id`, priorytet (P0/P1/P2), wpływ na decyzje, ryzyko błędu i czas naprawy.\n"
        "5. **Przeprowadź głębokie myślenie** nad konsekwencjami każdej zmiany dla pozostałych części "
        "(łańcuch spójności raportów) — zero konfliktów rule_id, zero duplikatów.\n"
        "6. **przeprowadź głęboką analizę** temporalności (`valid_from`/`valid_to`) i podstaw prawnych "
        "`_legal_basis` względem aktów z docs/Bbb (zgodność z prawem = fundament pewności).\n"
        "7. Wymyśl **innowacyjne ulepszenia wyprzedzające profesjonalistów** — rozwiązania, których nie ma "
        "nawet w najlepszych biurach rachunkowych i produktach konkurencji.\n"
        "8. **Przeprowadź głębokie myślenie** o scenariuszach awaryjnych (zmiana prawa w trakcie roku, "
        "masowe korekty, niedostępność KSeF, atak na dane) — jak reaguje Twoja część?\n"
        "9. **przeprowadź głęboką analizę** odporności i niezawodności — zero crashy, zero nieokreśloności, "
        "deterministyczne werdykty, szybkie odzyskiwanie.\n"
        "10. Każdą rekomendację odnieś do filarów V1/V2 (Control Plane, Data Plane, Legal Twin, runtime "
        "invariants, Decision Certificate, Law Radar, Declarative Change, zero-hardcode, temporalność, "
        "golden replay, kanary i auto-rollback).\n"
        + frazy_minimum()
    )


def system_opa():
    return (
        "## ⚙️ OPA MUSI BYĆ ROZBUDOWANYM SYSTEMEM (wymóg nadrzędny — włącz do swojej analizy):\n"
        "Prawo jest bardzo zmienne: zmiana reguł OPA oraz dodawanie i usuwanie reguł musi być **sprawne, "
        "niezawodne i proste**. Silnik reguł podatkowych OPA musi się **szybko i profesjonalnie adaptować "
        "do zmian** prawa. Dlatego OPA to nie zbiór reguł, lecz SYSTEM: control plane (tworzenie, weryfikacja, "
        "testowanie, wersjonowanie, podpisywanie, dystrybucja, wdrażanie kanarkowe, monitorowanie, wycofywanie "
        "reguł), data plane (ewaluacja), deklaratywne manifesty reguł, hot-reload parametrów, cykl życia "
        "SHADOW→CANDIDATE→ACTIVE→ROLLED_BACK, kill-switch, auto-rollback, Law Radar (projekty ustaw, nie tylko "
        "publikacje), Declarative Change („człowiek opisuje zmianę, maszyna ją wykonuje\"). "
        "W Twoim raporcie znajdź miejsce, gdzie Twoja część wzmacnia tę „systemowość\" — a nie tylko dokłada reguły.\n"
        "**Przeprowadź głębokie myślenie** nad tym, jak Twoja część wzmacnia systemowość OPA, oraz "
        "**przeprowadź głęboką analizę** cyklu życia reguł (dodanie→zmiana→usunięcie) w swojej domenie. "
        "Docelowy stan to **poziom ENTERPRISE** i **zaawansowany poziom Enterprise** w całym łańcuchu: "
        "prawo → reguła → test → bundle → werdykt. Wskaż też **innowacyjne ulepszenia wyprzedzające "
        "profesjonalistów**, które upraszczają obsługę zmiany prawa dla operatora i prawnika.\n"
    )


def format_raportu(tytul):
    return (
        "## 📐 FORMAT RAPORTU (obowiązkowy):\n"
        f"- Tytuł: „RAPORT ANALITYCZNY ENTERPRISE — {tytul}\"\n"
        "- Dokument musi reprezentować **zaawansowany poziom Enterprise** i **poziom ENTERPRISE** — "
        "precyzja, zero nieporozumień, zero wątpliwości co do reguł i ich podstaw prawnych.\n"
        "- Executive Summary (1 strona) z TOP 10 rekomendacji (priorytety P0/P1/P2)\n"
        "- Diagramy Mermaid (przepływy decyzyjne, architektura, zależności między regułami)\n"
        "- Tabele pokrycia: artykuł ustawy → reguły istniejące → luki → status (A/B/C)\n"
        "- Sekcja „OPA JAKO SYSTEM\" — wzmocnienie control plane / adaptacji do zmian prawa\n"
        "- Sekcja „KONTRAKTY Z INNYMI CZĘŚCIAMI\" — spójność łańcucha raportów\n"
        "- Sekcja „GENIALNE POMYSŁY ENTERPRISE\" — **innowacyjne ulepszenia wyprzedzające profesjonalistów** "
        "(min. 12 pomysłów, każdy z opisem działania i korzyści)\n"
        "- Mapa drogowa: uszeregowane wg krytyczności, szacowany czas naprawy, wpływ, ryzyko błędnej decyzji\n"
        "- Minimalna długość: 25–40 stron tekstu (bardzo rozbudowany raport; im więcej precyzyjnych, "
        "działających na wyobraźnię rozwiązań klasy **poziom ENTERPRISE**, tym lepiej)\n"
        "- Język: polski (terminologia techniczna może być angielska)\n"
    )


def zakonczenie(next_prompt):
    if next_prompt == "KONIEC_SERII":
        return (
            "## 🧹 NA ZAKOŃCZENIE PRACY (WYKONAJ DOKŁADNIE):\n"
            "1. Zapisz kompletny raport jako plik `.txt` w `JDG/raporty_glm52/` (nazwa podana w ZASADACH).\n"
            "2. **WYCZYŚĆ OKNO KONTEKSTOWE** — zakończ pracę, zapomnij o tej analizie (nowa, czysta sesja).\n"
            "3. **To był OSTATNI prompt serii (00–24).** Po wdrożeniu wzmocnień i poprawek ze wszystkich "
            "25 raportów silnik reguł podatkowych OPA osiąga najwyższy zaawansowany poziom ENTERPRISE — "
            "ufortyfikowaną fortecę niechybnej pewności, odporną na błędy, niedopatrzenia i zmiany prawa.\n"
            "4. Jeśli chcesz ulepszać dalej, wygeneruj nową serię raportów w oparciu o raport master 00 "
            "(JDG/raporty_glm52/RAPORT_00_FUNDAMENT_ARCHITEKTURA.txt) jako nowy fundament.\n"
        )
    return (
        "## 🧹 NA ZAKOŃCZENIE PRACY (WYKONAJ DOKŁADNIE):\n"
        "1. Zapisz kompletny raport jako plik `.txt` w `JDG/raporty_glm52/` (nazwa podana w ZASADACH).\n"
        "2. **WYCZYŚĆ OKNO KONTEKSTOWE** — zakończ pracę, zapomnij o tej analizie (nowa, czysta sesja). "
        "Dzięki temu GLM 5.2 płynnie przejdzie do następnego Promptu z pełną pojemnością okna.\n"
        f"3. Następny Prompt do wklejenia: `JDG/prompty_glm52/{next_prompt}`\n"
        "4. Powtórz procedurę dla każdego kolejnego Promptu, aż do ostatniego (24_POLICIES).\n"
    )


def buduj_prompt(num, total, tytul, persona, raport_nazwa, focus, kategorie, related, next_prompt, uwagi=""):
    p = []
    p.append(naglowek(num, total, tytul))
    p.append("Jesteś Najwyższej Klasy Ekspertem — " + persona)
    p.append("")
    p.append(krytyczne_zasady(raport_nazwa))
    p.append(swiete())
    p.append(zrodla_prawa())
    p.append("## 🎯 CEL ANALIZY TEJ CZĘŚCI:\n" + focus + "\n")
    p.append("## 📂 PLIKI DO PRZECZYTANIA I PRZEANALIZOWANIA (linki — nie szukaj innych):\n")
    for kat, paths in kategorie:
        p.append(f"### {kat}\n" + links(paths) + "\n")
    p.append(kombinacje_przekrojowe(num))
    if uwagi:
        p.append("### ⚠️ UWAGI DO ZESTAWU PLIKÓW\n" + uwagi + "\n")
    p.append(powiazane(related))
    p.append(system_opa())
    p.append(metodologia())
    p.append(format_raportu(tytul))
    p.append("## ⚠️ PRZYPOMNIENIE:\nNIE GENERUJ KODU REGO. NIE MODYFIKUJ PLIKÓW. "
             "Generujesz WYŁĄCZNIE OGROMNY RAPORT ANALITYCZNY .txt klasy ENTERPRISE. "
             "**Przeprowadź głębokie myślenie** i **przeprowadź głęboką analizę** na **zaawansowanym poziomie "
             "Enterprise** — ten raport ma reprezentować najwyższy **poziom ENTERPRISE**.\n")
    p.append(zakonczenie(next_prompt))
    return "\n".join(p) + "\n"


# ---------------------------------------------------------------------------
# DEFINICJE CZĘŚCI (25 części: 00–24)
# ---------------------------------------------------------------------------
CZESCI = []

# ============================= 00 FUNDAMENT =============================
CZESCI.append(dict(
    num=0, tytul="FUNDAMENT — ARCHITEKTURA, WIZJA V1+V2, AKTY PRAWNE, STAN SYSTEMU (RAPORT MASTER)",
    persona="Architektem Systemów Klasowych ENTERPRISE i Ekspertem Policy-as-Code (OPA/Rego) oraz "
            "prawa podatkowego i księgowego JDG. Masz za sobą audyty setek systemów decyzyjnych klasy finansowej.",
    raport="RAPORT_00_FUNDAMENT_ARCHITEKTURA.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę CAŁEGO stanu modułu JDG na "
           "zaawansowanym poziomie Enterprise. Ten raport jest RAPORTEM MASTER — definiuje architekturę docelową, "
           "wskaźniki pewności prawnej (LCI, TCL, RV, UVR), wspólny słownik rule_id/pakietów i kontrakty, z którymi "
           "muszą być spójne WSZYSTKIE pozostałe 24 części. Wygeneruj: (1) analizę zgodności stanu obecnego z "
           "ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md (V1) i WIZJA_OPA_ENTERPRISE_V2.md (V2) — wskaż luki L1–L12 i "
           "niespójności liczb (pliki/reguły/pokrycie) między README/MANIFEST/COVERAGE_REPORT/LEGAL_COVERAGE/audytami; "
           "(2) katalog aktów prawnych z docs/Bbb z mapą „akt → domena reguł → status pokrycia (A/B/C)\"; "
           "(3) definicję wskaźników mierzalnej pewności (LCI ≥99%, TCL 100%, RV 100%, UVR 0, zero duplikatów, "
           "zero stubów, zero hardcode) z konkretnymi narzędziami i bramkami CI, które je egzekwują; "
           "(4) projekt Control Plane + Data Plane dla JDG (policy registry API, bundle server z podpisem HSM, "
           "kanary 5%→100%, auto-rollback ≤5 min, hot-reload parametrów ≤15 min, Law Radar, Declarative Change, "
           "Legal Twin/LKG, runtime invariants, Decision Certificate); (5) roadmapę wdrożenia wg filarów V2 "
           "(ADR-016…021) z priorytetami i kosztami; (6) KONTRAKTY z częściami 01–24. To jest fundament łańcucha — "
           "każda inna część będzie czytać Twój raport."),
    kategorie=[
        ("PLIKI ŚWIĘTE + STAN SYSTEMU", ["README.md", "MANIFEST.md", "COVERAGE_REPORT.md",
          "unified_plan_progress.yaml", "unified_plan_v8.yaml"]),
        ("ARCHITEKTURA I WIZJA (docs/)", ["docs/ARCHITEKTURA.md", "docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
          "docs/WIZJA_OPA_ENTERPRISE_V2.md", "docs/ANALIZA_STANU_OPA_JAKO_SYSTEM.md",
          "docs/STRUKTURA_PROJEKTU.md", "docs/UNIFIED_PLAN.md", "docs/RULE_LIFECYCLE.md",
          "docs/DEVELOPER_GUIDE.md", "docs/OPA_REGO_DEVELOPER_GUIDE.md"]),
        ("AKTY PRAWNE I POKRYCIE (docs/)", ["docs/Bbb", "docs/Bbb.md", "docs/LEGAL_REFERENCE_ACTS.md",
          "docs/LEGAL_COVERAGE.md", "docs/SLOWNIK_REFERENCJI_PRAWNYCH.md", "docs/AUDYT_PODSTAW_PRAWNYCH.md",
          "docs/LEGAL_COVERAGE_GAP_RAPORT.md", "docs/LEGAL_TWIN_RAPORT.md", "docs/PEWNOSC_DASHBOARD.md",
          "docs/KALENDARZ_ZMIAN_PRAWNYCH.md", "docs/ZGODNOSC_DOKUMENTY_KSIEGOWE.md"]),
        ("API / PODRĘCZNIK / KATALOGI (docs/)", ["docs/API_REFERENCJA.md", "docs/PODRECZNIK_UZYTKOWNIKA.md",
          "docs/FAQ.md", "docs/KATALOG_REGUL.md", "docs/INWENTARYZACJA_PLIKOW.md", "docs/KATALOG_NARZEDZI.md"]),
    ],
    related=["01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24"],
    next="01_ORKIESTRATOR_RDZEN.txt",
    uwagi=("MANIFEST.md ma ~1,1 MB (ok. 280–450 tys. tokenów) — czytaj go selektywnie: nagłówki, metryki, "
           "sekcje dotyczące reguł z Twojej domeny. Zachowaj budżet 50% okna kontekstowego."),
))

# ============================= 01 ORKIESTRATOR =============================
CZESCI.append(dict(
    num=1, tytul="ORKIESTRATOR I RDZEŃ SILNIKA (main_jdg, routing, risk, temporal, thresholds, validation)",
    persona="Architektem silników regułowych OPA klasy ENTERPRISE, specjalistą od multi-pass decision engines, "
            "sharded routerów i niezawodności systemów decyzyjnych klasy finansowej.",
    raport="RAPORT_01_ORKIESTRATOR_RDZEN.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę ORKIESTRATORA i rdzenia silnika na "
           "zaawansowanym poziomie Enterprise. Oceń: Multi-Pass PASS 0–8, Sharded Router (O(1), determinizm), "
           "First-Match-Wins else-chain, safe_merge (allowlista niemutowalna), werdykt 25-polowy, system priorytetów, "
           "mechanizmy fallback/validation, temporalność (time-travel, valid_from/valid_to), provenance (Merkle), "
           "thresholds_jdg (zero hardcode), edge_cases i liability. Wymyśl innowacyjne ulepszenia wyprzedzające "
           "profesjonalistów: runtime invariant check na końcu POST-MERGE (filar V2/F2), shadow A/B porównanie "
           "werdyktów, cache decyzji, deterministyczny routing z debugowaniem ścieżki, wstrzykiwanie wersji reguł "
           "do werdyktu (bundle_version, rule_version, threshold_version), Decision Certificate. Sprawdź, czy "
           "architektura jest zgodna z V1/V2 i czy rdzeń pozwala OPA działać jako SYSTEM (szybka adaptacja do "
           "zmian prawa)."),
    kategorie=[
        ("RDZEŃ (rules/ — katalog główny)", ["_helpers_jdg.rego", "_metadata_jdg.rego", "main_jdg.rego",
          "routing.rego", "risk.rego", "fallback.rego", "api_fallback.rego", "validation.rego",
          "compliance.rego", "provenance.rego", "temporal.rego", "thresholds_jdg.rego", "edge_cases.rego",
          "liability.rego", "retention.rego", "digital.rego"]),
    ],
    related=["00, 02, 03, 16"],
    next="02_VAT_CORE.txt",
))

# ============================= 02 VAT CORE =============================
CZESCI.append(dict(
    num=2, tytul="VAT — CORE (MACRO) + ENTERPRISE (stawki, odliczenia, MPP, fraud, korekty)",
    persona="Najwyższej Klasy Ekspertem w podatku VAT (ustawa z 11.03.2004, Dz.U. 2025 poz. 456), systemach "
            "OPA/Rego i mechanizmach MPP/Split Payment, SLIM VAT i KSeF.",
    raport="RAPORT_02_VAT_CORE.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu VAT (warstwa Macro + Enterprise) "
           "na zaawansowanym poziomie Enterprise. Priorytet: **MPP i Split Payment (Art. 108a–108f)** — kompletność, "
           "progi (15 000 zł, Zał. 15), BLOCK_AND_ALERT; stawki i zwolnienia (Art. 41–43, 113 — limit 200 000 zł); "
           "odliczenia (Art. 86–95, proporcja, złe długi 90 dni SLIM VAT 3); miejsce świadczenia (Art. 28a–28o); "
           "obowiązek podatkowy (Art. 19a); WNT/WDT/eksport/import; sankcje KSeF. Wymyśl innowacyjne ulepszenia "
           "wyprzedzające profesjonalistów: auto-detekcja MPP z analizą semantyczną opisu towaru, auto-tracking "
           "limitu zwolnienia 200 000 zł w czasie rzeczywistym, korekty wieloletnie Art. 91 z pełną automatyzacją, "
           "fraud detection (karuzele, puste faktury, solidarna odpowiedzialność), auto-GTU. Porównaj z "
           "LEGAL_COVERAGE.md i legal_coverage_gaps.json (luki: Art. 17, Art. 90) i wskaż brakujące reguły "
           "z konkretnymi artykułami."),
    kategorie=[
        ("VAT CORE (rules/vat/)", ["rules/vat/substantive.rego", "rules/vat/deductions.rego",
          "rules/vat/procedures.rego", "rules/vat/place_of_supply.rego", "rules/vat/plan23_detailed.rego",
          "rules/vat/plan26_critical.rego", "rules/vat/plan42_reduced_rates.rego",
          "rules/vat/enterprise_vat_bridge.rego"]),
        ("VAT ENTERPRISE (rules/ — katalog główny)", ["vat_substantive_complete_enterprise.rego",
          "vat_rates_exemptions_audit_enterprise.rego", "vat_deductions_corrections_enterprise.rego",
          "vat_fraud_detection_enterprise.rego", "vat_mpp_split_payment_enterprise.rego",
          "vat_cashflow_predictor_enterprise.rego"]),
        ("INNOWACJE VAT (rules/ — p02–p05)", [          "p02_vat_macro_innovations_v8.rego",
          "p03_vat_macro_innovations_v9.rego",
          "p04_vat_macro_enterprise_v9.rego", "p03_vat_micro_innovations_v8.rego",
          "p04_vat_micro_innovations_v9.rego", "p05_vat_micro_atomic_v9.rego"]),
        ("REFERENCJE POKRYCIA (bundles/)", ["bundles/legal_coverage_gaps.json", "bundles/legal_reference_canon.json"]),
    ],
    related=["00, 01, 03, 15, 16"],
    next="03_VAT_MICRO.txt",
    uwagi=("`bundles/legal_coverage_gaps.json` i `legal_reference_canon.json` czytaj selektywnie (sekcje VAT)."),
))

# ============================= 03 VAT MICRO =============================
CZESCI.append(dict(
    num=3, tytul="VAT — WARSTWA MICRO (atomowe reguły per artykuł, plan33/plan34)",
    persona="Ekspertem od atomowych reguł Rego per artykuł ustawy o VAT (warstwa micro, dual-layer architecture) "
            "oraz audytu spójności reguł z ustawą o VAT z 2026 r.",
    raport="RAPORT_03_VAT_MICRO.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę WARSTWY MICRO VAT na zaawansowanym poziomie "
           "Enterprise: rules/micro/vat/ (vat.rego — ~64 tys. tokenów, ksef_micro, margin_scheme_micro, "
           "place_of_supply_micro, proportion_vat, wdt_export_import) oraz plan33_vat/plan34_vat. Oceń: pokrycie "
           "artykułów ustawy o VAT (każda reguła → artykuł/ustęp), jakość else-chain, priorytety, podstawy prawne "
           "`_legal_basis` (kanoniczne vs NON_CANONICAL wg legal_basis_audit.json), duplikaty rule_id, stuby, "
           "hardcode wartości. Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: super-inteligentna "
           "sieć zależności między regułami micro a macro (transparentność), automatyczna weryfikacja pokrycia "
           "artykułów (każdy materialny węzeł prawa z Bbb → ≥1 reguła), łączenie reguł micro z werdyktami macro "
           "bez konfliktów, testy natywne per artykuł, temporalne testy przejść nowelizacji."),
    kategorie=[
        ("VAT MICRO (rules/micro/vat/)", ["rules/micro/vat/vat.rego", "rules/micro/vat/ksef_micro.rego",
          "rules/micro/vat/margin_scheme_micro.rego", "rules/micro/vat/place_of_supply_micro.rego",
          "rules/micro/vat/proportion_vat.rego", "rules/micro/vat/wdt_export_import.rego"]),
        ("VAT MICRO LOOSE (rules/micro/)", ["rules/micro/plan33_vat.rego", "rules/micro/plan34_vat.rego",
          "rules/micro/plan33_prop.rego"]),
        ("REFERENCJE (bundles/ — ⚠️ czytaj SELEKTYWNIE: stats/by_act/wiersze VAT)", ["bundles/legal_basis_audit.json",
          "bundles/vat_micro_inventory.json"]),
    ],
    related=["00, 02, 01"],
    next="04_PIT_CORE.txt",
    uwagi=("`legal_basis_audit.json` (~3 MB) i `vat_micro_inventory.json` czytaj SELEKTYWNIE — tylko sekcje "
           "statystyk i wiersze dotyczące VAT (grep po „VAT\"/„vat\")."),
))

# ============================= 04 PIT CORE =============================
CZESCI.append(dict(
    num=4, tytul="PIT — CORE (MACRO) + ULGI (skala, liniowy, KUP, NKUP, amortyzacja, ulgi Art. 21–26h, IP Box)",
    persona="Najwyższej Klasy Ekspertem w podatku PIT (ustawa z 26.07.1991, Dz.U. 2025 poz. 789), ulgach "
            "podatkowych, KUP/NKUP, amortyzacji i systemach regułowych OPA/Rego.",
    raport="RAPORT_04_PIT_CORE.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu PIT (Core/Macro + ulgi) na "
           "zaawansowanym poziomie Enterprise. Priorytet: **ULGI I OPTYMALIZACJA** — Art. 26e (B+R), 26eb "
           "(prototyp), 26ec (ekspansja), 26gb (robotyzacja), 26h (termomodernizacja 53 000 zł), IP Box Art. 30ca "
           "(5%), ulga na powrót/młodych/4+ (Art. 21 ust. 1 pkt 148–154), ulga rehabilitacyjna; formy "
           "opodatkowania (skala 12%/32%, liniowy 19%, Art. 9a); KUP Art. 22–23 (NKUP, limit 150 000/225 000 zł "
           "samochody); zaliczki Art. 44; strata podatkowa (5 lat/50%); amortyzacja (Art. 22a–22o, KŚT, "
           "jednorazowa 100 tys. zł). Sprawdź reguły rules/pit/* (20 plików: forms, kup, kup_extended, exemptions, "
           "advances_returns, transitions, plan23/plan26, art21_exemptions_enterprise, ipbox_enterprise, "
           "rd_relief_enterprise, thermo_relief_enterprise, donation_relief_enterprise, "
           "cross_relief_optimizer_enterprise, tax_loss_harvesting_enterprise, family_estonian_enterprise, "
           "elearning, tax_form_transition_intelligence), allowances.rego i nkup_enterprise_complete.rego. "
           "Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: symulator „co by było gdyby\" ulg "
           "(B+R vs IP Box vs robotyzacja), optymalizator formy opodatkowania, predykcja zaliczek, kalkulator "
           "optymalnej składki — jako rekomendacje (nigdy decyzje automatyczne)."),
    kategorie=[
        ("PIT CORE (rules/pit/ — 20 plików)", ["rules/pit/forms.rego", "rules/pit/kup.rego",
          "rules/pit/kup_extended.rego", "rules/pit/exemptions.rego", "rules/pit/advances_returns.rego",
          "rules/pit/transitions.rego", "rules/pit/plan23_exemptions.rego", "rules/pit/plan23_tax_form_change.rego",
          "rules/pit/plan26_detailed.rego", "rules/pit/plan26_pit_critical.rego",
          "rules/pit/art21_exemptions_enterprise.rego", "rules/pit/ipbox_enterprise.rego",
          "rules/pit/rd_relief_enterprise.rego", "rules/pit/thermo_relief_enterprise.rego",
          "rules/pit/donation_relief_enterprise.rego", "rules/pit/cross_relief_optimizer_enterprise.rego",
          "rules/pit/tax_loss_harvesting_enterprise.rego", "rules/pit/family_estonian_enterprise.rego",
          "rules/pit/elearning.rego", "rules/pit/tax_form_transition_intelligence.rego"]),
        ("PIT TOP-LEVEL (rules/)", ["allowances.rego", "nkup_enterprise_complete.rego",
          "rules/allowances/plan23_reliefs.rego"]),
        ("INNOWACJE PIT (rules/ — p04–p07)", ["p04_pit_macro_innovations_v8.rego", "p05_pit_innovations_v8.rego",
          "p05_pit_macro_innovations_v9.rego", "p06_pit_macro_enterprise_v9.rego",
          "p06_pit_micro_innovations_v8.rego", "p06_pit_micro_innovations_v9.rego",
          "p07_pit_micro_atomic_v9.rego"]),
        ("PIT MICRO LOOSE (rules/micro/)", ["rules/micro/plan33_pit.rego", "rules/micro/plan34_pit.rego",
          "rules/micro/pit/pit.rego"]),
        ("REFERENCJE (bundles/ — ⚠️ czytaj SELEKTYWNIE)", ["bundles/pit_micro_inventory.json"]),
    ],
    related=["00, 05, 06, 09"],
    next="05_PIT_ENTERPRISE.txt",
    uwagi=("`pit_micro_inventory.json` czytaj selektywnie (statystyki + wiersze PIT)."),
))

# ============================= 05 PIT ENTERPRISE =============================
CZESCI.append(dict(
    num=5, tytul="PIT — ENTERPRISE (deklaracje PIT-36/36L/28, estoński CIT, exit tax, transformacje, optymalizacja)",
    persona="Ekspertem ENTERPRISE od rocznych deklaracji PIT (PIT-36/36L/28), estońskiego CIT, exit tax/MDR, "
            "optymalizacji podatkowej i formularzy podatkowych MF.",
    raport="RAPORT_05_PIT_ENTERPRISE.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę warstwy ENTERPRISE PIT na zaawansowanym "
           "poziomie Enterprise. Priorytety: auto-deklaracje roczne (annual_declaration_enterprise: PIT-36/36L/28 "
           "auto-fill, zgodność z rozporządzeniem MF ws. wzorów zeznań z 30.12.2025); estoński CIT dla JDG "
           "(p16_estonian_cit_enterprise — warunki, limity, JPK_CIT); exit tax + MDR (exit_tax_mdr_enterprise, "
           "p16_entrepreneur_test_enterprise — test przedsiębiorcy, p16_enhanced_sca_enterprise); transformacje "
           "form opodatkowania (form_transition_simulator_enterprise, form_optimizer_enterprise, "
           "p16_autoform_generator_enterprise); optymalizacja podatkowa (tax_optimization_enterprise, "
           "decision_scoring_enterprise). Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: silnik "
           "„autopilota rocznego rozliczenia\" z pełnym dowodem (Decision Certificate), symulator zmiany formy "
           "z prognozą na 3 lata, automatyczny scoring decyzji strategicznych z podstawą prawną, harmonizacja "
           "z JPK_CIT i JPK_V7M."),
    kategorie=[
        ("PIT ENTERPRISE (rules/)", ["annual_declaration_enterprise.rego", "form_transition_simulator_enterprise.rego",
          "p16_autoform_generator_enterprise.rego", "p16_estonian_cit_enterprise.rego",
          "p16_entrepreneur_test_enterprise.rego", "p16_enhanced_sca_enterprise.rego",
          "exit_tax_mdr_enterprise.rego", "tax_optimization_enterprise.rego", "decision_scoring_enterprise.rego",
          "form_optimizer_enterprise.rego"]),
        ("PIT ENTERPRISE MICRO LOOSE (rules/micro/)", ["rules/micro/plan33_est.rego",
          "rules/micro/plan33_tax_trans.rego"]),
    ],
    related=["00, 04, 10, 15"],
    next="06_ZUS.txt",
))

# ============================= 06 ZUS =============================
CZESCI.append(dict(
    num=6, tytul="ZUS/SUS — składki, ulgi (start/preferencyjny/Mały ZUS+), zdrowotna, zasiłki, PPK/PFRON, HR",
    persona="Najwyższej Klasy Ekspertem w ubezpieczeniach społecznych (ustawa z 13.10.1998, Dz.U. 2025 poz. 345), "
            "składce zdrowotnej (ustawa z 27.08.2004, Dz.U. 2025 poz. 890), zasiłkach i systemach OPA/Rego.",
    raport="RAPORT_06_ZUS.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu ZUS na zaawansowanym poziomie "
           "Enterprise. Priorytet: **SKŁADKA ZDROWOTNA (Polski Ład)** — skala 9% od dochodu; liniowy 4,9% (limit "
           "12 900 zł rocznie — ZWERYFIKUJ, czy nie jest przestarzały); ryczałt 4,9% z 3 progami podstawy "
           "(60%/100%/180% przeciętnego wynagrodzenia); karta podatkowa 9% od minimalnego. Składki społeczne: "
           "emerytalna 19,52%, rentowa 8%, chorobowa 2,45%, wypadkowa 1,67%; ulga na start (Art. 18a, 6 mies.), "
           "preferencyjny (Art. 18c, 24 mies.), Mały ZUS+ (36 mies., 30% minimalnego — SPRAWDŹ nowe limity 2026); "
           "terminy (10/15/20 dzień miesiąca); zasiłki (chorobowy, macierzyński, opiekuńczy — micro/zasilkowa); "
           "PPK/PFRON (ppk_pfron_enterprise); składka solidarnościowa (solidarity_auto_calc_enterprise); "
           "pracownicy (employer.rego, mpips.rego, p19_hr_swiadczenia_innovations_v9, insurance_tracker_enterprise). "
           "Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: kalkulator optymalnej składki zdrowotnej "
           "z symulacją „co by było gdyby\", automatyczny tracker ulg ZUS z alarmami terminów, precyzyjny silnik "
           "podstawy wymiaru (health_precision_engine_v8, cumulative_revenue_engine), temporalność składek."),
    kategorie=[
        ("ZUS TOP-LEVEL (rules/)", ["zus.rego", "employer.rego", "mpips.rego", "ppk_pfron_enterprise.rego",
          "solidarity_auto_calc_enterprise.rego", "insurance_tracker_enterprise.rego",
          "p19_hr_swiadczenia_innovations_v9.rego"]),
        ("ZUS CORE (rules/zus/)", ["rules/zus/plan23_interactions.rego", "rules/zus/plan42_benefits.rego",
          "rules/zus/enterprise_benefits.rego", "rules/zus/sickness_benefits_enterprise.rego",
          "rules/zus/health_contribution_enterprise.rego", "rules/zus/health_precision_engine_v8.rego",
          "rules/zus/cumulative_revenue_engine.rego"]),
        ("ZUS MICRO SUS (rules/micro/sus/ — 16 plików)", ["rules/micro/sus/sus.rego", "rules/micro/sus/sus_a6.rego",
          "rules/micro/sus/sus_a6b.rego", "rules/micro/sus/sus_a9.rego", "rules/micro/sus/sus_a11.rego",
          "rules/micro/sus/sus_a13.rego", "rules/micro/sus/sus_a14.rego", "rules/micro/sus/sus_a18.rego",
          "rules/micro/sus/sus_a18a.rego", "rules/micro/sus/sus_a18c.rego", "rules/micro/sus/sus_a19.rego",
          "rules/micro/sus/sus_a22.rego", "rules/micro/sus/sus_a24.rego", "rules/micro/sus/sus_a36.rego",
          "rules/micro/sus/sus_a40.rego", "rules/micro/sus/sus_a47.rego"]),
        ("ZUS MICRO ZDROWOTNA (rules/micro/zdrowotna/ — 7 plików)", ["rules/micro/zdrowotna/zdrowotna.rego",
          "rules/micro/zdrowotna/zdrowotna_a79.rego", "rules/micro/zdrowotna/zdrowotna_a81.rego",
          "rules/micro/zdrowotna/zdrowotna_a81b.rego", "rules/micro/zdrowotna/zdrowotna_a81c.rego",
          "rules/micro/zdrowotna/zdrowotna_a81d.rego", "rules/micro/zdrowotna/zdrowotna_a82.rego"]),
        ("ZUS MICRO ZASIŁKOWA (rules/micro/zasilkowa/ — 5 plików)", ["rules/micro/zasilkowa/zasilkowa.rego",
          "rules/micro/zasilkowa/zasilkowa_a19.rego", "rules/micro/zasilkowa/zasilkowa_a29.rego",
          "rules/micro/zasilkowa/zasilkowa_a32.rego", "rules/micro/zasilkowa/zasilkowa_a33.rego"]),
        ("ZUS MICRO LOOSE + INNOWACJE (rules/micro/, rules/)", ["rules/micro/plan33_zus.rego",
          "rules/micro/plan34_zus.rego", "p07_zus_macro_innovations_v8.rego", "p07_zus_macro_innovations_v9.rego",
          "p08_zus_macro_enterprise_v9.rego", "p08_zus_micro_innovations_v8.rego",
          "p08_zus_micro_innovations_v9.rego"]),
        ("ZUS MICRO RATES + HEALTH (rules/micro/)", ["rules/micro/_zus_micro_rates.rego",
          "rules/micro/plan33_health.rego"]),
        ("REFERENCJE (bundles/ — ⚠️ czytaj SELEKTYWNIE)", ["bundles/zus_micro_inventory.json"]),
    ],
    related=["00, 04, 08"],
    next="07_KKS.txt",
    uwagi=("`zus_micro_inventory.json` czytaj selektywnie. **Zweryfikuj limity 2026** (składka zdrowotna, "
           "Mały ZUS+) względem aktualnych przepisów i wskaż reguły wymagające aktualizacji."),
))

# ============================= 07 KKS =============================
CZESCI.append(dict(
    num=7, tytul="KKS — Kodeks Karny Skarbowy (czynny żal, sankcje, kary, obrona, GAAR, sanctions)",
    persona="Najwyższej Klasy Ekspertem w Kodeksie Karnym Skarbowym (KKS), odpowiedzialności karnej skarbowej, "
            "czynnym żalu, sankcjach podatkowych i systemach OPA/Rego klasy ENTERPRISE.",
    raport="RAPORT_07_KKS.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu KKS na zaawansowanym poziomie "
           "Enterprise. Priorytet: **CZYNNY ŻAL (Art. 16), Art. 54 (uchylanie się od opodatkowania), Art. 56 "
           "(nierzetelne księgi), Art. 57 (nierzetelna ewidencja VAT), Art. 62 (puste faktury)** — zgodnie z "
           "legal_coverage_gaps.json to 5 luk P1! Oceń: kks.rego (~63 tys. tokenów), rules/kks/* (enterprise_penalties, "
           "kks_innovations_v8, plan42_detailed, plan43_decomposition, plan44_kks_conviction), micro/kks/kks.rego, "
           "p09/p10 innovations, penalty_ai_enterprise, sanctions_optimization_enterprise, "
           "sanctions_supplements_enterprise, gaar_shield_enterprise, rules/risk/plan26_kks.rego. Sprawdź: kary "
           "i grzywny (stawki dzienne, górne limity 500 000 zł), przedawnienie karalności (Art. 44 KKS, 5 lat), "
           "obowiązki po stronie płatnika, voluntary disclosure, kalkulator kar, symulacje. Wymyśl innowacyjne "
           "ulepszenia wyprzedzające profesjonalistów: silnik predykcji ryzyka karnego per transakcja, "
           "automatyczny „czynny żal w jednym kliknięciu\" z pełną dokumentacją, kalkulator kar z temporalnością, "
           "defense builder dla postępowań (strategia 4-ścieżkowa), monitoring sankcji."),
    kategorie=[
        ("KKS TOP-LEVEL (rules/)", ["kks.rego", "_kks_micro_rates.rego", "penalty_ai_enterprise.rego",
          "sanctions_optimization_enterprise.rego", "sanctions_supplements_enterprise.rego",
          "gaar_shield_enterprise.rego", "p33_ordpu_kks_supplement.rego", "p09_kks_macro_innovations_v8.rego",
          "p10_kks_micro_innovations_v8.rego", "p10_kks_innovations_v9.rego"]),
        ("KKS CORE (rules/kks/)", ["rules/kks/_kks_macro_rates.rego", "rules/kks/enterprise_penalties.rego",
          "rules/kks/kks_innovations_v8.rego", "rules/kks/plan42_detailed.rego", "rules/kks/plan43_decomposition.rego",
          "rules/kks/plan44_kks_conviction.rego"]),
        ("KKS MICRO + RISK (rules/micro/, rules/risk/)", ["rules/micro/kks/kks.rego", "rules/risk/plan26_kks.rego",
          "rules/micro/plan33_kks.rego"]),
        ("REFERENCJE (bundles/ — ⚠️ czytaj SELEKTYWNIE)", ["bundles/legal_coverage_gaps.json"]),
    ],
    related=["00, 08, 02"],
    next="08_ORDYNACJA_OBRONA.txt",
))

# ============================= 08 ORDYNACJA =============================
CZESCI.append(dict(
    num=8, tytul="ORDYNACJA PODATKOWA + OBRONA PODATNIKA (postępowania, przedawnienie, korekty, KAS, sądy)",
    persona="Najwyższej Klasy Ekspertem w Ordynacji Podatkowej (Dz.U. 2025 poz. 234), postępowaniach "
            "podatkowych, kontrolach KAS, sądach administracyjnych i obronie praw podatnika.",
    raport="RAPORT_08_ORDYNACJA_OBRONA.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu ORDYNACJI PODATKOWEJ i OBRONY "
           "PODATNIKA na zaawansowanym poziomie Enterprise. Priorytety: przedawnienie zobowiązań (Art. 70, 5 lat), "
           "korekty deklaracji (Art. 81/81b), terminy (Art. 12, 47, 56 — odsetki), postępowania podatkowe "
           "(Art. 120–129), kontrola podatkowa (Art. 281–292), zobowiązania (Art. 21–26), ulga w spłacie "
           "(Art. 67a), interpretacje (Art. 14b), Biała Lista (Art. 117ba), odsetki (Art. 56, 57); KKS-powiązane "
           "audyty (rules/audit/*: plan44_audit, plan45_audit, runtime_invariants_enterprise); narzędzia obrony: "
           "audit_defense_enterprise, defense_builder_enterprise, tax_authority_interaction_enterprise, "
           "tax_correspondence_engine_enterprise, tax_ruling_autodrafter_enterprise, overpayment_auto_claimer_enterprise, "
           "proceeding_tracker_enterprise, poa_manager_enterprise, judicial_interpretations_enterprise, "
           "judicial_trend_enterprise, financial_hardship_scorer_enterprise, deadline_monitor_enterprise, "
           "interest_calculator_enterprise, exit_tax_interest_calculator, statute_of_limitations, "
           "ord_supplements_enterprise, rules/ord/ord_innovations_v8.rego, micro/ord/ord.rego, "
           "micro/plan33_ord, micro/plan34_ord, p11_ordynacja_podatkowa_innovations_v9. "
           "Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: kalkulator odsetek z pełną temporalnością, "
           "asystent postępowania (każdy termin z 3 poziomami alertów), auto-generator korespondencji z US z "
           "podstawą prawną, predykcja wyroków WSA/NSA (judgment_predictor), monitor przedawnień z dowodem."),
    kategorie=[
        ("ORDYNACJA (rules/, rules/ord/, rules/micro/ord/)", ["rules/ord/ord_innovations_v8.rego",
          "rules/micro/ord/ord.rego", "rules/micro/plan33_ord.rego", "rules/micro/plan34_ord.rego",
          "ord_supplements_enterprise.rego", "p11_ordynacja_podatkowa_innovations_v9.rego",
          "statute_of_limitations.rego", "rules/statute/plan26_detailed.rego",
          "interest_calculator_enterprise.rego", "exit_tax_interest_calculator.rego",
          "deadline_monitor_enterprise.rego"]),
        ("OBRONA PODATNIKA (rules/)", ["tax_authority_interaction_enterprise.rego",
          "tax_correspondence_engine_enterprise.rego", "tax_ruling_autodrafter_enterprise.rego",
          "overpayment_auto_claimer_enterprise.rego", "proceeding_tracker_enterprise.rego",
          "defense_builder_enterprise.rego", "audit_defense_enterprise.rego", "judicial_interpretations_enterprise.rego",
          "judicial_trend_enterprise.rego", "financial_hardship_scorer_enterprise.rego", "poa_manager_enterprise.rego"]),
        ("AUDYT KAS (rules/audit/)", ["rules/audit/plan44_audit.rego", "rules/audit/plan45_audit.rego",
          "rules/audit/runtime_invariants_enterprise.rego"]),
    ],
    related=["00, 07, 02, 04"],
    next="09_UOR_KSIEGOWOSC.txt",
))

# ============================= 09 UoR =============================
CZESCI.append(dict(
    num=9, tytul="UoR / PKPiR / KSIĘGOWOŚĆ (pełna księgowość, księgi, kolumny PKPiR, amortyzacja, transformacja)",
    persona="Najwyższej Klasy Ekspertem w ustawie o rachunkowości (Dz.U. 2025 poz. 567), PKPiR (rozporządzenie MF "
            "15.11.2025), pełnej księgowości, inwentaryzacji i automatyzacji księgowości klasy ENTERPRISE.",
    raport="RAPORT_09_UOR_KSIEGOWOSC.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu KSIĘGOWOŚCI (UoR/PKPiR) na "
           "zaawansowanym poziomie Enterprise. **To jedna z największych luk wg LEGAL_COVERAGE.md: pokrycie UoR "
           "~0% (martwa warstwa PKPiR z matched:false)!** Oceń: accounting.rego (~22 tys. tokenów), "
           "rules/accounting/* (pkpir_enterprise_live, pkpir_enterprise_validation, pkpir_enterprise_validator, "
           "uor_enterprise_live, depreciation_enterprise, depreciation_enterprise_complete, plan23_leasing, "
           "plan42_pkpir), rules/uor/* (9 plików: uor_books, uor_assets, uor_costs, uor_revenue, uor_obligation, "
           "uor_closing, uor_inventory, uor_financial_stmt, plan42_uor), micro/uor/uor.rego, micro/pkpir/* "
           "(7 plików: pkpir, pkpir_kolumny, pkpir_przychody, pkpir_koszty, pkpir_nkup, pkpir_remanent, "
           "pkpir_korekty), micro/amortyzacja/* (pit_a22a, pit_a22i, pit_a22k, pit_a22n), "
           "pkpir_to_uor_transformer.rego, p09/p11/p12 innovations, p33_uor_supplement, "
           "p18_automatyzacja_ksiegowosci_innovations_v9. Sprawdź: kompletność 17 kolumn PKPiR, remanent, "
           "walidację kolumn, amortyzację (KŚT, limity 150 000/225 000), leasing, sprawozdanie finansowe, "
           "inwentaryzację, progi pełnej księgowości (2 000 000 EUR). Wymyśl innowacyjne ulepszenia wyprzedzające "
           "profesjonalistów: pełny automatyzm księgowania z podwójnym zapisem (TigerBeetle/Shadow Ledger), "
           "transformator PKPiR→UoR, automatyczna walidacja kolumn z dowodem zgodności z rozporządzeniem, "
           "system „zero martwych reguł\" dla warstwy księgowej."),
    kategorie=[
        ("KSIĘGOWOŚĆ TOP-LEVEL (rules/)", ["accounting.rego", "pkpir_to_uor_transformer.rego", "_pkpir_rates.rego",
          "_uor_rates.rego", "p09_ksiegowosc_pkpir_uor_innovations_v9.rego", "p11_accounting_pkpir_innovations_v8.rego",
          "p12_uor_innovations_v8.rego", "p33_uor_supplement.rego", "p18_automatyzacja_ksiegowosci_innovations_v9.rego"]),
        ("KSIĘGOWOŚĆ CORE (rules/accounting/)", ["rules/accounting/pkpir_enterprise_live.rego",
          "rules/accounting/pkpir_enterprise_validation.rego", "rules/accounting/pkpir_enterprise_validator.rego",
          "rules/accounting/uor_enterprise_live.rego", "rules/accounting/depreciation_enterprise.rego",
          "rules/accounting/depreciation_enterprise_complete.rego", "rules/accounting/plan23_leasing.rego",
          "rules/accounting/plan42_pkpir.rego"]),
        ("UoR (rules/uor/)", ["rules/uor/plan42_uor.rego", "rules/uor/uor_assets.rego", "rules/uor/uor_books.rego",
          "rules/uor/uor_closing.rego", "rules/uor/uor_costs.rego", "rules/uor/uor_financial_stmt.rego",
          "rules/uor/uor_inventory.rego", "rules/uor/uor_obligation.rego", "rules/uor/uor_revenue.rego"]),
        ("UoR/PKPiR MICRO (rules/micro/)", ["rules/micro/uor/uor.rego", "rules/micro/plan33_uor.rego",
          "rules/micro/pkpir/pkpir.rego",
          "rules/micro/pkpir/pkpir_kolumny.rego", "rules/micro/pkpir/pkpir_przychody.rego",
          "rules/micro/pkpir/pkpir_koszty.rego", "rules/micro/pkpir/pkpir_nkup.rego",
          "rules/micro/pkpir/pkpir_remanent.rego", "rules/micro/pkpir/pkpir_korekty.rego",
          "rules/micro/amortyzacja/pit_a22a.rego", "rules/micro/amortyzacja/pit_a22i.rego",
          "rules/micro/amortyzacja/pit_a22k.rego", "rules/micro/amortyzacja/pit_a22n.rego"]),
        ("REFERENCJE (bundles/ — ⚠️ czytaj SELEKTYWNIE)", ["bundles/accounting_compliance.json"]),
    ],
    related=["00, 04, 16"],
    next="10_CROSSBORDER.txt",
))

# ============================= 10 CROSSBORDER =============================
CZESCI.append(dict(
    num=10, tytul="CROSS-BORDER / TP / MDR-DAC6 / CFC / ViDA / CBAM / DAC8 (transakcje zagraniczne)",
    persona="Ekspertem ENTERPRISE od transakcji transgranicznych JDG (WDT, WNT, eksport, import, usługi), cen "
            "transferowych, MDR/DAC6, CFC, ViDA, CBAM, DAC8 i podatku u źródła.",
    raport="RAPORT_10_CROSSBORDER.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu CROSS-BORDER na zaawansowanym "
           "poziomie Enterprise. **Pokrycie cross-border wg LEGAL_COVERAGE.md <2% — jedna z największych luk!** "
           "Oceń: crossborder.rego, international.rego, international_expanded.rego, rules/crossborder/* "
           "(exit_tax_cfc_complete, plan23_ue, post_brexit), micro/crossborder/crossborder.rego, "
           "p12_crossborder_innovations_v9, p13_crossborder_innovations_v8, vida_drr_full.rego, cbam_full.rego, "
           "dac8_report_generator.rego, cfc_auto_classifier.rego, mdr_auto_generator.rego, mdr_dac6_enterprise.rego, "
           "wdt_document_tracker.rego, cross_jurisdiction_ruling_enterprise.rego, cross_domain_intelligence_enterprise.rego, "
           "p3233_innovations.rego, rules/tp/* (plan44_tp, plan45_tp), rules/mdr/* (mdr_enterprise, mdr_hallmarks, "
           "plan44_mdr, plan45_mdr), _crossborder_rates.rego. Sprawdź: WDT (30 dni, limit eksportowy), WNT, "
           "eksport pośredni, import usług (reverse charge), miejsce świadczenia (Art. 28a–28o), kursy NBP "
           "(temporalność), TP (transakcje z podmiotami powiązanymi, dokumentacja), MDR/DAC6 (schemata, hallmarks, "
           "terminy 30 dni), CFC (próg 50%/33%), ViDA/DRR, CBAM, DAC8 (krypto). Wymyśl innowacyjne ulepszenia "
           "wyprzedzające profesjonalistów: automatyczny klasyfikator transakcji transgranicznych z łańcuchem "
           "podstaw prawnych, tracker WDT z alarmem 30 dni, auto-generator dokumentacji TP, harmonizacja z "
           "kursami NBP z pełnym time-travel."),
    kategorie=[
        ("CROSS-BORDER TOP-LEVEL (rules/)", ["crossborder.rego", "international.rego", "international_expanded.rego",
          "_crossborder_rates.rego", "vida_drr_full.rego", "cbam_full.rego", "dac8_report_generator.rego",
          "cfc_auto_classifier.rego", "mdr_auto_generator.rego", "mdr_dac6_enterprise.rego",
          "wdt_document_tracker.rego", "cross_jurisdiction_ruling_enterprise.rego",
          "cross_domain_intelligence_enterprise.rego", "p3233_innovations.rego", "p12_crossborder_innovations_v9.rego",
          "p13_crossborder_innovations_v8.rego"]),
        ("CROSS-BORDER CORE + MICRO (rules/)", ["rules/crossborder/exit_tax_cfc_complete.rego",
          "rules/crossborder/plan23_ue.rego", "rules/crossborder/post_brexit.rego",
          "rules/micro/crossborder/crossborder.rego"]),
        ("TP + MDR (rules/)", ["rules/tp/plan44_tp.rego", "rules/tp/plan45_tp.rego", "rules/mdr/mdr_enterprise.rego",
          "rules/mdr/mdr_hallmarks.rego", "rules/mdr/plan44_mdr.rego", "rules/mdr/plan45_mdr.rego"]),
        ("CROSS-BORDER MICRO LOOSE (rules/micro/)", ["rules/micro/plan33_cb.rego", "rules/micro/plan33_tp.rego",
          "rules/micro/plan33_mdr.rego"]),
    ],
    related=["00, 02, 08"],
    next="11_PCC_LOKALNE_AKCYZA.txt",
))

# ============================= 11 PCC/LOKALNE/AKCYZA =============================
CZESCI.append(dict(
    num=11, tytul="PCC / PODATKI LOKALNE / AKCYZĄ (nieruchomości, środki transportu, umowy, paliwo, alkohol)",
    persona="Ekspertem ENTERPRISE od podatku PCC, podatków lokalnych (nieruchomości, środki transportu), "
            "podatku akcyzowego i opłat lokalnych dla JDG.",
    raport="RAPORT_11_PCC_LOKALNE_AKCYZA.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu PCC/LOKALNE/AKCYZA na zaawansowanym "
           "poziomie Enterprise. **Pokrycie PCC+lokalne+akcyza wg LEGAL_COVERAGE.md ~1% (225 pkt) — NAJWIĘKSZA "
           "LUKA!** Oceń: local_taxes.rego, rules/local_taxes/* (10 plików: pcc.rego, pcc_enterprise_complete, "
           "pcc_excise_enterprise, excise_enterprise_complete, local_procedures_enterprise, plan26_local, "
           "real_estate, transport, akcyza_fuel, akcyza_alcohol), micro/pcc/pcc.rego, micro/akcyza (katalog — "
           "1 plik), micro/transport/transport.rego, p14_pcc_lokalne_akcyza_innovations_v9, "
           "p15_pcc_local_excise_innovations_v8, p33_pcc_complete, p33_excise_supplement, _pcc_local_excise_rates.rego. "
           "Sprawdź: PCC (umowy sprzedaży, pożyczki, spółki — stawki 0,5%/1%/2%, wyłączenia, obowiązek 14 dni), "
           "podatek od nieruchomości (stawki uchwał gmin, budynki/grunty), środki transportu, akcyza (paliwo, "
           "alkohol, inne wyroby — legalność obrotu, dokumenty), opłaty lokalne. Wymyśl innowacyjne ulepszenia "
           "wyprzedzające profesjonalistów: silnik „pcc w 1 kliknięcie\" (PCC-3 auto), baza stawek lokalnych z "
           "temporalnością i hot-reload, klasyfikator wyrobów akcyzowych z pełną podstawą prawną, kalendarz "
           "terminów lokalnych."),
    kategorie=[
        ("PCC/LOKALNE/AKCYZA TOP-LEVEL (rules/)", ["local_taxes.rego", "_pcc_local_excise_rates.rego",
          "p14_pcc_lokalne_akcyza_innovations_v9.rego", "p15_pcc_local_excise_innovations_v8.rego",
          "p33_pcc_complete.rego", "p33_excise_supplement.rego"]),
        ("PCC/LOKALNE/AKCYZA CORE (rules/local_taxes/)", ["rules/local_taxes/pcc.rego",
          "rules/local_taxes/pcc_enterprise_complete.rego", "rules/local_taxes/pcc_excise_enterprise.rego",
          "rules/local_taxes/excise_enterprise_complete.rego", "rules/local_taxes/local_procedures_enterprise.rego",
          "rules/local_taxes/plan26_local.rego", "rules/local_taxes/real_estate.rego",
          "rules/local_taxes/transport.rego", "rules/local_taxes/akcyza_fuel.rego",
          "rules/local_taxes/akcyza_alcohol.rego"]),
        ("PCC/AKCYZA/TRANSPORT MICRO (rules/micro/)", ["rules/micro/pcc/pcc.rego",
          "rules/micro/transport/transport.rego", "rules/micro/akcyza/akcyza.rego",
          "rules/micro/plan33_pcc.rego", "rules/micro/plan33_prop_transport.rego",
          "rules/micro/plan33_agricultural_tax.rego"]),
        ("PCC CORE (rules/pcc/)", ["rules/pcc/pcc_companies.rego", "rules/pcc/pcc_loans.rego",
          "rules/pcc/pcc_rates.rego", "rules/pcc/pcc_sales.rego", "rules/pcc/plan42_pcc.rego"]),
    ],
    related=["00, 09, 12"],
    next="12_RYCZALT_CYKL_ZYCIE.txt",
    uwagi=("Jeśli nie znasz dokładnej nazwy pliku w rules/micro/akcyza/, przeczytaj katalog "
           "https://github.com/Gorski-Maciej/NexusAI/tree/main/JDG/rules/micro/akcyza — tam jest 1 plik."),
))

# ============================= 12 RYCZAŁT/CYKL ŻYCIA =============================
CZESCI.append(dict(
    num=12, tytul="RYCZAŁT / CEIDG / PRAWO PRZEDSIĘBIORCÓW / SUKCESJA / BUDOWNICTWO / CYKL ŻYCIA FIRMY",
    persona="Ekspertem ENTERPRISE od ryczałtu ewidencjonowanego (Dz.U. 2025 poz. 234), CEIDG, Prawa "
            "przedsiębiorców (Dz.U. 2025 poz. 123), sukcesji firm i cyklu życia JDG.",
    raport="RAPORT_12_RYCZALT_CYKL_ZYCIE.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu RYCZAŁT/CEIDG/PRAWO "
           "PRZEDSIĘBIORCÓW/SUKCESJA/BUDOWNICTWO na zaawansowanym poziomie Enterprise. **Pokrycie ryczałtu wg "
           "LEGAL_COVERAGE.md ~20%, prawa przedsiębiorców ~10%.** Oceń: micro/ryczalt/ryczalt.rego (stawki PKWiU, "
           "limit 2 mln EUR), micro/ceidg/ceidg.rego (wpis, zmiana, wykreślenie, Art. 5–15), micro/pp/pp.rego "
           "(Art. 4–25: definicja przedsiębiorcy, działalność nieewidencjonowana, zawieszenie, prokura), "
           "micro/sukcesja/sukcesja.rego (zarząd sukcesyjny, Art. 3–15), micro/budownictwo/budownictwo.rego "
           "(Prawo budowlane), business.rego, rules/business/* (gig_economy, plan26_suspension_succession, "
           "strategic_intelligence), p13_ryczalt_cykl_zycia_innovations_v9, p16_business_lifecycle_innovations_v8, "
           "lifecycle_manager_enterprise, restructuring.rego, _business_lifecycle_rates.rego. Sprawdź: stawki "
           "ryczałtu wg kodów PKWiU (8,5%, 12,5%, 17%, 20%, 25%?), limity, zawieszenie (Art. 22–25 PP), "
           "działalność nieewidencjonowaną (Art. 5 PP, 50% płacy minimalnej), sukcesję, gig economy. Wymyśl "
           "innowacyjne ulepszenia wyprzedzające profesjonalistów: automatyczny klasyfikator PKWiU→stawka ryczałtu, "
           "asystent zawieszenia/wznowienia z kalendarzem, symulator „JDG vs etat vs spółka\", monitor limitu "
           "2 mln EUR w czasie rzeczywistym."),
    kategorie=[
        ("RYCZAŁT/CEIDG/PP/SUKCESJA/BUDOWNICTWO (rules/micro/)", ["rules/micro/ryczalt/ryczalt.rego",
          "rules/micro/ceidg/ceidg.rego", "rules/micro/pp/pp.rego", "rules/micro/sukcesja/sukcesja.rego",
          "rules/micro/budownictwo/budownictwo.rego"]),
        ("CYKL ŻYCIA (rules/)", ["business.rego", "_business_lifecycle_rates.rego", "restructuring.rego",
          "lifecycle_manager_enterprise.rego", "p13_ryczalt_cykl_zycia_innovations_v9.rego",
          "p16_business_lifecycle_innovations_v8.rego", "rules/business/gig_economy.rego",
          "rules/business/plan26_suspension_succession.rego", "rules/business/strategic_intelligence.rego"]),
        ("RYCZAŁT/CEIDG/SUKCESJA MICRO LOOSE (rules/micro/)", ["rules/micro/plan33_ryc.rego",
          "rules/micro/plan33_ceidg.rego", "rules/micro/plan33_succ.rego"]),
    ],
    related=["00, 13, 11"],
    next="13_HYPER_CYKL_FIRMY.txt",
))

# ============================= 13 HYPER PLAN45 =============================
CZESCI.append(dict(
    num=13, tytul="HYPER PLAN45 + REPREZENTACJA + DZIAŁALNOŚĆ REGULOWANA + KONTEKSTY SPECJALNE",
    persona="Ekspertem ENTERPRISE od hiper-szczegółowych reguł Plan45 (terminy, limity, sankcje, prokura, "
            "działalność regulowana, sezonowa, rodzinna, siła wyższa, waluty, e-Doręczenia).",
    raport="RAPORT_13_HYPER_CYKL_FIRMY.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę warstwy HYPER PLAN45 na zaawansowanym "
           "poziomie Enterprise. Oceń WSZYSTKIE pary plan44/plan45 w podkatalogach rules/ oraz rules/jdg/hyper/** "
           "(14 plików: audit, deadlines, edelivery, family, force_majeure, fx, general, limits, mdr, misc, "
           "procurement, sanctions, solidarity, wis): representation (prokura, plan26_prokura), esig (e-Signature), "
           "calendar (terminy, weekendy, święta), taxfree, seasonal (sezonowość), conviction (konsekwencje "
           "skazań), regulated (działalność regulowana), insurance (ubezpieczenia), family (rodzina), "
           "force_majeure (siła wyższa), fx (waluty), procurement (zamówienia), payments (płatności), residency "
           "(rezydencja), solidarity (solidarność), advertising (reklama/progowanie). Oraz top-level: "
           "representation.rego, regulated_compliance_enterprise.rego, conviction_checker_enterprise.rego, "
           "esig_auto_applicator_enterprise.rego, calendar_notifier_enterprise.rego, conflicts.rego, "
           "conflict_declaration_enterprise.rego, p17_edge_conflicts_innovations_v8.rego, "
           "_edge_cases_conflicts_rates.rego. Sprawdź spójność terminów z kalendarzem ustawowym, limity, "
           "sankcje i reguły konfliktów między domenami. Wymyśl innowacyjne ulepszenia wyprzedzające "
           "profesjonalistów: inteligentny kalendarz terminów (weekendy/święta z automatycznym przesunięciem), "
           "deklaratywne szablony dla nowych kontekstów (dodanie reguły = 8 pól), detektor konfliktów "
           "międzydomenowych POST-MERGE, sieć zależności między regułami hyper a macro."),
    kategorie=[
        ("HYPER PLAN45 (rules/jdg/hyper/ — 14 plików)", ["rules/jdg/hyper/audit/plan45.rego",
          "rules/jdg/hyper/deadlines/plan45.rego", "rules/jdg/hyper/edelivery/plan45.rego",
          "rules/jdg/hyper/family/plan45.rego", "rules/jdg/hyper/force_majeure/plan45.rego",
          "rules/jdg/hyper/fx/plan45.rego", "rules/jdg/hyper/general/plan45.rego", "rules/jdg/hyper/limits/plan45.rego",
          "rules/jdg/hyper/mdr/plan45.rego", "rules/jdg/hyper/misc/plan45.rego", "rules/jdg/hyper/procurement/plan45.rego",
          "rules/jdg/hyper/sanctions/plan45.rego", "rules/jdg/hyper/solidarity/plan45.rego", "rules/jdg/hyper/wis/plan45.rego"]),
        ("KONTEKSTY plan44/45 (rules/ — pary)", ["rules/representation/plan26_prokura.rego",
          "rules/esig/plan44_esig.rego", "rules/esig/plan45_esig.rego", "rules/calendar/plan44_calendar.rego",
          "rules/calendar/plan45_calendar.rego", "rules/taxfree/plan44_taxfree.rego", "rules/taxfree/plan45_taxfree.rego",
          "rules/seasonal/plan44_seasonal.rego", "rules/seasonal/plan45_seasonal.rego",
          "rules/conviction/plan44_conviction.rego", "rules/conviction/plan45_conviction.rego",
          "rules/regulated/plan44_regulated.rego", "rules/regulated/plan45_regulated.rego",
          "rules/insurance/plan44_insurance.rego", "rules/insurance/plan45_insurance.rego",
          "rules/family/plan44_family.rego", "rules/family/plan45_family.rego",
          "rules/force_majeure/plan44_force_majeure.rego", "rules/force_majeure/plan45_force_majeure.rego",
          "rules/fx/plan44_fx.rego", "rules/fx/plan45_fx.rego", "rules/procurement/plan44_procurement.rego",
          "rules/procurement/plan45_procurement.rego", "rules/payments/plan44_payments.rego",
          "rules/payments/plan45_payments.rego", "rules/residency/plan44_residency.rego",
          "rules/residency/plan45_residency.rego", "rules/solidarity/plan44_solidarity.rego",
          "rules/solidarity/plan45_solidarity.rego", "rules/advertising/plan44_advertising.rego",
          "rules/advertising/plan45_advertising.rego"]),
        ("KONFLIKTY + TOP-LEVEL (rules/)", ["conflicts.rego", "conflict_declaration_enterprise.rego",
          "p17_edge_conflicts_innovations_v8.rego", "_edge_cases_conflicts_rates.rego",
          "representation.rego", "regulated_compliance_enterprise.rego", "conviction_checker_enterprise.rego",
          "esig_auto_applicator_enterprise.rego", "calendar_notifier_enterprise.rego"]),
    ],
    related=["00, 12, 01"],
    next="14_RODO_AML_BDO.txt",
))

# ============================= 14 RODO/AML/BDO =============================
CZESCI.append(dict(
    num=14, tytul="RODO / AML-CBDD / BDO / ŚRODOWISKO / SEKURYTYZACJA (bezpieczeństwo i zgodność)",
    persona="Ekspertem ENTERPRISE od RODO, AML/CBDD, BDO (baza danych o produktach i opakowaniach), ochrony "
            "środowiska i bezpieczeństwa danych w systemach finansowych.",
    raport="RAPORT_14_RODO_AML_BDO.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu RODO/AML/BDO/ŚRODOWISKO na "
           "zaawansowanym poziomie Enterprise. **Pokrycie AML/RODO/BDO wg LEGAL_COVERAGE.md ~5%.**"
           "Oceń: rodo.rego, rodo_extended.rego, rules/rodo/plan42_rodo.rego, rules/micro/rodo/* (6 plików: rodo, "
           "rodo_ai_marketing, rodo_erasure, rodo_podprocesorzy, rodo_sankcje, rodo_zatrudnienie — Art. 17, 28, 30, "
           "83 RODO), rules/micro/aml/* (5 plików: aml, aml_cbdd, aml_ryzyko, aml_str_gif, aml_transakcje — ustawa "
           "o AML/CBDD), rules/micro/bdo/* (6 plików: bdo_ewc, bdo_ewidencja, bdo_rejestracja, bdo_transport, "
           "bdo_weee_baterie, bdo_zezwolenia), micro/srodowisko/srodowisko.rego, environmental.rego, "
           "rules/environmental/bdo_enterprise.rego, p15_srodowisko_bdo_innovations_v9.rego, "
           "p16_rodo_aml_security_innovations_v9.rego, rules/security/security_fortress_v8.rego, "
           "rules/compliance/aml_enterprise.rego, rules/micro/srodowisko/srodowisko.rego. Sprawdź: rejestr czynności (Art. 30), prawo do usunięcia "
           "(Art. 17), sankcje (Art. 83), podprocesorzy (Art. 28), obowiązki AML (rejestracja, CBBD, STR do GIF, "
           "ocena ryzyka), BDO (rejestracja, ewidencja, WEEE, baterie, opakowania, transport). Wymyśl "
           "innowacyjne ulepszenia wyprzedzające profesjonalistów: automatyczny rejestr czynności z mapą "
           "przetwarzania, silnik oceny ryzyka AML z scoringiem kontrahentów, monitor obowiązków BDO z "
           "kalendarzem, integracja z Decision Certificate (każdy werdykt zgodny z RODO)."),
    kategorie=[
        ("RODO (rules/)", ["rodo.rego", "rodo_extended.rego", "rules/rodo/plan42_rodo.rego",
          "rules/micro/rodo/rodo.rego", "rules/micro/rodo/rodo_ai_marketing.rego",
          "rules/micro/rodo/rodo_erasure.rego", "rules/micro/rodo/rodo_podprocesorzy.rego",
          "rules/micro/rodo/rodo_sankcje.rego", "rules/micro/rodo/rodo_zatrudnienie.rego"]),
        ("AML (rules/)", ["rules/compliance/aml_enterprise.rego", "rules/micro/aml/aml.rego",
          "rules/micro/aml/aml_cbdd.rego", "rules/micro/aml/aml_ryzyko.rego", "rules/micro/aml/aml_str_gif.rego",
          "rules/micro/aml/aml_transakcje.rego"]),
        ("BDO/ŚRODOWISKO (rules/)", ["environmental.rego", "rules/environmental/bdo_enterprise.rego",
          "rules/micro/bdo/bdo_ewc.rego", "rules/micro/bdo/bdo_ewidencja.rego", "rules/micro/bdo/bdo_rejestracja.rego",
          "rules/micro/bdo/bdo_transport.rego", "rules/micro/bdo/bdo_weee_baterie.rego",
          "rules/micro/bdo/bdo_zezwolenia.rego", "rules/micro/srodowisko/srodowisko.rego"]),
        ("SEKURYTYZACJA + INNOWACJE (rules/)", ["rules/security/security_fortress_v8.rego",
          "p15_srodowisko_bdo_innovations_v9.rego", "p16_rodo_aml_security_innovations_v9.rego",
          "rules/micro/plan33_rodo.rego"]),
    ],
    related=["00, 16, 01"],
    next="15_KSEF_JPK_DEKLARACJE.txt",
))

# ============================= 15 KSeF/JPK =============================
CZESCI.append(dict(
    num=15, tytul="KSeF / JPK / e-DEKLARACJE / e-DORĘCZENIA / WIS / GTU (obowiązki elektroniczne)",
    persona="Ekspertem ENTERPRISE od KSeF (Krajowy System e-Faktur, obowiązek od 01.02.2026), JPK_V7M, JPK_CIT, "
            "e-Deklaracji, e-Doręczeń, WIS i kodów GTU.",
    raport="RAPORT_15_KSEF_JPK_DEKLARACJE.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę modułu KSeF/JPK/e-DEKLARACJE na "
           "zaawansowanym poziomie Enterprise. Priorytet: **KSeF 2.0 (obowiązek 01.02.2026, sankcje do 500 000 zł)** — "
           "generacja XML, walidacja XSD, wysyłka online/offline (7 dni), UPO, firewall, monitor sankcji, "
           "sandbox; JPK_V7M (auto-generacja, GTU, kody), JPK_CIT, JPK_KR/ST, deklaracje VAT-7; e-Doręczenia "
           "(edelivery_gateway_enterprise/v2, epuap_enterprise), WIS (wis_api_enterprise, wis_autorequester, "
           "rules/wis/*), GTU (gtu_completeness_checker_enterprise), cross_declaration_validator_enterprise, "
           "corrections.rego, ksef_jpk.rego, rules/jpk/plan26_deadlines.rego, micro/jpk/jpk.rego, "
           "micro/ksef/ksef.rego, p17_ksef_jpk_edeklaracje_innovations_v9, _compliance_rates.rego oraz "
           "ksef_*_enterprise (10 plików) i jpk_*_enterprise (4 pliki). Sprawdź kompletność łańcucha: faktura "
           "→ KSeF → UPO → JPK → deklaracja → audyt. Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: "
           "silnik „zero ręcznej pracy\" dla KSeF (offline queue z retry, firewall przed błędnym NIP), "
           "auto-uzupełnianie GTU z analizą semantyczną, monitor sankcji w czasie rzeczywistym, korelator "
           "deklaracji (VAT-7 ≡ JPK_V7M ≡ księgi)."),
    kategorie=[
        ("KSeF (rules/)", ["ksef_jpk.rego", "ksef_innovations_enterprise.rego", "ksef_upo_tracker_enterprise.rego",
          "ksef_sanction_monitor_enterprise.rego", "ksef_outbox_enterprise.rego", "ksef_firewall_enterprise.rego",
          "ksef_offline_queue_enterprise.rego", "ksef_receipt_digest_enterprise.rego",
          "ksef_resilience_enterprise.rego", "ksef_sandbox_harness_enterprise.rego"]),
        ("JPK (rules/)", ["jpk_cit.rego", "jpk_v7_autogen_enterprise.rego", "jpk_corrections_workflow_enterprise.rego",
          "jpk_kr_st_generator_enterprise.rego", "rules/jpk/plan26_deadlines.rego", "rules/micro/jpk/jpk.rego",
          "rules/micro/ksef/ksef.rego", "rules/micro/plan33_jpk.rego", "rules/micro/plan33_ksef.rego"]),
        ("e-DEKLARACJE / e-DORĘCZENIA / WIS / GTU (rules/)", ["cross_declaration_validator_enterprise.rego",
          "gtu_completeness_checker_enterprise.rego", "edelivery_gateway_enterprise.rego",
          "edelivery_gateway_v2_enterprise.rego", "rules/edelivery/plan44_edelivery.rego",
          "rules/edelivery/plan45_edelivery.rego", "epuap_enterprise.rego", "wis_api_enterprise.rego",
          "wis_autorequester_enterprise.rego", "rules/wis/plan44_wis.rego", "rules/wis/plan45_wis.rego",
          "corrections.rego", "_compliance_rates.rego", "p17_ksef_jpk_edeklaracje_innovations_v9.rego"]),
    ],
    related=["00, 02, 05, 16"],
    next="16_SYSTEM_OPA.txt",
))

# ============================= 16 SYSTEM OPA =============================
CZESCI.append(dict(
    num=16, tytul="SYSTEM OPA — INNOWACJE P18–P35 (OPA jako rozbudowany SYSTEM, automatyzacja, walidacja, audyt)",
    persona="Architektem ENTERPRISE systemów Policy-as-Code — ekspert od cyklu życia reguł, quality pipelines, "
            "weryfikacji formalnej, chaos engineeringu i samouzdrawiania systemów regułowych.",
    raport="RAPORT_16_SYSTEM_OPA.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę „SYSTEMU OPA\" na zaawansowanym poziomie "
           "Enterprise. **To serce wymogu „OPA MUSI BYĆ ROZBUDOWANYM SYSTEMEM\": prawo jest bardzo zmienne, "
           "zmiany reguł oraz dodawanie/usuwanie reguł musi być sprawne, niezawodne i proste, a silnik musi się "
           "szybko i profesjonalnie adaptować do zmian.** Oceń: p21_opa_system_innovations_v9 (policy registry, "
           "canary, shadow), p22_validation_tools_innovations_v9 (bramki jakości), p23_test_rego_ci_innovations_v9 "
           "(CI dla Rego), p24_audyt_kompletny_innovations_v9, p18_automatyzacja_ksiegowosci_innovations_v9, "
           "p20_neural_mesh_innovations_v9, p34_innovations_engine, p34_remaining_fixes, p35_cross_act_coherence, "
           "p35_system_gaps, p35_innovations_engine, p01_core_architecture_innovations_v8, "
           "p01_fundament_innovations_v9, p02_decision_core_innovations_v9, p03_orchestrator_innovations_v9, "
           "p21/p22/p23/p24_innovations_enterprise, rule_lifecycle_enterprise, reliability_guarantee_enterprise, "
           "decision_core_completeness_enterprise, p14_compliance_innovations_v8. Zbuduj KOMPLETNĄ mapę: jak JDG "
           "realizuje (a) dodanie reguły w 7 krokach, (b) zmianę reguły jako nową wersję SHADOW→CANDIDATE→ACTIVE, "
           "(c) bezpieczne usuwanie (deprecate→retire→purge), (d) kill-switch, (e) pipeline ISAP→produkcja ≤24 h "
           "(P0 ≤4 h), (f) parametr hot-reload ≤15 min, (g) bramki CI blokujące (lint, validate, tautologia, "
           "dead-rule, hardcoded, zero-defect, mutation ≥70%, golden replay, impact), (h) filary V2 (Legal Twin, "
           "runtime invariants, Decision Certificate, Law Radar, Declarative Change). Wymyśl innowacyjne "
           "ulepszenia wyprzedzające profesjonalistów — wskaż, czego brakuje do „ufortyfikowanej fortecy\"."),
    kategorie=[
        ("SYSTEM OPA — INNOWACJE (rules/)", ["p01_core_architecture_innovations_v8.rego",
          "p01_fundament_innovations_v9.rego", "p02_decision_core_innovations_v9.rego",
          "p03_orchestrator_innovations_v9.rego", "p14_compliance_innovations_v8.rego",
          "p18_automatyzacja_ksiegowosci_innovations_v9.rego", "p20_neural_mesh_innovations_v9.rego",
          "p21_opa_system_innovations_v9.rego", "p21_innovations_enterprise.rego",
          "p22_validation_tools_innovations_v9.rego", "p22_innovations_enterprise.rego",
          "p23_test_rego_ci_innovations_v9.rego", "p23_innovations_enterprise.rego",
          "p24_audyt_kompletny_innovations_v9.rego", "p24_innovations_enterprise.rego",
          "rules/micro/p24_innovations_enterprise.rego",
          "p34_innovations_engine.rego", "p34_remaining_fixes.rego", "p35_cross_act_coherence.rego",
          "p35_system_gaps.rego", "p35_innovations_engine.rego"]),
        ("SYSTEM OPA — RDZEŃ SYSTEMOWY (rules/)", ["rule_lifecycle_enterprise.rego",
          "reliability_guarantee_enterprise.rego", "decision_core_completeness_enterprise.rego"]),
        ("REFERENCJE SYSTEMOWE (bundles/)", ["bundles/policies_drift_report.json", "bundles/hardcoded_audit.json",
          "bundles/coverage_deserts.json", "bundles/impact_matrix.json"]),
    ],
    related=["00, 01, 17, 18, 21, 22"],
    next="17_ENTERPRISE_AI.txt",
    uwagi=("JSON-y z bundles/ czytaj selektywnie — to dane audytowe (statystyki i kluczowe wiersze)."),
))

# ============================= 17 ENTERPRISE AI =============================
CZESCI.append(dict(
    num=17, tytul="ENTERPRISE AI — INTELIGENCJA SYSTEMU (Neural Mesh, Adaptive Trust, Strategie, Bankowość PSD2)",
    persona="Ekspertem ENTERPRISE od warstw AI/ML wokół deterministycznych silników regułowych — adaptive trust, "
            "knowledge graphs, predykcje, bankowość PSD2/PolishAPI i strategia biznesowa JDG.",
    raport="RAPORT_17_ENTERPRISE_AI.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę warstwy ENTERPRISE AI na zaawansowanym "
           "poziomie Enterprise. Zasada graniczna z V1/V2: inteligencja może rekomendować, ostrzegać i cofać, ale "
           "decyzja ewaluacyjna zawsze zostaje w deterministycznym Rego. Oceń: adaptive_trust_scoring_enterprise "
           "(tryby AUTO_POST/SUGGEST/ASK_USER wg Trust Score 0,92/0,75), neural_rule_mesh_enterprise + "
           "neural_mesh_v2_enterprise (knowledge graph reguł, propagacja pewności, detekcja konfliktów), "
           "banking_automation_enterprise (PSD2/PolishAPI, AIS/PIS, zgody), cashflow_tax_predictor_enterprise "
           "(predykcja podatków), strategic_advisor_enterprise + strategic_roadmap_enterprise (wirtualny CFO), "
           "legislative_monitor_enterprise + legislative_impact_analyzer_enterprise (monitor legislacyjny), "
           "form_optimizer_enterprise, hyper_plan45_meta_enterprise, decision_composer_enterprise. Wymyśl "
           "innowacyjne ulepszenia wyprzedzające profesjonalistów: samo-doskonaląca się sieć pewności reguł "
           "(feedback księgowej → adaptive trust per reguła), predykcja wpływu nowelizacji „symulacja jutra\", "
           "detekcja anomalii werdyktów ML z auto-rollbackiem, asystent LLM dla policy-engineerów (4-eyes), "
           "bankowość z automatyczną księgowością PSD2."),
    kategorie=[
        ("ENTERPRISE AI (rules/)", ["adaptive_trust_scoring_enterprise.rego", "neural_rule_mesh_enterprise.rego",
          "neural_mesh_v2_enterprise.rego", "banking_automation_enterprise.rego",
          "cashflow_tax_predictor_enterprise.rego", "strategic_advisor_enterprise.rego",
          "strategic_roadmap_enterprise.rego", "legislative_monitor_enterprise.rego",
          "legislative_impact_analyzer_enterprise.rego", "form_optimizer_enterprise.rego",
          "hyper_plan45_meta_enterprise.rego", "decision_composer_enterprise.rego"]),
    ],
    related=["00, 16, 01"],
    next="18_NARZEDZIA_SYSTEM.txt",
))

# ============================= 18 NARZĘDZIA SYSTEM =============================
CZESCI.append(dict(
    num=18, tytul="NARZĘDZIA SYSTEMOWE (walidacja, lint, pokrycie prawne, legal twin, golden replay, CI)",
    persona="Ekspertem ENTERPRISE od narzędzi deweloperskich dla Policy-as-Code: walidatorów, linterów, audytów "
            "legalnych, golden replay, chaos engineeringu i CI/CD dla OPA.",
    raport="RAPORT_18_NARZEDZIA_SYSTEM.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę NARZĘDZI SYSTEMOWYCH na zaawansowanym "
           "poziomie Enterprise. Te narzędzia realizują wymóg „OPA jako SYSTEM\" — szybką i prostą adaptację do "
           "zmian prawa. Oceń: validate_rules.py (9 walidacji), lint_rego_rules.py (6-check), "
           "generate_manifest.py, generate_coverage_report.py, validate_legal_basis.py (+v2, p24), "
           "hardcoded_audit.py + hardcoded_audit_gate.py (ADR-002), dead_rule_detector.py, tautology_guard.py, "
           "else_chain_dead_code_detector.py, cross_ref_validator.py, doc_consistency_validator.py, "
           "traceability_matrix.py, legal_coverage_heatmap.py, legal_basis_audit.py, legal_coverage_gap_report.py, "
           "legal_change_calendar.py, law_radar.py, law_impact_matrix.py, legal_twin.py, golden_replay.py, "
           "declarative_change.py, invariant_checker.py, decision_certificate.py, confidence_dashboard.py, "
           "policies_sync_gate.py, zero_defect_certification.py, rule_provenance_dna.py, self_healing_engine.py, "
           "chaos_engineering.py, predictive_audit_shield.py, adaptive_trust_score.py, "
           "cross_package_conflict_detector.py, rule_impact_simulator.py, temporal_drift_detector.py, "
           "isap_drift_alarm.py, isap_crawler.py, isap_rule_update_pipeline.py, rule_lifecycle_manager.py, "
           "decision_quality_monitor.py, enterprise_dashboard.py, migration_impact_analyzer.py, "
           "initiative_numbering_auditor.py, adr_auto_proposer.py, policy_registry_api.py, data_service.py, "
           "deployment_orchestrator.py, manifest_v2.py, api_doc_generator.py, doc_coverage_map.py, "
           "verify_prompt_coverage.py, sc_legal_graph.py, regulatory_radar.py, sc_verdict_streaming.py, "
           "sc_context_enricher.py, live_architecture_diagrams.py. Oceń każdy plik: poprawność, kompletność, "
           "integrację z CI, pokrycie wymogów V1/V2 (Legal Twin, Declarative Change, Decision Certificate, "
           "Law Radar). Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów."),
    kategorie=[
        ("WALIDACJA I JAKOŚĆ (JDG/tools/ + katalog główny JDG)", ["validate_rules.py", "lint_rego_rules.py",
          "generate_manifest.py", "generate_coverage_report.py", "generate_missing_rules.py",
          "generate_coverage_report.py", "hardcoded_audit.py", "hardcoded_audit_gate.py", "dead_rule_detector.py",
          "tautology_guard.py", "else_chain_dead_code_detector.py", "cross_ref_validator.py",
          "doc_consistency_validator.py", "zero_defect_certification.py", "rule_provenance_dna.py"]),
        ("LEGAL I POKRYCIE (JDG/tools/)", ["validate_legal_basis.py", "validate_legal_basis_v2.py",
          "validate_p24_legal_basis.py", "legal_basis_audit.py", "legal_coverage_heatmap.py",
          "legal_coverage_gap_report.py", "legal_change_calendar.py", "law_radar.py", "law_impact_matrix.py",
          "legal_twin.py", "golden_replay.py", "declarative_change.py", "traceability_matrix.py",
          "root:tools/doc_coverage_map.py", "root:tools/sc_legal_graph.py", "root:tools/regulatory_radar.py"]),
        ("SYSTEM I CI (JDG/tools/)", ["rule_lifecycle_manager.py", "decision_quality_monitor.py",
          "isap_crawler.py", "isap_rule_update_pipeline.py", "isap_drift_alarm.py", "self_healing_engine.py",
          "chaos_engineering.py", "predictive_audit_shield.py", "adaptive_trust_score.py",
          "cross_package_conflict_detector.py", "rule_impact_simulator.py", "temporal_drift_detector.py",
          "invariant_checker.py", "decision_certificate.py", "confidence_dashboard.py", "policies_sync_gate.py",
          "enterprise_dashboard.py", "migration_impact_analyzer.py", "initiative_numbering_auditor.py",
          "adr_auto_proposer.py", "policy_registry_api.py", "data_service.py", "deployment_orchestrator.py",
          "manifest_v2.py", "api_doc_generator.py", "root:tools/verify_prompt_coverage.py",
          "root:tools/sc_verdict_streaming.py", "root:tools/sc_context_enricher.py",
          "root:tools/live_architecture_diagrams.py"]),
    ],
    related=["00, 16, 19, 21, 22"],
    next="19_NARZEDZIA_DOMENY.txt",
))

# ============================= 19 NARZĘDZIA DOMENY =============================
CZESCI.append(dict(
    num=19, tytul="NARZĘDZIA DOMENOWE (generatory reguł, audytory per domena, ZUS atom, KKS toolkit, testy)",
    persona="Ekspertem ENTERPRISE od generowania i audytowania reguł podatkowych per domena (ZUS, KKS, VAT, PIT, "
            "PCC, cross-border) oraz od narzędzi wspierających dodawanie/zmianę/usuwanie reguł.",
    raport="RAPORT_19_NARZEDZIA_DOMENY.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę NARZĘDZI DOMENOWYCH na zaawansowanym "
           "poziomie Enterprise. To one realizują „prostotę zmiany reguł\" (Declarative Change): generator reguł "
           "z diffu prawnego, audytory per domena, kalkulatory. Oceń: generate_micro_rules.py, "
           "generate_massive_rules.py, generate_from_plan50.py, crossref_plan50.py, parse_plan33_and_generate.py, "
           "fix_plan34_duplicates.py, convert_true_to_conditions.py, debug_converter.py, "
           "fix_micro_plan33_legal_basis.py, fix_p06_legal_basis.py, fix_p07_thresholds.py, "
           "fix_p10_plan33_kks.py, fix_plan34_legal_basis.py, fix_hyper_legal_basis.py, fix_zus_naming.py, "
           "zus_naming_unifier.py, zus_atom_linter.py, zus_completeness_engine.py, health_tier_recalculator.py, "
           "sickness_duration_tracker.py, contribution_base_validator.py, zus_atom_test_matrix.py, "
           "cross_act_zus_checker.py, preferential_period_tracker.py, zus_rule_sharding.py, "
           "health_reconciliation_micro.py, kks_penalty_simulator.py, kks_voluntary_disclosure.py, "
           "kks_limitations_calendar.py, kks_risk_scorer.py, kks_completeness_matrix.py, p10_kks_micro_toolkit.py, "
           "p10_kks_test_generator.py, p10_kks_proactive_shield.py, p10_kks_jurisprudence.py, "
           "p10_kks_micro_simulator.py, p11_accounting_toolkit.py, p12_uor_toolkit.py, "
           "p12_uor_accounting_toolkit.py, p13_crossborder_toolkit.py, p14_compliance_toolkit.py, "
           "p15_local_taxes_toolkit.py, p15_pcc_local_excise_toolkit.py, p16_business_lifecycle_toolkit.py, "
           "p17_edge_cases_conflicts_toolkit.py, generate_test_suite.py, generate_missing_package_tests.py, "
           "generate_enterprise_tests.py, split_micro_tests.py, dedup_micro_plan33.py, judgment_predictor.py, "
           "llm_bridge.py, pit_reliefs_optimizer.py, pit_micro_amortization_auditor.py, zus_macro_auditor.py, "
           "zus_micro_auditor.py, rodo_aml_security_auditor.py, automatyzacja_ksiegowosci_auditor.py, "
           "validation_tools_auditor.py, test_rego_ci_auditor.py, audyt_kompletny_auditor.py, ordpu_auditor.py, "
           "ksiegowosc_pkpir_uor_auditor.py, kks_penalty_auditor.py, crossborder_auditor.py, "
           "ryczalt_lifecycle_auditor.py, pcc_local_excise_auditor.py, bdo_environment_auditor.py, "
           "ksef_jpk_edeklaracje_auditor.py, hr_swiadczenia_auditor.py, neural_mesh_innovations_auditor.py, "
           "opa_system_auditor.py, vat_traceability_matrix.py, vat_gap_detector.py, vat_innovation_tools.py, "
           "vat_ruleid_migrator.py, pit_innovation_tools.py, pit_temporal_snapshot_engine.py, "
           "vat_mpp_auto_detector.py, vat_micro_auditor.py, limitations_calendar.py, accounting_docs_compliance.py. "
           "Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów."),
    kategorie=[
        ("GENERATORY I KONWERTERY (JDG/tools/)", ["generate_micro_rules.py", "generate_massive_rules.py",
          "generate_from_plan50.py", "crossref_plan50.py", "parse_plan33_and_generate.py",
          "fix_plan34_duplicates.py", "convert_true_to_conditions.py", "debug_converter.py",
          "fix_micro_plan33_legal_basis.py", "fix_p06_legal_basis.py", "fix_p07_thresholds.py",
          "fix_p10_plan33_kks.py", "fix_plan34_legal_basis.py", "fix_hyper_legal_basis.py", "fix_zus_naming.py",
          "dedup_micro_plan33.py", "generate_test_suite.py", "generate_missing_package_tests.py",
          "generate_enterprise_tests.py", "split_micro_tests.py"]),
        ("ZUS ATOM (JDG/tools/)", ["zus_naming_unifier.py", "zus_atom_linter.py", "zus_completeness_engine.py",
          "health_tier_recalculator.py", "sickness_duration_tracker.py", "contribution_base_validator.py",
          "zus_atom_test_matrix.py", "cross_act_zus_checker.py", "preferential_period_tracker.py",
          "zus_rule_sharding.py", "health_reconciliation_micro.py"]),
        ("KKS TOOLKIT (JDG/tools/)", ["kks_penalty_simulator.py", "kks_voluntary_disclosure.py",
          "kks_limitations_calendar.py", "kks_risk_scorer.py", "kks_completeness_matrix.py",
          "p10_kks_micro_toolkit.py", "p10_kks_test_generator.py", "p10_kks_proactive_shield.py",
          "p10_kks_jurisprudence.py", "p10_kks_micro_simulator.py"]),
        ("TOOLKITY PER DOMENA (JDG/tools/)", ["p11_accounting_toolkit.py", "p12_uor_toolkit.py",
          "p12_uor_accounting_toolkit.py", "p13_crossborder_toolkit.py", "p14_compliance_toolkit.py",
          "p15_local_taxes_toolkit.py", "p15_pcc_local_excise_toolkit.py", "p16_business_lifecycle_toolkit.py",
          "p17_edge_cases_conflicts_toolkit.py"]),
        ("AUDYTORY PER DOMENA (JDG/tools/)", ["ordpu_auditor.py", "ksiegowosc_pkpir_uor_auditor.py",
          "kks_penalty_auditor.py", "crossborder_auditor.py", "ryczalt_lifecycle_auditor.py",
          "pcc_local_excise_auditor.py", "bdo_environment_auditor.py", "ksef_jpk_edeklaracje_auditor.py",
          "hr_swiadczenia_auditor.py", "neural_mesh_innovations_auditor.py", "opa_system_auditor.py",
          "zus_macro_auditor.py", "zus_micro_auditor.py", "rodo_aml_security_auditor.py",
          "automatyzacja_ksiegowosci_auditor.py", "validation_tools_auditor.py", "test_rego_ci_auditor.py",
          "audyt_kompletny_auditor.py", "vat_micro_auditor.py", "pit_micro_amortization_auditor.py"]),
        ("AI / OPTYMALIZACJA / INWENTARYZACJA (JDG/tools/)", ["judgment_predictor.py", "llm_bridge.py",
          "pit_reliefs_optimizer.py", "vat_traceability_matrix.py", "vat_gap_detector.py",
          "vat_innovation_tools.py", "vat_ruleid_migrator.py", "pit_innovation_tools.py",
          "pit_temporal_snapshot_engine.py", "vat_mpp_auto_detector.py", "limitations_calendar.py",
          "accounting_docs_compliance.py"]),
    ],
    related=["00, 16, 18, 06, 07"],
    next="20_TESTY_PYTEST.txt",
))

# ============================= 20 TESTY PYTEST =============================
CZESCI.append(dict(
    num=20, tytul="TESTY PYTEST (testy jednostkowe i integracyjne modułów ENTERPRISE)",
    persona="Ekspertem ENTERPRISE od testowania systemów regułowych: pytest, property-based testing, testy "
            "integracyjne, mutation testing i CI dla silnika OPA.",
    raport="RAPORT_20_TESTY_PYTEST.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę TESTÓW PYTEST modułu JDG na zaawansowanym "
           "poziomie Enterprise. **Uwaga z audytu: część testów nie kolekcjonuje się względem głównego repo "
           "(np. test_risk_guard.py importuje nieistniejące symbole z nexus_ai/services/risk_guard.py) — "
           "zweryfikuj to i wskaż konkretnie.** Oceń: tests/*.py (42 pliki: test_aml_enterprise, "
           "test_bdo_enterprise, test_conflicts_enterprise, test_crossborder_enterprise, test_edge_cases_enterprise, "
           "test_facts_aggregator, test_fraud_graph_scanner, test_hyper_plan45_enterprise, test_kks_enterprise, "
           "test_ksef_generator, test_p01_control_plane, test_p02_legal, test_p03_orchestrator_enterprise, "
           "test_p04_vat_macro_enterprise, test_p05_vat_micro_atomic, test_p06_pit_macro_enterprise, "
           "test_p07_pit_micro_atomic, test_p08_zus_macro_enterprise, test_p16_v8_enterprise, "
           "test_payment_priority_service, test_pcc_excise_enterprise, test_phase5_modules, "
           "test_pkpir_uor_enterprise, test_priority_engine, test_risk_api, test_risk_guard, "
           "test_risk_guard_integration, test_rodo_enterprise, test_semantic_guard, test_strategic_v2_modules, "
           "test_tax_pipeline, test_tax_rules, test_tax_audit, test_temporal_manager, test_temporal_validity + "
           "tests/auto/test_auto_block_*.py — 55 plików automatycznych testów blokowych). Sprawdź: pokrycie "
           "domagania reguł, jakość asercji, użycie property-based (hypothesis/crosshair), testy graniczne "
           "(grosze, waluty, limity), testy temporalne, integrację z DuckDB/OPA, importy (spójność z kodem "
           "głównym). Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: golden dataset per domena, "
           "mutation testing ≥75% w CI, fuzzing 10k+ wejść, contract tests OpenAPI, chaos tests, auto-rollback "
           "na czerwone testy."),
    kategorie=[
        ("TESTY PYTEST (JDG/tests/ — *.py)", ["test_aml_enterprise.py", "test_bdo_enterprise.py",
          "test_conflicts_enterprise.py", "test_crossborder_enterprise.py", "test_edge_cases_enterprise.py",
          "test_facts_aggregator.py", "test_fraud_graph_scanner.py", "test_hyper_plan45_enterprise.py",
          "test_kks_enterprise.py", "test_ksef_generator.py", "test_p01_control_plane.py", "test_p02_legal.py",
          "test_p03_orchestrator_enterprise.py", "test_p04_vat_macro_enterprise.py", "test_p05_vat_micro_atomic.py",
          "test_p06_pit_macro_enterprise.py", "test_p07_pit_micro_atomic.py", "test_p08_zus_macro_enterprise.py",
          "test_p16_v8_enterprise.py", "test_payment_priority_service.py", "test_pcc_excise_enterprise.py",
          "test_phase5_modules.py", "test_pkpir_uor_enterprise.py", "test_priority_engine.py", "test_risk_api.py",
          "test_risk_guard.py", "test_risk_guard_integration.py", "test_rodo_enterprise.py",
          "test_semantic_guard.py", "test_strategic_v2_modules.py", "test_tax_pipeline.py", "test_tax_rules.py",
          "test_tax_audit.py", "test_temporal_manager.py", "test_temporal_validity.py"]),
        ("TESTY AUTO-BLOKOWE (JDG/tests/auto/ — katalog, 55 plików)", ["tests/auto/ (katalog — wszystkie "
          "test_auto_block_*.py, czytaj selektywnie wybrane reprezentatywne pliki)"]),
    ],
    related=["00, 16, 21, 01"],
    next="21_TESTY_NATIVE_REGON.txt",
    uwagi=("Katalog tests/auto/ liczy ~55 plików — nie czytaj wszystkich w całości; wybierz reprezentatywne "
           "(np. test_auto_block_vat.py, test_auto_block_zus.py, test_auto_block_kks.py) i oceń wzorzec. "
           "Liczba plików w tests/ bywa różna (35–42 w tests/ + ~55 w tests/auto/) — podaj w raporcie faktyczne "
           "liczby z chwili analizy."),
))

# ============================= 21 TESTY NATYWNE REGO =============================
CZESCI.append(dict(
    num=21, tytul="TESTY NATYWNE REGO (opa test — test_native_*.rego, coverage testów reguł)",
    persona="Ekspertem ENTERPRISE od natywnych testów Rego (opa test), coverage, golden tests i mutation analysis "
            "dla silników OPA.",
    raport="RAPORT_21_TESTY_NATIVE_REGON.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę NATYWNYCH TESTÓW REGO na zaawansowanym "
           "poziomie Enterprise. Oceń: tests/rego/* (111 plików test_native_*.rego — per pakiet enterprise i "
           "domenowy), tests/jdg_rules_test.rego, tests/p26_regression_test.rego, tests/README.md. Sprawdź: "
           "pokrycie pakietów reguł testami (cel ≥95% pakietów, 100% krytycznych), jakość przypadków (happy path, "
           "granice, negatywne no_match, temporalne przed/po valid_from), zgodność z wymogiem golden replay i "
           "mutation ≥70%. Zidentyfikuj pakiety bez testów (coverage_deserts, test_neural_mesh_untested.rego!) "
           "i zaproponuj konkretne testy dla luk. Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: "
           "auto-generacja testów z manifestów reguł, property-based testy Rego, „testy-dowody\" dla Decision "
           "Certificate, integracja z opa test --coverage w CI, fuzzery decyzyjne."),
    kategorie=[
        ("NATYWNE TESTY REGO (JDG/tests/rego/ — 111 plików, katalog)", ["tests/rego/ (katalog — przeczytaj "
          "selektywnie: 10–15 reprezentatywnych plików z różnych domen + wskaż wzorce i luki)"]),
        ("REGRESJA (JDG/tests/)", ["tests/jdg_rules_test.rego", "tests/p26_regression_test.rego",
          "tests/README.md"]),
    ],
    related=["00, 16, 20, 07"],
    next="22_BUNDLE_API_MIGRACJE.txt",
    uwagi=("Nie czytaj wszystkich 111 plików w całości — przeanalizuj reprezentatywną próbkę z każdej domeny "
           "(vat, pit, zus, kks, ord, ksef, enterprise) i oceń wzorzec + pokrycie."),
))

# ============================= 22 BUNDLE/API/MIGRACJE =============================
CZESCI.append(dict(
    num=22, tytul="BUNDLE / API / MIGRACJE (bundle OPA, OpenAPI, RuleStore DuckDB, deployment, rejestry)",
    persona="Ekspertem ENTERPRISE od dystrybucji bundle OPA (signing, delta, canary), API REST, migracji DuckDB, "
            "RuleStore i deploymentu zero-downtime.",
    raport="RAPORT_22_BUNDLE_API_MIGRACJE.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę BUNDLE/API/MIGRACJI na zaawansowanym "
           "poziomie Enterprise. To realizuje Control Plane i Data Plane z V1/V2. Oceń: bundles/bundle.sh "
           "(budowa tar.gz, manifest), bundles/manifest.json, manifest_v2.json, policy_registry.json, "
           "legal_graph.json, thresholds_data.json, deployments.json, impact_matrix.json, law_radar.json, "
           "policies_drift_report.json, healthy_versions.json, rule_registry.json, legal_reference_canon.json, "
           "legal_basis_audit.json, legal_coverage_gaps.json, legal_basis_v2_report.json, coverage_deserts.json, "
           "legal_change_calendar.json, accounting_compliance.json, hardcoded_audit.json, vat_micro_inventory.json, "
           "pit_micro_inventory.json, zus_micro_inventory.json; api/openapi.yaml (10 endpointów, JWT); "
           "migrations/001_jdg_rule_store.sql, 002_jdg_enterprise_v7.sql, 003_jdg_v8_legal_twin.sql. Sprawdź: "
           "spójność liczb między manifestem a regułami (L2: niespójne metryki!), podpisywanie bundle (brak "
           "HSM — wskaż jak dodać), delta-bundles, long-polling, persist=true, wersjonowanie i „listę zdrowych "
           "wersji\", hot-reload danych przez OPA Data API, 9 tabel RuleStore (w tym jdg_legal_cartography → "
           "rozbudowa do legal_graph LKG), audyt WORM (Merkle/HMAC), model ról. Wymyśl innowacyjne ulepszenia "
           "wyprzedzające profesjonalistów: bundle server z podpisem i weryfikacją na węźle, kanary 5%→100% z "
           "auto-rollbackiem ≤5 min, wdrożenie parametru ≤15 min, pełny łańcuch traceability nowelizacja→werdykt."),
    kategorie=[
        ("BUNDLE (JDG/bundles/)", ["bundles/bundle.sh", "bundles/manifest.json", "bundles/manifest_v2.json",
          "bundles/legal_graph.json", "bundles/thresholds_data.json",
          "bundles/deployments.json", "bundles/impact_matrix.json", "bundles/law_radar.json",
          "bundles/policies_drift_report.json", "bundles/healthy_versions.json", "bundles/rule_registry.json",
          "bundles/legal_reference_canon.json", "bundles/legal_coverage_gaps.json", "bundles/coverage_deserts.json",
          "bundles/legal_change_calendar.json", "bundles/accounting_compliance.json", "bundles/hardcoded_audit.json"]),
        ("REJESTRY WIELKIE (⚠️ 3–5 MB — czytaj TYLKO stats/by_act/priorytety i ograniczoną liczbę wierszy!)",
          ["bundles/policy_registry.json", "bundles/legal_basis_audit.json", "bundles/legal_basis_v2_report.json",
          "bundles/vat_micro_inventory.json", "bundles/pit_micro_inventory.json", "bundles/zus_micro_inventory.json"]),
        ("API (JDG/api/)", ["api/openapi.yaml"]),
        ("MIGRACJE (JDG/migrations/)", ["migrations/001_jdg_rule_store.sql", "migrations/002_jdg_enterprise_v7.sql",
          "migrations/003_jdg_v8_legal_twin.sql"]),
    ],
    related=["00, 16, 18, 24"],
    next="23_DOKUMENTACJA.txt",
    uwagi=("legal_basis_audit.json (~3 MB), legal_basis_v2_report.json (~3 MB), policy_registry.json (~5 MB) — "
           "czytaj TYLKO sekcje: stats, by_act, priority_details i ograniczoną liczbę wierszy. Nie mieszczą się "
           "w całości w budżecie 50% okna!"),
))

# ============================= 23 DOKUMENTACJA =============================
CZESCI.append(dict(
    num=23, tytul="DOKUMENTACJA TEMATYCZNA (docs/ — moduły P02–P24, audyty, strategie)",
    persona="Ekspertem ENTERPRISE od dokumentacji systemów finansowych — ocena spójności, kompletności i "
            "zgodności dokumentacji z kodem reguł oraz architekturą docelową V1/V2.",
    raport="RAPORT_23_DOKUMENTACJA.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę DOKUMENTACJI TEMATYCZNEJ na zaawansowanym "
           "poziomie Enterprise. Oceń spójność dokumentów docs/ ze sobą i z rzeczywistym stanem reguł: "
           "DECISION_CORE_P02, VAT_MACRO_P03, VAT_MICRO_P04, PIT_MACRO_P05, PIT_MICRO_P06, ZUS_MACRO_P07, "
           "ZUS_MICRO_P08, KSIEGOWOSC_PKPIR_UOR_P09, KKS_P10, ORDYNACJA_PODATKOWA_P11, CROSSBORDER_P12, "
           "RYCZALT_CYKL_ZYCIE_P13, PCC_LOKALNE_AKCYZA_P14, SRODOWISKO_BDO_P15, RODO_AML_BEZPIECZENSTWO_P16, "
           "KSEF_JPK_EDEKLARACJE_P17, AUTOMATYZACJA_KSIEGOWOSCI_P18, HR_SWIADCZENIA_P19, NEURAL_MESH_INNOWACJE_P20, "
           "OPA_JAKO_SYSTEM_P21, NARZEDZIA_WALIDACJI_P22, TESTY_REGO_CI_P23, AUDYT_KOMPLETNY_P24, PIT_AUDYT_R04, "
           "PRAWA_PRZEDSIEBIORCOW_AUDYT_R02, VAT_AUDYT_R03, LOGIKA_BIZNESOWA, ZGODNOSC_PRAWNA, MANIFEST_2_0, "
           "ARCHITECTURE.md, api.md, UNIFIED_PLAN.md. Wskaż: niespójności liczb (pliki/reguły/pokrycie) między "
           "dokumentami, braki względem V1/V2, dokumenty „żywe\" vs „martwe\", brakujące sekcje (DR/BCP, model "
           "ról, SLO). Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów: automatyczna walidacja "
           "dokumentacji vs kod (doc_consistency_validator), jeden autorytatywny rejestr metryk, „living docs\" "
           "z traceability do reguł."),
    kategorie=[
        ("DOKUMENTY MODUŁÓW P02–P24 (JDG/docs/)", ["DECISION_CORE_P02.md", "VAT_MACRO_P03.md", "VAT_MICRO_P04.md",
          "PIT_MACRO_P05.md", "PIT_MICRO_P06.md", "ZUS_MACRO_P07.md", "ZUS_MICRO_P08.md",
          "KSIEGOWOSC_PKPIR_UOR_P09.md", "KKS_P10.md", "ORDYNACJA_PODATKOWA_P11.md", "CROSSBORDER_P12.md",
          "RYCZALT_CYKL_ZYCIE_P13.md", "PCC_LOKALNE_AKCYZA_P14.md", "SRODOWISKO_BDO_P15.md",
          "RODO_AML_BEZPIECZENSTWO_P16.md", "KSEF_JPK_EDEKLARACJE_P17.md", "AUTOMATYZACJA_KSIEGOWOSCI_P18.md",
          "HR_SWIADCZENIA_P19.md", "NEURAL_MESH_INNOWACJE_P20.md", "OPA_JAKO_SYSTEM_P21.md",
          "NARZEDZIA_WALIDACJI_P22.md", "TESTY_REGO_CI_P23.md", "AUDYT_KOMPLETNY_P24.md"]),
        ("AUDYTY I STRATEGIE (JDG/docs/)", ["PIT_AUDYT_R04.md", "PRAWA_PRZEDSIEBIORCOW_AUDYT_R02.md",
          "VAT_AUDYT_R03.md", "MANIFEST_2_0.md", "UNIFIED_PLAN.md", "ARCHITECTURE.md", "api.md"]),
        ("BIZNES I ZGODNOŚĆ (JDG/docs/)", ["LOGIKA_BIZNESOWA.md", "ZGODNOSC_PRAWNA.md"]),
    ],
    related=["00, 16, 18"],
    next="24_POLICIES.txt",
))

# ============================= 24 POLICIES =============================
CZESCI.append(dict(
    num=24, tytul="POLICIES — LUSTRO REGUŁ + OVERLAYS v2026/v2027 (spójność rules/ ↔ policies/)",
    persona="Ekspertem ENTERPRISE od spójności repozytoriów reguł (single source of truth), bundle overlays "
            "czasowych i harmonizacji dwóch zestawów reguł (JDG/rules vs policies/).",
    raport="RAPORT_24_POLICIES.txt",
    focus=("Przeprowadź głębokie myślenie i przeprowadź głęboką analizę katalogu POLICIES na zaawansowanym "
           "poziomie Enterprise. **Zasada nadrzędna V1: „Pojedyncze źródło prawdy\" — żadnych mirrorów "
           "(rules/ vs policies/); warianty czasowe wyłącznie przez overlays na ten sam bazowy zestaw reguł.** "
           "Oceń: policies/jdg/ (lustro reguł JDG: main_jdg, vat/, pit/, zus, kks, temporal, routing, risk, "
           "edge_cases, fallback, compliance, conflicts, corrections, crossborder, digital, employer, "
           "environmental, international, ksef_jpk, liability, local_taxes, mpips, representation, restructuring, "
           "retention, rodo, validation, accounting, allowances, business), policies/jdg/bundles/ (base + overlays "
           "v2026/v2027), policies/tax/ (silnik dla spółek: main_sc, sc_ksef_jpk, sc_liability, sc_partnership, "
           "ordynacja_extended, pit_withholding, cit_deductions, labor_extended, anomaly, direct/cit, direct/pit), "
           "policies/compliance/, policies/data/thresholds_sc.rego, policies/Makefile, policies/bundle.sh. "
           "Sprawdź: dryf między rules/ a policies/ (policies_drift_report.json), duplikację, niespójne "
           "rule_id/werdykty, pokrycie overlays (nakładanie i luki czasowe). Zaproponuj architekturę docelową: "
           "jeden registry + overlays czasowe, mechanizm auto-synchronizacji, bramki CI blokujące dryf. "
           "Wymyśl innowacyjne ulepszenia wyprzedzające profesjonalistów."),
    kategorie=[
        ("POLICIES JDG (policies/jdg/)", ["root:policies/jdg/main_jdg.rego", "root:policies/jdg/_helpers_jdg.rego",
          "root:policies/jdg/_metadata_jdg.rego", "root:policies/jdg/accounting.rego", "root:policies/jdg/allowances.rego",
          "root:policies/jdg/business.rego", "root:policies/jdg/compliance.rego", "root:policies/jdg/conflicts.rego",
          "root:policies/jdg/corrections.rego", "root:policies/jdg/crossborder.rego", "root:policies/jdg/digital.rego",
          "root:policies/jdg/edge_cases.rego", "root:policies/jdg/employer.rego", "root:policies/jdg/environmental.rego",
          "root:policies/jdg/fallback.rego", "root:policies/jdg/international.rego", "root:policies/jdg/kks.rego",
          "root:policies/jdg/ksef_jpk.rego", "root:policies/jdg/liability.rego", "root:policies/jdg/local_taxes.rego",
          "root:policies/jdg/mpips.rego", "root:policies/jdg/representation.rego", "root:policies/jdg/restructuring.rego",
          "root:policies/jdg/retention.rego", "root:policies/jdg/risk.rego", "root:policies/jdg/rodo.rego",
          "root:policies/jdg/routing.rego", "root:policies/jdg/temporal.rego", "root:policies/jdg/validation.rego",
          "root:policies/jdg/zus.rego", "root:policies/jdg/pit/forms.rego", "root:policies/jdg/pit/kup.rego",
          "root:policies/jdg/pit/exemptions.rego", "root:policies/jdg/pit/advances_returns.rego",
          "root:policies/jdg/pit/transitions.rego", "root:policies/jdg/vat/substantive.rego",
          "root:policies/jdg/vat/deductions.rego", "root:policies/jdg/vat/procedures.rego", "root:policies/jdg/README.md"]),
        ("POLICIES TAX (policies/tax/ — spółki)", ["root:policies/tax/main_sc.rego", "root:policies/tax/_helpers.rego",
          "root:policies/tax/_helpers_sc.rego", "root:policies/tax/_metadata.rego", "root:policies/tax/accounting.rego",
          "root:policies/tax/allowances.rego", "root:policies/tax/anomaly.rego", "root:policies/tax/cit_deductions.rego",
          "root:policies/tax/compliance.rego", "root:policies/tax/crossborder.rego", "root:policies/tax/direct/cit.rego",
          "root:policies/tax/direct/pit.rego", "root:policies/tax/fallback.rego", "root:policies/tax/labor_extended.rego",
          "root:policies/tax/ordynacja_extended.rego", "root:policies/tax/partner_mirror.rego",
          "root:policies/tax/pit_withholding.rego", "root:policies/tax/risk.rego", "root:policies/tax/routing.rego",
          "root:policies/tax/sc_fallback.rego", "root:policies/tax/sc_ksef_jpk.rego", "root:policies/tax/sc_liability.rego",
          "root:policies/tax/sc_partnership.rego", "root:policies/tax/vat_registration.rego",
          "root:policies/tax/vat/gtu.rego", "root:policies/tax/uor_reports.rego", "root:policies/tax/uor_valuation.rego",
          "root:policies/tax/what_if.rego", "root:policies/tests/sc_main_test.rego", "root:policies/tax/README.md"]),
        ("BUNDLES / DATA / MAKE (policies/)", ["root:policies/jdg/bundles/bundle.sh", "root:policies/jdg/bundles/README.md",
          "root:policies/data/thresholds_sc.rego", "root:policies/bundle.sh", "root:policies/Makefile"]),
        ("REFERENCJE (JDG/bundles/)", ["bundles/policies_drift_report.json"]),
    ],
    related=["00, 22, 16"],
    next="KONIEC_SERII",
))


# ---------------------------------------------------------------------------
# GENERACJA
# ---------------------------------------------------------------------------
def pokrycie_plikow() -> int:
    """Sprawdza, czy każdy plik JDG/rules/** i policies/** jest przywołany w promptach (ścieżka lub katalog nadrzędny)."""
    teksty = ""
    for f in os.listdir(OUT_DIR):
        if f.endswith(".txt") and not f.startswith("README"):
            with open(os.path.join(OUT_DIR, f), encoding="utf-8") as fh:
                teksty += fh.read() + "\n"
    pomin = (".sbom.json", ".signature", ".tar.gz", ".benchmarks", ".hypothesis", "/reports/")
    bledy = 0
    for base, rel in ((os.path.join(REPO_ROOT, "JDG"), ""), (os.path.join(REPO_ROOT, "policies"), "policies/")):
        if not os.path.isdir(base):
            continue
        for katalog, pod, pliki in os.walk(base):
            if any(x in katalog for x in (".benchmarks", ".hypothesis", "/reports")):
                continue
            for nazwa in pliki:
                if nazwa.endswith(pomin) or nazwa.startswith("."):
                    continue
                pelna = os.path.join(katalog, nazwa)
                wzgl = os.path.relpath(pelna, os.path.join(REPO_ROOT, "JDG"))
                if rel:
                    wzgl = os.path.join(rel, os.path.relpath(pelna, os.path.join(REPO_ROOT, "policies")))
                if wzgl in teksty:
                    continue
                # pliki .rego w rules/ MUSZĄ mieć pełną ścieżkę (rules/<plik>)
                # w linku — inaczej GLM nie trafi do pliku (tylko nazwa pliku
                # mogłaby być przypadkowym dopasowaniem w innym kontekście).
                if nazwa.endswith(".rego") and "rules/" in katalog and "/" in wzgl:
                    # dopuszczalne: pełna ścieżka gdzieś w tekście
                    # lub link GitHub zawierający "JDG/" + wzgl
                    if "JDG/" + wzgl in teksty:
                        continue
                    print(f"[VERIFY-POKRYCIE] reguła bez pełnej ścieżki: {wzgl}")
                    bledy += 1
                    continue
                # pozostałe pliki: sprawdź katalog nadrzędny (np. tests/rego/)
                czesci = wzgl.split(os.sep)
                pokryty = False
                for i in range(1, len(czesci)):
                    if os.path.join(*czesci[:i]) + "/" in teksty:
                        pokryty = True
                        break
                if not pokryty:
                    print(f"[VERIFY-POKRYCIE] brak przypisania: {wzgl}")
                    bledy += 1
    return bledy


def sprawdz_martwe_linki() -> int:
    """Weryfikuje, że każdy link GitHub w promptach wskazuje istniejący plik.

    Łapie martwe wpisy (np. p03_vat_macro_innovations_v8.rego, którego już nie ma)
    oraz linki z błędnym prefiksem (plik w rules/ linkowany jako JDG/<plik>).
    """
    bledy = 0
    for f in sorted(os.listdir(OUT_DIR)):
        if not f.endswith(".txt") or f.startswith("README"):
            continue
        t = open(os.path.join(OUT_DIR, f), encoding="utf-8").read()
        for m in re.finditer(r"https://github\.com/Gorski-Maciej/NexusAI/blob/main/([^\s\n)]+)", t):
            sciezka = m.group(1)
            if sciezka.startswith("JDG/"):
                rel = sciezka[4:]
                pelna = os.path.join(REPO_ROOT, "JDG", rel)
                # link może wskazywać plik LUB katalog (np. tests/auto/, tests/rego/)
                if not (os.path.isfile(pelna) or os.path.isdir(pelna)):
                    print(f"[VERIFY-LINK] martwy link w {f}: {sciezka}")
                    bledy += 1
            elif sciezka.startswith("policies/"):
                pelna = os.path.join(REPO_ROOT, "policies", sciezka[9:])
                if not (os.path.isfile(pelna) or os.path.isdir(pelna)):
                    print(f"[VERIFY-LINK] martwy link w {f}: {sciezka}")
                    bledy += 1
    return bledy


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(RAPORT_DIR, exist_ok=True)
    # unikalność nazw raportów (zapobiega cichej nadpisce w raporty_glm52/)
    raporty = [c["raport"] for c in CZESCI]
    assert len(raporty) == len(set(raporty)), "Zduplikowane nazwy raportów w CZESCI!"
    total = len(CZESCI)
    nazwy = {c["num"]: nazwa_pliku(c["num"], c["tytul"]) for c in CZESCI}
    for czesc in CZESCI:
        # poprawna nazwa następnego promptu (lub informacja o końcu serii)
        nast = czesc["next"]
        if nast != "KONIEC_SERII":
            nast_num = czesc["num"] + 1
            nast = nazwy.get(nast_num, nast)
        tekst = buduj_prompt(
            num=czesc["num"],
            total=total,
            tytul=czesc["tytul"],
            persona=czesc["persona"],
            raport_nazwa=czesc["raport"],
            focus=czesc["focus"],
            kategorie=czesc["kategorie"],
            related=czesc["related"],
            next_prompt=nast,
            uwagi=czesc.get("uwagi", ""),
        )
        nazwa = nazwy[czesc["num"]]
        sciezka = os.path.join(OUT_DIR, nazwa)
        with open(sciezka, "w", encoding="utf-8") as f:
            f.write(tekst)
        print(f"[OK] {nazwa}  ({len(tekst)} znaków)")

    # README serii
    readme = ("#" + "=" * 76 + "\n"
              "# README — SERIA 25 PROMPTÓW GLM 5.2 (NEXUSAI JDG ENTERPRISE)\n"
              "#" + "=" * 76 + "\n\n"
              "## JAK UŻYWAĆ SERII\n"
              "1. Wklejaj prompty PO KOLEI (00 → 24), jeden na jedną sesję GLM 5.2.\n"
              "2. Każdy prompt kończy się instrukcją WYCZYSZCZENIA OKNA KONTEKSTOWEGO — po zapisaniu raportu\n"
              "   do JDG/raporty_glm52/ zacznij nową sesję i wklej następny prompt.\n"
              "3. Raporty trafiają do JDG/raporty_glm52/ (RAPORT_XX_*.txt). Po wdrożeniu wzmocnień z raportów\n"
              "   silnik reguł podatkowych OPA ma osiągnąć najwyższy zaawansowany poziom ENTERPRISE.\n\n"
              "## KALIBRACJA OKNA KONTEKSTOWEGO\n"
              "- GLM 5.2: okno 1 000 000 tokenów; dane wejściowe ≤ 50% okna (~500 tys. tokenów).\n"
              "- Katalog JDG ≈ 8,2 mln tokenów (rego ~3,7 mln, docs ~447 tys., tools ~520 tys., tests ~618 tys.,\n"
              "  bundles JSON ~3,1 mln — z czego duże JSON-y czytane selektywnie).\n"
              "- Dlatego seria liczy 25 części — każda skalibrowana poniżej limitu 50%.\n\n"
              "## SPIS CZĘŚCI (plik -> tytuł)\n"
              + "\n".join(f"- {nazwa_pliku(c['num'], c['tytul'])}  |  {c['tytul']}" for c in CZESCI) + "\n\n"
              "## ZASADY\n"
              "- Prompty NIE generują kodu — tylko ogromne raporty analityczne .txt (25–40 stron).\n"
              "- W każdym prompcie frazy obowiązkowe ≥4x (głębokie myślenie, głęboka analiza, poziom ENTERPRISE,\n"
              "  zaawansowany poziom Enterprise, innowacyjne ulepszenia wyprzedzające profesjonalistów).\n"
              "- Spójność łańcucha: każda część czyta raport master 00 i raporty części powiązanych oraz\n"
              "  publikuje sekcję KONTRAKTY Z INNYMI CZĘŚCIAMI.\n"
              "- Regenerator: python3 JDG/tools/generate_glm52_prompty.py\n")
    with open(os.path.join(OUT_DIR, "README_PROMTY_GLM52.txt"), "w", encoding="utf-8") as f:
        f.write(readme)
    print(f"\n[OK] README_PROMTY_GLM52.txt")
    print(f"\nWygenerowano {total} promptów w: {OUT_DIR}")
    print(f"Raporty GLM zapisze do: {RAPORT_DIR}")


if __name__ == "__main__":
    if "--verify" in sys.argv:
        bledy = 0
        # frazy >=4x w wygenerowanych plikach
        frazy = ["Przeprowadź głębokie myślenie", "przeprowadź głęboką analizę",
                 "zaawansowany poziom Enterprise", "poziom ENTERPRISE",
                 "innowacyjne ulepszenia wyprzedzające profesjonalistów"]
        for f in sorted(os.listdir(OUT_DIR)):
            if not f.endswith(".txt") or f.startswith("README"):
                continue
            t = open(os.path.join(OUT_DIR, f), encoding="utf-8").read()
            for fraza in frazy:
                if t.count(fraza) < 4:
                    print(f"[VERIFY-FRAZA] {f}: '{fraza}' tylko {t.count(fraza)}x")
                    bledy += 1
        bledy += pokrycie_plikow()
        bledy += sprawdz_martwe_linki()
        if bledy == 0:
            print("[VERIFY] OK — frazy >=4x, pełne pokrycie plików, zero martwych linków, unikalne raporty.")
        else:
            print(f"[VERIFY] ZNALEZIONO {bledy} błędów.")
        sys.exit(1 if bledy else 0)
    main()
