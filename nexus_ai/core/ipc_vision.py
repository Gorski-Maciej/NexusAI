# core/ipc_vision.py
import uuid
from multiprocessing import shared_memory

try:
    import numpy as np
except ImportError:
    np = None  # type: ignore[assignment]


class MissingNumpyError(RuntimeError):
    """Rzucany gdy brak numpy, ale kod próbuje go użyć."""

    def __init__(self) -> None:
        super().__init__("numpy jest wymagane do ImageMemoryManager. Zainstaluj: pip install numpy")


class ImageMemoryManager:
    """Zarządza pamięcią współdzieloną dla bezstratnego przesyłania obrazów."""

    @staticmethod
    def store_image(img_array: "np.ndarray") -> dict:
        """Zapisuje obraz do pamięci współdzielonej i zwraca metadane."""
        if np is None:
            raise MissingNumpyError()
        shm_name = f"nexus_img_{uuid.uuid4().hex}"

        # Tworzymy blok pamięci o rozmiarze tablicy
        shm = shared_memory.SharedMemory(create=True, size=img_array.nbytes, name=shm_name)

        # Tworzymy tablicę NumPy zmapowaną na ten blok i kopiujemy dane
        shared_array = np.ndarray(img_array.shape, dtype=img_array.dtype, buffer=shm.buf)
        shared_array[:] = img_array[:]

        return {
            "name": shm_name,
            "shape": img_array.shape,
            "dtype": str(img_array.dtype)
        }

    @staticmethod
    def retrieve_image(metadata: dict) -> "np.ndarray":
        """Odczytuje i podłącza pamięć na podstawie metadanych."""
        if np is None:
            raise MissingNumpyError()
        shm = shared_memory.SharedMemory(name=metadata["name"])
        shared_array = np.ndarray(metadata["shape"], dtype=np.dtype(metadata["dtype"]), buffer=shm.buf)
        return shared_array
