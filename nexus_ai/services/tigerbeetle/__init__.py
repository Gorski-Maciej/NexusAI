"""TigerBeetle -- bezpieczny, lokalny silnik księgowy (podwójny zapis).

Zgodnie z aa3fvcx.txt oraz audytem TigerBeetle 2026:
- TigerBeetle: matematycznie gwarantowana integralność finansowa
- komunikacja przez gniazdo UNIX
- amount jako int (grosze), bez Decimal
- Linked transfers (atomic chains)
- Natywne two-phase transfers
- Batch transfers (do 8190)
- Multi-ledger isolation
"""

from __future__ import annotations

from nexus_ai.services.tigerbeetle.client import (
    LEDGER,
    TRANSFER_CODE,
    TigerBeetleClient,
    TigerBeetleMapper,
)
from nexus_ai.services.tigerbeetle.ledger_initializer import LedgerInitializer
from nexus_ai.services.tigerbeetle.models import (
    Base,
    CompanyPartner,
    CompanyProfile,
    FinancialPeriod,
    FinancialPeriodStatus,
    LedgerTransferCache,
    LegalForm,
    TaxForm,
    TaxPolicy,
    TransferStatus,
)

__all__ = [
    # Konfiguracja
    "LEDGER",
    "TRANSFER_CODE",
    # Klient
    "TigerBeetleClient",
    "TigerBeetleMapper",
    # Inicjalizacja
    "LedgerInitializer",
    # Modele SQLite (cache)
    "CompanyProfile",
    "CompanyPartner",
    "TaxPolicy",
    "LedgerTransferCache",
    "FinancialPeriod",
    "TransferStatus",
    "FinancialPeriodStatus",
    "LegalForm",
    "TaxForm",
    "Base",
]
