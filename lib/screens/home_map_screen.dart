import 'dart:async';
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
import '../widgets/beach_preview.dart';
import '../widgets/brand.dart';
import '../widgets/castle_layer.dart';
import '../widgets/site_chrome.dart';
import '../widgets/tide_transition.dart';

/// Home: the map of sandcastles, the filter chips in a strip above it, and a
/// rotating row of up to 10 beach cards along the bottom. Tapping a castle opens
/// that beach's page; tapping a card opens a mini preview with Back / View full page.
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
  Beach? _preview; // beach whose mini card is open
  double _previewH = 0; // its measured height, so the map can keep the castle above it
  final _previewKey = GlobalKey();

  // The card row: up to 10 beaches, picked at random from the ones the filter lets through.
  static const _maxCards = 10;
  List<Beach> _picks = const [];
  String _picksFor = '';
  PageController? _cards; // remade when the card width changes (phone ↔ wide screen)
  double _cardsFraction = 0;
  Timer? _rotate;
  DateTime _pauseUntil = DateTime(0); // a touch on the cards pauses the rotation for a bit

  /// The row loops forever, so it starts far from page 0 and can be swiped either way.
  int get _basePage => _picks.length * 500;

  /// Space the cards and credits take at the bottom of the map; the map keeps castles clear of it.
  double _bottomInset = 0;
  double _cardsBottom = 0; // where the card row / preview starts, above the credits

  // Current fly-to animation.
  LatLng _fromC = const LatLng(0, 0), _toC = const LatLng(0, 0);
  double _fromZ = 0, _toZ = 0;
  double _dip = 0; // how far to zoom out mid-flight on long hops (e.g. Jersey → Hawaiʻi)

  List<Beach> get _beaches => BeachScope.of(context).beaches;
  List<Beach> get _shown => _beaches.where(_filter.matches).toList();

  @override
  void initState() {
    super.initState();
    _rotate = Timer.periodic(const Duration(seconds: 5), _tick);
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

  /// Every 5 seconds, slide to the next card (unless someone's using the row or a preview is open).
  void _tick(Timer _) {
    final c = _cards;
    if (!mounted || c == null || !c.hasClients || _preview != null || _picks.length < 2) return;
    if (MediaQuery.disableAnimationsOf(context) || DateTime.now().isBefore(_pauseUntil)) return;
    c.nextPage(duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _rotate?.cancel();
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
    zoom = zoom.clamp(1.0, 18.0);
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
      _preview = null;
    });
    final shown = _shown;
    if (shown.isNotEmpty) _flyToFit(shown);
  }

  /// Pick up to 10 beaches for the card row (new picks each time the filter changes).
  void _pickCards(List<Beach> shown) {
    if (_picksFor == _filter.label && _picks.isNotEmpty) return;
    _picks = ([...shown]..shuffle()).take(_maxCards).toList();
    _picksFor = _filter.label;
    if (_cards?.hasClients ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _cards?.jumpToPage(_basePage));
    }
  }

  /// A card was tapped: open its mini preview and fly the map to the beach, above the preview.
  void _openPreview(Beach b) {
    HapticFeedback.selectionClick();
    setState(() {
      _preview = b;
      _touched = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _preview != b) return;
      final box = _previewKey.currentContext?.findRenderObject() as RenderBox?;
      setState(() => _previewH = box?.size.height ?? 0);
      _bottomInset = _cardsBottom + _previewH; // so the fly-to below keeps the castle above the preview
      // Close enough to see the town, or closer if the user has already zoomed in.
      final t = _fitTarget([b], maxZoom: math.max(10, _map.camera.zoom));
      _flyTo(t.center, t.zoom, ms: 800);
    });
  }

  void _closePreview() => setState(() => _preview = null);

  PageController _cardsController(double fraction) {
    if (_cards == null || fraction != _cardsFraction) {
      final old = _cards;
      final page = (old?.hasClients ?? false) ? old!.page?.round() ?? _basePage : _basePage;
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
    _pickCards(shown);
    // Bottom of the map, from the bottom up: credits bar, then the card row.
    final textScale = MediaQuery.textScalerOf(context);
    final creditsH = math.max(16.0, textScale.scale(11) * 1.25) + 8 + safeBottom;
    final cardH = BeachCard.heightFor(context);
    final cardsBottom = _cardsBottom = creditsH + 4;
    _bottomInset = _preview != null
        ? cardsBottom + _previewH
        : shown.isEmpty
        ? creditsH
        : cardsBottom + cardH;
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
              child: LayoutBuilder(
                builder: (context, box) {
                  final mapH = box.maxHeight;
                  return Stack(
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
                              minZoom: 1,
                              maxZoom: 18,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                              ),
                              onTap: (_, _) => _closePreview(), // tapping the map closes the preview
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
                                  tileBuilder: (context, tile, _) =>
                                      ColorFiltered(colorFilter: tiles.tint, child: tile),
                                ),
                              if (_ready)
                                CastleLayer(
                                  beaches: repo.beaches,
                                  visible: {for (final b in shown) b.slug},
                                  selected: _preview?.slug,
                                  onBeachTap: (b) => openBeach(context, b.slug), // straight to the beach page
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
                      // The card row: up to 10 beaches, sliding along every few seconds. Hidden while a preview is open.
                      if (shown.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: cardsBottom,
                          height: cardH,
                          // Offstage hides the row under the preview but keeps its place, so Back returns to the same card.
                          child: Offstage(
                            offstage: _preview != null,
                            child: Listener(
                              // Touching the row pauses the rotation, so it never slides away under a finger.
                              onPointerDown: (_) => _pauseUntil = DateTime.now().add(const Duration(seconds: 12)),
                              // Let a mouse drag the cards too (on the website), not just fingers and trackpads.
                              child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context)
                                    .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                                child: PageView.builder(
                                  controller: _cardsController(phone ? .9 : math.min(.9, 420 / width)),
                                  // No itemCount: the row loops, so card 10 is followed by card 1 again.
                                  itemBuilder: (context, i) {
                                    final b = _picks[i % _picks.length];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      child: BeachCard(beach: b, selected: false, onTap: () => _openPreview(b)),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      // The mini preview: covers the bottom part of the map only (never the top 12%).
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: cardsBottom,
                        top: mapH * .12,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 560),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, a) => SlideTransition(
                                position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(a),
                                child: FadeTransition(opacity: a, child: child),
                              ),
                              child: _preview == null
                                  ? const SizedBox.shrink()
                                  : BeachPreview(
                                      key: _previewKey,
                                      beach: _preview!,
                                      onBack: _closePreview,
                                      onOpen: () => openBeach(context, _preview!.slug),
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
                              decoration: Brand.card(color: Colors.white, shadow: 3),
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
                            _RoundButton(
                              Icons.add_rounded,
                              'Zoom in',
                              () => _flyTo(_map.camera.center, _map.camera.zoom + 1, ms: 350),
                            ),
                            const SizedBox(height: 7),
                            _RoundButton(
                              Icons.remove_rounded,
                              'Zoom out',
                              () => _flyTo(_map.camera.center, _map.camera.zoom - 1, ms: 350),
                            ),
                            const SizedBox(height: 7),
                            _RoundButton(Icons.zoom_out_map_rounded, 'Back to all beaches', () {
                              _closePreview();
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
                              decoration: Brand.card(color: Colors.white.withValues(alpha: .92), shadow: 2, radius: 20),
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
                  );
                },
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
      decoration: const BoxDecoration(color: Brand.paper),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: on ? Brand.card(color: Brand.ink, shadow: 2, radius: 999) : Brand.card(shadow: 1.5, radius: 999),
          child: Text(
            f.label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: on ? Colors.white : Brand.ink),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
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
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: Brand.card(shadow: 3, radius: 21),
        child: Icon(icon, size: 22, color: Brand.ink),
      ),
    ),
  );
}
