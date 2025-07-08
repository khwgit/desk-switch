import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kvm_helper/kvm_helper.dart';
import 'package:kvm_helper/kvm_helper_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelKvmHelper platform = MethodChannelKvmHelper();
  const MethodChannel channel = MethodChannel('kvm_helper');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'requestPermission':
              case 'isPermissionGranted':
              case 'setBlockedInputs':
                return true;
              case 'getBlockedInputs':
                return <String>[];
              default:
                return null;
            }
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('requestPermission', () async {
    final result = await platform.requestPermission(const {
      ...InputType.values,
    });
    expect(result, true);
  });

  test('isPermissionGranted', () async {
    final result = await platform.isPermissionGranted(const {
      ...InputType.values,
    });
    expect(result, true);
  });

  test('setBlockedInputs', () async {
    final result = await platform.setBlockedInputs(const {
      ...InputType.values,
    });
    expect(result, true);
  });

  test('getBlockedInputs', () async {
    final result = await platform.getBlockedInputs();
    expect(result, isEmpty);
  });
}
