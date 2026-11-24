#!/usr/bin/env python3
"""Download small thumbnails of the photo candidates so they can be looked at and picked.

Run from the project folder (after tool/find_photo_candidates.py):
    python3 tool/fetch_photo_thumbs.py
Writes tool/photo_candidates/<beach>/<number>.jpg (250 px wide, about 7 MB in total).
The numbers match the order in tool/photo_candidates.json. Once the photos are picked,
this folder is deleted again. Python standard library only.
"""
import json
import re
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CANDS = ROOT / "tool" / "photo_candidates.json"
OUT = ROOT / "tool" / "photo_candidates"
UA = "ShoreThingApp/0.1 (https://github.com/rishiaggarwal06-afk/shore-thing; beach guide app)"


def get(url):
    for wait in (0, 5, 20, 60):
        time.sleep(wait)
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=60) as r:
                return r.read()
        except Exception as e:  # noqa: BLE001 - retry, then skip this one
            print(f"  retrying ({e})", file=sys.stderr)
    return None


def main():
    cands = json.loads(CANDS.read_text(encoding="utf-8"))
    for slug, cs in cands.items():
        folder = OUT / slug
        folder.mkdir(parents=True, exist_ok=True)
        for i, c in enumerate(cs):
            dest = folder / f"{i}.jpg"
            if dest.exists() and dest.stat().st_size > 0:
                continue
            data = get(re.sub(r"/1280px-", "/250px-", c["image"]))
            if data:
                dest.write_bytes(data)
            time.sleep(0.2)
        print(f"{slug}: done", file=sys.stderr)
    print("Done. Now push: git add -A && git commit -m 'Photo thumbnails' && git push", file=sys.stderr)


if __name__ == "__main__":
    main()
