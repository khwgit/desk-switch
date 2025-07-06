import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'kvm_helper_platform_interface.dart';
import 'models/input.dart';

/// An implementation of [KvmHelperPlatform] that uses method channels.
class MethodChannelKvmHelper extends KvmHelperPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kvm_helper');

  static const EventChannel _inputsEventChannel = EventChannel(
    'kvm_helper/inputs',
  );

  @override
  Future<bool> requestPermission([Set<InputType>? types]) async {
    final result = await methodChannel.invokeMethod<bool>('requestPermission', {
      'types': types?.map((type) => type.name).toList(),
    });
    return result ?? false;
  }

  @override
  Future<bool> isPermissionGranted([Set<InputType>? types]) async {
    final result = await methodChannel.invokeMethod<bool>(
      'isPermissionGranted',
      {'types': types?.map((type) => type.name).toList()},
    );
    return result ?? false;
  }

  @override
  Stream<Map<String, dynamic>> inputs([Set<InputType>? types]) {
    // Pass the types parameter to the native platform for filtering
    return _inputsEventChannel
        .receiveBroadcastStream(
          {'types': types?.map((type) => type.name).toList()},
        )
        .map(
          (event) => Map<String, dynamic>.from(event),
        );
  }

  @override
  Future<void> injectMouseInput(MouseInput input) async {
    await methodChannel.invokeMethod('injectMouseInput', input.toJson());
  }

  @override
  Future<void> injectKeyboardInput(KeyboardInput input) async {
    await methodChannel.invokeMethod('injectKeyboardInput', input.toJson());
  }

  @override
  Future<bool> setInputBlocked(bool blocked, [Set<InputType>? types]) async {
    final result = await methodChannel.invokeMethod<bool>('setInputBlocked', {
      'blocked': blocked,
      'types': types?.map((type) => type.name).toList(),
    });
    return result ?? false;
  }

  @override
  Future<bool> isInputBlocked([Set<InputType>? types]) async {
    final inputs = await getBlockedInputs();
    return types == null
        ? inputs.isNotEmpty
        : inputs.any((type) => types.contains(type));
  }

  @override
  Future<Set<InputType>> getBlockedInputs() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>(
      'getBlockedInputs',
    );
    if (result == null) {
      return <InputType>{};
    }

    final blockedTypes = <InputType>{};
    for (final typeName in result) {
      if (typeName is String) {
        final inputType = InputType.values.firstWhere(
          (type) => type.name == typeName,
          orElse: () => InputType.keyboard, // fallback, shouldn't happen
        );
        blockedTypes.add(inputType);
      }
    }
    return blockedTypes;
  }
}
