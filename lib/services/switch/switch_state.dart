import 'dart:ui';

import 'package:desk_switch/models/workspace.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kvm_helper/models/monitor.dart';

part 'switch_state.freezed.dart';

@freezed
sealed class SwitchState with _$SwitchState {
  const factory SwitchState.server({
    WorkspaceMessage? message,
    WorkspaceLayout? layout,
    WorkspaceCursor? cursor,
    Offset? position,
  }) = SwitchServerState;

  const factory SwitchState.client({
    List<Monitor>? monitors,
    Offset? position,
  }) = SwitchClientState;

  const SwitchState._();
}
