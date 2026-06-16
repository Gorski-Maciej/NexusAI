# ═══════════════════════════════════════════════════════════════════════════════
# nexus_crypto — Python type stubs (.pyi)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Manual type stubs for the nexus_crypto package (Rust + PyO3 bridge).
# These stubs provide full type information for mypy and IDE autocomplete,
# eliminating the need for ``type: ignore[import-untyped]`` comments.
#
# ═══════════════════════════════════════════════════════════════════════════════

from __future__ import annotations

from typing import Any

# ── Custom exceptions ───────────────────────────────────────────────────────

class CryptoError(Exception):
    """Base exception for all nexus-crypto errors."""
class KeyLengthError(CryptoError):
    """Raised when key is not exactly 32 bytes."""
class DecryptionError(CryptoError):
    """Raised when decryption fails."""
class EncryptionError(CryptoError):
    """Raised when encryption fails."""
class IntegrityError(CryptoError):
    """Raised when AEAD integrity verification fails."""
class HashError(CryptoError):
    """Raised when a hashing operation fails."""

# ── Sha256Hasher (Rust-native when available) ────────────────────────────────

class Sha256Hasher:
    """Streaming SHA-256 hasher (Rust-native + Python fallback)."""
    def __init__(self) -> None: ...
    def update(self, data: bytes) -> None: ...
    def hexdigest(self) -> str: ...
    def digest(self) -> bytes: ...
    def copy(self) -> Sha256Hasher: ...

# ── Crypto primitives ───────────────────────────────────────────────────────

def encrypt(key: bytes, plaintext: bytes) -> bytes: ...
def decrypt(key: bytes, data: bytes) -> bytes: ...
def decrypt_into_sensitive(key: bytes, data: bytes) -> SensitiveBytes: ...
def hash_password(password: str) -> str: ...
def verify_password(password: str, hash_str: str) -> bool: ...
def sha256(data: bytes) -> str: ...
def hmac_sha256(key: bytes, data: bytes) -> bytes: ...
def blake2b(data: bytes, digest_size: int = 64) -> bytes: ...
def generate_key() -> bytes: ...
def derive_key(password: str, salt: bytes | None = None) -> tuple[bytes, bytes]: ...

# ── Secure Memory (Rust-native) — RAII auto-zeroizing buffers ───────────────

class SensitiveBytes:
    """RAII-protected sensitive byte buffer (auto-zeroized on drop)."""
    def __init__(self, size: int) -> None: ...
    @staticmethod
    def from_bytes(data: bytes) -> SensitiveBytes: ...
    def hexdigest(self) -> str: ...
    def to_bytes(self) -> bytes: ...
    def __len__(self) -> int: ...
    def __repr__(self) -> str: ...

class MlockedVec:
    """Memory-locked sensitive buffer with auto-zeroize on drop."""
    @staticmethod
    def new(size: int) -> MlockedVec: ...
    @staticmethod
    def from_bytes(data: bytes) -> MlockedVec: ...
    def zeroize_and_unlock(self) -> None: ...
    def is_locked(self) -> bool: ...
    def to_bytes(self) -> bytes: ...
    def __len__(self) -> int: ...
    def __repr__(self) -> str: ...

def protect_read(addr: int, length: int) -> None: ...
def protect_rw(addr: int, length: int) -> None: ...
def protect_none(addr: int, length: int) -> None: ...

# ── Tax Math Engine (Rust-native when available) ────────────────────────────

def to_grosze(amount: str) -> int: ...
def to_zlotowki(grosze: int) -> str: ...
def multiply_net_by_vat(net_grosze: int, vat_rate: str) -> int: ...
def add_tax(net_grosze: int, vat_grosze: int) -> int: ...
def calculate_vat_by_policy(positions: list, vat_rate: str, rounding_level: str) -> int: ...
def validate_invariants(positions: list, summary: Any) -> Any: ...

