# 🧠 NexusAI JDG — Strategiczne Ulepszenia, Optymalizacje i Przełomowe Pomysły v2.0

> **Status:** ✅ **9/9 WDROŻONYCH** (7 production-ready + 2 stub/PoC) — 2026-07-12  
> **Data:** 2026-07-12  
> **Autor:** Zespół NexusAI — Chief Architect Review v2  
> **Plik:** `Plan OPA/48_JDG_STRATEGIC_IMPROVEMENTS_V2.md`  
> **Podsumowanie wdrożenia:** `Plan OPA/49_JDG_IMPLEMENTATION_SUMMARY.md`  
> **Uwaga:** Ten dokument zawiera 9 **całkowicie nowych** inicjatyw, niepowielających `29_JDG_STRATEGIC_IMPROVEMENTS.md` (v1.0).  
> **Bazuje na:** Audyt jakościowy (46), Mapa kanoniczna (38c), Docs 22-25, implementacje Rego w `policies/jdg/`  
> **Inicjatywy v1.0 (już wdrożone):** Doc-as-Code METADATA, Temporal Bundle Routing, Semantic Conflict Resolution, Dynamic DAG Pruning, Decoupled Thresholds, Boundary Fuzz Testing, What-If Tax Arbitrage, Temporal Action Queue, Zero-Day Legal Delta AI  
>  
> ### 📦 STATUS WDROŻENIA v2.0 (2026-07-12)  
>  
> | # | Inicjatywa | Moduł Python | Testy | Status |  
> |---|-----------|-------------|:-----:|:------:|  
> | A1 | Immutable Audit Trail | `nexus_ai/tax/immutable_audit.py` | 3/3 | ✅ |  
> | A2 | Rego AST Linter | `nexus_ai/tax/rego_linter.py` | 3/3 | ✅ |  
> | A3 | Legal Explainer | `nexus_ai/tax/legal_explainer.py` | 3/3 | ✅ |  
> | B1 | DuckDB WASM OPA PoC | `nexus_ai/tax/opa_wasm_poc.py` | 1/1 | ✅ Stub |  
> | B2 | Orthogonal Array Testing | `nexus_ai/tax/orthogonal_array_tester.py` | 3/3 | ✅ |  
> | B3 | Telemetry Fail-Fast | `nexus_ai/tax/dynamic_dag.py` | 2/2 | ✅ |  
> | C1 | Federated KUP Benchmark | `nexus_ai/tax/federated_kup_benchmark.py` | 3/3 | ✅ Stub |  
> | C2 | Tax Ruling Drafter | `nexus_ai/tax/tax_ruling_drafter.py` | 2/2 | ✅ |  
> | C3 | Liquidity Oracle | `nexus_ai/tax/liquidity_oracle.py` | 3/3 | ✅ |  
>  
> **Łącznie: 23/23 testów ✅ | 8 nowych modułów + 1 rozszerzenie = 9 zmian w kodzie**  

---

## 📊 INDEKS NOWYCH INICJATYW

| # | Inicjatywa | Typ | Kluczowa innowacja |
|---|-----------|:---:|---------------------|
| **A1** | Kryptograficzne poświadczenie ścieżki ewaluacji | Ulepszenie | Merkle Tree + ECDSA — niepodważalny audyt |
| **A2** | Biznesowo-podatkowy Linter Rego AST | Ulepszenie | Automatyczne blokowanie `hardcoded values` w CI/CD |
| **A3** | Deterministyczny Generator Uzasadnień | Ulepszenie | JSON trace → czytelna nota podatkowa po polsku |
| **B1** | Ewaluacja OPA wewnątrz DuckDB (WASM) | Optymalizacja | 10-50× szybsze batch processing |
| **B2** | Macierzowe Testy Kombinatoryczne | Optymalizacja | 10 000 kombinacji cross-pass zamiast ręcznych testów |
| **B3** | Profilowanie Telemetryczne DAG + Fail-Fast | Optymalizacja | -30% CPU przez dynamiczne priorytetyzowanie reguł |
| **C1** | Sfederowany Benchmarking Anomalii KUP | Przełom | AI wykrywająca podejrzane wydatki na podstawie benchmarku branżowego |
| **C2** | Autonomiczny Generator Wniosków KIS/WIS | Przełom | AI draftuje interpretację podatkową gdy reguły nie dają odpowiedzi |
| **C3** | Wyrocznia Płynności — Symulacje Kasowe | Przełom | AI rekomenduje metodę kasową na podstawie historii opóźnień płatności |

---

## 📊 ETAP 1: GŁĘBOKA ANALIZA SYSTEMU — STAN NA LIPIEC 2026

### 1.1 Dojrzałość systemu po wdrożeniu inicjatyw v1.0

System NexusAI JDG przeszedł transformację z planu (~214 reguł) przez rozbudowę (Doc 28a, 42, 43) do **~800 reguł kanonicznych**. Wdrożono 9 inicjatyw strategicznych v1.0:

| Inicjatywa v1.0 | Status | Wpływ |
|---|---|:---:|
| Doc-as-Code METADATA | ✅ 32/32 plików | Eliminacja entropii dokumentacyjnej |
| Temporal Bundle Routing | ✅ `bundles/` | Historyczne wersje reguł |
| Semantic Conflict Resolution | ✅ 5 reguł konfliktów | Wykrywanie kolizji międzydomenowych |
| Dynamic DAG Pruning | ✅ `dynamic_dag.py` | -40-60% passów na prostych transakcjach |
| Decoupled Thresholds | ✅ 5 plików .rego | -85% rozmiar payloadu API |
| Boundary Fuzz Testing | ✅ 175 testów / 25 progów | Pokrycie wartości granicznych |
| What-If Tax Arbitrage | ✅ `what_if_arbitrage.py` | System doradczy (nie tylko compliance) |
| Temporal Action Queue | ✅ 7 zdarzeń, 4 pakiety | Przyszłe korekty i przypomnienia |
| Zero-Day Legal Delta AI | ✅ `legal_delta_agent.py` | Automatyczne śledzenie zmian prawa |

### 1.2 Co NADAL wymaga poprawy — Zidentyfikowane słabości

> ⚠️ Źródło: Audyt jakościowy `46_JDG_QUALITY_AUDIT.md`, Sekcja 4 (Luki globalne).

