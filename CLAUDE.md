# Beach Finder (repo: shore-thing)

## Product
An app + website for discovering beaches worldwide.

- Users browse a **world map**, tap a **region/country**, then see **beaches in that area as pins**.
- Each beach has a **detail page** showing:
  - **Amenities:** beach shacks, food, restrooms, parking, lifeguards, water sports rentals
  - **Good for:** water sports, lounging, food, family, surfing, snorkeling
  - **Conditions month-by-month** through the year: air temp, water temp, wave height, rain
- Users can **filter beaches by activity**.
- **Later (not yet):** beaches pay to be featured/verified; beach product ads.

## Tech
- **Flutter**: one codebase for web, iOS, and Android. The Dart package name is `beach_finder`.
- **Firebase**: Firestore (data), Auth (accounts), Storage (images), Hosting (website).
- **Maps**: flutter_map with MapTiler `basic-v2` raster tiles (free plan = non-commercial; needs the MapTiler logo + "© MapTiler © OpenStreetMap contributors" on the map), recoloured to the brand (sand land, ocean water, place names in dark ink) by a colour filter. All in `lib/services/map_tiles.dart`. Key in `lib/config/secrets.dart` (`Secrets.maptilerKey`); without it the app draws a **built-in Natural Earth map** (`assets/data/basemap.json`, public domain, made from world-atlas/us-atlas TopoJSON; `lib/services/basemap.dart` + `lib/widgets/basemap_layers.dart`) with no outside requests — that's what the shared web preview uses (build it with the example secrets so the key never ships in it). One key for the iPhone app (no origin restriction); the future website needs its own key restricted to the site's address.
- **Open-Meteo**: weather, marine, and climate data.
- **OpenStreetMap**: seed source for beach locations.
- **Attribution for MapTiler (logo + text), OSM, Open-Meteo and each Wikimedia photo must appear in the app.** It's required by their licenses/terms, so don't remove it. The map shows it in one credit bar bottom-right.

