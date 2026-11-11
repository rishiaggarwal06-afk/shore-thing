import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

/// A place name drawn on the built-in map.
class MapLabel {
  const MapLabel(this.name, this.point, {required this.isState, required this.size});
  final String name;
  final LatLng point;
  final bool isState;

  /// Rough size of the country/state, used to decide which names show at each zoom.
  final double size;
}

/// The built-in world map (Natural Earth, public domain), used when there's no
/// MapTiler key: e.g. on the shared web preview, which can't load outside map images.
/// Stored in assets/data/basemap.json as flat [lat, lon, lat, lon, …] rings.
class Basemap {
  Basemap(this.land, this.states, this.labels);

  final List<List<LatLng>> land;
  final List<List<LatLng>> states;
  final List<MapLabel> labels;

  static Basemap? _cached;

  static Future<Basemap> load() async {
    if (_cached != null) return _cached!;
    final j = jsonDecode(await rootBundle.loadString('assets/data/basemap.json')) as Map<String, dynamic>;
    List<List<LatLng>> rings(String key) => [
      for (final r in j[key] as List)
        [
          for (var i = 0; i + 1 < (r as List).length; i += 2)
            LatLng((r[i] as num).toDouble(), (r[i + 1] as num).toDouble()),
        ],
    ];
    final labels = [
      for (final l in j['labels'] as List)
        MapLabel(
          l['n'] as String,
          LatLng((l['lat'] as num).toDouble(), (l['lon'] as num).toDouble()),
          isState: l['k'] == 'state',
          size: (l['a'] as num).toDouble(),
        ),
    ]..sort((a, b) => b.size.compareTo(a.size)); // biggest places get first pick of space
    return _cached = Basemap(rings('land'), rings('states'), labels);
  }
}
