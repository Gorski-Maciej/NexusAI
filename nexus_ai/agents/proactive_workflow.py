"""ProactiveWorkflowScheduler — Autonomiczny Silnik Proaktywnych Workflow.

GENIALNY POMYSŁ ENTERPRISE (v5.0):
Transformacja agentów z REAKTYWNYCH w PROAKTYWNYCH zarządców księgowości.

Zgodnie z aa3fvcx.txt, AGENT_SYSTEM_ENTERPRISE.txt:
- Tylko technologie z RAPORT_TECHNOLOGII_NEXUSAI.txt
- 5 agentów, JEDEN poziom automatyzacji (DecisionMode)
- Taskiq Scheduler dla zadań cronowych
- NATS JetStream dla komunikacji między agentami
- psutil dla monitorowania zasobów
- diskcache dla stanu workflow
- pendulum dla harmonogramowania czasowego

Architektura ENTERPRISE:
─────────────────────────────────────────────────────────────────────────────
AgentOrchestrator (CFO)
  └── ProactiveWorkflowScheduler
        ├── WorkflowManager      — zarządzanie cyklem życia workflow
        ├── ResourceOptimizer    — auto-unload modeli, dynamiczne skalowanie
        ├── TaxDeadlineMonitor   — alerty ZUS, VAT, PIT/CIT, KSeF
        ├── PaymentScheduler     — przygotowanie paczek przelewów
        ├── VendorMonitor        — monitoring kontrahentów (zmiany kont, VAT)
        └── HealthGuardian       — monitoring agentów, auto-restart
─────────────────────────────────────────────────────────────────────────────

Harmonogram proaktywny (cron przez Taskiq Scheduler):
  06:00 — Daily Briefing: podsumowanie poprzedniego dnia
  07:00 — KSeF Check: pobranie nowych faktur z KSeF
  08:00 — Bank Sync: sprawdzenie konta bankowego, nowe transakcje
  09:00 — Dunning Check: windykacja należności
  10:00 — Vendor Monitor: weryfikacja Białej Listy MF, zmiany kont
  14:00 — Tax Deadline Alert: alerty o zbliżających się terminach
  16:00 — Payment Batch: przygotowanie paczki przelewów na jutro
  18:00 — Evening Summary: podsumowanie dnia dla przedsiębiorcy
  22:00 — Resource Optimizer: auto-unload nieużywanych modeli

  Poniedziałek 07:00 — Weekly Report: P&L, DSO, top kontrahenci
  1. dzień miesiąca 08:00 — Monthly Closing: uzgodnienia, amortyzacja
  10., 20., 25. dzień miesiąca — Tax Calendar Alert
  Ostatni dzień miesiąca 18:00 — Month-End Closing
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from typing import Any

import pendulum
from structlog import get_logger

from nexus_ai.agents.models import (
    ActionCard,
    ActionCardFeed,
    ActionCardOption,
    ActionCardResponse,
    AgentContext,
    AgentDecision,
    AgentHealth,
    AnalyticsQuery,
    DecisionMode,
    make_context,
)
from nexus_ai.agents.topics import AgentTopic

logger = get_logger("nexus.agents.proactive")


# ═════════════════════════════════════════════════════════════════════════
# Workflow Status & Typy
# ═════════════════════════════════════════════════════════════════════════


class WorkflowStatus:
    """Statusy workflow."""

    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


class WorkflowType:
    """Typy proaktywnych workflow."""

    DAILY_BRIEFING = "daily_briefing"
    KSEF_FETCH = "ksef_fetch"
    BANK_SYNC = "bank_sync"
    DUNNING_CHECK = "dunning_check"
    VENDOR_MONITOR = "vendor_monitor"
    TAX_DEADLINE_ALERT = "tax_deadline_alert"
    PAYMENT_BATCH = "payment_batch"
    EVENING_SUMMARY = "evening_summary"
    RESOURCE_OPTIMIZER = "resource_optimizer"
    WEEKLY_REPORT = "weekly_report"
    MONTHLY_CLOSING = "monthly_closing"
    TAX_CALENDAR = "tax_calendar"
    MONTH_END_CLOSING = "month_end_closing"
    HEALTH_CHECK = "health_check"
    AUTO_BACKUP = "auto_backup"
    COMPLIANCE_SCAN = "compliance_scan"
    DECISION_FEED_REFRESH = "decision_feed_refresh"


@dataclass
class WorkflowExecution:
    """Rekord wykonania workflow."""

    workflow_id: str
    workflow_type: str
    status: str = WorkflowStatus.PENDING
    started_at: str = ""
    completed_at: str = ""
    duration_ms: float = 0.0
    result: dict[str, Any] = field(default_factory=dict)
    error: str = ""
    triggered_by: str = "scheduler"  # scheduler | agent | user | system
    priority: int = 5  # 1-10, 1=najwyższy

    def start(self) -> None:
        self.status = WorkflowStatus.RUNNING
        self.started_at = pendulum.now("UTC").isoformat()

    def complete(self, result: dict[str, Any] | None = None) -> None:
        self.status = WorkflowStatus.COMPLETED
        self.completed_at = pendulum.now("UTC").isoformat()
        if self.started_at:
            start = pendulum.parse(self.started_at)
            self.duration_ms = (pendulum.now("UTC") - start).total_seconds() * 1000
        if result:
            self.result = result

    def fail(self, error: str) -> None:
        self.status = WorkflowStatus.FAILED
        self.error = error
        self.completed_at = pendulum.now("UTC").isoformat()

    def skip(self, reason: str = "") -> None:
        self.status = WorkflowStatus.SKIPPED
        self.result["skip_reason"] = reason


# ═════════════════════════════════════════════════════════════════════════
# Resource Optimizer — Samooptymalizujący się zarządca zasobów
# ═════════════════════════════════════════════════════════════════════════


class ResourceOptimizer:
    """Zarządca zasobów agentów — auto-unload, dynamiczne skalowanie.

    Zgodnie z aa3fvcx.txt: psutil do monitorowania, diskcache do stanu.
    """

    def __init__(self, config: dict[str, Any] | None = None) -> None:
        self._config = config or {}
        self._psutil_available = False
        self._last_check: dict[str, Any] = {}
        self._model_usage: dict[str, float] = {}  # last_used timestamp
        self._idle_threshold_seconds = self._config.get("model_idle_ttl", 1800)  # 30 min
        self._ram_threshold_pct = self._config.get("ram_threshold_pct", 80)
        self._cpu_threshold_pct = self._config.get("cpu_threshold_pct", 70)
        self._logger = get_logger("nexus.agents.resources")

        try:
            import psutil
            self._psutil = psutil
            self._process = psutil.Process()
            self._psutil_available = True
        except Exception:
            self._psutil = None
            self._process = None

    @property
    def available(self) -> bool:
        return self._psutil_available

    def get_system_resources(self) -> dict[str, Any]:
        """Pobierz aktualne zużycie zasobów."""
        if not self._psutil_available:
            return {"available": False}

        try:
            mem = self._process.memory_info() if self._process else None
            return {
                "available": True,
                "ram_mb": mem.rss / (1024 * 1024) if mem else 0,
                "ram_pct": self._psutil.virtual_memory().percent,
                "cpu_pct": self._psutil.cpu_percent(interval=0.1),
                "cpu_count": self._psutil.cpu_count(),
                "disk_free_gb": self._psutil.disk_usage("/").free / (1024**3),
            }
        except Exception as exc:
            self._logger.debug("[RESOURCE] System check failed: %s", exc)
            return {"available": False, "error": str(exc)}

    def should_unload_models(self, loaded_models: list[str]) -> list[str]:
        """Sprawdź które modele powinny być odładowane.

        Returns:
            Lista nazw modeli do odładowania.
        """
        resources = self.get_system_resources()
        to_unload: list[str] = []

        if not loaded_models:
            return to_unload

        # Warunek 1: RAM powyżej progu
        if resources.get("ram_pct", 0) > self._ram_threshold_pct:
            # Odładuj najmniej używane modele
            now = pendulum.now("UTC").timestamp()
            sorted_by_usage = sorted(
                loaded_models,
                key=lambda m: self._model_usage.get(m, now),
            )
            # Odładuj najstarsze (najmniej używane) — zostaw przynajmniej 1
            to_unload = sorted_by_usage[:max(1, len(sorted_by_usage) // 2)]
            self._logger.info(
                "[RESOURCE] RAM %.1f%% > %.1f%% — unloading %d models",
                resources.get("ram_pct", 0),
                self._ram_threshold_pct,
                len(to_unload),
            )

        # Warunek 2: Modele idle powyżej progu
        now = pendulum.now("UTC").timestamp()
        for model_name in loaded_models:
            last_used = self._model_usage.get(model_name, now)
            if (now - last_used) > self._idle_threshold_seconds and model_name not in to_unload:
                to_unload.append(model_name)
                self._logger.info("[RESOURCE] Model %s idle > %ds — unloading", model_name, self._idle_threshold_seconds)

        return to_unload

    def mark_model_used(self, model_name: str) -> None:
        """Oznacz model jako używany (odświeża timestamp)."""
        self._model_usage[model_name] = pendulum.now("UTC").timestamp()

    def optimal_worker_count(self, current_workers: int = 1) -> int:
        """Oblicz optymalną liczbę workerów.

        Na podstawie dostępnego RAM i CPU.
        """
        resources = self.get_system_resources()
        if not resources.get("available"):
            return max(1, current_workers)

        ram_pct = resources.get("ram_pct", 50)
        cpu_pct = resources.get("cpu_pct", 30)

        # Skaluj w górę przy niskim obciążeniu, w dół przy wysokim
        if ram_pct < 40 and cpu_pct < 30:
            return min(current_workers + 1, 4)
        elif ram_pct > self._ram_threshold_pct or cpu_pct > self._cpu_threshold_pct:
            return max(1, current_workers - 1)

        return current_workers


# ═════════════════════════════════════════════════════════════════════════
# WorkflowManager — Zarządca cyklu życia workflow
# ═════════════════════════════════════════════════════════════════════════


class WorkflowManager:
    """Zarządca cyklu życia proaktywnych workflow.

    Przechowuje historię, status, metryki wykonania.
    """

    def __init__(self, max_history: int = 1000) -> None:
        self._executions: list[WorkflowExecution] = []
        self._max_history = max_history
        self._stats: dict[str, dict[str, int]] = {}  # type -> {completed, failed, skipped}
        self._logger = get_logger("nexus.agents.workflows")

    def create_execution(self, workflow_type: str, triggered_by: str = "scheduler") -> WorkflowExecution:
        """Utwórz nowy rekord wykonania workflow."""
        execution = WorkflowExecution(
            workflow_id=uuid.uuid4().hex[:16],
            workflow_type=workflow_type,
            triggered_by=triggered_by,
        )
        return execution

    def record(self, execution: WorkflowExecution) -> None:
        """Zapisz rekord wykonania."""
        self._executions.append(execution)

        # Aktualizuj statystyki
        if execution.workflow_type not in self._stats:
            self._stats[execution.workflow_type] = {"completed": 0, "failed": 0, "skipped": 0}
        self._stats[execution.workflow_type][execution.status] += 1

        # Trim
        if len(self._executions) > self._max_history:
            self._executions = self._executions[-self._max_history:]

    def get_last_execution(self, workflow_type: str) -> WorkflowExecution | None:
        """Pobierz ostatnie wykonanie danego typu."""
        for execution in reversed(self._executions):
            if execution.workflow_type == workflow_type:
                return execution
        return None

    def was_executed_recently(self, workflow_type: str, cooldown_minutes: int = 1440) -> bool:
        """Sprawdź czy workflow był już wykonany w ciągu ostatnich N minut.

        Dla dziennych workflow: cooldown = 1440 (24h).
        Dla częstych workflow: cooldown = częstotliwość cron.
        """
        now = pendulum.now("UTC")
        cutoff = now.subtract(minutes=cooldown_minutes)
        for execution in reversed(self._executions):
            if execution.workflow_type == workflow_type and execution.started_at:
                try:
                    exec_time = pendulum.parse(execution.started_at)
                    if exec_time > cutoff and execution.status == WorkflowStatus.COMPLETED:
                        return True
                except Exception:
                    pass
        return False

    def get_stats(self) -> dict[str, Any]:
        """Pobierz statystyki workflow."""
        return {
            "total_executions": len(self._executions),
            "by_type": dict(self._stats),
            "recent": [
                {
                    "type": e.workflow_type,
                    "status": e.status,
                    "duration_ms": e.duration_ms,
                    "started_at": e.started_at,
                    "triggered_by": e.triggered_by,
                }
                for e in self._executions[-10:]
            ],
        }

    @property
    def execution_count(self) -> int:
        return len(self._executions)


# ═════════════════════════════════════════════════════════════════════════
# ActionCardGenerator — GENIALNY POMYSŁ v5.1: "Zasada 1-Click CFO"
# ═════════════════════════════════════════════════════════════════════════


class ActionCardGenerator:
    """Generator Kart Decyzyjnych — tłumaczy techniczne AgentDecision na proste karty.

    GENIALNY POMYSŁ v5.1 — "Zasada 1-Click CFO":
    Przedsiębiorca NIE widzi stawek VAT, kont księgowych, reguł OPA.
    Widzi kartę z 2-4 przyciskami. Agent wykonał 95% pracy:
    - Przeanalizował fakturę (OCR + walidacja krzyżowa)
    - Sprawdził kontrahenta (Biała Lista MF, GUS BIR)
    - Obliczył podatki (OPA/Rego)
    - Przygotował księgowania (TigerBeetle double-entry)
    - Spakował to wszystko w hidden_payload każdego przycisku

    Użytkownik klika 1 przycisk → system wykonuje resztę.

    Integracja z Qwen3-Nano:
    - Model tłumaczy skomplikowany JSON → proste zdania NL
    - Prompt: "Jesteś tłumaczem księgowości na język przedsiębiorcy"
    - System prompt zabrania żargonu (WN/MA, PKWiU, MPP)
    """

    # ── Stałe ────────────────────────────────────────────────────────

    MAX_OPTIONS = 4
    """Maksymalna liczba opcji na karcie."""

    # ── Szablony decyzji ─────────────────────────────────────────────

    DECISION_TEMPLATES: dict[str, dict[str, Any]] = {
        "INVOICE_NEW_VENDOR": {
            "title": "Nowa faktura od nowego kontrahenta",
            "options": [
                {"label": "✅ Zaksięguj", "action_type": "confirm", "is_recommended": True},
                {"label": "🔍 Sprawdź kontrahenta", "action_type": "alternative"},
                {"label": "❌ Odrzuć", "action_type": "reject"},
            ],
        },
        "INVOICE_HIGH_AMOUNT": {
            "title": "Faktura na wysoką kwotę",
            "options": [
                {"label": "✅ Zaksięguj (4-Eyes OK)", "action_type": "confirm", "is_recommended": True},
                {"label": "🔍 Zweryfikuj ręcznie", "action_type": "alternative"},
                {"label": "⏸️ Odłóż na później", "action_type": "escalate"},
            ],
        },
        "INVOICE_STANDARD": {
            "title": "Faktura do zaksięgowania",
            "options": [
                {"label": "✅ Zaksięguj", "action_type": "confirm", "is_recommended": True},
                {"label": "✏️ Popraw dane", "action_type": "alternative"},
                {"label": "❌ Odrzuć", "action_type": "reject"},
            ],
        },
        "TAX_ALERT": {
            "title": "Alert podatkowy",
            "options": [
                {"label": "✅ OK, przygotuj przelew", "action_type": "confirm", "is_recommended": True},
                {"label": "📅 Przypomnij jutro", "action_type": "alternative"},
                {"label": "📞 Skonsultuj z księgową", "action_type": "escalate"},
            ],
        },
        "ASSET_CLASSIFICATION": {
            "title": "Klasyfikacja środka trwałego",
            "options": [
                {"label": "✅ Amortyzacja liniowa", "action_type": "confirm", "is_recommended": True},
                {"label": "🔄 Amortyzacja jednorazowa", "action_type": "alternative"},
                {"label": "❌ To nie jest ŚT", "action_type": "reject"},
            ],
        },
        "PAYMENT_BATCH": {
            "title": "Paczka przelewów do akceptacji",
            "options": [
                {"label": "✅ Zatwierdź wszystkie", "action_type": "confirm", "is_recommended": True},
                {"label": "📋 Przejrzyj po kolei", "action_type": "alternative"},
                {"label": "⏸️ Wstrzymaj", "action_type": "escalate"},
            ],
        },
    }

    def __init__(self, orchestrator: Any = None) -> None:
        self._orchestrator = orchestrator
        self._logger = get_logger("nexus.agents.cards")

    def generate_action_card(
        self,
        decision: AgentDecision,
        document_type: str = "INVOICE",
        urgency: str = "normal",
    ) -> ActionCard:
        """Generuj kartę decyzyjną z AgentDecision.

        GENIALNY POMYSŁ v5.1:
        Tłumaczy techniczną decyzję na 2-4 proste przyciski.
        Przedsiębiorca NIE widzi stawek VAT, kont, reguł.

        Args:
            decision: Pełna decyzja agenta (zawiera wszystkie dane techniczne).
            document_type: Typ dokumentu (INVOICE, ASSET, TAX_ALERT, PAYMENT).
            urgency: Priorytet (critical, high, normal, low).

        Returns:
            ActionCard z 2-4 prostymi opcjami.
        """
        import uuid

        card_id = uuid.uuid4().hex[:12]
        status = decision.verdict.status
        trust = decision.verdict.trust_score
        details = decision.verdict.details if hasattr(decision.verdict, 'details') else {}
        extracted = details.get("extracted_data", {}) if isinstance(details, dict) else {}

        # Wybierz szablon
        template = self._select_template(status, trust, extracted, document_type)

        # Zbuduj podsumowanie
        summary = self._build_summary(decision, extracted, document_type, trust)

        # Zbuduj opcje
        options = self._build_options(template, decision, extracted, trust)

        # Określ priorytet
        gross = extracted.get("amount_gross", 0)
        if isinstance(gross, str):
            try:
                gross = float(gross)
            except (ValueError, TypeError):
                gross = 0
        if urgency == "normal":
            if isinstance(gross, (int, float)) and gross > 50000:
                urgency = "high"
            elif trust < 0.5:
                urgency = "critical"

        return ActionCard(
            card_id=card_id,
            decision_id=decision.decision_id,
            title=template["title"],
            summary=summary,
            agent_name=decision.agent_name,
            document_type=document_type,
            options=options,
            trust_score=trust,
            decision_mode=decision.decision_mode,
            urgency=urgency,
            context={
                "invoice_number": extracted.get("invoice_number", ""),
                "vendor_nip": extracted.get("nip", ""),
                "vendor_name": extracted.get("vendor_name", ""),
                "amount_gross": extracted.get("amount_gross", 0),
                "currency": extracted.get("currency", "PLN"),
                "date": extracted.get("date", ""),
                "status": status,
            },
            created_at=pendulum.now("UTC").isoformat(),
            expires_at=(
                pendulum.now("UTC").add(days=7).isoformat()
                if urgency == "normal"
                else pendulum.now("UTC").add(hours=24).isoformat()
            ),
        )

    def _select_template(
        self,
        status: str,
        trust: float,
        extracted: dict[str, Any],
        document_type: str,
    ) -> dict[str, Any]:
        """Wybierz odpowiedni szablon decyzji."""
        gross = extracted.get("amount_gross", 0)
        if isinstance(gross, str):
            try:
                gross = float(gross)
            except (ValueError, TypeError):
                gross = 0
        vendor_nip = extracted.get("nip", "")

        # Alert podatkowy
        if document_type == "TAX_ALERT":
            return self.DECISION_TEMPLATES["TAX_ALERT"]
        if document_type == "ASSET":
            return self.DECISION_TEMPLATES["ASSET_CLASSIFICATION"]
        if document_type == "PAYMENT":
            return self.DECISION_TEMPLATES["PAYMENT_BATCH"]

        # Faktury
        if status == "BLOCK" or trust < 0.5:
            return self.DECISION_TEMPLATES["INVOICE_NEW_VENDOR"]
        if isinstance(gross, (int, float)) and gross > 50000:
            return self.DECISION_TEMPLATES["INVOICE_HIGH_AMOUNT"]

        return self.DECISION_TEMPLATES["INVOICE_STANDARD"]

    def _build_summary(
        self,
        decision: AgentDecision,
        extracted: dict[str, Any],
        document_type: str,
        trust: float,
    ) -> str:
        """Zbuduj czytelne podsumowanie dla przedsiębiorcy.

        GENIALNY POMYSŁ: Żadnego żargonu księgowego.
        """
        gross = extracted.get("amount_gross", 0)
        vendor = extracted.get("vendor_name", extracted.get("nip", "nieznany"))
        inv_num = extracted.get("invoice_number", "")

        parts = []

        if document_type == "TAX_ALERT":
            parts.append(f"Zbliża się termin płatności podatku.")
            parts.append(decision.explanation[:200] if decision.explanation else "Szczegóły w karcie.")
        elif document_type == "ASSET":
            parts.append(f"Zakup na kwotę {gross} PLN wymaga decyzji o klasyfikacji.")
            parts.append("Czy to środek trwały, czy koszt jednorazowy?")
        elif document_type == "PAYMENT":
            parts.append("Przygotowano paczkę przelewów do akceptacji.")
            parts.append("Sprawdź i zatwierdź jednym kliknięciem.")
        else:
            parts.append(f"Faktura {inv_num} od {vendor} na kwotę {gross} PLN.")
            if trust >= 0.92:
                parts.append("Wszystkie kontrole przeszły pomyślnie. Możesz bezpiecznie zaksięgować.")
            elif trust >= 0.75:
                parts.append(f"Agent ma {trust:.0%} pewności. Zalecana szybka weryfikacja.")
            else:
                parts.append(f"Niska pewność ({trust:.0%}). Wymagana Twoja decyzja.")

            if decision.explanation:
                # Dodaj 1 zdanie wyjaśnienia, bez żargonu
                short = decision.explanation.split(".")[0][:150]
                if short and short not in parts[-1]:
                    parts.append(short)

        return " ".join(parts)

    def _build_options(
        self,
        template: dict[str, Any],
        decision: AgentDecision,
        extracted: dict[str, Any],
        trust: float,
    ) -> list[ActionCardOption]:
        """Zbuduj 2-4 opcje (przyciski) z ukrytym payloadem.

        Każdy przycisk zawiera hidden_payload z pełnymi parametrami
        księgowymi, które zostaną wykonane po kliknięciu.
        """
        import uuid

        options = []
        template_options = template.get("options", [])

        for i, opt in enumerate(template_options[:self.MAX_OPTIONS]):
            option_id = uuid.uuid4().hex[:8]
            label = opt["label"]
            action_type = opt.get("action_type", "confirm")
            is_recommended = opt.get("is_recommended", False)

            # Zbuduj ukryty payload z pełnymi danymi księgowymi
            hidden_payload = {
                "decision_id": decision.decision_id,
                "action": action_type,
                "original_status": decision.verdict.status,
                "original_trust_score": trust,
                "extracted_data": extracted,
                "voting_result": (
                    {
                        "winner": decision.voting_result.winner,
                        "consensus": decision.voting_result.consensus,
                    }
                    if decision.voting_result
                    else None
                ),
                "quality_verdict": decision.verdict.details.get("quality_verdict")
                if isinstance(decision.verdict.details, dict)
                else None,
                "proof_hash": decision.verdict.proof_hash,
                "supporting_data": decision.supporting_data,
            }

            description = self._option_description(action_type, is_recommended, extracted)

            options.append(ActionCardOption(
                option_id=option_id,
                label=label,
                description=description,
                is_recommended=is_recommended,
                action_type=action_type,
                hidden_payload=hidden_payload,
                trust_impact=0.05 if action_type == "confirm" else -0.02,
            ))

        return options

    @staticmethod
    def _option_description(
        action_type: str,
        is_recommended: bool,
        extracted: dict[str, Any],
    ) -> str:
        """Wygeneruj opis opcji zrozumiały dla przedsiębiorcy."""
        if action_type == "confirm":
            if is_recommended:
                return "Rekomendowane przez AI — optymalne podatkowo"
            return "Zaksięguj z wybranymi parametrami"
        elif action_type == "alternative":
            return "Wybierz inną opcję księgowania"
        elif action_type == "reject":
            return "Odrzuć — faktura zawiera błędy lub jest nieprawidłowa"
        elif action_type == "escalate":
            return "Odłóż decyzję na później"
        return ""

    def build_daily_feed(
        self,
        pending_decisions: list[AgentDecision],
    ) -> ActionCardFeed:
        """Zbuduj codzienny feed kart decyzyjnych.

        GENIALNY POMYSŁ v5.1:
        Przedsiębiorca po zalogowaniu widzi "skrzynkę decyzyjną"
        z kartami do podjęcia. Zero tabel, zero formularzy.

        Args:
            pending_decisions: Lista decyzji oczekujących (SUGGEST/ASK_USER).

        Returns:
            ActionCardFeed gotowy do publikacji na ui.feed.pending.
        """
        cards = []
        urgent_count = 0

        for decision in pending_decisions:
            details = decision.verdict.details if hasattr(decision.verdict, 'details') else {}
            extracted = details.get("extracted_data", {}) if isinstance(details, dict) else {}

            gross = extracted.get("amount_gross", 0)
            if isinstance(gross, str):
                try:
                    gross = float(gross)
                except (ValueError, TypeError):
                    gross = 0

            urgency = "normal"
            if isinstance(gross, (int, float)) and gross > 50000:
                urgency = "high"
            if decision.verdict.trust_score < 0.5:
                urgency = "critical"

            if urgency in ("critical", "high"):
                urgent_count += 1

            card = self.generate_action_card(
                decision=decision,
                document_type="INVOICE",
                urgency=urgency,
            )
            cards.append(card)

        # Sortuj: najpierw pilne
        cards.sort(key=lambda c: {"critical": 0, "high": 1, "normal": 2, "low": 3}.get(c.urgency, 3))

        greeting = self._generate_greeting(len(cards), urgent_count)

        return ActionCardFeed(
            cards=cards,
            total_pending=len(cards),
            urgent_count=urgent_count,
            generated_at=pendulum.now("UTC").isoformat(),
            greeting=greeting,
        )

    @staticmethod
    def _generate_greeting(total: int, urgent: int) -> str:
        """Wygeneruj powitanie dla przedsiębiorcy."""
        now = pendulum.now("UTC")
        hour = now.hour

        if hour < 10:
            time_greeting = "Dzień dobry"
        elif hour < 18:
            time_greeting = "Dzień dobry"
        else:
            time_greeting = "Dobry wieczór"

        if total == 0:
            return f"{time_greeting}! 🎉 Wszystko zaksięgowane. Nie masz żadnych oczekujących decyzji."
        elif urgent > 0:
            return f"{time_greeting}! Masz {total} decyzje do podjęcia, w tym {urgent} pilne."
        else:
            return f"{time_greeting}! Masz {total} decyzje do podjęcia."

    async def generate_card_from_decision(
        self,
        decision: AgentDecision,
    ) -> ActionCard:
        """Asynchroniczna wersja generate_action_card z tłumaczeniem NL.

        Jeśli dostępny model Qwen3-Nano, używa go do wygenerowania
        bardziej naturalnego podsumowania i etykiet przycisków.
        """
        card = self.generate_action_card(decision)

        # Spróbuj użyć Qwen3-Nano do lepszego tłumaczenia
        if self._orchestrator and hasattr(self._orchestrator, '_models'):
            communicator_model = self._orchestrator._models.get("communicator", "")
            if communicator_model:
                try:
                    enhanced = await self._enhance_with_nl(card, communicator_model)
                    if enhanced:
                        return enhanced
                except Exception as exc:
                    self._logger.debug("[CARDS] NL enhancement failed: %s", exc)

        return card

    async def _enhance_with_nl(
        self,
        card: ActionCard,
        model_path: str,
    ) -> ActionCard | None:
        """Użyj Qwen3-Nano do wygenerowania lepszych opisów NL.

        Model tłumaczy surowe dane na język zrozumiały dla laika.
        Prompt zabrania żargonu księgowego.
        """
        context = card.context
        prompt = f"""Jesteś asystentem przedsiębiorcy. Przetłumacz dane księgowe na prosty, zrozumiały język.
