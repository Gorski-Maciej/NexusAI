# frontend/views/mobile_sync.py
import qrcode
import socket
import flet as ft

def get_local_ip():
    # Pobiera IP komputera w sieci lokalnej (np. 192.168.1.15)
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    return s.getsockname()[0]

def MobileSyncView(page: ft.Page):
    local_ip = get_local_ip()
    port = page.session.get("api_port")
    token = page.session.get("api_token")

    # Adres, który telefon "uderzy" (musi być dostępny w sieci lokalnej)
    upload_url = f"http://{local_ip}:{port}/mobile/upload?token={token}"

    qr = qrcode.make(upload_url)
    qr.save("assets/temp_qr.png")

    return ft.Column([
        ft.Text("Zeskanuj telefonem, aby wysłać zdjęcie faktury"),
        ft.Image(src="temp_qr.png", width=200)
    ])
