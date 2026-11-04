import 'package:flutter/widgets.dart';

import 'beach_repository.dart';

/// Makes the loaded [BeachRepository] available to every screen:
/// `BeachScope.of(context).beaches`.
class BeachScope extends InheritedWidget {
  const BeachScope({super.key, required this.repo, required super.child});

  final BeachRepository repo;

  static BeachRepository of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BeachScope>()!.repo;

  @override
  bool updateShouldNotify(BeachScope oldWidget) => repo != oldWidget.repo;
}
