import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/services/switch/switch_state.dart';

SwitchServerState updateServerKeyboardInput(
  KeyboardInput input,
  SwitchServerState state,
) {
  return state.copyWith(
    events: [
      // TODO: Keyboard input mapper
      // TODO: Detect keyboard shortcut
    ],
  );
}
