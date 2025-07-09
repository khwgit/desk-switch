# KVM Helper

A Flutter plugin for capturing and injecting input events and monitoring display configuration across multiple platforms.

## Features

- **Input Capture**: Capture keyboard and mouse events in real-time
- **Input Injection**: Inject keyboard and mouse events programmatically
- **Input Blocking**: Block specific input types from reaching other applications
- **Monitor Detection**: Detect and monitor display configuration changes, including monitor arrangement, orientation, and hot-plug events
- **Cross-Platform**: Supports macOS, Windows, and Linux (WIP)

## Getting Started

### Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  kvm_helper: ^0.0.1
```

### Permissions

#### macOS
- The plugin requires Accessibility permissions. When you first use the plugin, macOS will prompt you to grant permissions in System Preferences > Security & Privacy > Privacy > Accessibility.
- For monitor detection, no special permissions are needed.

#### Windows & Linux
- No special permissions are required for desktop applications.

## Usage

### Basic Setup

```dart
import 'package:kvm_helper/kvm_helper.dart';

final kvmHelper = KvmHelper();
```

### Requesting Permissions

```dart
// Request all permissions
bool granted = await kvmHelper.requestPermission();

// Request specific input types
bool granted = await kvmHelper.requestPermission({
  InputType.keyboard,
  InputType.mouse,
});

// Check if permissions are granted
bool hasPermission = await kvmHelper.isPermissionGranted();
```

### Capturing Input Events

```dart
// Capture all input events
Stream<Input> inputStream = kvmHelper.inputs();

// Capture only keyboard events
Stream<Input> keyboardStream = kvmHelper.inputs({InputType.keyboard});

// Capture only mouse events
Stream<Input> mouseStream = kvmHelper.inputs({InputType.mouse});

// Listen to events
inputStream.listen((input) {
  if (input is KeyboardInput) {
    print('Keyboard: ${input.type} - Key: ${input.code}');
  } else if (input is MouseInput) {
    print('Mouse: ${input.type} - Position: (${input.x}, ${input.y})');
  }
});
```

### Injecting Input Events

```dart
// Inject keyboard event
await kvmHelper.injectKeyboardInput(
  KeyboardInput(
    code: 0x00, // Key code for 'A'
    type: KeyboardInputType.keyDown,
    modifiers: [KeyModifier.shift],
    character: 'A',
  ),
);

// Inject mouse event
await kvmHelper.injectMouseInput(
  MouseInput(
    x: 100.0,
    y: 100.0,
    type: MouseInputType.leftMouseDown,
    button: MouseButton.left,
  ),
);

// Or use the generic inject method
await kvmHelper.injectInput(keyboardInput);
await kvmHelper.injectInput(mouseInput);
```

### Blocking Input Events

```dart
// Block all inputs
await kvmHelper.blockInputs();

// Block specific input types
await kvmHelper.blockInputs({InputType.keyboard});
await kvmHelper.blockInputs({InputType.mouse});

// Unblock inputs
await kvmHelper.unblockInputs();

// Check blocked inputs
Set<InputType> blockedTypes = await kvmHelper.getBlockedInputs();
bool isBlocked = await kvmHelper.isInputBlocked();
```

### Monitor Detection

#### Listen for Monitor Configuration Changes

```dart
Stream<List<Monitor>> monitorStream = kvmHelper.monitors();

monitorStream.listen((monitors) {
  print('Monitor configuration updated: ${monitors.length} monitors');
  for (final monitor in monitors) {
    print('  - ${monitor.name}: ${monitor.width}x${monitor.height} at (${monitor.x}, ${monitor.y})');
  }
});
```



## Input Types

### Keyboard Input Types
- `KeyboardInputType.keyDown`
- `KeyboardInputType.keyUp`
- `KeyboardInputType.flagsChanged`

### Mouse Input Types
- `MouseInputType.leftMouseDown`
- `MouseInputType.leftMouseUp`
- `MouseInputType.rightMouseDown`
- `MouseInputType.rightMouseUp`
- `MouseInputType.mouseMoved`
- `MouseInputType.leftMouseDragged`
- `MouseInputType.rightMouseDragged`
- `MouseInputType.scrollWheel`
- `MouseInputType.otherMouseDown`
- `MouseInputType.otherMouseUp`
- `MouseInputType.otherMouseDragged`

### Key Modifiers
- `KeyModifier.shift`
- `KeyModifier.control`
- `KeyModifier.option`
- `KeyModifier.command`
- `KeyModifier.capsLock`
- `KeyModifier.function`
- `KeyModifier.numericPad`
- `KeyModifier.help`

### Mouse Buttons
- `MouseButton.left`
- `MouseButton.right`
- `MouseButton.center`

## Monitor Model

The `Monitor` model contains the following properties:

- `id`: Unique identifier for the monitor
- `name`: Display name of the monitor
- `x`, `y`: Position coordinates (global desktop space)
- `width`, `height`: Dimensions
- `isPrimary`: Whether this is the primary monitor
- `scaleFactor`: Display scale factor

## Platform Support

- ✅ macOS
- ✅ Windows
- ✅ Linux (WIP)

## Troubleshooting Monitor Detection

- **Coordinate Systems:**
  - On macOS, all coordinates are in the global desktop space (origin at bottom-left of the primary display).
  - On Windows, the origin is at the top-left of the primary display.
  - Always use the coordinates from native mouse events for best results.
- **Vertical/Rotated Monitors:**
  - The plugin uses `CGDisplayBounds` on macOS for accurate detection, which works for vertical and rotated monitors.
  - If you have issues, print all monitor bounds and the cursor position for debugging.
- **No Monitor Found:**
  - If `getMonitorAt` returns null, the point may be outside all monitor bounds (e.g., in a "dead zone" between monitors).
  - Check your display arrangement in System Preferences (macOS) or Display Settings (Windows).

## macOS Implementation Notes

- **Monitor Change Detection:** Uses `NotificationCenter` to observe `NSApplication.didChangeScreenParametersNotification` for real-time updates.
- **Monitor Hit-Testing:** Uses `CGDisplayBounds` for each display to ensure correct detection regardless of orientation or arrangement.
- **Accessibility Permissions:** Required for input capture/injection, not for monitor detection.

## Example

See the `example/` directory for a complete working example that demonstrates all features of the plugin, including real-time monitor detection and input event handling.

## License

This project is licensed under the MIT License.

