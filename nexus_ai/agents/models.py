"""msgspec Struct definitions for agent communication.

Zgodnie z aa3fvcx.txt (5 agentów, 13 modeli):
- Wszystkie struktury danych to msgspec.Struct (ultraszybka serializacja)
- Komunikacja przez NATS JetStream w formacie JSON/MessagePack
- Zero Pydantic — lżejsze i szybsze
- JEDEN poziom automatyzacji: DecisionMode (AUTO_POST / SUGGEST / ASK_USER)
- Enterprise: CognitiveAuditTrail, BayesianTrustScore,
  ConfidenceVote, VotingResult, ProofChain, MemorySystem,
  ContinuousLearningFramework
"""

from __future__ import annotations

import enum
import uuid
from typing import Any

from msgspec import Struct, field


# ═════════════════════════════════════════════════════════════════════════
# DecisionMode — Jeden poziom automatyzacji (zgodnie z aa3fvcx.txt)
# ═════════════════════════════════════════════════════════════════════════


class DecisionMode(enum.StrEnum):
    """Tryb decyzyjny agenta — JEDEN poziom automatyzacji.

    Zgodnie z aa3fvcx.txt:
    - AUTO_POST (≥0.92): Agent samodzielnie księguje, użytkownik tylko informowany.
    - SUGGEST  (≥0.75): Agent proponuje decyzję z ostrzeżeniem, użytkownik zatwierdza.
    - ASK_USER (<0.75): Agent pyta użytkownika o decyzję.

    Człowiek ZAWSZE jest decydentem. Agent wykonuje pracę i przedstawia opcje.
    """

    AUTO_POST = "auto_post"
    SUGGEST = "suggest"
    ASK_USER = "ask_user"


# ═════════════════════════════════════════════════════════════════════════
# GENIALNY POMYSŁ v6.0: Silent Partner — Strategic Mode & Context
# ═════════════════════════════════════════════════════════════════════════


class StrategicMode(enum.StrEnum):
    """Tryb strategiczny agenta — GENIALNY POMYSŁ v6.0 "Cichy Wspólnik".

    Zamiast pytać o każdą decyzję taktyczną ("którą stawkę VAT?"),
    agent pyta o STRATEGIĘ raz na kwartał, a działa taktycznie zawsze.

    - CASH_PROTECT: Maksymalizuj płynność, rozkładaj koszty.
    - GROWTH: Inwestuj, przyspieszaj amortyzację.
    - TAX_OPTIMAL: Minimalizuj PIT/CIT, rozkładaj dochody.
    - EFFICIENCY: Najszybsza ścieżka, zero zbędnych kroków.
    """

    CASH_PROTECT = "cash_protect"
    GROWTH = "growth"
    TAX_OPTIMAL = "tax_optimal"
    EFFICIENCY = "efficiency"


class CashFlowPhase(enum.StrEnum):
    """Faza przepływów pieniężnych."""

    SURPLUS = "surplus"       # Wpływy > wydatki
    DEFICIT = "deficit"       # Wydatki > wpływy
    NEUTRAL = "neutral"       # Zbalansowane


class DashboardState(enum.StrEnum):
    """Stan Executive Dashboard — GENIALNY POMYSŁ v6.0."""

    NORMAL = "normal"      # 🔵 Podsumowanie + "Akceptuj wszystkie"
    ATTENTION = "attention"  # 🟡 1-2 pozycje oznaczone
    ALERT = "alert"         # 🔴 Pilna sprawa
    EMPTY = "empty"         # ⚪ "Wszystko zaksięgowane. Idź na kawę ☕"


class ContextDimension(Struct, kw_only=True):
    """Pięć wymiarów kontekstu strategicznego — Learning by Context (LbC).

    GENIALNY POMYSŁ v6.0:
    Zamiast uczyć się CO przedsiębiorca robi, agent uczy się
    W JAKIM KONTEKŚCIE podejmuje decyzje.
    """

    cash_flow_phase: CashFlowPhase = CashFlowPhase.NEUTRAL
    """Aktualna faza przepływów pieniężnych."""
    tax_period: str = "mid_quarter"
    """Okres podatkowy: start_quarter, mid_quarter, end_quarter, vat_deadline, year_end."""
    vendor_season: str = "normal"
    """Sezonowość kontrahenta: normal, high_season, low_season, first_time."""
    growth_phase: str = "maintenance"
    """Faza rozwoju firmy: startup, growth, maintenance, scaling."""
    macro_context: dict[str, Any] = field(default_factory=dict)
    """Kontekst makroekonomiczny: stopy procentowe, inflacja, kursy walut."""

    @property
    def summary(self) -> str:
        """Podsumowanie kontekstu w języku naturalnym."""
        parts = [
            f"Cash flow: {self.cash_flow_phase.value}",
            f"Tax period: {self.tax_period}",
            f"Vendor season: {self.vendor_season}",
            f"Growth: {self.growth_phase}",
        ]
        return " | ".join(parts)


class StrategicRecommendation(Struct, kw_only=True):
    """Strategiczna rekomendacja agenta — GENIALNY POMYSŁ v6.0.

    Agent NIE pyta o taktykę ("VAT 23% czy 8%?").
    Agent pyta o STRATEGIĘ ("Oszczędzamy czy inwestujemy?").
    """

    rec_id: str
    """Unikalne ID rekomendacji."""
    category: str
    """Kategoria: liquidity, investment, tax, efficiency, risk."""
    title: str
    """Krótki tytuł (max 80 znaków)."""
    description: str
    """Opis sytuacji i rekomendacji."""
    impact: str = "medium"
    """Wpływ: high, medium, low."""
    potential_savings: float = 0.0
    """Potencjalne oszczędności w PLN."""
    options: list[dict[str, Any]] = field(default_factory=list)
    """2-3 opcje strategiczne do wyboru."""
    context_drivers: list[str] = field(default_factory=list)
    """Które wymiary kontekstu wpływają na tę rekomendację."""
    created_at: str = ""
    """ISO timestamp utworzenia."""


