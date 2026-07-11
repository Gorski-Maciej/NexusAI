#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI — ScVerdictStreaming: Strumieniowe Przetwarzanie Faktur dla SC
# ═══════════════════════════════════════════════════════════════════════════════
#
# Optymalizacja #3 z 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md
#
# Architektura strumieniowa z podziałem na dane "wolnozmienne" (partnership,
# partners, thresholds — ładowane RAZ na sesję) i "szybkozmienne" (faktury).
#
# Usage:
#   python3 sc_verdict_streaming.py --context context.json --invoices invoices/*.json
#   python3 sc_verdict_streaming.py --context context.json --invoices invoices/ --output results/
#   python3 sc_verdict_streaming.py --benchmark --invoices invoices/
# ═══════════════════════════════════════════════════════════════════════════════

import argparse
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Dict, List, Optional


# ── OPA Client ────────────────────────────────────────────────────────────────

class OpaClient:
    """Klient OPA z obsługą pre-załadowanego kontekstu."""

    def __init__(self, opa_url: str = "http://localhost:8181"):
        self.opa_url = opa_url.rstrip("/")
        self.context: Dict = {}
        self.context_loaded = False

    def load_context(self, context_json: Dict) -> None:
        """Ładuje kontekst wolnozmienny do OPA (partnership, partners, thresholds)."""
        self.context = context_json
        self.context_loaded = True

        # Faza 1 MVP: symulacja pre-load context
        # W Fazie 2: użycie OPA Data API PUT /v1/data/sc/context
        print(f"📦 Kontekst załadowany: {len(context_json.get('partners', []))} wspólników, "
              f"spółka: {context_json.get('partnership', {}).get('name', 'unknown')}")

    def evaluate(self, invoice: Dict) -> Dict:
        """Ewaluuje pojedynczą fakturę z pre-załadowanym kontekstem."""
        if not self.context_loaded:
            raise RuntimeError("Kontekst niezaładowany — wywołaj load_context() najpierw")

        # Buduj pełny input: kontekst + faktura
        full_input = {
            **self.context,
            "invoice": invoice.get("invoice", invoice),
            "vendor": invoice.get("vendor", {}),
            "confidence": invoice.get("confidence", {}),
        }

        # Faza 1 MVP: wywołanie OPA przez CLI
        # W Fazie 2: HTTP POST /v1/data/sc/rules/evaluate
        input_json = json.dumps(full_input)
        try:
            result = subprocess.run(
                ["opa", "eval", "--data", "policies/tax", "--input", "/dev/stdin",
                 "data.tax.fallback.decide"],
                input=input_json,
                capture_output=True,
                text=True,
                timeout=30,
            )
            if result.returncode != 0:
                return {"error": result.stderr, "invoice": invoice.get("invoice", {}).get("id", "unknown")}

            # Parsuj wynik OPA
            return self._parse_opa_output(result.stdout, invoice)
        except subprocess.TimeoutExpired:
            return {"error": "OPA_TIMEOUT", "invoice": invoice.get("invoice", {}).get("id", "unknown")}
        except FileNotFoundError:
            # Tryb development — symulacja bez OPA
            return self._simulate_verdict(invoice)

    def _parse_opa_output(self, output: str, invoice: Dict) -> Dict:
        """Parsuje surowy output OPA do struktury werdyktu."""
        try:
            result = json.loads(output)
            verdict = result[0]["result"] if isinstance(result, list) else result.get("result", {})
            verdict["_invoice_id"] = invoice.get("invoice", {}).get("id", invoice.get("id", "unknown"))
            verdict["_timestamp"] = time.time()
            return verdict
        except (json.JSONDecodeError, KeyError, IndexError):
            return {
                "matched": False,
                "rule_id": "sc_verdict_streaming.parse_error",
                "_invoice_id": invoice.get("id", "unknown"),
                "_error": "Failed to parse OPA output"
            }

    def _simulate_verdict(self, invoice: Dict) -> Dict:
        """Symuluje werdykt (developerski fallback bez OPA)."""
        amount = invoice.get("amount_net", invoice.get("invoice", {}).get("amount_net", 0))
        return {
            "matched": True,
            "rule_id": "sc_verdict_streaming.simulated",
            "package": "sc.fallback",
            "priority": 200,
            "vat_rate": 0.23,
            "amount_net": amount,
            "_invoice_id": invoice.get("id", "unknown"),
            "_timestamp": time.time(),
            "_simulated": True
        }


# ── Verdict Streamer ──────────────────────────────────────────────────────────

