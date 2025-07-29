import 'dart:async';

import 'package:desk_switch/core/services/permission_service.dart';
import 'package:desk_switch/core/services/server/broadcast_service.dart';
import 'package:desk_switch/core/services/server/capture_service.dart';
import 'package:desk_switch/core/services/server/transmitter_service.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/server_profile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_providers.g.dart';

enum ServerState {
  stopped,
  starting,
  running,
  stopping,
}

@riverpod
class Server extends _$Server {
  @override
  ServerState build() {
    final captureService = ref.watch(captureServiceProvider.notifier);
    final transmitterService = ref.watch(transmitterServiceProvider.notifier);

    ref.listen(
      captureServiceProvider.select((state) => state.package),
      (previous, next) {
        if (next == null) return;
        transmitterService.send(next);
      },
    );

    ref.listen(
      transmitterServiceProvider.select((state) => state.package),
      (previous, next) {
        if (next == null) return;
        switch (next.message) {
          case InputMessage _:
            // Impossible to happen
            break;
          case DeviceMessage message:
            captureService.updateDevice(
              next.id,
              monitors: message.monitors,
            );
            break;
        }
      },
    );

    return ServerState.stopped;
  }

  Future<void> start() async {
    state = ServerState.starting;
    const profile = ServerProfile(
      name: 'Server 1',
      broadcastPort: 12345,
      connectionPort: 12346,
    );
    final permissionService = ref.read(permissionServiceProvider.notifier);
    final transmitterService = ref.read(transmitterServiceProvider.notifier);
    final broadcastService = ref.read(broadcastServiceProvider.notifier);
    final captureService = ref.read(captureServiceProvider.notifier);

    final permissionGranted = await permissionService.isPermissionGranted();
    if (!permissionGranted) {
      // TODO: Show error message
      return;
    }

    final server = await transmitterService.start(
      port: profile.connectionPort,
      name: profile.name,
    );
    if (server != null) {
      await Future.wait([
        broadcastService.start(
          port: profile.broadcastPort,
          server: server,
        ),
        captureService.start(),
      ]);
    }
    state = ServerState.running;
  }

  Future<void> stop() async {
    state = ServerState.stopping;
    final transmitterService = ref.read(transmitterServiceProvider.notifier);
    final broadcastService = ref.read(broadcastServiceProvider.notifier);
    final captureService = ref.read(captureServiceProvider.notifier);

    await Future.wait([
      transmitterService.stop(),
      broadcastService.stop(),
      captureService.stop(),
    ]);
    state = ServerState.stopped;
  }
}
