# -*- mode: python; coding: utf-8 -*-
import sys
import os
from PyInstaller.utils.hooks import collect_data_files, collect_submodules, copy_metadata

# --- [1] KONFIGURACJA ŚRODOWISKA ---
# Zwiększenie limitu rekurencji dla głębokich zależności Transformers/Torch
sys.setrecursionlimit(10000)
block_cipher = None
project_root = os.path.abspath(os.getcwd())

# --- [2] ZBIERANIE DANYCH (DATA & METADATA) ---
datas = []

# Wiele bibliotek AI sprawdza wersje w runtime. Brak metadanych = "DistributionNotFound"
packages_to_metadata = [
    'torch', 'transformers', 'surya', 'tqdm', 'regex', 'requests',
    'packaging', 'filelock', 'numpy', 'huggingface-hub', 'safetensors',
    'pyyaml', 'tokenizers', 'onnxruntime', 'duckdb'
]

for pkg in packages_to_metadata:
    try:
        datas += copy_metadata(pkg)
    except:
        pass

# Dodajemy pliki statyczne, modele i binarne serwery
added_files = [
    ('models/', 'models/'),          # Wagi AI
    ('nats-server.exe', '.'),        # Serwer NATS
    ('assets/', 'assets/'),          # Ikony/Grafiki UI
    ('app_data/', 'app_data/'),      # Struktura folderów
    ('db/', 'db/'),                  # Skrypty DB
    ('.env.example', '.'),           # Szablon konfiguracji
    ('core/exporters/*.txt', 'core/exporters/') # Szablony eksportu
]

datas += added_files
datas += collect_data_files('surya')
datas += collect_data_files('transformers')

# --- [3] UKRYTE IMPORTY (HIDDEN IMPORTS) ---
# Rejestrujemy moduły ładowane dynamicznie
hidden_imports = [
    'sqlalchemy.ext.declarative',
    'sqlalchemy.orm.attributes',
    'sqlalchemy.dialects.sqlite',
    'sqlalchemy.ext.baked',
    'sqlalchemy.sql.default_comparator',
    'duckdb',
    'taskiq_nats',
    'taskiq.serializers.json_serializer',
    'flet',
    'flet.canvas',
    'flet.charts',
    'fastapi',
    'uvicorn',
    'uvicorn.logging',
    'uvicorn.protocols.http.httptools_impl',
    'uvicorn.protocols.websockets.wsproto_impl',
    'litestar',
    'litestar.plugins.sqlalchemy',
    'onnxruntime',
    'tokenizers',
    'sentence_transformers',
    'email.mime.multipart',
    'email.mime.text',
    'email.mime.base',
    'lancedb',
    'pyarrow',
    'pydantic',
    'httpx'
]

# Automatyczne skanowanie Twoich modułów
for module in ['core', 'models', 'services', 'pipeline', 'db', 'api', 'frontend', 'worker']:
    try:
        hidden_imports += collect_submodules(module)
    except:
        pass

# --- [4] ANALIZA I FILTROWANIE ---
a = Analysis(
    ['main.py'],
    pathex=[project_root],
    binaries=[],
    datas=datas,
    hiddenimports=hidden_imports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['notebook', 'jupyter', 'matplotlib', 'test', 'pytest', 'unittest', 'setuptools', 'distutils', 'PIL._tkinter'],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

# --- [5] KONFIGURACJA PLIKU EXE ---
exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='NexusAI',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True, # Zostawiamy True dla logów AI/Workera/NATS
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='assets/icon.ico',
    version='file_version_info.txt', # Powiązanie z plikiem wersji
    manifest="""
    <assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
      <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
        <security>
          <requestedPrivileges>
            <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
          </requestedPrivileges>
        </security>
      </trustInfo>
    </assembly>
    """
)

# --- [6] KOLEKCJA (FOLDER MODE - ONEDIR) ---
# Folder mode jest stabilniejszy dla aplikacji AI (szybszy start)
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=['torch', 'onnxruntime', 'mkl', 'libopenblas'], # Nie kompresujemy ciężkich DLL (ryzyko błędów)
    name='NexusAI_Distribution',
)
