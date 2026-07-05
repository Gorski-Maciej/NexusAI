# 🦀 Moduł Rust — `nexus-crypto` (Rust + PyO3)

> **Cel:** Pełna dokumentacja wewnętrznego modułu kryptograficznego `nexus-crypto` zaimplementowanego w Rust z PyO3.  \n> **Kiedy czytać:** Przed jakąkolwiek zmianą w `nexus_ai/rust/`, przed code review zmian w `nexus-crypto`, przed audytem bezpieczeństwa.

---

## 1. Misja i filozofia

`nexus-crypto` to minimalny moduł kryptograficzny zbudowany w języku Rust z interfejsem Python przez PyO3/Maturin. Zawiera **dokładnie 3 algorytmy** — żadnego więcej — bo mniej = bezpieczniej.

### 1.1 Dlaczego własny moduł (nie PyNaCl / cryptography)?

| Argument | Szczegóły |
|---|---|
| **Minimalna powierzchnia ataku** | Biblioteka `cryptography` ma > 50 algorytmów i > 200k LOC. NexusAI potrzebuje 3. |
| **Statyczna kompilacja w Nuitkę** | Moduł Rust linkuje się statycznie → zero zewnętrznych .so |
| **Pełna kontrola łańcucha dostaw** | Weryfikujemy każdą wersję `rust` crate, nie mamy transitive deps |
| **Szybkość** | ChaCha20-Poly1305 w Rust: ~1 GB/s (vs ~300 MB/s w PyCryptodome) |
| **Wymuszenie best practices** | Stałe parametry Argon2id (memory=64MB, iterations=3, parallelism=4) na poziomie API |

### 1.2 Czego NIE ma `nexus-crypto`

| Algorytm | Dlaczego nie | Alternatywa |
|---|---|---|
| AES-128 | Wymaga hardware AES-NI, mniej portable | ChaCha20-Poly1305 |
| RSA | Asymetryczny — nie używamy, KG kluczy jest w KSeF | OpenSSL w submodule KSeF |
| ECDSA | Podpisy cyfrowe — używane w KSeF oddzielnie | OpenSSL |
| SHA-1, MD5 | Przestarzałe | SHA-256 |
| PBKDF2 | Mniej odporny na GPU | Argon2id |
| Blowfish, 3DES | Przestarzałe | — |
| Fernet (AES-CBC + HMAC) | Podatny na padding oracle | ChaCha20-Poly1305 AEAD |

> Zasada: **anything not essential = removed.** Mniej kodu = mniej bugów.

---

## 2. Struktura plików

```
nexus_ai/rust/
├── Cargo.toml                          # Maturin manifest
├── pyproject.toml                      # Build config
├── README.md                           # Krótka instrukcja (auto-generated)
└── src/
    ├── lib.rs                          # Public API + PyO3 exports
    ├── aead.rs                         # ChaCha20-Poly1305 AEAD
    ├── argon2.rs                       # Argon2id KDF
    ├── sha256.rs                       # SHA-256 hash
    ├── vault.rs                        # Bezpieczny magazyn kluczy (mlock)
    ├── error.rs                        # Typy błędów (thiserror)
    ├── constants.rs                    # Stałe (nonce sizes, tag sizes)
    └── tests/                          # Testy Rust (cargo test)
        ├── aead_test.rs
        ├── argon2_test.rs
        └── sha256_test.rs
```

### 2.1 Limity linii kodu (LOC budget)

Moduł jest objęty **budżetem LOC** — maksymalnie 1500 linijek Rust:

```toml
# nexus_ai/rust/.cloc-budget.toml
[rust]
max_loc = 1500
critical_paths = ["aead.rs", "argon2.rs", "sha256.rs"]
```

Przekroczenie = błąd kompilacji (sprawdzane w CI).

---

## 3. Algorytmy — specyfikacja

### 3.1 AEAD: ChaCha20-Poly1305 (RFC 8439)

| Parametr | Wartość |
|---|---|
| **Algorytm** | ChaCha20 (stream cipher) |
| **MAC** | Poly1305 (universal hash) |
| **Klucz** | 256 bit (32 bajty) |
| **Nonce** | 96 bit (12 bajtów) — jeden nonce per klucz |
| **Tag** | 128 bit (16 bajtów) |
| **AAD** | Associated Authenticated Data — opcjonalne |

#### Interfejs Rust:

```rust
// nexus_ai/rust/src/aead.rs
pub fn aead_encrypt(
    key: &[u8; 32],
    nonce: &[u8; 12],
    plaintext: &[u8],
    aad: &[u8]
) -> Result<Vec<u8>, NexusCryptoError>;  // ciphertext + tag

pub fn aead_decrypt(
    key: &[u8; 32],
    nonce: &[u8; 12],
    ciphertext_with_tag: &[u8],
    aad: &[u8]
) -> Result<Vec<u8>, NexusCryptoError>;  // plaintext
```

