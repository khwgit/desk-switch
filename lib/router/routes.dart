import 'package:desk_switch/features/app/screens/app_scaffold.dart';
import 'package:desk_switch/features/home/screens/home_screen.dart';
import 'package:desk_switch/features/settings/screens/settings_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_maker/go_router_maker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final appRouteProvider = Provider<AppRoute>(
  (ref) => AppRoute(),
);

class AppRoute {
  List<RouteBase> get routes => [
    $app.$route(
      branches: [
        StatefulShellBranch(
          routes: [
            home.$route(
              path: '/',
              location: (data) => '/',
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            settings.$route(
              path: '/settings',
              location: (data) => '/settings',
            ),
          ],
        ),
      ],
    ),
  ];

  final $app = StatefulShellRouteMaker.indexedStack(
    builder: (context, state, data, shell) => AppScaffold(
      shell: shell,
    ),
  );

  final home = RouteMaker(
    builder: (context, state, data) => const HomeScreen(),
  );

  final settings = RouteMaker(
    builder: (context, state, data) => const SettingsScreen(),
  );
}
