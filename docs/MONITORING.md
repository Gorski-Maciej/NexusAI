# 📊 Monitoring systemu — ProcessMonitor i SystemMonitor

> **Plik:** `nexus_ai/core/monitor.py`
> **Status:** Stabilny · **Wersja:** 3.0.0-dev
> **Ostatnia aktualizacja:** 2026-07-05

---

## 1. Przegląd

NexusAI używa **psutil** jako jedynej biblioteki do monitorowania zasobów systemowych. System składa się z dwóch komponentów:

| Komponent | Zakres | Metryki |
|---|---|---|
| **ProcessMonitor** | Bieżący proces NexusAI | RSS/USS/PSS, CPU%, wątki, FDs, połączenia |
| **SystemMonitor** | Cały system | CPU/RAM/swap/disk/net, temperatury, load average |

```
┌────────────────────────────────────────────────────────────┐
│                    Monitoring System                        │
│                                                            │
│  ProcessMonitor (oneshot)    SystemMonitor (statyczne)     │
│  ┌─────────────────────┐    ┌──────────────────────────┐  │
│  │ pool.oneshot()      │    │ cpu_percent(percpu=True) │  │
│  │ memory_full_info()  │    │ virtual_memory()         │  │
│  │ cpu_times()         │    │ disk_usage()             │  │
│  │ num_fds()           │    │ net_io_counters()        │  │
│  │ connections()       │    │ sensors_temperatures()   │  │
│  └─────────────────────┘    └──────────────────────────┘  │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  WorkerGuard — dynamiczne throttlingu CPU/RAM        │  │
│  │  OpenTelemetry — export metryk do traces/metrics     │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

---

## 2. ProcessMonitor

Monitoruje bieżący proces NexusAI z optymalizacją **oneshot()** — jeden syscall zamiast N dla wielu atrybutów (~5-10x szybciej dla 10+ atrybutów).

### 2.1 API

```python
from nexus_ai.core.monitor import ProcessMonitor

monitor = ProcessMonitor()

# Zbierz wszystkie metryki (oneshot)
metrics = monitor.collect_metrics()
# → ProcessMetrics(
#     pid=12345,
#     rss_mb=245.3,
#     uss_mb=198.7,       # Unique Set Size (Linux)
#     pss_mb=210.2,       # Proportional Set Size (Linux)
#     vms_mb=1024.5,
#     cpu_percent=12.5,
#     cpu_user=45.2,
#     cpu_system=3.1,
#     num_threads=24,
#     num_fds=156,
#     uptime_seconds=3600,
#     status="running",
#     connections_count=8,
# )

# Sprawdź próg pamięci
is_healthy, metrics = monitor.check_memory_health(threshold_mb=4000)
# → (True, ProcessMetrics(...)) jeśli RSS < 4 GB
```

### 2.2 ProcessMetrics

| Pole | Typ | Opis |
|---|---|---|
| `rss_mb` | float | Resident Set Size (MB) |
| `uss_mb` | float \| None | Unique Set Size — tylko Linux (MB) |
| `pss_mb` | float \| None | Proportional Set Size — tylko Linux (MB) |
| `vms_mb` | float | Virtual Memory Size (MB) |
| `cpu_percent` | float | Obciążenie CPU (%) |
| `cpu_user` | float | Czas user space (s) |
| `cpu_system` | float | Czas kernel space (s) |
| `cpu_iowait` | float \| None | Czas I/O wait — tylko Linux (s) |
| `num_threads` | int | Liczba wątków |
| `num_fds` | int | Liczba deskryptorów plików |
| `create_time` | float | Timestamp startu procesu |
| `uptime_seconds` | float | Czas od startu (s) |
| `status` | str | Status procesu (`running`, `sleeping`) |
| `name` | str | Nazwa procesu |
| `cpu_affinity` | list[int] | Lista przypisanych rdzeni CPU |
| `memory_percent` | float | % całkowitego RAM |
| `connections_count` | int | Liczba otwartych połączeń sieciowych |
| `pid` | int | ID procesu |

### 2.3 Optymalizacja oneshot()

```python
with proc.oneshot():
    # Wszystkie wywołania są cache'owane — 1 syscall zamiast N
    mem_info = proc.memory_info()
    mem_full = proc.memory_full_info()  # USS/PSS
    cpu_pct = proc.cpu_percent(interval=0.0)
    cpu_times = proc.cpu_times()
    threads = proc.num_threads()
    fds = proc.num_fds()
    ctime = proc.create_time()
    status = proc.status()
    name = proc.name()
    affinity = proc.cpu_affinity()
    mem_pct = proc.memory_percent()
    conns = proc.connections(kind="inet")
```

### 2.4 Bezpieczne helpery

```python
# Każda metoda ma safe wrapper na wypadek AccessDenied/NoSuchProcess:
_safe_memory_full_info(proc)  # → USS/PSS lub None
_safe_num_fds(proc)           # → int lub -1
_safe_ionice(proc)            # → str lub None
_safe_connections(proc)       # → list lub []
```

---

## 3. SystemMonitor

Monitoruje cały system operacyjny — CPU, RAM, swap, dysk, sieć, sensory.

### 3.1 API

```python
from nexus_ai.core.monitor import SystemMonitor

