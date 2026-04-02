import 'dart:io';

import 'package:flutter/material.dart';

import 'package:koi_dessert_bar/core/services/supabase_service.dart';
import 'package:koi_dessert_bar/features/product/models/product_model.dart';

class AdminProvider extends ChangeNotifier {
  List<ProductModel> _products = const [];
  Map<String, int> _stats = const {};
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products =
          await SupabaseService.instance.fetchAllProducts(search: search);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await SupabaseService.instance.fetchOrderStats();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> saveProduct(ProductModel product, {File? imageFile}) async {
    _isLoading = true;
    notifyListeners();
    try {
      var imageUrl = product.imageUrl;
      if (imageFile != null) {
        final uploadId = product.id.isEmpty
            ? 'new_${DateTime.now().millisecondsSinceEpoch}'
            : product.id;
        imageUrl =
            await SupabaseService.instance.uploadProductImage(imageFile, uploadId);
      }

      final updatedProduct = product.copyWith(imageUrl: imageUrl);
      if (product.id.isEmpty) {
        await SupabaseService.instance.createProduct(updatedProduct);
      } else {
        await SupabaseService.instance.updateProduct(updatedProduct);
      }

      await loadProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await SupabaseService.instance.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await SupabaseService.instance.updateOrderStatus(orderId, status);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
