"""AgentFixedAssets — Rozszerzenie: Auto-klasyfikacja ŚT z faktur.

RAPORT v7.0: "Brakuje automatycznego wykrywania ŚT z faktur (AI-assisted classification)".
Ta implementacja dodaje automatyczną klasyfikację ŚT na podstawie danych z faktury.
"""

from __future__ import annotations

from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.fixed_assets_classifier")


# ═════════════════════════════════════════════════════════════════════════
# Auto-klasyfikacja ŚT z faktur
# ═════════════════════════════════════════════════════════════════════════

# Mapa słów kluczowych → klasyfikacja KŚT
KEYWORD_TO_KST: dict[str, dict[str, Any]] = {
    # Grupa 0: Grunty
    "grunt": {"group": 0, "symbol": "0", "rate": 0.0, "life_years": 0},
    "działka": {"group": 0, "symbol": "0", "rate": 0.0, "life_years": 0},
    "prawo wieczystego": {"group": 0, "symbol": "0", "rate": 0.0, "life_years": 0},

    # Grupa 1: Budynki i lokale
    "budynek": {"group": 1, "symbol": "110", "rate": 2.5, "life_years": 40},
    "lokal": {"group": 1, "symbol": "110", "rate": 2.5, "life_years": 40},
    "hala produkcyjna": {"group": 1, "symbol": "110", "rate": 2.5, "life_years": 40},
    "magazyn": {"group": 1, "symbol": "110", "rate": 2.5, "life_years": 40},

    # Grupa 2: Obiekty inżynierii
    "plac": {"group": 2, "symbol": "220", "rate": 4.5, "life_years": 22},
    "ogrodzenie": {"group": 2, "symbol": "291", "rate": 4.5, "life_years": 22},
    "parking": {"group": 2, "symbol": "220", "rate": 4.5, "life_years": 22},

    # Grupa 3: Kotły i maszyny energetyczne
    "kocioł": {"group": 3, "symbol": "310", "rate": 7.0, "life_years": 14},
    "piec": {"group": 3, "symbol": "310", "rate": 7.0, "life_years": 14},
    "generator": {"group": 3, "symbol": "340", "rate": 7.0, "life_years": 14},

    # Grupa 4: Maszyny, urządzenia i aparaty ogólnego zastosowania
    "maszyna": {"group": 4, "symbol": "410", "rate": 14.0, "life_years": 7},
    "urządzenie": {"group": 4, "symbol": "491", "rate": 20.0, "life_years": 5},
    "aparat": {"group": 4, "symbol": "491", "rate": 20.0, "life_years": 5},
    "sprężarka": {"group": 4, "symbol": "430", "rate": 14.0, "life_years": 7},
    "pompa": {"group": 4, "symbol": "420", "rate": 14.0, "life_years": 7},
    "obrabiarka": {"group": 4, "symbol": "460", "rate": 14.0, "life_years": 7},

    # Grupa 5: Maszyny specjalne
    "koparka": {"group": 5, "symbol": "510", "rate": 20.0, "life_years": 5},
    "spychacz": {"group": 5, "symbol": "520", "rate": 20.0, "life_years": 5},
    "dźwig": {"group": 5, "symbol": "530", "rate": 20.0, "life_years": 5},

    # Grupa 6: Urządzenia techniczne
    "transformator": {"group": 6, "symbol": "610", "rate": 10.0, "life_years": 10},
    "rozdzielnia": {"group": 6, "symbol": "610", "rate": 10.0, "life_years": 10},

    # Grupa 7: Środki transportu
    "samochód": {"group": 7, "symbol": "741", "rate": 20.0, "life_years": 5},
    "auto": {"group": 7, "symbol": "741", "rate": 20.0, "life_years": 5},
    "pojazd": {"group": 7, "symbol": "749", "rate": 20.0, "life_years": 5},
    "przyczepa": {"group": 7, "symbol": "742", "rate": 14.0, "life_years": 7},
    "naczepa": {"group": 7, "symbol": "742", "rate": 14.0, "life_years": 7},
    "motocykl": {"group": 7, "symbol": "743", "rate": 20.0, "life_years": 5},

    # Grupa 8: Narzędzia, przyrządy
    "narzędzie": {"group": 8, "symbol": "800", "rate": 20.0, "life_years": 5},
    "przyrząd": {"group": 8, "symbol": "800", "rate": 20.0, "life_years": 5},
    "oprzyrządowanie": {"group": 8, "symbol": "800", "rate": 20.0, "life_years": 5},

    # IT — wartości niematerialne i prawne / sprzęt
    "komputer": {"group": 4, "symbol": "491", "rate": 30.0, "life_years": 3},
    "laptop": {"group": 4, "symbol": "491", "rate": 30.0, "life_years": 3},
    "serwer": {"group": 4, "symbol": "491", "rate": 30.0, "life_years": 3},
    "monitor": {"group": 4, "symbol": "491", "rate": 20.0, "life_years": 5},
    "drukarka": {"group": 4, "symbol": "491", "rate": 20.0, "life_years": 5},
    "oprogramowanie": {"group": 0, "symbol": "WNiP", "rate": 20.0, "life_years": 2},
    "licencja": {"group": 0, "symbol": "WNiP", "rate": 20.0, "life_years": 2},
    "telefon": {"group": 4, "symbol": "491", "rate": 20.0, "life_years": 3},
    "tablet": {"group": 4, "symbol": "491", "rate": 20.0, "life_years": 3},
}


