#!/usr/bin/env python3
"""
NexusAI JDG — Federated Tax Knowledge Mesh (Innovation #2, P28 Grand Finale)
Współdzielenie reguł między instancjami (multi-tenant), kanoniczny registry,
wersjonowanie polityk, hash SHA-256 reguł.
"""
import sys, os, json, hashlib
from datetime import datetime

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULES_DIR = os.path.join(BASE, "rules")

class FederatedRuleMesh:
    """Federated mesh — współdzielenie i wersjonowanie reguł multi-tenant."""
    
    def __init__(self):
        self.registry = {}
        self.tenants = {}
        self.canonical_registry = {}
    
    def scan_local_rules(self):
        """Skanuj lokalne reguły i zbuduj kanoniczny registry."""
        for root, _, files in os.walk(RULES_DIR):
            for f in files:
                if not f.endswith(".rego"):
                    continue
                filepath = os.path.join(root, f)
                with open(filepath, "rb") as fh:
                    content = fh.read()
                
                sha256 = hashlib.sha256(content).hexdigest()
                relpath = os.path.relpath(filepath, RULES_DIR)
                
                self.canonical_registry[relpath] = {
                    "path": relpath,
                    "sha256": sha256,
                    "size_bytes": len(content),
                    "last_modified": datetime.fromtimestamp(os.path.getmtime(filepath)).isoformat(),
                    "version": "1.0.0"
                }
        
        return self.canonical_registry
    
    def register_tenant(self, tenant_id, tenant_rules_dir):
        """Zarejestruj nowego tenanta z jego zestawem reguł."""
        tenant_registry = {}
        for root, _, files in os.walk(tenant_rules_dir) if os.path.exists(tenant_rules_dir) else []:
            for f in files:
                if f.endswith(".rego"):
                    filepath = os.path.join(root, f)
                    with open(filepath, "rb") as fh:
                        sha256 = hashlib.sha256(fh.read()).hexdigest()
                    tenant_registry[os.path.relpath(filepath, tenant_rules_dir)] = sha256
        
        self.tenants[tenant_id] = {
            "rules_count": len(tenant_registry),
            "hashes": tenant_registry,
            "registered_at": datetime.now().isoformat()
        }
        
        return self.tenants[tenant_id]
    
    def diff_against_canonical(self, tenant_id):
        """Porównaj reguły tenanta z kanonicznym registry."""
        if tenant_id not in self.tenants:
            return {"error": "Tenant not found"}
        
        tenant_hashes = self.tenants[tenant_id]["hashes"]
        diff = {
            "matching": 0,
            "modified": [],
            "missing": [],
            "extra": []
        }
        
        for path, info in self.canonical_registry.items():
            if path in tenant_hashes:
                if tenant_hashes[path] == info["sha256"]:
                    diff["matching"] += 1
                else:
                    diff["modified"].append(path)
            else:
                diff["missing"].append(path)
        
        for path in tenant_hashes:
            if path not in self.canonical_registry:
                diff["extra"].append(path)
        
        diff["integrity_score"] = diff["matching"] / max(len(self.canonical_registry), 1)
        return diff
    
    def export_registry(self):
        """Eksportuj kanoniczny registry do JSON."""
        return {
            "canonical_rules": len(self.canonical_registry),
            "tenants": len(self.tenants),
            "registry": self.canonical_registry,
            "tenants_detail": self.tenants,
            "generated_at": datetime.now().isoformat()
        }

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Federated Tax Knowledge Mesh v1.0          ║")
    print("║  Innovation #2: Multi-Tenant Rule Sharing (P28)          ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    mesh = FederatedRuleMesh()
    registry = mesh.scan_local_rules()
    
    print(f"\n📊 Kanoniczny Registry:")
    print(f"   Reguły: {len(registry)}")
    
    total_size = sum(info["size_bytes"] for info in registry.values())
    print(f"   Rozmiar: {total_size:,} bajtów")
    
    unique_hashes = set(info["sha256"] for info in registry.values())
    print(f"   Unikalne SHA-256: {len(unique_hashes)}")
    
    print(f"\n📋 KPI: {len(registry)} reguł w kanonicznym registry z SHA-256")
    print("   Cel P28: 100% reguł wersjonowanych w federated mesh")
    
    report = mesh.export_registry()
    report_path = os.path.join(BASE, "reports", "federated_mesh_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print(f"\n📄 Report: {report_path}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
