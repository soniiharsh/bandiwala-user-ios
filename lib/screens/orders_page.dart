import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../providers/orders_provider.dart';
import '../core/theme/theme.dart';
import '../widgets/skeletons.dart';
import 'track_order_page.dart';
import 'order_details_page.dart';

const kBandiWalaYellow = AppColors.primary;

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: cs.outlineVariant),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const OrdersListSkeleton(),
        error: (_, __) => _buildEmptyState(
          'Something went wrong\nPlease try again',
          Icons.error_outline,
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState(
              'No orders yet',
              Icons.shopping_bag_outlined,
            );
          }
          return RefreshIndicator(
            color: kBandiWalaYellow,
            onRefresh: () async => ref.invalidate(userOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) => _OrderCard(order: orders[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kBandiWalaYellow.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: kBandiWalaYellow),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final AppOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailsPage(order: order)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant, width: 1),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Order Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kBandiWalaYellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: kBandiWalaYellow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.id.substring(0, order.id.length > 6 ? 6 : order.id.length).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.createdAt != null
                              ? DateFormat(
                                  'dd MMM yyyy, hh:mm a',
                                ).format(order.createdAt!)
                              : 'Date N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
            ),

            // Vendors List
            if (order.itemsByVendor.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: order.itemsByVendor.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (_, index) {
                  final vendorOrder = order.itemsByVendor.values.elementAt(
                    index,
                  );
                  return _VendorSection(vendorOrder: vendorOrder);
                },
              ),

            // Order Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${order.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kBandiWalaYellow,
                    ),
                  ),
                ],
              ),
            ),
            if (order.status == OrderStatus.outForDelivery &&
                order.deliveryAgentLocation != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrackOrderPage(
                          latitude: order.deliveryAgentLocation!['latitude']!,
                          longitude: order.deliveryAgentLocation!['longitude']!,
                          orderId: order.id,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text('Track Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kBandiWalaYellow,
                      side: const BorderSide(color: kBandiWalaYellow),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case OrderStatus.confirmed:
      case OrderStatus.orderCreated:
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        icon = Icons.check_circle_outline;
        break;
      case OrderStatus.preparing:
        bgColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        icon = Icons.restaurant;
        break;
      case OrderStatus.ready:
        bgColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        icon = Icons.delivery_dining;
        break;
      case OrderStatus.outForDelivery:
        bgColor = Colors.teal.withValues(alpha: 0.1);
        textColor = Colors.teal;
        icon = Icons.directions_bike;
        break;
      case OrderStatus.completed:
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.value.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorSection extends StatelessWidget {
  final VendorOrder vendorOrder;

  const _VendorSection({required this.vendorOrder});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vendorName = vendorOrder.vendorName;
    final items = vendorOrder.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBandiWalaYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, color: kBandiWalaYellow, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                vendorName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.entries.map((entry) {
          final item = entry.value;
          final itemTotal = item.price * item.quantity;
          // Build customization summary
          final List<String> customParts = [];
          if (item.selectedOption != null) {
            customParts.add(item.selectedOption!['name'] ?? '');
          }
          for (final addon in item.selectedAddons) {
            customParts.add(addon['name'] ?? '');
          }
          final customLabel = customParts.where((s) => s.isNotEmpty).join(', ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.name} × ${item.quantity}',
                        style: TextStyle(fontSize: 13, color: cs.onSurface),
                      ),
                      if (customLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            customLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₹${itemTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${items.values.fold(0.0, (s, i) => s + i.price * i.quantity).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
