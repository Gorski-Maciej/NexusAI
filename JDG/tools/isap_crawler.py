# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ISAP Legal Radar Crawler (C3 Strategic Initiative)
# ═══════════════════════════════════════════════════════════════════════════════
# Source: NexusAI_JDG_7000_MASTER_IMPLEMENTATION_PLAN.txt, Section 5.6
#         NexusAI_JDG_STRATEGIC_IMPROVEMENTS_7000.txt, Initiative C3
#
# Purpose: Bot crawler monitorujący zmiany w aktach prawnych objętych JDG
# (I-XIII) poprzez ISAP API, RCL RSS i Sejm API. Wykrywa zmiany, porównuje
# hash dzisiejszy vs wczorajszy i generuje GitHub Issues dla zespołu OPA.
#
# Architecture: Cron job (@daily) → crawl 13 aktów → diff engine → GitHub Issue
#
# Data sources (priority order):
#   1. LEX-Polska API (komercyjny, pełny feed) — wymaga umowy, ~5-15k PLN/rok
#   2. Sejm API (open, ograniczony do ustaw)
#   3. RCL RSS feed (publicznie dostępny, darmowy)
#   4. ISAP Selenium scraper (fallback dla niedostępnych aktów)
#
# Usage:
#   python isap_crawler.py                  # single run (cron)
#   python isap_crawler.py --daemon         # continuous mode (co 60 min)
#   python isap_crawler.py --dry-run        # check without creating issues
#   python isap_crawler.py --act vat        # check single act only
#
# Dependencies: httpx, difflib, hashlib, duckdb (for legal text store)
# ═══════════════════════════════════════════════════════════════════════════════

import asyncio
import hashlib
import difflib
import os
import sys
import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import httpx

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("isap_crawler")

