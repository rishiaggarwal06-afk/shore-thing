import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../config/secrets.dart';

/// Where the map images ("tiles") come from, and how they're tinted to the brand.
///
/// With a MapTiler key in lib/config/secrets.dart the app uses MapTiler's
/// "basic-v2" map, which is allowed in published apps. Without one it draws a
/// built-in map (Natural Earth, see Basemap): used by the shared web preview.
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

  /// Set to false when MapTiler turns the key down (deleted, mistyped or over its limit),
  /// so the app shows the built-in map instead of "Invalid key" tiles.
  static bool _keyWorks = true;

  static MapTiles get current => hasMapTilerKey && _keyWorks ? _mapTiler : _builtIn;

  /// Asks MapTiler for one small map image. If it refuses the key (HTTP 401/403), the
  /// app falls back to the built-in map. Network trouble doesn't count: the tiles may
  /// still load later. Returns true when the map source changed.
  static Future<bool> checkKey() async {
    if (!hasMapTilerKey || !_keyWorks) return false;
    try {
      final r = await http
          .head(Uri.parse('https://api.maptiler.com/maps/basic-v2/256/0/0/0.png?key=${Secrets.maptilerKey}'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 401 || r.statusCode == 403) {
        _keyWorks = false;
        return true;
      }
    } catch (_) {
      // Offline or slow: keep MapTiler.
    }
    return false;
  }

  /// True when the app draws its own built-in map instead of downloading map images.
  bool get builtIn => urlTemplate.isEmpty;

  static final _mapTiler = MapTiles._(
    urlTemplate: 'https://api.maptiler.com/maps/basic-v2/256/{z}/{x}/{y}{r}.png?key=${Secrets.maptilerKey}',
    // Tuned on basic-v2's colours: its water (148,193,224) → flat sea #5BBFC9, its land
    // (224,224,209) → sand #EFD9A7, its near-black label text (2,2,1) → ink #23302F, and white
    // roads → cream. Worked out from the original filter, so parks and roads keep its soft look.
    tint: const ColorFilter.matrix([
      1.615, 0.271, -1.048, 0, 32.26, //
      0.263, 0.227, 0.252, 0, 46.73,
      -0.368, 0.208, 0.762, 0, 46.57,
      0, 0, 0, 1, 0,
    ]),
    credit: '© MapTiler © OpenStreetMap contributors',
    usesMapTiler: true,
  );

  /// No key: draw the built-in Natural Earth map instead (no outside requests).
  static const _builtIn = MapTiles._(
    urlTemplate: '',
    tint: ColorFilter.mode(Color(0x00000000), BlendMode.dst),
    credit: 'Map data: Natural Earth',
    usesMapTiler: false,
  );
}
