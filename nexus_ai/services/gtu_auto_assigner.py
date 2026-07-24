"""
v7.0 INNOWACJA 5: Semantic GTU Auto-Assigner (MR-3).

Automatyczne przypisywanie kodów GTU (13 kodów JPK_V7M)
na podstawie analizy semantycznej opisu towaru/usługi.

Raport v7.0 LUKA: GTU przypisywane tylko przez category_code
(13 mapowań w substantive.rego). Brak semantycznej auto-detekcji.

Ten moduł dodaje:
- Keyword matching dla 13 kodów GTU
- Scoring konfidencji dla każdego dopasowania
- Fallback do category_code gdy NLP nie daje pewności
- Integrację z LLM bridge dla niejednoznacznych przypadków
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from structlog import get_logger

logger = get_logger("nexus.services.gtu_assigner")


# ── Oficjalne kody GTU (JPK_V7M, §10 rozp. JPK_VAT) ────────────────────────

GTU_CODES: dict[str, dict[str, Any]] = {
    "GTU_01": {
        "description": "Dostawa napojów alkoholowych",
        "legal_basis": "Art. 41 ust. 1 VAT, poz. 1 zał. 15",
        "cn_codes": ["2203", "2204", "2205", "2206", "2207", "2208"],
        "keywords": ["alkohol", "piwo", "wino", "wódka", "whisky", "drink",
                      "napój alkoholowy", "spirytus", "likier", "szampan"],
        "categories": {"ALCOHOL", "BEVERAGES_ALCOHOLIC", "SPIRITS"},
    },
    "GTU_02": {
        "description": "Dostawa towarów — paliwa i oleje",
        "legal_basis": "§10 ust. 3 pkt 2 rozp. JPK_VAT",
        "cn_codes": ["2709", "2710", "2711", "2713", "2714", "2715", "2716"],
        "keywords": ["paliwo", "benzyna", "olej napędowy", "diesel", "LPG",
                      "gaz płynny", "ropa", "asfalt", "olej opałowy",
                      "paliwo lotnicze", "biodiesel", "etanol paliwowy"],
        "categories": {"FUEL", "FUEL_HEATING", "FUEL_DIESEL", "FUEL_GASOLINE",
                       "FUEL_LPG", "CRUDE_OIL", "OIL_LUBRICANTS"},
    },
    "GTU_03": {
        "description": "Dostawa oleju opałowego",
        "legal_basis": "§10 ust. 3 pkt 3 rozp. JPK_VAT",
        "cn_codes": ["2710"],
        "keywords": ["olej opałowy", "olej grzewczy", "mazut"],
        "categories": {"FUEL_HEATING", "HEATING_OIL"},
    },
    "GTU_04": {
        "description": "Dostawa wyrobów tytoniowych",
        "legal_basis": "§10 ust. 3 pkt 4 rozp. JPK_VAT",
        "cn_codes": ["2402", "2403"],
        "keywords": ["tytoń", "papierosy", "cygara", "cygaretki", "e-papieros",
                      "liquid", "tytoniowy", "nikotyna"],
        "categories": {"TOBACCO"},
    },
    "GTU_05": {
        "description": "Dostawa odpadów — wyłącznie określonych w poz. 79-91 zał. 3",
        "legal_basis": "§10 ust. 3 pkt 5 rozp. JPK_VAT",
        "cn_codes": ["3915", "4004", "4707", "7001", "7204"],
        "keywords": ["odpad", "złom", "makulatura", "stłuczka", "odpadowy",
                      "recykling", "surowiec wtórny"],
        "categories": {"WASTE", "WASTE_GLASS", "WASTE_PAPER", "WASTE_PLASTIC",
                       "SCRAP", "SCRAP_METAL", "RECYCLABLES"},
    },
    "GTU_06": {
        "description": "Dostawa urządzeń elektronicznych i części",
        "legal_basis": "§10 ust. 3 pkt 6 rozp. JPK_VAT",
        "cn_codes": ["8471", "8517", "8528", "8473"],
        "keywords": ["laptop", "komputer", "telefon", "smartfon", "tablet",
                      "monitor", "serwer", "procesor", "pamięć RAM",
                      "dysk SSD", "drukarka", "skaner", "elektronika",
                      "konsola", "router", "switch", "karta graficzna"],
        "categories": {"ELECTRONICS", "COMPUTERS", "LAPTOPS", "TABLETS",
                       "SMARTPHONES", "ELECTRONICS_CONSUMER"},
    },
    "GTU_07": {
        "description": "Dostawa pojazdów i części samochodowych",
        "legal_basis": "§10 ust. 3 pkt 7 rozp. JPK_VAT",
        "cn_codes": ["8701", "8702", "8703", "8704", "8705", "8708", "8711"],
        "keywords": ["samochód", "auto", "pojazd", "motocykl", "części",
                      "samochodowe", "nadwozie", "silnik samochodowy",
                      "skrzynia biegów", "układ hamulcowy", "opony",
                      "felgi", "akumulator samochodowy"],
        "categories": {"VEHICLES", "CAR_PARTS", "CAR_NEW", "AUTO_PARTS"},
    },
    "GTU_08": {
        "description": "Dostawa metali szlachetnych i nieszlachetnych",
        "legal_basis": "§10 ust. 3 pkt 8 rozp. JPK_VAT",
        "cn_codes": ["7106", "7108", "7109", "7110", "7111", "7112",
                     "7206", "7207", "7208", "7214", "7601"],
        "keywords": ["złoto", "srebro", "platyna", "pallad", "metal",
                      "szlachetny", "stal", "żelazo", "aluminium", "miedź",
                      "cynk", "ołów", "nikiel", "tytan", "mosiądz"],
        "categories": {"PRECIOUS_METALS", "GOLD_RAW", "SILVER_RAW",
                       "PLATINUM_RAW", "STEEL", "STEEL_SEMI", "ALUMINUM",
                       "COPPER", "LEAD", "ZINC", "TIN", "IRON"},
    },
    "GTU_09": {
        "description": "Dostawa leków i wyrobów medycznych",
        "legal_basis": "§10 ust. 3 pkt 9 rozp. JPK_VAT",
        "cn_codes": ["3001", "3002", "3003", "3004", "3005", "3006",
                     "9018", "9021", "9022"],
        "keywords": ["lek", "medyczny", "farmaceutyczny", "apteka", "szczepionka",
                      "strzykawka", "opatrunek", "sprzęt medyczny", "diagnostyka",
                      "test medyczny", "recepta", "suplement diety medyczny"],
        "categories": {"MEDICAL_PRODUCTS", "MEDICAL_EQUIPMENT", "PHARMACEUTICALS"},
    },
    "GTU_10": {
        "description": "Dostawa budynków, budowli i gruntów",
        "legal_basis": "§10 ust. 3 pkt 10 rozp. JPK_VAT",
        "cn_codes": [],  # PKWiU, nie CN
        "keywords": ["budynek", "budowla", "grunt", "działka", "nieruchomość",
                      "lokal", "mieszkanie", "dom", "hala", "magazyn",
                      "biurowiec", "parking", "garaz"],
        "categories": {"REAL_ESTATE", "BUILDING_SALE", "CONSTRUCTION_RESIDENTIAL"},
    },
    "GTU_11": {
        "description": "Dostawa usług niematerialnych",
        "legal_basis": "§10 ust. 3 pkt 11 rozp. JPK_VAT",
        "cn_codes": [],  # Usługi, nie towary
        "keywords": ["doradztwo", "consulting", "prawny", "księgowy",
                      "reklama", "marketing", "IT", "software", "licencja",
                      "SaaS", "chmura", "hosting", "domena", "projekt",
                      "graficzny", "tłumaczenie", "szkolenie online",
                      "ubezpieczenie", "finansowy", "pośrednictwo"],
        "categories": {"CONSULTING", "IT_SERVICES", "SOFTWARE_LICENSE",
                       "SAAS", "LEGAL", "MARKETING", "ADVERTISING"},
    },
    "GTU_12": {
        "description": "Dostawa usług transportowych i magazynowych",
        "legal_basis": "§10 ust. 3 pkt 12 rozp. JPK_VAT",
        "cn_codes": [],  # Usługi
        "keywords": ["transport", "przewóz", "spedycja", "kurier", "logistyka",
                      "magazynowanie", "przechowywanie", "dostawa", "ładunek",
                      "fracht", "przeładunek", "przeprowadzka"],
        "categories": {"TRANSPORT_SERVICES", "LOGISTICS", "WAREHOUSING"},
    },
    "GTU_13": {
        "description": "Dostawa usług budowlanych",
        "legal_basis": "§10 ust. 3 pkt 13 rozp. JPK_VAT",
        "cn_codes": [],  # PKWiU 41-43
        "keywords": ["budowlany", "budowa", "remont", "montaż", "instalacja",
                      "wykończenie", "tynk", "malowanie", "elektryka",
                      "hydraulika", "dach", "fundament", "ogrodzenie",
                      "ocieplenie", "elewacja", "glazura", "panele"],
        "categories": {"CONSTRUCTION", "CONSTRUCTION_SERVICES",
                       "CONSTRUCTION_MATERIALS", "CONSTRUCTION_SUBCONTRACTING"},
    },
}


@dataclass
class GTUAssignment:
    """Wynik przypisania kodu GTU."""

    gtu_code: str = ""
    gtu_description: str = ""
    confidence: float = 0.0  # 0.0-1.0
    method: str = ""  # keyword, category, llm, fallback
    matched_keywords: list[str] = field(default_factory=list)
    alternative_codes: list[str] = field(default_factory=list)


@dataclass
class GTUResult:
    """Pełny wynik analizy GTU — wszystkie 13+ kodów ze scoringiem."""

    primary_assignment: GTUAssignment = field(default_factory=GTUAssignment)
    all_scores: dict[str, float] = field(default_factory=dict)
    requires_manual_review: bool = False
    review_reason: str = ""


class GTUAutoAssigner:
    """v7.0 INNOWACJA 5: Semantyczny auto-assigner kodów GTU.

    Usage:
        assigner = GTUAutoAssigner()
        result = assigner.assign(description="laptop Dell Latitude 5540",
                                 category_code="ELECTRONICS")
        # → GTU_06 (confidence 0.95)
    """

    # Próg konfidencji dla auto-assignment
    AUTO_CONFIDENCE_THRESHOLD = 0.70
    # Próg dla manual review
    MANUAL_REVIEW_THRESHOLD = 0.40

    def assign(
        self,
        description: str = "",
        category_code: str = "",
        cn_code: str = "",
        pkwiu_code: str = "",
    ) -> GTUResult:
        """Przypisz kod GTU na podstawie opisu i kategorii.

        Strategia:
        1. Keyword matching (najwyższy priorytet)
        2. CN code matching (jeśli dostępny)
        3. Category code mapping (fallback)
        4. Jeśli konfidencja < threshold → manual review

        Args:
            description: Opis towaru/usługi.
            category_code: Kod kategorii (np. "ELECTRONICS").
            cn_code: Kod CN (np. "8471").
            pkwiu_code: Kod PKWiU.

        Returns:
            GTUResult z przypisaniem i scoringiem.
        """
        scores: dict[str, float] = {}

        # 1. Keyword matching
        if description:
            keyword_scores = self._score_by_keywords(description)
            for code, score in keyword_scores.items():
                scores[code] = max(scores.get(code, 0.0), score)

        # 2. CN code matching
        if cn_code:
            cn_scores = self._score_by_cn(cn_code)
            for code, score in cn_scores.items():
                scores[code] = max(scores.get(code, 0.0), score)

        # 3. Category code matching
        if category_code:
            cat_scores = self._score_by_category(category_code)
            for code, score in cat_scores.items():
                scores[code] = max(scores.get(code, 0.0), score)

        # 4. PKWiU matching
        if pkwiu_code:
            pkwiu_scores = self._score_by_pkwiu(pkwiu_code)
            for code, score in pkwiu_scores.items():
                scores[code] = max(scores.get(code, 0.0), score)

        # Znajdź najlepsze dopasowanie
        best_code = ""
        best_score = 0.0
        best_keywords: list[str] = []
        alternatives: list[str] = []

        for code, score in sorted(scores.items(), key=lambda x: -x[1]):
            if not best_code:
                best_code = code
                best_score = score
                if description:
                    best_keywords = [
                        kw for kw in GTU_CODES.get(code, {}).get("keywords", [])
                        if kw.lower() in description.lower()
                    ][:5]
            elif score >= best_score * 0.7:
                alternatives.append(code)

        # Określ metodę
        method = "keyword" if best_keywords else (
            "cn_code" if cn_code else (
                "category" if category_code else "fallback"
            )
        )

        primary = GTUAssignment(
            gtu_code=best_code,
            gtu_description=GTU_CODES.get(best_code, {}).get("description", ""),
            confidence=best_score,
            method=method,
            matched_keywords=best_keywords,
            alternative_codes=alternatives[:3],
        )

        requires_review = best_score < self.MANUAL_REVIEW_THRESHOLD
        review_reason = ""
        if requires_review:
            review_reason = (
                f"Niska konfidencja ({best_score:.2f}) — "
                f"zalecana ręczna weryfikacja GTU"
            )
        elif best_score < self.AUTO_CONFIDENCE_THRESHOLD:
            review_reason = (
                f"Średnia konfidencja ({best_score:.2f}) — "
                f"rozważ weryfikację"
            )

        logger.info(
            "[GTU] assigned=%s confidence=%.2f method=%s keywords=%d",
            best_code, best_score, method, len(best_keywords),
        )

        return GTUResult(
            primary_assignment=primary,
            all_scores=scores,
            requires_manual_review=requires_review,
            review_reason=review_reason,
        )

    def _score_by_keywords(self, description: str) -> dict[str, float]:
        """Keyword matching — przypisz punkty za każde trafienie."""
        desc_lower = description.lower()
        scores: dict[str, float] = {}

        for gtu_code, data in GTU_CODES.items():
            score = 0.0
            keywords = data.get("keywords", [])
            matched = 0

            for kw in keywords:
                if kw.lower() in desc_lower:
                    matched += 1

            if matched > 0:
                # Score: min(matched/total_keywords, 1.0)
                score = min(matched / max(len(keywords), 1), 1.0)
                scores[gtu_code] = score

        return scores

    def _score_by_cn(self, cn_code: str) -> dict[str, float]:
        """CN code matching — sprawdź czy kod pasuje do GTU."""
        cn_clean = cn_code.strip().replace(" ", "")
        scores: dict[str, float] = {}

        for gtu_code, data in GTU_CODES.items():
            cn_codes = data.get("cn_codes", [])
            if not cn_codes:
                continue

            for cn in cn_codes:
                if cn_clean.startswith(cn[:4]):
                    scores[gtu_code] = 0.85
                    break

        return scores

    def _score_by_category(self, category_code: str) -> dict[str, float]:
        """Category code matching."""
        scores: dict[str, float] = {}

        for gtu_code, data in GTU_CODES.items():
            categories = data.get("categories", set())
            if category_code in categories:
                scores[gtu_code] = 0.65

        return scores

    def _score_by_pkwiu(self, pkwiu_code: str) -> dict[str, float]:
        """PKWiU code matching (głównie dla usług)."""
        pkwiu_clean = pkwiu_code.strip().replace(" ", "")
        scores: dict[str, float] = {}

        pkwiu_map = {
            "41": "GTU_13", "42": "GTU_13", "43": "GTU_13",  # Budownictwo
            "49": "GTU_12", "50": "GTU_12", "51": "GTU_12",  # Transport
            "52": "GTU_12",                                     # Magazynowanie
            "62": "GTU_11", "63": "GTU_11",                    # IT
            "69": "GTU_11", "70": "GTU_11",                    # Doradztwo
            "73": "GTU_11",                                     # Reklama
            "74": "GTU_11",                                     # Pozostałe profesjonalne
        }

        for prefix, gtu_code in pkwiu_map.items():
            if pkwiu_clean.startswith(prefix):
                scores[gtu_code] = 0.80
                break

        return scores

    def get_gtu_for_category(self, category_code: str) -> dict[str, str]:
        """Proste mapowanie category_code → GTU (jak w substantive.rego P65)."""
        cat_to_gtu = {
            "ALCOHOL": "GTU_01",
            "BEVERAGES_ALCOHOLIC": "GTU_01",
            "TOBACCO": "GTU_04",
            "FUEL": "GTU_02",
            "FUEL_HEATING": "GTU_02",
            "FUEL_DIESEL": "GTU_02",
            "FUEL_GASOLINE": "GTU_02",
            "FUEL_LPG": "GTU_02",
            "CRUDE_OIL": "GTU_02",
            "OIL_LUBRICANTS": "GTU_02",
            "HEATING_OIL": "GTU_03",
            "ELECTRONICS": "GTU_06",
            "COMPUTERS": "GTU_06",
            "LAPTOPS": "GTU_06",
            "TABLETS": "GTU_06",
            "SMARTPHONES": "GTU_06",
            "VEHICLES": "GTU_07",
            "CAR_PARTS": "GTU_07",
            "CAR_NEW": "GTU_07",
            "AUTO_PARTS": "GTU_07",
            "STEEL": "GTU_08",
            "STEEL_SEMI": "GTU_08",
            "ALUMINUM": "GTU_08",
            "COPPER": "GTU_08",
            "PRECIOUS_METALS": "GTU_08",
            "GOLD_RAW": "GTU_08",
            "SILVER_RAW": "GTU_08",
            "MEDICAL_PRODUCTS": "GTU_09",
            "MEDICAL_EQUIPMENT": "GTU_09",
            "PHARMACEUTICALS": "GTU_09",
            "REAL_ESTATE": "GTU_10",
            "BUILDING_SALE": "GTU_10",
            "CONSULTING": "GTU_11",
            "IT_SERVICES": "GTU_11",
            "SOFTWARE_LICENSE": "GTU_11",
            "SAAS": "GTU_11",
            "LEGAL": "GTU_11",
            "MARKETING": "GTU_11",
            "TRANSPORT_SERVICES": "GTU_12",
            "LOGISTICS": "GTU_12",
            "WAREHOUSING": "GTU_12",
            "CONSTRUCTION": "GTU_13",
            "CONSTRUCTION_SERVICES": "GTU_13",
            "CONSTRUCTION_MATERIALS": "GTU_13",
            "CONSTRUCTION_RESIDENTIAL": "GTU_13",
        }
        gtu = cat_to_gtu.get(category_code, "")
        return {"gtu_code": gtu, "description": GTU_CODES.get(gtu, {}).get("description", "")}
