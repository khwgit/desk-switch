import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';

@freezed
abstract class DeviceGate with _$DeviceGate {
  const factory DeviceGate({
    required Rect rect,
    required String deviceId,
    required String monitorId,
  }) = _DeviceGate;

  const DeviceGate._();
}
