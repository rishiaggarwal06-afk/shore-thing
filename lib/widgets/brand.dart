import 'package:flutter/material.dart';

/// Shore Thing brand colours and the "chunky" look (thick ink border + hard shadow).
class Brand {
  static const ink = Color(0xFF123D40);
  static const yellow = Color(0xFFFFE14D);
  static const orange = Color(0xFFFF7F50);
  static const paper = Color(0xFFFFF9E9);
  static const teal = Color(0xFF98D7D0);
  static const ocean = Color(0xFF0AB0C6);
  static const sand = Color(0xFFFFE38A);
  static const sandDark = Color(0xFFD9A94F);

  /// Bundled Liberation Sans (same letter widths as Arial).
  static const font = 'LiberationSans';

  /// Phones get the compact layout below this width (same as the CSS breakpoint).
  static const phoneBreakpoint = 760.0;
  static bool isPhone(BuildContext c) => MediaQuery.sizeOf(c).width <= phoneBreakpoint;

  static BoxDecoration chunky({Color color = Colors.white, double shadow = 5, double radius = 0, double border = 3}) =>
      BoxDecoration(
        color: color,
        border: Border.all(color: ink, width: border),
        borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
        boxShadow: shadow > 0 ? [BoxShadow(color: ink, offset: Offset(shadow, shadow))] : null,
      );

  static ThemeData theme() => ThemeData(
        fontFamily: font,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: ocean, primary: ink, surface: paper),
        textTheme: const TextTheme().apply(bodyColor: ink, displayColor: ink),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: ink),
      );

  static const eyebrow = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: ink);
}

/// Content column: max 1100px wide, centred, 16px side gutter.
class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child, this.vertical = 20});
  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1132),
          child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: vertical), child: child),
        ),
      );
}
