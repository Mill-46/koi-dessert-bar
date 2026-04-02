import 'package:flutter/material.dart';

import 'package:koi_dessert_bar/core/services/supabase_service.dart';
import 'package:koi_dessert_bar/features/order/models/cart_item_model.dart';
import 'package:koi_dessert_bar/features/order/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  OrderModel? _lastOrder;

  bool get isLoading => _isLoading;
  String? get error => _error;
  OrderModel? get lastOrder => _lastOrder;

  Future<String?> placeOrder({
    required List<CartItemModel> items,
    required String type,
    String? address,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final order = await SupabaseService.instance.createOrder(
        items: items,
        type: type,
        address: address,
        notes: notes,
      );
      _lastOrder = order;
      return order.id;
    } catch (e) {
      _error = SupabaseService.instance.describeOrderError(e);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await SupabaseService.instance.cancelOrder(orderId);
    } catch (e) {
      _error = SupabaseService.instance.describeOrderError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
