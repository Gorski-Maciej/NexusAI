"""nexus_ai/agents — Multi-agent AI system for NexusAI.

Architektura "zero zaufania do pojedynczego modelu":
- AgentOrchestrator — centralny koordynator (CFO)
- AgentDataExtraction — potrójny OCR + walidacja krzyżowa
- AgentAnalytics — analityka finansowa przez DuckDB
- AgentQualityValidator — weryfikacja decyzji (Guardian)

Komunikacja: NATS JetStream przez Taskiq.
Modele: GGUF przez llama-cpp-python.
Struktury danych: msgspec.Struct.
"""

from nexus_ai.agents.models import (
    AgentCommand,
    AgentContext,
    AgentDecision,
    AgentMessage,
    AnalyticsQuery,
    AnalyticsResult,
    DataExtractionRequest,
    DataExtractionResult,
    DecisionVerdict,
    QualityCheckRequest,
    QualityCheckResult,
    TrustScore,
)
from nexus_ai.agents.orchestrator import AgentOrchestrator
from nexus_ai.agents.extraction import AgentDataExtraction
from nexus_ai.agents.analytics import AgentAnalytics
from nexus_ai.agents.quality_validator import AgentQualityValidator
from nexus_ai.agents.topics import AgentTopic

__all__ = [
    "AgentCommand",
    "AgentContext",
    "AgentDecision",
    "AgentMessage",
    "AgentTopic",
    "AnalyticsQuery",
    "AnalyticsResult",
    "DataExtractionRequest",
    "DataExtractionResult",
    "DecisionVerdict",
    "QualityCheckRequest",
    "QualityCheckResult",
    "TrustScore",
    "AgentOrchestrator",
    "AgentDataExtraction",
    "AgentAnalytics",
    "AgentQualityValidator",
]
