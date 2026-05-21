import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserProfile {
  final String firstName;
  final String lastName;
  final String? nickname;
  final String? photoUrl;
  final String area;

  UserProfile({
    required this.firstName,
    required this.lastName,
    this.nickname,
    this.photoUrl,
    required this.area,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable()
class UserScholarship {
  final bool hasDesayuno;
  final bool hasComida;

  UserScholarship({
    this.hasDesayuno = false,
    this.hasComida = false,
  });

  factory UserScholarship.fromJson(Map<String, dynamic> json) =>
      _$UserScholarshipFromJson(json);
  Map<String, dynamic> toJson() => _$UserScholarshipToJson(this);
}

@JsonSerializable()
class UserModel {
  @JsonKey(name: '_id')
  final String id;
  final String email;
  final String role;
  final UserProfile profile;
  final UserScholarship scholarship;
  final bool isActive;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.profile,
    required this.scholarship,
    this.isActive = false,
    this.createdAt,
  });

  String get fullName => '${profile.firstName} ${profile.lastName}';

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
