import 'package:flutter/widgets.dart';

import '../config/secrets.dart';

/// Where the map images ("tiles") come from, and how they're tinted to the brand.
///
/// With a MapTiler key in lib/config/secrets.dart the app uses MapTiler's
/// "basic-v2" map, which is allowed in published apps. Without one it falls
/// back to free OpenStreetMap tiles, which are fine for development only.
class MapTiles {
  const MapTiles._({required this.urlTemplate, required this.tint, required this.credit, required this.usesMapTiler});

  final String urlTemplate;

  /// Turns the map's colours into Shore Thing's sand land and ocean water,
  /// with place names in dark ink.
  final ColorFilter tint;

  /// Required credit line shown on the map.
  final String credit;

  /// MapTiler's free plan also requires its logo on the map.
  final bool usesMapTiler;

  static bool get hasMapTilerKey => Secrets.maptilerKey.isNotEmpty && !Secrets.maptilerKey.startsWith('YOUR_');

  static MapTiles get current => hasMapTilerKey ? _mapTiler : _openStreetMap;

  static final _mapTiler = MapTiles._(
    urlTemplate: 'https://api.maptiler.com/maps/basic-v2/256/{z}/{x}/{y}{r}.png?key=${Secrets.maptilerKey}',
    // Tuned on basic-v2 from three sample colours: its water (148,193,224) → ocean #0AB0C6,
    // its land (224,224,209) → sand #FFE38A, and its near-black label text (2,2,1) → ink #123D40,
    // so place names stay dark and readable. Each colour depends on how much redder than blue
    // a pixel is and how bright it is.
    tint: const ColorFilter.matrix([
      2.689, 0.312, -2.064, 0, 14.06, //
      0.558, 0.248, -0.062, 0, 59.45,
      -0.661, 0.130, 0.922, 0, 64.14,
      0, 0, 0, 1, 0,
    ]),
    credit: '© MapTiler © OpenStreetMap contributors',
    usesMapTiler: true,
  );

  static const _openStreetMap = MapTiles._(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    tint: ColorFilter.matrix([
      3.95, 0, -3.95, 0, 219, //
      0.82, 0, -0.82, 0, 220,
      -0.97, 0, 0.97, 0, 147,
      0, 0, 0, 1, 0,
    ]),
    credit: '© OpenStreetMap contributors',
    usesMapTiler: false,
  );
}
