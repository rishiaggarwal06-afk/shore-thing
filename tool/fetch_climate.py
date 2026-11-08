#!/usr/bin/env python3
"""Fill in real month-by-month conditions for every beach in assets/data/beaches.json.

Uses Open-Meteo's free APIs (data licensed CC BY 4.0, attribution shown in the app):
  - Historical Weather API: daily high temperature and rain, 2016–2025
  - Marine API: daily max wave height and sea surface temperature

Run from the project folder:   python3 tool/fetch_climate.py
It makes about 2 requests per beach and rewrites the "monthly" field of each beach.
"""
import json
import statistics
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from pathlib import Path

DATA = Path(__file__).resolve().parent.parent / "assets" / "data" / "beaches.json"
UA = "ShoreThingApp/0.1 (https://github.com/rishiaggarwal06-afk/shore-thing)"
START_YEAR, END_YEAR = 2016, 2025
MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


def get(base, params):
    url = base + "?" + urllib.parse.urlencode(params)
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")
            if "limit exceeded" in body.lower():
                sys.exit("Open-Meteo says the daily request limit is used up. Try again tomorrow.")
            if e.code == 400:
                raise ValueError(body) from e
            wait = 10 * (attempt + 1)
        except (urllib.error.URLError, TimeoutError, ConnectionError):
            wait = 10 * (attempt + 1)
        print(f"  retrying in {wait}s…", file=sys.stderr)
        time.sleep(wait)
    sys.exit("Couldn't reach Open-Meteo. Check your internet connection and try again.")


def by_month(dates, values):
    """Group daily values by (year, month), skipping missing days."""
    groups = defaultdict(list)
    for d, v in zip(dates, values):
        if v is not None:
            groups[(int(d[:4]), int(d[5:7]))].append(v)
    return groups


def land(beach):
    data = get("https://archive-api.open-meteo.com/v1/archive", {
        "latitude": beach["lat"], "longitude": beach["lon"],
        "start_date": f"{START_YEAR}-01-01", "end_date": f"{END_YEAR}-12-31",
        "daily": "temperature_2m_max,precipitation_sum",
        "temperature_unit": "fahrenheit", "precipitation_unit": "inch", "timezone": "America/New_York",
    })["daily"]
    highs = by_month(data["time"], data["temperature_2m_max"])
    rain = by_month(data["time"], data["precipitation_sum"])
    air, rain_totals = {}, {}
    for m in range(1, 13):
        air[m] = statistics.mean(v for (y, mm), days in highs.items() if mm == m for v in days)
        # Average of each year's monthly total (only complete-ish months).
        totals = [sum(days) for (y, mm), days in rain.items() if mm == m and len(days) >= 25]
        rain_totals[m] = statistics.mean(totals)
    return air, rain_totals


def sea(beach):
    """Wave height and water temperature from the nearest ocean grid cell (a little offshore)."""
    for offset in (0.05, 0.1, 0.2):
        for start in (START_YEAR, 2022):
            try:
                data = get("https://marine-api.open-meteo.com/v1/marine", {
                    "latitude": beach["lat"], "longitude": round(beach["lon"] + offset, 4),
                    "start_date": f"{start}-01-01", "end_date": f"{END_YEAR}-12-31",
                    "daily": "wave_height_max", "hourly": "sea_surface_temperature",
                    "timezone": "America/New_York",
                })
            except ValueError:
                continue  # that date range isn't available; try a shorter one
            waves = by_month(data["daily"]["time"], data["daily"]["wave_height_max"])
            sst = by_month([t[:10] for t in data["hourly"]["time"]], data["hourly"]["sea_surface_temperature"])
            if len(waves) >= 12 and len(sst) >= 12:
                return waves, sst, start
    raise SystemExit(f"No ocean data found near {beach['name']}.")


def wave_range(days_m):
    ft = sorted(v * 3.281 for v in days_m)
    lo, hi = ft[len(ft) // 4], ft[(len(ft) * 3) // 4]  # middle half of days
    lo, hi = max(1, round(lo)), max(1, round(hi))
    return f"{lo}–{hi}" if hi > lo else f"{lo}"


def main():
    doc = json.loads(DATA.read_text(encoding="utf-8"))
    for beach in doc["beaches"]:
        print(beach["name"], file=sys.stderr)
        air, rain = land(beach)
        time.sleep(2)
        waves, sst, sea_from = sea(beach)
        time.sleep(2)
        monthly = []
        for m in range(1, 13):
            wave_days = [v for (y, mm), days in waves.items() if mm == m for v in days]
            water_c = statistics.mean(v for (y, mm), days in sst.items() if mm == m for v in days)
            monthly.append({
                "month": MONTHS[m - 1],
                "airF": round(air[m]),
                "waterF": round(water_c * 9 / 5 + 32),
                "waveFt": wave_range(wave_days),
                "rainIn": round(rain[m], 1),
            })
        beach["monthly"] = monthly
        beach["monthlySource"] = (
            f"Averages of daily data: air and rain {START_YEAR}–{END_YEAR}, "
            f"waves and water {sea_from}–{END_YEAR}. Weather data by Open-Meteo.com (CC BY 4.0)."
        )
    DATA.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Updated", DATA, file=sys.stderr)


if __name__ == "__main__":
    main()
