import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_helper/kvm_helper.dart';
import 'package:kvm_helper/kvm_helper_method_channel.dart';
import 'package:kvm_helper/kvm_helper_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKvmHelperPlatform
    with MockPlatformInterfaceMixin
    implements KvmHelperPlatform {
  @override
  Future<bool> requestPermission(Set<InputType> types) => Future.value(true);

  @override
  Future<bool> isPermissionGranted(Set<InputType> types) => Future.value(true);

  @override
  Stream<Map<String, dynamic>> inputs(Set<InputType> types) =>
      const Stream.empty();

  @override
  Future<void> injectMouseInput(MouseInput input) => Future.value();

  @override
  Future<void> injectKeyboardInput(KeyboardInput input) => Future.value();

  @override
  Future<bool> setBlockedInputs(Set<InputType> types) => Future.value(true);

  @override
  Future<Set<InputType>> getBlockedInputs() => Future.value(<InputType>{});

  @override
  Stream<List<Monitor>> monitors() => const Stream.empty();
}

void main() {
  final KvmHelperPlatform initialPlatform = KvmHelperPlatform.instance;

  test('$MethodChannelKvmHelper is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKvmHelper>());
  });

  test('requestPermission', () async {
    KvmHelper kvmHelperPlugin = KvmHelper();
    MockKvmHelperPlatform fakePlatform = MockKvmHelperPlatform();
    KvmHelperPlatform.instance = fakePlatform;

    final result = await kvmHelperPlugin.requestPermission();
    expect(result, true);
  });

  test('isPermissionGranted', () async {
    KvmHelper kvmHelperPlugin = KvmHelper();
    MockKvmHelperPlatform fakePlatform = MockKvmHelperPlatform();
    KvmHelperPlatform.instance = fakePlatform;

    final result = await kvmHelperPlugin.isPermissionGranted();
    expect(result, true);
  });

  test('inputs with types parameter', () async {
    KvmHelper kvmHelperPlugin = KvmHelper();
    MockKvmHelperPlatform fakePlatform = MockKvmHelperPlatform();
    KvmHelperPlatform.instance = fakePlatform;

    // Test with keyboard only
    final keyboardStream = kvmHelperPlugin.inputs({InputType.keyboard});
    expect(keyboardStream, isA<Stream<Input>>());

    // Test with mouse only
    final mouseStream = kvmHelperPlugin.inputs({InputType.mouse});
    expect(mouseStream, isA<Stream<Input>>());

    // Test with both types
    final bothStream = kvmHelperPlugin.inputs({
      InputType.keyboard,
      InputType.mouse,
    });
    expect(bothStream, isA<Stream<Input>>());

    // Test with no types (all inputs)
    final allStream = kvmHelperPlugin.inputs();
    expect(allStream, isA<Stream<Input>>());
  });

  test('monitors stream', () {
    KvmHelper kvmHelperPlugin = KvmHelper();
    MockKvmHelperPlatform fakePlatform = MockKvmHelperPlatform();
    KvmHelperPlatform.instance = fakePlatform;

    final monitorsStream = kvmHelperPlugin.monitors();
    expect(monitorsStream, isA<Stream<List<Monitor>>>());
  });
}
