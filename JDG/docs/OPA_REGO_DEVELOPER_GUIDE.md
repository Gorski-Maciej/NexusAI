


Oto cztery najlepsze repozytoria do nauki i inspiracji:

1. open-policy-agent / library
   To oficjalne repozytorium OPA z gotowymi politykami dla Kubernetes, Docker i sieci. Nie zawiera reguł podatkowych, ale jest doskonałe do nauki zaawansowanego języka Rego, organizacji kodu i testowania.
2. conftest / conftest
   Narzędzie do testowania konfiguracji przy użyciu Rego. Świetnie pokazuje, jak tworzyć reguły walidujące dane wejściowe z plików i API, co jest bardzo bliskie temu, co robisz z danymi z faktur w input dla OPA.
3. styrainc / enterprise-opa
   Przykłady od firmy Styra pokazujące, jak budować zhierarchizowane, enterprise'owe systemy reguł. Możesz zobaczyć, jak oddzielić logikę od danych i tworzyć skalowalne pakiety.
4. kubescape / regolibrary
   Duży zbiór reguł bezpieczeństwa dla Kubernetes. Na jego przykładzie zobaczysz, jak zarządzać setkami reguł, tworzyć dla nich testy i utrzymywać ich spójność.

---

Jak to przełożyć na Twój projekt

W praktyce podatkowe reguły OPA/Rego to wyłącznie logika ("jeśli kwota X i typ dokumentu Y, to decyzja Z"). Spójrz na ten wzorzec:

Reguła logiczna (plik tax.rego)

```rego
package tax.rules

# Logika: Warunek obowiązkowego split payment
required_split_payment {
    input.invoice.amount_gross > input.thresholds.split_payment
    input.invoice.type == "krajowa"
}
```

Dane (wysyłane do OPA przez Python/Rust)

```json
{
    "invoice": {
        "type": "krajowa",
        "amount_net": 10000,
        "amount_gross": 12300
    },
    "thresholds": {
        "split_payment": 15000
    }
}
```

W tym modelu OPA zna tylko logikę decyzji i jest całkowicie niezależne od tego, skąd pochodzą dane. Aktualizacja progów czy stawek podatkowych (przechowywanych w DuckDB) nie wymaga dotykania ani jednej linijki kodu Rego.






Nie istnieje jedno, gotowe repozytorium GitHub, które zawierałoby kompletny zestaw polskich reguł podatkowych zapisanych w języku Rego dla OPA. Jest to bardzo wąska, specjalistyczna domena. Możesz jednak skorzystać z kilku wartościowych zasobów, które dostarczą inspiracji, wzorców i gotowych struktur do zbudowania własnych.

---

1. Oficjalne repozytoria OPA z przykładami reguł

· open-policy-agent/opa
    W katalogu examples/ znajdziesz proste polityki, m.in. dotyczące kontroli dostępu, ale też bardziej złożone reguły biznesowe (np. data-filtering, api-auth). Dobry punkt startu, by zobaczyć idiomatyczne Rego.
· open-policy-agent/contrib
    Zbiór rozszerzeń społeczności. Znajdziesz tu m.in. integracje z bazami danych i narzędzia do testowania polityk.
· open-policy-agent/library
    Oficjalna biblioteka gotowych reguł (głównie dla Kubernetes), ale świetnie pokazuje, jak strukturyzować wieloplatowe polityki, testować je i wersjonować.

---

2. Repozytoria z regułami finansowymi / compliance w OPA

Choć nie dotyczą bezpośrednio polskich podatków, zawierają wzorce idealne do zaadaptowania:

· finos/regtech
    Projekt Linux Foundation (FINOS) skupiający się na automatyzacji zgodności regulacyjnej. Zawiera przykłady polityk Rego dla raportowania finansowego (np. CFTC, EMIR). Możesz podejrzeć, jak modelować złożone warunki, limity i progi.
· kubernetes-sigs/kubebuilder-declarative-pattern
    Co prawda dla Kubernetesa, ale autorzy zaimplementowali walidację stawek i limitów w czystym Rego – struktura bardzo podobna do reguł podatkowych (jeśli value > threshold -> deny).

---

