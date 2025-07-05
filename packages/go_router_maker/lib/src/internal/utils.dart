// ignore_for_file: invalid_export_of_internal_element, invalid_use_of_internal_member

import 'package:go_router/go_router.dart';

export 'package:go_router/src/route_data.dart' show NoOpPage;

typedef RouteMakerDataBuilder<T extends RouteData?> = T Function(
  GoRouterState state,
);

T? castRoute<T extends RouteData?>(
  RouteData? data,
) {
  if (data is T) return data;
  return null;
}