# 13 aktów prawnych objętych modułem JDG (I-XIII z 50_JDG_BRAKUJACE_PUNKTY_PRAWNE)
ACTS_TO_MONITOR = {
    "I_vat": {
        "name": "Ustawa o podatku od towarów i usług (VAT)",
        "isap_id": "Dz.U. 2024 poz. 361 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/361",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20240000361/O/D20240361.pdf",
        "jdg_coverage_pct": "~14%",
        "jdg_rules_package": "jdg.vat.*",
        "key_articles": ["5", "17", "29", "41", "86", "89a", "89b", "90", "106e", "113", "116", "117"]
    },
    "II_pit": {
        "name": "Ustawa o podatku dochodowym od osób fizycznych (PIT)",
        "isap_id": "Dz.U. 2024 poz. 226 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/226",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20240000226/O/D20240226.pdf",
        "jdg_coverage_pct": "~8-10%",
        "jdg_rules_package": "jdg.pit.*",
        "key_articles": ["9", "14", "22", "23", "26", "27", "30c", "30ca", "30da", "30f", "44", "45"]
    },
    "III_ord": {
        "name": "Ordynacja Podatkowa",
        "isap_id": "Dz.U. 2023 poz. 2383 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2023/2383",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20230002383/O/D20232383.pdf",
        "jdg_coverage_pct": "~5-10%",
        "jdg_rules_package": "jdg.liability.*, jdg.compliance.*",
        "key_articles": ["70", "78", "81", "96b", "112", "117", "119"]
    },
    "IV_kks": {
        "name": "Kodeks Karny Skarbowy (KKS)",
        "isap_id": "Dz.U. 2024 poz. 628 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/628",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20240000628/O/D20240628.pdf",
        "jdg_coverage_pct": "~66%",
        "jdg_rules_package": "jdg.kks.*",
        "key_articles": ["16", "44", "51", "54", "56", "57", "60", "61", "62", "63", "64", "68", "69", "76", "77", "79", "83"]
    },
    "V_sus": {
        "name": "Ustawa o systemie ubezpieczeń społecznych (SUS/ZUS)",
        "isap_id": "Dz.U. 2024 poz. 497 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/497",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20240000497/O/D20240497.pdf",
        "jdg_coverage_pct": "~15%",
        "jdg_rules_package": "jdg.zus.*, jdg.sus.*",
        "key_articles": ["6", "8", "9", "18a", "18c", "36a", "47", "81"]
    },
    "VI_ryczalt": {
        "name": "Ustawa o zryczałtowanym podatku dochodowym",
        "isap_id": "Dz.U. 2024 poz. 279 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/279",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20240000279/O/D20240279.pdf",
        "jdg_coverage_pct": "~20%",
        "jdg_rules_package": "jdg.pit.lump_sum.*, jdg.ryczalt.*",
        "key_articles": ["6", "12", "21"]
    },
    "VII_pp": {
        "name": "Prawo Przedsiębiorców",
        "isap_id": "Dz.U. 2024 poz. 236 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/236",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20240000236/O/D20240236.pdf",
        "jdg_coverage_pct": "~10%",
        "jdg_rules_package": "jdg.business.*, jdg.ceidg.*",
        "key_articles": ["5", "22", "23", "24", "25"]
    },
    "VIII_uor": {
        "name": "Ustawa o rachunkowości (UoR)",
        "isap_id": "Dz.U. 2023 poz. 120 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2023/120",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20230000120/O/D20230120.pdf",
        "jdg_coverage_pct": "~0% (martwa warstwa)",
        "jdg_rules_package": "jdg.accounting.*, jdg.uor.*",
        "key_articles": ["26", "27", "28", "30", "39", "45", "74"]
    },
    "IX_pcc_lokalne": {
        "name": "PCC + Podatki i opłaty lokalne + Akcyza",
        "isap_id": "Dz.U. 2023 poz. 1465 t.j.",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2023/1465",
        "rcl_url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/WDU20230001465/O/D20231465.pdf",
        "jdg_coverage_pct": "~1%",
        "jdg_rules_package": "jdg.local_taxes.*, jdg.pcc.*",
        "key_articles": ["1", "3", "4", "5", "7", "9"]
    },
    "X_crossborder": {
        "name": "Cross-border / TP / CFC / ViDA",
        "isap_id": "Dz.U. 2024 poz. 226 (PIT) + Dyrektywy UE",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/226",
        "rcl_url": None,
        "jdg_coverage_pct": "<2%",
        "jdg_rules_package": "jdg.crossborder.*, jdg.tp.*, jdg.mdr.*",
        "key_articles": ["23o", "23zf", "30f", "30da"]
    },
    "XI_ceidg": {
        "name": "CEIDG / Sukcesja / PPK",
        "isap_id": "Dz.U. 2024 poz. 236 (PP) + ustawa o PPK",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/236",
        "rcl_url": None,
        "jdg_coverage_pct": "~10%",
        "jdg_rules_package": "jdg.business.*, jdg.sukcesja.*",
        "key_articles": []
    },
    "XII_zdrowotna": {
        "name": "Zdrowotna + Zasiłkowa",
        "isap_id": "Dz.U. 2024 poz. 497 (SUS) + ustawa o świadczeniach",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/497",
        "rcl_url": None,
        "jdg_coverage_pct": "~15%",
        "jdg_rules_package": "jdg.zus.*, jdg.zdrowotna.*, jdg.zasilkowa.*",
        "key_articles": []
    },
    "XIII_aml_rodo": {
        "name": "AML V / RODO / BDO / SUP / KOBiZE",
        "isap_id": "Dz.U. 2024 poz. 628 (KKS) + RODO + ustawa AML",
        "sejm_api_url": "https://api.sejm.gov.pl/eli/acts/DU/2024/628",
        "rcl_url": None,
        "jdg_coverage_pct": "~5%",
        "jdg_rules_package": "jdg.rodo.*, jdg.aml.*, jdg.environmental.*, jdg.bdo.*",
        "key_articles": []
    }
}

