# Projekt układu sumatora pełnego (Full Adder) z minimalizacją bramek logicznych

Praca zaliczeniowa z Elektroniki — LaTeX (pdfLaTeX), kompilacja w **Overleaf** lub lokalnie.

---

## Co jest w tym katalogu

| Plik | Rola |
|------|------|
| `main.tex` | **Wariant A** — dokument główny (wieloplikowy), wczytuje punkty przez `\input` |
| `01_wstep_teoretyczny.tex` … `06_zrodla.tex` | **Wariant A** — 6 plików z treścią punktów 1–6 |
| `praca_kompletna.tex` | **Wariant B** — cała praca w JEDNYM pliku (treść identyczna z wariantem A) |
| `Elektronika (1) (2).docx` | praca wzorcowa (tylko referencja — nie kompilować) |
| `Spis treści` | spis treści pracy (tylko referencja) |

Oba warianty generują **ten sam PDF (~20 stron)**: strona tytułowa, spis treści, 6 rozdziałów, 3 rysunki, 7 tabel.

---

## WARIANT A — wersja wieloplikowa (`main.tex` + 6 plików)

Przydatny, gdy praca jest edytowana punkt po punkcie.

1. Wejdź na [overleaf.com](https://www.overleaf.com) i zaloguj się.
2. **New Project → Blank Project** — nadaj nazwę, np. `Full Adder`.
3. W lewym panelu (file tree) kliknij ikonę **Upload** (strzałka w górę).
4. Wgraj **wszystkie 7 plików `.tex`**:
   - `main.tex`
   - `01_wstep_teoretyczny.tex`
   - `02_opis_techniczny.tex`
   - `03_implementacja.tex`
   - `04_symulacja.tex`
   - `05_podsumowanie.tex`
   - `06_zrodla.tex`
5. Otwórz **Menu** (lewy górny róg) i ustaw:
   - **Compiler:** `pdfLaTeX` (domyślny — zostaw)
   - **Main document:** `main.tex`
6. Kliknij **Recompile** — potem jeszcze **raz** (drugi przebieg buduje spis treści i odwołania `Rysunek 1–3`).
7. PDF pobierzesz przyciskiem **Download PDF** (obok Recompile).

> **Uwaga:** pliki muszą leżeć *płasko* w głównym katalogu projektu (nie w podfolderze) — `\input{...}` odwołuje się do nazw bez ścieżek.

---

## WARIANT B — wersja jedno-plikowa (`praca_kompletna.tex`)

Najprostszy: jeden plik, zero zależności między plikami.

1. **New Project → Blank Project** na Overleaf.
2. Wgraj **tylko** `praca_kompletna.tex`.
3. **Menu → Main document:** `praca_kompletna.tex`, Compiler: `pdfLaTeX`.
4. **Recompile ×2** (drugi przebieg — dla spisu treści i numerów rysunków).
5. **Download PDF** — gotowe.

---

## Przed oddaniem — wpisz swoje dane

W pliku głównym (A: `main.tex`, B: `praca_kompletna.tex`) znajdź i zastąp w **2 miejscach**:

```
[IMIĘ NAZWISKO NUMER INDEKSU]
```

1. **Strona tytułowa** — tabela na dole strony tytułowej,
2. **Metadane PDF** — pole `pdfauthor={...}` w `\hypersetup`.

---

## Kompilacja lokalna (alternatywa dla Overleaf)

Wymagany TeX Live / MiKTeX z pakietami: `babel-polish`, `tikz`, `circuitikz`, `booktabs`, `setspace`, `hyperref`, `cmap`, `glyphtounicode`.

```bash
pdflatex main.tex            # lub praca_kompletna.tex
pdflatex main.tex            # drugi przebieg: spis treści + \ref
```

lub automatycznie:

```bash
latexmk -pdf main.tex
```

---

## Rozwiązywanie problemów

| Objaw | Przyczyna / rozwiązanie |
|-------|------------------------|
| Spis treści pusty, w tekście `??` zamiast numerów rysunków | Zrobiłeś tylko 1 przebieg kompilacji — **skompiluj drugi raz** |
| Błąd `File '01_wstep_teoretyczny' not found` (wariant A) | Nie wgrałeś wszystkich 6 plików punktów albo leżą w podfolderze |
| Ostrzeżenie o `lmodern` | Niekrytelne — kod używa `\IfFileExists`, kompilacja przejdzie też bez tego pakietu |
| Polskie znaki krzaczą się przy kopiowaniu z PDF | Upewnij się, że w preambule jest `\input{glyphtounicode}` + `\pdfgentounicode=1` + `\usepackage{cmap}` (są w obu wariantach) |
| 2 × `Overfull \hbox` w logu | Kosmetyczne (szerokie tabele/mapy Karnaugha) — nie wpływa na treść |
| Zmieniłeś treść w `01–06`, a PDF się nie zmienia (wariant B) | Wariant B to osobna, sklejona kopia — edytuj `praca_kompletna.tex` albo przegeneruj go z wariantu A |

---

## Struktura pracy (6 punktów)

1. **Wstęp teoretyczny** — definicja, zasada działania, zastosowania, rodzaje sumatorów (+ Rys. 1: symbol blokowy FA)
2. **Opis techniczny projektu** — założenia, specyfikacja sygnałów, analiza logiczna, tablica prawdy, 2 mapy Karnaugha, minimalizacja (13–16 → 5 bramek), porównanie
3. **Implementacja i realizacja** — dobór bramek (74HC86/08/32), projekt, schemat logiczny (+ Rys. 2), realizacja
4. **Symulacja i testowanie** — środowisko, scenariusze, tabela wyników, przebiegi czasowe (+ Rys. 3)
5. **Podsumowanie i wnioski** — ocena, korzyści, ograniczenia, możliwości rozwoju
6. **Źródła** — bibliografia

Funkcje końcowe: `s = a ⊕ b ⊕ c_in`,  `c_out = a·b ∨ c₁·c_in`,  gdzie `c₁ = a ⊕ b`.
