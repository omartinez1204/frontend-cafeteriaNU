// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductSnapshot _$ProductSnapshotFromJson(Map<String, dynamic> json) =>
    ProductSnapshot(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      photoUrl: json['photoUrl'] as String?,
    );

Map<String, dynamic> _$ProductSnapshotToJson(ProductSnapshot instance) =>
    <String, dynamic>{
      'name': instance.name,
      'price': instance.price,
      'photoUrl': instance.photoUrl,
    };

CustomerSnapshot _$CustomerSnapshotFromJson(Map<String, dynamic> json) =>
    CustomerSnapshot(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      photoUrl: json['photoUrl'] as String?,
      area: json['area'] as String,
    );

Map<String, dynamic> _$CustomerSnapshotToJson(CustomerSnapshot instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'photoUrl': instance.photoUrl,
      'area': instance.area,
    };

OrderItemModel _$OrderItemModelFromJson(Map<String, dynamic> json) =>
    OrderItemModel(
      productId: json['productId'] as String,
      productSnapshot: ProductSnapshot.fromJson(
        json['productSnapshot'] as Map<String, dynamic>,
      ),
      restrictions:
          (json['restrictions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$OrderItemModelToJson(OrderItemModel instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productSnapshot': instance.productSnapshot,
      'restrictions': instance.restrictions,
      'quantity': instance.quantity,
    };

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: json['_id'] as String,
  userId: json['userId'] as String,
  customerSnapshot: json['customerSnapshot'] == null
      ? null
      : CustomerSnapshot.fromJson(
          json['customerSnapshot'] as Map<String, dynamic>,
        ),
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  customerNote: json['customerNote'] as String?,
  totalAmount: (json['totalAmount'] as num).toDouble(),
  paymentMethod: json['paymentMethod'] as String,
  paymentStatus: json['paymentStatus'] as String,
  currentStatus: json['currentStatus'] as String,
  rejectionReason: json['rejectionReason'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'customerSnapshot': instance.customerSnapshot,
      'items': instance.items,
      'customerNote': instance.customerNote,
      'totalAmount': instance.totalAmount,
      'paymentMethod': instance.paymentMethod,
      'paymentStatus': instance.paymentStatus,
      'currentStatus': instance.currentStatus,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