class ExecutiveSummaryItem(Struct, kw_only=True):
    """Pojedynczy element Executive Summary."""

    item_type: str
    """Typ: invoice_posted, vendor_verified, payment_scheduled, alert, recommendation."""
    title: str
    """Krótki opis pozycji."""
    detail: str = ""
    """Szczegóły."""
    amount: float = 0.0
    """Kwota (jeśli dotyczy)."""
    currency: str = "PLN"
    """Waluta."""
    status: str = "auto"
    """Status: auto, verified, pending, alert."""
    decision_id: str = ""
    """Referencja do decyzji (jeśli dotyczy)."""


class ExecutiveSummary(Struct, kw_only=True):
    """Executive Summary — GENIALNY POMYSŁ v6.0 "Cichy Wspólnik".

    Agent prezentuje efekt swojej pracy w formie Executive Summary.
    Przedsiębiorca może:
    - Zaakceptować wszystko jednym kliknięciem (80% przypadków)
    - Skorygować konkretną pozycję (15% przypadków)
    - Zatrzymać i przeanalizować (5% przypadków)
    """

    summary_id: str
    """Unikalne ID podsumowania."""
    generated_at: str
    """ISO timestamp wygenerowania."""
    greeting: str = ""
    """Powitanie (np. "Dzień dobry, Michał! Agent przepracował noc.")."""
    items: list[ExecutiveSummaryItem] = field(default_factory=list)
    """Lista wszystkich pozycji."""
    auto_posted_count: int = 0
    """Liczba automatycznie zaksięgowanych faktur."""
    auto_posted_amount: float = 0.0
    """Łączna kwota automatycznie zaksięgowanych faktur."""
    verified_count: int = 0
    """Liczba faktur z weryfikacją."""
    time_saved_minutes: float = 0.0
    """Oszczędność czasu przedsiębiorcy w minutach."""
    trend_pct: float = 0.0
    """Trend vs poprzedni okres (w %)."""
    items_to_review: int = 0
    """Liczba pozycji do opcjonalnego wglądu."""
    strategic_recommendations: list[StrategicRecommendation] = field(default_factory=list)
    """Strategiczne rekomendacje (opcjonalne, 0-2)."""
    dashboard_state: DashboardState = DashboardState.NORMAL
    """Stan dashboardu."""
    silent_rate: float = 0.0
    """Silent Rate = auto_posted / total (cel ≥95%)."""
    currency: str = "PLN"
    """Domyślna waluta."""

    @property
    def total_processed(self) -> int:
        """Łączna liczba przetworzonych dokumentów."""
        return self.auto_posted_count + self.verified_count

    @property
    def requires_attention(self) -> bool:
        """Czy podsumowanie wymaga uwagi użytkownika."""
        return self.items_to_review > 0 or self.dashboard_state in (
            DashboardState.ATTENTION, DashboardState.ALERT
        )


# ═════════════════════════════════════════════════════════════════════════
# Confidentiality & Voting — Mechanizmy decyzyjne
# ═════════════════════════════════════════════════════════════════════════


class BayesianTrustScore(Struct, kw_only=True):
    """Bayesian Trust Score z aktualizacją po każdej decyzji.

    Posterior Beta distribution:
      Prior:       Beta(α₀=1, β₀=1)
      Likelihood:  Bern(y|θ)
      Posterior:   Beta(α₀+Σy, β₀+n-Σy)

    Trust Score = E[θ|D] = α / (α + β)
    Confidence  = 1 - Var[θ|D] (skalowane)
    """

    alpha: float = 1.0
    """Liczba poprawnych decyzji + 1 (prior)."""
    beta: float = 1.0
    """Liczba błędnych decyzji + 1 (prior)."""

    @property
    def trust_score(self) -> float:
        """Trust Score = E[θ|D] = α / (α + β)."""
        return self.alpha / (self.alpha + self.beta)

    @property
    def confidence(self) -> float:
        """Pewność Trust Score = 1 - skalowana wariancja."""
        total = self.alpha + self.beta
        variance = (self.alpha * self.beta) / (total**2 * (total + 1))
        return max(0.0, min(1.0, 1.0 - variance * 12))

    def update(self, correct: bool) -> None:
        """Bayesian update po decyzji: zwiększ α (OK) lub β (błąd)."""
        if correct:
            self.alpha += 1.0
        else:
            self.beta += 1.0

    def adaptive_threshold(self, base: float = 0.92, max_correction: float = 0.1) -> float:
        """Adaptacyjny próg decyzyjny dla danego kontrahenta.

        Dla znanych (α+β >= 100): pełna korekta.
        Dla nowych (α+β < 30): conservative (mniejsza korekta).
        """
        total = self.alpha + self.beta
        correction = ((self.alpha - self.beta) / total) * max_correction
        if total < 30:
            correction *= total / 30.0  # conservative dla nowych
        return max(0.0, min(1.0, base - correction))

    def __repr__(self) -> str:
        return (
            f"BayesianTrustScore(α={self.alpha:.0f}, β={self.beta:.0f}, "
            f"trust={self.trust_score:.3f}, conf={self.confidence:.3f})"
        )


