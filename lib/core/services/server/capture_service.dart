import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:desk_switch/core/utils/logger.dart';
import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/monitor.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kvm_helper/kvm_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'capture_service.freezed.dart';
part 'capture_service.g.dart';

@freezed
abstract class CaptureState with _$CaptureState {
  const factory CaptureState({
    /// Package to be sent to the client
    ClientPackage? package,

    /// Global cursor position in the virtual desktop space
    Offset? globalPosition,

    /// Actual cursor position in the local desktop space
    Offset? localPosition,

    /// Currently controlled client
    // String? clientId,

    /// Currently controlled monitor
    // String? monitorId,

    /// All monitors that are currently available using global coordinates
    ///
    /// Key is client id, value is map of monitor id to monitor.
    /// When client id is empty, it means the local desktop.
    @Default({}) Map<String, List<Monitor>> monitors,

    @Default({}) Map<String, List<MonitorGate>> gates,
  }) = _CaptureState;

  const CaptureState._();

  Monitor? getMonitor(String clientId, String monitorId) =>
      monitors[clientId]?.firstWhereOrNull(
        (monitor) => monitor.id == monitorId,
      );

  (String clientId, Monitor monitor)? get current {
    final globalPosition = this.globalPosition;
    if (globalPosition == null) return null;

    Monitor? monitor;
    final clientId = monitors.keys.firstWhereOrNull(
      (clientId) {
        monitor = monitors[clientId]?.firstWhereOrNull(
          (monitor) => monitor.contains(globalPosition.dx, globalPosition.dy),
        );

        return monitor != null;
      },
    );

    return clientId == null || monitor == null ? null : (clientId, monitor!);
  }
}

@riverpod
class CaptureService extends _$CaptureService {
  static const _kvm = KvmHelper.instance;

  StreamSubscription<Input>? _inputSub;
  StreamSubscription<List<Monitor>>? _monitorsSub;

  @override
  CaptureState build() {
    ref.onDispose(() {
      _monitorsSub?.cancel();
      _inputSub?.cancel();
    });

    // return ControlState();
    return _dummyState;
  }

  Future<void> start() async {
    _monitorsSub = _kvm.monitors().listen((monitors) {
      updateDevice('', monitors: monitors);
    });
    _inputSub = _kvm.inputs().listen((input) {
      updateInput(input);
    });
  }

  Future<void> stop() async {
    _monitorsSub?.cancel();
    _inputSub?.cancel();
  }

  void updateInput(Input input) {
    switch (input) {
      case MouseInput input:
        // The [input] is in the local desktop space, calculate delta to get the global position
        var localPosition = Offset(input.x, input.y);
        var delta = state.localPosition == null
            ? Offset.zero
            : localPosition - state.localPosition!;
        var globalPosition = state.globalPosition == null
            ? localPosition
            : state.globalPosition! + delta;
        var package = state.package;

        final current = state.current;
        if (current != null) {
          var (clientId, monitor) = current;
          final gates = state.gates[clientId] ?? [];

          for (final gate in gates) {
            if (gate.nextClientId == clientId) continue;
            final (distanceX, distanceY) = monitor.distanceTo(
              globalPosition.dx,
              globalPosition.dy,
            );

            final direction = distanceX > 0
                ? Direction.right
                : distanceX < 0
                ? Direction.left
                : distanceY > 0
                ? Direction.bottom
                : distanceY < 0
                ? Direction.top
                : null;

            if (direction == null || direction != gate.direction) continue;
            final value = switch (direction) {
              Direction.left => distanceY,
              Direction.right => distanceY,
              Direction.top => distanceX,
              Direction.bottom => distanceX,
            };

            if (value < gate.min || value > gate.max) continue;

            // Switch to the next client and monitor
            final nextMonitor = state.getMonitor(
              gate.nextClientId,
              gate.nextMonitorId,
            );

            if (nextMonitor == null) continue;

            monitor = nextMonitor;
            clientId = gate.nextClientId;
            break;
          }

          globalPosition = monitor.clamp(globalPosition);
          if (clientId.isNotEmpty) {
            package = ClientPackage(
              id: clientId,
              message: Message.input(
                input.copyWith(
                  // TODO: calculate the local position
                  x: globalPosition.dx - 2560,
                  y: globalPosition.dy,
                ),
              ),
            );
          }
        }

        state = state.copyWith(
          package: package,
          globalPosition: globalPosition,
          localPosition: localPosition,
        );

        break;
      default:
        state = state.copyWith(
          package: state.package?.copyWith(
            message: Message.input(input),
          ),
        );
        break;
    }
  }

  void updateDevice(
    String id, {
    required List<Monitor> monitors,
  }) {
    logger.info('updateDevice: $id, $monitors');
    // TODO: make sure the cursor is within the new monitors if position is not null
    // TODO: calculate global coordinates for the monitors

    // TODO: store the original monitors
    // final updatedMonitors = {
    //   ...state.monitors,
    //   id: {for (var monitor in monitors) monitor.id: monitor},
    // };

    // Calculate global coordinates for the monitors
  }
}

const _dummyState = CaptureState(
  monitors: {
    '': [
      Monitor(
        id: 'display1',
        name: 'DELL P2418D (1)',
        x: -1440,
        y: 0,
        width: 1440,
        height: 2560,
      ),
      Monitor(
        id: 'display2',
        name: 'DELL P2418D (2)',
        x: 0,
        y: 0,
        width: 2560,
        height: 1440,
      ),
    ],
    'client1': [
      Monitor(
        id: 'display1',
        name: 'ASUS VG289',
        x: 2560,
        y: 0,
        width: 3840,
        height: 2160,
      ),
    ],
  },
  gates: {
    '': [
      MonitorGate(
        id: 'display2',
        direction: Direction.right,
        min: 0,
        max: 1440,
        nextClientId: 'client1',
        nextMonitorId: 'display1',
      ),
      MonitorGate(
        id: 'display2',
        direction: Direction.left,
        min: 0,
        max: 1440,
        nextClientId: '',
        nextMonitorId: 'display1',
      ),
    ],
    'client1': [
      MonitorGate(
        id: 'display1',
        direction: Direction.left,
        min: 0,
        max: 1440,
        nextClientId: '',
        nextMonitorId: 'display2',
      ),
    ],
  },
);
