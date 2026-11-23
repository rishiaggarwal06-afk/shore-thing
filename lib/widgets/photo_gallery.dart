import 'package:flutter/material.dart';

import '../models/beach.dart';
import '../models/beach_photo.dart';
import 'beach_scene.dart';
import 'brand.dart';

/// Big swipeable photo at the top of a beach page, with dots and the photo credit.
/// Tapping a photo opens [PhotoViewer] (full screen, pinch to zoom).
/// Beaches without photos yet show the three illustrated scenes instead.
class PhotoGallery extends StatefulWidget {
  const PhotoGallery({super.key, required this.beach});
  final Beach beach;

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.beach;
    final photos = b.photos;
    final count = photos.isEmpty ? 3 : photos.length;
    final phone = Brand.isPhone(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        decoration: Brand.chunky(shadow: 5),
        child: AspectRatio(
          aspectRatio: phone ? 4 / 3 : 16 / 9,
          child: Stack(fit: StackFit.expand, children: [
            PageView.builder(
              controller: _pages,
              itemCount: count,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final scene = BeachScene(palette: b.color, view: i, label: 'Illustrated scene for ${b.name}');
                if (photos.isEmpty) return scene;
                return Semantics(
                  button: true,
                  label: 'Photo ${i + 1} of $count of ${b.name}. Open full screen',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => PhotoViewer.open(context, photos, i, b.name),
                    child: Hero(
                      tag: photos[i].asset,
                      child: Image.asset(photos[i].asset, fit: BoxFit.cover, errorBuilder: (_, _, _) => scene),
                    ),
                  ),
                );
              },
            ),
            // Credit for the photo on screen (required by its license).
            if (photos.isNotEmpty)
              Positioned(
                left: 0,
                bottom: 0,
                right: 70,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      color: Brand.paper.withValues(alpha: .85),
                      child: Text('${photos[_page].artist} · ${photos[_page].license}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
              ),
            // "Expand" hint, bottom-right.
            if (photos.isNotEmpty)
              const Positioned(
                right: 8,
                bottom: 8,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Brand.paper, shape: BoxShape.circle),
                    child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.open_in_full_rounded, size: 18, color: Brand.ink),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
      if (count > 1) ...[
        const SizedBox(height: 10),
        // Dots: which photo you're on. Tapping a dot jumps to that photo.
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < count; i++)
            Semantics(
              button: true,
              label: 'Show photo ${i + 1}',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => _pages.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  width: i == _page ? 22 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i == _page ? Brand.ink : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Brand.ink, width: 1.5),
                  ),
                ),
              ),
            ),
        ]),
      ],
    ]);
  }
}

/// Full-screen photo viewer: swipe between photos, pinch or double-tap to zoom,
/// full credit at the bottom, X to close.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.photos, required this.start, required this.beachName});
  final List<BeachPhoto> photos;
  final int start;
  final String beachName;

  static Future<void> open(BuildContext context, List<BeachPhoto> photos, int start, String beachName) =>
      Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, _, _) => PhotoViewer(photos: photos, start: start, beachName: beachName),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ));

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final _pages = PageController(initialPage: widget.start);
  late int _page = widget.start;
  final _zoom = <int, TransformationController>{};

  @override
  void dispose() {
    _pages.dispose();
    for (final z in _zoom.values) {
      z.dispose();
    }
    super.dispose();
  }

  void _toggleZoom(int i, TapDownDetails at) {
    final z = _zoom[i]!;
    if (z.value.getMaxScaleOnAxis() > 1.01) {
      z.value = Matrix4.identity();
    } else {
      // Zoom 2.5× around the spot that was tapped (it stays under the finger).
      const s = 2.5;
      final p = at.localPosition;
      z.value = Matrix4.identity()
        ..translateByDouble(-p.dx * (s - 1), -p.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.photos[_page];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _pages,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (context, i) {
            final z = _zoom.putIfAbsent(i, TransformationController.new);
            TapDownDetails? lastTap;
            return GestureDetector(
              onDoubleTapDown: (d) => lastTap = d,
              onDoubleTap: () => _toggleZoom(i, lastTap!),
              child: InteractiveViewer(
                transformationController: z,
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Hero(
                    tag: widget.photos[i].asset,
                    child: Image.asset(
                      widget.photos[i].asset,
                      fit: BoxFit.contain,
                      semanticLabel: 'Photo ${i + 1} of ${widget.photos.length} of ${widget.beachName}',
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Top: counter + close button.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(children: [
                Text('${_page + 1} / ${widget.photos.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  iconSize: 30,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ]),
            ),
          ),
        ),
        // Bottom: full credit.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.black.withValues(alpha: .6),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(widget.beachName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Photo: ${p.artist} · ${p.license} · Wikimedia Commons',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                  Text('Pinch or double-tap to zoom', style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
