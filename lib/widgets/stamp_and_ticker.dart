import 'package:flutter/material.dart';

import 'brand.dart';

/// The rotated orange "100% GOOD DAY ENERGY" stamp.
class GoodDayStamp extends StatelessWidget {
  const GoodDayStamp({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Transform.rotate(
          angle: 0.21, // about 12 degrees
          child: Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Brand.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Brand.ink, width: 3),
            ),
            child: const Text('100%\nGOOD\nDAY ENERGY',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, height: 1.15, color: Brand.ink)),
          ),
        ),
      );
}

/// Orange band with slogans that scroll sideways forever.
class SloganTicker extends StatefulWidget {
  const SloganTicker({super.key});

  @override
  State<SloganTicker> createState() => _SloganTickerState();
}

class _SloganTickerState extends State<SloganTicker> with SingleTickerProviderStateMixin {
  static const _text = 'SUN ON YOUR FACE  ✳︎  SALT IN YOUR HAIR  ✳︎  FIND YOUR HAPPY PLACE  ✳︎  SEE YOU AT THE SHORE  ✳︎  ';
  static const _style = TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Brand.ink, letterSpacing: .3);
  late final _anim = AnimationController(vsync: this, duration: const Duration(seconds: 22));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the device's reduce-motion setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _anim.stop();
    } else if (!_anim.isAnimating) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Measure one copy of the text so the loop is seamless.
    final copy = (TextPainter(
      text: const TextSpan(text: _text, style: _style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout())
        .width;
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: Brand.orange,
        border: Border(top: BorderSide(color: Brand.ink, width: 3)),
      ),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, _) => OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(-copy * _anim.value, 0),
              child: const Text(_text + _text + _text + _text, style: _style, maxLines: 1, softWrap: false),
            ),
          ),
        ),
      ),
    );
  }
}
