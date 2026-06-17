"""
NexusAI — Custom Load Test Shapes (SUPERMOC EDITION)
======================================================

Zgodnie z aa3fvcx.txt: locust zastępuje k6 z pełnym wykorzystaniem
LoadTestShape dla realistycznych profili obciążenia.

SUPERMOCE:
  - LoadTestShape      — definiowanie niestandardowych kształtów obciążenia
  - StepLoadShape      — wbudowany shape skokowy
  - DoubleWaveShape    — podwójna fala (godziny szczytu)
  - Custom tick()      — własna logika obciążenia w czasie rzeczywistym
  - time_limit         — automatyczne zakończenie testu po czasie

Usage:
    LOCUST_SHAPE=NexusSpikeShape locust -f tests/performance/locustfile.py \\
        --host=http://localhost:8000 --headless -t 10m

    locust -f tests/performance/locustfile.py \\
        --shape=NexusMonthEndShape --host=http://localhost:8000
"""

from __future__ import annotations

import math
import os

from locust import LoadTestShape


class NexusSpikeShape(LoadTestShape):
    """SUPERMOC: Symulacja nagłego skoku obciążenia.

    Idealne do testowania:
      - Auto-scalingu (jeśli w przyszłości)
      - Rate limitingu
      - Circuit breakera (stamina)
      - Zachowania systemu pod ekstremalnym obciążeniem

    Profil:
      - 0-2min:    rozgrzewka        (50 użytkowników)
      - 2-3min:    pierwszy skok     (50 → 500)
      - 3-5min:    plateau 1         (500)
      - 5-6min:    drugi skok        (500 → 1000)
      - 6-8min:    plateau 2         (1000)
      - 8-10min:   schodzenie        (1000 → 50)
      - 10min:     koniec
    """

    time_limit = 600  # 10 minutes
    spawn_rate = 20   # użytkowników na sekundę

    def tick(self) -> tuple[int, float] | None:
        """SUPERMOC: Własna logika obciążenia.

        tick() — wywoływany co sekundę przez locust.
        Zwraca (user_count, spawn_rate) lub None (koniec testu).
        """
        run_time = self.get_run_time()

        if run_time < 120:        # 0-2min: warmup
            return (50, 10)
        elif run_time < 180:      # 2-3min: spike 1
            return (500, 100)
        elif run_time < 300:      # 3-5min: plateau 1
            return (500, 10)
        elif run_time < 360:      # 5-6min: spike 2
            return (1000, 200)
        elif run_time < 480:      # 6-8min: plateau 2
            return (1000, 10)
        elif run_time < 600:      # 8-10min: cooldown
            return (50, 20)
        return None               # Koniec testu


class NexusMonthEndShape(LoadTestShape):
    """SUPERMOC: Symulacja ruchu na koniec miesiąca (księgowania masowe).

    W księgowości koniec miesiąca to okres wzmożonego ruchu:
    - Księgowania masowe
    - Zamykanie okresów
    - Raporty miesięczne
    - Wysyłka do KSeF

    Profil (na 15 minut):
      - 0-3min:    normalny ruch     (100 użytkowników)
      - 3-5min:    wzrost            (100 → 300)
      - 5-7min:    szczyt            (300 → 500)
      - 7-10min:   plateau           (500)
      - 10-12min:  spadek            (500 → 100)
      - 12-15min:  normalizacja      (100)
    """

    time_limit = 900  # 15 minutes

    def tick(self) -> tuple[int, float] | None:
        run_time = self.get_run_time()

        if run_time < 180:
            return (100, 10)
        elif run_time < 300:
            return (300, 20)
        elif run_time < 420:
            return (500, 30)
        elif run_time < 600:
            return (500, 10)
        elif run_time < 720:
            return (100, 30)
        elif run_time < 900:
            return (100, 5)
        return None


class NexusTaxPeriodShape(LoadTestShape):
    """SUPERMOC: Symulacja okresu rozliczeniowego VAT.

    W szczycie okresu VAT (do 25. dnia miesiąca) ruch jest większy:
    - Wysyłka faktur do KSeF
    - Generowanie deklaracji VAT
    - Reconciliation

    Profil (na 30 minut):
      - 0-10min:   normalny           (200 użytkowników)
      - 10-15min:  wzrost             (200 → 500)
      - 15-20min:  szczyt VAT         (500 → 800)
      - 20-25min:  plateau            (800)
      - 25-30min:  koniec okresu      (800 → 0)
    """

    time_limit = 1800  # 30 minutes

    def tick(self) -> tuple[int, float] | None:
        run_time = self.get_run_time()

        if run_time < 600:
            return (200, 10)
        elif run_time < 900:
            return (500, 20)
        elif run_time < 1200:
            return (800, 30)
        elif run_time < 1500:
            return (800, 10)
        elif run_time < 1800:
            return (50, 30)
        return None


class NexusDoubleWaveShape(LoadTestShape):
    """SUPERMOC: Podwójna fala dla symulacji godzin szczytu.

    Symuluje dwa szczyty w ciągu dnia:
    - Poranny szczyt (9:00-11:00)
    - Popołudniowy szczyt (14:00-16:00)

    Używa funkcji sinus do generowania płynnych fal.
    """

    time_limit = 1800  # 30 minutes
    spawn_rate = 10

    def tick(self) -> tuple[int, float] | None:
        run_time = self.get_run_time()
        if run_time >= self.time_limit:
            return None

        # SUPERMOC: Matematyczny kształt fali
        # Dwie fale: pierwszy szczyt w 25%, drugi w 75% czasu
        progress = run_time / self.time_limit
        wave1 = math.sin(progress * 2 * math.pi) * 0.5 + 0.5  # 0-1 range
        wave2 = math.sin((progress - 0.5) * 2 * math.pi) * 0.3 + 0.3  # offset
        users = int(200 + (wave1 + wave2) * 400)

        return (max(50, users), self.spawn_rate)


class NexusSteadyShape(LoadTestShape):
    """SUPERMOC: Stałe obciążenie dla stabilnych benchmarków.

    Idealne do porównywania wydajności między wersjami:
    - Benchmark przed/po zmianach
    - Regression testing
    - SLO validation
    """

    time_limit = 300  # 5 minutes

    def __init__(self, *args: tuple, **kwargs: dict) -> None:
        super().__init__(*args, **kwargs)
        self.target_users = int(os.getenv("LOCUST_TARGET_USERS", "100"))
        self.spawn = int(os.getenv("LOCUST_SPAWN_RATE", "10"))

    def tick(self) -> tuple[int, float] | None:
        run_time = self.get_run_time()
        if run_time >= self.time_limit:
            return None

        # Warmup: stopniowe zwiększanie
        if run_time < 60:
            users = int(self.target_users * (run_time / 60))
            return (max(1, users), self.spawn)

        # Stabilne obciążenie
        return (self.target_users, self.spawn)
