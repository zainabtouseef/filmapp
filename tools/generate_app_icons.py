"""Generate web, iOS, Android, and store icons from the CineConnect SVG mark.

Requires rsvg-convert and Pillow. Run from any directory with
``python3 tools/generate_app_icons.py``.
"""

from __future__ import annotations

import io
import json
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/branding/cineconnect_app_icon.svg"
RENDER_SIZE = 2048
BACKGROUND = "#070708"


def render_svg(svg: bytes) -> Image.Image:
    result = subprocess.run(
        ["rsvg-convert", "-w", str(RENDER_SIZE), "-h", str(RENDER_SIZE), "-"],
        input=svg,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    return Image.open(io.BytesIO(result.stdout)).convert("RGBA")


def at_size(image: Image.Image, size: int, *, opaque: bool = True) -> Image.Image:
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    if not opaque:
        return resized
    base = Image.new("RGB", (size, size), BACKGROUND)
    base.paste(resized, mask=resized.getchannel("A"))
    return base


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def main() -> None:
    source = SOURCE.read_bytes()
    full = render_svg(source)

    # Android adaptive foreground retains transparency and scales the symbol
    # inside the platform's central safe zone. The background is supplied by XML.
    tree = ET.fromstring(source)
    svg_ns = "{http://www.w3.org/2000/svg}"
    background = tree.find(f"{svg_ns}rect[@id='app-background']")
    mark = tree.find(f"{svg_ns}g[@id='brand-mark']")
    if background is None or mark is None:
        raise ValueError("Icon master is missing its background or brand mark")
    tree.remove(background)
    mark.set("transform", "translate(512 512) scale(0.82) translate(-512 -512)")
    foreground = render_svg(ET.tostring(tree, encoding="utf-8"))

    web = ROOT / "web"
    save(at_size(full, 32), web / "favicon.png")
    save(at_size(full, 180), web / "apple-touch-icon.png")
    for size in (192, 512):
        save(at_size(full, size), web / f"icons/Icon-{size}.png")
        save(at_size(full, size), web / f"icons/Icon-maskable-{size}.png")
    at_size(full, 256).save(
        web / "favicon.ico", format="ICO", sizes=[(16, 16), (32, 32), (48, 48)]
    )

    branding = ROOT / "assets/branding"
    save(at_size(full, 1024), branding / "CineConnect-AppStore-1024.png")
    # Google Play requires a 32-bit PNG with an alpha channel for its listing.
    # Keep the artwork fully opaque while preserving the RGBA channel.
    save(at_size(full, 512).convert("RGBA"), branding / "CineConnect-PlayStore-512.png")

    iconset = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    catalog = json.loads((iconset / "Contents.json").read_text())
    for entry in catalog["images"]:
        if not entry.get("filename"):
            continue
        pixels = round(float(entry["size"].split("x")[0]) * float(entry["scale"].rstrip("x")))
        save(at_size(full, pixels), iconset / entry["filename"])

    android = ROOT / "android/app/src/main/res"
    densities = {
        "mdpi": (48, 108),
        "hdpi": (72, 162),
        "xhdpi": (96, 216),
        "xxhdpi": (144, 324),
        "xxxhdpi": (192, 432),
    }
    # Mask at the high-resolution source before shrinking, for smooth legacy
    # round icons on devices below Android 8.
    circle_mask = Image.new("L", (RENDER_SIZE, RENDER_SIZE), 0)
    ImageDraw.Draw(circle_mask).ellipse((0, 0, RENDER_SIZE - 1, RENDER_SIZE - 1), fill=255)
    legacy_round = full.copy()
    legacy_round.putalpha(circle_mask)
    for density, (legacy_size, adaptive_size) in densities.items():
        directory = android / f"mipmap-{density}"
        save(at_size(full, legacy_size), directory / "ic_launcher.png")
        save(at_size(legacy_round, legacy_size, opaque=False), directory / "ic_launcher_round.png")
        save(at_size(foreground, adaptive_size, opaque=False), directory / "ic_launcher_foreground.png")

    print("Generated CineConnect web, iOS, Android, and store icon assets.")


if __name__ == "__main__":
    main()