# Zbierz wszystkie metryki systemowe
metrics = SystemMonitor.collect_all()
# → SystemMetrics(
#     cpu_count_physical=8,
#     cpu_count_logical=16,
#     cpu_percent=45.2,
#     cpu_percent_per_core=[32.1, 48.5, ...],
#     cpu_freq_current_mhz=2400.0,
#     load_avg_1min=2.5,
#     ram_total_gb=32.0,
#     ram_available_gb=12.5,
#     ram_percent=60.9,
#     swap_percent=15.0,
#     disk_percent=55.0,
#     cpu_temp_celsius=72.3,
#     uptime_days=14.2,
# )

# Kompleksowe sprawdzenie zdrowia
is_healthy, metrics, alerts = SystemMonitor.check_health(
    ram_threshold_pct=90.0,
    disk_threshold_pct=95.0,
    swap_threshold_pct=80.0,
    cpu_threshold_pct=95.0,
)
# → (True, SystemMetrics(...), []) lub
# → (False, SystemMetrics(...), ["RAM at 91.5% (threshold: 90%)"])
```

### 3.2 SystemMetrics — wszystkie pola

| Kategoria | Pola |
|---|---|
| **CPU** | `cpu_count_physical`, `cpu_count_logical`, `cpu_percent`, `cpu_percent_per_core`, `cpu_freq_current/min/max_mhz`, `cpu_stats_ctx_switches/interrupts/syscalls`, `load_avg_1/5/15min` |
| **RAM** | `ram_total/available/used_gb`, `ram_percent`, `ram_buffers/cached_gb`, `swap_total/used_gb`, `swap_percent`, `swap_sin/sout_gb` |
| **Disk** | `disk_total/used/free_gb`, `disk_percent`, `disk_read/write_mb`, `disk_read/write_count`, `disk_io_time_ms` |
| **Network** | `net_bytes_sent/recv_mb`, `net_packets_sent/recv`, `net_errors_in/out`, `net_drop_in/out` |
| **Sensors** | `cpu_temp_celsius`, `gpu_temp_celsius`, `fan_rpm` |
| **System** | `boot_time`, `uptime_days`, `users_count`, `pids_count` |

### 3.3 Health Check progi

| Metryka | Domyślny próg | Alert |
|---|---|---|
| RAM | >90% | `RAM at 91.5%` |
| Disk | >95% | `Disk at 96.2%` |
| Swap | >80% | `Swap at 85.0%` |
| CPU | >95% | `CPU at 97.1%` |
| CPU Temp | >85°C | `CPU temperature at 92.3°C` |
| Swap+RAM | swap>50% + RAM>80% | `SWAP pressure — possible OOM risk` |

---

## 4. WorkerGuard — integracja z workerem

WorkerGuard w `luz/worker.py` używa monitoringu do dynamicznego throttlingu:

```python
class WorkerGuard:
    async def check_resources(self):
        """Dynamiczne limitowanie współbieżności."""
        metrics = process_monitor.collect_metrics()
        
        if metrics.rss_mb > 4000 or metrics.cpu_percent > 80:
            self.max_concurrent = max(1, self.max_concurrent - 1)
            logger.warning(
                "Throttling: CPU=%.1f%%, RAM=%.1f MB → concurrent=%d",
                metrics.cpu_percent, metrics.rss_mb, self.max_concurrent
            )
```

**Metryki zbierane przez WorkerGuard:**
- ProcessMonitor: RSS, USS, PSS, CPU user/system, num_threads, num_fds
- SystemMonitor: RAM, swap, disk, net, CPU temp
- Użycie `psutil.Process.oneshot()` — ~5x szybciej dla pełnego zestawu metryk

---

## 5. OpenTelemetry

Metryki monitoringu są eksportowane przez OpenTelemetry:

```python
from nexus_ai.core.otel import get_meter

meter = get_meter("nexus.monitor")
monitor_gauge = meter.create_histogram(
    name="nexus.monitor.rss_mb",
    description="Process RSS in MB",
    unit="MB",
)
```

Eksportowane metryki:
- `nexus.monitor.rss_mb` — histogram RSS procesu
- `nexus.monitor.cpu_percent` — obciążenie CPU
- `nexus.monitor.threads` — liczba wątków
- `nexus.system.ram_percent` — % użycia RAM
- `nexus.system.cpu_percent` — % użycia CPU
- `nexus.system.disk_percent` — % użycia dysku

---

## 6. Praktyczne zastosowania

### Monitoring okresowy (co 60s)

```python
import anyio
from nexus_ai.core.monitor import process_monitor, system_monitor
from nexus_ai.core.otel import get_meter

async def monitoring_loop():
    meter = get_meter("nexus.monitor")
    rss_hist = meter.create_histogram("nexus.monitor.rss_mb")
    
    while True:
        metrics = process_monitor.collect_metrics()
        rss_hist.record(metrics.rss_mb)
        
        is_healthy, sys_metrics, alerts = system_monitor.check_health()
        if not is_healthy:
            for alert in alerts:
                logger.warning("[HEALTH] %s", alert)
        
        await anyio.sleep(60)
```

### Alert OOM (Out of Memory)

```python
from nexus_ai.core.monitor import process_monitor

is_healthy, metrics = process_monitor.check_memory_health(4000)
if not is_healthy:
    # GC collect + log warning
    gc.collect()
    logger.warning("Memory: %.1f MB — possible OOM", metrics.rss_mb)
```

---

> **Zobacz również:**
> - [`ARCHITECTURE.md`](ARCHITECTURE.md) — NFR, Capacity Planning, SLO
> - [`SCRIPTS.md`](SCRIPTS.md) — WorkerGuard w luz/worker.py
> - [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) — diagnostyka problemów wydajnościowych
