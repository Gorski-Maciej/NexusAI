#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Regeneracja raportów GLM52 z promptów i dowodów lokalnego repozytorium.

Raporty są audytami stanu faktycznego: nie kopiują instrukcji promptu i nie
udają wdrożeń. Każde twierdzenie o stanie kodu jest oparte na inwentarzu
plików wskazanych w odpowiednim prompcie; brakujące ścieżki są jawnie oznaczane.
"""
from __future__ import annotations

import re
import shutil
from collections import Counter
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
JDG = ROOT / "JDG"
PROMPTS = JDG / "prompty_glm52"
REPORTS = JDG / "raporty_glm52"

PATH_RE = re.compile(r"https://github\.com/[^\s)`]+/blob/main/JDG/([^\s)`]+)")
RULE_ID_RE = re.compile(r'"rule_id"\s*:\s*"([^"]+)"')
PACKAGE_RE = re.compile(r'^\s*package\s+([^\s]+)', re.MULTILINE)
LEGAL_RE = re.compile(r'"?_legal_basis"?\s*:\s*"([^"]+)"')
TEMPORAL_RE = re.compile(r'\bvalid_(?:from|to)\b')

# These are report outputs explicitly declared in the prompts. The prompt is
# authoritative, so old aliases in raporty_glm52 are removed before generation.

def clean_token(path: str) -> str:
    return path.rstrip(".,;:")


def prompt_data(prompt: Path) -> dict:
    text = prompt.read_text(encoding="utf-8", errors="replace")
    n = int(prompt.name[:2])
    out = re.search(r"Raport zapisz jako plik: `JDG/raporty_glm52/([^`]+)", text)
    title_match = re.search(rf"PROMPT\s+{n:02d}/\d+\s+—\s+(.+)", text)
    focus_match = re.search(
        r"## 🎯 CEL ANALIZY TEJ CZĘŚCI:\n(.*?)(?=\n## |\Z)", text, re.S
    )
    paths = []
    for raw in PATH_RE.findall(text):
        raw = clean_token(raw)
        if raw not in paths:
            paths.append(raw)
    return {
        "number": n,
        "prompt": prompt.name,
        "output": out.group(1) if out else f"RAPORT_{n:02d}_NIEZNANY.txt",
        "title": title_match.group(1).strip() if title_match else prompt.stem,
        "focus": " ".join(focus_match.group(1).split()) if focus_match else "Brak sekcji celu.",
        "paths": paths,
    }


def resolve_path(raw: str) -> tuple[Path | None, str]:
    raw = raw.split("#", 1)[0]
    direct = JDG / raw
    if direct.exists():
        return direct, "wprost"
    # Never substitute a same-named file from another directory: that would
    # turn a missing prompt source into false evidence.
    return None, "brak"


def files_for(path: Path) -> list[Path]:
    if path.is_file():
        return [path]
    return sorted(p for p in path.rglob("*") if p.is_file())


def read_sample(path: Path) -> str:
    """Read the complete text so reported counts are not prefix samples."""
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def file_stats(path: Path) -> dict:
    try:
        size = path.stat().st_size
        with path.open("r", encoding="utf-8", errors="replace") as fh:
            lines = sum(1 for _ in fh)
    except (OSError, UnicodeError):
        size, lines = 0, 0
    sample = read_sample(path)
    ids = RULE_ID_RE.findall(sample)
    packages = PACKAGE_RE.findall(sample)
    legal = LEGAL_RE.findall(sample)
    return {
        "path": str(path.relative_to(JDG)),
        "bytes": size,
        "lines": lines,
        "ids": ids,
        "packages": packages,
        "legal": legal,
        "temporal": len(TEMPORAL_RE.findall(sample)),
    }


def esc(value: object) -> str:
    return str(value).replace("|", "\\|").replace("\n", " ")


def pct(a: int, b: int) -> str:
    return f"{(100*a/b):.1f}%" if b else "n/d"


def domain_tests(number: int, title: str) -> list[Path]:
    words = set(re.findall(r"[a-z0-9]+", title.lower()))
    aliases = {
        4: {"pit"}, 5: {"pit", "enterprise"}, 6: {"zus", "sus"},
        7: {"kks"}, 8: {"ordynacja", "obrona"}, 9: {"uor", "pkpir", "księgowość"},
        10: {"cross-border", "crossborder", "tp", "mdr"},
        11: {"pcc", "podatki", "lokalne", "akcyzą"},
        12: {"ryczałt", "ceidg", "sukcesja"}, 13: {"hyper", "plan45"},
        14: {"rodo", "aml", "bdo", "środowisko"},
        15: {"ksef", "jpk", "e-deklaracje"}, 16: {"system", "opa"},
        17: {"enterprise", "ai", "inteligencja"}, 18: {"narzędzia", "systemowe"},
        19: {"narzędzia", "domenowe"}, 20: {"testy", "pytest"},
        21: {"testy", "natywne", "rego"}, 22: {"bundle", "api", "migracje"},
        23: {"dokumentacja"}, 24: {"policies"},
    }
    keys = aliases.get(number, words)
    out = []
    for p in sorted((JDG / "tests").rglob("*")):
        if not p.is_file() or p.suffix not in {".py", ".rego"}:
            continue
        low = p.name.lower()
        if any(k.lower() in low for k in keys):
            out.append(p)
    return out[:40]


def relevant_snippets(stats: list[dict]) -> list[str]:
    snippets = []
    for s in stats:
        if s["ids"]:
            snippets.append(f"{s['path']}: rule_id={len(s['ids'])}, przykłady={', '.join(s['ids'][:3])}")
        elif s["packages"]:
            snippets.append(f"{s['path']}: package={', '.join(s['packages'][:2])}")
    return snippets[:20]


def report_for(data: dict) -> str:
    resolved, missing = [], []
    for raw in data["paths"]:
        path, how = resolve_path(raw)
        if path is None:
            missing.append(raw)
        else:
            resolved.append((raw, path, how))

    unique_files = {}
    for _, path, _ in resolved:
        for f in files_for(path):
            unique_files[str(f)] = f
    stats = [file_stats(f) for f in sorted(unique_files.values())]
    rego = [s for s in stats if s["path"].endswith(".rego")]
    tests = domain_tests(data["number"], data["title"])
    test_stats = [file_stats(f) for f in tests]
    all_ids = [x for s in rego for x in s["ids"]]
    duplicate_ids = sorted(k for k, v in Counter(all_ids).items() if v > 1)
    packages = sorted({p for s in rego for p in s["packages"]})
    legal_count = sum(len(s["legal"]) for s in rego)
    temporal_files = sum(1 for s in rego if s["temporal"])
    total_bytes = sum(s["bytes"] for s in stats)
    total_lines = sum(s["lines"] for s in stats)
    focus = data["focus"]
    selected_names = ", ".join(s["path"] for s in stats[:12]) or "brak rozwiązanego artefaktu"
    missing_text = ", ".join(missing[:25]) if missing else "brak"
    status = "AUDYT OPARTY NA DOWODACH" if stats else "NIEKOMPLETNY — BRAK ROZWIĄZANYCH ŹRÓDEŁ"

    lines: list[str] = []
    add = lines.append
    add("=" * 100)
    add(f"RAPORT ANALITYCZNY ENTERPRISE — CZĘŚĆ {data['number']:02d}/25 — {data['title']}")
    add("=" * 100)
    add(f"Data wygenerowania: {date.today().isoformat()} | Źródło sterujące: {data['prompt']}")
    add(f"Status raportu: {status}")
    add("Metoda: automatyczny audyt plików wskazanych w prompcie + selektywna analiza tekstowa; bez generowania kodu.")
    add("UWAGA METODYCZNA: rekomendacja, plan lub nazwa reguły nie oznacza, że dana funkcja została wdrożona.")
    add("")
    add("1. EXECUTIVE SUMMARY")
    add("- Zakres promptu: " + focus)
    add(f"- Rozwiązane ścieżki promptu: {len(resolved)}/{len(data['paths'])}; brakujące: {len(missing)}.")
    add(f"- Przeanalizowane unikalne pliki: {len(stats)} ({len(rego)} Rego), {total_lines:,} linii, {total_bytes:,} B.")
    add(f"- Zaobserwowane rule_id: {len(all_ids)}, unikalne: {len(set(all_ids))}, duplikaty w zakresie: {len(duplicate_ids)}.")
    add(f"- Pliki Rego z polem valid_from/valid_to w próbie: {temporal_files}/{len(rego)} ({pct(temporal_files, len(rego))}).")
    add(f"- Wystąpienia _legal_basis w próbie: {legal_count}; pakiety Rego: {len(packages)}.")
    add(f"- Dopasowane testy domenowe po nazwie pliku: {len(tests)}.")
    add("")
    add("TOP 10 USTALEŃ / REKOMENDACJI")
    findings = [
        ("P0", f"Zamknąć {len(missing)} nierozwiązanych odwołań promptu albo zaktualizować prompt; nie wolno traktować braku pliku jako dowodu implementacji."),
        ("P0", f"Ustalić bramkę spójności dla {len(set(all_ids))} unikalnych rule_id; wykryte duplikaty w zakresie: {len(duplicate_ids)}."),
        ("P0", "Wymagać testu pozytywnego, granicznego, negatywnego/no_match i temporalnego dla każdej krytycznej reguły."),
        ("P0", "Powiązać każdą regułę materialną z kanonicznym _legal_basis oraz rekordem w Legal Twin; nie ufać samemu komentarzowi."),
        ("P1", f"Podnieść temporalność: obecnie wykryto ją w {temporal_files}/{len(rego)} plików Rego w zakresie audytu."),
        ("P1", "Parametry stawek, progów, limitów i terminów trzymać w danych wersjonowanych; wykrywać hardcode w CI."),
        ("P1", "Dodać golden replay i diff werdyktów przed kanarem; zmiana prawa musi mieć datę wejścia i datę wygaśnięcia."),
        ("P1", "Dopiąć provenance: input → rule_id → podstawa → test → bundle → Decision Certificate."),
        ("P2", "Utworzyć dashboard pokrycia domeny z rozróżnieniem: istnieje kod, istnieje test, istnieje podstawa, działa w routerze."),
        ("P2", "Oznaczać rekomendacje jako SUGGEST/ASK_USER; raport nie powinien prowadzić do automatycznej decyzji podatkowej."),
    ]
    for i, (prio, text) in enumerate(findings, 1):
        add(f"{i:02d}. {prio}: {text}")
    add("")
    add("2. DOWÓD Z REPOZYTORIUM")
    add("2.1. Rozwiązanie ścieżek wskazanych przez prompt")
    add("| Ścieżka z promptu | Rozwiązanie | Tryb |")
    add("|---|---|---|")
    for raw, path, how in resolved[:80]:
        add(f"| `{esc(raw)}` | `{esc(path.relative_to(JDG))}` | {how} |")
    if len(resolved) > 80:
        add(f"| … | pominięto {len(resolved)-80} dalszych ścieżek w tabeli; statystyki obejmują wszystkie | — |")
    add("")
    add("2.2. Ścieżki nierozwiązane — nie są dowodem istnienia funkcji")
    add("- " + missing_text)
    add("")
    add("2.3. Statystyki artefaktów")
    add("| Plik | Linie | Bajty | rule_id | _legal_basis | temporal | package |")
    add("|---|---:|---:|---:|---:|---:|---|")
    for s in stats[:100]:
        add(f"| `{esc(s['path'])}` | {s['lines']} | {s['bytes']} | {len(s['ids'])} | {len(s['legal'])} | {s['temporal']} | {esc(', '.join(s['packages'][:2]))} |")
    if len(stats) > 100:
        add(f"| … | pominięto {len(stats)-100} plików w tabeli | | | | | |")
    add("")
    add("3. ANALIZA PRAWO → REGUŁA → TEST → WERDYKT")
    add("Przeprowadź głębokie myślenie nad łańcuchem dowodowym, ale nie utożsamiaj obecności tekstu z poprawnością prawną.")
    add("- PRAWO: prompt wskazuje akty i artykuły; raport wymaga potwierdzenia w docs/Bbb/LEGAL_REFERENCE_ACTS oraz kanonicznego identyfikatora aktu.")
    add(f"- REGUŁA: w wybranych plikach znaleziono {len(all_ids)} deklarowanych rule_id ({len(set(all_ids))} unikalnych); przykładowe obserwacje:")
    for s in relevant_snippets(rego):
        add("  - " + s)
    add("- TEST: dopasowanie nazwy pliku testowego nie dowodzi wykonania testu; należy uruchomić pytest/opa test i zapisać wynik w CI.")
    add(f"- WERDYKT: należy zweryfikować, czy pakiety ({len(packages)}) są rzeczywiście włączone przez router, safe_merge i końcowy invariant check.")
    add("- DATA: wartości liczbowe należy porównać z bundle canonical; ten generator nie uznaje samego literalnego wystąpienia liczby za potwierdzenie jej prawidłowości.")
    add("")
    add("4. REJESTR LUK I RYZYK")
    add("| ID | Obserwacja | Dowód | Wpływ | Priorytet | Kryterium zamknięcia |")
    add("|---|---|---|---|---|---|")
    gaps = [
        ("G-01", f"Brakujące ścieżki źródłowe: {len(missing)}", "Tabela 2.2", "Niepełny audyt", "P0", "0 braków albo jawne mapowanie migracyjne"),
        ("G-02", f"Duplikaty rule_id w próbie: {len(duplicate_ids)}", ", ".join(duplicate_ids[:5]) or "brak", "Niedeterminizm / kolizja", "P0", "dead_rule_detector = 0"),
        ("G-03", f"Brak temporalności w {len(rego)-temporal_files}/{len(rego)} plików Rego", "Tabela 2.3", "Błędny time-travel", "P1", "valid_from/valid_to + test graniczny"),
        ("G-04", "Niepotwierdzony most test → reguła → werdykt", "Brak wyniku uruchomienia w raporcie", "Cichy regres", "P1", "coverage + golden replay"),
        ("G-05", "Niepotwierdzona kanoniczność podstaw prawnych", f"_legal_basis={legal_count}", "Ryzyko błędnej podstawy", "P0", "Legal Twin i validator przechodzą"),
        ("G-06", "Brak dowodu wdrożenia kanarowego", "Prompt opisuje wymaganie; repo wymaga weryfikacji runtime", "Niebezpieczny release", "P1", "metryki + auto-rollback test"),
    ]
    for row in gaps:
        add("| " + " | ".join(esc(x) for x in row) + " |")
    add("")
    add("5. OPA JAKO SYSTEM")
    add("Control Plane: rejestr reguł, review, walidacja, podpisany bundle, Legal Twin, kanar i rollback.")
    add("Data Plane: deterministyczna ewaluacja, First-Match-Wins, safe_merge, temporalność, provenance i runtime invariants.")
    add("Minimalny kontrakt wydania:")
    add("```text")
    add("change request → legal diff → rule/test diff → validate/lint → pytest + opa test")
    add("→ legal-basis gate → duplicate/stub/tautology gate → golden replay")
    add("→ signed bundle → canary → health metrics → ACTIVE albo ROLLED_BACK")
    add("```")
    add("Każdy etap musi pozostawić artefakt, wersję i hash; sam raport analityczny nie zmienia lifecycle reguły.")
    add("")
    add("6. TESTY I WALIDACJA")
    add("| Test / grupa | Stan istnienia | Wymagany dowód |")
    add("|---|---|---|")
    for t, ts in zip(tests, test_stats):
        add(f"| `{esc(ts['path'])}` | istnieje, {ts['lines']} linii | uruchomienie + wynik + przypadki graniczne |")
    if not tests:
        add("| testy domenowe po nazwie | nie znaleziono | dodać lub jawnie udokumentować brak |")
    add("Rekomendowany zestaw: happy path, no_match, granice progów, data przed/po nowelizacji, duplikat/konflikt, brak danych, rollback i determinism replay.")
    add("")
    add("7. INNOWACYJNE ULEPSZENIA WYPRZEDZAJĄCE PROFESJONALISTÓW")
    ideas = [
        "Legal Twin diff: zmiana artykułu automatycznie pokazuje dotknięte rule_id, testy i formularze.",
        "Temporal boundary generator: automatyczne przypadki dzień przed / dzień wejścia / dzień po.",
        "Decision Certificate verifier: podpis, bundle_version, rule_version, threshold_version i hash wejścia.",
        "Rule impact graph: graf zależności reguła → router → werdykt → dokument.",
        "Evidence completeness score: osobne wyniki dla prawa, kodu, testu, danych i runtime.",
        "Golden replay bank per domena i wersja prawa, z tolerancją wyłącznie dla pól niedeterministycznych.",
        "Declarative Change Wizard z obowiązkowym ASK_USER przy niejednoznacznej podstawie prawnej.",
        "Canary risk budget: automatyczny rollback po wzroście BLOCK_AND_ALERT lub zmianie rozkładu werdyktów.",
        "Hardcode provenance scanner: literal → źródło danych → data obowiązywania → test.",
        "Coverage desert radar: mapa aktów i pakietów bez reguł, bez testów albo bez routera.",
        "Explainability bundle: dowód decyzji eksportowany razem z wersją reguły i podstawą prawną.",
        "Mutation testing dla najważniejszych rule_id; brak wykrycia mutacji blokuje promocję do ACTIVE.",
    ]
    for i, idea in enumerate(ideas, 1):
        add(f"{i:02d}. {idea}")
    add("Wszystkie powyższe punkty są rekomendacjami projektowymi, nie stwierdzeniem, że funkcje istnieją.")
    add("")
    add("8. KONTRAKTY Z INNYMI CZĘŚCIAMI")
    add("- Raport master 00: wspólne LCI/TCL/RV/UVR, _legal_basis, valid_from/valid_to, rule_id, 25-polowy werdykt.")
    add(f"- Pakiety wykryte w bieżącym zakresie: {', '.join(packages[:30]) or 'brak'}.")
    add("- Części sąsiednie muszą traktować powyższe nazwy jako obserwację, nie jako zgodę na dodawanie reguł bez rejestracji.")
    add("- Zmiana rule_id wymaga aktualizacji routera, manifestu, testów, bundle, dokumentacji i golden replay.")
    add("")
    add("9. MAPA DROGOWA")
    add("| Etap | Zadanie | Kryterium | Szacunek |")
    add("|---|---|---|---|")
    add("| P0 | Uzupełnić/uzgodnić źródła i legal basis | 0 braków, validator OK | 1–3 dni |")
    add("| P0 | Zbudować testy krytycznych rule_id | positive/negative/boundary | 2–5 dni |")
    add("| P1 | Wdrożyć temporalny golden replay | przejścia dat bez regresji | 2–5 dni |")
    add("| P1 | Podłączyć provenance i Decision Certificate | pełny łańcuch dowodu | 2–5 dni |")
    add("| P1 | Kanar + metryki + rollback | test SLA i failure injection | 1–2 tyg. |")
    add("| P2 | Dashboard coverage/evidence | trend domeny per bundle | 1–2 tyg. |")
    add("")
    add("10. WNIOSKI KOŃCOWE")
    add(f"Audyt części {data['number']:02d} potwierdza istnienie {len(stats)} artefaktów w zakresie promptu, ale nie potwierdza automatycznie ich poprawności prawnej ani aktywnego routingu.")
    add("Największa wartość raportu to rozdzielenie faktów (inwentarz i skany) od rekomendacji (roadmapa). Przed wdrożeniem każdej zmiany wymagane są review prawne, testy i podpisany bundle.")
    add("=" * 100)
    add(f"KONIEC RAPORTU {data['number']:02d}/25 — raport wygenerowany z promptu {data['prompt']}")
    add("=" * 100)
    return "\n".join(lines) + "\n"


def main() -> int:
    REPORTS.mkdir(parents=True, exist_ok=True)
    # Preserve the first four reports. Remove only legacy report files and the
    # obsolete status marker that claimed the discarded series was complete;
    # unrelated metadata in the directory is left untouched.
    keep = {
        "RAPORT_00_FUNDAMENT_ARCHITEKTURA.txt",
        "RAPORT_01_ORKIESTRATOR_RDZEN.txt",
        "RAPORT_02_VAT_CORE.txt",
        "RAPORT_03_VAT_MICRO.txt",
    }
    declared = {
        prompt_data(p)["output"]
        for p in PROMPTS.glob("[0-9][0-9]_*.txt")
        if 4 <= int(p.name[:2]) <= 24
    }
    stale_status = {"STATUS_WDROZEN.txt"}
    for p in REPORTS.iterdir():
        if not p.is_file():
            continue
        if p.name in stale_status or (p.name.startswith("RAPORT_") and p.name not in keep and p.name not in declared):
            p.unlink()
    generated = []
    for prompt in sorted(PROMPTS.glob("[0-9][0-9]_*.txt")):
        n = int(prompt.name[:2])
        if n < 4 or n > 24:
            continue
        data = prompt_data(prompt)
        target = REPORTS / data["output"]
        target.write_text(report_for(data), encoding="utf-8")
        generated.append(target)
    print(f"Wygenerowano {len(generated)} raportów 04–24.")
    for p in generated:
        print(f"{p.relative_to(ROOT)}\t{p.stat().st_size} B\t{sum(1 for _ in p.open(encoding='utf-8'))} linii")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
