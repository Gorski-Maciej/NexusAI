#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI — ScRegulatoryRadar: Automatyczny Monitoring Zmian Legislacyjnych
# ═══════════════════════════════════════════════════════════════════════════════
#
# Faza 1 MVP: Crawler monitorujący zmiany w prawie podatkowym.
# Sprawdza Dzienniki Ustaw, rozporządzenia MF i interpretacje podatkowe.
# Porównuje zmiany z istniejącymi regułami przez _legal_basis.
#
# Pomysł #3 z 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md
#
# Usage:
#   python3 regulatory_radar.py --check
#   python3 regulatory_radar.py --monitor --interval 86400
#   python3 regulatory_radar.py --report
# ═══════════════════════════════════════════════════════════════════════════════

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.request import urlopen, Request
from urllib.error import URLError


# ── Configuration ─────────────────────────────────────────────────────────────

# Akty prawne monitorowane przez Radar
MONITORED_ACTS: Dict[str, str] = {
    "USTAWA_VAT": "ustawa z dnia 11 marca 2004 r. o podatku od towarów i usług",
    "USTAWA_PIT": "ustawa z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych",
    "USTAWA_RYCZALT": "ustawa z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym",
    "USTAWA_SUS": "ustawa z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych",
    "USTAWA_ZDROWOTNE": "ustawa z dnia 27 sierpnia 2004 r. o świadczeniach opieki zdrowotnej",
    "KODEKS_CYWILNY": "ustawa z dnia 23 kwietnia 1964 r. — Kodeks cywilny",
    "ORDYNACJA": "ustawa z dnia 29 sierpnia 1997 r. — Ordynacja podatkowa",
    "PRAWO_PRZEDSIEBIORCOW": "ustawa z dnia 6 marca 2018 r. — Prawo przedsiębiorców",
    "USTAWA_KKS": "ustawa z dnia 10 września 1999 r. — Kodeks karny skarbowy",
    "USTAWA_CEIDG": "ustawa z dnia 6 marca 2018 r. o Centralnej Ewidencji i Informacji o Działalności Gospodarczej",
}

# Źródła do monitorowania
SOURCES: List[Dict] = [
    {
        "name": "ISAP — Dziennik Ustaw",
        "url": "https://isap.sejm.gov.pl/isap.nsf/download.xsp/typeWDU",
        "type": "HTML",
        "parser": "parse_isap",
    },
    {
        "name": "RCL — Rządowe Centrum Legislacji",
        "url": "https://legislacja.gov.pl/",
        "type": "HTML",
        "parser": "parse_rcl",
    },
    {
        "name": "MF — Interpretacje Podatkowe",
        "url": "https://www.podatki.gov.pl/interpretacje-podatkowe/",
        "type": "HTML",
        "parser": "parse_mf_interpretations",
    },
]

# Wzorce do ekstrakcji zmian numerycznych (stawki, progi, limity)
NUMERIC_EXTRACTOR = re.compile(
    r'(?:limit|próg|stawka|kwota|odsetki?)\s+(?:wynosi|wzrasta|maleje|zmienia się)\s+(?:z|od)\s+[\d\s,]+\s*(?:PLN|EUR|%|zł)?\s+(?:do|na)\s+([\d\s,]+)\s*(?:PLN|EUR|%|zł)?',
    re.IGNORECASE
)

ARTICLE_EXTRACTOR = re.compile(
    r'Art\.\s*[\d]+[a-z]?[\s.]*(?:ust\.\s*\d+)?',
    re.IGNORECASE
)


# ── Data Classes ──────────────────────────────────────────────────────────────

class RegulatoryChange:
    """Reprezentuje pojedynczą zmianę legislacyjną."""

    def __init__(
        self,
        source: str,
        title: str,
        date_published: str,
        date_effective: str,
        affected_articles: List[str],
        numeric_changes: List[Dict],
        description: str,
    ):
        self.source = source
        self.title = title
        self.date_published = date_published
        self.date_effective = date_effective
        self.affected_articles = affected_articles
        self.numeric_changes = numeric_changes
        self.description = description

    def to_dict(self) -> Dict:
        return {
            "source": self.source,
            "title": self.title,
            "date_published": self.date_published,
            "date_effective": self.date_effective,
            "affected_articles": self.affected_articles,
            "numeric_changes": self.numeric_changes,
            "description": self.description,
        }