# GitHub configuration (from env vars)
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
GITHUB_REPO = os.environ.get("GITHUB_REPO", "Gorski-Maciej/NexusAI")
GITHUB_API_URL = f"https://api.github.com/repos/{GITHUB_REPO}/issues"

# RCL RSS feed URL (Rządowe Centrum Legislacji)
RCL_RSS_URL = "https://isap.sejm.gov.pl/isap.nsf/rss?openagent"

# Local storage for hashes
CRAWLER_DATA_DIR = Path(os.environ.get("ISAP_DATA_DIR", Path(__file__).parent / ".isap_cache"))
CRAWLER_DATA_DIR.mkdir(parents=True, exist_ok=True)

HASH_STORE_FILE = CRAWLER_DATA_DIR / "isap_hashes.json"


# ═══════════════════════════════════════════════════════════════════════════════
# HASH STORE
# ═══════════════════════════════════════════════════════════════════════════════

class HashStore:
    """Persistent store for ISAP document hashes."""

    def __init__(self, path: Path = HASH_STORE_FILE):
        self.path = path
        self._data = self._load()

    def _load(self) -> dict:
        if self.path.exists():
            return json.loads(self.path.read_text())
        return {}

    def _save(self):
        self.path.write_text(json.dumps(self._data, indent=2, ensure_ascii=False))

    def get_hash(self, act_key: str) -> Optional[str]:
        return self._data.get(act_key, {}).get("hash")

    def set_hash(self, act_key: str, hash_value: str, text_preview: str = ""):
        self._data[act_key] = {
            "hash": hash_value,
            "text_preview": text_preview[:500],
            "crawled_at": datetime.now(timezone.utc).isoformat()
        }
        self._save()

    def get_all_acts(self) -> dict:
        return self._data


# ═══════════════════════════════════════════════════════════════════════════════
# ISAP CRAWLER
# ═══════════════════════════════════════════════════════════════════════════════

