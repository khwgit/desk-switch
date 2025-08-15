import 'dart:async';

import 'package:collection/collection.dart';
import 'package:desk_switch/models/server_data.dart';
import 'package:desk_switch/services/communication/receiver_service.dart';
import 'package:desk_switch/services/pair/broadcast_service.dart';
import 'package:desk_switch/services/pair/discovery_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'client_content_providers.g.dart';

// Provider for the list of online servers (future: combine with pins)
@riverpod
Future<List<ServerData>> servers(Ref ref) async {
  await ref.watch(_initDiscoveryProvider.future);
  final localId = ref.watch(
    broadcastServiceProvider.select(
      (state) => state.config?.server.id,
    ),
  );
  final connected = ref.watch(connectedServerProvider);
  final servers = ref.watch(
    discoveryServiceProvider.select(
      (state) => state.servers.values.expand<ServerData>(
        (data) {
          if (data.id == localId) {
            return []; // Don't show local server in the list
          }
          if (data.id == connected?.id) {
            return [data.copyWith(status: connected?.status)];
          }

          return [data.copyWith(status: ServerStatus.online)];
        },
      ).toList(),
    ),
  );

  ref.keepAlive();
  return servers;
}

@riverpod
Future<void> _initDiscovery(Ref ref) async {
  final discoveryService = ref.watch(discoveryServiceProvider.notifier);
  await discoveryService.start();
  ref.keepAlive();
}

@riverpod
ServerData? connectedServer(Ref ref) {
  return ref.watch(
    receiverServiceProvider.select(
      (state) => state.server,
    ),
  );
}

// Notifier for selected server with availability checking
@riverpod
class SelectedServer extends _$SelectedServer {
  @override
  ServerData? build() {
    // Watch the servers stream to check availability
    ref.listen(serversProvider, (previous, next) {
      state = next.when(
        data: (servers) => servers.firstWhereOrNull(
          (server) => server.id == state?.id,
        ),
        loading: () => state, // Keep current state while loading
        error: (error, stackTrace) => null, // Unselect on error
      );
    });

    ref.keepAlive();
    return null;
  }

  void select(ServerData? server) => state = server;
}

// Notifier for pinned server IDs
@riverpod
class PinnedServers extends _$PinnedServers {
  @override
  Set<String> build() => <String>{};

  void pin(String serverId) {
    state = <String>{...state, serverId};
  }

  void unpin(String serverId) {
    state = <String>{...state}..remove(serverId);
  }

  bool isPinned(String serverId) => state.contains(serverId);
}

// @Riverpod(keepAlive: true)
// class AutoConnectPreferences extends _$AutoConnectPreferences {
//   static const String _prefix = 'auto_connect_';

//   @override
//   Future<Map<String, bool>> build() async {
//     final prefs = await SharedPreferences.getInstance();
//     final keys = prefs.getKeys();
//     final autoConnectKeys = keys.where((key) => key.startsWith(_prefix));

//     final preferences = <String, bool>{};
//     for (final key in autoConnectKeys) {
//       final serverId = key.substring(_prefix.length);
//       preferences[serverId] = prefs.getBool(key) ?? false;
//     }

//     return preferences;
//   }

//   Future<void> setAutoConnect(String serverId, bool enabled) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('$_prefix$serverId', enabled);

//     final currentPreferences = state.value ?? {};
//     state = AsyncValue.data({
//       ...currentPreferences,
//       serverId: enabled,
//     });
//   }

//   Future<bool> getAutoConnect(String serverId) async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool('$_prefix$serverId') ?? false;
//   }

//   Future<void> removeAutoConnect(String serverId) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('$_prefix$serverId');

//     final currentPreferences = state.value ?? {};
//     currentPreferences.remove(serverId);
//     state = AsyncValue.data(Map.from(currentPreferences));
//   }
// }