class RuleImpact:
    """Reprezentuje wpływ zmiany legislacyjnej na reguły OPA."""

    def __init__(self, change: RegulatoryChange, affected_rules: List[str]):
        self.change = change
        self.affected_rules = affected_rules
        self.severity = "HIGH" if any("stawka" in c.get("type", "") for c in change.numeric_changes) else "MEDIUM"
        self.action_required = "UPDATE_THRESHOLDS" if change.numeric_changes else "REVIEW_RULES"

    def to_pr_description(self) -> str:
        """Generuje opis Pull Request dla zmiany legislacyjnej."""
        lines = [
            f"## 🤖 Auto-PR: {self.change.title}",
            "",
            f"**Źródło:** {self.change.source}",
            f"**Data publikacji:** {self.change.date_published}",
            f"**Data wejścia w życie:** {self.change.date_effective}",
            f"**Severity:** {self.severity}",
            f"**Akcja:** {self.action_required}",
            "",
            "### Dotknięte reguły:",
        ]
        for rule in self.affected_rules:
            lines.append(f"- `{rule}`")

        if self.change.numeric_changes:
            lines.append("")
            lines.append("### Zmiany numeryczne:")
            for change in self.change.numeric_changes:
                lines.append(f"- {change.get('description', '')}")

        lines.append("")
        lines.append(f"### Opis zmiany:")
        lines.append(self.change.description)

        return "\n".join(lines)


# ── Crawler ───────────────────────────────────────────────────────────────────