| Obszar | Problem | Dotkliwość |
|--------|---------|:----------:|
| **Audyt zewnętrzny** | Werdykty OPA nie są kryptograficznie poświadczone — biegły rewident może zakwestionować decyzję | 🔴 KRYTYCZNA |
| **Nawrót długu technicznego** | 16% reguł ma zakodowane wartości (46, §4.3) — bez automatycznego lintera problem będzie narastał przy nowych regułach | 🔴 KRYTYCZNA |
| **Czytelność decyzji** | OPA zwraca surowy JSON — JDG nie rozumie DLACZEGO faktura została zablokowana (46, §4.1: 98% reguł bez przykładów) | 🟡 WAŻNA |
| **Wydajność batch** | 9 wywołań REST API OPA na fakturę — przy >100k faktur/miesiąc to bottleneck | 🟡 WAŻNA |
| **Testy cross-pass** | Brak testowania interakcji między domenami (VAT+ZUS+PIT+Crossborder jednocześnie) — 46, §4.2: 93% reguł bez scenariuszy brzegowych | 🟡 WAŻNA |
| **Statyczne ryzyko** | Reguły fraudu (P0-P9) są statyczne — nie uczą się na danych z rynku | 🟢 ŚREDNIA |
| **Luki prawne** | Gdy reguła nie pasuje → TRIAGE_QUEUE — ale nikt nie składa interpretacji do KIS (46, §4.5: 47 reguł zdeprecjonowanych, niejasna hierarchia) | 🟢 ŚREDNIA |
| **Płynność JDG** | System sprawdza zgodność, ale nie optymalizuje cash-flow przedsiębiorcy | 🟢 ŚREDNIA |

---

## 🎯 ETAP 2: KREATYWNE MYŚLENIE — 9 INICJATYW v2.0

---

## CZĘŚĆ A: 3 GENIALNE ULEPSZENIA (Jakość, Bezpieczeństwo, Zaufanie)

---

### A1. Kryptograficzne Poświadczenie Ścieżki Ewaluacji (Immutable Audit Trail)

#### Na czym polega

Obecnie OPA zwraca werdykt JSON, który jest zapisywany w DuckDB. Podczas kontroli skarbowej urząd może zakwestionować: "skąd wiemy, że system użył aktualnych reguł, a nie wadliwej wersji?" — bo werdykt nie jest kryptograficznie związany z wersją reguł, które go wygenerowały.

**Rozwiązanie:** Dla każdego werdyktu generujemy **Merkle Tree** z trzech komponentów:
1. **Hash dokumentu wejściowego** (`input.invoice` + `input.jdg_entrepreneur`) — SHA-256
2. **Hash bundle'a OPA** (identyfikator wersji + hash zawartości `.rego`) — `opa build --revision` 
3. **Hash stanu thresholdów** (DuckDB `jdg_thresholds` z `valid_from`/`valid_to`) — hash całej tabeli dla danego dnia

```python
class ImmutableVerdictSigner:
    def sign_verdict(self, verdict: dict, input_hash: str, 
                     bundle_hash: str, thresholds_hash: str) -> SignedVerdict:
        # 1. Zbuduj liście drzewa Merkle
        leaf1 = sha256(input_hash)
        leaf2 = sha256(bundle_hash)  
        leaf3 = sha256(thresholds_hash)
        
        # 2. Korzeń Merkle = hash(hash(L1+L2) + L3)
        root = sha256(sha256(leaf1 + leaf2) + leaf3)
        
        # 3. Podpisz korzeń kluczem ECDSA systemu
        signature = ecdsa_sign(private_key, root)
        
        return SignedVerdict(
            verdict=verdict,
            merkle_root=root,
            signature=signature,
            bundle_version=bundle_hash[:8],
            thresholds_snapshot=thresholds_hash[:8],
            signed_at=datetime.now(),
            certificate_fingerprint=cert_fingerprint
        )

# Weryfikacja przez audytora zewnętrznego (np. biegłego rewidenta):
def verify_verdict(signed: SignedVerdict) -> bool:
    # 1. Odtwórz Merkle root z oryginalnych danych
    recomputed_root = compute_merkle_root(
        input_hash, bundle_hash, thresholds_hash
    )
    # 2. Zweryfikuj podpis ECDSA
    return ecdsa_verify(public_key, recomputed_root, signed.signature)
```

#### Dlaczego to jest genialne

1. **Niepodważalność w sądzie** — biegły rewident nie może zakwestionować decyzji, bo jest ona matematycznie związana z wersją reguł i progów obowiązujących w dniu transakcji.
2. **Łańcuch zaufania** — każdy werdykt jest powiązany z konkretną wersją bundle'a OPA. Przy aktualizacji reguł stare werdykty pozostają weryfikowalne.
3. **Ochrona przed manipulacją** — jakakolwiek zmiana w `input`, `bundle` lub `thresholds` po podpisaniu spowoduje niezgodność hasha — wykrywalne natychmiast.
4. **Zgodność z eIDAS** — podpis ECDSA z kwalifikowanym certyfikatem spełnia wymogi unijnego rozporządzenia o podpisach elektronicznych.

#### Wpływ na bezpieczeństwo / zgodność / zaufanie

- **Bezpieczeństwo:** Eliminacja ryzyka "ktoś zmienił werdykt po fakcie"
- **Zgodność:** Spełnienie wymogów art. 74 UoR (rzetelność dokumentacji) i art. 86 § 1 OrdPU (ciężar dowodu)
- **Zaufanie:** JDG może przedstawić niepodważalny dowód w sporze z US

#### Wykonalność

**WYSOKA.** Komponenty:
- `hashlib` (SHA-256) — biblioteka standardowa Pythona
- `ecdsa` lub `cryptography` — podpis ECDSA, standardowe biblioteki
- DuckDB — przechowywanie hashy obok werdyktów (1 dodatkowa kolumna)
- OPA `bundle revision` — już dostępne

#### Przykład koncepcyjny

```
Faktura FV/2026/06/001 z 15.06.2026:
  → input_hash: a3f2b8c1...
  → bundle_hash (jdg_v2026.3): 7d9e1f0a...
  → thresholds_hash (stan na 15.06): c4b6a8d2...
  → Merkle root: 5e8f3a1b...
  → Podpis ECDSA: 3045022100a1b2c3...
  
W przypadku kontroli skarbowej w 2029:
  1. Biegły rewident otrzymuje werdykt + podpis
  2. Odtwarza Merkle root z oryginalnego input + bundle z archiwum + thresholds z DuckDB time-travel
  3. Weryfikacja podpisu → pozytywna
  4. Wniosek: decyzja podjęta zgodnie z regułami obowiązującymi 15.06.2026 ✓
```

---

### A2. Biznesowo-Podatkowy Linter Rego AST (Hardcoded Value Blocker)

#### Na czym polega

Problem zakodowanych wartości (16% reguł) został zidentyfikowany w audycie 46, ale **naprawienie go ręcznie nie zapobiegnie nawrotowi** — deweloperzy będą popełniać ten sam błąd w nowych regułach.

**Rozwiązanie:** Budujemy dedykowany linter, który parsuje drzewo składniowe Rego (Abstract Syntax Tree) i wykrywa "magiczne liczby" — wartości liczbowe, stringi przypominające daty/kwoty, listy kategorii — które nie są pobierane z `data.thresholds.*`. Linter jest zintegrowany z pipeline CI/CD i **blokuje PR** przed mergem.