NIE używaj żargonu (WN, MA, PKWiU, MPP, JPK). Mów jak człowiek do człowieka.

Dane:
- Dokument: {card.document_type}
- Kwota: {context.get('amount_gross', '?')} {context.get('currency', 'PLN')}
- Kontrahent: {context.get('vendor_name', context.get('vendor_nip', '?'))}
- Pewność AI: {card.trust_score:.0%}

Zwróć DOKŁADNIE w tym formacie (bez dodatkowego tekstu):
TITLE: [krótki nagłówek - max 60 znaków]
SUMMARY: [2-3 zdania wyjaśnienia - max 300 znaków]
OPTION1: [etykieta przycisku 1 - max 30 znaków]
OPTION2: [etykieta przycisku 2 - max 30 znaków]
OPTION3: [etykieta przycisku 3 - max 30 znaków]"""

        try:
            result = await self._orchestrator.infer(
                model_path, prompt, max_tokens=300, temperature=0.3,
            )
            if result:
                return self._parse_nl_result(result, card)
        except Exception:
            pass

        return None

    @staticmethod
    def _parse_nl_result(result: str, original_card: ActionCard) -> ActionCard | None:
        """Parsuj wynik NL z Qwen3-Nano i zaktualizuj kartę."""
        import re

        title_match = re.search(r"TITLE:\s*(.+)", result)
        summary_match = re.search(r"SUMMARY:\s*(.+)", result)
        option_matches = re.findall(r"OPTION\d:\s*(.+)", result)

        if not title_match:
            return None

        new_title = title_match.group(1).strip()[:60]
        new_summary = summary_match.group(1).strip()[:300] if summary_match else original_card.summary

        # Aktualizuj etykiety opcji
        options = list(original_card.options)
        for i, opt in enumerate(options):
            if i < len(option_matches):
                new_label = option_matches[i].strip()[:30]
                options[i] = ActionCardOption(
                    option_id=opt.option_id,
                    label=new_label,
                    description=opt.description,
                    is_recommended=opt.is_recommended,
                    action_type=opt.action_type,
                    hidden_payload=opt.hidden_payload,
                    trust_impact=opt.trust_impact,
                )

        return ActionCard(
            card_id=original_card.card_id,
            decision_id=original_card.decision_id,
            title=new_title,
            summary=new_summary,
            agent_name=original_card.agent_name,
            document_type=original_card.document_type,
            options=options,
            trust_score=original_card.trust_score,
            decision_mode=original_card.decision_mode,
            urgency=original_card.urgency,
            context=original_card.context,
            created_at=original_card.created_at,
            expires_at=original_card.expires_at,
        )


# ═════════════════════════════════════════════════════════════════════════
# ProactiveWorkflowScheduler — Główny silnik
# ═════════════════════════════════════════════════════════════════════════


class ProactiveWorkflowScheduler:
    """Autonomiczny Silnik Proaktywnych Workflow — ENTERPRISE v5.0.

    GENIALNY POMYSŁ:
    Agenci przestają być REAKTYWNI — stają się PROAKTYWNYMI zarządcami
    całego cyklu księgowego. Nie czekają na fakturę — sami ją znajdują,
    przetwarzają i przedstawiają przedsiębiorcy gotowe decyzje.

    Harmonogram:
    - Daily (co 24h): briefing, KSeF, bank, dunning, vendor, tax alerts
    - Weekly (poniedziałek): P&L, DSO, top kontrahenci
    - Monthly (1., 10., 20., 25., ostatni dzień): raporty, alerty, zamknięcie

    Integracja:
    - AgentOrchestrator: koordynacja wszystkich workflow
    - AgentAnalytics: daily brief, weekly/monthly reports
    - AgentDataExtraction: KSeF fetch, bank sync
    - AgentQualityValidator: tax deadlines, compliance scan
    - ResourceOptimizer: zarządzanie modelami i workerami
    """

    # ── Harmonogram workflow ─────────────────────────────────────────

    WORKFLOW_SCHEDULE: dict[str, dict[str, Any]] = {
        # ── Dzienne ──
        WorkflowType.DAILY_BRIEFING: {
            "cron": "0 6 * * *",
            "priority": 3,
            "description": "Poranne podsumowanie finansowe dla przedsiębiorcy",
            "agent": "orchestrator",
        },
        WorkflowType.KSEF_FETCH: {
            "cron": "0 7 * * *",
            "priority": 2,
            "description": "Automatyczne pobranie nowych faktur z KSeF",
            "agent": "extraction",
        },
        WorkflowType.BANK_SYNC: {
            "cron": "0 8 * * *",
            "priority": 2,
            "description": "Synchronizacja z kontem bankowym, wykrycie nowych przelewów",
            "agent": "analytics",
        },
        WorkflowType.DUNNING_CHECK: {
            "cron": "0 9 * * *",
            "priority": 4,
            "description": "Kontrola należności — windykacja automatyczna",
            "agent": "orchestrator",
        },
        WorkflowType.VENDOR_MONITOR: {
            "cron": "0 10 * * *",
            "priority": 4,
            "description": "Weryfikacja kontrahentów — Biała Lista MF, zmiany kont bankowych",
            "agent": "analytics",
        },
        WorkflowType.TAX_DEADLINE_ALERT: {
            "cron": "0 14 * * *",
            "priority": 3,
            "description": "Alerty o zbliżających się terminach podatkowych (ZUS, VAT, PIT/CIT)",
            "agent": "quality",
        },
        WorkflowType.PAYMENT_BATCH: {
            "cron": "0 16 * * *",
            "priority": 3,
            "description": "Przygotowanie paczki przelewów do akceptacji",
            "agent": "orchestrator",
        },
        WorkflowType.EVENING_SUMMARY: {
            "cron": "0 18 * * *",
            "priority": 5,
            "description": "Wieczorne podsumowanie dnia",
            "agent": "orchestrator",
        },
        WorkflowType.HEALTH_CHECK: {
            "cron": "*/30 * * * *",
            "priority": 1,
            "description": "Monitoring stanu agentów i zasobów",
            "agent": "system",
        },
        WorkflowType.RESOURCE_OPTIMIZER: {
            "cron": "0 22 * * *",
            "priority": 6,
            "description": "Auto-unload nieużywanych modeli, optymalizacja RAM",
            "agent": "system",
        },
        # ── Tygodniowe ──
        WorkflowType.WEEKLY_REPORT: {
            "cron": "0 7 * * 1",  # Poniedziałek 07:00
            "priority": 5,
            "description": "Raport tygodniowy: P&L, DSO, top kontrahenci",
            "agent": "analytics",
        },
        # ── Miesięczne ──
        WorkflowType.MONTHLY_CLOSING: {
            "cron": "0 8 1 * *",  # 1. dzień miesiąca 08:00
            "priority": 3,
            "description": "Uzgodnienia miesięczne, amortyzacja, zestawienia",
            "agent": "orchestrator",
        },
        WorkflowType.TAX_CALENDAR: {
            "cron": "0 8 10,20,25 * *",  # 10., 20., 25. dzień
            "priority": 3,
            "description": "Kalendarz podatkowy — alerty ZUS, VAT, PIT/CIT, JPK",
            "agent": "quality",
        },
        WorkflowType.MONTH_END_CLOSING: {
            "cron": "0 18 28-31 * *",  # Ostatnie dni miesiąca
            "priority": 2,
            "description": "Zamknięcie miesiąca — uzgodnienia końcowe",
            "agent": "orchestrator",
        },
        WorkflowType.AUTO_BACKUP: {
            "cron": "0 3 * * *",
            "priority": 5,
            "description": "Automatyczny backup bazy danych (zaszyfrowany)",
            "agent": "system",
        },
        WorkflowType.COMPLIANCE_SCAN: {
            "cron": "0 12 * * *",
            "priority": 4,
            "description": "Skan compliance — reguły OPA, RODO, KSeF",
            "agent": "quality",
        },
        WorkflowType.DECISION_FEED_REFRESH: {
            "cron": "*/30 * * * *",
            "priority": 2,
            "description": "Odświeżenie feedu kart decyzyjnych — publikacja ActionCardFeed na ui.feed.pending",
            "agent": "orchestrator",
        },
    }

    def __init__(
        self,
        orchestrator: Any = None,
        config: dict[str, Any] | None = None,
    ) -> None:
        self._orchestrator = orchestrator
        self._config = config or {}
        self._running = False
        self._logger = get_logger("nexus.agents.proactive")

        # ── Sub-komponenty ──
        self._workflow_manager = WorkflowManager()
        self._resource_optimizer = ResourceOptimizer(config)
        self._last_executed: dict[str, str] = {}  # type -> ISO timestamp

    # ── Konfiguracja alertów podatkowych ──
    # Dni przed terminem, w których generujemy alerty: ZUS (10.), DRA (15.), VAT (25.), PIT/CIT (20.)
    TAX_DEADLINE_ZUS_DAYS: tuple[int, ...] = (3, 5, 8)
    TAX_DEADLINE_ZUS_DRA_DAYS: tuple[int, ...] = (8, 10, 13)
    TAX_DEADLINE_VAT_DAYS: tuple[int, ...] = (18, 20, 23)
    TAX_DEADLINE_PIT_DAYS: tuple[int, ...] = (13, 15, 18)

    @property
    def workflow_manager(self) -> WorkflowManager:
        return self._workflow_manager

    @property
    def resource_optimizer(self) -> ResourceOptimizer:
        return self._resource_optimizer

    async def start(self) -> None:
        """Uruchom silnik proaktywnych workflow."""
        self._running = True
        self._logger.info(
            "[PROACTIVE] Workflow Engine started | %d workflows registered",
            len(self.WORKFLOW_SCHEDULE),
        )

    async def stop(self) -> None:
        """Zatrzymaj silnik."""
        self._running = False
        self._logger.info("[PROACTIVE] Workflow Engine stopped")

    @property
    def is_running(self) -> bool:
        return self._running

    # ── Główna metoda — uruchom workflow ────────────────────────────

    async def execute_workflow(self, workflow_type: str) -> WorkflowExecution:
        """Wykonaj konkretny workflow.

        Args:
            workflow_type: Typ workflow (WorkflowType).

        Returns:
            WorkflowExecution z wynikiem.
        """
        schedule = self.WORKFLOW_SCHEDULE.get(workflow_type)
        if not schedule:
            execution = WorkflowExecution(
                workflow_id=uuid.uuid4().hex[:16],
                workflow_type=workflow_type,
                status=WorkflowStatus.FAILED,
                error=f"Unknown workflow type: {workflow_type}",
            )
            self._workflow_manager.record(execution)
            return execution

        # Sprawdź deduplikację z cooldownem odpowiednim dla częstotliwości cron
        cron = schedule.get("cron", "")
        cooldown = self._cooldown_from_cron(cron)
        if self._workflow_manager.was_executed_recently(workflow_type, cooldown):
            execution = WorkflowExecution(
                workflow_id=uuid.uuid4().hex[:16],
                workflow_type=workflow_type,
            )
            execution.skip(f"Already executed within cooldown ({cooldown}min)")
            self._workflow_manager.record(execution)
            self._logger.debug("[PROACTIVE] %s skipped — within cooldown", workflow_type)
            return execution

        execution = self._workflow_manager.create_execution(workflow_type)
        execution.start()
        self._logger.info("[PROACTIVE] ▶ %s starting...", workflow_type)

        try:
            handler = self._get_handler(workflow_type)
            if handler:
                result = await handler()
                execution.complete(result or {})
                self._last_executed[workflow_type] = pendulum.now("UTC").isoformat()
                self._logger.info(
                    "[PROACTIVE] ✓ %s completed | %.0fms | result=%s",
                    workflow_type, execution.duration_ms,
                    result if result else "OK",
                )
            else:
                execution.skip(f"No handler registered for {workflow_type}")
                self._logger.debug("[PROACTIVE] ○ %s skipped — no handler", workflow_type)
        except Exception as exc:
            execution.fail(str(exc))
            self._logger.warning("[PROACTIVE] ✗ %s failed: %s", workflow_type, exc)

        self._workflow_manager.record(execution)
        return execution

    def _get_handler(self, workflow_type: str):
        """Pobierz handler dla danego typu workflow."""
        handlers = {
            WorkflowType.DAILY_BRIEFING: self._handle_daily_briefing,
            WorkflowType.KSEF_FETCH: self._handle_ksef_fetch,
            WorkflowType.BANK_SYNC: self._handle_bank_sync,
            WorkflowType.DUNNING_CHECK: self._handle_dunning_check,
            WorkflowType.VENDOR_MONITOR: self._handle_vendor_monitor,
            WorkflowType.TAX_DEADLINE_ALERT: self._handle_tax_deadline_alert,
            WorkflowType.PAYMENT_BATCH: self._handle_payment_batch,
            WorkflowType.EVENING_SUMMARY: self._handle_evening_summary,
            WorkflowType.HEALTH_CHECK: self._handle_health_check,
            WorkflowType.RESOURCE_OPTIMIZER: self._handle_resource_optimizer,
            WorkflowType.WEEKLY_REPORT: self._handle_weekly_report,
            WorkflowType.MONTHLY_CLOSING: self._handle_monthly_closing,
            WorkflowType.TAX_CALENDAR: self._handle_tax_calendar,
            WorkflowType.MONTH_END_CLOSING: self._handle_month_end_closing,
            WorkflowType.AUTO_BACKUP: self._handle_auto_backup,
            WorkflowType.COMPLIANCE_SCAN: self._handle_compliance_scan,
            WorkflowType.DECISION_FEED_REFRESH: self._handle_decision_feed_refresh,
        }
        return handlers.get(workflow_type)

    # ══════════════════════════════════════════════════════════════════
    # Handlery workflow — konkretne implementacje
    # ══════════════════════════════════════════════════════════════════

    async def _handle_daily_briefing(self) -> dict[str, Any]:
        """Poranny Daily Briefing — podsumowanie dla przedsiębiorcy.

        AgentAnalytics generuje brief, Orchestrator wysyła do UI.
        """
        if not self._orchestrator or "analytics" not in getattr(
            self._orchestrator, "_sub_agents", {}
        ):
            return {"status": "no_orchestrator"}

        analytics = self._orchestrator._sub_agents["analytics"]

        query = AnalyticsQuery(
            query_id=f"daily-brief-{pendulum.now('UTC').to_date_string()}",
            query_type="daily_brief",
            sql_query="""
                SELECT
                    COUNT(*) AS new_invoices,
                    COALESCE(SUM(amount_gross), 0) AS total_amount,
                    COUNT(CASE WHEN status = 'pending_decision' THEN 1 END) AS pending_decisions,
                    COUNT(CASE WHEN status = 'overdue' THEN 1 END) AS overdue_count
                FROM invoice_read_model
                WHERE created_at >= DATE('now', '-1 day')
            """,
        )
        result = await analytics.analyze(query)

        # Wyślij do Orchestratora (publikacja NATS)
        ctx = make_context(
            task_id=query.query_id,
            source="proactive-scheduler",
            target="orchestrator",
            priority=3,
        )
        await self._orchestrator.publish(AgentTopic.ANALYTICS_RESULT, result, ctx)

        return {
            "brief_generated": result.success,
            "new_invoices": result.data[0].get("new_invoices", 0) if result.data else 0,
            "pending_decisions": result.data[0].get("pending_decisions", 0) if result.data else 0,
            "daily_brief": result.daily_brief[:200] if result.daily_brief else "",
        }

    async def _handle_ksef_fetch(self) -> dict[str, Any]:
        """Automatyczne pobranie faktur z KSeF.

        AgentDataExtraction sprawdza API KSeF i pobiera nowe faktury.
        """
        if not self._orchestrator:
            return {"status": "no_orchestrator"}

        extraction = self._orchestrator._sub_agents.get("extraction")
        if not extraction:
            return {"status": "no_extraction_agent"}

        # Publikuj zadanie pobrania KSeF
        ctx = make_context(
            task_id=f"ksef-fetch-{uuid.uuid4().hex[:8]}",
            source="proactive-scheduler",
            target="extraction",
            priority=2,
        )
        await self._orchestrator.publish(
            AgentTopic.KSEF_RECEIVE,
            {
                "action": "fetch_new",
                "since": pendulum.now("UTC").subtract(days=1).isoformat(),
                "auto_process": True,
            },
            ctx,
        )

        return {
            "status": "dispatched",
            "timestamp": pendulum.now("UTC").isoformat(),
        }

    async def _handle_bank_sync(self) -> dict[str, Any]:
        """Synchronizacja z kontem bankowym.

        AgentAnalytics sprawdza nowe transakcje bankowe.
        """
        if not self._orchestrator or "analytics" not in getattr(
            self._orchestrator, "_sub_agents", {}
        ):
            return {"status": "no_orchestrator"}

        analytics = self._orchestrator._sub_agents["analytics"]

        query = AnalyticsQuery(
            query_id=f"bank-sync-{uuid.uuid4().hex[:8]}",
            query_type="sql",
            sql_query="""
                SELECT
                    COUNT(*) AS new_transactions,
                    COALESCE(SUM(CASE WHEN flow_direction = 'INFLOW' THEN amount ELSE 0 END), 0) AS total_inflow,
                    COALESCE(SUM(CASE WHEN flow_direction = 'OUTFLOW' THEN amount ELSE 0 END), 0) AS total_outflow
                FROM m_daily_cashflow
                WHERE day >= DATE('now', '-1 day')
            """,
        )
        result = await analytics.analyze(query)

        return {
            "new_transactions": result.data[0].get("new_transactions", 0) if result.data else 0,
            "total_inflow": result.data[0].get("total_inflow", 0) if result.data else 0,
            "total_outflow": result.data[0].get("total_outflow", 0) if result.data else 0,
        }

    async def _handle_dunning_check(self) -> dict[str, Any]:
        """Kontrola należności — windykacja automatyczna.

        Wykrywa przeterminowane faktury i inicjuje proces windykacji.
        """
        if not self._orchestrator or "analytics" not in getattr(
            self._orchestrator, "_sub_agents", {}
        ):
            return {"status": "no_orchestrator"}

        analytics = self._orchestrator._sub_agents["analytics"]

        query = AnalyticsQuery(
            query_id=f"dunning-{uuid.uuid4().hex[:8]}",
            query_type="sql",
            sql_query="""
                SELECT
                    COUNT(*) AS overdue_count,
                    COALESCE(SUM(balance_due), 0) AS total_overdue,
                    COUNT(CASE WHEN days_overdue > 30 THEN 1 END) AS critical_overdue
                FROM invoice_read_model
                WHERE status = 'OVERDUE' OR status = 'PARTIALLY_PAID'
            """,
        )
        result = await analytics.analyze(query)

        overdue = result.data[0] if result.data else {}
        critical = overdue.get("critical_overdue", 0)

        return {
            "overdue_count": overdue.get("overdue_count", 0),
            "total_overdue": overdue.get("total_overdue", 0),
            "critical_count": critical,
            "dunning_initiated": critical > 0,
        }

    async def _handle_vendor_monitor(self) -> dict[str, Any]:
        """Monitoring kontrahentów — Biała Lista MF, zmiany kont.

        AgentAnalytics weryfikuje status VAT kontrahentów.
        """
        if not self._orchestrator:
            return {"status": "no_orchestrator"}

        # Publikuj zadanie weryfikacji vendorów
        ctx = make_context(
            task_id=f"vendor-monitor-{uuid.uuid4().hex[:8]}",
            source="proactive-scheduler",
            target="analytics",
            priority=4,
        )
        await self._orchestrator.publish(
            AgentTopic.VENDOR_CHECK,
            {
                "action": "verify_all_active",
                "check_white_list": True,
                "check_account_changes": True,
            },
            ctx,
        )

        return {
            "status": "dispatched",
            "timestamp": pendulum.now("UTC").isoformat(),
        }

    async def _handle_tax_deadline_alert(self) -> dict[str, Any]:
        """Alerty o zbliżających się terminach podatkowych.

        AgentQualityValidator sprawdza kalendarz podatkowy.
        """
        now = pendulum.now("UTC")
        alerts = []

        # ZUS — do 10. dnia miesiąca (składki); 15. (DRA)
        if now.day in self.TAX_DEADLINE_ZUS_DAYS:
            alerts.append({
                "type": "ZUS",
                "deadline": f"{now.year}-{now.month:02d}-10",
                "days_left": 10 - now.day,
                "description": "Termin opłacenia składek ZUS",
            })
        if now.day in self.TAX_DEADLINE_ZUS_DRA_DAYS:
            alerts.append({
                "type": "ZUS",
                "deadline": f"{now.year}-{now.month:02d}-15",
                "days_left": 15 - now.day,
                "description": "Termin złożenia deklaracji ZUS DRA",
            })

        # VAT/JPK — do 25. dnia miesiąca
        if now.day in self.TAX_DEADLINE_VAT_DAYS:
            alerts.append({
                "type": "VAT",
                "deadline": f"{now.year}-{now.month:02d}-25",
                "days_left": 25 - now.day,
                "description": "Termin złożenia JPK_V7 i zapłaty VAT",
            })

        # PIT/CIT — do 20. dnia miesiąca (zaliczki)
        if now.day in self.TAX_DEADLINE_PIT_DAYS:
            alerts.append({
                "type": "PIT_CIT",
                "deadline": f"{now.year}-{now.month:02d}-20",
                "days_left": 20 - now.day,
                "description": "Termin zapłaty zaliczki na PIT/CIT",
            })

        if alerts:
            ctx = make_context(
                task_id=f"tax-alert-{uuid.uuid4().hex[:8]}",
                source="proactive-scheduler",
                target="orchestrator",
                priority=2,
            )
            await self._orchestrator.publish(
                AgentTopic.TAX_DEADLINE,
                {"alerts": alerts},
                ctx,
            )

        return {
            "alerts_generated": len(alerts),
            "alerts": alerts,
        }

    async def _handle_payment_batch(self) -> dict[str, Any]:
        """Przygotowanie paczki przelewów do akceptacji.

        AgentOrchestrator zbiera wszystkie zatwierdzone faktury do zapłaty.
        """
        if not self._orchestrator:
            return {"status": "no_orchestrator"}

        ctx = make_context(
            task_id=f"payment-batch-{uuid.uuid4().hex[:8]}",
            source="proactive-scheduler",
            target="orchestrator",
            priority=3,
        )
        await self._orchestrator.publish(
            AgentTopic.COUNCIL_TASK_REQUEST,
            {
                "task": "prepare_payment_batch",
                "for_date": pendulum.now("UTC").add(days=1).to_date_string(),
                "include_due_tomorrow": True,
                "include_discounts": True,
            },
            ctx,
        )

        return {
            "status": "dispatched",
            "for_date": pendulum.now("UTC").add(days=1).to_date_string(),
        }

    async def _handle_evening_summary(self) -> dict[str, Any]:
        """Wieczorne podsumowanie dnia.

        AgentAnalytics generuje podsumowanie, Orchestrator wysyła do UI.
        """
        if not self._orchestrator or "analytics" not in getattr(
            self._orchestrator, "_sub_agents", {}
        ):
            return {"status": "no_orchestrator"}

        analytics = self._orchestrator._sub_agents["analytics"]

        query = AnalyticsQuery(
            query_id=f"evening-summary-{uuid.uuid4().hex[:8]}",
            query_type="daily_brief",
            sql_query="""
                SELECT
                    COUNT(*) AS today_processed,
                    COALESCE(SUM(amount_gross), 0) AS today_total,
                    COUNT(CASE WHEN status = 'auto_posted' THEN 1 END) AS auto_posted,
                    COUNT(CASE WHEN status = 'pending_decision' THEN 1 END) AS awaiting_decision
                FROM invoice_read_model
                WHERE DATE(created_at) = DATE('now')
            """,
        )
        result = await analytics.analyze(query)

        ctx = make_context(
            task_id=query.query_id,
            source="proactive-scheduler",
            target="orchestrator",
            priority=5,
        )
        await self._orchestrator.publish(AgentTopic.ANALYTICS_RESULT, result, ctx)

        return {
            "today_processed": result.data[0].get("today_processed", 0) if result.data else 0,
            "today_total": result.data[0].get("today_total", 0) if result.data else 0,
            "auto_posted": result.data[0].get("auto_posted", 0) if result.data else 0,
            "awaiting_decision": result.data[0].get("awaiting_decision", 0) if result.data else 0,
        }

    async def _handle_health_check(self) -> dict[str, Any]:
        """Monitoring stanu agentów i zasobów.

        Sprawdza stan wszystkich 5 agentów przez heartbeat.
        """
        resources = self._resource_optimizer.get_system_resources()

        # Sprawdź stan agentów przez Orchestrator
        agents_status = {}
        if self._orchestrator:
            for name, agent in self._orchestrator._sub_agents.items():
                try:
                    health = agent.health
                    agents_status[name] = {
                        "status": health.status,
                        "decisions": health.decisions_total,
                        "uptime_s": health.uptime_seconds,
                    }
                except Exception:
                    agents_status[name] = {"status": "unknown"}

        # Wykryj potencjalne problemy
        issues = []
        if resources.get("ram_pct", 0) > 90:
            issues.append("CRITICAL: RAM usage > 90%")
        elif resources.get("ram_pct", 0) > 80:
            issues.append("WARNING: RAM usage > 80%")
        if resources.get("disk_free_gb", 100) < 1:
            issues.append("CRITICAL: Disk space < 1 GB")

        if issues:
            self._logger.warning("[PROACTIVE] Health issues: %s", issues)

        return {
            "resources": resources,
            "agents": agents_status,
            "issues": issues,
            "healthy": len(issues) == 0,
        }

    async def _handle_resource_optimizer(self) -> dict[str, Any]:
        """Auto-unload nieużywanych modeli, optymalizacja RAM.

        ResourceOptimizer sprawdza które modele można odładować.
        """
        resources = self._resource_optimizer.get_system_resources()
        unloaded: list[str] = []

        if not self._orchestrator:
            return {"status": "no_orchestrator", "models_unloaded": 0}

        # Zbierz ścieżki załadowanych modeli od wszystkich sub-agentów
        loaded: list[str] = []
        for _name, agent in self._orchestrator._sub_agents.items():
            if hasattr(agent, "_models"):
                loaded.extend([v for v in agent._models.values() if v])

        to_unload = self._resource_optimizer.should_unload_models(loaded)

        # Faktyczne odładowanie modeli przez ModelManager (jeśli dostępny)
        unloaded_count = 0
        model_manager = getattr(self._orchestrator, "_model_manager", None)
        if model_manager and hasattr(model_manager, "unload"):
            for model_path in to_unload:
                try:
                    model_manager.unload(model_path)
                    unloaded_count += 1
                    self._logger.info("[RESOURCE] Unloaded: %s", model_path)
                except Exception as exc:
                    self._logger.debug("[RESOURCE] Failed to unload %s: %s", model_path, exc)
        elif to_unload:
            self._logger.info(
                "[RESOURCE] %d models marked for unload (ModelManager.unload not available)",
                len(to_unload),
            )

        return {
            "resources_before": resources,
            "models_unloaded": to_unload,
            "unloaded_count": unloaded_count,
            "ram_pct": resources.get("ram_pct", 0),
            "timestamp": pendulum.now("UTC").isoformat(),
        }

    async def _handle_weekly_report(self) -> dict[str, Any]:
        """Raport tygodniowy: P&L, DSO, top kontrahenci."""
        if not self._orchestrator or "analytics" not in getattr(
            self._orchestrator, "_sub_agents", {}
        ):
            return {"status": "no_orchestrator"}

        analytics = self._orchestrator._sub_agents["analytics"]

        query = AnalyticsQuery(
            query_id=f"weekly-{uuid.uuid4().hex[:8]}",
            query_type="sql",
            sql_query="""
                SELECT
                    DATE_TRUNC('week', created_at) AS week,
                    COUNT(*) AS invoice_count,
                    COALESCE(SUM(amount_gross), 0) AS total_amount,
                    AVG(amount_gross) AS avg_amount,
                    COUNT(DISTINCT contractor_id) AS unique_contractors,
                    COALESCE(SUM(CASE WHEN status = 'OVERDUE' THEN amount_gross ELSE 0 END), 0) AS overdue_total
                FROM invoice_read_model
                WHERE created_at >= DATE('now', '-7 days')
                GROUP BY 1 ORDER BY 1
            """,
        )
        result = await analytics.analyze(query)

        ctx = make_context(
            task_id=query.query_id,
            source="proactive-scheduler",
            target="orchestrator",
            priority=5,
        )
        await self._orchestrator.publish(AgentTopic.ANALYTICS_RESULT, result, ctx)

        return {
            "report_generated": result.success,
            "weeks": len(result.data),
            "total_amount": sum((r.get("total_amount", 0) or 0) for r in result.data),
        }

    async def _handle_monthly_closing(self) -> dict[str, Any]:
        """Uzgodnienia miesięczne — amortyzacja, zestawienia."""
        ctx = make_context(
            task_id=f"monthly-closing-{uuid.uuid4().hex[:8]}",
            source="proactive-scheduler",
            target="orchestrator",
            priority=3,
        )
        await self._orchestrator.publish(
            AgentTopic.COUNCIL_TASK_REQUEST,
            {
                "task": "monthly_closing",
                "month": pendulum.now("UTC").format("YYYY-MM"),
                "steps": [
                    "depreciation",
                    "accruals",
                    "reconciliation",
                    "vat_settlement",
                    "monthly_report",
                ],
            },
            ctx,
        )

        return {"status": "dispatched"}

    async def _handle_tax_calendar(self) -> dict[str, Any]:
        """Kalendarz podatkowy — alerty miesięczne.

        Wysyłane 10., 20., 25. dnia miesiąca.
        """
        now = pendulum.now("UTC")
        ctx = make_context(
            task_id=f"tax-calendar-{uuid.uuid4().hex[:8]}",
            source="proactive-scheduler",
            target="orchestrator",
            priority=3,
        )
        await self._orchestrator.publish(
            AgentTopic.TAX_DEADLINE,
            {
                "calendar_day": now.day,
                "month": now.format("YYYY-MM"),
                "upcoming": [
                    {"type": "ZUS", "days": "10-15"},
                    {"type": "PIT_CIT", "days": "20"},
                    {"type": "VAT_JPK", "days": "25"},
                ],
            },
            ctx,
        )

        return {"status": "dispatched"}

    async def _handle_month_end_closing(self) -> dict[str, Any]:
        """Zamknięcie miesiąca — ostatnie dni."""
        ctx = make_context(
            task_id=f"month-end-{uuid.uuid4().hex[:8]}",
            source="proactive-scheduler",
            target="orchestrator",
            priority=2,
        )
        await self._orchestrator.publish(
            AgentTopic.COUNCIL_TASK_REQUEST,
            {
                "task": "month_end_closing",
                "urgency": "high",
                "auto_post_final_batch": True,
            },
            ctx,
        )

        return {"status": "dispatched"}

    async def _handle_auto_backup(self) -> dict[str, Any]:
        """Automatyczny backup bazy danych."""
        ctx = make_context(
            task_id=f"auto-backup-{uuid.uuid4().hex[:8]}",
            source="proactive-scheduler",
            target="system",
            priority=5,
        )
        await self._orchestrator.publish(
            AgentTopic.SYSTEM_CONFIG_UPDATED,
            {"action": "backup", "trigger": "scheduled"},
            ctx,
        )

        return {"status": "dispatched"}

    async def _handle_compliance_scan(self) -> dict[str, Any]:
        """Skan compliance — reguły OPA, RODO, KSeF."""
        if not self._orchestrator or "quality" not in getattr(
            self._orchestrator, "_sub_agents", {}
        ):
            return {"status": "no_orchestrator"}

        ctx = make_context(
            task_id=f"compliance-{uuid.uuid4().hex[:8]}",
            source="proactive-scheduler",
            target="quality",
            priority=4,
        )
        await self._orchestrator.publish(
            AgentTopic.COMPLIANCE_CHECK,
            {
                "checks": ["opa_rules", "gdpr", "ksef", "proof_chain"],
            },
            ctx,
        )

        return {"status": "dispatched"}

        return {"status": "dispatched"}

    async def _handle_decision_feed_refresh(self) -> dict[str, Any]:
        """Odświeżenie feedu kart decyzyjnych dla UI.

        GENIALNY POMYSŁ v5.1:
        Co 30 minut buduje ActionCardFeed ze wszystkich oczekujących
        decyzji (SUGGEST/ASK_USER) i publikuje na ui.feed.pending.
        Dzięki temu UI zawsze ma świeży feed kart dla przedsiębiorcy.
        """
        if not self._orchestrator:
            return {"status": "no_orchestrator"}

        try:
            feed = await self._orchestrator.build_daily_decision_feed()
            return {
                "status": "ok",
                "total_cards": feed.total_pending,
                "urgent": feed.urgent_count,
            }
        except Exception as exc:
            self._logger.warning("[PROACTIVE] Feed refresh failed: %s", exc)
            return {"status": "error", "error": str(exc)}

    # ── Metody pomocnicze ──────────────────────────────────────────

    @staticmethod
    def _cooldown_from_cron(cron: str) -> int:
        """Oblicz cooldown w minutach na podstawie wyrażenia cron.

        */30 = 30 min, 0 6 = 1440 (daily), 0 7 * * 1 = 10080 (weekly).
        """
        parts = cron.split()
        if len(parts) < 2:
            return 1440
        minute_part = parts[0]
        hour_part = parts[1]
        # Sub-hourly: */N
        if minute_part.startswith("*/") and hour_part == "*":
            try:
                return int(minute_part[2:])
            except ValueError:
                pass
        # Hourly: 0 * * * *
        if hour_part == "*":
            return 60
        # Daily: X HH * * *
        return 1440

    def get_schedule_summary(self) -> list[dict[str, Any]]:
        """Pobierz podsumowanie harmonogramu."""
        return [
            {
                "type": wf_type,
                "cron": schedule["cron"],
                "priority": schedule["priority"],
                "description": schedule["description"],
                "agent": schedule["agent"],
                "last_executed": self._last_executed.get(wf_type, "never"),
                "executed_recently": self._workflow_manager.was_executed_recently(
                    wf_type,
                    ProactiveWorkflowScheduler._cooldown_from_cron(schedule["cron"]),
                ),
            }
            for wf_type, schedule in self.WORKFLOW_SCHEDULE.items()
        ]

    def get_stats(self) -> dict[str, Any]:
        """Pobierz pełne statystyki."""
        return {
            **self._workflow_manager.get_stats(),
            "resources": self._resource_optimizer.get_system_resources(),
            "last_executed": dict(self._last_executed),
            "schedule": self.get_schedule_summary(),
        }
