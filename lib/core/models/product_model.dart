import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class RestrictionModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final List<String> applicableCategories;

  RestrictionModel({
    required this.id,
    required this.name,
    this.applicableCategories = const [],
  });

  factory RestrictionModel.fromJson(Map<String, dynamic> json) =>
      _$RestrictionModelFromJson(json);
  Map<String, dynamic> toJson() => _$RestrictionModelToJson(this);
}

@JsonSerializable()
class ProductModel {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? photoUrl;
  final List<RestrictionModel> availableRestrictions;
  final bool isVisible;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.photoUrl,
    this.availableRestrictions = const [],
    this.isVisible = true,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