class IsapCrawler:
    """
    Crawls ISAP (via Sejm API + RCL RSS) for legal changes affecting 13 acts.

    Architecture:
      1. Sejm API — primary source (open, rate-limited)
      2. RCL RSS — secondary (free, public)
      3. LEX-Polska API — premium (requires subscription)
      4. Selenium fallback — last resort (maintenance overhead)

    Detection method:
      - Fetch today's version of each act
      - Compute SHA-256 hash
      - Compare with yesterday's hash from HashStore
      - If difference → generate diff + create GitHub Issue

    Rate limiting:
      - Sejm API: max 30 req/min (2s delay between requests)
      - RCL RSS: max 60 req/hour
    """

    def __init__(self, hash_store: HashStore, github_token: str = GITHUB_TOKEN):
        self.store = hash_store
        self.github_token = github_token
        self.client = httpx.AsyncClient(
            timeout=30,
            headers={"User-Agent": "NexusAI-ISAP-Crawler/1.0 (+https://github.com/Gorski-Maciej/NexusAI)"}
        )
        self.diffs: list[dict] = []

    async def close(self):
        await self.client.aclose()

    # ── Main crawl loop ─────────────────────────────────────────────────────

    async def crawl_daily_diff(self, act_filter: Optional[str] = None) -> list[dict]:
        """Run once per day; detect changes vs yesterday."""
        self.diffs = []
        acts_to_check = ACTS_TO_MONITOR

        if act_filter:
            acts_to_check = {k: v for k, v in ACTS_TO_MONITOR.items() if act_filter in k}

        logger.info(f"Starting crawl for {len(acts_to_check)} acts...")

        for act_key, act_info in acts_to_check.items():
            try:
                await self._check_act(act_key, act_info)
                await asyncio.sleep(2)  # Rate limiting dla Sejm API
            except Exception as e:
                logger.error(f"Failed to crawl {act_key}: {e}")
                self.diffs.append({
                    "act_key": act_key,
                    "act_name": act_info["name"],
                    "status": "ERROR",
                    "error": str(e)
                })

        return self.diffs

    async def _check_act(self, act_key: str, act_info: dict):
        """Check a single act for changes."""

        # 1. Fetch today's version (Sejm API primary)
        today_text = await self._fetch_act_text(act_key, act_info)

        if not today_text:
            logger.warning(f"No text fetched for {act_key}, falling back to RCL")
            today_text = await self._fetch_rcl_text(act_key, act_info)

        if not today_text:
            logger.warning(f"Could not fetch text for {act_key}, skipping")
            return

        # 2. Compute hash
        today_hash = hashlib.sha256(today_text.encode("utf-8")).hexdigest()

        # 3. Compare with yesterday's hash
        yesterday_hash = self.store.get_hash(act_key)

        if yesterday_hash is None:
            # First crawl — just store
            logger.info(f"[{act_key}] First crawl — storing hash {today_hash[:16]}...")
            self.store.set_hash(act_key, today_hash, today_text[:500])
            self.diffs.append({
                "act_key": act_key,
                "act_name": act_info["name"],
                "status": "INITIAL",
                "hash": today_hash[:16]
            })
            return

        if today_hash == yesterday_hash:
            logger.debug(f"[{act_key}] No changes detected")
            return

        # 4. CHANGE DETECTED — generate diff
        logger.info(f"[{act_key}] CHANGE DETECTED! Hash: {yesterday_hash[:16]} → {today_hash[:16]}")

        diff_text = await self._generate_diff(act_key, today_text)

        self.store.set_hash(act_key, today_hash, today_text[:500])

        change_info = {
            "act_key": act_key,
            "act_name": act_info["name"],
            "status": "CHANGED",
            "old_hash": yesterday_hash[:16],
            "new_hash": today_hash[:16],
            "diff": diff_text,
            "jdg_coverage_pct": act_info["jdg_coverage_pct"],
            "jdg_rules_package": act_info["jdg_rules_package"],
            "key_articles": act_info["key_articles"],
            "detected_at": datetime.now(timezone.utc).isoformat()
        }

        self.diffs.append(change_info)

        # 5. Create GitHub Issue
        await self._create_github_issue(change_info)

    # ── Text fetching ────────────────────────────────────────────────────────

    async def _fetch_act_text(self, act_key: str, act_info: dict) -> Optional[str]:
        """Fetch act text from Sejm API."""
        sejm_url = act_info.get("sejm_api_url")
        if not sejm_url:
            return None

        try:
            # Sejm API: /eli/acts/DU/{year}/{item} returns JSON with act details
            response = await self.client.get(sejm_url)
            response.raise_for_status()
            data = response.json()

            # Extract text from response
            title = data.get("title", "")
            status = data.get("status", "")
            published_date = data.get("publishedDate", "")

            # For full text, use the download URL
            rcl_url = act_info.get("rcl_url")
            if rcl_url:
                text_response = await self.client.get(rcl_url)
                text_response.raise_for_status()
                # For PDF, we'd need OCR; for HTML, extract text
                return f"[{title}] [{status}] [{published_date}]\n{text_response.text[:5000]}"

            return f"[{title}] [{status}] [{published_date}]"

        except httpx.HTTPError as e:
            logger.warning(f"Sejm API error for {act_key}: {e}")
            return None

    async def _fetch_rcl_text(self, act_key: str, act_info: dict) -> Optional[str]:
        """Fallback: fetch from RCL RSS feed."""
        try:
            response = await self.client.get(RCL_RSS_URL)
            response.raise_for_status()
            # RCL RSS is XML — extract relevant entries
            return response.text[:5000]
        except httpx.HTTPError as e:
            logger.warning(f"RCL RSS error: {e}")
            return None

    # ── Diff engine ──────────────────────────────────────────────────────────

    async def _generate_diff(self, act_key: str, new_text: str) -> str:
        """Compare old vs new; return unified diff."""
        old_data = self.store.get_all_acts().get(act_key, {})
        old_text = old_data.get("text_preview", "")

        if not old_text:
            return "[No old text available for comparison]"

        old_lines = old_text.splitlines()
        new_lines = new_text[:5000].splitlines()

        diff_lines = list(difflib.unified_diff(
            old_lines,
            new_lines,
            fromfile=f"{act_key} (OLD)",
            tofile=f"{act_key} (NEW)",
            lineterm="",
            n=3
        ))

        return "\n".join(diff_lines[:200])  # Limit diff size

    # ── GitHub issue creation ────────────────────────────────────────────────

    async def _create_github_issue(self, change_info: dict):
        """Create a GitHub Issue for detected legal change."""
        if not self.github_token:
            logger.warning("No GITHUB_TOKEN set — skipping issue creation")
            return

        act_name = change_info["act_name"]
        jdg_pkg = change_info["jdg_rules_package"]
        articles = ", ".join(f"Art. {a}" for a in change_info.get("key_articles", [])[:5])

        title = f"⚠️ ISAP: Zmiana w {act_name} — {datetime.now().strftime('%Y-%m-%d %H:%M')}"

        body = f"""## ⚠️ Live Legal Radar — Wykryto zmianę w akcie prawnym

**Akt:** {act_name} ({change_info['act_key']})
**Wykryto:** {change_info['detected_at']}
**Hash:** {change_info['old_hash']} → {change_info['new_hash']}

### Wpływ na JDG
- **Pakiet Rego:** `{jdg_pkg}`
- **Pokrycie:** {change_info['jdg_coverage_pct']}
- **Kluczowe artykuły:** {articles}

### Diff (pierwsze 200 linii)
```diff
{change_info['diff'][:3000]}
```

### Wymagane działania
1. [ ] Zweryfikuj zmianę w ISAP (https://isap.sejm.gov.pl)
2. [ ] Zaktualizuj odpowiednie reguły Rego w `{jdg_pkg}`
3. [ ] Dodaj wpis w `_metadata_jdg.rego` → `temporal_validity`
4. [ ] Zaktualizuj progi w `thresholds_jdg.rego` jeśli dotyczy
5. [ ] Dodaj test regresji
6. [ ] Zaktualizuj `legal_cartography` w `_metadata_jdg.rego`

### Auto-wykryte przez
NexusAI C3 Live Legal Radar (ISAP Crawler v1.0)
{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} UTC

---
*Ten issue został automatycznie wygenerowany przez ISAP Crawler.*
*Jeśli to false positive, zamknij z label `auto-detected-false-positive`.*
"""

        headers = {
            "Authorization": f"token {self.github_token}",
            "Accept": "application/vnd.github.v3+json"
        }
        payload = {
            "title": title,
            "body": body,
            "labels": ["legal-change", "auto-detected", "C3-legal-radar"]
        }

        try:
            response = await self.client.post(
                GITHUB_API_URL,
                json=payload,
                headers=headers
            )
            response.raise_for_status()
            issue_url = response.json().get("html_url", "unknown")
            logger.info(f"Created GitHub issue: {issue_url}")
        except httpx.HTTPError as e:
            logger.error(f"Failed to create GitHub issue: {e}")

    # ── Coverage report ─────────────────────────────────────────────────────

    def generate_coverage_report(self) -> str:
        """Generate JDG legal coverage report based on monitored acts."""
        lines = [
            "# NexusAI JDG — Legal Coverage Report",
            f"Generated: {datetime.now().isoformat()}",
            "",
            "| # | Akt prawny | Pokrycie JDG | Status crawla |",
            "|---|-----------|-------------|--------------|"
        ]

        for act_key, act_info in ACTS_TO_MONITOR.items():
            hash_val = self.store.get_hash(act_key)
            status = "✅ Monitorowany" if hash_val else "❌ Nie pobrano"
            lines.append(
                f"| {act_key.split('_')[0]} | {act_info['name']} | "
                f"{act_info['jdg_coverage_pct']} | {status} |"
            )

        return "\n".join(lines)


