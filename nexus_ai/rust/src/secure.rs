// ═══════════════════════════════════════════════════════════════════════════════
// Secure — Zeroize helpers + mlocked sensitive memory for Rust+PyO3
// ═══════════════════════════════════════════════════════════════════════════════
//
// Używa `zeroize` crate do bezpiecznego czyszczenia pamięci (Zeroizing<Vec<u8>>)
// oraz `libc::mlock`/`libc::munlock` do blokowania pamięci przed swap (MlockedVec).
//
// Komponenty:
//   SensitiveBytes  — Zeroizing<Vec<u8>>: RAII auto-zeroize on drop
//   MlockedVec      — mlocked + auto-zeroize na drop
//   zero()          — zero out a mutable byte slice
//   zero_vec()      — zero out a Vec<u8>
//   protect_read()  — mprotect(PROT_READ) — set memory to read-only
//   protect_rw()    — mprotect(PROT_READ|PROT_WRITE) — set memory to R/W
//
// Structured logging: log::info!, log::debug!, log::warn!
// All logs forwarded to Python structlog via pyo3-log (init in lib.rs)
// ═══════════════════════════════════════════════════════════════════════════════

use libc;
use std::ops::{Deref, DerefMut};
use zeroize::{Zeroize, Zeroizing};

// ═══════════════════════════════════════════════════════════════════════════════
// SensitiveBytes — RAII auto-zeroizing byte buffer (Zeroizing<Vec<u8>>)
// ═══════════════════════════════════════════════════════════════════════════════

/// RAII-protected sensitive byte buffer.
///
/// Memory is automatically zeroized on drop.
/// Uses `zeroize::Zeroizing<Vec<u8>>` internally.
///
/// Usage:
///   let mut buf = SensitiveBytes::new(32);
///   buf.copy_from_slice(&key);
///   // ... use buf ...
///   // On drop: buf is zeroized automatically
///
/// Python dostęp przez:
///   from nexus_crypto import SensitiveBytes
///   buf = SensitiveBytes(32)
pub struct SensitiveBytes {
    inner: Zeroizing<Vec<u8>>,
}

impl SensitiveBytes {
    /// Create a new zero-initialized sensitive buffer.
    pub fn new(size: usize) -> Self {
        log::debug!("SensitiveBytes: allocated {} bytes (zeroized on drop)", size);
        SensitiveBytes {
            inner: Zeroizing::new(vec![0u8; size]),
        }
    }

    /// Create from an existing Vec<u8>, consuming it.
    pub fn from_vec(data: Vec<u8>) -> Self {
        let len = data.len();
        log::debug!("SensitiveBytes: wrapping {} bytes from Vec", len);
        SensitiveBytes {
            inner: Zeroizing::new(data),
        }
    }

    /// Return the length of the buffer.
    pub fn len(&self) -> usize {
        self.inner.len()
    }

    /// Check if the buffer is empty.
    pub fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }

    /// Convert to a hex string (for safe logging).
    pub fn hexdigest(&self) -> String {
        hex::encode(&self.inner[..8.min(self.inner.len())])
    }
}

impl Deref for SensitiveBytes {
    type Target = [u8];
    fn deref(&self) -> &[u8] {
        &self.inner
    }
}

impl DerefMut for SensitiveBytes {
    fn deref_mut(&mut self) -> &mut [u8] {
        &mut self.inner
    }
}

