#!/usr/bin/env python3
"""Generator Promptow V3 — 20 czesci kampanii wzmacniania modulu JDG (OPA/Rego).

Uruchomienie:   python3 JDG/tools/generate_v3_prompty.py
Wynik:          JDG/prompty_enterprise_v3/NN_NAZWA.txt  (00 startowy — reczny)

Dane czesci:    v3_parts_data_a.py (01-10) + v3_parts_data_b.py (11-20).

Gwarancje w kazdym pliku:
  - kazda z 5 wymaganych fraz wystepuje co najmniej 4 razy,
  - budzet 50% okna kontekstowego GLM 5.2 jest opisany,
  - sekcja CONTEXT_RESET_REQUIRED na koncu,
  - linki wyłącznie do prawdziwych plików/katalogów JDG,
  - obowiazek raportu TXT i rejestru zmian w kazdej czesci.
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # JDG
OUT = ROOT / "prompty_enterprise_v3"

BLOB = "https://github.com/Gorski-Maciej/NexusAI/blob/main/"
TREE = "https://github.com/Gorski-Maciej/NexusAI/tree/main/"
POLICY_TREE = "https://github.com/Gorski-Maciej/NexusAI/tree/main/policies"

FRAZES = [
    "Przeprowadź głębokie myślenie",
    "przeprowadź głęboką analizę",
    "zaawansowany poziom Enterprise",
    "poziom ENTERPRISE",
    "innowacyjne ulepszenia wyprzedzające profesjonalistów",
]


def url(rel: str) -> str:
    r = rel.strip()
    if r.startswith("http"):
        return r
    if r == "policies" or r.startswith("policies/"):
        return BLOB + r if r.startswith("policies/") else POLICY_TREE
    if r.startswith(".github/"):
        return BLOB + r
    if r.startswith("dir:"):
        return TREE + "JDG/" + r[4:]
    return BLOB + "JDG/" + r


SACRED = [
    (BLOB + "JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md",
     "V1 — OPA jako SYSTEM; SLO; zasady 1-10"),
    (BLOB + "JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md",
     "V2 — KONTYNUACJA V1; filary F1-F6"),
    (BLOB + "JDG/docs/ARCHITEKTURA.md", "stan obecny + ADR 001-022"),
    (BLOB + "JDG/docs/Bbb", "kompletna lista aktów prawnych JDG + mapa artykułów"),
    (BLOB + "JDG/docs/ANALIZA_STANU_OPA_JAKO_SYSTEM.md", "luki L1-L12"),
    (BLOB + "JDG/MANIFEST.md", "autorytatywny rejestr rule_id"),
]


PATTERNS = [
    (BLOB + "Louh", "wzorzec Promptu — struktura i styl (najkrótszy)"),
    (BLOB + "Bb", "wzorzec Promptu — wymagania i ton (linia przykładowy)"),
    (BLOB + "Jllug", "wzorzec Promptu — rozbudowany, analityczny"),
    (BLOB + "Jnkkk", "wzorzec Promptu — zaawansowany poziom Enterprise, kampanijny"),
]


def sacred_block() -> str:
    lines = ["DOKUMENTY ŚWIĘTE (czytaj ZAWSZE; każda zmiana musi być z nimi zgodna):"]
    for u, d in SACRED:
        lines.append(f"- {u}  ({d})")
    lines.append(f"- {POLICY_TREE}  (mirror + overlays — single source of truth)")
    return "\n".join(lines)


def patterns_block() -> str:
    lines = [
        "\nWZORCE PROMPTÓW — OBOWIĄZKOWE DO PRZECZYTANIA (zgodnie z wymogiem: ",
        "MUSISZ wykorzystać wszystkie Prompty-wzorce do nadania temu raportowi ",
        "stylu, głębi i jednoznaczności):",
    ]
    for u, d in PATTERNS:
        lines.append(f"- {u}  ({d})")
    lines.append(
        "Po ich przeczytaniu: utrzymaj ten sam styl — rozbudowany, jednoznaczny, "
        "z zaawansowanym poziomem Enterprise, z konkretnymi wymaganiami i "
        "wymuszonymi frazami, jak w wzorcach."
    )
    return "\n".join(lines)


def files_block(num: str, groups: list) -> str:
    lines = [f"\nPLIKI DO ANALIZY (CZĘŚĆ {num}) — czytaj wg priorytetów ★★★→★:"]
    for label, rels in groups:
        lines.append(f"\n{label}:")
        for rel in rels:
            lines.append(f"- {url(rel)}")
    return "\n".join(lines)


BUDGET = """BUDŻET OKNA KONTEKSTOWEGO GLM 5.2 (1 000 000 tokenów) — PRZESTRZEGAJ:
1. Dane i informacje, które przeczytasz i zapamiętasz, mogą zająć MAKSYMALNIE
   50% okna kontekstowego (ok. 500 000 tokenów).