class InvoicePositions:
    """A single invoice line item in grosze."""
    net_grosze: int
    vat_rate: str
    def __init__(self, net_grosze: int, vat_rate: str) -> None: ...
    def vat_grosze(self) -> int: ...
    def __repr__(self) -> str: ...

class InvoiceSummary:
    """Invoice totals in grosze."""
    netto_grosze: int
    vat_grosze: int
    brutto_grosze: int
    def __init__(self, netto_grosze: int, vat_grosze: int, brutto_grosze: int) -> None: ...
    def __repr__(self) -> str: ...

class ValidationResult:
    """Result of invariant validation."""
    is_valid: bool
    error_message: str
    def __init__(self, is_valid: bool, error_message: str = "") -> None: ...
    def __bool__(self) -> bool: ...
    def __repr__(self) -> str: ...

class RoundingPolicy:
    """Rounding strategy constants and logic."""
    POSITION: str = "position"
    TOTAL: str = "total"
    @staticmethod
    def calculate(positions: list, vat_rate: str, rounding_level: str) -> int: ...

class TaxMathEngine:
    """Infallible tax math — integer-only, ROUND_HALF_UP, no floats."""
    @staticmethod
    def to_grosze(amount: str) -> int: ...
    @staticmethod
    def to_zlotowki(grosze: int) -> str: ...
    @staticmethod
    def multiply_net_by_vat(net_grosze: int, vat_rate: str) -> int: ...
    @staticmethod
    def add_tax(net_grosze: int, vat_grosze: int) -> int: ...
    @staticmethod
    def calculate_vat_by_policy(positions: list, vat_rate: str, rounding_level: str) -> int: ...
    @staticmethod
    def validate_invariants(positions: list, summary: Any) -> Any: ...

# ── JWT verification (Rust-native when available) ────────────────────────────

def verify_jwt(
    token: str,
    secret: str,
    required_issuer: str | None = None,
    required_audience: str | None = None,
) -> dict | None: ...
def decode_jwt_header(token: str) -> dict | None: ...

# ── Tax Pipeline (Rust-native when available) ──────────────────────────────

class ContextInterpreter:
    """Builds flat context dict from invoice data for rule evaluation."""
    @staticmethod
    def build(invoice_data_json: str) -> str: ...

class DecisionTraceHasher:
    """SHA-256 hash chain computation for decision trace."""
    @staticmethod
    def compute_hash(
        previous_hash: str,
        trace_id: str,
        transaction_id: str,
        context_json: str,
        verdict_json: str,
        timestamp_iso: str,
        calculation_input: str = ...,
        calculation_output: str = ...,
        invariants_result: str = ...,
        risk_verdict: str = ...,
    ) -> str: ...
    @staticmethod
    def genesis_hash() -> str: ...

class AuditParams:
    """Optional audit trail metadata for pipeline results."""
    current_hash: str
    context_json: str
    verdict_json: str
    evaluated_rules_json: str
    def __init__(
        self,
        current_hash: str,
        context_json: str,
        verdict_json: str,
        evaluated_rules_json: str,
    ) -> None: ...
    def __repr__(self) -> str: ...

class PipelineComputeResult:
    """Result of the synchronous pipeline computation (all 5 steps).
    
    Audit trail fields are grouped in the optional ``audit_params`` field.
    """
    is_valid: bool
    error_message: str
    netto_grosze: int
    vat_grosze: int
    brutto_grosze: int
    positions_net_grosze: list[int]
    calculation_input_json: str
    calculation_output_json: str
    invariants_result_json: str
    audit_params: AuditParams | None
    matched_rule_id: str
    routing: str
    routing_reason: str
    parsed_vat_rate: str
    parsed_rounding_level: str
    def __init__(
        self,
        is_valid: bool,
        error_message: str,
        netto_grosze: int,
        vat_grosze: int,
        brutto_grosze: int,
        positions_net_grosze: list[int],
        calculation_input_json: str,
        calculation_output_json: str,
        invariants_result_json: str,
        audit_params: AuditParams | None = ...,
        matched_rule_id: str = ...,
        routing: str = ...,
        routing_reason: str = ...,
        parsed_vat_rate: str = ...,
        parsed_rounding_level: str = ...,
    ) -> None: ...
    def __repr__(self) -> str: ...

