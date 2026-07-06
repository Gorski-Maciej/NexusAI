"""Agent Knowledge Mesh — Samoucząca się Siatka Wiedzy Agentów.

Zgodnie z RAPORT_TECHNOLOGII_NEXUSAI.txt:
  - DuckDB — Collective Bayesian Field + Experience Replay
  - sqlite-vec — embeddingi dla Cross-Agent Experience Replay (k-NN)
  - msgspec — wszystkie struktury danych
  - NATS JetStream — publikacja eventów Mesh
  - stamina — Circuit Breaker na poziomie agenta
"""

from __future__ import annotations

import json
from typing import Any

import pendulum
from msgspec import json as msgspec_json
from structlog import get_logger

from nexus_ai.agents.models import (
    ExperienceRule,
    MeshEvent,
    MeshField,
    RouteDecision,
)
from nexus_ai.core.vectorize import execute_db, execute_db_fetchall, execute_db_fetchone, vectorize_text

logger = get_logger("nexus.agents.mesh")


# ═════════════════════════════════════════════════════════════════════════
# B. COLLECTIVE BAYESIAN FIELD — Warstwa 2
# ═════════════════════════════════════════════════════════════════════════


# Metody pomocnicze dla MeshField i ExperienceRule (rozszerzenia logiki)


def _mesh_field_update(field: MeshField, correct: bool, agent_name: str) -> None:
    """Bayesian update — zwiększ alpha (OK) lub beta (błąd)."""
    if correct:
        field.alpha += 1.0
    else:
        field.beta += 1.0
    field.total_decisions += 1
    if correct:
        field.auto_post_count += 1
    field.last_updated = pendulum.now("UTC").isoformat()
    field.updated_by_agent = agent_name


def _experience_rule_generate_id() -> str:
    """Generuj unikalne ID reguły."""
    import uuid
    return uuid.uuid4().hex[:16]


def _mesh_event_generate_id() -> str:
    """Generuj unikalne ID zdarzenia."""
    import uuid
    return uuid.uuid4().hex[:16]