2. Pozostałe >=50% okna jest ZAREZERWOWANE na: przeprowadzenie głębokiego
   myślenia, przeprowadzenie głębokiej analizy, generowanie INTELIGENTNEGO
   KODU oraz generowanie rozbudowanego raportu TXT.
3. PRZED czytaniem: oszacuj tokeny (KB/4), wypisz szacunek dla każdego pliku i
   czytaj wg priorytetów (★★★ → ★★ → ★). To, co pominiesz, oznacz w raporcie.
"""

STEPS = """KROK PO KROKU (wykonaj wszystkie bez wyjątków):
0. Przeczytaj szablon JDG/raporty_enterprise_v3/SZABLON_RAPORTU.txt i
   strukturę raportu A-J — zgodnie z nim buduj raport tej części.
1. Przeprowadź głębokie myślenie o domenie tej części: akty prawne (docs/Bbb),
   istotne artykuły ustaw i miejsce w architekturze JDG zgodnie z V1/V2.
2. Przeprowadź głęboką analizę każdego pliku z listy: legal_basis, temporalność
   (valid_from/valid_to), progi (data.thresholds), duplikaty rule_id, puste pola,
   staby, pominięcia. Porównaj z MANIFEST oraz ze ŚWIETYMI plikami V1/V2.
3. Sporządź listę LUK / BŁĘDÓW / NIEDOCIĄGNIĘĆ (minimum 20 pozycji, z
   priorytetami: krytyczne / ważne / kosmetyczne).
4. Zaprojektuj i wdroż innowacyjne ulepszenia wyprzedzające profesjonalistów
   (minimum 10) — zgodnie z zasadami V1 (1-10) i filarami V2 (F1-F6):
   Control/Data Plane, Legal Twin, runtime invariants, Golden Oracle,
   Decision Certificate, Law Radar, Declarative Change, auto-rollback, canary,
   zero-hardcode, temporalność, sharded router.
5. Wygeneruj INTELIGENTNY KOD bezpośrednio w JDG: reguły Rego w JDG/rules/,
   narzędzia i bramki w JDG/tools/, testy natywne Rego w JDG/tests/rego/,
   testy pytest w JDG/tests/ (czytelne dla CI/CD).
6. Uruchom lokalne bramki: `opa check -b` i `opa test` (gdy dostępny),
   `pytest -q`, oraz narzędzia JDG/tools. Zapisz wyniki do raportu.
7. Zaktualizuj rejestr zmian JDG/bundles/enterprise_v3_registry.json (dodaj
   blok tej części; NIE nadpisuj całego rejestru).
8. Zapisz raport TXT (ścieżka niżej) w pełnej strukturze z wymaganych sekcji.

STRUKTURA RAPORTU TXT (JDG/raporty_enterprise_v3/{OUT}.txt) — min. 12 stron:
A. METRYKI przed/po i podsumowanie.
B. AUDYT — każdy plik z listy: co działa, co nie, dlaczego.
C. LUKI (min. 20 pozycji: opis, plik, priorytet, skutek).
D. ROZWIĄZANIA ENTERPRISE — kod wdrożony: plik, rule_id, package, legal_basis,
   valid_from/valid_to, progi (zero hardcode).
E. INNOWACJE — innowacyjne ulepszenia wyprzedzające profesjonalistów (V1/V2).
F. TESTY — komunikaty i wyniki (logi, liczby).
G. SPÓJNOŚĆ MIĘDZYCZĘŚCIOWA z częściami: {CONS}.
H. DECYZJE CZŁOWIEKA — pytania i otwarte kwestie.