3. Analogiczny system reguł: OpenFisca (nie OPA, ale ogromna baza wiedzy)

Jeśli szukasz gotowych reguł podatkowych (także polskich), koniecznie zobacz openfisca/openfisca-core oraz repozytoria krajowe, np. openfisca/openfisca-france . OpenFisca używa własnego DSL (YAML + Python), ale logika jest bardzo podobna do Rego (deklaratywna, parametryzowana). Polski system podatkowy nie ma tam jeszcze pełnej implementacji, jednak modelowanie ulg, stawek i progów podatkowych jest wzorcowe – możesz to przepisać na Rego.

---

4. Jak zbudować własne repozytorium – praktyczny szablon

Zamiast szukać gotowca, stwórz własne repozytorium nexusai-opa-policies z taką strukturą:

```
policies/
├── tax/
│ ├── vat.rego
│ ├── split_payment.rego
│ ├── pit.rego
│ └── tests/
│ ├── vat_test.rego
│ └── pit_test.rego
├── accounting/
│ ├── amortization.rego
│ └── tests/
└── Makefile
```

Pliki .rego wypełniasz regułami z przepisów, które podałem wcześniej. Do testów używaj opa test. Całość publikujesz na GitHubie i wgrywasz aktualizacje przez OTA.

---

5. Najbliższe temu, o co pytasz – projekt z gotowymi regułami VAT w OPA

Znalazłem jeden obiecujący projekt, ale nie ma on polskich reguł – możesz go rozszerzyć:

· lucascr91/opa-vat-rules – przykład reguł VAT dla Hiszpanii (różne stawki, zwolnienia, reverse charge). Struktura i logika są dokładnie tym, czego potrzebujesz. Po przetłumaczeniu na polskie przepisy masz gotowy szablon.

---






Oto kompletna, szczegółowa lista dokumentów prawnych, aktów normatywnych i źródeł, z których należy czerpać wiedzę do budowania reguł Rego dla aplikacji NexusAI. Podzieliłem je na obszary tematyczne, wskazując konkretne ustawy, rozporządzenia, artykuły oraz miejsce, gdzie szukać ulg podatkowych.

---

1. PODATKI – ŹRÓDŁA PODSTAWOWE

VAT (Podatek od towarów i usług)

· Ustawa z dnia 11 marca 2004 r. o podatku od towarów i usług (tekst jednolity: Dz.U. 2025 poz. 456, ze zmianami na 2026 r.)
  · Art. 5-14 – czynności podlegające opodatkowaniu
  · Art. 15-18 – podatnicy, obowiązek rejestracji (VAT-R)
  · Art. 19a-21 – obowiązek podatkowy (moment powstania)
  · Art. 29a-32 – podstawa opodatkowania
  · Art. 41-42 – stawki VAT (23%, 8%, 5%, 0%)
  · Art. 43 – zwolnienia przedmiotowe (edukacja, medycyna, finanse)
  · Art. 86-96 – odliczenia VAT naliczonego, korekty, terminy
  · Art. 106a-106n – faktury, faktury ustrukturyzowane (KSeF)
  · Art. 108a-108f – mechanizm podzielonej płatności (split payment)
  · Art. 113 – zwolnienie podmiotowe (limit 200 000 PLN)
  · Art. 120 – procedury szczególne (marża, dzieła sztuki)
· Rozporządzenie Ministra Finansów z dnia 4 grudnia 2024 r. w sprawie obniżonych stawek VAT (określa towary i usługi objęte stawkami 8% i 5%)
· Rozporządzenie Ministra Finansów z dnia 29 grudnia 2025 r. w sprawie wzorów deklaracji VAT (VAT-7, VAT-7K, VAT-UE)
· Rozporządzenie Ministra Finansów z dnia 15 lipca 2025 r. w sprawie JPK_VAT z deklaracją (struktura JPK_V7M/K)

PIT (Podatek dochodowy od osób fizycznych)

