#!/usr/bin/env python3
"""Find local businesses near each beach that publish a contact email, for partner outreach.

Run from the project folder:   python3 tool/find_businesses.py
Writes (into tool/outreach/, which git ignores, so the list never goes public):
  businesses.csv   every business picked, 5 per beach where possible
  group_A.csv      half of them (email WITHOUT a price)
  group_B.csv      the other half (email WITH the $12/month price)

Source: OpenStreetMap (via the Overpass API). Only businesses whose OSM entry lists an
email address are used, i.e. addresses the business itself has made public. Each row
links to the OSM entry so you can double-check it. Takes about 5–10 minutes.
Python standard library only.
"""
import csv
import json
import math
import random
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "data" / "beaches.json"
OUT = ROOT / "tool" / "outreach"
UA = "ShoreThingApp/0.1 (https://github.com/rishiaggarwal06-afk/shore-thing; beach guide app)"
SERVERS = ["https://overpass-api.de/api/interpreter", "https://overpass.kumi.systems/api/interpreter"]
PER_BEACH = 5
EMAIL = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")

# Kinds of business, most beach-relevant first (lower number = preferred).
KINDS = [
    (0, "shop", {"surf", "water_sports", "diving", "scuba_diving", "fishing", "boat"}),
    (0, "amenity", {"boat_rental", "surf_school", "dive_centre"}),
    (0, "leisure", {"water_park", "sports_centre"}),
    (0, "sport", {"surfing", "scuba_diving", "kitesurfing", "windsurfing", "canoe", "sailing", "swimming"}),
    (1, "amenity", {"restaurant", "cafe", "bar", "fast_food", "ice_cream", "pub", "biergarten"}),
    (2, "shop", {"bicycle", "rental", "sports", "outdoor", "beach", "clothes", "gift", "souvenir"}),
    (2, "amenity", {"bicycle_rental", "car_rental"}),
    (3, "tourism", {"hotel", "guest_house", "hostel", "motel", "apartment", "camp_site"}),
    (3, "tourism", {"attraction", "information"}),
]


def kind_of(tags):
    for rank, key, values in KINDS:
        v = tags.get(key)
        if v in values:
            return rank, f"{key}={v}"
    return None


def query(lat, lon, radius):
    q = f"""[out:json][timeout:60];
(
  nwr(around:{radius},{lat},{lon})["email"];
  nwr(around:{radius},{lat},{lon})["contact:email"];
);
out tags center;"""
    body = urllib.parse.urlencode({"data": q}).encode()
    for attempt in range(6):
        server = SERVERS[attempt % len(SERVERS)]
        try:
            req = urllib.request.Request(server, data=body, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.load(r)["elements"]
        except Exception as e:  # noqa: BLE001 - busy server: wait and try again
            wait = 15 * (attempt + 1)
            print(f"  server busy ({e}); waiting {wait}s", file=sys.stderr)
            time.sleep(wait)
    return []


def distance_m(lat1, lon1, lat2, lon2):
    p = math.pi / 180
    a = 0.5 - math.cos((lat2 - lat1) * p) / 2 + math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2
    return round(12742000 * math.asin(math.sqrt(a)))


def candidates(beach, radius, used_emails):
    out = []
    for e in query(beach["lat"], beach["lon"], radius):
        t = e.get("tags", {})
        name = t.get("name")
        email = (t.get("email") or t.get("contact:email") or "").split(";")[0].strip()
        k = kind_of(t)
        if not name or not k or not EMAIL.match(email) or email.lower() in used_emails:
            continue
        lat = e.get("lat") or e.get("center", {}).get("lat")
        lon = e.get("lon") or e.get("center", {}).get("lon")
        if lat is None:
            continue
        out.append({
            "beach": beach["name"],
            "beach_slug": beach["slug"],
            "business": name,
            "type": k[1],
            "rank": k[0],
            "email": email,
            "website": t.get("website") or t.get("contact:website") or "",
            "phone": t.get("phone") or t.get("contact:phone") or "",
            "distance_m": distance_m(beach["lat"], beach["lon"], lat, lon),
            "osm_link": f"https://www.openstreetmap.org/{e['type']}/{e['id']}",
        })
    # Best first: beach-related kinds, then closest.
    out.sort(key=lambda c: (c["rank"], c["distance_m"]))
    return out


def pick(cands):
    """Up to 5, mixing kinds so it isn't 5 restaurants."""
    chosen, kinds = [], {}
    for c in cands:
        if len(chosen) == PER_BEACH:
            break
        if kinds.get(c["type"], 0) >= 2:
            continue
        chosen.append(c)
        kinds[c["type"]] = kinds.get(c["type"], 0) + 1
    for c in cands:  # fill any gaps with whatever is left
        if len(chosen) == PER_BEACH:
            break
        if c not in chosen:
            chosen.append(c)
    return chosen


def main():
    beaches = json.loads(DATA.read_text(encoding="utf-8"))["beaches"]
    OUT.mkdir(parents=True, exist_ok=True)
    used, rows = set(), []
    for b in beaches:
        chosen = []
        for radius in (3000, 8000):  # widen the search for remote beaches
            chosen = pick(candidates(b, radius, used))
            if len(chosen) == PER_BEACH:
                break
            time.sleep(5)
        for c in chosen:
            used.add(c["email"].lower())
        rows += chosen
        print(f"{b['name']}: {len(chosen)} businesses", file=sys.stderr)
        time.sleep(5)  # be polite to the free Overpass servers

    # Split into two groups of (about) equal size, balanced across beaches:
    # within each beach the businesses alternate A/B, starting on whichever group is smaller.
    random.seed(2026)
    counts = {"A": 0, "B": 0}
    by_beach = {}
    for r in rows:
        by_beach.setdefault(r["beach_slug"], []).append(r)
    for group in by_beach.values():
        random.shuffle(group)
        first = "A" if counts["A"] <= counts["B"] else "B"
        for i, r in enumerate(group):
            g = first if i % 2 == 0 else ("B" if first == "A" else "A")
            r["group"] = g
            counts[g] += 1

    fields = ["group", "beach", "business", "type", "email", "website", "phone", "distance_m", "osm_link", "beach_slug"]
    def write(path, items):
        with open(path, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
            w.writeheader()
            w.writerows(items)
    write(OUT / "businesses.csv", rows)
    write(OUT / "group_A.csv", [r for r in rows if r["group"] == "A"])
    write(OUT / "group_B.csv", [r for r in rows if r["group"] == "B"])
    short = [b["name"] for b in beaches if sum(r["beach_slug"] == b["slug"] for r in rows) < PER_BEACH]
    print(f"\nDone: {len(rows)} businesses (group A {counts['A']}, group B {counts['B']}).", file=sys.stderr)
    if short:
        print("Fewer than 5 found near: " + ", ".join(short), file=sys.stderr)
    print(f"Files are in {OUT.relative_to(ROOT)}/ (not uploaded to GitHub).", file=sys.stderr)


if __name__ == "__main__":
    main()
