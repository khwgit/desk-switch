import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kvm_helper_method_channel.dart';
import 'models/input.dart';

abstract class KvmHelperPlatform extends PlatformInterface {
  /// Constructs a KvmHelperPlatform.
  KvmHelperPlatform() : super(token: _token);

  static final Object _token = Object();

  static KvmHelperPlatform _instance = MethodChannelKvmHelper();

  /// The default instance of [KvmHelperPlatform] to use.
  ///
  /// Defaults to [MethodChannelKvmHelper].
  static KvmHelperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KvmHelperPlatform] when
  /// they register themselves.
  static set instance(KvmHelperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Requests permission to capture and inject input events.
  /// When [types] is null, requests all input capture and injection permissions.
  Future<bool> requestPermission([Set<InputType>? types]) {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  /// Checks if permission is granted.
  /// When [types] is null, returns false if any input capture and injection permission is not granted.
  Future<bool> isPermissionGranted([Set<InputType>? types]) {
    throw UnimplementedError('isPermissionGranted() has not been implemented.');
  }

  /// Stream of all input events from the unified channel.
  /// When [types] is null, returns all input events.
  /// When [types] is provided, filters to only the specified input types.
  Stream<Map<String, dynamic>> inputs([Set<InputType>? types]) {
    throw UnimplementedError('inputs() has not been implemented.');
  }

  /// Injects a mouse event.
  Future<void> injectMouseInput(MouseInput input) {
    throw UnimplementedError('injectMouseInput() has not been implemented.');
  }

  /// Injects a keyboard event.
  Future<void> injectKeyboardInput(KeyboardInput input) {
    throw UnimplementedError('injectKeyboardInput() has not been implemented.');
  }

  /// Sets whether input should be blocked.
  /// When [types] is null, blocks all inputs.
  Future<bool> setInputBlocked(bool blocked, [Set<InputType>? types]) {
    throw UnimplementedError('setInputBlocked() has not been implemented.');
  }

  /// Checks if input is blocked.
  /// When [types] is null, returns true if any input is blocked.
  Future<bool> isInputBlocked([Set<InputType>? types]) {
    throw UnimplementedError('isInputBlocked() has not been implemented.');
  }

  /// Returns the set of currently blocked input types.
  Future<Set<InputType>> getBlockedInputs() {
    throw UnimplementedError('getBlockedInputs() has not been implemented.');
  }
}
