import 'package:flutter_test/flutter_test.dart';
import 'package:input_capture_injection/input_capture_injection.dart';
import 'package:input_capture_injection/input_capture_injection_method_channel.dart';
import 'package:input_capture_injection/input_capture_injection_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockInputCaptureInjectionPlatform
    with MockPlatformInterfaceMixin
    implements InputCaptureInjectionPlatform {
  final Set<InputType> _blockedTypes = <InputType>{};

  @override
  Future<void> injectKeyboardInput(KeyboardInput input) {
    // TODO: implement injectKeyboardInput
    throw UnimplementedError();
  }

  @override
  Future<void> injectMouseInput(MouseInput input) {
    // TODO: implement injectMouseInput
    throw UnimplementedError();
  }

  @override
  Future<bool> isPermissionGranted([Set<InputType>? types]) {
    // For testing purposes, return true for all permissions
    return Future.value(true);
  }

  @override
  Stream<Map<String, dynamic>> inputs() {
    // TODO: implement inputs
    throw UnimplementedError();
  }

  @override
  Future<bool> requestPermission([Set<InputType>? types]) {
    // For testing purposes, return true for all permissions
    return Future.value(true);
  }

  @override
  Future<bool> setInputBlocked(bool blocked, [Set<InputType>? types]) {
    if (types == null) {
      if (blocked) {
        _blockedTypes.addAll(InputType.values);
      } else {
        _blockedTypes.clear();
      }
    } else {
      if (blocked) {
        _blockedTypes.addAll(types);
      } else {
        _blockedTypes.removeAll(types);
      }
    }
    return Future.value(true);
  }

  @override
  Future<bool> isInputBlocked([Set<InputType>? types]) {
    if (types == null) {
      return Future.value(_blockedTypes.isNotEmpty);
    }
    return Future.value(types.any((type) => _blockedTypes.contains(type)));
  }

  @override
  Future<Set<InputType>> getBlockedInputs() {
    return Future.value(_blockedTypes);
  }
}

void main() {
  final InputCaptureInjectionPlatform initialPlatform =
      InputCaptureInjectionPlatform.instance;

  test('$MethodChannelInputCaptureInjection is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelInputCaptureInjection>());
  });

  test('setLocalInputBlocked and isLocalInputBlocked', () async {
    InputCaptureInjection inputCaptureInjectionPlugin = InputCaptureInjection();
    MockInputCaptureInjectionPlatform fakePlatform =
        MockInputCaptureInjectionPlatform();
    InputCaptureInjectionPlatform.instance = fakePlatform;

    // Test blocking all inputs
    await inputCaptureInjectionPlugin.setInputBlocked(true);
    expect(await inputCaptureInjectionPlugin.isInputBlocked(), true);

    // Test unblocking all inputs
    await inputCaptureInjectionPlugin.setInputBlocked(false);
    expect(await inputCaptureInjectionPlugin.isInputBlocked(), false);

    // Test blocking specific input type
    await inputCaptureInjectionPlugin.setInputBlocked(true, {
      InputType.keyboard,
    });
    expect(
      await inputCaptureInjectionPlugin.isInputBlocked({InputType.keyboard}),
      true,
    );
    expect(
      await inputCaptureInjectionPlugin.isInputBlocked({InputType.mouse}),
      false,
    );

    // Test blocking mouse input
    await inputCaptureInjectionPlugin.setInputBlocked(true, {InputType.mouse});
    expect(
      await inputCaptureInjectionPlugin.isInputBlocked({InputType.mouse}),
      true,
    );
    expect(
      await inputCaptureInjectionPlugin.isInputBlocked({InputType.keyboard}),
      true,
    );
  });

  test('getBlockedInputs', () async {
    InputCaptureInjection inputCaptureInjectionPlugin = InputCaptureInjection();
    MockInputCaptureInjectionPlatform fakePlatform =
        MockInputCaptureInjectionPlatform();
    InputCaptureInjectionPlatform.instance = fakePlatform;

    // Test initial state (no blocked inputs)
    expect(await inputCaptureInjectionPlugin.getBlockedInputs(), isEmpty);

    // Test blocking keyboard only
    await inputCaptureInjectionPlugin.setInputBlocked(true, {
      InputType.keyboard,
    });
    expect(await inputCaptureInjectionPlugin.getBlockedInputs(), {
      InputType.keyboard,
    });

    // Test blocking mouse only
    await inputCaptureInjectionPlugin.setInputBlocked(false, {
      InputType.keyboard,
    });
    await inputCaptureInjectionPlugin.setInputBlocked(true, {InputType.mouse});
    expect(await inputCaptureInjectionPlugin.getBlockedInputs(), {
      InputType.mouse,
    });

    // Test blocking both keyboard and mouse
    await inputCaptureInjectionPlugin.setInputBlocked(true, {
      InputType.keyboard,
      InputType.mouse,
    });
    expect(await inputCaptureInjectionPlugin.getBlockedInputs(), {
      InputType.keyboard,
      InputType.mouse,
    });

    // Test unblocking all
    await inputCaptureInjectionPlugin.setInputBlocked(false);
    expect(await inputCaptureInjectionPlugin.getBlockedInputs(), isEmpty);
  });

  test('requestPermission and isPermissionGranted', () async {
    InputCaptureInjection inputCaptureInjectionPlugin = InputCaptureInjection();
    MockInputCaptureInjectionPlatform fakePlatform =
        MockInputCaptureInjectionPlatform();
    InputCaptureInjectionPlatform.instance = fakePlatform;

    // Test requesting all permissions
    final allPermissionsResult = await inputCaptureInjectionPlugin
        .requestPermission();
    expect(allPermissionsResult, true);

    // Test checking all permissions
    final allPermissionsCheck = await inputCaptureInjectionPlugin
        .isPermissionGranted();
    expect(allPermissionsCheck, true);

    // Test requesting specific permission
    final keyboardPermissionResult = await inputCaptureInjectionPlugin
        .requestPermission({InputType.keyboard});
    expect(keyboardPermissionResult, true);

    // Test checking specific permission
    final keyboardPermissionCheck = await inputCaptureInjectionPlugin
        .isPermissionGranted({InputType.keyboard});
    expect(keyboardPermissionCheck, true);

    // Test checking mouse permission
    final mousePermissionCheck = await inputCaptureInjectionPlugin
        .isPermissionGranted({InputType.mouse});
    expect(mousePermissionCheck, true);
  });
}
