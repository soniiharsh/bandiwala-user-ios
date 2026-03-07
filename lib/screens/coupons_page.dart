import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kBandiwalaYellow = Color(0xFFFFC107);

class CouponsPage extends StatelessWidget {
  final double cartAmount;
  final List<String> cartVendorIds;
  final Map<String, double> vendorAmounts;
  final Map<String, String> vendorNames;

  const CouponsPage({
    super.key,
    required this.cartAmount,
    required this.cartVendorIds,
    required this.vendorAmounts,
    required this.vendorNames,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Apply coupon',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: kBandiwalaYellow,
                strokeWidth: 3,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final applicableCoupons = <Map<String, dynamic>>[];
          final notApplicableCoupons = <Map<String, dynamic>>[];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final couponData = {'id': doc.id, ...data};

            // Check usage limit
            final hasUsageLimit = couponData['hasUsageLimit'] ?? false;
            final maxUsage = couponData['maxUsage'];
            final currentUsage = couponData['currentUsage'] ?? 0;
            if (hasUsageLimit && maxUsage != null && currentUsage >= maxUsage)
              continue;

            final isWholeApp = couponData['isWholeApp'] ?? true;
            final minAmount = (couponData['minAmount'] ?? 0).toDouble();

            List<String> applicableVendorIds = [];
            double relevantAmount = 0;
            double remainingAmount = 0;
            bool isApplicable = false;
            bool shouldShowCoupon = true;

            if (isWholeApp) {
              applicableVendorIds = List.from(cartVendorIds);
              relevantAmount = cartAmount;
              remainingAmount = minAmount - cartAmount;
              isApplicable = cartAmount >= minAmount;
            } else {
              final couponVendorIds = List<String>.from(
                couponData['vendorIds'] ?? [],
              );

              if (couponVendorIds.isEmpty) {
                shouldShowCoupon = false;
              } else {
                applicableVendorIds = _findMatchingVendors(
                  cartVendorIds: cartVendorIds,
                  couponVendorIds: couponVendorIds,
                  vendorNames: vendorNames,
                );

                if (applicableVendorIds.isEmpty) {
                  shouldShowCoupon = false;
                } else {
                  relevantAmount = applicableVendorIds.fold(
                    0.0,
                    (sum, id) => sum + (vendorAmounts[id] ?? 0),
                  );
                  remainingAmount = minAmount - relevantAmount;
                  isApplicable = relevantAmount >= minAmount;
                }
              }
            }

            if (!shouldShowCoupon) continue;

            couponData['applicableVendorIds'] = applicableVendorIds;
            couponData['remainingAmount'] = remainingAmount;
            couponData['isApplicable'] = isApplicable;
            couponData['relevantAmount'] = relevantAmount;

            if (isApplicable) {
              applicableCoupons.add(couponData);
            } else {
              notApplicableCoupons.add(couponData);
            }
          }

          final allCoupons = [...applicableCoupons, ...notApplicableCoupons];

          if (allCoupons.isEmpty) return _buildEmptyState();

          return Column(
            children: [
              // Manual coupon entry
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: kBandiwalaYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter a valid coupon code',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          color: kBandiwalaYellow,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Available Coupons',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: allCoupons.length,
                  itemBuilder: (context, index) {
                    final coupon = allCoupons[index];
                    return _CouponCard(
                      coupon: coupon,
                      remainingAmount: coupon['remainingAmount'] as double,
                      isApplicable: coupon['isApplicable'] as bool,
                      vendorNames: vendorNames,
                      applicableVendorIds:
                          coupon['applicableVendorIds'] as List<String>,
                      isWholeApp: coupon['isWholeApp'] ?? true,
                      vendorAmounts: vendorAmounts,
                      onApply: () {
                        if (coupon['isApplicable'] as bool) {
                          Clipboard.setData(
                            ClipboardData(text: coupon['couponCode'] as String),
                          );
                          Navigator.pop(context, coupon);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<String> _findMatchingVendors({
    required List<String> cartVendorIds,
    required List<String> couponVendorIds,
    required Map<String, String> vendorNames,
  }) {
    final matchedIds = <String>[];
    for (var cartId in cartVendorIds) {
      final normalizedCartId = cartId.trim();
      for (var couponId in couponVendorIds) {
        if (normalizedCartId == couponId.trim()) {
          matchedIds.add(cartId);
          break;
        }
      }
    }
    return matchedIds;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No coupons available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for exciting offers',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final double remainingAmount;
  final bool isApplicable;
  final Map<String, String> vendorNames;
  final List<String> applicableVendorIds;
  final bool isWholeApp;
  final Map<String, double> vendorAmounts;
  final VoidCallback onApply;

  const _CouponCard({
    required this.coupon,
    required this.remainingAmount,
    required this.isApplicable,
    required this.vendorNames,
    required this.applicableVendorIds,
    required this.isWholeApp,
    required this.vendorAmounts,
    required this.onApply,
  });

  String _buildAddMoreMessage() {
    if (isApplicable || applicableVendorIds.isEmpty) return '';

    final minAmount = (coupon['minAmount'] ?? 0).toDouble();

    if (isWholeApp) {
      return 'Shop for ₹${remainingAmount.toStringAsFixed(0)} more to apply offer';
    }

    final totalFromVendors = applicableVendorIds.fold(
      0.0,
      (sum, id) => sum + (vendorAmounts[id] ?? 0),
    );
    final shortage = minAmount - totalFromVendors;
    if (shortage <= 0) return '';

    if (applicableVendorIds.length == 1) {
      final vendorName =
          vendorNames[applicableVendorIds[0]] ?? 'this restaurant';
      return 'Add ₹${shortage.toStringAsFixed(0)} more from $vendorName';
    } else if (applicableVendorIds.length == 2) {
      final name1 = vendorNames[applicableVendorIds[0]] ?? 'Restaurant 1';
      final name2 = vendorNames[applicableVendorIds[1]] ?? 'Restaurant 2';
      return 'Add ₹${shortage.toStringAsFixed(0)} more from $name1 or $name2';
    } else {
      final name1 = vendorNames[applicableVendorIds[0]] ?? 'Restaurant';
      final others = applicableVendorIds.length - 1;
      return 'Add ₹${shortage.toStringAsFixed(0)} more from $name1 or $others others';
    }
  }

  // ✅ FIXED: No longer shows % — shows ₹ flat discount amount
  String _getMainDescription() {
    final couponType = coupon['couponType'] ?? 'discount';
    final discountAmount = (coupon['discountAmount'] ?? 0).toDouble();
    final minAmount = (coupon['minAmount'] ?? 0).toDouble();

    if (couponType == 'freebie') {
      final freebieName = coupon['freebieName'] ?? 'FREE ITEM';
      return 'Get $freebieName FREE';
    } else if (couponType == 'freeDelivery') {
      return 'Free Delivery on this order';
    } else {
      // ✅ Fixed: flat ₹ amount, not percentage
      if (minAmount > 0) {
        return 'Save ₹${discountAmount.toInt()} on orders above ₹${minAmount.toInt()}';
      }
      return 'Save ₹${discountAmount.toInt()} on this order';
    }
  }

  // ✅ FIXED: Detailed description also uses ₹ flat amount
  String _getDetailedDescription() {
    final description = coupon['description'] ?? '';
    if (description.isNotEmpty) return description;

    final couponType = coupon['couponType'] ?? 'discount';
    final couponCode = coupon['couponCode'] ?? '';
    final discountAmount = (coupon['discountAmount'] ?? 0).toDouble();
    final minAmount = (coupon['minAmount'] ?? 0).toDouble();
    final maxDiscount = coupon['maxDiscount'];

    if (couponType == 'freeDelivery') {
      return minAmount > 0
          ? 'Free delivery on orders above ₹${minAmount.toInt()}. Use code $couponCode.'
          : 'Free delivery on this order. Use code $couponCode.';
    } else if (couponType == 'freebie') {
      final freebieName = coupon['freebieName'] ?? 'free item';
      return minAmount > 0
          ? 'Get $freebieName free on orders above ₹${minAmount.toInt()}. Use code $couponCode.'
          : 'Get $freebieName free with this order. Use code $couponCode.';
    } else {
      // ✅ Fixed: flat ₹ discount language
      String desc =
          'Get flat ₹${discountAmount.toInt()} off using code $couponCode';
      if (minAmount > 0) desc += ' on orders above ₹${minAmount.toInt()}';
      if (maxDiscount != null)
        desc += '. Max discount ₹${(maxDiscount as num).toInt()}';
      return '$desc.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final couponCode = coupon['couponCode'] ?? '';
    final mainDesc = _getMainDescription();
    final detailedDesc = _getDetailedDescription();
    final addMoreMessage = _buildAddMoreMessage();

    return GestureDetector(
      onTap: isApplicable ? onApply : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: kBandiwalaYellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer,
                      color: kBandiwalaYellow,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          couponCode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mainDesc,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: isApplicable ? onApply : null,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: isApplicable
                          ? null
                          : Colors.grey.shade100,
                    ),
                    child: Text(
                      'Apply',
                      style: TextStyle(
                        color: isApplicable
                            ? kBandiwalaYellow
                            : Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dotted separator
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: DottedLinePainter(),
            ),

            // Detailed description
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detailedDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  if (addMoreMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      addMoreMessage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: kBandiwalaYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
