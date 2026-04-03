import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:koi_dessert_bar/core/constants/app_colors.dart';
import 'package:koi_dessert_bar/core/services/supabase_service.dart';
import 'package:koi_dessert_bar/core/utils/currency_formatter.dart';
import 'package:koi_dessert_bar/features/order/models/order_model.dart';

class OrderDetailView extends StatelessWidget {
  final OrderModel order;

  const OrderDetailView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupabaseService.instance.fetchOrderItems(order.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _OrderSummary(order: order),
              const SizedBox(height: 16),
              Text(
                'Items',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text('No items found for this order.')
              else
                ...items.map((item) => _OrderItemTile(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final OrderModel order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${order.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Status: ${order.status}'),
          Text('Type: ${order.isDelivery ? 'Delivery' : 'Dine In'}'),
          if (order.address != null && order.address!.isNotEmpty)
            Text('Address: ${order.address}'),
          if (order.notes != null && order.notes!.isNotEmpty)
            Text('Notes: ${order.notes}'),
          const SizedBox(height: 8),
          Text(
            'Total: ${CurrencyFormatter.rupiah(order.totalPrice)}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final product = item['products'] as Map<String, dynamic>?;
    final name = product?['name'] as String? ?? 'Unknown product';
    final imageUrl = product?['image_url'] as String?;
    final quantity = item['quantity'] as int? ?? 0;
    final unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0;
    final subtotal = (item['subtotal'] as num?)?.toDouble() ?? unitPrice * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              child: imageUrl != null
                  ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('$quantity × ${CurrencyFormatter.rupiah(unitPrice)}'),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.rupiah(subtotal),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
