import 'package:flutter/material.dart';

import 'package:koi_dessert_bar/core/services/supabase_service.dart';
import 'package:koi_dessert_bar/features/product/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = const [];
  List<String> _categories = const ['All'];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await SupabaseService.instance.fetchCategories();
      _products = await SupabaseService.instance.fetchProducts(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    await loadProducts();
  }
}
