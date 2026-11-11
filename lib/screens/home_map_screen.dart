import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../models/beach.dart';
import '../models/beach_filter.dart';
import '../services/beach_scope.dart';
import '../services/map_tiles.dart';
import '../widgets/basemap_layers.dart';
import '../widgets/brand.dart';
import '../widgets/castle_layer.dart';
import '../widgets/search_box.dart';
import '../widgets/site_chrome.dart';
import '../widgets/stamp_and_ticker.dart';
import '../widgets/tide_transition.dart';

/// Home: full-screen map of sandcastles with the floating search/filter panel on top.
class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> with SingleTickerProviderStateMixin {
  final _map = MapController();
  final _panelKey = GlobalKey();
  final _mapKey = GlobalKey();
  late final _fly = AnimationController(vsync: this);
  BeachFilter _filter = BeachFilter.all;
  bool _touched = false; // hides the "drag to explore" hint after the first touch
  bool _ready = false;

  // Current fly-to animation.
  LatLng _fromC = const LatLng(0, 0), _toC = const LatLng(0, 0);
  double _fromZ = 0, _toZ = 0;

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
        _fromZ + (_toZ - _fromZ) * t,
      );
    });
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  /// Space (px) covered by the panel, which castles should stay clear of.
  EdgeInsets _overlayPadding() {
    final mapBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    final panelBox = _panelKey.currentContext?.findRenderObject() as RenderBox?;
    if (mapBox == null || panelBox == null) return EdgeInsets.zero;
    final size = mapBox.size;
    final panel = panelBox.localToGlobal(Offset.zero, ancestor: mapBox) & panelBox.size;
    var p = Brand.isPhone(context)
        ? EdgeInsets.only(top: panel.bottom + 8)
        : EdgeInsets.only(left: panel.right + 12, right: 64);
    // Never squeeze the free area below a usable size.
    if (size.width - p.horizontal < 200) p = p.copyWith(left: 0, right: 0);
    if (size.height - p.vertical < 160) p = p.copyWith(top: 0, bottom: 0);
    return p;
  }

  /// Camera that fits [list] inside the free area, leaving room for castles and name tags.
  ({LatLng center, double zoom}) _fitTarget(List<Beach> list) {
    if (list.isEmpty) list = _beaches;
    final p = _overlayPadding();
    final fit = CameraFit.coordinates(
      coordinates: [for (final b in list) LatLng(b.lat, b.lon)],
      padding: EdgeInsets.fromLTRB(p.left + 80, p.top + 65, p.right + 80, p.bottom + 65),
      maxZoom: list.length > 1 ? 16 : 13, // one castle gets a neighbourhood view
    ).fit(_map.camera);
    return (center: fit.center, zoom: fit.zoom);
  }

  void _flyTo(LatLng center, double zoom, {int ms = 650}) {
    final cam = _map.camera;
    zoom = zoom.clamp(3.0, 18.0);
    if (MediaQuery.disableAnimationsOf(context)) {
      _map.move(center, zoom);
      return;
    }
    _fromC = cam.center;
    _fromZ = cam.zoom;
    _toC = center;
    _toZ = zoom;
    _fly
      ..duration = Duration(milliseconds: ms)
      ..forward(from: 0);
  }

  void _flyToFit(List<Beach> list) {
    final t = _fitTarget(list);
    _flyTo(t.center, t.zoom);
  }

  void _setFilter(BeachFilter f) {
    setState(() => _filter = f);
    final shown = _shown;
    if (shown.isNotEmpty) _flyToFit(shown);
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
    final touchDevice = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;

    return Title(
      title: 'Shore Thing · beach finder',
      color: Brand.ink,
      child: Scaffold(
        body: Column(
          children: [
            DemoBanner(beachCount: repo.beaches.length),
            const SiteHeader(),
            Expanded(
              child: Stack(
                key: _mapKey,
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
                          minZoom: 3,
                          maxZoom: 18,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                          onMapReady: () => WidgetsBinding.instance.addPostFrameCallback((_) {
                            // Re-fit once the panel has been measured, so it doesn't cover any castles.
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
                              visible: {for (final b in _shown) b.slug},
                              onBeachTap: (b) => openBeach(context, b.slug),
                              onClusterTap: _openCluster,
                            ),
                          // Required credits (and MapTiler's logo, on its free plan), bottom-right.
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  // Floating panel
                  Positioned(
                    left: phone ? 8 : 16,
                    right: phone ? 8 : null,
                    top: phone ? 8 : 16,
                    child: _Panel(
                      key: _panelKey,
                      phone: phone,
                      beachCount: repo.beaches.length,
                      regionsLabel: repo.regionsLabel,
                      selected: _filter,
                      noMatches: _shown.isEmpty,
                      onFilter: _setFilter,
                    ),
                  ),
                  // Zoom controls
                  Positioned(
                    right: 14,
                    top: phone ? null : 14,
                    bottom: phone ? 34 : null,
                    child: Column(
                      children: [
                        _RoundButton('+', 'Zoom in', () => _flyTo(_map.camera.center, _map.camera.zoom + 1, ms: 350)),
                        const SizedBox(height: 7),
                        _RoundButton('−', 'Zoom out', () => _flyTo(_map.camera.center, _map.camera.zoom - 1, ms: 350)),
                        const SizedBox(height: 7),
                        _RoundButton('⟲︎', 'Back to all beaches', () => _flyToFit(repo.beaches)),
                      ],
                    ),
                  ),
                  // Hint
                  Positioned(
                    left: 14,
                    bottom: 36, // above the map credits
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
            const SloganTicker(),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.phone,
    required this.beachCount,
    required this.regionsLabel,
    required this.selected,
    required this.noMatches,
    required this.onFilter,
  });

  final bool phone;
  final int beachCount;
  final String regionsLabel;
  final BeachFilter selected;
  final bool noMatches;
  final ValueChanged<BeachFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final f in [BeachFilter.all, ...BeachFilter.activities]) _chip(f),
    ];
    final amenityChips = [for (final f in BeachFilter.amenities) _chip(f)];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!phone) ...[const Text('YOUR OUT-OF-OFFICE STARTS HERE', style: Brand.eyebrow), const SizedBox(height: 10)],
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: phone ? 'Find your kind of ' : 'Find your\nkind of '),
                const TextSpan(
                  text: 'beach.',
                  style: TextStyle(color: Brand.orange, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            style: TextStyle(fontSize: phone ? 28 : 50, fontWeight: FontWeight.w900, height: 1.02, letterSpacing: -1),
          ),
        ),
        SizedBox(height: phone ? 6 : 14),
        Text(
          phone
              ? '$beachCount favorites across $regionsLabel. Tap a sandcastle to dive in.'
              : '$beachCount favorites across $regionsLabel.\nTap a sandcastle to dive in.',
          style: TextStyle(fontSize: phone ? 14 : 17, height: 1.4),
        ),
        SizedBox(height: phone ? 10 : 18),
        const SearchBox(),
        if (!phone) ...[
          const SizedBox(height: 10),
          const Text('Try Asbury Park, Siesta Key or Waikīkī.', style: TextStyle(fontSize: 12)),
        ],
        SizedBox(height: phone ? 10 : 14),
        if (phone)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final c in [...chips, ...amenityChips])
                  Padding(padding: const EdgeInsets.only(right: 6), child: c),
              ],
            ),
          )
        else ...[
          Wrap(spacing: 6, runSpacing: 6, children: chips),
          const SizedBox(height: 10),
          const Text('AMENITIES', style: Brand.eyebrow),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: amenityChips),
        ],
        if (noMatches) ...[
          const SizedBox(height: 10),
          Text(
            'None of our $beachCount list “${selected.label}” yet.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: phone ? null : 410,
          padding: EdgeInsets.all(phone ? 14 : 22),
          decoration: Brand.chunky(color: Brand.paper, shadow: 6),
          child: content,
        ),
        if (!phone) const Positioned(right: -26, top: -20, child: GoodDayStamp()),
      ],
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
