import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:koi_dessert_bar/core/constants/app_colors.dart';
import 'package:koi_dessert_bar/core/router/app_router.dart';
import 'package:koi_dessert_bar/core/utils/currency_formatter.dart';
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
            onPressed: () =>
                context.push(AppRoutes.adminProductForm, extra: null),
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : admin.products.isEmpty
                    ? const Center(child: Text('No products found'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: admin.products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = admin.products[index];
                          return _AdminProductTile(
                            product: product,
                            isDeleting: admin.isDeletingProduct(product.id),
                            onEdit: () => context.push(
                              AppRoutes.adminProductForm,
                              extra: product,
                            ),
                            onDelete: () => _handleDelete(product),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final admin = context.read<AdminProvider>();
    final success = await admin.deleteProduct(product);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (admin.notice ?? 'Product deleted')
              : (admin.error ?? 'Failed to delete'),
        ),
        backgroundColor: success ? AppColors.primary : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _AdminProductTile extends StatelessWidget {
  final ProductModel product;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminProductTile({
    required this.product,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                  '${CurrencyFormatter.rupiah(product.price)} • Stock: ${product.stock}',
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
                onPressed: isDeleting ? null : onEdit,
              ),
              IconButton(
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
