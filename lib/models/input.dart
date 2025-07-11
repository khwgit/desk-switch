import 'package:desk_switch/models/input.pb.dart' as pb;
import 'package:kvm_helper/kvm_helper.dart';

export 'package:kvm_helper/models/input.dart';

// Conversion between Dart model and protobuf
extension InputToProto on Input {
  pb.Input toProto() {
    switch (this) {
      case KeyboardInput input:
        return pb.Input()
          ..kind = pb.InputType.KEYBOARD
          ..keyboard = (pb.KeyboardInput()
            ..code = input.code
            ..type = input.type.toProto()
            ..modifiers.addAll(input.modifiers.map((m) => m.toProto()))
            ..character = input.character ?? '');
      case MouseInput input:
        return pb.Input()
          ..kind = pb.InputType.MOUSE
          ..mouse = (pb.MouseInput()
            ..x = input.x
            ..y = input.y
            ..type = input.type.toProto()
            ..button = (input.button?.toProto() ?? pb.MouseButton.LEFT)
            ..deltaX = input.deltaX
            ..deltaY = input.deltaY
            ..deltaZ = input.deltaZ);
    }
  }
}

extension ProtoToInput on pb.Input {
  Input toModel() {
    if (hasKeyboard()) {
      final k = keyboard;
      return Input.keyboard(
        code: k.code,
        type: k.type.toModel(),
        modifiers: k.modifiers.map((m) => m.toModel()).toList(),
        character: k.character.isEmpty ? null : k.character,
      );
    } else if (hasMouse()) {
      final m = mouse;
      return Input.mouse(
        x: m.x,
        y: m.y,
        type: m.type.toModel(),
        button: m.hasButton() ? m.button.toModel() : null,
        deltaX: m.deltaX,
        deltaY: m.deltaY,
        deltaZ: m.deltaZ,
      );
    } else {
      throw Exception('Unknown input type');
    }
  }
}

// Enum conversions
extension KeyboardInputTypeProto on KeyboardInputType {
  pb.KeyboardInputType toProto() {
    switch (this) {
      case KeyboardInputType.keyDown:
        return pb.KeyboardInputType.KEY_DOWN;
      case KeyboardInputType.keyUp:
        return pb.KeyboardInputType.KEY_UP;
      case KeyboardInputType.flagsChanged:
        return pb.KeyboardInputType.FLAGS_CHANGED;
    }
  }
}

extension KeyboardInputTypeModel on pb.KeyboardInputType {
  KeyboardInputType toModel() {
    switch (this) {
      case pb.KeyboardInputType.KEY_DOWN:
        return KeyboardInputType.keyDown;
      case pb.KeyboardInputType.KEY_UP:
        return KeyboardInputType.keyUp;
      case pb.KeyboardInputType.FLAGS_CHANGED:
        return KeyboardInputType.flagsChanged;
      default:
        throw Exception('Unknown KeyboardInputType');
    }
  }
}

extension KeyModifierProto on KeyModifier {
  pb.KeyModifier toProto() {
    switch (this) {
      case KeyModifier.shift:
        return pb.KeyModifier.SHIFT;
      case KeyModifier.control:
        return pb.KeyModifier.CONTROL;
      case KeyModifier.option:
        return pb.KeyModifier.OPTION;
      case KeyModifier.command:
        return pb.KeyModifier.COMMAND;
      case KeyModifier.capsLock:
        return pb.KeyModifier.CAPS_LOCK;
      case KeyModifier.function:
        return pb.KeyModifier.FUNCTION;
      case KeyModifier.numericPad:
        return pb.KeyModifier.NUMERIC_PAD;
      case KeyModifier.help:
        return pb.KeyModifier.HELP;
    }
  }
}

