import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'brand.dart';

/// The 3-second wave intro shown when the app opens, on top of the map.
///
///   0.0–0.6 s  the "shore thing" logo rises in on warm sand
///   0.6–2.0 s  three layers of waves roll along the bottom and creep up
///   2.0–2.3 s  a bigger wave surges over the whole screen
///   2.3–3.0 s  the tide pulls back down and away, revealing the map
///
/// The map is already built underneath, so there's no extra waiting.
/// Tapping skips ahead to the tide going out. With the phone's Reduce Motion
/// setting on, it's a short fade instead.
class WaveIntro extends StatefulWidget {
  const WaveIntro({super.key, required this.onDone});

  /// Called when the intro has finished and should be removed.
  final VoidCallback onDone;

  @override
  State<WaveIntro> createState() => _WaveIntroState();
}

class _WaveIntroState extends State<WaveIntro> with TickerProviderStateMixin {
  static const _total = Duration(milliseconds: 3000);

  // Timeline marks, as fractions of the 3 seconds.
  static const _logoEnd = .2; // 0.6 s
  static const _surgeStart = .66; // 2.0 s
  static const _surgeEnd = .77; // 2.3 s

  late final AnimationController _t = AnimationController(vsync: this, duration: _total);

  // Keeps the waves moving sideways for as long as the intro is up.
  late final AnimationController _sway = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  bool _reduceMotion = false;
  bool _hapticDone = false;

  @override
  void initState() {
    super.initState();
    _t.addListener(() {
      if (!_hapticDone && _t.value >= _surgeEnd) {
        _hapticDone = true;
        HapticFeedback.lightImpact(); // a small "splash" as the wave breaks
      }
    });
    _t.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t.isAnimating || _t.value > 0) return;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _t.duration = const Duration(milliseconds: 600);
      _sway.stop();
    }
    // Start the clock only once the first frames are on screen: the map underneath does
    // a lot of work as the app opens, and the intro shouldn't play while nothing is visible.
    WidgetsBinding.instance.endOfFrame.then((_) => WidgetsBinding.instance.endOfFrame).then((_) {
      if (mounted && !_t.isAnimating && _t.value == 0) _t.forward();
    });
  }

  @override
  void dispose() {
    _t.dispose();
    _sway.dispose();
    super.dispose();
  }

  /// Tap to skip: jump to the moment the tide starts going out.
  void _skip() {
    if (_reduceMotion || _t.value >= _surgeEnd) return;
    _t.forward(from: _surgeEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Shore Thing',
      button: true,
      onTapHint: 'Skip intro',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        // The intro sits above the app's pages, so it brings its own Material: without one,
        // Flutter marks text with a yellow "missing style" underline.
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedBuilder(
            animation: Listenable.merge([_t, _sway]),
            builder: (context, _) => _reduceMotion ? _fade() : _waves(context),
          ),
        ),
      ),
    );
  }

  /// Reduce Motion: the logo on sand, fading away.
  Widget _fade() => Opacity(
    opacity: (1 - _t.value).clamp(0.0, 1.0),
    child: const ColoredBox(
      color: Brand.paper,
      child: Center(child: _Logo()),
    ),
  );

  Widget _waves(BuildContext context) {
    final t = _t.value;
    // Water level as a fraction of screen height measured from the bottom (1 = covers it all).
    double level;
    if (t < _surgeStart) {
      level = .12 + .2 * Curves.easeInOut.transform(t / _surgeStart); // gentle creep up to 32%
    } else if (t < _surgeEnd) {
      level = .32 + .9 * Curves.easeIn.transform((t - _surgeStart) / (_surgeEnd - _surgeStart)); // surge
    } else {
      level = 1.22;
    }
    // After the surge the whole sea slides down and off the bottom, uncovering the map.
    final retreat = t <= _surgeEnd ? 0.0 : Curves.easeInOutCubic.transform((t - _surgeEnd) / (1 - _surgeEnd));
    final logoIn = Curves.easeOutCubic.transform((t / _logoEnd).clamp(0.0, 1.0));

    return Stack(
      fit: StackFit.expand,
      children: [
        // Sand and logo: hidden for good once the wave has covered them.
        if (t < _surgeEnd)
          ColoredBox(
            color: Brand.paper,
            child: Center(
              child: Opacity(
                opacity: logoIn,
                child: Transform.translate(offset: Offset(0, 24 * (1 - logoIn)), child: const _Logo()),
              ),
            ),
          ),
        Transform.translate(
          offset: Offset(0, retreat * MediaQuery.sizeOf(context).height * 1.3),
          child: CustomPaint(
            painter: _SeaPainter(level: level, phase: _sway.value),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: const [
        TextSpan(text: 'shore '),
        TextSpan(
          text: 'thing',
          style: TextStyle(color: Brand.ocean),
        ),
      ],
    ),
    textScaler: TextScaler.noScaling, // a fixed-size logo, like an app icon
    style: Brand.title(46).copyWith(height: 1),
  );
}

/// Three layers of waves, back to front, each with a white foam line on its crest.
class _SeaPainter extends CustomPainter {
  const _SeaPainter({required this.level, required this.phase});

  /// How high the water reaches, as a fraction of the height from the bottom.
  final double level;

  /// 0→1, repeating: moves the waves sideways.
  final double phase;

  static const _layers = [
    // colour, how far above the front wave, wave height, wavelength, speed
    (Color(0xFFA9E4E8), 46.0, 10.0, 1.15, 1.0),
    (Brand.water, 22.0, 12.0, .9, -1.4),
    (Brand.ocean, 0.0, 14.0, .7, 1.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final front = size.height * (1 - level);
    for (final (color, lift, amp, wave, speed) in _layers) {
      final top = front - lift;
      final path = Path()..moveTo(0, size.height);
      final crest = Path();
      final length = size.width * wave;
      for (var x = 0.0; x <= size.width + 4; x += 4) {
        final y = top + amp * math.sin(2 * math.pi * (x / length + phase * speed));
        path.lineTo(x, y);
        x == 0 ? crest.moveTo(x, y) : crest.lineTo(x, y);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
        crest,
        Paint()
          ..color = Colors.white.withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SeaPainter old) => old.level != level || old.phase != phase;
}
