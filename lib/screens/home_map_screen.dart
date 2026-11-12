import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../models/beach.dart';
import '../models/beach_filter.dart';
import '../services/beach_scope.dart';
import '../services/map_tiles.dart';
import '../widgets/basemap_layers.dart';
import '../widgets/beach_card.dart';
import '../widgets/brand.dart';
import '../widgets/castle_layer.dart';
import '../widgets/site_chrome.dart';
import '../widgets/tide_transition.dart';

/// Home: the map of sandcastles, the filter chips in a strip above it, and a
/// row of beach cards along the bottom. Swiping the cards flies the map from
/// beach to beach; tapping a castle brings up its card.
class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> with SingleTickerProviderStateMixin {
  final _map = MapController();
  late final _fly = AnimationController(vsync: this);
  BeachFilter _filter = BeachFilter.all;
  bool _touched = false; // hides the "drag to explore" hint after the first touch
  bool _ready = false;
  Beach? _selected; // the beach whose card is in the middle of the row

  // The card row. Its controller is remade when the card width changes (phone ↔ wide screen).
  PageController? _cards;
  double _cardsFraction = 0;
  bool _scrollingCards = false; // true while *we* move the cards, so it isn't mistaken for a swipe

  /// Space the cards and credits take at the bottom of the map; the map keeps castles clear of it.
  double _bottomInset = 0;

  // Current fly-to animation.
  LatLng _fromC = const LatLng(0, 0), _toC = const LatLng(0, 0);
  double _fromZ = 0, _toZ = 0;
  double _dip = 0; // how far to zoom out mid-flight on long hops (e.g. Jersey → Hawaiʻi)

  List<Beach> get _beaches => BeachScope.of(context).beaches;
  List<Beach> get _shown => _beaches.where(_filter.matches).toList();

  @override
  void initState() {
    super.initState();
    _fly.addListener(() {
      final t = Curves.easeInOutCubic.transform(_fly.value);
      _map.move(
        LatLng(
          _fromC.latitude + (_toC.latitude - _fromC.latitude) * t,
          _fromC.longitude + (_toC.longitude - _fromC.longitude) * t,
        ),
        _fromZ + (_toZ - _fromZ) * t - _dip * math.sin(math.pi * _fly.value),
      );
    });
  }

  @override
  void dispose() {
    _fly.dispose();
    _cards?.dispose();
    super.dispose();
  }

  /// Camera that fits [list] inside the free area, leaving room for castles and name tags.
  ({LatLng center, double zoom}) _fitTarget(List<Beach> list, {double? maxZoom}) {
    if (list.isEmpty) list = _beaches;
    final bottom = _bottomInset;
    final fit = CameraFit.coordinates(
      coordinates: [for (final b in list) LatLng(b.lat, b.lon)],
      // Room around the edges for castles and their name tags (and the zoom buttons).
      padding: Brand.isPhone(context)
          ? EdgeInsets.fromLTRB(56, 50, 56, bottom + 40) // phones: tighter, so Hawaiʻi and Florida both fit
          : EdgeInsets.fromLTRB(70, 60, 100, bottom + 50), // right: clear of the zoom buttons
      maxZoom: maxZoom ?? (list.length > 1 ? 16 : 13), // one castle gets a neighbourhood view
    ).fit(_map.camera);
    return (center: fit.center, zoom: fit.zoom);
  }

  void _flyTo(LatLng center, double zoom, {int ms = 650}) {
    final cam = _map.camera;
    zoom = zoom.clamp(2.0, 18.0);
    if (MediaQuery.disableAnimationsOf(context)) {
      _map.move(center, zoom);
      return;
    }
    _fromC = cam.center;
    _fromZ = cam.zoom;
    _toC = center;
    _toZ = zoom;
    // Long hop: zoom out on the way so you can see where you're going, like a plane taking off.
    final lowZ = math.min(_fromZ, _toZ);
    final apart = (cam.projectAtZoom(_fromC, lowZ) - cam.projectAtZoom(_toC, lowZ)).distance;
    final view = cam.nonRotatedSize.shortestSide;
    _dip = apart > view * .6 ? (math.log(apart / (view * .6)) / math.ln2).clamp(0.0, 6.0) : 0.0;
    if (_dip > 0) ms = math.max(ms, 1100);
    _fly
      ..duration = Duration(milliseconds: ms)
      ..forward(from: 0);
  }