class CollectiveBayesianField:
    """Współdzielone pole Bayesiańskie — jedna prawda dla wszystkich agentów.

    DuckDB jako trwały magazyn:
      CREATE TABLE mesh_bayesian_field (
        vendor_nip VARCHAR,
        category VARCHAR,
        amount_range VARCHAR,
        alpha DOUBLE DEFAULT 1.0,
        beta DOUBLE DEFAULT 1.0,
        last_updated TIMESTAMP,
        updated_by_agent VARCHAR,
        total_decisions INTEGER DEFAULT 0,
        auto_post_count INTEGER DEFAULT 0,
        correction_count INTEGER DEFAULT 0,
        PRIMARY KEY (vendor_nip, category, amount_range)
      )

    Każdy z 5 agentów aktualizuje to samo pole.
    Gdy Extraction poprawia OCR → Quality automatycznie widzi wyższy Trust.
    """

    def __init__(self, db_path: str | None = None) -> None:
        self._db_path = db_path or "/tmp/nexus-mesh-bayesian.db"
        self._conn: Any = None
        self._cache: dict[str, MeshField] = {}  # RAM cache
        self._initialized = False

    async def initialize(self) -> None:
        """Inicjalizuj DuckDB i utwórz tabelę."""
        if self._initialized:
            return
        try:
            import duckdb
            self._conn = duckdb.connect(self._db_path)
            self._conn.execute("""CREATE TABLE IF NOT EXISTS mesh_bayesian_field (
                vendor_nip VARCHAR NOT NULL, category VARCHAR NOT NULL DEFAULT '',
                amount_range VARCHAR NOT NULL DEFAULT '', alpha DOUBLE DEFAULT 1.0,
                beta DOUBLE DEFAULT 1.0, last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_by_agent VARCHAR DEFAULT '', total_decisions INTEGER DEFAULT 0,
                auto_post_count INTEGER DEFAULT 0, correction_count INTEGER DEFAULT 0,
                PRIMARY KEY (vendor_nip, category, amount_range))""")
            self._conn.execute("CREATE INDEX IF NOT EXISTS idx_mesh_nip ON mesh_bayesian_field(vendor_nip)")
            self._initialized = True
            logger.info("[MESH] CollectiveBayesianField initialized | DB: %s | fields: %d", self._db_path, self.count)
        except Exception as exc:
            logger.warning("[MESH] DuckDB init failed (fallback to RAM): %s", exc)
            self._initialized = True

    @staticmethod
    def _make_key(vendor_nip: str, category: str = "", amount_range: str = "") -> str:
        return f"{vendor_nip}::{category}::{amount_range}"

    @staticmethod
    def _amount_to_range(amount: float) -> str:
        """Konwertuj kwotę na przedział."""
        if amount <= 0:
            return "unknown"
        if amount < 1_000:
            return "micro"
        if amount < 10_000:
            return "small"
        if amount < 50_000:
            return "medium"
        if amount < 100_000:
            return "large"
        return "xlarge"

    async def get_field(
        self,
        vendor_nip: str,
        category: str = "",
        amount: float = 0.0,
    ) -> MeshField:
        """Pobierz lub utwórz pole Bayesiańskie dla danego vendora.

        Priorytet wyszukiwania:
        1. Exact match: NIP + category + amount_range
        2. NIP + amount_range (ignoruj category)
        3. NIP only
        4. Nowe pole (default alpha=1, beta=1)
        """
        amount_range = self._amount_to_range(amount)

        # 1. Exact match
        field = await self._query_field(vendor_nip, category, amount_range)
        if field:
            return field

        # 2. NIP + amount_range
        field = await self._query_field(vendor_nip, "", amount_range)
        if field:
            return field

        # 3. NIP only
        field = await self._query_field(vendor_nip, "", "")
        if field:
            return field

        # 4. Nowe pole
        return MeshField(
            vendor_nip=vendor_nip,
            category=category,
            amount_range=amount_range,
            alpha=1.0,
            beta=1.0,
            last_updated=pendulum.now("UTC").isoformat(),
        )

    async def update_field(
        self,
        vendor_nip: str,
        correct: bool,
        agent_name: str,
        category: str = "",
        amount: float = 0.0,
    ) -> MeshField:
        """Aktualizuj pole Bayesiańskie po decyzji.

        Args:
            vendor_nip: NIP kontrahenta.
            correct: True = poprawna decyzja, False = błędna.
            agent_name: Który agent aktualizuje (np. 'orchestrator').
            category: Kategoria faktury.
            amount: Kwota faktury.

        Returns:
            Zaktualizowane MeshField.
        """
        if not self._initialized:
            await self.initialize()

        amount_range = self._amount_to_range(amount)

        # Pobierz lub utwórz
        field = await self.get_field(vendor_nip, category, amount)
        _mesh_field_update(field, correct, agent_name)

        # Zapisz do DuckDB
        if self._conn:
            try:
                await execute_db(
                    self._conn,
                    "INSERT OR REPLACE INTO mesh_bayesian_field "
                    "(vendor_nip, category, amount_range, alpha, beta, "
                    "last_updated, updated_by_agent, total_decisions, "
                    "auto_post_count, correction_count) "
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    (vendor_nip, category, amount_range, field.alpha, field.beta,
                     field.last_updated, agent_name, field.total_decisions,
                     field.auto_post_count, field.correction_count),
                )
            except Exception as exc:
                logger.debug("[MESH] DuckDB update failed: %s", exc)

        # Cache w RAM
        key = self._make_key(vendor_nip, category, amount_range)
        self._cache[key] = field

        logger.debug(
            "[MESH] Field updated | NIP=%s | agent=%s | trust=%.3f | α=%.0f β=%.0f",
            vendor_nip[:8], agent_name, field.trust_score, field.alpha, field.beta,
        )
        return field

    async def get_aggregate_trust(
        self,
        vendor_nip: str,
        amount: float = 0.0,
    ) -> tuple[float, float, int]:
        """Pobierz zagregowany Trust Score dla vendora (ważony po przedziałach).

        Returns:
            (trust_score, confidence, total_decisions)
        """
        if not self._conn:
            return (0.5, 0.0, 0)

        try:
            row = await execute_db_fetchone(
                self._conn,
                "SELECT SUM(alpha) as total_alpha, SUM(beta) as total_beta, "
                "SUM(total_decisions) as total_dec FROM mesh_bayesian_field WHERE vendor_nip = ?",
                (vendor_nip,),
            )
            rows = (row,) if row else None
            if rows and rows[0] is not None:
                alpha = float(rows[0])
                beta = float(rows[1])
                total_dec = int(rows[2])
                total = alpha + beta
                trust = alpha / total if total > 0 else 0.5
                variance = (alpha * beta) / (total**2 * (total + 1)) if total > 1 else 1.0
                confidence = max(0.0, 1.0 - variance * 12)
                return (trust, confidence, total_dec)
        except Exception as exc:
            logger.debug("[MESH] Aggregate query failed: %s", exc)

        return (0.5, 0.0, 0)

    async def _query_field(
        self,
        vendor_nip: str,
        category: str,
        amount_range: str,
    ) -> MeshField | None:
        """Zapytaj DuckDB o pole."""
        # Najpierw cache
        key = self._make_key(vendor_nip, category, amount_range)
        if key in self._cache:
            return self._cache[key]

        if not self._conn:
            return None

        try:
            row = await execute_db_fetchone(
                self._conn,
                "SELECT vendor_nip, category, amount_range, alpha, beta, "
                "last_updated, updated_by_agent, total_decisions, "
                "auto_post_count, correction_count FROM mesh_bayesian_field "
                "WHERE vendor_nip = ? AND category = ? AND amount_range = ?",
                (vendor_nip, category, amount_range),
            )
            if row:
                field = MeshField(
                    vendor_nip=str(row[0]),
                    category=str(row[1]),
                    amount_range=str(row[2]),
                    alpha=float(row[3]),
                    beta=float(row[4]),
                    last_updated=str(row[5]) if row[5] else "",
                    updated_by_agent=str(row[6]),
                    total_decisions=int(row[7]) if row[7] else 0,
                    auto_post_count=int(row[8]) if row[8] else 0,
                    correction_count=int(row[9]) if row[9] else 0,
                )
                self._cache[key] = field
                return field
        except Exception as exc:
            logger.debug("[MESH] Query field failed: %s", exc)

        return None

    @property
    def count(self) -> int:
        if self._conn:
            try:
                row = self._conn.execute("SELECT COUNT(*) FROM mesh_bayesian_field").fetchone()
                return int(row[0]) if row else 0
            except Exception:
                return 0
        return len(self._cache)

    async def close(self) -> None:
        if self._conn:
            try:
                self._conn.close()
            except Exception as exc:
                logger.debug("[MESH] Bayesian close failed: %s", exc)
            self._conn = None


