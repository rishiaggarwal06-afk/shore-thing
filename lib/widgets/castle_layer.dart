import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/beach.dart';
import 'sandcastle.dart';

/// A group of castles that would overlap on screen.
class CastleGroup {
  CastleGroup(this.at, this.members);
  Offset at; // screen position (average of members)
  final List<({Beach beach, Offset at})> members;
}

/// Map layer that draws one sandcastle per visible beach, rebuilding on every
/// pan/zoom. Castles closer than 44×40 px merge into a numbered cluster.
class CastleLayer extends StatefulWidget {
  const CastleLayer({
    super.key,
    required this.beaches,
    required this.visible,
    required this.onBeachTap,
    required this.onClusterTap,
    this.selected,
  });

  final List<Beach> beaches;
  final Set<String> visible; // slugs that pass the current filter
  final String? selected; // slug of the beach whose card is showing
  final void Function(Beach) onBeachTap;

  /// Called with the cluster's members and how far apart (px) they are on screen.
  final void Function(List<Beach> members, double spreadPx) onClusterTap;

  @override
  State<CastleLayer> createState() => _CastleLayerState();
}

class _CastleLayerState extends State<CastleLayer> with SingleTickerProviderStateMixin {
  // Castles pop up one after another: 250ms + 140ms each, 550ms per pop.
  late final _intro = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 250 + widget.beaches.length * 140 + 550),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (_intro.value == 0 && !_intro.isAnimating) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  double _pop(int i) {
    final ms = _intro.value * _intro.duration!.inMilliseconds;
    final p = ((ms - 250 - i * 140) / 550).clamp(0.0, 1.0);
    return const Cubic(.3, 1.7, .5, 1).transform(p);
  }

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final shown = [
      for (final b in widget.beaches)
        if (widget.visible.contains(b.slug)) (beach: b, at: camera.latLngToScreenOffset(LatLng(b.lat, b.lon))),
    ];

    // 1. Group castles that would overlap on screen.
    final groups = <CastleGroup>[];
    for (final m in shown) {
      final g = groups.where((g) => (g.members.first.at.dx - m.at.dx).abs() < 44 && (g.members.first.at.dy - m.at.dy).abs() < 40).firstOrNull;
      if (g == null) {
        groups.add(CastleGroup(m.at, [m]));
      } else {
        g.members.add(m);
      }
    }
    for (final g in groups) {
      final n = g.members.length;
      g.at = Offset(g.members.fold(0.0, (s, m) => s + m.at.dx) / n, g.members.fold(0.0, (s, m) => s + m.at.dy) / n);
    }

    // 2. Hide a name tag when it would sit on another castle or an already placed tag.
    final labels = [for (final g in groups) g.members.length > 1 ? '${g.members.length} beaches' : g.members.first.beach.name];
    final castleBoxes = [for (final g in groups) Rect.fromLTRB(g.at.dx - 23, g.at.dy - 44, g.at.dx + 23, g.at.dy)];
    final placed = <Rect>[];
    final hidden = <bool>[];
    for (var i = 0; i < groups.length; i++) {
      final half = _labelWidth(labels[i]) / 2 + 3;
      final at = groups[i].at;
      final tag = Rect.fromLTRB(at.dx - half, at.dy + 2, at.dx + half, at.dy + 26);
      final clash = [for (var j = 0; j < castleBoxes.length; j++) if (j != i) castleBoxes[j]].any(tag.overlaps) ||
          placed.any(tag.overlaps);
      hidden.add(clash);
      if (!clash) placed.add(tag);
    }

    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) => Stack(clipBehavior: Clip.none, children: [
        for (var i = 0; i < groups.length; i++)
          Positioned(
            left: groups[i].at.dx,
            top: groups[i].at.dy - SandcastleMarker.baseFromTop,
            child: FractionalTranslation(
              translation: const Offset(-.5, 0),
              child: _marker(groups[i], labels[i], hidden[i]),
            ),
          ),
      ]),
    );
  }

  Widget _marker(CastleGroup g, String label, bool labelHidden) {
    final first = g.members.first.beach;
    final pop = _pop(widget.beaches.indexOf(first));
    if (g.members.length == 1) {
      return SandcastleMarker(
        key: ValueKey(first.slug),
        label: label,
        semanticLabel: '${first.name}, show its card',
        pop: pop,
        labelHidden: labelHidden,
        selected: first.slug == widget.selected,
        onTap: () => widget.onBeachTap(first),
      );
    }
    final members = [for (final m in g.members) m.beach];
    var spread = 0.0;
    for (final a in g.members) {
      for (final b in g.members) {
        spread = math.max(spread, (a.at - b.at).distance);
      }
    }
    return SandcastleMarker(
      key: ValueKey('cluster-${members.map((b) => b.slug).join()}'),
      label: label,
      count: members.length,
      semanticLabel: '${members.length} beaches: ${members.map((b) => b.name).join(', ')}. Zoom in',
      pop: pop,
      labelHidden: labelHidden,
      selected: members.any((b) => b.slug == widget.selected),
      onTap: () => widget.onClusterTap(members, spread),
    );
  }

  final _widths = <String, double>{};
  double _labelWidth(String text) => _widths.putIfAbsent(text, () {
        final tp = TextPainter(
          text: TextSpan(text: text, style: castleLabelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        return tp.width + 18 + 3; // padding + border
      });
}