  void _flyToFit(List<Beach> list) {
    final t = _fitTarget(list);
    _flyTo(t.center, t.zoom);
  }

  void _setFilter(BeachFilter f) {
    setState(() {
      _filter = f;
      _selected = null;
    });
    final shown = _shown;
    if (_cards?.hasClients ?? false) {
      _scrollingCards = true;
      _cards!.jumpToPage(0);
      _scrollingCards = false;
    }
    if (shown.isNotEmpty) _flyToFit(shown);
  }

  /// Show [b]'s card and fly the map to it. [scrollCards]: also move the card row (castle taps).
  void _select(Beach b, {bool scrollCards = false}) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = b;
      _touched = true;
    });
    // Close enough to see the town, or closer if the user has already zoomed in.
    final t = _fitTarget([b], maxZoom: math.max(10, _map.camera.zoom));
    _flyTo(t.center, t.zoom, ms: 800);
    final i = _shown.indexOf(b);
    if (scrollCards && i >= 0 && (_cards?.hasClients ?? false)) {
      _scrollingCards = true;
      _cards!
          .animateToPage(i, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic)
          .whenComplete(() => _scrollingCards = false);
    }
  }

  /// The user swiped the cards to page [i].
  void _onCardSwiped(int i) {
    if (_scrollingCards || i >= _shown.length) return;
    _select(_shown[i]);
  }

  PageController _cardsController(double fraction) {
    if (_cards == null || fraction != _cardsFraction) {
      final old = _cards;
      final page = (old?.hasClients ?? false) ? old!.page?.round() ?? 0 : 0;
      _cards = PageController(viewportFraction: fraction, initialPage: page);
      _cardsFraction = fraction;
      if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return _cards!;
  }

  /// Zoom in just far enough for a cluster's castles to stand apart.
  void _openCluster(List<Beach> members, double spreadPx) {
    setState(() => _touched = true);
    final factor = math.min(8.0, math.max(1.6, 150 / math.max(spreadPx, 1)));
    final lat = members.fold(0.0, (s, b) => s + b.lat) / members.length;
    final lon = members.fold(0.0, (s, b) => s + b.lon) / members.length;
    _flyTo(LatLng(lat, lon), _map.camera.zoom + math.log(factor) / math.ln2, ms: 800);
  }

  @override
  Widget build(BuildContext context) {
    final phone = Brand.isPhone(context);
    final repo = BeachScope.of(context);
    final tiles = MapTiles.current;
    final safeBottom = MediaQuery.paddingOf(context).bottom; // iPhone home-indicator strip
    final width = MediaQuery.sizeOf(context).width;
    final shown = _shown;
    // Bottom of the map, from the bottom up: credits bar, then the card row.
    final textScale = MediaQuery.textScalerOf(context);
    final creditsH = math.max(16.0, textScale.scale(11) * 1.25) + 8 + safeBottom;
    final cardH = BeachCard.heightFor(context);
    final cardsBottom = creditsH + 4;
    _bottomInset = shown.isEmpty ? creditsH : cardsBottom + cardH;
    final touchDevice = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;

    return Title(
      title: 'Shore Thing · beach finder',
      color: Brand.ink,
      child: Scaffold(
        body: Column(
          children: [
            const TopBar(leading: Logo(), trailing: SearchButton()),
            _FilterBar(
              phone: phone,
              filters: [
                for (final f in [BeachFilter.all, ...BeachFilter.activities, ...BeachFilter.amenities])
                  // A chip that would show an empty map isn't worth a tap.
                  if (repo.beaches.any(f.matches)) f,
              ],
              selected: _filter,
              onFilter: _setFilter,
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Listener(
                      onPointerDown: (_) {
                        if (!_touched) setState(() => _touched = true);
                        _fly.stop();
                      },
                      child: FlutterMap(
                        mapController: _map,
                        options: MapOptions(
                          backgroundColor: Brand.ocean,
                          initialCameraFit: CameraFit.coordinates(
                            coordinates: [for (final b in repo.beaches) LatLng(b.lat, b.lon)],
                            padding: const EdgeInsets.all(80),
                          ),
                          minZoom: 2,
                          maxZoom: 18,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                          onTap: (_, _) => setState(() => _selected = null), // tap the sea/land to let go
                          onMapReady: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                            // Re-fit once the map knows its real size.
                            final t = _fitTarget(repo.beaches);
                            _map.move(t.center, t.zoom);
                            setState(() => _ready = true);
                          }),
                        ),
                        children: [
                          // No MapTiler key (e.g. the shared web preview): draw the built-in map.
                          if (tiles.builtIn)
                            const BasemapLayers()
                          else
                            TileLayer(
                              urlTemplate: tiles.urlTemplate,
                              retinaMode: RetinaMode.isHighDensity(context), // sharper map on iPhone screens
                              userAgentPackageName: 'com.shorething.beach_finder',
                              tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: tiles.tint, child: tile),
                            ),
                          if (_ready)
                            CastleLayer(
                              beaches: repo.beaches,
                              visible: {for (final b in shown) b.slug},
                              selected: _selected?.slug,
                              onBeachTap: (b) => _select(b, scrollCards: true),
                              onClusterTap: _openCluster,
                            ),
                          // Required credits (and MapTiler's logo, on its free plan), bottom-right.
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(8, 4, 8, 4 + safeBottom),
                              color: Brand.paper.withValues(alpha: .92),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tiles.usesMapTiler) ...[
                                    Semantics(
                                      label: 'MapTiler',
                                      child: SvgPicture.asset('assets/images/brand/maptiler-logo.svg', height: 16),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(tiles.credit, style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // The card row: one card per beach the filter lets through.
                  if (shown.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: cardsBottom,
                      height: cardH,
                      // Let a mouse drag the cards too (on the website), not just fingers and trackpads.
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                        child: PageView.builder(
                          controller: _cardsController(phone ? .9 : math.min(.9, 420 / width)),
                          itemCount: shown.length,
                          onPageChanged: _onCardSwiped,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: BeachCard(
                              beach: shown[i],
                              selected: shown[i] == _selected,
                              onTap: () => openBeach(context, shown[i].slug),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (shown.isEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: Brand.chunky(color: Brand.paper, shadow: 3),
                          child: Text(
                            'None of our beaches are listed for “${_filter.label}” yet.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  // Zoom controls
                  Positioned(
                    right: 14,
                    top: phone ? null : 14,
                    bottom: phone ? _bottomInset + 12 : null,
                    child: Column(
                      children: [
                        _RoundButton('+', 'Zoom in', () => _flyTo(_map.camera.center, _map.camera.zoom + 1, ms: 350)),
                        const SizedBox(height: 7),
                        _RoundButton('−', 'Zoom out', () => _flyTo(_map.camera.center, _map.camera.zoom - 1, ms: 350)),
                        const SizedBox(height: 7),
                        _RoundButton('⟲︎', 'Back to all beaches', () {
                          setState(() => _selected = null);
                          _flyToFit(shown);
                        }),
                      ],
                    ),
                  ),
                  // Hint
                  Positioned(
                    left: 12,
                    top: 12,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _touched ? 0 : .9,
                        duration: const Duration(milliseconds: 400),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                          decoration: BoxDecoration(color: Brand.paper, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            touchDevice
                                ? 'Drag to explore · pinch to zoom · tap a castle'
                                : 'Drag to explore · scroll to zoom · click a castle',
                            style: const TextStyle(fontSize: 11, letterSpacing: .3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Strip of filter chips under the top bar. Scrolls sideways on phones, wraps on wide screens.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.phone, required this.filters, required this.selected, required this.onFilter});

  final bool phone;
  final List<BeachFilter> filters;
  final BeachFilter selected;
  final ValueChanged<BeachFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final chips = [for (final f in filters) _chip(f)];
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Brand.paper,
        border: Border(bottom: BorderSide(color: Brand.ink, width: 3)),
      ),
      child: phone
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [for (final c in chips) Padding(padding: const EdgeInsets.only(right: 6), child: c)],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Wrap(spacing: 6, runSpacing: 6, children: chips),
            ),
    );
  }

  Widget _chip(BeachFilter f) {
    final on = f.label == selected.label;
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onFilter(f),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: on ? Brand.ink : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Brand.ink, width: 2),
          ),
          child: Text(
            f.label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? Brand.yellow : Brand.ink),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton(this.symbol, this.label, this.onTap);
  final String symbol, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Brand.paper,
          shape: BoxShape.circle,
          border: Border.all(color: Brand.ink, width: 1.5),
          boxShadow: const [BoxShadow(color: Brand.ink, offset: Offset(0, 2))],
        ),
        child: Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1)),
      ),
    ),
  );
}
