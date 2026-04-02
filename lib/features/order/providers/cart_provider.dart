import 'package:flutter/material.dart';

import 'package:koi_dessert_bar/features/order/models/cart_item_model.dart';
import 'package:koi_dessert_bar/features/product/models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);
  double get total =>
      _items.fold<double>(0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  void addItem(ProductModel product, {int qty = 1}) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + qty,
      );
    } else {
      _items.add(CartItemModel(product: product, quantity: qty));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void decrementItem(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) {
      return;
    }

    final current = _items[index];
    if (current.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = current.copyWith(quantity: current.quantity - 1);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
