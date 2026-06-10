"""
DecisionEngine — SQL/DuckDB-based decision engine.

Zgodnie z aa3fvcx.txt:
- DuckDB (Punkt 3): "First-match-wins w SQL" — reguły decyzyjne w DuckDB
- SQLite (Punkt 3): dane transakcyjne faktur i kontrahentów
- TigerBeetle (Punkt 9): integralność finansowa
- sqlite-vec (Punkt 3): wyszukiwanie semantyczne

Zastępuje:
- Council of Agents (Alpha/Beta/Gamma) — logika walidacji → DuckDB rules
- WorkflowPlanner — klasyfikacja simple/complex → SQL conditions
- JambaStrategist — decyzja strategiczna → matryca decyzyjna w DuckDB
- Rules SWAT Team — kaskada reguł → hierarchiczne reguły w DuckDB
- TrustScoreCalculator — 5-składnikowy trust score → SQL aggregation
- PLE Engine — pamięć → dane historyczne w SQLite/DuckDB
- BayesianThresholdLearner — adaptacja progów → DuckDB stats
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any
from uuid import uuid4
import pendulum

from nexus_ai.core.cache import get_cache
from nexus_ai.core.msgspec_utils import msgspec_dumps, msgspec_loads
from nexus_ai.db.analytics import DuckDBManager
from nexus_ai.db.models import Invoice

# NexusCache dla decision_rules (event-based invalidation)
# Brak TTL — cache unieważniany przy każdej zmianie reguł przez API
# Klucz: decision_rules:active — lista aktywnych reguł (list[dict])
_rules_cache = get_cache()
CACHE_KEY = "decision_rules:active"


def invalidate_rules_cache() -> None:
    """Unieważnij cache reguł decyzyjnych.

    Wywoływana przy każdej zmianie reguł (add_rule, deprecate_rule, _seed_defaults).
    Następne wywołanie _get_active_rules() załaduje świeże reguły z DuckDB.
    """
    _rules_cache.delete_sync(CACHE_KEY)


# =========================================================================
# Decision data structures
# =========================================================================

@dataclass(slots=True)
class DecisionVerdict:
    """Decision result from the engine."""
    decision: str           # AUTO_POST | SUGGEST | ASK_USER | BLOCK
    confidence: float       # 0.0 – 1.0
    reasoning: str
    matched_rule: str = ""
    risk_override: bool = False
    semantic_anomaly: bool = False

    def to_dict(self) -> dict[str, Any]:
        return {
            "decision": self.decision,
            "confidence": self.confidence,
            "reasoning": self.reasoning,
            "matched_rule": self.matched_rule,
            "risk_override": self.risk_override,
            "semantic_anomaly": self.semantic_anomaly,
        }


# =========================================================================
# DecisionEngine — SQL-based decision making
# =========================================================================

DECISION_RULES_SCHEMA = """
CREATE TABLE IF NOT EXISTS decision_rules (
    rule_id       VARCHAR PRIMARY KEY,
    condition_json VARCHAR NOT NULL,
    output_json   VARCHAR NOT NULL,
    priority      INTEGER NOT NULL DEFAULT 100,
    valid_from    DATE NOT NULL,
    valid_to      DATE,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_decision_rules_valid
    ON decision_rules(valid_from, valid_to, priority);
"""

DEFAULT_DECISION_RULES: list[dict[str, Any]] = [
    # ---- level 1: Auto-post for trusted vendors ----
    {
        "condition": {"vendor_known": True, "vendor_invoice_count__gte": 10, "vendor_trust__gte": 0.85, "amount_gross__lte": 5000, "ocr_confidence__gte": 0.92},
        "output": {"decision": "AUTO_POST", "confidence": 0.95, "reasoning": "Zaufany kontrahent, niska kwota, wysoki OCR"},
        "priority": 10,
    },
    {
        "condition": {"vendor_known": True, "vendor_invoice_count__gte": 3, "vendor_trust__gte": 0.80, "amount_gross__lte": 3000, "ocr_confidence__gte": 0.90},
        "output": {"decision": "AUTO_POST", "confidence": 0.90, "reasoning": "Znany kontrahent, niska kwota"},
        "priority": 20,
    },
    # ---- level 2: Suggest ----
    {
        "condition": {"vendor_known": True, "amount_gross__lte": 10000, "ocr_confidence__gte": 0.85},
        "output": {"decision": "SUGGEST", "confidence": 0.80, "reasoning": "Znany kontrahent, średnia kwota"},
        "priority": 30,
    },
    {
        "condition": {"vendor_known": False, "amount_gross__lte": 5000, "ocr_confidence__gte": 0.90},
        "output": {"decision": "SUGGEST", "confidence": 0.75, "reasoning": "Nowy kontrahent ale niska kwota i wysoki OCR"},
        "priority": 40,
    },
    # ---- level 3: Ask user ----
    {
        "condition": {"amount_gross__lte": 50000, "ocr_confidence__gte": 0.80},
        "output": {"decision": "ASK_USER", "confidence": 0.60, "reasoning": "Średnia kwota lub nieznany kontrahent"},
        "priority": 50,
    },
    # ---- level 4: Block ----
    {
        "condition": {"amount_gross__gte": 50000},
        "output": {"decision": "BLOCK", "confidence": 0.40, "reasoning": "Wysoka kwota — wymagana ręczna weryfikacja"},
        "priority": 100,
    },
    # ---- fallback ----
    {
        "condition": {},
        "output": {"decision": "ASK_USER", "confidence": 0.50, "reasoning": "Brak pasującej reguły — eskaluj"},
        "priority": 999,
    },
]


class DecisionEngine:
    """SQL/DuckDB-based decision engine.

    Replaces all LLM agents with deterministic SQL rules.
    Uses DuckDB for first-match-wins rule matching.

    Args:
        duckdb: DuckDBManager for rule storage and analytics.
    """

    def __init__(self, duckdb: DuckDBManager | None = None) -> None:
        self._duckdb = duckdb
        if duckdb:
            self._ensure_schema()
            self._seed_defaults()

    def _ensure_schema(self) -> None:
        """Create decision_rules table."""
        if not self._duckdb:
            return
        self._duckdb.execute(DECISION_RULES_SCHEMA)

    def _seed_defaults(self) -> None:
        """Insert default decision rules if table is empty."""
        if not self._duckdb:
            return
        count = self._duckdb.execute("SELECT COUNT(1) FROM decision_rules")
        if count and count[0][0] > 0:
            return
        for rule in DEFAULT_DECISION_RULES:
            self._duckdb.execute(
                """INSERT INTO decision_rules
                   (rule_id, condition_json, output_json, priority, valid_from, created_by)
                   VALUES (?, ?, ?, ?, ?, ?)""",
                (
                    str(uuid4()),
                    msgspec_dumps(rule["condition"]),
                    msgspec_dumps(rule["output"]),
                    rule["priority"],
                    pendulum.now("UTC").date().isoformat(),
                    "system",
                ),
            )
        # Unieważnij cache — świeże reguły w DuckDB
        invalidate_rules_cache()

    def decide(
        self,
        invoice_data: dict[str, Any],
        vendor_profile: dict[str, Any] | None = None,
    ) -> DecisionVerdict:
        """Make decision based on invoice data using SQL rules.

        Uses first-match-wins: rules are ordered by priority,
        first matching rule determines the decision.

        Args:
            invoice_data: Invoice data dict.
            vendor_profile: Optional vendor profile.

        Returns:
            DecisionVerdict with decision and confidence.
        """
        vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}

        # Extract features for rule matching
        features = {
            "vendor_known": bool(vendor.get("known", False)),
            "vendor_invoice_count": int(vendor.get("invoice_count", 0)),
            "vendor_trust": float(vendor.get("trust_score", 0.5)),
            "amount_gross": float(invoice_data.get("amount_gross", 0) or 0),
            "amount_net": float(invoice_data.get("amount_net", 0) or 0),
            "ocr_confidence": float(invoice_data.get("ocr_confidence", 0.5)),
            "category": str(invoice_data.get("category", "")),
        }

        # Match rules by priority (first-match-wins)
        rules = self._get_active_rules()
        for rule in rules:
            condition = rule.get("condition", {})
            if self._match_condition(condition, features):
                output = rule.get("output", {})
                return DecisionVerdict(
                    decision=output.get("decision", "ASK_USER"),
                    confidence=float(output.get("confidence", 0.5)),
                    reasoning=output.get("reasoning", ""),
                    matched_rule=rule.get("rule_id", ""),
                )

        # Fallback
        return DecisionVerdict(
            decision="ASK_USER",
            confidence=0.5,
            reasoning="No matching rule — escalate",
        )

    def _get_active_rules(self) -> list[dict[str, Any]]:
        """Get active decision rules ordered by priority.

        Cache'owane w NexusCache (event-based invalidation).
        Cache unieważniany przez invalidate_rules_cache() przy każdej
        zmianie reguł (add_rule, deprecate_rule, seed) — nigdy nie wygasa
        sam z siebie. Gwarantuje to świeżość reguł bez opóźnienia TTL.
        """
        # Sprawdź NexusCache (L1 RAM) — szybki path bez DuckDB
        cached = _rules_cache.get_sync(CACHE_KEY)
        if cached is not None:
            return cached

        if not self._duckdb:
            return DEFAULT_DECISION_RULES
        try:
            rows = self._duckdb.execute(
                """SELECT condition_json, output_json, rule_id, priority
                   FROM decision_rules
                   WHERE valid_from <= CURRENT_DATE
                     AND (valid_to IS NULL OR valid_to >= CURRENT_DATE)
                   ORDER BY priority ASC"""
            )
            if not rows:
                _rules_cache.set_sync(CACHE_KEY, DEFAULT_DECISION_RULES)
                return DEFAULT_DECISION_RULES
            rules = [
                {
                    "condition": msgspec_loads(r[0]) if isinstance(r[0], str) else r[0],
                    "output": msgspec_loads(r[1]) if isinstance(r[1], str) else r[1],
                    "rule_id": str(r[2]),
                    "priority": int(r[3]),
                }
                for r in rows
            ]
            # Zapisz w NexusCache (bez TTL — unieważniamy ręcznie)
            _rules_cache.set_sync(CACHE_KEY, rules)
            return rules
        except Exception:
            return DEFAULT_DECISION_RULES

    # ── Rule CRUD (z event-based cache invalidation) ────────────────────

    def add_rule(
        self,
        condition: dict[str, Any],
        output: dict[str, Any],
        priority: int = 100,
        valid_from: str | None = None,
        valid_to: str | None = None,
        created_by: str = "admin",
    ) -> str | None:
        """Dodaj nową regułę decyzyjną i unieważnij cache."""
        if not self._duckdb:
            return None
        rule_id = str(uuid4())
        try:
            self._duckdb.execute(
                """INSERT INTO decision_rules
                   (rule_id, condition_json, output_json, priority, valid_from, valid_to, created_by)
                   VALUES (?, ?, ?, ?, ?, ?, ?)""",
                (
                    rule_id,
                    msgspec_dumps(condition),
                    msgspec_dumps(output),
                    priority,
                    valid_from or pendulum.now("UTC").date().isoformat(),
                    valid_to,
                    created_by,
                ),
            )
            invalidate_rules_cache()
            return rule_id
        except Exception:
            return None

    def deprecate_rule(self, rule_id: str) -> bool:
        """Dezaktywuj regułę przez ustawienie valid_to = dzisiaj i unieważnij cache."""
        if not self._duckdb:
            return False
        try:
            today = pendulum.now("UTC").date().isoformat()
            result = self._duckdb.execute(
                "UPDATE decision_rules SET valid_to = CAST(? AS DATE) "
                "WHERE rule_id = ? AND valid_to IS NULL",
                (today, rule_id),
            )
            invalidate_rules_cache()
            return bool(result)
        except Exception:
            return False

    @staticmethod
    def _match_condition(condition: dict[str, Any], features: dict[str, Any]) -> bool:
        """Check if a condition matches the feature set.

        Supports operators:
        - field_name: exact match
        - field_name__gte: greater than or equal
        - field_name__lte: less than or equal
        - field_name__in: in list
        """
        if not condition:
            return True  # Empty condition matches everything (fallback)

        for key, expected in condition.items():
            # Parse operator
            if "__gte" in key:
                field = key.replace("__gte", "")
                actual = features.get(field, 0)
                if actual < float(expected):
                    return False
            elif "__lte" in key:
                field = key.replace("__lte", "")
                actual = features.get(field, float("inf"))
                if actual > float(expected):
                    return False
            elif "__in" in key:
                field = key.replace("__in", "")
                actual = features.get(field, "")
                if actual not in expected:
                    return False
            else:
                actual = features.get(key)
                if actual != expected:
                    return False
        return True


# =========================================================================
# InvoiceClassifier — simple vs complex (replaces WorkflowPlanner)
# =========================================================================

def classify_invoice(invoice_data: dict[str, Any], vendor_profile: dict[str, Any] | None = None) -> str:
    """Classify invoice as simple or complex using SQL-like conditions.

    Zgodnie z aa3fvcx.txt: deterministyczne reguły, bez LLM.

    Returns:
        "simple" or "complex"
    """
    vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}
    amount = float(invoice_data.get("amount_gross", 0) or 0)
    ocr_conf = float(invoice_data.get("ocr_confidence", 0.5))
    vendor_known = bool(vendor.get("known", False))
    vendor_count = int(vendor.get("invoice_count", 0))

    # Simple: niska kwota, znany kontrahent, wysoki OCR
    if amount <= 5000 and vendor_known and vendor_count >= 3 and ocr_conf >= 0.85:
        return "simple"
    return "complex"


# =========================================================================
# TrustScore — SQL-based trust calculation (replaces TrustScoreCalculator)
# =========================================================================

TRUST_WEIGHTS = {
    "ocr_confidence": 0.30,
    "vendor_reliability": 0.25,
    "data_consistency": 0.20,
    "context_trust": 0.10,
    "risk_guard": 0.15,
}


def calculate_trust_score(
    invoice_data: dict[str, Any],
    vendor_profile: dict[str, Any] | None = None,
) -> dict[str, Any]:
    """Calculate trust score using weighted components.

    Zgodnie z aa3fvcx.txt: statystyczne ważenie, bez LLM.

    Returns:
        Dict with trust_score and components.
    """
    vendor = vendor_profile or invoice_data.get("vendor_profile", {}) or {}

    ocr = float(invoice_data.get("ocr_confidence", 0.5))

    v_known = 1.0 if vendor.get("known", False) else 0.0
    v_count = min(float(vendor.get("invoice_count", 0)) / 10.0, 1.0)
    v_trust = float(vendor.get("trust_score", 0.5))
    vendor_score = v_known * 0.30 + v_count * 0.25 + v_trust * 0.30 + 0.15

    net = float(invoice_data.get("amount_net", 0) or 0)
    vat = float(invoice_data.get("vat", 0) or 0)
    gross = float(invoice_data.get("amount_gross", 0) or 0)
    math_ok = 1.0 if abs((net + vat) - gross) <= 0.01 else 0.0
    data_score = math_ok * 0.50 + 0.50

    trust = (
        ocr * TRUST_WEIGHTS["ocr_confidence"]
        + vendor_score * TRUST_WEIGHTS["vendor_reliability"]
        + data_score * TRUST_WEIGHTS["data_consistency"]
        + 0.60 * TRUST_WEIGHTS["context_trust"]
        + 1.0 * TRUST_WEIGHTS["risk_guard"]
    )

    return {
        "trust_score": round(min(max(trust, 0.0), 1.0), 4),
        "components": {
            "ocr_confidence": round(ocr, 4),
            "vendor_reliability": round(vendor_score, 4),
            "data_consistency": round(data_score, 4),
            "context_trust": 0.60,
            "risk_guard": 1.0,
        },
    }



