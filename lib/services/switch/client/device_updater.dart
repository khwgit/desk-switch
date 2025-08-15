import 'package:desk_switch/models/message.dart';
import 'package:desk_switch/models/workspace.dart';
import 'package:desk_switch/services/switch/switch_event.dart';
import 'package:desk_switch/services/switch/switch_state.dart';

SwitchClientState updateClientDevice(
  DeviceMessage message,
  SwitchClientState state,
) {
  // TODO: Calculate the layout with server profile and validate the cursor
  return state.copyWith(
    monitors: message.monitors,
    events: [
      SendSwitchEvent(
        WorkspaceMessage(
          deviceId: 'server', // TODO: Use server id
          data: DeviceMessage(monitors: message.monitors),
        ),
      ),
    ],
  );
}