class ConfidenceVote(Struct, kw_only=True):
    """Głos modelu w procesie decyzyjnym z ważeniem bayesiańskim."""

    model_name: str
    """Nazwa modelu."""
    model_weight: float = 0.0
    """Historyczna precyzja modelu (Bayesian waga)."""
    vote: str = ""
    """Głos: POST | REVIEW | BLOCK."""
    confidence: float = 0.0
    """Pewność tej konkretnej decyzji (0.0-1.0)."""
    weighted_vote: float = 0.0
    """Ważony głos = model_weight × confidence."""
    details: str = ""
    """Szczegóły głosu."""


class VotingResult(Struct, kw_only=True):
    """Wynik ważonego głosowania między modelami/agentami."""

    votes: list[ConfidenceVote] = field(default_factory=list)
    """Lista głosów wszystkich modeli."""
    total_weight: float = 0.0
    """Suma wag wszystkich modeli."""
    winner: str = ""
    """Zwycięski werdykt: POST | REVIEW | BLOCK."""
    consensus: bool = False
    """Czy osiągnięto konsensus (> 0.66 majority)."""
    uncertainty: float = 0.0
    """Poziom niepewności (0.0-1.0). > 0.3 → eskalacja."""

    @property
    def consensus_ratio(self) -> float:
        """Stosunek zgody między modelami."""
        if not self.votes:
            return 0.0
        winner_votes = sum(
            1 for v in self.votes if v.vote == self.winner
        )
        return winner_votes / len(self.votes)


# ═════════════════════════════════════════════════════════════════════════
# Proof Chain — Niepodważalny łańcuch audytowy (SHA-256)
# ═════════════════════════════════════════════════════════════════════════


class ProofBlock(Struct, kw_only=True):
    """Pojedynczy blok w łańcuchu dowodowym (Proof Chain)."""

    index: int
    """Indeks bloku w łańcuchu."""
    decision_id: str
    """ID decyzji."""
    decision_json: str
    """Decyzja w formacie JSON."""
    timestamp: str
    """ISO timestamp utworzenia."""
    previous_hash: str = "0" * 64
    """Hash poprzedniego bloku."""
    hash: str = ""
    """SHA-256 hash tego bloku."""


class ProofChain(Struct, kw_only=True):
    """Łańcuch dowodowy SHA-256 dla niepodważalnego audytu.

    Każda decyzja tworzy blok z hashem poprzedniego.
    Modyfikacja dowolnego bloku → wszystkie kolejne unieważnione.
    Zgodne z RAPORT_TECHNOLOGII: nexus-crypto SHA-256.
    """

    blocks: list[ProofBlock] = field(default_factory=list)
    """Bloki w łańcuchu."""
    decision_id: str = ""
    """ID decyzji (korzeń łańcucha)."""


# ═════════════════════════════════════════════════════════════════════════
# Memory Systems — Typy pamięci agentów
# ═════════════════════════════════════════════════════════════════════════


class MemoryType(enum.StrEnum):
    """Typy pamięci w systemie agentów AI.

    Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt §6:
    - EPISODIC: DuckDB event store — wszystkie zdarzenia i decyzje
    - SEMANTIC: sqlite-vec embeddings — wektorowa pamięć semantyczna
    - PROCEDURAL: OPA/Rego — reguły podatkowe i compliance
    - WORKING: NATS KV Store — krótkoterminowa pamięć (TTL 1h)
    - DECISION_CACHE: diskcache + sqlite-vec k-NN — cache decyzji
    """

    EPISODIC = "episodic"
    SEMANTIC = "semantic"
    PROCEDURAL = "procedural"
    WORKING = "working"
    DECISION_CACHE = "decision_cache"


class MemoryRecord(Struct, kw_only=True):
    """Pojedynczy rekord w pamięci agenta."""

    memory_type: MemoryType
    """Typ pamięci."""
    key: str
    """Klucz rekordu."""
    value: Any = None
    """Wartość rekordu."""
    embedding: list[float] = field(default_factory=list)
    """Embedding wektorowy (dla SEMANTIC)."""
    ttl_seconds: int = 0
    """TTL w sekundach (0 = bez TTL)."""
    created_at: str = ""
    """ISO timestamp utworzenia."""
    metadata: dict[str, Any] = field(default_factory=dict)
    """Dodatkowe metadane."""


class MemoryQuery(Struct, kw_only=True):
    """Zapytanie do pamięci agenta."""

    memory_type: MemoryType
    """Typ pamięci do przeszukania."""
    query: str
    """Zapytanie tekstowe."""
    embedding: list[float] = field(default_factory=list)
    """Embedding do wyszukiwania (k-NN)."""
    k: int = 5
    """Liczba wyników k-NN."""
    threshold: float = 0.7
    """Próg podobieństwa (0.0-1.0)."""
    filters: dict[str, Any] = field(default_factory=dict)
    """Filtry dodatkowe."""


class MemoryResult(Struct, kw_only=True):
    """Wynik zapytania do pamięci."""

    records: list[MemoryRecord] = field(default_factory=list)
    """Znalezione rekordy."""
    total: int = 0
    """Całkowita liczba wyników."""
    query_time_ms: float = 0.0
    """Czas zapytania w milisekundach."""


# ═════════════════════════════════════════════════════════════════════════
# Continuous Learning Framework — System uczenia się
# ═════════════════════════════════════════════════════════════════════════


class FeedbackType(enum.StrEnum):
    """Typ feedbacku od użytkownika."""

    ACCEPT = "accept"
    CORRECT = "correct"
    REJECT = "reject"


