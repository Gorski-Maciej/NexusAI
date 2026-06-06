# core/ipc/shm_manager.py
from multiprocessing import shared_memory

import numpy as np


class SharedImageBuffer:
    """Klasa do obsługi Zero-Copy IPC dla dużych obrazów."""

    @staticmethod
    def create(image: np.ndarray) -> dict:
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
    def attach(metadata: dict) -> np.ndarray:
        """Podłącza się do istniejącego bloku pamięci."""
        shm = shared_memory.SharedMemory(name=metadata["shm_name"])
        return np.ndarray(metadata["shape"], dtype=np.dtype(metadata["dtype"]), buffer=shm.buf)
