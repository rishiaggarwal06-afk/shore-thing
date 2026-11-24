import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../services/basemap.dart';
import 'brand.dart';

/// Draws the built-in map: sand land with ink coastlines, US state borders, and
/// country/state names in dark ink. Names appear as you zoom in and never overlap.
class BasemapLayers extends StatefulWidget {
  const BasemapLayers({super.key});

  @override
  State<BasemapLayers> createState() => _BasemapLayersState();
}

class _BasemapLayersState extends State<BasemapLayers> {
  Basemap? _map;
  late final List<Polygon> _land, _states;

  @override
  void initState() {
    super.initState();
    Basemap.load().then((m) {
      if (!mounted) return;
      setState(() {
        _land = [
          for (final r in m.land) Polygon(points: r, color: Brand.sand, borderColor: Brand.ink, borderStrokeWidth: 1.2),
        ];
        _states = [
          for (final r in m.states)
            Polygon(points: r, color: Brand.sand, borderColor: Brand.ink.withValues(alpha: .45), borderStrokeWidth: .8),
        ];
        _map = m;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = _map;
    if (m == null) return const SizedBox.shrink();
    return Stack(
      children: [
        PolygonLayer(polygons: _land),
        PolygonLayer(polygons: _states),
        _Labels(m.labels),
      ],
    );
  }
}

class _Labels extends StatelessWidget {
  const _Labels(this.labels);
  final List<MapLabel> labels;

  // Which places are big enough to name at this zoom.
  static bool _shown(MapLabel l, double zoom) {
    if (l.isState) return zoom >= 3.6 && (zoom >= 5 || l.size >= 1.2);
    if (zoom < 2.5) return l.size >= 400;
    if (zoom < 3.5) return l.size >= 60;
    if (zoom < 4.5) return l.size >= 6;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final zoom = camera.zoom;
    final size = camera.size;
    final placed = <Rect>[];
    final children = <Widget>[];
    for (final l in labels) {
      if (!_shown(l, zoom)) continue;
      if (!l.isState && l.name == 'United States' && zoom >= 4.5) continue; // states take over
      final at = camera.latLngToScreenOffset(l.point);
      if (at.dx < -100 || at.dy < -40 || at.dx > size.width + 100 || at.dy > size.height + 40) continue;
      final style = l.isState ? _stateStyle : _countryStyle;
      final text = l.isState ? l.name : l.name.toUpperCase();
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final box = Rect.fromCenter(center: at, width: tp.width + 8, height: tp.height + 4);
      if (placed.any(box.overlaps)) continue; // a bigger place already claimed this spot
      placed.add(box);
      children.add(
        Positioned(
          left: box.left + 4,
          top: box.top + 2,
          child: IgnorePointer(child: Text(text, style: style, maxLines: 1, softWrap: false)),
        ),
      );
    }
    return Stack(clipBehavior: Clip.none, children: children);
  }

  static const _halo = [Shadow(color: Brand.paper, blurRadius: 3), Shadow(color: Brand.paper, blurRadius: 3)];
  static const _countryStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: Brand.ink,
    shadows: _halo,
  );
  static const _stateStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Brand.ink, shadows: _halo);
}
