import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'services/beach_repository.dart';
import 'services/beach_scope.dart';
import 'widgets/brand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean web addresses (/beach/asbury-park instead of /#/beach/asbury-park).
  // HASH_URLS=true keeps addresses after a # (needed when hosted inside another page).
  if (!const bool.fromEnvironment('HASH_URLS')) usePathUrlStrategy();
  final repo = await BeachRepository.load();
  runApp(ShoreThingApp(repo: repo));
}

class ShoreThingApp extends StatelessWidget {
  ShoreThingApp({super.key, required this.repo}) : _router = buildRouter(repo);

  final BeachRepository repo;
  final GoRouter _router;

  @override
  Widget build(BuildContext context) => BeachScope(
        repo: repo,
        child: MaterialApp.router(
          title: 'Shore Thing',
          debugShowCheckedModeBanner: false,
          theme: Brand.theme(),
          routerConfig: _router,
        ),
      );
}
