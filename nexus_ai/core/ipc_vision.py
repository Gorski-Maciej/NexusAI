# core/ipc_vision.py
import struct
import uuid
from multiprocessing import shared_memory
from typing import Any


class ImageMemoryManager:
    """Zarządza pamięcią współdzieloną dla bezstratnego przesyłania obrazów.

    Używa shared_memory z raw bytes zamiast numpy arrays.
    Obrazy są przesyłane jako bajty z metadanymi o wymiarach.
    """

    @staticmethod
    def store_image(image_bytes: bytes, width: int, height: int, channels: int = 3) -> dict:
        """Zapisuje obraz (raw bytes) do pamięci współdzielonej.

        Args:
            image_bytes: Raw pixel data (RGB order).
            width: Szerokość obrazu w pikselach.
            height: Wysokość obrazu w pikselach.
            channels: Liczba kanałów (domyślnie 3 = RGB).

        Returns:
            Metadane dla retrieve_image.
        """
        shm_name = f"nexus_img_{uuid.uuid4().hex}"
        size = len(image_bytes)

        shm = shared_memory.SharedMemory(create=True, size=size, name=shm_name)
        shm.buf[:size] = image_bytes

        return {
            "name": shm_name,
            "size": size,
            "width": width,
            "height": height,
            "channels": channels,
        }

    @staticmethod
    def retrieve_image(metadata: dict) -> tuple[bytes, dict]:
        """Odczytuje obraz z pamięci współdzielonej na podstawie metadanych.

        Returns:
            Tuple (raw_bytes, dimensions_dict).
        """
        shm = shared_memory.SharedMemory(name=metadata["name"])
        size = metadata["size"]
        data = bytes(shm.buf[:size])
        dims = {
            "width": metadata["width"],
            "height": metadata["height"],
            "channels": metadata.get("channels", 3),
        }
        return data, dims
