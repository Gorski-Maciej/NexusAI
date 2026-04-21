# pipeline/audit.py
import json
from datetime import datetime
from pathlib import Path

class PipelineAuditTrail:
    """Zapisuje ślad każdej transformacji dokumentu."""

    def __init__(self, doc_id: str):
        self.doc_id = doc_id
        self.steps = []

    def log_step(self, step_name: str, input_summary: str, output_summary: str, confidence: float = 1.0):
        self.steps.append({
            "timestamp": datetime.now().isoformat(),
            "step": step_name,
            "input": input_summary[:200], # Tylko fragmenty dla oszczędności DB
            "output": output_summary,
            "confidence": confidence
        })

    def get_full_trail(self) -> str:
        return json.dumps(self.steps, indent=2)

class PipelineAudit:
    """Zapisuje ślad decyzji podjętych przez Pipeline do pliku lokalnego."""

    def __init__(self, doc_id: str, logs_path: Path):
        self.doc_id = doc_id
        self.log_file = logs_path / f"audit_{doc_id}.log"

    def write_log(self, message: str):
        with open(self.log_file, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now().isoformat()}] {message}\n")
