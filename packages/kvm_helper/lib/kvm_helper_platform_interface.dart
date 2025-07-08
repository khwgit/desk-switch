import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kvm_helper_method_channel.dart';
import 'models/input.dart';
import 'models/monitor.dart';

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

  /// Requests permissions for the given types of input events.
  Future<bool> requestPermission(Set<InputType> types) {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  /// Checks if all permissions for the given types are granted.
  Future<bool> isPermissionGranted(Set<InputType> types) {
    throw UnimplementedError('isPermissionGranted() has not been implemented.');
  }

  /// Stream of input events as raw JSON data from the unified channel.
  Stream<Map<String, dynamic>> inputs(Set<InputType> types) {
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

  /// Sets whether inputs should be blocked.
  Future<bool> setBlockedInputs(Set<InputType> types) {
    throw UnimplementedError('setBlockedInputs() has not been implemented.');
  }

  /// Returns the set of currently blocked input types.
  Future<Set<InputType>> getBlockedInputs() {
    throw UnimplementedError('getBlockedInputs() has not been implemented.');
  }

  /// Stream of monitor configuration changes.
  /// Updates when monitors are connected, disconnected, or rearranged.
  Stream<List<Monitor>> monitors() {
    throw UnimplementedError('monitors() has not been implemented.');
  }
}
