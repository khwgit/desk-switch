import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class GoRouteConfig<DataT extends GoRouteData> {
  const GoRouteConfig(this.location, this.data);
  final String location;
  final DataT? data;

  void go(BuildContext context) {
    return GoRouter.of(context).goRoute(this);
  }

  Future<T?> push<T>(BuildContext context) {
    return GoRouter.of(context).pushRoute(this);
  }

  Future<T?> pushReplacement<T>(BuildContext context) {
    return GoRouter.of(context).pushReplacementRoute(this);
  }

  Future<T?> replace<T>(BuildContext context) {
    return GoRouter.of(context).replaceRoute(this);
  }
}

extension GoRouterExtension on GoRouter {
  void goRoute(GoRouteConfig config) {
    return go(config.location, extra: config.data);
  }

  Future<T?> pushRoute<T>(GoRouteConfig config) {
    return push(config.location, extra: config.data);
  }

  Future<T?> pushReplacementRoute<T>(GoRouteConfig config) {
    return pushReplacement(config.location, extra: config.data);
  }

  Future<T?> replaceRoute<T>(GoRouteConfig config) {
    return replace(config.location, extra: config.data);
  }
}
