# 🧪 Testowanie (Testing)

> **Cel:** Opisać strategię testów i narzędzia.  
> **Kiedy czytać:** Przed pisaniem pierwszego testu; przed wdrożeniem.

---

## 1. Strategia testów

NexusAI stosuje **piramidę testów** z naciskiem na property-based testing (matematyczne dowody poprawności):

```
        ┌──────┐
        │ E2E  │  locust (wydajność), schemathesis (fuzz API)
        ├──────┤
        │Integr│  testy integracyjne (DB + NATS + TigerBeetle)
        ├──────┤
        │ Unit │  testy jednostkowe (pytest)
        ├──────┤
        │PBT   │  property-based (crosshair — SMT solver)
        └──────┘
```

### 1.1 Poziomy testów

| Poziom | Narzędzie | Cel | Pokrycie |
|---|---|---|---|
| **Property-Based** | crosshair | Matematyczne dowody poprawności (VAT, zaokrąglenia) | Krytyczna logika finansowa |
| **Jednostkowe** | pytest | Izolowane funkcje i klasy | Wszystkie serwisy |
| **Integracyjne** | pytest + DB/NATS | Przepływy end-to-end | Kluczowe procesy |
| **Fuzz API** | schemathesis | Automatyczna walidacja OpenAPI | Wszystkie endpointy |
| **Wydajnościowe** | locust | Testy obciążeniowe | API pod loadem |
| **Profilowanie** | py-spy | Wąskie gardła CPU | Diagnostyka |

---

## 2. Jak uruchomić testy

```bash
# Wszystkie testy (zatrzymaj przy pierwszym błędzie)
pixi run test

# Wszystkie testy (nie zatrzymuj)
pixi run test-all

# Testy z pokryciem kodu
pixi run test-cov

# Testy równoległe (wszystkie rdzenie)
pixi run test-parallel

# Konkretny plik
pixi run test -- tests/test_inventory_fifo.py

# Konkretny test
pixi run test -- tests/test_vat_reconciliation.py -k "test_cross_border"

# Testy integracyjne (wymagają DB/NATS)
pixi run test -- -m integration

# Property-based tests (crosshair)
pixi run test -- tests/test_crosshair_properties.py
```

---

## 3. Narzędzia testowe

### 3.1 pytest (framework testowy)

```python
# tests/test_inventory_fifo.py
import pytest
from nexus_ai.services.inventory_fifo import FifoInventory

@pytest.mark.anyio  # dla testów asynchronicznych
async def test_fifo_basic():
    inv = FifoInventory()
    inv.add_purchase("A", qty=10, unit_cost_cents=1000)  # 10 szt. po 10 PLN
    inv.add_purchase("A", qty=5, unit_cost_cents=1200)   # 5 szt. po 12 PLN
    cost = inv.sell("A", qty=12)
    assert cost == 10 * 1000 + 2 * 1200  # FIFO: najpierw starsze
```

### 3.2 crosshair (property-based testing z SMT solverem)

```python
# tests/test_crosshair_properties.py
from decimal import Decimal
from crosshair import register_type
from nexus_ai.domain.values import Money, MoneyNet

def test_net_plus_vat_equals_gross(net_cents: int, vat_rate_percent: int):
    """Niezmiennik: dla dowolnego netto i stawki VAT,
    netto + VAT ZAWSZE = brutto"""
    assert 0 <= vat_rate_percent <= 23
    net = Money(amount=Decimal(str(net_cents)) / 100)
    rate = Decimal(str(vat_rate_percent)) / 100
    net_with_vat = MoneyNet(amount_net=net, vat_rate=rate)
    assert net_with_vat.amount_net + net_with_vat.amount_vat == net_with_vat.amount_gross

def test_money_roundtrip(zlotowki: Decimal):
    """Konwersja złotówki → grosze → złotówki jest idempotentna"""
    # crosshair znajdzie kontrprzykład matematycznie (SMT), nie losowo
    grosze = int((zlotowki * 100).quantize(Decimal("0.01")))
    zl_powrot = Decimal(str(grosze)) / 100
    assert zl_powrot == zlotowki
```

**Przewaga crosshair nad hypothesis:**
- SMT solver (Z3) zamiast losowania → matematyczne dowody
- Analiza statyczna przed uruchomieniem → szybsze
- Deterministyczne wyniki

### 3.3 schemathesis (fuzz testing API)

```bash
# Automatyczny fuzz test wszystkich endpointów z OpenAPI
pixi run test -- tests/schemathesis/
```

```python
# tests/schemathesis/test_api_schema.py
import schemathesis

schema = schemathesis.from_url("http://127.0.0.1:8000/schema/openapi.yml")

@schema.parametrize()
def test_api(case):
    """Każdy endpoint testowany setkami losowych parametrów"""
    response = case.call()
    case.validate_response(response)
```

### 3.4 locust (testy wydajnościowe)

```python
# tests/performance/locustfile.py
from locust import HttpUser, task, between

class NexusUser(HttpUser):
    wait_time = between(1, 3)
    
    @task(3)
    def list_invoices(self):
        self.client.get("/api/v1/invoices", headers={"Authorization": f"Bearer {self.token}"})
    
    @task(1)
    def upload_invoice(self):
        with open("tests/fixtures/sample_invoice.pdf", "rb") as f:
            self.client.post("/api/v1/invoices/upload", files={"file": f})
```