# ═══════════════════════════════════════════════════════════════════════════════
# DAEMON MODE — Continuous monitoring (co 60 min)
# ═══════════════════════════════════════════════════════════════════════════════

async def daemon_mode(crawler: IsapCrawler):
    """Run crawler continuously every 60 minutes."""
    logger.info("Starting ISAP Crawler in daemon mode (interval: 60 min)")
    while True:
        try:
            logger.info("─" * 60)
            logger.info("Starting crawl cycle...")
            diffs = await crawler.crawl_daily_diff()

            if diffs:
                changes = [d for d in diffs if d.get("status") == "CHANGED"]
                errors = [d for d in diffs if d.get("status") == "ERROR"]
                logger.info(
                    f"Crawl complete: {len(diffs)} acts checked, "
                    f"{len(changes)} changes detected, {len(errors)} errors"
                )
                for change in changes:
                    logger.warning(f"  ⚠️  {change['act_key']}: CHANGE DETECTED")
            else:
                logger.info("Crawl complete: no changes detected")

        except Exception as e:
            logger.error(f"Crawl cycle failed: {e}")

        await asyncio.sleep(3600)  # 60 minutes


# ═══════════════════════════════════════════════════════════════════════════════
# CLI ENTRYPOINT
# ═══════════════════════════════════════════════════════════════════════════════

