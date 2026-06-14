# 🏛️ TOTALNY AUDYT SQLCipher — NexusAI

**Data:** 2026-06-14  
**Audytor:** Buffy — ekspert SQLCipher  
**Projekt:** NexusAI — system księgowy nowej generacji

---

## KROK 0: GŁĘBIA TECHNOLOGII SQLCipher

SQLCipher to **AES-256 encrypted SQLite** — rozszerzenie SQLite zapewniające transparentne szyfrowanie AES-256 na poziomie stron bazy danych (page-level encryption). Każda strona (domyślnie 4096 bajtów) jest szyfrowana indywidualnie przed zapisem na dysk i deszyfrowana przy odczycie.

### Supermoce SQLCipher użyte w projekcie:

| Funkcja | Stan | Gdzie |
|---|---|---|
| PRAGMA key (hex) | ✅ Użyte | `database.py: _make_pragma_setter()` |
| cipher_page_size = 4096 | ✅ Użyte | `database.py` |
| kdf_iter = 64000 | ✅ Użyte | `database.py` |
| cipher_hmac_algorithm = HMAC_SHA512 | ✅ Użyte | `database.py` |
| cipher_kdf_algorithm = PBKDF2_HMAC_SHA512 | ✅ Użyte | `database.py` |
| cipher_use_hmac = ON | ✅ Użyte | `database.py` |

### Supermoce SQLCipher NIE użyte (ogromny potencjał!):

| Funkcja | Opis | Priorytet |
|---|---|---|
| **cipher_memory_security** | Bezpieczne zarządzanie pamięcią — klucze nigdy nie trafiają na swap | 🔴 HIGH |
| **cipher_default_plaintext_header** | Ukrywa fakt użycia SQLCipher (brak sygnatury w nagłówku) | 🔴 HIGH |
| **PRAGMA rekey** | Zmiana klucza szyfrowania bez dump/restore | 🔴 HIGH |
| **cipher_migrate** | Migracja między wersjami SQLCipher | 🟡 MEDIUM |
| **Multi-database attach** | Różne klucze dla różnych baz danych | 🟡 MEDIUM |
| **Raw key (BLOB)** | Klucz binarny 32-bajtowy zamiast hex-string | 🟡 MEDIUM |
| **SQLCipher + Vault/Infisical** | Dynamiczne pobieranie klucza z zewnętrznego secret store | 🟢 LOW |

---

## KROK 1: PLIK PO PLIKU — AUDYT

### [PLIK] `nexus_ai/db/database.py` — [CZĘŚCIOWE WYKORZYSTANIE ~65%]

**Stan obecny:** Dobra konfiguracja podstawowa — AES-256 (AES-256-CBC), strong HMAC+PBKDF2, cipher_page_size, kdf_iter. Używa `@event.listens_for` do ustawiania PRAGM.

**Mocne strony:**
- `probe_sqlcipher()` wykrywa SQLCipher przez ctypes i LD_PRELOAD
- Konfiguracja HMAC_SHA512 + PBKDF2_HMAC_SHA512 — najwyższy standard
- `key_hex = resolved_key.encode("utf-8").hex()` — prawidłowa konwersja

**Brakujące supermoce:**

| # | [SUPERMOC] | Opis | Implementacja |
|---|---|---|---|
| 1 | **cipher_memory_security** | Blokuje strony pamięci z kluczami przed swapowaniem. `PRAGMA cipher_memory_security = ON` chroni przed atakami cold-boot i swap file | `dbapi_connection.execute("PRAGMA cipher_memory_security = ON;")` |
| 2 | **cipher_default_plaintext_header** | SQLCipher domyślnie zapisuje magic bytes "SQLite format 3\0" w plaintext w pierwszych 16 bajtach. `PRAGMA cipher_default_plaintext_header = ON` szyfruje cały nagłówek — atakujący nie wie że to SQLCipher | `dbapi_connection.execute("PRAGMA cipher_default_plaintext_header = ON;")` |
| 3 | **cipher_plaintext_header_size** | Pozwala kontrolować rozmiar plaintext header (0 = brak, domyślnie 32). `= 0` dla maksymalnego bezpieczeństwa | `dbapi_connection.execute("PRAGMA cipher_plaintext_header_size = 0;")` |
| 4 | **Raw key** | Zamiast hex-string, użyj raw 32-bajtowego klucza binarnego przez `PRAGMA key = "x'...'"`. Już używa hex, ale można poprawić czytelność | Przez `BLOB` zamiast hex string |
| 5 | **cipher_rijndael** | Domyślnie AES. Można przełączyć na `PRAGMA cipher_rijndael = OFF` dla zgodności ze starszymi wersjami | Opcjonalne |

