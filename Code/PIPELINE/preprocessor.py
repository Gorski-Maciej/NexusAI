# pipeline/preprocessor.py
import cv2
import numpy as np
from PIL import Image
import io
from core.logger import logger

class ImageOptimizer:
    """Poprawia jakość wizualną dokumentów przed OCR/Vision AI."""

    @staticmethod
    def enhance_for_ocr(image_bytes: bytes) -> bytes:
        """Zwiększa kontrast i usuwa szumy (Denoising)."""
        try:
            nparr = np.frombuffer(image_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)

            # 1. Progowanie adaptacyjne (Binarization)
            thresh = cv2.adaptiveThreshold(
                img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv2.THRESH_BINARY, 11, 2
            )

            # 2. Usuwanie drobnych szumów
            kernel = np.ones((1, 1), np.uint8)
            opening = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel)

            _, encoded_img = cv2.imencode('.png', opening)
            return encoded_img.tobytes()
        except Exception as e:
            logger.error(f"Image enhancement failed: {e}")
            return image_bytes

    @staticmethod
    def deskew(image_bytes: bytes) -> bytes:
        """Prostuje tekst, jeśli dokument został krzywo zeskanowany."""
        try:
            nparr = np.frombuffer(image_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_GRAYSCALE)

            # Znajdowanie krawędzi i prostowanie
            coords = np.column_stack(np.where(img > 0))
            angle = cv2.minAreaRect(coords)[-1]
            if angle < -45:
                angle = -(90 + angle)
            else:
                angle = -angle

            (h, w) = img.shape[:2]
            center = (w // 2, h // 2)
            M = cv2.getRotationMatrix2D(center, angle, 1.0)
            rotated = cv2.warpAffine(img, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)

            _, encoded_img = cv2.imencode('.png', rotated)
            return encoded_img.tobytes()
        except Exception as e:
            logger.error(f"Image deskew failed: {e}")
            return image_bytes
