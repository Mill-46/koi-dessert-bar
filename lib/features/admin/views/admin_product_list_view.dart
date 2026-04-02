import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:koi_dessert_bar/core/constants/app_colors.dart';
import 'package:koi_dessert_bar/core/router/app_router.dart';
import 'package:koi_dessert_bar/features/admin/providers/admin_provider.dart';
import 'package:koi_dessert_bar/features/product/models/product_model.dart';

class AdminProductListView extends StatefulWidget {
  const AdminProductListView({super.key});

  @override
  State<AdminProductListView> createState() => _AdminProductListViewState();
}

class _AdminProductListViewState extends State<AdminProductListView> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => context.push(AppRoutes.adminProductForm, extra: null),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          admin.loadProducts();
                        },
                      )
                    : null,
              ),
              onChanged: (value) => admin.loadProducts(search: value),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: admin.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  )
                : admin.products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: admin.products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _AdminProductTile(
                          product: admin.products[index],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AdminProductTile extends StatelessWidget {
  final ProductModel product;

  const _AdminProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppColors.background,
                      child: const Icon(
                        Icons.fastfood_rounded,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${product.price.toStringAsFixed(0)} • Stock: ${product.stock}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () =>
                    context.push(AppRoutes.adminProductForm, extra: product),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _confirmDelete(context, admin),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              admin.deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