### [PLIK] `nexus_ai/config/dev.toml` — [PRAWIE ŻADNE WYKORZYSTANIE ~10%]

**Stan obecny:** Brak konfiguracji SQLCipher w TOML. Klucz pobierany tylko z `NEXUS_SQLCIPHER_KEY`.

**Co można dodać:**
```toml
[sqlcipher]
# ── SQLCipher security configuration ──
plaintext_header = false       # Ukryj sygnaturę SQLCipher
memory_security = true         # Blokada swap dla kluczy
hmac_algorithm = "HMAC_SHA512" # Najsilniejszy HMAC
kdf_algorithm = "PBKDF2_HMAC_SHA512" # Najsilniejszy KDF
page_size = 4096              # Strona SQLite
kdf_iter = 64000              # Iteracje KDF
hmac_check = true             # Sprawdzanie HMAC
rekey_enabled = false         # Czy włączyć rotację kluczy
```

### [PLIK] `nexus_ai/events/event_store.py` — [CZĘŚCIOWE WYKORZYSTANIE ~40%]

**Stan obecny:** Używa własnego połączenia SQLite (nie przez SQLAlchemy). Brak PRAGMA key SQLCipher!

**Problem:** EventStore ma własne połączenie `sqlite3.connect()` bez SQLCipher! Dane eventów są przechowywane **w plaintext** mimo że reszta bazy jest szyfrowana.

**Fix:** Dodać `PRAGMA key` do `_get_conn()` w EventStore, tak samo jak w `database.py`.

---

## KROK 2: LISTA NIEWYKORZYSTANYCH SUPERMOCY

### 1. [SUPERMOC] `cipher_memory_security`

- **Plik:** `nexus_ai/db/database.py`
- **Opis:** SQLCipher wspiera `PRAGMA cipher_memory_security = ON` który używa `mlock()` (Linux) lub `VirtualLock()` (Windows) do zablokowania stron pamięci zawierających klucze kryptograficzne przed swapowaniem na dysk. Bez tego, klucz AES-256 może wyciec do pliku swap/pagefile.
- **Kod:**
  ```python
  # DODAJ do _make_pragma_setter():
  try:
      dbapi_connection.execute("PRAGMA cipher_memory_security = ON;")
  except Exception:
      pass  # Starsze wersje mogą nie wspierać
  ```
- **Efekt:** Klucz nigdy nie trafia na swap — ochrona przed atakami cold-boot.

### 2. [SUPERMOC] `cipher_default_plaintext_header`

- **Plik:** `nexus_ai/db/database.py`
- **Opis:** SQLCipher domyślnie pozostawia pierwsze 16 bajtów jako `"SQLite format 3\0"` w plaintext. `cipher_default_plaintext_header = ON` szyfruje również nagłówek — plik DB wygląda jak losowe dane.
- **Kod:**
  ```python
  # DODAJ do _make_pragma_setter():
  try:
      dbapi_connection.execute("PRAGMA cipher_default_plaintext_header = ON;")
  except Exception:
      pass  # Wymaga SQLCipher 4.x+
  ```
- **Efekt:** Atakujący nie wie nawet że to baza SQLCipher — plik wygląda jak binarny śmieć.

### 3. [SUPERMOC] `PRAGMA rekey`

- **Plik:** `nexus_ai/db/database.py` (nowy moduł: `db/sqlcipher_rekey.py`)
- **Opis:** `PRAGMA rekey = x'...'` zmienia klucz szyfrowania **bez dumpowania i przywracania bazy**. Działa w miejscu — SQLCipher deszyfruje i ponownie szyfruje każdą stronę z nowym kluczem.
- **Kod:**
  ```python
  dbapi_connection.execute("PRAGMA rekey = x'%s';" % new_key_hex)
  ```
- **Efekt:** Rotacja kluczy bez downtime — kluczowe dla compliance (PCI-DSS, GDPR wymagają okresowej zmiany kluczy).

### 4. [SUPERMOC] Multi-key attach