```python
class RegoHardcodedValueLinter:
    """Parsuje AST Reguł Rego i wykrywa zakodowane wartości."""
    
    FORBIDDEN_PATTERNS = [
        # 1. Liczby całkowite przypominające progi (≥ 1000)
        r'\b\d{4,}\b',
        # 2. Kwoty z groszami
        r'\b\d+\.\d{2}\b',
        # 3. Daty (YYYY-MM-DD)
        r'\b20\d{2}-[01]\d-[0-3]\d\b',
        # 4. Procenty jako string ("0.23")
        r'"0\.\d{2,4}"',
        # 5. Listy stringów (zakodowane kategorie)
        r'\["[^"]+"(?:,\s*"[^"]+")*\]',
    ]
    
    ALLOWED_CONTEXTS = [
        # Dozwolone: w definicji zmiennej z data.thresholds
        r'data\.thresholds\.\w+(?:\.\w+)*',
        # Dozwolone: w komentarzach
        r'#.*',
        # Dozwolone: testy jednostkowe
        r'test_',
    ]
    
    def lint_file(self, rego_file: str) -> list[LintViolation]:
        """Zwraca listę naruszeń w pliku .rego."""
        ast = self.parse_rego_ast(rego_file)
        violations = []
        
        for node in self.walk_ast(ast):
            for pattern in self.FORBIDDEN_PATTERNS:
                if self.matches(node, pattern):
                    # Sprawdź czy wartość jest w dozwolonym kontekście
                    if not self.is_in_allowed_context(node):
                        violations.append(LintViolation(
                            file=rego_file,
                            line=node.line,
                            value=node.value,
                            suggestion=f"Zamień na data.thresholds.jdg.*",
                            severity="ERROR"  # ERROR = blokuje CI/CD
                        ))
        
        return violations

# Pipeline CI/CD:
# $ opa check --strict policies/jdg/*.rego     # Poprawność składni
# $ python -m tax_linter policies/jdg/*.rego   # Detekcja hardcoded values
# → Jeśli linter zwróci ERROR → CI FAILS → PR zablokowany
```

#### Dlaczego to jest genialne

1. **Zapobieganie, nie leczenie** — problem zakodowanych wartości NIGDY nie wróci, bo każdy nowy PR jest automatycznie sprawdzany.
2. **Natywne dla ekosystemu Rego** — linter rozumie składnię Rego (wie, że `# komentarz` jest OK, ale `amount > 150000` w regule nie).
3. **Edukacja deweloperów** — linter nie tylko blokuje, ale sugeruje poprawne `data.thresholds.*` — deweloper uczy się poprawnej konwencji.
4. **Rozszerzalność** — nowe wzorce zakazanych wartości można dodawać deklaratywnie.

#### Wpływ na bezpieczeństwo / zgodność / zaufanie

- **Bezpieczeństwo:** Automatyczne wymuszenie polityki "Zero Hardcoded Values" — fizycznie niemożliwe do złamania
- **Zgodność:** Każda wartość krytyczna (stawka VAT, limit, próg) ma ślad w DuckDB z `valid_from`/`valid_to`
- **Zaufanie:** Deweloperzy nie mogą przypadkiem wprowadzić błędnych wartości

#### Wykonalność

**WYSOKA.** Komponenty:
- Parser AST Rego — `opa parse --format json` zwraca strukturalne drzewo składniowe
- Python `json` — parsowanie wyjścia OPA
- Walidacja regex — biblioteka standardowa
- Integracja CI/CD — GitHub Actions / GitLab CI, standardowe narzędzie

#### Przykład koncepcyjny

```
PR #142: Nowa reguła P999 dla limitu kwoty wolnej od zajęcia

Plik: policies/jdg/business.rego
  Line 47: allowance > 50000    ← LINTER: ERROR — zakodowana wartość 50000
  Sugestia: Zamień na data.thresholds.jdg.bounds.seizure_free_amount
  
  Line 52: if date > "2026-01-01"  ← LINTER: ERROR — zakodowana data
  Sugestia: Zamień na data.thresholds.jdg.dates.ksef_mandatory_date

CI/CD: ❌ FAILED — 2 hardcoded value violations
PR zostaje zablokowany do czasu poprawy ✓
```

---

### A3. Deterministyczny Generator Uzasadnień Podatkowych (Legal Explainer)

#### Na czym polega

OPA zwraca JSON-a: `{"vat_rate": "0.23", "kus_qualification": "none", "rule_id": "jdg.compliance.cash_limit"}`. Przedsiębiorca JDG widzi tylko "faktura zablokowana", ale nie rozumie **dlaczego**. Musi dzwonić do księgowego.

**Rozwiązanie:** Komponent "Legal Explainer" bierze ślad ewaluacji OPA (`--explain full`), parsuje drzewo decyzyjne, ekstrahuje `rule_id` i `legal_basis` z `# METADATA`, a następnie generuje **czytelną notę podatkową w języku polskim**, która wyjaśnia:
1. Która reguła zadziałała
2. Dlaczego (które przesłanki zostały spełnione)
3. Jaka jest podstawa prawna
4. Co przedsiębiorca może zrobić (jeśli reguła jest blokująca)

```python
class LegalExplainerEngine:
    """Generuje czytelne uzasadnienie decyzji OPA."""
    
    TEMPLATES = {
        "BLOCKED": (
            "📋 **Faktura {invoice_number} została zablokowana**\n\n"
            "**Powód:** {rule_description}\n"
            "**Podstawa prawna:** {legal_basis}\n"
            "**Co zrobić:** {remediation}\n"
        ),
        "WARNING": (
            "⚠️ **Ostrzeżenie dla faktury {invoice_number}**\n\n"
            "**Uwaga:** {rule_description}\n"
            "**Ryzyko:** {risk_description}\n"
            "**Podstawa prawna:** {legal_basis}\n"
        ),
        "OK": (
            "✅ **Faktura {invoice_number} — księgowanie standardowe**\n\n"
            "VAT: {vat_rate} | KUP: {kus_qualification} | ZUS: {zus_rate}\n"
        ),
    }
    
    def explain(self, verdict: dict, opa_trace: dict) -> str:
        rule_id = verdict["rule_id"]
        metadata = self.load_metadata(rule_id)  # Z # METADATA w .rego
        
        if verdict.get("_routing") == "BLOCK_AND_ALERT":
            template = self.TEMPLATES["BLOCKED"]
            return template.format(
                invoice_number=verdict["invoice_number"],
                rule_description=metadata["description"],
                legal_basis=metadata["legal_basis"],
                remediation=metadata.get("remediation", 
                    "Skontaktuj się z księgowym")
            )
        elif verdict.get("_warnings"):
            template = self.TEMPLATES["WARNING"]
            # ...
        
        return template

# Przykład użycia:
explainer = LegalExplainerEngine()
trace = opa_client.evaluate(input_data, explain="full")
verdict = trace["result"][0]
explanation = explainer.explain(verdict, trace)
# → Czytelny tekst po polsku, gotowy do wyświetlenia w UI
```

#### Dlaczego to jest genialne

1. **Eliminacja "czarnej skrzynki"** — przedsiębiorca rozumie DLACZEGO system podjął taką decyzję, bez konsultacji z księgowym.
2. **Zgodność z RODO** — art. 22 ust. 3 RODO wymaga prawa do uzyskania wyjaśnienia decyzji opartej na zautomatyzowanym przetwarzaniu. Explainer spełnia ten wymóg.
3. **Redukcja obciążenia supportu** — 80% zapytań "dlaczego faktura jest czerwona?" rozwiązuje się automatycznie.
4. **Edukacja JDG** — przedsiębiorca uczy się prawa podatkowego przez interakcję z systemem.

