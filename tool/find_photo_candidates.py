#!/usr/bin/env python3
"""Search Wikimedia Commons for freely licensed photo candidates for beaches that need photos.

Run from the project folder:   python3 tool/find_photo_candidates.py
It writes tool/photo_candidates.json (about 15 candidates per beach: title, license,
photographer, thumbnail and full-size links). Then push it, and the photos get picked
by eye from that list. Nothing is downloaded into the app by this script.

Only searches (no image downloads), uses the Python standard library only, and waits
between requests to be polite to Wikimedia. Takes a few minutes.
"""
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "data" / "beaches.json"
OUT = ROOT / "tool" / "photo_candidates.json"
UA = "ShoreThingApp/0.1 (https://github.com/rishiaggarwal06-afk/shore-thing; beach guide app)"
OK = re.compile(r"^(CC0|Public domain|CC BY(-SA)? \d\.\d( [a-z]{2,3})?)$", re.I)
WANT = 15

# Extra search words that find the right beach (the beach name alone is often ambiguous).
QUERIES = {
    "santa-monica": ["Santa Monica State Beach", "Santa Monica beach pier"],
    "la-jolla-cove": ["La Jolla Cove", "La Jolla Cove beach"],
    "huntington-beach": ["Huntington Beach pier", "Huntington Beach California beach"],
    "grace-bay": ["Grace Bay Providenciales", "Grace Bay beach"],
    "seven-mile-beach": ["Seven Mile Beach Grand Cayman", "Seven Mile Beach Cayman"],
    "eagle-beach": ["Eagle Beach Aruba", "Eagle Beach"],
    "tulum-beach": ["Tulum beach", "Tulum ruins beach"],
    "bavaro-beach": ["Playa Bávaro", "Bavaro beach Punta Cana"],
    "copacabana": ["Copacabana beach Rio", "Praia de Copacabana"],
    "ipanema": ["Ipanema beach", "Praia de Ipanema"],
    "baia-do-sancho": ["Baía do Sancho", "Praia do Sancho Fernando de Noronha"],
    "praia-da-marinha": ["Praia da Marinha", "Marinha beach Algarve"],
    "praia-do-camilo": ["Praia do Camilo", "Camilo beach Lagos"],
    "la-concha": ["Playa de La Concha San Sebastián", "La Concha beach"],
    "navagio": ["Navagio", "Navagio beach Zakynthos"],
    "elafonissi": ["Elafonissi", "Elafonisi beach Crete"],
    "myrtos": ["Myrtos beach", "Myrtos Kefalonia"],
    "spiaggia-dei-conigli": ["Spiaggia dei Conigli", "Isola dei Conigli Lampedusa"],
    "maya-bay": ["Maya Bay", "Maya Bay Phi Phi"],
    "railay-west": ["Railay West beach", "Railay beach"],
    "kuta-beach": ["Kuta Beach Bali", "Kuta beach"],
    "white-beach-boracay": ["White Beach Boracay", "Boracay beach"],
    "bondi-beach": ["Bondi Beach", "Bondi Beach Sydney"],
    "manly-beach": ["Manly Beach", "Manly beach Sydney"],
    "whitehaven-beach": ["Whitehaven Beach", "Whitehaven Beach Whitsunday"],
    "byron-bay": ["Byron Bay Main Beach", "Byron Bay beach"],
    "anse-source-dargent": ["Anse Source d'Argent", "Anse Source d'Argent La Digue"],
    "anse-lazio": ["Anse Lazio", "Anse Lazio Praslin"],
    "camps-bay": ["Camps Bay beach", "Camps Bay Cape Town"],
    "boulders-beach": ["Boulders Beach penguins", "Boulders Beach Simon's Town"],
}


def get(params):
    url = "https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode(params)
    for wait in (0, 10, 30, 60):
        time.sleep(wait)
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=60) as r:
                return json.load(r)
        except Exception as e:  # noqa: BLE001 - retry anything, then give up on this search
            print(f"  retrying ({e})", file=sys.stderr)
    return None


def plain(html):
    return re.sub(r"<[^>]+>", "", html or "").strip()


def main():
    beaches = json.loads(DATA.read_text(encoding="utf-8"))["beaches"]
    out = json.loads(OUT.read_text(encoding="utf-8")) if OUT.exists() else {}
    todo = [b for b in beaches if not b.get("photos") and b["slug"] not in out]
    print(f"Searching photos for {len(todo)} beaches…", file=sys.stderr)
    for b in todo:
        seen, cands = set(), []
        for q in QUERIES.get(b["slug"], [b["name"]]):
            d = get({
                "action": "query", "format": "json", "generator": "search", "gsrnamespace": 6,
                "gsrsearch": q + " filetype:bitmap", "gsrlimit": 40, "prop": "imageinfo",
                "iiprop": "url|extmetadata|size", "iiextmetadatafilter": "LicenseShortName|Artist",
                "iiurlwidth": 1280,
            })
            time.sleep(2)
            pages = sorted((d or {}).get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 0))
            for p in pages:
                ii = p["imageinfo"][0]
                meta = ii.get("extmetadata", {})
                lic = plain(meta.get("LicenseShortName", {}).get("value"))
                title = p["title"]
                if title in seen or not OK.match(lic) or not title.lower().endswith((".jpg", ".jpeg")):
                    continue
                if ii["width"] < 1200 or ii["width"] < ii["height"] * 1.2:  # big enough, landscape
                    continue
                seen.add(title)
                cands.append({
                    "title": title,
                    "license": lic,
                    "artist": plain(meta.get("Artist", {}).get("value")) or "Unknown",
                    "source": ii["descriptionurl"],
                    "image": ii["thumburl"].split("?")[0].replace("thumb.wikimedia.org", "upload.wikimedia.org"),
                })
                if len(cands) >= WANT:
                    break
            if len(cands) >= WANT:
                break
        out[b["slug"]] = cands
        print(f"{b['name']}: {len(cands)} candidates", file=sys.stderr)
        OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")  # save as we go
    print(f"Done. Wrote {OUT.relative_to(ROOT)}. Now push it: git add -A && git commit -m 'Photo candidates' && git push",
          file=sys.stderr)


if __name__ == "__main__":
    main()