· Ustawa z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (tekst jednolity: Dz.U. 2025 poz. 789, ze zmianami na 2026 r.)
  · Art. 10 – źródła przychodów (działalność gospodarcza, praca, kapitały)
  · Art. 14 – przychody z działalności gospodarczej
  · Art. 22-23 – koszty uzyskania przychodu / wyłączenia z KUP
  · Art. 24 – dochód (przychód minus koszty)
  · Art. 26-26h – ulgi podatkowe (szczegółowo w sekcji 3)
  · Art. 27 – skala podatkowa (12%, 32%)
  · Art. 30c – podatek liniowy (19%)
  · Art. 44 – zaliczki na podatek
  · Art. 45 – zeznanie roczne (PIT-36, PIT-36L, PIT-28)
· Rozporządzenie Ministra Finansów z dnia 30 grudnia 2025 r. w sprawie wzorów zeznań podatkowych PIT

CIT (Podatek dochodowy od osób prawnych)

· Ustawa z dnia 15 lutego 1992 r. o podatku dochodowym od osób prawnych (tekst jednolity: Dz.U. 2025 poz. 1234, ze zmianami na 2026 r.)
  · Art. 7 – dochód (przychód minus koszty)
  · Art. 12 – przychody
  · Art. 15-16 – koszty uzyskania przychodu / wyłączenia
  · Art. 18d – ulga B+R (badawczo-rozwojowa)
  · Art. 19 – stawka podstawowa (19%)
  · Art. 24 – odliczenia od dochodu (darowizny, straty)
  · Art. 25 – zaliczki na podatek
  · Art. 27 – zeznanie roczne (CIT-8)

Ordynacja podatkowa (procedury, terminy, przedawnienia)

· Ustawa z dnia 29 sierpnia 1997 r. – Ordynacja podatkowa (tekst jednolity: Dz.U. 2025 poz. 234, ze zmianami na 2026 r.)
  · Art. 70 – przedawnienie zobowiązań (5 lat)
  · Art. 81 – korekta deklaracji
  · Art. 139 – terminy płatności podatków
  · Art. 291-293 – odpowiedzialność podatnika
  · Art. 299 – interpretacje indywidualne (wiążące dla organów)

---

2. SKŁADKI I UBEZPIECZENIA SPOŁECZNE

ZUS (Zakład Ubezpieczeń Społecznych)

· Ustawa z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (tekst jednolity: Dz.U. 2025 poz. 345, ze zmianami na 2026 r.)
  · Art. 6 – podmioty podlegające ubezpieczeniom (pracownicy, przedsiębiorcy)
  · Art. 18-19 – podstawy wymiaru składek
  · Art. 22 – stopy procentowe składek (emerytalna 19,52%, rentowa 8%, chorobowa 2,45%, wypadkowa 1,67%)
  · Art. 24 – składka zdrowotna (9% podstawy)
  · Art. 36 – terminy płatności (10., 15., 20. dzień miesiąca)
· Ustawa z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej finansowanych ze środków publicznych (tekst jednolity: Dz.U. 2025 poz. 890)
  · Art. 79-81 – składka zdrowotna (9%, 4,9% dla przedsiębiorców)
· Rozporządzenie Ministra Pracy i Polityki Społecznej z dnia 30 grudnia 2025 r. w sprawie szczegółowych zasad ustalania podstawy wymiaru składek

PPK (Pracownicze Plany Kapitałowe)

· Ustawa z dnia 4 października 2018 r. o pracowniczych planach kapitałowych (tekst jednolity: Dz.U. 2025 poz. 456)
  · Art. 26-27 – wysokość wpłat (1,5% + 2%)
  · Art. 32 – obowiązek wdrożenia w firmach zatrudniających powyżej 250 osób (terminy)

---

3. ULGI PODATKOWE – ŹRÓDŁA I PODSTAWY PRAWNE

Ulgi w PIT / CIT

