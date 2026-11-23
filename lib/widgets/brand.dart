import 'package:flutter/material.dart';

/// Shore Thing's look: colours, the serif headline font, and soft rounded cards.
///
/// Nov 2026 redesign: the old thick ink outlines and hard offset shadows (a "neo-brutalist"
/// look) made every screen feel boxy and generated, so cards are now rounded with soft,
/// diffused shadows, headings use a serif display font, and the yellow is an accent
/// (highlights like "Today") instead of a slab on every screen.
class Brand {
  // Colours ("sunlit coast").
  static const ink = Color(0xFF12343B); // deep sea green: text and dark surfaces
  static const inkSoft = Color(0xFF55696D); // secondary text
  static const yellow = Color(0xFFFFD84D); // sun: highlights only
  static const orange = Color(0xFFFF7A59); // coral accent
  static const paper = Color(0xFFFBF7EF); // sand-cream page background
  static const teal = Color(0xFFCFE9E6); // light lagoon: dividers, quiet fills
  static const ocean = Color(0xFF14A3B4); // sea
  static const sand = Color(0xFFF4E2B8);
  static const sandDark = Color(0xFFD9A94F);

  // Soft tints for icon bubbles and highlighted cards.
  static const sunTint = Color(0xFFFFF1BF);
  static const lagoonTint = Color(0xFFDDF2F0);
  static const coralTint = Color(0xFFFFE4DB);
  static const sandTint = Color(0xFFF6ECD6);

  /// Bundled Liberation Sans (same letter widths as Arial) for body text.
  static const font = 'LiberationSans';

  /// Bundled DM Serif Display (SIL Open Font License) for headings and the wordmark.
  static const display = 'DMSerifDisplay';

  /// Bundled DejaVu Sans supplies symbols Liberation Sans lacks (✳ ↗ ☀ ☂ ⚑),
  /// so iPhones don't swap in colourful emoji.
  static const fontFallback = ['DejaVuSans'];

  /// Phones get the compact layout below this width (same as the CSS breakpoint).
  static const phoneBreakpoint = 760.0;
  static bool isPhone(BuildContext c) => MediaQuery.sizeOf(c).width <= phoneBreakpoint;

  /// Serif heading at [size]: page titles ~34, section titles ~26, card titles ~20.
  static TextStyle title(double size, {Color color = ink}) =>
      TextStyle(fontFamily: display, fontSize: size, height: 1.1, color: color, fontWeight: FontWeight.w400);

  /// Rounded card with a soft shadow and no outline.
  /// [shadow] sets how lifted it looks (0 = flat); [radius] the corner rounding.
  static BoxDecoration card({Color color = Colors.white, double shadow = 4, double radius = 18}) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: shadow > 0
        ? [
            BoxShadow(color: ink.withValues(alpha: .07), blurRadius: shadow * 4, offset: Offset(0, shadow)),
            BoxShadow(color: ink.withValues(alpha: .04), blurRadius: 2, offset: const Offset(0, 1)),
          ]
        : null,
  );

  /// Older name for [card], kept so existing screens keep working. [border] is ignored
  /// (no more outlines); a [radius] of 0 means the standard rounding.
  static BoxDecoration chunky({Color color = Colors.white, double shadow = 4, double radius = 0, double border = 0}) =>
      card(color: color, shadow: shadow, radius: radius > 0 ? radius : 18);

  static ThemeData theme() => ThemeData(
    fontFamily: font,
    fontFamilyFallback: fontFallback,
    scaffoldBackgroundColor: paper,
    colorScheme: ColorScheme.fromSeed(seedColor: ocean, primary: ink, surface: paper),
    textTheme: const TextTheme().apply(bodyColor: ink, displayColor: ink),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: ink),
  );

  /// Small label above a title (sentence case, not shouty capitals).
  static const eyebrow = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: inkSoft);
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: vertical),
        child: child,
      ),
    ),
  );
}

/// Link-style text with the underline drawn as a thin line below the text.
/// (TextDecoration.underline sits too close to the letters on iPhone.)
class UnderlinedText extends StatelessWidget {
  const UnderlinedText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(bottom: 2),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Brand.ink, width: 1.5)),
    ),
    child: Text(text, style: style),
  );
}
