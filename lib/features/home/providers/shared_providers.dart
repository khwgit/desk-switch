import 'dart:async';

import 'package:desk_switch/core/services/broadcast_service.dart';
import 'package:desk_switch/core/services/client_service.dart';
import 'package:desk_switch/core/services/server_service.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/server_info.dart';
import 'package:kvm_helper/kvm_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_providers.g.dart';

final _kvm = KvmHelper();

// Provider for whether the server is running
@riverpod
bool serverRunning(Ref ref) {
  final state = ref.watch(serverServiceProvider);
  return state == ServerServiceState.running;
}

@riverpod
ServerServiceState serverState(Ref ref) {
  return ref.watch(serverServiceProvider);
}

@riverpod
ClientServiceState clientState(Ref ref) {
  return ref.watch(clientServiceProvider);
}

@riverpod
class Server extends _$Server {
  StreamSubscription? _inputCaptureSubscription;

  @override
  ServerInfo? build() {
    return null;
  }

  Future<void> start() async {
    final serverService = ref.read(serverServiceProvider.notifier);
    final broadcastService = ref.read(broadcastServiceProvider.notifier);
    // final inputCaptureService = ref.watch(inputCaptureServiceProvider.notifier);

    final serverInfo = await serverService.start(
      port: 8080,
      name: null,
    );
    if (serverInfo != null) {
      state = serverInfo;
      await broadcastService.start(serverInfo);

      // Subscribe to input capture and log events
      await _kvm.requestPermission();
      _inputCaptureSubscription?.cancel();
      _inputCaptureSubscription = _kvm.inputs().listen((input) {
        logger.info('🖱️ Captured input: $input');
        serverService.sendInput(input);
      });
    }
  }

  Future<void> stop() async {
    final serverService = ref.read(serverServiceProvider.notifier);
    final broadcastService = ref.read(broadcastServiceProvider.notifier);
    // final inputCaptureService = ref.watch(inputCaptureServiceProvider.notifier);

    await broadcastService.stop();
    // await inputCaptureService.stop();
    await serverService.stop();
    // Cancel input capture subscription
    await _inputCaptureSubscription?.cancel();
    _inputCaptureSubscription = null;
  }
}

@riverpod
class Client extends _$Client {
  StreamSubscription? _inputSubscription;

  @override
  ClientServiceState build() {
    return ClientServiceState.disconnected;
  }

  Future<void> connect(ServerInfo server) async {
    final clientService = ref.read(clientServiceProvider.notifier);
    await clientService.connect(server);
    _inputSubscription?.cancel();
    _inputSubscription = clientService.inputs().listen((input) {
      logger.info('🔌 Received input: $input');
      // _inputCapture.injectInput(input);
    });
  }

  Future<void> disconnect() async {
    final clientService = ref.read(clientServiceProvider.notifier);
    await clientService.disconnect();
    _inputSubscription?.cancel();
    _inputSubscription = null;
  }
}
