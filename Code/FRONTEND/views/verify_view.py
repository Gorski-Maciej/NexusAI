# frontend/views/verify_view.py
import flet as ft

class InteractivePDFViewer(ft.UserControl):
    """Widok PDF z interaktywnymi strefami OCR."""

    def __init__(self, image_path: str, boxes: list[dict]):
        super().__init__()
        self.image_path = image_path
        self.boxes = boxes # Lista współrzędnych [x1, y1, x2, y2] + label
        self.overlays = []

    def highlight_field(self, label: str):
        """Metoda wywoływana z formularza, aby przewinąć i podświetlić pole."""
        for box in self.overlays:
            if box.data == label:
                box.bgcolor = ft.colors.with_opacity(0.3, ft.colors.YELLOW_ACCENT_400)
                box.border = ft.border.all(2, ft.colors.AMBER_600)
            else:
                box.bgcolor = ft.colors.TRANSPARENT
                box.border = None
        self.update()

    def build(self):
        # Tworzymy warstwę z obrazem i nakładkami
        stack = ft.Stack(
            controls=[
                ft.Image(src=self.image_path, fit=ft.ImageFit.CONTAIN)
                # Tu byłyby dodane prostokąty z self.overlays na podstawie self.boxes
            ]
        )
        return stack
