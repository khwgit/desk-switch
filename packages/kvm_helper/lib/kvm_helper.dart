import 'kvm_helper_platform_interface.dart';
import 'models/input.dart';
import 'models/monitor.dart';

export 'models/input.dart';
export 'models/monitor.dart';

class KvmHelper {
  const KvmHelper._();
  static const KvmHelper instance = KvmHelper._();
  factory KvmHelper() => instance;

  Future<bool> requestPermission([Set<InputType>? types]) {
    return KvmHelperPlatform.instance.requestPermission(types);
  }

  Future<bool> isPermissionGranted([Set<InputType>? types]) {
    return KvmHelperPlatform.instance.isPermissionGranted(types);
  }

  Stream<Input> inputs([Set<InputType>? types]) {
    return KvmHelperPlatform.instance
        .inputs(types)
        .map(
          (event) => Input.fromJson(event),
        );
  }

  Future<void> injectMouseInput(MouseInput input) {
    return KvmHelperPlatform.instance.injectMouseInput(input);
  }

  Future<void> injectKeyboardInput(KeyboardInput input) {
    return KvmHelperPlatform.instance.injectKeyboardInput(input);
  }

  Future<void> injectInput(Input input) {
    return switch (input) {
      MouseInput() => injectMouseInput(input),
      KeyboardInput() => injectKeyboardInput(input),
    };
  }

  Future<bool> setInputBlocked(bool blocked, [Set<InputType>? types]) {
    return KvmHelperPlatform.instance.setInputBlocked(
      blocked,
      types,
    );
  }

  Future<bool> isInputBlocked([Set<InputType>? types]) {
    return KvmHelperPlatform.instance.isInputBlocked(types);
  }

  Future<Set<InputType>> getBlockedInputs() {
    return KvmHelperPlatform.instance.getBlockedInputs();
  }

  Stream<List<Monitor>> monitors() {
    return KvmHelperPlatform.instance.monitors();
  }
}