#### Wpływ na bezpieczeństwo / zgodność / zaufanie

- **Bezpieczeństwo:** Transparentność decyzji — brak "ukrytych" blokad
- **Zgodność:** RODO art. 22 ust. 3 (prawo do wyjaśnienia), art. 13-14 (prawo do informacji)
- **Zaufanie:** JDG ufa systemowi, bo rozumie jego decyzje

#### Wykonalność

**ŚREDNIA.** ⚠️ Ryzyko: OPA `--explain full` zwraca szczegółowy, wewnętrzny format śladu, który **może zmieniać się między wersjami OPA**. Należy dodać testy regresyjne dla parsera trace'a przy każdej aktualizacji OPA i rozważyć własny format trace'a (np. akumulowanie `rule_id` w werdykcie zamiast parsowania `--explain`).

Komponenty:
- OPA `--explain full` — zwraca pełne drzewo decyzyjne (dostępne, ⚠️ format może być niestabilny)
- `# METADATA` w `.rego` — już wdrożone w v1.0 (32/32 plików)
- Silnik szablonów — Python `string.Template` lub Jinja2
- Język polski — tłumaczenie kluczowych terminów podatkowych (stały słownik)

---

## CZĘŚĆ B: 3 ENTERPRISE-LEVEL OPTYMALIZACJE (Wydajność, Jakość, Proces)

---

### B1. Ewaluacja OPA wewnątrz DuckDB przez WebAssembly (In-Database WASM OPA)

#### Co jest optymalizowane

**Przepustowość batch processing** — obecnie każda faktura wymaga 1-9 wywołań REST API OPA. Przy >100 000 faktur miesięcznie to ~900 000 requestów HTTP — narzut sieciowy i JSON serializacji/deserializacji dominuje nad faktycznym czasem ewaluacji reguł.

#### Jak działa obecnie

```python
# Dla każdej faktury: 1-9 HTTP POST do OPA REST API
for invoice in batch:
    for pass_name in active_passes:
        response = requests.post(
            f"{OPA_URL}/v1/data/jdg/{pass_name}",
            json={"input": invoice}
        )
        verdicts[pass_name] = response.json()["result"]
    
    merged = object_union(verdicts)
    store_in_duckdb(merged)
```

#### Jak będzie działać po optymalizacji

OPA kompiluje reguły Rego do **WebAssembly (WASM)**. Ładujemy skompilowany moduł `.wasm` jako **User-Defined Function (UDF)** w DuckDB. Ewaluacja odbywa się **wewnątrz silnika bazy danych** — bez HTTP, bez JSON serializacji:

```sql
-- Rejestracja UDF w DuckDB
CREATE MACRO evaluate_tax(invoice_json) 
AS opa_wasm_eval('policies/jdg/bundle.tar.gz', invoice_json);

-- Batch processing — ewaluacja w silniku wektorowym DuckDB
SELECT 
    invoice_id,
    evaluate_tax(to_json(invoice)) AS verdict
FROM staging_invoices
WHERE processed = false;
```

```python
# Python — tylko odpalenie zapytania SQL, bez pętli
class DuckDBOpaEvaluator:
    def __init__(self):
        # Ładuj bundle OPA jako moduł WASM
        self.wasm_module = opa_compile_to_wasm("policies/jdg/")
        duckdb.execute("""
            CREATE MACRO evaluate_tax(invoice_json) 
            AS wasm_eval($1, ?)
        """, [self.wasm_module])
    
    def batch_evaluate(self, invoices_df: DataFrame) -> DataFrame:
        # Ewaluacja 100 000 faktur w jednym zapytaniu SQL
        return duckdb.execute("""
            SELECT 
                invoice_id,
                evaluate_tax(json_object(
                    'invoice', invoice_data,
                    'jdg_entrepreneur', entrepreneur_data
                )) AS verdict
            FROM invoices_df
        """).fetchdf()
```

#### Dlaczego to jest optymalizacja ENTERPRISE

1. **Eliminacja narzutu sieciowego** — zero HTTP, zero marshallingu JSON między procesami.
2. **Przetwarzanie wektorowe** — DuckDB wykonuje ewaluację na kolumnach, wykorzystując SIMD i cache procesora.
3. **Skalowalność horyzontalna** — im więcej rdzeni, tym szybciej (DuckDB natywnie wspiera wielowątkowość).
4. **Atomowość** — ewaluacja w transakcji SQL: albo wszystkie faktury, albo żadna.

#### Szacowany zysk

| Metryka | Obecnie (REST API) | Po optymalizacji (WASM w DB) | Zysk |
|---------|:------------------:|:---------------------------:|:----:|
| 1 faktura | ~50-200ms | ~10-30ms | **3-5×** |
| 10 000 faktur (batch) | ~8-15 min | ~30-60 sek | **10-30×** |
| 100 000 faktur (batch) | ~1.5-3 godz | ~5-10 min | **15-50×** |
| Narzut sieciowy | 80% czasu | 0% | **∞** |

#### Wykonalność

**TRUDNA (z ryzykiem technicznym).** ⚠️ DuckDB WASM UDF jest funkcją eksperymentalną, zaprojektowaną dla prostych funkcji skalarnych, nie dla złożonych modułów. OPA WASM wymaga środowiska uruchomieniowego (JavaScript/polyfill) — integracja z natywnym silnikiem C++ DuckDB może wymagać:
- Niestandardowego rozszerzenia DuckDB (custom C++ extension)
- Alternatywnie: DuckDB + osobny proces WASM (WASMtime/wasmer) z IPC przez shared memory
- Szacowany czas: 15-25 dni inżynieryjnych (nie 10 dni)

Komponenty:
- `opa build -t wasm` — kompilacja reguł do WASM (dostępne w OPA ≥0.45)
- DuckDB WASM UDF — `CREATE MACRO ... AS wasm_eval(...)` (eksperymentalne, ⚠️ ryzyko)
- Python orchestration — standardowe API DuckDB
- Ryzyko: integracja OPA WASM z DuckDB UDF może wymagać custom patchy lub zastępczego rozwiązania

**Rekomendacja:** Rozpocząć od Proof of Concept (Sprint 4) przed pełnym wdrożeniem.

---

### B2. Macierzowe Testy Kombinatoryczne — Orthogonal Array Cross-Pass Testing

#### Co jest optymalizowane

**Jakość testów i pokrycie interakcji między domenami** — obecnie testy (Boundary Fuzz) sprawdzają pojedyncze reguły i wartości graniczne, ale NIE testują, co się dzieje gdy JDG jednocześnie:
- Jest na podatku liniowym
- Importuje usługi spoza UE
- Ma aktywną ulgę B+R
- Jest w trakcie kontroli podatkowej
- Otrzymuje fakturę od kontrahenta spoza Białej Listy

W systemie 800 reguł, liczba możliwych kombinacji inputów jest astronomiczna. Nie da się testować ręcznie.

