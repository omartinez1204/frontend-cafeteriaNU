// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      role: json['role'] as String? ?? 'cliente',
      profile: RegisterProfile.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'role': instance.role,
      'profile': instance.profile,
    };

RegisterProfile _$RegisterProfileFromJson(Map<String, dynamic> json) =>
    RegisterProfile(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      nickname: json['nickname'] as String?,
      area: json['area'] as String? ?? 'alumno',
    );

Map<String, dynamic> _$RegisterProfileToJson(RegisterProfile instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'nickname': instance.nickname,
      'area': instance.area,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user,
    };
