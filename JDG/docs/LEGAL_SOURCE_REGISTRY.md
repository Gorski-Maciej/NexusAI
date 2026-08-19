# Legal Source Registry — ETAP 02

> Generator: `JDG/tools/legal_source_registry.py` · schema `1.0.0`
> Status danych: kandydaci repozytoryjni; brak fikcyjnej certyfikacji aktualności prawa.

## Model

- `source_record_id` — stabilny identyfikator źródła.
- `source_hash` — SHA-256 metadanych rekordu; nie jest hashem oficjalnego tekstu ustawy.
- `effective_interval` — jawny interwał z oznaczeniem `UNVERIFIED_EXTERNAL`.
- `provenance` — ścieżka katalog → dokument → wymagany feed oficjalny.
- `confidence` — pewność kandydata repozytoryjnego, nie opinia prawna.
- `legal_nodes` — węzły LKG z referencją do rekordu źródłowego i propagowanym hashem.

## 4-eyes i publikacja

Publikacja jest blokowana do czasu dostarczenia hashy oficjalnego snapshotu, dwóch różnych recenzentów oraz zatwierdzenia interwału i diffu prawnego.

## Wynik budowy

- Rekordy źródeł: 30
- Węzły Legal Twin: 181
- Węzły bez dopasowanego rekordu: 0
- Walidacja strukturalna: **PASS**
- Rekordy oczekujące na 4-eyes: 30

## Ograniczenia

- Repozytorium nie zawiera pobranych, podpisanych tekstów ISAP/RCL; pipeline nie może ich wymyślić.
- Część `legal_graph.json` ma historyczne lub niezweryfikowane interwały; pozostają jawnie oznaczone.
- `PUBLISHED` jest niedostępny bez zewnętrznego snapshotu i dwóch niezależnych akceptacji.
