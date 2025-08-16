import 'package:desk_switch/core/extensions/object_extension.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/profile.dart';
import 'package:desk_switch/services/communication/receiver_service.dart';
import 'package:desk_switch/services/control/capture_service.dart';
import 'package:desk_switch/services/switch/client/device_updater.dart';
import 'package:desk_switch/services/switch/client/input_updater.dart';
import 'package:desk_switch/services/switch/switch_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'switch_client.g.dart';

@riverpod
class SwitchClient extends _$SwitchClient {
  @override
  SwitchClientState build(ClientProfile profile) {
    ref.listen(
      captureServiceProvider.select((state) => state.monitors),
      (prev, next) => next?.let(
        (next) => update(DeviceMessage(monitors: next)),
      ),
    );

    ref.listen(
      receiverServiceProvider,
      (prev, next) => next.let(
        (next) => update(next.message!, next.server!.id),
      ),
    );

    return const SwitchClientState();
  }

  void update(Message message, [String deviceId = '']) {
    final next = state.copyWith(events: []);
    state = switch (message) {
      InputMessage(:final input) => updateClientInput(input, next),
      DeviceMessage message => updateClientDevice(message, next),
    };
  }
}
