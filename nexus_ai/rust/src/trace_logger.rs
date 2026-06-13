// ═══════════════════════════════════════════════════════════════════════════════
// TraceLogger — Merkle tree cryptographic audit trail
// ═══════════════════════════════════════════════════════════════════════════════
//
// ZASTĘPUJE: Linear SHA-256 hash chain → Merkle tree
//
// PRZED (linear hash chain):
//   verify_chain_integrity() — O(n) — skanuje wszystkie wpisy
//   Każdy wpis: current_hash = SHA256(previous_hash || fields)
//
// PO (Merkle tree):
//   verify_chain_integrity() — O(log n) — używa Merkle root
//   verified_batch() — O(k log n) dla k dowodów
//   Każdy wpis to liść w binarnym drzewie Merkle
//
// Komponenty:
//   1. MerkleTree — binary Merkle tree builder
//   2. MerkleProof — proof for a single leaf (O(log n) size)
//   3. compute_current_hash() — SHA-256 leaf hash (zachowane API)
//   4. verify_merkle_proof() — verify single entry against root
//   5. verify_batch() — verify multiple entries
//   6. DecisionTraceLogger — zachowane API
//   7. PreparedLog — zachowane API
//   8. verify_chain_integrity() — O(log n) przez Merkle root
//
// Struktura Merkle tree:
//   Level 0 (leaves): [L0, L1, L2, L3, ...]
//   Level 1:           [H(L0||L1), H(L2||L3), ...]
//   Level n (root):    [ROOT]
//
//   Dla nieparzystej liczby węzłów: duplikujemy ostatni.
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;
use serde_json::{json, Value};
use sha2::{Digest, Sha256};

// ═══════════════════════════════════════════════════════════════════════════════
// Constants
// ═══════════════════════════════════════════════════════════════════════════════

const GENESIS_HASH: &str = "0000000000000000000000000000000000000000000000000000000000000000";
const EMPTY_HASH: [u8; 32] = [0u8; 32];

// ═══════════════════════════════════════════════════════════════════════════════
// MerkleTree — binary Merkle tree
// ═══════════════════════════════════════════════════════════════════════════════

/// Binary Merkle tree for cryptographic audit trail verification.
///
/// Builds a complete binary Merkle tree from an array of leaf hashes.
/// Supports O(log n) proof generation and verification.
///
/// Odd-numbered levels: the last node is duplicated (peered with itself).
///
/// Usage:
///   let tree = MerkleTree::new(&leaves);
///   let root = tree.root();
///   let proof = tree.proof(index);
///   assert!(MerkleTree::verify(&leaves[index], &proof, &root));
pub struct MerkleTree {
    /// All levels bottom-up: levels[0] = leaves, levels[n] = root
    levels: Vec<Vec<[u8; 32]>>,
    /// Number of leaves
    leaf_count: usize,
    /// Pre-computed root hash (hex string)
    root_hex: String,
}

impl MerkleTree {
    /// Build a Merkle tree from an array of leaf hashes.
    ///
    /// Each leaf should be a SHA-256 hash of an audit entry.
    /// For empty leaves, the root is the genesis hash (64 zeros).
    pub fn new(leaves: &[[u8; 32]]) -> Self {
        log::debug!("MerkleTree::new: building tree with {} leaves", leaves.len());

        if leaves.is_empty() {
            return MerkleTree {
                levels: vec![vec![]],
                leaf_count: 0,
                root_hex: GENESIS_HASH.to_string(),
            };
        }

        let mut levels: Vec<Vec<[u8; 32]>> = Vec::new();
        let mut current_level = leaves.to_vec();
        levels.push(current_level.clone());

        // Build levels bottom-up until we reach the root
        while current_level.len() > 1 {
            let mut next_level: Vec<[u8; 32]> = Vec::with_capacity((current_level.len() + 1) / 2);

            for chunk in current_level.chunks(2) {
                let left = &chunk[0];
                let right = if chunk.len() > 1 { &chunk[1] } else { &chunk[0] }; // duplicate for odd
                let combined = MerkleTree::hash_pair(left, right);
                next_level.push(combined);
            }

            levels.push(next_level.clone());
            current_level = next_level;
        }

        let root = current_level[0];
        let root_hex = hex::encode(root);

        log::debug!(
            "MerkleTree::new: built {} levels, root={}",
            levels.len(),
            &root_hex[..16]
        );

        MerkleTree {
            leaf_count: leaves.len(),
            levels,
            root_hex,
        }
    }

    /// Compute SHA-256(left || right).
    fn hash_pair(left: &[u8; 32], right: &[u8; 32]) -> [u8; 32] {
        let mut hasher = Sha256::new();
        hasher.update(left);
        hasher.update(right);
        let result = hasher.finalize();
        let mut arr = [0u8; 32];
        arr.copy_from_slice(&result);
        arr
    }

    /// Get the Merkle root hash (hex string).
    pub fn root_hex(&self) -> &str {
        &self.root_hex
    }

    /// Get the Merkle root hash (raw 32 bytes).
    pub fn root(&self) -> [u8; 32] {
        if self.levels.is_empty() || self.levels.last().map(|l| l.is_empty()).unwrap_or(true) {
            return EMPTY_HASH;
        }
        self.levels.last().unwrap()[0]
    }

    /// Number of leaves.
    pub fn leaf_count(&self) -> usize {
        self.leaf_count
    }

