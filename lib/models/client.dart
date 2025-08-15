import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'client.freezed.dart';
part 'client.g.dart';

@freezed
abstract class Client with _$Client {
  const Client._();
  const factory Client({
    required String id,
    required String name,
    String? host,
    int? port,

    @JsonKey(includeToJson: false, includeFromJson: false) WebSocket? socket,
  }) = _Client;

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
}

enum ClientStatus {
  online,
  offline,
}
