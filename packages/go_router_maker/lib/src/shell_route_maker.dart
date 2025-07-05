import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'internal/utils.dart';

typedef ShellRouteMakerWidgetBuilder<T extends RouteData?> = Widget Function(
  BuildContext context,
  GoRouterState state,
  T data,
  Widget child,
);

typedef ShellRouteMakerPageBuilder<T extends RouteData?> = Page<dynamic>
    Function(
  BuildContext context,
  GoRouterState state,
  T data,
  Widget child,
);

typedef ShellRouteMakerRedirect<T extends RouteData?> = FutureOr<String?>
    Function(
  BuildContext context,
  GoRouterState state,
  T data,
);

class ShellRouteMaker<T extends RouteData?> {
  const ShellRouteMaker({
    this.data,
    this.builder,
    this.pageBuilder,
    this.redirect,
    this.navigatorKey,
    this.parentNavigatorKey,
    this.observers,
    this.restorationScopeId,
  });

  final RouteMakerDataBuilder<T>? data;
  final ShellRouteMakerWidgetBuilder<T>? builder;
  final ShellRouteMakerPageBuilder<T>? pageBuilder;
  final ShellRouteMakerRedirect<T>? redirect;

  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final List<NavigatorObserver>? observers;
  final String? restorationScopeId;

  ShellRoute $route({
    List<RouteBase> routes = const <RouteBase>[],
  }) {
    T extract(GoRouterState state) {
      return (_stateObjectExpando[state] ??= data?.call(state)) as T;
    }

    return ShellRoute(
      builder: (context, state, child) {
        final extracted = extract(state);
        final result = builder?.call(context, state, extracted, child) ??
            castRoute<ShellRouteData?>(extracted)
                ?.builder(context, state, child);
        if (result != null) return result;
        throw UnimplementedError(
          'One of `build` or `buildPage` must be implemented.',
        );
      },
      pageBuilder: (context, state, child) {
        final extracted = extract(state);
        return pageBuilder?.call(context, state, extracted, child) ??
            castRoute<ShellRouteData?>(extracted)
                ?.pageBuilder(context, state, child) ??
            const NoOpPage();
      },
      redirect: (context, state) {
        final extracted = extract(state);
        return redirect?.call(context, state, extracted);
      },
      parentNavigatorKey: parentNavigatorKey,
      routes: routes,
      navigatorKey: navigatorKey,
      observers: observers,
      restorationScopeId: restorationScopeId,
    );
  }

  /// Used to cache [ShellRouteData] that corresponds to a given [GoRouterState]
  /// to minimize the number of times it has to be deserialized.
  static final _stateObjectExpando = Expando<RouteData>(
    'GoRouteState to ShellRouteData expando',
  );
}