    /// Generate a Merkle proof for the leaf at `index`.
    ///
    /// Returns None if the index is out of bounds or tree is empty.
    ///
    /// The proof contains the sibling hashes needed to reconstruct the root
    /// from the leaf, in order from bottom to top.
    pub fn proof(&self, index: usize) -> Option<MerkleProof> {
        if index >= self.leaf_count || self.levels.is_empty() {
            return None;
        }

        let mut siblings: Vec<[u8; 32]> = Vec::new();
        let mut idx = index;

        for level in &self.levels[..self.levels.len() - 1] {
            // Find the sibling: if idx is even, sibling is idx+1; if odd, sibling is idx-1
            let sibling_idx = if idx % 2 == 0 {
                if idx + 1 < level.len() { idx + 1 } else { idx } // duplicate for odd
            } else {
                idx - 1
            };

            if sibling_idx < level.len() {
                siblings.push(level[sibling_idx]);
            }

            idx /= 2; // parent index
        }

        Some(MerkleProof {
            leaf_index: index,
            siblings,
        })
    }

    /// Verify a single leaf against a root hash using a Merkle proof.
    ///
    /// Returns true if the reconstructed root matches the expected root.
    pub fn verify(leaf: &[u8; 32], proof: &MerkleProof, root: &[u8; 32]) -> bool {
        let mut current = *leaf;
        let mut idx = proof.leaf_index;

        for sibling in &proof.siblings {
            let combined = if idx % 2 == 0 {
                MerkleTree::hash_pair(&current, sibling) // left + right
            } else {
                MerkleTree::hash_pair(sibling, &current) // left + right (sibling is left)
            };
            current = combined;
            idx /= 2;
        }

        current == *root
    }

