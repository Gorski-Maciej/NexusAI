"""nexus_ai/agents — Multi-agent AI system dla NexusAI.

Zgodnie z aa3fvcx.txt:
- 5 wyspecjalizowanych agentów AI (NIE 10)
- JEDEN poziom automatyzacji: DecisionMode (AUTO_POST / SUGGEST / ASK_USER)
- Komunikacja przez NATS JetStream
- Modele GGUF przez llama-cpp-python
- Struktury danych: msgspec.Struct
- Continuous Learning Framework (jeden poziom uczenia)
- Proof Chain SHA-256
- GENIALNY POMYSŁ: Cognitive Audit Trail — samouzdrawiający się łańcuch dowodowy
- Adaptive Thresholds (Bayesian)
- 4-Eyes Principle
- Decision Cache (diskcache + sqlite-vec)
- GENIALNY POMYSŁ v5.2: Progressive Autonomy — agent rośnie z przedsiębiorcą

Architektura "zero zaufania do pojedynczego modelu":
- Agent Orkiestrator (Granite 3.2 3B + Guardian 0.5B + Qwen3-Nano 0.5B)
- Agent Ekstrakcji Danych (Triple OCR + Vision Guardian + ModernBERT-NER)
- Agent Analityczny (Hrida-T2SQL + Granite 3.2 + Fin-RWKV-169M)
- Agent Walidator Jakości (Tax Guardian + Fraud GraphSAGE + FinBERT-ESG + Lag-Llama)
- Agent ds. Środków Trwałych (Amortyzator-KŚT 0.2B)

Technologie — wyłącznie z RAPORT_TECHNOLOGII_NEXUSAI.txt:
- llama-cpp-python, NATS JetStream, Taskiq, DuckDB, SQLite+SQLCipher,
  sqlite-vec, TigerBeetle, msgspec, stamina, nexus-crypto, OPA+Rego
"""

from nexus_ai.agents.models import (
    ActionCard,
    ActionCardFeed,
    ActionCardOption,
    ActionCardResponse,
    AgentCommand,
    AgentContext,
    AgentDecision,
    AgentHealth,
    AgentMessage,
    AnalyticsQuery,
    AnalyticsResult,
    AssetClassification,
    BayesianTrustScore,
    CashFlowForecast,
    CashFlowPhase,
    CognitiveProofBlock,
    ConfidenceVote,
    ContextDimension,
    CrossValidationResult,
    DashboardState,
    DataExtractionRequest,
    DataExtractionResult,
    DecisionMode,
    DecisionVerdict,
    ExecutiveSummary,
    ExecutiveSummaryItem,
    ExperienceRule,
    FeedbackType,
    LearningConfig,
    LearningRecord,
    MemoryQuery,
    MemoryRecord,
    MemoryResult,
    MemoryType,
    MeshEvent,
    MeshField,
    ProofBlock,
    ProofChain,
    QualityCheckRequest,
    QualityCheckResult,
    RouteDecision,
    StrategicMode,
    StrategicRecommendation,
    TaxCalculation,
    TrustScore,
    VendorRiskScore,
    VotingResult,
    make_context,
)
from nexus_ai.agents.orchestrator import AgentOrchestrator
from nexus_ai.agents.extraction import AgentDataExtraction
from nexus_ai.agents.analytics import AgentAnalytics
from nexus_ai.agents.quality_validator import AgentQualityValidator
from nexus_ai.agents.error_handbook import DynamicErrorHandbook, HandbookExample, HandbookQuery
from nexus_ai.agents.proactive_workflow import (
    ActionCardGenerator,
    ProactiveWorkflowScheduler,
    ResourceOptimizer,
    WorkflowExecution,
    WorkflowManager,
    WorkflowStatus,
    WorkflowType,
)
from nexus_ai.agents.user_decision_profile import (
    AmountThreshold,
    CategoryPreference,
    DecisionPattern,
    UserDecisionProfile,
    VendorTrustProfile,
    WeeklyAutonomyReport,
)
from nexus_ai.agents.topics import AgentTopic, JETSTREAM_STREAMS
from nexus_ai.agents.base import (
    BaseAgent,
    ContinuousLearningProvider,
    DecisionCache,
    ProofChainManager,
)
from nexus_ai.agents.knowledge_mesh import (
    CollectiveBayesianField,
    CrossAgentExperienceReplay,
    KnowledgeMesh,
    MeshProtocol,
    PredictiveTaskRouter,
)
from nexus_ai.agents.decision_trace import (
    ConfidenceCalibrator,
    DecisionSpan,
    DecisionTrace,
    DecisionTracer,
    EnsembleResult,
    EnsembleVote,
    FeedbackLoop,
    MultiModelEnsemble,
)
from nexus_ai.agents.telemetry_store import AgentTelemetryStore
# GENIALNY POMYSŁ v6.0: Silent Partner
from nexus_ai.agents.strategy_engine import StrategyEngine
from nexus_ai.agents.executive_summary import ExecutiveSummaryGenerator

