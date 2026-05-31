# core/categorizer.py
from sentence_transformers import SentenceTransformer
from scipy.spatial.distance import cosine

class OfflineCategorizer:
    def __init__(self):
        # Ładujemy model z naszego lokalnego cache'u
        self.model = SentenceTransformer('all-MiniLM-L6-v2')

        # Definiujemy kategorie, których szukamy
        self.categories = {
            "PALIWO": "stacja paliw benzyna olej napędowy autogaz orlen bp shell",
            "IT": "usługi informatyczne oprogramowanie hosting domena serwer aws sprzęt",
            "BIURO": "artykuły biurowe papier tonery drukarka meble długopisy",
            "MARKETING": "reklama facebook google adwords ulotki kampania"
        }

        # Obliczamy wektory (embeddings) dla naszych kategorii tylko raz
        self.category_vectors = {
            name: self.model.encode(keywords)
            for name, keywords in self.categories.items()
        }

    def predict_category(self, invoice_lines_text: str) -> str:
        text_vector = self.model.encode(invoice_lines_text)
        best_category = "INNE"
        min_distance = float('inf')

        for name, cat_vector in self.category_vectors.items():
            dist = cosine(text_vector, cat_vector)
            if dist < min_distance:
                min_distance = dist
                best_category = name

        return best_category if min_distance < 0.6 else "INNE"