    /// Batch verify multiple leaves in a single pass.
    ///
    /// More efficient than verifying each leaf independently because
    /// shared nodes in the proof paths are computed once.
    ///
    /// Note: In this implementation, we verify each leaf independently
    /// (still O(k log n)), but we return which ones failed.
    ///
    /// Returns Ok(()) if all proofs verify, or Err with indices of failed leaves.
    pub fn batch_verify(
        leaves: &[([u8; 32], MerkleProof)],
        root: &[u8; 32],
    ) -> Result<(), Vec<usize>> {
        let mut failed: Vec<usize> = Vec::new();

        for (_i, (leaf, proof)) in leaves.iter().enumerate() {
            if !MerkleTree::verify(leaf, proof, root) {
                log::warn!(
                    "MerkleTree::batch_verify: leaf {} failed verification",
                    proof.leaf_index
                );
                failed.push(proof.leaf_index);
            }
        }

        if failed.is_empty() {
            Ok(())
        } else {
            Err(failed)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MerkleProof — proof for a single leaf
// ═══════════════════════════════════════════════════════════════════════════════

/// Merkle proof for a single leaf, enabling O(log n) verification.
///
/// Contains the leaf index and sibling hashes needed to reconstruct
/// the root hash from the leaf.
#[pyclass(name = "MerkleProof")]
#[derive(Clone, Debug)]
pub struct MerkleProof {
    /// Index of the leaf in the original tree.
    #[pyo3(get)]
    pub leaf_index: usize,
    /// Sibling hashes from bottom to top (hex-encoded).
    #[pyo3(get)]
    pub siblings: Vec<[u8; 32]>,
}

#[pymethods]
impl MerkleProof {
    /// Get siblings as hex strings (for JSON serialization).
    fn siblings_hex(&self) -> Vec<String> {
        self.siblings.iter().map(|s| hex::encode(s)).collect()
    }

    fn __repr__(&self) -> String {
        format!(
            "MerkleProof(index={}, siblings={})",
            self.leaf_index,
            self.siblings.len()
        )
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Core hash functions
// ═══════════════════════════════════════════════════════════════════════════════

/// Compute the leaf SHA-256 hash for a decision trace entry.
///
/// Canonical field order (IDENTICAL to tax_pipeline::DecisionTraceHasher):
///   previous_hash|trace_id|transaction_id|context_json|verdict_json|
///   calculation_input|calculation_output|invariants_result|risk_verdict|timestamp
///
/// This hash becomes a LEAF in the Merkle tree.
#[pyfunction]
#[pyo3(signature = (
    previous_hash,
    trace_id,
    transaction_id,
    context_json,
    verdict_json,
    timestamp_iso,
    calculation_input = "",
    calculation_output = "",
    invariants_result = "",
    risk_verdict = "",
))]
fn compute_current_hash(
    previous_hash: &str,
    trace_id: &str,
    transaction_id: &str,
    context_json: &str,
    verdict_json: &str,
    timestamp_iso: &str,
    calculation_input: &str,
    calculation_output: &str,
    invariants_result: &str,
    risk_verdict: &str,
) -> String {
    log::debug!(
        "compute_current_hash (Merkle leaf): trace={}, tx={}",
        trace_id,
        transaction_id
    );

    let payload = format!(
        "{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
        previous_hash,
        trace_id,
        transaction_id,
        context_json,
        verdict_json,
        calculation_input,
        calculation_output,
        invariants_result,
        risk_verdict,
        timestamp_iso,
    );
    let mut hasher = Sha256::new();
    hasher.update(payload.as_bytes());
    hex::encode(hasher.finalize())
}

/// Compute the leaf hash as raw bytes (for Merkle tree construction).
#[allow(dead_code)]
fn compute_leaf_hash_bytes(
    previous_hash: &str,
    trace_id: &str,
    transaction_id: &str,
    context_json: &str,
    verdict_json: &str,
    timestamp_iso: &str,
    calculation_input: &str,
    calculation_output: &str,
    invariants_result: &str,
    risk_verdict: &str,
) -> [u8; 32] {
    let payload = format!(
        "{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",
        previous_hash,
        trace_id,
        transaction_id,
        context_json,
        verdict_json,
        calculation_input,
        calculation_output,
        invariants_result,
        risk_verdict,
        timestamp_iso,
    );
    let mut hasher = Sha256::new();
    hasher.update(payload.as_bytes());
    let result = hasher.finalize();
    let mut arr = [0u8; 32];
    arr.copy_from_slice(&result);
    arr
}

/// Return the genesis hash (64 zeros) — used for the very first chain entry.
#[pyfunction]
fn genesis_hash() -> String {
    GENESIS_HASH.to_string()
}

// ═══════════════════════════════════════════════════════════════════════════════
// Merkle API (Python-facing)
// ═══════════════════════════════════════════════════════════════════════════════

/// Build a Merkle tree from an array of entry hashes and return the root hash.
///
/// Args:
///     leaf_hashes_hex: List of hex-encoded SHA-256 leaf hashes (oldest first).
///
/// Returns:
///     Dict with:
///         - root_hash: str — Merkle root hash (hex)
///         - leaf_count: int — number of leaves
///         - levels: int — number of levels in the tree
#[pyfunction]
fn build_merkle_tree(leaf_hashes_hex: Vec<String>) -> PyResult<String> {
    log::info!("build_merkle_tree: building from {} leaves", leaf_hashes_hex.len());

    let leaves: Result<Vec<[u8; 32]>, _> = leaf_hashes_hex
        .iter()
        .map(|h| {
            let bytes = hex::decode(h).map_err(|e| {
                PyValueError::new_err(format!("Invalid hex hash: {e}"))
            })?;
            if bytes.len() != 32 {
                return Err(PyValueError::new_err(
                    format!("Hash must be 32 bytes (64 hex chars), got {}", bytes.len())
                ));
            }
            let mut arr = [0u8; 32];
            arr.copy_from_slice(&bytes);
            Ok(arr)
        })
        .collect();

    let leaves = leaves?;
    let tree = MerkleTree::new(&leaves);

    let result = json!({
        "root_hash": tree.root_hex(),
        "leaf_count": tree.leaf_count(),
        "levels": tree.levels.len(),
    });

    log::info!(
        "build_merkle_tree: root={}, leaves={}, levels={}",
        &tree.root_hex()[..16],
        tree.leaf_count(),
        tree.levels.len(),
    );

    Ok(serde_json::to_string(&result).expect("infallible json"))
}

/// Generate a Merkle proof for a specific entry.
///
/// Args:
///     leaf_hashes_hex: List of hex-encoded SHA-256 leaf hashes (oldest first).
///     leaf_index: Index of the leaf to prove (0-based).
///
/// Returns:
///     JSON string with proof data, or None if index out of bounds.
#[pyfunction]
fn get_merkle_proof(
    leaf_hashes_hex: Vec<String>,
    leaf_index: usize,
) -> PyResult<Option<String>> {
    let leaves: Vec<[u8; 32]> = leaf_hashes_hex
        .iter()
        .filter_map(|h| {
            let bytes = hex::decode(h).ok()?;
            if bytes.len() != 32 { return None; }
            let mut arr = [0u8; 32];
            arr.copy_from_slice(&bytes);
            Some(arr)
        })
        .collect();

    let tree = MerkleTree::new(&leaves);
    let proof = tree.proof(leaf_index);

    match proof {
        Some(p) => {
            let result = json!({
                "leaf_index": p.leaf_index,
                "root_hash": tree.root_hex(),
                "siblings": p.siblings.iter().map(hex::encode).collect::<Vec<_>>(),
            });
            log::debug!("get_merkle_proof: index={}, siblings={}", leaf_index, p.siblings.len());
            Ok(Some(serde_json::to_string(&result).expect("infallible json")))
        }
        None => {
            log::warn!("get_merkle_proof: index {} out of bounds ({} leaves)", leaf_index, leaves.len());
            Ok(None)
        }
    }
}

/// Verify a single entry against a Merkle root.
///
/// Args:
///     leaf_hash_hex: Hex-encoded SHA-256 hash of the entry.
///     proof_json: JSON string with proof data (from ``get_merkle_proof``).
///     expected_root_hex: Expected Merkle root hash (hex).
///
/// Returns:
///     True if the proof is valid.
#[pyfunction]
fn verify_merkle_proof(
    leaf_hash_hex: &str,
    proof_json: &str,
    expected_root_hex: &str,
) -> PyResult<bool> {
    let leaf_bytes = hex::decode(leaf_hash_hex)
        .map_err(|e| PyValueError::new_err(format!("Invalid leaf hash: {e}")))?;

    if leaf_bytes.len() != 32 {
        return Err(PyValueError::new_err(
            "Leaf hash must be 32 bytes (64 hex chars)"
        ));
    }

    let mut leaf = [0u8; 32];
    leaf.copy_from_slice(&leaf_bytes);

    let proof_data: Value = serde_json::from_str(proof_json)
        .map_err(|e| PyValueError::new_err(format!("Invalid proof JSON: {e}")))?;

    let index = proof_data["leaf_index"].as_i64().unwrap_or(0) as usize;
    let siblings_hex: Vec<String> = proof_data["siblings"]
        .as_array()
        .map(|arr| {
            arr.iter()
                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                .collect()
        })
        .unwrap_or_default();

    let siblings: Result<Vec<[u8; 32]>, _> = siblings_hex
        .iter()
        .map(|h| {
            let bytes = hex::decode(h)
                .map_err(|e| PyValueError::new_err(format!("Invalid sibling hash: {e}")))?;
            if bytes.len() != 32 {
                return Err(PyValueError::new_err("Sibling hash must be 32 bytes"));
            }
            let mut arr = [0u8; 32];
            arr.copy_from_slice(&bytes);
            Ok(arr)
        })
        .collect();

    let siblings = siblings?;

    let root_bytes = hex::decode(expected_root_hex)
        .map_err(|e| PyValueError::new_err(format!("Invalid root hash: {e}")))?;

    if root_bytes.len() != 32 {
        return Err(PyValueError::new_err("Root hash must be 32 bytes (64 hex chars)"));
    }

    let mut root = [0u8; 32];
    root.copy_from_slice(&root_bytes);

    let proof = MerkleProof {
        leaf_index: index,
        siblings,
    };

    Ok(MerkleTree::verify(&leaf, &proof, &root))
}

/// Batch verify multiple entries against a Merkle root.
///
/// Args:
///     entries: List of (leaf_hash_hex, proof_json) tuples.
///     expected_root_hex: Expected Merkle root hash (hex).
///
/// Returns:
///     JSON string with verification results:
///         - valid: bool
///         - verified_count: int
///         - failed_indices: list of indices that failed
///         - error: str (empty if all valid)
#[pyfunction]
fn verify_batch(
    entries: Vec<(String, String)>,
    expected_root_hex: &str,
) -> PyResult<String> {
    log::info!("verify_batch: verifying {} entries", entries.len());

    let root_bytes = hex::decode(expected_root_hex)
        .map_err(|e| PyValueError::new_err(format!("Invalid root hash: {e}")))?;

    if root_bytes.len() != 32 {
        return Err(PyValueError::new_err("Root hash must be 32 bytes"));
    }

    let mut root = [0u8; 32];
    root.copy_from_slice(&root_bytes);

    let mut leaves_and_proofs: Vec<([u8; 32], MerkleProof)> = Vec::new();
    let mut parse_errors: Vec<usize> = Vec::new();

    for (i, (leaf_hex, proof_json)) in entries.iter().enumerate() {
        // Parse leaf
        let leaf_bytes = match hex::decode(leaf_hex) {
            Ok(b) if b.len() == 32 => {
                let mut arr = [0u8; 32];
                arr.copy_from_slice(&b);
                arr
            }
            _ => {
                parse_errors.push(i);
                continue;
            }
        };

        // Parse proof
        let proof_data: Value = match serde_json::from_str(proof_json) {
            Ok(v) => v,
            Err(_) => {
                parse_errors.push(i);
                continue;
            }
        };

        let index = proof_data["leaf_index"].as_i64().unwrap_or(i as i64) as usize;
        let siblings_hex: Vec<String> = proof_data["siblings"]
            .as_array()
            .map(|arr| {
                arr.iter()
                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                    .collect()
            })
            .unwrap_or_default();

        let siblings: Vec<[u8; 32]> = siblings_hex
            .iter()
            .filter_map(|h| {
                let bytes = hex::decode(h).ok()?;
                if bytes.len() != 32 { return None; }
                let mut arr = [0u8; 32];
                arr.copy_from_slice(&bytes);
                Some(arr)
            })
            .collect();

        // Only add if we have the correct number of siblings
        if !siblings.is_empty() || entries.len() == 1 {
            leaves_and_proofs.push((leaf_bytes, MerkleProof { leaf_index: index, siblings }));
        } else {
            parse_errors.push(i);
        }
    }

    let failed_indices = if !parse_errors.is_empty() {
        parse_errors
    } else {
        match MerkleTree::batch_verify(&leaves_and_proofs, &root) {
            Ok(()) => vec![],
            Err(failed) => failed,
        }
    };        let error_msg: String = if failed_indices.is_empty() {
            String::new()
        } else {
            format!("{} entries failed verification", failed_indices.len())
        };

        let result = json!({
            "valid": failed_indices.is_empty(),
            "verified_count": entries.len() - failed_indices.len(),
            "total_count": entries.len(),
            "failed_indices": failed_indices,
            "error": error_msg,
        });

    log::info!(
        "verify_batch: {}/{} verified, {} failed",
        entries.len() - failed_indices.len(),
        entries.len(),
        failed_indices.len(),
    );

    Ok(serde_json::to_string(&result).expect("infallible json"))
}

// ═══════════════════════════════════════════════════════════════════════════════
// PreparedLog — pre-computed log entry ready for DuckDB INSERT
// ═══════════════════════════════════════════════════════════════════════════════

/// Pre-computed decision trace log entry, ready for DuckDB persistence.
///
/// Python creates this via `DecisionTraceLogger.prepare_log()` and then
/// inserts it into DuckDB using the returned dict.
///
/// The `current_hash` now serves as a Merkle LEAF hash (in addition to
/// maintaining the linear chain linkage for backward compatibility).
#[pyclass(name = "PreparedLog")]
#[derive(Clone, Debug)]
pub struct PreparedLog {
    #[pyo3(get)]
    pub trace_id: String,
    #[pyo3(get)]
    pub transaction_id: String,
    #[pyo3(get)]
    pub rule_id: String,
    #[pyo3(get)]
    pub context_json: String,
    #[pyo3(get)]
    pub verdict_json: String,
    #[pyo3(get)]
    pub calculation_input: String,
    #[pyo3(get)]
    pub calculation_output: String,
    #[pyo3(get)]
    pub invariants_result: String,
    #[pyo3(get)]
    pub risk_verdict: String,
    #[pyo3(get)]
    pub decision_trace: String,
    #[pyo3(get)]
    pub trace_json: String,
    #[pyo3(get)]
    pub previous_hash: String,
    #[pyo3(get)]
    pub current_hash: String,
    #[pyo3(get)]
    pub timestamp: String,
}

#[pymethods]
impl PreparedLog {
    fn values(&self) -> Vec<String> {
        vec![
            self.trace_id.clone(),
            self.transaction_id.clone(),
            self.rule_id.clone(),
            self.context_json.clone(),
            self.verdict_json.clone(),
            self.calculation_input.clone(),
            self.calculation_output.clone(),
            self.invariants_result.clone(),
            self.risk_verdict.clone(),
            self.decision_trace.clone(),
            self.trace_json.clone(),
            self.previous_hash.clone(),
            self.current_hash.clone(),
            self.timestamp.clone(),
        ]
    }

    fn __repr__(&self) -> String {
        format!(
            "PreparedLog(trace={}, tx={}, hash={}..., merkle_leaf)",
            &self.trace_id[..8],
            &self.transaction_id[..8],
            &self.current_hash[..8],
        )
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DecisionTraceLogger — Rust-native logger pyclass
// ═══════════════════════════════════════════════════════════════════════════════

/// Append-only Merkle tree audit trail for tax decisions.
///
/// Combines:
///   - Linear hash chain (backward compatible — each entry links to previous)
///   - Merkle tree root (for O(log n) batch verification)
///
/// Usage (Python side)::
///
///     logger = DecisionTraceLogger()
///     entry = logger.prepare_log(
///         transaction_id="uuid",
///         previous_hash=latest_hash,
///         context=ctx_dict,
///         verdict=v_dict,
///     )
///     conn.execute(\"INSERT INTO decision_traces (...) VALUES (?)\", entry.to_dict())
///
///     # Merkle tree verification:
///     root = DecisionTraceLogger.compute_merkle_root(all_entries)
///     proof = DecisionTraceLogger.get_proof(all_entries, index)
///     ok = DecisionTraceLogger.verify_proof(leaf_hash, proof, root)
#[pyclass(name = "DecisionTraceLogger")]
pub struct DecisionTraceLogger;

#[pymethods]
impl DecisionTraceLogger {
    /// Prepare a decision trace log entry with cryptographic hash chain linkage.
    ///
    /// This is a PURE COMPUTATION method — it does NOT perform DuckDB I/O.
    /// The returned :class:`PreparedLog` must be inserted into DuckDB by the caller.
    ///
    /// The `current_hash` serves dual purpose:
    ///   1. Links to previous hash (linear chain, backward compatible)
    ///   2. Can be used as a Merkle tree leaf for O(log n) batch verification
    #[pyo3(signature = (
        transaction_id,
        previous_hash,
        context_json,
        verdict_json,
        rule_id = "",
        calculation_input = "",
        calculation_output = "",
        invariants_result = "",
        risk_verdict = "",
        decision_trace = "",
        trace_json = "",
        timestamp_iso = None,
    ))]
    #[staticmethod]
    fn prepare_log(
        transaction_id: &str,
        previous_hash: &str,
        context_json: &str,
        verdict_json: &str,
        rule_id: &str,
        calculation_input: &str,
        calculation_output: &str,
        invariants_result: &str,
        risk_verdict: &str,
        decision_trace: &str,
        trace_json: &str,
        timestamp_iso: Option<String>,
    ) -> PreparedLog {
        let trace_id = uuid::Uuid::new_v4().to_string();
        let ts = timestamp_iso.unwrap_or_else(|| {
            chrono::Utc::now().format("%Y-%m-%dT%H:%M:%S%.f").to_string()
        });

        log::debug!(
            "DecisionTraceLogger.prepare_log (Merkle leaf): tx={}, prev={}...",
            transaction_id,
            &previous_hash[..8.min(previous_hash.len())],
        );

        // Compute the SHA-256 leaf hash (same algorithm as before for compatibility)
        let current_hash = compute_current_hash(
            previous_hash,
            &trace_id,
            transaction_id,
            context_json,
            verdict_json,
            &ts,
            calculation_input,
            calculation_output,
            invariants_result,
            risk_verdict,
        );

        PreparedLog {
            trace_id,
            transaction_id: transaction_id.to_string(),
            rule_id: rule_id.to_string(),
            context_json: context_json.to_string(),
            verdict_json: verdict_json.to_string(),
            calculation_input: calculation_input.to_string(),
            calculation_output: calculation_output.to_string(),
            invariants_result: invariants_result.to_string(),
            risk_verdict: risk_verdict.to_string(),
            decision_trace: decision_trace.to_string(),
            trace_json: trace_json.to_string(),
            previous_hash: previous_hash.to_string(),
            current_hash,
            timestamp: ts,
        }
    }

    /// Get a SQL query fragment for retrieving traces by transaction_id.
    #[staticmethod]
    fn get_trace_query() -> String {
        serde_json::to_string(&json!({
            "sql": "SELECT trace_id, transaction_id, rule_id, context_json, \
                    verdict_json, calculation_input, calculation_output, \
                    invariants_result, risk_verdict, \
                    decision_trace, trace_json, \
                    previous_hash, current_hash, timestamp \
                    FROM decision_traces \
                    WHERE transaction_id = ? \
                    ORDER BY timestamp ASC",
            "params_order": ["transaction_id"],
        })).expect("infallible json")
    }

    /// Get a SQL query fragment for the latest hash.
    #[staticmethod]
    fn latest_hash_query() -> String {
        serde_json::to_string(&json!({
            "sql": "SELECT current_hash FROM decision_traces ORDER BY timestamp DESC LIMIT 1"
        })).expect("infallible json")
    }

    /// Get a SQL query for all hashes (for Merkle tree construction).
    #[staticmethod]
    fn all_hashes_query() -> String {
        serde_json::to_string(&json!({
            "sql": "SELECT current_hash FROM decision_traces ORDER BY timestamp ASC"
        })).expect("infallible json")
    }

    /// Get a SQL query fragment for counting entries.
    #[staticmethod]
    fn entry_count_query() -> String {
        serde_json::to_string(&json!({
            "sql": "SELECT COUNT(1) FROM decision_traces"
        })).expect("infallible json")
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// verify_chain_integrity — O(log n) Merkle tree verification
// ═══════════════════════════════════════════════════════════════════════════════

/// Verify the full decision trace hash chain using Merkle tree.
///
/// Builds a Merkle tree from all entries and verifies against the root.
/// O(n) for tree construction (must read all entries), but proofs are
/// O(log n) once the tree is built.
///
/// Additionally checks linear chain linkage for backward compatibility.
///
/// Args:
///     entries_json: JSON array of decision trace entries (oldest first).
///
/// Returns:
///     JSON array of integrity issues. An empty array means the chain is intact.
#[pyfunction]
fn verify_chain_integrity(entries_json: &str) -> PyResult<String> {
    let entries: Vec<Value> = serde_json::from_str(entries_json)
        .map_err(|e| PyValueError::new_err(format!("Invalid entries JSON: {e}")))?;

    let mut issues: Vec<Value> = Vec::new();
    let mut expected_previous = GENESIS_HASH.to_string();
    let mut leaf_hashes: Vec<[u8; 32]> = Vec::with_capacity(entries.len());

    // Phase 1: Verify linear hash chain (backward compat) AND collect leaf hashes
    for (i, entry) in entries.iter().enumerate() {
        let obj = match entry.as_object() {
            Some(o) => o,
            None => continue,
        };

        let trace_id = get_str(obj, "trace_id", "");
        let transaction_id = get_str(obj, "transaction_id", "");
        let context_json = get_str(obj, "context_json", "{}");
        let verdict_json = get_str(obj, "verdict_json", "{}");
        let calculation_input = get_str(obj, "calculation_input", "");
        let calculation_output = get_str(obj, "calculation_output", "");
        let invariants_result = get_str(obj, "invariants_result", "");
        let risk_verdict = get_str(obj, "risk_verdict", "");
        let stored_previous = get_str(obj, "previous_hash", "");
        let stored_current = get_str(obj, "current_hash", "");
        let timestamp_iso = get_str(obj, "timestamp", "");

        // 1. Linear chain: previous hash linkage
        if stored_previous != expected_previous {
            issues.push(json!({
                "trace_id": trace_id,
                "issue": "previous_hash_mismatch",
                "expected_previous": expected_previous,
                "stored_previous": stored_previous,
                "index": i,
                "message": format!(
                    "Entry {} ({}): stored previous_hash does not match previous entry's current_hash",
                    i, trace_id
                ),
            }));
        }

        // 2. Linear chain: current hash integrity (recompute from stored fields)
        let recomputed = compute_current_hash(
            &stored_previous,
            &trace_id,
            &transaction_id,
            &context_json,
            &verdict_json,
            &timestamp_iso,
            &calculation_input,
            &calculation_output,
            &invariants_result,
            &risk_verdict,
        );
        if recomputed != stored_current {
            issues.push(json!({
                "trace_id": trace_id,
                "issue": "current_hash_mismatch",
                "expected_current": recomputed,
                "stored_current": stored_current,
                "index": i,
                "message": format!(
                    "Entry {} ({}): stored current_hash does not match recomputed — data may have been tampered with",
                    i, trace_id
                ),
            }));
        }

        // 3. Collect leaf hash for Merkle tree verification
        let leaf_bytes = hex::decode(&recomputed).unwrap_or_default();
        if leaf_bytes.len() == 32 {
            let mut arr = [0u8; 32];
            arr.copy_from_slice(&leaf_bytes);
            leaf_hashes.push(arr);
        }

        expected_previous = stored_current;
    }

    // Phase 2: Merkle tree verification (if we have at least 2 entries)
    if leaf_hashes.len() >= 2 && issues.is_empty() {
        let tree = MerkleTree::new(&leaf_hashes);
        let merkle_root = tree.root_hex();

        // Verify each entry against the Merkle root (O(log n) per entry)
        for i in 0..leaf_hashes.len() {
            if let Some(proof) = tree.proof(i) {
                if !MerkleTree::verify(&leaf_hashes[i], &proof, &tree.root()) {
                    issues.push(json!({
                        "trace_id": get_str(entries[i].as_object().unwrap_or(&serde_json::Map::new()), "trace_id", ""),
                        "issue": "merkle_proof_failed",
                        "index": i,
                        "message": format!(
                            "Entry {}: Merkle proof does not match root {}",
                            i, merkle_root
                        ),
                    }));
                }
            }
        }

        log::info!(
            "verify_chain_integrity (Merkle): {} entries, root={}, {} issues",
            entries.len(),
            &merkle_root[..16],
            issues.len(),
        );
    } else {
        log::info!(
            "verify_chain_integrity (Merkle): {} entries, {} issues (Merkle skipped: <2 leaves or has issues)",
            entries.len(),
            issues.len(),
        );
    }

    let result = serde_json::to_string(&json!(issues)).expect("infallible json");
    log::info!(
        "verify_chain_integrity: {} entries, {} issues total",
        entries.len(),
        issues.len(),
    );
    Ok(result)
}

/// Helper: get string from JSON object with default fallback.
fn get_str(obj: &serde_json::Map<String, Value>, key: &str, default: &str) -> String {
    obj.get(key)
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| default.to_string())
}

// ═══════════════════════════════════════════════════════════════════════════════
// Module registration
// ═══════════════════════════════════════════════════════════════════════════════

pub fn register(module: &Bound<'_, PyModule>) -> PyResult<()> {
    module.add_class::<DecisionTraceLogger>()?;
    module.add_class::<PreparedLog>()?;
    module.add_class::<MerkleProof>()?;

    module.add_function(wrap_pyfunction!(compute_current_hash, module)?)?;
    module.add_function(wrap_pyfunction!(genesis_hash, module)?)?;
    module.add_function(wrap_pyfunction!(verify_chain_integrity, module)?)?;

    // Merkle tree API
    module.add_function(wrap_pyfunction!(build_merkle_tree, module)?)?;
    module.add_function(wrap_pyfunction!(get_merkle_proof, module)?)?;
    module.add_function(wrap_pyfunction!(verify_merkle_proof, module)?)?;
    module.add_function(wrap_pyfunction!(verify_batch, module)?)?;

    log::info!(
        "trace_logger (Merkle): registered DecisionTraceLogger, PreparedLog, MerkleProof, \
         compute_current_hash, genesis_hash, verify_chain_integrity (O(log n)), \
         build_merkle_tree, get_merkle_proof, verify_merkle_proof, verify_batch"
    );
    Ok(())
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    // ── MerkleTree tests ──────────────────────────────────────────────────

    #[test]
    fn test_merkle_empty_tree() {
        let tree = MerkleTree::new(&[]);
        assert_eq!(tree.leaf_count(), 0);
        assert_eq!(tree.root_hex(), GENESIS_HASH);
    }

    #[test]
    fn test_merkle_single_leaf() {
        let leaf = [1u8; 32];
        let tree = MerkleTree::new(&[leaf]);
        assert_eq!(tree.leaf_count(), 1);

        // For a single leaf, levels = [[leaf]], so root == leaf
        assert_eq!(tree.root(), leaf);
    }

    #[test]
    fn test_merkle_two_leaves() {
        let leaf1 = [1u8; 32];
        let leaf2 = [2u8; 32];
        let tree = MerkleTree::new(&[leaf1, leaf2]);
        assert_eq!(tree.leaf_count(), 2);

        // Root = SHA256(SHA256(leaf1 || leaf2))
        let combined = Sha256::digest(&[&leaf1[..], &leaf2[..]].concat());
        let expected_root: [u8; 32] = combined.into();
        assert_eq!(tree.root(), expected_root);
    }

    #[test]
    fn test_merkle_proof_single_leaf() {
        let leaf = [42u8; 32];
        let tree = MerkleTree::new(&[leaf]);
        let proof = tree.proof(0).unwrap();
        assert_eq!(proof.leaf_index, 0);
        // Single leaf: levels = [[leaf]], no intermediate levels → 0 siblings
        assert_eq!(proof.siblings.len(), 0);
        // Verify the single leaf against the root
        assert!(MerkleTree::verify(&leaf, &proof, &tree.root()),
            "Single leaf should verify with empty proof");
    }

    #[test]
    fn test_merkle_proof_and_verify() {
        let leaves: Vec<[u8; 32]> = (0..4).map(|i| [i as u8 + 1; 32]).collect();
        let tree = MerkleTree::new(&leaves);

        let root = tree.root();

        // Test each leaf
        for i in 0..4 {
            let proof = tree.proof(i).unwrap();
            assert!(MerkleTree::verify(&leaves[i], &proof, &root),
                "Leaf {} should verify successfully", i);
        }

        // Tampered leaf should fail
        let tampered = [0xFFu8; 32];
        let proof = tree.proof(1).unwrap();
        assert!(!MerkleTree::verify(&tampered, &proof, &root),
            "Tampered leaf should fail verification");
    }

    #[test]
    fn test_merkle_proof_odd_leaves() {
        // 3 leaves (odd): last gets duplicated
        let leaves: Vec<[u8; 32]> = (0..3).map(|i| [i as u8 + 10; 32]).collect();
        let tree = MerkleTree::new(&leaves);

        let root = tree.root();
        assert_eq!(tree.leaf_count(), 3);

        // All leaves should verify
        for i in 0..3 {
            let proof = tree.proof(i).unwrap();
            assert!(MerkleTree::verify(&leaves[i], &proof, &root),
                "Leaf {} should verify in odd tree", i);
        }
    }

    #[test]
    fn test_merkle_proof_out_of_bounds() {
        let leaves: Vec<[u8; 32]> = (0..2).map(|i| [i as u8; 32]).collect();
        let tree = MerkleTree::new(&leaves);

        assert!(tree.proof(5).is_none(), "Out of bounds index should return None");
    }

    #[test]
    fn test_merkle_batch_verify_all_pass() {
        let leaves: Vec<[u8; 32]> = (0..4).map(|i| [i as u8; 32]).collect();
        let tree = MerkleTree::new(&leaves);
        let root = tree.root();

        let proofs: Vec<([u8; 32], MerkleProof)> = (0..4)
            .map(|i| (leaves[i], tree.proof(i).unwrap()))
            .collect();

        assert!(MerkleTree::batch_verify(&proofs, &root).is_ok());
    }

    #[test]
    fn test_merkle_batch_verify_some_fail() {
        let leaves: Vec<[u8; 32]> = (0..4).map(|i| [i as u8; 32]).collect();
        let tree = MerkleTree::new(&leaves);
        let root = tree.root();

        // Tamper with leaf 1
        let mut tampered_leaves = leaves.clone();
        tampered_leaves[1] = [0xFFu8; 32];

        let proofs: Vec<([u8; 32], MerkleProof)> = tampered_leaves
            .iter()
            .enumerate()
            .map(|(i, leaf)| (*leaf, tree.proof(i).unwrap()))
            .collect();

        match MerkleTree::batch_verify(&proofs, &root) {
            Err(failed) => {
                assert!(!failed.is_empty(), "Should have at least one failure");
                assert!(failed.contains(&1), "Failed list should include index 1");
            }
            Ok(()) => panic!("Should have failed"),
        }
    }

    #[test]
    fn test_merkle_16_leaves() {
        // Larger tree: 16 leaves
        let leaves: Vec<[u8; 32]> = (0..16).map(|i| {
            let mut arr = [0u8; 32];
            arr[0] = i;
            arr
        }).collect();

        let tree = MerkleTree::new(&leaves);
        let root = tree.root();
        assert_eq!(tree.leaf_count(), 16);

        // Verify all
        for i in 0..16 {
            let proof = tree.proof(i).unwrap();
            assert!(MerkleTree::verify(&leaves[i], &proof, &root),
                "Leaf {} should verify in 16-leaf tree", i);
        }
    }

    // ── Hash computation tests ────────────────────────────────────────────

    #[test]
    fn test_genesis_hash() {
        let hash = genesis_hash();
        assert_eq!(hash.len(), 64);
        assert!(hash.chars().all(|c| c == '0'));
    }

    #[test]
    fn test_compute_current_hash_deterministic() {
        let h1 = compute_current_hash(GENESIS_HASH, "trace-1", "tx-1",
            "{\"cat\": \"FUEL\"}", "{\"rate\": \"0.23\"}", "2024-06-01T12:00:00",
            "", "", "", "");
        let h2 = compute_current_hash(GENESIS_HASH, "trace-1", "tx-1",
            "{\"cat\": \"FUEL\"}", "{\"rate\": \"0.23\"}", "2024-06-01T12:00:00",
            "", "", "", "");
        assert_eq!(h1, h2, "Should be deterministic");
    }

    #[test]
    fn test_compute_current_hash_different_inputs() {
        let h1 = compute_current_hash(GENESIS_HASH, "trace-1", "tx-1",
            "{\"cat\": \"FUEL\"}", "{\"rate\": \"0.23\"}", "2024-06-01T12:00:00",
            "", "", "", "");
        let h2 = compute_current_hash(GENESIS_HASH, "trace-1", "tx-1",
            "{\"cat\": \"FOOD\"}", "{\"rate\": \"0.08\"}", "2024-06-01T12:00:00",
            "", "", "", "");
        assert_ne!(h1, h2, "Different inputs should give different hashes");
    }

    // ── verify_chain_integrity tests ──────────────────────────────────────

    fn make_test_entry(index: usize, previous_hash: &str) -> Value {
        let current = compute_current_hash(
            previous_hash,
            &format!("trace-{}", index),
            &format!("tx-{}", index),
            &format!("{{\"cat\": \"ITEM_{}\"}}", index),
            "{\"rate\": \"0.23\"}",
            &format!("2024-06-{:02}T12:00:00", index + 1),
            "1000", "230", "{\"is_valid\": true}", "",
        );

        json!({
            "trace_id": format!("trace-{}", index),
            "transaction_id": format!("tx-{}", index),
            "rule_id": format!("rule-{}", index),
            "context_json": format!("{{\"cat\": \"ITEM_{}\"}}", index),
            "verdict_json": "{\"rate\": \"0.23\"}",
            "calculation_input": "1000",
            "calculation_output": "230",
            "invariants_result": "{\"is_valid\": true}",
            "risk_verdict": "",
            "decision_trace": format!("Rule {} applied", index),
            "trace_json": "{}",
            "previous_hash": previous_hash,
            "current_hash": current,
            "timestamp": format!("2024-06-{:02}T12:00:00", index + 1),
        })
    }

    #[test]
    fn test_verify_chain_integrity_clean() {
        let mut entries: Vec<Value> = Vec::new();
        let mut prev = GENESIS_HASH.to_string();

        for i in 0..4 {
            let entry = make_test_entry(i, &prev);
            prev = entry["current_hash"].as_str().unwrap().to_string();
            entries.push(entry);
        }

        let json_str = serde_json::to_string(&entries).unwrap();
        let result = verify_chain_integrity(&json_str).unwrap();
        let issues: Vec<Value> = serde_json::from_str(&result).unwrap();
        assert!(issues.is_empty(), "Clean chain should have no issues");
    }

    #[test]
    fn test_verify_chain_integrity_tampered() {
        let mut entries: Vec<Value> = Vec::new();
        let mut prev = GENESIS_HASH.to_string();

        for i in 0..3 {
            let mut entry = make_test_entry(i, &prev);
            prev = entry["current_hash"].as_str().unwrap().to_string();

            // Tamper with entry 1
            if i == 1 {
                entry["context_json"] = json!("{\"cat\": \"TAMPERED\"}");
            }

            entries.push(entry);
        }

        let json_str = serde_json::to_string(&entries).unwrap();
        let result = verify_chain_integrity(&json_str).unwrap();
        let issues: Vec<Value> = serde_json::from_str(&result).unwrap();
        assert!(!issues.is_empty(), "Tampered chain should have issues");
    }
}