extension KeyModifierModel on pb.KeyModifier {
  KeyModifier toModel() {
    switch (this) {
      case pb.KeyModifier.SHIFT:
        return KeyModifier.shift;
      case pb.KeyModifier.CONTROL:
        return KeyModifier.control;
      case pb.KeyModifier.OPTION:
        return KeyModifier.option;
      case pb.KeyModifier.COMMAND:
        return KeyModifier.command;
      case pb.KeyModifier.CAPS_LOCK:
        return KeyModifier.capsLock;
      case pb.KeyModifier.FUNCTION:
        return KeyModifier.function;
      case pb.KeyModifier.NUMERIC_PAD:
        return KeyModifier.numericPad;
      case pb.KeyModifier.HELP:
        return KeyModifier.help;
      default:
        throw Exception('Unknown KeyModifier');
    }
  }
}

extension MouseInputTypeProto on MouseInputType {
  pb.MouseInputType toProto() {
    switch (this) {
      case MouseInputType.leftMouseDown:
        return pb.MouseInputType.LEFT_MOUSE_DOWN;
      case MouseInputType.leftMouseUp:
        return pb.MouseInputType.LEFT_MOUSE_UP;
      case MouseInputType.rightMouseDown:
        return pb.MouseInputType.RIGHT_MOUSE_DOWN;
      case MouseInputType.rightMouseUp:
        return pb.MouseInputType.RIGHT_MOUSE_UP;
      case MouseInputType.mouseMoved:
        return pb.MouseInputType.MOUSE_MOVED;
      case MouseInputType.leftMouseDragged:
        return pb.MouseInputType.LEFT_MOUSE_DRAGGED;
      case MouseInputType.rightMouseDragged:
        return pb.MouseInputType.RIGHT_MOUSE_DRAGGED;
      case MouseInputType.scrollWheel:
        return pb.MouseInputType.SCROLL_WHEEL;
      case MouseInputType.otherMouseDown:
        return pb.MouseInputType.OTHER_MOUSE_DOWN;
      case MouseInputType.otherMouseUp:
        return pb.MouseInputType.OTHER_MOUSE_UP;
      case MouseInputType.otherMouseDragged:
        return pb.MouseInputType.OTHER_MOUSE_DRAGGED;
    }
  }
}

extension MouseInputTypeModel on pb.MouseInputType {
  MouseInputType toModel() {
    switch (this) {
      case pb.MouseInputType.LEFT_MOUSE_DOWN:
        return MouseInputType.leftMouseDown;
      case pb.MouseInputType.LEFT_MOUSE_UP:
        return MouseInputType.leftMouseUp;
      case pb.MouseInputType.RIGHT_MOUSE_DOWN:
        return MouseInputType.rightMouseDown;
      case pb.MouseInputType.RIGHT_MOUSE_UP:
        return MouseInputType.rightMouseUp;
      case pb.MouseInputType.MOUSE_MOVED:
        return MouseInputType.mouseMoved;
      case pb.MouseInputType.LEFT_MOUSE_DRAGGED:
        return MouseInputType.leftMouseDragged;
      case pb.MouseInputType.RIGHT_MOUSE_DRAGGED:
        return MouseInputType.rightMouseDragged;
      case pb.MouseInputType.SCROLL_WHEEL:
        return MouseInputType.scrollWheel;
      case pb.MouseInputType.OTHER_MOUSE_DOWN:
        return MouseInputType.otherMouseDown;
      case pb.MouseInputType.OTHER_MOUSE_UP:
        return MouseInputType.otherMouseUp;
      case pb.MouseInputType.OTHER_MOUSE_DRAGGED:
        return MouseInputType.otherMouseDragged;
      default:
        throw Exception('Unknown MouseInputType');
    }
  }
}

extension MouseButtonProto on MouseButton {
  pb.MouseButton toProto() {
    switch (this) {
      case MouseButton.left:
        return pb.MouseButton.LEFT;
      case MouseButton.right:
        return pb.MouseButton.RIGHT;
      case MouseButton.center:
        return pb.MouseButton.CENTER;
    }
  }
}

extension MouseButtonModel on pb.MouseButton {
  MouseButton toModel() {
    switch (this) {
      case pb.MouseButton.LEFT:
        return MouseButton.left;
      case pb.MouseButton.RIGHT:
        return MouseButton.right;
      case pb.MouseButton.CENTER:
        return MouseButton.center;
      default:
        throw Exception('Unknown MouseButton');
    }
  }
}
