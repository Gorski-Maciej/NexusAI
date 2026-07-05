"""nexus_ai/agents — Multi-agent AI system dla NexusAI.

Architektura "zero zaufania do pojedynczego modelu":
- 10 wyspecjalizowanych agentów AI
- Komunikacja przez NATS JetStream
- Modele GGUF przez llama-cpp-python
- Struktury danych: msgspec.Struct
- Continuous Learning Framework
- Proof Chain SHA-256
- Adaptive Thresholds (Bayesian)
- 4-Eyes Principle
- Decision Cache (diskcache + sqlite-vec)

Enterprise features (AGENT_SYSTEM_ENTERPRISE.txt):
- Bayesian Trust Score z aktualizacją po każdej decyzji
- Adaptive Thresholds per kontrahent
- Weighted Voting między modelami
- 4 poziomy autonomii (L0-L3)
- Memory Systems (Episodic, Semantic, Procedural, Working)
- Active Learning Loop (korekta → nauka → poprawa)
- Proof Chain SHA-256 dla niepodważalnego audytu
- 4-Eyes Principle dla kwot > 50k PLN
- Cross-Validation Matrix 4×4 dla OCR
- OpenTelemetry + Prometheus monitoring
"""

from nexus_ai.agents.models import (
    AgentCommand,
    AgentContext,
    AgentDecision,
    AgentHealth,
    AgentMessage,
    AnalyticsQuery,
    AnalyticsResult,
    AssetClassification,
    AutonomyConfig,
    AutonomyLevel,
    BayesianTrustScore,
    CashFlowForecast,
    ConfidenceVote,
    CrossValidationResult,
    DataExtractionRequest,
    DataExtractionResult,
    DecisionVerdict,
    FeedbackType,
    LearningConfig,
    LearningRecord,
    MemoryQuery,
    MemoryRecord,
    MemoryResult,
    MemoryType,
    ProofBlock,
    ProofChain,
    PropagationLevel,
    QualityCheckRequest,
    QualityCheckResult,
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
from nexus_ai.agents.topics import AgentTopic, JETSTREAM_STREAMS
from nexus_ai.agents.base import (
    BaseAgent,
    ContinuousLearningProvider,
    DecisionCache,
    ProofChainManager,
)

__all__ = [
    # Struktury danych
    "AgentCommand",
    "AgentContext",
    "AgentDecision",
    "AgentHealth",
    "AgentMessage",
    "AnalyticsQuery",
    "AnalyticsResult",
    "AssetClassification",
    "AutonomyConfig",
    "AutonomyLevel",
    "BayesianTrustScore",
    "CashFlowForecast",
    "ConfidenceVote",
    "CrossValidationResult",
    "DataExtractionRequest",
    "DataExtractionResult",
    "DecisionVerdict",
    "FeedbackType",
    "LearningConfig",
    "LearningRecord",
    "MemoryQuery",
    "MemoryRecord",
    "MemoryResult",
    "MemoryType",
    "ProofBlock",
    "ProofChain",
    "PropagationLevel",
    "QualityCheckRequest",
    "QualityCheckResult",
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
    # Agenci
    "AgentOrchestrator",
    "AgentDataExtraction",
    "AgentAnalytics",
    "AgentQualityValidator",
    # Topiki
    "AgentTopic",
    "JETSTREAM_STREAMS",
]