#### Interfejs Python (po PyO3):

```python
from nexus_crypto._core import aead_encrypt, aead_decrypt

key = bytes(32)  # 256-bit klucz (np. z Argon2id)
nonce = bytes(12)
ciphertext = aead_encrypt(
    key=key, nonce=nonce,
    plaintext=b"treść backupu",
    aad=b"backup/2026-07-05"
)
plaintext = aead_decrypt(
    key=key, nonce=nonce,
    ciphertext_with_tag=ciphertext,
    aad=b"backup/2026-07-05"
)
```

#### Zastosowanie w NexusAI:

| Lokalizacja | Użycie |
|---|---|
| `nexus_ai/scripts/backup.py` | Szyfrowanie backupów |
| `nexus_ai/installer/updater.py` | Szyfrowanie OTA update'ów |
| `nexus_ai/core/secrets.py` | Szyfrowanie kluczy API w Vault |

---

### 3.2 Argon2id — KDF (RFC 9106)

| Parametr | Wartość |
|---|---|
| **Wariant** | Argon2id (hybryd Argon2i + Argon2d) |
| **Memory cost** | 64 MB (65536 KiB) |
| **Iterations (time cost)** | 3 |
| **Parallelism (lanes)** | 4 |
| **Salt length** | 16 bajtów (losowy per user) |
| **Output length** | 32 bajty (256 bit) |

#### Interfejs Rust:

```rust
// nexus_ai/rust/src/argon2.rs
pub const ARGON2_MEMORY_KB: u32 = 65536;  // 64 MB
pub const ARGON2_ITERATIONS: u32 = 3;
pub const ARGON2_PARALLELISM: u32 = 4;
pub const ARGON2_SALT_LEN: usize = 16;
pub const ARGON2_HASH_LEN: usize = 32;

pub fn argon2_hash(password: &[u8], salt: &[u8]) -> [u8; 32];
pub fn argon2_verify(password: &[u8], salt: &[u8], expected: &[u8]) -> bool;
pub fn argon2_rehash_needed(password: &[u8], salt: &[u8]) -> bool;
```

#### Interfejs Python:

```python
from nexus_crypto._core import argon2_hash, argon2_verify

salt = bytes(16)  # Z bazy users.salt
password = "user-password".encode("utf-8")
hash_bytes = argon2_hash(password=password, salt=salt)

# Weryfikacja przy logowaniu
is_valid = argon2_verify(password=password, salt=salt, expected=hash_bytes)
```

#### Zastosowanie:

| Lokalizacja | Użycie |
|---|---|
| `nexus_ai/core/secrets.py` | Wyprowadzanie klucza SQLCipher z hasła użytkownika |
| `nexus_ai/api/security.py` | Weryfikacja hasła przy logowaniu |
| `nexus_ai/api/routes/auth.py` | Reset hasła (rehash z nową solą) |

---

### 3.3 SHA-256 — hashowanie (RFC 6234)

| Parametr | Wartość |
|---|---|
| **Algorytm** | SHA-256 (FIPS 180-4) |
| **Output** | 256 bit (32 bajty) |
| **Iterative** | Wiele przebiegów (np. dla proof chain) |

#### Interfejs Rust:

```rust
// nexus_ai/rust/src/sha256.rs
pub fn sha256(data: &[u8]) -> [u8; 32];
pub fn sha256_chain(prev_hash: &[u8; 32], new_event: &[u8]) -> [u8; 32];
pub fn sha256_file(path: &Path) -> Result<[u8; 32], NexusCryptoError>;
pub fn sha256_verify(data: &[u8], expected: &[u8; 32]) -> bool;
```

#### Interfejs Python:

```python
from nexus_crypto._core import sha256, sha256_file, sha256_chain

# Pojedynczy hash
digest = sha256(b"jakiś tekst")  # bytes(32)

# Łańcuch hash dla Proof Chain
prev = bytes(32)
new = sha256_chain(prev_hash=prev, new_event=b"invoice:12345")
```

#### Zastosowanie:

| Lokalizacja | Użycie |
|---|---|
| `nexus_ai/services/proof_chain.py` | Proof Chain decyzji |
| `nexus_ai/services/integrity_verifier.py` | Weryfikacja integralności |
| `nexus_ai/scripts/download_models.py` | SHA-256 weryfikacja modeli GGUF |
| `nexus_ai/scripts/backup.py` | Checksum backupu |

---

### 3.4 Vault — bezpieczny magazyn kluczy (mlock)

| Parametr | Wartość |
|---|---|
| **Mechanizm** | `mlock()` (Linux) / `VirtualLock` (Windows) |
| **Przechowywanie** | W pamięci RAM — nigdy na swap |
| **Zerowanie** | Po użyciu sekret = `0x00*N` |
| **Failsafe** | Jeśli mlock nie dostępny → warning + fallback (zapis do keyring) |

