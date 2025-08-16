import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/services/switch/switch_event.dart';
import 'package:desk_switch/services/switch/switch_state.dart';

SwitchClientState updateClientInput(
  Input input,
  SwitchClientState state,
) {
  return state.copyWith(
    events: [
      // TODO: Keyboard input mapper
      // TODO: Detect keyboard shortcut
      InjectSwitchEvent(input),
    ],
  );
}
