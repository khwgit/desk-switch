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
    return KvmHelperPlatform.instance.requestPermission(
      types ?? const {...InputType.values},
    );
  }

  Future<bool> isPermissionGranted([Set<InputType>? types]) {
    return KvmHelperPlatform.instance.isPermissionGranted(
      types ?? const {...InputType.values},
    );
  }

  Stream<Input> inputs([Set<InputType>? types]) {
    return KvmHelperPlatform.instance
        .inputs(types ?? const {...InputType.values})
        .map((event) => Input.fromJson(event));
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

  Future<bool> setBlockedInputs([Set<InputType>? types]) {
    return KvmHelperPlatform.instance.setBlockedInputs(
      types ?? const {...InputType.values},
    );
  }

  Future<void> blockInputs([Set<InputType>? types]) {
    return setBlockedInputs(types);
  }

  Future<void> unblockInputs([Set<InputType>? types]) {
    return types == null
        ? setBlockedInputs({})
        : getBlockedInputs().then(
            (blocked) => setBlockedInputs(
              blocked.difference(types),
            ),
          );
  }

  Future<Set<InputType>> getBlockedInputs() {
    return KvmHelperPlatform.instance.getBlockedInputs();
  }

  Future<bool> isInputBlocked([Set<InputType>? types]) async {
    return getBlockedInputs().then(
      (blocked) => types == null
          ? blocked.isNotEmpty
          : blocked.any((type) => types.contains(type)),
    );
  }

  Stream<List<Monitor>> monitors() {
    return KvmHelperPlatform.instance.monitors();
  }
}