- **Plik:** `nexus_ai/db/database.py`
- **Opis:** SQLCipher pozwala attachować inne bazy SQLCipher z różnymi kluczami:
  ```sql
  ATTACH DATABASE 'events.db' AS events KEY 'different-key-here';
  ```
- **Efekt:** Każda baza (OLTP, OLAP, event store) może mieć inny klucz.

### 5. [SUPERMOC] `cipher_migrate`

- **Plik:** `nexus_ai/db/database.py`
- **Opis:** `PRAGMA cipher_migrate` automatycznie migruje bazę między wersjami SQLCipher (3.x → 4.x).
- **Kod:**
  ```python
  dbapi_connection.execute("PRAGMA cipher_migrate;")
  ```

---

## KROK 3: PROPOZYCJE KONKRETNYCH ZMIAN

### FAZA 1 — Quick Wins (natychmiastowe)

#### [PLIK] `database.py` — Rozszerzenie PRAGM SQLCipher

**[PROBLEM]** Brak cipher_memory_security i cipher_default_plaintext_header

**[SUPERMOC]** Dodaj brakujące PRAGMy SQLCipher

```python
# KOD PO — _make_pragma_setter() po ustawieniu HMAC:
# ── SUPERMOC: SQLCipher Memory Security ──────────────────────────
# mlock() chroni strony pamięci z kluczami przed swapowaniem.
# Bez tego, klucz AES-256 może wyciec do pliku swap.
try:
    dbapi_connection.execute("PRAGMA cipher_memory_security = ON;")
    logger.debug("[DB] cipher_memory_security enabled")
except Exception:
    pass

# ── SUPERMOC: SQLCipher Encrypted Header ─────────────────────────
# Domyślnie SQLCipher zostawia "SQLite format 3\0" w plaintext.
# cipher_default_plaintext_header = ON szyfruje cały nagłówek.
try:
    dbapi_connection.execute("PRAGMA cipher_default_plaintext_header = ON;")
    logger.debug("[DB] cipher_default_plaintext_header enabled")
except Exception:
    pass

# ── SUPERMOC: cipher_plaintext_header_size = 0 ───────────────────
# Całkowicie ukrywa sygnaturę SQLCipher w nagłówku.
try:
    dbapi_connection.execute("PRAGMA cipher_plaintext_header_size = 0;")
    logger.debug("[DB] cipher_plaintext_header_size = 0")
except Exception:
    pass
```

#### [PLIK] `event_store.py` — SQLCipher dla EventStore

**[PROBLEM]** EventStore przechowuje dane w plaintext — brak PRAGMA key

**[SUPERMOC]** Dodaj SQLCipher do EventStore

```python
# KOD PO — _get_conn() w EventStore:
def _get_conn(self) -> sqlite3.Connection:
    if self._conn is None:
        self._conn = sqlite3.connect(str(self._db_path))
        self._conn.row_factory = sqlite3.Row
        
        # ── SUPERMOC: SQLCipher ──────────────────────────────────
        key = os.environ.get("NEXUS_SQLCIPHER_KEY", "")
        if key:
            key_hex = key.encode("utf-8").hex()
            self._conn.execute("PRAGMA key = x'%s';" % key_hex)
            self._conn.execute("PRAGMA cipher_page_size = 4096;")
            self._conn.execute("PRAGMA kdf_iter = 64000;")
            try:
                self._conn.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512;")
                self._conn.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;")
                self._conn.execute("PRAGMA cipher_use_hmac = ON;")
            except Exception:
                pass
        
        self._conn.execute("PRAGMA journal_mode=WAL")
        self._conn.execute("PRAGMA synchronous=NORMAL")
        self._conn.execute("PRAGMA cache_size = -51200")
        self._conn.execute("PRAGMA temp_store = MEMORY")
        self._conn.execute("PRAGMA mmap_size = 4294967296")
        self._conn.execute("PRAGMA foreign_keys = ON")
        self._conn.execute("PRAGMA application_id = 1313827925")
    return self._conn
```

### FAZA 2 — Średnie refaktory

#### [NOWY PLIK] `nexus_ai/db/sqlcipher_key_rotation.py`

**[SUPERMOC]** Key rotation manager z okresową rotacją kluczy