impl AsRef<[u8]> for SensitiveBytes {
    fn as_ref(&self) -> &[u8] {
        &self.inner
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MlockedVec — mlocked + auto-zeroizing byte buffer
// ═══════════════════════════════════════════════════════════════════════════════
//
// Łączy:
//   1. mlock() — blokuje pamięć RAM (zakaz swapowania)
//   2. Zeroize on drop — automatyczne zerowanie przy zwolnieniu
//   3. munlock() — odblokowanie pamięci po zerowaniu
//
// Wymaga libc (mlock/munlock — POSIX, dostępne na Linux/macOS/Android).
// Na platformach bez mlock, konstruktor zwraca Err z opisem błędu.
// ═══════════════════════════════════════════════════════════════════════════════

/// Memory-locked sensitive buffer with auto-zeroize on drop.
///
/// Memory is:
///   1. Locked with mlock() — prevents swapping to disk
///   2. Zeroized on drop — securely erased before munlock
///   3. Unlocked with munlock() — after zeroization
///
/// Usage:
///   let mut buf = MlockedVec::new(32)?;
///   buf.copy_from_slice(&key);
///   // ... use buf ...
///   // On drop: zeroized + munlock
///
/// Errors:
///   - Returns Err if mlock fails (e.g., insufficient privileges,
///     RLIMIT_MEMLOCK exceeded, or unsupported platform).
pub struct MlockedVec {
    data: Vec<u8>,
    locked: bool,
}

impl MlockedVec {
    /// Allocate a zero-initialized, mlocked buffer.
    ///
    /// Returns Err if mlock fails (check RLIMIT_MEMLOCK on Linux).
    pub fn new(size: usize) -> Result<Self, String> {
        let mut data = vec![0u8; size];
        let ret = unsafe {
            libc::mlock(data.as_ptr() as *const libc::c_void, data.len())
        };
        if ret != 0 {
            let err = std::io::Error::last_os_error();
            data.zeroize();
            log::error!("MlockedVec::new: mlock failed (size={}): {}", size, err);
            return Err(format!(
                "mlock failed (size={}): {}. Ensure RLIMIT_MEMLOCK is sufficient \
                 or run with CAP_IPC_LOCK.", size, err
            ));
        }
        log::debug!("MlockedVec::new: allocated and mlocked {} bytes", size);
        Ok(MlockedVec { data, locked: true })
    }

    /// Create an mlocked buffer from an existing Vec<u8>.
    /// The original Vec is consumed and zeroized if mlock fails.
    pub fn from_vec(mut data: Vec<u8>) -> Result<Self, String> {
        let size = data.len();
        let ret = unsafe {
            libc::mlock(data.as_ptr() as *const libc::c_void, data.len())
        };
        if ret != 0 {
            let err = std::io::Error::last_os_error();
            data.zeroize();
            log::error!("MlockedVec::from_vec: mlock failed (size={}): {}", size, err);
            return Err(format!(
                "mlock failed (size={}): {}. Ensure RLIMIT_MEMLOCK is sufficient \
                 or run with CAP_IPC_LOCK.", size, err
            ));
        }
        log::debug!("MlockedVec::from_vec: mlocked {} bytes from Vec", size);
        Ok(MlockedVec { data, locked: true })
    }

    /// Manually zeroize and unlock the buffer.
    ///
    /// After calling this, the buffer is empty and unlocked.
    /// Subsequent reads will return empty slice.
    pub fn zeroize_and_unlock(&mut self) {
        if self.locked {
            self.data.zeroize();
            unsafe {
                libc::munlock(self.data.as_ptr() as *const libc::c_void, self.data.len());
            }
            self.locked = false;
            self.data.clear();
            log::debug!("MlockedVec: zeroized and unlocked");
        }
    }

    /// Return the length of the buffer.
    pub fn len(&self) -> usize {
        self.data.len()
    }

    /// Check if the buffer is empty.
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }

    /// Check if the memory is currently locked.
    pub fn is_locked(&self) -> bool {
        self.locked
    }
}

impl Drop for MlockedVec {
    fn drop(&mut self) {
        if self.locked {
            // Zeroize first, then unlock
            self.data.zeroize();
            unsafe {
                libc::munlock(self.data.as_ptr() as *const libc::c_void, self.data.len());
            }
            log::debug!("MlockedVec::drop: zeroized and unlocked {} bytes", self.data.len());
        }
    }
}

impl Deref for MlockedVec {
    type Target = [u8];
    fn deref(&self) -> &[u8] {
        &self.data
    }
}

impl DerefMut for MlockedVec {
    fn deref_mut(&mut self) -> &mut [u8] {
        &mut self.data
    }
}

impl AsRef<[u8]> for MlockedVec {
    fn as_ref(&self) -> &[u8] {
        &self.data
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// mprotect helpers — set memory page protection
// ═══════════════════════════════════════════════════════════════════════════════
//
// Uwaga: mprotect wymaga adresów i rozmiarów wyrównanych do strony (4096B).
// Te funkcje przyjmują surowy wskaźnik i długość, i zaokrąglają je do stron.

/// Set memory to PROT_READ only (no write).
///
/// Useful for preventing accidental modification of sensitive data
/// after initialization. Call protect_rw() to re-enable writes.
///
/// Returns Err if the address/length combination is invalid or
/// mprotect fails.
pub fn protect_read(addr: *const u8, len: usize) -> Result<(), String> {
    protect(addr, len, libc::PROT_READ)
}

/// Set memory to PROT_READ | PROT_WRITE.
///
/// Re-enables writes after protect_read().
///
/// Returns Err if the address/length combination is invalid or
/// mprotect fails.
pub fn protect_rw(addr: *const u8, len: usize) -> Result<(), String> {
    protect(addr, len, libc::PROT_READ | libc::PROT_WRITE)
}

/// Set memory to PROT_NONE (no access).
///
/// Completely removes access to the memory page.
/// Call protect_rw() to restore access.
///
/// Returns Err if mprotect fails.
pub fn protect_none(addr: *const u8, len: usize) -> Result<(), String> {
    protect(addr, len, libc::PROT_NONE)
}

/// Internal: call mprotect with page-aligned address and length.
fn protect(addr: *const u8, len: usize, prot: i32) -> Result<(), String> {
    let page_size = unsafe { libc::sysconf(libc::_SC_PAGESIZE) } as usize;
    if page_size == 0 {
        return Err("sysconf _SC_PAGESIZE returned 0".to_string());
    }

    // Align address down to page boundary
    let aligned_addr = (addr as usize) & !(page_size - 1);
    // Align length up to page boundary, accounting for the offset
    let offset = (addr as usize) - aligned_addr;
    let aligned_len = ((offset + len + page_size - 1) / page_size) * page_size;

    let ret = unsafe {
        libc::mprotect(
            aligned_addr as *mut libc::c_void,
            aligned_len,
            prot,
        )
    };

    if ret != 0 {
        let err = std::io::Error::last_os_error();
        return Err(format!(
            "mprotect({:#x}, {}, {:#x}) failed: {}",
            aligned_addr, aligned_len, prot, err
        ));
    }
    Ok(())
}

// ═══════════════════════════════════════════════════════════════════════════════
// Simple zeroize helpers (backward compatible)
// ═══════════════════════════════════════════════════════════════════════════════

/// Securely zero out a mutable byte slice.
#[allow(dead_code)]
pub fn zero(data: &mut [u8]) {
    data.zeroize();
}

/// Securely zero out a Vec<u8>.
pub fn zero_vec(data: &mut Vec<u8>) {
    data.zeroize();
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_zero_vec() {
        let mut data = vec![1u8, 2, 3, 4, 5];
        zero_vec(&mut data);
        assert_eq!(data, vec![0u8; 5]);
    }

    #[test]
    fn test_sensitive_bytes_new() {
        let buf = SensitiveBytes::new(32);
        assert_eq!(buf.len(), 32);
        assert!(!buf.is_empty());
        assert_eq!(buf[0], 0);
    }

    #[test]
    fn test_sensitive_bytes_from_vec() {
        let buf = SensitiveBytes::from_vec(vec![1u8, 2, 3]);
        assert_eq!(buf.len(), 3);
        assert_eq!(buf[0], 1);
        assert_eq!(buf[1], 2);
        assert_eq!(buf[2], 3);
    }

    #[test]
    fn test_sensitive_bytes_deref_mut() {
        let mut buf = SensitiveBytes::new(4);
        buf.copy_from_slice(&[0xDE, 0xAD, 0xBE, 0xEF]);
        assert_eq!(buf[0], 0xDE);
        assert_eq!(buf[3], 0xEF);
    }

    #[test]
    fn test_mlocked_vec_new() {
        let buf = MlockedVec::new(64);
        // mlock może nie działać w środowisku CI/Termux bez odpowiednich uprawnień
        if let Ok(b) = buf {
            assert_eq!(b.len(), 64);
            assert!(b.is_locked());
        }
        // Jeśli mlock się nie uda, test przechodzi (graceful degradation)
    }

    #[test]
    fn test_mlocked_vec_from_vec() {
        let data = vec![0xABu8; 16];
        let buf = MlockedVec::from_vec(data);
        if let Ok(b) = buf {
            assert_eq!(b.len(), 16);
            assert!(b.is_locked());
            assert_eq!(b[0], 0xAB);
        }
    }

    #[test]
    fn test_mlocked_vec_zeroize_and_unlock() {
        let mut buf = match MlockedVec::new(32) {
            Ok(b) => b,
            Err(_) => return, // skip if mlock unavailable
        };
        buf.copy_from_slice(&[0xFFu8; 32]);
        buf.zeroize_and_unlock();
        assert!(!buf.is_locked());
        assert!(buf.is_empty());
    }

    #[test]
    fn test_protect_read() {
        // Użyj Vec (heap) zamiast array (stack) — dedykowana strona, brak SIGSEGV
        let mut data = vec![0x42u8; 4096]; // exactly one page on heap
        let ptr = data.as_ptr();
        let len = data.len();

        // Should succeed on most platforms
        let result = protect_read(ptr, len);
        // Revert to R/W so the Vec can be safely dropped
        let _ = protect_rw(ptr, len);
        // Either way, test shouldn't crash
        if result.is_ok() {
            assert_eq!(data[0], 0x42); // still accessible after mprotect
        }
    }
}
