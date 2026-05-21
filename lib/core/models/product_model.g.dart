// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestrictionModel _$RestrictionModelFromJson(Map<String, dynamic> json) =>
    RestrictionModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      applicableCategories:
          (json['applicableCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$RestrictionModelToJson(RestrictionModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'applicableCategories': instance.applicableCategories,
    };

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
  id: json['_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  category: json['category'] as String,
  photoUrl: json['photoUrl'] as String?,
  availableRestrictions:
      (json['availableRestrictions'] as List<dynamic>?)
          ?.map((e) => RestrictionModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  isVisible: json['isVisible'] as bool? ?? true,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'category': instance.category,
      'photoUrl': instance.photoUrl,
      'availableRestrictions': instance.availableRestrictions,
      'isVisible': instance.isVisible,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
