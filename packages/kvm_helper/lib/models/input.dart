import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';
part 'input.g.dart';

@freezed
sealed class Input with _$Input {
  const factory Input.keyboard({
    required int code,
    required KeyboardInputType type,
    @Default([]) List<KeyModifier> modifiers,
    String? character,
  }) = KeyboardInput;

  const factory Input.mouse({
    required double x,
    required double y,
    required MouseInputType type,
    MouseButton? button,
    double? deltaX,
    double? deltaY,
    double? deltaZ,
  }) = MouseInput;

  // const factory Input.clipboard({
  //   required String text,
  //   required int timestamp,
  // }) = ClipboardInput;

  factory Input.fromJson(Map<String, dynamic> json) => _$InputFromJson(json);
}

enum InputType { keyboard, mouse }

enum KeyboardInputType { keyDown, keyUp, flagsChanged }

enum KeyModifier {
  shift,
  control,
  option,
  command,
  capsLock,
  function,
  numericPad,
  help,
}

enum MouseInputType {
  leftMouseDown,
  leftMouseUp,
  rightMouseDown,
  rightMouseUp,
  mouseMoved,
  leftMouseDragged,
  rightMouseDragged,
  scrollWheel,
  otherMouseDown,
  otherMouseUp,
  otherMouseDragged,
}

enum MouseButton { left, right, center }