class LearningRecord(Struct, kw_only=True):
    """Rekord uczenia się — każda korekta użytkownika to nowy przykład."""

    id: str = ""
    """UUID rekordu."""
    decision_id: str
    """ID decyzji."""
    agent_name: str
    """Nazwa agenta."""
    predicted_value: dict[str, Any] = field(default_factory=dict)
    """Wartość przewidziana przez agenta."""
    corrected_value: dict[str, Any] = field(default_factory=dict)
    """Wartość poprawiona przez użytkownika."""
    delta: float = 0.0
    """Różnica między predicted a corrected (0.0-1.0)."""
    feedback_type: FeedbackType = FeedbackType.ACCEPT
    """Typ feedbacku."""
    timestamp: str = ""
    """ISO timestamp."""
    model_version: str = ""
    """Wersja modelu w momencie decyzji."""


class CognitiveProofBlock(Struct, kw_only=True):
    """Rozszerzony blok Proof Chain z uczeniem kognitywnym.

    GENIALNY POMYSŁ ENTERPRISE — Cognitive Audit Trail:
    Każdy blok łańcucha dowodowego zawiera nie tylko hash decyzji,
    ale też embedding korekty i referencję do reguły OPA.
    Gdy korekta się powtarza → reguła jest auto-naprawiana.
    """

    index: int
    decision_id: str
    decision_json: str
    timestamp: str
    previous_hash: str = "0" * 64
    hash: str = ""
    # ── Cognitive Extension ──
    correction_embedding: list[float] = field(default_factory=list)
    """Embedding korekty (768d) — do k-NN w sqlite-vec."""
    correction_count: int = 0
    """Ile razy ta sama korekta została zastosowana."""
    opa_rule_ref: str = ""
    """Referencja do reguły OPA, która została zaktualizowana."""
    auto_patched: bool = False
    """Czy reguła została automatycznie poprawiona."""


class LearningConfig(Struct, kw_only=True):
    """Konfiguracja Continuous Learning Framework.

    Uproszczona — jeden poziom uczenia.
    """

    enabled: bool = True
    min_delta_for_learning: float = 0.1
    min_samples_for_finetune: int = 100
    min_samples_for_opa_update: int = 10
    """Minimalna liczba korekt przed auto-naprawą reguł OPA."""
    k_nn_for_corrections: int = 10
    """k dla k-NN w Cognitive Audit Trail."""
    distance_threshold: float = 0.15
    """Próg odległości dla podobnych przypadków."""


# ═════════════════════════════════════════════════════════════════════════
# AgentContext — kontekst wykonania
# ═════════════════════════════════════════════════════════════════════════


class AgentContext(Struct, kw_only=True):
    """Kontekst wykonania dla agenta.

    Przekazywany przez NATS w nagłówkach wiadomości.
    """

    task_id: str
    """Unikalne ID zadania (blake2b hash z broker.py)."""
    source_agent: str
    """Nazwa agenta źródłowego."""
    target_agent: str
    """Nazwa agenta docelowego."""
    correlation_id: str = ""
    """ID korelacji dla śledzenia przepływu."""
    timestamp: str = ""
    """ISO timestamp utworzenia."""
    tenant_id: str = ""
    """ID tenant (dla multi-tenancy)."""
    retry_count: int = 0
    """Liczba ponowień."""
    priority: int = 5
    """Priorytet (1-10, 1=najwyższy)."""
    decision_mode: DecisionMode = DecisionMode.AUTO_POST
    """Tryb decyzyjny (AUTO_POST / SUGGEST / ASK_USER)."""
    trace_id: str = ""
    """OpenTelemetry trace ID."""
    # ── GENIALNY POMYSŁ v6.0: Silent Partner ──
    strategic_mode: StrategicMode = StrategicMode.EFFICIENCY
    """Tryb strategiczny (CASH_PROTECT / GROWTH / TAX_OPTIMAL / EFFICIENCY)."""
    silent_mode: bool = True
    """Czy agent działa w trybie Silent (v6.0: domyślnie True)."""


# ═════════════════════════════════════════════════════════════════════════
# AgentMessage — podstawowa jednostka komunikacji
# ═════════════════════════════════════════════════════════════════════════


class AgentMessage(Struct, kw_only=True):
    """Podstawowa wiadomość między agentami przez NATS JetStream."""

    context: AgentContext
    """Kontekst wykonania."""
    payload: dict[str, Any] = field(default_factory=dict)
    """Payload zadania (zależny od typu)."""
    metadata: dict[str, Any] = field(default_factory=dict)
    """Dodatkowe metadane (np. wersja modelu, czas wykonania)."""


# ═════════════════════════════════════════════════════════════════════════
# AgentCommand — polecenie wykonania
# ═════════════════════════════════════════════════════════════════════════


class AgentCommand(Struct, kw_only=True):
    """Polecenie dla agenta do wykonania."""

    command: str
    """Nazwa komendy (np. 'extract_invoice', 'run_query')."""
    params: dict[str, Any] = field(default_factory=dict)
    """Parametry komendy."""
    context: AgentContext
    """Kontekst wykonania."""


# ═════════════════════════════════════════════════════════════════════════
# DecisionVerdict — werdykt decyzyjny
# ═════════════════════════════════════════════════════════════════════════