#### Interfejs Rust:

```rust
// nexus_ai/rust/src/vault.rs
pub struct VaultKey {
    bytes: [u8; 32],
}

impl VaultKey {
    pub fn from_password(pwd: &[u8], salt: &[u8]) -> Self;  // Argon2id
    pub fn from_random() -> Self;  // CSPRNG (rdrand / getrandom)
    pub fn lock(&self);  // mlock + cleanup
    pub fn unlock(&self) -> Result<[u8; 32], NexusCryptoError>;
}
```

#### Interfejs Python:

```python
from nexus_crypto._core import VaultKey

key = VaultKey.from_random()  # 32 bajty losowych danych
key.lock()  # zabezpieczone w RAM (no swap)

# Użycie
plaintext = aead_decrypt(
    key=key.unlock(),
    nonce=...,
    ciphertext_with_tag=...,
    aad=...
)
# Po użyciu, klucz wraca do vault automatycznie
```

---

## 4. API eksportowane do Pythona

### 4.1 Lista funkcji (`nexus_crypto._core`)

```python
import nexus_crypto

# AEAD
nexus_crypto.aead_encrypt(key, nonce, plaintext, aad) -> bytes
nexus_crypto.aead_decrypt(key, nonce, ciphertext_with_tag, aad) -> bytes

# KDF
nexus_crypto.argon2_hash(password, salt) -> bytes
nexus_crypto.argon2_verify(password, salt, expected) -> bool
nexus_crypto.argon2_rehash_needed(password, salt) -> bool

# Hash
nexus_crypto.sha256(data) -> bytes
nexus_crypto.sha256_chain(prev_hash, new_event) -> bytes
nexus_crypto.sha256_file(path) -> bytes
nexus_crypto.sha256_verify(data, expected) -> bool

# Vault
nexus_crypto.VaultKey.from_password(pwd, salt) -> VaultKey
nexus_crypto.VaultKey.from_random() -> VaultKey
```

### 4.2 Test kompatybilności

```python
# Sprawdzamy czy moduł jest załadowany poprawnie
python -c "import nexus_crypto; print(nexus_crypto.__version__)"
# Oczekiwane: "2.3.0"
```

---

## 5. Bezpieczeństwo implementacji

### 5.1 Audytowane zależności (Cargo-deps)

| Crate | Wersja | Licencja | Użycie |
|---|---|---|---|
| `chacha20poly1305` | 0.10 | Apache 2.0 / MIT | AEAD |
| `argon2` | 0.5 | Apache 2.0 / MIT | Argon2id KDF |
| `sha2` | 0.10 | Apache 2.0 / MIT | SHA-256 |
| `pyo3` | 0.20 | Apache 2.0 / MIT | Python bindings |
| `thiserror` | 1.0 | Apache 2.0 / MIT | Błędy |
| `getrandom` | 0.2 | Apache 2.0 / MIT | CSPRNG |

> Wszystkie transitive deps są pinned w `Cargo.lock` i poddawane audytowi OpenSSF.

### 5.2 Side-channel attacks — mitigacja

| Atak | Wektor | Mitigacja w `nexus-crypto` |
|---|---|---|
| **Timing attack** | Czas wykonania zależy od sekretu | Użycie algorytmów o stałym czasie (ChaCha20, Poly1305, Argon2id) |
| **Cache attack** | Wzorce dostępu do cache | Stała tablica lookup w ChaCha20 |
| **Power analysis** | Analiza poboru mocy | Softowa implementacja (łatwiejsza do audytu) |
| **Memory dumps** | Wyciek pamięci po crashu | `mlock()` + zerowanie po użyciu |

### 5.3 Obsługa błędów

```rust
// nexus_ai/rust/src/error.rs
#[derive(Debug, thiserror::Error)]
pub enum NexusCryptoError {
    #[error("Ciphertext authentication failed")]
    AuthenticationFailure,  // AEAD tag mismatch
    
    #[error("Invalid key length: expected 32, got {got}")]
    InvalidKeyLength { got: usize },
    
    #[error("Invalid nonce length: expected 12, got {got}")]
    InvalidNonceLength { got: usize },
    
    #[error("Memory lock failed: {reason}")]
    MlockFailed { reason: String },
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}
```

> Każdy błąd ma precyzyjny komunikat — **brak** ogólnych `anyhow::Error` na granicy API.

---

## 6. Procedura release'u

### 6.1 Checklist przed nową wersją `nexus-crypto`

