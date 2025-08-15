import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/models/message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kvm_helper/models/monitor.dart';

part 'workspace.freezed.dart';

@freezed
abstract class WorkspaceLayout with _$WorkspaceLayout {
  const factory WorkspaceLayout({
    required List<WorkspaceMonitor> monitors,
    required List<WorkspaceGate> gates,
  }) = _WorkspaceLayout;

  List<WorkspaceMonitor> monitorsOf(String deviceId) {
    return monitors.where((monitor) => monitor.deviceId == deviceId).toList();
  }

  WorkspaceMonitor? monitor(String deviceId, String monitorId) {
    return monitors.firstWhereOrNull(
      (monitor) => monitor.deviceId == deviceId && monitor.data.id == monitorId,
    );
  }

  const WorkspaceLayout._();
}

@freezed
abstract class WorkspaceMonitor with _$WorkspaceMonitor {
  const factory WorkspaceMonitor({
    required String deviceId,
    required Offset offset,
    required Monitor data,
  }) = _WorkspaceMonitor;

  const WorkspaceMonitor._();

  Rect get rect => Rect.fromLTWH(
    data.x + offset.dx,
    data.y + offset.dy,
    data.width,
    data.height,
  );
}

/// [WorkspaceGate] is an area in the local monitors that triggers the cursor to
/// move from the local device to remote devices.
@freezed
abstract class WorkspaceGate with _$WorkspaceGate {
  const factory WorkspaceGate({
    required String deviceId,
    required String monitorId,
    required Rect rect,
  }) = _WorkspaceGate;

  const WorkspaceGate._();
}

@freezed
abstract class WorkspaceCursor with _$WorkspaceCursor {
  const factory WorkspaceCursor({
    required Offset position,
    required String deviceId,
    required String monitorId,
  }) = _WorkspaceCursor;

  const WorkspaceCursor._();
}

@freezed
abstract class WorkspaceMessage with _$WorkspaceMessage {
  const factory WorkspaceMessage({
    required String deviceId,
    required Message data,
  }) = _WorkspaceMessage;

  Input? get input => switch (data) {
    InputMessage(:final input) => input,
    _ => null,
  };

  const WorkspaceMessage._();
}
