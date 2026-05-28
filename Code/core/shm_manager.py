# core/ipc/shm_manager.py
import numpy as np
from multiprocessing import shared_memory
from typing import Tuple, Dict

class SharedImageBuffer:
    """Klasa do obsługi Zero-Copy IPC dla dużych obrazów."""

    @staticmethod
    def create(image: np.ndarray) -> Dict:
        """Tworzy blok w pamięci RAM i kopiuje do niego obraz."""
        # Alokacja pamięci o konkretnym rozmiarze
        shm = shared_memory.SharedMemory(create=True, size=image.nbytes)

        # Tworzymy 'widok' NumPy na tę pamięć
        shared_array = np.ndarray(image.shape, dtype=image.dtype, buffer=shm.buf)

        # Kopiujemy dane do współdzielonego bloku
        shared_array[:] = image[:]

        return {
            "shm_name": shm.name,
            "shape": image.shape,
            "dtype": str(image.dtype),
            "nbytes": image.nbytes
        }

    @staticmethod
    def attach(metadata: Dict) -> np.ndarray:
        """Podłącza się do istniejącego bloku pamięci."""
        shm = shared_memory.SharedMemory(name=metadata["shm_name"])
        return np.ndarray(metadata["shape"], dtype=np.dtype(metadata["dtype"]), buffer=shm.buf)