class DecisionVerdict(Struct, kw_only=True):
    """Werdykt decyzyjny dla faktury.

    Zgodnie z AGENT_SYSTEM_ENTERPRISE.txt:
    - Zielony (Trust Score >= 0.92): AUTO_POST
    - Żółty (0.75 <= Trust Score < 0.92): REVIEW
    - Czerwony (Trust Score < 0.75): BLOCK
    - Dodatkowo: ESCALATED, 4EYES_REQUIRED
    """

    status: str
    """Status decyzji: AUTO_POST, REVIEW, BLOCK, ESCALATED, 4EYES_REQUIRED."""
    trust_score: float = 0.0
    """Trust Score (0.0 - 1.0)."""
    reason: str = ""
    """Przyczyna decyzji."""
    details: dict[str, Any] = field(default_factory=dict)
    """Szczegóły decyzji."""
    verified_by: list[str] = field(default_factory=list)
    """Lista agentów, które zweryfikowały decyzję."""
    voting_result: VotingResult | None = None
    """Wynik ważonego głosowania (jeśli wykonane)."""
    proof_hash: str = ""
    """SHA-256 hash w Proof Chain."""
    decision_mode: DecisionMode = DecisionMode.AUTO_POST
    """Tryb decyzyjny użyty do podjęcia decyzji."""


class TrustScore(Struct, kw_only=True):
    """Trust Score dla decyzji - zgodny z AGENT_SYSTEM_ENTERPRISE.txt.

    Składa się z 4 komponentów:
    - ai_confidence: Zaufanie modelu do swojej decyzji
    - vendor_reliability: Wiarygodność kontrahenta
    - data_consistency: Spójność danych
    - context_trust: Zaufanie kontekstowe
    """

    ai_confidence: float = 0.0
    """Zaufanie modelu (0.0 - 1.0)."""
    vendor_reliability: float = 0.0
    """Wiarygodność kontrahenta (0.0 - 1.0)."""
    data_consistency: float = 0.0
    """Spójność danych (0.0 - 1.0)."""
    context_trust: float = 0.0
    """Zaufanie kontekstowe (0.0 - 1.0)."""
    overall: float = 0.0
    """Trust Score całkowity = średnia ważona."""


class AgentDecision(Struct, kw_only=True):
    """Pełna decyzja agenta z uzasadnieniem.

    Rozszerzona o Enterprise:
    - voting_result: Wynik ważonego głosowania
    - proof_chain: Łańcuch dowodowy SHA-256
    - autonomy_level: Poziom autonomii
    - learning_record: Rekord uczenia się
    """

    decision_id: str
    """Unikalne ID decyzji."""
    agent_name: str
    """Nazwa agenta podejmującego decyzję."""
    verdict: DecisionVerdict
    """Werdykt decyzyjny."""
    trust_score: TrustScore | None = None
    """Trust Score (jeśli dostępny)."""
    explanation: str = ""
    """Wyjaśnienie decyzji w języku naturalnym."""
    supporting_data: dict[str, Any] = field(default_factory=dict)
    """Dane wspierające decyzję."""
    created_at: str = ""
    """ISO timestamp."""
    voting_result: VotingResult | None = None
    """Wynik ważonego głosowania (Enterprise)."""
    proof_block: ProofBlock | None = None
    """Blok w Proof Chain (Enterprise)."""
    decision_mode: DecisionMode = DecisionMode.AUTO_POST
    """Tryb decyzyjny (Enterprise)."""
    learning_record: LearningRecord | None = None
    """Rekord uczenia się dla Continuous Learning (Enterprise)."""
    cognitive_block: CognitiveProofBlock | None = None
    """Cognitive Audit Trail block (Enterprise — genialny pomysł)."""


# ═════════════════════════════════════════════════════════════════════════
# AgentDataExtraction — Rozszerzone struktury
# ═════════════════════════════════════════════════════════════════════════


class DataExtractionRequest(Struct, kw_only=True):
    """Żądanie ekstrakcji danych z dokumentu."""

    invoice_id: str
    """ID faktury."""
    file_path: str
    """Ścieżka do pliku."""
    file_type: str = ""
    """Typ pliku (pdf, jpg, png, xml)."""
    tenant_id: str = ""
    """ID tenant."""
    options: dict[str, Any] = field(default_factory=dict)
    """Opcje ekstrakcji (np. języki OCR, użyte silniki)."""


class CrossValidationResult(Struct, kw_only=True):
    """Wynik walidacji krzyżowej 4×4 — każde pole z 4 silników."""

    field_name: str
    """Nazwa pola."""
    values: dict[str, str] = field(default_factory=dict)
    """Wartości per silnik: {engine_name: value}."""
    consensus: str = ""
    """Wartość z konsensusu (3/4 lub 2/4 + Vision Guardian)."""
    consensus_ratio: float = 0.0
    """Stosunek zgody: 0.75 (3/4) lub 0.5 (2/4)."""
    confidence: float = 0.0
    """Pewność dla tego pola (0.0-1.0)."""
    issues: list[str] = field(default_factory=list)
    """Problemy walidacji dla tego pola."""


class DataExtractionResult(Struct, kw_only=True):
    """Wynik ekstrakcji danych z dokumentu.

    Rozszerzony o Enterprise:
    - cross_validation: Wyniki walidacji krzyżowej 4×4
    - template_match: Dopasowanie do wzorca faktury
    - learning_suggestions: Sugestie do Continuous Learning
    """

    invoice_id: str
    """ID faktury."""
    success: bool
    """Czy ekstrakcja się powiodła."""
    extracted_data: dict[str, Any] = field(default_factory=dict)
    """Wyekstrahowane dane (numer, data, NIP, kwoty, itd.)."""
    ocr_text: str = ""
    """Pełny tekst OCR."""
    confidence: float = 0.0
    """Ogólna pewność ekstrakcji (0.0 - 1.0)."""
    engine_results: dict[str, Any] = field(default_factory=dict)
    """Wyniki per silnik OCR."""
    document_type: str = ""
    """Typ dokumentu (INVOICE, RECEIPT, NOTE, OTHER)."""
    validation_issues: list[str] = field(default_factory=list)
    """Problemy walidacji (np. NIP nie przechodzi sumy kontrolnej)."""
    error: str = ""
    """Błąd (jeśli niepowodzenie)."""
    cross_validation: list[CrossValidationResult] = field(default_factory=list)
    """Wyniki walidacji krzyżowej 4×4 (Enterprise)."""
    template_match: dict[str, Any] = field(default_factory=dict)
    """Dopasowanie do wzorca faktury (Enterprise)."""
    field_confidences: dict[str, float] = field(default_factory=dict)
    """Indywidualne confidence per pole (Enterprise)."""


