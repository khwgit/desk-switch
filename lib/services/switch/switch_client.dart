import 'dart:async';

import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/profile.dart';
import 'package:desk_switch/models/workspace.dart';
import 'package:desk_switch/services/communication/receiver_service.dart';
import 'package:desk_switch/services/control/capture_service.dart';
import 'package:desk_switch/services/switch/switch_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'switch_client.g.dart';

@riverpod
class SwitchClient extends _$SwitchClient {
  @override
  void build(ClientProfile profile) {}

  Future<void> run(SwitchClientState? prev, SwitchClientState next) async {
    if (prev?.monitors != next.monitors) {
      // receiver.send(DeviceMessage(monitors: next.monitors ?? []));
    }
  }
}

@riverpod
class SwitchClientUpdater extends _$SwitchClientUpdater {
  @override
  SwitchClientState build(ClientProfile profile) {
    ref.listen(
      captureServiceProvider.select((state) => state.monitors),
      (prev, next) => update([
        if (next != null)
          WorkspaceMessage(
            id: '',
            data: DeviceMessage(monitors: next),
          ),
      ]),
    );

    ref.listen(
      receiverServiceProvider,
      (prev, next) => update([
        if (next.message != null && next.server != null)
          WorkspaceMessage(
            id: next.server!.id,
            data: next.message!,
          ),
      ]),
    );

    return const SwitchClientState();
  }

  void update(List<WorkspaceMessage> messages) {
    state = messages.fold(state, (state, message) {
      switch (message.data) {
        case InputMessage():
          // TODO: Key mapper / Shortcut detection
          return state;
        case DeviceMessage data:
          return message.id == ''
              ? state.copyWith(monitors: data.monitors)
              : state;
      }
    });
  }
}
