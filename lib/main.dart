import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'services/beach_repository.dart';
import 'services/beach_scope.dart';
import 'widgets/brand.dart';
import 'widgets/wave_intro.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean web addresses (/beach/asbury-park instead of /#/beach/asbury-park).
  // HASH_URLS=true keeps addresses after a # (needed when hosted inside another page).
  if (!const bool.fromEnvironment('HASH_URLS')) usePathUrlStrategy();
  final repo = await BeachRepository.load();
  runApp(ShoreThingApp(repo: repo));
}

class ShoreThingApp extends StatelessWidget {
  ShoreThingApp({super.key, required this.repo, this.intro = true}) : _router = buildRouter(repo);

  final BeachRepository repo;
  final GoRouter _router;

  /// Play the wave intro on top of the first screen (tests turn it off).
  final bool intro;

  @override
  Widget build(BuildContext context) => BeachScope(
    repo: repo,
    child: MaterialApp.router(
      title: 'Shore Thing',
      debugShowCheckedModeBanner: false,
      theme: Brand.theme(),
      routerConfig: _router,
      // The wave intro covers the app for its first 3 seconds while the map loads underneath.
      builder: (context, child) => intro ? _IntroGate(child: child!) : child!,
    ),
  );
}

/// Shows [WaveIntro] over the app once, then removes it.
class _IntroGate extends StatefulWidget {
  const _IntroGate({required this.child});
  final Widget child;

  @override
  State<_IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<_IntroGate> {
  bool _showing = true;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_showing) Positioned.fill(child: WaveIntro(onDone: () => setState(() => _showing = false))),
    ],
  );
}
