import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/beach_scope.dart';
import 'brand.dart';

/// Opens a beach page for a search or a castle tap.
/// Known beach → `/beach/slug`; unknown name → `/beach/what-they-typed` (the "not one of our ten" page).
/// Plays the tide transition unless the device asks for reduced motion.
void openBeach(BuildContext context, String query) {
  final repo = BeachScope.of(context);
  final beach = repo.bySlug(query) ?? repo.find(query);
  final path = beach != null ? '/beach/${beach.slug}' : '/beach/${Uri.encodeComponent(query.trim())}';
  final router = GoRouter.of(context);
  if (_tiding || MediaQuery.disableAnimationsOf(context)) {
    router.go(path);
    return;
  }
  _tiding = true;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Tide(
      name: beach?.name ?? query.trim(),
      onCovered: () => router.go(path),
      onDone: () {
        entry.remove();
        _tiding = false;
      },
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
}

bool _tiding = false;

const _colors = [Color(0xFFBFEEF5), Color(0xFF6FD3E3), Brand.ocean];

// Timings from the prototype (milliseconds).
const _stagger = 120, _riseMs = 700, _holdMs = 350, _fallMs = 850;
const _riseEnd = _stagger * 2 + _riseMs;
const _fallStart = _riseEnd + _holdMs;
const _total = _fallStart + _stagger * 2 + _fallMs;
const _riseCurve = Cubic(.3, .1, .25, 1);
const _fallCurve = Cubic(.55, 0, .6, 1);

/// Three water layers rush up over the screen, the page swaps underneath,
/// then the tide pulls back (top layer first) to reveal the beach.
class _Tide extends StatefulWidget {
  const _Tide({required this.name, required this.onCovered, required this.onDone});
  final String name;
  final VoidCallback onCovered;
  final VoidCallback onDone;

  @override
  State<_Tide> createState() => _TideState();
}

class _TideState extends State<_Tide> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: _total));
  bool _swapped = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (!_swapped && _c.value * _total >= _riseEnd) {
        _swapped = true;
        widget.onCovered();
      }
    });
    _c.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// How far down (0 = covering the screen, 1 = fully below it) layer [i] is at time [ms].
  double _down(int i, double ms) {
    if (ms < _fallStart) {
      final p = ((ms - i * _stagger) / _riseMs).clamp(0.0, 1.0);
      return 1 - _riseCurve.transform(p);
    }
    final order = _colors.length - 1 - i; // top layer leaves first
    final p = ((ms - _fallStart - order * _stagger) / _fallMs).clamp(0.0, 1.0);
    return _fallCurve.transform(p);
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height + 80;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final ms = _c.value * _total;
            return Stack(children: [
              for (var i = 0; i < _colors.length; i++)
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, h * _down(i, ms)),
                    child: _Layer(
                      color: _colors[i],
                      shift: (ms / 2600) * (i.isOdd ? -1 : 1),
                      label: i == _colors.length - 1 ? widget.name : null,
                    ),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Layer extends StatelessWidget {
  const _Layer({required this.color, required this.shift, this.label});
  final Color color;
  final double shift;
  final String? label;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: ColoredBox(color: color)),
        Positioned(
          left: 0,
          right: 0,
          top: -38,
          height: 40,
          child: CustomPaint(painter: _CrestPainter(color, shift)),
        ),
        if (label != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('✳︎ $label',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: Brand.font, fontFamilyFallback: Brand.fontFallback, color: Brand.paper, fontSize: 42, fontWeight: FontWeight.w900, decoration: TextDecoration.none)),
            ),
          ),
      ]);
}

/// The wavy white-edged crest from the prototype's SVG, tiled and sliding sideways.
class _CrestPainter extends CustomPainter {
  _CrestPainter(this.color, this.shift);
  final Color color;
  final double shift; // in tile widths

  @override
  void paint(Canvas canvas, Size size) {
    const tile = 240.0;
    final sy = size.height / 40;
    final start = -tile + (shift % 1) * tile;
    final curve = Path()..moveTo(start, 20 * sy);
    for (var x = start; x < size.width + tile; x += tile) {
      // C40 0 80 0 120 20 S200 40 240 20
      curve.cubicTo(x + 40, 0, x + 80, 0, x + 120, 20 * sy);
      curve.cubicTo(x + 160, 40 * sy, x + 200, 40 * sy, x + 240, 20 * sy);
    }
    final fill = Path.from(curve)
      ..lineTo(size.width + tile, size.height + 2)
      ..lineTo(start, size.height + 2)
      ..close();
    canvas.drawPath(fill, Paint()..color = color);
    canvas.drawPath(
        curve,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.white.withValues(alpha: .9));
  }

  @override
  bool shouldRepaint(_CrestPainter old) => old.shift != shift || old.color != color;
}