class ScVerdictStreamer:
    """Strumieniowe przetwarzanie faktur z pre-załadowanym kontekstem."""

    def __init__(self, opa_url: str = "http://localhost:8181", max_workers: int = 4):
        self.client = OpaClient(opa_url)
        self.max_workers = max_workers
        self.stats = {
            "total_invoices": 0,
            "processed": 0,
            "errors": 0,
            "total_time_ms": 0,
            "avg_time_ms": 0,
        }

    def load_context_from_file(self, context_path: str) -> None:
        """Ładuje kontekst z pliku JSON."""
        context = json.loads(Path(context_path).read_text())
        self.client.load_context(context)

    def process_invoice_file(self, invoice_path: str) -> Dict:
        """Przetwarza pojedynczy plik faktury."""
        invoice = json.loads(Path(invoice_path).read_text())
        start = time.time()
        try:
            verdict = self.client.evaluate(invoice)
            elapsed = (time.time() - start) * 1000
            self.stats["processed"] += 1
            verdict["_processing_time_ms"] = elapsed
            return verdict
        except Exception as e:
            elapsed = (time.time() - start) * 1000
            self.stats["errors"] += 1
            return {"error": str(e), "_invoice_path": invoice_path, "_processing_time_ms": elapsed}

    def process_directory(self, directory: str, output_dir: Optional[str] = None) -> List[Dict]:
        """Przetwarza wszystkie faktury w katalogu strumieniowo z wielowątkowością."""
        invoice_files = sorted(Path(directory).glob("*.json"))
        self.stats["total_invoices"] = len(invoice_files)

        print(f"📊 Przetwarzanie {len(invoice_files)} faktur z {directory}/")
        print(f"   Workers: {self.max_workers}")

        results = []
        start_total = time.time()

        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            futures = {
                executor.submit(self.process_invoice_file, str(f)): f.name
                for f in invoice_files
            }

            for i, future in enumerate(as_completed(futures)):
                filename = futures[future]
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    results.append({"error": str(e), "_invoice_file": filename})
                    self.stats["errors"] += 1

                # Progress indicator
                if (i + 1) % max(1, len(invoice_files) // 10) == 0:
                    elapsed = time.time() - start_total
                    rate = (i + 1) / elapsed if elapsed > 0 else 0
                    print(f"   ⏳ {i + 1}/{len(invoice_files)} ({rate:.1f} faktur/s)")

        self.stats["total_time_ms"] = (time.time() - start_total) * 1000
        self.stats["avg_time_ms"] = self.stats["total_time_ms"] / max(1, self.stats["total_invoices"])

        # Zapis wyników
        if output_dir:
            out_path = Path(output_dir)
            out_path.mkdir(parents=True, exist_ok=True)
            output_file = out_path / "verdicts.json"
            output_file.write_text(json.dumps(results, indent=2, ensure_ascii=False))
            print(f"   📁 Wyniki zapisane do {output_file}")

            # Zapis statystyk
            stats_file = out_path / "processing_stats.json"
            stats_file.write_text(json.dumps(self.stats, indent=2))
            print(f"   📁 Statystyki zapisane do {stats_file}")

        return results

    def benchmark(self, directory: str, runs: int = 3) -> Dict:
        """Uruchamia benchmark przetwarzania."""
        print(f"🏃 Benchmark — {runs} przebiegów...")
        all_times = []

        for run in range(runs):
            self.stats = {"total_invoices": 0, "processed": 0, "errors": 0, "total_time_ms": 0, "avg_time_ms": 0}
            start = time.time()
            self.process_directory(directory)
            elapsed = time.time() - start
            all_times.append(elapsed)
            print(f"   Run {run + 1}: {elapsed:.2f}s ({self.stats['total_invoices']} faktur, "
                  f"{self.stats['total_invoices'] / elapsed:.1f}/s)")

        avg_time = sum(all_times) / len(all_times)
        best_time = min(all_times)
        worst_time = max(all_times)

        benchmark_result = {
            "runs": runs,
            "avg_time_seconds": avg_time,
            "best_time_seconds": best_time,
            "worst_time_seconds": worst_time,
            "invoices_per_second": self.stats["total_invoices"] / avg_time if avg_time > 0 else 0,
            "total_invoices": self.stats["total_invoices"],
        }

        print(f"\n📊 Benchmark: {benchmark_result['invoices_per_second']:.1f} faktur/s "
              f"(avg: {avg_time:.2f}s, best: {best_time:.2f}s)")
        return benchmark_result


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="ScVerdictStreaming — strumieniowe przetwarzanie faktur SC")
    parser.add_argument("--context", required=True, help="Plik JSON z kontekstem (partnership + partners + thresholds)")
    parser.add_argument("--invoices", required=True, help="Katalog z plikami faktur JSON")
    parser.add_argument("--output", default="results", help="Katalog na wyniki")
    parser.add_argument("--workers", type=int, default=4, help="Liczba workerów (domyślnie 4)")
    parser.add_argument("--opa-url", default="http://localhost:8181", help="URL OPA (domyślnie localhost:8181)")
    parser.add_argument("--benchmark", action="store_true", help="Tryb benchmark")
    args = parser.parse_args()

    if not Path(args.invoices).exists():
        print(f"❌ Katalog {args.invoices} nie istnieje", file=sys.stderr)
        sys.exit(1)

    streamer = ScVerdictStreamer(opa_url=args.opa_url, max_workers=args.workers)

    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  ScVerdictStreaming — Strumieniowe Przetwarzanie Faktur SC  ║")
    print("╚══════════════════════════════════════════════════════════════╝")

    # Ładuj kontekst (RAZ)
    streamer.load_context_from_file(args.context)

    if args.benchmark:
        result = streamer.benchmark(args.invoices)
        benchmark_path = Path(args.output) / "benchmark_result.json"
        benchmark_path.parent.mkdir(parents=True, exist_ok=True)
        benchmark_path.write_text(json.dumps(result, indent=2))
        print(f"\n📁 Benchmark zapisany do {benchmark_path}")
    else:
        # Przetwarzaj faktury
        results = streamer.process_directory(args.invoices, args.output)

        # Podsumowanie
        total = streamer.stats["total_invoices"]
        processed = streamer.stats["processed"]
        errors = streamer.stats["errors"]
        avg_ms = streamer.stats["avg_time_ms"]
        total_s = streamer.stats["total_time_ms"] / 1000

        print(f"\n✅ Przetworzono {processed}/{total} faktur")
        print(f"   Błędy: {errors}")
        print(f"   Czas: {total_s:.2f}s (średnio {avg_ms:.1f}ms/fakturę)")
        print(f"   Przepustowość: {processed / total_s:.1f} faktur/s")


if __name__ == "__main__":
    main()
