import 'package:flutter/material.dart';

import 'brand.dart';

/// Slides a details panel up from the bottom, in the brand style.
/// Used when someone taps a forecast day, a month, a fact tile, etc.
/// Drag it down, tap outside it or press Close to put it away.
Future<void> showBrandSheet(BuildContext context, {required String title, String? subtitle, required Widget child}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Brand.ink.withValues(alpha: .45),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85, maxWidth: 640),
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: Brand.chunky(color: Brand.paper, shadow: 0, radius: 14),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Grab handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: Brand.ink.withValues(alpha: .35), borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Semantics(
                        header: true,
                        child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.15)),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 14)),
                      ],
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded, color: Brand.ink),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: child),
              ),
            ]),
          ),
        ),
      ),
    );

/// One "label ........ value" line inside a sheet.
class SheetRow extends StatelessWidget {
  const SheetRow(this.icon, this.label, this.value, {super.key});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Brand.teal, width: 1.5))),
        child: Row(children: [
          Icon(icon, size: 22, color: Brand.ink),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}
