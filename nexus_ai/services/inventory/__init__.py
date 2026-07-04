"""Inventory domain -- amortyzacja, inwentaryzacja FIFO, shadow resources.

Re-exports from flat service files for backward compatibility.
"""

from nexus_ai.services.fixed_assets import (  # noqa: F401
    FixedAsset,
    FixedAssetsService,
)
from nexus_ai.services.inventory_fifo import InventoryFIFOService  # noqa: F401
from nexus_ai.services.shadow_resource_correlation import (  # noqa: F401
    ShadowResourceCorrelation,
)