## Current state
- **20 beaches in 3 regions** in `assets/data/beaches.json`: Jersey Shore (10, Sandy Hook → Cape May), Florida (5: Siesta Key, Clearwater, South Beach, Bahia Honda, Daytona) and Hawaiʻi (5 Oʻahu beaches copied unchanged from the prototype in `reference/app.js`). Each beach has `region`; `regions` holds name/state/fallback temps; `sourcesNote` is shared. Facts gathered from public sources Nov 2026. Where sources disagreed (lifeguard hours, Daytona driving fees) the data says "varies"/points to the official site rather than guessing a number — keep it that way.
- Activity filter chips: Calm swimming, Snorkeling, Surf spots, Quiet escapes, Boardwalk fun, Nature & wildlife. Copy uses the beach count and `BeachRepository.regionsLabel`, never a hard-coded "ten" or region.
- Design reference: the HTML prototype in `reference/` (its style.css is missing, so styling follows the brand rules below).
- Brand: ink #123d40, yellow #FFE14D, orange #FF7F50, paper #fff9e9, teal #98d7d0, ocean #0AB0C6, sand #FFE38A; bold Arial-style type (bundled Liberation Sans); thick ink borders with hard offset shadows. Symbols (✳ ↗ ☀ ☂ ⚑ ≈) come from the bundled DejaVu Sans fallback font (`Brand.fontFallback`), otherwise iPhones show colourful emoji; keep the U+FE0E after them too. Use `UnderlinedText` instead of `TextDecoration.underline` (iOS draws underlines through the letters). Never give text boxes fixed heights/widths without scaling by `MediaQuery.textScalerOf` — the user's iPhone uses a large text size (`test/month_strip_test.dart` checks this).
- Screens (Nov 2026 redesign, user asked for less clutter / less "AI-looking"): every screen has the yellow `TopBar` (`lib/widgets/site_chrome.dart`). Map screen = logo + Search button, a strip of filter chips (chips that match no beach are hidden), then the map. A row of `BeachCard`s (`lib/widgets/beach_card.dart`) runs along the bottom of the map: swiping them flies the map to each beach (zooming out mid-flight on long hops), tapping a castle selects it (raised castle, yellow tag, yellow card), tapping a card opens the beach page. Card height comes from `BeachCard.heightFor` (scales with text size). No banner strip, slogan ticker, stamp or floating panel: don't bring them back. Search page lists all beaches by region and narrows as you type (`BeachRepository.search`, name matches first). Beach pages have a **Map** (home) button + Search in the top bar.
- Routes (go_router, clean web paths): `/` map, `/search` search, `/beach/<slug>` detail, anything else under `/beach/` → fuzzy search, then the "not one of our ten (yet)" page.
- Amenity booleans are true only when the beach's features list says so; "Family friendly" = lifeguards + (restrooms or food). Nothing lists water sports rentals yet.
- Real data pipeline (run from the project folder, results written into the app's assets):
  - `python3 tool/fetch_climate.py` (only beaches missing data; `--all` to redo) → each beach's `monthly` (10-year Open-Meteo averages) + `monthlySource`. Until it has run, "Best time to go" shows labelled PLACEHOLDER numbers.
  - `python3 tool/fetch_photos.py` → hand-picked CC0/CC BY/CC BY-SA Wikimedia Commons photos in `assets/images/beaches/` + each beach's `photos` (credit shown under each photo and in "Photo credits"). Until it has run, the illustrated scenes are shown.
  - Cloud sessions often can't run these: Open-Meteo's free daily limit and Wikimedia's image servers block the shared cloud IP. Running them on the user's Mac works. `thumb.wikimedia.org` isn't on the cloud allowlist; the scripts use `upload.wikimedia.org` instead.
  - Open-Meteo's free API is non-commercial only; a paid plan is needed once the app has ads or paid features.

## Before launch (remind the user when App Store / launch work starts)
- **Rotate the MapTiler key**: the current key was pasted in a chat. Delete it in MapTiler (cloud.maptiler.com → API keys), click NEW KEY, and put the new one in `lib/config/secrets.dart` on the Mac only. Never ask for keys in chat; use a secure form.
- Make a second MapTiler key for the website, restricted to the site's address (Allowed HTTP origins).
- MapTiler and Open-Meteo free plans are non-commercial: upgrade before adding ads or paid features.
- Done: "Shore Thing" display name, iPhone-only (TARGETED_DEVICE_FAMILY = 1), privacy policy + support pages.
- App icon: a **placeholder** sandcastle icon is in place (`assets/images/brand/app-icon.svg` → `app-icon-1024.png`). The user is designing their own: run `python3 tool/make_icons.py path/to/logo.png` to regenerate every iOS/web/Android size from it (1024×1024 PNG, no transparency, square corners).
- Remaining App Store steps: the user's final icon, $99 Apple Developer account, TestFlight, review.

## Website pages (GitHub Pages, `docs/` folder on main) — LIVE since Nov 2026
- `docs/index.html`, `docs/privacy.html`, `docs/support.html`, shared `docs/style.css`. Public contact email: shorethingva26@gmail.com.
- URLs: https://rishiaggarwal06-afk.github.io/shore-thing/privacy.html and …/support.html (App Store Connect needs both). No custom domain: the user doesn't own one (shorething.com was tried by mistake and removed). If they buy one later, set it in GitHub → Settings → Pages and add the DNS records.
- **Keep the privacy policy true**: it says the app collects nothing and only contacts MapTiler. If you add analytics, accounts, ads, location or any new network service, update `docs/privacy.html` (and its date) in the same change.

## Where we left off (update this at the end of each session)
- **Photos done (Nov 2026)**: Clearwater, Daytona, Waikīkī and Waimea Bay now have 3 photos each (picked from candidates; script lists trimmed). The cloud *can* run `tool/fetch_photos.py`, just slowly (Wikimedia rate-limits; the script waits and retries). Point Pleasant Beach and Beach Haven still have no photos (illustrations); Seaside Heights and Ocean City have 1, Island Beach, Wildwood, Cape May 2.
- **Apple Developer enrollment** failed on the website ("We are unable to process your request. An unknown error occurred."). Suggested: enroll in the Apple Developer app on iPhone, accept the agreement at developer.apple.com/account, or contact Apple (Program Enrollment). Not done yet.
- Free Personal Team installs expire after 7 days: reinstall with `cd ~/dev/shore-thing && git pull && flutter run --release`, then Settings → General → VPN & Device Management → Trust.
- Shareable web preview: https://claude.ai/artifact/Dgxzdhyz8ReCH1TB7xzfiv (public link; built without the MapTiler key, uses the built-in map). Old prototype link https://claude.ai/artifact/FSYdHJBacKwSAvF6zC1esM now points to it.
- UI ideas list (user picked #1, the map cards, done Nov 2026): next candidates are a swipeable full-width photo header + amenity icon row on beach pages, a "this month" conditions line, saved beaches (♥, stored on device only), haptics/swipe-back polish, and an Apple Maps Directions button (needs privacy-policy wording).
- Ideas the user is considering: OpenStreetMap "things to do"/rentals per beach (no key; fills the Water sports rentals filter), Viator affiliate tour links later (needs privacy policy update), saved favorites.
- Cloud sessions start without Flutter: `git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter` then use `/opt/flutter/bin/flutter`. The real MapTiler key is only on the user's Mac (cloud copies of `lib/config/secrets.dart` won't have it unless recreated from `secrets.example.dart`).

## Code layout
```
lib/
  main.dart      app entry point
  models/        plain data classes (Beach, Amenity, MonthlyConditions, ...)
  screens/       full pages (map screen, beach detail screen, ...)
  services/      talking to the outside world (Firestore, Open-Meteo, Mapbox, OSM)
  widgets/       reusable UI pieces (beach card, filter chips, attribution footer, ...)
  config/        secrets.dart (gitignored) + secrets.example.dart (template)
```

## Rules
- **The user is a beginner learning Flutter.** After each step, explain what was built in plain language: what each new file does and why.
- Keep code in `lib/models`, `lib/screens`, `lib/services`, `lib/widgets`.
- **Never put API keys directly in code.** Put them in `lib/config/secrets.dart`, which is gitignored, and keep `secrets.example.dart` up to date as the template.
- **Build in small steps** and make sure the app runs after each one (`flutter analyze` is clean, and `flutter run -d chrome` works).

## Environment notes
- Development and iOS builds happen on the user's Mac (Xcode + CocoaPods). Cloud sessions can build and test for web only, not iOS.
