import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  @JsonKey(name: 'role', defaultValue: 'cliente')
  final String role;
  @JsonKey(name: 'profile')
  final RegisterProfile profile;

  RegisterRequest({
    required this.email,
    required this.password,
    this.role = 'cliente',
    required this.profile,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable()
class RegisterProfile {
  @JsonKey(name: 'firstName')
  final String firstName;
  @JsonKey(name: 'lastName')
  final String lastName;
  @JsonKey(name: 'nickname')
  final String? nickname;
  @JsonKey(name: 'area', defaultValue: 'alumno')
  final String area;

  RegisterProfile({
    required this.firstName,
    required this.lastName,
    this.nickname,
    this.area = 'alumno',
  });

  factory RegisterProfile.fromJson(Map<String, dynamic> json) =>
      _$RegisterProfileFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterProfileToJson(this);
}


@JsonSerializable()
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