# ═════════════════════════════════════════════════════════════════════════
# C. CROSS-AGENT EXPERIENCE REPLAY — Warstwa 1
# ═════════════════════════════════════════════════════════════════════════


class CrossAgentExperienceReplay:
    """Replay doświadczeń między agentami.

    Gdy agent A uczy się → automatycznie tworzy reguły dla agentów B, C, D.

    DuckDB:
      CREATE TABLE mesh_experience_replay (
        rule_id VARCHAR PRIMARY KEY,
        source_agent VARCHAR,
        target_agent VARCHAR,
        trigger_condition VARCHAR,
        action VARCHAR,
        params JSON,
        priority INTEGER DEFAULT 5,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        hit_count INTEGER DEFAULT 0,
        last_hit TIMESTAMP,
        embedding FLOAT[768],
        active BOOLEAN DEFAULT TRUE
      )
    """

    # Mapowanie: type_zdarzenia → reguły dla innych agentów
    CROSS_AGENT_RULES: dict[str, list[dict[str, Any]]] = {
        # QualityValidator wykrywa błąd VAT → Extraction + Orchestrator
        "quality.tax_error": [
            {
                "target": "extraction",
                "action": "SET_SCRUTINY_HIGH",
                "params": {"flag": "VAT_SCRUTINY", "duration_days": 90},
                "priority": 1,
            },
            {
                "target": "orchestrator",
                "action": "LOWER_THRESHOLD",
                "params": {"delta": -0.05, "reason": "VAT errors detected by Quality"},
                "priority": 2,
            },
        ],
        # QualityValidator wykrywa fraud → Wszyscy agenci
        "quality.fraud_detected": [
            {
                "target": "extraction",
                "action": "SET_SCRUTINY_HIGH",
                "params": {"flag": "FRAUD_SCRUTINY", "duration_days": 365},
                "priority": 1,
            },
            {
                "target": "orchestrator",
                "action": "FORCE_4EYES",
                "params": {"min_amount": 0},
                "priority": 1,
            },
            {
                "target": "analytics",
                "action": "MONITOR_CLOSELY",
                "params": {"alert_on_any_transaction": True},
                "priority": 2,
            },
        ],
        # Extraction ma niski konsensus OCR → QualityValidator
        "extraction.low_consensus": [
            {
                "target": "quality-validator",
                "action": "INCREASE_SCRUTINY",
                "params": {"fields": ["nip", "amount_gross"], "threshold_multiplier": 1.5},
                "priority": 3,
            },
        ],
        # Orchestrator koryguje decyzję → Extraction + Analytics
        "orchestrator.decision_corrected": [
            {
                "target": "extraction",
                "action": "LEARN_CORRECTION",
                "params": {"source": "orchestrator_feedback"},
                "priority": 2,
            },
            {
                "target": "analytics",
                "action": "UPDATE_VENDOR_PROFILE",
                "params": {"source": "orchestrator_feedback"},
                "priority": 3,
            },
        ],
        # Analytics wykrywa anomalię → QualityValidator + Orchestrator
        "analytics.anomaly_detected": [
            {
                "target": "quality-validator",
                "action": "TRIGGER_DEEP_CHECK",
                "params": {"checks": ["tax", "fraud", "esg", "forecast"]},
                "priority": 2,
            },
            {
                "target": "orchestrator",
                "action": "LOWER_THRESHOLD",
                "params": {"delta": -0.08, "reason": "Anomaly detected by Analytics"},
                "priority": 2,
            },
        ],
    }

    def __init__(self, db_path: str | None = None) -> None:
        self._db_path = db_path or "/tmp/nexus-mesh-experience.db"
        self._conn: Any = None
        self._rules: dict[str, ExperienceRule] = {}
        self._initialized = False

    async def initialize(self) -> None:
        if self._initialized:
            return
        try:
            import duckdb
            self._conn = duckdb.connect(self._db_path)
            self._conn.execute("""CREATE TABLE IF NOT EXISTS mesh_experience_replay (
                rule_id VARCHAR PRIMARY KEY, source_agent VARCHAR NOT NULL,
                target_agent VARCHAR NOT NULL, trigger_condition VARCHAR NOT NULL,
                action VARCHAR NOT NULL, params JSON DEFAULT '{}',
                priority INTEGER DEFAULT 5, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                hit_count INTEGER DEFAULT 0, last_hit TIMESTAMP,
                embedding FLOAT[768], active BOOLEAN DEFAULT TRUE)""")
            self._conn.execute("CREATE INDEX IF NOT EXISTS idx_mesh_replay_target ON mesh_experience_replay(target_agent, active)")
            self._initialized = True
            logger.info("[MESH] CrossAgentExperienceReplay initialized | rules: %d", self.count)
        except Exception as exc:
            logger.warning("[MESH] Experience Replay init failed (fallback to RAM): %s", exc)
            self._initialized = True

    async def record_experience(
        self,
        event_type: str,
        source_agent: str,
        vendor_nip: str,
        category: str = "",
        amount: float = 0.0,
        details: dict[str, Any] | None = None,
    ) -> list[ExperienceRule]:
        """Zapisz doświadczenie i wygeneruj reguły Cross-Agent.

        Gdy agent źródłowy wykryje zdarzenie (np. 'quality.tax_error'),
        automatycznie tworzy reguły dla innych agentów według CROSS_AGENT_RULES.

        Args:
            event_type: Typ zdarzenia (np. 'quality.tax_error').
            source_agent: Agent źródłowy.
            vendor_nip: NIP kontrahenta.
            category: Kategoria.
            amount: Kwota.
            details: Dodatkowe szczegóły.

        Returns:
            Lista utworzonych reguł ExperienceRule.
        """
        if not self._initialized:
            await self.initialize()

        templates = self.CROSS_AGENT_RULES.get(event_type, [])
        if not templates:
            logger.debug("[MESH] No cross-agent rules for event: %s", event_type)
            return []

        created_rules: list[ExperienceRule] = []

        for template in templates:
            rule = ExperienceRule(
                rule_id=_experience_rule_generate_id(),
                source_agent=source_agent,
                target_agent=template["target"],
                trigger_condition=f"vendor_nip == '{vendor_nip}'",
                action=template["action"],
                params=template.get("params", {}),
                priority=template.get("priority", 5),
                created_at=pendulum.now("UTC").isoformat(),
                hit_count=0,
            )

            # Dodaj embedding dla k-NN
            rule.embedding = vectorize_text(vendor_nip, category, source_agent, template["target"], rule.action)

            # Zapisz do DuckDB
            if self._conn:
                try:
                    await execute_db(
                        self._conn,
                        "INSERT INTO mesh_experience_replay "
                        "(rule_id, source_agent, target_agent, trigger_condition, "
                        "action, params, priority, created_at, hit_count, embedding, active) "
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        (rule.rule_id, rule.source_agent, rule.target_agent,
                         rule.trigger_condition, rule.action,
                         json.dumps(rule.params), rule.priority,
                         rule.created_at, rule.hit_count,
                         rule.embedding, rule.active),
                    )
                except Exception as exc:
                    logger.debug("[MESH] Insert rule failed: %s", exc)

            # Cache w RAM
            self._rules[rule.rule_id] = rule
            created_rules.append(rule)

        if created_rules:
            logger.info(
                "[MESH] 📡 Cross-Agent Experience Replay | event=%s | source=%s → %d rules for %d targets",
                event_type, source_agent, len(created_rules),
                len(set(r.target_agent for r in created_rules)),
            )

        return created_rules

    async def get_rules_for_agent(
        self,
        target_agent: str,
        vendor_nip: str = "",
        category: str = "",
        max_rules: int = 10,
    ) -> list[ExperienceRule]:
        """Pobierz aktywne reguły dla danego agenta.

        Args:
            target_agent: Agent docelowy (np. 'extraction').
            vendor_nip: Filtruj po NIP (opcjonalnie).
            category: Filtruj po kategorii (opcjonalnie).
            max_rules: Maksymalna liczba reguł.

        Returns:
            Lista reguł posortowana po priorytecie.
        """
        if not self._conn:
            # Fallback: przeszukaj RAM
            rules = [
                r for r in self._rules.values()
                if r.target_agent == target_agent and r.active
            ]
            if vendor_nip:
                rules = [r for r in rules if vendor_nip in r.trigger_condition]
            rules.sort(key=lambda r: r.priority)
            return rules[:max_rules]

        try:
            sql = "SELECT rule_id, source_agent, target_agent, trigger_condition, " \
                  "action, params, priority, created_at, hit_count, last_hit, active " \
                  "FROM mesh_experience_replay WHERE target_agent = ? AND active = TRUE"
            params: list[Any] = [target_agent]
            if vendor_nip:
                sql += " AND trigger_condition LIKE ?"; params.append(f"%{vendor_nip}%")
            sql += " ORDER BY priority ASC, hit_count DESC LIMIT ?"; params.append(max_rules)
            rows = await execute_db_fetchall(self._conn, sql, params)

            rules = []
            for row in rows:
                parsed_params = {}
                try:
                    if row[5]:
                        parsed_params = json.loads(str(row[5])) if isinstance(row[5], str) else row[5]
                except (json.JSONDecodeError, TypeError):
                    pass

                rules.append(ExperienceRule(
                    rule_id=str(row[0]),
                    source_agent=str(row[1]),
                    target_agent=str(row[2]),
                    trigger_condition=str(row[3]),
                    action=str(row[4]),
                    params=parsed_params,
                    priority=int(row[6]) if row[6] else 5,
                    created_at=str(row[7]) if row[7] else "",
                    hit_count=int(row[8]) if row[8] else 0,
                    last_hit=str(row[9]) if row[9] else "",
                    active=bool(row[10]) if row[10] is not None else True,
                ))

            # Aktualizuj hit_count
            if rules:
                await self._increment_hits([r.rule_id for r in rules])

            return rules
        except Exception as exc:
            logger.debug("[MESH] Get rules query failed: %s", exc)
            return []

    async def _increment_hits(self, rule_ids: list[str]) -> None:
        if not self._conn:
            for rid in rule_ids:
                if rid in self._rules:
                    self._rules[rid].hit_count += 1
                    self._rules[rid].last_hit = pendulum.now("UTC").isoformat()
            return
        try:
            now = pendulum.now("UTC").isoformat()
            for rid in rule_ids:
                await execute_db(self._conn, "UPDATE mesh_experience_replay SET hit_count = hit_count + 1, last_hit = ? WHERE rule_id = ?", (now, rid))
        except Exception as exc:
            logger.debug("[MESH] Increment hits failed: %s", exc)

    @property
    def count(self) -> int:
        if self._conn:
            try:
                row = self._conn.execute("SELECT COUNT(*) FROM mesh_experience_replay").fetchone()
                return int(row[0]) if row else 0
            except Exception:
                return 0
        return len(self._rules)

    async def close(self) -> None:
        if self._conn:
            try:
                self._conn.close()
            except Exception as exc:
                logger.debug("[MESH] Experience close failed: %s", exc)
            self._conn = None


