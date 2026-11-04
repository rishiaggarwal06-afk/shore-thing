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
- **Maps**: flutter_map with free OpenStreetMap tiles, recoloured to the brand (sand land, ocean water) by a colour filter in `home_map_screen.dart`. Mapbox was dropped for now.
- **Open-Meteo**: weather, marine, and climate data.
- **OpenStreetMap**: seed source for beach locations.
- **Attribution for OSM (and Open-Meteo, once connected) must appear in the app.** It's required by their licenses/terms, so don't remove it. The map shows it bottom-right.

## Current state
- Focus region: **the Jersey Shore** (10 beaches, Sandy Hook → Cape May) in `assets/data/beaches.json`, gathered from public sources in Nov 2026 (2026 summer badge prices).
- Design reference: the HTML prototype in `reference/` (its style.css is missing, so styling follows the brand rules below).
- Brand: ink #123d40, yellow #FFE14D, orange #FF7F50, paper #fff9e9, teal #98d7d0, ocean #0AB0C6, sand #FFE38A; bold Arial-style type (bundled Liberation Sans); thick ink borders with hard offset shadows. Add U+FE0E after symbols like ✳ ↗ so they don't render as emoji.
- Routes (go_router, clean web paths): `/` map, `/beach/<slug>` detail, anything else under `/beach/` → fuzzy search, then the "not one of our ten (yet)" page.
- Amenity booleans are true only when the beach's features list says so; "Family friendly" = lifeguards + (restrooms or food). Nothing lists water sports rentals yet.
- "Best time to go" uses PLACEHOLDER numbers from `lib/services/climate_service.dart`. Next step: real Open-Meteo data.

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
