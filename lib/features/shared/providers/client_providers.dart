import 'dart:async';

import 'package:desk_switch/core/services/client/discovery_service.dart';
import 'package:desk_switch/core/services/client/injection_service.dart';
import 'package:desk_switch/core/services/client/receiver_service.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/server_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'client_providers.g.dart';

enum ClientState {
  connected,
  connecting,
  disconnected,
  disconnecting,
}

@Riverpod(keepAlive: true)
class Client extends _$Client {
  @override
  ClientState build() {
    final injectionService = ref.read(injectionServiceProvider.notifier);

    ref.listen(receiverServiceProvider, (prev, next) {
      final message = next.message;
      if (message is InputMessage) {
        logger.info('🔌 Received input: $message');
        injectionService.injectInput(message.input);
      }
    });

    return ClientState.disconnected;
  }

  Future<void> start() async {
    final discoveryService = ref.read(discoveryServiceProvider.notifier);
    await discoveryService.start();
  }

  Future<void> stop() async {
    final discoveryService = ref.read(discoveryServiceProvider.notifier);
    await discoveryService.stop();
  }

  Future<void> refresh() async {
    await stop();
    await start();
  }

  Future<void> connect(ServerData server) async {
    state = ClientState.connecting;
    final receiverService = ref.read(receiverServiceProvider.notifier);
    await receiverService.connect(server);
    state = ClientState.connected;
  }

  Future<void> disconnect() async {
    state = ClientState.disconnecting;
    final receiverService = ref.read(receiverServiceProvider.notifier);
    await receiverService.disconnect();
    state = ClientState.disconnected;
  }
}
