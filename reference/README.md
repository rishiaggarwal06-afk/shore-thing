# Shore Thing — Surf Club concept

A responsive, dependency-free beach discovery mockup. All content and illustrations are fictional; there are no live APIs, payments, trackers, or external assets.

Run from this directory:

```sh
python3 -m http.server 8000
```

Open http://localhost:8000 in a browser. Search any beach name, open beach cards, filter the collection, and use the back link or browser back button. Unknown names create clearly labeled sample guides. All source is plain HTML, CSS, and JavaScript, so it can be hosted by any static web server.

## Sandcastle world map

The home page is a full-screen world map (yellow land, blue ocean) that wraps around east–west, with the search panel and ticker floating on top. The map lives in `beachmap.js` and is themed with `--bm-*` variables in `style.css`. Each beach is a cartoon sandcastle: drag to pan, scroll, pinch or the ± buttons to zoom, and click a castle to visit that beach. Opening a beach (from a castle or the search) plays a tide transition: water rushes up over the page, the beach loads underneath, and the tide pulls back to reveal it. Filters hide castles and zoom to the matches. `world.js` is a simplified Natural Earth 1:110m land outline (public domain), so there are still no network requests.

## Oʻahu beaches

The ten beaches are real Oʻahu (City & County of Honolulu) favorites: Waikīkī, Ala Moana, Hanauma Bay, Sandy Beach, Makapuʻu, Waimānalo Bay, Lanikai, Kailua, Waimea Bay and Sunset Beach. Facts (lifeguards, facilities, fees, parking, seasonal surf) were gathered from public sources in Nov 2026 and live in the `beaches` list at the top of `app.js`. Conditions are typical values, not live data.

`hawaii.js` is a detailed outline of the main Hawaiian islands from the US Census Bureau 1:500,000 state boundaries (public domain), used instead of the coarse world outline so the map holds up at street-level zoom. Castles that would overlap merge into a numbered cluster, and clicking it zooms in until they separate.
