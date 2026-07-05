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
    CognitiveProofBlock,
    ConfidenceVote,
    CrossValidationResult,
    DataExtractionRequest,
    DataExtractionResult,
    DecisionMode,
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
from nexus_ai.agents.error_handbook import DynamicErrorHandbook, HandbookExample, HandbookQuery
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
    "BayesianTrustScore",
    "CashFlowForecast",
    "CognitiveProofBlock",
    "ConfidenceVote",
    "CrossValidationResult",
    "DataExtractionRequest",
    "DataExtractionResult",
    "DecisionMode",
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
    # GENIALNY POMYSŁ: Dynamiczny Podręcznik Błędów
    "DynamicErrorHandbook",
    "HandbookExample",
    "HandbookQuery",
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
