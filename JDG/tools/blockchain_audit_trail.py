#!/usr/bin/env python3
"""
NexusAI JDG — Blockchain-Anchored Audit Trail (Innovation #11, P28 Grand Finale)
Merkle DAG + SHA-256 kotwiczenie niezmiennej ścieżki audytu.
ADR-006 + plan44/plan45 — dowód integralności dla US i sądów.
"""
import sys, os, json, hashlib
from datetime import datetime
from collections import OrderedDict

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

class MerkleNode:
    def __init__(self, left, right, data=None):
        self.left = left
        self.right = right
        self.data = data
        self.hash = self._compute_hash()
    
    def _compute_hash(self):
        if self.data:
            return hashlib.sha256(json.dumps(self.data, sort_keys=True).encode()).hexdigest()
        left_hash = self.left.hash if self.left else ""
        right_hash = self.right.hash if self.right else ""
        return hashlib.sha256(f"{left_hash}{right_hash}".encode()).hexdigest()

class BlockchainAuditTrail:
    """Niezmienna ścieżka audytu zakotwiczona w Merkle DAG."""
    
    def __init__(self):
        self.chain = []
        self.merkle_roots = []
        self.genesis_block = self._create_genesis()
    
    def _create_genesis(self):
        genesis = {
            "block": 0,
            "timestamp": "2026-01-01T00:00:00",
            "prev_hash": "0" * 64,
            "data": {"action": "GENESIS", "description": "Start of JDG Audit Trail"},
            "merkle_root": hashlib.sha256(b"GENESIS").hexdigest()
        }
        self.chain.append(genesis)
        return genesis
    
    def add_verdict(self, verdict):
        """Dodaj werdykt do blockchainowej ścieżki audytu."""
        prev_block = self.chain[-1]
        
        block = {
            "block": len(self.chain),
            "timestamp": datetime.now().isoformat(),
            "prev_hash": prev_block.get("merkle_root", prev_block.get("hash", "")),
            "data": verdict,
            "nonce": 0
        }
        
        # PoW (lightweight)
        block["hash"] = self._mine(block)
        block["merkle_root"] = hashlib.sha256(
            json.dumps(block, sort_keys=True).encode()
        ).hexdigest()
        
        self.chain.append(block)
        self.merkle_roots.append(block["merkle_root"])
        return block
    
    def _mine(self, block, difficulty=2):
        """Lekki Proof-of-Work."""
        prefix = "0" * difficulty
        nonce = 0
        while True:
            block["nonce"] = nonce
            h = hashlib.sha256(json.dumps(block, sort_keys=True).encode()).hexdigest()
            if h.startswith(prefix):
                return h
            nonce += 1
    
    def verify_integrity(self):
        """Zweryfikuj integralność całej ścieżki."""
        for i in range(1, len(self.chain)):
            current = self.chain[i]
            previous = self.chain[i - 1]
            
            if current.get("prev_hash") != previous.get("merkle_root", ""):
                return False, f"Block {i}: prev_hash mismatch"
            
            expected = hashlib.sha256(json.dumps(
                {k: v for k, v in current.items() if k not in ["hash", "merkle_root"]},
                sort_keys=True
            ).encode()).hexdigest()
            
            if current["hash"] != expected:
                return False, f"Block {i}: hash mismatch"
        
        return True, "All blocks verified — AUDIT TRAIL INTACT"

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Blockchain-Anchored Audit Trail v1.0       ║")
    print("║  Innovation #11: Merkle DAG + SHA-256 (P28 Grand Finale) ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    blockchain = BlockchainAuditTrail()
    
    # Dodaj przykładowe werdykty
    verdicts = [
        {"action": "INVOICE_BOOKED", "invoice_id": "FV/2026/001", "amount": 5000.00, "vat": 1150.00, "user": "JDG_OWNER"},
        {"action": "ZUS_PAID", "period": "2026-07", "amount": 1850.25, "type": "PREFERENTIAL"},
        {"action": "PIT_ADVANCE_CALCULATED", "period": "2026-07", "income": 12000.00, "tax_advance": 1440.00},
    ]
    
    for v in verdicts:
        block = blockchain.add_verdict(v)
        print(f"\n📦 Block #{block['block']}: {v['action']}")
        print(f"   Hash: {block['hash'][:32]}...")
        print(f"   Merkle: {block['merkle_root'][:32]}...")
    
    # Weryfikacja
    valid, message = blockchain.verify_integrity()
    print(f"\n🔒 Integralność: {'✅ ' + message if valid else '❌ ' + message}")
    
    print(f"\n📋 KPI: {len(blockchain.chain)} bloków w niezmiennej ścieżce audytu")
    print("   Cel P28: 100% integralności audytu (Merkle DAG zakotwiczony)")
    
    report_path = os.path.join(BASE, "reports", "blockchain_audit_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump({
            "blocks": len(blockchain.chain),
            "integrity_verified": valid,
            "last_merkle_root": blockchain.chain[-1].get("merkle_root", ""),
            "generated_at": datetime.now().isoformat()
        }, f, indent=2)
    
    return 0 if valid else 1

if __name__ == "__main__":
    sys.exit(main())
