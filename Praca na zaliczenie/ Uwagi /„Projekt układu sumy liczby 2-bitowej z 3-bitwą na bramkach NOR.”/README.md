# Projekt układu sumy liczby 2-bitowej z 3-bitową na bramkach NOR

## Cel

Przygotowane materiały tworzą pracę w LaTeX-ie, którą można opublikować na Overleaf. Wszystkie pliki znajdują się w obrębie tego katalogu.

## Jak korzystać

1. **Najprostsza droga:** wgraj na Overleaf wyłącznie `projekt_caly/caly_projekt.tex`.
   Plik jest samowystarczalny — preamble i wszystkie rysunki (TikZ) ma wklejone w sobie, nie potrzebuje żadnych plików PNG.

2. Alternatywnie — wariant wieloplikowy:
   - `projekt_caly/caly_projekt.tex` — główny plik pracy
   - `projekt_caly/preamble.tex` — wspólny preamble
   - `projekt_caly/rysunki.tex` — biblioteka rysunków TikZ
   - `projekt_caly/punkt1_wstep.tex` … `punkt6_podsumowanie.tex` — pojedyncze punkty

3. Skompiluj `caly_projekt.tex` (najlepiej 2 razy, dla spisu treści i odnośników) — powstanie PDF z wszystkimi punktami i rysunkami.

## Struktura pracy

Praca zawiera 6 punktów:

1. Wstęp teoretyczny — definicja sumatora, zasada działania, zastosowania, rodzaje sumatorów, przejście do dalszej części.
2. Opis techniczny projektu — założenia, specyfikacja wejść i wyjść, analiza logiczna, tabela sygnałowa, schematy, przejście do następnego punktu.
3. Minimalizacja funkcji logicznej — funkcje wyjściowe, karty Karnaugha, postać minimalna na bramkach NOR, porównanie liczby bramek, przejście.
4. Schematy logiczne, tabelaryczne i wykresowe — schemat logiczny, tablica prawdy, schemat blokowy, wykres/ opis czasowy.
5. Symulacja i testowanie — środowisko symulacyjne, przygotowanie układu, scenariusze testowe, oczekiwane wyniki, analiza wyników.
6. Podsumowanie i wnioski — ocena układu, korzyści z minimalizacji bramek NOR, ograniczenia, możliwości rozwoju, zakres pracy.

## Uwagi techniczne

- `preamble.tex` używa `\usepackage[polish]{babel}` — Overleaf powinien obsłużyć to bez dodatkowych ustawień.
- Wszystkie rysunki (schemat blokowy, schemat logiczny na bramkach NOR, przebiegi czasowe) są wykonane **inline w TikZ** (`rysunki.tex`) — nie wymagają plików graficznych i skalują się bez utraty jakości.
- Rysunki wstawiane są przez makra: `\RysSchematBlokowy`, `\RysSchematBlokowyDwa`, `\RysSchematNOR`, `\RysSchematMinimalny`, `\RysPrzebiegi` (owinięte w `\resizebox`, aby mieściły się na stronie).
- W logach można spotkać warning `Label(s) may have changed` po pierwszym kompilowaniu — normalne; drugi przebieg go usuwa.
- Wspólny schematic wzorca: `\usetikzlibrary{shapes.gates.logic.US, arrows.meta, positioning, calc}` jest już w `preamble.tex` (i wklejone w `caly_projekt.tex`).

## Sekcje w jednym pliku

Po skompilowaniu `caly_projekt.tex` powinien pojawić się spis treści i kolejno:

- Wstęp teoretyczny
- Opis techniczny projektu
- Minimalizacja funkcji logicznej
- Schematy logiczne, tabelaryczne i wykresowe
- Symulacja i testowanie
- Podsumowanie i wnioski