#### Jak działa obecnie

```python
# Testy jednostkowe — 1 reguła, 1-2 przypadki
def test_vat_exemption():
    result = evaluate({"turnover": 180000, "is_vat_payer": False})
    assert result["vat_exemption"] == "SUBJECT"

def test_kup_car_limit():
    result = evaluate({"car_value": 200000, "category": "CAR"})
    assert result["kus_qualification"] == "limited_car_150k"
# Brak testu: co gdy JDG na ryczałcie kupuje auto 200k z importu?
```

#### Jak będzie działać po optymalizacji

Generator **tablic ortogonalnych (Orthogonal Arrays)** tworzy **minimalny zestaw kombinacji**, który testuje wszystkie **pary** parametrów (pairwise testing). Dla 20 parametrów, każdy z 2-5 wartościami, zamiast 5^20 ≈ 10^14 kombinacji, potrzebujemy tylko ~200-500 testów.

```python
class OrthogonalArrayTestGenerator:
    """Generuje macierz testową techniką All-Pairs / Orthogonal Array."""
    
    # Definicja parametrów i możliwych wartości
    TAX_FORMS = ["PIT_SCALE", "LINEAR", "LUMP_SUM", "TAX_CARD"]
    VAT_STATUS = ["ACTIVE_PAYER", "EXEMPT_SUBJECT", "EXEMPT_OBJECT"]
    PROCEDURES = ["NONE", "WNT", "WDT", "IMPORT", "EXPORT", "MARGIN"]
    PAYMENT_METHODS = ["BANK_TRANSFER", "CASH", "CARD", "COMPENSATION"]
    BUSINESS_STATUS = ["ACTIVE", "SUSPENDED", "IN_SUCCESSIO", "UNREGISTERED"]
    ALLOWANCES = ["NONE", "B+R", "IP_BOX", "THERMO", "B+R+IP_BOX"]
    ZUS_RELIEF = ["STANDARD", "START_RELIEF", "MALY_ZUS_PLUS", "PREFERENTIAL"]
    # ... 14 więcej parametrów (20 łącznie)
    
    def generate_test_matrix(self) -> list[TestCase]:
        # Użyj algorytmu All-Pairs (np. biblioteka allpairspy)
        parameters = [
            self.TAX_FORMS,
            self.VAT_STATUS,
            self.PROCEDURES,
            self.PAYMENT_METHODS,
            self.BUSINESS_STATUS,
            self.ALLOWANCES,
            self.ZUS_RELIEF,
            # ... 13 więcej
        ]
        
        # All-Pairs generuje ~350 kombinacji (zamiast 5^20 = 10^14)
        pairs = allpairs(parameters)
        
        test_cases = []
        for combo in pairs:
            input_data = self.build_input_from_combo(combo)
            test_cases.append(TestCase(
                name=f"cross_pass_{combo}",
                input=input_data,
                # Oczekiwane: system NIE powinien crashować, 
                # powinien zwrócić deterministyczny werdykt
                expectations=[
                    "no_crash",
                    "deterministic_verdict",
                    "valid_legal_basis",
                    "no_conflicting_rules"
                ]
            ))
        
        return test_cases

# Pipeline CI/CD (nocny):
# 1. Generate: 350 kombinacji cross-pass
# 2. Evaluate: każda przez OPA
# 3. Assert:
#    - Żadna kombinacja nie powoduje crashu OPA
#    - Żadna kombinacja nie zwraca sprzecznych reguł
#    - Każda kombinacja ma co najmniej jedną pasującą regułę
# 4. Jeśli FAIL → alert do zespołu
```

#### Dlaczego to jest optymalizacja ENTERPRISE

1. **Pokrycie interakcji** — testuje kombinacje, których nikt by ręcznie nie wymyślił
2. **Wykrywanie Dead Ends** — kombinacje, dla których żadna reguła nie pasuje → luka w systemie
3. **Wykrywanie konfliktów** — kombinacje, dla których dwie reguły dają sprzeczne wyniki
4. **Minimalny zestaw testów** — matematycznie gwarantowane pokrycie wszystkich par parametrów przy minimalnej liczbie przypadków

#### Szacowany zysk

| Metryka | Przed | Po | Zysk |
|---------|:-----:|:--:|:----:|
| Pokrycie interakcji cross-pass | ~5% | ~95% par | **19×** |
| Testy ręczne/regułę | 0 | 0 (auto) | ∞ |
| Wykryte martwe ścieżki (Dead Ends) | 0 | Szac. 5-15 | Nowa jakość |
| Czas generacji testów (350 kombinacji) | ∞ (niemożliwe ręcznie) | ~2-5 min | ∞ |

#### Wykonalność

**WYSOKA.** Komponenty:
- Biblioteka `allpairspy` (Python) — generowanie tablic ortogonalnych
- OPA REST API — ewaluacja każdej kombinacji
- CI/CD pipeline — GitHub Actions (nocny cron)
- Fixtures — rozszerzenie `conftest.py`

---

### B3. Profilowanie Telemetryczne DAG + Dynamiczny Fail-Fast

#### Co jest optymalizowane

**Kolejność ewaluacji passów** — obecnie Dynamic DAG Pruning pomija całe nieistotne passy, ale w obrębie aktywnych passów kolejność jest **stała** (zdefiniowana w `main_jdg.rego`). Tymczasem w praktyce niektóre reguły odrzucają 90% faktur już na pierwszym kroku.

#### Jak działa obecnie

```python
# Stała kolejność passów
PASS_ORDER = [
    "risk",        # Zawsze pierwszy
    "routing",     # Zawsze drugi
    "compliance",  # Zawsze trzeci
    # ... 
]

# Nawet jeśli 90% faktur odpada na compliance (P20 - brak na białej liście),
# system nadal ewaluuje risk i routing (puste passy, brak trafień)
```

#### Jak będzie działać po optymalizacji

System monitoruje **skuteczność odrzutową** każdej reguły w czasie rzeczywistym i **dynamicznie przestawia kolejność passów**, aby reguły najczęściej blokujące trafiały na początek:

```python
class TelemetryDrivenDAGRouter:
    """Dynamicznie optymalizuje kolejność passów na podstawie telemetrii."""
    
    def __init__(self):
        self.rule_stats = {}  # rule_id → {hits, blocks, last_updated}
        self.rolling_window = 1000  # Okno analizy ostatnich 1000 faktur
    
    def record_verdict(self, rule_id: str, blocked: bool):
        """Rejestruje wynik ewaluacji dla analizy statystycznej."""
        if rule_id not in self.rule_stats:
            self.rule_stats[rule_id] = {"hits": 0, "blocks": 0}
        
        self.rule_stats[rule_id]["hits"] += 1
        if blocked:
            self.rule_stats[rule_id]["blocks"] += 1
    
    def get_optimized_pass_order(self) -> list[str]:
        """Zwraca kolejność passów posortowaną po skuteczności blokowania."""
        # Oblicz block-rate dla każdej reguły
        rule_block_rates = {}
        for rule_id, stats in self.rule_stats.items():
            if stats["hits"] >= 10:  # Minimum próbek dla istotności
                rule_block_rates[rule_id] = stats["blocks"] / stats["hits"]
        
        # Sortuj pakiety po sumarycznym block-rate
        pass_block_rates = {}
        for rule_id, rate in rule_block_rates.items():
            package = self.get_package_name(rule_id)
            pass_block_rates[package] = pass_block_rates.get(package, 0) + rate
        
        # Najwyższy block-rate na początek → Fail-Fast
        return sorted(pass_block_rates.keys(), 
                     key=lambda p: pass_block_rates[p], 
                     reverse=True)

# Przykład adaptacji:
# Po 1000 fakturach telemetria pokazuje:
#   - compliance: 45% odrzutów (P20 whitelist)
#   - risk:       2% odrzutów  (P8 ceidg)
#   - routing:    8% odrzutów  (P12 nip)
# Nowa kolejność: compliance → routing → risk → ...
# Zysk: 45% faktur odpada na 1. pasie, zamiast przechodzić przez risk+routing
```

#### Dlaczego to jest optymalizacja ENTERPRISE

> **Kluczowa różnica vs v1.0 B1 (Dynamic DAG Pruning):** DAG Pruning jest **statyczny** — pomija całe passy na podstawie reguł `skip_if` zdefiniowanych w Pythonie (np. "pomiń crossborder jeśli kraj=PL"). Fail-Fast jest **dynamiczny** — nie pomija passów, tylko zmienia ich kolejność na podstawie rzeczywistej telemetrii (np. "compliance ma 45% block-rate → przesuń na początek"). Oba mechanizmy uzupełniają się: Pruning eliminuje passy zbędne, Fail-Fast optymalizuje kolejność pozostałych.

1. **Samouczący się system** — kolejność optymalizuje się automatycznie na podstawie rzeczywistych danych, nie statycznej konfiguracji.
2. **Odporność na zmiany** — jeśli zmieni się charakter faktur (np. nowy typ fraudu), system automatycznie dostosuje kolejność.
3. **Early exit** — faktury blokowane nie przechodzą przez cały pipeline — oszczędność CPU i czasu.
4. **Zero-kosztowa optymalizacja** — nie wymaga zmian w Rego, tylko w warstwie orkiestracji Pythona.

#### Szacowany zysk

- **Średnia redukcja passów na fakturę odrzuconą:** z 5-6 do 1-2 → **-60% CPU**
- **Średni czas ewaluacji dla faktur odrzuconych:** redukcja o **~30-40%**
- **Adaptacja do zmian profilu ryzyka:** automatyczna, < 1000 faktur

#### Wykonalność

**WYSOKA.** Komponenty:
- Dictionary w Pythonie — statystyki reguł (in-memory)
- `collections.deque` — rolling window ostatnich N faktur
- `sorted()` — sortowanie passów po block-rate
- Integracja z istniejącym `DynamicDAGRouter` — rozszerzenie, nie zastąpienie

---

## CZĘŚĆ C: 3 PRZEŁOMOWE POMYSŁY (Przewaga Konkurencyjna)

---

### C1. Sfederowany Benchmarking Anomalii KUP (Peer-Based Fraud Detection)

#### Szczegółowy opis

Obecne reguły fraudowe (P0-P9) są **statyczne** — lista kategorii `["ALCOHOL", "ENTERTAINMENT", "LUXURY"]` jest taka sama dla wszystkich JDG. Nie uwzględnia to **specyfiki branży**: zegarek za 5000 PLN dla programisty (PKD 62.01.Z) jest podejrzany, ale dla prawnika (PKD 69.10.Z) może być uzasadniony jako element wizerunku.

**Przełom:** System analizuje **zanonimizowane dane** wszystkich JDG korzystających z NexusAI (federated learning) i buduje **profil normalnych wydatków per PKD**. Każdy nowy wydatek jest porównywany z benchmarkiem branżowym — jeśli odstaje o >3σ, generowana jest flaga `peer_suspicion_score` przekazywana do OPA jako dodatkowa przesłanka.

```python
class FederatedKUPPeerBenchmark:
    """Analizuje wzorce KUP per branża (PKD) z zanonimizowanych danych."""
    
    def __init__(self):
        # Struktura: PKD → kategoria wydatku → [μ, σ, percentyl_95]
        self.benchmarks = self.load_anonymized_benchmarks()
    
    def build_benchmark(self):
        """Buduje macierz benchmarków z zanonimizowanych danych DuckDB."""
        return duckdb.execute("""
            WITH anonymized AS (
                SELECT 
                    pkd_main,
                    invoice.category_code,
                    invoice.amount_net,
                    -- Anonimizacja: grupowanie min. 30 JDG per PKD, 
                    -- dodanie szumu Laplace'a (ε=1.0)
                    laplace_noise(1.0) AS privacy_noise
                FROM global_nexusai_kup_data
                GROUP BY pkd_main, category_code
                HAVING COUNT(DISTINCT entrepreneur_id) >= 30
            )
            SELECT 
                pkd_main,
                category_code,
                AVG(amount_net + privacy_noise) AS mu,
                STDDEV(amount_net) AS sigma,
                PERCENTILE_CONT(0.95) WITHIN GROUP 
                    (ORDER BY amount_net) AS p95
            FROM anonymized
            GROUP BY pkd_main, category_code
        """)
    
    def score_invoice(self, invoice: dict, entrepreneur: dict) -> float:
        """Zwraca suspicion_score ∈ [0.0, 1.0]."""
        pkd = entrepreneur["pkd_main"]
        category = invoice["category_code"]
        amount = invoice["amount_net"]
        
        benchmark = self.benchmarks.get((pkd, category))
        if not benchmark:
            return 0.0  # Brak danych referencyjnych → nie oceniamy
        
        mu, sigma, p95 = benchmark
        
        # Oblicz z-score i przekształć na suspicion_score
        z_score = (amount - mu) / sigma if sigma > 0 else 0
        suspicion = min(1.0, max(0.0, (z_score - 2.0) / 4.0))
        
        return suspicion

# Integracja z OPA:
# 1. Benchmarker zwraca peer_suspicion_score
# 2. Wstrzykujemy do input.thresholds jako nowy próg
# 3. Reguła P5_b (peer_kup_anomaly) używa go w warunku
```

#### Wykonalność

**ŚREDNIA/TRUDNA.** Wymagania:
1. **Baza klientów** — minimalna masa krytyczna: ~1000 aktywnych JDG do sensownych benchmarków
2. **Anonimizacja** — `diffprivlib` (Differential Privacy):
   - ε=1.0 (konfigurowalne — musi być parametrem, nie stałą)
   - Grupowanie min. 30 podmiotów per PKD (ochrona przed re-identyfikacją)
   - Szum Laplace'a na **wszystkich** agregatach (AVG, STDDEV, PERCENTILE_CONT)
   - Ochrona przed atakiem kompozycyjnym (wielokrotne zapytania) — monitoring privacy budget