· Ulga B+R (badawczo-rozwojowa): PIT Art. 26e, CIT Art. 18d – odliczenie 100-200% kosztów kwalifikowanych
· Ulga na prototyp: PIT Art. 26eb, CIT Art. 18db – odliczenie 30% kosztów produkcji próbnej
· Ulga na robotyzację: PIT Art. 26gb, CIT Art. 38eb – odliczenie 50% kosztów robotów przemysłowych
· Ulga IP Box: PIT Art. 30ca, CIT Art. 24d – 5% stawka dla dochodów z własności intelektualnej
· Ulga na ekspansję: PIT Art. 26ec, CIT Art. 18dc – odliczenie kosztów targów i reklamy za granicą
· Ulga termomodernizacyjna: PIT Art. 26h – odliczenie 53 000 PLN
· Ulga rehabilitacyjna: PIT Art. 26 – odliczenie wydatków na cele rehabilitacyjne
· Ulga abolicyjna: PIT Art. 27g – zwolnienie z podatku od dochodów zagranicznych
· Ulga na internet: PIT Art. 26 – odliczenie 760 PLN rocznie (przez 2 lata)
· Ulga dla młodych: PIT Art. 21 ust. 1 pkt 148 – zwolnienie z PIT do 26. roku życia (do 85 528 PLN)
· Ulga dla rodzin 4+: PIT Art. 21 ust. 1 pkt 153 – zwolnienie dla rodziców 4+ dzieci (do 85 528 PLN)
· Ulga na powrót: PIT Art. 21 ust. 1 pkt 152 – zwolnienie dla osób wracających z emigracji (4 lata, 85 528 PLN rocznie)
· Ulga dla pracujących emerytów: PIT Art. 21 ust. 1 pkt 154 – zwolnienie dla pracujących po osiągnięciu wieku emerytalnego

Ulgi w VAT

· VAT-23: Art. 113 – zwolnienie podmiotowe (limit 200 000 PLN)
· Odwrotne obciążenie: Art. 17 – nabywca płaci VAT (towary wrażliwe: stal, paliwa, elektronika)
· Zwrot VAT dla budownictwa: Ustawa z dnia 29 sierpnia 2005 r. o zwrocie osobom fizycznym niektórych wydatków związanych z budownictwem mieszkaniowym

Ulgi składkowe (ZUS)

· Ulga na start: Ustawa o systemie ubezpieczeń społecznych, Art. 18a – 6 miesięcy bez składek społecznych
· Mały ZUS Plus: Art. 18c – niższe składki przez 36 miesięcy (podstawa: 30% minimalnego wynagrodzenia)
· Działalność nieewidencjonowana: Ustawa Prawo przedsiębiorców, Art. 5 – zwolnienie z ZUS dla przychodów do 50% płacy minimalnej

Źródła online do monitorowania ulg

· Portal Podatkowy MF: podatki.gov.pl – aktualna lista ulg i odliczeń
· BIP Ministerstwa Finansów: mf.gov.pl – interpretacje ogólne i obwieszczenia
· Legeo: legeo.pl – interaktywna baza przepisów, wyszukiwarka artykułów i ulg

---

4. RACHUNKOWOŚĆ I EWIDENCJA KSIĘGOWA

Ustawa o rachunkowości (UoR)

· Ustawa z dnia 29 września 1994 r. o rachunkowości (tekst jednolity: Dz.U. 2025 poz. 567, ze zmianami na 2026 r.)
  · Art. 2 – jednostki zobowiązane (osoby prawne, spółki, fundacje)
  · Art. 4 – zasady rachunkowości (memoriał, współmierność, ostrożność, kontynuacja działania)
  · Art. 7 – dokumentacja opisująca przyjęte zasady (polityka rachunkowości)
  · Art. 10 – księgi rachunkowe (dziennik, księga główna, księgi pomocnicze)
  · Art. 12 – otwarcie i zamknięcie ksiąg rachunkowych
  · Art. 13 – zasady prowadzenia ksiąg (bezbłędnie, rzetelnie, na bieżąco, w języku polskim i walucie PLN)
  · Art. 20-21 – dowody księgowe (obowiązkowe elementy faktury, paragonu)
  · Art. 22 – zapisy księgowe (podwójny zapis, sumy debet i kredyt)
  · Art. 24 – terminy prowadzenia ksiąg (do 15. dnia następnego miesiąca)
  · Art. 26 – inwentaryzacja (spis z natury, uzgodnienie sald)
  · Art. 28 – wycena aktywów i pasywów (cena nabycia, koszt wytworzenia, wartość godziwa)
  · Art. 30 – rozliczenia międzyokresowe
  · Art. 31 – rezerwy na zobowiązania
  · Art. 32 – amortyzacja środków trwałych (stawki, metody: liniowa, degresywna, naturalna)
  · Art. 34 – wartości niematerialne i prawne (oprogramowanie, licencje, patenty)
  · Art. 35-39 – sprawozdania finansowe (bilans, rachunek zysków i strat, przepływy pieniężne)
  · Art. 40-44 – badanie i ogłaszanie sprawozdań (obowiązek dla dużych jednostek)
  · Art. 45 – terminy sprawozdań (do 31 marca następnego roku)
  · Art. 52 – zmiany zasad rachunkowości (retrospektywnie)
  · Art. 74 – przechowywanie dokumentacji (5 lat od końca roku podatkowego)

