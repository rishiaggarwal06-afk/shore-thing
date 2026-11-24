import 'package:flutter/material.dart';

/// Shore Thing's look: "cabana stripes". Colours, the headline font, and soft rounded cards.
///
/// The user picked this direction (Nov 2026) from the samples page: a striped umbrella awning
/// across the top, pool-tile teal, mango orange and friendly rounded type. Cards are rounded with soft shadows and no outlines (the
/// old thick-outline, hard-shadow style made every screen feel boxy and generated).
class Brand {
  // Colours.
  static const ink = Color(0xFF23302F); // dark green-grey: text and dark surfaces
  static const inkSoft = Color(0xFF5E6B69); // secondary text
  static const ocean = Color(0xFF2E8C99); // pool-tile teal: the main brand colour, awning stripes
  static const orange = Color(0xFFF2A541); // mango: selected chips, flags, counts
  static const yellow = Color(0xFFFFD166); // sun: highlights like the selected name tag
  static const paper = Color(0xFFF7F3EA); // warm off-white page background
  static const teal = Color(0xFFD5ECEC); // light lagoon: dividers, quiet fills
  static const sand = Color(0xFFEFD9A7); // land on the map, photo placeholders
  static const sandDark = Color(0xFFC9A86A);

  // Soft tints for icon bubbles and highlighted cards.
  static const sunTint = Color(0xFFFFF0CC);
  static const lagoonTint = Color(0xFFDDF1F2);
  static const coralTint = Color(0xFFFDE6CC);
  static const sandTint = Color(0xFFF3EAD6);

  /// Map water: one flat sea colour.
  static const water = Color(0xFF5BBFC9);

  /// Bundled Plus Jakarta Sans (SIL Open Font License): one clean font for all text.
  static const font = 'PlusJakartaSans';

  /// Headings use the same font, extra bold.
  static const display = font;

  /// Bundled DejaVu Sans supplies symbols Liberation Sans lacks (✳ ↗ ☀ ☂ ⚑),
  /// so iPhones don't swap in colourful emoji.
  static const fontFallback = ['DejaVuSans'];

  /// Phones get the compact layout below this width (same as the CSS breakpoint).
  static const phoneBreakpoint = 760.0;
  static bool isPhone(BuildContext c) => MediaQuery.sizeOf(c).width <= phoneBreakpoint;

  /// Heading at [size]: page titles ~34, section titles ~24, card titles ~20.
  static TextStyle title(double size, {Color color = ink}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        height: 1.15,
        letterSpacing: -.4,
        color: color,
        fontWeight: FontWeight.w800,
      );

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
