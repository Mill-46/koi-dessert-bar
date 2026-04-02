import 'package:equatable/equatable.dart';

import '../../product/models/product_model.dart';

class CartItemModel extends Equatable {
  final ProductModel product;
  final int quantity;
  final String? note;

  const CartItemModel({
    required this.product,
    required this.quantity,
    this.note,
  });

  double get subtotal => product.price * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? note,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [product, quantity, note];
}
