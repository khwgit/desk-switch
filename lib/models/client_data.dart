import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_data.freezed.dart';
part 'client_data.g.dart';

@freezed
abstract class ClientData with _$ClientData {
  const ClientData._();
  const factory ClientData({
    required String id,
    required String name,
    String? host,
    int? port,

    @JsonKey(includeToJson: false, includeFromJson: false) WebSocket? socket,
  }) = _ClientData;

  factory ClientData.fromJson(Map<String, dynamic> json) =>
      _$ClientDataFromJson(json);
}

enum ClientStatus {
  online,
  offline,
}
