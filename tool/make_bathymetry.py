#!/usr/bin/env python3
"""Build assets/data/bathymetry.json: simplified ocean-depth areas for the map's sea shading.

Source: Natural Earth 1:10m bathymetry (public domain), from the natural-earth-vector repo.
Each level is "the sea deeper than N metres", so drawing them shallow-to-deep in darker
blues gives the nautical-chart look (pale near the coast, deep blue offshore).

Run from the project folder (needs Shapely:  pip3 install shapely):
    python3 tool/make_bathymetry.py
"""
import json
import urllib.request
from pathlib import Path

from shapely.geometry import shape, Polygon, MultiPolygon

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "data" / "bathymetry.json"
BASE = "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/"
# (depth in metres, file, how much to simplify in degrees, smallest area to keep in square degrees)
LEVELS = [
    (200, "ne_10m_bathymetry_K_200.geojson", 0.06, 0.15),
    (1000, "ne_10m_bathymetry_J_1000.geojson", 0.1, 0.4),
    (3000, "ne_10m_bathymetry_H_3000.geojson", 0.15, 1.0),
    (5000, "ne_10m_bathymetry_F_5000.geojson", 0.2, 2.0),
]


def flat(ring):
    """[(lon, lat), …] → [lat, lon, lat, lon, …] rounded to 2 decimals (≈1 km)."""
    out = []
    for lon, lat in ring:
        out += [round(lat, 2), round(lon, 2)]
    return out


def main():
    levels = []
    for depth, name, tol, min_area in LEVELS:
        with urllib.request.urlopen(BASE + name, timeout=120) as r:
            data = json.load(r)
        polys = []
        for f in data["features"]:
            geom = shape(f["geometry"]).simplify(tol, preserve_topology=True)
            parts = geom.geoms if isinstance(geom, MultiPolygon) else [geom] if isinstance(geom, Polygon) else []
            for p in parts:
                if p.area < min_area:
                    continue
                holes = [h for h in p.interiors if Polygon(h).area >= min_area]
                polys.append([flat(p.exterior.coords)] + [flat(h.coords) for h in holes])
        levels.append({"depth": depth, "polygons": polys})
        print(f"{depth} m: {len(polys)} areas")
    OUT.write_text(json.dumps({
        "source": "Natural Earth 1:10m bathymetry (public domain), simplified by tool/make_bathymetry.py",
        "levels": levels,
    }, separators=(",", ":")) + "\n")
    print(f"Wrote {OUT.relative_to(ROOT)} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
