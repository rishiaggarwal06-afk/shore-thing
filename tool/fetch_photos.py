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

# Chosen by hand and checked by eye, first one = main photo. Beach Haven has none yet:
# Commons had no suitable freely licensed beach photos (only old postcards and street
# scenes), so it keeps the illustrations.
# Photographer names that Commons' machine-readable data gets wrong, checked by hand
# on each file's page (the licenses require the real name).
ARTIST_FIX = {
    "File:Bondi Beach in January 2023.jpg": "Marcus Grbac",
    "File:Point Pleasant Beach boardw.jpg": "Leif Knutsen",
    "File:Ruby's, Huntington Beach pier, California.jpg": "Mike Peel",
    "File:Isola dei Conigli.JPG": "Ezio55",
    "File:Manly Beach.jpg": "Enochlau",
}

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
        "File:Point Pleasant Beach boardw.jpg",
        "File:Point Pleasant Beach north of Jenkinson's Aquarium.jpg",
        "File:Bay Head and Point Pleasant Beach from over the Atlantic, August 2025 (Aerial).jpg",
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
    "santa-monica": [
        "File:Los Angeles (California, USA), Santa Monica Beach -- 2012 -- 5301.jpg",
        "File:Santa Monica – Lifeguard tower (narrow) 2017.jpg",
        "File:Santa Monica Pier from Santa Monica State Beach 03.jpg",
    ],
    "la-jolla-cove": [
        "File:La Jolla Cove, San Diego.jpg",
        "File:La Jolla Cove from the south.JPG",
        "File:California sea lion in La Jolla (70568).jpg",
    ],
    "huntington-beach": [
        "File:Huntington Beach Municipal Pier - 89001203.jpg",
        "File:Surfer at Huntington Beach Pier.jpg",
        "File:Ruby's, Huntington Beach pier, California.jpg",
    ],
    "grace-bay": [
        "File:Grace Bay - panoramio.jpg",
        "File:Turks and Caicos (45316031582).jpg",
        "File:Turks and Caicos (43864066082).jpg",
    ],
    "seven-mile-beach": [
        "File:Seven Mile Beach Facing North.jpg",
        "File:Resorts on Seven Mile Beach, Grand Cayman.jpg",
        "File:Seven Mile Beach Facing West.jpg",
    ],
    "eagle-beach": [
        "File:Mangrove tree (Conocarpus erectus) Aruba Eagle Beach (2896882763).jpg",
        "File:Eagle Beach, Aruba 1.jpg",
        "File:Eagle beach Passions On The Beach Noord Aruba.jpg",
    ],
    "tulum-beach": [
        "File:Tulum - God of the Winds Temple 03.JPG",
        "File:Tulum Beach, Quintana Roo, Mexico.jpg",
        "File:Maya ruins at Tulum 2023 - beach.jpg",
    ],
    "bavaro-beach": [
        "File:Playa Bavaro.JPG",
        "File:Playa Bavaro 293.jpg",
        "File:2023 - Playa Bavaro Punta Cana - 11.jpg",
    ],
    "copacabana": [
        "File:Rio de janeiro copacabana beach 2010.JPG",
        "File:Copacabana Sunny Day -) - panoramio.jpg",
        "File:Copacabana beach (40486873483).jpg",
    ],
    "ipanema": [
        "File:Praia de Ipanema e Leblon vista da Pedra do Arpoador.jpg",
        "File:1 ipanema beach vidigal sunset.jpg",
        "File:Ipanema Beach Rio.jpg",
    ],
    "baia-do-sancho": [
        "File:Baía do sancho e vegetação.jpg",
        "File:Baía do Sancho vista do alto.JPG",
        "File:PE - Parque Nacional Marinho de Fernando de Noronha - Baía do Sancho - Praia do Sancho.jpg",
    ],
    "praia-da-marinha": [
        "File:Praia da Marinha 2017.jpg",
        "File:Praia da Marinha-Algarve-Portugal.jpg",
        "File:Praia da Marinha Tor.JPG",
    ],
    "praia-do-camilo": [
        "File:Praia do camilo (48454069281).jpg",
        "File:Praia do Camilo (48608303172).jpg",
        "File:Praia do Camilo (48471577097).jpg",
    ],
    "la-concha": [
        "File:San Sebastian Kontxa beach 1190650.jpg",
        "File:San Sebastian Kontxa beach 190363.jpg",
        "File:San Sebastian Playa de La Concha 06 2012 2505.jpg",
    ],
    "navagio": [
        "File:Navagio, Zante 01.jpg",
        "File:Navagio Beach aerial Zakynthos Greece (46470564281).jpg",
        "File:Panagiotis Shipwreck at Navagio Beach Zakynthos Greece (31530321957).jpg",
    ],
    "elafonissi": [
        "File:Ελαφονήσι 1275.jpg",
        "File:Elafonissi - panoramio (1).jpg",
        "File:Ελαφονήσι 8547.jpg",
    ],
    "myrtos": [
        "File:Myrtos Beach 5 (9344634826).jpg",
        "File:Myrtos Beach, Kefalonia.jpg",
        "File:Myrtos Beach 2 (9341821409).jpg",
    ],
    "spiaggia-dei-conigli": [
        "File:Isola dei Conigli.JPG",
        "File:SPIAGGIA DEI CONIGLI LAMPEDUSA 1.jpg",
        "File:Isola e spiaggia di Coniglie-Lampedusa.JPG",
    ],
    "maya-bay": [
        "File:Maya Bay, Koh Phi Phi, Krabi, Thailand.jpg",
        "File:Maya Bay enclosed limestone cliffs and turquoise water Ko Phi Phi Le.jpg",
        "File:Playa Maya, Ko Phi Phi, Tailandia, 2013-08-19, DD 13.JPG",
    ],
    "railay-west": [
        "File:Railay Beach 5.jpg",
        "File:Krabi, Railay West Beach (6218118271).jpg",
        "File:West Railay Beach 03.jpg",
    ],
    "kuta-beach": [
        "File:Kuta Beach, Bali, 20220827 0842 1083.jpg",
        "File:Jerman Beach, Kuta, Bali, Indonesia, 20220825 1207 0816.jpg",
        "File:Sunset, Kuta, Bali, Indonesia, 20220825 1752 0877.jpg",
    ],
    "white-beach-boracay": [
        "File:Boracay White Beach - panoramio - Tuderna.jpg",
        "File:\"White Beach\" Boracay, Philippinen.jpg",
        "File:Boracay White Beach in day (985286231).jpg",
    ],
    "bondi-beach": [
        "File:Sydney (AU), Bondi Beach -- 2019 -- 2354.jpg",
        "File:Bondi Beach, southwest view 20230224 2.jpg",
        "File:Bondi Beach in January 2023.jpg",
    ],
    "manly-beach": [
        "File:2020-10-24 Manly Beach 8.jpg",
        "File:Manly Beach.jpg",
        "File:2020-10-24 Manly Beach 6.jpg",
    ],
    "whitehaven-beach": [
        "File:Whitsunday Island - Whitehaven Beach 05.jpg",
        "File:DSC122 Australia Queensland Whitsunday Islands Whitehaven bay (5491401519).jpg",
        "File:North of Whitehaven Beach - panoramio (2).jpg",
    ],
    "byron-bay": [
        "File:Main Beach and Cape Byron, Byron Bay, New South Wales, Australia (Ank Kumar, Infosys Limited) 02.jpg",
        "File:Main Beach and Cape Byron, Byron Bay, New South Wales, Australia (Ank Kumar, Infosys Limited) 05.jpg",
        "File:Main Beach and Cape Byron, Byron Bay, New South Wales, Australia (Ank Kumar, Infosys Limited) 04.jpg",
    ],
    "anse-source-dargent": [
        "File:Anse Source d'Argent 2-La Digue.jpg",
        "File:Anse Source d'Argent - La Digue - Seychelles - 03.jpg",
        "File:Anse Source d'Argent 3-La Digue.jpg",
    ],
    "anse-lazio": [
        "File:Anse Lazio-rama 2015.JPG",
        "File:Anse Lazio-Praslin-Seychellen.jpg",
        "File:Anse Lazio beach Praslin Seychelles.jpg",
    ],
    "camps-bay": [
        "File:Camps Bay beach 6.jpg",
        "File:Camps Bay Beach ..., Cape Town.jpg",
        "File:Camps Bay Beach at sunset 04.jpg",
    ],
    "boulders-beach": [
        "File:Penguins at Boulders Beach 04.jpg",
        "File:Simon’s Town (ZA), Boulders Beach, Penguin Colony -- 2024 -- 3420.jpg",
        "File:Penguins at Boulders Beach 2018 05.jpg",
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
                "artist": ARTIST_FIX.get(title, plain(meta.get("Artist", {}).get("value")) or "Unknown"),
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
