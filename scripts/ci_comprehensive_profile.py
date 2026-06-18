#!/usr/bin/env python3
"""CI wrapper for comprehensive profiling.

Called from .github/workflows/profiling-ci.yml.
Avoids inline Python in YAML which confuses the parser.
"""
import anyio
import json
import sys

from nexus_ai.scripts.profiler import generate_comprehensive_profile


async def main() -> None:
    pid = int(sys.argv[1])
    duration = int(sys.argv[2])
    output_dir = sys.argv[3]
    native = sys.argv[4].lower() == "true"
    gil = sys.argv[5].lower() == "true"
    sha = sys.argv[6]

    report = await generate_comprehensive_profile(
        pid=pid,
        duration=duration,
        output_dir=output_dir,
        tags={"ci": "true", "sha": sha},
        native=native,
        gil=gil,
    )
    path = f"{output_dir}/comprehensive_{sha[:7]}.json"
    with open(path, "w") as f:
        json.dump(report.to_dict(), f, indent=2, default=str)
    print(f"✅ Comprehensive profile saved to {path}")


anyio.run(main())
