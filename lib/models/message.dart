import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/models/monitor.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
sealed class Message with _$Message {
  const factory Message.input({
    required Input input,
  }) = InputMessage;
  const factory Message.device({
    required String id,
    required List<Monitor> monitors,
  }) = DeviceMessage;

  const Message._();
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}