3. **Bezpieczeństwo prawne:**
   - Zgoda użytkownika na anonimizowaną analitykę (klauzula RODO, art. 6 ust. 1 lit. a)
   - **Mechanizm opt-out** — JDG może wyłączyć udział w benchmarku (checkbox w ustawieniach)
   - Transparentność: JDG widzi, które jego dane (zanonimizowane) są użyte
4. **UX** — czytelna komunikacja: "Ten wydatek odbiega od normy w Twojej branży — sprawdź"

#### Konkretne korzyści dla JDG

- **Ochrona przed błędami KUP** — system ostrzega, gdy wydatek jest nietypowy dla branży
- **Adaptacyjne reguły fraudu** — benchmark uczy się na danych, nie na sztywnych listach
- **Przewaga konkurencyjna** — żaden system księgowy nie oferuje benchmarkingu branżowego
- **Społeczność NexusAI** — im więcej JDG, tym lepsze benchmarki (network effect)

---

### C2. Autonomiczny Generator Wniosków KIS/WIS (Tax Ruling Drafter)

#### Szczegółowy opis

Gdy Multi-Pass OPA nie znajduje pasującej reguły (NO_MATCH) lub wykrywa konflikt, faktura trafia do TRIAGE_QUEUE. Obecnie kończy się to mailem do księgowego: "sprawdź to ręcznie". To **niedomknięta pętla compliance** — luka prawna pozostaje nierozwiązana.

**Przełom:** System nie tylko raportuje lukę, ale **automatycznie generuje wniosek o wydanie Indywidualnej Interpretacji Podatkowej (KIS/WIS)** do Krajowej Informacji Skarbowej. Na podstawie struktury JSON z OPA, trace'a ewaluacji i kontekstu z `# METADATA`, LLM (GPT-4 / Claude) draftuje:
1. Opis stanu faktycznego
2. Opis problemu prawnego
3. Stanowisko wnioskodawcy (JDG)
4. Pytanie do KIS

```python
class AutonomousTaxRulingDrafter:
    """Generuje draft wniosku o interpretację podatkową."""
    
    WIS_KIS_TEMPLATE = """
    Naczelnik Krajowej Informacji Skarbowej
    ul. Teodora Sixta 17, 43-300 Bielsko-Biała
    
    WNIOSEK O WYDANIE INTERPRETACJI INDYWIDUALNEJ
    na podstawie art. 14b § 1 Ordynacji podatkowej
    
    I. OPIS STANU FAKTYCZNEGO
    {stan_faktyczny}
    
    II. OPIS PROBLEMU PRAWNEGO
    {problem_prawny}
    
    III. STANOWISKO WNIOSKODAWCY
    {stanowisko}
    
    IV. PYTANIE
    {pytanie}
    """
    
    def draft_ruling_request(self, verdict: dict, opa_trace: dict) -> str:
        # 1. Ekstrahuj kontekst z trace'a OPA
        conflicting_rules = self.extract_conflicts(opa_trace)
        missing_rules = self.extract_dead_ends(opa_trace)
        
        # 2. Zbuduj prompt dla LLM
        prompt = f"""
        Jesteś doradcą podatkowym. Na podstawie poniższych danych 
        wygeneruj wniosek o interpretację indywidualną (KIS).
        
        Dane JDG:
        - Forma opodatkowania: {verdict['pit_form']}
        - Status VAT: {verdict['vat_status']}
        
        Problem:
        - Konflikt reguł: {conflicting_rules}
        - Brakujące reguły: {missing_rules}
        
        Wygeneruj 4 sekcje wniosku (stan faktyczny, problem prawny, 
        stanowisko, pytanie) w formacie zgodnym z wymogami KIS.
        """
        
        draft = llm_client.complete(prompt, max_tokens=2000)
        
        # 3. Dodaj metadane dla księgowego
        return f"""
        📋 **Automatycznie wygenerowany draft wniosku KIS**
        
        ⚠️ WYMAGA WERYFIKACJI PRZEZ KSIĘGOWEGO PRZED ZŁOŻENIEM
        
        {draft}
        
        ---
        Wygenerowano przez NexusAI Tax Ruling Drafter
        Data: {datetime.now()}
        ID sprawy: {verdict['invoice_id']}
        """
```

#### Wykonalność

**ŚREDNIA.** Komponenty:
1. **LLM (GPT-4 / Claude)** — API do generowania tekstu prawnego (koszt: ~$0.01/wniosek)
2. **Szablon KIS** — stały format, dostępny na stronie KIS
3. **Integracja z UI** — przycisk "Generuj wniosek KIS" przy fakturze z TRIAGE_QUEUE
4. **Human-in-the-loop** — księgowy ZAWSZE weryfikuje przed złożeniem

#### Konkretne korzyści dla JDG

- **Zamknięcie pętli compliance** — zamiast "ręcznie sprawdź" → "oto gotowy wniosek, zweryfikuj i wyślij"
- **Redukcja kosztów** — wniosek KIS kosztuje 40 PLN + czas księgowego — automatyzacja oszczędza 80% czasu
- **Szybsze rozstrzygnięcia** — KIS ma 3 miesiące na odpowiedź, system przypomina o follow-up
- **Unikalna funkcja** — żaden konkurent nie oferuje automatycznego generowania wniosków KIS

---

### C3. Wyrocznia Płynności — Symulacje Metody Kasowej (Liquidity-Driven Accounting Oracle)

#### Szczegółowy opis

Większość polskich JDG cierpi na **zatory płatnicze** — kontrahenci płacą 30-90 dni po terminie, ale JDG musi zapłacić VAT i PIT od faktury w momencie jej wystawienia (metoda memoriałowa). To tworzy **lukę płynnościową**: podatek zapłacony, a pieniądze nie wpłynęły.

**Przełom:** Co kwartał Wyrocznia Płynności analizuje historię płatności wszystkich faktur danego JDG i **symuluje scenariusz alternatywny**: "co by było, gdybyś przeszedł na metodę kasową?" System uruchamia OPA na historycznych danych z flagą `vat_cash_accounting: true` i porównuje:

```python
class LiquidityDrivenAccountingOracle:
    """Symuluje skutki finansowe przejścia na metodę kasową."""
    
    def quarterly_analysis(self, entrepreneur_id: str) -> LiquidityReport:
        # 1. Pobierz historię faktur z ostatniego kwartału
        invoices = duckdb.execute("""
            SELECT *, 
                   DATEDIFF('day', due_date, COALESCE(payment_date, NOW())) 
                   AS days_overdue
            FROM invoices 
            WHERE entrepreneur_id = ?
              AND issue_date >= DATE_TRUNC('quarter', NOW())
        """, [entrepreneur_id]).fetchdf()
        
        # 2. Symuluj metodę memoriałową (status quo)
        accrual_verdicts = self.evaluate_batch(invoices, 
                                               cash_accounting=False)
        
        # 3. Symuluj metodę kasową (alternatywa)
        cash_verdicts = self.evaluate_batch(invoices, 
                                            cash_accounting=True)
        
        # 4. Porównaj
        accrual_tax = sum(v["total_tax_due_this_quarter"] 
                         for v in accrual_verdicts)
        cash_tax = sum(v["total_tax_due_this_quarter"] 
                      for v in cash_verdicts)
        
        # 5. Oblicz wskaźniki płynności
        avg_delay = invoices["days_overdue"].mean()
        liquidity_gap = accrual_tax - cash_tax
        
        recommendation = None
        if avg_delay > 60 and liquidity_gap > 5000:
            recommendation = (
                f"Średnie opóźnienie płatności: {avg_delay:.0f} dni. "
                f"Przejście na metodę kasową uwolniłoby "
                f"{liquidity_gap:.0f} PLN w tym kwartale. "
                f"Warunki: jesteś małym podatnikiem (✓), "
                f"zgłoś metodę kasową do US na przyszły rok."
            )
        
        return LiquidityReport(
            avg_contractor_delay_days=avg_delay,
            liquidity_gap_pln=liquidity_gap,
            accrual_method_tax=accrual_tax,
            cash_method_tax=cash_tax,
            recommendation=recommendation,
            eligible_for_cash_accounting=(
                entrepreneur["is_small_taxpayer"] and 
                entrepreneur["is_vat_payer"]
            )
        )
```