# ═════════════════════════════════════════════════════════════════════════
# AgentAnalytics — Rozszerzone struktury
# ═════════════════════════════════════════════════════════════════════════


class AnalyticsQuery(Struct, kw_only=True):
    """Zapytanie analityczne do AgentAnalytics."""

    query_id: str
    """ID zapytania."""
    query_type: str
    """Typ zapytania: sql, trend, anomaly, forecast, custom, daily_brief."""
    natural_language: str = ""
    """Pytanie w języku naturalnym."""
    sql_query: str = ""
    """SQL do wykonania (jeśli znany)."""
    params: dict[str, Any] = field(default_factory=dict)
    """Parametry zapytania."""
    time_range: dict[str, str] = field(default_factory=dict)
    """Zakres czasowy (from, to)."""
    context: dict[str, Any] = field(default_factory=dict)
    """Dodatkowy kontekst."""


class AnalyticsResult(Struct, kw_only=True):
    """Wynik analizy.

    Rozszerzony o Enterprise:
    - anomalies: Lista wykrytych anomalii z szczegółami
    - forecast: Prognoza (dla typu forecast)
    - daily_brief: Codzienny brief (dla typu daily_brief)
    """

    query_id: str
    """ID zapytania."""
    success: bool
    """Czy analiza się powiodła."""
    summary: str = ""
    """Podsumowanie w języku naturalnym."""
    data: list[dict[str, Any]] = field(default_factory=list)
    """Dane wynikowe."""
    anomalies: list[dict[str, Any]] = field(default_factory=list)
    """Wykryte anomalie z typem i severity."""
    sql_executed: str = ""
    """SQL który został wykonany."""
    model_used: str = ""
    """Model użyty do analizy."""
    error: str = ""
    """Błąd (jeśli niepowodzenie)."""
    forecast: dict[str, Any] = field(default_factory=dict)
    """Prognoza cash flow (Enterprise)."""
    daily_brief: str = ""
    """Codzienny brief finansowy NL (Enterprise)."""
    risk_flags: list[dict[str, Any]] = field(default_factory=list)
    """Flagi ryzyka wykryte proaktywnie (Enterprise)."""


# ═════════════════════════════════════════════════════════════════════════
# AgentQualityValidator — Rozszerzone struktury
# ═════════════════════════════════════════════════════════════════════════


class QualityCheckRequest(Struct, kw_only=True):
    """Żądanie walidacji jakości decyzji.

    Rozszerzone o Enterprise:
    - four_eyes_check: Czy wymagana jest 4-Eyes weryfikacja
    - liquidity_stress_test: Czy wykonać stress test płynności
    """

    decision_id: str
    """ID decyzji do walidacji."""
    proposed_decision: dict[str, Any]
    """Proponowana decyzja."""
    invoice_data: dict[str, Any] = field(default_factory=dict)
    """Dane faktury."""
    context: dict[str, Any] = field(default_factory=dict)
    """Dodatkowy kontekst."""
    checks: list[str] = field(default_factory=list)
    """Lista wymaganych kontroli (tax, fraud, esg, forecast, four_eyes)."""
    four_eyes_required: bool = False
    """Czy wymagana 4-Eyes weryfikacja (kwota > 50k PLN) (Enterprise)."""
    liquidity_stress_test: bool = False
    """Czy wykonać stress test płynności (Enterprise)."""


class QualityCheckResult(Struct, kw_only=True):
    """Wynik walidacji jakości.

    Rozszerzony o Enterprise:
    - four_eyes_verdict: Wynik 4-Eyes weryfikacji
    - liquidity_verdict: Wynik stress testu płynności
    - voting_result: Ważone głosowanie modeli
    """

    decision_id: str
    """ID decyzji."""
    overall_verdict: str
    """Ogólny werdykt: OK, WARNING, ERROR."""
    overall_risk_score: float = 0.0
    """Ogólny risk score (0.0 - 1.0)."""
    tax_verdict: dict[str, Any] = field(default_factory=dict)
    """Werdykt strażnika podatkowego."""
    fraud_verdict: dict[str, Any] = field(default_factory=dict)
    """Werdykt detektora oszustw."""
    esg_verdict: dict[str, Any] = field(default_factory=dict)
    """Werdykt analityka ryzyka."""
    forecast: dict[str, Any] = field(default_factory=dict)
    """Prognoza płynności."""
    recommendations: list[str] = field(default_factory=list)
    """Rekomendacje."""
    models_used: list[str] = field(default_factory=list)
    """Modele użyte do walidacji."""
    error: str = ""
    """Błąd (jeśli niepowodzenie)."""
    four_eyes_verdict: dict[str, Any] = field(default_factory=dict)
    """Wynik 4-Eyes weryfikacji (Enterprise)."""
    liquidity_verdict: dict[str, Any] = field(default_factory=dict)
    """Wynik stress testu płynności (Enterprise)."""
    voting_result: dict[str, Any] = field(default_factory=dict)
    """Ważone głosowanie modeli walidacyjnych (Enterprise)."""


# ═════════════════════════════════════════════════════════════════════════
# Cash Manager & Tax Engine — Struktury dla nowych agentów
# ═════════════════════════════════════════════════════════════════════════


