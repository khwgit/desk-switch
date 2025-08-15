import 'package:desk_switch/core/extensions/object_extension.dart';
import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/profile.dart';
import 'package:desk_switch/services/communication/transmitter_service.dart';
import 'package:desk_switch/services/control/capture_service.dart';
import 'package:desk_switch/services/switch/server/device_updater.dart';
import 'package:desk_switch/services/switch/server/keyboard_input_updater.dart';
import 'package:desk_switch/services/switch/server/mouse_input_updater.dart';
import 'package:desk_switch/services/switch/switch_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'switch_server.g.dart';

@riverpod
class SwitchServer extends _$SwitchServer {
  @override
  SwitchServerState build(ServerProfile profile) {
    ref.listen(
      captureServiceProvider.select((state) => state.monitors),
      (prev, next) => next?.let(
        (next) => update(DeviceMessage(monitors: next)),
      ),
    );
    ref.listen(
      captureServiceProvider.select((state) => state.input),
      (prev, next) => next?.let(
        (next) => update(InputMessage(next)),
      ),
    );

    ref.listen(
      transmitterServiceProvider.select((state) => state.message),
      (prev, next) => next?.let(
        (next) => update(next.data, next.deviceId),
      ),
    );

    return const SwitchServerState();
  }

  void update(Message message, [String deviceId = '']) {
    final next = state.copyWith(events: []);
    state = switch (message) {
      InputMessage(:final input) => switch (input) {
        MouseInput input => updateServerMouseInput(input, next),
        KeyboardInput input => updateServerKeyboardInput(input, next),
      },
      DeviceMessage message => updateServerDevice(deviceId, message, next),
    };
  }
}
