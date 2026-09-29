# Projekt układu sumy liczby 2-bitowej z 3-bitową na bramkach NOR

## Cel

Przygotowane materiały tworzą pracę w LaTeX-ie, którą można opublikować na Overleaf. Wszystkie pliki znajdują się w obrębie tego katalogu.

## Jak korzystać

1. Otwórz na Overleaf projekt z plikami:
   - `projekt_caly/caly_projekt.tex` — główny plik pracy
   - `projekt_caly/preamble.tex` — wspólny preamble
   - `projekt_caly/punkt1_wstep.tex` … `punkt6_podsumowanie.tex` — pojedyncze punkty
   - `projekt_caly/syg1.png`, `syg2.png`, `syg3.png` — placeholdery pod rysunki i schematy

2. Wgraj folder `projekt_caly` na Overleaf (lub skopiuj te pliki bezpośrednio).

3. Skompiluj `caly_projekt.tex` — powinien wygenerować PDF z wszystkimi punktami.

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
- `syg1.png`, `syg2.png`, `syg3.png` są zastępcze. W razie potrzeby można je podmienić na własne rysunki/schematy.
- W logach można spotkać warningi typu `Float too large for page` oraz `Label(s) may have changed` po pierwszym kompilowaniu — są to normalne ostrzeżenia LaTeX.
- Na zachowanie plików `.tex` i `.png` w tym samym katalogu patrz `caly_projekt.tex`.

## Sekcje w jednym pliku

Po skompilowaniu `caly_projekt.tex` powinien pojawić się spis treści i kolejno:

- Wstęp teoretyczny
- Opis techniczny projektu
- Minimalizacja funkcji logicznej
- Schematy logiczne, tabelaryczne i wykresowe
- Symulacja i testowanie
- Podsumowanie i wnioski
