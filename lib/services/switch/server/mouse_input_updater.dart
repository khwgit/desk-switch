import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:desk_switch/core/extensions/offset_extension.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/monitor.dart';
import 'package:desk_switch/models/workspace.dart';
import 'package:desk_switch/services/switch/switch_event.dart';
import 'package:desk_switch/services/switch/switch_state.dart';

SwitchServerState updateServerMouseInput(
  MouseInput input,
  SwitchServerState state,
) {
  final next = _calculate(input, state);
  return next.copyWith(events: _pack(input, state, next));
}

SwitchServerState _calculate(
  MouseInput input,
  SwitchServerState state,
) {
  final cursor = state.cursor;
  final position = Offset(input.x, input.y);
  if (input.flag == InputFlag.sync.index || cursor == null) {
    logger.debug('[sync] pos:${position.dx},${position.dy}');
    final result = state.sync(position);
    assert(
      result != null,
      '$position is out of any server monitors',
    );
    return result ?? state;
  }
  if (input.flag == InputFlag.recenter.index) {
    logger.debug('[recenter] pos:${position.dx},${position.dy}');
    return state.copyWith(position: position);
  }

  final delta = position - state.position!;
  final cursorPosition = cursor.position + delta;
  final monitor = state.monitorAt(cursorPosition);
  logger.debug(
    '[update] pos:${position.dx},${position.dy} delta:${delta.dx},${delta.dy} cur:${cursorPosition.dx},${cursorPosition.dy} mon:${monitor?.deviceId}/${monitor?.data.id}',
  );
  if (monitor == null) {
    final monitor = state.layout?.monitor(
      cursor.deviceId,
      cursor.monitorId,
    );
    assert(monitor != null, 'Invalid cursor position');

    return state.copyWith(
      cursor: cursor.copyWith(
        position: monitor == null
            ? position
            : cursorPosition.clamp(monitor.rect),
      ),
    );
  }

  return state.copyWith(
    position: position,
    cursor: WorkspaceCursor(
      position: cursorPosition,
      deviceId: monitor.deviceId,
      monitorId: monitor.data.id,
    ),
  );
}

List<SwitchEvent> _pack(
  MouseInput input,
  SwitchServerState prev,
  SwitchServerState next,
) {
  final events = <SwitchEvent>[];

  final prevCursor = prev.cursor;
  final nextCursor = next.cursor;
  if (prevCursor == null || nextCursor == null) return events;

  final layout = next.layout;
  if (layout == null) return events;

  if (nextCursor.deviceId.isEmpty) {
    /// Controlling the local device
    if (prevCursor.deviceId != nextCursor.deviceId) {
      /// Switching to the local device
      events.add(const SwitchEvent.unblock());
      events.add(
        InjectSwitchEvent(
          Input.mouse(
            x: nextCursor.position.dx,
            y: nextCursor.position.dy,
            type: MouseInputType.mouseMoved,
            flag: InputFlag.sync.index,
          ),
        ),
      );
    }
  } else {
    /// Controlling a remote device
    if (prevCursor.deviceId != nextCursor.deviceId) {
      /// Switching to the remote device
      events.add(const SwitchEvent.block());
    }

    if (input.flag != InputFlag.recenter.index) {
      if (input.type == MouseInputType.mouseMoved) {
        final localPrimaryMonitor = layout.monitors.firstWhereOrNull(
          (monitor) => monitor.deviceId == '',
        );
        assert(localPrimaryMonitor != null, 'No server monitor found');
        if (localPrimaryMonitor != null) {
          final center = localPrimaryMonitor.rect.center;
          events.add(
            InjectSwitchEvent(
              Input.mouse(
                x: center.dx,
                y: center.dy,
                type: MouseInputType.mouseMoved,
                flag: InputFlag.recenter.index,
              ),
            ),
          );
        }
      }

      final clientMonitor = layout.monitor(
        nextCursor.deviceId,
        nextCursor.monitorId,
      );
      assert(clientMonitor != null, 'Client monitor not found');
      if (clientMonitor != null) {
        final position = (nextCursor.position - clientMonitor.offset).clamp(
          clientMonitor.data.rect,
        );
        events.add(
          SendSwitchEvent(
            WorkspaceMessage(
              deviceId: nextCursor.deviceId,
              data: InputMessage(
                input.copyWith(
                  x: position.dx,
                  y: position.dy,
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  return events;
}

extension on Monitor {
  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

extension SwitchServerStateExtension on SwitchServerState {
  /// Sync the workspace position and the actual position with [position]
  ///
  /// Returns null if the position is out of any local monitors
  SwitchServerState? sync(Offset position) {
    final monitors = layout?.monitorsOf('');
    final monitor = monitors?.firstWhereOrNull(
      (monitor) => monitor.rect.contains(position),
    );
    if (monitor == null) return null;

    return copyWith(
      position: position,
      cursor: WorkspaceCursor(
        position: position,
        deviceId: monitor.deviceId,
        monitorId: monitor.data.id,
      ),
    );
  }

  WorkspaceMonitor? monitorAt(Offset position) {
    final gate = layout?.gates.firstWhereOrNull(
      (gate) => gate.rect.contains(position),
    );
    if (gate != null) {
      return layout?.monitor(gate.deviceId, gate.monitorId);
    }

    return layout?.monitors.firstWhereOrNull(
      (monitor) => monitor.rect.contains(position),
    );
  }

  WorkspaceMonitor? monitor([String? deviceId, String? monitorId]) {
    final did = deviceId ?? cursor?.deviceId;
    final mid = monitorId ?? cursor?.monitorId;
    if (did == null || mid == null) return null;
    return layout?.monitor(did, mid);
  }
}