- [ ] Wszystkie testy `cargo test` przechodzą (pokrycie > 90%)
- [ ] `cargo audit` — brak znanych podatności w transitive deps
- [ ] `cargo deny check` — brak niedozwolonych licencji
- [ ] `cargo clippy -- -D warnings` — zero ostrzeżeń
- [ ] Benchmark wydajności: throughput AEAD > 800 MB/s
- [ ] Nowa wersja w `nexuscrypto/` na PyPI
- [ ] SBOM i podpis cyfrowy w GitHub Release

### 6.2 Kompilacja (maturin)

```bash
# Develop (szybki build)
pixi run build-rust
# → cd nexus_ai/rust && maturin develop --release --strip

# Release (koło .whl)
pixi run build-rust-release
# → cd nexus_ai/rust && maturin build --release --strip

# Wynik: nexus_ai/rust/target/wheels/nexus_crypto-*.whl
```

### 6.3 Weryfikacja ABI

```bash
# ABI3 (Python ≥ 3.12) — jeden wheel na wszystkie wersje
maturin build --release --compatibility linux --strip --interpreter 3.13
```

---

## 7. Procedura bezpiecznego incydentu (CVE)

1. **Discovery:** Wykryty problem w `nexus-crypto`
2. **Triaging:** Klasyfikacja (critical/high/medium/low) — kryteria: CVE score, exploitability
3. **Patch:** Nowa wersja `nexus-crypto` z poprawką w < 24h dla krytycznych
4. **Notification:** Email do security@nexus-ai.pl listy subskrybentów
5. **Disclosure:** Po 90 dniach — pełne CVE ID i raport

### 7.1 Zgłaszanie podatności

```bash
security@nexus-ai.pl
[PGP key fingerprint — pobierz z https://nexus-ai.pl/.well-known/pgp-key.asc]
```

---

## 8. Testy wewnętrzne (cargo test)

```rust
// nexus_ai/rust/src/tests/aead_test.rs
#[test]
fn test_aead_roundtrip() {
    let key = [0u8; 32];
    let nonce = [0u8; 12];
    let plaintext = b"secret data here";
    let aad = b"context:backup-2026";
    
    let ciphertext = aead_encrypt(&key, &nonce, plaintext, aad).unwrap();
    let decrypted = aead_decrypt(&key, &nonce, &ciphertext, aad).unwrap();
    
    assert_eq!(decrypted, plaintext);
}

#[test]
fn test_aead_tampered_ciphertext_fails() {
    let key = [1u8; 32];
    let nonce = [1u8; 12];
    let plaintext = b"hello";
    let aad = b"";
    
    let mut ciphertext = aead_encrypt(&key, &nonce, plaintext, aad).unwrap();
    ciphertext[0] ^= 0xFF;  // tamper one byte
    
    assert!(aead_decrypt(&key, &nonce, &ciphertext, aad).is_err());
}
```

---

## 9. Stos wywołań (callgraph)

```
┌──────────────────────────────────────────────────────────┐
│ Python application                                       │
├──────────────────────────────────────────────────────────┤
│ nexus_crypto._core  (PyO3 exports)                       │
├──────────────────────────────────────────────────────────┤
│ aead.rs       argon2.rs       sha256.rs       vault.rs  │
│   ↓              ↓               ↓              ↓        │
│ chacha20poly1305  argon2       sha2         mlock       │
│   (RustCrypto)     (RustCrypto) (RustCrypto) (POSIX/Win) │
├──────────────────────────────────────────────────────────┤
│ OS: mlock(), getrandom(), memchr(), etc.                 │
└──────────────────────────────────────────────────────────┘
```

---

## 10. Wskaźniki wydajności (benchmarki)

| Operacja | Hardware baseline | Throughput |
|---|---|---|
| **AEAD encrypt** | Intel i7-9700K, 1MB chunks | 850 MB/s |
| **AEAD decrypt** | j.w. | 880 MB/s |
| **Argon2id hash** | j.w., 64MB | 250 ms / hash |
| **Argon2id verify** | j.w. | 250 ms / verify |
| **SHA-256** | j.w., 1MB chunks | 480 MB/s |
| **SHA-256 chain** | j.w. | 420 MB/s |

Benchmark uruchamiane automatycznie w CI:
```bash
cd nexus_ai/rust && cargo bench
```

---

## 🔗 Zobacz również

- [Security](SECURITY.md) — kontekst bezpieczeństwa całej aplikacji
- [Architecture](ARCHITECTURE.md) — ADR-007 (nexus-crypto) — dlaczego własny moduł
- [Project Structure](PROJECT_STRUCTURE.md) — lokalizacja `nexus_ai/rust/`
- [Models Manifest](MODELS_MANIFEST.md) — manifest modeli (również weryfikowany SHA-256)

---

> **Data aktualizacji:** 2026-07-05 · **Autor:** NexusAI Team · **Wersja:** 2.3.0
> **Status dokumentu:** Stabilny · **Ostatnia weryfikacja:** 2026-07-05 · **Weryfikator:** Security Officer
