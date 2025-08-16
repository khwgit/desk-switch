import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'internal/utils.dart';

typedef StatefulShellRouteMakerWidgetBuilder<T extends RouteData?> = Widget
    Function(
  BuildContext context,
  GoRouterState state,
  T data,
  StatefulNavigationShell shell,
);

typedef StatefulShellRouteMakerPageBuilder<T extends RouteData?> = Page<dynamic>
    Function(
  BuildContext context,
  GoRouterState state,
  T data,
  StatefulNavigationShell shell,
);

typedef StatefulShellRouteMakerRedirect<T extends RouteData?>
    = FutureOr<String?> Function(
  BuildContext context,
  GoRouterState state,
  T data,
);

class StatefulShellRouteMaker<T extends RouteData?> {
  const StatefulShellRouteMaker({
    required ShellNavigationContainerBuilder this.navigatorContainerBuilder,
    this.data,
    this.builder,
    this.pageBuilder,
    this.redirect,
    this.parentNavigatorKey,
    this.restorationScopeId,
  });

  const StatefulShellRouteMaker.indexedStack({
    this.data,
    this.builder,
    this.pageBuilder,
    this.redirect,
    this.parentNavigatorKey,
    this.restorationScopeId,
  }) : navigatorContainerBuilder = null;

  final RouteMakerDataBuilder<T>? data;
  final StatefulShellRouteMakerWidgetBuilder<T>? builder;
  final StatefulShellRouteMakerPageBuilder<T>? pageBuilder;
  final StatefulShellRouteMakerRedirect<T>? redirect;

  final ShellNavigationContainerBuilder? navigatorContainerBuilder;
  final GlobalKey<NavigatorState>? parentNavigatorKey;
  final String? restorationScopeId;

  StatefulShellRoute $route({
    required List<StatefulShellBranch> branches,
  }) {
    T extract(GoRouterState state) {
      return (_stateObjectExpando[state] ??= data?.call(state)) as T;
    }

    Widget builder(
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell child,
    ) {
      final extracted = extract(state);
      final result = this.builder?.call(context, state, extracted, child) ??
          castRoute<StatefulShellRouteData?>(extracted)
              ?.builder(context, state, child);
      if (result != null) return result;
      throw UnimplementedError(
        'One of `build` or `buildPage` must be implemented.',
      );
    }

    Page<dynamic> pageBuilder(
      BuildContext context,
      GoRouterState state,
      StatefulNavigationShell child,
    ) {
      final extracted = extract(state);
      return this.pageBuilder?.call(context, state, extracted, child) ??
          castRoute<StatefulShellRouteData?>(extracted)
              ?.pageBuilder(context, state, child) ??
          const NoOpPage();
    }

    FutureOr<String?> redirect(
      BuildContext context,
      GoRouterState state,
    ) {
      final extracted = extract(state);
      return this.redirect?.call(context, state, extracted);
    }

    if (navigatorContainerBuilder != null) {
      return StatefulShellRoute(
        branches: branches,
        builder: builder,
        pageBuilder: pageBuilder,
        redirect: redirect,
        navigatorContainerBuilder: navigatorContainerBuilder!,
        parentNavigatorKey: parentNavigatorKey,
        restorationScopeId: restorationScopeId,
      );
    }

    return StatefulShellRoute.indexedStack(
      branches: branches,
      builder: builder,
      pageBuilder: pageBuilder,
      redirect: redirect,
      parentNavigatorKey: parentNavigatorKey,
      restorationScopeId: restorationScopeId,
    );
  }

  /// Used to cache [StatefulShellRouteData] that corresponds to a given [GoRouterState]
  /// to minimize the number of times it has to be deserialized.
  static final _stateObjectExpando = Expando<RouteData>(
    'GoRouteState to StatefulShellRouteData expando',
  );
}

class StatefulShellBranchMaker<T extends StatefulShellBranchData?> {
  const StatefulShellBranchMaker({
    this.data,
    this.initialLocation,
    this.navigatorKey,
    this.restorationScopeId,
    this.observers,
  });

  final T Function(GoRouterState state)? data;
  final GlobalKey<NavigatorState>? navigatorKey;
  final String? initialLocation;
  final String? restorationScopeId;
  final List<NavigatorObserver>? observers;

  StatefulShellBranch $branch({
    List<RouteBase> routes = const <RouteBase>[],
  }) {
    return StatefulShellBranch(
      routes: routes,
      navigatorKey: navigatorKey,
      observers: observers,
      initialLocation: initialLocation,
      restorationScopeId: restorationScopeId,
    );
  }
}
