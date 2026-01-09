import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const kBandiwalaYellow = Color(0xFFFFC107);
const kWhite = Color(0xFFFFFFFF);
const kBorderGrey = Color(0xFFE5E7EB);
const kTextGrey = Color(0xFF6B7280);
const kLightGrey = Color(0xFFF9FAFB);

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String customerPhone = user?.phoneNumber ?? '';

    return Scaffold(
      backgroundColor: kLightGrey,
      appBar: AppBar(
        title: const Text(
          'My Orders',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: kWhite,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: kBorderGrey),
        ),
      ),
      body: customerPhone.isEmpty
          ? _buildEmptyState('Please login to view orders', Icons.login)
          : StreamBuilder<QuerySnapshot>(
        // ✅ FIX: Remove orderBy to avoid index requirement
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('customerPhone', isEqualTo: customerPhone)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: kBandiwalaYellow,
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.hasError) {
            debugPrint('❌ Firestore Error: ${snapshot.error}');
            return _buildEmptyState(
              'Something went wrong\nPlease try again',
              Icons.error_outline,
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
              'No orders yet',
              Icons.shopping_bag_outlined,
            );
          }

          // ✅ Sort in memory instead of Firestore query
          final sortedDocs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTimestamp = aData['timestamp'] as Timestamp?;
              final bTimestamp = bData['timestamp'] as Timestamp?;

              if (aTimestamp == null || bTimestamp == null) return 0;
              return bTimestamp.compareTo(aTimestamp); // Descending order
            });

          return RefreshIndicator(
            color: kBandiwalaYellow,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDocs.length,
              itemBuilder: (context, index) {
                final orderDoc = sortedDocs[index];
                final orderData = orderDoc.data() as Map<String, dynamic>;
                return _OrderCard(
                  orderData: orderData,
                  orderDocId: orderDoc.id,
                );
              },
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
              color: kBandiwalaYellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: kBandiwalaYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: kTextGrey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderDocId;

  const _OrderCard({
    required this.orderData,
    required this.orderDocId,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = orderData['orderId'] ?? 'N/A';
    final status = orderData['status'] ?? 'unknown';
    final timestamp = orderData['timestamp'] as Timestamp?;
    final grandTotal = orderData['grandTotal'] ?? 0.0;
    final itemsByVendor = orderData['itemsByVendor'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
            decoration: const BoxDecoration(
              color: kLightGrey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBandiwalaYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: kBandiwalaYellow,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderId,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timestamp != null
                            ? DateFormat('dd MMM yyyy, hh:mm a')
                            .format(timestamp.toDate())
                            : 'Date N/A',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kTextGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
          ),

          // Vendors List
          if (itemsByVendor.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: itemsByVendor.keys.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final vendorId = itemsByVendor.keys.elementAt(index);
                final vendorData = itemsByVendor[vendorId] as Map<String, dynamic>;
                return _VendorSection(
                  vendorData: vendorData,
                  vendorId: vendorId,
                );
              },
            ),

          // Order Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kBorderGrey, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 16, color: kTextGrey),
                    SizedBox(width: 6),
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: kTextGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kBandiwalaYellow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'order_created':
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.check_circle_outline;
        break;
      case 'preparing':
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.restaurant;
        break;
      case 'ready':
        bgColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple;
        icon = Icons.delivery_dining;
        break;
      case 'completed':
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        icon = Icons.info_outline;
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
            status.toUpperCase(),
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
  final Map<String, dynamic> vendorData;
  final String vendorId;

  const _VendorSection({
    required this.vendorData,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    final vendorName = vendorData['vendorName'] ?? 'Unknown Vendor';
    final items = vendorData['items'] as List<dynamic>? ?? [];
    final vendorStatus = vendorData['status'] ?? 'pending';
    final subtotal = vendorData['subtotal'] ?? vendorData['vendorSubtotal'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vendor Header with Status
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBandiwalaYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.store,
                color: kBandiwalaYellow,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                vendorName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildVendorStatusChip(vendorStatus),
          ],
        ),
        const SizedBox(height: 12),

        // Items List
        ...items.map((item) {
          final itemMap = item as Map<String, dynamic>;
          final name = itemMap['name'] ?? 'Unknown Item';
          final quantity = itemMap['quantity'] ?? 1;
          final price = itemMap['price'] ?? 0.0;
          final itemTotal = itemMap['total'] ?? (price * quantity);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: kTextGrey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$name × $quantity',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  '₹${itemTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: kLightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vendor Subtotal',
                style: TextStyle(
                  fontSize: 12,
                  color: kTextGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorStatusChip(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String displayText;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
        displayText = 'Pending';
        break;
      case 'accepted':
        bgColor = Colors.blue.withOpacity(0.15);
        textColor = Colors.blue.shade700;
        icon = Icons.check_circle_outline;
        displayText = 'Accepted';
        break;
      case 'preparing':
        bgColor = Colors.purple.withOpacity(0.15);
        textColor = Colors.purple.shade700;
        icon = Icons.restaurant_menu;
        displayText = 'Preparing';
        break;
      case 'ready':
        bgColor = Colors.teal.withOpacity(0.15);
        textColor = Colors.teal.shade700;
        icon = Icons.delivery_dining;
        displayText = 'Ready';
        break;
      case 'completed':
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        displayText = 'Completed';
        break;
      case 'rejected':
      case 'cancelled':
        bgColor = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        displayText = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.15);
        textColor = Colors.grey.shade700;
        icon = Icons.info_outline;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayText,
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