# ═════════════════════════════════════════════════════════════════════════
# D. PREDICTIVE TASK ROUTER — Warstwa 3
# ═════════════════════════════════════════════════════════════════════════


class PredictiveTaskRouter:
    """Dynamiczny router zadań — optymalizuje ścieżkę agentów.

    Zamiast sztywnego Extraction→Quality→Orchestrator:
    - Trust ≥ 0.92 → POMIŃ QualityValidator + Analytics (50ms)
    - Trust 0.75-0.92 → Normalna ścieżka
    - Trust < 0.75 → ROZSZERZONA ścieżka (4-Eyes + Analytics)
    - Trust < 0.30 → CIRCUIT BREAKER → zawsze ASK_USER
    """

    # Domyślna ścieżka (sztywna)
    DEFAULT_ROUTE = ["extraction", "quality-validator", "orchestrator"]

    # Progi routingu
    TRUST_SKIP_THRESHOLD = 0.92       # Powyżej → pomiń Quality + Analytics
    TRUST_NORMAL_THRESHOLD = 0.75     # Normalna ścieżka
    TRUST_EXPAND_THRESHOLD = 0.50     # Poniżej → rozszerz (dodaj Analytics)
    TRUST_CIRCUIT_BREAKER = 0.30      # Poniżej → Circuit Breaker → ASK_USER

    def __init__(
        self,
        bayesian_field: CollectiveBayesianField,
        experience_replay: CrossAgentExperienceReplay,
    ) -> None:
        self._bayesian = bayesian_field
        self._experience = experience_replay

    async def route(
        self,
        vendor_nip: str,
        amount: float = 0.0,
        category: str = "",
        agent_name: str = "orchestrator",
    ) -> RouteDecision:
        """Wyznacz optymalną ścieżkę agentów dla danego przypadku.

        Algorytm:
        1. Pobierz Collective Bayesian Field dla vendora
        2. Pobierz Cross-Agent Experience Rules dla agenta
        3. Na podstawie Trust Score + Reguł → wyznacz ścieżkę
        4. Oblicz korekty progów

        Args:
            vendor_nip: NIP kontrahenta.
            amount: Kwota faktury.
            category: Kategoria.
            agent_name: Agent wywołujący (domyślnie orchestrator).

        Returns:
            RouteDecision z optymalną ścieżką.
        """
        # 1. Collective Bayesian Field
        field = await self._bayesian.get_field(vendor_nip, category, amount)
        trust = field.trust_score
        confidence = field.confidence

        # 2. Cross-Agent Experience Rules
        rules = await self._experience.get_rules_for_agent(
            target_agent=agent_name,
            vendor_nip=vendor_nip,
            category=category,
        )

        # 3. Wyznacz ścieżkę
        route: list[str] = list(self.DEFAULT_ROUTE)
        skip_agents: list[str] = []
        force_agents: list[str] = []
        adjustments: dict[str, float] = {}
        circuit_breaker = False

        # Circuit Breaker
        if trust < self.TRUST_CIRCUIT_BREAKER:
            circuit_breaker = True
            force_agents = ["quality-validator", "analytics"]
            logger.warning(
                "[MESH] ⚡ Circuit Breaker OPEN | NIP=%s | trust=%.2f",
                vendor_nip[:8], trust,
            )

        # Trust ≥ 0.92 → skip Quality + Analytics
        elif trust >= self.TRUST_SKIP_THRESHOLD:
            skip_agents = ["quality-validator", "analytics"]
            route = [a for a in route if a not in skip_agents]
            logger.debug(
                "[MESH] Fast path | NIP=%s | trust=%.2f | route=%s",
                vendor_nip[:8], trust, route,
            )

        # Trust < 0.75 → expand (dodaj Analytics przed Quality)
        elif trust < self.TRUST_NORMAL_THRESHOLD:
            if "analytics" not in route:
                # Wstaw Analytics przed quality-validator
                try:
                    q_idx = route.index("quality-validator")
                    route.insert(q_idx, "analytics")
                except ValueError:
                    route.append("analytics")
            logger.debug(
                "[MESH] Expanded path | NIP=%s | trust=%.2f | route=%s",
                vendor_nip[:8], trust, route,
            )

        # 4. Zastosuj reguły Cross-Agent Experience
        applied_rule_ids: list[str] = []
        for rule in rules:
            applied_rule_ids.append(rule.rule_id)

            if rule.action == "FORCE_4EYES":
                if "quality-validator" not in force_agents:
                    force_agents.append("quality-validator")
                adjustments["orchestrator"] = adjustments.get("orchestrator", 0.0) - 0.10

            elif rule.action == "LOWER_THRESHOLD":
                delta = rule.params.get("delta", -0.05)
                adjustments["orchestrator"] = adjustments.get("orchestrator", 0.0) + delta

            elif rule.action == "SET_SCRUTINY_HIGH":
                adjustments["extraction"] = adjustments.get("extraction", 0.0) - 0.10

            elif rule.action == "INCREASE_SCRUTINY":
                multiplier = float(rule.params.get("threshold_multiplier", 1.5))
                adjustments["quality-validator"] = adjustments.get("quality-validator", 0.0) + 0.05 * multiplier

            elif rule.action == "TRIGGER_DEEP_CHECK":
                if "quality-validator" not in force_agents:
                    force_agents.append("quality-validator")
                if "analytics" not in force_agents:
                    force_agents.append("analytics")

        # 5. Oblicz szacowany czas
        base_time = 15000.0  # 15s dla pełnej ścieżki
        time_per_agent = base_time / len(self.DEFAULT_ROUTE)
        estimated_ms = len(route) * time_per_agent
        if circuit_breaker:
            estimated_ms *= 1.5  # +50% dla rozszerzonej ścieżki

        return RouteDecision(
            vendor_nip=vendor_nip,
            trust_score=trust,
            confidence=confidence,
            route=route,
            skip_agents=skip_agents,
            force_agents=force_agents,
            circuit_breaker_open=circuit_breaker,
            threshold_adjustments=adjustments,
            mesh_field=field,
            applied_rules=applied_rule_ids,
            estimated_time_ms=estimated_ms,
        )

    async def should_skip_agent(
        self,
        agent_name: str,
        vendor_nip: str,
        amount: float = 0.0,
    ) -> bool:
        """Szybkie sprawdzenie: czy pominąć tego agenta?"""
        decision = await self.route(vendor_nip, amount)
        return agent_name in decision.skip_agents

    async def get_threshold_adjustments(
        self,
        vendor_nip: str,
        amount: float = 0.0,
    ) -> dict[str, float]:
        """Pobierz korekty progów dla wszystkich agentów."""
        decision = await self.route(vendor_nip, amount)
        return decision.threshold_adjustments