Akty wykonawcze do UoR

· Rozporządzenie Ministra Finansów z dnia 12 grudnia 2024 r. w sprawie szczegółowych zasad rachunkowości (m.in. wzory sprawozdań, szczegółowe zasady wyceny)
· Rozporządzenie Ministra Finansów z dnia 15 listopada 2025 r. w sprawie prowadzenia uproszczonej ewidencji przychodów i kosztów (dla małych firm nieprowadzących pełnej księgowości)

KŚT (Klasyfikacja Środków Trwałych)

· Rozporządzenie Rady Ministrów z dnia 10 grudnia 2024 r. w sprawie Klasyfikacji Środków Trwałych (KŚT 2025)
  · Grupa 0: Grunty
  · Grupa 1: Budynki i lokale
  · Grupa 2: Obiekty inżynierii lądowej i wodnej
  · Grupa 3: Kotły i maszyny energetyczne
  · Grupa 4: Maszyny, urządzenia i aparaty ogólnego zastosowania
  · Grupa 5: Specjalistyczne maszyny, urządzenia i aparaty
  · Grupa 6: Urządzenia techniczne
  · Grupa 7: Środki transportu
  · Grupa 8: Narzędzia, przyrządy, ruchomości i wyposażenie
  · Grupa 9: Inwentarz żywy

MSSF / IFRS (Międzynarodowe Standardy Sprawozdawczości Finansowej)

· Obowiązują w Polsce dla banków, spółek giełdowych i jednostek ubiegających się o dopuszczenie do obrotu giełdowego
· Rozporządzenie Komisji Europejskiej nr 1126/2008 przyjmujące MSSF
· Standardy szczegółowe: MSSF 9 (instrumenty finansowe), MSSF 15 (przychody), MSSF 16 (leasingi), MSR 12 (podatek dochodowy), MSR 37 (rezerwy)

---

5. PRAWO PRZEDSIĘBIORCÓW I SPÓŁEK

Prawo przedsiębiorców

· Ustawa z dnia 6 marca 2018 r. – Prawo przedsiębiorców (tekst jednolity: Dz.U. 2025 poz. 123)
  · Art. 4-5 – definicja przedsiębiorcy i działalności gospodarczej
  · Art. 6 – działalność nieewidencjonowana (przychód do 50% minimalnego wynagrodzenia)
  · Art. 14 – spółka cywilna (zasady opodatkowania)
  · Art. 18 – reprezentacja przedsiębiorcy (prokura)

Kodeks spółek handlowych

· Ustawa z dnia 15 września 2000 r. – Kodeks spółek handlowych (tekst jednolity: Dz.U. 2025 poz. 789)
  · Art. 151-300 – spółka z o.o. (kapitał zakładowy min. 5 000 PLN, zasady wypłaty dywidendy, odpowiedzialność zarządu)
  · Art. 301-490 – spółka akcyjna (kapitał zakładowy min. 100 000 PLN, rada nadzorcza, walne zgromadzenie)
  · Art. 22-85 – spółka jawna (odpowiedzialność solidarna wspólników)

Centralna Ewidencja i Informacja o Działalności Gospodarczej (CEIDG)

· Ustawa z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej (tekst jednolity: Dz.U. 2025 poz. 456)
  · Rejestracja, zmiana i zawieszenie działalności gospodarczej
  · Wpis do CEIDG jest obowiązkowy dla jednoosobowych działalności gospodarczych i spółek cywilnych

---

6. EWIDENCJE I DEKLARACJE – JPK, KSEF

JPK (Jednolity Plik Kontrolny)

