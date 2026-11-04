import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';

/// Draws the prototype's sandcastle SVG (viewBox -26 -50 52 56) with a flag
/// that can wave: [flagWave] 0 = still, 1 = squashed to 72% width and skewed 9°.
class SandcastlePainter extends CustomPainter {
  const SandcastlePainter({this.flagWave = 0});
  final double flagWave;

  static Path _body() {
    final p = Path()
      ..moveTo(-20, 0)
      ..cubicTo(-20, -6, -17, -9, -17, -12);
    // Walk the battlements left to right: (dx, dy) steps from the SVG path.
    const steps = [
      [0, -14], [3.4, 0], [0, 3], [3.2, 0], [0, -3], [3.4, 0], [0, 14], [1, 0], // left tower
      [0, -22], [2.4, 0], [0, 2.6], [2.4, 0], [0, -2.6], [2.4, 0], [0, 2.6], [2.4, 0], [0, -2.6], [2.4, 0],
      [0, 22], [1, 0], // middle tower
      [0, -14], [3.4, 0], [0, 3], [3.2, 0], [0, -3], [3.4, 0], [0, 14], // right tower
    ];
    for (final s in steps) {
      p.relativeLineTo(s[0].toDouble(), s[1].toDouble());
    }
    p
      ..cubicTo(17, -9, 20, -6, 20, 0)
      ..close();
    return p;
  }

  static final _bodyPath = _body();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final s = math.min(size.width / 52, size.height / 56);
    canvas.translate(size.width / 2, size.height - 6 * s);
    canvas.scale(s);

    final ink = Paint()..color = Brand.ink;
    // Shadow
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 1.5), width: 46, height: 8),
        Paint()..color = Brand.ink.withValues(alpha: .2));
    // Pole
    canvas.drawLine(
        const Offset(0, -33),
        const Offset(0, -46),
        Paint()
          ..color = Brand.ink
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round);
    // Flag (waves around its left edge)
    canvas.save();
    canvas.translate(0, -42.8);
    canvas.transform((Matrix4.identity()
          ..setEntry(1, 0, math.tan(9 * math.pi / 180) * flagWave) // skewY
          ..scaleByDouble(1 - .28 * flagWave, 1, 1, 1))
        .storage);
    final flag = Path()
      ..moveTo(0, -3.2)
      ..lineTo(10, 0)
      ..lineTo(0, 3.2)
      ..close();
    canvas.drawPath(flag, Paint()..color = Brand.orange);
    canvas.drawPath(
        flag,
        Paint()
          ..color = Brand.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeJoin = StrokeJoin.round);
    canvas.restore();
    // Thick ink outline, then sand fill on top
    canvas.drawPath(_bodyPath, ink);
    canvas.drawPath(
        _bodyPath,
        Paint()
          ..color = Brand.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(_bodyPath, Paint()..color = Brand.sand);
    // Sand details
    final detail = Paint()
      ..color = Brand.sandDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-16.5, -12), const Offset(16.5, -12), detail);
    canvas.drawLine(const Offset(-15, -5), const Offset(-11, -5), detail);
    canvas.drawLine(const Offset(10, -3.5), const Offset(14, -3.5), detail);
    // Door and windows
    final door = Path()
      ..moveTo(-3.6, 0)
      ..lineTo(-3.6, -5.5)
      ..arcTo(Rect.fromCircle(center: const Offset(0, -5.5), radius: 3.6), math.pi, math.pi, false)
      ..lineTo(3.6, 0)
      ..close();
    canvas.drawPath(door, ink);
    canvas.drawCircle(const Offset(-12, -18), 1.4, ink);
    canvas.drawCircle(const Offset(12, -18), 1.4, ink);
    canvas.drawCircle(const Offset(0, -24), 1.6, ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SandcastlePainter old) => old.flagWave != flagWave;
}

/// A tappable castle with its name tag (or a count badge for a cluster).
/// The castle's base sits on the point it marks.
class SandcastleMarker extends StatefulWidget {
  const SandcastleMarker({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.count,
    this.pop = 1,
    this.labelHidden = false,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final int? count;

  /// 0→1 entrance animation progress (castles "pop" up out of the sand).
  final double pop;

  /// Name tag hidden because it would overlap another castle (shown again on hover).
  final bool labelHidden;

  static const castleSize = Size(46, 50);
  static const baseFromTop = 44.0; // the castle's base, measured from the top of the widget

  @override
  State<SandcastleMarker> createState() => _SandcastleMarkerState();
}

class _SandcastleMarkerState extends State<SandcastleMarker> with SingleTickerProviderStateMixin {
  late final _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _hover = false;

  void _setHover(bool v) {
    if (v == _hover) return;
    setState(() => _hover = v);
    if (v && !MediaQuery.disableAnimationsOf(context)) {
      _wave.repeat(reverse: true);
    } else {
      _wave.animateTo(0, duration: const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = widget.pop;
    final showLabel = !widget.labelHidden || _hover;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: Focus(
          onFocusChange: _setHover,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _setHover(true),
            onTap: widget.onTap,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(clipBehavior: Clip.none, children: [
                AnimatedSlide(
                  offset: Offset(0, _hover ? -.06 : 0),
                  duration: const Duration(milliseconds: 300),
                  curve: const Cubic(.3, 1.7, .5, 1),
                  child: AnimatedScale(
                    scale: _hover ? 1.12 : 1,
                    alignment: const Alignment(0, .76),
                    duration: const Duration(milliseconds: 300),
                    curve: const Cubic(.3, 1.7, .5, 1),
                    child: Transform(
                      alignment: const Alignment(0, .76),
                      transform: Matrix4.translationValues(0, 10 * (1 - pop), 0)
                        ..scaleByDouble(.2 + .8 * pop, .2 + .8 * pop, 1, 1),
                      child: Opacity(
                        opacity: pop.clamp(0.0, 1.0),
                        child: AnimatedBuilder(
                          animation: _wave,
                          builder: (_, _) => CustomPaint(
                            size: SandcastleMarker.castleSize,
                            painter: SandcastlePainter(flagWave: _wave.value),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.count != null)
                  Positioned(
                    top: -4,
                    left: 23 + 9,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 22),
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Brand.orange,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: Brand.ink, width: 1.5),
                      ),
                      child: Text('${widget.count}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1)),
                    ),
                  ),
              ]),
              AnimatedOpacity(
                opacity: showLabel ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
                  decoration: BoxDecoration(
                    color: Brand.paper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Brand.ink, width: 1.5),
                    boxShadow: const [BoxShadow(color: Brand.ink, offset: Offset(0, 2))],
                  ),
                  child: Text(widget.label, style: castleLabelStyle),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

const castleLabelStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.5, color: Brand.ink);