# ═════════════════════════════════════════════════════════════════════════
# E. KNOWLEDGE MESH — Główna klasa (integruje wszystkie 3 warstwy)
# ═════════════════════════════════════════════════════════════════════════


class KnowledgeMesh:
    """Agent Knowledge Mesh — centralny hub wiedzy agentów.

    Integruje:
    - CollectiveBayesianField (Warstwa 2)
    - CrossAgentExperienceReplay (Warstwa 1)
    - PredictiveTaskRouter (Warstwa 3)

    Używany przez AgentOrchestrator do:
    - Dynamicznego routingu zadań
    - Współdzielenia wiedzy między agentami
    - Adaptacyjnych progów decyzyjnych
    """

    def __init__(
        self,
        db_dir: str = "/tmp/nexus-mesh",
        orchestrator: Any = None,
    ) -> None:
        self._orchestrator = orchestrator
        self._bayesian = CollectiveBayesianField(f"{db_dir}/bayesian.db")
        self._experience = CrossAgentExperienceReplay(f"{db_dir}/experience.db")
        self._router = PredictiveTaskRouter(self._bayesian, self._experience)
        self._initialized = False

    # ── Lifecycle ───────────────────────────────────────────────────

    async def initialize(self) -> None:
        """Inicjalizuj Knowledge Mesh (DuckDB + doświadczenia)."""
        if self._initialized:
            return
        await self._bayesian.initialize()
        await self._experience.initialize()
        self._initialized = True
        logger.info(
            "[MESH] 🧠 Knowledge Mesh initialized | %d fields | %d rules | router ready",
            self._bayesian.count, self._experience.count,
        )

    async def close(self) -> None:
        """Zamknij Knowledge Mesh."""
        await self._bayesian.close()
        await self._experience.close()
        self._initialized = False

    @property
    def is_initialized(self) -> bool:
        return self._initialized

    # ── Router (Warstwa 3) ───────────────────────────────────────────

    @property
    def router(self) -> PredictiveTaskRouter:
        return self._router

    async def route(
        self,
        vendor_nip: str,
        amount: float = 0.0,
        category: str = "",
    ) -> RouteDecision:
        """Wyznacz optymalną ścieżkę agentów."""
        if not self._initialized:
            await self.initialize()
        return await self._router.route(vendor_nip, amount, category)

    # ── Bayesian Field (Warstwa 2) ────────────────────────────────────

    @property
    def bayesian(self) -> CollectiveBayesianField:
        return self._bayesian

    async def update_trust(
        self,
        vendor_nip: str,
        correct: bool,
        agent_name: str,
        category: str = "",
        amount: float = 0.0,
    ) -> MeshField:
        """Aktualizuj Trust Score po decyzji (wszystkie agenty widzą)."""
        if not self._initialized:
            await self.initialize()
        return await self._bayesian.update_field(
            vendor_nip, correct, agent_name, category, amount,
        )

    async def get_vendor_trust(self, vendor_nip: str, amount: float = 0.0) -> tuple[float, float, int]:
        """Pobierz zagregowany Trust Score vendora."""
        if not self._initialized:
            await self.initialize()
        return await self._bayesian.get_aggregate_trust(vendor_nip, amount)

    # ── Experience Replay (Warstwa 1) ──────────────────────────────────

    @property
    def experience(self) -> CrossAgentExperienceReplay:
        return self._experience

    async def share_experience(
        self,
        event_type: str,
        source_agent: str,
        vendor_nip: str,
        category: str = "",
        amount: float = 0.0,
        details: dict[str, Any] | None = None,
    ) -> list[ExperienceRule]:
        """Podziel się doświadczeniem między agentami.

        Gdy agent A uczy się → automatycznie uczy agentów B, C, D.
        """
        if not self._initialized:
            await self.initialize()

        rules = await self._experience.record_experience(
            event_type, source_agent, vendor_nip, category, amount, details,
        )

        # Publikuj event na NATS (jeśli orchestrator dostępny)
        if self._orchestrator and rules:
            try:
                event = MeshEvent(
                    event_id=_mesh_event_generate_id(),
                    event_type="experience.created",
                    source_agent=source_agent,
                    payload={
                        "vendor_nip": vendor_nip,
                        "category": category,
                        "amount": amount,
                        "rules_created": len(rules),
                        "targets": [r.target_agent for r in rules],
                        "actions": [r.action for r in rules],
                    },
                    timestamp=pendulum.now("UTC").isoformat(),
                )
                await self._orchestrator.publish(
                    "mesh.experience.created",
                    msgspec_json.decode(msgspec_json.encode(event)),
                )
            except Exception as exc:
                logger.debug("[MESH] NATS publish failed: %s", exc)

        return rules

    async def get_agent_rules(
        self,
        agent_name: str,
        vendor_nip: str = "",
        category: str = "",
    ) -> list[ExperienceRule]:
        """Pobierz reguły Cross-Agent dla konkretnego agenta."""
        if not self._initialized:
            await self.initialize()
        return await self._experience.get_rules_for_agent(agent_name, vendor_nip, category)

    # ── Stats ──────────────────────────────────────────────────────────

    def get_stats(self) -> dict[str, Any]:
        """Pobierz statystyki Knowledge Mesh."""
        return {
            "bayesian_fields": self._bayesian.count if self._initialized else 0,
            "experience_rules": self._experience.count if self._initialized else 0,
            "initialized": self._initialized,
        }


