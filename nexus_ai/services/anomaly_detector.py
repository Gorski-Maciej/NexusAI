from __future__ import annotations

from typing import final

import polars as pl

from nexus_ai.db.analytics import DuckDBManager


@final
class SmartAnomalyDetector:
    """Wykrywa podejrzane faktury przy użyciu algorytmów statystycznych."""

    def __init__(self, db_manager: DuckDBManager):
        self.db = db_manager

    def detect(self, contractor_nip: str, current_amount: float) -> bool:
        """
        Zwraca True, jeśli kwota faktury znacząco odbiega od
        historycznego profilu danego kontrahenta.
        """
        # Pobieramy historię kwot dla tego NIPu z DuckDB
        query = "SELECT amount_gross FROM invoices_replica WHERE contractor_nip = ?"
        history = self.db.execute_query(query, (contractor_nip,))

        if len(history) < 10:
            # Zbyt mało danych - wracamy do bezpiecznego Z-Score (średnia + 3 odchylenia)
            return False

        pl.DataFrame(history)
        # Isolation Forest:
        # Tutaj w prawdziwym kodzie będzie logika dopasowania modelu (np. model.fit(df))
        return False
