"""
NexusAI — Central Application Entry Point
==========================================

Simply imports and runs the main application from the ``nexus_ai`` package.
Use ``python main.py`` from the project root, or install via pip:
    pip install -e .
    nexus-api   # starts the Granian server
"""

from nexus_ai.main import main

if __name__ == "__main__":
    raise SystemExit(main())
