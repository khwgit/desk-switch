import 'package:desk_switch/core/errors/app_error.dart';
import 'package:desk_switch/models/profile.dart';
import 'package:desk_switch/models/server_data.dart';
import 'package:desk_switch/services/communication/receiver_service.dart';
import 'package:desk_switch/services/communication/transmitter_service.dart';
import 'package:desk_switch/services/control/capture_service.dart';
import 'package:desk_switch/services/pair/broadcast_service.dart';
import 'package:desk_switch/services/permission_service.dart';
import 'package:desk_switch/services/switch/switch_state.dart';
import 'package:desk_switch/services/switch_service.dart';
import 'package:desk_switch/services/system_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kvm.freezed.dart';
part 'kvm.g.dart';

enum KvmMode {
  idle,
  client,
  server,
}

enum KvmStatus {
  idle,
  connected,
  connecting,
  disconnecting,
  booting,
  serving,
  stopping;

  KvmMode get mode => switch (this) {
    idle => KvmMode.idle,
    booting => KvmMode.server,
    serving => KvmMode.server,
    stopping => KvmMode.server,
    connected => KvmMode.client,
    connecting => KvmMode.client,
    disconnecting => KvmMode.client,
  };

  bool get isServerMode => mode == KvmMode.server;
  bool get isClientMode => mode == KvmMode.client;
}

@freezed
sealed class KvmState with _$KvmState {
  const factory KvmState({
    @Default(KvmStatus.idle) KvmStatus status,
  }) = _KvmState;

  const KvmState._();
}

@riverpod
class Kvm extends _$Kvm {
  late PermissionService _permission;
  late ReceiverService _receiver;
  late TransmitterService _transmitter;
  late SystemService _system;
  late BroadcastService _broadcast;
  late CaptureService _capture;

  ProviderSubscription<AsyncValue<SwitchState>>? _sub;

  @override
  KvmState build() {
    _permission = ref.watch(permissionServiceProvider.notifier);
    _transmitter = ref.watch(transmitterServiceProvider.notifier);
    _receiver = ref.watch(receiverServiceProvider.notifier);
    _system = ref.watch(systemServiceProvider.notifier);
    _broadcast = ref.watch(broadcastServiceProvider.notifier);
    _capture = ref.watch(captureServiceProvider.notifier);

    return const KvmState();
  }

  Future<void> connect(ServerData server) async {
    state = state.copyWith(status: KvmStatus.connecting);

    try {
      const profile = ClientProfile(); // TODO: get profile
      _sub = ref.listen(switchServiceProvider(profile), (prev, next) {});

      final granted = await _permission.request(PermissionType.kvm);
      if (!granted) {
        throw const PermissionError(message: 'Permission denied');
      }

      await _receiver.connect(server);
      state = state.copyWith(status: KvmStatus.connected);
    } catch (e) {
      await stop();
      rethrow;
    }
  }

  Future<void> serve() async {
    state = state.copyWith(status: KvmStatus.booting);

    try {
      const profile = ServerProfile(); // TODO: get profile
      _sub = ref.listen(switchServiceProvider(profile), (prev, next) {});

      final granted = await _permission.request(PermissionType.kvm);
      if (!granted) {
        throw const PermissionError(message: 'Permission denied');
      }

      final server = await _transmitter.start(
        id: await _system.getMachineId(),
        name: profile.name ?? await _system.getMachineName(),
        port: profile.connectionPort,
      );
      if (server == null) {
        throw const UnknownError(message: 'Failed to start transmitter');
      }

      await _broadcast.start(
        port: profile.broadcastPort,
        server: server,
      );
      await _capture.start();

      state = state.copyWith(status: KvmStatus.serving);
    } catch (e) {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      _sub?.close();
      switch (state.status.mode) {
        case KvmMode.client:
          await _receiver.disconnect();
          break;
        case KvmMode.server:
          await _capture.stop();
          await _broadcast.stop();
          await _transmitter.stop();
          break;
        case KvmMode.idle:
      }
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(status: KvmStatus.idle);
    }
  }
}