class RegulatoryRadar:
    """Monitor zmian legislacyjnych powiązany z regułami OPA."""

    def __init__(self, plan_dir: str = "Plan OPA", rego_dir: str = "policies"):
        self.plan_dir = Path(plan_dir)
        self.rego_dir = Path(rego_dir)
        self.changes: List[RegulatoryChange] = []
        self.rule_map: Dict[str, List[str]] = self._build_rule_map()
        self.checkpoint_file = self.rego_dir / "data" / "radar_checkpoint.json"

    def _build_rule_map(self) -> Dict[str, List[str]]:
        """Buduje mapowanie: artykuł prawny → lista reguł OPA."""
        rule_map: Dict[str, List[str]] = defaultdict(list)

        # Skanuj pliki Rego w poszukiwaniu _legal_basis
        for rego_file in self.rego_dir.glob("**/*.rego"):
            content = rego_file.read_text()
            matches = ARTICLE_EXTRACTOR.findall(content)
            for match in matches:
                article = match.replace(".", "").strip()
                rule_map[article].append(str(rego_file.relative_to(self.rego_dir)))

        return dict(rule_map)

    def check_now(self) -> List[RuleImpact]:
        """Sprawdza zmiany legislacyjne teraz."""
        impacts = []

        for source in SOURCES:
            try:
                changes = self._fetch_and_parse(source)
                for change in changes:
                    affected_rules = self._find_affected_rules(change)
                    if affected_rules:
                        impact = RuleImpact(change, affected_rules)
                        impacts.append(impact)
            except Exception as e:
                print(f"⚠️  Błąd podczas sprawdzania {source['name']}: {e}", file=sys.stderr)

        self.changes = [i.change for i in impacts]
        self._save_checkpoint()
        return impacts

    def _fetch_and_parse(self, source: Dict) -> List[RegulatoryChange]:
        """Pobiera i parsuje źródło legislacyjne. Faza 1: symulacja."""
        # Faza 1 MVP: symulowane dane zamiast rzeczywistego crawlera HTTP
        # W Fazie 2: implementacja rzeczywistego HTTP fetch + parser HTML
        today = datetime.now()
        return [
            RegulatoryChange(
                source=source["name"],
                title="Simulowana zmiana — Faza 1 MVP RegulatoryRadar",
                date_published=today.strftime("%Y-%m-%d"),
                date_effective=(today + timedelta(days=14)).strftime("%Y-%m-%d"),
                affected_articles=["Art. 26h PIT"],
                numeric_changes=[
                    {
                        "type": "limit",
                        "parameter": "thermo_cap",
                        "old_value": 53000,
                        "new_value": 60000,
                        "description": "Limit ulgi termomodernizacyjnej: 53 000 → 60 000 PLN"
                    }
                ],
                description="Symulowana zmiana dla demonstracji RegulatoryRadar. "
                            "W Fazie 2 zastąpiona rzeczywistym crawlingiem RCL/ISAP."
            )
        ]

    def _find_affected_rules(self, change: RegulatoryChange) -> List[str]:
        """Znajduje reguły OPA dotknięte zmianą legislacyjną."""
        affected = set()
        for article in change.affected_articles:
            article_key = article.replace(".", "").strip()
            if article_key in self.rule_map:
                affected.update(self.rule_map[article_key])
        return sorted(affected)

    def monitor(self, interval_seconds: int = 86400) -> None:
        """Ciągły monitoring zmian legislacyjnych."""
        print(f"🔭 RegulatoryRadar — monitoring co {interval_seconds}s...")
        while True:
            impacts = self.check_now()
            if impacts:
                print(f"\n📢 Wykryto {len(impacts)} zmian dotykających reguł OPA:")
                for impact in impacts:
                    print(f"   🔴 {impact.change.title}")
                    print(f"      Dotknięte reguły: {', '.join(impact.affected_rules)}")
                    print(f"      Akcja: {impact.action_required}")

                    # Generuj opis PR
                    pr_desc = impact.to_pr_description()
                    pr_path = self.rego_dir / "data" / f"auto_pr_{impact.change.date_published}.md"
                    pr_path.write_text(pr_desc)
                    print(f"      📁 PR template: {pr_path}")
            else:
                print(".", end="", flush=True)
            time.sleep(interval_seconds)

    def generate_report(self) -> Dict:
        """Generuje raport z monitoringu."""
        return {
            "last_check": datetime.now().isoformat(),
            "acts_monitored": len(MONITORED_ACTS),
            "sources_monitored": len(SOURCES),
            "rules_with_legal_basis": sum(len(v) for v in self.rule_map.values()),
            "recent_changes": [c.to_dict() for c in self.changes[-10:]],
        }

    def _save_checkpoint(self) -> None:
        """Zapisuje checkpoint ostatniego sprawdzenia."""
        self.checkpoint_file.parent.mkdir(parents=True, exist_ok=True)
        checkpoint = {
            "last_check": datetime.now().isoformat(),
            "changes_count": len(self.changes),
        }
        self.checkpoint_file.write_text(json.dumps(checkpoint, indent=2))


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="ScRegulatoryRadar — monitoring zmian legislacyjnych")
    parser.add_argument("--check", action="store_true", help="Sprawdź zmiany teraz")
    parser.add_argument("--monitor", action="store_true", help="Ciągły monitoring")
    parser.add_argument("--interval", type=int, default=86400, help="Interwał monitoringu w sekundach (domyślnie 24h)")
    parser.add_argument("--report", action="store_true", help="Generuj raport")
    parser.add_argument("--plan-dir", default="Plan OPA", help="Katalog z dokumentami planu")
    parser.add_argument("--rego-dir", default="policies", help="Katalog z regułami Rego")
    args = parser.parse_args()

    radar = RegulatoryRadar(plan_dir=args.plan_dir, rego_dir=args.rego_dir)

    if args.check:
        print("🔭 Sprawdzanie zmian legislacyjnych...")
        impacts = radar.check_now()
        if impacts:
            print(f"\n📢 Znaleziono {len(impacts)} zmian dotykających reguł:")
            for impact in impacts:
                print(impact.to_pr_description())
                print("\n---\n")
        else:
            print("✅ Brak zmian dotykających reguł OPA")

    if args.monitor:
        radar.monitor(args.interval)

    if args.report:
        report = radar.generate_report()
        print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
