import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:koi_dessert_bar/core/constants/app_colors.dart';
import 'package:koi_dessert_bar/core/services/supabase_service.dart';
import 'package:koi_dessert_bar/core/utils/currency_formatter.dart';
import 'package:koi_dessert_bar/features/admin/providers/admin_provider.dart';
import 'package:koi_dessert_bar/features/order/models/order_model.dart';

class AdminOrderManagementView extends StatelessWidget {
  const AdminOrderManagementView({super.key});

  static const Map<String, List<String>> _transitions = {
    'pending': ['processing', 'cancelled'],
    'processing': ['ready'],
    'ready': ['completed'],
    'completed': [],
    'cancelled': [],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Management')),
      body: StreamBuilder<List<OrderModel>>(
        stream: SupabaseService.instance.watchAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _AdminOrderCard(
              order: orders[index],
              nextStatuses: _transitions[orders[index].status] ?? [],
            ),
          );
        },
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final List<String> nextStatuses;

  const _AdminOrderCard({
    required this.order,
    required this.nextStatuses,
  });

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        order.isDelivery
                            ? Icons.delivery_dining_rounded
                            : Icons.restaurant_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        order.isDelivery ? 'Delivery' : 'Dine In',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          if (order.isDelivery && order.address != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.address!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          Divider(height: 20, color: Colors.grey.shade100),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.rupiah(order.totalPrice),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (nextStatuses.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: nextStatuses.map((nextStatus) {
                    final isCancelling = nextStatus == 'cancelled';
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        onPressed: () =>
                            _updateStatus(context, admin, nextStatus),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCancelling ? Colors.red : AppColors.primary,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          _statusLabel(nextStatus),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Final',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'processing':
        return '→ Processing';
      case 'ready':
        return '→ Ready';
      case 'completed':
        return '→ Complete';
      case 'cancelled':
        return 'Cancel';
      default:
        return status;
    }
  }

  void _updateStatus(
    BuildContext context,
    AdminProvider admin,
    String newStatus,
  ) {
    if (newStatus == 'cancelled') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Cancel Order'),
          content: const Text('Are you sure you want to cancel this order?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                admin.updateOrderStatus(order.id, newStatus);
                Navigator.pop(context);
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      return;
    }

    admin.updateOrderStatus(order.id, newStatus);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