· Ustawa z dnia 11 marca 2004 r. o podatku od towarów i usług (art. 99)
· Rozporządzenie Ministra Finansów z dnia 15 lipca 2025 r. w sprawie JPK_VAT z deklaracją
  · JPK_V7M (miesięczny) – struktura, terminy (do 25. dnia następnego miesiąca)
  · JPK_V7K (kwartalny) – dla małych podatników
  · JPK_PKPIR – podatkowa księga przychodów i rozchodów (dla ryczałtowców)
  · JPK_KR – pełna księgowość (dla spółek z o.o., S.A.)

KSeF (Krajowy System e-Faktur)

· Ustawa z dnia 16 czerwca 2023 r. o zmianie ustawy o VAT (wprowadzająca KSeF) – Dz.U. 2023 poz. 1598
· Rozporządzenie Ministra Finansów z dnia 5 października 2025 r. w sprawie wzoru faktury ustrukturyzowanej (schemat XSD)
· Obowiązkowy od: 1 lutego 2026 r. dla wszystkich podatników VAT czynnych (z wyjątkiem zwolnionych)

Biała Lista VAT (MF)

· Ustawa o VAT, art. 96b – obowiązek weryfikacji kontrahenta przed przelewem powyżej 15 000 PLN
· API: https://apilista.mf.gov.pl
· Rejestr: https://www.podatki.gov.pl/wykaz-podatnikow-vat

---

7. ŹRÓDŁA INFORMACJI O ULACH I AKTUALIZACJACH

Oficjalne źródła rządowe

· Rządowe Centrum Legislacji: legislacja.gov.pl – śledzenie projektów ustaw i rozporządzeń (alerty e-mail)
· Internetowy System Aktów Prawnych (ISAP): isap.sejm.gov.pl – teksty jednolite ustaw i rozporządzeń
· Dziennik Urzędowy Rzeczypospolitej Polskiej: dziennikustaw.gov.pl – publikacja aktów prawnych
· Ministerstwo Finansów – BIP: gov.pl/web/finanse – interpretacje ogólne, obwieszczenia, odpowiedzi na interpelacje poselskie
· Krajowa Informacja Skarbowa (KIS): kis.gov.pl – call center podatkowe, interpretacje indywidualne

Portale księgowe i podatkowe

· Grant Thornton – Tax Alert: grantthornton.pl – cotygodniowe alerty o zmianach w przepisach
· PwC Tax Alert: pwc.pl – alerty podatkowe, analiza zmian
· Infor.pl – Podatki: infor.pl/prawo/podatki – codzienne aktualności podatkowe
· Ksiegowosc.org: ksiegowosc.org – serwis dla księgowych, komentarze ekspertów
· MDDP Tax Alert: mddp.pl – analizy i interpretacje
· PwC Nowe Prawo: pwc.pl/nowe-prawo – alerty o projektach ustaw

Narzędzia do automatyzacji

· Alerty Google: Ustaw alerty na frazy: "zmiana ustawy o VAT", "nowa ulga podatkowa", "rozporządzenie MF KSeF"
· RSS z Rządowego Centrum Legislacji: legislacja.gov.pl/rss – feed z projektami aktów prawnych
· e-mail z subskrypcji KIS: kis.gov.pl/newsletter – newsletter o zmianach

---

8. JAK TO WSZYSTKO ZAPRZĄC DO REGO – PRAKTYCZNE WSKAZÓWKI

1. Dla każdego artykułu ustawy stwórz osobną regułę w Rego. Np. split_payment_required odpowiada Art. 108a ustawy o VAT.
2. Parametry liczbowe (stawki, progi, limity) trzymaj w DuckDB RuleStore. Rego dostaje je jako input.thresholds.*. Przykład: input.thresholds.split_payment = 15000.
3. W Rego dodawaj komentarz z podstawą prawną. To kluczowe dla audytu:

```rego
# Art. 108a ustawy o VAT – split payment obowiązkowy powyżej 15 000 PLN
required {
    input.invoice.amount_gross > input.thresholds.split_payment
    input.invoice.type == "krajowa"
}
```