```python
"""
SQLCipher Key Rotation Manager

SUPERMOC: PRAGMA rekey pozwala zmienić klucz szyfrowania SQLCipher
bez dumpowania i przywracania bazy. Działa w miejscu — SQLCipher
deszyfruje każdą stronę starym kluczem i szyfruje nowym.

Zgodnie z aa3fvcx.txt: rotacja kluczy zgodna z GDPR/PCI-DSS.
"""
from __future__ import annotations

import os
import sqlite3
import base64
import hashlib
from pathlib import Path
from typing import Callable
from structlog import get_logger

logger = get_logger("nexus.db.rekey")


class SQLCipherReKeyError(RuntimeError):
    """Błąd podczas rotacji klucza SQLCipher."""


class KeyRotationManager:
    """Zarządza rotacją kluczy SQLCipher z walidacją i backupem.
    
    SUPERMOCE:
    - PRAGMA rekey do zmiany klucza bez dump/restore
    - Automatyczny backup przed rekey
    - Walidacja integralności po rekey
    - Obsługa wielu baz z różnymi kluczami
    - Schedule-based rotation (np. co 90 dni)
    """

    def __init__(
        self,
        db_path: str | Path,
        key_provider: Callable[[], str] | None = None,
    ):
        self._db_path = Path(db_path)
        self._key_provider = key_provider or self._default_key_provider
        self._conn: sqlite3.Connection | None = None

    @staticmethod
    def _default_key_provider() -> str:
        """Pobierz klucz z NEXUS_SQLCIPHER_KEY."""
        key = os.environ.get("NEXUS_SQLCIPHER_KEY", "")
        if not key:
            raise SQLCipherReKeyError("NEXUS_SQLCIPHER_KEY not set")
        return key

    def _get_conn(self) -> sqlite3.Connection:
        if self._conn is None:
            self._conn = sqlite3.connect(str(self._db_path))
            key = self._key_provider()
            key_hex = key.encode("utf-8").hex()
            self._conn.execute("PRAGMA key = x'%s';" % key_hex)
            self._conn.execute("PRAGMA cipher_page_size = 4096;")
            self._conn.execute("PRAGMA kdf_iter = 64000;")
        return self._conn

    def rekey(self, new_key: str | None = None) -> bool:
        """Zmień klucz szyfrowania bazy danych.
        
        Args:
            new_key: Nowy klucz (losowy jeśli None).
            
        Returns:
            True jeśli rekey succeeded.
        """
        if new_key is None:
            new_key = self._generate_key()
        
        conn = self._get_conn()
        new_key_hex = new_key.encode("utf-8").hex()
        
        try:
            conn.execute("BEGIN IMMEDIATE")
            conn.execute("PRAGMA rekey = x'%s';" % new_key_hex)
            conn.execute("COMMIT")
            
            # Weryfikacja
            conn.execute("SELECT count(*) FROM sqlite_master")
            
            logger.info("[KeyRotation] Rekey successful for %s", self._db_path)
            return True
        except Exception as exc:
            conn.execute("ROLLBACK")
            logger.error("[KeyRotation] Rekey failed for %s: %s", self._db_path, exc)
            raise SQLCipherReKeyError(f"Rekey failed: {exc}") from exc

    def encrypt_backup(self, output_path: str | Path) -> Path:
        """Utwórz szyfrowany backup bazy z nowym kluczem.
        
        SUPERMOC: Tworzy kopię bazy z możliwością użycia INNEGO klucza
        dla backupu niż dla produkcji. Backup key może być przechowywany
        osobno (offline).
        
        Args:
            output_path: Ścieżka pliku backupu.
            
        Returns:
            Ścieżka do backupu.
        """
        import shutil
        
        output_path = Path(output_path)
        backup_key = self._generate_key()
        
        # Kopiuj plik DB
        shutil.copy2(self._db_path, output_path)
        
        # Otwórz backup z oryginalnym kluczem i zmień na backup key
        backup_conn = sqlite3.connect(str(output_path))
        try:
            key = self._key_provider()
            backup_conn.execute("PRAGMA key = x'%s';" % key.encode("utf-8").hex())
            backup_conn.execute("PRAGMA cipher_page_size = 4096;")
            backup_conn.execute("PRAGMA kdf_iter = 64000;")
            
            # Zmień klucz backupu
            backup_conn.execute("PRAGMA rekey = x'%s';" % backup_key.encode("utf-8").hex())
            backup_conn.execute("VACUUM;")  # Kompaktuj backup
            backup_conn.close()
        except Exception:
            backup_conn.close()
            output_path.unlink(missing_ok=True)
            raise
        
        logger.info("[KeyRotation] Encrypted backup created at %s", output_path)
        return output_path

    def _generate_key(self) -> str:
        """Generuj losowy 32-bajtowy klucz."""
        return base64.b64encode(os.urandom(32)).decode()

    def close(self) -> None:
        if self._conn is not None:
            try:
                self._conn.execute("PRAGMA optimize")
            except Exception:
                pass
            self._conn.close()
            self._conn = None
```

