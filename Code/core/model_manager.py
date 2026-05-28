# core/model_manager.py
from pathlib import Path
from huggingface_hub import snapshot_download
from core.logger import logger

class LazyModelManager:
    """Pobiera ciężkie wagi modeli AI tylko w momencie ich pierwszego użycia."""

    def __init__(self, base_models_dir: str = "models/"):
        self.base_models_dir = Path(base_models_dir)
        self.base_models_dir.mkdir(parents=True, exist_ok=True)

        self._models = {
            "sentence_transformers": {
                "repo_id": "sentence-transformers/all-MiniLM-L6-v2",
                "local_dir": self.base_models_dir / "all-MiniLM-L6-v2",
                "loaded_instance": None
            },
            "surya_ocr": {
                "repo_id": "vikp/surya_det2",
                "local_dir": self.base_models_dir / "surya_det2",
                "loaded_instance": None
            }
        }

    def get_model_path(self, model_key: str) -> str:
        """Sprawdza czy model istnieje, pobiera w tle jeśli nie..."""
        model_info = self._models.get(model_key)
        if not model_info:
            raise ValueError(f"Nieznany model: {model_key}")

        local_dir = model_info["local_dir"]
        if not local_dir.exists():
            logger.info(f"Pobieranie modelu {model_key} w tle...")
            snapshot_download(repo_id=model_info["repo_id"], local_dir=local_dir)

        return str(local_dir)
