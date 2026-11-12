import 'package:go_router/go_router.dart';

import 'services/beach_repository.dart';
import 'screens/beach_detail_screen.dart';
import 'screens/beach_not_found_screen.dart';
import 'screens/home_map_screen.dart';
import 'screens/search_screen.dart';

/// Web addresses:
///   /                     → the map
///   /search               → search beaches by name
///   /beach/asbury-park    → that beach's page
///   /beach/(anything else) → fuzzy search, or the "not one of our 20 (yet)" page
GoRouter buildRouter(BeachRepository repo) => GoRouter(
      routes: [
        GoRoute(path: '/', pageBuilder: (_, _) => const NoTransitionPage(child: HomeMapScreen())),
        GoRoute(path: '/search', pageBuilder: (_, _) => const NoTransitionPage(child: SearchScreen())),
        GoRoute(
          path: '/beach/:q',
          pageBuilder: (_, state) {
            final q = state.pathParameters['q']!.trim();
            final beach = repo.bySlug(q) ?? repo.find(q);
            return NoTransitionPage(
              key: state.pageKey,
              child: beach != null ? BeachDetailScreen(beach: beach) : BeachNotFoundScreen(query: q),
            );
          },
        ),
      ],
      errorBuilder: (_, _) => const HomeMapScreen(),
    );