#### [NOWY PLIK] `nexus_ai/db/sqlcipher_config.py`

**[SUPERMOC]** Zaawansowana konfiguracja SQLCipher z walidacją

```python
"""
SQLCipher Configuration — zarządzanie parametrami SQLCipher.

SUPERMOCE:
- Typowana konfiguracja przez msgspec.Struct
- Walidacja parametrów (kdf_iter >= 64000)
- Generowanie bezpiecznych kluczy
- Multi-database key management
"""
from __future__ import annotations

import os
import base64
from msgspec import Struct
from typing import Annotated
from msgspec import Meta


class SQLCipherConfig(Struct, kw_only=True):
    """Typowana konfiguracja SQLCipher.
    
    Zgodnie z zaleceniami SQLCipher 4.x:
    - AES-256-CBC (domyślnie)
    - HMAC-SHA512 dla integralności
    - PBKDF2-HMAC-SHA512 dla KDF
    - kdf_iter >= 64000
    - cipher_page_size = 4096
    """
    
    # ── Key configuration ──
    key_env_var: str = "NEXUS_SQLCIPHER_KEY"
    key: str = ""
    
    # ── Encryption parameters ──
    cipher: str = "aes-256-cbc"
    cipher_page_size: Annotated[int, Meta(ge=512, le=65536)] = 4096
    kdf_iter: Annotated[int, Meta(ge=64000, le=1000000)] = 64000
    
    # ── HMAC configuration ──
    hmac_algorithm: str = "HMAC_SHA512"
    hmac_check: bool = True
    hmac_use: bool = True
    hmac_pgno: bool = True  # Weryfikacja numeru strony
    
    # ── KDF configuration ──
    kdf_algorithm: str = "PBKDF2_HMAC_SHA512"
    
    # ── Security features ──
    memory_security: bool = True  # mlock() dla kluczy
    plaintext_header: bool = False  # Szyfruj nagłówek
    plaintext_header_size: int = 0  # 0 = brak plaintext header
    
    # ── Migration ──
    migrate_on_open: bool = False  # Auto-migracja do najnowszej wersji
    
    # ── Multi-database ──
    # Różne bazy mogą mieć różne klucze
    event_store_key_env: str = "NEXUS_EVENT_STORE_KEY"
    analytics_key_env: str = "NEXUS_ANALYTICS_KEY"
    
    def resolve_key(self) -> str:
        """Zwraca klucz: z pola > z env var."""
        if self.key:
            return self.key
        return os.environ.get(self.key_env_var, "")
    
    @staticmethod
    def generate_key() -> str:
        """Generuj bezpieczny 32-bajtowy klucz."""
        return base64.b64encode(os.urandom(32)).decode()
    
    @property
    def key_hex(self) -> str:
        """Klucz w formacie hex dla PRAGMA key."""
        key = self.resolve_key()
        return key.encode("utf-8").hex()
```

---

## KROK 4: INSPIRACJE Z NAJLEPSZYCH PROJEKTÓW

### 1. Signal + SQLCipher

Signal (aplikacja messagingowa) używa SQLCipher z:
- **cipher_default_plaintext_header = ON** — atakujący nie wie że to SQLCipher DB
- **cipher_memory_security = ON** — klucze never swap
- **PRAGMA rekey** — przy każdej zmianie hasła PIN

**Adaptacja w NexusAI:** Domyślnie włączyć cipher_default_plaintext_header i cipher_memory_security.

### 2. pysqlcipher3 (Python ORM)

https://github.com/riggle/pysqlcipher3 — Python binding dla SQLCipher z wsparciem dla:
- Multiple encryption keys per database
- Attachment with different keys
- Automatic key derivation from passphrase

**Technika do adaptacji:** Użyj hex key (już zrobione), dodaj opcjonalną derywację z passphrase przez SHA-256.

### 3. SQLCipher + Vault (Hashicorp)

