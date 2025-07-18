import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_profile.freezed.dart';
part 'client_profile.g.dart';

@freezed
abstract class ClientProfile with _$ClientProfile {
  const factory ClientProfile({
    String? id,
    String? name,
  }) = _ClientProfile;

  const ClientProfile._();
  factory ClientProfile.fromJson(Map<String, dynamic> json) =>
      _$ClientProfileFromJson(json);
}

enum Position {
  left,
  right,
  top,
  bottom,
}

@freezed
abstract class ClientConstraint with _$ClientConstraint {
  const factory ClientConstraint({
    required String a,
    required String b,
    required Position position,
    @Default(0) int offset,
  }) = _ClientConstraint;

  const ClientConstraint._();
  factory ClientConstraint.fromJson(Map<String, dynamic> json) =>
      _$ClientConstraintFromJson(json);
}

// enum Direction {
//   left,
//   right,
//   top,
//   bottom,
// }

// @freezed
// abstract class ClientLayout with _$ClientLayout {
//   const factory ClientLayout({
//     required Direction direction,
//     @Default(0) int offset,
//   }) = _ClientLayout;

//   const ClientLayout._();
//   factory ClientLayout.fromJson(Map<String, dynamic> json) =>
//       _$ClientLayoutFromJson(json);
// }