```bash
# Uruchomienie
pixi run test -- tests/performance/locustfile.py --host=http://127.0.0.1:8000
```

### 3.5 py-spy (profiler)

```bash
# Profiluj działający proces API (bez restartu!)
pixi run profile       # Zapisuje flamegraph.svg
pixi run profile-top   # Top-like widok
```

---

## 4. Szablon testu — jak pisać nowe testy

### 4.1 Test jednostkowy

```python
# tests/test_[nazwa_serwisu].py
import pytest
from nexus_ai.services.moj_serwis import MojSerwis

class TestMojSerwis:
    """Testy dla MojSerwis."""
    
    @pytest.fixture
    def serwis(self):
        return MojSerwis()
    
    def test_podstawowy_przypadek(self, serwis):
        wynik = serwis.metoda("dane")
        assert wynik.status == "ok"
    
    def test_przypadek_brzegowy_pusta_lista(self, serwis):
        wynik = serwis.metoda([])
        assert wynik == []
    
    def test_rzuca_wyjatek_dla_nieprawidlowych_danych(self, serwis):
        with pytest.raises(ValueError, match="Nieprawidłowy NIP"):
            serwis.metoda(nip="0000000000")
```

### 4.2 Test integracyjny (async + DB)

```python
# tests/integration/test_przeplyw.py
import pytest
from nexus_ai.db.database import get_session

@pytest.mark.anyio
@pytest.mark.integration
async def test_full_invoice_flow(db_session):
    """Pełny przepływ: utworzenie → OCR → decyzja → księgowanie."""
    # 1. Utwórz fakturę
    invoice = await create_invoice(db_session, ...)
    assert invoice.status == "NEW"
    
    # 2. Uruchom OCR
    result = await process_ocr(invoice.id)
    assert result.confidence >= 0.5
    
    # 3. Podejmij decyzję
    decision = await auto_decree(invoice.id, result)
    assert decision.status in ("APPROVED", "PENDING_REVIEW")
```

---

## 5. Specyfika księgowa — co testować

### 5.1 Zaokrąglenia VAT

```python
def test_vat_rounding_half_up():
    """VAT zawsze zaokrąglany HALF_UP."""
    assert compute_vat(net_cents=12345, rate=Decimal("0.23")) == 2839  # 2839.35 → 2839
    assert compute_vat(net_cents=12346, rate=Decimal("0.23")) == 2840  # 2839.58 → 2840
```

### 5.2 Podwójny zapis (TigerBeetle)

```python
async def test_double_entry_balances():
    """Suma debetów MUSI być równa sumie kredytów."""
    transfer = create_transfer(debit_account=401, credit_account=201, amount=10000)
    assert transfer.debits_sum == transfer.credits_sum
```

### 5.3 Przeliczanie walut

```python
def test_fx_conversion():
    """100 EUR × 4.5123 PLN/EUR = 451.23 PLN."""
    result = convert_currency(Money(amount=Decimal("100"), currency="EUR"), "PLN", rate=Decimal("4.5123"))
    assert result == Money(amount=Decimal("451.23"), currency="PLN")
```

### 5.4 Obliczenia odsetek

```python
def test_interest_calculation():
    """Odsetki za 30 dni przy 10% rocznie od 10000 PLN."""
    interest = compute_interest(principal=1000000, rate=Decimal("0.10"), days=30)
    assert interest == 8219  # 10000 * 0.10 * 30/365 = 82.19 PLN = 8219 gr
```

### 5.5 Amortyzacja liniowa

```python
def test_linear_depreciation():
    """Środek trwały 12000 PLN, 20% rocznie = 200 PLN/miesiąc."""
    schedule = compute_depreciation(value=1200000, rate=Decimal("0.20"), method="linear")
    assert schedule[0].monthly == 20000  # 200.00 PLN = 20000 gr
    assert schedule[59].remaining == 20000  # Po 5 latach: ostatni odpis
```

---

## 6. Mockowanie zewnętrznych API

```python
# tests/conftest.py
@pytest.fixture
def mock_ksef(httpx_mock):
    httpx_mock.add_response(
        url="https://ksef.mf.gov.pl/api/invoice/send",
        json={"ksef_id": "1234567890ABCDEF"},
        status_code=200,
    )
    return httpx_mock

@pytest.fixture
def mock_nbp(httpx_mock):
    httpx_mock.add_response(
        url="https://api.nbp.pl/api/exchangerates/rates/a/eur/",
        json={"code": "EUR", "rates": [{"mid": 4.5123}]},
    )
```

---

## 7. CI/CD — testy w pipeline

```yaml
# .github/workflows/ci.yml (fragment)
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: prefix-dev/setup-pixi@v0
      - run: pixi install
      - run: pixi run lint         # Ruff
      - run: pixi run typecheck    # mypy strict
      - run: pixi run test         # pytest + crosshair
      - run: pixi run test-cov     # coverage
```

---

## 🔗 Zobacz również

- [Moduły i logika](MODULES.md) — testowane serwisy i agenci AI
- [Proces rozwoju](CONTRIBUTING.md) — checklist przed PR, standardy kodowania
- [Architektura](ARCHITECTURE.md) — wzorce projektowe podlegające testom

---

> **Data aktualizacji:** 2026-07-04 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-04 · **Weryfikator:** NexusAI Team