def compute_pipeline(
    vat_rate: str,
    rounding_level: str,
    positions_net_str: list[str],
    previous_hash: str | None = ...,
    context_json: str | None = ...,
    verdict_json: str | None = ...,
    trace_id: str | None = ...,
    transaction_id: str | None = ...,
    timestamp_iso: str | None = ...,
) -> PipelineComputeResult: ...

def evaluate_rules(
    rules_json: str,
    context_json: str,
) -> str: ...

def run_full_pipeline(
    invoice_data_json: str,
    rules_json: str,
    previous_hash: str | None = ...,
    trace_id: str | None = ...,
    transaction_id: str | None = ...,
    timestamp_iso: str | None = ...,
) -> PipelineComputeResult: ...

# ── Trace Logger (Rust-native when available) ──────────────────────────────

class PreparedLog:
    """Pre-computed decision trace log entry, ready for DuckDB INSERT."""
    trace_id: str
    transaction_id: str
    rule_id: str
    context_json: str
    verdict_json: str
    calculation_input: str
    calculation_output: str
    invariants_result: str
    risk_verdict: str
    decision_trace: str
    trace_json: str
    previous_hash: str
    current_hash: str
    timestamp: str
    def values(self) -> list[str]: ...
    def __repr__(self) -> str: ...

class DecisionTraceLogger:
    """Append-only cryptographic audit trail for tax decisions.
    
    Prepares hash-chained log entries (no I/O). DuckDB INSERT is caller's
    responsibility.
    """
    @staticmethod
    def prepare_log(
        transaction_id: str,
        previous_hash: str,
        context_json: str,
        verdict_json: str,
        rule_id: str = ...,
        calculation_input: str = ...,
        calculation_output: str = ...,
        invariants_result: str = ...,
        risk_verdict: str = ...,
        decision_trace: str = ...,
        trace_json: str = ...,
        timestamp_iso: str | None = ...,
    ) -> PreparedLog: ...
    @staticmethod
    def get_trace_query() -> str: ...
    @staticmethod
    def latest_hash_query() -> str: ...
    @staticmethod
    def entry_count_query() -> str: ...

def compute_current_hash(
    previous_hash: str,
    trace_id: str,
    transaction_id: str,
    context_json: str,
    verdict_json: str,
    timestamp_iso: str,
    calculation_input: str = ...,
    calculation_output: str = ...,
    invariants_result: str = ...,
    risk_verdict: str = ...,
) -> str: ...

def genesis_hash() -> str: ...

def verify_chain_integrity(entries_json: str) -> str: ...

# ── Rule Engine (Rust native) — PriorityEngine first-match-wins ──────────

class PriorityEngine:
    """First-match-wins rule evaluation with deterministic sorting."""
    @staticmethod
    def resolve(rules_json: str, context_json: str) -> str: ...
    @staticmethod
    def sort_rules(rules_json: str) -> str: ...
    @staticmethod
    def validate_priorities(rules_json: str) -> str: ...

class RulesEngine:
    """Comprehensive rule evaluation pipeline — self-contained SQL evaluator."""
    @staticmethod
    def evaluate(rules_json: str, context_json: str) -> str: ...
    @staticmethod
    def batch_evaluate(rules_json: str, contexts_json: str) -> str: ...
    @staticmethod
    def validate(rules_json: str) -> str: ...
    @staticmethod
    def sort_rules(rules_json: str) -> str: ...

class TemporalManager:
    """Temporal rule filtering and validation in pure Rust."""
    @staticmethod
    def filter_rules(rules_json: str, date_str: str) -> str: ...
    @staticmethod
    def sort_by_temporal(rules_json: str) -> str: ...
    @staticmethod
    def validate_overlap(rules_json: str) -> str: ...
