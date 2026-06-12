"""
projection_worker.py — CLI entrypoint for the Projection Worker.

Usage:
    python -m nexus_ai.scripts.projection_worker
    python -m nexus_ai.scripts.projection_worker --nats nats://localhost:4222
    python -m nexus_ai.scripts.projection_worker --no-fallback --poll 5.0

Osobny proces konsumujący eventy domenowe z NATS JetStream i aktualizujący
projekcje CQRS (InvoiceProjection, DecisionProjection).

Sygnały:
    SIGINT / SIGTERM — graceful shutdown z dokończeniem bieżących eventów.
"""

from __future__ import annotations

import argparse
import anyio
import logging
import os
import platform
import signal
import sys
from pathlib import Path

if getattr(sys, "frozen", False):
    BASE_PATH = Path(sys._MEIPASS)
else:
    BASE_PATH = Path(__file__).resolve().parent.parent.parent

import pendulum
from structlog import get_logger

from nexus_ai.events.projection_worker import create_default_worker

logger = get_logger("nexus.projection_worker")


def _setup_logging(verbose: bool = False) -> None:
    """Skonfiguruj logging z structlog i standardowym logging jako backend."""
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s (PID:%(process)d): %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )


async def _run_worker(
    nats_servers: list[str] | None = None,
    enable_fallback: bool = True,
    fallback_poll_seconds: float = 30.0,
    poll_interval: float = 1.0,
    batch_size: int = 10,
    base_dir: str | None = None,
) -> None:
    """Utwórz i uruchom ProjectionWorker.

    Args:
        nats_servers: Serwery NATS.
        enable_fallback: Czy włączyć fallback polling EventStore.
        fallback_poll_seconds: Interwał fallback pollowania.
        poll_interval: Interwał pollowania JetStream.
        batch_size: Rozmiar batcha dla JetStream pull consumer.
        base_dir: Bazowy katalog dla danych (EventStore, projekcje).
    """
    # Określ base_dir
    if base_dir:
        base_path = Path(base_dir).resolve()
    else:
        base_path = Path.cwd()

    nats = os.getenv("NEXUS_NATS_URL", "nats://localhost:4222")
    nats_list = nats_servers or [nats]

    logger.info(
        "[PROJECTION-WORKER] Booting — base_dir=%s nats=%s fallback=%s",
        base_path,
        nats_list,
        enable_fallback,
    )

    # Utwórz worker (parametry przekazane przez create_default_worker)
    worker = await create_default_worker(
        base_dir=base_path,
        nats_servers=nats_list,
        enable_fallback=enable_fallback,
        poll_interval=poll_interval,
        batch_size=batch_size,
        fallback_poll_seconds=fallback_poll_seconds,
    )

    # Podłącz sygnały shutdown
    if platform.system() != "Windows":
        for sig in (signal.SIGINT, signal.SIGTERM):
            signal.signal(sig, worker.handle_signal)

    try:
        await worker.start()
    except anyio.CancelledError:
        pass
    finally:
        await worker.stop()


def main(argv: list[str] | None = None) -> int:
    """CLI entry point for projection worker.

    Args:
        argv: Argumenty wiersza poleceń (domyślnie sys.argv[1:]).

    Returns:
        0 = sukces, 1 = błąd.
    """
    parser = argparse.ArgumentParser(
        description="NexusAI Projection Worker — consumes events from "
                    "NATS JetStream and updates CQRS projections",
    )
    parser.add_argument(
        "--nats",
        type=str,
        action="append",
        dest="nats_servers",
        help="NATS server URL (powtarzalne dla wielu serwerów). "
             "Domyślnie: NEXUS_NATS_URL lub nats://localhost:4222",
    )
    parser.add_argument(
        "--no-fallback",
        action="store_true",
        help="Wyłącz fallback polling EventStore (tylko JetStream)",
    )
    parser.add_argument(
        "--fallback-interval",
        type=float,
        default=30.0,
        help="Interwał fallback pollowania EventStore w sekundach "
             "(domyślnie: 30)",
    )
    parser.add_argument(
        "--poll-interval",
        type=float,
        default=1.0,
        help="Interwał pollowania JetStream pull consumer w sekundach "
             "(domyślnie: 1.0)",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=10,
        help="Maksymalna liczba wiadomości w jednym fetchu JetStream "
             "(domyślnie: 10)",
    )
    parser.add_argument(
        "--base-dir",
        type=str,
        default=None,
        help="Bazowy katalog dla danych (EventStore, projekcje). "
             "Domyślnie: bieżący katalog",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Debug logging",
    )

    args = parser.parse_args(argv)

    _setup_logging(verbose=args.verbose)

    start = pendulum.now("UTC")

    try:
        anyio.run(
            lambda: _run_worker(
                nats_servers=args.nats_servers,
                enable_fallback=not args.no_fallback,
                fallback_poll_seconds=args.fallback_interval,
                poll_interval=args.poll_interval,
                batch_size=args.batch_size,
                base_dir=args.base_dir,
            ),
        )
        uptime = (pendulum.now("UTC") - start).total_seconds()
        logger.info(
            "[PROJECTION-WORKER] Shutdown complete (uptime=%.1fs)",
            uptime,
        )
        return 0

    except KeyboardInterrupt:
        uptime = (pendulum.now("UTC") - start).total_seconds()
        logger.info(
            "[PROJECTION-WORKER] Interrupted (uptime=%.1fs)",
            uptime,
        )
        return 0
    except Exception as exc:
        logger.exception(
            "[PROJECTION-WORKER] Fatal error: %s", exc,
        )
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
