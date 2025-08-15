import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:desk_switch/core/extensions/object_extension.dart';
import 'package:desk_switch/core/extensions/offset_extension.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/monitor.dart';
import 'package:desk_switch/models/profile.dart';
import 'package:desk_switch/models/workspace.dart';
import 'package:desk_switch/services/communication/transmitter_service.dart';
import 'package:desk_switch/services/control/capture_service.dart';
import 'package:desk_switch/services/control/injection_service.dart';
import 'package:desk_switch/services/switch/switch_state.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'switch_server.g.dart';

@riverpod
class SwitchServer extends _$SwitchServer {
  late InjectionService _injection;
  late TransmitterService _transmitter;

  @override
  void build(ServerProfile profile) {
    _injection = ref.watch(injectionServiceProvider.notifier);
    _transmitter = ref.watch(transmitterServiceProvider.notifier);
  }

  Future<void> run(SwitchServerState? prev, SwitchServerState next) async {
    final prevCursor = prev?.cursor;
    final nextCursor = next.cursor;
    if (prevCursor == null || nextCursor == null) return;

    logger.debug(
      'mon:${next.cursor?.deviceId}[${next.cursor?.monitorId}] pos:${next.position?.dx},${next.position?.dy} cur:${nextCursor.position.dx},${nextCursor.position.dy}',
    );
    if (nextCursor.deviceId.isEmpty) {
      // Controlling local device
      if (prevCursor.deviceId != nextCursor.deviceId) {
        // await _injection.unblockInputs({InputType.mouse});
        await _injection.injectInput(
          Input.mouse(
            x: nextCursor.position.dx,
            y: nextCursor.position.dy,
            type: MouseInputType.mouseMoved,
            flag: InputFlag.sync.index,
          ),
        );
      }
    } else {
      // Controlling remote devices
      final monitor = next.layout?.monitorsOf('').firstOrNull;
      assert(monitor != null, 'No server monitor found');
      if (monitor == null) return;

      final center = monitor.rect.center;
      if (prevCursor.deviceId != nextCursor.deviceId) {
        // Switching to remote devices
        // await injection.blockInputs({InputType.mouse});
      }

      final nextInput = next.message?.input;
      if (nextInput != null) {
        if (nextInput.type == MouseInputType.mouseMoved &&
            nextInput.flag != InputFlag.recenter.index) {
          await _injection.injectInput(
            Input.mouse(
              x: center.dx,
              y: center.dy,
              type: MouseInputType.mouseMoved,
              flag: InputFlag.recenter.index,
            ),
          );
        }
        // TODO: Send the message to the client
        // transmitter.send(
        //   WorkspaceMessage(
        //     id: '',
        //     data: InputMessage(nextInput),
        //   ),
        // );
      }
    }
  }
}

@riverpod
class SwitchServerUpdater extends _$SwitchServerUpdater {
  @override
  SwitchServerState build(ServerProfile profile) {
    ref.listen(
      captureServiceProvider.select((state) => state.monitors),
      (prev, next) => next?.let(
        (next) => update(
          WorkspaceMessage(
            id: '',
            data: DeviceMessage(monitors: next),
          ),
        ),
      ),
    );
    ref.listen(
      captureServiceProvider.select((state) => state.input),
      (prev, next) => next?.let(
        (next) => update(
          WorkspaceMessage(
            id: '',
            data: InputMessage(next),
          ),
        ),
      ),
    );

    ref.listen(
      transmitterServiceProvider.select((state) => state.message),
      (prev, next) => update(next),
    );

    return const SwitchServerState();
  }

  void update(WorkspaceMessage? message) {
    if (message == null) return;
    state = state.copyWith(message: message).let((state) {
      switch (message.data) {
        case InputMessage(:final input):
          switch (input) {
            case MouseInput input:
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

            case KeyboardInput input:
              return state;
          }
        case DeviceMessage(:final monitors):
          // TODO: Calculate the layout with server profile and validate the cursor
          return state.copyWith(
            layout: const WorkspaceLayout(
              monitors: [
                WorkspaceMonitor(
                  deviceId: '',
                  offset: Offset.zero,
                  data: Monitor(
                    id: 'display2',
                    name: 'DELL P2418D (2)',
                    x: 0,
                    y: 0,
                    width: 2560,
                    height: 1440,
                  ),
                ),
                WorkspaceMonitor(
                  deviceId: '',
                  offset: Offset.zero,
                  data: Monitor(
                    id: 'display1',
                    name: 'DELL P2418D (1)',
                    x: -1440,
                    y: 0,
                    width: 1440,
                    height: 2560,
                  ),
                ),
                WorkspaceMonitor(
                  deviceId: 'client1',
                  offset: Offset(2560, 0),
                  data: Monitor(
                    id: 'display1',
                    name: 'ASUS VG289',
                    x: 0,
                    y: 0,
                    width: 3840,
                    height: 2160,
                  ),
                ),
              ],
              gates: [
                WorkspaceGate(
                  deviceId: 'client1',
                  monitorId: 'display1',
                  rect: Rect.fromLTWH(2560 - 1, 0, 1, 1440),
                ),
              ],
            ),
          );
      }
    });
  }
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
