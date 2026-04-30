from pathlib import Path
import sys
import asyncio
from datetime import date

sys.path.append(str(Path(__file__).resolve().parents[1]))

from Roboton_Reflekton.forex_engine import ForexEngine
from Roboton_Reflekton.ledger_client import TigerBeetleClient


class FakeResponse:
    def __init__(self, payload):
        self._payload = payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def read(self):
        import json
        return json.dumps(self._payload).encode("utf-8")


class FakeDuckDB:
    def __init__(self):
        self.rate_cache = {}
        self.invoice_rows = {"inv-1": [("EUR", 100, 4.30)]}
        self.payment_rows = {"pay-1": [(4.40,)]}

    def execute(self, query, params=None):
        q = " ".join(query.split())
        if "SELECT avg_rate FROM exchange_rates" in q:
            return [(self.rate_cache[(params[0], params[1])],)] if (params[0], params[1]) in self.rate_cache else []
        if "INSERT OR REPLACE INTO exchange_rates" in q:
            self.rate_cache[(params[0], params[1])] = params[2]
            return []
        if "FROM invoices_fx" in q:
            return self.invoice_rows.get(params[0], [])
        if "FROM bank_transactions_fx" in q:
            return self.payment_rows.get(params[0], [])
        return []


def test_fetch_nbp_rate_uses_lookback_and_cache(monkeypatch):
    db = FakeDuckDB()
    tb = TigerBeetleClient()
    engine = ForexEngine(db, tb, 201, 750, 751)

    calls = {"n": 0}

    from urllib.error import HTTPError

    def fake_urlopen(url, timeout):
        calls["n"] += 1
        if "2026-04-27" in url:
            raise HTTPError(url, 404, "not found", hdrs=None, fp=None)
        return FakeResponse({"rates": [{"mid": 4.321, "no": "060/A/NBP/2026"}]})

    monkeypatch.setattr("Roboton_Reflekton.forex_engine.request.urlopen", fake_urlopen)
    rate = engine.fetch_nbp_rate(date(2026, 4, 27), "EUR")
    assert float(rate) == 4.321

    rate_cached = engine.fetch_nbp_rate(date(2026, 4, 26), "EUR")
    assert float(rate_cached) == 4.321
    assert calls["n"] >= 2




def test_fetch_nbp_rate_retries_on_url_error(monkeypatch):
    db = FakeDuckDB()
    tb = TigerBeetleClient()
    engine = ForexEngine(db, tb, 201, 750, 751)

    from urllib.error import URLError

    calls = {"n": 0}

    def fake_urlopen(url, timeout):
        calls["n"] += 1
        if "2026-04-27" in url:
            raise URLError("temporary dns failure")
        return FakeResponse({"rates": [{"mid": 4.111, "no": "061/A/NBP/2026"}]})

    monkeypatch.setattr("Roboton_Reflekton.forex_engine.request.urlopen", fake_urlopen)
    rate = engine.fetch_nbp_rate(date(2026, 4, 27), "EUR")
    assert float(rate) == 4.111
    assert calls["n"] >= 2

def test_process_fx_settlement_creates_gain_transfer() -> None:
    async def run() -> None:
        db = FakeDuckDB()
        tb = TigerBeetleClient()
        engine = ForexEngine(db, tb, 201, 750, 751)

        result = await engine.process_fx_settlement("inv-1", "pay-1")
        assert result.direction == "GAIN"
        assert float(result.fx_diff_pln) == 10.0
        assert await tb.get_account_credits_posted(750) == 1000

    asyncio.run(run())
