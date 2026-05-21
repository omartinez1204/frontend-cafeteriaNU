// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  nickname: json['nickname'] as String?,
  photoUrl: json['photoUrl'] as String?,
  area: json['area'] as String,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'nickname': instance.nickname,
      'photoUrl': instance.photoUrl,
      'area': instance.area,
    };

UserScholarship _$UserScholarshipFromJson(Map<String, dynamic> json) =>
    UserScholarship(
      hasDesayuno: json['hasDesayuno'] as bool? ?? false,
      hasComida: json['hasComida'] as bool? ?? false,
    );

Map<String, dynamic> _$UserScholarshipToJson(UserScholarship instance) =>
    <String, dynamic>{
      'hasDesayuno': instance.hasDesayuno,
      'hasComida': instance.hasComida,
    };

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['_id'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
  profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
  scholarship: UserScholarship.fromJson(
    json['scholarship'] as Map<String, dynamic>,
  ),
  isActive: json['isActive'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  '_id': instance.id,
  'email': instance.email,
  'role': instance.role,
  'profile': instance.profile,
  'scholarship': instance.scholarship,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt?.toIso8601String(),
};
