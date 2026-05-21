import 'package:json_annotation/json_annotation.dart';

part 'order_model.g.dart';

@JsonSerializable()
class ProductSnapshot {
  final String name;
  final double price;
  final String? photoUrl;

  ProductSnapshot({
    required this.name,
    required this.price,
    this.photoUrl,
  });

  factory ProductSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ProductSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$ProductSnapshotToJson(this);
}

@JsonSerializable()
class CustomerSnapshot {
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String area;

  CustomerSnapshot({
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    required this.area,
  });

  String get fullName => '$firstName $lastName';

  factory CustomerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$CustomerSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerSnapshotToJson(this);
}

@JsonSerializable()
class OrderItemModel {
  final String productId;
  final ProductSnapshot productSnapshot;
  final List<String> restrictions;
  final int quantity;

  OrderItemModel({
    required this.productId,
    required this.productSnapshot,
    this.restrictions = const [],
    required this.quantity,
  });

  double get subtotal => quantity * productSnapshot.price;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$OrderItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemModelToJson(this);
}

@JsonSerializable()
class OrderModel {
  @JsonKey(name: '_id')
  final String id;
  final String userId;
  final CustomerSnapshot? customerSnapshot;
  final List<OrderItemModel> items;
  final String? customerNote;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String currentStatus;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    this.customerSnapshot,
    required this.items,
    this.customerNote,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.currentStatus,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  String get currentStatusText {
    switch (currentStatus) {
      case 'CREADO':
        return 'Enviado';
      case 'PENDIENTE_EN_CAJA':
        return 'Pendiente en Caja';
      case 'RECHAZADO_CAJA':
        return 'Rechazado en Caja';
      case 'ACEPTADO':
        return 'Aceptado por Caja';
      case 'EN_PREPARACION':
        return 'En preparación';
      case 'RECHAZADO_COCINA':
        return 'Rechazado por Cocina';
      case 'LISTO_PARA_ENTREGAR':
        return 'Listo para recoger';
      case 'ENTREGADO':
        return 'Entregado';
      default:
        return currentStatus;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) =>
      _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}
