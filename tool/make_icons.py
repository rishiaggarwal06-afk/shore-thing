#!/usr/bin/env python3
"""Make every app icon size from one 1024×1024 image.

Usage (from the project folder):
    python3 tool/make_icons.py                      # uses assets/images/brand/app-icon-1024.png
    python3 tool/make_icons.py ~/Desktop/my-logo.png  # uses your own design (and saves it as the new master)

Your image should be a square PNG, 1024×1024, with no transparency and square corners
(the iPhone rounds the corners itself). Needs Pillow:  pip3 install pillow
"""
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / "assets" / "images" / "brand" / "app-icon-1024.png"


def main():
    src_path = Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else MASTER
    src = Image.open(src_path)
    if src.size[0] != src.size[1]:
        sys.exit(f"The icon must be square; yours is {src.size[0]}×{src.size[1]}.")
    if src.mode in ("RGBA", "LA", "P"):
        # Apple rejects see-through icons: put the image on a solid background.
        bg = Image.new("RGB", src.size, "#FFE14D")
        bg.paste(src.convert("RGBA"), mask=src.convert("RGBA").split()[-1])
        src = bg
    src = src.convert("RGB").resize((1024, 1024), Image.LANCZOS)
    src.save(MASTER)

    count = 0

    def write(path, size):
        nonlocal count
        src.resize((size, size), Image.LANCZOS).save(path)
        count += 1

    icons = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for img in json.loads((icons / "Contents.json").read_text())["images"]:
        if "filename" in img:
            points = float(img["size"].split("x")[0])
            write(icons / img["filename"], round(points * int(img["scale"][0])))
    for name, size in [("icons/Icon-192.png", 192), ("icons/Icon-512.png", 512),
                       ("icons/Icon-maskable-192.png", 192), ("icons/Icon-maskable-512.png", 512),
                       ("favicon.png", 32)]:
        write(ROOT / "web" / name, size)
    for folder, size in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
        path = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{folder}" / "ic_launcher.png"
        if path.exists():
            write(path, size)
    print(f"Wrote {count} icon files from {src_path}")


if __name__ == "__main__":
    main()