class CashFlowForecast(Struct, kw_only=True):
    """Prognoza przepływów pieniężnych (AgentCashManager)."""

    horizon_days: int = 90
    """Horyzont prognozy w dniach."""
    scenario: str = "baseline"
    """Scenariusz: optimistic, baseline, pessimistic."""
    daily_balance: list[dict[str, Any]] = field(default_factory=list)
    """Dzienny stan konta."""
    min_balance: float = 0.0
    """Minimalny prognozowany stan konta."""
    alerts: list[dict[str, Any]] = field(default_factory=list)
    """Alerty (ryzyko niedoboru, przekroczenie limitu)."""
    confidence_interval: dict[str, float] = field(default_factory=dict)
    """Przedział ufności (p25, p50, p75)."""


class TaxCalculation(Struct, kw_only=True):
    """Wynik kalkulacji podatkowej (AgentTaxEngine)."""

    calculation_id: str
    """ID kalkulacji."""
    tax_type: str
    """Typ podatku: VAT, PIT, CIT."""
    amount: float = 0.0
    """Kwota podatku."""
    base_amount: float = 0.0
    """Podstawa opodatkowania."""
    rate: float = 0.0
    """Stawka podatkowa."""
    split_payment: bool = False
    """Czy wymagany split payment."""
    deadline: str = ""
    """Termin płatności."""
    details: dict[str, Any] = field(default_factory=dict)
    """Szczegóły kalkulacji."""


class VendorRiskScore(Struct, kw_only=True):
    """Ocena wiarygodności kontrahenta (AgentVendorIntelligence)."""

    nip: str
    """NIP kontrahenta."""
    score: float = 0.0
    """Ogólny risk score (0-100, 0 = brak ryzyka)."""
    vat_status: str = ""
    """Status VAT: active, suspended, removed."""
    white_list_verified: bool = False
    """Czy zweryfikowany na Białej Liście MF."""
    bank_accounts: list[str] = field(default_factory=list)
    """Lista rachunków bankowych."""
    gus_verified: bool = False
    """Czy dane zgodne z GUS BIR."""
    payment_history: dict[str, Any] = field(default_factory=dict)
    """Historia płatności."""
    flags: list[str] = field(default_factory=list)
    """Flagi ryzyka."""


class AssetClassification(Struct, kw_only=True):
    """Klasyfikacja środka trwałego (AgentFixedAssets)."""

    asset_id: str
    """ID środka trwałego."""
    classification: str = ""
    """Klasyfikacja: building, machinery, vehicle, it, intangible."""
    depreciation_method: str = "linear"
    """Metoda amortyzacji: linear, degressive, one_time."""
    depreciation_rate: float = 0.0
    """Roczna stawka amortyzacji."""
    useful_life_years: int = 0
    """Okres użytkowania w latach."""
    monthly_depreciation: float = 0.0
    """Miesięczny odpis amortyzacyjny."""


# ═════════════════════════════════════════════════════════════════════════
# ActionCard — GENIALNY POMYSŁ v5.1: "Zasada 1-Click CFO"
# ═════════════════════════════════════════════════════════════════════════


class ActionCardOption(Struct, kw_only=True):
    """Pojedyncza opcja na karcie decyzyjnej.

    Przedsiębiorca widzi tylko label i description.
    hidden_payload zawiera wszystkie techniczne parametry księgowe
    (konta, stawki VAT, reguły OPA) — niewidoczne dla użytkownika.
    """

    option_id: str
    """Unikalne ID opcji (uuid hex 8)."""
    label: str
    """Tekst przycisku — max 40 znaków, zrozumiały dla laika."""
    description: str = ""
    """Krótki opis pod przyciskiem — co się stanie po kliknięciu."""
    is_recommended: bool = False
    """Czy to rekomendacja AI (zielony przycisk)."""
    action_type: str = "confirm"
    """Typ akcji: confirm, alternative, reject, escalate."""
    hidden_payload: dict[str, Any] = field(default_factory=dict)
    """Ukryty payload z pełnymi parametrami księgowymi (JSON)."""
    trust_impact: float = 0.0
    """Wpływ na Trust Score przy wyborze tej opcji (+/-)."""


class ActionCard(Struct, kw_only=True):
    """Karta decyzyjna — JEDNA decyzja dla przedsiębiorcy.

    GENIALNY POMYSŁ v5.1 — "Zasada 1-Click CFO":
    Przedsiębiorca widzi kartę z 2-4 prostymi przyciskami.
    Agent wykonał 95% pracy — użytkownik tylko klika.

    Architektura:
    - AgentDecision (skomplikowany, techniczny) → ActionCard (prosty, ludzki)
    - Qwen3-Nano tłumaczy JSON na zrozumiałe opcje
    - Każdy przycisk ma ukryty payload z pełnymi parametrami księgowymi
    """

    card_id: str
    """Unikalne ID karty."""
    decision_id: str
    """Referencja do oryginalnej AgentDecision."""
    title: str
    """Nagłówek karty — 1 zdanie, co się dzieje."""
    summary: str
    """TL;DR — 2-3 zdania wyjaśnienia dla przedsiębiorcy (NIE księgowego)."""
    agent_name: str = "orchestrator"
    """Który agent wygenerował kartę."""
    document_type: str = ""
    """Typ dokumentu: INVOICE, RECEIPT, ASSET, TAX_ALERT, PAYMENT."""
    options: list[ActionCardOption] = field(default_factory=list)
    """2-4 opcje do wyboru (przyciski)."""
    trust_score: float = 0.0
    """Trust Score decyzji (0.0-1.0)."""
    decision_mode: DecisionMode = DecisionMode.ASK_USER
    """Tryb decyzyjny."""
    urgency: str = "normal"
    """Priorytet: critical, high, normal, low."""
    context: dict[str, Any] = field(default_factory=dict)
    """Dodatkowy kontekst: kwota, kontrahent, data."""
    created_at: str = ""
    """ISO timestamp utworzenia."""
    expires_at: str = ""
    """ISO timestamp wygaśnięcia (np. termin płatności)."""


