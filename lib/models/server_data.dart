import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_data.freezed.dart';
part 'server_data.g.dart';

@freezed
abstract class ServerData with _$ServerData {
  const factory ServerData({
    required String id,
    required String name,
    ServerStatus? status,
    String? host,
    int? port,
  }) = _ServerData;

  factory ServerData.fromJson(Map<String, dynamic> json) =>
      _$ServerDataFromJson(json);
}

enum ServerStatus {
  online,
  offline,
  connected,
  connecting,
  disconnecting,
}
