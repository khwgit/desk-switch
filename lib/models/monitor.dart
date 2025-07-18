import 'dart:ui';

import 'package:desk_switch/models/device.pb.dart' as pb_device;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kvm_helper/kvm_helper.dart';

export 'package:kvm_helper/models/monitor.dart';

part 'monitor.freezed.dart';
part 'monitor.g.dart';

enum Direction {
  left,
  right,
  top,
  bottom,
}

///
@freezed
abstract class MonitorGate with _$MonitorGate {
  const factory MonitorGate({
    required String id,
    required Direction direction,
    required int min,
    required int max,
    required String nextClientId,
    required String nextMonitorId,
  }) = _MonitorGate;

  const MonitorGate._();
  factory MonitorGate.fromJson(Map<String, dynamic> json) =>
      _$MonitorGateFromJson(json);
}

// enum MonitorPosition {
//   left,
//   right,
//   above,
//   below,
// }

// @freezed
// abstract class MonitorConstraint with _$MonitorConstraint {
//   const factory MonitorConstraint({
//     required String a,
//     required String b,
//     required MonitorPosition position,
//     @Default(0) int offset,
//   }) = _MonitorConstraint;

//   const MonitorConstraint._();
//   factory MonitorConstraint.fromJson(Map<String, dynamic> json) =>
//       _$MonitorConstraintFromJson(json);
// }

// Conversion between Dart Monitor model and protobuf
extension MonitorToProto on Monitor {
  pb_device.Monitor toProto() {
    return pb_device.Monitor()
      ..id = id
      ..name = name
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
  }
}

extension ProtoToMonitor on pb_device.Monitor {
  Monitor toModel() {
    return Monitor(
      id: id,
      name: name,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }
}

/// Extension methods for Monitor
extension MonitorExtensions on Monitor {
  /// Calculates the distance between a cursor position and this monitor
  /// Returns a tuple of (xDistance, yDistance) where:
  /// - 0 means the cursor is within the monitor's bounds in that direction
  /// - Negative value means the cursor is outside the monitor (left/above)
  /// - Positive value means the cursor is outside the monitor (right/below)
  (double, double) distanceTo(double cursorX, double cursorY) {
    double xDistance = 0;
    double yDistance = 0;

    // Calculate X distance
    if (cursorX < x) {
      // Cursor is to the left of the monitor (negative direction)
      xDistance = cursorX - x;
    } else if (cursorX > x + width) {
      // Cursor is to the right of the monitor (positive direction)
      xDistance = cursorX - (x + width);
    }
    // If cursorX is between x and x + width, xDistance remains 0

    // Calculate Y distance
    if (cursorY < y) {
      // Cursor is above the monitor (negative direction)
      yDistance = cursorY - y;
    } else if (cursorY > y + height) {
      // Cursor is below the monitor (positive direction)
      yDistance = cursorY - (y + height);
    }
    // If cursorY is between y and y + height, yDistance remains 0

    return (xDistance, yDistance);
  }

  Offset clamp(Offset position) {
    return Offset(
      position.dx.clamp(x, x + width),
      position.dy.clamp(y, y + height),
    );
  }
}