class ActionCardFeed(Struct, kw_only=True):
    """Feed kart decyzyjnych — "skrzynka odbiorcza" przedsiębiorcy.

    Publikowany na ui.feed.pending przez ProactiveWorkflowScheduler.
    """

    cards: list[ActionCard] = field(default_factory=list)
    """Lista kart oczekujących na decyzję."""
    total_pending: int = 0
    """Łączna liczba oczekujących decyzji."""
    urgent_count: int = 0
    """Liczba pilnych (urgency=critical/high)."""
    generated_at: str = ""
    """ISO timestamp wygenerowania feedu."""
    greeting: str = ""
    """Powitanie od agenta (np. "Dzień dobry! Oto 3 decyzje na dziś")."""


class ActionCardResponse(Struct, kw_only=True):
    """Odpowiedź użytkownika na kartę decyzyjną.

    Publikowana na ui.feed.action po kliknięciu przycisku.
    """

    card_id: str
    """ID karty."""
    decision_id: str
    """ID decyzji."""
    selected_option_id: str
    """Którą opcję wybrał użytkownik."""
    selected_label: str = ""
    """Etykieta wybranej opcji."""
    user_comment: str = ""
    """Opcjonalny komentarz użytkownika."""
    responded_at: str = ""
    """ISO timestamp odpowiedzi."""


# ═════════════════════════════════════════════════════════════════════════
# Health & Monitoring
# ═════════════════════════════════════════════════════════════════════════


class AgentHealth(Struct, kw_only=True):
    """Status zdrowia agenta."""

    agent_name: str
    """Nazwa agenta."""
    status: str
    """Status: healthy, degraded, unhealthy."""
    models_loaded: int = 0
    """Liczba załadowanych modeli."""
    memory_mb: float = 0.0
    """Zużycie RAM w MB."""
    uptime_seconds: float = 0.0
    """Czas działania w sekundach."""
    last_heartbeat: str = ""
    """Ostatni heartbeat ISO timestamp."""
    error_count: int = 0
    """Liczba błędów od ostatniego restartu."""
    decisions_total: int = 0
    """Liczba decyzji od ostatniego restartu."""


# ═════════════════════════════════════════════════════════════════════════
# Helpers
# ═════════════════════════════════════════════════════════════════════════


def make_context(
    task_id: str,
    source: str,
    target: str,
    **kwargs: Any,
) -> AgentContext:
    """Utwórz AgentContext z domyślnymi wartościami."""
    import pendulum

    return AgentContext(
        task_id=task_id,
        source_agent=source,
        target_agent=target,
        timestamp=pendulum.now("UTC").isoformat(),
        **kwargs,
    )


def generate_decision_id() -> str:
    """Generuj unikalne ID decyzji."""
    return uuid.uuid4().hex[:16]


# ═════════════════════════════════════════════════════════════════════════
# Agent Knowledge Mesh v5.3 — Struktury EASP (Emergent Agent Swarm Protocol)
# ═════════════════════════════════════════════════════════════════════════


class MeshField(Struct, kw_only=True):
    """Pole w Collective Bayesian Field — współdzielone przez wszystkie agenty."""

    vendor_nip: str
    category: str = ""
    amount_range: str = ""
    alpha: float = 1.0
    beta: float = 1.0
    last_updated: str = ""
    updated_by_agent: str = ""
    total_decisions: int = 0
    auto_post_count: int = 0
    correction_count: int = 0

    @property
    def trust_score(self) -> float:
        total = self.alpha + self.beta
        return self.alpha / total if total > 0 else 0.5

    @property
    def confidence(self) -> float:
        total = self.alpha + self.beta
        if total <= 1:
            return 0.0
        variance = (self.alpha * self.beta) / (total**2 * (total + 1))
        return max(0.0, 1.0 - variance * 12)


class ExperienceRule(Struct, kw_only=True):
    """Reguła Cross-Agent Experience Replay — agent A uczy agenta B."""

    rule_id: str
    source_agent: str
    target_agent: str
    trigger_condition: str
    action: str
    params: dict[str, Any] = field(default_factory=dict)
    priority: int = 5
    created_at: str = ""
    hit_count: int = 0
    last_hit: str = ""
    embedding: list[float] = field(default_factory=list)
    active: bool = True


class RouteDecision(Struct, kw_only=True):
    """Decyzja Predictive Task Routera — optymalna ścieżka agentów."""

    vendor_nip: str
    trust_score: float = 0.5
    confidence: float = 0.0
    route: list[str] = field(default_factory=list)
    skip_agents: list[str] = field(default_factory=list)
    force_agents: list[str] = field(default_factory=list)
    circuit_breaker_open: bool = False
    threshold_adjustments: dict[str, float] = field(default_factory=dict)
    mesh_field: MeshField | None = None
    applied_rules: list[str] = field(default_factory=list)
    estimated_time_ms: float = 0.0


class MeshEvent(Struct, kw_only=True):
    """Zdarzenie w Knowledge Mesh — publikowane przez NATS JetStream."""

    event_id: str
    event_type: str
    source_agent: str
    payload: dict[str, Any] = field(default_factory=dict)
    timestamp: str = ""
    trace_id: str = ""
