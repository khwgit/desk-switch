import 'package:desk_switch/models/client_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_profile.freezed.dart';
part 'server_profile.g.dart';

@freezed
abstract class ServerProfile with _$ServerProfile {
  const factory ServerProfile({
    String? name,
    int? broadcastPort,
    int? connectionPort,
    @Default([]) List<ClientProfile> clients,
    @Default([]) List<ClientConstraint> constraints,
  }) = _ServerProfile;

  // Map<Direction, List<ClientProfile>> get layout {
  //   final Map<Direction, List<ClientProfile>> result = {};
  //   for (final client in clients) {
  //     if (client.layout != null) {
  //       final direction = client.layout!.direction;
  //       result.putIfAbsent(direction, () => <ClientProfile>[]);
  //       result[direction]!.add(client);
  //     }
  //   }

  //   return result;
  // }

  const ServerProfile._();
  factory ServerProfile.fromJson(Map<String, dynamic> json) =>
      _$ServerProfileFromJson(json);
}
