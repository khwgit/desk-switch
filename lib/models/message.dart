import 'package:desk_switch/models/input.dart';
import 'package:desk_switch/models/message.pb.dart' as pb;
import 'package:desk_switch/models/monitor.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
abstract class ClientPackage with _$ClientPackage {
  const factory ClientPackage({
    required String id,
    required Message message,
  }) = _ClientPackage;

  const ClientPackage._();
  factory ClientPackage.fromJson(Map<String, dynamic> json) =>
      _$ClientPackageFromJson(json);
}

@freezed
sealed class Message with _$Message {
  const factory Message.input(
    Input input,
  ) = InputMessage;
  const factory Message.device({
    required List<Monitor> monitors,
  }) = DeviceMessage;

  const Message._();
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
}

// Conversion between Dart Message model and protobuf
extension MessageToProto on Message {
  pb.Message toProto() {
    return switch (this) {
      InputMessage input =>
        pb.Message()
          ..kind = pb.MessageType.INPUT
          ..input = (pb.InputMessage()..input = input.input.toProto()),
      DeviceMessage client =>
        pb.Message()
          ..kind = pb.MessageType.DEVICE
          ..device = (pb.DeviceMessage()
            ..monitors.addAll(client.monitors.map((m) => m.toProto()))),
    };
  }
}

extension ProtoToMessage on pb.Message {
  Message toModel() {
    switch (kind) {
      case pb.MessageType.INPUT:
        if (hasInput()) {
          return Message.input(input.input.toModel());
        }
        throw Exception('Message has INPUT kind but no input data');
      case pb.MessageType.DEVICE:
        if (hasDevice()) {
          return Message.device(
            monitors: device.monitors.map((m) => m.toModel()).toList(),
          );
        }
        throw Exception('Message has DEVICE kind but no device data');
      default:
        throw Exception('Unknown message type: $kind');
    }
  }
}
