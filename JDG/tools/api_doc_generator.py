#!/usr/bin/env python3
"""
NexusAI JDG — API Documentation Auto-Generator (Innowacja 6)
Parsuje openapi.yaml i generuje docs/api.md z endpointami, schematami i przykładami.

Usage: python api_doc_generator.py [--json]
Output: JDG/docs/api.md
"""

import re
import sys
try:
    import yaml
except ImportError:
    print("❌ PyYAML nie jest zainstalowany. Zainstaluj: pip install pyyaml")
    import sys as _sys
    _sys.exit(1)
from pathlib import Path
from datetime import datetime


JDG_ROOT = Path(__file__).resolve().parent.parent
OPENAPI_PATH = JDG_ROOT / "api" / "openapi.yaml"


def safe_get(d, *keys, default=""):
    """Bezpiecznie pobiera zagnieżdżone wartości."""
    for k in keys:
        if isinstance(d, dict):
            d = d.get(k, {})
        else:
            return default
    return d if d != {} else default


def extract_endpoints(spec: dict) -> list[dict]:
    """Ekstrahuje endpointy z OpenAPI spec."""
    endpoints = []
    for path, methods in spec.get("paths", {}).items():
        for method, details in methods.items():
            if method.upper() in ("GET", "POST", "PUT", "DELETE", "PATCH"):
                endpoints.append({
                    "method": method.upper(),
                    "path": path,
                    "summary": details.get("summary", ""),
                    "description": details.get("description", ""),
                    "operationId": details.get("operationId", ""),
                    "tags": details.get("tags", []),
                    "parameters": details.get("parameters", []),
                    "requestBody": details.get("requestBody", {}),
                    "responses": details.get("responses", {}),
                })
    return sorted(endpoints, key=lambda e: (e["path"], e["method"]))


def extract_schemas(spec: dict) -> list[dict]:
    """Ekstrahuje schematy z OpenAPI spec."""
    schemas = []
    for name, schema in safe_get(spec, "components", "schemas", default={}).items():
        schemas.append({
            "name": name,
            "type": schema.get("type", "object"),
            "required": schema.get("required", []),
            "properties": list(schema.get("properties", {}).keys()),
        })
    return schemas


def generate_api_doc(spec: dict) -> str:
    """Generuje docs/api.md."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    info = spec.get("info", {})
    endpoints = extract_endpoints(spec)
    schemas = extract_schemas(spec)
    servers = spec.get("servers", [])

    lines = [
        f"# 📡 {info.get('title', 'NexusAI JDG API')} — Dokumentacja",
        "",
        f"> **Auto-generowane:** {now} | **Wersja:** {info.get('version', 'N/A')}",
        f"> **Generator:** Innowacja 6 — API Documentation Auto-Generator",
        "",
        info.get("description", "").strip(),
        "",
        "## 🌐 Serwery",
        "",
    ]
    for s in servers:
        lines.append(f"- **{s.get('description', s.get('url', ''))}:** `{s.get('url', '')}`")

    lines.extend(["", f"## 📋 Endpointy ({len(endpoints)})", ""])

    for ep in endpoints:
        method = ep["method"]
        path = ep["path"]
        summary = ep["summary"]
        tags = ", ".join(ep["tags"])

        lines.extend([
            f"### {method} `{path}`",
            "",
            f"**{summary}** | Tagi: {tags} | `operationId: {ep['operationId']}`",
            "",
        ])

        if ep["description"]:
            desc = ep["description"].strip().split("\n")[0][:200]
            lines.append(f"{desc}")

        # Parametry
        if ep["parameters"]:
            lines.extend(["", "**Parametry:**", ""])
            for p in ep["parameters"]:
                required = "✅" if p.get("required") else ""
                schema = p.get("schema", {})
                ptype = schema.get("type", "")
                enum = f" (enum: {', '.join(schema.get('enum', []))})" if schema.get("enum") else ""
                lines.append(f"- `{p['name']}` ({ptype}{enum}) {required} — {p.get('description', '')[:100]}")

        # Request body
        if ep["requestBody"]:
            ref = ""
            content = ep["requestBody"].get("content", {})
            if "application/json" in content:
                schema_ref = safe_get(content["application/json"], "schema", "$ref", default="")
                if schema_ref:
                    ref = schema_ref.split("/")[-1]
            lines.append(f"**Request Body:** `{ref}`")

        # Response codes
        resp_codes = sorted(ep["responses"].keys())
        lines.append(f"**Response codes:** {', '.join(resp_codes)}")
        lines.append("")

    lines.extend(["", "## 📦 Schematy", "", f"Liczba schematów: {len(schemas)}", ""])
    for s in schemas:
        props = ", ".join(f"`{p}`" for p in s["properties"][:10])
        if len(s["properties"]) > 10:
            props += f" +{len(s['properties']) - 10} więcej"
        req = ", ".join(f"`{r}`" for r in s["required"][:5]) if s["required"] else "brak"
        lines.append(f"### `{s['name']}` ({s['type']})")
        lines.append(f"- Wymagane: {req}")
        lines.append(f"- Pola: {props}")
        lines.append("")

    lines.extend(["---", f"*Auto-generowane — {now}*",
                   "*Innowacja 6 — `python JDG/tools/api_doc_generator.py`*"])
    return "\n".join(lines)


def main():
    if not OPENAPI_PATH.exists():
        print(f"❌ Nie znaleziono: {OPENAPI_PATH}")
        return 1

    print("📡 Generowanie dokumentacji API (Innowacja 6)...")
    spec = yaml.safe_load(OPENAPI_PATH.read_text(encoding="utf-8"))

    endpoints = extract_endpoints(spec)
    schemas = extract_schemas(spec)
    print(f"   Endpointów: {len(endpoints)}")
    print(f"   Schematów: {len(schemas)}")

    doc = generate_api_doc(spec)
    output = JDG_ROOT / "docs" / "api.md"
    output.write_text(doc, encoding="utf-8")
    print(f"✅ Dokumentacja API: {output} ({len(doc)} bajtów)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
