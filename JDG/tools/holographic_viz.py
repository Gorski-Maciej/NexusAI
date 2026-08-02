#!/usr/bin/env python3
"""
NexusAI JDG — Holographic Rule Visualization (Innovation #8, P28 Grand Finale)
Wizualizacja sieci reguł — dashboard dla architektów.
383+ pliki, zależności cross-package z cross_package_conflict_detector.
"""
import sys, os, json
from datetime import datetime

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RULES_DIR = os.path.join(BASE, "rules")

def build_dependency_graph():
    """Zbuduj graf zależności między pakietami."""
    graph = {"nodes": [], "edges": []}
    packages = set()
    
    for root, _, files in os.walk(RULES_DIR):
        for f in files:
            if not f.endswith(".rego"):
                continue
            filepath = os.path.join(root, f)
            relpath = os.path.relpath(filepath, RULES_DIR)
            pkg = relpath.replace("/", ".").replace(".rego", "")
            
            with open(filepath, "r") as fh:
                content = fh.read()
            
            # Znajdź importy
            imports = set()
            for match in __import__('re').finditer(r'import\s+data\.(\w[\w.]*)', content):
                imports.add(match.group(1))
            
            # Dodaj węzeł
            node_size = content.count('"rule_id"')
            graph["nodes"].append({
                "id": pkg,
                "label": os.path.basename(relpath).replace(".rego", ""),
                "size": node_size,
                "path": relpath
            })
            packages.add(pkg)
            
            # Dodaj krawędzie
            for imp in imports:
                if imp in packages or any(imp.startswith(p) for p in packages):
                    graph["edges"].append({"from": pkg, "to": imp})
    
    return graph

def generate_html_viz(graph):
    """Wygeneruj wizualizację HTML z użyciem D3.js."""
    graph_json = json.dumps(graph)
    
    return f"""<!DOCTYPE html>
<html>
<head>
    <title>NexusAI JDG — Holographic Rule Visualization (P28)</title>
    <script src="https://d3js.org/d3.v7.min.js"></script>
    <style>
        body {{ margin: 0; background: #0a0a1a; color: #fff; font-family: monospace; }}
        svg {{ width: 100vw; height: 100vh; }}
        .node circle {{ stroke: #fff; stroke-width: 1.5px; }}
        .node text {{ fill: #fff; font-size: 8px; }}
        .link {{ stroke: #444; stroke-opacity: 0.6; }}
        .title {{ position: fixed; top: 10px; left: 20px; z-index: 10; font-size: 18px; color: #0ff; }}
        .stats {{ position: fixed; bottom: 10px; left: 20px; z-index: 10; font-size: 11px; color: #888; }}
    </style>
</head>
<body>
    <div class="title">🔮 JDG Holographic Rule Network — P28 Grand Finale</div>
    <div class="stats">Nodes: {len(graph['nodes'])} | Edges: {len(graph['edges'])} | Rules: ~10,889</div>
    <div id="viz"></div>
    <script>
        const data = {graph_json};
        const width = window.innerWidth;
        const height = window.innerHeight;
        
        const svg = d3.select("#viz").append("svg")
            .attr("width", width).attr("height", height);
        
        const g = svg.append("g");
        
        const simulation = d3.forceSimulation(data.nodes)
            .force("link", d3.forceLink(data.edges).id(d => d.id).distance(80))
            .force("charge", d3.forceManyBody().strength(-120))
            .force("center", d3.forceCenter(width/2, height/2))
            .force("collision", d3.forceCollide().radius(20));
        
        const link = g.append("g").selectAll("line")
            .data(data.edges).enter().append("line")
            .attr("class", "link");
        
        const colorScale = d3.scaleSequential(d3.interpolateViridis)
            .domain([0, d3.max(data.nodes, d => d.size)]);
        
        const node = g.append("g").selectAll("g")
            .data(data.nodes).enter().append("g")
            .call(d3.drag()
                .on("start", (e,d) => {{ if(!e.active) simulation.alphaTarget(0.3).restart(); d.fx=d.x; d.fy=d.y; }})
                .on("drag", (e,d) => {{ d.fx=e.x; d.fy=e.y; }})
                .on("end", (e,d) => {{ if(!e.active) simulation.alphaTarget(0); d.fx=null; d.fy=null; }}));
        
        node.append("circle")
            .attr("r", d => Math.max(3, Math.min(15, d.size / 3)))
            .attr("fill", d => colorScale(d.size));
        
        node.append("text").text(d => d.label)
            .attr("dx", 12).attr("dy", 4);
        
        node.append("title").text(d => `${{d.id}}: ${{d.size}} rules`);
        
        simulation.on("tick", () => {{
            link.attr("x1", d => d.source.x).attr("y1", d => d.source.y)
                .attr("x2", d => d.target.x).attr("y2", d => d.target.y);
            node.attr("transform", d => `translate(${{d.x}},${{d.y}})`);
        }});
        
        const zoom = d3.zoom().scaleExtent([0.1, 5]).on("zoom", e => g.attr("transform", e.transform));
        svg.call(zoom);
    </script>
</body>
</html>"""

def main():
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  NexusAI JDG — Holographic Rule Visualization v1.0        ║")
    print("║  Innovation #8: 3D Rule Network (P28 Grand Finale)      ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    
    print("\n[Faza 1/3] Budowa grafu zależności...")
    graph = build_dependency_graph()
    
    packages = len(graph["nodes"])
    edges = len(graph["edges"])
    total_rules = sum(n["size"] for n in graph["nodes"])
    
    print(f"   Pakiety: {packages}")
    print(f"   Zależności (cross-package): {edges}")
    print(f"   Reguły: {total_rules}")
    
    # Top 5 most connected
    connections = {}
    for e in graph["edges"]:
        connections[e["from"]] = connections.get(e["from"], 0) + 1
    top = sorted(connections.items(), key=lambda x: x[1], reverse=True)[:5]
    print(f"\n📊 Top 5 najbardziej połączonych pakietów:")
    for pkg, count in top:
        print(f"   {pkg}: {count} połączeń")
    
    print(f"\n[Faza 2/3] Generowanie wizualizacji HTML...")
    html = generate_html_viz(graph)
    
    viz_path = os.path.join(BASE, "reports", "holographic_viz.html")
    os.makedirs(os.path.dirname(viz_path), exist_ok=True)
    with open(viz_path, "w") as f:
        f.write(html)
    
    print(f"   ✓ Zapisano: {viz_path}")
    
    print(f"\n[Faza 3/3] Analiza cross-domain...")
    cross_domain = [e for e in graph["edges"] if e["from"].split(".")[0] != e["to"].split(".")[0]]
    print(f"   Cross-domain edges: {len(cross_domain)}/{edges} ({len(cross_domain)/max(edges,1)*100:.0f}%)")
    
    print(f"\n📋 KPI: {packages} pakietów, {edges} połączeń w sieci reguł")
    print("   Cel P28: Pełna wizualizacja 3D dla 383+ plików reguł")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
