#!/usr/bin/env python3
"""Download the chosen Wikimedia Commons photos for each beach into the app.

Every photo below is CC0, public domain, CC BY or CC BY-SA, so it may be used in the
app as long as the credit (author + license + source) is shown, which the app does.

Run from the project folder:   python3 tool/fetch_photos.py
Writes assets/images/beaches/<slug>-<n>.jpg and the "photos" list of each beach in
assets/data/beaches.json. Safe to run again: existing photos are skipped.
"""
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "data" / "beaches.json"
OUT = ROOT / "assets" / "images" / "beaches"
UA = "ShoreThingApp/0.1 (https://github.com/rishiaggarwal06-afk/shore-thing; beach guide app)"
WIDTH = 1280  # big enough for phones, small enough to keep the app light

# Chosen by hand and checked by eye, first one = main photo. Point Pleasant Beach and
# Beach Haven have none yet: Commons had no suitable freely licensed beach photos
# (only food, a train station or a portrait), so they keep the illustrations.
PHOTOS = {
    "sandy-hook": [
        "File:Sandy Hook Beach at the Gateway National Recreation Area in Highlands, New Jersey.jpg",
        "File:New York City skyline view from Sandy Hook beach NJ.jpg",
        "File:Beach scene at Sandy Hook NJ.JPG",
    ],
    "asbury-park": [
        "File:Asbury Park July 10 Early Morning 01.jpg",
        "File:Asbury Park July 10 Early Morning 02.jpg",
        "File:Asbury Park July 10 Early Morning 16.jpg",
    ],
    "point-pleasant-beach": [
    ],
    "seaside-heights": [
        "File:Seaside Heights beach north of Funtown Pier.JPG",
    ],
    "island-beach-state-park": [
        "File:Island Beach State Park boardwalk.jpg",
        "File:Island Beach State Park sand dunes.jpg",
    ],
    "beach-haven": [
    ],
    "atlantic-city": [
        "File:The beach and boardwalk in Atlantic City.jpg",
        "File:Atlantic City beach view.JPG",
        "File:Atlantic City Beach and Jettty New Jersey.jpg",
    ],
    "ocean-city": [
        "File:Ocean City New Jersey beach patrol boat.jpg",
    ],
    "wildwood": [
        "File:Wildwood New Jersey beach scene with kids playing in the tidal pool.jpg",
        "File:Beaches and hotels at Wildwood New Jersey in early August.jpg",
    ],
    "cape-may": [
        "File:View of Cape May Lighthouse from the beach, near Cape May Point, 2007.jpg",
        "File:Cape May Beach Dusk.jpg",
    ],
    "siesta-key-beach": [
        "File:Siesta Key Beach. Sarasota - panoramio - 4net (3).jpg",
        "File:2017 Sarasota Enormity of Siesta Beach on Siesta Key at Sunset 03 FRD 9744.jpg",
        "File:Siesta Key Beach. Sarasota - panoramio - 4net (6).jpg",
    ],
    "clearwater-beach": [
        "File:Clearwater Beach, Florida (35188097760).jpg",
        "File:Clearwater-beach-florida-pier-60.jpg",
        "File:Clearwater-beach-florida-oceanview.jpg",
    ],
    "south-beach": [
        "File:Lifeguard stand, Miami Beach.jpg",
        "File:Miami Beach - Beach scene.jpg",
        "File:South Beach, Miami Beach, Florida - at the beach, June 2021.jpg",
    ],
    "bahia-honda-state-park": [
        "File:Bahia Honda State Park - Beach with palm trees.jpg",
        "File:Bahia Honda FL beach01.jpg",
        "File:Bahia Honda FL beach03.jpg",
    ],
    "daytona-beach": [
        "File:Driving on Daytona Beach.jpg",
        "File:Daytona Beach Oceanfront Park pano01.jpg",
        "File:Daytona Beach, Florida (4783857222).jpg",
    ],
    "waikiki-beach": [
        "File:Waikiki Beach (2024)-L1004709.jpg",
        "File:Waikiki surfers and sailboats at sunset.jpg",
        "File:The Royal Hawaiian Hotel, Waikiki.jpg",
    ],
    "hanauma-bay": [
        "File:Hanauma Bay, Oahu, Hawaii, USA2.jpg",
        "File:Hanauma Bay View.JPG",
        "File:Hanauma Bay (8701274230).jpg",
    ],
    "lanikai-beach": [
        "File:Lanikai Beach 09.jpg",
        "File:Lanikai Beach 14.jpg",
        "File:Lanikai Beach 22.jpg",
    ],
    "waimea-bay": [
        "File:WaimeaBay.jpg",
        "File:Waimea Bay Sunset.JPG",
        "File:Waimea Bay Oahu Hawaii Photo Don Ramey Logan.jpg",
    ],
    "kailua-beach-park": [
        "File:Kailua Beach lifeguard tower at sunset.jpg",
        "File:Kailua Beach Sunset (9193268473).jpg",
        "File:Kailua Beach Sunset Too (9193276101).jpg",
    ],
}
ALLOWED = re.compile(r"^(CC0|Public domain|PD.*|CC BY(-SA)? [0-9.]+.*)$", re.I)


