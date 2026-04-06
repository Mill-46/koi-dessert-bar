import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:koi_dessert_bar/core/services/supabase_service.dart';
import 'package:koi_dessert_bar/features/product/models/product_model.dart';

class AdminProvider extends ChangeNotifier {
  List<ProductModel> _products = const [];
  Map<String, int> _stats = const {};
  final Set<String> _deletingProductIds = <String>{};
  bool _isLoading = false;
  String? _error;
  String? _notice;

  List<ProductModel> get products => _products;
  Map<String, int> get stats => _stats;
  Set<String> get deletingProductIds => _deletingProductIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get notice => _notice;

  bool isDeletingProduct(String productId) =>
      _deletingProductIds.contains(productId);

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

  Future<bool> saveProduct(
    ProductModel product, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    _isLoading = true;
    _error = null;
    _notice = null;
    notifyListeners();
    try {
      if (product.id.isEmpty) {
        var createdProduct =
            await SupabaseService.instance.createProduct(product);
        if (imageBytes != null) {
          final imageUrl = await SupabaseService.instance.uploadProductImage(
            imageBytes,
            createdProduct.id,
            fileName: imageName ?? 'product-image.jpg',
          );
          createdProduct = await SupabaseService.instance.updateProduct(
            createdProduct.copyWith(imageUrl: imageUrl),
          );
        }
        _notice = 'Product added successfully.';
      } else {
        var updatedProduct = product;
        if (imageBytes != null) {
          final imageUrl = await SupabaseService.instance.uploadProductImage(
            imageBytes,
            product.id,
            fileName: imageName ?? 'product-image.jpg',
            previousImageUrl: product.imageUrl,
          );
          updatedProduct = updatedProduct.copyWith(imageUrl: imageUrl);
        }
        await SupabaseService.instance.updateProduct(updatedProduct);
        _notice = 'Product updated successfully.';
      }

      await loadProducts();
      return true;
    } catch (e) {
      _error = SupabaseService.instance.describeAdminError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(ProductModel product) async {
    if (_deletingProductIds.contains(product.id)) {
      return false;
    }

    _error = null;
    _notice = null;
    _deletingProductIds.add(product.id);
    notifyListeners();
    try {
      await SupabaseService.instance.deleteProduct(product);
      _products.removeWhere((item) => item.id == product.id);
      _notice = 'Product deleted.';
      return true;
    } catch (e) {
      if (SupabaseService.instance.isForeignKeyViolation(e)) {
        await SupabaseService.instance.archiveProduct(product);
        _products.removeWhere((item) => item.id == product.id);
        _notice =
            'Product is already used in orders, so it was archived and hidden from the menu.';
        return true;
      }

      _error = SupabaseService.instance.describeAdminError(e);
      return false;
    } finally {
      _deletingProductIds.remove(product.id);
      notifyListeners();
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
