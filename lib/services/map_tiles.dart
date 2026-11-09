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
  /// and fades labels and roads way back.
  final ColorFilter tint;

  /// Required credit line shown on the map.
  final String credit;

  /// MapTiler's free plan also requires its logo on the map.
  final bool usesMapTiler;

  static bool get hasMapTilerKey => Secrets.maptilerKey.isNotEmpty && !Secrets.maptilerKey.startsWith('YOUR_');

  static MapTiles get current => hasMapTilerKey ? _mapTiler : _openStreetMap;

  static final _mapTiler = MapTiles._(
    urlTemplate: 'https://api.maptiler.com/maps/basic-v2/256/{z}/{x}/{y}{r}.png?key=${Secrets.maptilerKey}',
    // Tuned on basic-v2: its water (148,193,224) → ocean #0AB0C6, its land (224,224,209) → sand #FFE38A.
    // Each pixel's colour depends on how much redder than blue it is.
    tint: const ColorFilter.matrix([
      2.849, 0, -2.849, 0, 226.5, //
      0.593, 0, -0.593, 0, 221.1,
      -0.698, 0, 0.698, 0, 145,
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
