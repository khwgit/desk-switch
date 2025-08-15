import 'dart:ui';

import 'package:desk_switch/models/workspace.dart';
import 'package:desk_switch/services/switch/switch_event.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kvm_helper/models/monitor.dart';

part 'switch_state.freezed.dart';

@freezed
sealed class SwitchState with _$SwitchState {
  const factory SwitchState.server({
    @Default([]) List<SwitchEvent> events,
    WorkspaceLayout? layout,
    WorkspaceCursor? cursor,
    Offset? position,
  }) = SwitchServerState;

  const factory SwitchState.client({
    @Default([]) List<SwitchEvent> events,
    List<Monitor>? monitors,
    Offset? position,
  }) = SwitchClientState;

  const SwitchState._();
}
