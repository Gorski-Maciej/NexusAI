"""Tax domain -- podatki, symulacje, strategie, KSeF, OPA.

Re-exports from flat service files for backward compatibility.
"""

from nexus_ai.services.ksef_generator import generate_ksef_xml, KsefGenerator  # noqa: F401
from nexus_ai.services.opa_policy_generator import OpaPolicyGenerator  # noqa: F401
from nexus_ai.services.tax_simulator import TaxSimulator  # noqa: F401
from nexus_ai.services.tax_strategies import StrategyContext, StrategyRegistry  # noqa: F401
from nexus_ai.services.vat_reconciliation import VATReconciliationEngine  # noqa: F401
from nexus_ai.services.white_list_service import WhiteListService  # noqa: F401
