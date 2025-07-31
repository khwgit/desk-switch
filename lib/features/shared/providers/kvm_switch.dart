import 'package:desk_switch/core/errors/app_error.dart';
import 'package:desk_switch/core/services/client/injection_service.dart';
import 'package:desk_switch/core/services/client/receiver_service.dart';
import 'package:desk_switch/core/services/permission_service.dart';
import 'package:desk_switch/core/services/server/broadcast_service.dart';
import 'package:desk_switch/core/services/server/capture_service.dart';
import 'package:desk_switch/core/services/server/transmitter_service.dart';
import 'package:desk_switch/core/services/system_service.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/server_data.dart';
import 'package:desk_switch/models/server_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'kvm_switch.freezed.dart';
part 'kvm_switch.g.dart';

enum KvmSwitchStatus {
  idle,
  connected,
  connecting,
  disconnecting,
  booting,
  serving,
  stopping;

  bool get isServerMode => switch (this) {
    booting => true,
    serving => true,
    stopping => true,
    _ => false,
  };

  bool get isClientMode => switch (this) {
    connected => true,
    connecting => true,
    disconnecting => true,
    _ => false,
  };
}

@freezed
sealed class KvmSwitchState with _$KvmSwitchState {
  const factory KvmSwitchState({
    @Default(KvmSwitchStatus.idle) KvmSwitchStatus status,
  }) = _KvmSwitchState;

  const KvmSwitchState._();
}

@Riverpod(keepAlive: true)
class KvmSwitch extends _$KvmSwitch {
  InjectionService? _injection;
  ReceiverService? _receiver;
  CaptureService? _capture;
  TransmitterService? _transmitter;
  BroadcastService? _broadcast;
  PermissionService? _permission;
  SystemService? _system;

  @override
  KvmSwitchState build() {
    _injection = ref.watch(injectionServiceProvider.notifier);
    _receiver = ref.watch(receiverServiceProvider.notifier);
    _capture = ref.watch(captureServiceProvider.notifier);
    _transmitter = ref.watch(transmitterServiceProvider.notifier);
    _broadcast = ref.watch(broadcastServiceProvider.notifier);
    _permission = ref.watch(permissionServiceProvider.notifier);
    _system = ref.watch(systemServiceProvider.notifier);

    ref.listen(receiverServiceProvider, (prev, next) {
      if (state.status == KvmSwitchStatus.connected) {
        final message = next.message;
        if (message is InputMessage) {
          logger.info('🔌 Received input: $message');
          _injection?.injectInput(message.input);
        }
      }
    });

    return const KvmSwitchState();
  }

  Future<void> connect(ServerData server) async {
    state = state.copyWith(status: KvmSwitchStatus.connecting);
    await _receiver?.connect(server);
    state = state.copyWith(status: KvmSwitchStatus.connected);
  }

  Future<void> disconnect() async {
    state = state.copyWith(status: KvmSwitchStatus.disconnecting);
    await _receiver?.disconnect();
    state = state.copyWith(status: KvmSwitchStatus.idle);
  }

  Future<void> serve(ServerProfile profile) async {
    state = state.copyWith(status: KvmSwitchStatus.booting);
    final granted = await _permission?.isPermissionGranted() ?? false;
    if (!granted) {
      state = state.copyWith(status: KvmSwitchStatus.idle);
      throw const PermissionError(message: 'Permission not granted');
    }

    final server = await _transmitter?.start(
      id: await _system?.getMachineId() ?? '',
      name: await _system?.getMachineName() ?? '',
      port: profile.connectionPort,
    );

    if (server == null) {
      throw const UnknownError(message: 'Failed to start server');
    }

    await _broadcast?.start(port: profile.broadcastPort, server: server);
    await _capture?.start();
    state = state.copyWith(status: KvmSwitchStatus.serving);
  }

  Future<void> stop() async {
    state = state.copyWith(status: KvmSwitchStatus.stopping);
    await _transmitter?.stop();
    await _broadcast?.stop();
    await _capture?.stop();
    state = state.copyWith(status: KvmSwitchStatus.idle);
  }
}
