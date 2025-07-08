// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kvm_helper/kvm_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('permission test', (WidgetTester tester) async {
    final KvmHelper plugin = KvmHelper();

    // Test permission check
    final bool hasPermission = await plugin.isPermissionGranted();
    expect(hasPermission, isA<bool>());

    // Test blocked inputs
    final Set<InputType> blockedInputs = await plugin.getBlockedInputs();
    expect(blockedInputs, isA<Set<InputType>>());
  });

  testWidgets('input blocking test', (WidgetTester tester) async {
    final KvmHelper plugin = KvmHelper();
    Set<InputType> blockedInputs = {};

    // Test setting input blocked
    await plugin.blockInputs();

    // Test getting blocked inputs
    blockedInputs = await plugin.getBlockedInputs();
    expect(blockedInputs, isNotEmpty);

    // Test unblocking
    await plugin.unblockInputs();

    // Test getting blocked inputs
    blockedInputs = await plugin.getBlockedInputs();
    expect(blockedInputs, isEmpty);
  });
}
