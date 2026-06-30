"""NexusAI — Performance & Load Test Scenarios (Locust).

Zgodnie z aa3fvcx.txt: locust zastępuje k6.
Ten pakiet zawiera scenariusze testów wydajnościowych używające FastHttpUser
z pełnym wykorzystaniem supermocy locust:
  - FastHttpUser (geventhttpclient) — 3-5× więcej RPS niż HttpUser
  - SequentialTaskSet — ścisła kolejność operacji biznesowych
  - catch_response — walidacja biznesowa odpowiedzi
  - LoadTestShape — customowe profile obciążenia
  - @events hooks — integracja z OpenTelemetry
  - Distributed mode — master/worker dla CI/CD
"""