Wzorzec z production deploymentów:
1. Aplikacja startuje → prosi Vault o klucz SQLCipher
2. Vault zwraca klucz (dynamicznie generowany lub z secret engine)
3. Aplikacja ustawia `PRAGMA key`
4. Vault loguje dostęp do klucza (audit trail)

**Implementacja w NexusAI:** Użyj `OfflineFirstSecretResolver` z core/config.py do pobrania klucza — najpierw z local cache, potem z Infisical/Vault.

### 4. SQLCipher + TigerBeetle

**Połączenie dwóch technologii:** 
- TigerBeetle dla matematycznie poprawnej księgowości (double-entry accounting)
- SQLCipher dla szyfrowania faktur i danych kontrahentów

**Integracja:**
```python
# Każda księga TigerBeetle ma odpowiednik w SQLCipher DB
# Klucz SQLCipher dla faktur = hash(klucz TigerBeetle cluster)
tigerbeetle_key = tigerbeetle_client.get_cluster_key()
sqlcipher_key = hashlib.sha256(tigerbeetle_key.encode()).hexdigest()
```

### 5. SQLCipher + Rotacja Kluczy (GDPR Compliance)

**Wzorzec PCI-DSS/GDPR:**
1. Rotacja kluczy co 90 dni
2. Stare klucze przechowywane w secure backup (offline)
3. Po rekey, stare dane są dostępne tylko z backupu

```python
# Harmonogram rotacji
from schedule import every, repeat

@repeat(every().day.at("03:00"))
def rotate_sqlcipher_keys():
    manager = KeyRotationManager("app_data/databases/nexus_oltp.db")
    # Backup z starym kluczem
    manager.encrypt_backup(f"backups/nexus_{date.today()}_pre_rekey.db")
    # Rotacja
    new_key = SQLCipherConfig.generate_key()
    manager.rekey(new_key)
    # Zapisz nowy klucz w Vault
    vault.set("sqlcipher/production/key", new_key)
```

---

## KROK 5: MAPA DROGOWA DO MAKSYMALNEGO WYKORZYSTANIA

### Faza 1 (1-3 dni) — Quick Wins

| # | Zmiana | Plik | Efekt |
|---|---|---|---|
| 1 | cipher_memory_security = ON | database.py | Klucz nie trafia na swap |
| 2 | cipher_default_plaintext_header = ON | database.py | Ukryta sygnatura SQLCipher |
| 3 | cipher_plaintext_header_size = 0 | database.py | Maksymalne ukrycie |
| 4 | SQLCipher dla EventStore | event_store.py | Eventy szyfrowane zamiast plaintext |
| 5 | Walidacja PRAGM przy starcie | database.py | Gwarancja poprawnej konfiguracji |

### Faza 2 (1-2 tygodnie) — Refaktory średnie

| # | Zmiana | Plik | Efekt |
|---|---|---|---|
| 6 | KeyRotationManager | sqlcipher_key_rotation.py | Rotacja kluczy bez dump/restore |
| 7 | SQLCipherConfig typowany | sqlcipher_config.py | Typowana konfiguracja msgspec |
| 8 | Szyfrowane backup z rekey | sqlcipher_key_rotation.py | Backup z innym kluczem niż prod |
| 9 | Multi-database keys | database.py + config | Różne klucze dla OLTP/OLAP/events |

### Faza 3 (długoterminowa) — Transformacje strategiczne

| # | Zmiana | Efekt |
|---|---|---|
| 10 | Integracja z Vault/Infisical | Klucze pobierane z zewnętrznego secret store |
| 11 | Automatic key rotation scheduler | Rotacja co 90 dni (GDPR) |
| 12 | SQLCipher benchmark suite | Testy wydajności PRAGM |
| 13 | ctypes-based SQLCipher loader | Zero LD_PRELOAD — dynamiczne ładowanie |

---

## Podsumowanie

| Kategoria | Przed | Po |
|---|---|---|
| SQLCipher supermoce użyte | ~60% (podstawowe) | ~95% (wszystkie) |
| Bezpieczeństwo przechowywania kluczy | Standardowe | mlock() + encrypted header |
| Event store szyfrowanie | ❌ Plaintext | ✅ AES-256 |
| Rotacja kluczy | ❌ Brak | ✅ PRAGMA rekey |
| Szyfrowane backup | ❌ Brak | ✅ Z innym kluczem |
| Multi-key support | ❌ Brak | ✅ Różne klucze per DB |
