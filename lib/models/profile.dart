import 'package:desk_switch/models/server_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
sealed class Profile with _$Profile {
  const factory Profile.server({
    String? name,
    int? broadcastPort,
    int? connectionPort,
  }) = ServerProfile;

  const factory Profile.client({
    String? id,
    String? name,
  }) = ClientProfile;

  const Profile._();
  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