# ═════════════════════════════════════════════════════════════════════════
# F. HELPER: MeshProtocol — protokół komunikacji NATS dla Mesh
# ═════════════════════════════════════════════════════════════════════════


class MeshProtocol:
    """Protokół komunikacji Knowledge Mesh przez NATS JetStream.

    Topiki NATS:
      mesh.field.updated        — aktualizacja Collective Bayesian Field
      mesh.experience.created   — nowa reguła Cross-Agent Experience Replay
      mesh.route.decided        — decyzja Predictive Task Routera
      mesh.threshold.adjusted   — korekta progu decyzyjnego
      mesh.circuit_breaker      — stan Circuit Breakera per vendor
    """

    TOPICS = {
        "field_updated": "mesh.field.updated",
        "experience_created": "mesh.experience.created",
        "route_decided": "mesh.route.decided",
        "threshold_adjusted": "mesh.threshold.adjusted",
        "circuit_breaker": "mesh.circuit_breaker",
    }

    @staticmethod
    def build_field_event(
        field: MeshField,
        source_agent: str,
    ) -> MeshEvent:
        """Zbuduj event aktualizacji pola."""
        return MeshEvent(
            event_id=_mesh_event_generate_id(),
            event_type="field.updated",
            source_agent=source_agent,
            payload={
                "vendor_nip": field.vendor_nip,
                "category": field.category,
                "amount_range": field.amount_range,
                "trust_score": field.trust_score,
                "confidence": field.confidence,
                "total_decisions": field.total_decisions,
                "alpha": field.alpha,
                "beta": field.beta,
            },
            timestamp=pendulum.now("UTC").isoformat(),
        )

    @staticmethod
    def build_experience_event(
        rules: list[ExperienceRule],
        source_agent: str,
    ) -> MeshEvent:
        """Zbuduj event Cross-Agent Experience."""
        return MeshEvent(
            event_id=_mesh_event_generate_id(),
            event_type="experience.created",
            source_agent=source_agent,
            payload={
                "rules": [
                    {
                        "rule_id": r.rule_id,
                        "target_agent": r.target_agent,
                        "action": r.action,
                        "trigger_condition": r.trigger_condition,
                        "priority": r.priority,
                    }
                    for r in rules
                ],
                "targets": list({r.target_agent for r in rules}),
                "total_rules": len(rules),
            },
            timestamp=pendulum.now("UTC").isoformat(),
        )


__all__ = [
    "KnowledgeMesh",
    "CollectiveBayesianField",
    "CrossAgentExperienceReplay",
    "PredictiveTaskRouter",
    "MeshProtocol",
]
