# core/llm_extractor.py
from llama_cpp import Llama

from nexus_ai.core.msgspec_utils import msgspec_loads


class LocalLLMExtractor:
    def __init__(self, model_path="models/phi-3-mini-4k-instruct.Q4_K_S.gguf"):
        # n_ctx to okno kontekstowe (4096 wystarczy na fakturę)
        self.llm = Llama(model_path=model_path, n_ctx=4096, n_threads=4)

    def extract_invoice_data(self, ocr_text: str):
        prompt = f"""<|user|>
Analizuj poniższy tekst faktury i wyciągnij dane w formacie JSON.
Wymagane pola: numer_faktury, data_sprzedazy, kwota_netto, kwota_vat, waluta, termin_platnosci.
Tekst faktury:
{ocr_text}
<|assistant|>
```json
"""
        # Generujemy odpowiedź (stop na ``` kończącym JSON)
        output = self.llm(prompt, max_tokens=512, stop=["```"], echo=False)
        json_str = output['choices'][0]['text']
        return msgspec_loads(json_str)