#### Wykonalność

**WYSOKA.** Komponenty:
1. **DuckDB time-travel** — historia faktur z datami płatności (już dostępne)
2. **OPA multi-evaluation** — ewaluacja tych samych faktur z różnymi flagami
3. **Warunek małego podatnika** — reguła P235 już istnieje
4. **UI** — dashboard "Płynność" z rekomendacją kwartalną

#### Konkretne korzyści dla JDG

- **Optymalizacja cash-flow** — JDG płaci VAT/PIT dopiero gdy dostanie zapłatę
- **Proaktywne doradztwo** — system sam proponuje zmianę metody, nie czeka aż JDG zapyta
- **Konkretne liczby** — "uwolnisz 8 500 PLN w tym kwartale" zamiast "metoda kasowa może być korzystna"
- **Zero konkurencji** — żaden system księgowy nie symuluje scenariuszy kasowych

---

## 📊 MACIERZ PRIORYTETÓW WDROŻENIA v2.0

| # | Inicjatywa | Typ | Wpływ | Wykonalność | Priorytet | Zależności |
|---|-----------|:---:|:-----:|:-----------:|:---------:|------------|
| **A2** | Linter Rego AST | Ulepszenie | 🔴 WYSOKI | ✅ Łatwa | **P0** | — (niezależna) |
| **A1** | Immutable Audit Trail | Ulepszenie | 🔴 WYSOKI | ✅ Łatwa | **P0** | — (niezależna) |
| **B2** | Orthogonal Array Testing | Optymalizacja | 🟡 ŚREDNI | ✅ Łatwa | **P1** | A1 (potrzebuje METADATA) |
| **B3** | Telemetry Fail-Fast | Optymalizacja | 🟡 ŚREDNI | ✅ Łatwa | **P1** | — (rozszerza istniejący DAG) |
| **A3** | Legal Explainer | Ulepszenie | 🔴 WYSOKI | 🟡 Średnia | **P2** | A1 (METADATA + trace) |
| **B1** | DuckDB WASM OPA | Optymalizacja | 🟡 ŚREDNI | 🔴 Trudna | **P2** | A1 (bundle jako WASM) |
| **C3** | Liquidity Oracle | Przełom | 🟢 NAJWYŻSZY | ✅ Łatwa | **P3** | — (niezależna, używa istniejącego API) |
| **C2** | Tax Ruling Drafter | Przełom | 🟢 NAJWYŻSZY | 🟡 Średnia | **P3** | A3 (trace do kontekstu LLM) |
| **C1** | Federated KUP Benchmark | Przełom | 🟢 NAJWYŻSZY | 🔴 Trudna | **P4** | — (wymaga masy krytycznej JDG) |

> **Uwaga o priorytetach:** "P0" w macierzy oznacza najwyższą ważność biznesową. W harmonogramie poniżej inicjatywy P0 są realizowane w **Sprincie 1** (1-2 tygodnie), nie "natychmiast przed sprintem" — ponieważ są to zmiany w kodzie (linter, krypto), które wymagają pełnego cyklu dev+test+review, a nie natychmiastowego hotfixu.

---

## 🚀 REKOMENDACJE NATYCHMIASTOWE

### Sprint 1: Fundamenty (1-2 tygodnie)

| Zadanie | Inicjatywa | Czas | Zespół |
|---------|:----------:|:----:|--------|
| Implementacja Lintera Rego AST w CI/CD | A2 | 3 dni | DevOps + Backend |
| Merkle Tree + ECDSA w DuckDB werdyktach | A1 | 2 dni | Backend |
| Pipeline Orthogonal Array Tests | B2 | 3 dni | QA + Backend |

### Sprint 2: Optymalizacje (2-3 tygodnie)

| Zadanie | Inicjatywa | Czas | Zespół |
|---------|:----------:|:----:|--------|
| Telemetry-Driven Fail-Fast DAG | B3 | 4 dni | Backend |
| Legal Explainer Engine (MVP: szablony) | A3 | 5 dni | Backend + Content |

### Sprint 3: Przełom (3-6 tygodni)

| Zadanie | Inicjatywa | Czas | Zespół |
|---------|:----------:|:----:|--------|
| Liquidity Oracle (co kwartał) | C3 | 4 dni | Backend + Analityka |
| Tax Ruling Drafter (integracja LLM) | C2 | 7 dni | AI + Backend |

### Sprint 4: Eksperyment (6+ tygodni)

| Zadanie | Inicjatywa | Czas | Zespół |
|---------|:----------:|:----:|--------|
| DuckDB WASM OPA — Proof of Concept | B1 | 10 dni | AI + Backend |
| Federated KUP Benchmark — pilot (100 JDG) | C1 | 14 dni | AI + Analityka + Legal |

---

## 🔥 KONKLUZJA KOŃCOWA

System NexusAI JDG osiągnął już poziom dojrzałości ~800 reguł kanonicznych z 9 wdrożonymi inicjatywami v1.0. **Inicjatywy v2.0** adresują pozostałe luki zidentyfikowane w audycie jakościowym (46):

- **A1-A3** zamykają problemy audytu zewnętrznego, transparentności i długu technicznego
- **B1-B3** podnoszą wydajność batchową o 10-50×, pokrycie testów o 19× i redukują CPU o 30%
- **C1-C3** dają NexusAI unikalną przewagę konkurencyjną: benchmark branżowy KUP, automatyczne wnioski KIS i optymalizację płynności

**Następny krok:** Sprint 1 — implementacja Lintera Rego AST (A2) i Immutable Audit Trail (A1) jako fundamenty bezpieczeństwa i jakości kodu.

---

*Wygenerowano przez NexusAI Chief Architect Review v2.0*  
*Data: 2026-07-12*  
*Bazuje na: Audyt jakościowy (46), Mapa kanoniczna (38c), Docs 22-25, Inicjatywy v1.0 (29)*  
*Inicjatywy v1.0 już wdrożone — ten dokument zawiera TYLKO nowe, niepowielające się pomysły*
