import 'dart:ui';

import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/monitor.dart';
import 'package:desk_switch/models/workspace.dart';
import 'package:desk_switch/services/switch/switch_state.dart';

SwitchServerState updateServerDevice(
  String deviceId,
  DeviceMessage message,
  SwitchServerState state,
) {
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
