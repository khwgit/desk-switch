import 'package:freezed_annotation/freezed_annotation.dart';

part 'server.freezed.dart';
part 'server.g.dart';

@freezed
abstract class Server with _$Server {
  const factory Server({
    required String id,
    required String name,
    ServerStatus? status,
    String? host,
    int? port,
  }) = _Server;

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
}

enum ServerStatus {
  online,
  offline,
  connected,
  connecting,
  disconnecting,
}