def fetch(url, as_json=True):
    for attempt in range(6):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=90) as r:
                body = r.read()
            return json.loads(body) if as_json else body
        except Exception as e:  # rate limits and flaky connections: wait and retry
            headers = getattr(e, "headers", None)
            wait = int((headers.get("Retry-After") if headers else 0) or 0) or 10 * (attempt + 1)
            print(f"  waiting {wait}s ({type(e).__name__})", file=sys.stderr)
            time.sleep(wait)
    sys.exit(f"Couldn't download {url}. Check your internet connection and try again.")


def plain(html):
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", html or "")).strip()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    doc = json.loads(DATA.read_text(encoding="utf-8"))
    for beach in doc["beaches"]:
        titles = PHOTOS.get(beach["slug"], [])
        if not titles:
            continue
        info = fetch("https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode({
            "action": "query", "format": "json", "titles": "|".join(titles),
            "prop": "imageinfo", "iiprop": "url|extmetadata", "iiurlwidth": WIDTH,
        }))
        pages = {p["title"]: p for p in info["query"]["pages"].values() if "imageinfo" in p}
        normalized = {n["from"]: n["to"] for n in info["query"].get("normalized", [])}
        photos = []
        for n, title in enumerate(titles, start=1):
            page = pages.get(normalized.get(title, title))
            if not page:
                print(f"  skipped (not found): {title}", file=sys.stderr)
                continue
            ii = page["imageinfo"][0]
            meta = ii.get("extmetadata", {})
            license_name = plain(meta.get("LicenseShortName", {}).get("value"))
            if not ALLOWED.match(license_name):
                print(f"  skipped (license {license_name}): {title}", file=sys.stderr)
                continue
            dest = OUT / f"{beach['slug']}-{n}.jpg"
            if not dest.exists() or dest.stat().st_size == 0:
                url = ii["thumburl"].replace("thumb.wikimedia.org", "upload.wikimedia.org").split("?")[0]
                data = fetch(url, as_json=False)
                dest.write_bytes(data)  # written only after the whole download succeeded
                time.sleep(2)
            photos.append({
                "asset": f"assets/images/beaches/{dest.name}",
                "artist": plain(meta.get("Artist", {}).get("value")) or "Unknown",
                "license": license_name,
                "source": ii["descriptionurl"],
            })
        beach["photos"] = photos
        print(f"{beach['name']}: {len(photos)} photos", file=sys.stderr)
        time.sleep(3)
    DATA.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Updated", DATA, file=sys.stderr)


if __name__ == "__main__":
    main()