class FixedAssetAutoClassifier:
    """Automatyczna klasyfikacja środków trwałych z danych faktury.

    RAPORT v7.0 Rekomendacja: AI-assisted classification of fixed assets.
    Klasyfikuje na podstawie słów kluczowych w nazwie + kwoty + kategorii.
    """

    # Progi dla automatycznej klasyfikacji jako ŚT
    MIN_AMOUNT_FOR_ASSET = 3_500     # PLN — poniżej = materiał/narzędzie
    MIN_USEFUL_LIFE = 1               # Minimum 1 rok użytkowania
    MIN_AMOUNT_FOR_AUTO_CLASSIFY = 10_000  # ≥ 10k PLN → pewna klasyfikacja ŚT

    def __init__(self) -> None:
        self._classification_stats: dict[str, int] = {
            "total_classified": 0,
            "auto_classified": 0,
            "manual_required": 0,
            "not_asset": 0,
        }
        self._keyword_map: dict[str, dict[str, Any]] = dict(KEYWORD_TO_KST)

    # ── Core Logic ──────────────────────────────────────────────────

    def classify(
        self,
        invoice_data: dict[str, Any],
        model_infer: Any = None,
    ) -> dict[str, Any]:
        """Sklasyfikuj ŚT na podstawie danych z faktury.

        Args:
            invoice_data: Wyekstrahowane dane z faktury.
            model_infer: Opcjonalna funkcja inferencji AI dla trudnych przypadków.

        Returns:
            Dict z klasyfikacją: {classification, group, symbol, rate, life_years, method, confidence}
        """
        name = invoice_data.get("description", invoice_data.get("name", ""))
        amount = float(invoice_data.get("amount_gross", invoice_data.get("amount_net", 0)))
        category = invoice_data.get("category", "")

        self._classification_stats["total_classified"] += 1

        # ── 1. Sprawdź czy to ŚT (kwota + okres użytkowania) ──
        if amount < self.MIN_AMOUNT_FOR_ASSET:
            self._classification_stats["not_asset"] += 1
            return {
                "classification": "not_fixed_asset",
                "reason": f"Kwota {amount:.2f} PLN poniżej progu {self.MIN_AMOUNT_FOR_ASSET} PLN",
                "confidence": 0.95,
                "suggested_treatment": "expense_or_low_value_asset",
            }

        # ── 2. Klasyfikacja po słowach kluczowych ──
        name_lower = name.lower()
        best_match = None
        best_score = 0
        best_keyword = ""

        for keyword, kst_info in self._keyword_map.items():
            if keyword in name_lower:
                score = len(keyword)
                if score > best_score:
                    best_score = score
                    best_match = kst_info
                    best_keyword = keyword

        if best_match and amount >= self.MIN_AMOUNT_FOR_AUTO_CLASSIFY:
            self._classification_stats["auto_classified"] += 1
            return {
                "classification": "fixed_asset",
                "method": "auto_keyword",
                "group": best_match["group"],
                "symbol": best_match["symbol"],
                "rate": best_match["rate"],
                "life_years": best_match["life_years"],
                "depreciation_method": self._determine_method(amount, best_match["rate"]),
                "confidence": min(0.95, best_score / 15),  # Max 0.95
                "matched_keyword": best_keyword,
            }

        # ── 3. Klasyfikacja po kategorii ──
        category_match = self._classify_by_category(category, amount)
        if category_match and amount >= self.MIN_AMOUNT_FOR_AUTO_CLASSIFY:
            self._classification_stats["auto_classified"] += 1
            return {
                "classification": "fixed_asset",
                "method": "auto_category",
                **category_match,
                "confidence": 0.70,
            }

        # ── 4. Próba AI (jeśli dostępne) ──
        if model_infer and amount >= self.MIN_AMOUNT_FOR_ASSET:
            try:
                import inspect
                if inspect.iscoroutinefunction(model_infer):
                    # Async model inference needs event loop - skip for sync classifier
                    logger.debug("[FIXED-ASSETS] Async model_infer not supported in sync classify()")
                else:
                    ai_result = self._ai_classify(name, amount, category, model_infer)
                    if ai_result:
                    self._classification_stats["auto_classified"] += 1
                    return {
                        "classification": "fixed_asset",
                        "method": "ai_assisted",
                        **ai_result,
                        "confidence": 0.65,
                    }
            except Exception as exc:
                logger.debug("[FIXED-ASSETS] AI classify failed: %s", exc)

        # ── 5. Manualna klasyfikacja ──
        self._classification_stats["manual_required"] += 1
        return {
            "classification": "needs_manual_review",
            "reason": f"Nie można automatycznie sklasyfikować: {name[:50]}",
            "amount": amount,
            "description": name,
            "confidence": 0.30,
        }

    def _classify_by_category(
        self, category: str, amount: float
    ) -> dict[str, Any] | None:
        """Klasyfikacja po kategorii wydatku."""
        cat_lower = category.lower() if category else ""

        category_map = {
            "it": {"group": 4, "symbol": "491", "rate": 30.0, "life_years": 3},
            "sprzęt": {"group": 4, "symbol": "491", "rate": 20.0, "life_years": 5},
            "transport": {"group": 7, "symbol": "741", "rate": 20.0, "life_years": 5},
            "maszyny": {"group": 4, "symbol": "410", "rate": 14.0, "life_years": 7},
            "budynek": {"group": 1, "symbol": "110", "rate": 2.5, "life_years": 40},
            "wyposażenie": {"group": 8, "symbol": "800", "rate": 20.0, "life_years": 5},
        }

        for key, info in category_map.items():
            if key in cat_lower:
                info["depreciation_method"] = self._determine_method(amount, info["rate"])
                return info
        return None

    def _ai_classify(
        self, name: str, amount: float, category: str, model_infer: Any
    ) -> dict[str, Any] | None:
        """Użyj AI do klasyfikacji ŚT."""
        prompt = (
            f"Sklasyfikuj środek trwały:\n"
            f"Nazwa: {name}\n"
            f"Kwota: {amount:.2f} PLN\n"
            f"Kategoria: {category}\n\n"
            f"Podaj: GRUPA_KST (0-8), SYMBOL, STAWKA (%), OKRES (lata).\n"
            f"Format: GRUPA: X, SYMBOL: XXX, STAWKA: X.X, OKRES: X"
        )
        try:
            result = model_infer(prompt)
            return self._parse_ai_response(result)
        except Exception:
            return None

    @staticmethod
    def _parse_ai_response(text: str) -> dict[str, Any] | None:
        """Parsuj odpowiedź AI."""
        import re
        group = re.search(r"GRUPA[:\s]*(\d+)", text, re.IGNORECASE)
        symbol = re.search(r"SYMBOL[:\s]*(\S+)", text, re.IGNORECASE)
        rate = re.search(r"STAWKA[:\s]*([\d.]+)", text, re.IGNORECASE)
        life = re.search(r"OKRES[:\s]*(\d+)", text, re.IGNORECASE)

        if group and symbol:
            return {
                "group": int(group.group(1)),
                "symbol": symbol.group(1),
                "rate": float(rate.group(1)) if rate else 20.0,
                "life_years": int(life.group(1)) if life else 5,
                "depreciation_method": "linear",
            }
        return None

    @staticmethod
    def _determine_method(amount: float, rate: float) -> str:
        """Określ metodę amortyzacji."""
        if amount <= 10_000:
            return "one_time"  # Amortyzacja jednorazowa
        if rate >= 20.0:
            return "degressive"  # Degresywna dla szybko zużywających się
        return "linear"  # Liniowa domyślnie

    def add_keyword(self, keyword: str, kst_info: dict[str, Any]) -> None:
        """Dodaj nowe słowo kluczowe do mapy."""
        self._keyword_map[keyword.lower()] = kst_info

    def get_stats(self) -> dict[str, Any]:
        return {
            **self._classification_stats,
            "auto_classify_rate_pct": round(
                self._classification_stats["auto_classified"]
                / max(self._classification_stats["total_classified"], 1) * 100, 1
            ),
            "keywords_count": len(self._keyword_map),
        }
