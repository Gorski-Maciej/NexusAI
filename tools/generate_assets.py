"""
generate_assets.py — Generate Windows icon files (.ico, .png) from the SVG logo.

Usage:
    python tools/generate_assets.py                  # Generate all assets
    python tools/generate_assets.py --force-png      # Force Pillow rendering (no cairosvg)

Requires:
    pip install Pillow            # Required for ICO conversion
    pip install cairosvg Pillow   # For SVG→PNG conversion (optional, fallback to Pillow)
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ASSETS_DIR = PROJECT_ROOT / "assets"
SVG_PATH = ASSETS_DIR / "logo.svg"
ICO_PATH = ASSETS_DIR / "nexus.ico"
PNG_PATH = ASSETS_DIR / "nexus.png"
SPLASH_PNG_PATH = ASSETS_DIR / "logo_splash.png"


def _has_cairosvg() -> bool:
    try:
        import cairosvg  # noqa: F401
        return True
    except ImportError:
        return False


def generate_png_with_cairosvg(size: int = 256) -> bool:
    """Convert SVG to PNG using cairosvg."""
    try:
        import cairosvg

        print(f"  Converting SVG → PNG ({size}x{size})...")
        cairosvg.svg2png(
            url=str(SVG_PATH),
            write_to=str(PNG_PATH),
            output_width=size,
            output_height=size,
        )
        print(f"    ✓ Created: {PNG_PATH.name} ({PNG_PATH.stat().st_size / 1024:.0f} KB)")
        return True
    except Exception as e:
        print(f"    ✗ cairosvg failed: {e}")
        return False


def generate_png_with_pillow(size: int = 256) -> bool:
    """Render the nexus logo using Pillow drawing primitives (no cairosvg needed)."""
    try:
        from PIL import Image, ImageDraw

        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        center = size // 2
        r_outer = center - 8
        r_inner = int(r_outer * 0.55)

        # Outer ring
        for i in range(r_outer - 3, r_outer + 1):
            draw.ellipse(
                [center - i, center - i, center + i, center + i],
                outline=(0, 180, 216, 180 - (r_outer - i) * 40),
            )

        # Inner ring
        for i in range(r_inner - 2, r_inner + 1):
            draw.ellipse(
                [center - i, center - i, center + i, center + i],
                outline=(0, 180, 216, 150 - (r_inner - i) * 30),
            )

        # Connection lines
        dist = r_outer - 15
        for dx, dy in [(0, -dist), (0, dist), (-dist, 0), (dist, 0)]:
            steps = int(dist / 4)
            for i in range(steps):
                x1 = center + int(dx * i / steps)
                y1 = center + int(dy * i / steps)
                x2 = center + int(dx * (i + 1) / steps)
                y2 = center + int(dy * (i + 1) / steps)
                draw.line([x1, y1, x2, y2], fill=(0, 180, 216, 60), width=2)

        # Outer node circles
        for dx, dy in [(0, -dist), (0, dist), (-dist, 0), (dist, 0)]:
            for r in range(2, 7):
                fill = (0, 180 + (6 - r) * 10, 216, 200 - (6 - r) * 30)
                draw.ellipse(
                    [center + dx - r, center + dy - r, center + dx + r, center + dy + r],
                    fill=fill,
                )

        # Center node (accent color)
        for r in range(3, 11):
            g = int(214 - (10 - r) * 10)
            b = int(160 - (10 - r) * 8)
            draw.ellipse(
                [center - r, center - r, center + r, center + r],
                fill=(6, g, b, 255 - (10 - r) * 20),
            )

        # Small connection dots on inner ring
        inner_r2 = int(r_inner * 0.8)
        for angle in [45, 135, 225, 315]:
            rad = angle * math.pi / 180
            dx = int(inner_r2 * math.cos(rad))
            dy = int(inner_r2 * math.sin(rad))
            for r in range(1, 3):
                draw.ellipse(
                    [center + dx - r, center + dy - r, center + dx + r, center + dy + r],
                    fill=(0, 180, 216, 150 - r * 30),
                )

        img.save(str(PNG_PATH))
        print(f"    ✓ Created: {PNG_PATH.name} ({PNG_PATH.stat().st_size / 1024:.0f} KB)")
        return True

    except Exception as e:
        print(f"    ✗ Pillow rendering failed: {e}")
        return False


def generate_ico(sizes: list[int] | None = None) -> bool:
    """Convert PNG to multi-size ICO."""
    try:
        from PIL import Image

        if not PNG_PATH.exists():
            print(f"    ✗ Source PNG not found: {PNG_PATH}")
            return False

        sizes = sizes or [16, 32, 48, 64, 128, 256]
        img = Image.open(PNG_PATH)
        ico_images = [img.resize((s, s), Image.LANCZOS) for s in sizes]

        ico_images[0].save(
            str(ICO_PATH),
            format="ICO",
            sizes=[(s, s) for s in sizes],
            append_images=ico_images[1:],
        )
        print(f"    ✓ Created: {ICO_PATH.name} ({ICO_PATH.stat().st_size / 1024:.0f} KB)")
        return True
    except Exception as e:
        print(f"    ✗ ICO generation failed: {e}")
        return False


def generate_splash_png() -> bool:
    """Generate a smaller splash screen logo (150x150)."""
    try:
        from PIL import Image

        if not PNG_PATH.exists():
            print(f"    ✗ Source PNG not found: {PNG_PATH}")
            return False

        img = Image.open(PNG_PATH)
        splash = img.resize((150, 150), Image.LANCZOS)
        splash.save(str(SPLASH_PNG_PATH))
        print(f"    ✓ Created: {SPLASH_PNG_PATH.name} ({SPLASH_PNG_PATH.stat().st_size / 1024:.0f} KB)")
        return True
    except Exception as e:
        print(f"    ✗ Splash generation failed: {e}")
        return False


def main() -> int:
    print("=" * 60)
    print("  NexusAI Asset Generator")
    print("=" * 60)
    print()

    ASSETS_DIR.mkdir(parents=True, exist_ok=True)

    if not SVG_PATH.exists():
        print(f"[!] SVG logo not found: {SVG_PATH}")
        # The existing logo.svg should be present; if not, the Pillow fallback handles it
        print("    Using Pillow renderer (no SVG needed)")

    # Step 1: Generate PNG
    print("[1/3] Generating PNG icon (256×256)...")
    png_ok = False
    if _has_cairosvg():
        png_ok = generate_png_with_cairosvg()
    if not png_ok:
        print("  (using Pillow renderer)")
        png_ok = generate_png_with_pillow()

    # Step 2: Generate splash
    print("\n[2/3] Generating splash logo (150×150)...")
    if png_ok:
        generate_splash_png()

    # Step 3: Generate ICO
    print("\n[3/3] Generating Windows ICO (16→256)...")
    if png_ok:
        generate_ico()
    else:
        print("    ✗ Cannot generate ICO without PNG")

    # Summary
    print("\n" + "=" * 60)
    print("  Summary")
    print("=" * 60)
    all_ok = True
    for path in [ICO_PATH, PNG_PATH, SPLASH_PNG_PATH]:
        exists = path.exists()
        size_kb = path.stat().st_size / 1024 if exists else 0
        status = f"✓ {size_kb:.0f} KB" if exists else "✗ MISSING"
        if not exists:
            all_ok = False
        print(f"  {path.name:25s} {status}")

    print()
    if all_ok:
        print("All assets generated successfully.")
    else:
        print("Some assets could not be generated.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