FRAZY OBOWIĄZKOWE — użyj każdej co najmniej 4 razy (w kodzie i raporcie):
- Przeprowadź głębokie myślenie
- przeprowadź głęboką analizę
- zaawansowany poziom Enterprise
- poziom ENTERPRISE
- innowacyjne ulepszenia wyprzedzające profesjonalistów

NA KOŃCU PRACY:
1. Zapisz raport: JDG/raporty_enterprise_v3/{OUT}.txt
2. Zaktualizuj rejestr: JDG/bundles/enterprise_v3_registry.json (blok części {num}).
3. Wydrukuj dokładnie:
   "V3-{OUT}_KOMPLETNE — SPÓJNOŚĆ ZAREJESTROWANA — CONTEXT_RESET_REQUIRED — wyczyść okno kontekstowe"
4. Kontynuuj kampanię szablonu: kolejność 01 → 20 zgodnie z sekwencerem.
"""


def build(num: str, tag: str, out: str, cons: str, scope: str, luki: str,
          pomysly: str, groups: list) -> str:
    head = (
        f"INSTRUKCJA DLA MODELU GLM 5.2 — CZĘŚĆ {num}/20: {tag}\n\n"
        "Jesteś Najwyższej klasy Ekspertem — architektem silników OPA/Rego klasy "
        "ENTERPRISE, ekspertem polskiego prawa podatkowego (akty wg JDG/docs/Bbb) "
        "i inżynierem niezawodności. Twoim zadaniem: przeprowadź głębokie myślenie, "
        "przeprowadź głęboką analizę modułu "
        f"„{tag}” w katalogu JDG, wykryj wszystkie luki, braki, niedociągnięcia, "
        "a następnie wygeneruj INTELIGENTNY KOD oraz rozbudowany raport na "
        "zaawansowanym poziomie Enterprise — poziom ENTERPRISE — z innowacyjnymi "
        "ulepszeniami wyprzedzającymi profesjonalistów. Wszystkie reguły Rego muszą "
        "być zgodne z aktami prawnymi z JDG/docs/Bbb (lista aktów) i z DWOMA "
        "ŚWIĘTYMI dokumentami docelowymi modułu (V1 i V2 — linki poniżej), które "
        "wyznaczają ostateczną strukturę modułu JDG.\n"
    )
    repeats = "\nWYMUSZONE POWTÓRZENIA FRAZ (wklej 4x do raportu w sekcjach A-H):\n" + \
        "\n".join(f"[{i}] " + " — ".join(FRAZES) for i in range(1, 5)) + "\n"
    scope_section = (
        f"\nZAKRES PRAWNY I TECHNICZNY TEJ CZĘŚCI (podstawa głębokiej analizy):\n{scope}\n"
    )
    luki_section = (
        "\nZNANE LUKI / BRAKI / NIEDOCIĄGNIĘCIA DO POTWIERDZENIA \n"
        "(zweryfikuj KAŻDĄ w kodzie, potwierdź lub obal, dodaj nowe, minimum 20):\n"
        f"{luki}\n"
    )
    ideas_section = (
        "\nPOMYSŁY SEED (rozbuduj je i dodaj własne innowacyjne ulepszenia "
        "wyprzedzające profesjonalistów):\n"
        f"{pomysly}\n"
    )
    parts = [
        head,
        BUDGET,
        sacred_block(),
        patterns_block(),
        scope_section,
        luki_section,
        ideas_section,
        files_block(num, groups),
        STEPS.format(OUT=out, CONS=cons, num=num),
        repeats,
    ]
    return "\n".join(parts) + "\n"


def main() -> int:
    import v3_parts_data_a as da
    import v3_parts_data_b as db
    PARTS = da.PARTS_A + db.PARTS_B
    OUT.mkdir(parents=True, exist_ok=True)
    ok = True
    for p in PARTS:
        num, tag, out, cons, scope, luki, pomysly, groups = p
        txt = build(num, tag, out, cons, scope, luki, pomysly, groups)
        path = OUT / f"{out}.txt"
        path.write_text(txt, encoding="utf-8")
        for f in FRAZES:
            cnt = txt.count(f)
            if cnt < 4:
                print(f"!! {path.name}: fraza '{f}' tylko {cnt}x")
                ok = False
    print(f"OK — wygenerowano {len(PARTS)} plików PROMPT w {OUT}" if ok
          else "NIEKOMPLETNE frazy — sprawdź logi powyżej")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())