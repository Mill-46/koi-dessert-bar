// ============================================================
// lib/core/services/supabase_service.dart
// Single-responsibility data access layer wrapping Supabase
// ============================================================

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/models/profile_model.dart';
import '../../features/order/models/cart_item_model.dart';
import '../../features/order/models/order_model.dart';
import '../../features/product/models/product_model.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  // Shorthand for Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  // ── Current user helpers ─────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  String get currentUserId => currentUser!.id;
  bool get isLoggedIn => currentUser != null;

  // ─────────────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async => await _client.auth.signOut();

  String describeAuthError(Object error) {
    final raw = error.toString();

    if (raw.contains('status code 404')) {
      return 'Registrasi gagal karena auth flow project tidak cocok dengan konfigurasi aplikasi. Konfigurasi aplikasi sudah diperbarui. Coba lagi.';
    }
    if (raw.contains('User already registered')) {
      return 'Email sudah terdaftar. Silakan login atau gunakan email lain.';
    }
    if (raw.contains('Invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Email belum diverifikasi. Cek inbox Anda lalu coba login lagi.';
    }

    return raw;
  }

  // ─────────────────────────────────────────────────────────
  // PROFILES
  // ─────────────────────────────────────────────────────────

  /// Fetch the current user's profile
  Future<ProfileModel> fetchProfile() async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', currentUserId)
        .single();
    return ProfileModel.fromMap(data);
  }

  /// Update full_name or avatar
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', currentUserId);
  }

  // ─────────────────────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────────────────────

  /// Fetch all available products, optionally filtered by category
  Future<List<ProductModel>> fetchProducts({String? category}) async {
    dynamic query = _client.from('products').select();
    query = query.eq('is_available', true);

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => ProductModel.fromMap(e)).toList();
  }

  /// Fetch all categories (for filter chips)
  Future<List<String>> fetchCategories() async {
    final data = await _client
        .from('products')
        .select('category')
        .eq('is_available', true);
    final categories = (data as List)
        .map((e) => e['category'] as String)
        .toSet()
        .toList();
    categories.insert(0, 'All');
    return categories;
  }

  // ── Admin product CRUD ────────────────────────────────────

  Future<List<ProductModel>> fetchAllProducts({String? search}) async {
    dynamic query = _client.from('products').select();

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<List<ProductModel>> fetchProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) {
      return const [];
    }

    final data = await _client
        .from('products')
        .select()
        .inFilter('id', productIds);

    return (data as List).map((e) => ProductModel.fromMap(e)).toList();
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    final data = await _client
        .from('products')
        .insert(product.toInsertMap())
        .select()
        .single();
    return ProductModel.fromMap(data);
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final data = await _client
        .from('products')
        .update(product.toInsertMap())
        .eq('id', product.id)
        .select()
        .single();
    return ProductModel.fromMap(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
  }

  // ── Supabase Storage — product images ─────────────────────

  /// Uploads an image file and returns the public URL
  Future<String> uploadProductImage(File imageFile, String productId) async {
    final ext = imageFile.path.split('.').last;
    final path = 'products/$productId.$ext';

    await _client.storage
        .from('product-images')
        .upload(path, imageFile, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from('product-images').getPublicUrl(path);
  }

  Future<void> deleteProductImage(String path) async {
    await _client.storage.from('product-images').remove([path]);
  }

  // ─────────────────────────────────────────────────────────
  // ORDERS
  // ─────────────────────────────────────────────────────────

  /// Atomic order creation: insert order + all items in a transaction-like fashion.
  /// Supabase doesn't expose transactions directly, so we insert order first,
  /// then items; the DB trigger handles stock decrement & validation.
  Future<OrderModel> createOrder({
    required List<CartItemModel> items,
    required String type,          // 'delivery' | 'onsite'
    String? address,
    String? notes,
  }) async {
    final latestProducts = await fetchProductsByIds(
      items.map((item) => item.product.id).toSet().toList(),
    );
    final latestById = {
      for (final product in latestProducts) product.id: product,
    };

    for (final item in items) {
      final latest = latestById[item.product.id];
      if (latest == null || !latest.isAvailable || latest.stock < item.quantity) {
        throw Exception(
          'Insufficient stock for ${latest?.name ?? item.product.name}. '
          'Available stock: ${latest?.stock ?? 0}.',
        );
      }
    }

    // Calculate total client-side (DB also validates via triggers)
    final total = items.fold<double>(
      0, (sum, item) => sum + (item.product.price * item.quantity),
    );

    // 1️⃣ Insert order header
    final orderData = await _client
        .from('orders')
        .insert({
          'user_id':     currentUserId,
          'type':        type,
          'address':     address,
          'notes':       notes,
          'status':      'pending',
          'total_price': total,
        })
        .select()
        .single();

    final order = OrderModel.fromMap(orderData);

    // 2️⃣ Insert all order items (batch)
    final itemsPayload = items
        .map((item) => {
              'order_id':   order.id,
              'product_id': item.product.id,
              'quantity':   item.quantity,
              'unit_price': item.product.price,
            })
        .toList();

    try {
      await _client.from('order_items').insert(itemsPayload);
    } catch (error) {
      await _client
          .from('orders')
          .update({'status': 'cancelled', 'notes': 'Auto-cancelled: item insert failed'})
          .eq('id', order.id);
      rethrow;
    }

    await addPointsForOrder(items);

    return order;
  }

  String describeOrderError(Object error) {
    final raw = error.toString();

    if (raw.contains('Insufficient stock for product')) {
      return 'Stock produk tidak mencukupi. Silakan kurangi jumlah item atau pilih produk lain.';
    }

    if (raw.contains('Insufficient stock for')) {
      final match = RegExp(
        r'Insufficient stock for\s+([^.,]+).*Available stock:\s*(\d+)',
      ).firstMatch(raw);
      if (match != null) {
        return 'Stok ${match.group(1)} tidak mencukupi. Sisa stok: ${match.group(2)}.';
      }

      return 'Stock produk tidak mencukupi. Silakan kurangi jumlah item atau pilih produk lain.';
    }

    if (raw.contains('23514')) {
      return 'Stock produk tidak mencukupi. Coba kurangi jumlah pesanan atau pilih produk lain.';
    }

    if (raw.contains('delivery_needs_address')) {
      return 'Alamat delivery wajib diisi.';
    }

    return raw;
  }

  /// Real-time stream of the current user's orders
  Future<List<OrderModel>> fetchMyOrders() async {
    final data = await _client
        .from('orders')
        .select()
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => OrderModel.fromMap(row)).toList();
  }

  Stream<List<OrderModel>> watchMyOrders({
    Duration interval = const Duration(seconds: 5),
  }) async* {
    while (true) {
      yield await fetchMyOrders();
      await Future<void>.delayed(interval);
    }
  }

  /// Cancel an order — the DB trigger will reject if not 'pending'
  Future<void> cancelOrder(String orderId) async {
    await _client
        .from('orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId);
  }

  // ── Admin order management ────────────────────────────────

  /// Real-time stream of ALL orders for admin dashboard
  Future<List<OrderModel>> fetchAllOrders() async {
    final data = await _client
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    return (data as List).map((row) => OrderModel.fromMap(row)).toList();
  }

  Stream<List<OrderModel>> watchAllOrders({
    Duration interval = const Duration(seconds: 5),
  }) async* {
    while (true) {
      yield await fetchAllOrders();
      await Future<void>.delayed(interval);
    }
  }

  /// Update any order status (admin)
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }

  /// Fetch order items with product details for a specific order
  Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    final data = await _client
        .from('order_items')
        .select('*, products(name, image_url, price)')
        .eq('order_id', orderId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> addPointsForOrder(List<CartItemModel> items) async {
    final earnedPoints =
        items.fold<int>(0, (sum, item) => sum + item.quantity);
    if (earnedPoints <= 0) {
      return;
    }

    final profile = await fetchProfile();
    await _client
        .from('profiles')
        .update({'points': profile.points + earnedPoints})
        .eq('id', currentUserId);
  }

  /// Admin stats: count by status
  Future<Map<String, int>> fetchOrderStats() async {
    final data = await _client.from('orders').select('status');
    final stats = <String, int>{
      'pending': 0, 'processing': 0, 'ready': 0, 'completed': 0, 'cancelled': 0,
    };
    for (final row in data as List) {
      final status = row['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }
}
