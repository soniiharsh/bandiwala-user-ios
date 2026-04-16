import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../core/theme/theme.dart';
import '../providers/vendors_provider.dart';
import '../providers/items_provider.dart';
import 'track_order_page.dart';

const _kYellow = AppColors.primary;

class OrderDetailsPage extends ConsumerWidget {
  final AppOrder order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: cs.outlineVariant),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: cs.outlineVariant, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _buildStatusBadge(order.status),
                  const SizedBox(height: 12),
                  Text(
                    order.createdAt != null
                        ? DateFormat(
                            'dd MMM yyyy, hh:mm a',
                          ).format(order.createdAt!)
                        : 'Date N/A',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Delivery Address
            _buildSection(
              context,
              title: 'Delivery Address',
              icon: Icons.location_on_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.deliveryAddress.address,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurface,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phone: ${order.customerPhone}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Order Items
            _buildSection(
              context,
              title: 'Order Items',
              icon: Icons.shopping_bag_outlined,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.itemsByVendor.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 32, color: cs.outlineVariant),
                itemBuilder: (_, index) {
                  final vendorId = order.itemsByVendor.keys.elementAt(index);
                  final vendorOrder = order.itemsByVendor.values.elementAt(
                    index,
                  );
                  return _VendorSection(
                    vendorId: vendorId,
                    vendorOrder: vendorOrder,
                  );
                },
              ),
            ),

            // Payment Details
            _buildSection(
              context,
              title: 'Payment Details',
              icon: Icons.receipt_outlined,
              child: Column(
                children: [
                  _buildPriceRow(context, 'Items Total', order.itemsTotal),
                  const SizedBox(height: 8),
                  _buildPriceRow(context, 'Delivery Fee', order.deliveryFee),
                  const SizedBox(height: 8),
                  _buildPriceRow(context, 'Platform Fee', order.platformFee),
                  const SizedBox(height: 8),
                  _buildPriceRow(context, 'Food Tax', order.foodTax),
                  const SizedBox(height: 8),
                  _buildPriceRow(context, 'Delivery Tax', order.deliveryTax),
                  if (order.couponApplied) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow(
                      context,
                      'Coupon Discount (${order.couponCode})',
                      -order.couponDiscount,
                      isDiscount: true,
                    ),
                  ],
                  Divider(height: 24, color: cs.outlineVariant),
                  _buildPriceRow(
                    context,
                    'Grand Total',
                    order.grandTotal,
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment: ${order.paymentMethod.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Track Order
            if (order.status == OrderStatus.outForDelivery &&
                order.deliveryAgentLocation != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Track Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kYellow,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _kYellow),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    double amount, {
    bool isBold = false,
    bool isDiscount = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold ? cs.onSurface : cs.onSurfaceVariant,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isDiscount
                ? Colors.green
                : isBold
                ? _kYellow
                : cs.onSurface,
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Text(
            status.value.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vendor section ────────────────────────────────────────────────────────────

class _VendorSection extends ConsumerWidget {
  final String vendorId;
  final VendorOrder vendorOrder;

  const _VendorSection({required this.vendorId, required this.vendorOrder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vendorAsync = ref.watch(vendorStreamProvider(vendorId));
    final vendorImageUrl = vendorAsync.valueOrNull?.imageUrl ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor header with image
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: vendorImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: vendorImageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          _imagePlaceholder(isDark, Icons.store, size: 48),
                      errorWidget: (_, __, ___) =>
                          _imagePlaceholder(isDark, Icons.store, size: 48),
                    )
                  : _imagePlaceholder(isDark, Icons.store, size: 48),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                vendorOrder.vendorName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Items
        ...vendorOrder.items.entries.map((entry) {
          final itemId = entry.key;
          final item = entry.value;
          return _ItemRow(itemId: itemId, item: item, vendorId: vendorId);
        }),
      ],
    );
  }

  Widget _imagePlaceholder(bool isDark, IconData icon, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: size * 0.45,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
    );
  }
}

// ── Item row ──────────────────────────────────────────────────────────────────

class _ItemRow extends ConsumerWidget {
  final String itemId;
  final OrderItem item;
  final String vendorId;

  const _ItemRow({
    required this.itemId,
    required this.item,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAsync = ref.watch(itemStreamProvider(itemId));
    final imageUrl = itemAsync.valueOrNull?.imageUrl ?? '';

    final itemTotal = item.price * item.quantity;
    final List<String> customParts = [];
    if (item.selectedOption != null) {
      customParts.add(item.selectedOption!['name'] ?? '');
    }
    for (final addon in item.selectedAddons) {
      customParts.add(addon['name'] ?? '');
    }
    final customLabel = customParts.where((s) => s.isNotEmpty).join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Item image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _itemPlaceholder(isDark),
                    errorWidget: (_, __, ___) => _itemPlaceholder(isDark),
                  )
                : _itemPlaceholder(isDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name} × ${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                if (customLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      customLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${itemTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPlaceholder(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.fastfood_outlined,
        size: 24,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
    );
  }
}