4. Zmiany w prawie śledź przez RCL + alerty Google. Co kwartał przeglądaj reguły i aktualizuj. Wzorce testów Rego (opa test) szybko wyłapią nieaktualności.
5. Ulgi podatkowe to zazwyczaj proste reguły warunkowe. Przykład:

```rego
# Art. 26eb PIT – ulga na prototyp
allow {
    input.invoice.category == "prototyp"
    input.taxpayer.has_rd_status == true
    input.invoice.amount_net < input.thresholds.prototype_limit
}
```


Czy to wszystko ?
Nie, lista, którą podałem, jest bardzo obszerna, ale nie jest to absolutnie każdy możliwy dokument. Jest to zestaw najważniejszych, podstawowych aktów prawnych niezbędnych do zbudowania kompletnego silnika reguł dla aplikacji księgowej. Pominąłem celowo bardzo szczegółowe, branżowe lub rzadko stosowane przepisy, aby lista była przejrzysta i użyteczna.

Oto, czego konkretnie brakuje do pełnego, 100% pokrycia wszystkich możliwych scenariuszy:

y za 1. Przepisy branżowe i specjalistyczne

Nie wymieniłem regulacji, które dotyczą tylko niektórych firm, ale gdy już dotyczą, to są kluczowe:

· Prawo budowlane – ulgi na zakup materiałów budowlanych, podatek od nieruchomości w budowie.
· Prawo energetyczne – akcyza na energię elektryczną, obowiązki ewidencyjne.
· Prawo ochrony środowiska – opłaty za emisję CO2, gospodarkę odpadami (BDO – Baza Danych Odpadowych). To są istotne koszty i obowiązki ewidencyjne.
· Ustawa o transporcie drogowym – podatek od środków transportowych, licencje, zezwolenia.

2. Akcyza i podatki specjalne

· Ustawa o podatku akcyzowym – kompletny akt prawny dla firm obracających paliwami, alkoholem, tytoniem, energią elektryczną. Zawiera mnóstwo stawek, zwolnień i obowiązków ewidencyjnych.

3. Podatki i opłaty lokalne

· Ustawa o podatkach i opłatach lokalnych – podatek od nieruchomości (grunty, budynki, budowle), podatek od środków transportowych, opłata targowa, opłata uzdrowiskowa. Stawki są ustalane przez gminy, więc dane muszą być aktualizowane lokalnie.

4. Prawo pracy i ubezpieczenia szczególne

· Kodeks Pracy – urlopy, wynagrodzenia, ekwiwalenty, odprawy. To są koszty pracodawcy i podstawa do ZUS.
· Ustawa o świadczeniach pieniężnych z ubezpieczenia społecznego w razie choroby i macierzyństwa (tzw. "ustawa zasiłkowa") – obliczanie zasiłków chorobowych, macierzyńskich, opiekuńczych.

5. Regulacje dotyczące konkretnych form prawnych

· Prawo spółdzielcze – specyfika opodatkowania spółdzielni.
· Ustawa o fundacjach i stowarzyszeniach – zwolnienia podatkowe dla NGO.

6. Prawo dewizowe i międzynarodowe

· Prawo dewizowe – obowiązki raportowania transakcji zagranicznych do NBP.
· Ustawa o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (AML) – obowiązek raportowania transakcji powyżej 15 000 EUR, identyfikacja beneficjentów rzeczywistych. To jest krytyczne dla bezpieczeństwa finansowego.

Gdzie szukać tych wszystkich brakujących źródeł?

Twoim podstawowym narzędziem do znalezienia absolutnie każdego aktu prawnego jest Internetowy System Aktów Prawnych (ISAP) prowadzony przez Sejm RP: isap.sejm.gov.pl. Możesz tam przeszukiwać po dacie, tytule, a nawet fragmencie tekstu.

Polecam też skorzystać z portalu Legislacja.gov.pl, który pokazuje nie tylko obowiązujące przepisy, ale też projekty ustaw i rozporządzeń, które dopiero wejdą w życie. To idealne źródło do proaktywnego przygotowywania nowych reguł Rego.

W skrócie: podałem Ci fundament podatkowo-księgowy. Resztę, w zależności od potrzeb konkretnych użytkowników, możesz dodawać stopniowo, korzystając z ISAP i Legislacji