__all__ = [
    # Struktury danych
    "ActionCard",
    "ActionCardFeed",
    "ActionCardOption",
    "ActionCardResponse",
    "AgentCommand",
    "AgentContext",
    "AgentDecision",
    "AgentHealth",
    "AgentMessage",
    "AnalyticsQuery",
    "AnalyticsResult",
    "AssetClassification",
    "BayesianTrustScore",
    "CashFlowForecast",
    "CognitiveProofBlock",
    "ConfidenceVote",
    "CrossValidationResult",
    "DataExtractionRequest",
    "DataExtractionResult",
    "DecisionMode",
    "DecisionVerdict",
    "ExperienceRule",
    "FeedbackType",
    "LearningConfig",
    "LearningRecord",
    "MemoryQuery",
    "MemoryRecord",
    "MemoryResult",
    "MemoryType",
    "MeshEvent",
    "MeshField",
    "ProofBlock",
    "ProofChain",
    "QualityCheckRequest",
    "QualityCheckResult",
    "RouteDecision",
    "TaxCalculation",
    "TrustScore",
    "VendorRiskScore",
    "VotingResult",
    "make_context",
    # Klasy bazowe
    "BaseAgent",
    "ContinuousLearningProvider",
    "DecisionCache",
    "ProofChainManager",
    # GENIALNY POMYSŁ v5.3: Agent Knowledge Mesh
    "CollectiveBayesianField",
    "CrossAgentExperienceReplay",
    "KnowledgeMesh",
    "MeshProtocol",
    "PredictiveTaskRouter",
    # GENIALNY POMYSŁ v5.4: Decision Protocol
    "AgentTelemetryStore",
    "ConfidenceCalibrator",
    "DecisionSpan",
    "DecisionTrace",
    "DecisionTracer",
    "EnsembleResult",
    "EnsembleVote",
    "FeedbackLoop",
    "MultiModelEnsemble",
    # GENIALNY POMYSŁ v6.0: Silent Partner ("Cichy Wspólnik")
    "CashFlowPhase",
    "ContextDimension",
    "DashboardState",
    "ExecutiveSummary",
    "ExecutiveSummaryGenerator",
    "ExecutiveSummaryItem",
    "StrategicMode",
    "StrategicRecommendation",
    "StrategyEngine",
    # GENIALNY POMYSŁ: Dynamiczny Podręcznik Błędów
    "DynamicErrorHandbook",
    "HandbookExample",
    "HandbookQuery",
    # GENIALNY POMYSŁ v5.1: ActionCardGenerator ("1-Click CFO")
    "ActionCardGenerator",
    # GENIALNY POMYSŁ v5.2: Progressive Autonomy Engine
    "AmountThreshold",
    "CategoryPreference",
    "DecisionPattern",
    "UserDecisionProfile",
    "VendorTrustProfile",
    "WeeklyAutonomyReport",
    # GENIALNY POMYSŁ v5.0: Proactive Workflow Engine
    "ProactiveWorkflowScheduler",
    "ResourceOptimizer",
    "WorkflowExecution",
    "WorkflowManager",
    "WorkflowStatus",
    "WorkflowType",
    # Agenci (5 — zgodnie z aa3fvcx.txt)
    "AgentOrchestrator",         # 1. Centralny Mózg i CFO
    "AgentDataExtraction",       # 2. Forteca Precyzji (OCR + KSeF)
    "AgentAnalytics",            # 3. Sztab Analityczny (cashflow + vendor intel)
    "AgentQualityValidator",     # 4. Trójwarstwowa Tarcza (tax + fraud + ESG)
    # Agent nr 5 (FixedAssets) — w nexus_ai/services/fixed_assets.py
    # Topiki
    "AgentTopic",
    "JETSTREAM_STREAMS",
]