async def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="NexusAI ISAP Legal Radar Crawler (C3 Strategic Initiative)"
    )
    parser.add_argument(
        "--daemon", action="store_true",
        help="Run in continuous mode (crawl every 60 min)"
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Check for changes without creating GitHub Issues"
    )
    parser.add_argument(
        "--act", type=str, metavar="ACT_KEY",
        help="Check single act only (e.g., 'vat', 'pit', 'kks')"
    )
    parser.add_argument(
        "--report", action="store_true",
        help="Generate coverage report and exit"
    )
    parser.add_argument(
        "--list", action="store_true",
        help="List all monitored acts and exit"
    )

    args = parser.parse_args()

    store = HashStore()
    crawler = IsapCrawler(store)

    try:
        if args.list:
            print("Monitored acts (I-XIII):")
            for key, info in ACTS_TO_MONITOR.items():
                print(f"  {key}: {info['name']} (coverage: {info['jdg_coverage_pct']})")
            return

        if args.report:
            print(crawler.generate_coverage_report())
            return

        if args.daemon:
            await daemon_mode(crawler)
            return

        # Single run
        logger.info("Single crawl mode")
        if args.dry_run:
            # Temporarily disable GitHub token
            crawler.github_token = ""

        diffs = await crawler.crawl_daily_diff(act_filter=args.act)

        # Print summary
        changes = [d for d in diffs if d.get("status") == "CHANGED"]
        initial = [d for d in diffs if d.get("status") == "INITIAL"]
        errors = [d for d in diffs if d.get("status") == "ERROR"]

        print(f"\n{'='*60}")
        print(f"ISAP Crawl Summary — {datetime.now().strftime('%Y-%m-%d %H:%M')}")
        print(f"{'='*60}")
        print(f"Acts checked: {len(diffs)}")
        print(f"Changes detected: {len(changes)}")
        print(f"First crawl: {len(initial)}")
        print(f"Errors: {len(errors)}")

        for change in changes:
            print(f"\n  ⚠️  {change['act_key']}: {change['act_name']}")
            print(f"      Hash: {change['old_hash']} → {change['new_hash']}")
            print(f"      JDG package: {change['jdg_rules_package']}")

        if errors:
            print("\n  Errors:")
            for err in errors:
                print(f"    ❌ {err['act_key']}: {err.get('error', 'unknown')}")

    finally:
        await crawler.close()


if __name__ == "__main__":
    asyncio.run(main())
