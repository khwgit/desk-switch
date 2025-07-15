import 'package:freezed_annotation/freezed_annotation.dart';

part 'monitor.freezed.dart';
part 'monitor.g.dart';

@freezed
abstract class Monitor with _$Monitor {
  const Monitor._();
  const factory Monitor({
    required String id,
    required String name,
    required double x,
    required double y,
    required double width,
    required double height,
  }) = _Monitor;

  factory Monitor.fromJson(Map<String, dynamic> json) =>
      _$MonitorFromJson(json);

  /// Checks if the given global cursor position is within this monitor's bounds.
  /// Returns true if the point (x, y) is inside the monitor, false otherwise.
  bool contains(double x, double y) {
    return x >= this.x &&
        x <= this.x + width &&
        y >= this.y &&
        y <= this.y + height;
  }
}
