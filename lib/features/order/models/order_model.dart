import 'package:equatable/equatable.dart';

class OrderModel extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String? address;
  final String status;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.type,
    this.address,
    required this.status,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isDelivery => type == 'delivery';
  bool get isCancellable => isPending;

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        type: map['type'] as String,
        address: map['address'] as String?,
        status: map['status'] as String,
        totalPrice: (map['total_price'] as num?)?.toDouble() ?? 0,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        address,
        status,
        totalPrice,
        notes,
        createdAt,
        updatedAt,
      ];
}
